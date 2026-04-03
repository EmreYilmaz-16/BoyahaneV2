<cfprocessingdirective pageEncoding="utf-8">

<cfset editMode = structKeyExists(url, "report_id") AND isNumeric(url.report_id) AND val(url.report_id) GT 0>

<cfif editMode>
    <cfquery name="getReport" datasource="boyahane">
        SELECT * FROM reports
        WHERE report_id = <cfqueryparam value="#val(url.report_id)#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getReport.recordCount>
        <cflocation url="index.cfm?fuseaction=report.list_reports" addtoken="false">
    </cfif>
</cfif>

<cffunction name="fv" output="false">
    <cfargument name="col">
    <cfif editMode AND getReport.recordCount>
        <cfreturn htmlEditFormat(getReport[col][1])>
    </cfif>
    <cfreturn "">
</cffunction>
<cffunction name="fb" output="false">
    <cfargument name="col">
    <cfargument name="default" default="false">
    <cfif editMode AND getReport.recordCount>
        <cfreturn getReport[col][1]>
    </cfif>
    <cfreturn arguments.default>
</cffunction>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-chart-bar"></i></div>
        <div class="page-header-info">
            <h1 class="page-title">#editMode ? "Rapor Düzenle" : "Yeni Rapor"#</h1>
            <p class="page-subtitle">#editMode ? "Rapor bilgilerini güncelleyin" : "Sisteme yeni rapor ekleyin"#</p>
        </div>
    </div>
    <div class="page-header-right">
        <a href="index.cfm?fuseaction=report.list_reports" class="btn btn-light">
            <i class="fas fa-arrow-left me-1"></i> Listeye Dön
        </a>
    </div>
</div>

<div class="card shadow-sm">
    <div class="card-body">
        <form id="reportForm" method="post" enctype="multipart/form-data">
            <input type="hidden" name="report_id" value="#editMode ? val(url.report_id) : 0#">

            <div class="row g-3">
                <!--- Sol kolon --->
                <div class="col-md-6">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Rapor Adı <span class="text-danger">*</span></label>
                        <div id="txtReportName"></div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Açıklama</label>
                        <div id="txtReportDetail"></div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">CFM Dosyası Yükle</label>
                        <input type="file" class="form-control" id="cfmFileInput" name="cfm_file" accept=".txt,.cfm">
                        <div class="form-text">
                            <cfif editMode AND len(trim(fv("cfm_file_name")))>
                                Mevcut dosya: <strong>#fv("cfm_file_name")#</strong> &mdash; Yeni dosya seçilirse üzerine yazılır.
                            <cfelse>
                                <code>.cfm</code> veya <code>.txt</code> uzantılı dosya yükleyin (sunucuda .cfm olarak kaydedilir).
                            </cfif>
                        </div>
                    </div>
                </div>

                <!--- Sağ kolon --->
                <div class="col-md-6">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Özel Rapor</label><br>
                        <div id="chkIsSpecial"></div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Rapor Aktif mi?</label><br>
                        <div id="chkReportStatus"></div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Admin Raporu</label><br>
                        <div id="chkAdminStatus"></div>
                    </div>
                </div>
            </div>

            <hr>
            <div class="d-flex gap-2">
                <button type="button" onclick="saveReport()" class="btn btn-primary">
                    <i class="fas fa-save me-1"></i> #editMode ? "Güncelle" : "Kaydet"#
                </button>
                <a href="index.cfm?fuseaction=report.list_reports" class="btn btn-light">
                    <i class="fas fa-times me-1"></i> İptal
                </a>
                <cfif editMode>
                <a href="index.cfm?fuseaction=report.detail_view_report&report_id=#val(url.report_id)#" class="btn btn-info ms-auto">
                    <i class="fas fa-eye me-1"></i> Raporu Görüntüle
                </a>
                </cfif>
            </div>
        </form>
    </div>
</div>

<script>
var editMode = #editMode ? "true" : "false"#;

$(function() {
    $("##txtReportName").dxTextBox({
        value: "#jsstringformat(fv("report_name"))#",
        placeholder: "Raporun adı...",
        stylingMode: "outlined"
    });

    $("##txtReportDetail").dxTextArea({
        value: "#jsstringformat(fv("report_detail"))#",
        placeholder: "Kısa açıklama...",
        stylingMode: "outlined",
        height: 80
    });

    $("##chkIsSpecial").dxCheckBox({
        value: #fb("is_special","false")#,
        text: "Bu rapor özel (dinamik CFM tabanlı) bir rapordur"
    });

    $("##chkReportStatus").dxCheckBox({
        value: #fb("report_status","true")#,
        text: "Aktif — kullanıcılar bu raporu görebilir"
    });

    $("##chkAdminStatus").dxCheckBox({
        value: #fb("admin_status","false")#,
        text: "Yalnızca adminler görebilir"
    });
});

function saveReport() {
    var reportName = $("##txtReportName").dxTextBox("instance").option("value");
    if (!reportName || reportName.trim() === "") {
        DevExpress.ui.notify("Rapor adı zorunludur.", "warning", 2500);
        return;
    }

    var formData = new FormData(document.getElementById("reportForm"));
    formData.set("report_name",   reportName.trim());
    formData.set("report_detail", $("##txtReportDetail").dxTextArea("instance").option("value") || "");
    formData.set("is_special",    $("##chkIsSpecial").dxCheckBox("instance").option("value") ? "true" : "false");
    formData.set("report_status", $("##chkReportStatus").dxCheckBox("instance").option("value") ? "true" : "false");
    formData.set("admin_status",  $("##chkAdminStatus").dxCheckBox("instance").option("value") ? "true" : "false");

    $.ajax({
        url: "index.cfm?fuseaction=report.save_report",
        type: "POST",
        data: formData,
        processData: false,
        contentType: false,
        success: function(resp) {
            var r = typeof resp === "string" ? JSON.parse(resp) : resp;
            if (r.success) {
                var mode = r.mode || (editMode ? "updated" : "added");
                window.location.href = "index.cfm?fuseaction=report.list_reports&success=" + mode;
            } else {
                DevExpress.ui.notify(r.message || "Kayıt başarısız.", "error", 4000);
            }
        },
        error: function() {
            DevExpress.ui.notify("Sunucu hatası oluştu.", "error", 4000);
        }
    });
}
</script>
</cfoutput>
