<cfprocessingdirective pageEncoding="utf-8">

<!--- Markaları getir ve JSON'a çevir --->
<cfquery name="getBrands" datasource="boyahane">
    SELECT 
        brand_id,
        brand_name,
        brand_code,
        detail,
        is_active,
        is_internet,
        record_date,
        update_date
    FROM 
        product_brands
    ORDER BY 
        brand_name
</cfquery>

<!--- Veriyi JSON formatına çevir --->
<cfset brandsArray = []>
<cfloop query="getBrands">
    <cfset brandObj = {
        "brand_id" = brand_id,
        "brand_name" = brand_name ?: "",
        "brand_code" = brand_code ?: "",
        "detail" = detail ?: "",
        "is_active" = is_active,
        "is_internet" = is_internet,
        "record_date" = isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : "",
        "update_date" = isDate(update_date) ? dateFormat(update_date, "dd/mm/yyyy") & " " & timeFormat(update_date, "HH:mm") : ""
    }>
    <cfset arrayAppend(brandsArray, brandObj)>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-tags"></i>
        </div>
        <div class="page-header-title">
            <h1>Ürün Markaları</h1>
            <p>Tüm markaları görüntüleyin ve yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="addBrand()">
        <i class="fas fa-plus"></i>Yeni Marka
    </button>
</div>

<div class="px-3">
    <!--- Başarı/Hata Mesajları --->
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show" role="alert">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added">
                <strong>Başarılı!</strong> Marka başarıyla eklendi.
            <cfelseif url.success eq "updated">
                <strong>Başarılı!</strong> Marka başarıyla güncellendi.
            <cfelseif url.success eq "deleted">
                <strong>Başarılı!</strong> Marka başarıyla silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <!--- DevExtreme DataGrid --->
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title">
                <i class="fas fa-list"></i>Marka Listesi
            </div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="brandsGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
// Veriyi hazırla
var brandsData = #serializeJSON(brandsArray)#;

// jQuery ve DevExtreme yüklenene kadar bekle
window.addEventListener('load', function() {
    // DevExtreme Türkçe ayarla
    if (typeof DevExpress !== 'undefined') {
        DevExpress.localization.locale('tr');
    }
    
    // Grid'i başlat
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $("##brandsGrid").dxDataGrid({
            dataSource: brandsData,
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
                fileName: 'markalar_' + new Date().toISOString().slice(0,10),
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
                    dataField: 'brand_id',
                    caption: 'ID',
                    width: 80,
                    alignment: 'center',
                    dataType: 'number'
                },
                {
                    dataField: 'brand_name',
                    caption: 'Marka Adı',
                    minWidth: 200,
                    cellTemplate: function(container, options) {
                        $('<strong>').text(options.value || '-').appendTo(container);
                    }
                },
                {
                    dataField: 'brand_code',
                    caption: 'Marka Kodu',
                    width: 150,
                    cellTemplate: function(container, options) {
                        if (options.value) {
                            container.text(options.value);
                        } else {
                            $('<span>').addClass('text-muted').text('-').appendTo(container);
                        }
                    }
                },
                {
                    dataField: 'detail',
                    caption: 'Detay',
                    minWidth: 200,
                    cellTemplate: function(container, options) {
                        if (options.value) {
                            container.text(options.value);
                        } else {
                            $('<span>').addClass('text-muted').text('-').appendTo(container);
                        }
                    }
                },
                {
                    dataField: 'is_active',
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
                    dataField: 'is_internet',
                    caption: 'İnternet',
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
                            .addClass('grid-btn grid-btn-view')
                            .attr('title', 'Görüntüle')
                            .html('<i class="fas fa-eye"></i>')
                            .on('click', function() {
                                viewBrand(options.data.brand_id);
                            })
                            .appendTo(btnGroup);
                        
                        // Düzenle butonu
                        $('<button>')
                            .addClass('grid-btn grid-btn-edit')
                            .attr('title', 'Düzenle')
                            .html('<i class="fas fa-edit"></i>')
                            .on('click', function() {
                                editBrand(options.data.brand_id);
                            })
                            .appendTo(btnGroup);
                        
                        // Sil butonu
                        $('<button>')
                            .addClass('grid-btn grid-btn-del')
                            .attr('title', 'Sil')
                            .html('<i class="fas fa-trash"></i>')
                            .on('click', function() {
                                deleteBrand(options.data.brand_id, options.data.brand_name);
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
            noDataText: 'Marka bulunamadı',
            onContentReady: function(e) {
                var count = e.component.totalCount();
                $('##recordCount').text(count + ' kayıt');
            }
        });
    }
});

function addBrand() {
    window.location.href = '/index.cfm?fuseaction=product.add_product_brand';
}

function viewBrand(id) {
    // AJAX ile marka detaylarını getir
    $.ajax({
        url: '/product/cfc/product.cfc?method=getBrand',
        method: 'GET',
        data: { id: id },
        dataType: 'json',
        success: function(response) {
            if (response.success) {
                showBrandModal(response.data);
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
                message: 'Marka bilgileri alınırken bir hata oluştu!',
                type: 'error',
                displayTime: 3000
            });
        }
    });
}

function showBrandModal(brand) {
    var modalContent = $('<div>').css({'padding': '20px'});
    
    var detailsHtml = '<div class="row g-3">' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">ID</label>' +
            '<div class="fw-bold">' + brand.brand_id + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Marka Kodu</label>' +
            '<div class="fw-bold">' + (brand.brand_code || '-') + '</div>' +
        '</div>' +
        '<div class="col-12">' +
            '<label class="form-label text-muted">Marka Adı</label>' +
            '<div class="fw-bold fs-5">' + brand.brand_name + '</div>' +
        '</div>' +
        '<div class="col-12">' +
            '<label class="form-label text-muted">Detay</label>' +
            '<div>' + (brand.detail || '-') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Durum</label>' +
            '<div>' + (brand.is_active ? '<span class="status-badge status-active">Aktif</span>' : '<span class="status-badge status-passive">Pasif</span>') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">İnternet Satış</label>' +
            '<div>' + (brand.is_internet ? '<i class="fas fa-check text-success"></i> Evet' : '<i class="fas fa-times text-danger"></i> Hayır') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Kayıt Tarihi</label>' +
            '<div>' + (brand.record_date || '-') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Güncelleme Tarihi</label>' +
            '<div>' + (brand.update_date || '-') + '</div>' +
        '</div>' +
    '</div>';
    
    modalContent.html(detailsHtml);
    
    // DevExtreme Popup oluştur
    var popupElement = $('<div>').appendTo('body');
    var popup = popupElement.dxPopup({
        title: 'Marka Detayları - ' + brand.brand_name,
        contentTemplate: function() {
            return modalContent;
        },
        width: 600,
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
                        editBrand(brand.brand_id);
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

function editBrand(id) {
    window.location.href = '/index.cfm?fuseaction=product.edit_product_brands&id=' + id;
}

function deleteBrand(id, name) {
    if (typeof DevExpress !== 'undefined' && DevExpress.ui && DevExpress.ui.dialog) {
        DevExpress.ui.dialog.confirm(
            '"' + name + '" markasını silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!',
            'Marka Sil'
        ).done(function(dialogResult) {
            if (dialogResult) {
                $.ajax({
                    url: '/product/cfc/product.cfc?method=deleteBrand',
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
                            message: 'Marka silinirken bir hata oluştu!',
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
        if (confirm('"' + name + '" markasını silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!')) {
            fetch('/product/cfc/product.cfc?method=deleteBrand', {
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
                alert('Marka silinirken bir hata oluştu!');
            });
        }
    }
}
</script>
</cfoutput>
