<cfprocessingdirective pageEncoding="utf-8">

<!---
    Ürün ağacı (BOM) görüntüleme ve düzenleme
    url.stock_id  = kök stok (BOM sahibi)

    product_tree sütun anlamları:
        stock_id           = kök stok (BOM sahibi)
        related_id         = bileşenin stock_id'si  (malzeme satırı)
        product_id         = bileşenin product_id'si (malzeme satırı)
        operation_type_id  = operasyon satırı için (related_id NULL)
--->

<cfparam name="url.stock_id" default="0">
<cfset rootStockId = isNumeric(url.stock_id) AND val(url.stock_id) gt 0 ? val(url.stock_id) : 0>

<cfif rootStockId eq 0>
    <cflocation url="index.cfm?fuseaction=product.list_product_trees" addtoken="false">
</cfif>

<!--- Kök stok + ürün bilgisi --->
<cfquery name="getRootStock" datasource="boyahane">
    SELECT s.stock_id,
           COALESCE(s.stock_code,'')    AS stock_code,
           COALESCE(p.product_name,'')  AS product_name,
           COALESCE(pc.product_cat,'')  AS product_cat
    FROM stocks s
    LEFT JOIN product p      ON s.product_id    = p.product_id
    LEFT JOIN product_cat pc ON p.product_catid = pc.product_catid
    WHERE s.stock_id = <cfqueryparam value="#rootStockId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getRootStock.recordCount>
    <cflocation url="index.cfm?fuseaction=product.list_product_trees" addtoken="false">
</cfif>

<!---
    Ağaç satırları — Recursive CTE ile kendi ağacı olan bileşenler (yarımamüller)
    otomatik olarak açılır. Döngü sınırı: 10 seviye (döngüsel referans koruması).
