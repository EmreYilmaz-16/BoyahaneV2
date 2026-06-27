<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    action=start : Bitiş tarihi olmadan aktif duruş kaydı oluşturur.
    action=end   : Aktif duruşun bitiş tarihi ve süresini günceller.
    action boş   : Eski ekranlarla uyumluluk için tamamlanmış kayıt ekler.
--->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.action"               default="">
    <cfparam name="form.prod_pause_id"        default="0">
    <cfparam name="form.p_order_id"           default="0">
    <cfparam name="form.pause_type_id"        default="0">
    <cfparam name="form.prod_duration"        default="0">
    <cfparam name="form.prod_detail"          default="">
    <cfparam name="form.action_date"          default="">
    <cfparam name="form.station_id"           default="0">
    <cfparam name="form.employee_id"          default="0">
    <cfparam name="form.is_working_time"      default="0">
    <cfparam name="form.duration_start_date"  default="">
    <cfparam name="form.duration_finish_date" default="">

    <cfset action       = lCase(trim(form.action))>
    <cfset prodPauseId  = isNumeric(form.prod_pause_id) AND val(form.prod_pause_id) gt 0 ? val(form.prod_pause_id) : 0>
    <cfset pOrderId     = isNumeric(form.p_order_id) AND val(form.p_order_id) gt 0 ? val(form.p_order_id) : 0>
    <cfset pauseTypeId  = isNumeric(form.pause_type_id) AND val(form.pause_type_id) gt 0 ? val(form.pause_type_id) : javaCast("null","")>
    <cfset duration     = isNumeric(form.prod_duration) ? val(form.prod_duration) : 0>
    <cfset detailVal    = trim(form.prod_detail)>
    <cfset stationId    = isNumeric(form.station_id) AND val(form.station_id) gt 0 ? val(form.station_id) : javaCast("null","")>
    <cfset employeeId   = isNumeric(form.employee_id) AND val(form.employee_id) gt 0 ? val(form.employee_id) : javaCast("null","")>
    <cfset isWrk        = (form.is_working_time eq "1" OR form.is_working_time eq "true")>

    <cfif pOrderId eq 0>
        <cfset response.message = "Geçersiz üretim emri ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Duruşu başlat: aynı emir için tek bir açık kayıt bulunabilir. --->
    <cfif action eq "start">
        <cftransaction>
            <!--- Eş zamanlı çift tıklamalarda iki kayıt açılmasını engelle. --->
            <cfquery name="qOrderLock" datasource="boyahane">
                SELECT p_order_id
                FROM production_orders
                WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
                  AND status = 2
                FOR UPDATE
            </cfquery>

            <cfif qOrderLock.recordCount eq 0>
                <cfthrow message="Üretim emri bulunamadı veya çalışır durumda değil.">
            </cfif>

            <cfquery name="qActive" datasource="boyahane">
                SELECT prod_pause_id, duration_start_date
                FROM setup_prod_pause
                WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
                  AND duration_finish_date IS NULL
                ORDER BY prod_pause_id DESC
                LIMIT 1
            </cfquery>

            <cfif qActive.recordCount>
                <cfset response = {
                    "success": false,
                    "message": "Bu üretim emri için zaten aktif bir duruş var.",
                    "prod_pause_id": val(qActive.prod_pause_id)
                }>
            <cfelse>
                <cfquery name="ins" datasource="boyahane">
                    INSERT INTO setup_prod_pause (
                        p_order_id, prod_pause_type_id, prod_duration, prod_detail,
                        is_working_time, action_date, station_id, employee_id,
                        duration_start_date, duration_finish_date,
                        record_date, record_ip
                    ) VALUES (
                        <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#isNull(pauseTypeId) ? '' : pauseTypeId#" cfsqltype="cf_sql_integer" null="#isNull(pauseTypeId)#">,
                        0,
                        <cfqueryparam value="#detailVal#" cfsqltype="cf_sql_varchar" null="#NOT len(detailVal)#">,
                        <cfqueryparam value="#isWrk#" cfsqltype="cf_sql_bit">,
                        CURRENT_TIMESTAMP,
                        <cfqueryparam value="#isNull(stationId) ? '' : stationId#" cfsqltype="cf_sql_integer" null="#isNull(stationId)#">,
                        <cfqueryparam value="#isNull(employeeId) ? '' : employeeId#" cfsqltype="cf_sql_integer" null="#isNull(employeeId)#">,
                        CURRENT_TIMESTAMP,
                        NULL,
                        CURRENT_TIMESTAMP,
                        <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
                    )
                    RETURNING prod_pause_id, duration_start_date
                </cfquery>
                <cfset response = {
                    "success": true,
                    "action": "started",
                    "prod_pause_id": val(ins.prod_pause_id),
                    "duration_start_ms": ins.duration_start_date.getTime(),
                    "duration_start_date": dateFormat(ins.duration_start_date, "yyyy-mm-dd") & "T" & timeFormat(ins.duration_start_date, "HH:mm:ss")
                }>
            </cfif>
        </cftransaction>

    <!--- Duruşu bitir: yalnızca halen açık olan aynı kaydı güncelle. --->
    <cfelseif action eq "end">
        <cfif prodPauseId eq 0>
            <cfset response.message = "Geçersiz duruş kaydı ID.">
        <cfelse>
            <cfquery name="upd" datasource="boyahane">
                UPDATE setup_prod_pause
                SET duration_finish_date = CURRENT_TIMESTAMP,
                    prod_duration = GREATEST(
                        1,
                        ROUND(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - duration_start_date)) / 60.0)::INTEGER
                    ),
                    update_date = CURRENT_TIMESTAMP,
                    update_ip = <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
                WHERE prod_pause_id = <cfqueryparam value="#prodPauseId#" cfsqltype="cf_sql_integer">
                  AND p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
                  AND duration_finish_date IS NULL
                RETURNING prod_pause_id, prod_duration, duration_start_date, duration_finish_date
            </cfquery>

            <cfif upd.recordCount>
                <cfset response = {
                    "success": true,
                    "action": "ended",
                    "prod_pause_id": val(upd.prod_pause_id),
                    "prod_duration": val(upd.prod_duration),
                    "duration_start_ms": upd.duration_start_date.getTime(),
                    "duration_finish_ms": upd.duration_finish_date.getTime(),
                    "duration_start_date": dateFormat(upd.duration_start_date, "yyyy-mm-dd") & "T" & timeFormat(upd.duration_start_date, "HH:mm:ss"),
                    "duration_finish_date": dateFormat(upd.duration_finish_date, "yyyy-mm-dd") & "T" & timeFormat(upd.duration_finish_date, "HH:mm:ss")
                }>
            <cfelse>
                <cfset response.message = "Aktif duruş kaydı bulunamadı veya daha önce bitirilmiş.">
            </cfif>
        </cfif>

    <!--- Eski ekranların tek istekte tamamlanmış duruş ekleme akışı. --->
    <cfelse>
        <cfset actionDate = (len(trim(form.action_date)) AND isDate(form.action_date))
            ? createODBCDateTime(parseDateTime(Replace(form.action_date,'T',' ','all')))
            : createODBCDateTime(now())>
        <cfset startDate = (len(trim(form.duration_start_date)) AND isDate(form.duration_start_date))
            ? createODBCDateTime(parseDateTime(Replace(form.duration_start_date,'T',' ','all')))
            : javaCast("null","")>
        <cfset finishDate = (len(trim(form.duration_finish_date)) AND isDate(form.duration_finish_date))
            ? createODBCDateTime(parseDateTime(Replace(form.duration_finish_date,'T',' ','all')))
            : javaCast("null","")>

        <cfif duration eq 0 AND NOT isNull(startDate) AND NOT isNull(finishDate)>
            <cfset duration = int((finishDate.getTime() - startDate.getTime()) / 60000)>
        </cfif>

        <cfquery name="ins" datasource="boyahane">
            INSERT INTO setup_prod_pause (
                p_order_id, prod_pause_type_id, prod_duration, prod_detail,
                is_working_time, action_date, station_id, employee_id,
                duration_start_date, duration_finish_date,
                record_date, record_ip
            ) VALUES (
                <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#isNull(pauseTypeId) ? '' : pauseTypeId#" cfsqltype="cf_sql_integer" null="#isNull(pauseTypeId)#">,
                <cfqueryparam value="#duration#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#detailVal#" cfsqltype="cf_sql_varchar" null="#NOT len(detailVal)#">,
                <cfqueryparam value="#isWrk#" cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#actionDate#" cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#isNull(stationId) ? '' : stationId#" cfsqltype="cf_sql_integer" null="#isNull(stationId)#">,
                <cfqueryparam value="#isNull(employeeId) ? '' : employeeId#" cfsqltype="cf_sql_integer" null="#isNull(employeeId)#">,
                <cfqueryparam value="#isNull(startDate) ? '' : startDate#" cfsqltype="cf_sql_timestamp" null="#isNull(startDate)#">,
                <cfqueryparam value="#isNull(finishDate) ? '' : finishDate#" cfsqltype="cf_sql_timestamp" null="#isNull(finishDate)#">,
                CURRENT_TIMESTAMP,
                <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
            )
            RETURNING prod_pause_id
        </cfquery>
        <cfset response = { "success": true, "action": "inserted", "prod_pause_id": val(ins.prod_pause_id) }>
    </cfif>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
