<cfprocessingdirective pageEncoding="utf-8">

<!--- jQuery yükleme kontrolü (index.cfm window_type popup/ajaxpage ise jQuery yüklenmez) --->
<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
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


<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-box-open"></i>
        </div>
        <div class="page-header-title">
            <h1>Yeni Ürün Ekle</h1>
            <p>Sisteme yeni ürün ekleyin</p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=product.list_product" class="btn-back">
        <i class="fas fa-arrow-left"></i>Ürün Listesi
    </a>
</div>

<div class="px-3">
    <div class="grid-card">
        <div class="card-body">
            <form id="productForm" method="post">
                <!--- Temel Bilgiler --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Temel Bilgiler</div>
                    </div>
                    <div class="card-body p-3">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label for="product_code" class="form-label">Ürün Kodu</label>
                            <input type="text" class="form-control" id="product_code" name="product_code" placeholder="Ürün kodu (opsiyonel)">
                        </div>
                        
                        <div class="col-md-6">
                            <label for="product_name" class="form-label">Ürün Adı <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="product_name" name="product_name" required placeholder="Ürün adını giriniz">
                        </div>
                        
                        <div class="col-md-6">
                            <label for="product_catid" class="form-label">Kategori <span class="text-danger">*</span></label>
                            <select class="form-select" id="product_catid" name="product_catid" required>
                                <option value="">Kategori Seçiniz</option>
                                <cfoutput query="getCategories">
                                    <option value="#product_catid#">#hierarchy# - #product_cat#</option>
                                </cfoutput>
                            </select>
                        </div>
                        
                        <div class="col-md-6">
                            <label for="barcod" class="form-label">Barkod</label>
                            <input type="text" class="form-control" id="barcod" name="barcod" placeholder="Barkod numarası">
                        </div>
                        
                        <div class="col-md-6">
                            <label for="short_code" class="form-label">Kısa Kod</label>
                            <input type="text" class="form-control" id="short_code" name="short_code" placeholder="Kısa kod">
                        </div>
                        
                        <div class="col-md-6">
                            <label for="manufact_code" class="form-label">Üretici Kodu</label>
                            <input type="text" class="form-control" id="manufact_code" name="manufact_code" placeholder="Üretici kodu">
                        </div>
                        
                        <div class="col-12">
                            <label for="product_detail" class="form-label">Ürün Detayı</label>
                            <textarea class="form-control" id="product_detail" name="product_detail" rows="2" placeholder="Ürün detayı"></textarea>
                        </div>
                        
                        <div class="col-12">
                            <label for="product_detail2" class="form-label">Ürün Detayı 2</label>
                            <textarea class="form-control" id="product_detail2" name="product_detail2" rows="2" placeholder="Ek detay bilgisi"></textarea>
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
                            <input type="number" class="form-control" id="tax" name="tax" value="18" step="0.01" min="0" max="100">
                        </div>
                        
                        <div class="col-md-4">
                            <label for="brand_id" class="form-label">Marka</label>
                            <select class="form-select" id="brand_id" name="brand_id">
                                <option value="0">Marka Seçiniz</option>
                                <cfoutput query="getBrands">
                                    <option value="#brand_id#">#brand_name# <cfif len(trim(brand_code))>(#brand_code#)</cfif></option>
                                </cfoutput>
                            </select>
                            <small class="text-muted">
                                <a href="javascript:void(0)" onclick="openBrandModal()">
                                    <i class="fas fa-plus-circle"></i> Yeni Marka Ekle
                                </a>
                            </small>
                        </div>
                        
                        <div class="col-md-4">
                            <label for="shelf_life" class="form-label">Raf Ömrü</label>
                            <input type="text" class="form-control" id="shelf_life" name="shelf_life" placeholder="Ör: 12 ay">
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
                                <input class="form-check-input" type="checkbox" id="product_status" name="product_status" value="1" checked>
                                <label class="form-check-label" for="product_status">
                                    <i class="fas fa-power-off me-1"></i>Ürün Aktif
                                </label>
                            </div>
                        </div>
                        
                        <div class="col-md-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="is_sales" name="is_sales" value="1" checked>
                                <label class="form-check-label" for="is_sales">
                                    <i class="fas fa-shopping-cart me-1"></i>Satış Yapılabilir
                                </label>
                            </div>
                        </div>
                        
                        <div class="col-md-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="is_purchase" name="is_purchase" value="1" checked>
                                <label class="form-check-label" for="is_purchase">
                                    <i class="fas fa-shopping-basket me-1"></i>Alış Yapılabilir
                                </label>
                            </div>
                        </div>
                        
                        <div class="col-md-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="is_ek_islem" name="is_ek_islem" value="1">
                                <label class="form-check-label" for="is_ek_islem">
                                    <i class="fas fa-tools me-1"></i>Ek İşlem
                                </label>
                            </div>
                        </div>
                    </div>
                </div>

                <!--- Form Butonları --->
                <div class="d-flex justify-content-between align-items-center">
                    <button type="reset" class="btn btn-outline-secondary btn-sm">
                        <i class="fas fa-undo me-1"></i>Formu Temizle
                    </button>
                    <div class="d-flex gap-2">
                        <a href="/index.cfm?fuseaction=product.list_product" class="btn-back">
                            <i class="fas fa-times"></i>İptal
                        </a>
                        <button type="submit" class="btn-save">
                            <i class="fas fa-save"></i>Kaydet
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<!--- Marka Ekleme Modal Popup --->
<div id="brandModal"></div>

