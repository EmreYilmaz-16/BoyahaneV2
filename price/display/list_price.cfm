<cfprocessingdirective pageEncoding="utf-8">

<cfif NOT (isDefined("url.price_catid") AND isNumeric(url.price_catid) AND url.price_catid gt 0)>
    <cflocation url="index.cfm?fuseaction=price.list_price_cat" addtoken="false">
</cfif>
<cfset currentCatId = val(url.price_catid)>

<!--- Fiyat listesi bilgileri --->
<cfquery name="getPriceCat" datasource="boyahane">
    SELECT pc.*, sm.money_name, sm.money_symbol
    FROM price_cat pc
    LEFT JOIN setup_money sm ON pc.money_id = sm.money_id
    WHERE pc.price_catid = <cfqueryparam value="#currentCatId#" cfsqltype="cf_sql_integer">
</cfquery>
<cfif NOT getPriceCat.recordCount>
    <cflocation url="index.cfm?fuseaction=price.list_price_cat" addtoken="false">
</cfif>

<!--- Bu listedeki fiyatlar --->
<cfquery name="getPrices" datasource="boyahane">
    SELECT
        pr.price_id,
        pr.price_catid,
        pr.product_id,
        pr.stock_id,
        pr.price,
        pr.price_kdv,
        pr.is_kdv,
        p.tax,
        pr.price_discount,
        pr.unit,
        pr.money,
        pr.startdate,
        pr.finishdate,
        pr.record_date,
        p.product_name,
        p.product_code,
        p.barcod AS product_barcod,
        s.stock_code,
        s.barcod AS stock_barcod,
        s.property
    FROM price pr
    LEFT JOIN product p ON pr.product_id = p.product_id
    LEFT JOIN stocks  s ON pr.stock_id   = s.stock_id
    WHERE pr.price_catid = <cfqueryparam value="#currentCatId#" cfsqltype="cf_sql_integer">
    ORDER BY p.product_name, s.stock_code
</cfquery>

<!--- Stoklar (yeni fiyat eklemek için) --->
<cfquery name="getStocks" datasource="boyahane">
    SELECT s.stock_id, s.stock_code, s.barcod, s.property, s.product_unit_id,
           p.product_id, p.product_name, p.product_code, p.tax AS product_tax
    FROM stocks s
    LEFT JOIN product p ON s.product_id = p.product_id
    WHERE s.stock_status = true
    ORDER BY p.product_name, s.stock_code
</cfquery>

<cfset stocksArray = []>
<cfloop query="getStocks">
    <cfset arrayAppend(stocksArray, {
        "stock_id":     stock_id,
        "stock_code":   stock_code ?: "",
        "barcod":       barcod ?: "",
        "property":     property ?: "",
        "product_id":   product_id ?: 0,
        "product_unit_id": product_unit_id ?: 0,
        "product_name": product_name ?: "",
        "product_code": product_code ?: "",
        "product_tax":  isNumeric(product_tax) ? product_tax : 18,
        "label":        (product_name ?: "?") & " — " & (stock_code ?: "")
    })>
</cfloop>

