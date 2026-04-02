<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getReports" datasource="boyahane">
    SELECT
        r.report_id,
        r.report_name,
        r.report_detail,
        r.is_special,
        r.cfm_file_name,
        r.report_status,
        r.admin_status,
        r.record_date
    FROM reports r
    ORDER BY r.report_id DESC
</cfquery>

<cfset reportsArr = []>
<cfloop query="getReports">
    <cfset arrayAppend(reportsArr, {
        "report_id"    : val(report_id),
        "report_name"  : report_name   ?: "",
        "report_detail": report_detail ?: "",
        "is_special"   : is_special,
        "cfm_file_name": cfm_file_name ?: "",
        "report_status": report_status,
        "admin_status" : admin_status,
        "record_date"  : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") : ""
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-chart-bar"></i></div>
        <div class="page-header-info">
            <h1 class="page-title">Raporlar</h1>
            <p class="page-subtitle">Sisteme tanımlı raporların listesi</p>
        </div>
    </div>
    <div class="page-header-right">
        <a href="index.cfm?fuseaction=report.add_report" class="btn btn-primary">
            <i class="fas fa-plus me-1"></i> Yeni Rapor
        </a>
    </div>
</div>

<cfif structKeyExists(url,"success")>
    <cfif url.success eq "added">
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="fas fa-check-circle me-2"></i>Rapor başarıyla eklendi.
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <cfelseif url.success eq "updated">
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="fas fa-check-circle me-2"></i>Rapor başarıyla güncellendi.
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <cfelseif url.success eq "deleted">
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="fas fa-trash me-2"></i>Rapor silindi.
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </cfif>
</cfif>

<div class="card shadow-sm">
    <div class="card-body p-0">
        <div id="reportsGrid"></div>
    </div>
</div>

<script>
var reportsData = #serializeJSON(reportsArr)#;

$(function () {
    $("#reportsGrid").dxDataGrid({
        dataSource: reportsData,
        keyExpr: "report_id",
        showBorders: true,
        rowAlternationEnabled: true,
        hoverStateEnabled: true,
        paging: { pageSize: 25 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [10,25,50,100], showInfo: true },
        searchPanel: { visible: true, placeholder: "Ara..." },
        sorting: { mode: "multiple" },
        columns: [
            { dataField: "report_id",    caption: "#",           width: 60,  allowSearch: false },
            { dataField: "report_name",  caption: "Rapor Adı",   minWidth: 180 },
            { dataField: "report_detail",caption: "Açıklama",    minWidth: 220 },
            {
                dataField: "is_special",
                caption: "Özel Rapor",
                width: 100,
                alignment: "center",
                cellTemplate: function(el, info) {
                    el.html(info.value
                        ? '<span class="badge bg-info">Özel</span>'
                        : '<span class="badge bg-secondary">Standart</span>');
                }
            },
            { dataField: "cfm_file_name", caption: "CFM Dosyası", width: 200 },
            {
                dataField: "report_status",
                caption: "Aktif",
                width: 80,
                alignment: "center",
                cellTemplate: function(el, info) {
                    el.html(info.value
                        ? '<span class="badge bg-success">Aktif</span>'
                        : '<span class="badge bg-warning text-dark">Pasif</span>');
                }
            },
            { dataField: "record_date", caption: "Kayıt Tarihi", width: 120, allowSearch: false },
            {
                caption: "İşlemler",
                width: 160,
                alignment: "center",
                allowSorting: false,
                cellTemplate: function(el, info) {
                    var id = info.data.report_id;
                    el.html(
                        '<a href="index.cfm?fuseaction=report.detail_view_report&report_id=' + id + '" class="btn btn-sm btn-info me-1" title="Görüntüle"><i class="fas fa-eye"></i></a>' +
                        '<a href="index.cfm?fuseaction=report.add_report&report_id=' + id + '" class="btn btn-sm btn-warning me-1" title="Düzenle"><i class="fas fa-edit"></i></a>' +
                        '<button onclick="deleteReport(' + id + ')" class="btn btn-sm btn-danger" title="Sil"><i class="fas fa-trash"></i></button>'
                    );
                }
            }
        ],
        onRowDblClick: function(e) {
            window.location.href = "index.cfm?fuseaction=report.detail_view_report&report_id=" + e.data.report_id;
        }
    });
});

function deleteReport(id) {
    DevExpress.ui.dialog.confirm("Bu raporu silmek istediğinizden emin misiniz?", "Rapor Sil").done(function(result) {
        if (result) {
            $.post("index.cfm?fuseaction=report.delete_report", { report_id: id }, function(resp) {
                var r = typeof resp === "string" ? JSON.parse(resp) : resp;
                if (r.success) {
                    window.location.href = "index.cfm?fuseaction=report.list_reports&success=deleted";
                } else {
                    DevExpress.ui.notify(r.message || "Silinemedi.", "error", 3000);
                }
            });
        }
    });
}
</script>
</cfoutput>
