<cfprocessingdirective pageEncoding="utf-8">

<!--- Popup modunda mı kontrol et --->
<cfparam name="url.popup" default="0">
<cfset isPopup = val(url.popup) eq 1>

<!--- jQuery yükleme kontrolü (index.cfm window_type popup/ajaxpage ise jQuery yüklenmez) --->
<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<cfif not isPopup>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-tags"></i>
        </div>
        <div class="page-header-title">
            <h1>Yeni Marka Ekle</h1>
            <p>Sisteme yeni marka ekleyin</p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=product.list_product_brands" class="btn-back">
        <i class="fas fa-list"></i>Marka Listesi
    </a>
</div>
</cfif>

<div class="px-3 pb-4">
    <div class="row justify-content-center">
        <div class="col-lg-8">
            <div class="grid-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title">
                        <i class="fas fa-tags"></i>Marka Bilgileri
                    </div>
                </div>
                <div class="p-4">
                    <form id="brandForm">

                        <!--- Temel Bilgiler --->
                        <div class="mb-1 pb-2" style="border-bottom:1px solid #eef1f6;">
                            <div class="grid-card-header-title mb-3">
                                <i class="fas fa-info-circle"></i>Temel Bilgiler
                            </div>
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <label for="brand_name" class="form-label required-field">Marka Adı</label>
                                    <input type="text" class="form-control" id="brand_name" name="brand_name" required placeholder="Marka adını giriniz">
                                </div>
                                <div class="col-md-6">
                                    <label for="brand_code" class="form-label">Marka Kodu</label>
                                    <input type="text" class="form-control" id="brand_code" name="brand_code" placeholder="Marka kodu (opsiyonel)">
                                </div>
                                <div class="col-12">
                                    <label for="detail" class="form-label">Detay</label>
                                    <textarea class="form-control" id="detail" name="detail" rows="3" placeholder="Marka detayı"></textarea>
                                </div>
                            </div>
                        </div>

                        <!--- Durum ve Özellikler --->
                        <div class="mt-4 mb-4">
                            <div class="grid-card-header-title mb-3">
                                <i class="fas fa-cog"></i>Durum ve Özellikler
                            </div>
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="is_active" name="is_active" value="1" checked>
                                        <label class="form-check-label form-label mb-0" for="is_active">
                                            <i class="fas fa-power-off me-1"></i>Marka Aktif
                                        </label>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="is_internet" name="is_internet" value="1">
                                        <label class="form-check-label form-label mb-0" for="is_internet">
                                            <i class="fas fa-globe me-1"></i>İnternet Satış
                                        </label>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!--- Butonlar --->
                        <div class="d-flex justify-content-between align-items-center pt-3" style="border-top:1px solid #eef1f6;">
                            <button type="button" class="btn btn-light btn-sm" onclick="this.closest('form').reset()">
                                <i class="fas fa-undo me-1"></i>Temizle
                            </button>
                            <div class="d-flex gap-2">
                                <cfif not isPopup>
                                <a href="/index.cfm?fuseaction=product.list_product_brands" class="btn btn-light">
                                    <i class="fas fa-times me-1"></i>İptal
                                </a>
                                </cfif>
                                <button type="submit" class="btn-save">
                                    <i class="fas fa-save"></i>Kaydet
                                </button>
                            </div>
                        </div>

                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
// jQuery yüklenene kadar bekle
if (typeof jQuery === 'undefined') {
    console.error('jQuery yüklenmemiş! Form submit çalışmayabilir.');
}

$(document).ready(function() {
    console.log('Form hazır - jQuery versiyon:', $.fn.jquery);
    
    $('#brandForm').on('submit', function(e) {
        e.preventDefault();
        console.log('Form submit edildi');
        
        var formData = {
            brand_name: $('#brand_name').val(),
            brand_code: $('#brand_code').val(),
            detail: $('#detail').val(),
            is_active: $('#is_active').is(':checked'),
            is_internet: $('#is_internet').is(':checked')
        };
        
        console.log('Gönderilen veri:', formData);
        
        $.ajax({
            url: '/product/cfc/product.cfc?method=saveBrand',
            method: 'POST',
            data: formData,
            dataType: 'json',
            beforeSend: function() {
                console.log('AJAX başlatıldı...');
            },
            success: function(response) {
                console.log('AJAX başarılı:', response);
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
                    
                    <cfif isPopup>
                    // Popup modunda parent'a mesaj gönder
                    setTimeout(function() {
                        if (window.parent) {
                            window.parent.postMessage({
                                type: 'brandAdded',
                                brandId: response.brand_id
                            }, '*');
                        }
                    }, 500);
                    <cfelse>
                    setTimeout(function() {
                        window.location.href = '/index.cfm?fuseaction=product.list_product_brands&success=added';
                    }, 1000);
                    </cfif>
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
            error: function(xhr, status, error) {
                console.error('AJAX hatası:', {xhr: xhr, status: status, error: error});
                console.error('Response:', xhr.responseText);
                if (typeof DevExpress !== 'undefined' && DevExpress.ui) {
                    DevExpress.ui.notify({
                        message: 'Marka kaydedilirken bir hata oluştu! ' + error,
                        type: 'error',
                        displayTime: 5000,
                        position: {
                            my: 'top right',
                            at: 'top right'
                        }
                    });
                } else {
                    alert('Marka kaydedilirken bir hata oluştu! ' + error);
                }
            }
        });
    });
});
</script>