<!--- Fiyatlar JSON --->
<cfset pricesArray = []>
<cfloop query="getPrices">
    <cfset displayName = (product_name ?: "") & (len(stock_code) ? " [" & stock_code & "]" : "")>
    <cfset arrayAppend(pricesArray, {
        "price_id":        price_id,
        "product_id":      product_id ?: 0,
        "stock_id":        stock_id ?: 0,
        "product_name":    displayName,
        "product_code":    product_code ?: "",
        "stock_code":      stock_code ?: "",
        "barcod":          len(stock_barcod) ? stock_barcod : (product_barcod ?: ""),
        "property":        property ?: "",
        "price":           isNumeric(price) ? price : 0,
        "price_kdv":       isNumeric(price_kdv) ? price_kdv : 0,
        "is_kdv":          is_kdv,
        "tax":             isNumeric(tax) ? tax : 0,
        "price_discount":  isNumeric(price_discount) ? price_discount : 0,
        "money":           money ?: "",
        "startdate":       isDate(startdate)  ? dateFormat(startdate,  "yyyy-mm-dd") : "",
        "finishdate":      isDate(finishdate) ? dateFormat(finishdate, "yyyy-mm-dd") : "",
        "record_date":     isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") : ""
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-list-ul"></i></div>
        <div class="page-header-title">
            <h1>#xmlFormat(getPriceCat.price_cat)#
                <small class="text-muted fs-6">#xmlFormat(getPriceCat.money_name ?: "TRY")# (#xmlFormat(getPriceCat.money_symbol ?: "₺")#)</small>
            </h1>
            <p>Bu fiyat listesindeki ürünleri görüntüleyin, ekleyin veya fiyatlarını düzenleyin</p>
        </div>
    </div>
    <div class="d-flex gap-2">
        <a href="index.cfm?fuseaction=price.add_price_cat&price_catid=#currentCatId#" class="btn btn-outline-secondary btn-sm">
            <i class="fas fa-cog me-1"></i>Liste Ayarları
        </a>
        <a href="index.cfm?fuseaction=price.list_price_cat" class="btn-back">
            <i class="fas fa-arrow-left"></i>Fiyat Listeleri
        </a>
    </div>
</div>

<div class="px-3 pb-5">

    <!--- ══ Özet Kartlar ══ --->
    <div class="row g-3 mb-3">
        <div class="col-sm-6 col-xl-3">
            <div class="summary-card">
                <div class="summary-icon bg-primary"><i class="fas fa-box"></i></div>
                <div class="summary-info">
                    <div class="summary-value">#getPrices.recordCount#</div>
                    <div class="summary-label">Toplam Ürün</div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-3">
            <div class="summary-card">
                <div class="summary-icon bg-success"><i class="fas fa-coins"></i></div>
                <div class="summary-info">
                    <cfset minP = 0><cfset maxP = 0>
                    <cfif getPrices.recordCount>
                        <cfset minP = val(getPrices.price[1])>
                        <cfset maxP = val(getPrices.price[1])>
                        <cfloop query="getPrices">
                            <cfif val(price) lt minP><cfset minP = val(price)></cfif>
                            <cfif val(price) gt maxP><cfset maxP = val(price)></cfif>
                        </cfloop>
                    </cfif>
                    <div class="summary-value">#numberFormat(minP,"_.99")#</div>
                    <div class="summary-label">Min Fiyat</div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-3">
            <div class="summary-card">
                <div class="summary-icon bg-warning"><i class="fas fa-chart-bar"></i></div>
                <div class="summary-info">
                    <div class="summary-value">#numberFormat(maxP,"_.99")#</div>
                    <div class="summary-label">Maks Fiyat</div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-3">
            <div class="summary-card">
                <div class="summary-icon bg-info"><i class="fas fa-percent"></i></div>
                <div class="summary-info">
                    <div class="summary-value">#numberFormat(getPriceCat.discount ?: 0, "_.99")#%</div>
                    <div class="summary-label">Liste İndirimi</div>
                </div>
            </div>
        </div>
    </div>

    <div class="row g-3">

        <!--- ══ SOL: Ürün Ekle + Toplu İşlem ══ --->
        <div class="col-lg-4">

            <!--- Ürün Ekle --->
            <div class="grid-card mb-3">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-plus-circle"></i>Ürün Ekle</div>
                </div>
                <div class="card-body p-3">
                    <div class="mb-2">
                        <label class="form-label fw-semibold small">Stok / Ürün Ara</label>
                        <input type="text" class="form-control form-control-sm" id="stockSearch"
                               placeholder="Ürün adı, kodu veya barkod..." autocomplete="off">
                        <div id="stockSearchDropdown" class="search-dropdown d-none"></div>
                        <input type="hidden" id="addStockId" value="0">
                        <input type="hidden" id="addProductId" value="0">
                        <input type="hidden" id="addProductTax" value="18">
                        <div id="addStockInfo" class="mt-1 d-none">
                            <small class="text-info"><i class="fas fa-info-circle me-1"></i><span id="addStockLabel"></span></small>
                        </div>
                    </div>
                    <div class="row g-2 mb-2">
                        <div class="col-6">
                            <label class="form-label fw-semibold small">Fiyat (KDV Hariç)</label>
                            <input type="number" class="form-control form-control-sm" id="addPrice" step="0.01" min="0" placeholder="0,00">
                        </div>
                        <div class="col-6">
                            <label class="form-label fw-semibold small">KDV %</label>
                            <input type="number" class="form-control form-control-sm" id="addTax" step="1" min="0" max="100" value="18">
                        </div>
                    </div>
                    <div class="row g-2 mb-3">
                        <div class="col-6">
                            <label class="form-label fw-semibold small">İndirim %</label>
                            <input type="number" class="form-control form-control-sm" id="addDiscount" step="0.01" min="0" max="100" placeholder="0">
                        </div>
                        <div class="col-6">
                            <label class="form-label fw-semibold small">KDV'li Fiyat</label>
                            <input type="text" class="form-control form-control-sm bg-light" id="addPriceKdvPreview" readonly placeholder="0,00">
                        </div>
                    </div>
                    <button type="button" class="btn btn-success w-100" onclick="addPriceRow()">
                        <i class="fas fa-plus me-2"></i>Listeye Ekle
                    </button>
                </div>
            </div>

            <!--- Toplu Fiyat Güncelleme --->
            <div class="grid-card mb-3">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-sliders-h"></i>Toplu Fiyat Güncelleme</div>
                </div>
                <div class="card-body p-3">
                    <div class="mb-3">
                        <label class="form-label fw-semibold small">Değişim Türü</label>
                        <div class="btn-group w-100" role="group">
                            <input type="radio" class="btn-check" name="bulkType" id="bulkIncrease" value="increase" checked>
                            <label class="btn btn-outline-success btn-sm" for="bulkIncrease">
                                <i class="fas fa-arrow-up me-1"></i>Artış
                            </label>
                            <input type="radio" class="btn-check" name="bulkType" id="bulkDecrease" value="decrease">
                            <label class="btn btn-outline-danger btn-sm" for="bulkDecrease">
                                <i class="fas fa-arrow-down me-1"></i>İndirim
                            </label>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold small">Oran (%)</label>
                        <div class="input-group input-group-sm">
                            <input type="number" class="form-control" id="bulkRate" step="0.01" min="0" max="999" placeholder="10">
                            <span class="input-group-text">%</span>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold small">Yuvarlama</label>
                        <select class="form-select form-select-sm" id="bulkRound">
                            <option value="0">Yok</option>
                            <option value="1">1 kuruş</option>
                            <option value="5">5 kuruş</option>
                            <option value="10">10 kuruş</option>
                            <option value="50">50 kuruş</option>
                            <option value="100" selected>1 TL</option>
                        </select>
                    </div>
                    <button type="button" class="btn btn-primary w-100" onclick="applyBulkChange()">
                        <i class="fas fa-sync-alt me-2"></i>Tüm Listeye Uygula
                    </button>
                    <div id="bulkResult" class="mt-2 d-none"></div>
                </div>
            </div>

        </div>

        <!--- ══ SAĞ: Fiyat Tablosu ══ --->
        <div class="col-lg-8">
            <div class="grid-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title">
                        <i class="fas fa-list-ul"></i>Fiyat Kalemleri
                    </div>
                    <span class="record-count" id="recordCount">Yükleniyor...</span>
                </div>
                <div class="card-body p-2">
                    <div id="priceGrid"></div>
                </div>
            </div>
        </div>

    </div>
</div>

<style>
.search-dropdown {
    position: fixed; z-index: 9999;
    background: ##fff; border: 1px solid ##dee2e6;
    border-radius: 8px; max-height: 220px; overflow-y: auto;
    box-shadow: 0 4px 16px rgba(0,0,0,.15);
}
.search-dropdown .search-item {
    padding: 8px 14px; cursor: pointer; border-bottom: 1px solid ##f0f0f0; font-size:.875rem;
}
.search-dropdown .search-item:hover { background: ##f0f6ff; }
.search-dropdown .search-item .item-code { color: ##6c757d; font-size: .8rem; }
</style>

<script>
var allStocks  = #serializeJSON(stocksArray)#;
var pricesData = #serializeJSON(pricesArray)#;
var catId      = #currentCatId#;
var priceGrid  = null;

/* ─── Stok arama ─── */
function positionDropdown(inputEl, dropdownEl) {
    var r = inputEl.getBoundingClientRect();
    dropdownEl.style.top   = r.bottom + 'px';
    dropdownEl.style.left  = r.left   + 'px';
    dropdownEl.style.width = r.width  + 'px';
}

function showStockDropdown(term) {
    var dd  = document.getElementById('stockSearchDropdown');
    var inp = document.getElementById('stockSearch');
    if (!term || term.length < 2) { dd.classList.add('d-none'); return; }
    positionDropdown(inp, dd);
    term = term.toLowerCase();
    var results = allStocks.filter(function(s) {
        return (s.product_name && s.product_name.toLowerCase().includes(term)) ||
               (s.stock_code   && s.stock_code.toLowerCase().includes(term))   ||
               (s.barcod       && s.barcod.toLowerCase().includes(term))       ||
               (s.product_code && s.product_code.toLowerCase().includes(term));
    }).slice(0, 25);
    dd.innerHTML = '';
    if (!results.length) {
        dd.innerHTML = '<div class="search-item text-muted">Sonuç bulunamadı</div>';
        dd.classList.remove('d-none'); return;
    }
    results.forEach(function(s) {
        var div = document.createElement('div');
        div.className = 'search-item';
        div.innerHTML = '<div>' + esc(s.product_name) + '</div>' +
                        '<div class="item-code">' + esc(s.stock_code) +
                        (s.barcod ? ' · ' + esc(s.barcod) : '') + '</div>';
        div.addEventListener('click', function() {
            dd.classList.add('d-none');
            document.getElementById('stockSearch').value       = s.product_name + (s.stock_code ? ' — ' + s.stock_code : '');
            document.getElementById('addStockId').value         = s.stock_id;
            document.getElementById('addProductId').value       = s.product_id || 0;
            document.getElementById('addProductTax').value      = s.product_tax || 18;
            document.getElementById('addTax').value             = s.product_tax || 18;
            document.getElementById('addStockInfo').classList.remove('d-none');
            document.getElementById('addStockLabel').textContent = s.label;
            updateKdvPreview();
            document.getElementById('addPrice').focus();
        });
        dd.appendChild(div);
    });
    dd.classList.remove('d-none');
}

function updateKdvPreview() {
    var p = parseFloat(document.getElementById('addPrice').value) || 0;
    var t = parseFloat(document.getElementById('addTax').value)   || 0;
    document.getElementById('addPriceKdvPreview').value = (p * (1 + t / 100)).toLocaleString('tr-TR', {minimumFractionDigits: 2, maximumFractionDigits: 4});
}

/* ─── Satır ekle ─── */
function addPriceRow() {
    var stockId   = parseInt(document.getElementById('addStockId').value)   || 0;
    var productId = parseInt(document.getElementById('addProductId').value) || 0;
    if (!stockId && !productId) { alert('Lütfen bir ürün seçin.'); document.getElementById('stockSearch').focus(); return; }

    var price    = parseFloat(document.getElementById('addPrice').value)    || 0;
    var tax      = parseFloat(document.getElementById('addTax').value)      || 0;
    var discount = parseFloat(document.getElementById('addDiscount').value) || 0;
    var label    = document.getElementById('addStockLabel').textContent;

    var btn = document.querySelector('##priceGrid').previousElementSibling;

    $.ajax({
        url: '/price/form/save_price_row.cfm', method: 'POST',
        data: {
            price_catid:    catId,
            stock_id:       stockId,
            product_id:     productId,
            price:          price,
            tax:            tax,
            price_discount: discount
        },
        dataType: 'json',
        success: function(res) {
            if (res.success) {
                /* Grid'i yenile */
                loadPriceGrid();
                /* Temizle */
                document.getElementById('stockSearch').value = '';
                document.getElementById('addStockId').value = '0';
                document.getElementById('addProductId').value = '0';
                document.getElementById('addStockInfo').classList.add('d-none');
                document.getElementById('addPrice').value = '';
                document.getElementById('addDiscount').value = '';
                document.getElementById('addPriceKdvPreview').value = '';
            } else {
                alert('Hata: ' + (res.message || ''));
            }
        },
        error: function() { alert('Sunucu hatası!'); }
    });
}

/* ─── Toplu fiyat değişikliği ─── */
function applyBulkChange() {
    var rate = parseFloat(document.getElementById('bulkRate').value) || 0;
    if (!rate) { alert('Lütfen bir oran girin.'); return; }
    var typeSel = document.querySelector('input[name="bulkType"]:checked');
    var type    = typeSel ? typeSel.value : 'increase';
    var rounding = parseInt(document.getElementById('bulkRound').value) || 0;
    var sign    = type === 'increase' ? 1 : -1;
    var msg     = (type === 'increase' ? 'artırılacak' : 'azaltılacak') + ': %' + rate;
    if (!confirm('Bu listedeki TÜM ürün fiyatları ' + msg + '. Onaylıyor musunuz?')) return;

    var resultDiv = document.getElementById('bulkResult');
    resultDiv.className = 'mt-2';
    resultDiv.innerHTML = '<div class="text-center"><i class="fas fa-spinner fa-spin"></i> İşleniyor...</div>';

    $.ajax({
        url: '/price/form/bulk_price_change.cfm', method: 'POST',
        data: { price_catid: catId, rate: rate, type: type, rounding: rounding },
        dataType: 'json',
        success: function(res) {
            if (res.success) {
                resultDiv.innerHTML = '<div class="alert alert-success py-2 mb-0"><i class="fas fa-check me-1"></i>' + (res.updated || 0) + ' fiyat güncellendi.</div>';
                loadPriceGrid();
            } else {
                resultDiv.innerHTML = '<div class="alert alert-danger py-2 mb-0">' + esc(res.message || 'Hata') + '</div>';
            }
        },
        error: function() { resultDiv.innerHTML = '<div class="alert alert-danger py-2 mb-0">Sunucu hatası!</div>'; }
    });
}

/* ─── Fiyat satırı sil ─── */
function deletePriceRow(priceId, name) {
    if (!confirm('«' + name + '» fiyat kaydını silmek istediğinizden emin misiniz?')) return;
    $.ajax({
        url: '/price/form/delete_price_row.cfm', method: 'POST',
        data: { price_id: priceId }, dataType: 'json',
        success: function(res) {
            if (res.success) loadPriceGrid();
            else alert('Hata: ' + (res.message || ''));
        }
    });
}

/* ─── Grid yükle / yenile ─── */
function loadPriceGrid() {
    $.ajax({
        url: '/price/form/get_prices.cfm', method: 'GET',
        data: { price_catid: catId }, dataType: 'json',
        success: function(data) {
            pricesData = Array.isArray(data) ? data : [];
            if (priceGrid) {
                priceGrid.option('dataSource', pricesData);
            }
            document.getElementById('recordCount').textContent = pricesData.length + ' kayıt';
        }
    });
}

function esc(str) {
    return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    /* Stok arama */
    document.getElementById('stockSearch').addEventListener('input', function(){ showStockDropdown(this.value); });
    document.getElementById('addPrice').addEventListener('input', updateKdvPreview);
    document.getElementById('addTax').addEventListener('input', updateKdvPreview);
    document.getElementById('addPrice').addEventListener('keydown', function(e){ if (e.key === 'Enter') addPriceRow(); });
    document.addEventListener('click', function(e){
        var dd = document.getElementById('stockSearchDropdown');
        if (!document.getElementById('stockSearch').contains(e.target) && !dd.contains(e.target)) dd.classList.add('d-none');
    });

    /* DevExtreme Grid */
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        priceGrid = $('##priceGrid').dxDataGrid({
            dataSource: pricesData,
            showBorders: true,
            showRowLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            allowColumnReordering: true,
            allowColumnResizing: true,
            columnResizingMode: 'widget',
            paging: { pageSize: 50 },
            pager: { visible: true, showInfo: true, infoText: 'Sayfa {0} / {1} ({2} kayıt)', showNavigationButtons: true, showPageSizeSelector: true, allowedPageSizes: [25, 50, 100] },
            filterRow: { visible: true, applyFilter: 'auto' },
            searchPanel: { visible: true, width: 200, placeholder: 'Ara...' },
            export: { enabled: true },
            onExporting: function (e) {
                var workbook = new ExcelJS.Workbook();
                var worksheet = workbook.addWorksheet('FiyatListesi');
                DevExpress.excelExporter.exportDataGrid({
                    component: e.component,
                    worksheet: worksheet,
                    autoFilterEnabled: true
                }).then(function () {
                    workbook.xlsx.writeBuffer().then(function (buffer) {
                        var fileName = 'fiyat_listesi_' + catId + '_' + new Date().toISOString().slice(0, 10) + '.xlsx';
                        saveAs(new Blob([buffer], { type: 'application/octet-stream' }), fileName);
                    });
                });
                e.cancel = true;
            },
            editing: {
                mode: 'cell',
                allowUpdating: true,
                allowDeleting: false
            },
            onRowUpdating: function(e) {
                /* Satır güncelleme — price_id ile tek satır kaydet */
                var updated = Object.assign({}, e.oldData, e.newData);
                $.ajax({
                    url: '/price/form/save_price_row.cfm', method: 'POST',
                    data: {
                        price_id:       updated.price_id,
                        price_catid:    catId,
                        stock_id:       updated.stock_id   || 0,
                        product_id:     updated.product_id || 0,
                        price:          updated.price      || 0,
                        tax:            updated.tax        || 0,
                        price_discount: updated.price_discount || 0,
                        startdate:      updated.startdate  || '',
                        finishdate:     updated.finishdate || ''
                    },
                    dataType: 'json',
                    success: function(res) {
                        if (res.success) {
                            loadPriceGrid();
                        }
                    }
                });
            },
            onContentReady: function(e) {
                document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt';
            },
            columns: [
                {
                    dataField: 'product_name', caption: 'Ürün / Stok', minWidth: 200, allowEditing: false,
                    cellTemplate: function(c, o) {
                        $('<div>').html('<strong>' + esc(o.data.product_name) + '</strong>' +
                            (o.data.property ? '<br><small class="text-muted">' + esc(o.data.property) + '</small>' : '') +
                            (o.data.barcod   ? '<br><small class="text-muted"><i class="fas fa-barcode me-1"></i>' + esc(o.data.barcod) + '</small>' : '')
                        ).appendTo(c);
                    }
                },
                {
                    dataField: 'price', caption: 'Fiyat', width: 120, dataType: 'number',
                    format: { type: 'fixedPoint', precision: 4 }, alignment: 'right',
                    cellTemplate: function(c, o) {
                        $('<strong>').text((parseFloat(o.value)||0).toLocaleString('tr-TR',{minimumFractionDigits:2,maximumFractionDigits:4})).appendTo(c);
                    }
                },
                { dataField: 'tax', caption: 'KDV %', width: 80, dataType: 'number', alignment: 'center' },
                {
                    dataField: 'price_kdv', caption: 'KDV\'li Fiyat', width: 120, dataType: 'number', allowEditing: false,
                    format: { type: 'fixedPoint', precision: 4 }, alignment: 'right',
                    cellTemplate: function(c, o) {
                        $('<span>').addClass('text-success fw-semibold')
                            .text((parseFloat(o.value)||0).toLocaleString('tr-TR',{minimumFractionDigits:2,maximumFractionDigits:4})).appendTo(c);
                    }
                },
                { dataField: 'price_discount', caption: 'İnd. %', width: 80, dataType: 'number', alignment: 'center' },
                { dataField: 'startdate',  caption: 'Başlangıç', width: 115, dataType: 'date', format: 'dd/MM/yyyy', allowEditing: true },
                { dataField: 'finishdate', caption: 'Bitiş',      width: 115, dataType: 'date', format: 'dd/MM/yyyy', allowEditing: true },
                {
                    caption: 'Sil', width: 65, alignment: 'center', allowSorting: false, allowFiltering: false, allowEditing: false,
                    cellTemplate: function(c, o) {
                        $('<button>').addClass('btn btn-sm btn-outline-danger')
                            .html('<i class="fas fa-trash"></i>')
                            .on('click', function(){ deletePriceRow(o.data.price_id, o.data.product_name); })
                            .appendTo(c);
                    }
                }
            ]
        }).dxDataGrid('instance');

        document.getElementById('recordCount').textContent = pricesData.length + ' kayıt';
    }
});
</script>
</cfoutput>
