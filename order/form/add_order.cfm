<cfprocessingdirective pageEncoding="utf-8">

<!--- Edit mode --->
<cfset editMode    = isDefined("url.order_id") AND isNumeric(url.order_id) AND url.order_id gt 0>
<cfset currentOrderId = editMode ? val(url.order_id) : 0>

<cfif editMode>
    <cfquery name="getOrder" datasource="boyahane">
        SELECT o.*,
               COALESCE(c.nickname, c.fullname, '') AS company_name,
               COALESCE(sm.money_name, 'TRY') AS currency_name
        FROM orders o
        LEFT JOIN company c ON o.company_id = c.company_id
        LEFT JOIN setup_money sm ON o.order_currency = sm.money_id
        WHERE o.order_id = <cfqueryparam value="#currentOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getOrder.recordCount>
        <cfset editMode = false>
        <cfset currentOrderId = 0>
    <cfelse>
        <cfquery name="getOrderRows" datasource="boyahane">
            SELECT orw.*, p.product_code
            FROM order_row orw
            LEFT JOIN product p ON orw.product_id = p.product_id
            WHERE orw.order_id = <cfqueryparam value="#currentOrderId#" cfsqltype="cf_sql_integer">
            ORDER BY orw.order_row_id
        </cfquery>
    </cfif>
</cfif>

<!--- Ödeme yöntemleri --->
<cfquery name="getPaymethods" datasource="boyahane">
    SELECT paymethod_id, paymethod FROM setup_paymethod ORDER BY paymethod
</cfquery>

<!--- Sevkiyat yöntemleri --->
<cfquery name="getShipMethods" datasource="boyahane">
    SELECT ship_method_id, ship_method FROM ship_method ORDER BY ship_method
</cfquery>

<!--- Para birimleri --->
<cfquery name="getMoneys" datasource="boyahane">
    SELECT money_id, money_name, money_symbol FROM setup_money ORDER BY money_name
</cfquery>

<!--- Stoklar --->
<cfquery name="getStocks" datasource="boyahane">
    SELECT s.stock_id, s.stock_code, s.barcod,
           s.property, s.product_unit_id,
           p.product_id, p.product_name, p.product_code
    FROM stocks s
    LEFT JOIN product p ON s.product_id = p.product_id
    WHERE s.stock_status = true
    ORDER BY p.product_name, s.stock_code
</cfquery>

<cfset stocksArray = []>
<cfloop query="getStocks">
    <cfset arrayAppend(stocksArray, {
        "stock_id"        = stock_id,
        "stock_code"      = stock_code ?: "",
        "barcod"          = barcod ?: "",
        "property"        = property ?: "",
        "product_id"      = product_id ?: 0,
        "product_unit_id" = product_unit_id ?: 0,
        "product_name"    = product_name ?: "",
        "product_code"    = product_code ?: "",
        "label"           = (product_name ?: "?") & " — " & (stock_code ?: "")
    })>
</cfloop>

<!--- Mevcut satırlar --->
<cfset rowsArray = []>
<cfif editMode AND isDefined("getOrderRows") AND getOrderRows.recordCount>
    <cfloop query="getOrderRows">
        <cfset arrayAppend(rowsArray, {
            "order_row_id": order_row_id,
            "stock_id":     stock_id ?: 0,
            "product_id":   product_id ?: 0,
            "product_name": product_name ?: "",
            "product_code": product_code ?: "",
            "quantity":     isNumeric(quantity)     ? quantity     : 0,
            "price":        isNumeric(price)        ? price        : 0,
            "tax":          isNumeric(tax)          ? tax          : 0,
            "discount_1":   isNumeric(discount_1)   ? discount_1   : 0,
            "nettotal":     isNumeric(nettotal)     ? nettotal     : 0,
            "unit":         unit ?: "",
            "unit_id":      unit_id ?: 0,
            "lot_no":       lot_no ?: ""
        })>
    </cfloop>
</cfif>

