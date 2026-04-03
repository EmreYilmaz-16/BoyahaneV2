<cfprocessingdirective pageEncoding="utf-8">

<!--- Edit mode --->
<cfset editMode      = isDefined("url.price_catid") AND isNumeric(url.price_catid) AND url.price_catid gt 0>
<cfset currentCatId  = editMode ? val(url.price_catid) : 0>

<cfif editMode>
    <cfquery name="getPriceCat" datasource="boyahane">
        SELECT * FROM price_cat
        WHERE price_catid = <cfqueryparam value="#currentCatId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getPriceCat.recordCount>
        <cfset editMode    = false>
        <cfset currentCatId = 0>
    </cfif>
</cfif>

<!--- Para birimleri --->
<cfquery name="getMoneys" datasource="boyahane">
    SELECT money_id, money_name, money_symbol FROM setup_money ORDER BY money_name
</cfquery>

<!--- Ödeme yöntemleri --->
<cfquery name="getPaymethods" datasource="boyahane">
    SELECT paymethod_id, paymethod FROM setup_paymethod ORDER BY paymethod
</cfquery>

<!--- Stoklar --->
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

<!--- Mevcut fiyat satırları (edit modunda) --->
<cfset priceRowsArray = []>
<cfif editMode AND getPriceCat.recordCount>
    <cfquery name="getPriceRows" datasource="boyahane">
        SELECT pr.*,
               p.product_name, p.product_code,
            p.tax,
               s.stock_code, s.barcod
        FROM price pr
        LEFT JOIN product p ON pr.product_id = p.product_id
        LEFT JOIN stocks  s ON pr.stock_id   = s.stock_id
        WHERE pr.price_catid = <cfqueryparam value="#currentCatId#" cfsqltype="cf_sql_integer">
        ORDER BY p.product_name, s.stock_code
    </cfquery>
    <cfloop query="getPriceRows">
        <cfset arrayAppend(priceRowsArray, {
            "price_id":       price_id,
            "stock_id":       stock_id ?: 0,
            "product_id":     product_id ?: 0,
            "product_name":   product_name ?: "",
            "product_code":   product_code ?: "",
            "stock_code":     stock_code ?: "",
            "price":          isNumeric(price) ? price : 0,
            "price_kdv":      isNumeric(price_kdv) ? price_kdv : 0,
            "is_kdv":         is_kdv,
            "tax":            isNumeric(tax) ? tax : 18,
            "price_discount": isNumeric(price_discount) ? price_discount : 0,
            "unit":           unit ?: 0,
            "money":          money ?: "",
            "startdate":      isDate(startdate)  ? dateFormat(startdate,  "yyyy-mm-dd") : "",
            "finishdate":     isDate(finishdate) ? dateFormat(finishdate, "yyyy-mm-dd") : ""
        })>
    </cfloop>
</cfif>

<!--- sel* --->
<cfset selStatus    = editMode AND getPriceCat.recordCount ? getPriceCat.price_cat_status : true>
<cfset selIsKdv     = editMode AND getPriceCat.recordCount ? getPriceCat.is_kdv    : true>
<cfset selIsSales   = editMode AND getPriceCat.recordCount ? getPriceCat.is_sales   : true>
<cfset selIsPurch   = editMode AND getPriceCat.recordCount ? getPriceCat.is_purchase : false>
<cfset selMoneyId   = editMode AND getPriceCat.recordCount ? val(getPriceCat.money_id   ?: 1)  : 1>
<cfset selPaymethod = editMode AND getPriceCat.recordCount ? val(getPriceCat.paymethod  ?: 0)  : 0>
<cfset selMargin    = editMode AND getPriceCat.recordCount ? val(getPriceCat.margin     ?: 0)  : 0>
<cfset selDiscount  = editMode AND getPriceCat.recordCount ? val(getPriceCat.discount   ?: 0)  : 0>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-tags"></i></div>
        <div class="page-header-title">
            <cfif editMode>
                <cfoutput><h1>Fiyat Listesi Düzenle <small class="text-muted fs-6">###currentCatId#</small></h1></cfoutput>
                <p>Fiyat listesi bilgilerini ve ürün fiyatlarını düzenleyin</p>
            <cfelse>
                <h1>Yeni Fiyat Listesi</h1>
                <p>Fiyat listesi bilgilerini doldurun ve ürün fiyatlarını ekleyin</p>
            </cfif>
        </div>
    </div>
    <a href="index.cfm?fuseaction=price.list_price_cat" class="btn-back">
        <i class="fas fa-arrow-left"></i>Fiyat Listeleri
    </a>
