<cfprocessingdirective pageEncoding="utf-8">

<!--- jQuery yükleme kontrolü (index.cfm window_type popup/ajaxpage ise jQuery yüklenmez) --->
<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<!--- Form submit edildi mi kontrol et --->
<cfif structKeyExists(form, "submit")>
    <cfparam name="form.hierarchy" default="">
    <cfparam name="form.product_cat" default="">
    <cfparam name="form.detail" default="">
    
    <!--- Kategori adı zorunlu --->
    <cfif trim(form.product_cat) eq "">
        <cfset errorMsg = "Kategori adı zorunludur!">
    <cfelse>
        <!--- Kategori ekle --->
        <cftry>
            <cfquery datasource="boyahane">
                INSERT INTO product_cat (
                    hierarchy,
                    product_cat,
                    detail,
                    record_date,
                    record_emp,
                    record_emp_ip
                )
                VALUES (
                    <cfqueryparam value="#trim(form.hierarchy)#" cfsqltype="cf_sql_varchar" null="#trim(form.hierarchy) eq ''#">,
                    <cfqueryparam value="#trim(form.product_cat)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(form.detail)#" cfsqltype="cf_sql_varchar" null="#trim(form.detail) eq ''#">,
                    <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer" null="#not structKeyExists(session, 'user')#">,
                    <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                )
            </cfquery>
            
            <!--- Başarılı --->
            <cflocation url="#cgi.script_name#?fuseaction=product.list_product_cat&success=added" addtoken="false">
            <cfabort>
            
            <cfcatch type="any">
                <cfset errorMsg = "Kategori eklenirken bir hata oluştu: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-layer-group"></i>
        </div>
        <div class="page-header-title">
            <h1>Yeni Kategori Ekle</h1>
            <p>Ürün kategorisi bilgilerini doldurun</p>
        </div>
    </div>
    <a href="<cfoutput>#cgi.script_name#?fuseaction=product.list_product_cat</cfoutput>" class="btn-back">
        <i class="fas fa-arrow-left"></i>Geri Dön
    </a>
</div>

<div class="px-3 pb-4">
    <div class="row justify-content-center">
        <div class="col-lg-7">

            <!--- Hata mesajı --->
            <cfif isDefined("errorMsg")>
                <div class="alert alert-danger alert-dismissible fade show mb-3" role="alert">
                    <i class="fas fa-exclamation-circle me-2"></i>
                    <cfoutput>#errorMsg#</cfoutput>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            </cfif>

            <div class="grid-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title">
                        <i class="fas fa-layer-group"></i>Kategori Bilgileri
                    </div>
                </div>
                <div class="p-4">
                    <form method="post" action="<cfoutput>#cgi.script_name#?fuseaction=product.add_product_cat</cfoutput>" id="categoryForm">

                        <div class="mb-4">
                            <label for="hierarchy" class="form-label">
                                <i class="fas fa-sitemap me-1"></i>Hiyerarşi
                            </label>
                            <input type="text"
                                   class="form-control"
                                   id="hierarchy"
                                   name="hierarchy"
                                   placeholder="Örn: 01, 01.01, 01.01.01"
                                   value="<cfif isDefined('form.hierarchy')><cfoutput>#form.hierarchy#</cfoutput></cfif>">
                            <div class="form-note">Kategori hiyerarşisini belirtir (isteğe bağlı)</div>
                        </div>

                        <div class="mb-4">
                            <label for="product_cat" class="form-label required-field">
                                <i class="fas fa-tag me-1"></i>Kategori Adı
                            </label>
                            <input type="text"
                                   class="form-control"
                                   id="product_cat"
                                   name="product_cat"
                                   required
                                   placeholder="Kategori adını girin"
                                   value="<cfif isDefined('form.product_cat')><cfoutput>#form.product_cat#</cfoutput></cfif>">
                        </div>

                        <div class="mb-4">
                            <label for="detail" class="form-label">
                                <i class="fas fa-align-left me-1"></i>Detay
                            </label>
                            <textarea class="form-control"
                                      id="detail"
                                      name="detail"
                                      rows="3"
                                      placeholder="Kategori hakkında ek bilgiler"><cfif isDefined('form.detail')><cfoutput>#form.detail#</cfoutput></cfif></textarea>
                        </div>

                        <div class="alert alert-info mb-4">
                            <i class="fas fa-info-circle me-2"></i>
                            <strong>Not:</strong> <span style="color:#ef4444;">*</span> işaretli alanlar zorunludur.
                        </div>

                        <div class="d-flex justify-content-end gap-2">
                            <a href="/index.cfm?fuseaction=product.list_product_cat" class="btn btn-light">
                                <i class="fas fa-times me-1"></i>İptal
                            </a>
                            <button type="submit" name="submit" class="btn-save">
                                <i class="fas fa-save"></i>Kategori Ekle
                            </button>
                        </div>

                    </form>
                </div>
            </div>

        </div>
    </div>
</div>

<script>
    document.getElementById('categoryForm').addEventListener('submit', function(e) {
        const productCat = document.getElementById('product_cat').value.trim();
        if (productCat === '') {
            e.preventDefault();
            alert('Kategori adı zorunludur!');
            document.getElementById('product_cat').focus();
        }
    });
</script>
