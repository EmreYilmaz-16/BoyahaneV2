<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.p_order_id" default="0">
<cfset pOrderId = isNumeric(url.p_order_id) AND val(url.p_order_id) gt 0 ? val(url.p_order_id) : 0>

<cfif pOrderId eq 0>
    <cflocation url="index.cfm?fuseaction=production.list_production_orders" addtoken="false">
</cfif>

<!--- Üretim emri başlık --->
<cfquery name="getOrder" datasource="boyahane">
    SELECT po.p_order_id, po.p_order_no, po.status, po.quantity, po.lot_no,
           po.start_date, po.finish_date,
           COALESCE(ci.color_code,'') AS color_code,
           COALESCE(ci.color_name,'') AS color_name,
           COALESCE(ws.station_name,'') AS station_name,
           COALESCE(ws.station_id, 0)   AS station_id,
           po.exit_dep_id, po.exit_loc_id,
           po.production_dep_id, po.production_loc_id,
           COALESCE(c.nickname, c.fullname,'') AS company_name,
           po.stock_id
    FROM production_orders po
    LEFT JOIN stocks       s  ON po.stock_id   = s.stock_id
    LEFT JOIN color_info   ci ON po.stock_id   = ci.stock_id
    LEFT JOIN company      c  ON ci.company_id = c.company_id
    LEFT JOIN workstations ws ON po.station_id = ws.station_id
    WHERE po.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getOrder.recordCount OR val(getOrder.status) eq 5 OR val(getOrder.status) eq 9>
    <cflocation url="index.cfm?fuseaction=production.list_production_orders" addtoken="false">
</cfif>

<!--- Mevcut sonuçlar --->
<cfquery name="getResults" datasource="boyahane">
    SELECT r.pr_order_id,
           r.result_no,
           r.lot_no,
           r.start_date,
           r.finish_date,
           COALESCE(ws.station_name,'') AS station_name,
           COALESCE(r.prod_ord_result_stage, 0) AS stage,
           r.record_date
    FROM production_order_results r
    LEFT JOIN workstations ws ON r.station_id = ws.station_id
    WHERE r.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    ORDER BY r.pr_order_id DESC
</cfquery>

<!--- Sonuç satırları --->
<cfquery name="getResultRows" datasource="boyahane">
    SELECT rr.pr_order_row_id, rr.pr_order_id,
           rr.type, rr.tree_type,
           COALESCE(p.product_name,'')  AS product_name,
           COALESCE(s.stock_code,'')    AS stock_code,
           COALESCE(rr.amount, 0)       AS amount,
           COALESCE(rr.unit_name,'')    AS unit_name,
           COALESCE(rr.lot_no,'')       AS lot_no,
           COALESCE(rr.purchase_net_system, 0) AS unit_cost,
           COALESCE(rr.fire_amount, 0)  AS fire_amount
    FROM production_order_results_row rr
    LEFT JOIN stocks  s ON rr.stock_id  = s.stock_id
    LEFT JOIN product p ON rr.product_id= p.product_id
    WHERE rr.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    ORDER BY rr.pr_order_id DESC, rr.line_number
</cfquery>

<cfset resArr = []>
<cfloop query="getResults">
    <cfset arrayAppend(resArr, {
        "pr_order_id"  : val(pr_order_id),
        "result_no"    : result_no    ?: "",
        "lot_no"       : lot_no       ?: "",
        "station_name" : station_name ?: "",
        "stage"        : val(stage),
        "start_date"   : isDate(start_date)  ? dateFormat(start_date,"dd/mm/yyyy")  : "",
        "finish_date"  : isDate(finish_date) ? dateFormat(finish_date,"dd/mm/yyyy") : "",
        "record_date"  : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") & " " & timeFormat(record_date,"HH:mm") : ""
    })>
</cfloop>

