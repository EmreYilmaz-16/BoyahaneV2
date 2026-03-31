<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Üretim emrini plandan kaldır (station_id=NULL, start_date=NULL, finish_date=NULL, status=0)
    POST params: p_order_id
--->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.p_order_id" default="0">

    <cfset pOrderId = isNumeric(form.p_order_id) AND val(form.p_order_id) gt 0 ? val(form.p_order_id) : 0>

    <cfif pOrderId eq 0>
        <cfset response.message = "Geçersiz üretim emri.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery name="chkOrder" datasource="boyahane">
        SELECT p_order_id FROM production_orders
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT chkOrder.recordCount>
        <cfset response.message = "Üretim emri bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        UPDATE production_orders SET
            station_id  = NULL,
            start_date  = NULL,
            finish_date = NULL,
            status      = 1,
            update_date = CURRENT_TIMESTAMP
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
          AND status NOT IN (2, 5)
    </cfquery>

    <cfset response.success = true>
    <cfset response.message = "Emir plandan kaldırıldı.">

<cfcatch type="any">
    <cfset response.message = "Sunucu hatası: " & htmlEditFormat(cfcatch.message)>
</cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
