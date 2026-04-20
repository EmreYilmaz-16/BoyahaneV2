<cfprocessingdirective pageEncoding="utf-8">

<!--- ── Zimmet Listesi ── --->
<cfquery name="getAssignments" datasource="boyahane">
    SELECT
        aa.assignment_id,
        aa.asset_id,
        am.asset_name,
        am.asset_no,
        am.brand,
        am.model,
        am.serial_no,
        am.asset_type,
        aa.user_id,
        aa.assigned_to_name,
        aa.assigned_to_title,
        aa.department_name,
        TO_CHAR(aa.assigned_date,       'DD/MM/YYYY') AS assigned_date,
        TO_CHAR(aa.expected_return_date,'DD/MM/YYYY') AS expected_return_date,
        TO_CHAR(aa.returned_date,       'DD/MM/YYYY') AS returned_date,
        aa.assignment_status,
        aa.notes,
        aa.return_notes,
        aa.return_condition,
        aa.assigned_by,
        TO_CHAR(aa.record_date,'DD/MM/YYYY') AS record_date
    FROM asset_assignments aa
    INNER JOIN asset_master am ON am.asset_id = aa.asset_id
    ORDER BY aa.assignment_id DESC
    LIMIT 1000
</cfquery>

<!--- Assets available for zimmet (not currently assigned to active) --->
<cfquery name="getAssets" datasource="boyahane">
    SELECT asset_id, asset_no, asset_name, asset_type, brand, model, serial_no
    FROM asset_master
    WHERE asset_status NOT IN ('SCRAPPED','SOLD')
    ORDER BY asset_name
</cfquery>

<cfquery name="getUsers" datasource="boyahane">
    SELECT id, name, surname, username
    FROM kullanicilar
    WHERE is_active = true
    ORDER BY name, surname
</cfquery>

<cfquery name="getDepartments" datasource="boyahane">
    SELECT department_id, department_head, department_detail
    FROM department
    WHERE department_status = true
    ORDER BY department_head
</cfquery>

<!--- Stats --->
<cfset assignArr = []>
<cfset cntActive   = 0>
<cfset cntReturned = 0>
<cfset cntLost     = 0>
<cfset cntDamaged  = 0>

<cfloop query="getAssignments">
    <cfset statusLbl = "">
    <cfswitch expression="#assignment_status#">
        <cfcase value="ACTIVE">   <cfset statusLbl="Zimmetli">  <cfset cntActive++>  </cfcase>
        <cfcase value="RETURNED"> <cfset statusLbl="İade Edildi"><cfset cntReturned++></cfcase>
        <cfcase value="LOST">     <cfset statusLbl="Kayıp">     <cfset cntLost++>    </cfcase>
        <cfcase value="DAMAGED">  <cfset statusLbl="Hasarlı">   <cfset cntDamaged++> </cfcase>
        <cfdefaultcase><cfset statusLbl=assignment_status></cfdefaultcase>
    </cfswitch>

    <cfset typeLbl = "">
    <cfswitch expression="#asset_type#">
        <cfcase value="PHYSICAL"><cfset typeLbl="Fiziki"></cfcase>
        <cfcase value="IT">      <cfset typeLbl="BT"></cfcase>
        <cfcase value="VEHICLE"> <cfset typeLbl="Araç"></cfcase>
        <cfdefaultcase><cfset typeLbl=asset_type></cfdefaultcase>
    </cfswitch>

    <cfset arrayAppend(assignArr, {
        "assignment_id":       val(assignment_id),
        "asset_id":            val(asset_id),
        "asset_name":          asset_name     ?: "",
        "asset_no":            asset_no       ?: "",
        "brand":               brand          ?: "",
        "model":               model          ?: "",
        "serial_no":           serial_no      ?: "",
        "asset_type":          asset_type     ?: "",
        "type_label":          typeLbl,
        "assigned_to_name":    assigned_to_name  ?: "",
        "assigned_to_title":   assigned_to_title ?: "",
        "department_name":     department_name   ?: "",
        "assigned_date":       assigned_date         ?: "",
        "expected_return_date":expected_return_date  ?: "",
        "returned_date":       returned_date         ?: "",
        "assignment_status":   assignment_status     ?: "",
        "status_label":        statusLbl,
        "notes":               notes         ?: "",
        "return_notes":        return_notes  ?: "",
        "return_condition":    return_condition ?: "",
        "assigned_by":         assigned_by   ?: ""
    })>