<cfset rowArr = []>
<cfloop query="getResultRows">
    <cfset arrayAppend(rowArr, {
        "pr_order_row_id": val(pr_order_row_id),
        "pr_order_id"    : val(pr_order_id),
        "type"           : val(type),
        "tree_type"      : tree_type     ?: "S",
        "product_name"   : product_name  ?: "",
        "stock_code"     : stock_code    ?: "",
        "amount"         : isNumeric(amount)    ? val(amount)    : 0,
        "fire_amount"    : isNumeric(fire_amount) ? val(fire_amount) : 0,
        "unit_name"      : unit_name     ?: "",
        "lot_no"         : lot_no        ?: "",
        "unit_cost"      : isNumeric(unit_cost) ? val(unit_cost) : 0
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-clipboard-check"></i></div>
        <div class="page-header-title">
            <h1>Üretim Sonuçları</h1>
            <p><b>#htmlEditFormat(getOrder.p_order_no)#</b> — #htmlEditFormat(getOrder.color_code)# #htmlEditFormat(getOrder.color_name)# | Planlanan: #isNumeric(getOrder.quantity) ? numberFormat(getOrder.quantity,'_.___,__') : ''# kg</p>
        </div>
    </div>
    <div class="d-flex gap-2">
        <button class="btn-add" onclick="openResultModal()">
            <i class="fas fa-plus"></i>Yeni Sonuç
        </button>
        <a class="btn-back" href="index.cfm?fuseaction=production.view_production_order&p_order_id=#pOrderId#">
            <i class="fas fa-arrow-left"></i>Emre Dön
        </a>
    </div>
</div>

<div class="px-3 pb-5">

<!--- SONUÇ BAŞLIKLARI --->
<div class="grid-card mb-3">
    <div class="grid-card-header">
        <div class="grid-card-header-title"><i class="fas fa-list-alt"></i>Sonuç Kayıtları</div>
        <span class="record-count" id="resCount">Yükleniyor...</span>
    </div>
    <div class="card-body p-2">
        <div id="resultGrid"></div>
    </div>
</div>

<!--- SONUÇ SATIRLARI --->
<div class="grid-card">
    <div class="grid-card-header">
        <div class="grid-card-header-title"><i class="fas fa-boxes"></i>Sonuç Satırları</div>
        <span class="record-count" id="rowCount">Yükleniyor...</span>
    </div>
    <div class="card-body p-2">
        <div id="rowGrid"></div>
    </div>
</div>
</div>

<!--- SONUÇ EKLEME MODAL --->
<div id="resultModal" class="modal fade" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Yeni Üretim Sonucu</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label">Sonuç No</label>
                        <div id="fld_result_no_dx"></div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Lot No</label>
                        <div id="fld_result_lot_no_dx"></div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Aşama</label>
                        <div id="fld_result_stage_dx"></div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Başlangıç</label>
                        <div id="fld_result_start_dx"></div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Bitiş</label>
                        <div id="fld_result_finish_dx"></div>
                    </div>

                    <div class="col-12 border-top pt-3">
                        <h6 class="mb-2"><i class="fas fa-cubes me-1"></i>Sonuç Satırı Ekle</h6>
                        <div class="row g-2 align-items-end">
                            <div class="col-md-4">
                                <label class="form-label form-label-sm">Ürün</label>
                                <div id="fld_row_product_dx"></div>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label form-label-sm">Miktar</label>
                                <div id="fld_row_amount_dx"></div>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label form-label-sm">Fire</label>
                                <div id="fld_row_fire_dx"></div>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label form-label-sm">Lot No</label>
                                <div id="fld_row_lot_dx"></div>
                            </div>
                            <div class="col-md-2">
                                <button class="btn btn-sm btn-outline-primary w-100" onclick="addRow()"><i class="fas fa-plus"></i> Ekle</button>
                            </div>
                        </div>
                        <div class="mt-2" id="rowPreviewGrid"></div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Vazgeç</button>
                <button type="button" class="btn btn-success" id="btnSaveResult" onclick="saveResult()">
                    <i class="fas fa-save me-1"></i>Sonucu Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<script>
var resultData   = #serializeJSON(resArr)#;
var rowData      = #serializeJSON(rowArr)#;
var pOrderId     = #val(pOrderId)#;
var pOrderLot    = "#htmlEditFormat(getOrder.lot_no)#";
var pendingRows  = [];

$(function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    buildResultGrid();
    buildRowGrid();
    initModal();
});

function buildResultGrid() {
    $('##resultGrid').dxDataGrid({
        dataSource: resultData,
        keyExpr: 'pr_order_id',
        showBorders: true,
        rowAlternationEnabled: true,
        paging: { enabled: false },
        onContentReady: function(e){ document.getElementById('resCount').textContent = e.component.totalCount() + ' kayıt'; },
        columns: [
            { dataField:'pr_order_id',  caption:'ID',      width:65, alignment:'center', dataType:'number', sortOrder:'desc' },
            { dataField:'result_no',    caption:'Sonuç No', width:130 },
            { dataField:'lot_no',       caption:'Lot No',   width:120 },
            { dataField:'station_name', caption:'Makina',   width:140 },
            { dataField:'start_date',   caption:'Başlangıç',width:110, alignment:'center' },
            { dataField:'finish_date',  caption:'Bitiş',    width:110, alignment:'center' },
            {
                dataField:'stage', caption:'Aşama', width:100, alignment:'center',
                cellTemplate: function(c,o) {
                    var labels = {0:'Taslak',1:'Onaylandı',9:'İptal'};
                    var colors = {0:'secondary',1:'success',9:'danger'};
                    var s = o.value||0;
                    $('<span class="badge bg-' + (colors[s]||'secondary') + '">' + (labels[s]||s) + '</span>').appendTo(c);
                }
            },
            { dataField:'record_date',  caption:'Kayıt',   width:130, alignment:'center' }
        ]
    });
}

function buildRowGrid() {
    $('##rowGrid').dxDataGrid({
        dataSource: rowData,
        keyExpr: 'pr_order_row_id',
        showBorders: true,
        rowAlternationEnabled: true,
        paging: { enabled: false },
        onContentReady: function(e){ document.getElementById('rowCount').textContent = e.component.totalCount() + ' kayıt'; },
        columns: [
            { dataField:'pr_order_id',   caption:'Sonuç ID', width:80, alignment:'center' },
            { dataField:'product_name',  caption:'Ürün',     minWidth:160 },
            { dataField:'stock_code',    caption:'Stok Kodu',width:120 },
            { dataField:'amount',        caption:'Miktar',   width:90,  alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:3} },
            { dataField:'fire_amount',   caption:'Fire',     width:80,  alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:3} },
            { dataField:'unit_name',     caption:'Birim',    width:70 },
            { dataField:'lot_no',        caption:'Lot No',   width:120 },
            { dataField:'unit_cost',     caption:'Maliyet',  width:100, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:4} }
        ]
    });
}

