<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getDefects" datasource="boyahane">
    SELECT defect_type_id, defect_code, defect_name, severity, is_active,
           sort_order, COALESCE(detail,'') AS detail, record_date
    FROM qc_defect_types
    ORDER BY sort_order, defect_name
</cfquery>

<cfset defectsArr = []>
<cfloop query="getDefects">
    <cfset sevLabel = ""><cfset sevClass = "">
    <cfswitch expression="#severity#">
        <cfcase value="1"><cfset sevLabel = "Hafif">  <cfset sevClass = "bg-info"></cfcase>
        <cfcase value="2"><cfset sevLabel = "Orta">   <cfset sevClass = "bg-warning text-dark"></cfcase>
        <cfcase value="3"><cfset sevLabel = "Ciddi">  <cfset sevClass = "bg-orange" ></cfcase>
        <cfcase value="4"><cfset sevLabel = "Kritik"> <cfset sevClass = "bg-danger"></cfcase>
        <cfdefaultcase><cfset sevLabel = "?"><cfset sevClass = "bg-secondary"></cfdefaultcase>
    </cfswitch>
    <cfset arrayAppend(defectsArr, {
        "defect_type_id" : val(defect_type_id),
        "defect_code"    : defect_code  ?: "",
        "defect_name"    : defect_name  ?: "",
        "severity"       : val(severity),
        "sev_label"      : sevLabel,
        "sev_class"      : sevClass,
        "is_active"      : isBoolean(is_active) ? is_active : true,
        "sort_order"     : val(sort_order),
        "detail"         : detail       ?: "",
        "record_date"    : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") & " " & timeFormat(record_date,"HH:mm") : ""
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-bug"></i></div>
        <div class="page-header-title">
            <h1>Hata Tipleri</h1>
            <p>Kalite kontrol hata/kusur tip tanımları</p>
        </div>
    </div>
    <button class="btn-add" onclick="addDefect()">
        <i class="fas fa-plus"></i>Yeni Hata Tipi
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Hata tipi eklendi.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Hata tipi güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Hata tipi silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </cfif>

    <div class="card">
        <div class="card-body p-0">
            <div id="defectGrid"></div>
        </div>
    </div>
</div>

<div class="modal fade" id="deleteModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fas fa-exclamation-triangle text-warning me-2"></i>Hata Tipini Sil</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <p><strong id="deleteDefectName"></strong> hata tipini silmek istediğinize emin misiniz?</p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-danger" id="confirmDeleteBtn">Sil</button>
            </div>
        </div>
    </div>
</div>

<script>
var defectsData = #serializeJSON(defectsArr)#;
var deleteModal = null;
var deleteTargetId = 0;

$(function(){
    deleteModal = new bootstrap.Modal(document.getElementById('deleteModal'));

    new DevExpress.ui.dxDataGrid(document.getElementById('defectGrid'), {
        dataSource: defectsData,
        keyExpr: 'defect_type_id',
        showBorders: true,
        showRowLines: true,
        rowAlternationEnabled: true,
        filterRow: { visible: true },
        searchPanel: { visible: true, width: 240 },
        paging: { pageSize: 25 },
        columns: [
            { dataField: 'defect_code', caption: 'Kod',       width: 120 },
            { dataField: 'defect_name', caption: 'Hata Adı',  minWidth: 180 },
            {
                dataField: 'sev_label', caption: 'Ağırlık', width: 110,
                cellTemplate: function(container, options) {
                    var d = options.data;
                    $('<span>').addClass('badge ' + d.sev_class).text(d.sev_label).appendTo(container);
                }
            },
            {
                dataField: 'is_active', caption: 'Durum', width: 100,
                cellTemplate: function(container, options) {
                    var cls = options.value ? 'badge bg-success' : 'badge bg-secondary';
                    $('<span>').addClass(cls).text(options.value ? 'Aktif' : 'Pasif').appendTo(container);
                }
            },
            { dataField: 'sort_order',  caption: 'Sıra', width: 80 },
            { dataField: 'record_date', caption: 'Kayıt',  width: 130 },
            {
                caption: 'İşlemler', width: 100, allowFiltering: false, allowSorting: false,
                cellTemplate: function(container, options) {
                    var d = options.data;
                    $('<button>').addClass('btn btn-sm btn-outline-primary me-1')
                        .html('<i class="fas fa-edit"></i>')
                        .on('click', function(){ editDefect(d.defect_type_id); })
                        .appendTo(container);
                    $('<button>').addClass('btn btn-sm btn-outline-danger')
                        .html('<i class="fas fa-trash"></i>')
                        .on('click', function(){ confirmDelete(d.defect_type_id, d.defect_name); })
                        .appendTo(container);
                }
            }
        ]
    });
});

function addDefect()   { window.location.href = 'index.cfm?fuseaction=quality.add_qc_defect_type'; }
function editDefect(id){ window.location.href = 'index.cfm?fuseaction=quality.add_qc_defect_type&defect_type_id=' + id; }

function confirmDelete(id, name) {
    deleteTargetId = id;
    document.getElementById('deleteDefectName').textContent = name;
    deleteModal.show();
}

document.getElementById('confirmDeleteBtn').addEventListener('click', function(){
    if (!deleteTargetId) return;
    $.post('index.cfm?fuseaction=quality.delete_qc_defect_type', { defect_type_id: deleteTargetId }, function(res){
        var r = typeof res === 'string' ? JSON.parse(res) : res;
        deleteModal.hide();
        if (r.success) {
            window.location.href = 'index.cfm?fuseaction=quality.list_qc_defect_types&success=deleted';
        } else {
            alert('Hata: ' + (r.message || 'Silinemedi'));
        }
    });
});
</script>
</cfoutput>