<!--- Seçili değerler --->
<cfset selPurchaseSales = editMode AND isDefined("getOrder") AND getOrder.recordCount ? getOrder.purchase_sales : true>
<cfset selOrderStage    = editMode AND isDefined("getOrder") AND getOrder.recordCount ? val(getOrder.order_stage ?: 1) : 1>
<cfset selPaymethod     = editMode AND isDefined("getOrder") AND getOrder.recordCount ? val(getOrder.paymethod ?: 0) : 0>
<cfset selShipMethod    = editMode AND isDefined("getOrder") AND getOrder.recordCount ? val(getOrder.ship_method ?: 0) : 0>
<cfset selCurrency      = editMode AND isDefined("getOrder") AND getOrder.recordCount ? val(getOrder.order_currency ?: 0) : 0>
<cfset selCompanyId     = editMode AND isDefined("getOrder") AND getOrder.recordCount ? val(getOrder.company_id ?: 0) : 0>
<cfset selCompanyName   = editMode AND isDefined("getOrder") AND getOrder.recordCount ? (getOrder.company_name ?: "") : "">
<cfset selOrderStatus   = editMode AND isDefined("getOrder") AND getOrder.recordCount ? getOrder.order_status : true>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-shopping-cart"></i></div>
        <div class="page-header-title">
            <cfif editMode>
                <cfoutput><h1>Sipariş Düzenle <small class="text-muted fs-6">###currentOrderId#</small></h1></cfoutput>
                <p>Sipariş bilgilerini ve kalemlerini düzenleyin</p>
            <cfelse>
                <h1>Yeni Sipariş</h1>
                <p>Sipariş bilgilerini doldurun ve ürünleri ekleyin</p>
            </cfif>
        </div>
    </div>
    <a href="index.cfm?fuseaction=order.list_orders" class="btn-back">
        <i class="fas fa-arrow-left"></i>Sipariş Listesi
    </a>
</div>

