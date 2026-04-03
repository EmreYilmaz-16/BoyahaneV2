<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.report_id"     default="0">
    <cfparam name="form.report_name"   default="">
    <cfparam name="form.report_detail" default="">
    <cfparam name="form.is_special"    default="false">
    <cfparam name="form.report_status" default="false">
    <cfparam name="form.admin_status"  default="false">

    <cfset reportId     = val(form.report_id)>
    <cfset reportName   = trim(form.report_name)>
    <cfset reportDetail = trim(form.report_detail)>
    <cfset isSpecial    = (form.is_special    eq "true")>
    <cfset isActive     = (form.report_status eq "true")>
    <cfset isAdmin      = (form.admin_status  eq "true")>
    <cfset editMode     = (reportId GT 0)>

    <cfif len(reportName) EQ 0>
        <cfset response.message = "Rapor adı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- CFM dosyası yükleme --->
    <cfset uploadedFileName = "">
    <cfset uploadDir = expandPath("/report/special_report/")>

    <cftry>
        <cffile action="upload"
                fileField="cfm_file"
                destination="#uploadDir#"
                nameConflict="overwrite">

        <!--- Sadece .cfm ve .txt kabul et --->
        <cfset uploadedExt = lcase(listLast(cffile.clientFile, "."))>
        <cfif NOT listFind("cfm,txt", uploadedExt)>
            <cffile action="delete" file="#cffile.serverDirectory#/#cffile.serverFile#">
            <cfset response.message = "Yalnızca .cfm veya .txt uzantılı dosya yüklenebilir.">
            <cfoutput>#serializeJSON(response)#</cfoutput>
            <cfabort>
        </cfif>

        <!--- Dosyayı GUID ile yeniden adlandır: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.cfm --->
        <cfset guidName = lcase(createUUID()) & ".cfm">
        <cfset destFile = uploadDir & guidName>

        <cffile action="rename"
                source="#cffile.serverDirectory#/#cffile.serverFile#"
                destination="#destFile#"
                nameConflict="overwrite">

        <cfset uploadedFileName = guidName>

        <cfcatch type="any">
            <!--- Dosya seçilmemişse veya upload başarısızsa sessizce geç --->
            <cflog file="application" type="warning" text="save_report upload hata: #cfcatch.message#">
        </cfcatch>
    </cftry>

    <cfif editMode>
        <!--- UPDATE --->
        <cfif len(uploadedFileName)>
            <cfquery datasource="boyahane">
                UPDATE reports SET
                    report_name   = <cfqueryparam value="#reportName#"   cfsqltype="cf_sql_varchar">,
                    report_detail = <cfqueryparam value="#reportDetail#" cfsqltype="cf_sql_varchar">,
                    is_special    = <cfqueryparam value="#isSpecial#"    cfsqltype="cf_sql_boolean">,
                    cfm_file_name = <cfqueryparam value="#uploadedFileName#" cfsqltype="cf_sql_varchar">,
                    report_status = <cfqueryparam value="#isActive#"     cfsqltype="cf_sql_boolean">,
                    admin_status  = <cfqueryparam value="#isAdmin#"      cfsqltype="cf_sql_boolean">,
                    update_date   = CURRENT_TIMESTAMP,
                    update_ip     = <cfqueryparam value="#cgi.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">,
                    update_emp    = <cfqueryparam value="#session.user.id#"  cfsqltype="cf_sql_integer">
                WHERE report_id = <cfqueryparam value="#reportId#" cfsqltype="cf_sql_integer">
            </cfquery>
        <cfelse>
            <cfquery datasource="boyahane">
                UPDATE reports SET
                    report_name   = <cfqueryparam value="#reportName#"   cfsqltype="cf_sql_varchar">,
                    report_detail = <cfqueryparam value="#reportDetail#" cfsqltype="cf_sql_varchar">,
                    is_special    = <cfqueryparam value="#isSpecial#"    cfsqltype="cf_sql_boolean">,
                    report_status = <cfqueryparam value="#isActive#"     cfsqltype="cf_sql_boolean">,
                    admin_status  = <cfqueryparam value="#isAdmin#"      cfsqltype="cf_sql_boolean">,
                    update_date   = CURRENT_TIMESTAMP,
                    update_ip     = <cfqueryparam value="#cgi.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">,
                    update_emp    = <cfqueryparam value="#session.user.id#"  cfsqltype="cf_sql_integer">
                WHERE report_id = <cfqueryparam value="#reportId#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>
        <cfset response.success = true>
        <cfset response.mode    = "updated">
        <cfset response.report_id = reportId>
    <cfelse>
        <!--- INSERT --->
        <cfquery name="insReport" datasource="boyahane" result="insResult">
            INSERT INTO reports (
                report_name, report_detail, is_special,
                cfm_file_name,
                report_status, admin_status,
                record_date, record_ip, record_emp
            ) VALUES (
                <cfqueryparam value="#reportName#"       cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#reportDetail#"     cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#isSpecial#"        cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#uploadedFileName#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#isActive#"         cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#isAdmin#"          cfsqltype="cf_sql_boolean">,
                CURRENT_TIMESTAMP,
                <cfqueryparam value="#cgi.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
            )
            RETURNING report_id
        </cfquery>
        <cfset response.success   = true>
        <cfset response.mode      = "added">
        <cfset response.report_id = val(insResult.generatedKey)>
    </cfif>

    <cfcatch type="any">
        <cfset response.success = false>
        <cfset response.message = cfcatch.message & " " & cfcatch.detail>
        <cflog file="application" type="error" text="save_report.cfm hata: #cfcatch.message# | #cfcatch.detail#">
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
<cfabort>