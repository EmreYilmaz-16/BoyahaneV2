<cfprocessingdirective pageEncoding="utf-8">

<!--- Tüm partiler: ref_no dolu olan orders (irsaliyeden oluşturulmuş sipariş = parti) --->
<cfquery name="getPartiler" datasource="boyahane">
    SELECT o.order_id,
           o.order_number,
           o.order_stage,
           o.order_date,
           o.deliverdate,
           o.ref_no,
           o.nettotal,
           o.grosstotal,
           o.taxtotal,
           o.record_date,
           COALESCE(c.nickname, c.fullname, '') AS company_name,
           COALESCE(s.ship_id, 0)              AS ship_id,
           COALESCE(s.hk_metre, 0)             AS hk_metre
    FROM orders o
    LEFT JOIN company c ON o.company_id = c.company_id
    LEFT JOIN ship s    ON s.ship_number = o.ref_no
    WHERE o.ref_no IS NOT NULL AND o.ref_no <> ''
    ORDER BY o.order_id DESC
</cfquery>

<!--- Tüm parti satırları (stok renk/varyant bilgisiyle) --->
<cfquery name="getPartiRows" datasource="boyahane">
    SELECT orw.order_id,
           orw.order_row_id,
           orw.product_name,
           orw.stock_id,
           orw.quantity,
           orw.unit,
           orw.price,
           orw.tax,
           orw.nettotal,
           COALESCE(st.is_main_stock, true)  AS is_main_stock,
           COALESCE(st.property, '')          AS stock_property,
           COALESCE(st.stock_code_2, '')      AS stock_code_2,
           COALESCE(st.product_id, 0)         AS product_id
    FROM order_row orw
    JOIN orders o   ON orw.order_id = o.order_id
    LEFT JOIN stocks st ON orw.stock_id = st.stock_id
    WHERE o.ref_no IS NOT NULL AND o.ref_no <> ''
    ORDER BY orw.order_id, orw.order_row_id
</cfquery>

<!--- Renk varyantları --->
<cfset rowProductIds = []>
<cfloop query="getPartiRows">
    <cfif isNumeric(product_id) AND val(product_id) gt 0 AND NOT arrayContains(rowProductIds, val(product_id))>
        <cfset arrayAppend(rowProductIds, val(product_id))>
    </cfif>
</cfloop>

<cfset colorVariantsArr = []>
<cfif arrayLen(rowProductIds) gt 0>
    <cfquery name="getColorVariants" datasource="boyahane">
        SELECT st.stock_id, st.stock_code,
               COALESCE(st.stock_code_2,'') AS stock_code_2,
               COALESCE(st.property,'')     AS property,
               st.product_id
        FROM stocks st
        WHERE st.product_id IN (<cfqueryparam value="#arrayToList(rowProductIds)#" cfsqltype="cf_sql_integer" list="true">)
          AND (st.is_main_stock IS NULL OR st.is_main_stock = false)
        ORDER BY st.product_id, st.stock_id
    </cfquery>
    <cfloop query="getColorVariants">
        <cfset arrayAppend(colorVariantsArr, {
            "stock_id":     val(stock_id),
            "stock_code":   stock_code   ?: "",
            "stock_code_2": stock_code_2 ?: "",
            "property":     property     ?: "",
            "product_id":   val(product_id)
        })>
    </cfloop>
</cfif>

<!--- Per-order ilk satır özeti (renk, metre, kg) --->
<cfset orderFirstRow = {}>
<cfloop query="getPartiRows">
    <cfset oid = val(order_id)>
    <cfif NOT structKeyExists(orderFirstRow, oid)>
        <!--- İlk satır bilgileri --->
        <cfset orderFirstRow[oid] = {
            "first_row_id":       val(order_row_id),
            "first_stock_id":     isNumeric(stock_id)   ? val(stock_id)   : 0,
            "first_product_id":   isNumeric(product_id) ? val(product_id) : 0,
            "first_product_name": product_name    ?: "",
            "first_is_main":      isBoolean(is_main_stock) ? is_main_stock : true,
            "first_property":     stock_property  ?: "",
            "first_code2":        stock_code_2    ?: "",
            "first_qty":          isNumeric(quantity) ? val(quantity) : 0,
            "first_unit":         unit ?: "",
            "parti_metre":        0,
            "parti_kg":           0
        }>
    </cfif>
    <!--- Metre ve KG toplaları --->
    <cfset uLower = lCase(trim(unit ?: ""))>
    <cfif uLower eq "m" OR uLower eq "mt" OR uLower eq "metre" OR uLower eq "mtr">
        <cfset orderFirstRow[oid]["parti_metre"] += isNumeric(quantity) ? val(quantity) : 0>
    <cfelseif uLower eq "kg">
        <cfset orderFirstRow[oid]["parti_kg"] += isNumeric(quantity) ? val(quantity) : 0>
    </cfif>