<div class="px-3 pb-5">
    <form id="orderForm">
        <input type="hidden" id="order_id" value="<cfoutput>#currentOrderId#</cfoutput>">

        <div class="row g-3">

            <!--- ═══════ SOL: SİPARİŞ BİLGİLERİ ═══════ --->
            <div class="col-lg-4">
                <div class="grid-card sticky-top-card">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-receipt"></i>Sipariş Bilgileri
                        </div>
                        <span class="badge bg-primary" id="orderStatusBadge">
                            <cfif editMode>Düzenleniyor<cfelse>Yeni</cfif>
                        </span>
                    </div>
                    <div class="card-body p-3">

                        <!--- Alış / Satış --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fas fa-exchange-alt me-1 text-primary"></i>İşlem Türü</label>
                            <div class="btn-group w-100" role="group">
                                <input type="radio" class="btn-check" name="purchase_sales" id="ps_satis" value="true"  <cfif selPurchaseSales>checked</cfif>>
                                <label class="btn btn-outline-success btn-sm" for="ps_satis"><i class="fas fa-arrow-up me-1"></i>Satış</label>
                                <input type="radio" class="btn-check" name="purchase_sales" id="ps_alis"  value="false" <cfif NOT selPurchaseSales>checked</cfif>>
                                <label class="btn btn-outline-warning btn-sm" for="ps_alis"><i class="fas fa-arrow-down me-1"></i>Alış</label>
                            </div>
                        </div>

                        <!--- Sipariş Aşaması --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fas fa-tasks me-1 text-primary"></i>Aşama</label>
                            <select class="form-select" id="order_stage">
                                <option value="1" <cfif selOrderStage eq 1>selected</cfif>>Beklemede</option>
                                <option value="2" <cfif selOrderStage eq 2>selected</cfif>>Onaylandı</option>
                                <option value="3" <cfif selOrderStage eq 3>selected</cfif>>Üretimde</option>
                                <option value="4" <cfif selOrderStage eq 4>selected</cfif>>Hazır</option>
                                <option value="5" <cfif selOrderStage eq 5>selected</cfif>>Sevk Edildi</option>
                                <option value="6" <cfif selOrderStage eq 6>selected</cfif>>Tamamlandı</option>
                            </select>
                        </div>

                        <!--- Firma --->
                        <div class="mb-3" style="position:relative">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-building me-1 text-primary"></i>Firma <span class="text-danger">*</span>
                            </label>
                            <input type="text" class="form-control" id="companySearch"
                                   placeholder="Firma adı ile arayın..." autocomplete="off" required
                                   value="<cfoutput>#xmlFormat(selCompanyName)#</cfoutput>">
                            <input type="hidden" id="company_id" value="<cfoutput>#selCompanyId#</cfoutput>">
                            <div id="companyDropdown" class="search-dropdown d-none"></div>
                            <div id="companyInfo" class="mt-1 <cfif selCompanyId eq 0>d-none</cfif>">
                                <small class="text-success"><i class="fas fa-check-circle me-1"></i><span id="companyRiskInfo"></span></small>
                            </div>
                        </div>

                        <!--- Sipariş No --->
                        <div class="mb-3">
                            <label for="order_number" class="form-label fw-semibold">
                                <i class="fas fa-hashtag me-1 text-primary"></i>Sipariş No
                            </label>
                            <input type="text" class="form-control" id="order_number"
                                   placeholder="Otomatik veya elle girin"
                                   value="<cfoutput><cfif editMode AND getOrder.recordCount>#xmlFormat(getOrder.order_number)#</cfif></cfoutput>">
                        </div>

                        <!--- Başlık --->
                        <div class="mb-3">
                            <label for="order_head" class="form-label fw-semibold">
                                <i class="fas fa-heading me-1 text-primary"></i>Başlık
                            </label>
                            <input type="text" class="form-control" id="order_head"
                                   placeholder="Sipariş başlığı"
                                   value="<cfoutput><cfif editMode AND getOrder.recordCount>#xmlFormat(getOrder.order_head)#</cfif></cfoutput>">
                        </div>

                        <!--- Referans No --->
                        <div class="mb-3">
                            <label for="ref_no" class="form-label fw-semibold">
                                <i class="fas fa-link me-1 text-primary"></i>Referans No
                            </label>
                            <input type="text" class="form-control" id="ref_no"
                                   placeholder="Sipariş/teklif no vb."
                                   value="<cfoutput><cfif editMode AND getOrder.recordCount>#xmlFormat(getOrder.ref_no)#</cfif></cfoutput>">
                        </div>

                        <!--- Teslim Tarihi --->
                        <div class="mb-3">
                            <label for="deliverdate" class="form-label fw-semibold">
                                <i class="fas fa-calendar-alt me-1 text-primary"></i>Teslim Tarihi
                            </label>
                            <input type="date" class="form-control" id="deliverdate"
                                   value="<cfoutput><cfif editMode AND getOrder.recordCount AND isDate(getOrder.deliverdate)>#dateFormat(getOrder.deliverdate,'yyyy-mm-dd')#</cfif></cfoutput>">
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

                        <!--- Sevkiyat Yöntemi --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-truck me-1 text-primary"></i>Sevkiyat Yöntemi
                            </label>
                            <select class="form-select" id="ship_method">
                                <option value="0">-- Seçin --</option>
                                <cfoutput query="getShipMethods">
                                <option value="#ship_method_id#" <cfif selShipMethod eq ship_method_id>selected</cfif>>#xmlFormat(ship_method)#</option>
                                </cfoutput>
                            </select>
                        </div>

                        <!--- Para Birimi --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-coins me-1 text-primary"></i>Para Birimi
                            </label>
                            <select class="form-select" id="order_currency">
                                <option value="0">-- Seçin --</option>
                                <cfoutput query="getMoneys">
                                <option value="#money_id#" <cfif selCurrency eq money_id>selected</cfif>>#xmlFormat(money_name)# (#xmlFormat(money_symbol)#)</option>
                                </cfoutput>
                            </select>
                        </div>

                        <!--- Açıklama --->
                        <div class="mb-3">
                            <label for="order_detail" class="form-label fw-semibold">
                                <i class="fas fa-sticky-note me-1 text-primary"></i>Açıklama
                            </label>
                            <textarea class="form-control" id="order_detail" rows="2"
                                      placeholder="Sipariş açıklaması..."><cfoutput><cfif editMode AND getOrder.recordCount>#xmlFormat(getOrder.order_detail)#</cfif></cfoutput></textarea>
                        </div>

                        <!--- Durum --->
                        <div class="mb-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="order_status"
                                       <cfif selOrderStatus>checked</cfif>>
                                <label class="form-check-label fw-semibold" for="order_status">
                                    <i class="fas fa-toggle-on me-1 text-primary"></i>Aktif
                                </label>
                            </div>
                        </div>

                        <!--- Toplam Özet --->
                        <div class="order-totals p-3 rounded mb-3" style="background:#f8f9fa;border:1px solid #dee2e6;">
                            <div class="d-flex justify-content-between mb-1">
                                <span class="text-muted small">Brüt Toplam</span>
                                <span id="totalGross">0,00</span>
                            </div>
                            <div class="d-flex justify-content-between mb-1">
                                <span class="text-muted small">İndirim</span>
                                <span id="totalDiscount">0,00</span>
                            </div>
                            <div class="d-flex justify-content-between mb-1">
                                <span class="text-muted small">KDV</span>
                                <span id="totalTax">0,00</span>
                            </div>
                            <hr class="my-1">
                            <div class="d-flex justify-content-between">
                                <span class="fw-bold">Net Toplam</span>
                                <span class="fw-bold text-primary fs-5" id="totalNet">0,00</span>
                            </div>
                        </div>

                        <!--- Kaydet / Sil --->
                        <div class="d-grid gap-2">
                            <button type="button" class="btn btn-primary btn-lg" id="saveBtn" onclick="saveOrder()">
                                <i class="fas fa-save me-2"></i>
                                <cfif editMode>Güncelle<cfelse>Kaydet</cfif>
                            </button>
                            <cfif editMode>
                            <button type="button" class="btn btn-outline-danger" onclick="deleteOrderForm()">
                                <i class="fas fa-trash me-2"></i>Sil
                            </button>
                            </cfif>
                        </div>

                    </div>
                </div>
            </div>

            <!--- ═══════ SAĞ: ÜRÜN SATIRLARI ═══════ --->
            <div class="col-lg-8">

                <!--- Stok Arama / Satır Ekleme --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-plus-circle"></i>Ürün Ekle
                        </div>
                    </div>
                    <div class="card-body p-3">
                        <div class="row g-2 align-items-end">
                            <div class="col-lg-5">
                                <label class="form-label fw-semibold small">Stok Ara</label>
                                <input type="text" class="form-control form-control-sm" id="stockSearch"
                                       placeholder="Ürün adı, kodu veya barkod..." autocomplete="off">
                                <div id="stockSearchDropdown" class="search-dropdown d-none"></div>
                                <input type="hidden" id="addStockId" value="0">
                                <input type="hidden" id="addProductId" value="0">
                                <input type="hidden" id="addProductUnitId" value="0">
                            </div>
                            <div class="col-lg-2">
                                <label class="form-label fw-semibold small">Miktar</label>
                                <input type="number" class="form-control form-control-sm" id="addQuantity"
                                       step="0.001" min="0" placeholder="1" value="1">
                            </div>
                            <div class="col-lg-2">
                                <label class="form-label fw-semibold small">Birim Fiyat</label>
                                <input type="number" class="form-control form-control-sm" id="addPrice"
                                       step="0.01" min="0" placeholder="0,00" value="">
                            </div>
                            <div class="col-lg-2">
                                <label class="form-label fw-semibold small">KDV %</label>
                                <input type="number" class="form-control form-control-sm" id="addTax"
                                       step="1" min="0" max="100" placeholder="18" value="18">
                            </div>
                            <div class="col-lg-1">
                                <button type="button" class="btn btn-success btn-sm w-100" onclick="addRowToGrid()" title="Ekle">
                                    <i class="fas fa-plus"></i>
                                </button>
                            </div>
                        </div>
                        <div id="addStockInfo" class="mt-2 d-none">
                            <small class="text-info"><i class="fas fa-info-circle me-1"></i><span id="addStockLabel"></span></small>
                        </div>
                    </div>
                </div>

                <!--- Satır Tablosu --->
                <div class="grid-card">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-list-ul"></i>Sipariş Kalemleri
                        </div>
                        <span class="record-count" id="rowCount">0 satır</span>
                    </div>
                    <div class="card-body p-2">
                        <div id="orderRowGrid"></div>
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
var allStocks   = #serializeJSON(stocksArray)#;
var orderRows   = #serializeJSON(rowsArray)#;
var editOrderId = #currentOrderId#;

