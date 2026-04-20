<cfprocessingdirective pageEncoding="utf-8">

<!--- ── BT Servis Log Listesi ── --->
<cfquery name="getLogs" datasource="boyahane">
    SELECT
        sl.log_id,
        sl.asset_id,
        am.asset_name,
        am.asset_no,
        am.brand,
        am.model,
        am.serial_no,
        sl.log_type,
        TO_CHAR(sl.log_date,'DD/MM/YYYY')     AS log_date,
        sl.problem_description,
        sl.resolution_notes,
        sl.component_changed,
        sl.technician_name,
        sl.is_warranty,
        COALESCE(sl.service_cost,0)           AS service_cost,
        sl.status,
        TO_CHAR(sl.record_date,'DD/MM/YYYY')  AS record_date
    FROM it_service_logs sl
    INNER JOIN asset_master am ON am.asset_id = sl.asset_id
    ORDER BY sl.log_id DESC
    LIMIT 1000
</cfquery>

<!--- Sadece BT varlıkları --->
<cfquery name="getITAssets" datasource="boyahane">
    SELECT asset_id, asset_no, asset_name, brand, model, serial_no
    FROM asset_master
    WHERE asset_type = 'IT'
      AND asset_status NOT IN ('SCRAPPED','SOLD')
    ORDER BY asset_name
</cfquery>

<!--- Stats --->
<cfset logArr    = []>
<cfset cntOpen   = 0>
<cfset cntIP     = 0>
<cfset cntDone   = 0>
<cfset cntCancel = 0>
<cfset totalCost = 0>

<cfloop query="getLogs">
    <cfset typeLbl = "">
    <cfswitch expression="#log_type#">
        <cfcase value="REPAIR">          <cfset typeLbl="Onarım/Arıza"></cfcase>
        <cfcase value="SOFTWARE_UPDATE"> <cfset typeLbl="Yazılım Güncelleme"></cfcase>
        <cfcase value="FORMAT">          <cfset typeLbl="Format/Yeniden Kurulum"></cfcase>
        <cfcase value="COMPONENT_CHANGE"><cfset typeLbl="Parça Değişimi"></cfcase>
        <cfcase value="ANTIVIRUS">       <cfset typeLbl="Antivirüs"></cfcase>
        <cfcase value="NETWORK_CONFIG">  <cfset typeLbl="Ağ Yapılandırması"></cfcase>
        <cfcase value="OTHER">           <cfset typeLbl="Diğer"></cfcase>
        <cfdefaultcase>                  <cfset typeLbl=log_type></cfdefaultcase>
    </cfswitch>

    <cfset statusLbl = "">
    <cfswitch expression="#status#">
        <cfcase value="OPEN">        <cfset statusLbl="Açık">         <cfset cntOpen++></cfcase>
        <cfcase value="IN_PROGRESS"> <cfset statusLbl="Devam Ediyor"> <cfset cntIP++></cfcase>
        <cfcase value="COMPLETED">   <cfset statusLbl="Tamamlandı">   <cfset cntDone++></cfcase>
        <cfcase value="CANCELLED">   <cfset statusLbl="İptal">        <cfset cntCancel++></cfcase>
        <cfdefaultcase>              <cfset statusLbl=status></cfdefaultcase>
    </cfswitch>

    <cfset totalCost += val(service_cost)>

    <cfset arrayAppend(logArr, {
        "log_id":               val(log_id),
        "asset_id":             val(asset_id),
        "asset_name":           asset_name          ?: "",
        "asset_no":             asset_no            ?: "",
        "brand":                brand               ?: "",
        "model":                model               ?: "",
        "serial_no":            serial_no           ?: "",
        "log_type":             log_type            ?: "",
        "type_label":           typeLbl,
        "log_date":             log_date            ?: "",
        "problem_description":  problem_description ?: "",
        "resolution_notes":     resolution_notes    ?: "",
        "component_changed":    component_changed   ?: "",
        "technician_name":      technician_name     ?: "",
        "is_warranty":          (is_warranty eq "true" or is_warranty eq true),
        "service_cost":         val(service_cost),
        "status":               status              ?: "",
        "status_label":         statusLbl
    })>
