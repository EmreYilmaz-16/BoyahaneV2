<cfprocessingdirective pageEncoding="utf-8">

<!--- jQuery yükleme kontrolü (index.cfm window_type popup/ajaxpage ise jQuery yüklenmez) --->
<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<!--- ID parametresi kontrolü --->
<cfparam name="url.id" default="0">

<cfif val(url.id) eq 0>
    <cflocation url="/index.cfm?fuseaction=product.list_product_brands&error=notfound" addtoken="false">
</cfif>

<!--- Marka bilgilerini getir --->
<cfquery name="getBrand" datasource="boyahane">
    SELECT *
    FROM product_brands
    WHERE brand_id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif getBrand.recordCount eq 0>
    <cflocation url="/index.cfm?fuseaction=product.list_product_brands&error=notfound" addtoken="false">
</cfif>

<style>
    .page-header {
        background: linear-gradient(135deg, #FF9800 0%, #F57C00 100%);
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
        border-left: 3px solid #FF9800;
        padding: 1rem;
        margin-bottom: 1.5rem;
    }
    .form-section h5 {
        color: #FF9800;
        margin-bottom: 1rem;
    }
</style>

<cfoutput>
<div class="page-header">
    <div class="container">
        <div class="row align-items-center">
            <div class="col-md-6">
                <h1><i class="fas fa-edit me-2"></i>Marka Düzenle</h1>
                <p class="mb-0">#getBrand.brand_name#</p>
            </div>
            <div class="col-md-6 text-end">
                <button class="btn btn-light btn-sm" onclick="window.location.href='/index.cfm?fuseaction=product.list_product_brands'">
                    <i class="fas fa-list me-1"></i>Marka Listesi
                </button>
            </div>
        </div>
    </div>
</div>

<div class="container">
    <div class="card shadow-sm">
        <div class="card-body">
            <form id="brandForm" method="post">
                <input type="hidden" id="brand_id" name="brand_id" value="#getBrand.brand_id#">
                
                <!--- Temel Bilgiler --->
                <div class="form-section">
                    <h5><i class="fas fa-info-circle me-2"></i>Temel Bilgiler</h5>
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label for="brand_name" class="form-label">Marka Adı <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="brand_name" name="brand_name" value="#getBrand.brand_name#" required placeholder="Marka adını giriniz">
                        </div>
                        
                        <div class="col-md-6">
                            <label for="brand_code" class="form-label">Marka Kodu</label>
                            <input type="text" class="form-control" id="brand_code" name="brand_code" value="#getBrand.brand_code#" placeholder="Marka kodu (opsiyonel)">
                        </div>
                        
                        <div class="col-12">
                            <label for="detail" class="form-label">Detay</label>
                            <textarea class="form-control" id="detail" name="detail" rows="3" placeholder="Marka detayı">#getBrand.detail#</textarea>
                        </div>
                    </div>
                </div>
                
                <!--- Durum ve Özellikler --->
                <div class="form-section">
                    <h5><i class="fas fa-cog me-2"></i>Durum ve Özellikler</h5>
                    <div class="row g-3">
                        <div class="col-md-6">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="is_active" name="is_active" value="1" <cfif getBrand.is_active>checked</cfif>>
                                <label class="form-check-label" for="is_active">
                                    <i class="fas fa-power-off me-1"></i>Marka Aktif
                                </label>
                            </div>
                        </div>
                        
                        <div class="col-md-6">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="is_internet" name="is_internet" value="1" <cfif getBrand.is_internet>checked</cfif>>
                                <label class="form-check-label" for="is_internet">
                                    <i class="fas fa-globe me-1"></i>İnternet Satış
                                </label>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!--- Kayıt Bilgileri --->
                <div class="form-section">
                    <h5><i class="fas fa-clock me-2"></i>Kayıt Bilgileri</h5>
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label text-muted">Kayıt Tarihi</label>
                            <div class="form-control-plaintext">
                                <cfif isDate(getBrand.record_date)>
                                    #dateFormat(getBrand.record_date, "dd/mm/yyyy")# #timeFormat(getBrand.record_date, "HH:mm")#
                                <cfelse>
                                    -
                                </cfif>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <label class="form-label text-muted">Güncelleme Tarihi</label>
                            <div class="form-control-plaintext">
                                <cfif isDate(getBrand.update_date)>
                                    #dateFormat(getBrand.update_date, "dd/mm/yyyy")# #timeFormat(getBrand.update_date, "HH:mm")#
                                <cfelse>
                                    -
                                </cfif>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!--- Form Butonları --->
                <div class="row">
                    <div class="col-12">
                        <hr>
                        <button type="submit" class="btn btn-primary">
                            <i class="fas fa-save me-1"></i>Güncelle
                        </button>
                        <button type="button" class="btn btn-secondary" onclick="window.location.href='/index.cfm?fuseaction=product.list_product_brands'">
                            <i class="fas fa-times me-1"></i>İptal
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
// jQuery kontrolü
if (typeof jQuery === 'undefined') {
    console.error('jQuery yüklenmemiş!');
} else {
    console.log('jQuery yüklendi, versiyon: ' + jQuery.fn.jquery);
}

$(document).ready(function() {
    console.log('Document ready - Edit Brand Form');
    
    $('##brandForm').on('submit', function(e) {
        e.preventDefault();
        console.log('Form submit eventi tetiklendi');
        
        var formData = {
            brand_id: $('##brand_id').val(),
            brand_name: $('##brand_name').val(),
            brand_code: $('##brand_code').val(),
            detail: $('##detail').val(),
            is_active: $('##is_active').is(':checked'),
            is_internet: $('##is_internet').is(':checked')
        };
        
        console.log('Form data hazırlandı:', formData);
        
        $.ajax({
            url: '/product/cfc/product.cfc?method=saveBrand',
            method: 'POST',
            data: formData,
            dataType: 'json',
            beforeSend: function() {
                console.log('AJAX çağrısı başlatılıyor...');
            },
            success: function(response) {
                console.log('AJAX başarılı yanıt:', response);
                
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
                        window.location.href = '/index.cfm?fuseaction=product.list_product_brands&success=updated';
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
            error: function(xhr, status, error) {
                console.error('AJAX hata!', {
                    xhr: xhr,
                    status: status,
                    error: error,
                    responseText: xhr.responseText
                });
                
                if (typeof DevExpress !== 'undefined' && DevExpress.ui) {
                    DevExpress.ui.notify({
                        message: 'Marka güncellenirken bir hata oluştu!',
                        type: 'error',
                        displayTime: 5000,
                        position: {
                            my: 'top right',
                            at: 'top right'
                        }
                    });
                } else {
                    alert('Marka güncellenirken bir hata oluştu!');
                }
            }
        });
    });
});
</script>
</cfoutput>