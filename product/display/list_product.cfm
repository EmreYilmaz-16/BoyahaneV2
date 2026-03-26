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

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-box-open"></i>
        </div>
        <div class="page-header-title">
            <h1>Ürünler</h1>
            <p>Tüm ürünleri görüntüleyin ve yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="addProduct()">
        <i class="fas fa-plus"></i>Yeni Ürün
    </button>
</div>

<div class="px-3">
    <!--- Başarı/Hata Mesajları --->
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
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
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title">
                <i class="fas fa-list"></i>Ürün Listesi
            </div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
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
                    width: 220,
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
                                viewProduct(options.data.product_id);
                            })
                            .appendTo(btnGroup);
                        
                        // Düzenle butonu
                        $('<button>')
                            .addClass('grid-btn grid-btn-edit')
                            .attr('title', 'Düzenle')
                            .html('<i class="fas fa-edit"></i>')
                            .on('click', function() {
                                editProduct(options.data.product_id);
                            })
                            .appendTo(btnGroup);
                        
                        // Sil butonu
                        $('<button>')
                            .addClass('grid-btn grid-btn-del')
                            .attr('title', 'Sil')
                            .html('<i class="fas fa-trash"></i>')
                            .on('click', function() {
                                deleteProduct(options.data.product_id, options.data.product_name);
                            })
                            .appendTo(btnGroup);

                        // Hareketler butonu
                        $('<button>')
                            .addClass('grid-btn grid-btn-info')
                            .attr('title', 'Hareketler')
                            .html('<i class="fas fa-history"></i>')
                            .css({'background-color': '##6f42c1', 'color': '##fff', 'border': 'none', 'border-radius': '4px', 'padding': '4px 8px', 'cursor': 'pointer'})
                            .on('click', function() {
                                showMovementsPopup(options.data.product_id, options.data.product_name);
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
            noDataText: 'Ürün bulunamadı',
            onContentReady: function(e) {
                var count = e.component.totalCount();
                $('##recordCount').text(count + ' kayıt');
            }
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
    window.location.href = '/index.cfm?fuseaction=product.edit_product&id=' + id;
}

function showMovementsPopup(productId, productName) {
    var allRows = [];

    function renderMovementsTable(rows) {
        var tableWrap = $('##mvTable_' + productId);
        if (!rows || rows.length === 0) {
            tableWrap.html('<div class="alert alert-info"><i class="fas fa-info-circle me-2"></i>Seçilen depoya ait hareket bulunamadı.</div>');
            return;
        }
        // Bakiye: satırları eski→yeni sırala, kümülatif hesapla, tekrar ters çevir
        var rowsAsc = rows.slice().reverse();
        var runBal = 0, balances = [];
        for (var b = 0; b < rowsAsc.length; b++) {
            runBal += (parseFloat(rowsAsc[b].stock_in) || 0) - (parseFloat(rowsAsc[b].stock_out) || 0);
            balances.unshift(runBal);
        }
        var html = '<div style="overflow-x:auto"><table class="table table-sm table-bordered table-hover table-striped" style="font-size:13px">';
        html += '<thead class="table-dark"><tr>';
        html += '<th>Tarih</th><th>Fiş No</th><th>Fiş Tipi</th><th>Stok Kodu</th>';
        html += '<th style="text-align:right">Giriş</th><th style="text-align:right">Çıkış</th>';
        html += '<th style="text-align:right">Bakiye</th>';
        html += '<th>Depo</th><th>Lokasyon</th><th>Lot No</th><th>Raf</th>';
        html += '</tr></thead><tbody>';
        var totalIn = 0, totalOut = 0;
        for (var i = 0; i < rows.length; i++) {
            var r = rows[i];
            var tipClass = '';
            var pt = r.process_type || 0;
            if (pt === 1 || pt === 20)      tipClass = 'text-success';   // Giriş / Alış İrs.
            else if (pt === 2 || pt === 10) tipClass = 'text-danger';    // Çıkış / Satış İrs.
            else if (pt === 3 || pt === 40) tipClass = 'text-primary';   // Transfer
            else if (pt === 4)              tipClass = 'text-warning';   // Sayım
            else if (pt === 30)             tipClass = 'text-secondary'; // İade
            else                            tipClass = 'text-muted';
            totalIn  += parseFloat(r.stock_in)  || 0;
            totalOut += parseFloat(r.stock_out) || 0;
            var bal = balances[i];
            var balColor = bal > 0 ? '##198754' : (bal < 0 ? '##dc3545' : '##555');
            html += '<tr>';
            html += '<td>' + (r.process_date || '-') + '</td>';
            html += '<td><strong>' + (r.fis_number || '-') + '</strong></td>';
            html += '<td><span class="' + tipClass + ' fw-bold">' + (r.fis_type_label || '-') + '</span></td>';
            html += '<td>' + (r.stock_code || '-') + '</td>';
            html += '<td style="text-align:right;color:##198754">' + (r.stock_in > 0 ? parseFloat(r.stock_in).toFixed(2) : '-') + '</td>';
            html += '<td style="text-align:right;color:##dc3545">' + (r.stock_out > 0 ? parseFloat(r.stock_out).toFixed(2) : '-') + '</td>';
            html += '<td style="text-align:right;font-weight:bold;color:' + balColor + '">' + bal.toFixed(2) + '</td>';
            html += '<td>' + (r.department_head || '-') + '</td>';
            html += '<td>' + (r.department_location || '-') + '</td>';
            html += '<td>' + (r.lot_no || '-') + '</td>';
            html += '<td>' + (r.shelf_number || '-') + '</td>';
            html += '</tr>';
        }
        var netBal = totalIn - totalOut;
        var netBalColor = netBal > 0 ? '##198754' : (netBal < 0 ? '##dc3545' : '##555');
        html += '</tbody><tfoot class="table-secondary"><tr>';
        html += '<td colspan="4"><strong>TOPLAM</strong></td>';
        html += '<td style="text-align:right;color:##198754"><strong>' + totalIn.toFixed(2) + '</strong></td>';
        html += '<td style="text-align:right;color:##dc3545"><strong>' + totalOut.toFixed(2) + '</strong></td>';
        html += '<td style="text-align:right;font-weight:bold;color:' + netBalColor + '"><strong>' + netBal.toFixed(2) + '</strong></td>';
        html += '<td colspan="4"></td></tr></tfoot>';
        html += '</table></div>';
        html += '<p class="text-muted mt-1" style="font-size:12px"><i class="fas fa-info-circle"></i> ' + rows.length + ' hareket kayıtı listelendi.</p>';
        tableWrap.html(html);
    }

    function applyDepoFilter() {
        var sel = $('##mvDepoFilter_' + productId).val();
        var filtered = sel === '__all__'
            ? allRows
            : allRows.filter(function(r) {
                var key = (r.department_head || '') + '||' + (r.department_location || '');
                return key === sel;
            });
        renderMovementsTable(filtered);
    }

    var popupElement = $('<div>').appendTo('body');
    var popup = popupElement.dxPopup({
        titleTemplate: function() {
            return $('<div>').html('<i class="fas fa-history" style="margin-right:6px"></i> Stok Hareketleri — ' + productName);
        },
        width: '92%',
        maxWidth: 1150,
        height: 'auto',
        maxHeight: '88vh',
        showTitle: true,
        dragEnabled: true,
        closeOnOutsideClick: true,
        showCloseButton: true,
        contentTemplate: function() {
            var wrap = $('<div>').css({'padding': '10px'});
            wrap.html('<div class="text-center py-4"><i class="fas fa-spinner fa-spin fa-2x"></i><p class="mt-2 text-muted">Yükleniyor...</p></div>');
            return wrap;
        },
        toolbarItems: [
            {
                widget: 'dxButton',
                location: 'after',
                toolbar: 'bottom',
                options: { text: 'Kapat', onClick: function() { popup.hide(); } }
            }
        ],
        onShowing: function() {
            $.ajax({
                url: '/product/cfc/product.cfc?method=getProductMovements',
                method: 'GET',
                data: { product_id: productId },
                dataType: 'json',
                success: function(response) {
                    var content = popup.$content();
                    content.empty();
                    if (!response.success) {
                        content.html('<div class="alert alert-danger">' + (response.message || 'Hata oluştu') + '</div>');
                        return;
                    }
                    allRows = response.data || [];
                    if (allRows.length === 0) {
                        content.html('<div class="alert alert-info"><i class="fas fa-info-circle me-2"></i>Bu ürüne ait stok hareketi bulunamadı.</div>');
                        return;
                    }
                    // Benzersiz depo-lokasyon kombinasyonları
                    var depos = [];
                    var depoSeen = {};
                    for (var d = 0; d < allRows.length; d++) {
                        var dhead = allRows[d].department_head || '';
                        var dloc  = allRows[d].department_location || '';
                        var dkey  = dhead + '||' + dloc;
                        var dlabel = dhead + (dloc ? ' — ' + dloc : '');
                        if (dkey && !depoSeen[dkey]) { depoSeen[dkey] = true; depos.push({key: dkey, label: dlabel}); }
                    }
                    depos.sort(function(a, b) { return a.label.localeCompare(b.label); });

                    // Filtre satırı
                    var filterHtml = '<div class="d-flex align-items-center gap-2 mb-2 p-2 bg-light border rounded">';
                    filterHtml += '<label class="fw-bold mb-0" style="white-space:nowrap"><i class="fas fa-warehouse me-1"></i>Depo / Lokasyon:</label>';
                    filterHtml += '<select id="mvDepoFilter_' + productId + '" class="form-select form-select-sm" style="max-width:340px">';
                    filterHtml += '<option value="__all__">-- Tümü --</option>';
                    for (var d2 = 0; d2 < depos.length; d2++) {
                        filterHtml += '<option value="' + depos[d2].key.replace(/"/g, '&quot;') + '">' + depos[d2].label + '</option>';
                    }
                    filterHtml += '</select>';
                    filterHtml += '<span class="text-muted ms-2" style="font-size:12px">Toplam <strong>' + allRows.length + '</strong> hareket</span>';
                    filterHtml += '</div>';
                    filterHtml += '<div id="mvTable_' + productId + '"></div>';

                    content.html(filterHtml);

                    // Filtre değişince tabloyu yenile
                    content.find('##mvDepoFilter_' + productId).on('change', function() {
                        applyDepoFilter();
                        popup.repaint();
                    });

                    // İlk render
                    renderMovementsTable(allRows);
                    popup.repaint();
                },
                error: function() {
                    popup.$content().html('<div class="alert alert-danger">Veriler alınırken bir hata oluştu!</div>');
                }
            });
        },
        onHidden: function() {
            popupElement.remove();
        }
    }).dxPopup('instance');

    popup.show();
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