</cfloop>

<!--- ── HTML ── --->
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-file-signature"></i></div>
        <div class="page-header-title">
            <h1>Zimmet Yönetimi</h1>
            <p>Demirbaş zimmet takibi ve belge yönetimi</p>
        </div>
    </div>
    <button class="btn-add" onclick="openAssignModal(0)">
        <i class="fas fa-plus"></i>Yeni Zimmet
    </button>
</div>

<div class="px-3 pb-4">

    <!--- Özet Kartlar --->
    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-file-signature"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Zimmetli</span>
                    <span class="summary-value"><cfoutput>#cntActive#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-check-circle"></i></div>
                <div class="summary-info">
                    <span class="summary-label">İade Edildi</span>
                    <span class="summary-value"><cfoutput>#cntReturned#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-red">
                <div class="summary-icon"><i class="fas fa-exclamation-triangle"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Kayıp</span>
                    <span class="summary-value"><cfoutput>#cntLost#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card" style="background:linear-gradient(135deg,##92400e,##f59e0b);color:##fff;box-shadow:0 2px 10px rgba(0,0,0,.12);">
                <div class="summary-icon"><i class="fas fa-tools"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Hasarlı</span>
                    <span class="summary-value"><cfoutput>#cntDamaged#</cfoutput></span>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Zimmet Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-3">
            <div class="row g-2 mb-3">
                <div class="col-md-2">
                    <select id="filterStatus" class="form-select form-select-sm">
                        <option value="">Tüm Durumlar</option>
                        <option value="ACTIVE">Zimmetli</option>
                        <option value="RETURNED">İade Edildi</option>
                        <option value="LOST">Kayıp</option>
                        <option value="DAMAGED">Hasarlı</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <select id="filterType" class="form-select form-select-sm">
                        <option value="">Tüm Tipler</option>
                        <option value="PHYSICAL">Fiziki</option>
                        <option value="IT">BT</option>
                        <option value="VEHICLE">Araç</option>
                    </select>
                </div>
                <div class="col-md-4">
                    <input type="text" id="filterSearch" class="form-control form-control-sm" placeholder="Personel / varlık / bölüm ara...">
                </div>
                <div class="col-md-2">
                    <button class="btn btn-outline-secondary btn-sm w-100" onclick="clearFilters()">
                        <i class="fas fa-eraser me-1"></i>Temizle
                    </button>
                </div>
                <div class="col-md-2">
                    <button class="btn btn-outline-primary btn-sm w-100" onclick="printSelected()">
                        <i class="fas fa-print me-1"></i>Zimmet Belgesi
                    </button>
                </div>
            </div>
            <div id="assignGrid"></div>
        </div>
    </div>
</div>

