<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfset wpId = isDefined("form.ws_p_id") AND isNumeric(form.ws_p_id) ? val(form.ws_p_id) : 0>

    <cfif wpId lte 0>
        <cfset response.message = "Geçersiz ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM workstations_products
        WHERE ws_p_id = <cfqueryparam value="#wpId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response = { "success": true }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>