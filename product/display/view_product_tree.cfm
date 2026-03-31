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
            <div class="d-flex align-items-center gap-2">
                <button class="btn btn-sm btn-outline-secondary bom-ctrl-btn" onclick="toggleExpandAll(true)" title="Tümünü Aç">
                    <i class="fas fa-angle-double-down"></i>
                </button>
                <button class="btn btn-sm btn-outline-secondary bom-ctrl-btn" onclick="toggleExpandAll(false)" title="Tümünü Kapat">
                    <i class="fas fa-angle-double-up"></i>
                </button>
                <span class="record-count" id="recordCount">Yükleniyor...</span>
            </div>
        </div>
        <cfoutput>
        <div class="tree-info-strip">
            <span class="bom-badge"><i class="fas fa-code-branch me-1"></i>BOM</span>
            <span class="bom-sep">|</span>
            <strong class="text-dark">#htmlEditFormat(getRootStock.stock_code)#</strong>
            <span class="text-muted ms-1 small">#htmlEditFormat(getRootStock.product_name)#</span>
            <cfif len(trim(getRootStock.product_cat))>
            <span class="bom-sep ms-2">|</span>
            <span class="text-muted small">#htmlEditFormat(getRootStock.product_cat)#</span>
            </cfif>
        </div>
        </cfoutput>
        <div class="card-body p-0">
            <div id="treeGrid"></div>
        </div>
    </div>
</div>