</cfloop>

<!--- JS dizileri --->
<cfset partilerArr = []>
<cfloop query="getPartiler">
    <cfset stageLabel = "">
    <cfswitch expression="#val(order_stage)#">
        <cfcase value="1"><cfset stageLabel = "Beklemede"></cfcase>
        <cfcase value="2"><cfset stageLabel = "Onaylandı"></cfcase>
        <cfcase value="3"><cfset stageLabel = "Üretimde"></cfcase>
        <cfcase value="4"><cfset stageLabel = "Hazır"></cfcase>
        <cfcase value="5"><cfset stageLabel = "Sevk Edildi"></cfcase>
        <cfcase value="6"><cfset stageLabel = "Tamamlandı"></cfcase>
        <cfdefaultcase><cfset stageLabel = "Bilinmiyor"></cfdefaultcase>
    </cfswitch>
    <cfset oid = val(order_id)>
    <cfset fr = structKeyExists(orderFirstRow, oid) ? orderFirstRow[oid] : {
        "first_row_id":0,"first_stock_id":0,"first_product_id":0,
        "first_product_name":"","first_is_main":true,"first_property":"",
        "first_code2":"","first_qty":0,"first_unit":"",
        "parti_metre":0,"parti_kg":0
    }>
    <cfset arrayAppend(partilerArr, {
        "order_id":           val(order_id),
        "order_number":       order_number ?: "",
        "order_stage":        val(order_stage),
        "stage_label":        stageLabel,
        "ref_no":             ref_no       ?: "",
        "ship_id":            val(ship_id),
        "hk_metre":           isNumeric(hk_metre) ? val(hk_metre) : 0,
        "company_name":       company_name ?: "",
        "order_date":         isDate(order_date)  ? dateFormat(order_date,  "dd/mm/yyyy") : "",
        "deliverdate":        isDate(deliverdate) ? dateFormat(deliverdate, "dd/mm/yyyy") : "",
        "nettotal":           isNumeric(nettotal)   ? val(nettotal)   : 0,
        "grosstotal":         isNumeric(grosstotal) ? val(grosstotal) : 0,
        "taxtotal":           isNumeric(taxtotal)   ? val(taxtotal)   : 0,
        "record_date":        isDate(record_date)  ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : "",
        "first_row_id":       fr.first_row_id,
        "first_stock_id":     fr.first_stock_id,
        "first_product_id":   fr.first_product_id,
        "first_product_name": fr.first_product_name,
        "first_is_main":      fr.first_is_main,
        "first_property":     fr.first_property,
        "first_code2":        fr.first_code2,
        "first_qty":          fr.first_qty,
        "first_unit":         fr.first_unit,
        "parti_metre":        fr.parti_metre,
        "parti_kg":           fr.parti_kg
    })>
</cfloop>

<cfset partiRowsArr = []>
<cfloop query="getPartiRows">
    <cfset arrayAppend(partiRowsArr, {
        "order_row_id":  val(order_row_id),
        "order_id":      val(order_id),
        "stock_id":      isNumeric(stock_id)   ? val(stock_id)   : 0,
        "product_id":    isNumeric(product_id) ? val(product_id) : 0,
        "product_name":  product_name    ?: "",
        "is_main_stock": isBoolean(is_main_stock) ? is_main_stock : true,
        "stock_property":stock_property  ?: "",
        "stock_code_2":  stock_code_2    ?: "",
        "quantity":      isNumeric(quantity) ? val(quantity) : 0,
        "unit":          unit             ?: "",
        "price":         isNumeric(price)    ? val(price)    : 0,
        "tax":           isNumeric(tax)      ? val(tax)      : 0,
        "nettotal":      isNumeric(nettotal) ? val(nettotal) : 0
    })>
</cfloop>