--->
<cfquery name="getTree" datasource="boyahane">
    WITH RECURSIVE bom_tree AS (

        -- Kök stokun direkt BOM satırları
        SELECT
            pt.product_tree_id,
            COALESCE(pt.related_product_tree_id, 0)  AS display_parent_id,
            pt.stock_id                              AS bom_owner_stock_id,
            pt.related_id,
            pt.product_id,
            pt.amount,      pt.unit_id,
            pt.fire_amount, pt.fire_rate,
            pt.operation_type_id,
            pt.station_id,
            pt.line_number, pt.process_stage, pt.tree_type,
            pt.detail,      pt.hierarchy,
            pt.is_phantom, pt.is_configure, pt.is_sevk,
            pt.record_date,
            false AS is_sub_bom,
            1     AS depth
        FROM product_tree pt
        WHERE pt.stock_id = <cfqueryparam value="#rootStockId#" cfsqltype="cf_sql_integer">

        UNION ALL

        -- Bileşen stokların kendi BOM satırları (alt yarımamüller)
        SELECT
            sub.product_tree_id,
            CASE
                WHEN COALESCE(sub.related_product_tree_id, 0) = 0
                THEN parent.product_tree_id   -- kök satırı → ana BOM satırına bağla
                ELSE sub.related_product_tree_id  -- iç hiyerarşiyi koru
            END AS display_parent_id,
            sub.stock_id                     AS bom_owner_stock_id,
            sub.related_id,
            sub.product_id,
            sub.amount,      sub.unit_id,
            sub.fire_amount, sub.fire_rate,
            sub.operation_type_id,
            sub.station_id,
            sub.line_number, sub.process_stage, sub.tree_type,
            sub.detail,      sub.hierarchy,
            sub.is_phantom, sub.is_configure, sub.is_sevk,
            sub.record_date,
            true            AS is_sub_bom,
            parent.depth + 1
        FROM bom_tree parent
        INNER JOIN product_tree sub ON sub.stock_id = parent.related_id
        WHERE parent.related_id IS NOT NULL
          AND parent.related_id > 0
          AND parent.depth < 10
    )

    SELECT DISTINCT ON (bom.product_tree_id)
        bom.product_tree_id,
        bom.display_parent_id                            AS related_product_tree_id,
        <cfqueryparam value="#rootStockId#" cfsqltype="cf_sql_integer"> AS root_stock_id,
        bom.bom_owner_stock_id,
        COALESCE(bom.related_id, 0)                     AS component_stock_id,
        COALESCE(bom.product_id, 0)                     AS component_product_id,
        COALESCE(cs.stock_code,'')                       AS component_stock_code,
        COALESCE(cp.product_name,'')                     AS component_name,
        COALESCE(bom.amount, 0)                         AS amount,
        COALESCE(bom.unit_id, 0)                        AS unit_id,
        COALESCE(u.unit,'')                             AS unit_name,
        COALESCE(u.unit_code,'')                        AS unit_code,
        COALESCE(bom.operation_type_id, 0)              AS operation_type_id,
        COALESCE(ot.operation_type,'')                  AS operation_type_name,
        COALESCE(bom.station_id, 0)                     AS station_id,
        COALESCE(ws.station_name,'')                    AS station_name,
        COALESCE(bom.is_phantom, false)                 AS is_phantom,
        COALESCE(bom.is_configure, false)               AS is_configure,
        COALESCE(bom.is_sevk, false)                    AS is_sevk,
        COALESCE(bom.line_number, 0)                    AS line_number,
        COALESCE(bom.process_stage, 0)                  AS process_stage,
        COALESCE(bom.tree_type, 0)                      AS tree_type,
        COALESCE(bom.detail,'')                         AS detail,
        COALESCE(bom.hierarchy,'')                      AS hierarchy,
        COALESCE(bom.fire_amount, 0)                    AS fire_amount,
        COALESCE(bom.fire_rate, 0)                      AS fire_rate,
        bom.is_sub_bom,
        COALESCE(bom.record_date, CURRENT_TIMESTAMP)    AS record_date
    FROM bom_tree bom
    LEFT JOIN stocks cs          ON bom.related_id        = cs.stock_id
    LEFT JOIN product cp         ON cs.product_id         = cp.product_id
    LEFT JOIN setup_unit u       ON bom.unit_id           = u.unit_id
    LEFT JOIN operation_types ot ON bom.operation_type_id = ot.operation_type_id
    LEFT JOIN workstations ws    ON bom.station_id        = ws.station_id
    ORDER BY bom.product_tree_id, bom.depth ASC
</cfquery>

<cfset treeArr = []>
<cfloop query="getTree">
    <cfset arrayAppend(treeArr, {
        "product_tree_id"         : val(product_tree_id),
        "related_product_tree_id" : val(related_product_tree_id),
        "root_stock_id"           : val(root_stock_id),
        "bom_owner_stock_id"      : val(bom_owner_stock_id),
        "component_stock_id"      : val(component_stock_id),
        "component_product_id"    : val(component_product_id),
        "component_stock_code"    : component_stock_code  ?: "",
        "component_name"          : component_name        ?: "",
        "amount"                  : isNumeric(amount) ? val(amount) : 0,
        "unit_id"                 : val(unit_id),
        "unit_name"               : unit_name             ?: "",
        "unit_code"               : unit_code             ?: "",
        "operation_type_id"       : val(operation_type_id),
        "operation_type_name"     : operation_type_name   ?: "",
        "station_id"              : val(station_id),
        "station_name"            : station_name          ?: "",
        "is_phantom"              : is_phantom,
        "is_configure"            : is_configure,
        "is_sevk"                 : is_sevk,
        "line_number"             : val(line_number),
        "process_stage"           : val(process_stage),
        "tree_type"               : val(tree_type),
        "detail"                  : detail                ?: "",
        "hierarchy"               : hierarchy             ?: "",
        "fire_amount"             : isNumeric(fire_amount) ? val(fire_amount) : 0,
        "fire_rate"               : isNumeric(fire_rate)   ? val(fire_rate)   : 0,
        "is_sub_bom"              : is_sub_bom,
        "record_date"             : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") : ""
    })>
