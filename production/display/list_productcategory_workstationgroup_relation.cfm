<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getRelations" datasource="boyahane">
    SELECT rel.id,
           rel.product_catid,
           rel.workstation_id,
           COALESCE(pc.product_cat, '') AS product_cat,
           COALESCE(pc.hierarchy, '')   AS hierarchy,
           COALESCE(ws.station_name, '') AS station_name,
           COALESCE(rel.record_date, CURRENT_TIMESTAMP) AS record_date
    FROM productcategory_workstationgroup_relation rel
    LEFT JOIN product_cat pc ON rel.product_catid = pc.product_catid
    LEFT JOIN workstations ws ON rel.workstation_id = ws.station_id
    ORDER BY rel.id DESC
</cfquery>

<cfset relArr = []>
<cfloop query="getRelations">
    <cfset arrayAppend(relArr, {
        "id": isNumeric(id) ? val(id) : 0,
        "product_catid": isNumeric(product_catid) ? val(product_catid) : 0,
        "workstation_id": isNumeric(workstation_id) ? val(workstation_id) : 0,
        "product_cat": product_cat ?: "",
        "hierarchy": hierarchy ?: "",
        "category_display": (len(trim(hierarchy)) ? trim(hierarchy) & " - " : "") & (product_cat ?: ""),
        "station_name": station_name ?: "",
        "record_date": isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-link"></i></div>
        <div class="page-header-title">
            <h1>Kategori - İş İstasyonu Eşleştirmeleri</h1>
            <p>Ürün kategorileri ile iş istasyonları arasındaki ilişkiler</p>
        </div>
    </div>
    <button class="btn-add" onclick="addRelation()">
        <i class="fas fa-plus"></i>Yeni Eşleştirme
    </button>
</div>

<div class="px-3 pb-5">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Eşleştirme oluşturuldu.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Eşleştirme güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Eşleştirme silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Eşleştirme Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="relationGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var relationData = #serializeJSON(relArr)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $('##relationGrid').dxDataGrid({
            dataSource: relationData,
            keyExpr: 'id',
            showBorders: true,
            showRowLines: true,
            showColumnLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            allowColumnReordering: true,
            allowColumnResizing: true,
            columnResizingMode: 'widget',
            width: '100%',
            height: 'auto',
            scrolling: { mode: 'virtual', rowRenderingMode: 'virtual' },
            paging: { pageSize: 50 },
            pager: { visible: true, allowedPageSizes: [10,25,50,100], showPageSizeSelector: true, showNavigationButtons: true, showInfo: true, infoText: 'Sayfa {0}/{1} ({2} kayıt)' },
            filterRow: { visible: true },
            headerFilter: { visible: true },
            searchPanel: { visible: true, width: 260, placeholder: 'Kategori veya istasyon ara...' },
            sorting: { mode: 'multiple' },
            columnChooser: { enabled: true, mode: 'select', title: 'Sütun Seçimi' },
            export: { enabled: true },
            onExporting: function (e) {
                var workbook = new ExcelJS.Workbook();
                var worksheet = workbook.addWorksheet('KategoriIstasyonEslesmeleri');
                DevExpress.excelExporter.exportDataGrid({
                    component: e.component,
                    worksheet: worksheet,
                    autoFilterEnabled: true
                }).then(function () {
                    workbook.xlsx.writeBuffer().then(function (buffer) {
                        var fileName = 'kategori_istasyon_eslesmeleri_' + new Date().toISOString().slice(0, 10) + '.xlsx';
                        saveAs(new Blob([buffer], { type: 'application/octet-stream' }), fileName);
                    });
                });
                e.cancel = true;
            },
            onRowDblClick: function(e) { editRelation(e.data.id); },
            onContentReady: function(e) {
                document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt';
            },
            columns: [
                { dataField: 'id', caption: 'ID', width: 70, alignment: 'center', dataType: 'number', sortOrder: 'desc' },
                { dataField: 'category_display', caption: 'Ürün Kategorisi', minWidth: 260,
                    cellTemplate: function(c, o) {
                        $('<a>').attr('href', 'javascript:void(0)').css({fontWeight: 'bold', cursor: 'pointer'})
                            .text(o.value || '-')
                            .on('click', function(){ editRelation(o.data.id); })
                            .appendTo(c);
                    }
                },
                { dataField: 'station_name', caption: 'İş İstasyonu', minWidth: 180 },
                { dataField: 'record_date', caption: 'Kayıt Tarihi', width: 145 },
                {
                    caption: 'İşlemler', width: 100, alignment: 'center', allowSorting: false, allowFiltering: false,
                    cellTemplate: function(c, o) {
                        var g = $('<div>').addClass('d-flex gap-1 justify-content-center');
                        $('<button>').addClass('btn btn-sm btn-outline-primary').attr('title', 'Düzenle').html('<i class="fas fa-edit"></i>')
                            .on('click', function(){ editRelation(o.data.id); }).appendTo(g);
                        $('<button>').addClass('btn btn-sm btn-outline-danger').attr('title', 'Sil').html('<i class="fas fa-trash"></i>')
                            .on('click', function(){ deleteRelation(o.data.id, o.data.category_display, o.data.station_name); }).appendTo(g);
                        g.appendTo(c);
                    }
                }
            ],
            summary: {
                totalItems: [{ column: 'id', summaryType: 'count', displayFormat: '{0} eşleştirme' }]
            }
        });
    }
});

function addRelation()    { window.location.href = 'index.cfm?fuseaction=production.add_productcategory_workstationgroup_relation'; }
function editRelation(id) { window.location.href = 'index.cfm?fuseaction=production.add_productcategory_workstationgroup_relation&id=' + id; }

function deleteRelation(id, categoryLabel, stationName) {
    var label = (categoryLabel || 'Kayıt') + ' → ' + (stationName || 'İstasyon');
    DevExpress.ui.dialog.confirm('"' + label + '" eşleştirmesini silmek istiyor musunuz?', 'Silme Onayı')
        .then(function(ok) {
            if (!ok) return;
            $.post('/production/form/delete_productcategory_workstationgroup_relation.cfm', { id: id }, function(res) {
                if (res && res.success) {
                    DevExpress.ui.notify('Eşleştirme silindi.', 'success', 2500);
                    relationData = relationData.filter(function(x){ return x.id != id; });
                    $('##relationGrid').dxDataGrid('instance').option('dataSource', relationData);
                    document.getElementById('recordCount').textContent = relationData.length + ' kayıt';
                } else {
                    DevExpress.ui.notify((res && res.message) || 'Silme başarısız.', 'error', 3500);
                }
            }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); });
        });
}
</script>
</cfoutput>