<!--- Stiller --->
<style>
/* ── Genişlet / Daralt düğmeleri ── */
.bom-ctrl-btn {
    width: 28px; height: 28px; padding: 0;
    display: inline-flex; align-items: center; justify-content: center;
    border-radius: 6px; font-size: 0.75rem;
}
/* ── BOM Bilgi Şeridi ── */
.tree-info-strip {
    display: flex; align-items: center; gap: 10px;
    background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
    border-bottom: 1px solid #bfdbfe;
    padding: 9px 16px; font-size: 0.83rem;
}
.bom-badge {
    background: var(--primary); color: #fff;
    font-size: 0.68rem; font-weight: 700;
    padding: 3px 9px; border-radius: 20px; letter-spacing: 0.5px;
}
.bom-sep { color: #93c5fd; }
/* ── Modal Bölüm kartları ── */
.modal-section {
    background: #f8fafc; border: 1px solid #e8edf3;
    border-radius: 10px; padding: 14px 16px; margin-bottom: 12px;
}
.modal-section.section-malzeme   { border-left: 3px solid #3b82f6; }
.modal-section.section-operasyon { border-left: 3px solid #f59e0b; }
.modal-section.section-common    { border-left: 3px solid #10b981; }
.modal-section.section-flags     { border-left: 3px solid #8b5cf6; }
.modal-section-title {
    font-size: 0.7rem; font-weight: 700;
    text-transform: uppercase; letter-spacing: 1px;
    color: #64748b; margin-bottom: 12px;
    display: flex; align-items: center; gap: 6px;
}
.modal-section-title i { color: var(--accent); font-size: 0.68rem; }
.row-type-selector .btn-outline-primary,
.row-type-selector .btn-outline-warning  { border-width: 2px; font-weight: 600; }
/* ── Modal z-index ── */
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
                    <div class="row-type-selector mb-3">
                        <div class="btn-group w-100" role="group">
                            <input type="radio" class="btn-check" name="f_row_type" id="rt_malzeme" value="malzeme" checked>
                            <label class="btn btn-outline-primary" for="rt_malzeme">
                                <i class="fas fa-box me-2"></i>Malzeme / Yarı Mamul
                            </label>
                            <input type="radio" class="btn-check" name="f_row_type" id="rt_operasyon" value="operasyon">
                            <label class="btn btn-outline-warning" for="rt_operasyon">
                                <i class="fas fa-cogs me-2"></i>Operasyon / İşlem
                            </label>
                        </div>
                    </div>

                    <!--- ─── Malzeme alanları ─── --->
                    <div id="section_malzeme" class="modal-section section-malzeme">
                        <div class="modal-section-title"><i class="fas fa-box"></i>Malzeme Bilgileri</div>
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
                    <div id="section_operasyon" class="modal-section section-operasyon" style="display:none;">
                        <div class="modal-section-title"><i class="fas fa-cogs"></i>Operasyon Bilgileri</div>
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
                    <div class="modal-section section-common">
                        <div class="modal-section-title"><i class="fas fa-sliders-h"></i>Ortak Bilgiler</div>
                        <div class="row g-3">
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
                    </div>

                    <!--- ─── Bayraklar ─── --->
                    <div class="modal-section section-flags">
                        <div class="modal-section-title"><i class="fas fa-tags"></i>Özellikler</div>
                        <div class="row g-3">
                            <div class="col-md-4 d-flex align-items-center">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="f_is_phantom">
                                    <label class="form-check-label" for="f_is_phantom">Sanal (Phantom)</label>
                                </div>
                            </div>
                            <div class="col-md-4 d-flex align-items-center">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="f_is_configure">
                                    <label class="form-check-label" for="f_is_configure">Konfigüre</label>
                                </div>
                            </div>
                            <div class="col-md-4 d-flex align-items-center">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="f_is_sevk">
                                    <label class="form-check-label" for="f_is_sevk">Sevk</label>
                                </div>
                            </div>
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer" style="background:#f8fafc;">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                    <i class="fas fa-times me-1"></i>İptal
                </button>
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
window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    initTree();
});

function initTree() {
    $('##treeGrid').dxTreeList({
        dataSource: treeData,
        keyExpr: 'product_tree_id',
        parentIdExpr: 'related_product_tree_id',
        rootValue: 0,
        showBorders: true, showRowLines: true, showColumnLines: true,
        rowAlternationEnabled: true, columnAutoWidth: true,
        allowColumnReordering: true, allowColumnResizing: true, columnResizingMode: 'widget',
        autoExpandAll: true,
        paging: { enabled: false },
        filterRow: { visible: true },
        headerFilter: { visible: true },
        searchPanel: { visible: true, width: 240, placeholder: 'Ara...' },
        sorting: { mode: 'multiple' },
        columnChooser: { enabled: true, mode: 'select', title: 'Sütun Seçimi' },
        scrolling: { mode: 'standard' },
        onContentReady: function(e) {
            var total = e.component.getVisibleRows().length;
            document.getElementById('recordCount').textContent = total + ' satır';
        },
        columns: [
            { dataField: 'line_number',
              caption: '##',
              width: 55, alignment: 'center', dataType: 'number'
            },
            {
                caption: 'Satır',
                minWidth: 220,
                cellTemplate: function(c, o) {
                    var d = o.data;
                    var isOp = d.operation_type_id > 0 && d.component_stock_id === 0;
                    if (isOp) {
                        $('<span>').addClass('badge bg-warning text-dark me-1').html('<i class="fas fa-cogs"></i>').appendTo(c);
                        $('<span>').text(d.operation_type_name || 'Operasyon').appendTo(c);
                    } else {
                        $('<span>').addClass('fw-semibold me-1').text(d.component_stock_code || '').appendTo(c);
                        if (d.component_name) {
                            $('<span>').addClass('small text-muted').text('— ' + d.component_name).appendTo(c);
                        }
                    }
                }
            },
            { dataField: 'amount',
              caption: 'Miktar',
              width: 90, alignment: 'right', dataType: 'number',
              format: { type: 'fixedPoint', precision: 4 }
            },
            { dataField: 'unit_name',
              caption: 'Birim',
              width: 75
            },
            { dataField: 'station_name',
              caption: 'İstasyon',
              width: 160,
              cellTemplate: function(c, o) { $('<span>').addClass('small').text(o.value || '-').appendTo(c); }
            },
            { dataField: 'fire_rate',
              caption: 'Fire %',
              width: 70, alignment: 'right', dataType: 'number',
              format: { type: 'fixedPoint', precision: 2 },
              cellTemplate: function(c, o) {
                  if (o.value) $('<span>').addClass('small text-warning').text(o.value + '%').appendTo(c);
              }
            },
            {
              caption: 'Bayraklar', width: 120, allowSorting: false, allowFiltering: false,
              cellTemplate: function(c, o) {
                  var d = o.data;
                  if (d.is_phantom)   $('<span>').addClass('badge bg-warning text-dark small me-1').text('Sanal').appendTo(c);
                  if (d.is_configure) $('<span>').addClass('badge bg-info text-dark small me-1').text('Konfigüre').appendTo(c);
                  if (d.is_sevk)      $('<span>').addClass('badge bg-secondary small').text('Sevk').appendTo(c);
              }
            },
            { dataField: 'detail',
              caption: 'Detay',
              minWidth: 120,
              cellTemplate: function(c, o) { $('<span>').addClass('small text-muted').text(o.value || '').appendTo(c); }
            },
            {
                caption: 'İşlemler', width: 135, alignment: 'center', allowSorting: false, allowFiltering: false,
                cellTemplate: function(c, o) {
                    var d = o.data;
                    var g = $('<div>').addClass('d-flex gap-1 justify-content-center');
                    if (d.is_sub_bom) {
                        /* Alt ağaç satırı — kendi BOM sayfasına yönlendir */
                        $('<a>').addClass('btn btn-sm btn-outline-secondary')
                            .attr('title', 'Kendi Ağacını Görüntüle')
                            .attr('href', 'index.cfm?fuseaction=product.view_product_tree&stock_id=' + d.bom_owner_stock_id)
                            .html('<i class="fas fa-external-link-alt"></i>')
                            .appendTo(g);
                    } else {
                        $('<button>').addClass('btn btn-sm btn-outline-success').attr('title', 'Alt Satır Ekle')
                            .html('<i class="fas fa-plus"></i>')
                            .on('click', function() { openAddModal(d.product_tree_id); })
                            .appendTo(g);
                        $('<button>').addClass('btn btn-sm btn-outline-primary').attr('title', 'Düzenle')
                            .html('<i class="fas fa-edit"></i>')
                            .on('click', function() { openEditModal(d); })
                            .appendTo(g);
                        $('<button>').addClass('btn btn-sm btn-outline-danger').attr('title', 'Sil')
                            .html('<i class="fas fa-trash"></i>')
                            .on('click', function() { deleteRow(d.product_tree_id); })
                            .appendTo(g);
                    }
                    g.appendTo(c);
                }
            }
        ]
    });
}

function refreshTree() {
    $('##treeGrid').dxTreeList('instance').option('dataSource', treeData);
}

function toggleExpandAll(expand) {
    var inst = $('##treeGrid').dxTreeList('instance');
    if (expand) { inst.expandAll(); } else { inst.collapseAll(); }
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
            DevExpress.ui.notify('Bileşen stok seçimi zorunludur.', 'warning', 2500); return;
        }
        var amount = parseFloat(document.getElementById('f_amount').value);
        if (isNaN(amount) || amount <= 0) {
            DevExpress.ui.notify('Miktar sıfırdan büyük olmalıdır.', 'warning', 2500); return;
        }
    } else {
        var opTypeId = document.getElementById('f_operation_type_id').value;
        if (!opTypeId || opTypeId == '0') {
            DevExpress.ui.notify('Operasyon tipi seçimi zorunludur.', 'warning', 2500); return;
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
            DevExpress.ui.notify(res.mode === 'added' ? 'Satır eklendi.' : 'Satır güncellendi.', 'success', 2500);
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
            DevExpress.ui.notify((res && res.message) || 'Kayıt başarısız.', 'error', 3500);
        }
    }, 'json').fail(function() {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-save me-1"></i>Kaydet';
        DevExpress.ui.notify('Sunucu hatası.', 'error', 3000);
    });
}

function deleteRow(id) {
    var row = treeData.find(function(x) { return x.product_tree_id === id; });
    var label = row ? (row.component_stock_code || row.operation_type_name || ('ID:' + id)) : ('ID:' + id);
    DevExpress.ui.dialog.confirm(
        '"' + label + '" satırını ve tüm alt satırlarını silmek istiyor musunuz?',
        'Silme Onayı'
    ).then(function(ok) {
        if (!ok) return;
        $.post('/product/form/delete_product_tree_row.cfm',
            { product_tree_id: id, root_stock_id: rootStockId },
            function(res) {
                if (res && res.success) {
                    DevExpress.ui.notify('Satır silindi.', 'success', 2500);
                    var deleted = res.deleted_ids || [id];
                    treeData = treeData.filter(function(x) { return deleted.indexOf(x.product_tree_id) === -1; });
                    refreshTree();
                    document.getElementById('recordCount').textContent = treeData.length + ' satır';
                } else {
                    DevExpress.ui.notify((res && res.message) || 'Silme başarısız.', 'error', 3500);
                }
            }, 'json').fail(function() { DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); });
    });
}
</script>
</cfoutput>
