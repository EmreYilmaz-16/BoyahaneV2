<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getCompanies" datasource="boyahane">
    SELECT company_id,
           COALESCE(nickname, fullname, member_code, 'Firma') AS display_name,
           member_code
    FROM company
    ORDER BY display_name
    LIMIT 500
</cfquery>

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

<cfset companiesData = []>
<cfloop query="getCompanies">
    <cfset arrayAppend(companiesData, {
        "company_id": company_id,
        "display_name": display_name ?: "",
        "company_code": member_code ?: ""
    })>
</cfloop>

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

            <div id="productGridWrap">
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
                        <select id="company_id" class="form-select">
                            <option value="0">-- Firma Seçin --</option>
                            <cfoutput query="getCompanies">
                                <option value="#company_id#">#xmlFormat(display_name)#</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="row g-2">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Ödeme</label>
                            <select id="paymethod" class="form-select">
                                <option value="0">-- Seçin --</option>
                                <cfoutput query="getPaymethods"><option value="#paymethod_id#">#xmlFormat(paymethod)#</option></cfoutput>
                            </select>
                        </div>
                        <div class="col-md-6">
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
                    <div id="cartItems" class="cart-items"></div>
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
        page: currentPage
    }, function(res) {
        isLoading = false;
        var items = res.items || [];
        items.forEach(function(p){ productCache[p.stock_id] = p; });

        var html = items.map(function(p){
            return '<div class="col-xl-4 col-md-6">'
                + '<div class="product-card">'
                + '<div class="product-name">' + esc(p.product_name) + '</div>'
                + '<div class="product-meta">Stok: ' + esc(p.stock_code) + '</div>'
                + '<div class="product-meta mb-2">Kod: ' + esc(p.product_code) + (p.barcod ? ' · Barkod: ' + esc(p.barcod) : '') + '</div>'
                + '<div class="mt-auto d-flex gap-2">'
                + '  <input type="number" min="1" value="1" class="form-control form-control-sm" id="qty_' + p.stock_id + '">'
                + '  <button class="btn btn-sm btn-primary" onclick="addToCart(' + p.stock_id + ')"><i class="fas fa-cart-plus me-1"></i>Sepete Ekle</button>'
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
            price: 0,
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
    var companyId = parseInt(document.getElementById('company_id').value, 10) || 0;
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
            ship_method: 0,
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
    document.getElementById('productSearch').addEventListener('input', function(){
        clearTimeout(searchTimer);
        searchTimer = setTimeout(resetAndSearch, 350);
    });
    document.getElementById('productSort').addEventListener('change', resetAndSearch);
});
</script>
</cfoutput>
