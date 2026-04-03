<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.form_id" default="0">
    <cfset formId = val(form.form_id)>

    <cfif formId EQ 0>
        <cfset response.message = "Geçersiz şablon ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="getTpl" datasource="boyahane">
        SELECT form_id, template_file FROM setup_print_files
        WHERE form_id = <cfqueryparam value="#formId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif NOT getTpl.recordCount>
        <cfset response.message = "Şablon bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Fiziksel dosyayı sil --->
    <cfif len(trim(getTpl.template_file))>
        <cfset cfmPath = expandPath("/documents/print_files/") & getTpl.template_file>
        <cfif fileExists(cfmPath)>
            <cffile action="delete" file="#cfmPath#">
        </cfif>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM setup_print_files
        WHERE form_id = <cfqueryparam value="#formId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response.success = true>

    <cfcatch type="any">
        <cfset response.message = cfcatch.message & " " & cfcatch.detail>
        <cflog file="application" type="error" text="delete_print_template hata: #cfcatch.message# | #cfcatch.detail#">
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
