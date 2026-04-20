<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getPlans" datasource="boyahane">
    SELECT qp.qc_plan_id, qp.plan_code, qp.plan_name, qp.control_type,
           qp.sample_method, qp.sample_value, qp.is_active, qp.record_date,
           COALESCE(p.product_name,'') AS product_name,
           COALESCE(p.product_code,'') AS product_code,
           (SELECT COUNT(*) FROM qc_plan_items qi WHERE qi.qc_plan_id = qp.qc_plan_id) AS item_count
    FROM qc_plans qp
    LEFT JOIN product p ON qp.product_id = p.product_id
    ORDER BY qp.qc_plan_id DESC
</cfquery>

<cfset plansArr = []>
<cfloop query="getPlans">
    <cfset ctLabel = ""><cfset smLabel = "">
    <cfswitch expression="#control_type#">
        <cfcase value="1"><cfset ctLabel = "Giriş Kontrol"></cfcase>
        <cfcase value="2"><cfset ctLabel = "Operasyon Kontrol"></cfcase>
        <cfcase value="3"><cfset ctLabel = "Final Kontrol"></cfcase>
        <cfdefaultcase><cfset ctLabel = "Diğer"></cfdefaultcase>
    </cfswitch>
    <cfswitch expression="#sample_method#">
        <cfcase value="1"><cfset smLabel = "Sabit Miktar"></cfcase>
        <cfcase value="2"><cfset smLabel = "Yüzde (%)"></cfcase>
        <cfcase value="3"><cfset smLabel = "Tümü"></cfcase>
    </cfswitch>
    <cfset arrayAppend(plansArr, {
        "qc_plan_id"   : val(qc_plan_id),
        "plan_code"    : plan_code    ?: "",
        "plan_name"    : plan_name    ?: "",
        "control_type" : val(control_type),
        "ct_label"     : ctLabel,
        "sample_method": val(sample_method),
        "sm_label"     : smLabel,
        "sample_value" : isNumeric(sample_value) ? val(sample_value) : "",
        "product_name" : product_name ?: "",
        "product_code" : product_code ?: "",
        "is_active"    : isBoolean(is_active) ? is_active : true,
        "item_count"   : val(item_count),
        "record_date"  : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") : ""
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-clipboard-list"></i></div>
        <div class="page-header-title">
            <h1>KK Planları</h1>
            <p>Ürün bazlı kalite kontrol planları</p>
        </div>
    </div>
    <button class="btn-add" onclick="addPlan()">
        <i class="fas fa-plus"></i>Yeni Plan
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Plan eklendi.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Plan güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Plan silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </cfif>

    <div class="card">
        <div class="card-body p-0">
            <div id="planGrid"></div>
        </div>
    </div>
</div>

<div class="modal fade" id="deleteModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fas fa-exclamation-triangle text-warning me-2"></i>Planı Sil</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <p><strong id="deletePlanName"></strong> planını ve tüm kalemlerini silmek istiyor musunuz?</p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-danger" id="confirmDeleteBtn">Sil</button>
            </div>
        </div>
    </div>
</div>

<script>
var plansData = #serializeJSON(plansArr)#;
var deleteModal = null;
var deleteTargetId = 0;

$(function(){
    deleteModal = new bootstrap.Modal(document.getElementById('deleteModal'));

    new DevExpress.ui.dxDataGrid(document.getElementById('planGrid'), {
        dataSource: plansData,
        keyExpr: 'qc_plan_id',
        showBorders: true,
        showRowLines: true,
        rowAlternationEnabled: true,
        filterRow: { visible: true },
        searchPanel: { visible: true, width: 240 },
        paging: { pageSize: 25 },
        columns: [
            { dataField: 'plan_code',    caption: 'Plan Kodu',    width: 130 },
            { dataField: 'plan_name',    caption: 'Plan Adı',     minWidth: 160 },
            { dataField: 'ct_label',     caption: 'Kontrol Tipi', width: 160 },
            { dataField: 'product_name', caption: 'Ürün',         minWidth: 150 },
            { dataField: 'sm_label',     caption: 'Numune Yöntemi', width: 140 },
            { dataField: 'sample_value', caption: 'Numune Değeri', width: 120, dataType: 'number' },
            { dataField: 'item_count',   caption: 'Parametre Sayısı', width: 140, dataType: 'number' },
            {
                dataField: 'is_active', caption: 'Durum', width: 90,
                cellTemplate: function(c,o){ $('<span>').addClass(o.value?'badge bg-success':'badge bg-secondary').text(o.value?'Aktif':'Pasif').appendTo(c); }
            },
            { dataField: 'record_date', caption: 'Tarih', width: 110 },
            {
                caption: 'İşlemler', width: 120, allowFiltering: false, allowSorting: false,
                cellTemplate: function(container, options) {
                    var d = options.data;
                    $('<button>').addClass('btn btn-sm btn-outline-info me-1').html('<i class="fas fa-list"></i>')
                        .attr('title','Kalemler').on('click', function(){ editPlan(d.qc_plan_id); }).appendTo(container);
                    $('<button>').addClass('btn btn-sm btn-outline-danger').html('<i class="fas fa-trash"></i>')
                        .attr('title','Sil').on('click', function(){ confirmDelete(d.qc_plan_id, d.plan_name); }).appendTo(container);
                }
            }
        ]
    });
});

function addPlan()    { window.location.href = 'index.cfm?fuseaction=quality.add_qc_plan'; }
function editPlan(id) { window.location.href = 'index.cfm?fuseaction=quality.add_qc_plan&qc_plan_id=' + id; }

function confirmDelete(id, name) {
    deleteTargetId = id;
    document.getElementById('deletePlanName').textContent = name;
    deleteModal.show();
}

document.getElementById('confirmDeleteBtn').addEventListener('click', function(){
    if (!deleteTargetId) return;
    $.post('index.cfm?fuseaction=quality.delete_qc_plan', { qc_plan_id: deleteTargetId }, function(res){
        var r = typeof res === 'string' ? JSON.parse(res) : res;
        deleteModal.hide();
        if (r.success) {
            window.location.href = 'index.cfm?fuseaction=quality.list_qc_plans&success=deleted';
        } else {
            alert('Hata: ' + (r.message || 'Silinemedi'));
        }
    });
});
</script>
</cfoutput>