</cfloop>

<!--- ── HTML ── --->
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-laptop-medical"></i></div>
        <div class="page-header-title">
            <h1>BT Servis &amp; Bakım</h1>
            <p>BT cihazlarına ait arıza, bakım, güncelleme ve parça değişim kayıtları</p>
        </div>
    </div>
    <button class="btn-add" onclick="openLogModal(0)">
        <i class="fas fa-plus"></i>Yeni Kayıt
    </button>
</div>

<div class="px-3 pb-4">

    <!--- Özet Kartlar --->
    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="summary-card summary-card-blue">
                <div class="summary-icon"><i class="fas fa-clipboard-list"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Açık</span>
                    <span class="summary-value"><cfoutput>#cntOpen#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-spinner"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Devam Ediyor</span>
                    <span class="summary-value"><cfoutput>#cntIP#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-check-circle"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Tamamlandı</span>
                    <span class="summary-value"><cfoutput>#cntDone#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-teal">
                <div class="summary-icon"><i class="fas fa-lira-sign"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Maliyet</span>
                    <span class="summary-value"><cfoutput>#numberFormat(totalCost,"_.__")#</cfoutput></span>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Servis Kayıtları</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-3">
            <div class="row g-2 mb-3">
                <div class="col-md-2">
                    <select id="filterStatus" class="form-select form-select-sm">
                        <option value="">Tüm Durumlar</option>
                        <option value="OPEN">Açık</option>
                        <option value="IN_PROGRESS">Devam Ediyor</option>
                        <option value="COMPLETED">Tamamlandı</option>
                        <option value="CANCELLED">İptal</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <select id="filterType" class="form-select form-select-sm">
                        <option value="">Tüm Tipler</option>
                        <option value="REPAIR">Onarım/Arıza</option>
                        <option value="SOFTWARE_UPDATE">Yazılım Güncelleme</option>
                        <option value="FORMAT">Format/Yeniden Kurulum</option>
                        <option value="COMPONENT_CHANGE">Parça Değişimi</option>
                        <option value="ANTIVIRUS">Antivirüs</option>
                        <option value="NETWORK_CONFIG">Ağ Yapılandırması</option>
                        <option value="OTHER">Diğer</option>
                    </select>
                </div>
                <div class="col-md-2">
                    <select id="filterWarranty" class="form-select form-select-sm">
                        <option value="">Garanti Durumu</option>
                        <option value="true">Garanti Kapsamında</option>
                        <option value="false">Garanti Dışı</option>
                    </select>
                </div>
                <div class="col-md-4">
                    <input type="text" id="filterSearch" class="form-control form-control-sm" placeholder="Cihaz / teknisyen / arıza tanımı ara...">
                </div>
                <div class="col-md-2">
                    <button class="btn btn-outline-secondary btn-sm w-100" onclick="clearFilters()">
                        <i class="fas fa-eraser me-1"></i>Temizle
                    </button>
                </div>
            </div>
            <div id="itServiceGrid"></div>
        </div>
    </div>
</div>

