<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Üretim emrini tamamlandı olarak sonuçlandırır.
    Otomatik olarak 2 stok fişi oluşturur:
      1. Sarf fişi (çıkış, type=2): production_orders_stocks hammaddeleri
      2. Giriş fişi (type=1): üretim sonucu oluşan stok
--->

<!--- ─── Atomik fiş no: cftry dışında tanımlanmalı ─── --->
<cffunction name="nextFisNo" returntype="string" access="private">
    <cfargument name="prefix" type="string" default="SF">
    <cfquery name="autoNo" datasource="boyahane">
        UPDATE general_papers
           SET stock_fis_number = COALESCE(stock_fis_number, 0) + 1
         WHERE zone_type = 0
         RETURNING COALESCE(stock_fis_no, <cfqueryparam value="#arguments.prefix#" cfsqltype="cf_sql_varchar">) || '-' ||
                       LPAD(stock_fis_number::text, 5, '0') AS generated_no
    </cfquery>
    <cfif autoNo.recordCount><cfreturn autoNo.generated_no></cfif>
    <cfquery name="ins" datasource="boyahane">
        INSERT INTO general_papers (zone_type, stock_fis_no, stock_fis_number)
        VALUES (0, <cfqueryparam value="#arguments.prefix#" cfsqltype="cf_sql_varchar">, 1)
        ON CONFLICT DO NOTHING
    </cfquery>
    <cfquery name="autoNo2" datasource="boyahane">
        UPDATE general_papers
           SET stock_fis_number = COALESCE(stock_fis_number, 0) + 1
         WHERE zone_type = 0
         RETURNING COALESCE(stock_fis_no, <cfqueryparam value="#arguments.prefix#" cfsqltype="cf_sql_varchar">) || '-' ||
                       LPAD(stock_fis_number::text, 5, '0') AS generated_no
    </cfquery>
    <cfif autoNo2.recordCount><cfreturn autoNo2.generated_no></cfif>
    <cfreturn arguments.prefix & '-' & dateFormat(now(),'yyyymmdd') & '-' & randRange(1000,9999)>