<!--- ─── HTML ─── --->
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-layer-group"></i></div>
        <div class="page-header-title">
            <h1>Tüm Partiler</h1>
            <p>İrsaliyelerden oluşturulan tüm sipariş partilerini görüntüleyin</p>
        </div>
    </div>
</div>

<div class="px-3 pb-5">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-layer-group"></i>Parti Listesi</div>
            <span class="record-count" id="partiTotalBadge"><cfoutput>#getPartiler.recordCount#</cfoutput> parti</span>
        </div>
        <div class="card-body p-2">
            <div id="mainPartiGrid"></div>
        </div>
    </div>
</div>

<!--- ─── Parti Kalemleri Modal ─── --->
<div class="modal fade" id="partiRowModal" tabindex="-1" aria-labelledby="partiRowModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-xl modal-dialog-centered modal-dialog-scrollable">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="partiRowModalLabel"><i class="fas fa-th-list me-2"></i>Parti Kalemleri</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-2">
                <div class="d-flex align-items-center gap-2 mb-2 px-1">
                    <span class="badge bg-primary" id="modalPartiKodu"></span>
                    <span class="text-muted small" id="modalIrsaliye"></span>
                </div>
                <div id="partiRowModalGrid"></div>
            </div>
            <div class="modal-footer py-2">
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">Kapat</button>
                <button type="button" class="btn btn-outline-primary btn-sm" id="modalEditBtn">
                    <i class="fas fa-edit me-1"></i>Siparişi Düzenle
                </button>
            </div>
        </div>
    </div>
</div>

<!--- ─── Renk Seçim Modal ─── --->
<div class="modal fade" id="colorPickerModal" tabindex="-1" aria-labelledby="colorPickerLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="colorPickerLabel"><i class="fas fa-palette me-2"></i>Renk Seçimi</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <p class="text-muted small mb-3" id="colorPickerProductName"></p>
                <div id="colorOptionsList" class="d-flex flex-wrap gap-2"></div>
                <div class="mt-3" id="noColorMsg" style="display:none;">
                    <div class="alert alert-info py-2 mb-0">Bu ürün için tanımlı renk varyantı bulunmuyor.</div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-primary btn-sm" id="colorPickerSaveBtn" disabled>
                    <i class="fas fa-check me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<style>
