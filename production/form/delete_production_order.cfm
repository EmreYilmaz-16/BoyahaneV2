<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.p_order_id" default="0">
    <cfset pOrderId = isNumeric(form.p_order_id) AND val(form.p_order_id) gt 0 ? val(form.p_order_id) : 0>

    <cfif pOrderId eq 0>
        <cfset response.message = "Geçersiz üretim emri ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Tamamlanmış emirleri silmeyi engelle --->
    <cfquery name="chk" datasource="boyahane">
        SELECT status FROM production_orders
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT chk.recordCount>
        <cfset response.message = "Üretim emri bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>
    <cfif val(chk.status) eq 5>
        <cfset response.message = "Tamamlanmış üretim emirleri silinemez.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- CASCADE ile production_orders_stocks ve production_orders_row da silinir --->
    <cfquery datasource="boyahane">
        DELETE FROM production_orders
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response = { "success": true, "p_order_id": pOrderId }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>