</div>

<div class="px-3 pb-5">
    <form id="priceCatForm">
        <input type="hidden" id="price_catid" value="<cfoutput>#currentCatId#</cfoutput>">

        <div class="row g-3">

            <!--- ══ SOL: LİSTE BİLGİLERİ ══ --->
            <div class="col-lg-4">
                <div class="grid-card sticky-top-card">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-tag"></i>Liste Bilgileri
                        </div>
                    </div>
                    <div class="card-body p-3">

                        <!--- Liste Adı --->
                        <div class="mb-3">
                            <label for="price_cat" class="form-label fw-semibold">
                                <i class="fas fa-tag me-1 text-primary"></i>Liste Adı <span class="text-danger">*</span>
                            </label>
                            <input type="text" class="form-control" id="price_cat" required
                                   placeholder="Örn: Liste Fiyatı, Perakende, Toptan..."
                                   value="<cfoutput><cfif editMode AND getPriceCat.recordCount>#xmlFormat(getPriceCat.price_cat)#</cfif></cfoutput>">
                        </div>

                        <!--- Satış / Alış --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fas fa-exchange-alt me-1 text-primary"></i>Kullanım</label>
                            <div class="d-flex gap-3">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" id="is_sales" <cfif selIsSales>checked</cfif>>
                                    <label class="form-check-label" for="is_sales">Satış</label>
                                </div>
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" id="is_purchase" <cfif selIsPurch>checked</cfif>>
                                    <label class="form-check-label" for="is_purchase">Alış</label>
                                </div>
                            </div>
                        </div>

                        <!--- KDV --->
                        <div class="mb-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="is_kdv" <cfif selIsKdv>checked</cfif>>
                                <label class="form-check-label fw-semibold" for="is_kdv">
                                    <i class="fas fa-percent me-1 text-primary"></i>KDV Dahil Fiyat
                                </label>
                            </div>
                        </div>

                        <!--- Para Birimi --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-coins me-1 text-primary"></i>Para Birimi
                            </label>
                            <select class="form-select" id="money_id">
                                <cfoutput query="getMoneys">
                                <option value="#money_id#" <cfif selMoneyId eq money_id>selected</cfif>>#xmlFormat(money_name)# (#xmlFormat(money_symbol)#)</option>
                                </cfoutput>
                            </select>
                        </div>

                        <!--- Ödeme Yöntemi --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-credit-card me-1 text-primary"></i>Ödeme Yöntemi
                            </label>
                            <select class="form-select" id="paymethod">
                                <option value="0">-- Seçin --</option>
                                <cfoutput query="getPaymethods">
                                <option value="#paymethod_id#" <cfif selPaymethod eq paymethod_id>selected</cfif>>#xmlFormat(paymethod)#</option>
                                </cfoutput>
                            </select>
                        </div>

                        <!--- Marj --->
                        <div class="row g-2 mb-3">
                            <div class="col-6">
                                <label for="margin" class="form-label fw-semibold">
                                    <i class="fas fa-chart-line me-1 text-primary"></i>Marj %
                                </label>
                                <input type="number" class="form-control" id="margin"
                                       step="0.01" min="0" placeholder="0.00"
                                       value="<cfoutput>#selMargin#</cfoutput>">
                            </div>
                            <div class="col-6">
                                <label for="discount" class="form-label fw-semibold">
                                    <i class="fas fa-percentage me-1 text-primary"></i>İndirim %
                                </label>
                                <input type="number" class="form-control" id="discount"
                                       step="0.01" min="0" max="100" placeholder="0.00"
                                       value="<cfoutput>#selDiscount#</cfoutput>">
                            </div>
                        </div>

                        <!--- Geçerlilik Tarihleri --->
                        <div class="row g-2 mb-3">
                            <div class="col-6">
                                <label for="startdate_cat" class="form-label fw-semibold small">
                                    <i class="fas fa-calendar me-1 text-primary"></i>Başlangıç
                                </label>
                                <input type="date" class="form-control form-control-sm" id="startdate_cat"
                                       value="<cfoutput><cfif editMode AND getPriceCat.recordCount AND isDate(getPriceCat.startdate)>#dateFormat(getPriceCat.startdate,'yyyy-mm-dd')#</cfif></cfoutput>">
                            </div>
                            <div class="col-6">
                                <label for="finishdate_cat" class="form-label fw-semibold small">
                                    <i class="fas fa-calendar-times me-1 text-primary"></i>Bitiş
                                </label>
                                <input type="date" class="form-control form-control-sm" id="finishdate_cat"
                                       value="<cfoutput><cfif editMode AND getPriceCat.recordCount AND isDate(getPriceCat.finishdate)>#dateFormat(getPriceCat.finishdate,'yyyy-mm-dd')#</cfif></cfoutput>">
                            </div>
                        </div>

                        <!--- Durum --->
                        <div class="mb-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="price_cat_status" <cfif selStatus>checked</cfif>>
                                <label class="form-check-label fw-semibold" for="price_cat_status">
                                    <i class="fas fa-toggle-on me-1 text-primary"></i>Aktif
                                </label>
                            </div>
                        </div>

                        <!--- Özet --->
                        <div class="p-3 rounded mb-3" style="background:#f8f9fa;border:1px solid #dee2e6">
                            <div class="d-flex justify-content-between">
                                <span class="text-muted small">Fiyat Satırı</span>
                                <span class="fw-bold text-primary" id="priceRowCount">0</span>
                            </div>
                        </div>

                        <div class="d-grid gap-2">
                            <button type="button" class="btn btn-primary btn-lg" id="saveBtn" onclick="savePriceCat()">
                                <i class="fas fa-save me-2"></i>
                                <cfif editMode>Güncelle<cfelse>Kaydet</cfif>
                            </button>
                            <cfif editMode>
                            <button type="button" class="btn btn-outline-danger" onclick="deletePriceCatForm()">
                                <i class="fas fa-trash me-2"></i>Sil
                            </button>
                            </cfif>
                        </div>

                    </div>
                </div>
            </div>

            <!--- ══ SAĞ: ÜRÜN FİYATLARI ══ --->
            <div class="col-lg-8">

                <!--- Stok Ekle --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-plus-circle"></i>Fiyat Ekle
                        </div>
                    </div>
                    <div class="card-body p-3">
                        <div class="row g-2 align-items-end">
                            <div class="col-lg-4">
                                <label class="form-label fw-semibold small">Stok / Ürün Ara</label>
                                <input type="text" class="form-control form-control-sm" id="stockSearch"
                                       placeholder="Ürün adı, kodu veya barkod..." autocomplete="off">
                                <div id="stockSearchDropdown" class="search-dropdown d-none"></div>
                                <input type="hidden" id="addStockId" value="0">
                                <input type="hidden" id="addProductId" value="0">
                            </div>
                            <div class="col-lg-2">
                                <label class="form-label fw-semibold small">Fiyat (KDV Hariç)</label>
                                <input type="number" class="form-control form-control-sm" id="addPrice"
                                       step="0.01" min="0" placeholder="0,00">
                            </div>
                            <div class="col-lg-2">
                                <label class="form-label fw-semibold small">KDV %</label>
                                <input type="number" class="form-control form-control-sm" id="addTax"
                                       step="1" min="0" max="100" placeholder="18" value="18">
                            </div>
                            <div class="col-lg-2">
                                <label class="form-label fw-semibold small">İndirim %</label>
                                <input type="number" class="form-control form-control-sm" id="addDiscount"
                                       step="0.01" min="0" max="100" placeholder="0">
                            </div>
                            <div class="col-lg-2">
                                <button type="button" class="btn btn-success btn-sm w-100" onclick="addPriceRow()" title="Ekle">
                                    <i class="fas fa-plus me-1"></i>Ekle
                                </button>
                            </div>
                        </div>
                        <div id="addStockInfo" class="mt-2 d-none">
                            <small class="text-info"><i class="fas fa-info-circle me-1"></i><span id="addStockLabel"></span></small>
                        </div>
                    </div>
                </div>

                <!--- Fiyat Tablosu --->
                <div class="grid-card">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-list-ul"></i>Fiyat Kalemleri
                        </div>
                        <span class="record-count" id="rowCountBadge">0 satır</span>
                    </div>
                    <div class="card-body p-2">
                        <div id="priceRowGrid"></div>
                    </div>
                </div>

            </div>
        </div>
    </form>
