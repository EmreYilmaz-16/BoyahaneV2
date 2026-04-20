<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>
<cftry>
    <cfparam name="form.qc_plan_id" default="0">
    <cfset planId = isNumeric(form.qc_plan_id) ? val(form.qc_plan_id) : 0>
    <cfif planId eq 0>
        <cfset response.message = "Geçersiz plan ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery name="checkUsage" datasource="boyahane">
        SELECT COUNT(*) AS cnt FROM qc_inspections
        WHERE qc_plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif val(checkUsage.cnt) gt 0>
        <cfset response.message = "Bu plan bir veya daha fazla KK işleminde kullanılıyor. Silinemez.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Kalemler CASCADE ile silinir (FK ON DELETE CASCADE) --->
    <cfquery datasource="boyahane">
        DELETE FROM qc_plans WHERE qc_plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfset response.success = true>
    <cfcatch type="any"><cfset response.message = cfcatch.message></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