</cfloop>

<!--- Form için bileşen stok listesi (malzeme satırları) --->
<cfquery name="getCompStocks" datasource="boyahane">
    SELECT s.stock_id,
           COALESCE(s.stock_code,'')    AS stock_code,
           COALESCE(p3.product_name,'') AS product_name
    FROM stocks s
    LEFT JOIN product p3 ON s.product_id = p3.product_id
    WHERE COALESCE(s.stock_status, true) = true
      AND s.stock_id <> <cfqueryparam value="#rootStockId#" cfsqltype="cf_sql_integer">
    ORDER BY s.stock_code
</cfquery>
<cfset compStocksArr = []>
<cfloop query="getCompStocks">
    <cfset arrayAppend(compStocksArr, {
        "stock_id"    : val(stock_id),
        "stock_code"  : stock_code   ?: "",
        "product_name": product_name ?: ""
    })>
</cfloop>

<!--- Birim listesi --->
<cfquery name="getUnits" datasource="boyahane">
    SELECT unit_id, COALESCE(unit,'') AS unit, COALESCE(unit_code,'') AS unit_code
    FROM setup_unit ORDER BY unit
</cfquery>
<cfset unitsArr = []>
<cfloop query="getUnits">
    <cfset arrayAppend(unitsArr, { "unit_id": val(unit_id), "unit": unit ?: "", "unit_code": unit_code ?: "" })>
</cfloop>

<!--- Operasyon tipleri --->
<cfquery name="getOpTypes" datasource="boyahane">
    SELECT operation_type_id, COALESCE(operation_type,'') AS operation_type
    FROM operation_types
    WHERE COALESCE(operation_status, true) = true
    ORDER BY operation_type
</cfquery>
<cfset opTypesArr = []>
<cfloop query="getOpTypes">
    <cfset arrayAppend(opTypesArr, { "operation_type_id": val(operation_type_id), "operation_type": operation_type ?: "" })>
</cfloop>

<!--- İstasyonlar --->
<cfquery name="getStations" datasource="boyahane">
    SELECT station_id, COALESCE(station_name,'') AS station_name
    FROM workstations
    WHERE COALESCE(active, true) = true
    ORDER BY station_name
</cfquery>
<cfset stationsArr = []>
<cfloop query="getStations">
    <cfset arrayAppend(stationsArr, { "station_id": val(station_id), "station_name": station_name ?: "" })>
</cfloop>

