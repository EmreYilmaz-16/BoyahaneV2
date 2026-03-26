<cfprocessingdirective pageEncoding="utf-8">

<!--- jQuery yükleme kontrolü (index.cfm window_type popup/ajaxpage ise jQuery yüklenmez) --->
<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<!--- ID parametresi kontrolü --->
<cfparam name="url.id" default="0">

<cfif val(url.id) eq 0>
    <cflocation url="../display/list_product.cfm?error=notfound" addtoken="false">
</cfif>

<!--- Ürün bilgilerini getir --->
<cfquery name="getProduct" datasource="boyahane">
    SELECT 
        p.*,
        pc.product_cat
    FROM 
        product p
        LEFT JOIN product_cat pc ON p.product_catid = pc.product_catid
    WHERE 
        p.product_id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif getProduct.recordCount eq 0>
    <cflocation url="../display/list_product.cfm?error=notfound" addtoken="false">
</cfif>

<!--- Kategorileri getir --->
<cfquery name="getCategories" datasource="boyahane">
    SELECT product_catid, product_cat, hierarchy
    FROM product_cat
    ORDER BY hierarchy, product_cat
</cfquery>

<!--- Markaları getir --->
<cfquery name="getBrands" datasource="boyahane">
    SELECT brand_id, brand_name, brand_code
    FROM product_brands
    WHERE is_active = true
    ORDER BY brand_name
</cfquery>

<!--- Kurumsal hesapları getir --->
<cfquery name="getCompanies" datasource="boyahane">
    SELECT company_id, COALESCE(NULLIF(trim(nickname),''), NULLIF(trim(fullname),''), 'Firma ##' || company_id::text) AS display_name
    FROM company
    WHERE company_status = true
    ORDER BY display_name
</cfquery>

<!--- Tanımlı birimleri getir (setup_unit) --->
<cfquery name="getSetupUnits" datasource="boyahane">
    SELECT unit_id, unit, unit_code
    FROM setup_unit
    ORDER BY unit
</cfquery>

<!--- Ürüne bağlı birimleri getir --->
<cfquery name="getUnits" datasource="boyahane">
    SELECT product_unit_id, product_unit_status, main_unit, add_unit,
           multiplier, quantity, weight, is_main, is_add_unit, record_date
    FROM product_unit
    WHERE product_id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
    ORDER BY is_main DESC, product_unit_id ASC
</cfquery>

<!--- Ürüne bağlı stokları getir --->
<cfquery name="getStocks" datasource="boyahane">
    SELECT stock_id, stock_code, stock_code_2, property, barcod,
           manufact_code, stock_status, is_main_stock, record_date
    FROM stocks
    WHERE product_id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
    ORDER BY is_main_stock DESC, stock_id ASC
</cfquery>


<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-box-open"></i>
        </div>
        <div class="page-header-title">
            <h1>Ürün Düzenle</h1>
            <p>#getProduct.product_name#</p>
        </div>
    </div>
    <span class="record-count">ID: #getProduct.product_id#</span>
</div>

<div class="px-3">
<div class="row g-3">

