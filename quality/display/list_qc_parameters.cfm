<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getParams" datasource="boyahane">
    SELECT qc_param_id, param_code, param_name, param_type,
           COALESCE(unit_name,'')   AS unit_name,
           min_value, max_value,
           is_active, sort_order,
           COALESCE(detail,'')      AS detail,
           record_date
    FROM qc_parameters
    ORDER BY sort_order, param_name
</cfquery>

<cfset paramsArr = []>
<cfloop query="getParams">
    <cfset typeLabel = "">
    <cfswitch expression="#param_type#">
        <cfcase value="1"><cfset typeLabel = "Sayısal"></cfcase>
        <cfcase value="2"><cfset typeLabel = "Geçti/Kaldı"></cfcase>
        <cfcase value="3"><cfset typeLabel = "Metin"></cfcase>
        <cfdefaultcase><cfset typeLabel = "Diğer"></cfdefaultcase>
    </cfswitch>
    <cfset arrayAppend(paramsArr, {
        "qc_param_id" : val(qc_param_id),
        "param_code"  : param_code  ?: "",
        "param_name"  : param_name  ?: "",
        "param_type"  : val(param_type),
        "type_label"  : typeLabel,
        "unit_name"   : unit_name   ?: "",
        "min_value"   : isNumeric(min_value) ? val(min_value) : "",
        "max_value"   : isNumeric(max_value) ? val(max_value) : "",
        "is_active"   : isBoolean(is_active) ? is_active : true,
        "sort_order"  : val(sort_order),
        "detail"      : detail      ?: "",
        "record_date" : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") & " " & timeFormat(record_date,"HH:mm") : ""
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-sliders-h"></i></div>
        <div class="page-header-title">
            <h1>KK Parametreleri</h1>
            <p>Kalite kontrol ölçüm/test parametreleri</p>
        </div>
    </div>
    <button class="btn-add" onclick="addParam()">
        <i class="fas fa-plus"></i>Yeni Parametre
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Parametre eklendi.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Parametre güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Parametre silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </cfif>

    <div class="card">
        <div class="card-body p-0">
            <div id="paramGrid"></div>
        </div>
    </div>
</div>

<!-- Silme Onay Modal -->
<div class="modal fade" id="deleteModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fas fa-exclamation-triangle text-warning me-2"></i>Parametreyi Sil</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <p><strong id="deleteParamName"></strong> parametresini silmek istediğinize emin misiniz?</p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-danger" id="confirmDeleteBtn">Sil</button>
            </div>
        </div>
    </div>
</div>

<script>
var paramsData = #serializeJSON(paramsArr)#;
var deleteModal = null;
var deleteTargetId = 0;

$(function(){
    deleteModal = new bootstrap.Modal(document.getElementById('deleteModal'));

    var grid = new DevExpress.ui.dxDataGrid(document.getElementById('paramGrid'), {
        dataSource: paramsData,
        keyExpr: 'qc_param_id',
        showBorders: true,
        showRowLines: true,
        rowAlternationEnabled: true,
        filterRow: { visible: true },
        headerFilter: { visible: true },
        searchPanel: { visible: true, width: 240 },
        paging: { pageSize: 25 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [25,50,100] },
        columns: [
            { dataField: 'param_code',  caption: 'Kod',        width: 120 },
            { dataField: 'param_name',  caption: 'Parametre Adı', minWidth: 180 },
            { dataField: 'type_label',  caption: 'Tip',        width: 130 },
            { dataField: 'unit_name',   caption: 'Birim',      width: 100 },
            { dataField: 'min_value',   caption: 'Min',        width: 90, dataType: 'number' },
            { dataField: 'max_value',   caption: 'Max',        width: 90, dataType: 'number' },
            {
                dataField: 'is_active', caption: 'Durum', width: 100,
                cellTemplate: function(container, options) {
                    var cls = options.value ? 'badge bg-success' : 'badge bg-secondary';
                    var lbl = options.value ? 'Aktif' : 'Pasif';
                    $('<span>').addClass(cls).text(lbl).appendTo(container);
                }
            },
            { dataField: 'record_date', caption: 'Kayıt Tarihi', width: 130, dataType: 'string' },
            {
                caption: 'İşlemler', width: 100, allowFiltering: false, allowSorting: false,
                cellTemplate: function(container, options) {
                    var d = options.data;
                    $('<button>').addClass('btn btn-sm btn-outline-primary me-1')
                        .html('<i class="fas fa-edit"></i>')
                        .attr('title','Düzenle')
                        .on('click', function(){ editParam(d.qc_param_id); })
                        .appendTo(container);
                    $('<button>').addClass('btn btn-sm btn-outline-danger')
                        .html('<i class="fas fa-trash"></i>')
                        .attr('title','Sil')
                        .on('click', function(){ confirmDelete(d.qc_param_id, d.param_name); })
                        .appendTo(container);
                }
            }
        ]
    });
});

function addParam() {
    window.location.href = 'index.cfm?fuseaction=quality.add_qc_parameter';
}

function editParam(id) {
    window.location.href = 'index.cfm?fuseaction=quality.add_qc_parameter&qc_param_id=' + id;
}

function confirmDelete(id, name) {
    deleteTargetId = id;
    document.getElementById('deleteParamName').textContent = name;
    deleteModal.show();
}

document.getElementById('confirmDeleteBtn').addEventListener('click', function(){
    if (!deleteTargetId) return;
    $.post('index.cfm?fuseaction=quality.delete_qc_parameter', { qc_param_id: deleteTargetId }, function(res){
        var r = typeof res === 'string' ? JSON.parse(res) : res;
        deleteModal.hide();
        if (r.success) {
            window.location.href = 'index.cfm?fuseaction=quality.list_qc_parameters&success=deleted';
        } else {
            alert('Hata: ' + (r.message || 'Silinemedi'));
        }
    });
});
</script>
</cfoutput>