/* Renk badge */
.color-badge { display:inline-flex; align-items:center; gap:5px; padding:2px 8px; border-radius:12px; font-size:.78rem; font-weight:600; color:##fff; background:##6366f1; }
.color-select-btn { border:none; background:transparent; cursor:pointer; color:##6366f1; padding:2px 6px; border-radius:4px; font-size:.78rem; }
.color-select-btn:hover { background:##ede9fe; }
/* Renk popup z-index */
##colorPickerModal { z-index: 99999 !important; }
##partiRowModal    { z-index: 99990 !important; }
.modal-backdrop    { z-index: 99988 !important; }
/* Renk seçenekleri */
##colorPickerModal .color-option { cursor:pointer; border:2px solid ##e5e7eb; border-radius:8px; padding:8px 12px; transition:.15s; display:flex; align-items:center; gap:8px; }
##colorPickerModal .color-option:hover  { border-color:##6366f1; background:##f5f3ff; }
##colorPickerModal .color-option.active { border-color:##6366f1; background:##ede9fe; }
##colorPickerModal .color-dot { width:14px; height:14px; border-radius:50%; background:##6366f1; flex-shrink:0; }
</style>

<script>
var partilerData   = #serializeJSON(partilerArr)#;
var partiRowsData  = #serializeJSON(partiRowsArr)#;
var colorVariants  = #serializeJSON(colorVariantsArr)#;

/* Renk haritası: product_id -> [{stock_id, stock_code, stock_code_2, property}] */
var colorMap = {};
colorVariants.forEach(function(v) {
    var pid = v.PRODUCT_ID || v.product_id;
    if (!colorMap[pid]) colorMap[pid] = [];
    colorMap[pid].push({
        stock_id:     v.STOCK_ID     || v.stock_id,
        stock_code:   v.STOCK_CODE   || v.stock_code   || '',
        stock_code_2: v.STOCK_CODE_2 || v.stock_code_2 || '',
        property:     v.PROPERTY     || v.property     || ''
    });
});

var paletteBg = ['##6366f1','##2563ab','##15803d','##b45309','##be123c','##0e7490','##7c3aed','##c2410c','##166534','##1e40af'];
function getBg(i) { return paletteBg[i % paletteBg.length]; }

/* Renk popup durumu */
var colorPickerRowId    = null;
var colorPickerSelected = null;
var colorPickerPartiRow = null;  /* ana grid satırı referansı (repaint için) */
var rowModalInstance    = null;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {

        /* ── Ana Parti Grid ──────────────────────────────────────── */
        $('##mainPartiGrid').dxDataGrid({
            dataSource: partilerData,
            showBorders: true, showRowLines: true, showColumnLines: true,
            rowAlternationEnabled: true, columnAutoWidth: true,
            allowColumnResizing: true, columnResizingMode: 'widget',
            paging: { pageSize: 50 },
            filterRow: { visible: true },
            sorting: { mode: 'multiple' },
            export: { enabled: true, fileName: 'partiler' },
            onExporting: function(e) {
                var workbook = new ExcelJS.Workbook();
                var worksheet = workbook.addWorksheet('Partiler');
                DevExpress.excelExporter.exportDataGrid({
                    component: e.component,
                    worksheet: worksheet,
                    autoFilterEnabled: true
                }).then(function() {
                    workbook.xlsx.writeBuffer().then(function(buffer) {
                        saveAs(new Blob([buffer], { type: 'application/octet-stream' }), 'partiler.xlsx');
                    });
                });
                e.cancel = true;
            },
            selection: { mode: 'none' },
            columns: [
                { dataField:'order_id',     caption:'ID',         width:70, alignment:'center', dataType:'number' },
                { dataField:'order_number', caption:'Parti Kodu', width:160,
                    cellTemplate: function(c,o){
                        $('<a>').attr('href','##').addClass('fw-bold text-decoration-none')
                            .text(o.value||'-')
                            .on('click', function(e){ e.preventDefault(); e.stopPropagation(); openRowModal(o.data); })
                            .appendTo(c);
                    }
                },
                { dataField:'company_name', caption:'Müşteri',    minWidth:160 },
                { dataField:'ref_no',       caption:'İrsaliye No', width:150 },
                { dataField:'stage_label',  caption:'Aşama',      width:130,
                    cellTemplate: function(c,o){
                        var cls = {
                            'Beklemede':'badge bg-secondary','Onaylandı':'badge bg-primary',
                            'Üretimde':'badge bg-warning text-dark','Hazır':'badge bg-info text-dark',
                            'Sevk Edildi':'badge bg-success','Tamamlandı':'badge bg-dark'
                        }[o.value] || 'badge bg-secondary';
                        $('<span>').addClass(cls).text(o.value||'-').appendTo(c);
                    }
                },
                {
                    caption:'Renk', width:170, allowSorting:false, allowFiltering:false,
                    cellTemplate: function(c,o) {
                        var d       = o.data;
                        var isMain  = d.FIRST_IS_MAIN  !== undefined ? d.FIRST_IS_MAIN  : d.first_is_main;
                        var propVal = d.FIRST_PROPERTY || d.first_property  || '';
                        var pidKey  = d.FIRST_PRODUCT_ID || d.first_product_id;
                        var sidKey  = d.FIRST_STOCK_ID   || d.first_stock_id;
                        var wrap    = $('<div>').addClass('d-flex align-items-center gap-1');
                        if (isMain === false || isMain === 'false' || isMain === 0) {
                            if (propVal) {
                                var idx = (colorMap[pidKey]||[]).findIndex(function(v){ return v.stock_id == sidKey; });
                                var bg  = getBg(idx >= 0 ? idx : 0);
                                $('<span>').addClass('color-badge').css('background', bg)
                                    .html('<i class="fas fa-circle me-1" style="font-size:.6rem"></i>' + $('<span>').text(propVal).html())
                                    .appendTo(wrap);
                            }
                            $('<button>').addClass('btn btn-sm btn-outline-secondary py-0 px-1').attr('title','Rengi Değiştir')
                                .html('<i class="fas fa-sync-alt" style="font-size:.7rem"></i>')
                                .on('click', function(e2){ e2.stopPropagation(); openColorPickerFromParti(d); })
                                .appendTo(wrap);
                        } else {
                            if (pidKey && colorMap[pidKey] && colorMap[pidKey].length > 0) {
                                $('<button>').addClass('btn btn-sm btn-outline-secondary py-0')
                                    .html('<i class="fas fa-palette me-1"></i>Renk Seç')
                                    .on('click', function(e2){ e2.stopPropagation(); openColorPickerFromParti(d); })
                                    .appendTo(wrap);
                            } else {
                                $('<span>').addClass('text-muted small').text('—').appendTo(wrap);
                            }
                        }
                        wrap.appendTo(c);
                    }
                },
                { dataField:'parti_metre', caption:'Part. Metre', width:110, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'parti_kg',    caption:'Part. KG',    width:90,  alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'hk_metre',   caption:'İrs. Metre', width:110, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'order_date', caption:'Sipariş Tar.', width:115 },
                { dataField:'deliverdate',caption:'Teslim Tar.',  width:115 },
                { dataField:'grosstotal', caption:'Brüt',  width:100, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'nettotal',   caption:'Net',   width:100, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                {
                    caption:'İşlemler', width:160, alignment:'center', allowSorting:false, allowFiltering:false,
                    cellTemplate: function(c,o) {
                        var g = $('<div>').addClass('d-flex gap-1 justify-content-center');
                        $('<button>').addClass('btn btn-sm btn-outline-info').attr('title','Kalemleri Gör')
                            .html('<i class="fas fa-th-list"></i>')
                            .on('click', function(e2){ e2.stopPropagation(); openRowModal(o.data); }).appendTo(g);
                        $('<button>').addClass('btn btn-sm btn-outline-primary').attr('title','Siparişi Düzenle')
                            .html('<i class="fas fa-edit"></i>')
                            .on('click', function(e2){
                                e2.stopPropagation();
                                window.location.href = 'index.cfm?fuseaction=order.add_order&order_id=' + (o.data.ORDER_ID||o.data.order_id);
                            }).appendTo(g);
                        $('<button>').addClass('btn btn-sm btn-outline-success').attr('title','Üretime Gönder')
                            .html('<i class="fas fa-industry"></i>')
                            .on('click', function(e2){ e2.stopPropagation(); partiSendToProduction(o.data.ORDER_ID||o.data.order_id); }).appendTo(g);
                        g.appendTo(c);
                    }
                }
            ],
            summary: {
                totalItems: [
                    { column:'order_id',   summaryType:'count', displayFormat:'{0} parti' },
                    { column:'grosstotal', summaryType:'sum',   displayFormat:'Brüt: {0}', valueFormat:{type:'fixedPoint',precision:2} },
                    { column:'nettotal',   summaryType:'sum',   displayFormat:'Net: {0}',  valueFormat:{type:'fixedPoint',precision:2} }
                ]
            }
        });
    }

    /* ─── Renk Kaydet ─────────────────────────────────────────── */
    $('##colorPickerSaveBtn').on('click', function() {
        if (!colorPickerSelected || !colorPickerRowId) return;
        var $btn = $(this).prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i>Kaydediliyor...');
        $.post('/ship/form/update_order_row_stock.cfm', {
            order_row_id: colorPickerRowId,
            stock_id:     colorPickerSelected.stock_id
        }, function(res) {
            if (res && res.success) {
                /* partiRowsData güncelle */
                for (var i = 0; i < partiRowsData.length; i++) {
                    var r = partiRowsData[i];
                    if ((r.ORDER_ROW_ID||r.order_row_id) == colorPickerRowId) {
                        r.STOCK_ID       = r.stock_id       = res.stock_id;
                        r.PRODUCT_NAME   = r.product_name   = res.product_name;
                        r.IS_MAIN_STOCK  = r.is_main_stock  = false;
                        r.STOCK_PROPERTY = r.stock_property = res.property;
                        r.STOCK_CODE_2   = r.stock_code_2   = res.stock_code_2;
                        break;
                    }
                }
                /* Ana grid satırını güncelle (renk sütunu için) */
                if (colorPickerPartiRow) {
                    colorPickerPartiRow.FIRST_IS_MAIN    = colorPickerPartiRow.first_is_main    = false;
                    colorPickerPartiRow.FIRST_PROPERTY   = colorPickerPartiRow.first_property   = res.property   || '';
                    colorPickerPartiRow.FIRST_STOCK_ID   = colorPickerPartiRow.first_stock_id   = res.stock_id   || 0;
                    colorPickerPartiRow.FIRST_CODE2      = colorPickerPartiRow.first_code2      = res.stock_code_2 || '';
                    var _mg = DevExpress.ui.dxDataGrid.getInstance(document.getElementById('mainPartiGrid'));
                    if (_mg) _mg.repaint();
                }
                /* Açık modal grid'ini yenile (varsa) */
                var g = DevExpress.ui.dxDataGrid.getInstance(document.getElementById('partiRowModalGrid'));
                if (g) {
                    var ds  = g.option('dataSource');
                    var oid = ds && ds[0] ? (ds[0].ORDER_ID||ds[0].order_id) : null;
                    if (oid) g.option('dataSource', partiRowsData.filter(function(r){ return (r.ORDER_ID||r.order_id)==oid; }));
                }
                try { /* grid refreshes above */ } catch(e) { console.warn('grid refresh:', e); }
                var cpModal = bootstrap.Modal.getInstance(document.getElementById('colorPickerModal'));
                if (cpModal) cpModal.hide();
            } else {
                alert('Hata: ' + (res.message || 'Bilinmeyen hata'));
                $btn.prop('disabled', false).html('<i class="fas fa-check me-1"></i>Kaydet');
            }
        }, 'json').fail(function(){
            alert('Sunucu hatası oluştu.');
            $btn.prop('disabled', false).html('<i class="fas fa-check me-1"></i>Kaydet');
        });
    });
});

/* ─── Parti Kalemleri Popup ────────────────────────────────── */
function openRowModal(partiData) {
    var orderId     = partiData.ORDER_ID    || partiData.order_id;
    var orderNumber = partiData.ORDER_NUMBER|| partiData.order_number || ('-');
    var refNo       = partiData.REF_NO      || partiData.ref_no      || '';
    var rows        = partiRowsData.filter(function(r){ return (r.ORDER_ID||r.order_id)==orderId; });

    $('##modalPartiKodu').text(orderNumber);
    $('##modalIrsaliye').text(refNo ? 'İrsaliye: ' + refNo : '');
    $('##modalEditBtn').off('click').on('click', function(){
        window.location.href = 'index.cfm?fuseaction=order.add_order&order_id=' + orderId;
    });

    /* Grid oluştur veya güncelle */
    var $gridEl = $('##partiRowModalGrid');
    if ($gridEl.data('dxDataGrid')) {
        var _rg = DevExpress.ui.dxDataGrid.getInstance($gridEl[0]);
        if (_rg) _rg.option('dataSource', rows);
    } else {
        $gridEl.dxDataGrid({
            dataSource: rows,
            showBorders: true, showRowLines: true, showColumnLines: true,
            rowAlternationEnabled: true, columnAutoWidth: true,
            allowColumnResizing: true, columnResizingMode: 'widget',
            paging: { enabled: false },
            columns: [
                {
                    dataField:'product_name', caption:'Ürün / İşlem', minWidth:220,
                    cellTemplate: function(c,o) {
                        var d        = o.data;
                        var isMain   = d.IS_MAIN_STOCK !== undefined ? d.IS_MAIN_STOCK : d.is_main_stock;
                        var propVal  = d.STOCK_PROPERTY || d.stock_property || '';
                        var name     = o.value || '-';
                        var wrap     = $('<div>').addClass('d-flex align-items-center gap-2');
                        $('<span>').text(name).appendTo(wrap);

                        if (isMain === false || isMain === 'false' || isMain === 0) {
                            /* Renk varyantı — renkli badge */
                            if (propVal) {
                                var pidKey = d.PRODUCT_ID || d.product_id;
                                var idx    = (colorMap[pidKey]||[]).findIndex(function(v){ return v.stock_id==(d.STOCK_ID||d.stock_id); });
                                var bg     = getBg(idx >= 0 ? idx : 0);
                                $('<span>').addClass('color-badge').css('background', bg)
                                    .html('<i class="fas fa-circle me-1" style="font-size:.6rem"></i>' + $('<span>').text(propVal).html())
                                    .appendTo(wrap);
                            }
                        } else {
                            /* Ana stok — renk seç butonu */
                            var pidKey2 = d.PRODUCT_ID || d.product_id;
                            if (pidKey2 && colorMap[pidKey2] && colorMap[pidKey2].length > 0) {
                                $('<button>').addClass('color-select-btn').attr('title','Renk Ata')
                                    .html('<i class="fas fa-palette"></i> Renk Seç')
                                    .on('click', function(e2){
                                        e2.stopPropagation();
                                        openColorPicker(d, pidKey2);
                                    }).appendTo(wrap);
                            }
                        }
                        wrap.appendTo(c);
                    }
                },
                { dataField:'quantity', caption:'Miktar', width:100, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:4} },
                { dataField:'unit',     caption:'Birim',  width:65 },
                { dataField:'price',    caption:'Fiyat',  width:100, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:4} },
                { dataField:'tax',      caption:'KDV %',  width:75,  alignment:'right', dataType:'number' },
                { dataField:'nettotal', caption:'Net',    width:110, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} }
            ],
            summary: {
                totalItems: [
                    { column:'nettotal', summaryType:'sum', displayFormat:'Toplam: {0}', valueFormat:{type:'fixedPoint',precision:2} }
                ]
            }
        });
    }

    /* Modal'ı body'e taşı, sonra göster */
    var modalEl = document.getElementById('partiRowModal');
    if (modalEl.parentNode !== document.body) document.body.appendChild(modalEl);
    rowModalInstance = bootstrap.Modal.getOrCreateInstance(modalEl);
    rowModalInstance.show();
}

