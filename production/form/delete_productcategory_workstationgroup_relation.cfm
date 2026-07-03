<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfset relId = isDefined("form.id") AND isNumeric(form.id) ? val(form.id) : 0>

    <cfif relId lte 0>
        <cfset response.message = "Geçersiz ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM productcategory_workstationgroup_relation
        WHERE id = <cfqueryparam value="#relId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response = { "success": true }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
