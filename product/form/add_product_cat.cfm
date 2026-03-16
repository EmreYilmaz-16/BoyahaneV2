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
            <cflocation url="../display/list_product_cat.cfm?success=added" addtoken="false">
            <cfabort>
            
            <cfcatch type="any">
                <cfset errorMsg = "Kategori eklenirken bir hata oluştu: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Yeni Kategori Ekle</title>
    
    <!--- Bootstrap CSS --->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <!--- Font Awesome --->
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" rel="stylesheet">
    
    <style>
        .page-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 2rem 0;
            margin-bottom: 2rem;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .form-card {
            border: none;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        .required-field::after {
            content: " *";
            color: red;
        }
    </style>
</head>
<body>
    <div class="page-header">
        <div class="container">
            <h1><i class="fas fa-plus-circle me-2"></i>Yeni Kategori Ekle</h1>
            <p class="mb-0">Ürün kategorisi ekleyin</p>
        </div>
    </div>

    <div class="container">
        <div class="row justify-content-center">
            <div class="col-lg-8">
                <!--- Hata mesajı --->
                <cfif isDefined("errorMsg")>
                    <div class="alert alert-danger alert-dismissible fade show" role="alert">
                        <i class="fas fa-exclamation-circle me-2"></i>
                        <cfoutput>#errorMsg#</cfoutput>
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                    </div>
                </cfif>

                <div class="card form-card">
                    <div class="card-header bg-primary text-white">
                        <h5 class="mb-0"><i class="fas fa-layer-group me-2"></i>Kategori Bilgileri</h5>
                    </div>
                    <div class="card-body p-4">
                        <form method="post" action="add_product_cat.cfm" id="categoryForm">
                            <div class="mb-3">
                                <label for="hierarchy" class="form-label">
                                    <i class="fas fa-sitemap me-1"></i>Hiyerarşi
                                </label>
                                <input type="text" 
                                       class="form-control" 
                                       id="hierarchy" 
                                       name="hierarchy" 
                                       placeholder="Örn: 01, 01.01, 01.01.01"
                                       value="<cfif isDefined('form.hierarchy')><cfoutput>#form.hierarchy#</cfoutput></cfif>">
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
                                       value="<cfif isDefined('form.product_cat')><cfoutput>#form.product_cat#</cfoutput></cfif>">
                            </div>

                            <div class="mb-3">
                                <label for="detail" class="form-label">
                                    <i class="fas fa-align-left me-1"></i>Detay
                                </label>
                                <textarea class="form-control" 
                                          id="detail" 
                                          name="detail" 
                                          rows="3" 
                                          placeholder="Kategori hakkında ek bilgiler"><cfif isDefined('form.detail')><cfoutput>#form.detail#</cfoutput></cfif></textarea>
                            </div>

                            <div class="alert alert-info">
                                <i class="fas fa-info-circle me-2"></i>
                                <strong>Not:</strong> <span class="text-danger">*</span> işaretli alanlar zorunludur.
                            </div>

                            <div class="d-flex justify-content-between">
                                <a href="../display/list_product_cat.cfm" class="btn btn-secondary">
                                    <i class="fas fa-arrow-left me-1"></i>Geri Dön
                                </a>
                                <button type="submit" name="submit" class="btn btn-primary btn-lg">
                                    <i class="fas fa-save me-1"></i>Kategori Ekle
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!--- Bootstrap JS --->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    
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
</body>
</html>