<!--- SOL: Ürün Formu (col-9) --->
<div class="col-lg-9">
    <div class="grid-card">
        <div class="card-body">
            <form id="productForm" method="post">
                <input type="hidden" id="product_id" name="product_id" value="#getProduct.product_id#">
                
                <!--- Temel Bilgiler --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Temel Bilgiler</div>
                    </div>
                    <div class="card-body p-3">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label for="product_code" class="form-label">Ürün Kodu</label>
                            <input type="text" class="form-control" id="product_code" name="product_code" value="#getProduct.product_code#" placeholder="Ürün kodu (opsiyonel)">
                        </div>
                        
                        <div class="col-md-6">
                            <label for="product_name" class="form-label">Ürün Adı <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="product_name" name="product_name" value="#getProduct.product_name#" required placeholder="Ürün adını giriniz">
                        </div>
                        
                        <div class="col-md-6">
                            <label for="product_catid" class="form-label">Kategori <span class="text-danger">*</span></label>
                            <select class="form-select" id="product_catid" name="product_catid" required>
                                <option value="">Kategori Seçiniz</option>
                                <cfloop query="getCategories">
                                    <option value="#product_catid#" <cfif getProduct.product_catid eq product_catid>selected</cfif>>#hierarchy# - #product_cat#</option>
                                </cfloop>
                            </select>
                        </div>
                        
                        <div class="col-md-6">
                            <label for="barcod" class="form-label">Barkod</label>
                            <input type="text" class="form-control" id="barcod" name="barcod" value="#getProduct.barcod#" placeholder="Barkod numarası">
                        </div>
                        
                        <div class="col-md-6">
                            <label for="short_code" class="form-label">Kısa Kod</label>
                            <input type="text" class="form-control" id="short_code" name="short_code" value="#getProduct.short_code#" placeholder="Kısa kod">
                        </div>
                        
                        <div class="col-md-6">
                            <label for="manufact_code" class="form-label">Üretici Kodu</label>
                            <input type="text" class="form-control" id="manufact_code" name="manufact_code" value="#getProduct.manufact_code#" placeholder="Üretici kodu">
                        </div>
                        
                        <div class="col-12">
                            <label for="product_detail" class="form-label">Ürün Detayı</label>
                            <textarea class="form-control" id="product_detail" name="product_detail" rows="2" placeholder="Ürün detayı">#getProduct.product_detail#</textarea>
                        </div>
                        
                        <div class="col-12">
                            <label for="product_detail2" class="form-label">Ürün Detayı 2</label>
                            <textarea class="form-control" id="product_detail2" name="product_detail2" rows="2" placeholder="Ek detay bilgisi">#getProduct.product_detail2#</textarea>
                        </div>
                    </div>
                    </div>
                </div>

                <!--- Finansal Bilgiler --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-dollar-sign"></i>Finansal Bilgiler</div>
                    </div>
                    <div class="card-body p-3">
                    <div class="row g-3">
                        <div class="col-md-4">
                            <label for="tax" class="form-label">KDV Oranı (%)</label>
                            <input type="number" class="form-control" id="tax" name="tax" value="#getProduct.tax#" step="0.01" min="0" max="100">
                        </div>
                        
                        <div class="col-md-4">
                            <label for="brand_id" class="form-label">Marka</label>
                            <select class="form-select" id="brand_id" name="brand_id">
                                <option value="0">Marka Seçiniz</option>
                                <cfloop query="getBrands">
                                    <option value="#brand_id#" <cfif getProduct.brand_id eq brand_id>selected</cfif>>#brand_name# <cfif len(trim(brand_code))>(#brand_code#)</cfif></option>
                                </cfloop>
                            </select>
                            <small class="text-muted">
                                <a href="javascript:void(0)" onclick="openBrandModal()">
                                    <i class="fas fa-plus-circle"></i> Yeni Marka Ekle
                                </a>
                            </small>
                        </div>
                        
                        <div class="col-md-4">
                            <label for="shelf_life" class="form-label">Raf Ömrü</label>
                            <input type="text" class="form-control" id="shelf_life" name="shelf_life" value="#getProduct.shelf_life#" placeholder="Ör: 12 ay">
                        </div>
                    </div>
                    </div>
                </div>

                <!--- Durum ve Özellikler --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-cog"></i>Durum ve Özellikler</div>
                    </div>
                    <div class="card-body p-3">
                    <div class="row g-3">
                        <div class="col-md-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="product_status" name="product_status" value="1" <cfif getProduct.product_status>checked</cfif>>
                                <label class="form-check-label" for="product_status">
                                    <i class="fas fa-power-off me-1"></i>Ürün Aktif
                                </label>
                            </div>
                        </div>
                        
                        <div class="col-md-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="is_sales" name="is_sales" value="1" <cfif getProduct.is_sales>checked</cfif>>
                                <label class="form-check-label" for="is_sales">
                                    <i class="fas fa-shopping-cart me-1"></i>Satış Yapılabilir
                                </label>
                            </div>
                        </div>
                        
                        <div class="col-md-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="is_purchase" name="is_purchase" value="1" <cfif getProduct.is_purchase>checked</cfif>>
                                <label class="form-check-label" for="is_purchase">
                                    <i class="fas fa-shopping-basket me-1"></i>Alış Yapılabilir
                                </label>
                            </div>
                        </div>
                    </div>
                    </div>
                </div>

                <!--- Kayıt Bilgileri --->
                <div class="d-flex gap-4 mb-4">
                    <cfif isDate(getProduct.record_date)>
                        <span class="form-note">
                            <i class="fas fa-calendar me-1"></i><strong>Kayıt:</strong>
                            #dateFormat(getProduct.record_date, "dd/mm/yyyy")# #timeFormat(getProduct.record_date, "HH:mm")#
                        </span>
                    </cfif>
                    <cfif isDate(getProduct.update_date)>
                        <span class="form-note">
                            <i class="fas fa-clock me-1"></i><strong>Güncelleme:</strong>
                            #dateFormat(getProduct.update_date, "dd/mm/yyyy")# #timeFormat(getProduct.update_date, "HH:mm")#
                        </span>
                    </cfif>
                </div>
                
                <!--- Form Butonları --->
                <div class="d-flex justify-content-between align-items-center">
                    <a href="/index.cfm?fuseaction=product.list_product" class="btn-back">
                        <i class="fas fa-arrow-left"></i>Ürün Listesi
                    </a>
                    <button type="submit" class="btn-save">
                        <i class="fas fa-save"></i>Güncelle
                    </button>
                </div>
            </form>
        </div>
    </div>

