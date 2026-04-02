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
    <cfif structKeyExists(form, "cfm_file") AND len(trim(form.cfm_file)) GT 0>
        <!--- form.cfm_file dolu olduğunda cffile işlemi yapılmaz; gerçek upload FORM alanı üzerinden gelir --->
    </cfif>

    <cfif isDefined("cffile") AND structKeyExists(cffile,"serverFile")>
        <!--- cffile zaten çalıştıysa (custom tag yöntemi) --->
        <cfset uploadedFileName = cffile.serverFile>
    <cfelseif structKeyExists(FORM,"cfm_file") AND len(trim(FORM.cfm_file)) GT 0>
        <!--- Lucee multipart: FORM.cfm_file dosya adını tutar --->
        <cfset tempFilePath = GetTempDirectory() & FORM.cfm_file>
        <cfset uploadDir = expandPath("/report/special_report/")>

        <!--- Uzantı kontrolü --->
        <cfif lcase(listLast(FORM.cfm_file,".")) NEQ "cfm">
            <cfset response.message = "Yalnızca .cfm uzantılı dosya yüklenebilir.">
            <cfoutput>#serializeJSON(response)#</cfoutput>
            <cfabort>
        </cfif>

        <!--- Güvenli dosya adı: yalnızca harf/rakam/tire/alt çizgi --->
        <cfset safeName = reReplace(listFirst(FORM.cfm_file,"."),"[^a-zA-Z0-9_\-]","_","all") & ".cfm">

        <cffile action="move" source="#tempFilePath#" destination="#uploadDir##safeName#" nameconflict="overwrite">
        <cfset uploadedFileName = safeName>
    </cfif>

    <!--- Gerçek Lucee multipart upload --->
    <cfif NOT len(uploadedFileName) AND isDefined("form") AND structKeyExists(form,"cfm_file")>
        <cfset uploadDir = expandPath("/report/special_report/")>
        <cftry>
            <cffile action="upload"
                    fileField="cfm_file"
                    destination="#uploadDir#"
                    nameConflict="overwrite"
                    accept=".cfm,text/plain,text/html">

            <cfif lcase(listLast(cffile.serverFile,".")) NEQ "cfm">
                <cffile action="delete" file="#cffile.serverDirectory#/#cffile.serverFile#">
                <cfset response.message = "Yalnızca .cfm uzantılı dosya yüklenebilir.">
                <cfoutput>#serializeJSON(response)#</cfoutput>
                <cfabort>
            </cfif>

            <!--- Güvenli dosya adı --->
            <cfset safeName = reReplace(listFirst(cffile.serverFile,"."),"[^a-zA-Z0-9_\-]","_","all") & ".cfm">
            <cfif safeName NEQ cffile.serverFile>
                <cffile action="rename"
                        source="#cffile.serverDirectory#/#cffile.serverFile#"
                        destination="#cffile.serverDirectory#/#safeName#"
                        nameConflict="overwrite">
            </cfif>
            <cfset uploadedFileName = safeName>
            <cfcatch type="any">
                <!--- Dosya yüklenmemişse sessizce geç --->
            </cfcatch>
        </cftry>
    </cfif>

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
        <cfset response.report_id = val(insReport.report_id)>
    </cfif>

    <cfcatch type="any">
        <cfset response.message = cfcatch.message & " " & cfcatch.detail>
        <cflog file="application" type="error" text="save_report.cfm hata: #cfcatch.message# | #cfcatch.detail#">
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
