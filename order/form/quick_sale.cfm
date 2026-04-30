<style>
    #cartItems > div > div.d-flex.gap-2.align-items-center > input{
        font-size:8pt !important;
        padding: 5px 6px !important;
        border-radius: 0;

    }
    #productGrid > div > div > div.mt-auto.d-flex.gap-2 > input{
     font-size:8pt !important;
        padding: 5px 6px !important;
        border-radius: 0;
    }
    webkit-scrollbar {
        width: 6px;
        height: 6px;
    }
</style>
<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getPaymethods" datasource="boyahane">
    SELECT paymethod_id, paymethod
    FROM setup_paymethod
    ORDER BY paymethod
</cfquery>

<cfquery name="getMoneys" datasource="boyahane">
    SELECT money_id, money_name
    FROM setup_money
    ORDER BY money_name
</cfquery>

<cfquery name="getShipMethods" datasource="boyahane">
    SELECT ship_method_id, ship_method
    FROM ship_method
    ORDER BY ship_method
</cfquery>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-bolt"></i></div>
        <div class="page-header-title">
            <h1>Hızlı Satış</h1>
            <p>Ürün kartlarından hızlıca sepete ekleyip sipariş oluşturun</p>
        </div>
    </div>
    <a href="index.cfm?fuseaction=order.list_orders" class="btn-back">
        <i class="fas fa-arrow-left"></i>Sipariş Listesi
    </a>
</div>

