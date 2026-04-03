<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getTemplates" datasource="boyahane">
    SELECT
        pf.form_id,
        pf.name,
        pf.detail,
        pf.process_type,
        pf.template_file,
        pf.active,
        pf.is_default,
        pf.is_standart,
        pf.record_date,
        COALESCE(pc.print_name, '') AS cat_name
    FROM setup_print_files pf
    LEFT JOIN setup_print_files_cats pc ON pf.process_type = pc.print_type
    ORDER BY pf.process_type, pf.form_id DESC
</cfquery>

<cfset templatesArr = []>
<cfloop query="getTemplates">
    <cfset arrayAppend(templatesArr, {
        "form_id"      : val(form_id),
        "name"         : name         ?: "",
        "detail"       : detail       ?: "",
        "process_type" : val(process_type),
        "cat_name"     : cat_name     ?: "",
        "template_file": template_file ?: "",
        "active"       : active,
        "is_default"   : is_default,
        "is_standart"  : is_standart,
        "record_date"  : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") : ""
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-print"></i></div>
        <div class="page-header-info">
            <h1 class="page-title">Yazdırma Şablonları</h1>
            <p class="page-subtitle">CFM tabanlı belge şablonlarını yönetin</p>
        </div>
    </div>
    <div class="page-header-right">
        <a href="index.cfm?fuseaction=setup.add_print_template" class="btn btn-primary">
            <i class="fas fa-plus me-1"></i> Yeni Şablon
        </a>
    </div>
</div>

<cfif structKeyExists(url,"success")>
    <cfif url.success eq "added">
        <div class="alert alert-success alert-dismissible fade show"><i class="fas fa-check-circle me-2"></i>Şablon eklendi.<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
    <cfelseif url.success eq "updated">
        <div class="alert alert-success alert-dismissible fade show"><i class="fas fa-check-circle me-2"></i>Şablon güncellendi.<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
    <cfelseif url.success eq "deleted">
        <div class="alert alert-success alert-dismissible fade show"><i class="fas fa-trash me-2"></i>Şablon silindi.<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>
    </cfif>
</cfif>

<div class="card shadow-sm">
    <div class="card-body p-0">
        <div id="templatesGrid"></div>
    </div>
</div>

<script>
var templatesData = #serializeJSON(templatesArr)#;

$(function() {
    $("##templatesGrid").dxDataGrid({
        dataSource: templatesData,
        keyExpr: "form_id",
        showBorders: true,
        rowAlternationEnabled: true,
        hoverStateEnabled: true,
        paging: { pageSize: 25 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [10,25,50], showInfo: true },
        searchPanel: { visible: true, placeholder: "Ara..." },
        columns: [
            { dataField: "form_id",       caption: "##",            width: 60, allowSearch: false },
            { dataField: "cat_name",      caption: "Kategori",     width: 170 },
            { dataField: "name",          caption: "Şablon Adı",   minWidth: 180 },
            { dataField: "detail",        caption: "Açıklama",     minWidth: 200 },
            { dataField: "template_file", caption: "Dosya",        width: 300,
              cellTemplate: function(el, info) {
                  el.html(info.value
                      ? '<code class="small">' + info.value + '</code>'
                      : '<span class="text-muted">—</span>');
              }
            },
            {
                dataField: "active", caption: "Aktif", width: 80, alignment: "center",
                cellTemplate: function(el, info) {
                    el.html(info.value
                        ? '<span class="badge bg-success">Aktif</span>'
                        : '<span class="badge bg-secondary">Pasif</span>');
                }
            },
            {
                dataField: "is_default", caption: "Varsayılan", width: 100, alignment: "center",
                cellTemplate: function(el, info) {
                    el.html(info.value ? '<i class="fas fa-star text-warning"></i>' : '');
                }
            },
            { dataField: "record_date", caption: "Tarih", width: 110, allowSearch: false },
            {
                caption: "İşlemler", width: 160, alignment: "center", allowSorting: false,
                cellTemplate: function(el, info) {
                    var id = info.data.form_id;
                    var pt = info.data.process_type;
                    el.html(
                        '<a href="index.cfm?fuseaction=setup.print_document&process_type=' + pt + '&form_id=' + id + '&doc_id=0" target="_blank" class="btn btn-sm btn-info me-1" title="Önizleme"><i class="fas fa-eye"></i></a>' +
                        '<a href="index.cfm?fuseaction=setup.add_print_template&form_id=' + id + '" class="btn btn-sm btn-warning me-1" title="Düzenle"><i class="fas fa-edit"></i></a>' +
                        '<button onclick="deleteTemplate(' + id + ')" class="btn btn-sm btn-danger" title="Sil"><i class="fas fa-trash"></i></button>'
                    );
                }
            }
        ],
        onRowDblClick: function(e) {
            window.location.href = "index.cfm?fuseaction=setup.add_print_template&form_id=" + e.data.form_id;
        }
    });
});

function deleteTemplate(id) {
    DevExpress.ui.dialog.confirm("Bu şablonu silmek istediğinizden emin misiniz?", "Şablon Sil").done(function(result) {
        if (!result) return;
        $.post("index.cfm?fuseaction=setup.delete_print_template", { form_id: id }, function(resp) {
            var r = typeof resp === "string" ? JSON.parse(resp) : resp;
            if (r.success) {
                window.location.href = "index.cfm?fuseaction=setup.list_print_templates&success=deleted";
            } else {
                DevExpress.ui.notify(r.message || "Silinemedi.", "error", 3000);
            }
        });
    });
}
</script>
</cfoutput>
