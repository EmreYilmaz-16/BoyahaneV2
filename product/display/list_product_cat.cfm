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

<style>
    .page-header {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
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
    .badge-hierarchy {
        font-size: 0.75rem;
        padding: 0.25em 0.5em;
    }
    #categoriesGrid {
        height: 600px;
    }
</style>

    <div class="page-header">
        <div class="container">
            <div class="row align-items-center">
                <div class="col-md-6">
                    <h1><i class="fas fa-layer-group me-2"></i>Ürün Kategorileri</h1>
                    <p class="mb-0">Tüm ürün kategorilerini görüntüleyin ve yönetin</p>
                </div>
                <div class="col-md-6 text-end">
                    <button class="btn btn-light btn-sm" onclick="window.location.href='../form/add_product_cat.cfm'">
                        <i class="fas fa-plus me-1"></i>Yeni Kategori
                    </button>
                </div>
            </div>
        </div>
    </div>

    
        <!--- Başarı/Hata Mesajları --->
        <cfif isDefined("url.success")>
            <cfoutput>
            <div class="alert alert-success alert-dismissible fade show" role="alert">
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
            <div class="alert alert-danger alert-dismissible fade show" role="alert">
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
        <div class="card shadow-sm">
            <div class="card-header bg-white py-2">
                <h6 class="mb-0"><i class="fas fa-list me-2"></i>Kategori Listesi</h6>
            </div>
            <div class="card-body p-2">
                <div id="categoriesGrid"></div>
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
                            .addClass('btn btn-sm btn-info')
                            .attr('title', 'Görüntüle')
                            .html('<i class="fas fa-eye"></i>')
                            .on('click', function() {
                                viewCategory(options.data.product_catid);
                            })
                            .appendTo(btnGroup);
                        
                        // Düzenle butonu
                        $('<button>')
                            .addClass('btn btn-sm btn-warning')
                            .attr('title', 'Düzenle')
                            .html('<i class="fas fa-edit"></i>')
                            .on('click', function() {
                                editCategory(options.data.product_catid);
                            })
                            .appendTo(btnGroup);
                        
                        // Sil butonu
                        $('<button>')
                            .addClass('btn btn-sm btn-danger')
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
            noDataText: 'Kategori bulunamadı'
        });
    }
});

function viewCategory(id) {
    window.location.href = '/index.cfm?fuseaction=product.view_product_cat&id=' + id;
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
                    url: '../form/delete_product_cat.cfm',
                    method: 'POST',
                    data: { id: id },
                    success: function(response) {
                        DevExpress.ui.notify({
                            message: 'Kategori başarıyla silindi.',
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
            fetch('../form/delete_product_cat.cfm', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'id=' + id
            })
            .then(function() {
                alert('Kategori başarıyla silindi.');
                location.reload();
            })
            .catch(function() {
                alert('Kategori silinirken bir hata oluştu!');
            });
        }
    }
}
</script>
</cfoutput>