<div class="px-3 pb-4 quick-sale-wrap">
    <div class="row g-3">
        <div class="col-lg-7">
            <div class="grid-card mb-3">
                <div class="grid-card-header"><div class="grid-card-header-title"><i class="fas fa-filter"></i>Filtreler</div></div>
                <div class="card-body p-3">
                    <div class="row g-2">
                        <div class="col-md-6">
                            <input id="productSearch" type="text" class="form-control" placeholder="Ürün adı / kod / barkod ara...">
                        </div>
                        <div class="col-md-3">
                            <select id="productSort" class="form-select">
                                <option value="name">Ada göre sırala</option>
                                <option value="code">Koda göre sırala</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <button class="btn btn-outline-secondary w-100" type="button" onclick="clearFilters()">
                                <i class="fas fa-eraser me-1"></i>Temizle
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <div id="productGridWrap" style="overflow-y: scroll;height: 66vh;max-height: 66vh;overflow-x: hidden;">
                <div class="text-center text-muted py-4" id="productHint">
                    <i class="fas fa-search me-1"></i>Aramak için en az 2 karakter girin
                </div>
                <div class="row g-3" id="productGrid"></div>
                <div class="text-center py-3" id="loadMoreWrap" style="display:none!important">
                    <button class="btn btn-outline-secondary" id="loadMoreBtn" type="button" onclick="loadMore()">
                        <i class="fas fa-chevron-down me-1"></i>Daha fazla yükle
                    </button>
                </div>
            </div>
        </div>

        <div class="col-lg-5">
            <div class="grid-card mb-3 sticky-top-card">
                <div class="grid-card-header"><div class="grid-card-header-title"><i class="fas fa-user"></i>Müşteri Bilgileri</div></div>
                <div class="card-body p-3">
                    <div class="mb-2">
                        <label class="form-label fw-semibold">Müşteri</label>
                        <div id="company_id_box"></div>
                    </div>
                    <div class="row g-2">
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Ödeme</label>
                            <select id="paymethod" class="form-select">
                                <option value="0">-- Seçin --</option>
                                <cfoutput query="getPaymethods"><option value="#paymethod_id#">#xmlFormat(paymethod)#</option></cfoutput>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Sevk Yöntemi</label>
                            <select id="ship_method" class="form-select">
                                <option value="0">-- Seçin --</option>
                                <cfoutput query="getShipMethods"><option value="#ship_method_id#">#xmlFormat(ship_method)#</option></cfoutput>
                            </select>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Para Birimi</label>
                            <select id="order_currency" class="form-select">
                                <option value="0">-- Seçin --</option>
                                <cfoutput query="getMoneys"><option value="#money_id#">#xmlFormat(money_name)#</option></cfoutput>
                            </select>
                        </div>
                    </div>
                    <div class="mt-2">
                        <label class="form-label fw-semibold">Not</label>
                        <textarea id="order_detail" class="form-control" rows="2" placeholder="Sipariş notu (opsiyonel)"></textarea>
                    </div>
                </div>
            </div>

            <div class="grid-card">
                <div class="grid-card-header d-flex justify-content-between align-items-center">
                    <div class="grid-card-header-title"><i class="fas fa-shopping-basket"></i>Sepet</div>
                    <span class="record-count" id="cartCount">0 ürün</span>
                </div>
                <div class="card-body p-3">
                    <div id="cartItems" class="cart-items" style="overflow-y: scroll;max-height: 30vh;height: 30vh;"></div>
                    <div class="totals-box mt-3">
                        <div><span>Ara Toplam</span><strong id="totalGross">0,00</strong></div>
                        <div><span>KDV</span><strong id="totalTax">0,00</strong></div>
                        <div class="grand"><span>Genel Toplam</span><strong id="totalNet">0,00</strong></div>
                    </div>
                    <button id="saveBtn" type="button" class="btn btn-success w-100 mt-3" onclick="saveQuickOrder()">
                        <i class="fas fa-save me-2"></i>Kaydet ve Sipariş Oluştur
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<style>
.quick-sale-wrap .sticky-top-card { position: sticky; top: 70px; }
.product-card { border:1px solid ##e5e7eb; border-radius:12px; padding:12px; background:##fff; height:100%; display:flex; flex-direction:column; }
.product-meta { color: ##6b7280; font-size: .8rem; line-height: 1.35; }
.product-name { font-weight:700; font-size: .95rem; margin-bottom: 6px; min-height: 38px; }
.cart-row { border-bottom:1px dashed ##e5e7eb; padding:8px 0; }
.cart-row:last-child { border-bottom:none; }
.qty-input { width:72px; }
.totals-box > div { display:flex; justify-content:space-between; margin-bottom:6px; }
.totals-box .grand { font-size:1.06rem; padding-top:8px; border-top:1px solid ##d1d5db; }
@media(max-width:991px){ .quick-sale-wrap .sticky-top-card { position: static; } }
</style>

<script>
var productCache = {};
var currentPage = 1;
var currentSearch = '';
var currentSort = 'name';
var isLoading = false;
var searchTimer = null;
var cart = [];
var currentPriceCat = 0;

function fmt(num) {
    return (num || 0).toLocaleString('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function esc(str) {
    return String(str || '').replace(/[&<>"]/g, function(m){ return ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'})[m]; });
}

function clearFilters() {
    document.getElementById('productSearch').value = '';
    document.getElementById('productSort').value = 'name';
    resetAndSearch();
}

function resetAndSearch() {
    currentPage = 1;
    document.getElementById('productGrid').innerHTML = '';
    document.getElementById('loadMoreWrap').style.display = 'none';
    loadProducts(true);
}

function loadProducts(reset) {
    var search = (document.getElementById('productSearch').value || '').trim();
    var sort   = document.getElementById('productSort').value;
    var hint   = document.getElementById('productHint');
    var grid   = document.getElementById('productGrid');

    if (search.length < 2) {
        grid.innerHTML = '';
        document.getElementById('loadMoreWrap').style.display = 'none';
        hint.style.display = '';
        return;
    }
    hint.style.display = 'none';

    if (reset) { currentPage = 1; currentSearch = search; currentSort = sort; grid.innerHTML = ''; }

    if (isLoading) return;
    isLoading = true;

    var btn = document.getElementById('loadMoreBtn');
    if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Yükleniyor...'; }

    $.getJSON('/order/form/quick_sale_products.cfm', {
        search: search,
        sort: sort,
        page: currentPage,
        price_cat: currentPriceCat
    }, function(res) {
        isLoading = false;
        var items = res.items || [];
        items.forEach(function(p){ productCache[p.stock_id] = p; });

        var noImg = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjEyMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cmVjdCB3aWR0aD0iMTAwJSIgaGVpZ2h0PSIxMDAlIiBmaWxsPSIjZjNmNGY2Ii8+PHRleHQgeD0iNTAlIiB5PSI1MCUiIGRvbWluYW50LWJhc2VsaW5lPSJtaWRkbGUiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtc2l6ZT0iMzIiIGZpbGw9IiNkMWQ1ZGIiPuKcoTwvdGV4dD48L3N2Zz4=';
        var html = items.map(function(p){
            var imgSrc   = p.main_image_src || '';
            var imgHtml  = '<div style="height:90px;background:##f8f9fa;border-radius:8px;overflow:hidden;margin-bottom:8px;display:flex;align-items:center;justify-content:center;">'
                + '<img src="' + (imgSrc || noImg) + '" onerror="this.src=\'' + noImg + '\'" '
                + 'style="max-height:90px;max-width:100%;object-fit:contain;"></div>';
            var priceHtml = (p.list_price > 0)
                ? '<div class="product-meta mb-1" style="color:##e67e22;font-weight:600;">Fiyat: ' + fmt(p.list_price) + '</div>'
                : '';
            return '<div class="col-xl-4 col-md-6">'
                + '<div class="product-card">'
                + imgHtml
                + '<div class="product-name">' + esc(p.product_name) + '</div>'
                + '<div class="product-meta">Stok: ' + esc(p.stock_code) + '</div>'
                + '<div class="product-meta mb-2">Kod: ' + esc(p.product_code) + (p.barcod ? ' · Barkod: ' + esc(p.barcod) : '') + '</div>'
                + priceHtml
                + '<div class="mt-auto d-flex gap-2">'
                + '  <input type="number" min="1" value="1" class="form-control form-control-sm" id="qty_' + p.stock_id + '">'
                + '  <button class="btn btn-sm btn-primary" onclick="addToCart(' + p.stock_id + ')"><i class="fas fa-cart-plus me-1"></i></button>'
                + '</div>'
                + '</div></div>';
        }).join('');

        grid.insertAdjacentHTML('beforeend', html);
        if (!grid.innerHTML.trim()) {
            grid.innerHTML = '<div class="col-12"><div class="alert alert-light border">Ürün bulunamadı.</div></div>';
        }

        var wrap = document.getElementById('loadMoreWrap');
        if (res.hasMore) {
            wrap.style.cssText = '';
            if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-chevron-down me-1"></i>Daha fazla yükle'; }
        } else {
            wrap.style.display = 'none';
        }
    }).fail(function() {
        isLoading = false;
        if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-chevron-down me-1"></i>Daha fazla yükle'; }
    });
}

function loadMore() {
    currentPage++;
    loadProducts(false);
}

function addToCart(stockId) {
    var p = productCache[stockId];
    if (!p) return;
    var qtyInput = document.getElementById('qty_' + stockId);
    var qty = parseFloat(qtyInput ? qtyInput.value : '1') || 1;
    var existing = cart.find(function(x){ return x.stock_id === stockId; });
    if (existing) {
        existing.quantity += qty;
    } else {
        cart.push({
            stock_id: p.stock_id,
            product_id: p.product_id || 0,
            product_name: p.product_name,
            product_code: p.product_code || '',
            quantity: qty,
            price: p.list_price > 0 ? p.list_price : 0,
            tax: 20,
            discount_1: 0,
            unit: '',
            unit_id: 0,
            lot_no: ''
        });
    }
    renderCart();
}

function updateCart(idx, field, value) {
    if (!cart[idx]) return;
    cart[idx][field] = parseFloat(value) || 0;
    renderCart();
}

function removeCart(idx) {
    cart.splice(idx, 1);
    renderCart();
}

function renderCart() {
    var gross = 0, tax = 0, net = 0;
    var html = cart.map(function(r, idx){
        var rowGross = (r.quantity || 0) * (r.price || 0);
        var rowTax = rowGross * ((r.tax || 0) / 100);
        var rowNet = rowGross + rowTax;
        gross += rowGross; tax += rowTax; net += rowNet;

        return '<div class="cart-row">'
            + '<div class="fw-semibold mb-1">' + esc(r.product_name) + '</div>'
            + '<div class="d-flex gap-2 align-items-center">'
            + ' <input class="form-control form-control-sm qty-input" type="number" step="0.01" min="0.01" value="' + (r.quantity || 0) + '" onchange="updateCart(' + idx + ',\'quantity\',this.value)">'
            + ' <input class="form-control form-control-sm" type="number" step="0.01" min="0" placeholder="Fiyat" value="' + (r.price || 0) + '" onchange="updateCart(' + idx + ',\'price\',this.value)">'
            + ' <input class="form-control form-control-sm" type="number" step="0.01" min="0" placeholder="KDV %" value="' + (r.tax || 0) + '" onchange="updateCart(' + idx + ',\'tax\',this.value)">'
            + ' <button class="btn btn-sm btn-outline-danger" onclick="removeCart(' + idx + ')"><i class="fas fa-trash"></i></button>'
            + '</div>'
            + '<div class="small text-muted mt-1">Satır Toplamı: ' + fmt(rowNet) + '</div>'
            + '</div>';
    }).join('');

    document.getElementById('cartItems').innerHTML = html || '<div class="text-muted">Sepet boş.</div>';
    document.getElementById('cartCount').textContent = cart.length + ' ürün';
    document.getElementById('totalGross').textContent = fmt(gross);
    document.getElementById('totalTax').textContent = fmt(tax);
    document.getElementById('totalNet').textContent = fmt(net);
}

function saveQuickOrder() {
    var companyId = parseInt($("##company_id_box").dxSelectBox("instance").option("value") || 0, 10) || 0;
    if (!companyId) { alert('Lütfen müşteri seçin.'); return; }
    if (!cart.length) { alert('Sepet boş.'); return; }

    var invalid = cart.some(function(r){ return !(parseFloat(r.quantity) > 0) || !(parseFloat(r.price) >= 0); });
    if (invalid) { alert('Sepette miktar/fiyat alanlarını kontrol edin.'); return; }

    var btn = document.getElementById('saveBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url: '/order/form/save_order.cfm',
        method: 'POST',
        dataType: 'json',
        data: {
            order_id: 0,
            purchase_sales: 'true',
            order_stage: 2,
            order_number: '',
            order_head: 'Hızlı Satış',
            ref_no: '',
            order_detail: document.getElementById('order_detail').value || '',
            order_date: new Date().toISOString().slice(0,10),
            deliverdate: '',
            company_id: companyId,
            paymethod: parseInt(document.getElementById('paymethod').value, 10) || 0,
            ship_method: parseInt(document.getElementById('ship_method').value, 10) || 0,
            order_currency: parseInt(document.getElementById('order_currency').value, 10) || 0,
            order_status: '1',
            rows: JSON.stringify(cart)
        },
        success: function(res) {
            if (res && res.success) {
                window.location.href = 'index.cfm?fuseaction=order.add_order&order_id=' + res.order_id;
                return;
            }
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet ve Sipariş Oluştur';
            alert((res && res.message) ? res.message : 'Kayıt sırasında hata oluştu.');
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet ve Sipariş Oluştur';
            alert('Sunucu hatası oluştu.');
        }
    });
}

window.addEventListener('load', function(){
    renderCart();

    // DevExtreme aranabilir müşteri seçici — remote
    $("##company_id_box").dxSelectBox({
        dataSource: new DevExpress.data.DataSource({
            store: new DevExpress.data.CustomStore({
                key: "company_id",
                load: function(loadOptions) {
                    var kw = loadOptions.searchValue || '';
                    if (kw.length < 2) return $.Deferred().resolve([]).promise();
                    return $.getJSON('/order/form/quick_sale_companies.cfm', { keyword: kw });
                },
                byKey: function(key) {
                    if (!key) return $.Deferred().resolve(null).promise();
                    return $.getJSON('/order/form/quick_sale_companies.cfm', { by_id: key })
                        .then(function(data){ return data && data.length ? data[0] : null; });
                }
            }),
            paginate: false
        }),
        valueExpr: "company_id",
        displayExpr: "display_name",
        searchEnabled: true,
        searchExpr: "display_name",
        searchMode: "contains",
        minSearchLength: 2,
        showClearButton: true,
        placeholder: "Firma adı veya kodu yazın...",
        noDataText: "Sonuç bulunamadı.",
        value: null,
        stylingMode: "outlined",
        height: 36,        onValueChanged: function(e) {
            var cid = e.value;
            currentPriceCat = 0;
            if (!cid) return;
            $.getJSON('/order/form/quick_sale_customer_info.cfm', { company_id: cid }, function(res) {
                if (!res || !res.success) return;
                if (res.paymethod_id)   document.getElementById('paymethod').value   = res.paymethod_id;
                if (res.ship_method_id) document.getElementById('ship_method').value = res.ship_method_id;
                currentPriceCat = res.price_cat || 0;
                if (currentSearch.length >= 2) resetAndSearch();
            });
        },        itemTemplate: function(data){
            return $('<div style="display:flex;align-items:center;justify-content:space-between;gap:8px;">').append(
                $('<span>').text(data.display_name),
                data.company_code
                    ? $('<span style="color:##94a3b8;font-size:.75rem;">').text(data.company_code)
                    : null
            );
        }
    });

    document.getElementById('productSearch').addEventListener('input', function(){
        clearTimeout(searchTimer);
        searchTimer = setTimeout(resetAndSearch, 350);
    });
    document.getElementById('productSort').addEventListener('change', resetAndSearch);
});
</script>
</cfoutput>