var rowGrid = null;
var companyPriceMap = {}; /* stock_id -> price */

/* ─── Firma arama ─── */
var allCompanies = [], companyLoaded = false;

function loadCompanies() {
    if (companyLoaded) return;
    $.ajax({
        url: '/company/cfc/company.cfc?method=getCompaniesForDropdown',
        method: 'GET', dataType: 'json',
        success: function(data) { allCompanies = Array.isArray(data) ? data : []; companyLoaded = true; }
    });
}

function selectCompany(c) {
    $('##companySearch').val(c.display_name || c.nickname || c.fullname || '');
    $('##company_id').val(c.company_id);
    $('##companyDropdown').addClass('d-none');
    $('##companyInfo').removeClass('d-none');
    companyPriceMap = {};
    $.ajax({
        url: '/company/cfc/company.cfc',
        method: 'GET',
        data: { method: 'getCompanyRisk', company_id: c.company_id },
        dataType: 'json',
        success: function(res) {
            var d = res.data || res;
            var label = [];
            if (d.paymethod_name)   label.push('Ödeme: ' + escHtml(d.paymethod_name));
            if (d.ship_method_name) label.push('Sevk: '  + escHtml(d.ship_method_name));
            $('##companyRiskInfo').html(label.length ? label.join(' &nbsp;|&nbsp; ') : 'Risk bilgisi yok');
            if (d.paymethod_id && !parseInt($('##paymethod').val())) $('##paymethod').val(d.paymethod_id);
            if (d.ship_method  && !parseInt($('##ship_method').val())) $('##ship_method').val(d.ship_method);

            /* Fiyat listesini yükle — satış için price_cat, alış için price_cat_purchase */
            var psSel = document.querySelector('input[name="purchase_sales"]:checked');
            var isSales = !psSel || psSel.value === 'true';
            var catId = isSales ? (d.price_cat || 0) : (d.price_cat_purchase || 0);
            if (catId > 0) loadCompanyPrices(catId);
        }
    });
}

