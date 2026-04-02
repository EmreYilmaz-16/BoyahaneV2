<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.report_id" default="0">
<cfset reportId = val(url.report_id)>

<cfif reportId EQ 0>
    <cflocation url="index.cfm?fuseaction=report.list_reports" addtoken="false">
</cfif>

<cfquery name="getReport" datasource="boyahane">
    SELECT
        report_id,
        report_name,
        report_detail,
        is_special,
        cfm_file_name,
        report_status,
        admin_status
    FROM reports
    WHERE report_id = <cfqueryparam value="#reportId#" cfsqltype="cf_sql_integer">
      AND report_status = true
</cfquery>

<cfif NOT getReport.recordCount>
    <cflocation url="index.cfm?fuseaction=report.list_reports&error=notfound" addtoken="false">
</cfif>

<!--- Admin raporu ise sadece adminler görebilir --->
<cfif getReport.admin_status AND NOT (structKeyExists(session,"user") AND session.user.is_admin)>
    <cfoutput>
    <div class="alert alert-danger mt-3">
        <i class="fas fa-lock me-2"></i>Bu raporu görüntüleme yetkiniz bulunmamaktadır.
    </div>
    </cfoutput>
    <cfabort>
</cfif>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-chart-bar"></i></div>
        <div class="page-header-info">
            <h1 class="page-title">#htmlEditFormat(getReport.report_name)#</h1>
            <cfif len(trim(getReport.report_detail))>
            <p class="page-subtitle">#htmlEditFormat(getReport.report_detail)#</p>
            </cfif>
        </div>
    </div>
    <div class="page-header-right">
        <a href="index.cfm?fuseaction=report.list_reports" class="btn btn-light me-2">
            <i class="fas fa-arrow-left me-1"></i> Raporlar
        </a>
        <cfif structKeyExists(session,"user") AND session.user.is_admin>
        <a href="index.cfm?fuseaction=report.add_report&report_id=#reportId#" class="btn btn-warning">
            <i class="fas fa-edit me-1"></i> Düzenle
        </a>
        </cfif>
    </div>
</div>
</cfoutput>

<!---
    =====================================================================
    ÖZEL RAPOR INCLUDE
    Yüklenen CFM dosyası buradan çağrılır.
    Dosya /report/special_report/ klasöründe yer almalıdır.
    =====================================================================
--->
<cfif getReport.is_special AND len(trim(getReport.cfm_file_name))>

    <!--- Güvenlik: yalnızca dosya adı (path traversal engeli) --->
    <cfset safeFileName = getFileFromPath(getReport.cfm_file_name)>
    <cfset safeFileName = reReplace(safeFileName, "[^a-zA-Z0-9_\-\.]", "", "all")>
    <cfset reportPath   = "/report/special_report/" & safeFileName>
    <cfset absPath      = expandPath(reportPath)>

    <cfif fileExists(absPath) AND lcase(listLast(safeFileName,".")) EQ "cfm">
        <cftry>
            <cfinclude template="#reportPath#">
            <cfcatch type="any">
                <div class="alert alert-danger mt-3">
                    <i class="fas fa-exclamation-triangle me-2"></i>
                    Rapor çalıştırılırken bir hata oluştu: <strong><cfoutput>#htmlEditFormat(cfcatch.message)#</cfoutput></strong>
                </div>
            </cfcatch>
        </cftry>
    <cfelse>
        <div class="alert alert-warning mt-3">
            <i class="fas fa-file-times me-2"></i>
            Rapor dosyası (<cfoutput><code>#htmlEditFormat(safeFileName)#</code></cfoutput>) sunucuda bulunamadı.
        </div>
    </cfif>

<cfelse>
    <div class="alert alert-info mt-3">
        <i class="fas fa-info-circle me-2"></i>
        Bu rapor için henüz bir CFM dosyası yüklenmemiştir veya rapor özel rapor olarak işaretlenmemiştir.
        <cfif structKeyExists(session,"user") AND session.user.is_admin>
        <a href="index.cfm?fuseaction=report.add_report&report_id=<cfoutput>#reportId#</cfoutput>" class="alert-link">
            Düzenle &rarr;
        </a>
        </cfif>
    </div>
</cfif>
