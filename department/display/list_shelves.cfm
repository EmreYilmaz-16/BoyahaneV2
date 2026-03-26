<cfprocessingdirective pageEncoding="utf-8">

<!--- Departmanlar --->
<cfquery name="getDepts" datasource="boyahane">
    SELECT department_id, department_head, hierarchy, is_store, is_production, department_status
    FROM department
    ORDER BY hierarchy, department_head
</cfquery>

<!--- Lokasyonlar --->
<cfquery name="getLocs" datasource="boyahane">
    SELECT id, department_id, department_location, location_id, status
    FROM stocks_location
    ORDER BY department_id, department_location
</cfquery>

<!--- Stoklar (ürün satırı eklemek için) --->
<cfquery name="getStocks" datasource="boyahane">
    SELECT s.stock_id, s.stock_code, s.barcod,
           p.product_id, p.product_name, p.product_code
    FROM stocks s
    LEFT JOIN product p ON s.product_id = p.product_id
    WHERE s.stock_status = true
    ORDER BY p.product_name, s.stock_code
</cfquery>

<cfset deptArr  = []>
<cfloop query="getDepts">
    <cfset arrayAppend(deptArr, {
        "department_id"   = department_id,
        "department_head" = department_head ?: "",
        "hierarchy"       = hierarchy ?: "",
        "is_store"        = is_store ?: 0,
        "is_production"   = is_production,
        "department_status" = department_status
    })>
</cfloop>

<cfset locArr = []>
<cfloop query="getLocs">
    <cfset arrayAppend(locArr, {
        "id"                 = id,
        "department_id"      = department_id,
        "department_location"= department_location ?: "",
        "location_id"        = location_id ?: 0,
        "status"             = status
    })>
</cfloop>

<cfset stockArr = []>
<cfloop query="getStocks">
    <cfset arrayAppend(stockArr, {
        "stock_id"    = stock_id,
        "stock_code"  = stock_code ?: "",
        "barcod"      = barcod ?: "",
        "product_id"  = product_id ?: 0,
        "product_name"= product_name ?: "",
        "product_code"= product_code ?: "",
        "label"       = (product_name ?: "?") & " — " & (stock_code ?: "")
    })>
</cfloop>

<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"
            integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo="
            crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<!--- ══════════════════════════════════ --->
<!--- SAYFA BAŞLIĞI                     --->
<!--- ══════════════════════════════════ --->
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-th-large"></i>
        </div>
        <div class="page-header-title">
            <h1>Raf Yönetimi</h1>
            <p>Lokasyon bazlı raf ve ürün yerleşimi</p>
        </div>
    </div>
</div>