</div>
<!--- /SOL --->

<!--- SAĞ: Birim + Stok Paneli (col-3) --->
<div class="col-lg-3">

    <!--- Kurumsal Hesap Kartı --->
    <div class="grid-card mb-3">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-building"></i>Kurumsal Hesap</div>
        </div>
        <div class="card-body p-3">
            <label class="form-label mb-1">Firma / Hesap</label>
            <select class="form-select form-select-sm" id="company_id" name="company_id">
                <option value="0">-- Hesap Seçilmedi --</option>
                <cfloop query="getCompanies">
                <option value="#company_id#"<cfif val(getProduct.company_id) eq company_id> selected</cfif>>#encodeForHTML(display_name)#</option>
                </cfloop>
            </select>
        </div>
    </div>

    <!--- Birim Kartı --->
    <div class="grid-card mb-3">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-ruler"></i>Ürün Birimleri</div>
            <button class="btn btn-sm btn-primary" onclick="openAddUnitForm()" title="Birim Ekle"><i class="fas fa-plus"></i></button>
        </div>
        <div class="card-body p-0">
            <!--- Birim Ekleme / Düzenleme Formu --->
            <div id="unitFormCard" style="display:none" class="border-bottom p-2 bg-light">
                <input type="hidden" id="uf_unit_id" value="0">
                <div class="mb-2">
                    <label class="form-label mb-1">Ana Birim <span class="text-danger">*</span></label>
                    <select class="form-select form-select-sm" id="uf_main_unit">
                        <option value="">Seçiniz...</option>
                        <cfloop query="getSetupUnits">
                        <option value="#unit#">#unit# (#unit_code#)</option>
                        </cfloop>
                    </select>
                </div>
                <div class="mb-2">
                    <label class="form-label mb-1">Ek Birim</label>
                    <select class="form-select form-select-sm" id="uf_add_unit">
                        <option value="">Yok</option>
                        <cfloop query="getSetupUnits">
                        <option value="#unit#">#unit# (#unit_code#)</option>
                        </cfloop>
                    </select>
                </div>
                <div class="row g-2 mb-2">
                    <div class="col-6">
                        <label class="form-label mb-1">Çarpan</label>
                        <input type="number" class="form-control form-control-sm" id="uf_multiplier" value="1" step="0.001" min="0">
                    </div>
                    <div class="col-6">
                        <label class="form-label mb-1">Miktar</label>
                        <input type="number" class="form-control form-control-sm" id="uf_quantity" value="1" step="0.001" min="0">
                    </div>
                </div>
                <div class="mb-2">
                    <label class="form-label mb-1">Ağırlık (kg)</label>
                    <input type="number" class="form-control form-control-sm" id="uf_weight" step="0.00001" min="0" placeholder="0.00">
                </div>
                <div class="mb-2 d-flex gap-2 flex-wrap">
                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" id="uf_is_main">
                        <label class="form-check-label" for="uf_is_main">Ana</label>
                    </div>
                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" id="uf_is_add_unit">
                        <label class="form-check-label" for="uf_is_add_unit">Ek</label>
                    </div>
                    <div class="form-check form-switch">
                        <input class="form-check-input" type="checkbox" id="uf_unit_status" checked>
                        <label class="form-check-label" for="uf_unit_status">Aktif</label>
                    </div>
                </div>
                <div class="d-flex gap-2">
                    <button class="btn btn-secondary btn-sm flex-fill" onclick="closeUnitForm()"><i class="fas fa-times"></i> İptal</button>
                    <button class="btn btn-primary btn-sm flex-fill" onclick="saveUnit()"><i class="fas fa-save"></i> Kaydet</button>
                </div>
            </div>
            <!--- Birim Listesi --->
            <div id="unitList">
                <cfif getUnits.recordCount eq 0>
                    <p class="text-muted text-center py-3 mb-0" id="noUnitMsg"><i class="fas fa-info-circle"></i> Henüz birim yok</p>
                </cfif>
                <cfloop query="getUnits">
                <div class="border-bottom px-2 py-2" id="unitRow_#product_unit_id#">
                    <div class="d-flex justify-content-between align-items-center">
                        <div>
                            <span class="fw-bold">#main_unit#</span>
                            <cfif is_main><span class="badge bg-success ms-1"><i class="fas fa-star"></i></span></cfif>
                            <cfif len(trim(add_unit))><small class="text-muted"> / #add_unit#</small></cfif>
                            <div><small class="text-muted">x#multiplier# &nbsp; #quantity# adet<cfif len(trim(weight))> &nbsp; #weight#kg</cfif></small></div>
                        </div>
                        <div class="d-flex gap-1">
                            <cfif not product_unit_status><span class="badge bg-secondary">Pasif</span></cfif>
                            <button class="btn btn-xs btn-outline-primary p-0" style="width:22px;height:22px;font-size:10px" onclick="editUnit(#product_unit_id#)"><i class="fas fa-edit"></i></button>
                            <button class="btn btn-xs btn-outline-danger p-0" style="width:22px;height:22px;font-size:10px" onclick="deleteUnit(#product_unit_id#,'#jsStringFormat(main_unit)#')"><i class="fas fa-trash"></i></button>
                        </div>
                    </div>
                </div>
                </cfloop>
            </div>
        </div>
    </div>

    <!--- Stok Kartı --->
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-boxes"></i>Stoklar</div>
            <button class="btn btn-sm btn-primary" onclick="openAddStockForm()" title="Stok Ekle">
                <i class="fas fa-plus"></i>
            </button>
        </div>
        <div class="card-body p-2" id="stockListContainer">
            <cfif getStocks.recordCount eq 0>
                <p class="text-muted text-center py-3" id="noStockMsg"><i class="fas fa-info-circle"></i> Henüz stok yok</p>
            </cfif>
            <div id="stockList">
            <cfloop query="getStocks">
                <div class="stock-item border rounded p-2 mb-2" id="stockItem_#stock_id#">
                    <div class="d-flex justify-content-between align-items-start">
                        <div style="flex:1;min-width:0">
                            <div class="fw-bold text-truncate" title="#stock_code#">#stock_code#</div>
                            <cfif len(trim(property))><small class="text-muted d-block text-truncate">#property#</small></cfif>
                            <cfif len(trim(barcod))><small class="text-muted d-block"><i class="fas fa-barcode"></i> #barcod#</small></cfif>
                        </div>
                        <div class="d-flex gap-1 ms-1">
                            <cfif is_main_stock><span class="badge bg-success" title="Ana Stok"><i class="fas fa-star"></i></span></cfif>
                            <cfif not stock_status><span class="badge bg-secondary">Pasif</span></cfif>
                            <button class="btn btn-xs btn-outline-primary p-0" style="width:22px;height:22px;font-size:10px" title="Düzenle" onclick="editStock(#stock_id#)">
                                <i class="fas fa-edit"></i>
                            </button>
                            <button class="btn btn-xs btn-outline-danger p-0" style="width:22px;height:22px;font-size:10px" title="Sil" onclick="deleteStock(#stock_id#,'#jsStringFormat(stock_code)#')">
                                <i class="fas fa-trash"></i>
                            </button>
                        </div>
                    </div>
                </div>
            </cfloop>
            </div>
        </div>
    </div>

    <!--- Stok Ekleme / Düzenleme Formu --->
    <div class="grid-card mt-3" id="stockFormCard" style="display:none">
        <div class="grid-card-header">
            <div class="grid-card-header-title" id="stockFormTitle"><i class="fas fa-plus-circle"></i>Stok Ekle</div>
            <button class="btn btn-sm btn-secondary" onclick="closeStockForm()" title="Kapat"><i class="fas fa-times"></i></button>
        </div>
        <div class="card-body p-3">
            <input type="hidden" id="sf_stock_id" value="0">
            <input type="hidden" id="sf_product_id" value="#url.id#">
            <div class="mb-2">
                <label class="form-label mb-1">Stok Kodu <span class="text-danger">*</span></label>
                <input type="text" class="form-control form-control-sm" id="sf_stock_code" placeholder="Stok kodu">
            </div>
            <div class="mb-2">
                <label class="form-label mb-1">Stok Kodu 2</label>
                <input type="text" class="form-control form-control-sm" id="sf_stock_code_2" placeholder="Alternatif kod">
            </div>
            <div class="mb-2">
                <label class="form-label mb-1">Özellik / Varyant</label>
                <input type="text" class="form-control form-control-sm" id="sf_property" placeholder="Renk, beden vb.">
            </div>
            <div class="mb-2">
                <label class="form-label mb-1">Barkod</label>
                <input type="text" class="form-control form-control-sm" id="sf_barcod" placeholder="Barkod">
            </div>
            <div class="mb-2">
                <label class="form-label mb-1">Üretici Kodu</label>
                <input type="text" class="form-control form-control-sm" id="sf_manufact_code" placeholder="Üretici kodu">
            </div>
            <div class="mb-2 d-flex gap-3">
                <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" id="sf_stock_status" checked>
                    <label class="form-check-label" for="sf_stock_status">Aktif</label>
                </div>
                <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" id="sf_is_main_stock">
                    <label class="form-check-label" for="sf_is_main_stock">Ana Stok</label>
                </div>
            </div>
            <button class="btn btn-primary btn-sm w-100" onclick="saveStock()">
                <i class="fas fa-save"></i> Kaydet
            </button>
        </div>
    </div>