<!--- ── Zimmet Ekle/Düzenle Modal ── --->
<div class="modal fade" id="assignModal" tabindex="-1">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header" style="background:var(--primary);color:##fff;">
                <h5 class="modal-title" id="assignModalTitle">
                    <i class="fas fa-file-signature me-2"></i>Yeni Zimmet
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="as_assignment_id">
                <div class="row g-3">
                    <div class="col-12">
                        <label class="form-label fw-semibold">Demirbaş / Varlık <span class="text-danger">*</span></label>
                        <select id="as_asset_id" class="form-select" onchange="onAssetChange()">
                            <option value="">Seçiniz...</option>
                            <cfoutput query="getAssets">
                                <option value="#asset_id#"
                                    data-no="#encodeForHTMLAttribute(asset_no)#"
                                    data-type="#asset_type#"
                                    data-brand="#encodeForHTMLAttribute(brand)#"
                                    data-model="#encodeForHTMLAttribute(model)#"
                                    data-serial="#encodeForHTMLAttribute(serial_no)#">
                                    #encodeForHTML(asset_name)#
                                    <cfif len(trim(asset_no))> (#encodeForHTML(asset_no)#)</cfif>
                                    <cfif len(trim(brand))> — #encodeForHTML(brand)# #encodeForHTML(model)#</cfif>
                                </option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold text-muted small">Demirbaş No</label>
                        <input type="text" id="as_asset_no_display" class="form-control form-control-sm" readonly style="background:##f9fafb;">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold text-muted small">Marka / Model</label>
                        <input type="text" id="as_brand_display" class="form-control form-control-sm" readonly style="background:##f9fafb;">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold text-muted small">Seri No</label>
                        <input type="text" id="as_serial_display" class="form-control form-control-sm" readonly style="background:##f9fafb;">
                    </div>

                    <div class="col-12"><hr class="my-1"><small class="text-muted fw-semibold text-uppercase">Zimmet Alan Personel</small></div>

                    <div class="col-md-5">
                        <label class="form-label fw-semibold">Sistemdeki Kullanıcı <small class="text-muted">(opsiyonel)</small></label>
                        <select id="as_user_id" class="form-select" onchange="onUserChange()">
                            <option value="">— Sistemde değil —</option>
                            <cfoutput query="getUsers">
                                <option value="#id#" data-fullname="#encodeForHTMLAttribute(name & ' ' & surname)#">
                                    #encodeForHTML(name)# #encodeForHTML(surname)# (#encodeForHTML(username)#)
                                </option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Ad Soyad <span class="text-danger">*</span></label>
                        <input type="text" id="as_assigned_to_name" class="form-control" maxlength="200" placeholder="Personel ad soyad">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Unvan / Pozisyon</label>
                        <input type="text" id="as_assigned_to_title" class="form-control" maxlength="100" placeholder="Örn: Mühendis">
                    </div>
                    <div class="col-md-5">
                        <label class="form-label fw-semibold">Bölüm</label>
                        <select id="as_department_id" class="form-select" onchange="onDeptChange()">
                            <option value="">— Seçiniz —</option>
                            <cfoutput query="getDepartments">
                                <option value="#department_id#" data-name="#encodeForHTMLAttribute(department_head)#">
                                    #encodeForHTML(department_head)#
                                    <cfif len(trim(department_detail))> — #encodeForHTML(department_detail)#</cfif>
                                </option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Bölüm Adı <small class="text-muted">(düzenlenebilir)</small></label>
                        <input type="text" id="as_department_name" class="form-control" maxlength="150" placeholder="Bölüm adı">
                    </div>

                    <div class="col-12"><hr class="my-1"><small class="text-muted fw-semibold text-uppercase">Zimmet Tarihleri</small></div>

                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Zimmet Tarihi <span class="text-danger">*</span></label>
                        <input type="date" id="as_assigned_date" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Beklenen İade Tarihi</label>
                        <input type="date" id="as_expected_return_date" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Zimmet Veren</label>
                        <input type="text" id="as_assigned_by" class="form-control" maxlength="100">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Durum</label>
                        <select id="as_assignment_status" class="form-select">
                            <option value="ACTIVE">Zimmetli</option>
                            <option value="RETURNED">İade Edildi</option>
                            <option value="LOST">Kayıp</option>
                            <option value="DAMAGED">Hasarlı</option>
                        </select>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Notlar</label>
                        <textarea id="as_notes" class="form-control" rows="2" placeholder="Zimmetle ilgili ek bilgi..."></textarea>
                    </div>
                </div>
                <div id="assignSaveMsg" class="mt-3"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-primary" id="assignSaveBtn" onclick="saveAssignment()">
                    <i class="fas fa-save me-2"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<!--- ── İade Modal ── --->
<div class="modal fade" id="returnModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header" style="background:##15803d;color:##fff;">
                <h5 class="modal-title"><i class="fas fa-undo me-2"></i>Zimmet İade</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="ret_assignment_id">
                <div id="ret_summary" class="alert alert-info py-2 mb-3"></div>
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">İade Tarihi <span class="text-danger">*</span></label>
                        <input type="date" id="ret_returned_date" class="form-control">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">İade Durumu</label>
                        <select id="ret_condition" class="form-select">
                            <option value="GOOD">İyi Durumda</option>
                            <option value="DAMAGED">Hasarlı</option>
                            <option value="LOST">Kayıp</option>
                        </select>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">İade Notu</label>
                        <textarea id="ret_notes" class="form-control" rows="2" placeholder="İade sırasındaki hasar, eksiklik vb. bilgiler..."></textarea>
                    </div>
                </div>
                <div id="returnSaveMsg" class="mt-3"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-success" id="returnSaveBtn" onclick="saveReturn()">
                    <i class="fas fa-check me-2"></i>İadeyi Onayla
                </button>
            </div>
        </div>
    </div>
</div>

<!--- ── Zimmet Belgesi Print Modal ── --->
<div class="modal fade" id="printModal" tabindex="-1">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header" style="background:##374151;color:##fff;">
                <h5 class="modal-title"><i class="fas fa-print me-2"></i>Zimmet Belgesi</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body" id="printArea">
                <!--- JS tarafından doldurulur --->
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-dark" onclick="window.print()">
                    <i class="fas fa-print me-2"></i>Yazdır
                </button>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<style>
.summary-card { display:flex;align-items:center;gap:14px;padding:16px 20px;border-radius:10px;color:##fff;box-shadow:0 2px 10px rgba(0,0,0,.12); }
.summary-card-blue   { background:linear-gradient(135deg,##1a3a5c,##2563ab); }
.summary-card-green  { background:linear-gradient(135deg,##15803d,##22c55e); }
.summary-card-orange { background:linear-gradient(135deg,##d97706,##f59e0b); }
.summary-card-red    { background:linear-gradient(135deg,##991b1b,##ef4444); }
.summary-icon  { font-size:1.8rem;opacity:.85; }
.summary-label { font-size:.75rem;opacity:.85;display:block; }
.summary-value { font-size:1.6rem;font-weight:700;display:block; }
.grid-card     { background:##fff;border-radius:10px;box-shadow:0 2px 12px rgba(0,0,0,.07);overflow:hidden; }
.grid-card-header { padding:14px 20px 12px;border-bottom:1px solid ##e9ecef;display:flex;align-items:center;justify-content:space-between; }
.grid-card-header-title { font-size:.95rem;font-weight:700;color:var(--primary);display:flex;align-items:center;gap:8px; }
.badge-as { display:inline-block;padding:3px 10px;border-radius:10px;font-size:.72rem;font-weight:600; }
.bas-ACTIVE   { background:##fef3c7;color:##92400e; }
.bas-RETURNED { background:##dcfce7;color:##15803d; }
.bas-LOST     { background:##fee2e2;color:##b91c1c; }
.bas-DAMAGED  { background:##ffedd5;color:##c2410c; }
##assignModal,##returnModal,##printModal { z-index:99999 !important; }
.modal-backdrop { z-index:99998 !important; }

/* Zimmet Belgesi Print Stili */
##printArea { font-family:'Segoe UI',sans-serif; font-size:13px; }
.zimmet-header { text-align:center; border-bottom:2px solid ##1a3a5c; padding-bottom:10px; margin-bottom:16px; }
.zimmet-header h3 { margin:0;color:##1a3a5c;font-size:1.3rem;font-weight:700; }
.zimmet-header p  { margin:4px 0 0;color:##6b7280;font-size:.85rem; }
.zimmet-table  { width:100%;border-collapse:collapse;margin-bottom:16px; }
.zimmet-table th { background:##1a3a5c;color:##fff;padding:7px 12px;font-size:.82rem;text-align:left; }
.zimmet-table td { border:1px solid ##e5e7eb;padding:6px 12px;font-size:.82rem; }
.zimmet-table tr:nth-child(even) td { background:##f9fafb; }
.zimmet-signatures { display:flex;gap:40px;margin-top:30px; }
.zimmet-sign-box   { flex:1;border-top:1px solid ##374151;padding-top:8px;text-align:center;font-size:.8rem;color:##374151; }
@media print {
    body * { visibility:hidden; }
    ##printArea, ##printArea * { visibility:visible; }
    ##printArea { position:fixed;top:0;left:0;width:100%;padding:20px; }
    .modal-footer { display:none; }
}
</style>

<script>
var allAssignments = #serializeJSON(assignArr)#;
var selectedId = null;

var statusBadge = {
    'ACTIVE':   '<span class="badge-as bas-ACTIVE"><i class="fas fa-file-signature me-1"></i>Zimmetli</span>',
    'RETURNED': '<span class="badge-as bas-RETURNED"><i class="fas fa-check me-1"></i>İade Edildi</span>',
    'LOST':     '<span class="badge-as bas-LOST"><i class="fas fa-times me-1"></i>Kayıp</span>',
    'DAMAGED':  '<span class="badge-as bas-DAMAGED"><i class="fas fa-tools me-1"></i>Hasarlı</span>'
};
var typeBadge = {
    'PHYSICAL':'<span style="background:##dbeafe;color:##1e40af;display:inline-block;padding:2px 8px;border-radius:8px;font-size:.7rem;font-weight:600">Fiziki</span>',
    'IT':      '<span style="background:##ede9fe;color:##6d28d9;display:inline-block;padding:2px 8px;border-radius:8px;font-size:.7rem;font-weight:600">BT</span>',
    'VEHICLE': '<span style="background:##fef3c7;color:##92400e;display:inline-block;padding:2px 8px;border-radius:8px;font-size:.7rem;font-weight:600">Araç</span>'
};

function renderGrid(data) {
    document.getElementById('recordCount').textContent = data.length + ' kayıt';
    $("##assignGrid").dxDataGrid({
        dataSource: data,
        keyExpr: "assignment_id",
        showBorders: false, showRowLines: true, showColumnLines: false,
        rowAlternationEnabled: true, hoverStateEnabled: true,
        paging:  { pageSize: 25 },
        pager:   { showPageSizeSelector:true, allowedPageSizes:[25,50,100], showInfo:true },
        sorting: { mode:"multiple" },
        export:  { enabled:true, fileName:"zimmet_listesi" },
        headerFilter: { visible:true },
        selection: { mode:"single" },
        onSelectionChanged: function(e){ selectedId = e.selectedRowsData.length ? e.selectedRowsData[0].assignment_id : null; },
        columns: [
            { dataField:"assignment_id", caption:"##", width:65, alignment:"center", sortOrder:"desc" },
            {
                dataField:"asset_type", caption:"Tip", width:75, alignment:"center",
                cellTemplate: function(el,i){ el.html(typeBadge[i.value]||i.value||'—'); }
            },
            { dataField:"asset_no",   caption:"Demirbaş No", width:115 },
            { dataField:"asset_name", caption:"Varlık Adı",  minWidth:160 },
            { dataField:"brand",      caption:"Marka/Model", width:120,
              cellTemplate: function(el,i){ el.text((i.data.brand+' '+i.data.model).trim()||'—'); }
            },
            { dataField:"serial_no",         caption:"Seri No",   width:120 },
            { dataField:"assigned_to_name",  caption:"Zimmet Alan",  minWidth:140 },
            { dataField:"assigned_to_title", caption:"Unvan",       width:120 },
            { dataField:"department_name",   caption:"Bölüm",       width:140 },
            { dataField:"assigned_date",     caption:"Zimmet Tarihi",  width:110, alignment:"center" },
            { dataField:"expected_return_date",caption:"Beklenen İade",width:110, alignment:"center",
              cellTemplate:function(el,i){ el.text(i.value||'—'); }
            },
            { dataField:"returned_date",     caption:"İade Tarihi",   width:110, alignment:"center",
              cellTemplate:function(el,i){ el.text(i.value||'—'); }
            },
            {
                dataField:"assignment_status", caption:"Durum", width:120, alignment:"center",
                cellTemplate: function(el,i){ el.html(statusBadge[i.value]||i.value||'—'); }
            },
            {
                caption:"İşlem", width:140, alignment:"center", allowSorting:false, allowFiltering:false,
                cellTemplate: function(el,i){
                    var btns = '<button class="btn btn-xs btn-outline-primary py-0 px-2 me-1" onclick="openAssignModal('+i.data.assignment_id+')" title="Düzenle"><i class="fas fa-pen"></i></button>';
                    if (i.data.assignment_status === 'ACTIVE') {
                        btns += '<button class="btn btn-xs btn-outline-success py-0 px-2 me-1" onclick="openReturnModal('+i.data.assignment_id+')" title="İade Al"><i class="fas fa-undo"></i></button>';
                    }
                    btns += '<button class="btn btn-xs btn-outline-secondary py-0 px-2" onclick="printBelge('+i.data.assignment_id+')" title="Zimmet Belgesi"><i class="fas fa-print"></i></button>';
                    el.html(btns);
                }
            }
        ]
    });
}

function applyFilters() {
    var statusVal = document.getElementById('filterStatus').value;
    var typeVal   = document.getElementById('filterType').value;
    var searchVal = (document.getElementById('filterSearch').value||'').trim().toLowerCase();
    var filtered  = allAssignments.filter(function(a){
        if (statusVal && a.assignment_status !== statusVal) return false;
        if (typeVal   && a.asset_type        !== typeVal)   return false;
        if (searchVal) {
            var hay = (a.assigned_to_name+' '+a.asset_name+' '+a.asset_no+' '+a.department_name+' '+a.serial_no).toLowerCase();
            if (hay.indexOf(searchVal) === -1) return false;
        }
        return true;
    });
    var grid = $("##assignGrid").dxDataGrid("instance");
    if (grid) {
        grid.option("dataSource", filtered);
        document.getElementById('recordCount').textContent = filtered.length + ' kayıt';
    }
}

function clearFilters() {
    ['filterStatus','filterType'].forEach(function(id){ document.getElementById(id).value=''; });
    document.getElementById('filterSearch').value='';
    applyFilters();
}

function onAssetChange() {
    var sel = document.getElementById('as_asset_id');
    var opt = sel.options[sel.selectedIndex];
    document.getElementById('as_asset_no_display').value = opt.dataset.no  || '';
    document.getElementById('as_brand_display').value    = ((opt.dataset.brand||'')+' '+(opt.dataset.model||'')).trim();
    document.getElementById('as_serial_display').value   = opt.dataset.serial || '';
}

function onUserChange() {
    var sel = document.getElementById('as_user_id');
    var opt = sel.options[sel.selectedIndex];
    if (opt.dataset.fullname) {
        document.getElementById('as_assigned_to_name').value = opt.dataset.fullname;
    }
}

function onDeptChange() {
    var sel = document.getElementById('as_department_id');
    var opt = sel.options[sel.selectedIndex];
    if (opt.dataset.name) {
        document.getElementById('as_department_name').value = opt.dataset.name;
    }
}

function openAssignModal(assignmentId) {
    var row = assignmentId ? allAssignments.find(function(a){ return a.assignment_id === assignmentId; }) : null;

    ['as_assignment_id','as_asset_id','as_user_id','as_department_id'].forEach(function(id){
        document.getElementById(id).value = '';
    });
    ['as_assigned_to_name','as_assigned_to_title','as_department_name',
     'as_assigned_date','as_expected_return_date','as_assigned_by','as_notes',
     'as_asset_no_display','as_brand_display','as_serial_display'].forEach(function(id){
        document.getElementById(id).value = '';
    });
    document.getElementById('as_assignment_status').value = 'ACTIVE';
    document.getElementById('assignSaveMsg').innerHTML = '';
    document.getElementById('assignModalTitle').innerHTML =
        '<i class="fas fa-file-signature me-2"></i>' + (row ? 'Zimmet Düzenle' : 'Yeni Zimmet');

    if (row) {
        document.getElementById('as_assignment_id').value      = row.assignment_id;
        document.getElementById('as_asset_id').value           = row.asset_id;
        document.getElementById('as_assigned_to_name').value   = row.assigned_to_name;
        document.getElementById('as_assigned_to_title').value  = row.assigned_to_title;
        document.getElementById('as_department_name').value    = row.department_name;
        document.getElementById('as_assignment_status').value  = row.assignment_status;
        document.getElementById('as_assigned_by').value        = row.assigned_by;
        document.getElementById('as_notes').value              = row.notes;
        // tarih dönüşümü dd/mm/yyyy -> yyyy-mm-dd
        function toInput(s){ if(!s)return''; var p=s.split('/'); return p.length===3?p[2]+'-'+p[1]+'-'+p[0]:''; }
        document.getElementById('as_assigned_date').value          = toInput(row.assigned_date);
        document.getElementById('as_expected_return_date').value   = toInput(row.expected_return_date);
        onAssetChange();
    } else {
        document.getElementById('as_assigned_date').value = new Date().toISOString().split('T')[0];
    }

    var m = new bootstrap.Modal(document.getElementById('assignModal'));
    m.show();
}

function openReturnModal(assignmentId) {
    var row = allAssignments.find(function(a){ return a.assignment_id === assignmentId; });
    if (!row) return;
    document.getElementById('ret_assignment_id').value = assignmentId;
    document.getElementById('ret_returned_date').value = new Date().toISOString().split('T')[0];
    document.getElementById('ret_condition').value     = 'GOOD';
    document.getElementById('ret_notes').value         = '';
    document.getElementById('returnSaveMsg').innerHTML = '';
    document.getElementById('ret_summary').innerHTML   =
        '<strong>' + row.asset_name + '</strong>' +
        (row.asset_no ? ' (' + row.asset_no + ')' : '') +
        ' — Zimmetli: <strong>' + row.assigned_to_name + '</strong>' +
        (row.department_name ? ' / ' + row.department_name : '') +
        ' — Zimmet Tarihi: <strong>' + row.assigned_date + '</strong>';
    var m = new bootstrap.Modal(document.getElementById('returnModal'));
    m.show();
}

function saveAssignment() {
    var assetId = document.getElementById('as_asset_id').value;
    var name    = document.getElementById('as_assigned_to_name').value.trim();
    var date    = document.getElementById('as_assigned_date').value;
    if (!assetId) { alert('Demirbaş seçin.'); return; }
    if (!name)    { alert('Personel adı zorunludur.'); return; }
    if (!date)    { alert('Zimmet tarihi zorunludur.'); return; }

    var btn = document.getElementById('assignSaveBtn');
    btn.disabled=true; btn.innerHTML='<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url:'/asset/form/save_assignment.cfm', method:'POST', dataType:'json',
        data:{
            assignment_id:        document.getElementById('as_assignment_id').value,
            asset_id:             assetId,
            user_id:              document.getElementById('as_user_id').value,
            assigned_to_name:     name,
            assigned_to_title:    document.getElementById('as_assigned_to_title').value,
            department_id:        document.getElementById('as_department_id').value,
            department_name:      document.getElementById('as_department_name').value,
            assigned_date:        date,
            expected_return_date: document.getElementById('as_expected_return_date').value,
            assigned_by:          document.getElementById('as_assigned_by').value,
            assignment_status:    document.getElementById('as_assignment_status').value,
            notes:                document.getElementById('as_notes').value
        },
        success:function(res){
            btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet';
            if(res&&res.success){
                document.getElementById('assignSaveMsg').innerHTML='<div class="alert alert-success py-2">Zimmet kaydedildi.</div>';
                setTimeout(function(){ location.reload(); },1000);
            } else {
                document.getElementById('assignSaveMsg').innerHTML='<div class="alert alert-danger py-2">'+(res.message||'Hata oluştu.')+'</div>';
            }
        },
        error:function(){
            btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet';
            document.getElementById('assignSaveMsg').innerHTML='<div class="alert alert-danger py-2">Sunucu hatası.</div>';
        }
    });
}

function saveReturn() {
    var id   = document.getElementById('ret_assignment_id').value;
    var date = document.getElementById('ret_returned_date').value;
    if (!date) { alert('İade tarihi girin.'); return; }
    var btn = document.getElementById('returnSaveBtn');
    btn.disabled=true; btn.innerHTML='<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';
    $.ajax({
        url:'/asset/form/return_assignment.cfm', method:'POST', dataType:'json',
        data:{
            assignment_id:    id,
            returned_date:    date,
            return_condition: document.getElementById('ret_condition').value,
            return_notes:     document.getElementById('ret_notes').value
        },
        success:function(res){
            btn.disabled=false; btn.innerHTML='<i class="fas fa-check me-2"></i>İadeyi Onayla';
            if(res&&res.success){
                document.getElementById('returnSaveMsg').innerHTML='<div class="alert alert-success py-2">İade kaydedildi.</div>';
                setTimeout(function(){ location.reload(); },1000);
            } else {
                document.getElementById('returnSaveMsg').innerHTML='<div class="alert alert-danger py-2">'+(res.message||'Hata oluştu.')+'</div>';
            }
        },
        error:function(){
            btn.disabled=false; btn.innerHTML='<i class="fas fa-check me-2"></i>İadeyi Onayla';
            document.getElementById('returnSaveMsg').innerHTML='<div class="alert alert-danger py-2">Sunucu hatası.</div>';
        }
    });
}

function printBelge(assignmentId) {
    var row = allAssignments.find(function(a){ return a.assignment_id === assignmentId; });
    if (!row) return;
    var condTr = { 'GOOD':'İyi Durumda', 'DAMAGED':'Hasarlı', 'LOST':'Kayıp', '':'—' };
    var html = '<div class="zimmet-header">';
    html += '<h3>ZİMMET TUTANAĞI</h3>';
    html += '<p>Düzenleme Tarihi: ' + new Date().toLocaleDateString('tr-TR') + '</p>';
    html += '</div>';
    html += '<table class="zimmet-table">';
    html += '<tr><th colspan="4" style="background:##374151">DEMİRBAŞ BİLGİLERİ</th></tr>';
    html += '<tr><td style="width:20%;font-weight:600">Demirbaş No</td><td>'+row.asset_no+'</td><td style="width:20%;font-weight:600">Varlık Adı</td><td>'+row.asset_name+'</td></tr>';
    html += '<tr><td style="font-weight:600">Marka / Model</td><td>'+(row.brand+' '+row.model).trim()+'</td><td style="font-weight:600">Seri No</td><td>'+row.serial_no+'</td></tr>';
    html += '<tr><th colspan="4" style="background:##374151">ZİMMET BİLGİLERİ</th></tr>';
    html += '<tr><td style="font-weight:600">Zimmet Alan</td><td>'+row.assigned_to_name+'</td><td style="font-weight:600">Unvan</td><td>'+(row.assigned_to_title||'—')+'</td></tr>';
    html += '<tr><td style="font-weight:600">Bölüm</td><td>'+(row.department_name||'—')+'</td><td style="font-weight:600">Zimmet Tarihi</td><td>'+row.assigned_date+'</td></tr>';
    html += '<tr><td style="font-weight:600">Beklenen İade</td><td>'+(row.expected_return_date||'—')+'</td><td style="font-weight:600">Zimmet Veren</td><td>'+(row.assigned_by||'—')+'</td></tr>';
    if (row.returned_date) {
        html += '<tr><th colspan="4" style="background:##15803d">İADE BİLGİLERİ</th></tr>';
        html += '<tr><td style="font-weight:600">İade Tarihi</td><td>'+row.returned_date+'</td><td style="font-weight:600">İade Durumu</td><td>'+(condTr[row.return_condition]||'—')+'</td></tr>';
        if (row.return_notes) html += '<tr><td style="font-weight:600">İade Notu</td><td colspan="3">'+row.return_notes+'</td></tr>';
    }
    if (row.notes) {
        html += '<tr><td style="font-weight:600">Notlar</td><td colspan="3">'+row.notes+'</td></tr>';
    }
    html += '</table>';
    html += '<div class="zimmet-signatures">';
    html += '<div class="zimmet-sign-box">Zimmet Veren<br><br><br><strong>Ad Soyad:</strong> ___________________<br><strong>İmza:</strong></div>';
    html += '<div class="zimmet-sign-box">Zimmet Alan<br><br><br><strong>Ad Soyad:</strong> '+(row.assigned_to_name||'___________________')+'<br><strong>İmza:</strong></div>';
    if (row.returned_date) {
        html += '<div class="zimmet-sign-box">İadeyi Teslim Alan<br><br><br><strong>Ad Soyad:</strong> ___________________<br><strong>İmza:</strong></div>';
    }
    html += '</div>';
    document.getElementById('printArea').innerHTML = html;
    var m = new bootstrap.Modal(document.getElementById('printModal'));
    m.show();
}

function printSelected() {
    var grid = $("##assignGrid").dxDataGrid("instance");
    if (!grid) return;
    var rows = grid.getSelectedRowsData();
    if (rows.length === 0) {
        alert('Listeden bir zimmet kaydı seçin, ardından bu butona tıklayın.');
        return;
    }
    printBelge(rows[0].assignment_id);
}

window.addEventListener('load', function(){
    ['assignModal','returnModal','printModal'].forEach(function(id){
        var m = document.getElementById(id);
        if (m) document.body.appendChild(m);
    });
    renderGrid(allAssignments);
    document.getElementById('filterStatus').addEventListener('change', applyFilters);
    document.getElementById('filterType').addEventListener('change', applyFilters);
    var st;
    document.getElementById('filterSearch').addEventListener('input', function(){
        clearTimeout(st); st = setTimeout(applyFilters, 300);
    });
});
</script>
</cfoutput>
