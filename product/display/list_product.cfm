<cfprocessingdirective pageEncoding="utf-8">

<!--- Ürünleri getir ve JSON'a çevir --->
<cfquery name="getProducts" datasource="boyahane">
    SELECT 
        p.product_id,
        p.product_code,
        p.product_name,
        p.product_catid,
        p.brand_id,
        p.barcod,
        p.product_detail,
        p.product_status,
        p.tax,
        p.is_sales,
        p.is_purchase,
        p.record_date,
        p.update_date,
        pc.product_cat,
        pc.hierarchy,
        pb.brand_name
    FROM 
        product p
        LEFT JOIN product_cat pc ON p.product_catid = pc.product_catid
        LEFT JOIN product_brands pb ON p.brand_id = pb.brand_id
    ORDER BY 
        p.product_id DESC
</cfquery>

<!--- Kategorileri getir (form için) --->
<cfquery name="getCategories" datasource="boyahane">
    SELECT product_catid, product_cat, hierarchy
    FROM product_cat
    ORDER BY hierarchy, product_cat
</cfquery>

<!--- Veriyi JSON formatına çevir --->
<cfset productsArray = []>
<cfloop query="getProducts">
    <cfset productObj = {
        "product_id" = product_id,
        "product_code" = product_code ?: "",
        "product_name" = product_name ?: "",
        "product_catid" = product_catid,
        "product_cat" = product_cat ?: "",
        "hierarchy" = hierarchy ?: "",
        "brand_id" = brand_id ?: 0,
        "brand_name" = brand_name ?: "",
        "barcod" = barcod ?: "",
        "product_detail" = product_detail ?: "",
        "product_status" = product_status,
        "tax" = tax,
        "is_sales" = is_sales,
        "is_purchase" = is_purchase,
        "record_date" = isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : "",
        "update_date" = isDate(update_date) ? dateFormat(update_date, "dd/mm/yyyy") & " " & timeFormat(update_date, "HH:mm") : ""
    }>
    <cfset arrayAppend(productsArray, productObj)>
</cfloop>

<cfset categoriesArray = []>
<cfloop query="getCategories">
    <cfset arrayAppend(categoriesArray, {
        "product_catid" = product_catid,
        "product_cat" = product_cat,
        "hierarchy" = hierarchy ?: ""
    })>
</cfloop>

<style>
    .page-header {
        background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%);
        color: white;
        padding: 1rem 0;
        margin-bottom: 1.5rem;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .page-header h1 {
        font-size: 1.5rem;
        margin-bottom: 0.25rem;
    }
    .page-header p {
        font-size: 0.875rem;
    }
    #productsGrid {
        height: 600px;
    }
    .status-badge {
        display: inline-block;
        padding: 0.25em 0.6em;
        font-size: 0.75rem;
        font-weight: 700;
        line-height: 1;
        text-align: center;
        white-space: nowrap;
        vertical-align: baseline;
        border-radius: 0.25rem;
    }
    .status-active {
        background-color: #28a745;
        color: white;
    }
    .status-passive {
        background-color: #dc3545;
        color: white;
    }
</style>

<div class="page-header">
    <div class="container">
        <div class="row align-items-center">
            <div class="col-md-6">
                <h1><i class="fas fa-box-open me-2"></i>Ürünler</h1>
                <p class="mb-0">Tüm ürünleri görüntüleyin ve yönetin</p>
            </div>
            <div class="col-md-6 text-end">
                <button class="btn btn-light btn-sm" onclick="addProduct()">
                    <i class="fas fa-plus me-1"></i>Yeni Ürün
                </button>
            </div>
        </div>
    </div>
</div>

<div class="container">
    <!--- Başarı/Hata Mesajları --->
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added">
                <strong>Başarılı!</strong> Ürün başarıyla eklendi.
            <cfelseif url.success eq "updated">
                <strong>Başarılı!</strong> Ürün başarıyla güncellendi.
            <cfelseif url.success eq "deleted">
                <strong>Başarılı!</strong> Ürün başarıyla silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <!--- DevExtreme DataGrid --->
    <div class="card shadow-sm">
        <div class="card-header bg-white py-2">
            <h6 class="mb-0"><i class="fas fa-list me-2"></i>Ürün Listesi</h6>
        </div>
        <div class="card-body p-2">
            <div id="productsGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
