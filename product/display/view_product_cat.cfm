<cfprocessingdirective pageEncoding="utf-8">

<!--- ID parametresi kontrolü --->
<cfparam name="url.id" default="0">

<cfif val(url.id) eq 0>
    <cflocation url="index.cfm?fuseaction=product.list_product_cat" addtoken="false">
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
        record_emp_ip,
        update_date,
        update_emp,
        update_emp_ip
    FROM 
        product_cat
    WHERE 
        product_catid = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>

<!--- Kategori bulunamadı --->
<cfif getCategory.recordCount eq 0>
    <cflocation url="index.cfm?fuseaction=product.list_product_cat&error=notfound" addtoken="false">
    <cfabort>
</cfif>

<!--- Bu kategoriye ait ürün sayısı --->
<cfquery name="getProductCount" datasource="boyahane">
    SELECT COUNT(*) as product_count
    FROM product
    WHERE product_catid = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>

<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kategori Detayları</title>
    
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
        .detail-card {
            border: none;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        .detail-row {
            padding: 1rem;
            border-bottom: 1px solid #f0f0f0;
        }
        .detail-row:last-child {
            border-bottom: none;
        }
        .detail-label {
            font-weight: 600;
            color: #667eea;
            margin-bottom: 0.25rem;
        }
        .detail-value {
            font-size: 1.1rem;
            color: #333;
        }
        .stats-card {
            border-left: 4px solid #667eea;
        }
    </style>
</head>
<body>
    <cfoutput>
    <div class="page-header">
        <div class="container">
            <div class="row align-items-center">
                <div class="col-md-8">
                    <h1><i class="fas fa-layer-group me-2"></i>#getCategory.product_cat#</h1>
                    <p class="mb-0">Kategori detayları ve bilgileri</p>
                </div>
                <div class="col-md-4 text-end">
                    <a href="/index.cfm?fuseaction=product.edit_product_cat&id=#url.id#" class="btn btn-warning">
                        <i class="fas fa-edit me-1"></i>Düzenle
                    </a>
                    <a href="/index.cfm?fuseaction=product.list_product_cat" class="btn btn-light">
                        <i class="fas fa-arrow-left me-1"></i>Geri
                    </a>
                </div>
            </div>
        </div>
    </div>

    <div class="container">
        <div class="row">
            <!--- Ana Bilgiler --->
            <div class="col-lg-8">
                <div class="card detail-card mb-4">
                    <div class="card-header bg-primary text-white">
                        <h5 class="mb-0"><i class="fas fa-info-circle me-2"></i>Kategori Bilgileri</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="detail-row">
                            <div class="detail-label">
                                <i class="fas fa-hashtag me-1"></i>Kategori ID
                            </div>
                            <div class="detail-value">
                                <span class="badge bg-primary" style="font-size: 1rem;">###getCategory.product_catid#</span>
                            </div>
                        </div>
                        
                        <div class="detail-row">
                            <div class="detail-label">
                                <i class="fas fa-sitemap me-1"></i>Hiyerarşi
                            </div>
                            <div class="detail-value">
                                <cfif len(trim(getCategory.hierarchy))>
                                    <span class="badge bg-info" style="font-size: 1rem;">#getCategory.hierarchy#</span>
                                <cfelse>
                                    <span class="text-muted">Belirtilmemiş</span>
                                </cfif>
                            </div>
                        </div>
                        
                        <div class="detail-row">
                            <div class="detail-label">
                                <i class="fas fa-tag me-1"></i>Kategori Adı
                            </div>
                            <div class="detail-value">
                                <strong>#getCategory.product_cat#</strong>
                            </div>
                        </div>
                        
                        <div class="detail-row">
                            <div class="detail-label">
                                <i class="fas fa-align-left me-1"></i>Detay
                            </div>
                            <div class="detail-value">
                                <cfif len(trim(getCategory.detail))>
                                    #getCategory.detail#
                                <cfelse>
                                    <span class="text-muted">Detay bilgisi yok</span>
                                </cfif>
                            </div>
                        </div>
                    </div>
                </div>

                <!--- Kayıt Bilgileri --->
                <div class="card detail-card">
                    <div class="card-header bg-secondary text-white">
                        <h5 class="mb-0"><i class="fas fa-history me-2"></i>Kayıt ve Güncelleme Bilgileri</h5>
                    </div>
                    <div class="card-body p-0">
                        <div class="detail-row">
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="detail-label">
                                        <i class="fas fa-calendar-plus me-1"></i>Kayıt Tarihi
                                    </div>
                                    <div class="detail-value">
                                        <cfif isDate(getCategory.record_date)>
                                            #dateFormat(getCategory.record_date, "dd/mm/yyyy")#<br>
                                            <small class="text-muted">#timeFormat(getCategory.record_date, "HH:mm:ss")#</small>
                                        <cfelse>
                                            <span class="text-muted">-</span>
                                        </cfif>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="detail-label">
                                        <i class="fas fa-user me-1"></i>Kaydeden Kullanıcı
                                    </div>
                                    <div class="detail-value">
                                        <cfif val(getCategory.record_emp) gt 0>
                                            Kullanıcı ID: #getCategory.record_emp#
                                        <cfelse>
                                            <span class="text-muted">-</span>
                                        </cfif>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="detail-row">
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="detail-label">
                                        <i class="fas fa-calendar-check me-1"></i>Son Güncelleme
                                    </div>
                                    <div class="detail-value">
                                        <cfif isDate(getCategory.update_date)>
                                            #dateFormat(getCategory.update_date, "dd/mm/yyyy")#<br>
                                            <small class="text-muted">#timeFormat(getCategory.update_date, "HH:mm:ss")#</small>
                                        <cfelse>
                                            <span class="text-muted">Güncelleme yok</span>
                                        </cfif>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="detail-label">
                                        <i class="fas fa-user-edit me-1"></i>Güncelleyen Kullanıcı
                                    </div>
                                    <div class="detail-value">
                                        <cfif val(getCategory.update_emp) gt 0>
                                            Kullanıcı ID: #getCategory.update_emp#
                                        <cfelse>
                                            <span class="text-muted">-</span>
                                        </cfif>
                                    </div>
                                </div>
                            </div>
                        </div>
                        
                        <div class="detail-row">
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="detail-label">
                                        <i class="fas fa-network-wired me-1"></i>Kayıt IP Adresi
                                    </div>
                                    <div class="detail-value">
                                        <cfif len(trim(getCategory.record_emp_ip))>
                                            <code>#getCategory.record_emp_ip#</code>
                                        <cfelse>
                                            <span class="text-muted">-</span>
                                        </cfif>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="detail-label">
                                        <i class="fas fa-network-wired me-1"></i>Güncelleme IP Adresi
                                    </div>
                                    <div class="detail-value">
                                        <cfif len(trim(getCategory.update_emp_ip))>
                                            <code>#getCategory.update_emp_ip#</code>
                                        <cfelse>
                                            <span class="text-muted">-</span>
                                        </cfif>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!--- Yan Panel --->
            <div class="col-lg-4">
                <!--- İstatistikler --->
                <div class="card stats-card mb-4">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-center">
                            <div>
                                <h6 class="text-muted mb-1">Bu Kategorideki Ürünler</h6>
                                <h2 class="mb-0">#getProductCount.product_count#</h2>
                            </div>
                            <div class="text-primary" style="font-size: 3rem;">
                                <i class="fas fa-box"></i>
                            </div>
                        </div>
                        <hr>
                        <a href="##" class="btn btn-sm btn-outline-primary w-100">
                            <i class="fas fa-list me-1"></i>Ürünleri Görüntüle
                        </a>
                    </div>
                </div>

                <!--- Hızlı İşlemler --->
                <div class="card">
                    <div class="card-header bg-light">
                        <h6 class="mb-0"><i class="fas fa-bolt me-1"></i>Hızlı İşlemler</h6>
                    </div>
                    <div class="card-body">
                        <div class="d-grid gap-2">
                            <a href="/index.cfm?fuseaction=product.edit_product_cat&id=#url.id#" class="btn btn-warning">
                                <i class="fas fa-edit me-1"></i>Düzenle
                            </a>
                            <button class="btn btn-danger" onclick="deleteCategory()">
                                <i class="fas fa-trash me-1"></i>Sil
                            </button>
                            <a href="/index.cfm?fuseaction=product.list_product_cat" class="btn btn-secondary">
                                <i class="fas fa-arrow-left me-1"></i>Liste'ye Dön
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    </cfoutput>

    <!--- Bootstrap JS --->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
    
    <!--- jQuery --->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    
    <script>
        function deleteCategory() {
            if (confirm('Bu kategoriyi silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!')) {
                $.ajax({
                    url: '/index.cfm?fuseaction=product.delete_product_cat',
                    method: 'POST',
                    data: { id: <cfoutput>#url.id#</cfoutput> },
                    success: function(response) {
                        if (response.success) {
                            alert(response.message);
                            window.location.href = '/index.cfm?fuseaction=product.list_product_cat';
                        } else {
                            alert('Hata: ' + response.message);
                        }
                    },
                    error: function() {
                        alert('Kategori silinirken bir hata oluştu!');
                    }
                });
            }
        }
    </script>
</body>
</html>