/* ─── Renk Seç (ana grid'den doğrudan) ───────────────────── */
function openColorPickerFromParti(partiRow) {
    colorPickerPartiRow = partiRow;
    var rowData = {
        ORDER_ROW_ID: partiRow.FIRST_ROW_ID      || partiRow.first_row_id,
        PRODUCT_NAME: partiRow.FIRST_PRODUCT_NAME|| partiRow.first_product_name || '',
        PRODUCT_ID:   partiRow.FIRST_PRODUCT_ID  || partiRow.first_product_id,
        STOCK_ID:     partiRow.FIRST_STOCK_ID    || partiRow.first_stock_id
    };
    openColorPicker(rowData, rowData.PRODUCT_ID);
}

/* ─── Üretime Gönder ──────────────────────────────────────── */
function partiSendToProduction(orderId) {
    if (!confirm('Bu partinin tüm satırları için üretim emri oluşturulacak. Devam etmek istiyor musunuz?')) return;
    $.ajax({
        url: '/production/form/send_order_to_production.cfm',
        type: 'POST',
        data: { order_id: orderId },
        dataType: 'json',
        success: function(res) {
            if (res.success) {
                DevExpress.ui.notify({ message: res.message, width: 400 }, 'success', 4000);
            } else {
                DevExpress.ui.notify({ message: res.message || 'Hata oluştu.', width: 400 }, 'error', 4000);
            }
        },
        error: function() {
            DevExpress.ui.notify({ message: 'Sunucu hatası oluştu.', width: 400 }, 'error', 4000);
        }
    });
}