// Veriyi hazırla
var productsData = #serializeJSON(productsArray)#;
var categoriesData = #serializeJSON(categoriesArray)#;

// jQuery ve DevExtreme yüklenene kadar bekle
window.addEventListener('load', function() {
    // DevExtreme Türkçe ayarla
    if (typeof DevExpress !== 'undefined') {
        DevExpress.localization.locale('tr');
    }
    
    // Grid'i başlat
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $("##productsGrid").dxDataGrid({
            dataSource: productsData,
            showBorders: true,
            showRowLines: true,
            showColumnLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            wordWrapEnabled: false,
            allowColumnReordering: true,
            allowColumnResizing: true,
            columnResizingMode: 'widget',
            
            // Sayfalama
            paging: {
                pageSize: 25,
                pageIndex: 0
            },
            pager: {
                visible: true,
                allowedPageSizes: [10, 25, 50, 100],
                showPageSizeSelector: true,
                showNavigationButtons: true,
                showInfo: true,
                infoText: 'Sayfa {0} / {1} ({2} kayıt)'
            },
            
            // Filtreleme
            filterRow: {
                visible: true,
                applyFilter: 'auto'
            },
            headerFilter: {
                visible: true
            },
            searchPanel: {
                visible: true,
                width: 240,
                placeholder: 'Ara...'
            },
            
            // Sıralama
            sorting: {
                mode: 'multiple'
            },
            
            // Sütun seçme
            columnChooser: {
                enabled: true,
                mode: 'select',
                title: 'Sütun Seçimi'
            },
            
            // Gruplama
            groupPanel: {
                visible: true,
                emptyPanelText: 'Gruplamak için sütun başlığını buraya sürükleyin'
            },
            grouping: {
                autoExpandAll: false
            },
            
            // Excel Export
            export: {
                enabled: true,
                fileName: 'urunler_' + new Date().toISOString().slice(0,10),
                allowExportSelectedData: false
            },
            
            // Seçim
            selection: {
                mode: 'multiple',
                showCheckBoxesMode: 'always'
            },
            
            // Sütunlar
            columns: [
                {
                    dataField: 'product_id',
                    caption: 'ID',
                    width: 80,
                    alignment: 'center',
                    dataType: 'number',
                    sortOrder: 'desc'
                },
                {
                    dataField: 'product_code',
                    caption: 'Ürün Kodu',
                    width: 120,
                    cellTemplate: function(container, options) {
                        if (options.value) {
                            container.text(options.value);
                        } else {
                            $('<span>').addClass('text-muted').text('-').appendTo(container);
                        }
                    }
                },
                {
                    dataField: 'product_name',
                    caption: 'Ürün Adı',
                    minWidth: 200,
                    cellTemplate: function(container, options) {
                        $('<strong>').text(options.value).appendTo(container);
                    }
                },
                {
                    dataField: 'product_cat',
                    caption: 'Kategori',
                    width: 150,
                    cellTemplate: function(container, options) {
                        if (options.value) {
                            $('<span>').addClass('badge bg-info').text(options.value).appendTo(container);
                        } else {
                            $('<span>').addClass('text-muted').text('-').appendTo(container);
                        }
                    }
                },
                {
                    dataField: 'brand_name',
                    caption: 'Marka',
                    width: 130,
                    cellTemplate: function(container, options) {
                        if (options.value) {
                            $('<span>').addClass('badge bg-secondary').text(options.value).appendTo(container);
                        } else {
                            $('<span>').addClass('text-muted').text('-').appendTo(container);
                        }
                    }
                },
                {
                    dataField: 'barcod',
                    caption: 'Barkod',
                    width: 120,
                    cellTemplate: function(container, options) {
                        if (options.value) {
                            container.text(options.value);
                        } else {
                            $('<span>').addClass('text-muted').text('-').appendTo(container);
                        }
                    }
                },
                {
                    dataField: 'tax',
                    caption: 'KDV %',
                    width: 80,
                    alignment: 'center',
                    dataType: 'number',
                    format: {
                        type: 'fixedPoint',
                        precision: 0
                    }
                },
                {
                    dataField: 'product_status',
                    caption: 'Durum',
                    width: 100,
                    alignment: 'center',
                    cellTemplate: function(container, options) {
                        if (options.value) {
                            $('<span>').addClass('status-badge status-active').text('Aktif').appendTo(container);
                        } else {
                            $('<span>').addClass('status-badge status-passive').text('Pasif').appendTo(container);
                        }
                    }
                },
                {
                    dataField: 'is_sales',
                    caption: 'Satış',
                    width: 80,
                    alignment: 'center',
                    cellTemplate: function(container, options) {
                        if (options.value) {
                            $('<i>').addClass('fas fa-check text-success').appendTo(container);
                        } else {
                            $('<i>').addClass('fas fa-times text-danger').appendTo(container);
                        }
                    }
                },
                {
                    dataField: 'is_purchase',
                    caption: 'Alış',
                    width: 80,
                    alignment: 'center',
                    cellTemplate: function(container, options) {
                        if (options.value) {
                            $('<i>').addClass('fas fa-check text-success').appendTo(container);
                        } else {
                            $('<i>').addClass('fas fa-times text-danger').appendTo(container);
                        }
                    }
                },
                {
                    dataField: 'record_date',
                    caption: 'Kayıt Tarihi',
                    width: 150,
                    alignment: 'center',
                    dataType: 'string'
                },
                {
                    caption: 'İşlemler',
                    width: 180,
                    alignment: 'center',
                    allowFiltering: false,
                    allowSorting: false,
                    allowGrouping: false,
                    cellTemplate: function(container, options) {
                        var btnGroup = $('<div>').css({
                            'display': 'flex',
                            'gap': '5px',
                            'justify-content': 'center'
                        });
                        
                        // Görüntüle butonu
                        $('<button>')
                            .addClass('btn btn-sm btn-info')
                            .attr('title', 'Görüntüle')
                            .html('<i class="fas fa-eye"></i>')
                            .on('click', function() {
                                viewProduct(options.data.product_id);
                            })
                            .appendTo(btnGroup);
                        
                        // Düzenle butonu
                        $('<button>')
                            .addClass('btn btn-sm btn-warning')
                            .attr('title', 'Düzenle')
                            .html('<i class="fas fa-edit"></i>')
                            .on('click', function() {
                                editProduct(options.data.product_id);
                            })
                            .appendTo(btnGroup);
                        
                        // Sil butonu
                        $('<button>')
                            .addClass('btn btn-sm btn-danger')
                            .attr('title', 'Sil')
                            .html('<i class="fas fa-trash"></i>')
                            .on('click', function() {
                                deleteProduct(options.data.product_id, options.data.product_name);
                            })
                            .appendTo(btnGroup);
                        
                        btnGroup.appendTo(container);
                    }
                }
            ],
            
            // Özelleştirme
            onToolbarPreparing: function(e) {
                e.toolbarOptions.items.unshift({
                    location: 'after',
                    widget: 'dxButton',
                    options: {
                        icon: 'refresh',
                        text: 'Yenile',
                        onClick: function() {
                            location.reload();
                        }
                    }
                });
            },
            
            // Mesajlar
            loadPanel: {
                enabled: true,
                text: 'Yükleniyor...'
            },
            noDataText: 'Ürün bulunamadı'
        });
    }
});

