<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.param_id" default="0">
    <cfset paramId = isNumeric(form.param_id) AND val(form.param_id) gt 0 ? val(form.param_id) : 0>

    <cfif paramId eq 0>
        <cfset response.message = "Geçersiz ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM boyahane_params
        WHERE param_id = <cfqueryparam value="#paramId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfset response = { "success": true }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
