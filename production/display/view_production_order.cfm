<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.p_order_id" default="0">
<cfset pOrderId = isNumeric(url.p_order_id) AND val(url.p_order_id) gt 0 ? val(url.p_order_id) : 0>

<cfif pOrderId eq 0>
    <cflocation url="index.cfm?fuseaction=production.list_production_orders" addtoken="false">
</cfif>

<!--- Ana emir bilgileri --->
<cfquery name="getOrder" datasource="boyahane">
    SELECT po.*,
           COALESCE(ci.color_code,'')           AS color_code,
           COALESCE(ci.color_name,'')           AS color_name,
           COALESCE(ci.boya_derecesi,'')        AS boya_derecesi,
           COALESCE(ci.flote, 0)                AS flote,
           COALESCE(ci.renk_tonu, 0)            AS renk_tonu,
           COALESCE(c.nickname, c.fullname,'')  AS company_name,
           COALESCE(s.stock_code,'')            AS stock_code,
           COALESCE(ws.station_name,'')         AS station_name,
           COALESCE(ws.capacity, 0)             AS ws_capacity
    FROM production_orders po
    LEFT JOIN stocks       s  ON po.stock_id    = s.stock_id
    LEFT JOIN color_info   ci ON po.stock_id    = ci.stock_id
    LEFT JOIN company      c  ON ci.company_id  = c.company_id
    LEFT JOIN workstations ws ON po.station_id  = ws.station_id
    WHERE po.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getOrder.recordCount>
    <cflocation url="index.cfm?fuseaction=production.list_production_orders" addtoken="false">
</cfif>

<!--- Reçete (product_tree) — operasyon bazlı hiyerarşi --->
<cfquery name="getRecipe" datasource="boyahane">
    SELECT
        pt.product_tree_id,
        COALESCE(pt.related_product_tree_id, 0) AS parent_tree_id,
        COALESCE(pt.related_id, 0)              AS row_stock_id,
        COALESCE(pt.operation_type_id, 0)       AS operation_type_id,
        COALESCE(s.stock_code,'')               AS stock_code,
        COALESCE(p.product_name,'')             AS product_name,
        COALESCE(pt.amount, 1)                  AS unit_amount,
        COALESCE(pt.unit_id, 0)                 AS unit_id,
        COALESCE(pt.line_number, 0)             AS line_number
    FROM product_tree pt
    LEFT JOIN stocks  s  ON pt.related_id = s.stock_id
    LEFT JOIN product p  ON s.product_id  = p.product_id
    WHERE pt.stock_id = <cfqueryparam value="#getOrder.stock_id#" cfsqltype="cf_sql_integer">
    ORDER BY pt.line_number, pt.product_tree_id
</cfquery>

<!--- Mevcut tüketim satırları (production_orders_stocks) --->
<cfquery name="getStocks" datasource="boyahane">
    SELECT pos.por_stock_id,
           pos.stock_id,
           COALESCE(s.stock_code,'')   AS stock_code,
           COALESCE(p.product_name,'') AS product_name,
           COALESCE(pos.amount, 0)     AS amount,
           COALESCE(pos.product_unit_id, 0) AS unit_id,
           COALESCE(pos.line_number,0) AS line_number
    FROM production_orders_stocks pos
    LEFT JOIN stocks  s ON pos.stock_id  = s.stock_id
    LEFT JOIN product p ON s.product_id  = p.product_id
    WHERE pos.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    ORDER BY pos.line_number, pos.por_stock_id
</cfquery>

<!--- Reçeteyi JS için hazırla (hiyerarşik) --->
<cfset opsMap  = {}>
<cfset opsList = []>
<cfloop query="getRecipe">
    <cfif val(operation_type_id) gt 0>
        <cfset op = { "name": product_name ?: "Operasyon", "children": [] }>
        <cfset opsMap["op_" & val(product_tree_id)] = op>
        <cfset arrayAppend(opsList, op)>
    </cfif>
