<cfprocessingdirective pageEncoding="utf-8">
<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Yeni Marka Ekle</title>
    
    <!--- Bootstrap CSS --->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!--- Font Awesome --->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    
    <!--- DevExtreme CSS --->
    <link rel="stylesheet" href="https://cdn3.devexpress.com/jslib/23.2.5/css/dx.common.css">
    <link rel="stylesheet" href="https://cdn3.devexpress.com/jslib/23.2.5/css/dx.light.css">
</head>
<body>

<!--- Popup modunda mı kontrol et - Bu dosya her zaman popup modunda açılır --->
<cfparam name="url.popup" default="1">
<cfset isPopup = true>

<!--- jQuery yükleme kontrolü --->
<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<style>
    body {
        background-color: #f8f9fa;
        padding: 0;
        margin: 0;
    }
    .modal-header-custom {
        background: linear-gradient(135deg, #9C27B0 0%, #7B1FA2 100%);
        color: white;
        padding: 1rem 1.5rem;
        margin: -0.5rem -0.5rem 1rem -0.5rem;
        border-radius: 0.25rem 0.25rem 0 0;
    }
    .modal-header-custom h2 {
        font-size: 1.25rem;
        margin: 0;
        font-weight: 600;
    }
    .form-section {
        background: white;
        border-left: 3px solid #9C27B0;
        padding: 1rem;
        margin-bottom: 1rem;
        border-radius: 0.25rem;
        box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    .form-section h5 {
        color: #9C27B0;
        margin-bottom: 1rem;
        font-size: 1rem;
        font-weight: 600;
    }
    .container-popup {
        padding: 1rem;
        max-width: 100%;
    }
    .btn-primary {
        background: linear-gradient(135deg, #9C27B0 0%, #7B1FA2 100%);
        border: none;
    }
    .btn-primary:hover {
        background: linear-gradient(135deg, #7B1FA2 0%, #6A1B9A 100%);
    }
</style>

<div class="container-popup">
    <!--- Modal Header --->
    <div class="modal-header-custom">
        <h2><i class="fas fa-plus-circle me-2"></i>Yeni Marka Ekle</h2>
    </div>
    
    <!--- Form --->
    <form id="brandForm" method="post">
        <!--- Temel Bilgiler --->
        <div class="form-section">
            <h5><i class="fas fa-info-circle me-2"></i>Temel Bilgiler</h5>
            <div class="row g-3">
                <div class="col-md-6">
                    <label for="brand_name" class="form-label">Marka Adı <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" id="brand_name" name="brand_name" required placeholder="Marka adını giriniz" autofocus>
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
                <button type="submit" class="btn btn-primary btn-lg">
                    <i class="fas fa-save me-1"></i>Kaydet ve Kapat
                </button>
                <button type="reset" class="btn btn-outline-secondary">
                    <i class="fas fa-undo me-1"></i>Temizle
                </button>
            </div>
        </div>
    </form>
</div>

<!--- Bootstrap JS --->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>

<!--- DevExtreme JS --->
<script src="https://cdn3.devexpress.com/jslib/23.2.5/js/dx.all.js"></script>

<!--- DevExtreme Türkçe Lokalizasyon --->
<script src="https://cdn3.devexpress.com/jslib/23.2.5/js/localization/dx.messages.tr.js"></script>

<script>
$(document).ready(function() {
    console.log('Popup form hazır - jQuery:', $.fn.jquery);
    
    // İlk input'a focus
    $('#brand_name').focus();
    
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
                // Submit butonunu disable et
                $('#brandForm button[type="submit"]').prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i>Kaydediliyor...');
            },
            success: function(response) {
                console.log('AJAX başarılı:', response);
                if (response.success) {
                    DevExpress.ui.notify({
                        message: response.message,
                        type: 'success',
                        displayTime: 2000,
                        position: {
                            my: 'top center',
                            at: 'top center'
                        }
                    });
                    
                    // Parent'a mesaj gönder
                    setTimeout(function() {
                        if (window.parent && window.parent !== window) {
                            console.log('Parent window\'a marka eklendi mesajı gönderiliyor, brand_id:', response.brand_id);
                            window.parent.postMessage({
                                type: 'brandAdded',
                                brandId: response.brand_id,
                                brandName: formData.brand_name
                            }, '*');
                        } else {
                            console.warn('Parent window bulunamadı!');
                        }
                    }, 300);
                } else {
                    DevExpress.ui.notify({
                        message: response.message,
                        type: 'error',
                        displayTime: 5000,
                        position: {
                            my: 'top center',
                            at: 'top center'
                        }
                    });
                    
                    // Butonu tekrar aktif et
                    $('#brandForm button[type="submit"]').prop('disabled', false).html('<i class="fas fa-save me-1"></i>Kaydet ve Kapat');
                }
            },
            error: function(xhr, status, error) {
                console.error('AJAX hatası:', {xhr: xhr, status: status, error: error, responseText: xhr.responseText});
                
                DevExpress.ui.notify({
                    message: 'Marka kaydedilirken bir hata oluştu! ' + error,
                    type: 'error',
                    displayTime: 5000,
                    position: {
                        my: 'top center',
                        at: 'top center'
                    }
                });
                
                // Butonu tekrar aktif et
                $('#brandForm button[type="submit"]').prop('disabled', false).html('<i class="fas fa-save me-1"></i>Kaydet ve Kapat');
            }
        });
    });
});
</script>

</body>
</html>