</div>

<cfoutput>
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
.search-dropdown .search-item:hover { background:##f0f6ff; }
.search-dropdown .search-item .item-code { color:##6c757d; font-size:.8rem; }
@media(min-width:992px){ .sticky-top-card { position:sticky; top:70px; } }
</style>

<script>
var allStocks    = #serializeJSON(stocksArray)#;
var priceRows    = #serializeJSON(priceRowsArray)#;
var editCatId    = #currentCatId#;
var priceRowGrid = null;

/* ─── Stok arama ─── */
function positionDropdown(inputEl, dropdownEl) {
    var rect = inputEl.getBoundingClientRect();
    dropdownEl.style.top   = rect.bottom + 'px';
    dropdownEl.style.left  = rect.left   + 'px';
    dropdownEl.style.width = rect.width  + 'px';
}

function showStockDropdown(term) {
    var container = document.getElementById('stockSearchDropdown');
    var inputEl   = document.getElementById('stockSearch');
    if (!term || term.length < 2) { container.classList.add('d-none'); return; }
    positionDropdown(inputEl, container);
    term = term.toLowerCase();
    var results = allStocks.filter(function(s) {
        return (s.product_name && s.product_name.toLowerCase().includes(term)) ||
               (s.stock_code   && s.stock_code.toLowerCase().includes(term))   ||
               (s.barcod       && s.barcod.toLowerCase().includes(term))       ||
               (s.product_code && s.product_code.toLowerCase().includes(term));
    }).slice(0, 25);
    container.innerHTML = '';
    if (!results.length) {
        container.innerHTML = '<div class="search-item text-muted">Sonuç bulunamadı</div>';
        container.classList.remove('d-none'); return;
    }
    results.forEach(function(s) {
        var div = document.createElement('div');
        div.className = 'search-item';
        div.innerHTML = '<div>' + escHtml(s.product_name) + '</div>' +
                        '<div class="item-code">' + escHtml(s.stock_code) +
                        (s.barcod ? ' · ' + escHtml(s.barcod) : '') + '</div>';
        div.addEventListener('click', function() {
            container.classList.add('d-none');
            document.getElementById('stockSearch').value = s.product_name + (s.stock_code ? ' — ' + s.stock_code : '');
            document.getElementById('addStockId').value   = s.stock_id;
            document.getElementById('addProductId').value = s.product_id || 0;
            document.getElementById('addTax').value       = s.product_tax || 18;
            document.getElementById('addStockInfo').classList.remove('d-none');
            document.getElementById('addStockLabel').textContent = s.label;
            document.getElementById('addPrice').focus();
        });
        container.appendChild(div);
    });
    container.classList.remove('d-none');
}

/* ─── Satır ekle ─── */
function addPriceRow() {
    var stockId   = parseInt(document.getElementById('addStockId').value)   || 0;
    var productId = parseInt(document.getElementById('addProductId').value) || 0;
    var label     = document.getElementById('addStockLabel').textContent;
    if (!stockId && !productId) { alert('Lütfen bir ürün seçin.'); document.getElementById('stockSearch').focus(); return; }

    var price    = parseFloat(document.getElementById('addPrice').value)    || 0;
    var tax      = parseFloat(document.getElementById('addTax').value)      || 0;
    var discount = parseFloat(document.getElementById('addDiscount').value) || 0;
    var priceKdv = price * (1 + tax / 100);

    /* Aynı stok varsa güncelle --->*/
    var existing = priceRows.findIndex(function(r){ return r.stock_id === stockId && stockId > 0; });
    if (existing >= 0) {
        if (!confirm('Bu ürün zaten listede. Üzerine yazmak ister misiniz?')) return;
        priceRows.splice(existing, 1);
    }

    priceRows.push({
        price_id:       0,
        stock_id:       stockId,
        product_id:     productId,
        product_name:   label,
        product_code:   '',
        price:          price,
        price_kdv:      parseFloat(priceKdv.toFixed(6)),
        is_kdv:         document.getElementById('is_kdv').checked,
        tax:            tax,
        price_discount: discount,
        unit:           0,
        money:          '',
        startdate:      '',
        finishdate:     ''
    });

    refreshGrid();

    /* Temizle */
    document.getElementById('stockSearch').value = '';
    document.getElementById('addStockId').value  = '0';
    document.getElementById('addProductId').value = '0';
    document.getElementById('addStockInfo').classList.add('d-none');
    document.getElementById('addPrice').value    = '';
    document.getElementById('addDiscount').value = '';
}

function removeRow(idx) {
    priceRows.splice(idx, 1);
    refreshGrid();
}

function refreshGrid() {
    document.getElementById('priceRowCount').textContent  = priceRows.length;
    document.getElementById('rowCountBadge').textContent  = priceRows.length + ' satır';
    if (priceRowGrid) {
        priceRowGrid.option('dataSource', priceRows.map(function(r, i){ return Object.assign({}, r, {_idx: i}); }));
    }
}

/* ─── Kaydet ─── */
function savePriceCat() {
    var catName = document.getElementById('price_cat').value.trim();
    if (!catName) { alert('Liste adı zorunludur.'); document.getElementById('price_cat').focus(); return; }

    var data = {
        price_catid:       parseInt(document.getElementById('price_catid').value) || 0,
        price_cat:         catName,
        is_kdv:            document.getElementById('is_kdv').checked ? '1' : '0',
        is_sales:          document.getElementById('is_sales').checked ? '1' : '0',
        is_purchase:       document.getElementById('is_purchase').checked ? '1' : '0',
        price_cat_status:  document.getElementById('price_cat_status').checked ? '1' : '0',
        money_id:          parseInt(document.getElementById('money_id').value) || 1,
        paymethod:         parseInt(document.getElementById('paymethod').value) || 0,
        margin:            parseFloat(document.getElementById('margin').value)   || 0,
        discount:          parseFloat(document.getElementById('discount').value) || 0,
        startdate:         document.getElementById('startdate_cat').value,
        finishdate:        document.getElementById('finishdate_cat').value,
        rows:              JSON.stringify(priceRows)
    };

    var btn = document.getElementById('saveBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url: '/price/form/save_price_cat.cfm', method: 'POST', data: data, dataType: 'json',
        success: function(res) {
            if (res.success) {
                var newId = res.price_catid || parseInt(document.getElementById('price_catid').value) || 0;
                if (!editCatId && newId) {
                    window.location.href = 'index.cfm?fuseaction=price.add_price_cat&price_catid=' + newId;
                } else {
                    btn.disabled = false;
                    btn.innerHTML = '<i class="fas fa-save me-2"></i>Güncelle';
                    alert('Kaydedildi!');
                }
            } else {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-save me-2"></i>' + (editCatId ? 'Güncelle' : 'Kaydet');
                alert('Hata: ' + (res.message || 'Bilinmeyen hata'));
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>' + (editCatId ? 'Güncelle' : 'Kaydet');
            alert('Sunucu hatası!');
        }
    });
}

function deletePriceCatForm() {
    var id = parseInt(document.getElementById('price_catid').value) || 0;
    if (!id || !confirm('Bu fiyat listesini silmek istediğinizden emin misiniz?\nBağlı tüm fiyat kayıtları da silinecek!')) return;
    $.ajax({
        url: '/price/form/delete_price_cat.cfm', method: 'POST',
        data: { price_catid: id }, dataType: 'json',
        success: function(res) {
            if (res.success) window.location.href = 'index.cfm?fuseaction=price.list_price_cat';
            else alert('Silme hatası: ' + (res.message || ''));
        }
    });
}

function escHtml(str) {
    return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    /* Stok arama */
    document.getElementById('stockSearch').addEventListener('input', function(){ showStockDropdown(this.value); });
    document.getElementById('addPrice').addEventListener('keydown', function(e){ if (e.key === 'Enter') addPriceRow(); });
    document.addEventListener('click', function(e){
        var sDd = document.getElementById('stockSearchDropdown');
        if (!document.getElementById('stockSearch').contains(e.target) && !sDd.contains(e.target)) sDd.classList.add('d-none');
    });

    /* DevExtreme Grid */
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        priceRowGrid = $('##priceRowGrid').dxDataGrid({
            dataSource: priceRows.map(function(r, i){ return Object.assign({}, r, {_idx: i}); }),
            showBorders: true, showRowLines: true, rowAlternationEnabled: true, columnAutoWidth: true,
            editing: { mode: 'cell', allowUpdating: true, allowDeleting: false },
            onRowUpdated: function(e) {
                var idx = e.data._idx;
                if (idx !== undefined && priceRows[idx]) {
                    Object.assign(priceRows[idx], {
                        price:          e.data.price,
                        price_kdv:      e.data.price_kdv,
                        tax:            e.data.tax,
                        price_discount: e.data.price_discount,
                        startdate:      e.data.startdate,
                        finishdate:     e.data.finishdate
                    });
                    /* KDV'li fiyatı otomatik hesapla */
                    var p = parseFloat(priceRows[idx].price) || 0;
                    var t = parseFloat(priceRows[idx].tax)   || 0;
                    priceRows[idx].price_kdv = parseFloat((p * (1 + t / 100)).toFixed(6));
                }
            },
            columns: [
                { dataField: 'product_name', caption: 'Ürün', minWidth: 180, allowEditing: false },
                { dataField: 'price',          caption: 'Fiyat',       width: 110, dataType: 'number', format: { type:'fixedPoint', precision:4 }, alignment:'right' },
                { dataField: 'tax',            caption: 'KDV %',       width: 75,  dataType: 'number' },
                { dataField: 'price_kdv',      caption: 'KDV\'li',     width: 110, dataType: 'number', format: { type:'fixedPoint', precision:4 }, alignment:'right', allowEditing: false,
                    cellTemplate: function(c, o) { $('<span>').addClass('text-success fw-semibold').text((parseFloat(o.value)||0).toLocaleString('tr-TR',{minimumFractionDigits:4})).appendTo(c); }
                },
                { dataField: 'price_discount', caption: 'İnd. %',      width: 75,  dataType: 'number' },
                { dataField: 'startdate',      caption: 'Başlangıç',   width: 120, dataType: 'date',   format: 'dd/MM/yyyy', allowEditing: true },
                { dataField: 'finishdate',     caption: 'Bitiş',       width: 120, dataType: 'date',   format: 'dd/MM/yyyy', allowEditing: true },
                {
                    caption: 'Sil', width: 65, alignment: 'center', allowSorting: false, allowFiltering: false, allowEditing: false,
                    cellTemplate: function(c, o) {
                        $('<button>').addClass('btn btn-sm btn-outline-danger').html('<i class="fas fa-trash"></i>')
                            .on('click', function(){ removeRow(o.data._idx); }).appendTo(c);
                    }
                }
            ],
            onContentReady: function() {
                document.getElementById('priceRowCount').textContent  = priceRows.length;
                document.getElementById('rowCountBadge').textContent  = priceRows.length + ' satır';
            }
        }).dxDataGrid('instance');
    }

    refreshGrid();
});
</script>
</cfoutput>