/* ─── Stok arama ─── */
function loadCompanyPrices(catId) {
    $.ajax({
        url: '/price/form/get_prices.cfm',
        method: 'GET',
        data: { price_catid: catId },
        dataType: 'json',
        success: function(data) {
            companyPriceMap = {};
            if (Array.isArray(data)) {
                data.forEach(function(row) {
                    if (row.stock_id > 0) companyPriceMap[row.stock_id] = row.price;
                });
            }
        }
    });
}

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
    var companyId = parseInt(document.getElementById('company_id').value) || 0;
    if (!companyId) {
        container.innerHTML = '<div class="search-item text-warning"><i class="fas fa-exclamation-triangle me-1"></i>Önce firma seçin</div>';
        container.classList.remove('d-none');
        positionDropdown(inputEl, container);
        return;
    }
    positionDropdown(inputEl, container);
    term = term.toLowerCase();
    var results = allStocks.filter(function(s) {
        return (s.product_name && s.product_name.toLowerCase().includes(term)) ||
               (s.stock_code   && s.stock_code.toLowerCase().includes(term))   ||
               (s.barcod       && s.barcod.toLowerCase().includes(term))        ||
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
                        (s.barcod ? ' · Barkod: ' + escHtml(s.barcod) : '') + '</div>';
        div.addEventListener('click', function() {
            container.classList.add('d-none');
            selectSearchStock(s);
        });
        container.appendChild(div);
    });
    container.classList.remove('d-none');
}