</div>
<!--- /SAĞ --->

</div><!--- /row --->
</div><!--- /px-3 --->

<!--- Marka Ekleme Modal Popup --->
<div id="brandModal"></div>

<script>
var PRODUCT_ID = #url.id#;

// ==================== STOK FONKSİYONLARI ====================

function openAddStockForm() {
    $('##sf_stock_id').val('0');
    $('##sf_stock_code').val('');
    $('##sf_stock_code_2').val('');
    $('##sf_property').val('');
    $('##sf_barcod').val('');
    $('##sf_manufact_code').val('');
    $('##sf_stock_status').prop('checked', true);
    $('##sf_is_main_stock').prop('checked', false);
    $('##stockFormTitle').html('<i class="fas fa-plus-circle"></i> Stok Ekle');
    $('##stockFormCard').show();
    $('html, body').animate({ scrollTop: $('##stockFormCard').offset().top - 20 }, 300);
}

function closeStockForm() {
    $('##stockFormCard').hide();
}

function editStock(stockId) {
    $.ajax({
        url: '/product/cfc/product.cfc?method=getStocksByProduct',
        method: 'GET',
        data: { product_id: PRODUCT_ID },
        dataType: 'json',
        success: function(res) {
            if (!res.success) return;
            var stock = null;
            $.each(res.data, function(i, s) { if (s.stock_id == stockId) { stock = s; return false; } });
            if (!stock) return;
            $('##sf_stock_id').val(stock.stock_id);
            $('##sf_stock_code').val(stock.stock_code);
            $('##sf_stock_code_2').val(stock.stock_code_2);
            $('##sf_property').val(stock.property);
            $('##sf_barcod').val(stock.barcod);
            $('##sf_manufact_code').val(stock.manufact_code);
            $('##sf_stock_status').prop('checked', stock.stock_status);
            $('##sf_is_main_stock').prop('checked', stock.is_main_stock);
            $('##stockFormTitle').html('<i class="fas fa-edit"></i> Stok Düzenle');
            $('##stockFormCard').show();
            $('html, body').animate({ scrollTop: $('##stockFormCard').offset().top - 20 }, 300);
        }
    });
}

