<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfparam name="form.order_id" default="0">
    <cfset orderId = val(form.order_id)>

    <cfif orderId lte 0>
        <cfoutput>#serializeJSON({"success": false, "message": "Geçersiz sipariş ID."})#</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM orders WHERE order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>#serializeJSON({"success": true})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success": false, "message": cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
