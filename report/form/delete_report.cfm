<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.report_id" default="0">
    <cfset reportId = val(form.report_id)>

    <cfif reportId EQ 0>
        <cfset response.message = "Geçersiz rapor ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="getReport" datasource="boyahane">
        SELECT report_id, cfm_file_name FROM reports
        WHERE report_id = <cfqueryparam value="#reportId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif NOT getReport.recordCount>
        <cfset response.message = "Rapor bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Fiziksel CFM dosyasını sil (varsa) --->
    <cfif len(trim(getReport.cfm_file_name))>
        <cfset cfmPath = expandPath("/report/special_report/") & getReport.cfm_file_name>
        <cfif fileExists(cfmPath)>
            <cffile action="delete" file="#cfmPath#">
        </cfif>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM reports
        WHERE report_id = <cfqueryparam value="#reportId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response.success = true>

    <cfcatch type="any">
        <cfset response.message = cfcatch.message & " " & cfcatch.detail>
        <cflog file="application" type="error" text="delete_report.cfm hata: #cfcatch.message# | #cfcatch.detail#">
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