</cfloop>
<cfloop query="getRecipe">
    <cfif val(operation_type_id) eq 0 AND val(parent_tree_id) gt 0>
        <cfset pKey = "op_" & val(parent_tree_id)>
        <cfif structKeyExists(opsMap, pKey)>
            <cfset arrayAppend(opsMap[pKey].children, {
                "stock_id"    : val(row_stock_id),
                "stock_code"  : stock_code    ?: "",
                "product_name": product_name  ?: "",
                "unit_amount" : isNumeric(unit_amount) ? val(unit_amount) : 1,
                "total_amount": isNumeric(unit_amount) ? (val(unit_amount) * val(getOrder.quantity)) : val(getOrder.quantity),
                "unit_id"     : val(unit_id)
            })>
        </cfif>
    </cfif>
</cfloop>

<cfset stocksArr = []>
<cfloop query="getStocks">
    <cfset arrayAppend(stocksArr, {
        "por_stock_id": val(por_stock_id),
        "stock_id"    : val(stock_id),
        "stock_code"  : stock_code    ?: "",
        "product_name": product_name  ?: "",
        "amount"      : isNumeric(amount) ? val(amount) : 0,
        "line_number" : val(line_number)
    })>
</cfloop>

<cfset statusLabels = { "1": "Planlandı", "2": "Devam Ediyor", "5": "Tamamlandı", "9": "İptal" }>
<cfset curStatus    = val(getOrder.status)>
<cfset statusLabel  = structKeyExists(statusLabels, curStatus) ? statusLabels[curStatus] : "">
<cfset statusColor  = (curStatus eq 1 ? "secondary" : (curStatus eq 2 ? "primary" : (curStatus eq 5 ? "success" : "danger")))>

