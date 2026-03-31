<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Üretim sonucu kaydet:
      1. production_order_results satırı oluştur
      2. production_order_results_row satırlarını oluştur (JSON rows)
--->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.p_order_id"           default="0">
    <cfparam name="form.result_no"            default="">
    <cfparam name="form.lot_no"               default="">
    <cfparam name="form.prod_ord_result_stage" default="1">
    <cfparam name="form.start_date"           default="">
    <cfparam name="form.finish_date"          default="">
    <cfparam name="form.rows"                 default="[]">

    <cfset pOrderId = isNumeric(form.p_order_id) AND val(form.p_order_id) gt 0 ? val(form.p_order_id) : 0>

    <cfif pOrderId eq 0>
        <cfset response.message = "Geçersiz üretim emri ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Emri getir — istasyon ve diğer bilgiler için --->
    <cfquery name="getOrder" datasource="boyahane">
        SELECT p_order_id, station_id, lot_no, p_order_no,
               exit_dep_id, exit_loc_id, production_dep_id, production_loc_id
        FROM production_orders
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getOrder.recordCount>
        <cfset response.message = "Üretim emri bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Sonuç No --->
    <cfset resultNo = trim(form.result_no)>
    <cfif NOT len(resultNo)>
        <cfset resultNo = "SN-" & dateFormat(now(),"yyyymmdd") & "-" & right("0000" & randRange(1,9999),4)>
    </cfif>

    <!--- Tarihler --->
    <cfset startDate  = (len(trim(form.start_date))  AND isDate(form.start_date))
        ? createODBCDateTime(parseDateTime(Replace(form.start_date,'T',' ','all')))
        : createODBCDateTime(now())>
    <cfset finishDate = (len(trim(form.finish_date)) AND isDate(form.finish_date))
        ? createODBCDateTime(parseDateTime(Replace(form.finish_date,'T',' ','all')))
        : createODBCDateTime(now())>

    <cfset stageVal  = isNumeric(form.prod_ord_result_stage) ? val(form.prod_ord_result_stage) : 1>
    <cfset lotNo     = len(trim(form.lot_no)) ? trim(form.lot_no) : (len(getOrder.lot_no) ? getOrder.lot_no : "")>
    <cfset stationId = val(getOrder.station_id) gt 0 ? val(getOrder.station_id) : javaCast("null","")>

    <!--- Ana sonuç satırı INSERT --->
    <cfquery name="insResult" datasource="boyahane">
        INSERT INTO production_order_results (
            p_order_id, station_id, start_date, finish_date, lot_no,
            result_no, production_order_no,
            exit_dep_id, exit_loc_id, production_dep_id, production_loc_id,
            prod_ord_result_stage, is_stock_fis,
            record_emp, record_date, record_ip
        ) VALUES (
            <cfqueryparam value="#pOrderId#"                                         cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#isNull(stationId)?'':stationId#"                  cfsqltype="cf_sql_integer"  null="#isNull(stationId)#">,
            <cfqueryparam value="#startDate#"                                        cfsqltype="cf_sql_timestamp">,
            <cfqueryparam value="#finishDate#"                                       cfsqltype="cf_sql_timestamp">,
            <cfqueryparam value="#lotNo#"                                            cfsqltype="cf_sql_varchar"  null="#NOT len(lotNo)#">,
            <cfqueryparam value="#resultNo#"                                         cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#getOrder.p_order_no#"                             cfsqltype="cf_sql_varchar"  null="#NOT len(getOrder.p_order_no)#">,
            <cfqueryparam value="#isNumeric(getOrder.exit_dep_id)?val(getOrder.exit_dep_id):''#"        cfsqltype="cf_sql_integer" null="#NOT isNumeric(getOrder.exit_dep_id) OR val(getOrder.exit_dep_id) eq 0#">,
            <cfqueryparam value="#isNumeric(getOrder.exit_loc_id)?val(getOrder.exit_loc_id):''#"        cfsqltype="cf_sql_integer" null="#NOT isNumeric(getOrder.exit_loc_id) OR val(getOrder.exit_loc_id) eq 0#">,
            <cfqueryparam value="#isNumeric(getOrder.production_dep_id)?val(getOrder.production_dep_id):''#" cfsqltype="cf_sql_integer" null="#NOT isNumeric(getOrder.production_dep_id) OR val(getOrder.production_dep_id) eq 0#">,
            <cfqueryparam value="#isNumeric(getOrder.production_loc_id)?val(getOrder.production_loc_id):''#" cfsqltype="cf_sql_integer" null="#NOT isNumeric(getOrder.production_loc_id) OR val(getOrder.production_loc_id) eq 0#">,
            <cfqueryparam value="#stageVal#"                                         cfsqltype="cf_sql_integer">,
            false,
            <cfqueryparam value="0"                                                  cfsqltype="cf_sql_integer">,
            CURRENT_TIMESTAMP,
            <cfqueryparam value="#CGI.REMOTE_ADDR#"                                 cfsqltype="cf_sql_varchar">
        )
        RETURNING pr_order_id
    </cfquery>

    <cfset newPrOrderId = val(insResult.pr_order_id)>

    <!--- Satır kayıtları --->
    <cfset rowsArr = []>
    <cftry>
        <cfset rowsArr = deserializeJSON(form.rows)>
        <cfcatch><cfset rowsArr = []></cfcatch>
    </cftry>

    <cfset lineNum = 1>
    <cfloop array="#rowsArr#" index="r">
        <cfset rName   = trim(r.product_name ?: "")>
        <cfset rAmount = isNumeric(r.amount) ? val(r.amount) : 0>
        <cfset rFire   = isNumeric(r.fire_amount) ? val(r.fire_amount) : 0>
        <cfset rLot    = trim(r.lot_no ?: "")>

        <cfif rAmount gt 0>
            <cfquery datasource="boyahane">
                INSERT INTO production_order_results_row (
                    pr_order_id, p_order_id, type, tree_type,
                    name_product, amount, fire_amount, lot_no,
                    line_number, is_stock_fis, is_from_spect
                ) VALUES (
                    <cfqueryparam value="#newPrOrderId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#pOrderId#"     cfsqltype="cf_sql_integer">,
                    1,
                    'S',
                    <cfqueryparam value="#rName#"   cfsqltype="cf_sql_varchar" null="#NOT len(rName)#">,
                    <cfqueryparam value="#rAmount#" cfsqltype="cf_sql_numeric">,
                    <cfqueryparam value="#rFire#"   cfsqltype="cf_sql_numeric">,
                    <cfqueryparam value="#rLot#"    cfsqltype="cf_sql_varchar" null="#NOT len(rLot)#">,
                    <cfqueryparam value="#lineNum#" cfsqltype="cf_sql_integer">,
                    false,
                    false
                )
            </cfquery>
            <cfset lineNum++>
        </cfif>
    </cfloop>

    <cfset response = { "success": true, "pr_order_id": newPrOrderId, "result_no": resultNo }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>