function saveStock() {
    var stockCode = $.trim($('##sf_stock_code').val());
    if (!stockCode) {
        if (typeof DevExpress !== 'undefined') {
            DevExpress.ui.notify({ message: 'Stok kodu boş olamaz!', type: 'warning', displayTime: 2500 });
        } else { alert('Stok kodu boş olamaz!'); }
        return;
    }

    var data = {
        stock_id:      $('##sf_stock_id').val(),
        product_id:    PRODUCT_ID,
        stock_code:    stockCode,
        stock_code_2:  $('##sf_stock_code_2').val(),
        property:      $('##sf_property').val(),
        barcod:        $('##sf_barcod').val(),
        manufact_code: $('##sf_manufact_code').val(),
        stock_status:  $('##sf_stock_status').is(':checked'),
        is_main_stock: $('##sf_is_main_stock').is(':checked')
    };

    $.ajax({
        url: '/product/cfc/product.cfc?method=saveStock',
        method: 'POST',
        data: data,
        dataType: 'json',
        success: function(res) {
            if (res.success) {
                if (typeof DevExpress !== 'undefined') {
                    DevExpress.ui.notify({ message: res.message, type: 'success', displayTime: 2500 });
                }
                closeStockForm();
                refreshStockList();
            } else {
                if (typeof DevExpress !== 'undefined') {
                    DevExpress.ui.notify({ message: res.message, type: 'error', displayTime: 4000 });
                } else { alert(res.message); }
            }
        },
        error: function() {
            if (typeof DevExpress !== 'undefined') {
                DevExpress.ui.notify({ message: 'Stok kaydedilirken hata oluştu!', type: 'error', displayTime: 4000 });
            }
        }
    });
}

function deleteStock(stockId, stockCode) {
    var doDelete = function() {
        $.ajax({
            url: '/product/cfc/product.cfc?method=deleteStock',
            method: 'POST',
            data: { stock_id: stockId, product_id: PRODUCT_ID },
            dataType: 'json',
            success: function(res) {
                if (res.success) {
                    if (typeof DevExpress !== 'undefined') {
                        DevExpress.ui.notify({ message: res.message, type: 'success', displayTime: 2500 });
                    }
                    refreshStockList();
                } else {
                    if (typeof DevExpress !== 'undefined') {
                        DevExpress.ui.notify({ message: res.message, type: 'error', displayTime: 4000 });
                    } else { alert(res.message); }
                }
            }
        });
    };

    if (typeof DevExpress !== 'undefined' && DevExpress.ui && DevExpress.ui.dialog) {
        DevExpress.ui.dialog.confirm('"' + stockCode + '" stokunu silmek istediğinizden emin misiniz?', 'Stok Sil')
            .done(function(ok) { if (ok) doDelete(); });
    } else {
        if (confirm('"' + stockCode + '" stokunu silmek istediğinizden emin misiniz?')) doDelete();
    }
}