<cfif NOT structKeyExists(request,"jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>


<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-sitemap"></i></div>
        <div class="page-header-title">
            <h1>Ürün Ağacı</h1>
            <cfoutput><p><strong>#htmlEditFormat(getRootStock.stock_code)#</strong> — #htmlEditFormat(getRootStock.product_name)#</p></cfoutput>
        </div>
    </div>
    <div class="d-flex gap-2">
        <button class="btn-add" onclick="openAddModal(0)">
            <i class="fas fa-plus"></i>Kök Satır Ekle
        </button>
        <button class="btn-back" onclick="window.location.href='index.cfm?fuseaction=product.list_product_trees'">
            <i class="fas fa-arrow-left"></i>Listeye Dön
        </button>
    </div>
</div>

<div class="px-3 pb-5">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-sitemap"></i>Bileşen Ağacı</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="treeGrid"></div>
        </div>
    </div>
</div>

<!--- Modal z-index: DevExtreme overlay'lerinin önüne çıkması için --->
<style>
#rowModal { z-index: 9500 !important; }
.modal-backdrop { z-index: 9400 !important; }
</style>

<!--- Ekleme / Düzenleme Modal --->
<div class="modal fade" id="rowModal" tabindex="-1" aria-labelledby="rowModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-xl">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="rowModalLabel"><i class="fas fa-plus-circle me-2"></i>Satır Ekle</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <form id="rowForm" autocomplete="off">
                    <cfoutput>
                    <input type="hidden" id="f_product_tree_id" value="0">
                    <input type="hidden" id="f_root_stock_id"   value="#rootStockId#">
                    <input type="hidden" id="f_parent_tree_id"  value="0">
                    </cfoutput>

                    <!--- Satır tipi seçimi --->
                    <div class="mb-3">
                        <div class="btn-group w-100" role="group">
                            <input type="radio" class="btn-check" name="f_row_type" id="rt_malzeme" value="malzeme" checked>
                            <label class="btn btn-outline-primary" for="rt_malzeme">
                                <i class="fas fa-box me-1"></i>Malzeme / Yarı Mamul
                            </label>
                            <input type="radio" class="btn-check" name="f_row_type" id="rt_operasyon" value="operasyon">
                            <label class="btn btn-outline-warning" for="rt_operasyon">
                                <i class="fas fa-cogs me-1"></i>Operasyon / İşlem
                            </label>
                        </div>
                    </div>

                    <!--- ─── Malzeme alanları ─── --->
                    <div id="section_malzeme">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">Üst Bileşen (Ebeveyn)</label>
                                <select class="form-select" id="f_parent_tree_id_select">
                                    <option value="0">— Kök Seviye —</option>
                                </select>
                                <div class="form-text">Boş bırakırsanız kök seviyede eklenir.</div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">Bileşen Stok <span class="text-danger">*</span></label>
                                <select class="form-select" id="f_component_stock_id">
                                    <option value="0">Seçiniz...</option>
                                    <cfoutput>
                                    <cfloop array="#compStocksArr#" index="cs">
                                        <option value="#cs.stock_id#">#htmlEditFormat(cs.stock_code)##len(trim(cs.product_name)) ? " — " & htmlEditFormat(cs.product_name) : ""#</option>
                                    </cfloop>
                                    </cfoutput>
                                </select>
                            </div>
                        </div>
                        <div class="row g-3 mt-1">
                            <div class="col-md-3">
                                <label class="form-label">Miktar <span class="text-danger">*</span></label>
                                <input type="number" step="0.000001" min="0" class="form-control" id="f_amount" value="1">
                            </div>
                            <div class="col-md-3">
                                <label class="form-label">Birim</label>
                                <select class="form-select" id="f_unit_id">
                                    <option value="0">-</option>
                                    <cfoutput>
                                    <cfloop array="#unitsArr#" index="u">
                                        <option value="#u.unit_id#">#htmlEditFormat(u.unit)##len(trim(u.unit_code)) ? " (" & u.unit_code & ")" : ""#</option>
                                    </cfloop>
                                    </cfoutput>
                                </select>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label">Fire Miktarı</label>
                                <input type="number" step="0.000001" min="0" class="form-control" id="f_fire_amount" value="0">
                            </div>
                            <div class="col-md-3">
                                <label class="form-label">Fire Oranı (%)</label>
                                <input type="number" step="0.01" min="0" max="100" class="form-control" id="f_fire_rate" value="0">
                            </div>
                        </div>
                    </div>

                    <!--- ─── Operasyon alanları ─── --->
                    <div id="section_operasyon" style="display:none;">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label class="form-label">Operasyon Tipi <span class="text-danger">*</span></label>
                                <select class="form-select" id="f_operation_type_id">
                                    <option value="0">Seçiniz...</option>
                                    <cfoutput>
                                    <cfloop array="#opTypesArr#" index="ot">
                                        <option value="#ot.operation_type_id#">#htmlEditFormat(ot.operation_type)#</option>
                                    </cfloop>
                                    </cfoutput>
                                </select>
                            </div>
                            <div class="col-md-3">
                                <label class="form-label">Süre / Miktar</label>
                                <input type="number" step="0.000001" min="0" class="form-control" id="f_op_amount" value="1">
                            </div>
                        </div>
                    </div>

                    <!--- ─── Ortak alanlar ─── --->
                    <div class="row g-3 mt-1">
                        <div class="col-md-4">
                            <label class="form-label">İstasyon</label>
                            <select class="form-select" id="f_station_id">
                                <option value="0">-</option>
                                <cfoutput>
                                <cfloop array="#stationsArr#" index="st">
                                    <option value="#st.station_id#">#htmlEditFormat(st.station_name)#</option>
                                </cfloop>
                                </cfoutput>
                            </select>
                        </div>
                        <div class="col-md-2">
                            <label class="form-label">Sıra No</label>
                            <input type="number" min="0" class="form-control" id="f_line_number" value="0">
                        </div>
                        <div class="col-md-2">
                            <label class="form-label">Süreç Aşaması</label>
                            <input type="number" min="0" class="form-control" id="f_process_stage" value="0">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Detay / Açıklama</label>
                            <input type="text" class="form-control" id="f_detail" maxlength="150" placeholder="Açıklama...">
                        </div>
                    </div>
                    <div class="row g-3 mt-1">
                        <div class="col-md-3 d-flex align-items-center">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="f_is_phantom">
                                <label class="form-check-label" for="f_is_phantom">Sanal (Phantom)</label>
                            </div>
                        </div>
                        <div class="col-md-3 d-flex align-items-center">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="f_is_configure">
                                <label class="form-check-label" for="f_is_configure">Konfigüre</label>
                            </div>
                        </div>
                        <div class="col-md-3 d-flex align-items-center">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="f_is_sevk">
                                <label class="form-check-label" for="f_is_sevk">Sevk</label>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-primary" id="btnSaveRow" onclick="saveRow()">
                    <i class="fas fa-save me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var treeData   = #serializeJSON(treeArr)#;
var rootStockId = #rootStockId#;

/* ─── Satır tipi toggle ─── */
document.querySelectorAll('input[name="f_row_type"]').forEach(function(r) {
    r.addEventListener('change', function() { toggleRowType(this.value); });
});

function toggleRowType(type) {
    document.getElementById('section_malzeme').style.display  = (type === 'malzeme')  ? '' : 'none';
    document.getElementById('section_operasyon').style.display = (type === 'operasyon') ? '' : 'none';
}

/* ─── Init ─── */
(function() {
    function init() { initTree(); }
    if (document.readyState === 'complete') { init(); } else { window.addEventListener('load', init); }
})();

function escapeHtml(v) {
    return String(v == null ? '' : v)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function uiNotify(message, type) {
    if (window.DevExpress && DevExpress.ui && typeof DevExpress.ui.notify === 'function') {
        DevExpress.ui.notify(message, type || 'info', 2500);
    } else {
        alert(message);
    }
}

function uiConfirm(message, title, cb) {
    if (window.DevExpress && DevExpress.ui && DevExpress.ui.dialog && typeof DevExpress.ui.dialog.confirm === 'function') {
        DevExpress.ui.dialog.confirm(message, title || 'Onay').then(cb);
    } else {
        cb(confirm(message));
    }
}

function formatNumber(v, digits) {
    var n = Number(v || 0);
    return isNaN(n) ? '0' : n.toFixed(digits || 0);
}

function initTree() { refreshTree(); }

function refreshTree() {
    var rows = Array.isArray(treeData) ? treeData.slice() : [];
    var childrenByParent = {};
    rows.forEach(function(row) {
        var pid = Number(row.related_product_tree_id || 0);
        if (!childrenByParent[pid]) childrenByParent[pid] = [];
        childrenByParent[pid].push(row);
    });
    Object.keys(childrenByParent).forEach(function(pid) {
        childrenByParent[pid].sort(function(a, b) {
            return Number(a.line_number || 0) - Number(b.line_number || 0) ||
                   Number(a.product_tree_id || 0) - Number(b.product_tree_id || 0);
        });
    });

    var html = [];
    html.push('<div class="table-responsive">');
    html.push('<table class="table table-sm table-bordered align-middle mb-0">');
    html.push('<thead class="table-light"><tr>');
    html.push('<th style="width:60px">##</th><th>Satır</th><th style="width:100px">Miktar</th><th style="width:90px">Birim</th><th style="width:170px">İstasyon</th><th style="width:90px">Fire %</th><th style="width:140px">Bayraklar</th><th>Detay</th><th style="width:160px">İşlemler</th>');
    html.push('</tr></thead><tbody>');

    function renderRows(parentId, depth) {
        var list = childrenByParent[parentId] || [];
        list.forEach(function(d) {
            var isOp = Number(d.operation_type_id || 0) > 0 && Number(d.component_stock_id || 0) === 0;
            var flags = [];
            if (d.is_phantom) flags.push('<span class="badge bg-warning text-dark me-1">Sanal</span>');
            if (d.is_configure) flags.push('<span class="badge bg-info text-dark me-1">Konfigüre</span>');
            if (d.is_sevk) flags.push('<span class="badge bg-secondary">Sevk</span>');
            var actions = [];
            if (d.is_sub_bom) {
                actions.push('<a class="btn btn-sm btn-outline-secondary" title="Kendi Ağacını Görüntüle" href="index.cfm?fuseaction=product.view_product_tree&stock_id=' + Number(d.bom_owner_stock_id || 0) + '"><i class="fas fa-external-link-alt"></i></a>');
            } else {
                actions.push('<button type="button" class="btn btn-sm btn-outline-success" title="Alt Satır Ekle" onclick="openAddModal(' + Number(d.product_tree_id || 0) + ')"><i class="fas fa-plus"></i></button>');
                actions.push('<button type="button" class="btn btn-sm btn-outline-primary" title="Düzenle" onclick="openEditModalById(' + Number(d.product_tree_id || 0) + ')"><i class="fas fa-edit"></i></button>');
                actions.push('<button type="button" class="btn btn-sm btn-outline-danger" title="Sil" onclick="deleteRow(' + Number(d.product_tree_id || 0) + ')"><i class="fas fa-trash"></i></button>');
            }

            html.push('<tr>');
            html.push('<td class="text-center">' + escapeHtml(d.line_number || 0) + '</td>');
            html.push('<td><div style="padding-left:' + (depth * 18) + 'px">');
            if (isOp) {
                html.push('<span class="badge bg-warning text-dark me-1"><i class="fas fa-cogs"></i></span>' + escapeHtml(d.operation_type_name || 'Operasyon'));
            } else {
                html.push('<span class="fw-semibold me-1">' + escapeHtml(d.component_stock_code || '') + '</span>');
                if (d.component_name) html.push('<span class="small text-muted">— ' + escapeHtml(d.component_name) + '</span>');
            }
            html.push('</div></td>');
            html.push('<td class="text-end">' + escapeHtml(formatNumber(d.amount, 4)) + '</td>');
            html.push('<td>' + escapeHtml(d.unit_name || '') + '</td>');
            html.push('<td>' + escapeHtml(d.station_name || '-') + '</td>');
            html.push('<td class="text-end">' + escapeHtml(formatNumber(d.fire_rate, 2)) + '</td>');
            html.push('<td>' + flags.join('') + '</td>');
            html.push('<td><span class="small text-muted">' + escapeHtml(d.detail || '') + '</span></td>');
            html.push('<td><div class="d-flex gap-1 justify-content-center">' + actions.join('') + '</div></td>');
            html.push('</tr>');

            renderRows(Number(d.product_tree_id || 0), depth + 1);
        });
    }

    renderRows(0, 0);
    if (!rows.length) {
        html.push('<tr><td colspan="9" class="text-center text-muted py-3">Kayıt bulunamadı.</td></tr>');
    }
    html.push('</tbody></table></div>');

    document.getElementById('treeGrid').innerHTML = html.join('');
    document.getElementById('recordCount').textContent = rows.length + ' satır';
}

function openEditModalById(id) {
    var row = (Array.isArray(treeData) ? treeData : []).find(function(x) { return Number(x.product_tree_id) === Number(id); });
    if (!row) return;
    openEditModal(row);
}

function buildParentSelect(excludeId) {
    var sel = document.getElementById('f_parent_tree_id_select');
    sel.innerHTML = '<option value="0">— Kök Seviye —</option>';
    treeData.forEach(function(row) {
        /* Alt ağaç satırları üst bileşen olarak seçilemez */
        if (row.product_tree_id !== excludeId && !row.is_sub_bom) {
            var opt = document.createElement('option');
            opt.value = row.product_tree_id;
            opt.textContent = (row.hierarchy ? '[' + row.hierarchy + '] ' : '') +
                              (row.component_stock_code || row.operation_type_name || '');
            sel.appendChild(opt);
        }
    });
}

function resetForm() {
    document.getElementById('rowForm').reset();
    document.getElementById('f_product_tree_id').value = 0;
    document.getElementById('f_amount').value = 1;
    document.getElementById('f_op_amount').value = 1;
    /* Malzeme seçili başlat */
    document.getElementById('rt_malzeme').checked = true;
    toggleRowType('malzeme');
}

function openAddModal(parentId) {
    resetForm();
    buildParentSelect(0);
    document.getElementById('f_parent_tree_id_select').value = parentId || 0;
    document.getElementById('rowModalLabel').innerHTML =
        '<i class="fas fa-plus-circle me-2"></i>' + (parentId ? 'Alt Satır Ekle' : 'Kök Satır Ekle');
    var el = document.getElementById('rowModal');
    if (el.parentNode !== document.body) document.body.appendChild(el);
    new bootstrap.Modal(el).show();
}

function openEditModal(row) {
    resetForm();
    document.getElementById('f_product_tree_id').value = row.product_tree_id;

    var isOp = row.operation_type_id > 0 && row.component_stock_id === 0;
    if (isOp) {
        document.getElementById('rt_operasyon').checked = true;
        toggleRowType('operasyon');
        document.getElementById('f_operation_type_id').value = row.operation_type_id || 0;
        document.getElementById('f_op_amount').value         = row.amount || 1;
    } else {
        document.getElementById('rt_malzeme').checked = true;
        toggleRowType('malzeme');
        buildParentSelect(row.product_tree_id);
        document.getElementById('f_parent_tree_id_select').value  = row.related_product_tree_id || 0;
        document.getElementById('f_component_stock_id').value     = row.component_stock_id || 0;
        document.getElementById('f_amount').value                 = row.amount || 1;
        document.getElementById('f_unit_id').value                = row.unit_id || 0;
        document.getElementById('f_fire_amount').value            = row.fire_amount || 0;
        document.getElementById('f_fire_rate').value              = row.fire_rate || 0;
    }

    document.getElementById('f_station_id').value    = row.station_id    || 0;
    document.getElementById('f_line_number').value   = row.line_number   || 0;
    document.getElementById('f_process_stage').value = row.process_stage || 0;
    document.getElementById('f_detail').value        = row.detail || '';
    document.getElementById('f_is_phantom').checked  = row.is_phantom  === true;
    document.getElementById('f_is_configure').checked= row.is_configure === true;
    document.getElementById('f_is_sevk').checked     = row.is_sevk      === true;

    document.getElementById('rowModalLabel').innerHTML =
        '<i class="fas fa-edit me-2"></i>Satır Düzenle: ' +
        (isOp ? (row.operation_type_name || 'Operasyon') : (row.component_stock_code || ''));

    var el = document.getElementById('rowModal');
    if (el.parentNode !== document.body) document.body.appendChild(el);
    new bootstrap.Modal(el).show();
}

function saveRow() {
    var rowType = document.querySelector('input[name="f_row_type"]:checked').value;

    if (rowType === 'malzeme') {
        var compStockId = document.getElementById('f_component_stock_id').value;
        if (!compStockId || compStockId == '0') {
            uiNotify('Bileşen stok seçimi zorunludur.', 'warning'); return;
        }
        var amount = parseFloat(document.getElementById('f_amount').value);
        if (isNaN(amount) || amount <= 0) {
            uiNotify('Miktar sıfırdan büyük olmalıdır.', 'warning'); return;
        }
    } else {
        var opTypeId = document.getElementById('f_operation_type_id').value;
        if (!opTypeId || opTypeId == '0') {
            uiNotify('Operasyon tipi seçimi zorunludur.', 'warning'); return;
        }
    }

    var btn = document.getElementById('btnSaveRow');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Kaydediliyor...';

    var data = {
        product_tree_id   : document.getElementById('f_product_tree_id').value,
        root_stock_id     : rootStockId,
        row_type          : rowType,
        parent_tree_id    : document.getElementById('f_parent_tree_id_select') ? (document.getElementById('f_parent_tree_id_select').value || 0) : 0,
        component_stock_id: rowType === 'malzeme' ? document.getElementById('f_component_stock_id').value : 0,
        amount            : rowType === 'malzeme' ? document.getElementById('f_amount').value : document.getElementById('f_op_amount').value,
        unit_id           : rowType === 'malzeme' ? document.getElementById('f_unit_id').value : 0,
        fire_amount       : rowType === 'malzeme' ? document.getElementById('f_fire_amount').value : 0,
        fire_rate         : rowType === 'malzeme' ? document.getElementById('f_fire_rate').value : 0,
        operation_type_id : rowType === 'operasyon' ? document.getElementById('f_operation_type_id').value : 0,
        station_id        : document.getElementById('f_station_id').value,
        line_number       : document.getElementById('f_line_number').value,
        process_stage     : document.getElementById('f_process_stage').value,
        detail            : document.getElementById('f_detail').value,
        is_phantom        : document.getElementById('f_is_phantom').checked  ? 'true' : 'false',
        is_configure      : document.getElementById('f_is_configure').checked ? 'true' : 'false',
        is_sevk           : document.getElementById('f_is_sevk').checked     ? 'true' : 'false'
    };

    $.post('/product/form/save_product_tree_row.cfm', data, function(res) {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-save me-1"></i>Kaydet';
        if (res && res.success) {
            bootstrap.Modal.getInstance(document.getElementById('rowModal')).hide();
            uiNotify(res.mode === 'added' ? 'Satır eklendi.' : 'Satır güncellendi.', 'success');
            if (res.row) {
                if (res.mode === 'added') {
                    treeData.push(res.row);
                } else {
                    var idx = treeData.findIndex(function(x) { return x.product_tree_id === res.row.product_tree_id; });
                    if (idx >= 0) treeData[idx] = res.row; else treeData.push(res.row);
                }
                refreshTree();
                document.getElementById('recordCount').textContent = treeData.length + ' satır';
            } else {
                location.reload();
            }
        } else {
            uiNotify((res && res.message) || 'Kayıt başarısız.', 'error');
        }
    }, 'json').fail(function() {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-save me-1"></i>Kaydet';
        uiNotify('Sunucu hatası.', 'error');
    });
}

function deleteRow(id) {
    var row = treeData.find(function(x) { return x.product_tree_id === id; });
    var label = row ? (row.component_stock_code || row.operation_type_name || ('ID:' + id)) : ('ID:' + id);
    uiConfirm(
        '"' + label + '" satırını ve tüm alt satırlarını silmek istiyor musunuz?',
        'Silme Onayı',
        function(ok) {
        if (!ok) return;
        $.post('/product/form/delete_product_tree_row.cfm',
            { product_tree_id: id, root_stock_id: rootStockId },
            function(res) {
                if (res && res.success) {
                    uiNotify('Satır silindi.', 'success');
                    var deleted = res.deleted_ids || [id];
                    treeData = treeData.filter(function(x) { return deleted.indexOf(x.product_tree_id) === -1; });
                    refreshTree();
                    document.getElementById('recordCount').textContent = treeData.length + ' satır';
                } else {
                    uiNotify((res && res.message) || 'Silme başarısız.', 'error');
                }
            }, 'json').fail(function() { uiNotify('Sunucu hatası.', 'error'); });
    });
}
</script>
</cfoutput>