function addProduct() {
    window.location.href = '/index.cfm?fuseaction=product.add_product';
}

function viewProduct(id) {
    // AJAX ile ürün detaylarını getir
    $.ajax({
        url: '/product/cfc/product.cfc?method=getProduct',
        method: 'GET',
        data: { id: id },
        dataType: 'json',
        success: function(response) {
            if (response.success) {
                showProductModal(response.data);
            } else {
                DevExpress.ui.notify({
                    message: response.message,
                    type: 'error',
                    displayTime: 3000
                });
            }
        },
        error: function() {
            DevExpress.ui.notify({
                message: 'Ürün bilgileri alınırken bir hata oluştu!',
                type: 'error',
                displayTime: 3000
            });
        }
    });
}

function showProductModal(product) {
    var modalContent = $('<div>').css({'padding': '20px'});
    
    var detailsHtml = '<div class="row g-3">' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">ID</label>' +
            '<div class="fw-bold">' + product.product_id + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Ürün Kodu</label>' +
            '<div class="fw-bold">' + (product.product_code || '-') + '</div>' +
        '</div>' +
        '<div class="col-12">' +
            '<label class="form-label text-muted">Ürün Adı</label>' +
            '<div class="fw-bold fs-5">' + product.product_name + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Kategori</label>' +
            '<div>' + (product.product_cat || '-') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Marka</label>' +
            '<div>' + (product.brand_name || '-') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Barkod</label>' +
            '<div>' + (product.barcod || '-') + '</div>' +
        '</div>' +
        '<div class="col-12">' +
            '<label class="form-label text-muted">Detay</label>' +
            '<div>' + (product.product_detail || '-') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">KDV %</label>' +
            '<div>' + product.tax + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Durum</label>' +
            '<div>' + (product.product_status ? '<span class="status-badge status-active">Aktif</span>' : '<span class="status-badge status-passive">Pasif</span>') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Satış</label>' +
            '<div>' + (product.is_sales ? '<i class="fas fa-check text-success"></i> Evet' : '<i class="fas fa-times text-danger"></i> Hayır') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Alış</label>' +
            '<div>' + (product.is_purchase ? '<i class="fas fa-check text-success"></i> Evet' : '<i class="fas fa-times text-danger"></i> Hayır') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Kayıt Tarihi</label>' +
            '<div>' + (product.record_date || '-') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Güncelleme Tarihi</label>' +
            '<div>' + (product.update_date || '-') + '</div>' +
        '</div>' +
    '</div>';
    
    modalContent.html(detailsHtml);
    
    // DevExtreme Popup oluştur
    var popupElement = $('<div>').appendTo('body');
    var popup = popupElement.dxPopup({
        title: 'Ürün Detayları - ' + product.product_name,
        contentTemplate: function() {
            return modalContent;
        },
        width: 700,
        height: 'auto',
        showTitle: true,
        dragEnabled: true,
        closeOnOutsideClick: true,
        showCloseButton: true,
        toolbarItems: [
            {
                widget: 'dxButton',
                location: 'after',
                toolbar: 'bottom',
                options: {
                    text: 'Düzenle',
                    type: 'default',
                    icon: 'edit',
                    onClick: function() {
                        popup.hide();
                        editProduct(product.product_id);
                    }
                }
            },
            {
                widget: 'dxButton',
                location: 'after',
                toolbar: 'bottom',
                options: {
                    text: 'Kapat',
                    onClick: function() {
                        popup.hide();
                    }
                }
            }
        ],
        onHidden: function() {
            popupElement.remove();
        }
    }).dxPopup('instance');
    
    popup.show();
}