/* ─── Renk Seçim Popup ─────────────────────────────────────── */
function openColorPicker(rowData, productId) {
    var rowId    = rowData.ORDER_ROW_ID || rowData.order_row_id;
    var name     = rowData.PRODUCT_NAME || rowData.product_name || '';
    var variants = colorMap[productId]  || [];

    colorPickerRowId    = rowId;
    colorPickerSelected = null;

    $('##colorPickerProductName').text(name);
    $('##colorPickerSaveBtn').prop('disabled', true).html('<i class="fas fa-check me-1"></i>Kaydet');

    var $list = $('##colorOptionsList').empty();
    $('##noColorMsg').hide();

    if (variants.length === 0) {
        $('##noColorMsg').show();
    } else {
        variants.forEach(function(v, idx) {
            var label = v.property || v.stock_code_2 || v.stock_code;
            var bg    = getBg(idx);
            var $opt  = $('<div>').addClass('color-option').attr('data-stock-id', v.stock_id)
                .html('<span class="color-dot" style="background:' + bg + '"></span>' +
                      '<span>' + $('<span>').text(label).html() +
                      (v.stock_code_2 ? ' <small class="text-muted">(' + $('<span>').text(v.stock_code_2).html() + ')</small>' : '') +
                      '</span>');
            $opt.on('click', function() {
                $list.find('.color-option').removeClass('active');
                $(this).addClass('active');
                colorPickerSelected = v;
                $('##colorPickerSaveBtn').prop('disabled', false);
            });
            $list.append($opt);
        });
    }

    /* Renk picker'ı body'e taşı, üstte aç */
    var cpEl = document.getElementById('colorPickerModal');
    if (cpEl.parentNode !== document.body) document.body.appendChild(cpEl);
    bootstrap.Modal.getOrCreateInstance(cpEl).show();
}
</script>
</cfoutput>