function initModal() {
    $('##fld_result_no_dx').dxTextBox({ placeholder: 'Otomatik oluşturulur...' });
    $('##fld_result_lot_no_dx').dxTextBox({ value: pOrderLot, placeholder: 'Lot no' });
    $('##fld_result_stage_dx').dxSelectBox({
        dataSource: [{id:0,text:'Taslak'},{id:1,text:'Onaylandı'}],
        valueExpr:'id', displayExpr:'text', value:1
    });
    $('##fld_result_start_dx').dxDateBox({ type:'datetime', displayFormat:'dd/MM/yyyy HH:mm', value: new Date() });
    $('##fld_result_finish_dx').dxDateBox({ type:'datetime', displayFormat:'dd/MM/yyyy HH:mm', value: new Date() });
    $('##fld_row_product_dx').dxTextBox({ placeholder: 'Ürün adı...' });
    $('##fld_row_amount_dx').dxNumberBox({ min:0, value:0 });
    $('##fld_row_fire_dx').dxNumberBox({ min:0, value:0 });
    $('##fld_row_lot_dx').dxTextBox({ placeholder: 'Lot...' });
    buildRowPreview();
}

function buildRowPreview() {
    $('##rowPreviewGrid').dxDataGrid({
        dataSource: pendingRows,
        keyExpr: '_idx',
        showBorders: true,
        paging: { enabled:false },
        columns: [
            { dataField:'product_name', caption:'Ürün',   minWidth:140 },
            { dataField:'amount',       caption:'Miktar',  width:80, alignment:'right' },
            { dataField:'fire_amount',  caption:'Fire',    width:70, alignment:'right' },
            { dataField:'lot_no',       caption:'Lot No',  width:100 },
            {
                caption:'', width:50, allowFiltering:false, allowSorting:false,
                cellTemplate: function(c,o) {
                    $('<button class="btn btn-xs btn-outline-danger"><i class="fas fa-times"></i></button>')
                        .on('click', function(){
                            pendingRows = pendingRows.filter(function(r){ return r._idx !== o.data._idx; });
                            $('##rowPreviewGrid').dxDataGrid('instance').option('dataSource', pendingRows);
                        }).appendTo(c);
                }
            }
        ]
    });
}

