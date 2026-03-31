<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Üretim emrini makineye planla
    POST params: p_order_id, station_id, start_date, status
    finish_date → operasyon dakikalarından otomatik hesaplanır
    Çakışma kontrolü: aynı makinede aynı zaman aralığında başka emir olamaz
--->

<cfset response = { "success": false, "message": "", "start_date": "", "finish_date": "", "total_op_minutes": 0, "shifted_count": 0, "shifted_orders": [] }>

<cftry>
    <cfparam name="form.p_order_id"  default="0">
    <cfparam name="form.station_id"  default="0">
    <cfparam name="form.start_date"  default="">
    <cfparam name="form.status"      default="1">
    <cfparam name="form.shift_following" default="0">

    <cfset pOrderId  = isNumeric(form.p_order_id) AND val(form.p_order_id) gt 0 ? val(form.p_order_id) : 0>
    <cfset stationId = isNumeric(form.station_id) AND val(form.station_id) gt 0 ? val(form.station_id) : 0>
    <cfset statusVal = isNumeric(form.status) ? val(form.status) : 1>
    <cfset shiftFollowing = isNumeric(form.shift_following) AND val(form.shift_following) eq 1>

    <cfif pOrderId eq 0>
        <cfset response.message = "Geçersiz üretim emri.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>
    <cfif stationId eq 0>
        <cfset response.message = "Makina seçimi zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Başlangıç tarihi parse --->
    <cfset startDate = (len(trim(form.start_date)) AND isDate(form.start_date))
                        ? createODBCDateTime(parseDateTime(Replace(trim(form.start_date),'T',' ','all')))
                        : javaCast("null","")>

    <cfif isNull(startDate)>
        <cfset response.message = "Geçerli bir başlangıç tarihi girin.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- İstasyon kontrolü --->
    <cfquery name="chkStation" datasource="boyahane">
        SELECT station_id FROM workstations
        WHERE station_id = <cfqueryparam value="#stationId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT chkStation.recordCount>
        <cfset response.message = "Seçilen makina bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Emir kontrolü + stock_id al --->
    <cfquery name="chkOrder" datasource="boyahane">
        SELECT p_order_id, stock_id FROM production_orders
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT chkOrder.recordCount>
        <cfset response.message = "Üretim emri bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Operasyon dakika toplamını hesapla --->
    <!--- Önce production_operation tablosundan bak (emir özelinde) --->
    <cfquery name="qOpMinutes" datasource="boyahane">
        SELECT COALESCE(SUM(COALESCE(o_minute, 0)), 0) AS total_minutes
        FROM production_operation
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfset totalMinutes = val(qOpMinutes.total_minutes)>

    <!--- production_operation boşsa ürün ağacından operasyon sürelerini al --->
    <cfif totalMinutes eq 0 AND val(chkOrder.stock_id) gt 0>
        <cfquery name="qTreeMinutes" datasource="boyahane">
            SELECT COALESCE(SUM(
                       CASE
                           WHEN pt.operation_type_id IS NOT NULL
                                AND pt.operation_type_id > 0
                           THEN COALESCE(ot.o_minute, 0)
                           ELSE 0
                       END
                   ), 0) AS total_minutes
            FROM product_tree pt
            LEFT JOIN operation_types ot ON pt.operation_type_id = ot.operation_type_id
            WHERE pt.stock_id = <cfqueryparam value="#val(chkOrder.stock_id)#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset totalMinutes = val(qTreeMinutes.total_minutes)>
    </cfif>

    <!--- Bitiş tarihini hesapla: başlangıç + toplam dakika (minimum 30 dk) --->
    <cfset safeMins   = (totalMinutes gt 0) ? totalMinutes : 480>
    <cfset rawStart   = parseDateTime(Replace(trim(form.start_date),'T',' ','all'))>
    <cfset rawFinish  = dateAdd("n", safeMins, rawStart)>
    <cfset finishDate = createODBCDateTime(rawFinish)>
    <cfset startStr   = dateFormat(rawStart,"yyyy-mm-dd") & "T" & timeFormat(rawStart,"HH:mm:ss")>
    <cfset finishStr  = dateFormat(rawFinish,"yyyy-mm-dd") & "T" & timeFormat(rawFinish,"HH:mm:ss")>

    <!--- ============================================================
          ÇAKIŞMA KONTROLÜ
          Aynı makinede start_date..finish_date aralığıyla örtüşen
          başka emir var mı?  (kendi emrini hariç tut)
          ============================================================ --->
    <!--- Çakışma kontrolü: aynı makinede bitiş saati yeni başlangıçtan sonra olan işler --->
    <cfquery name="qConflict" datasource="boyahane">
        SELECT p_order_id, p_order_no, start_date, finish_date
        FROM production_orders
        WHERE station_id = <cfqueryparam value="#stationId#"  cfsqltype="cf_sql_integer">
          AND p_order_id <> <cfqueryparam value="#pOrderId#"  cfsqltype="cf_sql_integer">
          AND status IN (1, 2)
          AND start_date  IS NOT NULL
          AND finish_date IS NOT NULL
          AND start_date  < <cfqueryparam value="#finishDate#" cfsqltype="cf_sql_timestamp">
          AND finish_date > <cfqueryparam value="#startDate#"  cfsqltype="cf_sql_timestamp">
        ORDER BY finish_date DESC
    </cfquery>

    <cfif qConflict.recordCount>
        <!---
            Scheduler hücreleri 30 dk'ya snap'lediğinden bırakılan nokta çakışan
            bir işin içine düşebilir. Bu durumda işi reddetmek yerine en geç
            çakışan işin bitiş saatine kaydırıyoruz (auto-snap).
            Kaydırılmış başlangıç, yeni finish_date'i de etkiler.
        --->
        <cfset snapStart   = qConflict.finish_date>
        <cfset rawSnapStart = parseDateTime(dateFormat(snapStart,"yyyy-mm-dd") & " " & timeFormat(snapStart,"HH:mm:ss"))>
        <cfset rawFinish    = dateAdd("n", safeMins, rawSnapStart)>
        <cfset startDate    = createODBCDateTime(rawSnapStart)>
        <cfset finishDate   = createODBCDateTime(rawFinish)>
        <cfset finishStr    = dateFormat(rawFinish,"yyyy-mm-dd") & "T" & timeFormat(rawFinish,"HH:mm:ss")>
        <cfset startStr     = dateFormat(rawSnapStart,"yyyy-mm-dd") & "T" & timeFormat(rawSnapStart,"HH:mm:ss")>

        <!--- Kaydırılmış hâlde hâlâ çakışıyor mu? --->
        <cfquery name="qConflict2" datasource="boyahane">
            SELECT p_order_id, p_order_no
            FROM production_orders
            WHERE station_id = <cfqueryparam value="#stationId#"  cfsqltype="cf_sql_integer">
              AND p_order_id <> <cfqueryparam value="#pOrderId#"  cfsqltype="cf_sql_integer">
              AND status IN (1, 2)
              AND start_date  IS NOT NULL
              AND finish_date IS NOT NULL
              AND start_date  < <cfqueryparam value="#finishDate#" cfsqltype="cf_sql_timestamp">
              AND finish_date > <cfqueryparam value="#startDate#"  cfsqltype="cf_sql_timestamp">
        </cfquery>

        <cfif qConflict2.recordCount>
            <cfset conflictNo = qConflict2.p_order_no ?: ("Emir ##" & qConflict2.p_order_id)>
            <cfset response.message = "Çakışma: Bu makine belirtilen zaman aralığında '#conflictNo#' emriyle dolu. Lütfen farklı bir saat seçin.">
            <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
        </cfif>

        <cfset response.snapped = true>
        <cfset response.start_date = startStr>
    </cfif>

    <!--- Kaydet --->
    <cfquery datasource="boyahane">
        UPDATE production_orders SET
            station_id  = <cfqueryparam value="#stationId#"  cfsqltype="cf_sql_integer">,
            start_date  = <cfqueryparam value="#startDate#"  cfsqltype="cf_sql_timestamp">,
            finish_date = <cfqueryparam value="#finishDate#" cfsqltype="cf_sql_timestamp">,
            status      = <cfqueryparam value="#statusVal#"  cfsqltype="cf_sql_integer">,
            update_date = CURRENT_TIMESTAMP
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <!---
        Drag&drop ile araya emir bırakma:
        Bu kayıt başlangıcından sonra başlayan planlı emirleri,
        yeni emrin süresi kadar ileri kaydır.
    --->
    <cfif shiftFollowing>
        <cfquery name="qFollowingOrders" datasource="boyahane">
            SELECT p_order_id, start_date, finish_date
            FROM production_orders
            WHERE station_id = <cfqueryparam value="#stationId#" cfsqltype="cf_sql_integer">
              AND p_order_id <> <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
              AND status IN (1, 2)
              AND start_date IS NOT NULL
              AND finish_date IS NOT NULL
              AND start_date >= <cfqueryparam value="#startDate#" cfsqltype="cf_sql_timestamp">
            ORDER BY start_date ASC
        </cfquery>

        <cfloop query="qFollowingOrders">
            <cfset shiftedStart = dateAdd("n", safeMins, qFollowingOrders.start_date)>
            <cfset shiftedEnd   = dateAdd("n", safeMins, qFollowingOrders.finish_date)>

            <cfquery datasource="boyahane">
                UPDATE production_orders
                SET start_date  = <cfqueryparam value="#createODBCDateTime(shiftedStart)#" cfsqltype="cf_sql_timestamp">,
                    finish_date = <cfqueryparam value="#createODBCDateTime(shiftedEnd)#"   cfsqltype="cf_sql_timestamp">,
                    update_date = CURRENT_TIMESTAMP
                WHERE p_order_id = <cfqueryparam value="#qFollowingOrders.p_order_id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset arrayAppend(response.shifted_orders, {
                "p_order_id" : val(qFollowingOrders.p_order_id),
                "start_date" : dateFormat(shiftedStart,"yyyy-mm-dd") & "T" & timeFormat(shiftedStart,"HH:mm:ss"),
                "finish_date": dateFormat(shiftedEnd,  "yyyy-mm-dd") & "T" & timeFormat(shiftedEnd,  "HH:mm:ss")
            })>
        </cfloop>
        <cfset response.shifted_count = arrayLen(response.shifted_orders)>
    </cfif>

    <cfset response.success          = true>
    <cfset response.message          = "Emir planlandı.">
    <cfset response.start_date       = startStr>
    <cfset response.finish_date      = finishStr>
    <cfset response.total_op_minutes = safeMins>

<cfcatch type="any">
    <cfset response.message = "Sunucu hatası: " & htmlEditFormat(cfcatch.message)>
</cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
