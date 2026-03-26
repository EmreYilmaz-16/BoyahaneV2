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
    <!--- Custom CSS --->
    <link rel="stylesheet" href="/assets/css/custom.css">
    <style>
        body { background-color: var(--content-bg, #f0f4f8); padding: 0; margin: 0; }
    </style>
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


<div class="page-header" style="border-radius:0;">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-tag"></i>
        </div>
        <div class="page-header-title">
            <h1>Yeni Marka Ekle</h1>
        </div>
    </div>
</div>

<div class="px-3 pt-2">
    <!--- Form --->
    <form id="brandForm" method="post">
        <!--- Temel Bilgiler --->
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Temel Bilgiler</div>
            </div>
            <div class="card-body p-3">
            <div class="row g-3">
                <div class="col-md-6">
                    <label for="brand_name" class="form-label required-field">Marka Adı</label>
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
        </div>
        
        <!--- Durum ve Özellikler --->
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-cog"></i>Durum ve Özellikler</div>
            </div>
            <div class="card-body p-3">
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
        </div>
        
        <!--- Form Butonları --->
        <div class="d-flex justify-content-between align-items-center pb-3">
            <button type="reset" class="btn btn-outline-secondary btn-sm">
                <i class="fas fa-undo me-1"></i>Temizle
            </button>
            <button type="submit" class="btn-save">
                <i class="fas fa-save"></i>Kaydet ve Kapat
            </button>
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
    // İlk input'a focus
    $('#brand_name').focus();
    
    $('#brandForm').on('submit', function(e) {
        e.preventDefault();
        
        var formData = {
            brand_name: $('#brand_name').val(),
            brand_code: $('#brand_code').val(),
            detail: $('#detail').val(),
            is_active: $('#is_active').is(':checked'),
            is_internet: $('#is_internet').is(':checked')
        };
        
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
                            window.parent.postMessage({
                                type: 'brandAdded',
                                brandId: response.brand_id,
                                brandName: formData.brand_name
                            }, '*');
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