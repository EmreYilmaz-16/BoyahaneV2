<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.qc_param_id" default="0">
    <cfset paramId = isNumeric(form.qc_param_id) ? val(form.qc_param_id) : 0>

    <cfif paramId eq 0>
        <cfset response.message = "Geçersiz parametre ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Planlarda kullanılıyor mu kontrol et --->
    <cfquery name="checkUsage" datasource="boyahane">
        SELECT COUNT(*) AS cnt FROM qc_plan_items
        WHERE qc_param_id = <cfqueryparam value="#paramId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif val(checkUsage.cnt) gt 0>
        <cfset response.message = "Bu parametre bir veya daha fazla KK planında kullanılıyor. Önce planlardan kaldırın.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM qc_parameters
        WHERE qc_param_id = <cfqueryparam value="#paramId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response.success = true>
    <cfcatch type="any">
        <cfset response.message = cfcatch.message>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