<script>
// Marka dropdown'ını yenile
function refreshBrandDropdown(brandId) {
    $.ajax({
        url: '/product/cfc/product.cfc?method=getBrands',
        method: 'GET',
        dataType: 'json',
        success: function(brands) {
            var dropdown = $('#brand_id');
            dropdown.empty();
            dropdown.append('<option value="0">Marka Seçiniz</option>');
            
            $.each(brands, function(index, brand) {
                var optionText = brand.BRAND_NAME;
                if (brand.BRAND_CODE && brand.BRAND_CODE.trim() !== '') {
                    optionText += ' (' + brand.BRAND_CODE + ')';
                }
                dropdown.append('<option value="' + brand.BRAND_ID + '">' + optionText + '</option>');
            });
            
            // Yeni eklenen markayı seç
            if (brandId) {
                dropdown.val(brandId);
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
        brandPopup = $('#brandModal').dxPopup({
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
                    $('#brandModalFrame').attr('src', '/index.cfm?fuseaction=product.add_product_brand_popup');
                }, 100);
            },
            onHiding: function() {
                // Popup kapanınca iframe'i temizle
                $('#brandModalFrame').attr('src', 'about:blank');
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
    $('#productForm').on('submit', function(e) {
        e.preventDefault();
        
        var formData = {
            product_code: $('#product_code').val(),
            product_name: $('#product_name').val(),
            product_catid: $('#product_catid').val(),
            barcod: $('#barcod').val(),
            product_detail: $('#product_detail').val(),
            product_detail2: $('#product_detail2').val(),
            tax: $('#tax').val() || 0,
            brand_id: $('#brand_id').val() || 0,
            shelf_life: $('#shelf_life').val(),
            manufact_code: $('#manufact_code').val(),
            short_code: $('#short_code').val(),
            product_status: $('#product_status').is(':checked'),
            is_sales: $('#is_sales').is(':checked'),
            is_purchase: $('#is_purchase').is(':checked'),
            is_ek_islem: $('#is_ek_islem').is(':checked')
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
                        window.location.href = '/index.cfm?fuseaction=product.list_product&success=added';
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
                        message: 'Ürün kaydedilirken bir hata oluştu!',
                        type: 'error',
                        displayTime: 5000,
                        position: {
                            my: 'top right',
                            at: 'top right'
                        }
                    });
                } else {
                    alert('Ürün kaydedilirken bir hata oluştu!');
                }
            }
        });
    });
});
</script>