function selectSearchStock(s) {
    document.getElementById('stockSearch').value = s.product_name + (s.stock_code ? ' — ' + s.stock_code : '');
    document.getElementById('addStockId').value     = s.stock_id;
    document.getElementById('addProductId').value   = s.product_id || 0;
    document.getElementById('addProductUnitId').value = s.product_unit_id || 0;
    document.getElementById('addStockInfo').classList.remove('d-none');
    document.getElementById('addStockLabel').textContent = s.product_name +
        (s.stock_code ? ' — ' + s.stock_code : '') +
        (s.property   ? ' (' + s.property + ')' : '');
    /* Fiyat listesinden fiyatı otomatik doldur */
    var listPrice = companyPriceMap[s.stock_id];
    if (listPrice !== undefined && listPrice > 0) {
        document.getElementById('addPrice').value = listPrice;
    } else {
        document.getElementById('addPrice').value = '';
    }
    document.getElementById('addPrice').focus();
}

/* ─── Satır ekle / sil ─── */
function addRowToGrid() {
    var stockId     = parseInt(document.getElementById('addStockId').value)   || 0;
    var productId   = parseInt(document.getElementById('addProductId').value) || 0;
    var stockLabel  = document.getElementById('addStockLabel').textContent;
    if (!stockId) { alert('Lütfen bir ürün seçin.'); document.getElementById('stockSearch').focus(); return; }

    var qty     = parseFloat(document.getElementById('addQuantity').value) || 1;
    var price   = parseFloat(document.getElementById('addPrice').value)    || 0;
    var tax     = parseFloat(document.getElementById('addTax').value)      || 0;
    var gross   = qty * price;
    var taxAmt  = gross * (tax / 100);
    var net     = gross + taxAmt;

    orderRows.push({
        order_row_id: 0,
        stock_id:     stockId,
        product_id:   productId,
        product_name: stockLabel,
        product_code: '',
        quantity:     qty,
        price:        price,
        tax:          tax,
        discount_1:   0,
        nettotal:     net,
        unit:         '',
        unit_id:      0,
        lot_no:       ''
    });

    refreshGrid();
    calcTotals();

    /* Temizle */
    document.getElementById('stockSearch').value = '';
    document.getElementById('addStockId').value  = '0';
    document.getElementById('addProductId').value = '0';
    document.getElementById('addStockInfo').classList.add('d-none');
    document.getElementById('addQuantity').value = '1';
    document.getElementById('addPrice').value    = '';
}

function removeRow(idx) {
    orderRows.splice(idx, 1);
    refreshGrid();
    calcTotals();
}

function refreshGrid() {
    document.getElementById('rowCount').textContent = orderRows.length + ' satır';
    if (rowGrid) {
        rowGrid.option('dataSource', orderRows.map(function(r, i){ return Object.assign({}, r, {_idx: i}); }));
    }
}

function calcTotals() {
    var gross = 0, disc = 0, tax = 0, net = 0;
    orderRows.forEach(function(r) {
        var q  = parseFloat(r.quantity) || 0;
        var p  = parseFloat(r.price)    || 0;
        var t  = parseFloat(r.tax)      || 0;
        var d  = parseFloat(r.discount_1) || 0;
        var g  = q * p;
        var dt = g * (d / 100);
        var ta = (g - dt) * (t / 100);
        gross += g;
        disc  += dt;
        tax   += ta;
        net   += (g - dt + ta);
    });
    document.getElementById('totalGross').textContent    = gross.toLocaleString('tr-TR', {minimumFractionDigits:2, maximumFractionDigits:2});
    document.getElementById('totalDiscount').textContent = disc.toLocaleString('tr-TR',  {minimumFractionDigits:2, maximumFractionDigits:2});
    document.getElementById('totalTax').textContent      = tax.toLocaleString('tr-TR',   {minimumFractionDigits:2, maximumFractionDigits:2});
    document.getElementById('totalNet').textContent      = net.toLocaleString('tr-TR',   {minimumFractionDigits:2, maximumFractionDigits:2});
}

