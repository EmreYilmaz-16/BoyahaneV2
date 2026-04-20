<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getLicenses" datasource="boyahane">
    SELECT l.license_id, l.software_name, l.vendor_name, l.expiry_date,
           l.total_seat, l.used_seat, l.compliance_status,
           l.annual_cost, l.currency, l.purchase_date,
           COALESCE(am.asset_name, '-') AS asset_name
    FROM it_software_licenses l
    LEFT JOIN asset_master am ON am.asset_id = l.asset_id
    ORDER BY l.license_id DESC
</cfquery>

<cfquery name="getITAssets" datasource="boyahane">
    SELECT asset_id, asset_name FROM asset_master
    WHERE asset_type = 'IT' AND asset_status NOT IN ('SCRAPPED','SOLD')
    ORDER BY asset_name
</cfquery>

<cfset licArr    = []>
<cfset cntValid  = 0>
<cfset cntExp    = 0>
<cfset cntOver   = 0>
<cfset today     = now()>

<cfloop query="getLicenses">
    <cfset compLbl = "">
    <cfswitch expression="#compliance_status#">
        <cfcase value="VALID">   <cfset compLbl="Geçerli">   <cfset cntValid++></cfcase>
        <cfcase value="EXPIRED"> <cfset compLbl="Süresi Doldu"><cfset cntExp++></cfcase>
        <cfcase value="OVERUSED"><cfset compLbl="Limit Aşıldı"><cfset cntOver++></cfcase>
        <cfdefaultcase>          <cfset compLbl=compliance_status ?: "Bilinmiyor"></cfdefaultcase>
    </cfswitch>
    <cfset daysLeft = "">
    <cfif isDate(expiry_date)>
        <cfset daysLeft = dateDiff("d", today, expiry_date)>
    </cfif>
    <cfset arrayAppend(licArr, {
        "license_id":        val(license_id),
        "software_name":     software_name ?: "",
        "vendor_name":       vendor_name ?: "-",
        "asset_name":        asset_name ?: "-",
        "purchase_date":     isDate(purchase_date) ? dateFormat(purchase_date,"dd/mm/yyyy") : "",
        "expiry_date":       isDate(expiry_date) ? dateFormat(expiry_date,"dd/mm/yyyy") : "",
        "days_left":         isNumeric(daysLeft) ? val(daysLeft) : 9999,
        "total_seat":        isNumeric(total_seat) ? val(total_seat) : 0,
        "used_seat":         isNumeric(used_seat) ? val(used_seat) : 0,
        "compliance_status": compliance_status ?: "",
        "comp_label":        compLbl,
        "annual_cost":       isNumeric(annual_cost) ? val(annual_cost) : 0,
        "currency":          currency ?: "TRY"
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-key"></i></div>
        <div class="page-header-title">
            <h1>BT Lisans Yönetimi</h1>
            <p>Yazılım lisansları, kullanım durumu ve uyumluluk takibi</p>
        </div>
    </div>
    <button class="btn-add" data-bs-toggle="modal" data-bs-target="#licModal">
        <i class="fas fa-plus"></i>Yeni Lisans
    </button>
</div>

<div class="px-3 pb-4">

    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="summary-card summary-card-blue">
                <div class="summary-icon"><i class="fas fa-key"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Lisans</span>
                    <span class="summary-value"><cfoutput>#getLicenses.recordCount#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-check-circle"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Geçerli</span>
                    <span class="summary-value"><cfoutput>#cntValid#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-clock"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Süresi Dolmuş</span>
                    <span class="summary-value"><cfoutput>#cntExp#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-red">
                <div class="summary-icon"><i class="fas fa-exclamation-triangle"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Limit Aşıldı</span>
                    <span class="summary-value"><cfoutput>#cntOver#</cfoutput></span>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Lisans Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-3">
            <div id="licGrid"></div>
        </div>
    </div>
</div>

<!-- Yeni Lisans Modal -->
<div class="modal fade" id="licModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header" style="background:var(--primary);color:#fff;">
                <h5 class="modal-title"><i class="fas fa-key me-2"></i>Yeni Lisans Kaydı</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Yazılım Adı *</label>
                        <input type="text" id="l_software_name" class="form-control" maxlength="150">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Tedarikçi</label>
                        <input type="text" id="l_vendor_name" class="form-control" maxlength="150">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">BT Varlığı</label>
                        <select id="l_asset_id" class="form-select">
                            <option value="">Bağlı değil</option>
                            <cfoutput query="getITAssets">
                                <option value="#asset_id#">#encodeForHTML(asset_name)#</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Lisans Anahtarı</label>
                        <input type="text" id="l_license_key" class="form-control" maxlength="250">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Toplam Koltuk</label>
                        <input type="number" min="1" id="l_total_seat" class="form-control" value="1">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Kullanılan</label>
                        <input type="number" min="0" id="l_used_seat" class="form-control" value="0">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Satın Alma</label>
                        <input type="date" id="l_purchase_date" class="form-control">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Bitiş Tarihi</label>
                        <input type="date" id="l_expiry_date" class="form-control">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Uyumluluk</label>
                        <select id="l_compliance_status" class="form-select">
                            <option value="VALID">Geçerli</option>
                            <option value="EXPIRED">Süresi Doldu</option>
                            <option value="OVERUSED">Limit Aşıldı</option>
                            <option value="UNKNOWN">Bilinmiyor</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Yıllık Maliyet</label>
                        <input type="number" step="0.01" min="0" id="l_annual_cost" class="form-control" value="0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Para Birimi</label>
                        <input type="text" maxlength="10" id="l_currency" class="form-control" value="TRY">
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Not</label>
                        <input type="text" id="l_note" class="form-control">
                    </div>
                </div>
                <div id="licSaveMsg" class="mt-2"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-warning text-dark fw-bold" id="licSaveBtn" onclick="saveLic()">
                    <i class="fas fa-save me-2"></i>Kaydet
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
.badge-c { display:inline-block;padding:3px 10px;border-radius:10px;font-size:.72rem;font-weight:600; }
.bc-VALID   { background:##dcfce7;color:##15803d; }
.bc-EXPIRED { background:##fee2e2;color:##b91c1c; }
.bc-OVERUSED{ background:##fef3c7;color:##92400e; }
.bc-UNKNOWN { background:##f3f4f6;color:##6b7280; }
</style>
<script>
var allLic = #serializeJSON(licArr)#;

var cBadge = {
    'VALID':   '<span class="badge-c bc-VALID">Geçerli</span>',
    'EXPIRED': '<span class="badge-c bc-EXPIRED">Süresi Doldu</span>',
    'OVERUSED':'<span class="badge-c bc-OVERUSED">Limit Aşıldı</span>',
    'UNKNOWN': '<span class="badge-c bc-UNKNOWN">Bilinmiyor</span>'
};

window.addEventListener('load', function(){
    var lm = document.getElementById('licModal');
    if (lm) document.body.appendChild(lm);

    document.getElementById('recordCount').textContent = allLic.length + ' kayıt';
    $("##licGrid").dxDataGrid({
        dataSource: allLic, keyExpr:"license_id",
        showBorders:false, showRowLines:true, showColumnLines:false,
        rowAlternationEnabled:true, hoverStateEnabled:true,
        paging:{ pageSize:25 },
        pager:{ showPageSizeSelector:true, allowedPageSizes:[25,50,100], showInfo:true },
        sorting:{ mode:"multiple" },
        export:{ enabled:true, fileName:"bt_lisanslari" },
        headerFilter:{ visible:true },
        columns:[
            { dataField:"license_id",   caption:"##",         width:65, alignment:"center", sortOrder:"desc" },
            { dataField:"software_name",caption:"Yazılım",   minWidth:160 },
            { dataField:"vendor_name",  caption:"Tedarikçi", width:140 },
            { dataField:"asset_name",   caption:"BT Varlığı",width:150 },
            { dataField:"total_seat",   caption:"Koltuk",    width:80, alignment:"center" },
            {
                dataField:"used_seat", caption:"Kullanım", width:95, alignment:"center",
                cellTemplate: function(el,i){
                    var pct = i.data.total_seat > 0 ? Math.round(i.value/i.data.total_seat*100) : 0;
                    var col = pct >= 100 ? '##ef4444' : pct >= 80 ? '##f59e0b' : '##22c55e';
                    el.html('<span style="color:'+col+';font-weight:600;">'+i.value+' / '+i.data.total_seat+'</span>');
                }
            },
            { dataField:"purchase_date",caption:"Satın Alma",width:110, alignment:"center" },
            {
                dataField:"expiry_date", caption:"Bitiş", width:110, alignment:"center",
                cellTemplate: function(el,i){
                    var d = i.data.days_left;
                    var color = d < 0 ? '##ef4444' : d < 30 ? '##f59e0b' : '##374151';
                    el.html('<span style="color:'+color+';font-weight:'+(d<30?'600':'400')+'">'+i.value+'</span>');
                }
            },
            {
                dataField:"annual_cost", caption:"Yıllık Maliyet", width:130, alignment:"right",
                cellTemplate: function(el,i){
                    el.text((parseFloat(i.value||0)).toLocaleString('tr-TR',{minimumFractionDigits:2,maximumFractionDigits:2})+' '+(i.data.currency||'TRY'));
                }
            },
            {
                dataField:"compliance_status", caption:"Uyumluluk", width:130, alignment:"center",
                cellTemplate: function(el,i){ el.html(cBadge[i.value] || i.value || '-'); }
            }
        ]
    });
});

function saveLic() {
    var name = document.getElementById('l_software_name').value.trim();
    if (!name) { alert('Yazılım adı zorunludur.'); return; }
    var btn = document.getElementById('licSaveBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';
    $.ajax({
        url:'/asset/form/save_it_license.cfm', method:'POST', dataType:'json',
        data:{
            software_name:     name,
            vendor_name:       document.getElementById('l_vendor_name').value,
            asset_id:          document.getElementById('l_asset_id').value,
            license_key:       document.getElementById('l_license_key').value,
            total_seat:        document.getElementById('l_total_seat').value,
            used_seat:         document.getElementById('l_used_seat').value,
            purchase_date:     document.getElementById('l_purchase_date').value,
            expiry_date:       document.getElementById('l_expiry_date').value,
            compliance_status: document.getElementById('l_compliance_status').value,
            annual_cost:       document.getElementById('l_annual_cost').value,
            currency:          document.getElementById('l_currency').value,
            note:              document.getElementById('l_note').value
        },
        success: function(res){
            btn.disabled = false; btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet';
            if (res && res.success) {
                document.getElementById('licSaveMsg').innerHTML = '<div class="alert alert-success py-2">Lisans kaydedildi.</div>';
                setTimeout(function(){ location.reload(); }, 1200);
            } else {
                document.getElementById('licSaveMsg').innerHTML = '<div class="alert alert-danger py-2">'+(res.message||'Hata oluştu.')+'</div>';
            }
        },
        error: function(){
            btn.disabled = false; btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet';
            document.getElementById('licSaveMsg').innerHTML = '<div class="alert alert-danger py-2">Sunucu hatası.</div>';
        }
    });
}
</script>
</cfoutput>