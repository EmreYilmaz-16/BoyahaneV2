<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getInspections" datasource="boyahane">
    SELECT qi.qc_inspection_id, qi.inspection_no, qi.inspection_type,
           qi.lot_no, qi.quantity, qi.sample_quantity,
           qi.inspection_date, qi.inspector_name,
           qi.result, qi.record_date,
           COALESCE(p.product_name,'') AS product_name,
           COALESCE(p.product_code,'') AS product_code,
           COALESCE(sh.ship_number,'') AS ship_number,
           COALESCE(po.p_order_no,'')  AS p_order_no,
           COALESCE(sc.nickname, sc.fullname, poc.nickname, poc.fullname, '') AS company_name
    FROM qc_inspections qi
    LEFT JOIN product           p   ON qi.product_id  = p.product_id
    LEFT JOIN ship              sh  ON qi.ship_id      = sh.ship_id
    LEFT JOIN company           sc  ON sh.company_id   = sc.company_id
    LEFT JOIN production_orders po  ON qi.p_order_id  = po.p_order_id
    LEFT JOIN stocks            st  ON po.stock_id     = st.stock_id
    LEFT JOIN color_info        ci  ON st.stock_id     = ci.stock_id
    LEFT JOIN company           poc ON ci.company_id   = poc.company_id
    WHERE qi.is_active = true
    ORDER BY qi.qc_inspection_id DESC
</cfquery>

<cfset inspArr   = []>
<cfset cntKabul  = 0>
<cfset cntKos    = 0>
<cfset cntRet    = 0>
<cfset cntBekle  = 0>

