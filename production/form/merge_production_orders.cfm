<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.p_order_ids" default="">
    <cfparam name="form.target_p_order_id" default="0">

    <cfset rawIds = listToArray(form.p_order_ids)>
    <cfset orderIds = []>
    <cfloop array="#rawIds#" index="rawId">
        <cfif isNumeric(trim(rawId)) AND val(trim(rawId)) gt 0 AND NOT arrayFind(orderIds, val(trim(rawId)))>
            <cfset arrayAppend(orderIds, val(trim(rawId)))>
        </cfif>
    </cfloop>

    <cfif arrayLen(orderIds) lt 2>
        <cfset response.message = "Birleştirmek için en az iki geçerli üretim emri seçilmelidir.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset targetId = isNumeric(form.target_p_order_id) AND val(form.target_p_order_id) gt 0 ? val(form.target_p_order_id) : orderIds[1]>
    <cfif NOT arrayFind(orderIds, targetId)>
        <cfset targetId = orderIds[1]>
    </cfif>

    <cfquery name="getOrders" datasource="boyahane">
        SELECT p_order_id, p_order_no, COALESCE(quantity, 0) AS quantity
        FROM production_orders
        WHERE p_order_id IN (<cfqueryparam value="#arrayToList(orderIds)#" cfsqltype="cf_sql_integer" list="true">)
    </cfquery>

    <cfif getOrders.recordCount neq arrayLen(orderIds)>
        <cfset response.message = "Seçilen üretim emirlerinden bazıları bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset sourceIds = []>
    <cfset sourceLabels = []>
    <cfset totalQty = 0>
    <cfloop query="getOrders">
        <cfset totalQty += val(quantity)>
        <cfif val(p_order_id) neq targetId>
            <cfset arrayAppend(sourceIds, val(p_order_id))>
            <cfset arrayAppend(sourceLabels, len(trim(p_order_no)) ? trim(p_order_no) : "##" & val(p_order_id))>
        </cfif>
    </cfloop>

    <cfif arrayLen(sourceIds) lt 1>
        <cfset response.message = "Hedef emir dışında birleştirilecek üretim emri bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cftransaction>
        <cfquery datasource="boyahane">
            UPDATE production_orders
            SET quantity = <cfqueryparam value="#totalQty#" cfsqltype="cf_sql_numeric">,
                detail = COALESCE(detail, '') ||
                         <cfqueryparam value="#chr(10)#Birleştirilen emirler: #arrayToList(sourceLabels, ', ')#" cfsqltype="cf_sql_varchar">,
                update_date = CURRENT_TIMESTAMP
            WHERE p_order_id = <cfqueryparam value="#targetId#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfquery datasource="boyahane">
            UPDATE production_orders_stocks
            SET p_order_id = <cfqueryparam value="#targetId#" cfsqltype="cf_sql_integer">
            WHERE p_order_id IN (<cfqueryparam value="#arrayToList(sourceIds)#" cfsqltype="cf_sql_integer" list="true">)
        </cfquery>

        <cfquery datasource="boyahane">
            UPDATE production_orders_stocks pos
            SET amount = agg.total_amount
            FROM (
                SELECT MIN(por_stock_id) AS keep_id, SUM(COALESCE(amount, 0)) AS total_amount
                FROM production_orders_stocks
                WHERE p_order_id = <cfqueryparam value="#targetId#" cfsqltype="cf_sql_integer">
                GROUP BY COALESCE(stock_id, 0), COALESCE(product_id, 0), COALESCE(product_unit_id, 0)
            ) agg
            WHERE pos.por_stock_id = agg.keep_id
        </cfquery>

        <cfquery datasource="boyahane">
            DELETE FROM production_orders_stocks a
            USING production_orders_stocks b
            WHERE a.p_order_id = <cfqueryparam value="#targetId#" cfsqltype="cf_sql_integer">
              AND b.p_order_id = <cfqueryparam value="#targetId#" cfsqltype="cf_sql_integer">
              AND a.por_stock_id > b.por_stock_id
              AND COALESCE(a.stock_id, 0) = COALESCE(b.stock_id, 0)
              AND COALESCE(a.product_id, 0) = COALESCE(b.product_id, 0)
              AND COALESCE(a.product_unit_id, 0) = COALESCE(b.product_unit_id, 0)
        </cfquery>

        <cfquery datasource="boyahane">
            UPDATE production_orders_row
            SET p_order_id = <cfqueryparam value="#targetId#" cfsqltype="cf_sql_integer">
            WHERE p_order_id IN (<cfqueryparam value="#arrayToList(sourceIds)#" cfsqltype="cf_sql_integer" list="true">)
        </cfquery>

        <cfquery datasource="boyahane">
            UPDATE production_orders
            SET status = 9,
                detail = COALESCE(detail, '') ||
                         <cfqueryparam value="#chr(10)#Bu emir ## #targetId# üretim emrine birleştirildi." cfsqltype="cf_sql_varchar">,
                update_date = CURRENT_TIMESTAMP
            WHERE p_order_id IN (<cfqueryparam value="#arrayToList(sourceIds)#" cfsqltype="cf_sql_integer" list="true">)
        </cfquery>
    </cftransaction>

    <cfset response = {
        "success": true,
        "message": arrayLen(orderIds) & " üretim emri birleştirildi.",
        "target_p_order_id": targetId,
        "merged_p_order_ids": sourceIds,
        "quantity": totalQty
    }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