<style>
/* ---- view_production_order page-specific ---- */
.vpo-status-bar {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    padding: 12px 16px;
    background: #fff;
    border-bottom: 1px solid #e3e8ef;
    margin-bottom: 0;
}
.vpo-metric {
    display: flex;
    flex-direction: column;
    min-width: 110px;
}
.vpo-metric-label {
    font-size: 0.68rem;
    text-transform: uppercase;
    letter-spacing: .06em;
    color: #8a98a8;
    font-weight: 600;
}
.vpo-metric-value {
    font-size: 1rem;
    font-weight: 700;
    color: var(--primary, #1a3a5c);
    line-height: 1.3;
}
.vpo-metric-value.accent { color: var(--accent, #e67e22); }
.vpo-metric-value.success { color: #2ecc71; }
.vpo-metric-divider {
    width: 1px;
    background: #e3e8ef;
    align-self: stretch;
    margin: 2px 0;
}
/* summary table */
.vpo-info-table td { padding: 6px 8px; font-size: 0.82rem; border: none; }
.vpo-info-table tr:nth-child(even) td { background: #f7f9fc; }
.vpo-info-table .lbl { color: #8a98a8; font-weight: 500; white-space: nowrap; width: 42%; }
.vpo-info-table .lbl i { width: 14px; text-align: center; }
.vpo-info-table .val { color: #2c3e50; font-weight: 500; }
/* recipe */
.vpo-op-group { border-left: 3px solid var(--accent, #e67e22); border-radius: 0 6px 6px 0; background: #fffaf5; margin-bottom: 10px; padding: 8px 10px; }
.vpo-op-title { font-size: 0.78rem; font-weight: 700; text-transform: uppercase; letter-spacing: .05em; color: var(--accent, #e67e22); margin-bottom: 6px; }
.vpo-recipe-row { display: flex; justify-content: space-between; align-items: center; font-size: 0.8rem; padding: 4px 0; border-bottom: 1px dashed #ede8e0; }
.vpo-recipe-row:last-child { border-bottom: none; }
.vpo-recipe-name { color: #2c3e50; }
.vpo-recipe-name .stock-code { font-weight: 700; margin-right: 4px; color: var(--primary, #1a3a5c); }
.vpo-recipe-amt { white-space: nowrap; color: #8a98a8; font-size: 0.75rem; }
.vpo-recipe-amt strong { color: #2c3e50; font-size: 0.82rem; }
/* action header buttons */
.vpo-action-btn {
    display: inline-flex; align-items: center; gap: 5px;
    padding: 6px 12px; border-radius: 6px; font-size: 0.8rem; font-weight: 600;
    border: 1.5px solid; cursor: pointer; text-decoration: none; transition: all .2s;
    white-space: nowrap;
}
.vpo-action-btn:hover { opacity: .85; text-decoration: none; }
.vpo-action-btn.start   { border-color: var(--primary,#1a3a5c); color: var(--primary,#1a3a5c); background: #fff; }
.vpo-action-btn.start:hover { background: var(--primary,#1a3a5c); color: #fff; }
.vpo-action-btn.done    { border-color: #27ae60; color: #27ae60; background: #fff; }
.vpo-action-btn.done:hover { background: #27ae60; color: #fff; }
.vpo-action-btn.ops     { border-color: #2980b9; color: #2980b9; background: #fff; }
.vpo-action-btn.ops:hover { background: #2980b9; color: #fff; }
.vpo-action-btn.results { border-color: #7f8c8d; color: #7f8c8d; background: #fff; }
.vpo-action-btn.results:hover { background: #7f8c8d; color: #fff; }
.vpo-action-btn.edit    { border-color: var(--accent,#e67e22); color: var(--accent,#e67e22); background: #fff; }
.vpo-action-btn.edit:hover { background: var(--accent,#e67e22); color: #fff; }
#stocksGrid { height: 320px; }
</style>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-industry"></i></div>
        <div class="page-header-title">
            <h1>#htmlEditFormat(getOrder.p_order_no)#</h1>
            <p>
                #htmlEditFormat(getOrder.color_code)#
                <cfif len(trim(getOrder.color_name))> — #htmlEditFormat(getOrder.color_name)#</cfif>
                <cfif len(trim(getOrder.company_name))>&nbsp;|&nbsp;#htmlEditFormat(getOrder.company_name)#</cfif>
            </p>
        </div>
    </div>
    <div class="d-flex gap-2 flex-wrap align-items-center">
        <span class="badge bg-#statusColor# px-3 py-2 fs-6">#htmlEditFormat(statusLabel)#</span>
        <cfif curStatus eq 1>
            <button class="vpo-action-btn start" onclick="setStatus(2)"><i class="fas fa-play"></i>Başlat</button>
        </cfif>
        <cfif curStatus eq 2>
            <button class="vpo-action-btn done" onclick="openFinalizeModal()"><i class="fas fa-flag-checkered"></i>Sonuçlandır</button>
        </cfif>
        <a class="vpo-action-btn ops" href="index.cfm?fuseaction=production.view_production_operations&p_order_id=#pOrderId#"><i class="fas fa-cogs"></i>Operasyonlar</a>
        <a class="vpo-action-btn results" href="index.cfm?fuseaction=production.view_production_results&p_order_id=#pOrderId#"><i class="fas fa-clipboard-list"></i>Sonuçlar</a>
        <cfif curStatus lt 5>
            <a class="vpo-action-btn edit" href="index.cfm?fuseaction=production.add_production_order&p_order_id=#pOrderId#"><i class="fas fa-edit"></i>Düzenle</a>
        </cfif>
        <a class="btn-back" href="index.cfm?fuseaction=production.list_production_orders"><i class="fas fa-arrow-left"></i>Liste</a>
    </div>
</div>

<!--- Metrics strip --->
<div class="vpo-status-bar px-3">
    <div class="vpo-metric">
        <span class="vpo-metric-label"><i class="fas fa-weight-hanging me-1"></i>Miktar</span>
        <span class="vpo-metric-value accent">#numberFormat(getOrder.quantity,'_.___')# kg</span>
    </div>
    <div class="vpo-metric-divider"></div>
    <div class="vpo-metric">
        <span class="vpo-metric-label"><i class="fas fa-desktop me-1"></i>Makina</span>
        <span class="vpo-metric-value">#len(trim(getOrder.station_name)) ? htmlEditFormat(getOrder.station_name) : '—'#</span>
    </div>
    <div class="vpo-metric-divider"></div>
    <div class="vpo-metric">
        <span class="vpo-metric-label"><i class="fas fa-thermometer-half me-1"></i>Boya Derecesi</span>
        <span class="vpo-metric-value">#len(trim(getOrder.boya_derecesi)) ? htmlEditFormat(getOrder.boya_derecesi) : '—'#</span>
    </div>
    <div class="vpo-metric-divider"></div>
    <div class="vpo-metric">
        <span class="vpo-metric-label"><i class="fas fa-tint me-1"></i>Flote</span>
        <span class="vpo-metric-value">#val(getOrder.flote) gt 0 ? val(getOrder.flote) : '—'#</span>
    </div>
    <div class="vpo-metric-divider"></div>
    <div class="vpo-metric">
        <span class="vpo-metric-label"><i class="fas fa-palette me-1"></i>Renk Tonu</span>
        <span class="vpo-metric-value">#val(getOrder.renk_tonu) gt 0 ? val(getOrder.renk_tonu) : '—'#</span>
    </div>
    <cfif isNumeric(getOrder.result_amount) AND val(getOrder.result_amount) gt 0>
    <div class="vpo-metric-divider"></div>
    <div class="vpo-metric">
        <span class="vpo-metric-label"><i class="fas fa-check-circle me-1"></i>Sonuç</span>
        <span class="vpo-metric-value success">#numberFormat(getOrder.result_amount,'_.___')# kg</span>
    </div>
    </cfif>
    <cfif isDate(getOrder.start_date)>
    <div class="vpo-metric-divider"></div>
    <div class="vpo-metric">
        <span class="vpo-metric-label"><i class="fas fa-calendar-alt me-1"></i>Başlangıç (Plan)</span>
        <span class="vpo-metric-value" style="font-size:.85rem;">#dateFormat(getOrder.start_date,'dd/mm/yyyy')#</span>
    </div>
    </cfif>
    <cfif isDate(getOrder.finish_date)>
    <div class="vpo-metric-divider"></div>
    <div class="vpo-metric">
        <span class="vpo-metric-label"><i class="fas fa-calendar-check me-1"></i>Bitiş (Plan)</span>
        <span class="vpo-metric-value" style="font-size:.85rem;">#dateFormat(getOrder.finish_date,'dd/mm/yyyy')#</span>
    </div>
    </cfif>
</div>

<div class="px-3 pt-3 pb-5">
<div class="row g-3">

<!--- Sol: Emir Özeti --->
<div class="col-lg-4">
    <div class="grid-card h-100">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Emir Detayları</div>
        </div>
        <div class="card-body p-0">
            <table class="vpo-info-table w-100">
                <tr><td class="lbl"><i class="fas fa-hashtag"></i> Emir No</td><td class="val"><strong>#htmlEditFormat(getOrder.p_order_no)#</strong></td></tr>
                <tr><td class="lbl"><i class="fas fa-barcode"></i> Lot No</td><td class="val">#len(trim(getOrder.lot_no)) ? htmlEditFormat(getOrder.lot_no) : '—'#</td></tr>
                <tr><td class="lbl"><i class="fas fa-desktop"></i> Makina</td><td class="val">#len(trim(getOrder.station_name)) ? htmlEditFormat(getOrder.station_name) : '—'#</td></tr>
                <tr><td class="lbl"><i class="fas fa-weight-hanging"></i> Miktar</td><td class="val"><strong style="color:var(--accent)">#numberFormat(getOrder.quantity,'_.___')# kg</strong></td></tr>
                <tr><td class="lbl"><i class="fas fa-palette"></i> Renk Tonu</td><td class="val">#val(getOrder.renk_tonu) gt 0 ? val(getOrder.renk_tonu) : '—'#</td></tr>
                <tr><td class="lbl"><i class="fas fa-thermometer-half"></i> Boya Derecesi</td><td class="val">#len(trim(getOrder.boya_derecesi)) ? htmlEditFormat(getOrder.boya_derecesi) : '—'#</td></tr>
                <tr><td class="lbl"><i class="fas fa-tint"></i> Flote</td><td class="val">#val(getOrder.flote) gt 0 ? val(getOrder.flote) : '—'#</td></tr>
                <tr><td class="lbl"><i class="fas fa-calendar-alt"></i> Başlangıç</td><td class="val">#isDate(getOrder.start_date) ? dateFormat(getOrder.start_date,'dd/mm/yyyy HH:nn') : '—'#</td></tr>
                <tr><td class="lbl"><i class="fas fa-calendar-check"></i> Bitiş</td><td class="val">#isDate(getOrder.finish_date) ? dateFormat(getOrder.finish_date,'dd/mm/yyyy HH:nn') : '—'#</td></tr>
                <cfif isDate(getOrder.start_date_real)>
                <tr><td class="lbl"><i class="fas fa-play-circle"></i> Başlangıç (Gerçek)</td><td class="val" style="color:##27ae60">#dateFormat(getOrder.start_date_real,'dd/mm/yyyy HH:nn')#</td></tr>
                </cfif>
                <cfif isDate(getOrder.finish_date_real)>
                <tr><td class="lbl"><i class="fas fa-stop-circle"></i> Bitiş (Gerçek)</td><td class="val" style="color:##27ae60">#dateFormat(getOrder.finish_date_real,'dd/mm/yyyy HH:nn')#</td></tr>
                </cfif>
                <cfif isNumeric(getOrder.result_amount) AND val(getOrder.result_amount) gt 0>
                <tr><td class="lbl"><i class="fas fa-check-circle"></i> Sonuç Miktarı</td><td class="val" style="color:##27ae60"><strong>#numberFormat(getOrder.result_amount,'_.___')# kg</strong></td></tr>
                </cfif>
                <cfif len(trim(getOrder.detail))>
                <tr><td class="lbl"><i class="fas fa-comment-alt"></i> Açıklama</td><td class="val">#htmlEditFormat(getOrder.detail)#</td></tr>
                </cfif>
                <tr><td class="lbl"><i class="fas fa-clock"></i> Kayıt Tarihi</td><td class="val">#isDate(getOrder.record_date) ? dateFormat(getOrder.record_date,'dd/mm/yyyy') : '—'#</td></tr>
            </table>
        </div>
    </div>
</div>

<!--- Orta: Reçete --->
<div class="col-lg-4">
    <div class="grid-card h-100">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-flask"></i>Boya Reçetesi</div>
            <span class="record-count">#numberFormat(getOrder.quantity,'_.___')# kg</span>
        </div>
        <div class="card-body p-3" style="overflow-y:auto;max-height:420px;">
            <cfif NOT arrayLen(opsList)>
                <div class="text-center py-4 text-muted">
                    <i class="fas fa-flask fa-2x mb-2 d-block opacity-25"></i>
                    <small>Bu renk için reçete tanımlı değil.</small>
                </div>
            <cfelse>
                <cfloop array="#opsList#" index="op">
                    <div class="vpo-op-group">
                        <div class="vpo-op-title"><i class="fas fa-cog me-1"></i>#htmlEditFormat(op.name)#</div>
                        <cfloop array="#op.children#" index="ch">
                            <div class="vpo-recipe-row">
                                <span class="vpo-recipe-name">
                                    <span class="stock-code">#htmlEditFormat(ch.stock_code)#</span>#htmlEditFormat(ch.product_name)#
                                </span>
                                <span class="vpo-recipe-amt">
                                    #numberFormat(ch.unit_amount,'0.000')# &times; #numberFormat(getOrder.quantity,'0.000')#
                                    = <strong>#numberFormat(ch.total_amount,'0.000')# kg</strong>
                                </span>
                            </div>
                        </cfloop>
                    </div>
                </cfloop>
            </cfif>
        </div>
    </div>
</div>

<!--- Sağ: Hammadde Tüketimi --->
<div class="col-lg-4">
    <div class="grid-card h-100">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-boxes"></i>Hammadde Tüketimi</div>
            <button class="grid-btn grid-btn-edit" onclick="editStocks()" title="Düzenle"><i class="fas fa-edit"></i></button>
        </div>
        <div class="card-body p-2">
            <div id="stocksGrid"></div>
        </div>
    </div>
</div>

</div><!--- row --->
</div><!--- px-3 --->

<!--- Sonuçlandır modal --->
<div id="finalizePopupContainer"></div>

<script>
var pOrderId   = #pOrderId#;
var curStatus  = #curStatus#;
var stocksData = #serializeJSON(stocksArr)#;

$(function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    buildStocksGrid();
    initFinalizePopup();
});

function buildStocksGrid() {
    $('##stocksGrid').dxDataGrid({
        dataSource: stocksData,
        keyExpr: 'por_stock_id',
        showBorders: true,
        paging: { enabled: false },
        editing: {
            mode: 'row',
            allowUpdating: curStatus < 5,
            allowDeleting: curStatus < 5
        },
        onRowUpdated: function(e) { saveStockRow(e.data); },
        onRowRemoved: function(e) { deleteStockRow(e.data.por_stock_id); },
        columns: [
            { dataField:'stock_code',   caption:'Kodu',    width:100 },
            { dataField:'product_name', caption:'Malzeme', minWidth:120 },
            { dataField:'amount',       caption:'Miktar',  width:90, alignment:'right', dataType:'number', format: { type:'fixedPoint', precision:3 }, allowEditing: true }
        ]
    });
}

function saveStockRow(row) {
    $.post('/production/form/save_production_stock.cfm', {
        por_stock_id: row.por_stock_id,
        amount: row.amount
    }, function(res) {
        if (!res || !res.success) DevExpress.ui.notify((res && res.message) || 'Kaydedilemedi.', 'error', 3000);
    }, 'json');
}

function deleteStockRow(id) {
    $.post('/production/form/save_production_stock.cfm', { por_stock_id: id, _delete: 1 }, function(res) {
        if (!res || !res.success) DevExpress.ui.notify((res && res.message) || 'Silinemedi.', 'error', 3000);
    }, 'json');
}

function editStocks() {
    $('##stocksGrid').dxDataGrid('instance').option('editing.allowUpdating', true);
}

function setStatus(newStatus) {
    $.post('/production/form/update_production_status.cfm', { p_order_id: pOrderId, status: newStatus }, function(res) {
        if (res && res.success) location.reload();
        else DevExpress.ui.notify((res && res.message) || 'Güncelleme başarısız.', 'error', 3000);
    }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); });
}

var finalizePopup = null;
function initFinalizePopup() {
    $('##finalizePopupContainer').dxPopup({
        title: 'Üretim Sonuçlandır',
        width: 420,
        height: 'auto',
        showCloseButton: true,
        contentTemplate: function(content) {
            content.append(
                $('<div class="p-3">').append(
                    $('<div class="mb-3">').append(
                        $('<label class="form-label">Gerçekleşen Miktar (kg) <span class="text-danger">*</span></label>'),
                        $('<input type="number" step="0.001" min="0" class="form-control" id="f_result_amount" placeholder="0.000">')
                    ),
                    $('<div class="mb-3">').append(
                        $('<label class="form-label">Not</label>'),
                        $('<textarea class="form-control" id="f_finalize_note" rows="2" maxlength="500"></textarea>')
                    ),
                    $('<button class="btn-save w-100" onclick="submitFinalize()"><i class="fas fa-flag-checkered me-1"></i>Tamamla</button>')
                )
            );
        }
    });
    finalizePopup = $('##finalizePopupContainer').dxPopup('instance');
}

function openFinalizeModal() { finalizePopup.show(); }

function submitFinalize() {
    var amt = parseFloat(document.getElementById('f_result_amount').value) || 0;
    if (amt <= 0) { DevExpress.ui.notify('Gerçekleşen miktar girilmelidir.', 'warning', 2500); return; }
    $.post('/production/form/finalize_production_order.cfm', {
        p_order_id    : pOrderId,
        result_amount : amt,
        note          : document.getElementById('f_finalize_note').value.trim()
    }, function(res) {
        if (res && res.success) {
            finalizePopup.hide();
            window.location.href = 'index.cfm?fuseaction=production.list_production_orders&success=finalized';
        } else {
            DevExpress.ui.notify((res && res.message) || 'Sonuçlandırma başarısız.', 'error', 3500);
        }
    }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); });
}
</script>
</cfoutput>
