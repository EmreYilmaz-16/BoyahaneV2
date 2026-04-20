<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>
<cftry>
    <cfparam name="form.qc_inspection_id" default="0">
    <cfset inspId = isNumeric(form.qc_inspection_id) ? val(form.qc_inspection_id) : 0>
    <cfif inspId eq 0>
        <cfset response.message = "Geçersiz muayene ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Soft delete (is_active = false) --->
    <cfquery datasource="boyahane">
        UPDATE qc_inspections SET is_active = false
        WHERE qc_inspection_id = <cfqueryparam value="#inspId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfset response.success = true>
    <cfcatch type="any"><cfset response.message = cfcatch.message></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