function refreshStockList() {
    $.ajax({
        url: '/product/cfc/product.cfc?method=getStocksByProduct',
        method: 'GET',
        data: { product_id: PRODUCT_ID },
        dataType: 'json',
        success: function(res) {
            if (!res.success) return;
            var html = '';
            if (res.data.length === 0) {
                $('##noStockMsg').show();
            } else {
                $('##noStockMsg').hide();
                $.each(res.data, function(i, s) {
                    var badges = '';
                    if (s.is_main_stock) badges += '<span class="badge bg-success" title="Ana Stok"><i class="fas fa-star"></i></span>';
                    if (!s.stock_status) badges += '<span class="badge bg-secondary">Pasif</span>';
                    var propHtml   = s.property      ? '<small class="text-muted d-block text-truncate">' + $('<div>').text(s.property).html()      + '</small>' : '';
                    var barcodHtml = s.barcod         ? '<small class="text-muted d-block"><i class="fas fa-barcode"></i> ' + $('<div>').text(s.barcod).html() + '</small>' : '';
                    html += '<div class="stock-item border rounded p-2 mb-2" id="stockItem_' + s.stock_id + '">' +
                        '<div class="d-flex justify-content-between align-items-start">' +
                            '<div style="flex:1;min-width:0">' +
                                '<div class="fw-bold text-truncate" title="' + $('<div>').text(s.stock_code).html() + '">' + $('<div>').text(s.stock_code).html() + '</div>' +
                                propHtml + barcodHtml +
                            '</div>' +
                            '<div class="d-flex gap-1 ms-1">' +
                                badges +
                                '<button class="btn btn-xs btn-outline-primary p-0" style="width:22px;height:22px;font-size:10px" title="Düzenle" onclick="editStock(' + s.stock_id + ')"><i class="fas fa-edit"></i></button>' +
                                '<button class="btn btn-xs btn-outline-danger p-0" style="width:22px;height:22px;font-size:10px" title="Sil" onclick="deleteStock(' + s.stock_id + ',\'' + s.stock_code.replace(/'/g,"\'") + '\')"><i class="fas fa-trash"></i></button>' +
                            '</div>' +
                        '</div>' +
                    '</div>';
                });
            }
            $('##stockList').html(html);
        }
    });
}

// ==================== BİRİM FONKSİYONLARI ====================

function openAddUnitForm() {
    $('##uf_unit_id').val('0');
    $('##uf_main_unit').val('');
    $('##uf_add_unit').val('');
    $('##uf_multiplier').val('1');
    $('##uf_quantity').val('1');
    $('##uf_weight').val('');
    $('##uf_is_main').prop('checked', false);
    $('##uf_is_add_unit').prop('checked', false);
    $('##uf_unit_status').prop('checked', true);
    $('##unitFormCard').show();
    $('##uf_main_unit').focus();
}

function closeUnitForm() {
    $('##unitFormCard').hide();
}

function editUnit(unitId) {
    $.ajax({
        url: '/product/cfc/product.cfc?method=getUnitsByProduct',
        method: 'GET',
        data: { product_id: PRODUCT_ID },
        dataType: 'json',
        success: function(res) {
            if (!res.success) return;
            var unit = null;
            $.each(res.data, function(i, u) { if (u.product_unit_id == unitId) { unit = u; return false; } });
            if (!unit) return;
            $('##uf_unit_id').val(unit.product_unit_id);
            $('##uf_main_unit').val(unit.main_unit);
            $('##uf_add_unit').val(unit.add_unit);
            $('##uf_multiplier').val(unit.multiplier);
            $('##uf_quantity').val(unit.quantity);
            $('##uf_weight').val(unit.weight || '');
            $('##uf_is_main').prop('checked', unit.is_main);
            $('##uf_is_add_unit').prop('checked', unit.is_add_unit);
            $('##uf_unit_status').prop('checked', unit.product_unit_status);
            $('##unitFormCard').show();
            $('html, body').animate({ scrollTop: $('##unitFormCard').offset().top - 80 }, 300);
        }
    });
}

function saveUnit() {
    var mainUnit = $.trim($('##uf_main_unit').val());
    if (!mainUnit) {
        if (typeof DevExpress !== 'undefined') {
            DevExpress.ui.notify({ message: 'Ana birim boş olamaz!', type: 'warning', displayTime: 2500 });
        } else { alert('Ana birim boş olamaz!'); }
        return;
    }
    var data = {
        unit_id:            $('##uf_unit_id').val(),
        product_id:         PRODUCT_ID,
        main_unit:          mainUnit,
        add_unit:           $('##uf_add_unit').val(),
        multiplier:         $('##uf_multiplier').val() || 1,
        quantity:           $('##uf_quantity').val() || 1,
        weight:             $('##uf_weight').val() || '',
        is_main:            $('##uf_is_main').is(':checked'),
        is_add_unit:        $('##uf_is_add_unit').is(':checked'),
        product_unit_status: $('##uf_unit_status').is(':checked')
    };
    $.ajax({
        url: '/product/cfc/product.cfc?method=saveUnit',
        method: 'POST',
        data: data,
        dataType: 'json',
        success: function(res) {
            if (res.success) {
                if (typeof DevExpress !== 'undefined') DevExpress.ui.notify({ message: res.message, type: 'success', displayTime: 2500 });
                closeUnitForm();
                refreshUnitList();
            } else {
                if (typeof DevExpress !== 'undefined') { DevExpress.ui.notify({ message: res.message, type: 'error', displayTime: 4000 }); } else { alert(res.message); }
            }
        },
        error: function() {
            if (typeof DevExpress !== 'undefined') DevExpress.ui.notify({ message: 'Birim kaydedilirken hata oluştu!', type: 'error', displayTime: 4000 });
        }
    });
}

function deleteUnit(unitId, mainUnit) {
    var doDelete = function() {
        $.ajax({
            url: '/product/cfc/product.cfc?method=deleteUnit',
            method: 'POST',
            data: { unit_id: unitId, product_id: PRODUCT_ID },
            dataType: 'json',
            success: function(res) {
                if (res.success) {
                    if (typeof DevExpress !== 'undefined') DevExpress.ui.notify({ message: res.message, type: 'success', displayTime: 2500 });
                    refreshUnitList();
                } else {
                    if (typeof DevExpress !== 'undefined') { DevExpress.ui.notify({ message: res.message, type: 'error', displayTime: 4000 }); } else { alert(res.message); }
                }
            }
        });
    };
    if (typeof DevExpress !== 'undefined' && DevExpress.ui && DevExpress.ui.dialog) {
        DevExpress.ui.dialog.confirm('"' + mainUnit + '" birimini silmek istediğinizden emin misiniz?', 'Birim Sil')
            .done(function(ok) { if (ok) doDelete(); });
    } else {
        if (confirm('"' + mainUnit + '" birimini silmek istediğinizden emin misiniz?')) doDelete();
    }
}

function refreshUnitList() {
    $.ajax({
        url: '/product/cfc/product.cfc?method=getUnitsByProduct',
        method: 'GET',
        data: { product_id: PRODUCT_ID },
        dataType: 'json',
        success: function(res) {
            if (!res.success) return;
            var html = '';
            if (res.data.length === 0) {
                html = '<p class="text-muted text-center py-3 mb-0" id="noUnitMsg"><i class="fas fa-info-circle"></i> Henüz birim yok</p>';
            } else {
                $.each(res.data, function(i, u) {
                    var mainBadge   = u.is_main ? '<span class="badge bg-success ms-1"><i class="fas fa-star"></i></span>' : '';
                    var addUnit     = u.add_unit ? ' / ' + $('<div>').text(u.add_unit).html() : '';
                    var weight      = u.weight   ? ' &nbsp; ' + u.weight + 'kg' : '';
                    var statusBadge = !u.product_unit_status ? '<span class="badge bg-secondary">Pasif</span>' : '';
                    var e = function(s) { return $('<div>').text(s || '').html(); };
                    html += '<div class="border-bottom px-2 py-2" id="unitRow_' + u.product_unit_id + '">' +
                        '<div class="d-flex justify-content-between align-items-center">' +
                            '<div>' +
                                '<span class="fw-bold">' + e(u.main_unit) + '</span>' + mainBadge +
                                '<small class="text-muted">' + addUnit + '</small>' +
                                '<div><small class="text-muted">x' + u.multiplier + ' &nbsp; ' + u.quantity + ' adet' + weight + '</small></div>' +
                            '</div>' +
                            '<div class="d-flex gap-1">' +
                                statusBadge +
                                '<button class="btn btn-xs btn-outline-primary p-0" style="width:22px;height:22px;font-size:10px" onclick="editUnit(' + u.product_unit_id + ')"><i class="fas fa-edit"></i></button>' +
                                '<button class="btn btn-xs btn-outline-danger p-0" style="width:22px;height:22px;font-size:10px" onclick="deleteUnit(' + u.product_unit_id + ',\'' + (u.main_unit || '').replace(/'/g, "\\'") + '\')"><i class="fas fa-trash"></i></button>' +
                            '</div>' +
                        '</div>' +
                    '</div>';
                });
            }
            $('##unitList').html(html);
        }
    });
}

// ==================== MARKA FONKSİYONLARI ====================
function refreshBrandDropdown(brandId) {
    $.ajax({
        url: '/product/cfc/product.cfc?method=getBrands',
        method: 'GET',
        dataType: 'json',
        success: function(brands) {
            var dropdown = $('##brand_id');
            var currentValue = dropdown.val();
            dropdown.empty();
            dropdown.append('<option value="0">Marka Seçiniz</option>');
            
            $.each(brands, function(index, brand) {
                var optionText = brand.BRAND_NAME;
                if (brand.BRAND_CODE && brand.BRAND_CODE.trim() !== '') {
                    optionText += ' (' + brand.BRAND_CODE + ')';
                }
                dropdown.append('<option value="' + brand.BRAND_ID + '">' + optionText + '</option>');
            });
            
            // Yeni eklenen markayı seç, yoksa eski değeri koru
            if (brandId) {
                dropdown.val(brandId);
            } else {
                dropdown.val(currentValue);
            }
        },
        error: function(xhr, status, error) {
            console.error('Markalar getirilemedi:', error);
        }
    });
}

// Modal popup'ı aç
var brandPopup;
function openBrandModal() {
    if (!brandPopup) {
        brandPopup = $('##brandModal').dxPopup({
            title: 'Yeni Marka Ekle',
            width: '90%',
            height: '90%',
            contentTemplate: function() {
                return $('<iframe>')
                    .attr('id', 'brandModalFrame')
                    .css({
                        'width': '100%',
                        'height': '100%',
                        'border': 'none'
                    });
            },
            onShowing: function() {
                // Modal her açıldığında iframe'i yeniden yükle
                setTimeout(function() {
                    $('##brandModalFrame').attr('src', '/product/form/add_product_brand_popup.cfm');
                }, 100);
            },
            onHiding: function() {
                // Popup kapanınca iframe'i temizle
                $('##brandModalFrame').attr('src', 'about:blank');
            }
        }).dxPopup('instance');
    }
    
    brandPopup.show();
}

// Child sayfadan mesaj dinle
window.addEventListener('message', function(event) {
    if (event.data && event.data.type === 'brandAdded') {
        // Marka eklendi, dropdown'ı güncelle
        refreshBrandDropdown(event.data.brandId);
        // Popup'u kapat
        if (brandPopup) {
            brandPopup.hide();
        }
    }
});

$(document).ready(function() {
    $('##productForm').on('submit', function(e) {
        e.preventDefault();
        
        var formData = {
            product_id: $('##product_id').val(),
            product_code: $('##product_code').val(),
            product_name: $('##product_name').val(),
            product_catid: $('##product_catid').val(),
            barcod: $('##barcod').val(),
            product_detail: $('##product_detail').val(),
            product_detail2: $('##product_detail2').val(),
            tax: $('##tax').val() || 0,
            brand_id: $('##brand_id').val() || 0,
            shelf_life: $('##shelf_life').val(),
            manufact_code: $('##manufact_code').val(),
            short_code: $('##short_code').val(),
            product_status: $('##product_status').is(':checked'),
            is_sales: $('##is_sales').is(':checked'),
            is_purchase: $('##is_purchase').is(':checked'),
            company_id: $('##company_id').val() || 0
        };
        
        $.ajax({
            url: '/product/cfc/product.cfc?method=saveProduct',
            method: 'POST',
            data: formData,
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    if (typeof DevExpress !== 'undefined' && DevExpress.ui) {
                        DevExpress.ui.notify({
                            message: response.message,
                            type: 'success',
                            displayTime: 3000,
                            position: {
                                my: 'top right',
                                at: 'top right'
                            }
                        });
                    } else {
                        alert(response.message);
                    }
                    
                    setTimeout(function() {
                        window.location.href = '/index.cfm?fuseaction=product.list_products&success=updated';
                    }, 1000);
                } else {
                    if (typeof DevExpress !== 'undefined' && DevExpress.ui) {
                        DevExpress.ui.notify({
                            message: response.message,
                            type: 'error',
                            displayTime: 5000,
                            position: {
                                my: 'top right',
                                at: 'top right'
                            }
                        });
                    } else {
                        alert('Hata: ' + response.message);
                    }
                }
            },
            error: function() {
                if (typeof DevExpress !== 'undefined' && DevExpress.ui) {
                    DevExpress.ui.notify({
                        message: 'Ürün güncellenirken bir hata oluştu!',
                        type: 'error',
                        displayTime: 5000,
                        position: {
                            my: 'top right',
                            at: 'top right'
                        }
                    });
                } else {
                    alert('Ürün güncellenirken bir hata oluştu!');
                }
            }
        });
    });
});
</script>
</cfoutput>