</cffunction>

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.p_order_id"     default="0">
    <cfparam name="form.result_amount"  default="0">
    <cfparam name="form.note"           default="">

    <cfset pOrderId    = isNumeric(form.p_order_id) AND val(form.p_order_id) gt 0 ? val(form.p_order_id) : 0>
    <cfset resultAmt   = isNumeric(form.result_amount) AND val(form.result_amount) gt 0 ? val(form.result_amount) : 0>
    <cfset noteVal     = trim(form.note)>

    <cfif pOrderId eq 0>
        <cfset response.message = "Geçersiz üretim emri ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>
    <cfif resultAmt lte 0>
        <cfset response.message = "Gerçekleşen miktar girilmelidir.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Emrin mevcut durumunu kontrol et --->
    <cfquery name="chk" datasource="boyahane">
        SELECT status FROM production_orders
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT chk.recordCount>
        <cfset response.message = "Üretim emri bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>
    <cfif val(chk.status) eq 5>
        <cfset response.message = "Bu emir zaten tamamlanmış.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>
    <cfif val(chk.status) eq 9>
        <cfset response.message = "İptal edilmiş emirler sonuçlandırılamaz.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Üretim emrinin detayını çek (stok, emir no, lot, istasyon) --->
    <cfquery name="getOrder" datasource="boyahane">
        SELECT po.stock_id,
               COALESCE(po.p_order_no, '')        AS p_order_no,
               COALESCE(po.lot_no, '')             AS lot_no,
               COALESCE(s.product_id, 0)           AS product_id,
               COALESCE(po.station_id, 0)          AS station_id,
               COALESCE(po.production_dep_id, 0)   AS po_prod_dep_id,
               COALESCE(po.production_loc_id, 0)   AS po_prod_loc_id
        FROM   production_orders po
        LEFT JOIN stocks s ON po.stock_id = s.stock_id
        WHERE  po.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfset prodStockId   = val(getOrder.stock_id  ?: 0)>
    <cfset prodOrderNo   = getOrder.p_order_no>
    <cfset prodLotNo     = getOrder.lot_no>
    <cfset prodProductId = val(getOrder.product_id ?: 0)>

    <!--- İstasyon depo/lokasyon bilgileri (stocks_location.id cinsinden) --->
    <cfset sarfDepId  = val(getOrder.po_prod_dep_id ?: 0)>
    <cfset sarfLocId  = val(getOrder.po_prod_loc_id ?: 0)>
    <cfset girisDepId = 0>
    <cfset girisLocId = 0>
    <cfset wsStationId = val(getOrder.station_id ?: 0)>
    <cfif wsStationId gt 0>
        <cfquery name="getStation" datasource="boyahane">
            SELECT COALESCE(production_dep_id, 0) AS prod_dep,
                   COALESCE(production_loc_id, 0) AS prod_loc,
                   COALESCE(enter_dep_id, 0)      AS enter_dep,
                   COALESCE(enter_loc_id, 0)      AS enter_loc
            FROM workstations
            WHERE station_id = <cfqueryparam value="#wsStationId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif getStation.recordCount>
            <cfif sarfDepId eq 0><cfset sarfDepId  = val(getStation.prod_dep ?: 0)></cfif>
            <cfif sarfLocId eq 0><cfset sarfLocId  = val(getStation.prod_loc ?: 0)></cfif>
            <cfset girisDepId = val(getStation.enter_dep ?: 0)>
            <cfset girisLocId = val(getStation.enter_loc ?: 0)>
        </cfif>
    </cfif>

    <!--- Hammadde satırları (production_orders_stocks) --->
    <cfquery name="getStocks" datasource="boyahane">
        SELECT por.stock_id,
               COALESCE(por.amount, 0)    AS amount,
               COALESCE(por.lot_no, '')   AS lot_no,
               COALESCE(s.product_id, 0) AS product_id
        FROM   production_orders_stocks por
        LEFT JOIN stocks s ON por.stock_id = s.stock_id
        WHERE  por.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
          AND  COALESCE(por.stock_id, 0) > 0
          AND  COALESCE(por.amount, 0)   > 0
    </cfquery>

    <!--- ══════════════════════════════════════════════════
          1.  SARF FİŞİ (Çıkış - type 2): hammaddeler
    ══════════════════════════════════════════════════ --->
    <cfif getStocks.recordCount gt 0>
        <cfset sarfNo = nextFisNo("SARF")>
        <cfquery datasource="boyahane">
            INSERT INTO stock_fis (
                fis_type, fis_number, fis_date,
                ref_no, fis_detail,
                location_out, department_out,
                is_production,
                record_date, record_emp, record_ip
            ) VALUES (
                2,
                <cfqueryparam value="#sarfNo#"       cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#now()#"         cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#prodOrderNo#"   cfsqltype="cf_sql_varchar" null="#NOT len(prodOrderNo)#">,
                <cfqueryparam value="Üretim Sarf — #prodOrderNo#" cfsqltype="cf_sql_longvarchar">,
                <cfqueryparam value="#sarfLocId#"     cfsqltype="cf_sql_integer" null="#sarfLocId eq 0#">,
                <cfqueryparam value="#sarfDepId#"     cfsqltype="cf_sql_integer" null="#sarfDepId eq 0#">,
                true,
                <cfqueryparam value="#now()#"         cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
        <cfquery name="getSarfId" datasource="boyahane">
            SELECT lastval() AS fis_id
        </cfquery>
        <cfset sarfFisId = val(getSarfId.fis_id)>

        <cfloop query="getStocks">
            <cfset hmRowLot = len(trim(lot_no)) ? trim(lot_no) : prodLotNo>
            <!--- stock_fis_row --->
            <cfquery datasource="boyahane">
                INSERT INTO stock_fis_row (
                    fis_id, stock_id, amount, lot_no
                ) VALUES (
                    <cfqueryparam value="#sarfFisId#"  cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#val(stock_id)#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#val(amount)#"   cfsqltype="cf_sql_double">,
                    <cfqueryparam value="#hmRowLot#"      cfsqltype="cf_sql_varchar" null="#NOT len(hmRowLot)#">
                )
            </cfquery>
            <!--- stocks_row: çıkış hareketi --->
            <cfquery datasource="boyahane">
                INSERT INTO stocks_row (
                    stock_id, product_id, upd_id, process_type,
                    stock_in, stock_out,
                    store, store_location,
                    process_date, lot_no
                ) VALUES (
                    <cfqueryparam value="#val(stock_id)#"   cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#val(product_id)#" cfsqltype="cf_sql_integer" null="#val(product_id) eq 0#">,
                    <cfqueryparam value="#sarfFisId#"        cfsqltype="cf_sql_integer">,
                    2,
                    0,
                    <cfqueryparam value="#val(amount)#"     cfsqltype="cf_sql_double">,
                    <cfqueryparam value="#sarfDepId#"        cfsqltype="cf_sql_integer" null="#sarfDepId eq 0#">,
                    <cfqueryparam value="#sarfLocId#"        cfsqltype="cf_sql_integer" null="#sarfLocId eq 0#">,
                    <cfqueryparam value="#now()#"            cfsqltype="cf_sql_timestamp">,
                    <cfqueryparam value="#hmRowLot#"         cfsqltype="cf_sql_varchar" null="#NOT len(hmRowLot)#">
                )
            </cfquery>
        </cfloop>
    </cfif>

    <!--- ══════════════════════════════════════════════════
          2.  GİRİŞ FİŞİ (type 1): üretim sonucu stok
    ══════════════════════════════════════════════════ --->
    <cfif prodStockId gt 0>
        <cfset girisNo = nextFisNo("URG")>
        <cfquery datasource="boyahane">
            INSERT INTO stock_fis (
                fis_type, fis_number, fis_date,
                ref_no, fis_detail,
                location_in, department_in,
                is_production,
                record_date, record_emp, record_ip
            ) VALUES (
                1,
                <cfqueryparam value="#girisNo#"       cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#now()#"          cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#prodOrderNo#"    cfsqltype="cf_sql_varchar" null="#NOT len(prodOrderNo)#">,
                <cfqueryparam value="Üretim Girişi — #prodOrderNo#" cfsqltype="cf_sql_longvarchar">,
                <cfqueryparam value="#girisLocId#"     cfsqltype="cf_sql_integer" null="#girisLocId eq 0#">,
                <cfqueryparam value="#girisDepId#"     cfsqltype="cf_sql_integer" null="#girisDepId eq 0#">,
                true,
                <cfqueryparam value="#now()#"          cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
        <cfquery name="getGirisId" datasource="boyahane">
            SELECT lastval() AS fis_id
        </cfquery>
        <cfset girisFisId = val(getGirisId.fis_id)>

        <!--- stock_fis_row --->
        <cfquery datasource="boyahane">
            INSERT INTO stock_fis_row (
                fis_id, stock_id, amount, lot_no
            ) VALUES (
                <cfqueryparam value="#girisFisId#"    cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#prodStockId#"   cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#resultAmt#"     cfsqltype="cf_sql_double">,
                <cfqueryparam value="#prodLotNo#"     cfsqltype="cf_sql_varchar" null="#NOT len(prodLotNo)#">
            )
        </cfquery>
        <!--- stocks_row: giriş hareketi --->
        <cfquery datasource="boyahane">
            INSERT INTO stocks_row (
                stock_id, product_id, upd_id, process_type,
                stock_in, stock_out,
                store, store_location,
                process_date, lot_no
            ) VALUES (
                <cfqueryparam value="#prodStockId#"   cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#prodProductId#" cfsqltype="cf_sql_integer" null="#prodProductId eq 0#">,
                <cfqueryparam value="#girisFisId#"    cfsqltype="cf_sql_integer">,
                1,
                <cfqueryparam value="#resultAmt#"     cfsqltype="cf_sql_double">,
                0,
                <cfqueryparam value="#girisDepId#"    cfsqltype="cf_sql_integer" null="#girisDepId eq 0#">,
                <cfqueryparam value="#girisLocId#"    cfsqltype="cf_sql_integer" null="#girisLocId eq 0#">,
                <cfqueryparam value="#now()#"          cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#prodLotNo#"      cfsqltype="cf_sql_varchar" null="#NOT len(prodLotNo)#">
            )
        </cfquery>
    </cfif>

    <!--- ══  Üretim emrini tamamlandı olarak güncelle  ══ --->
    <cfquery datasource="boyahane">
        UPDATE production_orders SET
            status           = 5,
            result_amount    = <cfqueryparam value="#resultAmt#" cfsqltype="cf_sql_numeric">,
            finish_date_real = CURRENT_TIMESTAMP,
            detail           = CASE WHEN <cfqueryparam value="#len(noteVal)#" cfsqltype="cf_sql_integer"> > 0
                                    THEN COALESCE(detail,'') || ' | Sonuç notu: ' || <cfqueryparam value="#noteVal#" cfsqltype="cf_sql_varchar">
                                    ELSE detail
                               END,
            update_date      = CURRENT_TIMESTAMP
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response = {
        "success"       : true,
        "p_order_id"    : pOrderId,
        "result_amount" : resultAmt,
        "sarf_fis_no"   : isDefined("sarfNo")  ? sarfNo  : "",
        "giris_fis_no"  : isDefined("girisNo") ? girisNo : ""
    }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>