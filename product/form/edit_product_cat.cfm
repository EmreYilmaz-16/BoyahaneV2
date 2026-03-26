<cfprocessingdirective pageEncoding="utf-8">

<!--- jQuery yükleme kontrolü (index.cfm window_type popup/ajaxpage ise jQuery yüklenmez) --->
<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<!--- ID parametresi kontrolü --->
<cfparam name="url.id" default="0">

<cfif val(url.id) eq 0>
    <cflocation url="/index.cfm?fuseaction=product.list_product_cat&error=notfound" addtoken="false">
    <cfabort>
</cfif>

<!--- Kategori bilgilerini getir --->
<cfquery name="getCategory" datasource="boyahane">
    SELECT 
        product_catid,
        hierarchy,
        product_cat,
        detail,
        record_date,
        record_emp,
        update_date,
        update_emp
    FROM 
        product_cat
    WHERE 
        product_catid = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>

<!--- Kategori bulunamadı --->
<cfif getCategory.recordCount eq 0>
    <cflocation url="/index.cfm?fuseaction=product.list_product_cat&error=notfound" addtoken="false">
    <cfabort>
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
        <!--- Kategori güncelle --->
        <cftry>
            <cfquery datasource="boyahane">
                UPDATE product_cat
                SET
                    hierarchy = <cfqueryparam value="#trim(form.hierarchy)#" cfsqltype="cf_sql_varchar" null="#trim(form.hierarchy) eq ''#">,
                    product_cat = <cfqueryparam value="#trim(form.product_cat)#" cfsqltype="cf_sql_varchar">,
                    detail = <cfqueryparam value="#trim(form.detail)#" cfsqltype="cf_sql_varchar" null="#trim(form.detail) eq ''#">,
                    update_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    update_emp = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer" null="#not structKeyExists(session, 'user')#">,
                    update_emp_ip = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                WHERE
                    product_catid = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            
            <!--- Başarılı --->
            <cflocation url="/index.cfm?fuseaction=product.list_product_cat&success=updated" addtoken="false">
            <cfabort>
            
            <cfcatch type="any">
                <cfset errorMsg = "Kategori güncellenirken bir hata oluştu: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>





<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-layer-group"></i>
        </div>
        <div class="page-header-title">
            <h1>Kategori Düzenle</h1>
            <p>#getCategory.product_cat#</p>
        </div>
    </div>
    <span class="record-count">ID: #getCategory.product_catid#</span>
</div>
</cfoutput>

<div class="px-3">
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
                <i class="fas fa-edit"></i>Kategori Bilgileri
            </div>
        </div>
        <div class="card-body p-4">
                        <cfoutput>
                        <form method="post" action="/index.cfm?fuseaction=product.edit_product_cat&id=#url.id#" id="categoryForm">

                            <!--- Kayıt bilgileri --->
                            <div class="d-flex gap-4 mb-4">
                                <cfif isDate(getCategory.record_date)>
                                    <span class="form-note">
                                        <i class="fas fa-calendar me-1"></i><strong>Kayıt:</strong>
                                        #dateFormat(getCategory.record_date, "dd/mm/yyyy")# #timeFormat(getCategory.record_date, "HH:mm")#
                                    </span>
                                </cfif>
                                <cfif isDate(getCategory.update_date)>
                                    <span class="form-note">
                                        <i class="fas fa-clock me-1"></i><strong>Güncelleme:</strong>
                                        #dateFormat(getCategory.update_date, "dd/mm/yyyy")# #timeFormat(getCategory.update_date, "HH:mm")#
                                    </span>
                                </cfif>
                            </div>
                            <div class="mb-3">
                                <label for="hierarchy" class="form-label">
                                    <i class="fas fa-sitemap me-1"></i>Hiyerarşi
                                </label>
                                <input type="text" 
                                       class="form-control" 
                                       id="hierarchy" 
                                       name="hierarchy" 
                                       placeholder="Örn: 01, 01.01, 01.01.01"
                                       value="<cfif isDefined('form.hierarchy')>#form.hierarchy#<cfelse>#getCategory.hierarchy#</cfif>">
                                <small class="form-text text-muted">
                                    Kategori hiyerarşisini belirtir (isteğe bağlı)
                                </small>
                            </div>

                            <div class="mb-3">
                                <label for="product_cat" class="form-label required-field">
                                    <i class="fas fa-tag me-1"></i>Kategori Adı
                                </label>
                                <input type="text" 
                                       class="form-control" 
                                       id="product_cat" 
                                       name="product_cat" 
                                       required 
                                       placeholder="Kategori adını girin"
                                       value="<cfif isDefined('form.product_cat')>#form.product_cat#<cfelse>#getCategory.product_cat#</cfif>">
                            </div>

                            <div class="mb-3">
                                <label for="detail" class="form-label">
                                    <i class="fas fa-align-left me-1"></i>Detay
                                </label>
                                <textarea class="form-control" 
                                          id="detail" 
                                          name="detail" 
                                          rows="3" 
                                          placeholder="Kategori hakkında ek bilgiler"><cfif isDefined('form.detail')>#form.detail#<cfelse>#getCategory.detail#</cfif></textarea>
                            </div>

                            <div class="alert alert-info">
                                <i class="fas fa-info-circle me-2"></i>
                                <strong>Not:</strong> <span class="text-danger">*</span> işaretli alanlar zorunludur.
                            </div>

                            <div class="d-flex justify-content-between">
                                <a href="/index.cfm?fuseaction=product.list_product_cat" class="btn-back">
                                    <i class="fas fa-arrow-left"></i>Geri Dön
                                </a>
                                <button type="submit" name="submit" class="btn-save">
                                    <i class="fas fa-save"></i>Değişiklikleri Kaydet
                                </button>
                            </div>
                        </form>
                        </cfoutput>
                    </div>
    </div>
</div>

<script>
        // Form validasyonu
        document.getElementById('categoryForm').addEventListener('submit', function(e) {
            const productCat = document.getElementById('product_cat').value.trim();
            
            if (productCat === '') {
                e.preventDefault();
                alert('Kategori adı zorunludur!');
                document.getElementById('product_cat').focus();
                return false;
            }
        });
    </script>