<!--- ── Servis Log Modal ── --->
<div class="modal fade" id="logModal" tabindex="-1">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header" style="background:var(--primary);color:#fff;">
                <h5 class="modal-title" id="logModalTitle">
                    <i class="fas fa-laptop-medical me-2"></i>Yeni Servis Kaydı
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="sl_log_id">
                <div class="row g-3">
                    <div class="col-12">
                        <label class="form-label fw-semibold">BT Cihazı <span class="text-danger">*</span></label>
                        <select id="sl_asset_id" class="form-select" onchange="onITAssetChange()">
                            <option value="">Seçiniz...</option>
                            <cfoutput query="getITAssets">
                                <option value="#asset_id#"
                                    data-no="#encodeForHTMLAttribute(asset_no)#"
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
                    <div class="col-md-3">
                        <label class="form-label fw-semibold text-muted small">Demirbaş No</label>
                        <input type="text" id="sl_asset_no_d" class="form-control form-control-sm" readonly style="background:#f9fafb;">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold text-muted small">Marka / Model</label>
                        <input type="text" id="sl_brand_d" class="form-control form-control-sm" readonly style="background:#f9fafb;">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold text-muted small">Seri No</label>
                        <input type="text" id="sl_serial_d" class="form-control form-control-sm" readonly style="background:#f9fafb;">
                    </div>

                    <div class="col-12"><hr class="my-1"><small class="text-muted fw-semibold text-uppercase">İşlem Bilgileri</small></div>

                    <div class="col-md-3">
                        <label class="form-label fw-semibold">İşlem Tipi <span class="text-danger">*</span></label>
                        <select id="sl_log_type" class="form-select">
                            <option value="REPAIR">Onarım / Arıza</option>
                            <option value="SOFTWARE_UPDATE">Yazılım Güncelleme</option>
                            <option value="FORMAT">Format / Yeniden Kurulum</option>
                            <option value="COMPONENT_CHANGE">Parça Değişimi</option>
                            <option value="ANTIVIRUS">Antivirüs</option>
                            <option value="NETWORK_CONFIG">Ağ Yapılandırması</option>
                            <option value="OTHER">Diğer</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">İşlem Tarihi <span class="text-danger">*</span></label>
                        <input type="date" id="sl_log_date" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Durum</label>
                        <select id="sl_status" class="form-select">
                            <option value="OPEN">Açık</option>
                            <option value="IN_PROGRESS">Devam Ediyor</option>
                            <option value="COMPLETED">Tamamlandı</option>
                            <option value="CANCELLED">İptal</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Servis Maliyeti (₺)</label>
                        <input type="number" id="sl_service_cost" class="form-control" step="0.01" min="0" value="0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Teknisyen / Servis</label>
                        <input type="text" id="sl_technician_name" class="form-control" maxlength="150" placeholder="Teknisyen adı veya servis firması">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Değiştirilen Parça</label>
                        <input type="text" id="sl_component_changed" class="form-control" maxlength="200" placeholder="Örn: RAM 8GB, SSD 256GB, Batarya...">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Garanti</label>
                        <div class="form-check mt-2">
                            <input class="form-check-input" type="checkbox" id="sl_is_warranty">
                            <label class="form-check-label" for="sl_is_warranty">Garanti kapsamında işlem</label>
                        </div>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Arıza / Sorun Tanımı</label>
                        <textarea id="sl_problem_description" class="form-control" rows="2" placeholder="Bildirilen arıza veya talep açıklaması..."></textarea>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Yapılan İşlem / Çözüm</label>
                        <textarea id="sl_resolution_notes" class="form-control" rows="2" placeholder="Yapılan işlemin özeti, çözüm yöntemi..."></textarea>
                    </div>
                </div>
                <div id="logSaveMsg" class="mt-3"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-danger me-auto" id="logDeleteBtn" onclick="deleteLog()" style="display:none;">
                    <i class="fas fa-trash me-2"></i>Sil
                </button>
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-primary" id="logSaveBtn" onclick="saveLog()">
                    <i class="fas fa-save me-2"></i>Kaydet
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
.summary-card-teal   { background:linear-gradient(135deg,##0f766e,##14b8a6); }
.summary-icon  { font-size:1.8rem;opacity:.85; }
.summary-label { font-size:.75rem;opacity:.85;display:block; }
.summary-value { font-size:1.6rem;font-weight:700;display:block; }
.grid-card     { background:##fff;border-radius:10px;box-shadow:0 2px 12px rgba(0,0,0,.07);overflow:hidden; }
.grid-card-header { padding:14px 20px 12px;border-bottom:1px solid ##e9ecef;display:flex;align-items:center;justify-content:space-between; }
.grid-card-header-title { font-size:.95rem;font-weight:700;color:var(--primary);display:flex;align-items:center;gap:8px; }
.badge-sl { display:inline-block;padding:3px 10px;border-radius:10px;font-size:.72rem;font-weight:600; }
.bsl-OPEN        { background:##dbeafe;color:##1e40af; }
.bsl-IN_PROGRESS { background:##fef3c7;color:##92400e; }
.bsl-COMPLETED   { background:##dcfce7;color:##15803d; }
.bsl-CANCELLED   { background:##f3f4f6;color:##6b7280; }
.badge-warranty  { display:inline-block;padding:2px 8px;border-radius:8px;font-size:.68rem;font-weight:600;background:##dcfce7;color:##15803d; }
##logModal { z-index:99999 !important; }
.modal-backdrop { z-index:99998 !important; }
</style>

<script>
var allLogs = #serializeJSON(logArr)#;

var statusBadge = {
    'OPEN':        '<span class="badge-sl bsl-OPEN"><i class="fas fa-clock me-1"></i>Açık</span>',
    'IN_PROGRESS': '<span class="badge-sl bsl-IN_PROGRESS"><i class="fas fa-spinner me-1"></i>Devam</span>',
    'COMPLETED':   '<span class="badge-sl bsl-COMPLETED"><i class="fas fa-check me-1"></i>Tamamlandı</span>',
    'CANCELLED':   '<span class="badge-sl bsl-CANCELLED"><i class="fas fa-ban me-1"></i>İptal</span>'
};

var typeColors = {
    'REPAIR':          'background:##fee2e2;color:##b91c1c',
    'SOFTWARE_UPDATE': 'background:##ede9fe;color:##6d28d9',
    'FORMAT':          'background:##fef3c7;color:##92400e',
    'COMPONENT_CHANGE':'background:##dbeafe;color:##1e40af',
    'ANTIVIRUS':       'background:##dcfce7;color:##15803d',
    'NETWORK_CONFIG':  'background:##e0f2fe;color:##0369a1',
    'OTHER':           'background:##f3f4f6;color:##374151'
};

function renderGrid(data) {
    document.getElementById('recordCount').textContent = data.length + ' kayıt';
    $("##itServiceGrid").dxDataGrid({
        dataSource: data,
        keyExpr: "log_id",
        showBorders: false, showRowLines: true, showColumnLines: false,
        rowAlternationEnabled: true, hoverStateEnabled: true,
        paging:  { pageSize: 25 },
        pager:   { showPageSizeSelector:true, allowedPageSizes:[25,50,100], showInfo:true },
        sorting: { mode:"multiple" },
        export:  { enabled:true, fileName:"bt_servis_kayitlari" },
        headerFilter: { visible:true },
        masterDetail: {
            enabled: true,
            template: function(container, info) {
                var d = info.data;
                var html = '<div class="p-3" style="background:##f8fafc;border-left:3px solid ##2563ab;">';
                if (d.problem_description) html += '<p class="mb-1"><strong><i class="fas fa-exclamation-circle text-danger me-1"></i>Arıza Tanımı:</strong> ' + d.problem_description + '</p>';
                if (d.resolution_notes)    html += '<p class="mb-1"><strong><i class="fas fa-check-circle text-success me-1"></i>Yapılan İşlem:</strong> ' + d.resolution_notes + '</p>';
                if (d.component_changed)   html += '<p class="mb-1"><strong><i class="fas fa-puzzle-piece text-primary me-1"></i>Değiştirilen Parça:</strong> ' + d.component_changed + '</p>';
                if (!d.problem_description && !d.resolution_notes && !d.component_changed) html += '<span class="text-muted">Ek detay girilmemiş.</span>';
                html += '</div>';
                container.html(html);
            }
        },
        columns: [
            { dataField:"log_id", caption:"", width:65, alignment:"center", sortOrder:"desc" },
            {
                dataField:"log_type", caption:"İşlem Tipi", width:155,
                cellTemplate: function(el,i){
                    var s = typeColors[i.value]||'background:##f3f4f6;color:##374151';
                    el.html('<span style="display:inline-block;padding:2px 9px;border-radius:8px;font-size:.72rem;font-weight:600;'+s+'">'+(i.data.type_label||i.value)+'</span>');
                }
            },
            { dataField:"log_date",      caption:"Tarih",    width:95, alignment:"center" },
            { dataField:"asset_no",      caption:"Demirbaş No", width:110 },
            { dataField:"asset_name",    caption:"Cihaz Adı",   minWidth:150 },
            { dataField:"brand",         caption:"Marka/Model",  width:130,
              cellTemplate: function(el,i){ el.text(((i.data.brand||'')+' '+(i.data.model||'')).trim()||'—'); }
            },
            { dataField:"serial_no",       caption:"Seri No",     width:120 },
            { dataField:"technician_name", caption:"Teknisyen",    width:130,
              cellTemplate: function(el,i){ el.text(i.value||'—'); }
            },
            {
                dataField:"is_warranty", caption:"Garanti", width:90, alignment:"center",
                cellTemplate: function(el,i){
                    el.html(i.value ? '<span class="badge-warranty"><i class="fas fa-shield-alt me-1"></i>Evet</span>' : '<span style="color:##9ca3af;font-size:.8rem;">—</span>');
                }
            },
            { dataField:"service_cost", caption:"Maliyet (₺)", width:110, alignment:"right",
              format: { type:"fixedPoint", precision:2 }
            },
            {
                dataField:"status", caption:"Durum", width:120, alignment:"center",
                cellTemplate: function(el,i){ el.html(statusBadge[i.value]||i.value||'—'); }
            },
            {
                caption:"İşlem", width:80, alignment:"center", allowSorting:false, allowFiltering:false,
                cellTemplate: function(el,i){
                    el.html('<button class="btn btn-xs btn-outline-primary py-0 px-2" onclick="openLogModal('+i.data.log_id+')" title="Düzenle"><i class="fas fa-pen"></i></button>');
                }
            }
        ]
    });
}

function applyFilters() {
    var statusVal  = document.getElementById('filterStatus').value;
    var typeVal    = document.getElementById('filterType').value;
    var warrantyV  = document.getElementById('filterWarranty').value;
    var searchVal  = (document.getElementById('filterSearch').value||'').trim().toLowerCase();
    var filtered   = allLogs.filter(function(r){
        if (statusVal  && r.status    !== statusVal)  return false;
        if (typeVal    && r.log_type  !== typeVal)    return false;
        if (warrantyV  !== '') {
            var w = warrantyV === 'true';
            if (r.is_warranty !== w) return false;
        }
        if (searchVal) {
            var hay = (r.asset_name+' '+r.asset_no+' '+r.technician_name+' '+r.problem_description+' '+r.serial_no).toLowerCase();
            if (hay.indexOf(searchVal) === -1) return false;
        }
        return true;
    });
    var grid = $("##itServiceGrid").dxDataGrid("instance");
    if (grid) {
        grid.option("dataSource", filtered);
        document.getElementById('recordCount').textContent = filtered.length + ' kayıt';
    }
}

function clearFilters() {
    ['filterStatus','filterType','filterWarranty'].forEach(function(id){ document.getElementById(id).value=''; });
    document.getElementById('filterSearch').value='';
    applyFilters();
}

function onITAssetChange() {
    var sel = document.getElementById('sl_asset_id');
    var opt = sel.options[sel.selectedIndex];
    document.getElementById('sl_asset_no_d').value = opt.dataset.no     || '';
    document.getElementById('sl_brand_d').value    = ((opt.dataset.brand||'')+' '+(opt.dataset.model||'')).trim();
    document.getElementById('sl_serial_d').value   = opt.dataset.serial || '';
}

function openLogModal(logId) {
    var row = logId ? allLogs.find(function(r){ return r.log_id === logId; }) : null;

    document.getElementById('sl_log_id').value    = '';
    document.getElementById('sl_asset_id').value  = '';
    document.getElementById('sl_log_type').value  = 'REPAIR';
    document.getElementById('sl_status').value    = 'OPEN';
    document.getElementById('sl_service_cost').value = '0';
    document.getElementById('sl_is_warranty').checked = false;
    ['sl_technician_name','sl_component_changed','sl_problem_description',
     'sl_resolution_notes','sl_asset_no_d','sl_brand_d','sl_serial_d'].forEach(function(id){
        document.getElementById(id).value = '';
    });
    document.getElementById('logSaveMsg').innerHTML = '';
    document.getElementById('logDeleteBtn').style.display = 'none';
    document.getElementById('logModalTitle').innerHTML =
        '<i class="fas fa-laptop-medical me-2"></i>' + (row ? 'Servis Kaydı Düzenle' : 'Yeni Servis Kaydı');

    if (row) {
        document.getElementById('sl_log_id').value           = row.log_id;
        document.getElementById('sl_asset_id').value         = row.asset_id;
        document.getElementById('sl_log_type').value         = row.log_type;
        document.getElementById('sl_status').value           = row.status;
        document.getElementById('sl_service_cost').value     = row.service_cost;
        document.getElementById('sl_is_warranty').checked    = row.is_warranty;
        document.getElementById('sl_technician_name').value  = row.technician_name;
        document.getElementById('sl_component_changed').value= row.component_changed;
        document.getElementById('sl_problem_description').value = row.problem_description;
        document.getElementById('sl_resolution_notes').value    = row.resolution_notes;
        function toInput(s){ if(!s)return''; var p=s.split('/'); return p.length===3?p[2]+'-'+p[1]+'-'+p[0]:''; }
        document.getElementById('sl_log_date').value = toInput(row.log_date);
        onITAssetChange();
        document.getElementById('logDeleteBtn').style.display = '';
    } else {
        document.getElementById('sl_log_date').value = new Date().toISOString().split('T')[0];
    }

    var m = new bootstrap.Modal(document.getElementById('logModal'));
    m.show();
}

function saveLog() {
    var assetId = document.getElementById('sl_asset_id').value;
    var logDate = document.getElementById('sl_log_date').value;
    if (!assetId) { alert('Cihaz seçin.'); return; }
    if (!logDate) { alert('Tarih girin.'); return; }

    var btn = document.getElementById('logSaveBtn');
    btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url: '/asset/form/save_it_service_log.cfm', method: 'POST', dataType: 'json',
        data: {
            log_id:               document.getElementById('sl_log_id').value,
            asset_id:             assetId,
            log_type:             document.getElementById('sl_log_type').value,
            log_date:             logDate,
            status:               document.getElementById('sl_status').value,
            service_cost:         document.getElementById('sl_service_cost').value,
            is_warranty:          document.getElementById('sl_is_warranty').checked ? '1' : '0',
            technician_name:      document.getElementById('sl_technician_name').value,
            component_changed:    document.getElementById('sl_component_changed').value,
            problem_description:  document.getElementById('sl_problem_description').value,
            resolution_notes:     document.getElementById('sl_resolution_notes').value
        },
        success: function(res) {
            btn.disabled = false; btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet';
            if (res && res.success) {
                document.getElementById('logSaveMsg').innerHTML = '<div class="alert alert-success py-2">Kayıt kaydedildi.</div>';
                setTimeout(function(){ location.reload(); }, 1000);
            } else {
                document.getElementById('logSaveMsg').innerHTML = '<div class="alert alert-danger py-2">'+(res.message||'Hata oluştu.')+'</div>';
            }
        },
        error: function() {
            btn.disabled = false; btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet';
            document.getElementById('logSaveMsg').innerHTML = '<div class="alert alert-danger py-2">Sunucu hatası.</div>';
        }
    });
}

function deleteLog() {
    var logId = document.getElementById('sl_log_id').value;
    if (!logId) return;
    if (!confirm('Bu servis kaydı silinecek. Onaylıyor musunuz?')) return;
    $.ajax({
        url: '/asset/form/save_it_service_log.cfm', method: 'POST', dataType: 'json',
        data: { log_id: logId, action: 'delete' },
        success: function(res) {
            if (res && res.success) { location.reload(); }
            else { alert(res.message||'Silme hatası.'); }
        }
    });
}

window.addEventListener('load', function(){
    var m = document.getElementById('logModal');
    if (m) document.body.appendChild(m);
    renderGrid(allLogs);
    document.getElementById('filterStatus').addEventListener('change', applyFilters);
    document.getElementById('filterType').addEventListener('change', applyFilters);
    document.getElementById('filterWarranty').addEventListener('change', applyFilters);
    var st;
    document.getElementById('filterSearch').addEventListener('input', function(){
        clearTimeout(st); st = setTimeout(applyFilters, 300);
    });
});
</script>
</cfoutput>
