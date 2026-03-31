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

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-industry"></i></div>
        <div class="page-header-title">
            <h1>#htmlEditFormat(getOrder.p_order_no)#</h1>
            <p>
                #htmlEditFormat(getOrder.color_code)# — #htmlEditFormat(getOrder.color_name)# &nbsp;|&nbsp;
                #htmlEditFormat(getOrder.company_name)#
                &nbsp;<span class="badge bg-#statusColor#">#htmlEditFormat(statusLabel)#</span>
            </p>
        </div>
    </div>
    <div class="d-flex gap-2">
        <cfif curStatus eq 1>
        <button class="btn btn-sm btn-outline-primary" onclick="setStatus(2)">
            <i class="fas fa-play me-1"></i>Başlat
        </button>
        </cfif>
        <cfif curStatus eq 2>
        <button class="btn btn-sm btn-outline-success" onclick="openFinalizeModal()">
            <i class="fas fa-flag-checkered me-1"></i>Sonuçlandır
        </button>
        </cfif>
        <a class="btn btn-sm btn-outline-info" href="index.cfm?fuseaction=production.view_production_operations&p_order_id=#pOrderId#">
            <i class="fas fa-cogs me-1"></i>Operasyonlar
        </a>
        <a class="btn btn-sm btn-outline-secondary" href="index.cfm?fuseaction=production.view_production_results&p_order_id=#pOrderId#">
            <i class="fas fa-clipboard-list me-1"></i>Sonuçlar
        </a>
        <cfif curStatus lt 5>
        <a class="btn btn-sm btn-outline-warning" href="index.cfm?fuseaction=production.add_production_order&p_order_id=#pOrderId#">
            <i class="fas fa-edit me-1"></i>Düzenle
        </a>
        </cfif>
        <a class="btn-back" href="index.cfm?fuseaction=production.list_production_orders">
            <i class="fas fa-arrow-left"></i>Listeye Dön
        </a>
    </div>
</div>

<div class="px-3 pb-5">
<div class="row g-3">

<!--- Sol: Emir Özeti --->
<div class="col-lg-4">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Emir Özeti</div>
        </div>
        <div class="card-body p-3">
            <table class="table table-sm table-borderless mb-0">
                <tr><td class="text-muted" style="width:45%">Emir No</td><td><strong>#htmlEditFormat(getOrder.p_order_no)#</strong></td></tr>
                <tr><td class="text-muted">Lot No</td><td>#htmlEditFormat(getOrder.lot_no)#</td></tr>
                <tr><td class="text-muted">Makina</td><td>#htmlEditFormat(getOrder.station_name)#</td></tr>
                <tr><td class="text-muted">Miktar (kg)</td><td><strong>#numberFormat(getOrder.quantity,'_.___')#</strong></td></tr>
                <tr><td class="text-muted">Renk Tonu</td><td>#getOrder.renk_tonu#</td></tr>
                <tr><td class="text-muted">Boya Derecesi</td><td>#htmlEditFormat(getOrder.boya_derecesi)#</td></tr>
                <tr><td class="text-muted">Flote</td><td>#getOrder.flote#</td></tr>
                <tr><td class="text-muted">Başlangıç (Plan)</td><td>#isDate(getOrder.start_date) ? dateFormat(getOrder.start_date,'dd/mm/yyyy HH:nn') : '-'#</td></tr>
                <tr><td class="text-muted">Bitiş (Plan)</td><td>#isDate(getOrder.finish_date) ? dateFormat(getOrder.finish_date,'dd/mm/yyyy HH:nn') : '-'#</td></tr>
                <cfif isDate(getOrder.start_date_real)>
                <tr><td class="text-muted">Başlangıç (Gerçek)</td><td class="text-success">#dateFormat(getOrder.start_date_real,'dd/mm/yyyy HH:nn')#</td></tr>
                </cfif>
                <cfif isDate(getOrder.finish_date_real)>
                <tr><td class="text-muted">Bitiş (Gerçek)</td><td class="text-success">#dateFormat(getOrder.finish_date_real,'dd/mm/yyyy HH:nn')#</td></tr>
                </cfif>
                <cfif isNumeric(getOrder.result_amount) AND val(getOrder.result_amount) gt 0>
                <tr><td class="text-muted">Sonuç Miktarı</td><td class="text-success"><strong>#numberFormat(getOrder.result_amount,'_.___')# kg</strong></td></tr>
                </cfif>
                <cfif len(trim(getOrder.detail))>
                <tr><td class="text-muted">Açıklama</td><td>#htmlEditFormat(getOrder.detail)#</td></tr>
                </cfif>
                <tr><td class="text-muted">Kayıt Tarihi</td><td>#isDate(getOrder.record_date) ? dateFormat(getOrder.record_date,'dd/mm/yyyy') : '-'#</td></tr>
            </table>
        </div>
    </div>
</div>

<!--- Orta: Reçete --->
<div class="col-lg-4">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-flask"></i>Boya Reçetesi</div>
        </div>
        <div class="card-body p-3">
            <cfif NOT arrayLen(opsList)>
                <p class="text-muted small">Bu renk için reçete tanımlı değil.</p>
            <cfelse>
                <cfloop array="#opsList#" index="op">
                    <div class="mb-3">
                        <div class="d-flex align-items-center gap-2 mb-1">
                            <i class="fas fa-cog text-muted small"></i>
                            <span class="fw-semibold small">#htmlEditFormat(op.name)#</span>
                        </div>
                        <ul class="list-group list-group-flush">
                            <cfloop array="#op.children#" index="ch">
                                <li class="list-group-item py-1 px-2 small d-flex justify-content-between">
                                    <span><i class="fas fa-circle me-1" style="font-size:5px;vertical-align:middle;color:##aaa"></i>#htmlEditFormat(ch.stock_code)# #htmlEditFormat(ch.product_name)#</span>
                                    <span class="text-muted">
                                        #numberFormat(ch.unit_amount,'0.000')# &times; #numberFormat(getOrder.quantity,'0.000')#
                                        = <strong>#numberFormat(ch.total_amount,'0.000')# kg</strong>
                                    </span>
                                </li>
                            </cfloop>
                        </ul>
                    </div>
                </cfloop>
            </cfif>
        </div>
    </div>
</div>

<!--- Sağ: Hammadde Tüketimi --->
<div class="col-lg-4">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-boxes"></i>Hammadde Tüketimi</div>
            <button class="btn btn-sm btn-outline-secondary" onclick="editStocks()"><i class="fas fa-edit me-1"></i>Düzenle</button>
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
                    $('<button class="btn btn-success w-100" onclick="submitFinalize()"><i class="fas fa-flag-checkered me-1"></i>Tamamla</button>')
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
