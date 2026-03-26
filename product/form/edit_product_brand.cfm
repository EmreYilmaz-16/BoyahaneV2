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

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-edit"></i>
        </div>
        <div class="page-header-title">
            <h1>Marka Düzenle</h1>
            <p>#getBrand.brand_name#</p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=product.list_product_brands" class="btn-back">
        <i class="fas fa-list"></i>Marka Listesi
    </a>
</div>

<div class="px-3 pb-4">
    <div class="row justify-content-center">
        <div class="col-lg-8">
            <div class="grid-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title">
                        <i class="fas fa-tags"></i>Marka Bilgileri
                    </div>
                    <span class="record-count">ID: #getBrand.brand_id#</span>
                </div>
                <div class="p-4">
                    <form id="brandForm">
                        <input type="hidden" id="brand_id" name="brand_id" value="#getBrand.brand_id#">

                        <!--- Temel Bilgiler --->
                        <div class="mb-4 pb-4" style="border-bottom:1px solid ##eef1f6;">
                            <div class="grid-card-header-title mb-3">
                                <i class="fas fa-info-circle"></i>Temel Bilgiler
                            </div>
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <label for="brand_name" class="form-label required-field">Marka Adı</label>
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
                        <div class="mb-4 pb-4" style="border-bottom:1px solid ##eef1f6;">
                            <div class="grid-card-header-title mb-3">
                                <i class="fas fa-cog"></i>Durum ve Özellikler
                            </div>
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="is_active" name="is_active" value="1" <cfif getBrand.is_active>checked</cfif>>
                                        <label class="form-check-label form-label mb-0" for="is_active">
                                            <i class="fas fa-power-off me-1"></i>Marka Aktif
                                        </label>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="is_internet" name="is_internet" value="1" <cfif getBrand.is_internet>checked</cfif>>
                                        <label class="form-check-label form-label mb-0" for="is_internet">
                                            <i class="fas fa-globe me-1"></i>İnternet Satış
                                        </label>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!--- Kayıt Bilgileri --->
                        <div class="mb-4 pb-4" style="border-bottom:1px solid ##eef1f6;">
                            <div class="grid-card-header-title mb-3">
                                <i class="fas fa-clock"></i>Kayıt Bilgileri
                            </div>
                            <div class="row g-3">
                                <div class="col-md-6">
                                    <label class="form-label">Kayıt Tarihi</label>
                                    <div class="form-control-plaintext form-note">
                                        <cfif isDate(getBrand.record_date)>
                                            <i class="fas fa-calendar-alt me-1"></i>#dateFormat(getBrand.record_date, "dd/mm/yyyy")# #timeFormat(getBrand.record_date, "HH:mm")#
                                        <cfelse>-</cfif>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <label class="form-label">Güncelleme Tarihi</label>
                                    <div class="form-control-plaintext form-note">
                                        <cfif isDate(getBrand.update_date)>
                                            <i class="fas fa-calendar-check me-1"></i>#dateFormat(getBrand.update_date, "dd/mm/yyyy")# #timeFormat(getBrand.update_date, "HH:mm")#
                                        <cfelse>-</cfif>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!--- Butonlar --->
                        <div class="d-flex justify-content-end gap-2">
                            <a href="/index.cfm?fuseaction=product.list_product_brands" class="btn btn-light">
                                <i class="fas fa-times me-1"></i>İptal
                            </a>
                            <button type="submit" class="btn-save">
                                <i class="fas fa-save"></i>Güncelle
                            </button>
                        </div>

                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
$(document).ready(function() {
    $('##brandForm').on('submit', function(e) {
        e.preventDefault();

        var formData = {
            brand_id: $('##brand_id').val(),
            brand_name: $('##brand_name').val(),
            brand_code: $('##brand_code').val(),
            detail: $('##detail').val(),
            is_active: $('##is_active').is(':checked'),
            is_internet: $('##is_internet').is(':checked')
        };

        $.ajax({
            url: '/product/cfc/product.cfc?method=saveBrand',
            method: 'POST',
            data: formData,
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    if (typeof DevExpress !== 'undefined' && DevExpress.ui) {
                        DevExpress.ui.notify({ message: response.message, type: 'success', displayTime: 3000, position: { my: 'top right', at: 'top right' } });
                    } else {
                        alert(response.message);
                    }
                    setTimeout(function() {
                        window.location.href = '/index.cfm?fuseaction=product.list_product_brands&success=updated';
                    }, 1000);
                } else {
                    if (typeof DevExpress !== 'undefined' && DevExpress.ui) {
                        DevExpress.ui.notify({ message: response.message, type: 'error', displayTime: 5000, position: { my: 'top right', at: 'top right' } });
                    } else {
                        alert('Hata: ' + response.message);
                    }
                }
            },
            error: function(xhr, status, error) {
                if (typeof DevExpress !== 'undefined' && DevExpress.ui) {
                    DevExpress.ui.notify({ message: 'Marka güncellenirken bir hata oluştu!', type: 'error', displayTime: 5000, position: { my: 'top right', at: 'top right' } });
                } else {
                    alert('Marka güncellenirken bir hata oluştu!');
                }
            }
        });
    });
});
</script>
</cfoutput>