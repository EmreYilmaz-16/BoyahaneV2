<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!--- Sadece status alanını günceller --->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.p_order_id" default="0">
    <cfparam name="form.status"     default="0">

    <cfset pOrderId  = isNumeric(form.p_order_id) AND val(form.p_order_id) gt 0 ? val(form.p_order_id) : 0>
    <cfset newStatus = isNumeric(form.status) ? val(form.status) : 0>

    <cfif pOrderId eq 0 OR NOT listFind("1,2,5,9", newStatus)>
        <cfset response.message = "Geçersiz parametre.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset extraSql = "">
    <cfif newStatus eq 2>
        <!--- Başladı — gerçek başlangıç tarihini yaz --->
        <cfset extraSql = ", start_date_real = CURRENT_TIMESTAMP">
    <cfelseif newStatus eq 5>
        <!--- Tamamlandı — gerçek bitiş tarihini yaz --->
        <cfset extraSql = ", finish_date_real = CURRENT_TIMESTAMP">
    </cfif>

    <cfquery datasource="boyahane">
        UPDATE production_orders
        SET status = <cfqueryparam value="#newStatus#" cfsqltype="cf_sql_integer">,
            update_date = CURRENT_TIMESTAMP
            #extraSql#
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response = { "success": true, "p_order_id": pOrderId, "status": newStatus }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