/* ─── Kaydet ─── */
function saveOrder() {
    var companyId = parseInt(document.getElementById('company_id').value) || 0;
    if (!companyId) { alert('Lütfen firma seçin.'); document.getElementById('companySearch').focus(); return; }
    if (!orderRows.length) { alert('En az bir ürün satırı ekleyin.'); return; }

    var psSel = document.querySelector('input[name="purchase_sales"]:checked');
    var today = new Date().toISOString().slice(0, 10);

    var data = {
        order_id:       parseInt(document.getElementById('order_id').value) || 0,
        purchase_sales: psSel ? psSel.value : 'true',
        order_stage:    document.getElementById('order_stage').value,
        order_number:   document.getElementById('order_number').value,
        order_head:     document.getElementById('order_head').value,
        ref_no:         document.getElementById('ref_no').value,
        order_detail:   document.getElementById('order_detail').value,
        order_date:     today,
        deliverdate:    document.getElementById('deliverdate').value,
        company_id:     companyId,
        paymethod:      parseInt(document.getElementById('paymethod').value)      || 0,
        ship_method:    parseInt(document.getElementById('ship_method').value)    || 0,
        order_currency: parseInt(document.getElementById('order_currency').value) || 0,
        order_status:   document.getElementById('order_status').checked ? '1' : '0',
        rows:           JSON.stringify(orderRows)
    };

    var btn = document.getElementById('saveBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url: '/order/form/save_order.cfm', method: 'POST', data: data, dataType: 'json',
        success: function(res) {
            if (res.success) {
                var newId = res.order_id || parseInt(document.getElementById('order_id').value) || 0;
                if (!editOrderId && newId) {
                    window.location.href = 'index.cfm?fuseaction=order.add_order&order_id=' + newId;
                } else {
                    btn.disabled = false;
                    btn.innerHTML = '<i class="fas fa-save me-2"></i>Güncelle';
                    alert('Kaydedildi!');
                }
            } else {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-save me-2"></i>' + (editOrderId ? 'Güncelle' : 'Kaydet');
                alert('Hata: ' + (res.message || 'Bilinmeyen hata'));
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>' + (editOrderId ? 'Güncelle' : 'Kaydet');
            alert('Sunucu hatası!');
        }
    });
}

function deleteOrderForm() {
    var order_id = parseInt(document.getElementById('order_id').value) || 0;
    if (!order_id || !confirm('Bu siparişi silmek istediğinizden emin misiniz?')) return;
    $.ajax({
        url: '/order/form/delete_order.cfm', method: 'POST',
        data: { order_id: order_id }, dataType: 'json',
        success: function(res) {
            if (res.success) window.location.href = 'index.cfm?fuseaction=order.list_orders';
            else alert('Silme hatası: ' + (res.message || ''));
        }
    });
}

