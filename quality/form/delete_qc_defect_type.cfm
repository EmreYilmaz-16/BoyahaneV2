<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>
<cftry>
    <cfparam name="form.defect_type_id" default="0">
    <cfset defId = isNumeric(form.defect_type_id) ? val(form.defect_type_id) : 0>

    <cfif defId eq 0>
        <cfset response.message = "Geçersiz hata tipi ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery name="checkUsage" datasource="boyahane">
        SELECT COUNT(*) AS cnt FROM qc_inspection_defects
        WHERE defect_type_id = <cfqueryparam value="#defId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif val(checkUsage.cnt) gt 0>
        <cfset response.message = "Bu hata tipi bir KK işleminde kullanılıyor. Silinemez.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM qc_defect_types
        WHERE defect_type_id = <cfqueryparam value="#defId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfset response.success = true>
    <cfcatch type="any"><cfset response.message = cfcatch.message></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