<cfloop query="getInspections">
    <cfset itLabel = "">
    <cfswitch expression="#inspection_type#">
        <cfcase value="1"><cfset itLabel="Giriş Kontrol"></cfcase>
        <cfcase value="2"><cfset itLabel="Operasyon Kontrol"></cfcase>
        <cfcase value="3"><cfset itLabel="Final Kontrol"></cfcase>
        <cfdefaultcase><cfset itLabel="Diğer"></cfdefaultcase>
    </cfswitch>
    <cfset resLabel = "">
    <cfswitch expression="#result#">
        <cfcase value="1"><cfset resLabel="Kabul">         <cfset cntKabul++></cfcase>
        <cfcase value="2"><cfset resLabel="Koşullu Kabul"> <cfset cntKos++></cfcase>
        <cfcase value="3"><cfset resLabel="Ret">           <cfset cntRet++></cfcase>
        <cfdefaultcase><cfset resLabel="Bekliyor">         <cfset cntBekle++></cfdefaultcase>
    </cfswitch>
    <cfset arrayAppend(inspArr, {
        "qc_inspection_id" : val(qc_inspection_id),
        "inspection_no"    : inspection_no    ?: "",
        "inspection_type"  : val(inspection_type),
        "it_label"         : itLabel,
        "lot_no"           : lot_no           ?: "",
        "quantity"         : isNumeric(quantity)        ? val(quantity)        : 0,
        "sample_quantity"  : isNumeric(sample_quantity) ? val(sample_quantity) : 0,
        "inspection_date"  : isDate(inspection_date) ? dateFormat(inspection_date,"dd/mm/yyyy") & " " & timeFormat(inspection_date,"HH:mm") : "",
        "inspector_name"   : inspector_name   ?: "",
        "result"           : val(result),
        "res_label"        : resLabel,
        "product_name"     : product_name     ?: "",
        "product_code"     : product_code     ?: "",
        "ship_number"      : ship_number      ?: "",
        "p_order_no"       : p_order_no       ?: "",
        "company_name"     : company_name     ?: "",
        "record_date"      : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") & " " & timeFormat(record_date,"HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-microscope"></i></div>
        <div class="page-header-title">
            <h1>Kalite Kontrol Muayeneleri</h1>
            <p>Giriş, operasyon ve final kontrol kayıtları</p>
        </div>
    </div>
    <button class="btn-add" onclick="addInspection()">
        <i class="fas fa-plus"></i>Yeni Muayene
    </button>
</div>

<div class="px-3 pb-4">

    <cfif isDefined("url.success")>
        <div class="alert alert-dismissible fade show mb-3
            <cfif url.success eq 'deleted'>alert-danger<cfelse>alert-success</cfif>">
            <i class="fas fa-<cfif url.success eq 'deleted'>trash-alt<cfelse>check-circle</cfif> me-2"></i>
            <cfif url.success eq "added">Muayene başarıyla kaydedildi.
            <cfelseif url.success eq "updated">Muayene başarıyla güncellendi.
            <cfelseif url.success eq "deleted">Muayene silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </cfif>

    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="summary-card summary-card-blue">
                <div class="summary-icon"><i class="fas fa-microscope"></i></div>
                <div class="summary-info">
                    <span class="summary-value"><cfoutput>#getInspections.recordCount#</cfoutput></span>
                    <span class="summary-label">Toplam Muayene</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-check-circle"></i></div>
                <div class="summary-info">
                    <span class="summary-value"><cfoutput>#cntKabul#</cfoutput></span>
                    <span class="summary-label">Kabul</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-exclamation-circle"></i></div>
                <div class="summary-info">
                    <span class="summary-value"><cfoutput>#cntKos#</cfoutput></span>
                    <span class="summary-label">Koşullu Kabul</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-red">
                <div class="summary-icon"><i class="fas fa-times-circle"></i></div>
                <div class="summary-info">
                    <span class="summary-value"><cfoutput>#cntRet#</cfoutput></span>
                    <span class="summary-label">Ret</span>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list-alt"></i>Muayene Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-3">
            <div id="inspGrid"></div>
        </div>
    </div>
</div>

<!-- Silme Onay Modalı -->
<div class="modal fade" id="deleteModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header" style="background:#991b1b;color:#fff;">
                <h5 class="modal-title"><i class="fas fa-trash me-2"></i>Muayeneyi Sil</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body py-4 text-center">
                <i class="fas fa-exclamation-triangle text-danger" style="font-size:2.5rem;"></i>
                <p class="mt-3 mb-1">Aşağıdaki muayeneyi silmek istediğinize emin misiniz?</p>
                <p class="fw-bold fs-5 text-danger" id="deleteInspNo"></p>
                <p class="text-muted small">Bu işlem geri alınamaz.</p>
            </div>
            <div class="modal-footer justify-content-center gap-2">
                <button type="button" class="btn btn-outline-secondary px-4" data-bs-dismiss="modal">
                    <i class="fas fa-times me-2"></i>İptal
                </button>
                <button type="button" class="btn btn-danger px-4" id="confirmDeleteBtn">
                    <i class="fas fa-trash me-2"></i>Evet, Sil
                </button>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<style>
.summary-card { display:flex;align-items:center;gap:14px;padding:16px 20px;border-radius:10px;color:##fff;box-shadow:0 2px 10px rgba(0,0,0,.12); }
.summary-card-blue  { background:linear-gradient(135deg,##1a3a5c,##2563ab); }
.summary-card-green { background:linear-gradient(135deg,##15803d,##22c55e); }
.summary-card-orange{ background:linear-gradient(135deg,##92400e,##f59e0b); }
.summary-card-red   { background:linear-gradient(135deg,##991b1b,##ef4444); }
.summary-icon  { font-size:1.8rem;opacity:.85; }
.summary-label { font-size:.75rem;opacity:.85;display:block; }
.summary-value { font-size:1.6rem;font-weight:700;display:block; }

.badge-insp { display:inline-block;padding:3px 10px;border-radius:10px;font-size:.72rem;font-weight:600; }
/* Muayene tipi */
.bi-1 { background:##dbeafe;color:##1e40af; }   /* Giriş */
.bi-2 { background:##fef3c7;color:##92400e; }   /* Operasyon */
.bi-3 { background:##cffafe;color:##0e7490; }   /* Final */
.bi-0 { background:##f3f4f6;color:##6b7280; }   /* Diğer */
/* Sonuç */
.br-1 { background:##dcfce7;color:##15803d; }   /* Kabul */
.br-2 { background:##fef3c7;color:##92400e; }   /* Koşullu */
.br-3 { background:##fee2e2;color:##b91c1c; }   /* Ret */
.br-0 { background:##f3f4f6;color:##6b7280; }   /* Bekliyor */

.action-btn { display:inline-flex;align-items:center;justify-content:center;width:30px;height:30px;border-radius:6px;border:1px solid;font-size:.8rem;cursor:pointer;background:transparent;transition:all .15s; }
.action-btn-view  { border-color:##1a3a5c;color:##1a3a5c; }
.action-btn-view:hover  { background:##1a3a5c;color:##fff; }
.action-btn-del   { border-color:##b91c1c;color:##b91c1c; }
.action-btn-del:hover   { background:##b91c1c;color:##fff; }
</style>

<script>
var inspData      = #serializeJSON(inspArr)#;
var deleteModal   = null;
var deleteTargetId = 0;

var typeBadge = {
    1: '<span class="badge-insp bi-1">Giriş Kontrol</span>',
    2: '<span class="badge-insp bi-2">Operasyon Kontrol</span>',
    3: '<span class="badge-insp bi-3">Final Kontrol</span>'
};
var resBadge = {
    1: '<span class="badge-insp br-1">Kabul</span>',
    2: '<span class="badge-insp br-2">Koşullu Kabul</span>',
    3: '<span class="badge-insp br-3">Ret</span>',
    0: '<span class="badge-insp br-0">Bekliyor</span>'
};

$(function(){
    var dm = document.getElementById('deleteModal');
    if (dm) document.body.appendChild(dm);
    deleteModal = new bootstrap.Modal(document.getElementById('deleteModal'));

    document.getElementById('recordCount').textContent = inspData.length + ' kayıt';

    $("##inspGrid").dxDataGrid({
        dataSource: inspData,
        keyExpr: 'qc_inspection_id',
        showBorders: false,
        showRowLines: true,
        showColumnLines: false,
        rowAlternationEnabled: true,
        hoverStateEnabled: true,
        headerFilter: { visible: true },
        searchPanel: { visible: true, width: 220, placeholder: 'Ara...' },
        paging: { pageSize: 25 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [25,50,100], showInfo: true },
        sorting: { mode: 'multiple' },
        export: { enabled: true, fileName: 'kk_muayeneler' },
        columns: [
            { dataField: 'qc_inspection_id', caption: '##', width: 65, alignment: 'center', sortOrder: 'desc' },
            { dataField: 'inspection_no',    caption: 'Muayene No', width: 150 },
            {
                dataField: 'inspection_type', caption: 'Tip', width: 160, alignment: 'center',
                cellTemplate: function(el, i){ el.html(typeBadge[i.value] || '<span class="badge-insp bi-0">Diğer</span>'); }
            },
            { dataField: 'company_name',  caption: 'Cari',    minWidth: 150 },
            { dataField: 'product_name',  caption: 'Ürün',    minWidth: 150 },
            { dataField: 'lot_no',        caption: 'Lot No',  width: 120 },
            { dataField: 'quantity',      caption: 'Miktar',  width: 90, alignment: 'right', dataType: 'number' },
            { dataField: 'sample_quantity', caption: 'Numune', width: 90, alignment: 'right', dataType: 'number' },
            { dataField: 'ship_number',   caption: 'İrsaliye',  width: 130 },
            { dataField: 'p_order_no',    caption: 'Ürt. Emri', width: 130 },
            {
                dataField: 'result', caption: 'Sonuç', width: 140, alignment: 'center',
                cellTemplate: function(el, i){ el.html(resBadge[i.value] || resBadge[0]); }
            },
            { dataField: 'inspector_name',  caption: 'Kontrolör', width: 140 },
            { dataField: 'inspection_date', caption: 'Tarih',     width: 140, alignment: 'center' },
            {
                caption: 'İşlem', width: 90, allowFiltering: false, allowSorting: false, alignment: 'center',
                cellTemplate: function(el, opt) {
                    var d = opt.data;
                    el.html(
                        '<button class="action-btn action-btn-view me-1" title="Detay" onclick="viewInspection('+d.qc_inspection_id+')"><i class="fas fa-eye"></i></button>' +
                        '<button class="action-btn action-btn-del" title="Sil" onclick="confirmDelete('+d.qc_inspection_id+',\''+d.inspection_no.replace(/'/g,"\\'")+"')\">" +
                        '<i class="fas fa-trash"></i></button>'
                    );
                }
            }
        ]
    });
});

function addInspection()   { window.location.href = 'index.cfm?fuseaction=quality.add_qc_inspection'; }
function viewInspection(id){ window.location.href = 'index.cfm?fuseaction=quality.view_qc_inspection&qc_inspection_id=' + id; }

function confirmDelete(id, no) {
    deleteTargetId = id;
    document.getElementById('deleteInspNo').textContent = no;
    deleteModal.show();
}

document.addEventListener('click', function(e){
    if (e.target.closest('##confirmDeleteBtn') && deleteTargetId) {
        var btn = document.getElementById('confirmDeleteBtn');
        btn.disabled = true;
        btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Siliniyor...';
        $.post('index.cfm?fuseaction=quality.delete_qc_inspection', { qc_inspection_id: deleteTargetId }, function(res){
            var r = typeof res === 'string' ? JSON.parse(res) : res;
            deleteModal.hide();
            if (r.success) {
                window.location.href = 'index.cfm?fuseaction=quality.list_qc_inspections&success=deleted';
            } else {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-trash me-2"></i>Evet, Sil';
                alert('Hata: ' + (r.message || 'Silinemedi'));
            }
        });
    }
});
</script>
</cfoutput>