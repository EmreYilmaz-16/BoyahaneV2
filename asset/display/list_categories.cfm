<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getCategories" datasource="boyahane">
    SELECT c.category_id,
           c.category_code,
           c.category_name,
           c.asset_type,
           c.parent_id,
           c.is_active,
           p.category_name AS parent_name,
           (SELECT COUNT(*) FROM asset_master am WHERE am.category_id = c.category_id) AS asset_count
    FROM asset_categories c
    LEFT JOIN asset_categories p ON p.category_id = c.parent_id
    ORDER BY c.asset_type, c.category_name
</cfquery>

<cfset catArr = []>
<cfset cntPhysical = 0>
<cfset cntIT       = 0>
<cfset cntVehicle  = 0>
<cfset cntActive   = 0>

<cfloop query="getCategories">
    <cfset typeLbl = "">
    <cfswitch expression="#asset_type#">
        <cfcase value="PHYSICAL"><cfset typeLbl = "Fiziki"></cfcase>
        <cfcase value="IT">      <cfset typeLbl = "BT"></cfcase>
        <cfcase value="VEHICLE"> <cfset typeLbl = "Araç"></cfcase>
        <cfdefaultcase><cfset typeLbl = asset_type></cfdefaultcase>
    </cfswitch>
    <cfif asset_type eq "PHYSICAL"><cfset cntPhysical++></cfif>
    <cfif asset_type eq "IT">      <cfset cntIT++></cfif>
    <cfif asset_type eq "VEHICLE"> <cfset cntVehicle++></cfif>
    <cfif is_active>               <cfset cntActive++></cfif>
    <cfset arrayAppend(catArr, {
        "category_id":   val(category_id),
        "category_code": category_code ?: "",
        "category_name": category_name ?: "",
        "asset_type":    asset_type    ?: "",
        "type_label":    typeLbl,
        "parent_id":     val(parent_id ?: 0),
        "parent_name":   parent_name   ?: "",
        "is_active":     is_active,
        "asset_count":   val(asset_count)
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-tags"></i></div>
        <div class="page-header-title">
            <h1>Varlık Kategorileri</h1>
            <p>Kategori tanımlayın ve düzenleyin</p>
        </div>
    </div>
    <button class="btn-add" onclick="openCatModal(0)">
        <i class="fas fa-plus"></i>Yeni Kategori
    </button>
</div>

<div class="px-3 pb-4">

    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="summary-card summary-card-blue">
                <div class="summary-icon"><i class="fas fa-tags"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam</span>
                    <span class="summary-value"><cfoutput>#getCategories.recordCount#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-check-circle"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Aktif</span>
                    <span class="summary-value"><cfoutput>#cntActive#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="summary-card" style="background:linear-gradient(135deg,##0f4c75,##1b6ca8);color:##fff;box-shadow:0 2px 10px rgba(0,0,0,.12);">
                <div class="summary-icon"><i class="fas fa-industry"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Fiziki</span>
                    <span class="summary-value"><cfoutput>#cntPhysical#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="summary-card summary-card-purple">
                <div class="summary-icon"><i class="fas fa-laptop"></i></div>
                <div class="summary-info">
                    <span class="summary-label">BT</span>
                    <span class="summary-value"><cfoutput>#cntIT#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-2">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-truck"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Araç</span>
                    <span class="summary-value"><cfoutput>#cntVehicle#</cfoutput></span>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Kategori Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-3">
            <div class="row g-2 mb-3">
                <div class="col-md-3">
                    <select id="filterType" class="form-select form-select-sm">
                        <option value="">Tüm Tipler</option>
                        <option value="PHYSICAL">Fiziki</option>
                        <option value="IT">BT</option>
                        <option value="VEHICLE">Araç</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <select id="filterActive" class="form-select form-select-sm">
                        <option value="">Tüm Durumlar</option>
                        <option value="true">Aktif</option>
                        <option value="false">Pasif</option>
                    </select>
                </div>
                <div class="col-md-4">
                    <input type="text" id="filterSearch" class="form-control form-control-sm" placeholder="Kod veya ad ara...">
                </div>
                <div class="col-md-2">
                    <button class="btn btn-outline-secondary btn-sm w-100" onclick="clearFilters()">
                        <i class="fas fa-eraser me-1"></i>Temizle
                    </button>
                </div>
            </div>
            <div id="catGrid"></div>
        </div>
    </div>
</div>

<!-- Kategori Modal -->
<div class="modal fade" id="catModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header" style="background:var(--primary);color:##fff;">
                <h5 class="modal-title" id="catModalTitle">
                    <i class="fas fa-tag me-2"></i>Kategori
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="c_category_id">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Kategori Kodu</label>
                        <input type="text" id="c_category_code" class="form-control" maxlength="50" placeholder="PHYS-001">
                        <small class="text-muted">Boş bırakılabilir, sistem oluşturabilir</small>
                    </div>
                    <div class="col-md-9">
                        <label class="form-label fw-semibold">Kategori Adı <span class="text-danger">*</span></label>
                        <input type="text" id="c_category_name" class="form-control" maxlength="150" placeholder="Ör: Bilgisayarlar, Binek Araçlar...">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Varlık Tipi <span class="text-danger">*</span></label>
                        <select id="c_asset_type" class="form-select" onchange="filterParents()">
                            <option value="">Seçiniz</option>
                            <option value="PHYSICAL">Fiziki Varlık</option>
                            <option value="IT">BT Varlığı</option>
                            <option value="VEHICLE">Araç</option>
                        </select>
                    </div>
                    <div class="col-md-5">
                        <label class="form-label fw-semibold">Üst Kategori</label>
                        <select id="c_parent_id" class="form-select">
                            <option value="">— Üst kategori yok —</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Durum</label>
                        <select id="c_is_active" class="form-select">
                            <option value="true">Aktif</option>
                            <option value="false">Pasif</option>
                        </select>
                    </div>
                </div>
                <div id="catSaveMsg" class="mt-3"></div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-outline-danger me-auto" id="catDeleteBtn" onclick="deleteCategory()" style="display:none;">
                    <i class="fas fa-trash me-1"></i>Sil
                </button>
                <button class="btn btn-outline-secondary" data-bs-dismiss="modal">Kapat</button>
                <button class="btn btn-primary" id="catSaveBtn" onclick="saveCategory()">
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
.summary-card-orange { background:linear-gradient(135deg,##92400e,##f59e0b); }
.summary-card-purple { background:linear-gradient(135deg,##6b21a8,##a855f7); }
.summary-icon  { font-size:1.8rem;opacity:.85; }
.summary-label { font-size:.75rem;opacity:.85;display:block; }
.summary-value { font-size:1.6rem;font-weight:700;display:block; }
.badge-type { display:inline-block;padding:3px 10px;border-radius:10px;font-size:.72rem;font-weight:600; }
.badge-type-PHYSICAL { background:##dbeafe;color:##1e40af; }
.badge-type-IT       { background:##ede9fe;color:##6d28d9; }
.badge-type-VEHICLE  { background:##fef3c7;color:##92400e; }
.badge-active-true  { display:inline-block;padding:3px 10px;border-radius:10px;font-size:.72rem;font-weight:600;background:##dcfce7;color:##15803d; }
.badge-active-false { display:inline-block;padding:3px 10px;border-radius:10px;font-size:.72rem;font-weight:600;background:##fee2e2;color:##b91c1c; }
.catModal, ##catModal { z-index:99999 !important; }
.modal-backdrop { z-index:99998 !important; }
</style>
<script>
var allCats = #serializeJSON(catArr)#;

var typeBadge = {
    'PHYSICAL':'<span class="badge-type badge-type-PHYSICAL"><i class="fas fa-industry me-1"></i>Fiziki</span>',
    'IT':      '<span class="badge-type badge-type-IT"><i class="fas fa-laptop me-1"></i>BT</span>',
    'VEHICLE': '<span class="badge-type badge-type-VEHICLE"><i class="fas fa-truck me-1"></i>Araç</span>'
};

function renderGrid(data) {
    document.getElementById('recordCount').textContent = data.length + ' kayıt';
    $("##catGrid").dxDataGrid({
        dataSource: data,
        keyExpr: "category_id",
        showBorders: false,
        showRowLines: true,
        showColumnLines: false,
        rowAlternationEnabled: true,
        hoverStateEnabled: true,
        paging:  { pageSize: 25 },
        pager:   { showPageSizeSelector:true, allowedPageSizes:[25,50,100], showInfo:true },
        sorting: { mode:"multiple" },
        export:  { enabled:true, fileName:"varlik_kategorileri" },
        headerFilter: { visible:true },
        columns: [
            { dataField:"category_id",   caption:"##",       width:60,  alignment:"center", sortOrder:"asc" },
            { dataField:"category_code", caption:"Kod",      width:120 },
            { dataField:"category_name", caption:"Kategori Adı", minWidth:200 },
            {
                dataField:"asset_type", caption:"Tip", width:120, alignment:"center",
                cellTemplate: function(el,i){ el.html(typeBadge[i.value] || i.value || '—'); }
            },
            { dataField:"parent_name", caption:"Üst Kategori", width:180, defaultValue:"—",
              cellTemplate: function(el,i){ el.text(i.value || '—'); }
            },
            {
                dataField:"asset_count", caption:"Varlık", width:80, alignment:"center",
                cellTemplate: function(el,i){
                    var v = i.value || 0;
                    el.html(v > 0 ? '<strong style="color:##1a3a5c">'+v+'</strong>' : '<span style="color:##9ca3af">0</span>');
                }
            },
            {
                dataField:"is_active", caption:"Durum", width:90, alignment:"center",
                cellTemplate: function(el,i){
                    el.html(i.value ? '<span class="badge-active-true">Aktif</span>' : '<span class="badge-active-false">Pasif</span>');
                }
            },
            {
                caption:"İşlem", width:80, alignment:"center", allowSorting:false, allowFiltering:false,
                cellTemplate: function(el,i){
                    el.html('<button class="btn btn-xs btn-outline-primary py-0 px-2" onclick="openCatModal('+i.data.category_id+')"><i class="fas fa-pen"></i></button>');
                }
            }
        ]
    });
}

function applyFilters() {
    var typeVal   = document.getElementById('filterType').value;
    var activeVal = document.getElementById('filterActive').value;
    var searchVal = (document.getElementById('filterSearch').value||'').trim().toLowerCase();

    var filtered = allCats.filter(function(c){
        if (typeVal   && c.asset_type !== typeVal) return false;
        if (activeVal !== '' && String(c.is_active) !== activeVal) return false;
        if (searchVal) {
            var hay = (c.category_code+' '+c.category_name).toLowerCase();
            if (hay.indexOf(searchVal) === -1) return false;
        }
        return true;
    });
    var grid = $("##catGrid").dxDataGrid("instance");
    if (grid) {
        grid.option("dataSource", filtered);
        document.getElementById('recordCount').textContent = filtered.length + ' kayıt';
    }
}

function clearFilters() {
    document.getElementById('filterType').value   = '';
    document.getElementById('filterActive').value = '';
    document.getElementById('filterSearch').value = '';
    applyFilters();
}

function filterParents() {
    var selType = document.getElementById('c_asset_type').value;
    var currId  = parseInt(document.getElementById('c_category_id').value || 0);
    var sel = document.getElementById('c_parent_id');
    var curVal = sel.value;
    sel.innerHTML = '<option value="">— Üst kategori yok —</option>';
    allCats.forEach(function(c){
        if (c.asset_type === selType && c.category_id !== currId) {
            var opt = document.createElement('option');
            opt.value = c.category_id;
            opt.textContent = c.category_name;
            if (String(c.category_id) === curVal) opt.selected = true;
            sel.appendChild(opt);
        }
    });
}

function openCatModal(categoryId) {
    var row = categoryId ? allCats.find(function(c){ return c.category_id === categoryId; }) : null;

    document.getElementById('c_category_id').value   = categoryId || '';
    document.getElementById('c_category_code').value = row ? row.category_code : '';
    document.getElementById('c_category_name').value = row ? row.category_name : '';
    document.getElementById('c_asset_type').value    = row ? row.asset_type    : '';
    document.getElementById('c_is_active').value     = row ? String(row.is_active) : 'true';
    document.getElementById('catSaveMsg').innerHTML  = '';

    document.getElementById('catModalTitle').innerHTML =
        '<i class="fas fa-tag me-2"></i>' + (row ? 'Kategori Düzenle' : 'Yeni Kategori');

    var delBtn = document.getElementById('catDeleteBtn');
    delBtn.style.display = (row && row.asset_count === 0) ? '' : 'none';

    filterParents();
    if (row) document.getElementById('c_parent_id').value = row.parent_id || '';

    var m = new bootstrap.Modal(document.getElementById('catModal'));
    m.show();
}

function saveCategory() {
    var name = document.getElementById('c_category_name').value.trim();
    var type = document.getElementById('c_asset_type').value;
    if (!name) { alert('Kategori adı zorunludur.'); return; }
    if (!type) { alert('Varlık tipi seçilmelidir.'); return; }

    var btn = document.getElementById('catSaveBtn');
    btn.disabled=true; btn.innerHTML='<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url: '/asset/form/save_category.cfm',
        method: 'POST',
        dataType: 'json',
        data: {
            category_id:   document.getElementById('c_category_id').value,
            category_code: document.getElementById('c_category_code').value.trim(),
            category_name: name,
            asset_type:    type,
            parent_id:     document.getElementById('c_parent_id').value,
            is_active:     document.getElementById('c_is_active').value
        },
        success: function(res) {
            btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet';
            if (res && res.success) {
                document.getElementById('catSaveMsg').innerHTML = '<div class="alert alert-success py-2">Kayıt başarıyla kaydedildi.</div>';
                setTimeout(function(){ location.reload(); }, 1000);
            } else {
                document.getElementById('catSaveMsg').innerHTML = '<div class="alert alert-danger py-2">'+(res.message||'Hata oluştu.')+'</div>';
            }
        },
        error: function() {
            btn.disabled=false; btn.innerHTML='<i class="fas fa-save me-2"></i>Kaydet';
            document.getElementById('catSaveMsg').innerHTML = '<div class="alert alert-danger py-2">Sunucu hatası.</div>';
        }
    });
}

function deleteCategory() {
    var catId = document.getElementById('c_category_id').value;
    if (!catId) return;
    if (!confirm('Bu kategoriyi silmek istediğinizden emin misiniz?')) return;

    var btn = document.getElementById('catDeleteBtn');
    btn.disabled=true;

    $.ajax({
        url: '/asset/form/delete_category.cfm',
        method: 'POST',
        dataType: 'json',
        data: { category_id: catId },
        success: function(res) {
            btn.disabled=false;
            if (res && res.success) {
                setTimeout(function(){ location.reload(); }, 500);
            } else {
                document.getElementById('catSaveMsg').innerHTML = '<div class="alert alert-danger py-2">'+(res.message||'Silinemedi.')+'</div>';
            }
        },
        error: function() {
            btn.disabled=false;
            document.getElementById('catSaveMsg').innerHTML = '<div class="alert alert-danger py-2">Sunucu hatası.</div>';
        }
    });
}

window.addEventListener('load', function(){
    var m = document.getElementById('catModal');
    if (m) document.body.appendChild(m);
    renderGrid(allCats);
    document.getElementById('filterType').addEventListener('change', applyFilters);
    document.getElementById('filterActive').addEventListener('change', applyFilters);
    var st;
    document.getElementById('filterSearch').addEventListener('input', function(){
        clearTimeout(st); st = setTimeout(applyFilters, 300);
    });
});
</script>
</cfoutput>