function escHtml(str) {
    return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    /* Firma arama */
    var companySearch = document.getElementById('companySearch');
    var companyDd     = document.getElementById('companyDropdown');
    companySearch.addEventListener('focus', function(){ loadCompanies(); });
    companySearch.addEventListener('input', function(){
        var q = this.value.toLowerCase().trim();
        companyDd.innerHTML = '';
        if (!q) { companyDd.classList.add('d-none'); return; }
        positionDropdown(companySearch, companyDd);
        var matches = allCompanies.filter(function(c){ return (c.display_name||'').toLowerCase().includes(q); }).slice(0, 10);
        if (!matches.length) { companyDd.classList.add('d-none'); return; }
        matches.forEach(function(c){
            var div = document.createElement('div');
            div.className = 'search-item';
            div.textContent = c.display_name || '';
            div.addEventListener('click', function(){ selectCompany(c); });
            companyDd.appendChild(div);
        });
        companyDd.classList.remove('d-none');
    });
    loadCompanies();

    /* Alış/Satış toggle değişince fiyat listesini yeniden yükle */
    document.querySelectorAll('input[name="purchase_sales"]').forEach(function(radio) {
        radio.addEventListener('change', function() {
            var companyId = parseInt(document.getElementById('company_id').value) || 0;
            if (!companyId) return;
            var isSales = this.value === 'true';
            $.ajax({
                url: '/company/cfc/company.cfc',
                method: 'GET',
                data: { method: 'getCompanyRisk', company_id: companyId },
                dataType: 'json',
                success: function(res) {
                    var d = res.data || res;
                    var catId = isSales ? (d.price_cat || 0) : (d.price_cat_purchase || 0);
                    companyPriceMap = {};
                    if (catId > 0) loadCompanyPrices(catId);
                }
            });
        });
    });

    /* Stok arama */
    document.getElementById('stockSearch').addEventListener('input', function(){ showStockDropdown(this.value); });

    /* Dropdown dışına tıklama */
    document.addEventListener('click', function(e){
        if (!companySearch.contains(e.target) && !companyDd.contains(e.target)) companyDd.classList.add('d-none');
        var sDd = document.getElementById('stockSearchDropdown');
        if (!document.getElementById('stockSearch').contains(e.target) && !sDd.contains(e.target)) sDd.classList.add('d-none');
    });

    /* Enter ile satır ekle */
    document.getElementById('addPrice').addEventListener('keydown', function(e){ if (e.key === 'Enter') addRowToGrid(); });

    /* DevExpress Grid */
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        rowGrid = $('##orderRowGrid').dxDataGrid({
            dataSource: orderRows.map(function(r, i){ return Object.assign({}, r, {_idx: i}); }),
            showBorders: true, showRowLines: true, rowAlternationEnabled: true,
            columnAutoWidth: true,
            editing: {
                mode: 'cell',
                allowUpdating: true,
                allowDeleting: false
            },
            onRowUpdated: function(e) {
                var idx = e.data._idx;
                if (idx !== undefined && orderRows[idx]) {
                    Object.assign(orderRows[idx], {
                        quantity:   e.data.quantity,
                        price:      e.data.price,
                        tax:        e.data.tax,
                        discount_1: e.data.discount_1,
                        lot_no:     e.data.lot_no
                    });
                    /* net güncelle */
                    var q  = parseFloat(orderRows[idx].quantity)   || 0;
                    var p  = parseFloat(orderRows[idx].price)      || 0;
                    var t  = parseFloat(orderRows[idx].tax)        || 0;
                    var d  = parseFloat(orderRows[idx].discount_1) || 0;
                    var g  = q * p;
                    orderRows[idx].nettotal = g * (1 - d/100) * (1 + t/100);
                    calcTotals();
                }
            },
            columns: [
                { dataField: 'product_name', caption: 'Ürün', minWidth: 180, allowEditing: false },
                { dataField: 'quantity',   caption: 'Miktar',   width: 90, dataType: 'number', format: { type:'fixedPoint', precision:3 } },
                { dataField: 'price',      caption: 'Fiyat',    width: 110, dataType: 'number', format: { type:'fixedPoint', precision:2 }, alignment:'right' },
                { dataField: 'discount_1', caption: 'İnd. %',   width: 75, dataType: 'number' },
                { dataField: 'tax',        caption: 'KDV %',    width: 75, dataType: 'number' },
                { dataField: 'nettotal',   caption: 'Net',      width: 110, dataType: 'number', format: { type:'fixedPoint', precision:2 }, allowEditing: false, alignment:'right',
                    cellTemplate: function(c,o){ $('<strong>').text((parseFloat(o.value)||0).toLocaleString('tr-TR',{minimumFractionDigits:2})).appendTo(c); }
                },
                { dataField: 'unit',   caption: 'Birim', width: 70, allowEditing: true },
                { dataField: 'lot_no', caption: 'Lot No', width: 100, allowEditing: true },
                {
                    caption: 'Sil', width: 65, alignment: 'center', allowSorting: false, allowFiltering: false, allowEditing: false,
                    cellTemplate: function(c, o) {
                        $('<button>').addClass('btn btn-sm btn-outline-danger').html('<i class="fas fa-trash"></i>')
                            .on('click', function(){ removeRow(o.data._idx); }).appendTo(c);
                    }
                }
            ],
            onContentReady: function(e) {
                document.getElementById('rowCount').textContent = orderRows.length + ' satır';
            }
        }).dxDataGrid('instance');
    }

    calcTotals();
});
</script>
</cfoutput>
