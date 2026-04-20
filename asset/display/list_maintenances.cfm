<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getMaintenances" datasource="boyahane">
    SELECT m.maintenance_id, m.asset_id, am.asset_name,
           m.maintenance_type, m.planned_date, m.start_date, m.end_date,
           m.total_cost, m.maintenance_status,
           COALESCE(m.work_order_no, '') AS work_order_no
    FROM asset_maintenance m
    INNER JOIN asset_master am ON am.asset_id = m.asset_id
    ORDER BY m.maintenance_id DESC
    LIMIT 500
</cfquery>

<cfquery name="getAssets" datasource="boyahane">
    SELECT asset_id, asset_name FROM asset_master
    WHERE asset_status NOT IN ('SCRAPPED','SOLD')
    ORDER BY asset_name
</cfquery>

<cfset maintArr  = []>
<cfset cntOpen   = 0>
<cfset cntIP     = 0>
<cfset cntDone   = 0>
<cfset cntCancel = 0>

<cfloop query="getMaintenances">
    <cfset typeLbl = "">
    <cfswitch expression="#maintenance_type#">
        <cfcase value="PLANNED">     <cfset typeLbl = "Planlı"></cfcase>
        <cfcase value="UNPLANNED">   <cfset typeLbl = "Plansız"></cfcase>
        <cfcase value="REPAIR">      <cfset typeLbl = "Onarım"></cfcase>
        <cfcase value="CALIBRATION"> <cfset typeLbl = "Kalibrasyon"></cfcase>
        <cfcase value="SERVICE">     <cfset typeLbl = "Servis"></cfcase>
        <cfdefaultcase>              <cfset typeLbl = maintenance_type ?: ""></cfdefaultcase>
    </cfswitch>
    <cfset statusLbl = "">
    <cfswitch expression="#maintenance_status#">
        <cfcase value="OPEN">        <cfset statusLbl = "Açık">        <cfset cntOpen++></cfcase>
        <cfcase value="IN_PROGRESS"> <cfset statusLbl = "Devam Ediyor"><cfset cntIP++></cfcase>
        <cfcase value="COMPLETED">   <cfset statusLbl = "Tamamlandı">  <cfset cntDone++></cfcase>
        <cfcase value="CANCELLED">   <cfset statusLbl = "İptal">       <cfset cntCancel++></cfcase>
        <cfdefaultcase>              <cfset statusLbl = maintenance_status ?: ""></cfdefaultcase>
    </cfswitch>
    <cfset arrayAppend(maintArr, {
        "maintenance_id":     val(maintenance_id),
        "asset_name":         asset_name ?: "",
        "maintenance_type":   maintenance_type ?: "",
        "type_label":         typeLbl,
        "planned_date":       isDate(planned_date) ? dateFormat(planned_date,"dd/mm/yyyy") : "",
        "start_date":         isDate(start_date)   ? dateFormat(start_date,  "dd/mm/yyyy") : "",
        "end_date":           isDate(end_date)      ? dateFormat(end_date,    "dd/mm/yyyy") : "",
        "total_cost":         isNumeric(total_cost) ? val(total_cost) : 0,
        "maintenance_status": maintenance_status ?: "",
        "status_label":       statusLbl,
        "work_order_no":      work_order_no ?: ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-tools"></i></div>
        <div class="page-header-title">
            <h1>Bakım Kayıtları</h1>
            <p>Tüm varlıklara ait bakım ve servis geçmişi</p>
        </div>
    </div>
    <button class="btn-add" data-bs-toggle="modal" data-bs-target="#maintModal">
        <i class="fas fa-plus"></i>Yeni Bakım
    </button>
</div>

<div class="px-3 pb-4">

    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="summary-card summary-card-blue">
                <div class="summary-icon"><i class="fas fa-clipboard-list"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam</span>
                    <span class="summary-value"><cfoutput>#getMaintenances.recordCount#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-exclamation-circle"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Açık</span>
                    <span class="summary-value"><cfoutput>#cntOpen#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card" style="background:linear-gradient(135deg,##1e40af,##3b82f6);color:#fff;box-shadow:0 2px 10px rgba(0,0,0,.12);">
                <div class="summary-icon"><i class="fas fa-spinner"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Devam Ediyor</span>
                    <span class="summary-value"><cfoutput>#cntIP#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-check-double"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Tamamlandı</span>
                    <span class="summary-value"><cfoutput>#cntDone#</cfoutput></span>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-wrench"></i>Bakım Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-3">
            <div id="maintGrid"></div>
        </div>
    </div>
</div>

<!-- Yeni Bakım Modal -->
<div class="modal fade" id="maintModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header" style="background:var(--primary);color:#fff;">
                <h5 class="modal-title"><i class="fas fa-tools me-2"></i>Yeni Bakım Kaydı</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Varlık *</label>
                        <select id="m_asset_id" class="form-select">
                            <option value="">Seçiniz</option>
                            <cfoutput query="getAssets">
                                <option value="#asset_id#">#encodeForHTML(asset_name)#</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Bakım Tipi *</label>
                        <select id="m_maintenance_type" class="form-select">
                            <option value="PLANNED">Planlı</option>
                            <option value="UNPLANNED">Plansız</option>
                            <option value="REPAIR">Onarım</option>
                            <option value="CALIBRATION">Kalibrasyon</option>
                            <option value="SERVICE">Servis</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">İş Emri No</label>
                        <input type="text" id="m_work_order_no" class="form-control" maxlength="50">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Planlanan Tarih</label>
                        <input type="date" id="m_planned_date" class="form-control">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Durum</label>
                        <select id="m_status" class="form-select">
                            <option value="OPEN">Açık</option>
                            <option value="IN_PROGRESS">Devam Ediyor</option>
                            <option value="COMPLETED">Tamamlandı</option>
                            <option value="CANCELLED">İptal</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Başlangıç</label>
                        <input type="datetime-local" id="m_start_date" class="form-control">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Bitiş</label>
                        <input type="datetime-local" id="m_end_date" class="form-control">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">İşçilik Maliyeti</label>
                        <input type="number" step="0.01" min="0" id="m_labor_cost" class="form-control" value="0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Yedek Parça</label>
                        <input type="number" step="0.01" min="0" id="m_spare_part_cost" class="form-control" value="0">
                    </div>
                    <div class="col-md-8">
                        <label class="form-label fw-semibold">Not</label>
                        <input type="text" id="m_note" class="form-control">
                    </div>
                </div>
                <div id="maintSaveMsg" class="mt-2"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-warning text-dark fw-bold" id="maintSaveBtn" onclick="saveMaint()">
                    <i class="fas fa-save me-2"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<style>
##maintModal { z-index: 99999 !important; }
.modal-backdrop { z-index: 99998 !important; }
.modal         { z-index:99999 !important; }
.modal-backdrop{ z-index:99998 !important; }
.summary-card { display:flex;align-items:center;gap:14px;padding:16px 20px;border-radius:10px;color:##fff;box-shadow:0 2px 10px rgba(0,0,0,.12); }
.summary-card-blue   { background:linear-gradient(135deg,##1a3a5c,##2563ab); }
.summary-card-green  { background:linear-gradient(135deg,##15803d,##22c55e); }
.summary-card-orange { background:linear-gradient(135deg,##92400e,##f59e0b); }
.summary-icon  { font-size:1.8rem;opacity:.85; }
.summary-label { font-size:.75rem;opacity:.85;display:block; }
.summary-value { font-size:1.6rem;font-weight:700;display:block; }
.badge-s { display:inline-block;padding:3px 10px;border-radius:10px;font-size:.72rem;font-weight:600; }
.bs-OPEN        { background:##fef3c7;color:##92400e; }
.bs-IN_PROGRESS { background:##dbeafe;color:##1e40af; }
.bs-COMPLETED   { background:##dcfce7;color:##15803d; }
.bs-CANCELLED   { background:##fee2e2;color:##b91c1c; }
.bt-PLANNED    { background:##ede9fe;color:##6d28d9; }
.bt-UNPLANNED  { background:##ffedd5;color:##c2410c; }
.bt-REPAIR     { background:##fee2e2;color:##b91c1c; }
.bt-CALIBRATION{ background:##cffafe;color:##0e7490; }
.bt-SERVICE    { background:##dcfce7;color:##15803d; }
</style>
<script>
var allMaint = #serializeJSON(maintArr)#;

var sBadge = {
    'OPEN':        '<span class="badge-s bs-OPEN">Açık</span>',
    'IN_PROGRESS': '<span class="badge-s bs-IN_PROGRESS">Devam Ediyor</span>',
    'COMPLETED':   '<span class="badge-s bs-COMPLETED">Tamamlandı</span>',
    'CANCELLED':   '<span class="badge-s bs-CANCELLED">İptal</span>'
};
var tBadge = {
    'PLANNED':     '<span class="badge-s bt-PLANNED">Planlı</span>',
    'UNPLANNED':   '<span class="badge-s bt-UNPLANNED">Plansız</span>',
    'REPAIR':      '<span class="badge-s bt-REPAIR">Onarım</span>',
    'CALIBRATION': '<span class="badge-s bt-CALIBRATION">Kalibrasyon</span>',
    'SERVICE':     '<span class="badge-s bt-SERVICE">Servis</span>'
};

window.addEventListener('load', function(){
    // modal'ı body'e taşı — content-wrapper stacking context'inden kaçsın
    var mm = document.getElementById('maintModal');
    if (mm) document.body.appendChild(mm);

    document.getElementById('recordCount').textContent = allMaint.length + ' kayıt';
    $("##maintGrid").dxDataGrid({
        dataSource: allMaint,
        keyExpr: "maintenance_id",
        showBorders: false, showRowLines: true, showColumnLines: false,
        rowAlternationEnabled: true, hoverStateEnabled: true,
        paging: { pageSize: 25 },
        pager: { showPageSizeSelector:true, allowedPageSizes:[25,50,100], showInfo:true },
        sorting: { mode:"multiple" },
        export: { enabled:true, fileName:"bakim_kayitlari" },
        headerFilter: { visible:true },
        columns: [
            { dataField:"maintenance_id", caption:"##",      width:65, alignment:"center", sortOrder:"desc" },
            { dataField:"asset_name",     caption:"Varlık", minWidth:160 },
            {
                dataField:"maintenance_type", caption:"Tip", width:130, alignment:"center",
                cellTemplate: function(el,i){ el.html(tBadge[i.value] || i.value || '-'); }
            },
            { dataField:"work_order_no", caption:"İş Emri", width:120 },
            { dataField:"planned_date",  caption:"Planlanan", width:110, alignment:"center" },
            { dataField:"start_date",    caption:"Başlangıç",  width:110, alignment:"center" },
            { dataField:"end_date",      caption:"Bitiş",      width:110, alignment:"center" },
            {
                dataField:"total_cost", caption:"Maliyet", width:120, alignment:"right",
                cellTemplate: function(el,i){
                    el.text((parseFloat(i.value||0)).toLocaleString('tr-TR',{minimumFractionDigits:2,maximumFractionDigits:2}));
                }
            },
            {
                dataField:"maintenance_status", caption:"Durum", width:130, alignment:"center",
                cellTemplate: function(el,i){ el.html(sBadge[i.value] || i.value || '-'); }
            }
        ]
    });
});

function saveMaint() {
    var assetId = document.getElementById('m_asset_id').value;
    if (!assetId) { alert('Lütfen varlık seçin.'); return; }
    var btn = document.getElementById('maintSaveBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';
    $.ajax({
        url: '/asset/form/save_maintenance.cfm', method:'POST', dataType:'json',
        data: {
            asset_id:         assetId,
            maintenance_type: document.getElementById('m_maintenance_type').value,
            work_order_no:    document.getElementById('m_work_order_no').value,
            planned_date:     document.getElementById('m_planned_date').value,
            start_date:       document.getElementById('m_start_date').value,
            end_date:         document.getElementById('m_end_date').value,
            labor_cost:       document.getElementById('m_labor_cost').value,
            spare_part_cost:  document.getElementById('m_spare_part_cost').value,
            maintenance_status: document.getElementById('m_status').value,
            note:             document.getElementById('m_note').value
        },
        success: function(res) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet';
            if (res && res.success) {
                document.getElementById('maintSaveMsg').innerHTML = '<div class="alert alert-success py-2">Bakım kaydı oluşturuldu.</div>';
                setTimeout(function(){ location.reload(); }, 1200);
            } else {
                document.getElementById('maintSaveMsg').innerHTML = '<div class="alert alert-danger py-2">' + (res.message || 'Hata oluştu.') + '</div>';
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet';
            document.getElementById('maintSaveMsg').innerHTML = '<div class="alert alert-danger py-2">Sunucu hatası.</div>';
        }
    });
}
</script>
</cfoutput>