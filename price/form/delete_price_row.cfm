<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfparam name="form.price_id" default="0">
    <cfset priceId = val(form.price_id)>

    <cfif priceId lte 0>
        <cfoutput>#serializeJSON({"success": false, "message": "Geçersiz fiyat ID."})#</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM price WHERE price_id = <cfqueryparam value="#priceId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>#serializeJSON({"success": true})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success": false, "message": cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
