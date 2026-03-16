<cfprocessingdirective pageEncoding="utf-8">

<!--- Popup modunda mı kontrol et --->
<cfparam name="url.popup" default="0">
<cfset isPopup = val(url.popup) eq 1>

<!--- jQuery yükleme kontrolü (index.cfm window_type popup/ajaxpage ise jQuery yüklenmez) --->
<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<style>
    .page-header {
        background: linear-gradient(135deg, #9C27B0 0%, #7B1FA2 100%);
        color: white;
        padding: 1rem 0;
        margin-bottom: 1.5rem;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .page-header h1 {
        font-size: 1.5rem;
        margin-bottom: 0.25rem;
    }
    .form-section {
        background: #f8f9fa;
        border-left: 3px solid #9C27B0;
        padding: 1rem;
        margin-bottom: 1.5rem;
    }
    .form-section h5 {
        color: #9C27B0;
        margin-bottom: 1rem;
    }
</style>

<cfif not isPopup>
<div class="page-header">
    <div class="container">
        <div class="row align-items-center">
            <div class="col-md-6">
                <h1><i class="fas fa-plus-circle me-2"></i>Yeni Marka Ekle</h1>
                <p class="mb-0">Sisteme yeni marka ekleyin</p>
            </div>
            <div class="col-md-6 text-end">
                <button class="btn btn-light btn-sm" onclick="window.location.href='/index.cfm?fuseaction=product.list_product_brands'">
                    <i class="fas fa-list me-1"></i>Marka Listesi
                </button>
            </div>
        </div>
    </div>
</div>
</cfif>

<div class="container">
    <div class="card shadow-sm">
        <div class="card-body">
            <form id="brandForm" method="post">
                <!--- Temel Bilgiler --->
                <div class="form-section">
                    <h5><i class="fas fa-info-circle me-2"></i>Temel Bilgiler</h5>
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label for="brand_name" class="form-label">Marka Adı <span class="text-danger">*</span></label>
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
                <div class="form-section">
                    <h5><i class="fas fa-cog me-2"></i>Durum ve Özellikler</h5>
                    <div class="row g-3">
                        <div class="col-md-6">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="is_active" name="is_active" value="1" checked>
                                <label class="form-check-label" for="is_active">
                                    <i class="fas fa-power-off me-1"></i>Marka Aktif
                                </label>
                            </div>
                        </div>
                        
                        <div class="col-md-6">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="is_internet" name="is_internet" value="1">
                                <label class="form-check-label" for="is_internet">
                                    <i class="fas fa-globe me-1"></i>İnternet Satış
                                </label>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!--- Form Butonları --->
                <div class="row">
                    <div class="col-12">
                        <hr>
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-save me-1"></i>Kaydet
                        </button>
                        <cfif not isPopup>
                            <button type="button" class="btn btn-secondary" onclick="window.location.href='/index.cfm?fuseaction=product.list_product_brands'">
                                <i class="fas fa-times me-1"></i>İptal
                            </button>
                        </cfif>
                        <button type="reset" class="btn btn-warning">
                            <i class="fas fa-undo me-1"></i>Formu Temizle
                        </button>
                    </div>
                </div>
            </form>
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
            url: '../cfc/product.cfc?method=saveBrand',
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