<cfprocessingdirective pageEncoding="utf-8">
<cfparam name="variables.isIncluded" default="false">
<cfif NOT variables.isIncluded>
    <cfsetting showdebugoutput="false">
    <cfcontent type="application/json; charset=utf-8">
</cfif>

<!---
    Üretim emri kaydet (INSERT / UPDATE)
    Ayrıca production_orders_stocks tablosunu renk reçetesinden doldurur.
--->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.p_order_id"  default="0">
    <cfparam name="form.stock_id"    default="0">
    <cfparam name="form.station_id"  default="0">
    <cfparam name="form.quantity"    default="0">
    <cfparam name="form.p_order_no"  default="">
    <cfparam name="form.lot_no"      default="">
    <cfparam name="form.start_date"  default="">
    <cfparam name="form.finish_date" default="">
    <cfparam name="form.status"      default="1">
    <cfparam name="form.detail"      default="">
    <cfparam name="form.order_id"     default="0">
    <cfparam name="form.order_row_id" default="0">

    <cfset pOrderId    = isNumeric(form.p_order_id)  AND val(form.p_order_id)  gt 0 ? val(form.p_order_id)  : 0>
    <cfset stockId     = isNumeric(form.stock_id)    AND val(form.stock_id)    gt 0 ? val(form.stock_id)    : 0>
    <cfset stationId   = isNumeric(form.station_id)  AND val(form.station_id)  gt 0 ? val(form.station_id)  : javaCast("null","")>
    <cfset qty         = isNumeric(form.quantity)     AND val(form.quantity) gt 0   ? val(form.quantity)    : 0>
    <cfset orderNo     = trim(form.p_order_no)>
    <cfset lotNo       = trim(form.lot_no)>
    <cfset statusVal   = isNumeric(form.status) ? val(form.status) : 1>
    <cfset detailVal   = trim(form.detail)>
    <cfset hasOrderId    = isNumeric(form.order_id)     AND val(form.order_id)     gt 0>
    <cfset hasOrderRowId = isNumeric(form.order_row_id) AND val(form.order_row_id) gt 0>
    <cfset orderId       = hasOrderId    ? val(form.order_id)     : 0>
    <cfset orderRowId    = hasOrderRowId ? val(form.order_row_id) : 0>

    <!--- Tarih parse --->
    <cfset startDate  = (len(trim(form.start_date))  AND isDate(form.start_date))
                         ? createODBCDateTime(parseDateTime(Replace(form.start_date,'T',' ','all')))
                         : javaCast("null","")>
    <cfset finishDate = (len(trim(form.finish_date)) AND isDate(form.finish_date))
                         ? createODBCDateTime(parseDateTime(Replace(form.finish_date,'T',' ','all')))
                         : javaCast("null","")>

    <cfif stockId eq 0>
        <cfset response.message = "Renk kartı seçimi zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>
    <cfif qty lte 0>
        <cfset response.message = "Miktar sıfırdan büyük olmalıdır.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Otomatik emir no --->
    <cfif NOT len(orderNo)>
        <cfset orderNo = "UE-" & dateFormat(now(),"yyyymmdd") & "-" & right("000" & randRange(1,999),3)>
    </cfif>

    <cfif pOrderId gt 0>
        <!--- UPDATE --->
        <cfquery datasource="boyahane">
            UPDATE production_orders SET
                stock_id    = <cfqueryparam value="#stockId#"                           cfsqltype="cf_sql_integer">,
                station_id  = <cfqueryparam value="#isNull(stationId)?'':stationId#"   cfsqltype="cf_sql_integer" null="#isNull(stationId)#">,
                order_id    = <cfqueryparam value="#orderId#"    cfsqltype="cf_sql_integer" null="#NOT hasOrderId#">,
                order_row_id = <cfqueryparam value="#orderRowId#" cfsqltype="cf_sql_integer" null="#NOT hasOrderRowId#">,
                quantity    = <cfqueryparam value="#qty#"                               cfsqltype="cf_sql_numeric">,
                p_order_no  = <cfqueryparam value="#orderNo#"                          cfsqltype="cf_sql_varchar"  null="#NOT len(orderNo)#">,
                lot_no      = <cfqueryparam value="#lotNo#"                            cfsqltype="cf_sql_varchar"  null="#NOT len(lotNo)#">,
                start_date  = <cfqueryparam value="#isNull(startDate)?'':startDate#"   cfsqltype="cf_sql_timestamp" null="#isNull(startDate)#">,
                finish_date = <cfqueryparam value="#isNull(finishDate)?'':finishDate#" cfsqltype="cf_sql_timestamp" null="#isNull(finishDate)#">,
                status      = <cfqueryparam value="#statusVal#"                        cfsqltype="cf_sql_integer">,
                detail      = <cfqueryparam value="#detailVal#"                        cfsqltype="cf_sql_varchar"  null="#NOT len(detailVal)#">,
                update_date = CURRENT_TIMESTAMP
            WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset savedId = pOrderId>
        <cfset mode    = "updated">
    <cfelse>
        <!--- INSERT --->
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO production_orders
                (stock_id, station_id, order_id, order_row_id, quantity, p_order_no, lot_no,
                 start_date, finish_date, status, detail, record_date)
            VALUES (
                <cfqueryparam value="#stockId#"                           cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#isNull(stationId)?'':stationId#"   cfsqltype="cf_sql_integer" null="#isNull(stationId)#">,
                <cfqueryparam value="#orderId#"                          cfsqltype="cf_sql_integer" null="#NOT hasOrderId#">,
                <cfqueryparam value="#orderRowId#"                       cfsqltype="cf_sql_integer" null="#NOT hasOrderRowId#">,
                <cfqueryparam value="#qty#"                               cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#orderNo#"                           cfsqltype="cf_sql_varchar"  null="#NOT len(orderNo)#">,
                <cfqueryparam value="#lotNo#"                             cfsqltype="cf_sql_varchar"  null="#NOT len(lotNo)#">,
                <cfqueryparam value="#isNull(startDate)?'':startDate#"   cfsqltype="cf_sql_timestamp" null="#isNull(startDate)#">,
                <cfqueryparam value="#isNull(finishDate)?'':finishDate#" cfsqltype="cf_sql_timestamp" null="#isNull(finishDate)#">,
                <cfqueryparam value="#statusVal#"                         cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#detailVal#"                         cfsqltype="cf_sql_varchar"  null="#NOT len(detailVal)#">,
                CURRENT_TIMESTAMP
            )
            RETURNING p_order_id
        </cfquery>
        <cfset savedId = val(ins.p_order_id)>
        <cfset mode    = "added">

        <!--- production_orders_row: sipariş + sipariş satırı ile ilişkilendir --->
        <cfif hasOrderId>
            <cfquery datasource="boyahane">
                INSERT INTO production_orders_row (p_order_id, order_id, order_row_id)
                VALUES (
                    <cfqueryparam value="#savedId#"     cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#orderId#"     cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#orderRowId#"  cfsqltype="cf_sql_integer" null="#NOT hasOrderRowId#">
                )
            </cfquery>
        </cfif>

        <!---
            Reçeteden production_orders_stocks oluştur.
            Her çocuk satır (operation_type_id=0, related_product_tree_id IS NOT NULL)
            için miktarı qty ile ölçekleyerek ekle.
        --->
        <cfquery name="getTree" datasource="boyahane">
            SELECT pt.related_id  AS child_stock_id,
                   pt.product_id  AS child_product_id,
                   COALESCE(pt.amount, 1) AS unit_amount,
                   COALESCE(pt.unit_id, 0) AS unit_id,
                   COALESCE(pt.line_number, 0) AS line_number
            FROM product_tree pt
            WHERE pt.stock_id = <cfqueryparam value="#stockId#" cfsqltype="cf_sql_integer">
              AND (pt.operation_type_id IS NULL OR pt.operation_type_id = 0)
              AND pt.related_product_tree_id IS NOT NULL
              AND pt.related_id IS NOT NULL
            ORDER BY pt.line_number, pt.product_tree_id
        </cfquery>

        <cfset lineIdx = 0>
        <cfloop query="getTree">
            <cfset lineIdx++>
            <cfset compAmount = val(unit_amount) * qty>
            <cfset compProdId = (isNumeric(child_product_id) AND val(child_product_id) gt 0)
                                 ? val(child_product_id) : javaCast("null","")>
            <cfquery datasource="boyahane">
                INSERT INTO production_orders_stocks
                    (p_order_id, stock_id, product_id, amount, product_unit_id, line_number, record_date)
                VALUES (
                    <cfqueryparam value="#savedId#"                          cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#val(child_stock_id)#"              cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#isNull(compProdId)?'':compProdId#" cfsqltype="cf_sql_integer" null="#isNull(compProdId)#">,
                    <cfqueryparam value="#compAmount#"                       cfsqltype="cf_sql_numeric">,
                    <cfqueryparam value="#val(unit_id)#"                     cfsqltype="cf_sql_integer" null="#val(unit_id) eq 0#">,
                    <cfqueryparam value="#lineIdx#"                          cfsqltype="cf_sql_integer">,
                    CURRENT_TIMESTAMP
                )
            </cfquery>
        </cfloop>
    </cfif>

    <cfset response = { "success": true, "p_order_id": savedId, "mode": mode, "p_order_no": orderNo }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfif NOT variables.isIncluded>
    <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
</cfif>