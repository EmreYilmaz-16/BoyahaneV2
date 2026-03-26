<cfprocessingdirective pageEncoding="utf-8">

<!--- Kategorileri getir ve JSON'a çevir --->
<cfquery name="getCategories" datasource="boyahane">
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
    ORDER BY 
        hierarchy, product_cat
</cfquery>

<!--- Veriyi JSON formatına çevir --->
<cfset categoriesArray = []>
<cfloop query="getCategories">
    <cfset categoryObj = {
        "product_catid" = product_catid,
        "hierarchy" = hierarchy,
        "product_cat" = product_cat,
        "detail" = detail,
        "record_date" = isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : "",
        "update_date" = isDate(update_date) ? dateFormat(update_date, "dd/mm/yyyy") & " " & timeFormat(update_date, "HH:mm") : ""
    }>
    <cfset arrayAppend(categoriesArray, categoryObj)>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-layer-group"></i>
        </div>
        <div class="page-header-title">
            <h1>Ürün Kategorileri</h1>
            <p>Tüm ürün kategorilerini görüntüleyin ve yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="addCategory()">
        <i class="fas fa-plus"></i>Yeni Kategori
    </button>
</div>

<div class="px-3">
    <!--- Başarı/Hata Mesajları --->
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added">
                <strong>Başarılı!</strong> Kategori başarıyla eklendi.
            <cfelseif url.success eq "updated">
                <strong>Başarılı!</strong> Kategori başarıyla güncellendi.
            <cfelseif url.success eq "deleted">
                <strong>Başarılı!</strong> Kategori başarıyla silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <cfif isDefined("url.error")>
        <cfoutput>
        <div class="alert alert-danger alert-dismissible fade show mb-3" role="alert">
            <i class="fas fa-exclamation-circle me-2"></i>
            <cfif url.error eq "notfound">
                <strong>Hata!</strong> Kategori bulunamadı.
            <cfelse>
                <strong>Hata!</strong> Bir hata oluştu.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <!--- DevExtreme DataGrid --->
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title">
                <i class="fas fa-list"></i>Kategori Listesi
            </div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="categoriesGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
// Veriyi hazırla
var categoriesData = #serializeJSON(categoriesArray)#;

// jQuery ve DevExtreme yüklenene kadar bekle
window.addEventListener('load', function() {
    // DevExtreme Türkçe ayarla
    if (typeof DevExpress !== 'undefined') {
        DevExpress.localization.locale('tr');
    }
    
    // Grid'i başlat
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $("##categoriesGrid").dxDataGrid({
            dataSource: categoriesData,
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
                fileName: 'urun_kategorileri_' + new Date().toISOString().slice(0,10),
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
                    dataField: 'product_catid',
                    caption: 'ID',
                    width: 80,
                    alignment: 'center',
                    dataType: 'number',
                    sortOrder: 'desc'
                },
                {
                    dataField: 'hierarchy',
                    caption: 'Hiyerarşi',
                    width: 120,
                    alignment: 'center',
                    cellTemplate: function(container, options) {
                        if (options.value) {
                            $('<span>').addClass('badge bg-primary').text(options.value).appendTo(container);
                        } else {
                            $('<span>').addClass('text-muted').text('-').appendTo(container);
                        }
                    }
                },
                {
                    dataField: 'product_cat',
                    caption: 'Kategori Adı',
                    minWidth: 200,
                    cellTemplate: function(container, options) {
                        $('<strong>').text(options.value).appendTo(container);
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
                    dataField: 'record_date',
                    caption: 'Kayıt Tarihi',
                    width: 150,
                    alignment: 'center',
                    dataType: 'string'
                },
                {
                    dataField: 'update_date',
                    caption: 'Güncelleme Tarihi',
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
                                viewCategory(options.data.product_catid);
                            })
                            .appendTo(btnGroup);
                        
                        // Düzenle butonu
                        $('<button>')
                            .addClass('grid-btn grid-btn-edit')
                            .attr('title', 'Düzenle')
                            .html('<i class="fas fa-edit"></i>')
                            .on('click', function() {
                                editCategory(options.data.product_catid);
                            })
                            .appendTo(btnGroup);
                        
                        // Sil butonu
                        $('<button>')
                            .addClass('grid-btn grid-btn-del')
                            .attr('title', 'Sil')
                            .html('<i class="fas fa-trash"></i>')
                            .on('click', function() {
                                deleteCategory(options.data.product_catid, options.data.product_cat);
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
            noDataText: 'Kategori bulunamadı',
            onContentReady: function(e) {
                var count = e.component.totalCount();
                $('##recordCount').text(count + ' kayıt');
            }
        });
    }
});

function addCategory() {
    window.location.href = '/index.cfm?fuseaction=product.add_product_cat';
}

function viewCategory(id) {
    // Kategorileri veriden bul
    var category = categoriesData.find(function(cat) {
        return cat.product_catid === id;
    });
    
    if (!category) {
        DevExpress.ui.notify({
            message: 'Kategori bulunamadı!',
            type: 'error',
            displayTime: 3000
        });
        return;
    }
    
    // Modal içeriğini oluştur
    var modalContent = $('<div>').css({'padding': '20px'});
    
    var detailsHtml = '<div class="row g-3">' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">ID</label>' +
            '<div class="fw-bold">' + category.product_catid + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Hiyerarşi</label>' +
            '<div class="fw-bold">' + (category.hierarchy || '-') + '</div>' +
        '</div>' +
        '<div class="col-12">' +
            '<label class="form-label text-muted">Kategori Adı</label>' +
            '<div class="fw-bold fs-5">' + category.product_cat + '</div>' +
        '</div>' +
        '<div class="col-12">' +
            '<label class="form-label text-muted">Detay</label>' +
            '<div>' + (category.detail || '-') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Kayıt Tarihi</label>' +
            '<div>' + (category.record_date || '-') + '</div>' +
        '</div>' +
        '<div class="col-md-6">' +
            '<label class="form-label text-muted">Güncelleme Tarihi</label>' +
            '<div>' + (category.update_date || '-') + '</div>' +
        '</div>' +
    '</div>';
    
    modalContent.html(detailsHtml);
    
    // DevExtreme Popup oluştur
    var popupElement = $('<div>').appendTo('body');
    var popup = popupElement.dxPopup({
        title: 'Kategori Detayları - ' + category.product_cat,
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
                        editCategory(id);
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

function editCategory(id) {
    window.location.href = '/index.cfm?fuseaction=product.edit_product_cat&id=' + id;
}

function deleteCategory(id, name) {
    if (typeof DevExpress !== 'undefined' && DevExpress.ui && DevExpress.ui.dialog) {
        DevExpress.ui.dialog.confirm(
            '"' + name + '" kategorisini silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!',
            'Kategori Sil'
        ).done(function(dialogResult) {
            if (dialogResult) {
                $.ajax({
                    url: '/product/cfc/product.cfc?method=deleteCategory',
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
                            message: 'Kategori silinirken bir hata oluştu!',
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
        // DevExtreme yüklü değilse standart confirm kullan
        if (confirm('"' + name + '" kategorisini silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!')) {
            fetch('/product/cfc/product.cfc?method=deleteCategory', {
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
                alert('Kategori silinirken bir hata oluştu!');
            });
        }
    }
}
</script>
</cfoutput>