<div class="px-3 pb-4">
    <div class="shelf-master-layout">

        <!--- ══════════════════════════════ --->
        <!--- SOL: LOK/DEPT AĞACI          --->
        <!--- ══════════════════════════════ --->
        <div class="loc-tree-panel">
            <div class="loc-tree-header">
                <span><i class="fas fa-sitemap me-2"></i>Lokasyonlar</span>
                <span class="badge bg-light text-dark" id="locCount">-</span>
            </div>
            <div class="loc-search-wrap">
                <input id="locSearch" type="text" class="form-control form-control-sm"
                       placeholder="Ara..." oninput="filterLocTree(this.value)">
            </div>
            <div class="loc-tree-body" id="locTreeBody">
                <div class="loc-tree-empty"><i class="fas fa-spinner fa-spin"></i> Yükleniyor...</div>
            </div>
        </div>

        <!--- ══════════════════════════════ --->
        <!--- ORTA: RAF LİSTESİ            --->
        <!--- ══════════════════════════════ --->
        <div class="shelf-list-panel" id="shelfListPanel">
            <div class="shelf-list-header">
                <span id="shelfLocName"><i class="fas fa-boxes me-2"></i>Raflar</span>
                <button class="btn btn-sm btn-success" style="display:none" id="btnNewShelf" onclick="newShelf()">
                    <i class="fas fa-plus me-1"></i>Yeni Raf
                </button>
            </div>
            <div id="shelfListEmpty" class="loc-tree-empty">
                <i class="fas fa-hand-point-left fa-2x mb-2 opacity-25"></i>
                <p class="mt-2">Bir lokasyon seçin</p>
            </div>
            <div id="shelfListContent" style="display:none">
                <div id="shelfCards"></div>
            </div>
        </div>

        <!--- ══════════════════════════════ --->
        <!--- SAĞ: RAF DETAY + ÜRÜNLER     --->
        <!--- ══════════════════════════════ --->
        <div class="shelf-detail-panel" id="shelfDetailPanel">
            <div id="detailEmpty" class="panel-empty-state">
                <i class="fas fa-hand-pointer fa-3x mb-3 opacity-25"></i>
                <p class="text-muted">Raf seçin veya yeni raf oluşturun.</p>
            </div>

            <div id="detailContent" style="display:none" class="p-3">
                <input type="hidden" id="shelfId">
                <input type="hidden" id="shelfLocId">

                <!--- Form başlığı --->
                <div class="panel-form-header">
                    <div id="detailTitle" class="panel-form-title">
                        <i class="fas fa-layer-group me-2 text-warning"></i>Yeni Raf
                    </div>
                    <button class="btn btn-sm btn-outline-danger" id="deleteShelfBtn"
                            style="display:none" onclick="deleteShelf()">
                        <i class="fas fa-trash me-1"></i>Sil
                    </button>
                </div>

                <!--- Raf form alanları --->
                <div class="row g-2 mt-1">
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Raf Kodu <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="shelfCode" placeholder="Örn: A-01-B02">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Durum</label>
                        <select class="form-select" id="shelfStatus">
                            <option value="1">Aktif</option>
                            <option value="0">Pasif</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label fw-semibold">Raf Tipi</label>
                        <input type="number" class="form-control" id="shelfType" placeholder="0" min="0">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Kapasite</label>
                        <input type="number" class="form-control" id="shelfQty" placeholder="0" min="0">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Başlangıç</label>
                        <input type="date" class="form-control" id="shelfStart">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Bitiş</label>
                        <input type="date" class="form-control" id="shelfEnd">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Açıklama</label>
                        <input type="text" class="form-control" id="shelfDetail" placeholder="Not / açıklama">
                    </div>
                </div>

                <!--- Boyutlar + Koordinatlar (collapsible) --->
                <div class="mt-2">
                    <a class="text-muted small" data-bs-toggle="collapse" href="#shelfDimsBlock"
                       style="cursor:pointer;text-decoration:none">
                        <i class="fas fa-chevron-down me-1" style="font-size:.7rem"></i>Boyutlar &amp; Koordinatlar
                    </a>
                    <div class="collapse" id="shelfDimsBlock">
                        <div class="row g-2 mt-1">
                            <div class="col-md-2">
                                <label class="form-label small">En (cm)</label>
                                <input type="number" class="form-control form-control-sm" id="shelfW" step="0.01" placeholder="0">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label small">Boy (cm)</label>
                                <input type="number" class="form-control form-control-sm" id="shelfH" step="0.01" placeholder="0">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label small">Derinlik (cm)</label>
                                <input type="number" class="form-control form-control-sm" id="shelfD" step="0.01" placeholder="0">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label small">X</label>
                                <input type="text" class="form-control form-control-sm" id="shelfX" placeholder="">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label small">Y</label>
                                <input type="text" class="form-control form-control-sm" id="shelfY" placeholder="">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label small">Z</label>
                                <input type="text" class="form-control form-control-sm" id="shelfZ" placeholder="">
                            </div>
                        </div>
                    </div>
                </div>

                <hr class="my-3">

                <!--- ÜRÜNLER BÖLÜMÜ --->
                <div class="d-flex align-items-center justify-content-between mb-2">
                    <span class="fw-semibold"><i class="fas fa-cubes me-2 text-info"></i>Ürünler</span>
                    <div class="prod-search-outer" style="position:relative;width:280px">
                        <input id="prodSearch" type="text" class="form-control form-control-sm"
                               placeholder="Ürün / stok kodu ara..."
                               oninput="filterProducts(this.value)"
                               autocomplete="off">
                        <div id="prodDropdown" class="prod-dropdown" style="display:none"></div>
                    </div>
                </div>

                <table class="table table-sm table-bordered shelf-rows-table">
                    <thead class="table-light">
                        <tr>
                            <th>Ürün</th>
                            <th>Stok Kodu</th>
                            <th style="width:100px">Miktar</th>
                            <th style="width:40px"></th>
                        </tr>
                    </thead>
                    <tbody id="rowsBody">
                        <tr id="rowsEmpty">
                            <td colspan="4" class="text-center text-muted py-3">
                                <small>Ürün eklenmedi. Sağ üstten arama yapın.</small>
                            </td>
                        </tr>
                    </tbody>
                </table>

                <button class="btn btn-primary w-100 mt-1" onclick="saveShelf()">
                    <i class="fas fa-save me-2"></i>Kaydet
                </button>
            </div>
        </div>

    </div><!--- /shelf-master-layout --->