function addRow() {
    var name   = ($('##fld_row_product_dx').dxTextBox('instance').option('value') || '').trim();
    var amount = $('##fld_row_amount_dx').dxNumberBox('instance').option('value') || 0;
    var fire   = $('##fld_row_fire_dx').dxNumberBox('instance').option('value') || 0;
    var lot    = ($('##fld_row_lot_dx').dxTextBox('instance').option('value') || '').trim();

    if (!name) { DevExpress.ui.notify('Ürün adı giriniz.', 'warning', 2000); return; }
    if (amount <= 0) { DevExpress.ui.notify('Miktar sıfırdan büyük olmalıdır.', 'warning', 2000); return; }

    var idx = pendingRows.length ? Math.max.apply(null, pendingRows.map(function(r){return r._idx;})) + 1 : 1;
    pendingRows.push({ _idx: idx, product_name: name, amount: amount, fire_amount: fire, lot_no: lot });
    $('##rowPreviewGrid').dxDataGrid('instance').option('dataSource', pendingRows);

    $('##fld_row_product_dx').dxTextBox('instance').option('value','');
    $('##fld_row_amount_dx').dxNumberBox('instance').option('value', 0);
    $('##fld_row_fire_dx').dxNumberBox('instance').option('value', 0);
}

function openResultModal() {
    pendingRows = [];
    if ($('##rowPreviewGrid').dxDataGrid('instance')) {
        $('##rowPreviewGrid').dxDataGrid('instance').option('dataSource', pendingRows);
    }
    $('##fld_result_no_dx').dxTextBox('instance').option('value','');
    $('##fld_result_lot_no_dx').dxTextBox('instance').option('value', pOrderLot);
    $('##fld_result_stage_dx').dxSelectBox('instance').option('value', 1);
    $('##fld_result_start_dx').dxDateBox('instance').option('value', new Date());
    $('##fld_result_finish_dx').dxDateBox('instance').option('value', new Date());
    new bootstrap.Modal(document.getElementById('resultModal')).show();
}

function saveResult() {
    var payload = {
        p_order_id         : pOrderId,
        result_no          : ($('##fld_result_no_dx').dxTextBox('instance').option('value') || '').trim(),
        lot_no             : ($('##fld_result_lot_no_dx').dxTextBox('instance').option('value') || '').trim(),
        prod_ord_result_stage: $('##fld_result_stage_dx').dxSelectBox('instance').option('value'),
        start_date         : formatDateTime($('##fld_result_start_dx').dxDateBox('instance').option('value')),
        finish_date        : formatDateTime($('##fld_result_finish_dx').dxDateBox('instance').option('value')),
        rows               : JSON.stringify(pendingRows)
    };

    $('##btnSaveResult').prop('disabled', true);
    $.post('/production/form/save_production_result.cfm', payload, function(res) {
        if (res && res.success) {
            bootstrap.Modal.getInstance(document.getElementById('resultModal')).hide();
            DevExpress.ui.notify('Sonuç kaydedildi.', 'success', 2000);
            setTimeout(function(){ location.reload(); }, 1200);
        } else {
            DevExpress.ui.notify((res && res.message) || 'Kayıt başarısız.', 'error', 3000);
        }
    }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); })
              .always(function(){ $('##btnSaveResult').prop('disabled', false); });
}

function formatDateTime(d) {
    if (!d) return '';
    var dt = new Date(d);
    return dt.getFullYear() + '-' +
           String(dt.getMonth()+1).padStart(2,'0') + '-' +
           String(dt.getDate()).padStart(2,'0') + 'T' +
           String(dt.getHours()).padStart(2,'0') + ':' +
           String(dt.getMinutes()).padStart(2,'0');
}
</script>
</cfoutput>