function editProduct(id) {
    window.location.href = 'index.cfm?fusaction=product.edit_product.cfm?id=' + id;
}

function deleteProduct(id, name) {
    if (typeof DevExpress !== 'undefined' && DevExpress.ui && DevExpress.ui.dialog) {
        DevExpress.ui.dialog.confirm(
            '"' + name + '" ürününü silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!',
            'Ürün Sil'
        ).done(function(dialogResult) {
            if (dialogResult) {
                $.ajax({
                    url: '/product/cfc/product.cfc?method=deleteProduct',
                    method: 'POST',
                    data: { id: id },
                    dataType: 'json',
                    success: function(response) {
                        if (response.success) {
                            DevExpress.ui.notify({
                                message: response.message,
                                type: 'success',
                                displayTime: 3000,
                                position: {
                                    my: 'top right',
                                    at: 'top right'
                                }
                            });
                            setTimeout(function() {
                                location.reload();
                            }, 1000);
                        } else {
                            DevExpress.ui.notify({
                                message: response.message,
                                type: 'error',
                                displayTime: 3000,
                                position: {
                                    my: 'top right',
                                    at: 'top right'
                                }
                            });
                        }
                    },
                    error: function() {
                        DevExpress.ui.notify({
                            message: 'Ürün silinirken bir hata oluştu!',
                            type: 'error',
                            displayTime: 3000,
                            position: {
                                my: 'top right',
                                at: 'top right'
                            }
                        });
                    }
                });
            }
        });
    } else {
        if (confirm('"' + name + '" ürününü silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!')) {
            fetch('/product/cfc/product.cfc?method=deleteProduct', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'id=' + id
            })
            .then(function(res) { return res.json(); })
            .then(function(response) {
                if (response.success) {
                    alert(response.message);
                    location.reload();
                } else {
                    alert(response.message);
                }
            })
            .catch(function() {
                alert('Ürün silinirken bir hata oluştu!');
            });
        }
    }
}
</script>
</cfoutput>