</div>

<cfoutput>
<style>
/* ══ Ana layout ══ */
.shelf-master-layout {
    display: flex;
    gap: 12px;
    min-height: calc(100vh - 200px);
}

/* ══ Sol: Lokasyon ağacı ══ */
.loc-tree-panel {
    width: 250px;
    flex-shrink: 0;
    background: ##fff;
    border-radius: 12px;
    border: 1px solid ##e2e8f0;
    box-shadow: 0 1px 6px rgba(0,0,0,.07);
    display: flex;
    flex-direction: column;
    overflow: hidden;
}
.loc-tree-header {
    background: linear-gradient(135deg, ##1a3a5c, ##2563ab);
    color: ##fff;
    padding: 12px 14px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-weight: 600;
    font-size: .875rem;
    flex-shrink: 0;
}
.loc-search-wrap {
    padding: 8px 10px;
    border-bottom: 1px solid ##e9ecef;
    flex-shrink: 0;
}
.loc-tree-body {
    flex: 1;
    overflow-y: auto;
    padding: 6px 0;
}
.loc-tree-empty {
    text-align: center;
    color: ##adb5bd;
    padding: 30px 12px;
    font-size: .8rem;
}

/* ══ Departman ve Lokasyon nodeları ══ */
.tree-dept-node { border-bottom: 1px solid ##f0f0f0; }
.tree-dept-row {
    display: flex;
    align-items: center;
    padding: 8px 10px;
    cursor: pointer;
    user-select: none;
    gap: 5px;
    transition: background .15s;
}
.tree-dept-row:hover { background: ##f0f6ff; }
.tree-dept-chevron {
    width: 16px;
    text-align: center;
    font-size: .7rem;
    color: ##9ca3af;
    transition: transform .2s;
}
.tree-dept-chevron.open { transform: rotate(90deg); }
.tree-dept-icon { color: ##2563ab; font-size: .9rem; }
.tree-dept-name { flex: 1; font-size: .82rem; font-weight: 600; color: ##212529; }

.tree-loc-container { display: none; background: ##f8fafc; }
.tree-loc-container.open { display: block; }
.tree-loc-row {
    display: flex;
    align-items: center;
    padding: 6px 10px 6px 30px;
    cursor: pointer;
    gap: 5px;
    transition: background .15s;
    border-left: 2px solid transparent;
    font-size: .8rem;
}
.tree-loc-row:hover { background: ##f0fdf4; }
.tree-loc-row.active { background: ##dcfce7; border-left-color: ##16a34a; font-weight: 600; }
.tree-loc-dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; }
.tree-loc-name { flex: 1; color: ##374151; }
.tree-loc-noitem {
    padding: 5px 10px 5px 30px;
    font-size: .75rem;
    color: ##d1d5db;
    font-style: italic;
}

/* ══ Orta: Raf listesi ══ */
.shelf-list-panel {
    width: 280px;
    flex-shrink: 0;
    background: ##fff;
    border-radius: 12px;
    border: 1px solid ##e2e8f0;
    box-shadow: 0 1px 6px rgba(0,0,0,.07);
    display: flex;
    flex-direction: column;
    overflow: hidden;
}
.shelf-list-header {
    background: linear-gradient(135deg, ##78350f, ##d97706);
    color: ##fff;
    padding: 12px 14px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    font-size: .875rem;
    font-weight: 600;
    flex-shrink: 0;
}
##shelfCards { overflow-y: auto; padding: 8px; }

/* ══ Raf kartları ══ */
.shelf-card {
    border: 1px solid ##e5e7eb;
    border-radius: 8px;
    padding: 10px 12px;
    margin-bottom: 6px;
    cursor: pointer;
    transition: all .15s;
    display: flex;
    align-items: center;
    gap: 8px;
}
.shelf-card:hover { background: ##fffbeb; border-color: ##fbbf24; }
.shelf-card.active { background: ##fef3c7; border-color: ##d97706; border-left: 3px solid ##d97706; }
.shelf-card-code { font-weight: 700; font-size: .9rem; color: ##1f2937; flex: 1; }
.shelf-card-meta { font-size: .72rem; color: ##6b7280; }
.shelf-card-badge {
    font-size: .68rem;
    padding: 2px 6px;
    border-radius: 12px;
    background: ##e0f2fe;
    color: ##0369a1;
    flex-shrink: 0;
}
.shelf-card-badge.badge-inactive { background: ##fee2e2; color: ##dc2626; }

/* ══ Sağ: Detay paneli ══ */
.shelf-detail-panel {
    flex: 1;
    background: ##fff;
    border-radius: 12px;
    border: 1px solid ##e2e8f0;
    box-shadow: 0 1px 6px rgba(0,0,0,.07);
    overflow-y: auto;
    position: relative;
}
.panel-empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    min-height: 300px;
}
.panel-form-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 4px;
}
.panel-form-title {
    font-size: 1rem;
    font-weight: 700;
    color: ##1f2937;
}

/* ══ Ürün arama dropdown ══ */
.prod-dropdown {
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    background: ##fff;
    border: 1px solid ##d1d5db;
    border-radius: 6px;
    max-height: 220px;
    overflow-y: auto;
    z-index: 1060;
    box-shadow: 0 4px 16px rgba(0,0,0,.12);
}
.prod-drop-item {
    padding: 8px 12px;
    cursor: pointer;
    font-size: .82rem;
    border-bottom: 1px solid ##f3f4f6;
    display: flex;
    flex-direction: column;
    gap: 1px;
}
.prod-drop-item:hover { background: ##f0f9ff; }
.prod-drop-item .pi-name { font-weight: 600; color: ##1f2937; }
.prod-drop-item .pi-code { color: ##6b7280; font-size: .75rem; }
.prod-drop-empty { padding: 12px; text-align: center; color: ##9ca3af; font-size: .8rem; }

/* ══ Ürün satırları tablosu ══ */
.shelf-rows-table th { font-size: .78rem; }
.shelf-rows-table td { font-size: .82rem; vertical-align: middle; }
</style>

<script>
var allDepts  = #serializeJSON(deptArr)#;
var allLocs   = #serializeJSON(locArr)#;
var allStocks = #serializeJSON(stockArr)#;

var currentLocId   = 0;
var currentShelfId = 0;
var shelfRows      = [];

/* ══════════════════════════════════════ */
/* AĞAÇ OLUŞTUR                          */
/* ══════════════════════════════════════ */
function buildLocTree() {
    var body   = document.getElementById('locTreeBody');
    var html   = '';
    var total  = 0;
    allDepts.forEach(function(d) {
        var locs = allLocs.filter(function(l){ return l.department_id === d.department_id; });
        total += locs.length;
        var icon = d.is_production ? 'fa-industry' : (d.is_store ? 'fa-warehouse' : 'fa-building');
        html += '<div class="tree-dept-node" id="dn_' + d.department_id + '">';
        html += '<div class="tree-dept-row" onclick="toggleDeptNode(' + d.department_id + ')">';
        html += '<span class="tree-dept-chevron" id="chev_' + d.department_id + '"><i class="fas fa-chevron-right"></i></span>';
        html += '<i class="fas ' + icon + ' tree-dept-icon"></i>';
        html += '<span class="tree-dept-name">' + escHtml(d.department_head) + '</span>';
        html += '<span class="badge bg-secondary" style="font-size:.65rem">' + locs.length + '</span>';
        html += '</div>';
        html += '<div class="tree-loc-container" id="lc_' + d.department_id + '">';
        if (locs.length === 0) {
            html += '<div class="tree-loc-noitem">Lokasyon yok</div>';
        } else {
            locs.forEach(function(l) {
                var dot = l.status ? '##16a34a' : '##dc2626';
                html += '<div class="tree-loc-row" id="lr_' + l.id + '" onclick="selectLoc(' + l.id + ', ' + d.department_id + ')">';
                html += '<div class="tree-loc-dot" style="background:' + dot + '"></div>';
                html += '<span class="tree-loc-name">' + escHtml(l.department_location) + '</span>';
                html += '</div>';
            });
        }
        html += '</div>';
        html += '</div>';
    });
    if (html === '') html = '<div class="loc-tree-empty">Departman bulunamadı.</div>';
    body.innerHTML = html;
    document.getElementById('locCount').textContent = total;
}

function toggleDeptNode(deptId) {
    var container = document.getElementById('lc_' + deptId);
    var chev      = document.getElementById('chev_' + deptId);
    if (!container) return;
    var isOpen = container.classList.contains('open');
    container.classList.toggle('open', !isOpen);
    chev.classList.toggle('open', !isOpen);
}

function filterLocTree(term) {
    term = term.toLowerCase();
    allDepts.forEach(function(d) {
        var locs = allLocs.filter(function(l){ return l.department_id === d.department_id; });
        var deptMatch = d.department_head.toLowerCase().includes(term);
        var anyLocMatch = false;
        locs.forEach(function(l) {
            var row  = document.getElementById('lr_' + l.id);
            var show = !term || deptMatch || l.department_location.toLowerCase().includes(term);
            if (row) row.style.display = show ? '' : 'none';
            if (show) anyLocMatch = true;
        });
        var deptNode = document.getElementById('dn_' + d.department_id);
        if (deptNode) deptNode.style.display = (!term || deptMatch || anyLocMatch) ? '' : 'none';
        if (term && anyLocMatch) {
            var c = document.getElementById('lc_' + d.department_id);
            var v = document.getElementById('chev_' + d.department_id);
            if(c){ c.classList.add('open'); }
            if(v){ v.classList.add('open'); }
        }
    });
}

/* ══════════════════════════════════════ */
/* LOKASYON SEÇ → RAF LİSTESİ YÜKLE     */
/* ══════════════════════════════════════ */
function selectLoc(locId, deptId) {
    currentLocId   = locId;
    currentShelfId = 0;

    // Tree highlight
    document.querySelectorAll('.tree-loc-row').forEach(function(r){ r.classList.remove('active'); });
    var row = document.getElementById('lr_' + locId);
    if (row) row.classList.add('active');

    // Dept node aç
    if (deptId) {
        var c = document.getElementById('lc_' + deptId);
        var v = document.getElementById('chev_' + deptId);
        if(c){ c.classList.add('open'); }
        if(v){ v.classList.add('open'); }
    }

    // Lokasyon adını başlığa yaz
    var locObj = allLocs.find(function(l){ return l.id === locId; });
    document.getElementById('shelfLocName').innerHTML =
        '<i class="fas fa-boxes me-2"></i>' + escHtml(locObj ? locObj.department_location : 'Raflar');

    // Yeni raf butonu göster
    document.getElementById('btnNewShelf').style.display = '';

    // Sağ panel sıfırla
    showDetailEmpty();

    // Rafları yükle
    document.getElementById('shelfListEmpty').style.display  = 'none';
    document.getElementById('shelfListContent').style.display = 'none';
    document.getElementById('shelfCards').innerHTML = '<div class="text-center py-3"><i class="fas fa-spinner fa-spin text-muted"></i></div>';
    document.getElementById('shelfListContent').style.display = '';

    $.getJSON('department/form/get_shelves.cfm?loc_id=' + locId, function(data) {
        buildShelfList(data);
    }).fail(function() {
        document.getElementById('shelfCards').innerHTML = '<div class="text-center text-danger py-3 small">Yüklenemedi.</div>';
    });
}

function buildShelfList(shelves) {
    var html = '';
    if (!shelves || shelves.length === 0) {
        html = '<div class="text-center text-muted py-4 small"><i class="fas fa-inbox fa-2x mb-2 opacity-25 d-block"></i>Raf bulunamadı. Yeni raf ekleyin.</div>';
    } else {
        shelves.forEach(function(s) {
            var activeClass = s.place_status == 1 ? 'shelf-card-badge' : 'shelf-card-badge badge-inactive';
            var statusTxt   = s.place_status == 1 ? 'Aktif' : 'Pasif';
            html += '<div class="shelf-card" id="sc_' + s.product_place_id + '" onclick="selectShelf(' + s.product_place_id + ')">';
            html += '<div>';
            html += '<div class="shelf-card-code"><i class="fas fa-layer-group me-1 text-warning"></i>' + escHtml(s.shelf_code || '-') + '</div>';
            html += '<div class="shelf-card-meta">';
            if (s.row_count > 0) html += s.row_count + ' ürün &nbsp;';
            if (s.quantity  > 0) html += '· kapasite: ' + s.quantity;
            html += '</div>';
            html += '</div>';
            html += '<span class="' + activeClass + '">' + statusTxt + '</span>';
            html += '</div>';
        });
    }
    document.getElementById('shelfCards').innerHTML = html;
}

/* ══════════════════════════════════════ */
/* RAF SEÇ                               */
/* ══════════════════════════════════════ */
function selectShelf(shelfId) {
    currentShelfId = shelfId;

    document.querySelectorAll('.shelf-card').forEach(function(c){ c.classList.remove('active'); });
    var card = document.getElementById('sc_' + shelfId);
    if (card) card.classList.add('active');

    // Raf satırlarını yükle
    $.getJSON('department/form/get_shelf_rows.cfm?shelf_id=' + shelfId, function(data) {
        shelfRows = data.rows || [];
        var shelf = data.shelf || {};
        populateShelfForm(shelf);
        renderRowsTable();
        showDetailContent();
    }).fail(function() {
        alert('Raf yüklenemedi.');
    });
}

function populateShelfForm(s) {
    document.getElementById('shelfId').value     = s.product_place_id || 0;
    document.getElementById('shelfLocId').value  = currentLocId;
    document.getElementById('shelfCode').value   = s.shelf_code || '';
    document.getElementById('shelfStatus').value = (s.place_status !== undefined && s.place_status !== null) ? s.place_status : 1;
    document.getElementById('shelfType').value   = s.shelf_type || '';
    document.getElementById('shelfQty').value    = s.quantity || '';
    document.getElementById('shelfStart').value  = s.start_date || '';
    document.getElementById('shelfEnd').value    = s.finish_date || '';
    document.getElementById('shelfDetail').value = s.detail || '';
    document.getElementById('shelfW').value      = s.width || '';
    document.getElementById('shelfH').value      = s.height || '';
    document.getElementById('shelfD').value      = s.depth || '';
    document.getElementById('shelfX').value      = s.x_coordinate || '';
    document.getElementById('shelfY').value      = s.y_coordinate || '';
    document.getElementById('shelfZ').value      = s.z_coordinate || '';

    document.getElementById('detailTitle').innerHTML =
        '<i class="fas fa-layer-group me-2 text-warning"></i>Raf: ' + escHtml(s.shelf_code || '');
    document.getElementById('deleteShelfBtn').style.display = '';
}

/* ══════════════════════════════════════ */
/* YENİ RAF                              */
/* ══════════════════════════════════════ */
function newShelf() {
    currentShelfId = 0;
    shelfRows = [];

    document.querySelectorAll('.shelf-card').forEach(function(c){ c.classList.remove('active'); });

    document.getElementById('shelfId').value     = 0;
    document.getElementById('shelfLocId').value  = currentLocId;
    document.getElementById('shelfCode').value   = '';
    document.getElementById('shelfStatus').value = 1;
    document.getElementById('shelfType').value   = '';
    document.getElementById('shelfQty').value    = '';
    document.getElementById('shelfStart').value  = '';
    document.getElementById('shelfEnd').value    = '';
    document.getElementById('shelfDetail').value = '';
    document.getElementById('shelfW').value      = '';
    document.getElementById('shelfH').value      = '';
    document.getElementById('shelfD').value      = '';
    document.getElementById('shelfX').value      = '';
    document.getElementById('shelfY').value      = '';
    document.getElementById('shelfZ').value      = '';
    document.getElementById('prodSearch').value  = '';

    document.getElementById('detailTitle').innerHTML = '<i class="fas fa-layer-group me-2 text-warning"></i>Yeni Raf';
    document.getElementById('deleteShelfBtn').style.display = 'none';

    renderRowsTable();
    showDetailContent();
}

/* ══════════════════════════════════════ */
/* RAF KAYDET                            */
/* ══════════════════════════════════════ */
function saveShelf() {
    var code = document.getElementById('shelfCode').value.trim();
    if (!code) { alert('Raf kodu zorunludur.'); return; }
    if (!currentLocId)  { alert('Lokasyon seçilmemiş.'); return; }

    var payload = {
        shelf_id    : document.getElementById('shelfId').value,
        loc_id      : currentLocId,
        shelf_code  : code,
        place_status: document.getElementById('shelfStatus').value,
        shelf_type  : document.getElementById('shelfType').value  || 0,
        quantity    : document.getElementById('shelfQty').value   || 0,
        start_date  : document.getElementById('shelfStart').value || '',
        finish_date : document.getElementById('shelfEnd').value   || '',
        detail      : document.getElementById('shelfDetail').value|| '',
        width       : document.getElementById('shelfW').value || 0,
        height      : document.getElementById('shelfH').value || 0,
        depth       : document.getElementById('shelfD').value || 0,
        x_coordinate: document.getElementById('shelfX').value || '',
        y_coordinate: document.getElementById('shelfY').value || '',
        z_coordinate: document.getElementById('shelfZ').value || '',
        rows        : JSON.stringify(shelfRows)
    };

    $.post('department/form/save_shelf.cfm', payload, function(res) {
        if (res.success) {
            var isNew = (parseInt(payload.shelf_id) === 0);
            selectLoc(currentLocId, null);
            if (!isNew) {
                currentShelfId = res.product_place_id;
            }
            showToast(isNew ? 'Raf eklendi.' : 'Raf güncellendi.');
        } else {
            alert('Hata: ' + (res.message || 'Bilinmeyen hata.'));
        }
    }, 'json').fail(function() { alert('Sunucu hatası.'); });
}

/* ══════════════════════════════════════ */
/* RAF SİL                               */
/* ══════════════════════════════════════ */
function deleteShelf() {
    if (!currentShelfId) return;
    if (!confirm('Bu raf ve tüm ürün satırları silinecek. Devam?')) return;

    $.post('department/form/delete_shelf.cfm', { shelf_id: currentShelfId }, function(res) {
        if (res.success) {
            showDetailEmpty();
            selectLoc(currentLocId, null);
            showToast('Raf silindi.');
        } else {
            alert('Hata: ' + (res.message || 'Bilinmeyen hata.'));
        }
    }, 'json').fail(function() { alert('Sunucu hatası.'); });
}

/* ══════════════════════════════════════ */
/* ÜRÜN SATIRI EKLE                      */
/* ══════════════════════════════════════ */
function filterProducts(term) {
    var dd = document.getElementById('prodDropdown');
    if (!term || term.length < 2) { dd.style.display = 'none'; return; }
    term = term.toLowerCase();
    var matches = allStocks.filter(function(s) {
        return (s.product_name && s.product_name.toLowerCase().includes(term)) ||
               (s.product_code && s.product_code.toLowerCase().includes(term)) ||
               (s.stock_code   && s.stock_code.toLowerCase().includes(term))   ||
               (s.barcod       && s.barcod.toLowerCase().includes(term));
    }).slice(0, 30);

    if (matches.length === 0) {
        dd.innerHTML = '<div class="prod-drop-empty">Sonuç bulunamadı.</div>';
    } else {
        var html = '';
        matches.forEach(function(s, i) {
            html += '<div class="prod-drop-item" onclick="addRowFromStock(' + i + ',\'' + JSON.stringify(matches).replace(/'/g, "\\'") + '\')">';
            html += '<span class="pi-name">' + escHtml(s.product_name) + '</span>';
            html += '<span class="pi-code">' + escHtml(s.product_code) + ' &nbsp;|&nbsp; ' + escHtml(s.stock_code) + '</span>';
            html += '</div>';
        });
        dd.innerHTML = html;
    }
    dd.style.display = '';
}

// Temiz versiyon - indirekt onclick yerine data kullan
var _prodMatchCache = [];
function filterProductsSafe(term) {
    var dd = document.getElementById('prodDropdown');
    if (!term || term.length < 2) { dd.style.display = 'none'; _prodMatchCache = []; return; }
    term = term.toLowerCase();
    _prodMatchCache = allStocks.filter(function(s) {
        return (s.product_name && s.product_name.toLowerCase().includes(term)) ||
               (s.product_code && s.product_code.toLowerCase().includes(term)) ||
               (s.stock_code   && s.stock_code.toLowerCase().includes(term))   ||
               (s.barcod       && s.barcod.toLowerCase().includes(term));
    }).slice(0, 30);

    if (_prodMatchCache.length === 0) {
        dd.innerHTML = '<div class="prod-drop-empty">Sonuç bulunamadı.</div>';
    } else {
        var html = '';
        _prodMatchCache.forEach(function(s, i) {
            html += '<div class="prod-drop-item" data-idx="' + i + '">';
            html += '<span class="pi-name">' + escHtml(s.product_name) + '</span>';
            html += '<span class="pi-code">' + escHtml(s.product_code) + ' &nbsp;|&nbsp; ' + escHtml(s.stock_code) + '</span>';
            html += '</div>';
        });
        dd.innerHTML = html;
        dd.querySelectorAll('.prod-drop-item').forEach(function(el) {
            el.addEventListener('click', function() {
                var idx = parseInt(this.getAttribute('data-idx'));
                var s   = _prodMatchCache[idx];
                if (!s) return;
                addRowFromStock(s);
            });
        });
    }
    dd.style.display = '';
}

function addRowFromStock(s) {
    var dd = document.getElementById('prodDropdown');
    dd.style.display = 'none';
    document.getElementById('prodSearch').value = '';
    _prodMatchCache = [];

    shelfRows.push({
        product_place_row_id: 0,
        product_id  : s.product_id,
        stock_id    : s.stock_id,
        product_name: s.product_name,
        product_code: s.product_code,
        stock_code  : s.stock_code,
        amount      : 1
    });
    renderRowsTable();
}

function removeRow(idx) {
    shelfRows.splice(idx, 1);
    renderRowsTable();
}

function updateAmount(idx, val) {
    if (shelfRows[idx]) shelfRows[idx].amount = parseFloat(val) || 0;
}

function renderRowsTable() {
    var tbody = document.getElementById('rowsBody');
    var emptyRow = document.getElementById('rowsEmpty');
    if (shelfRows.length === 0) {
        tbody.innerHTML = '';
        tbody.innerHTML = '<tr id="rowsEmpty"><td colspan="4" class="text-center text-muted py-3"><small>Ürün eklenmedi. Sağ üstten arama yapın.</small></td></tr>';
        return;
    }
    var html = '';
    shelfRows.forEach(function(r, i) {
        html += '<tr>';
        html += '<td>' + escHtml(r.product_name || '-') + '<br><small class="text-muted">' + escHtml(r.product_code || '') + '</small></td>';
        html += '<td><small>' + escHtml(r.stock_code || '-') + '</small></td>';
        html += '<td><input type="number" class="form-control form-control-sm" value="' + r.amount + '" min="0" step="0.001" onchange="updateAmount(' + i + ',this.value)"></td>';
        html += '<td><button class="btn btn-sm btn-outline-danger py-0 px-1" onclick="removeRow(' + i + ')"><i class="fas fa-times"></i></button></td>';
        html += '</tr>';
    });
    tbody.innerHTML = html;
}

/* ══════════════════════════════════════ */
/* YARDIMCI                              */
/* ══════════════════════════════════════ */
function showDetailEmpty()   { document.getElementById('detailEmpty').style.display=''; document.getElementById('detailContent').style.display='none'; }
function showDetailContent() { document.getElementById('detailEmpty').style.display='none'; document.getElementById('detailContent').style.display=''; }

function escHtml(str) {
    if (!str && str !== 0) return '';
    return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function showToast(msg) {
    var t = document.createElement('div');
    t.textContent = msg;
    t.style.cssText = 'position:fixed;bottom:24px;right:24px;background:##22c55e;color:##fff;padding:10px 20px;border-radius:8px;z-index:9999;font-size:.875rem;box-shadow:0 4px 12px rgba(0,0,0,.15)';
    document.body.appendChild(t);
    setTimeout(function(){ t.remove(); }, 2800);
}

/* ══════════════════════════════════════ */
/* BAŞLANGIÇ                             */
/* ══════════════════════════════════════ */
$(document).ready(function() {
    buildLocTree();

    // Ürün arama: güvenli versiyon bağla
    document.getElementById('prodSearch').addEventListener('input', function() {
        filterProductsSafe(this.value);
    });

    // Dropdown dışına tıklanınca kapat
    document.addEventListener('click', function(e) {
        if (!e.target.closest('.prod-search-outer')) {
            document.getElementById('prodDropdown').style.display = 'none';
        }
    });
});
</script>
</cfoutput>
