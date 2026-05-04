<cfprocessingdirective pageEncoding="utf-8">

<!---
    Ürün ağacı (BOM) listesi
    product_tree.stock_id  = kök stok (BOM sahibi)
    product_tree.related_id = bileşenin stock_id'si (malzeme satırları için)
--->
<cfquery name="getStocksWithTree" datasource="boyahane">
    SELECT s.stock_id,
           COALESCE(s.stock_code,'')    AS stock_code,
           COALESCE(p.product_name,'')  AS product_name,
           COALESCE(pc.product_cat,'')  AS product_cat,
           COUNT(pt.product_tree_id)    AS row_count,
           MAX(pt.record_date)          AS last_update
    FROM stocks s
    INNER JOIN product_tree pt ON pt.stock_id = s.stock_id
    LEFT JOIN product p        ON s.product_id = p.product_id
    LEFT JOIN product_cat pc   ON p.product_catid = pc.product_catid
    GROUP BY s.stock_id, s.stock_code, p.product_name, pc.product_cat
    ORDER BY s.stock_code
</cfquery>

<cfset ptArr = []>
<cfloop query="getStocksWithTree">
    <cfset arrayAppend(ptArr, {
        "stock_id"    : val(stock_id),
        "stock_code"  : stock_code   ?: "",
        "product_name": product_name ?: "",
        "product_cat" : product_cat  ?: "",
        "row_count"   : val(row_count),
        "last_update" : isDate(last_update) ? dateFormat(last_update,"dd/mm/yyyy") : ""
    })>
</cfloop>

<!--- Tüm stoklar: yeni ağaç açmak için select --->
<cfquery name="getAllStocks" datasource="boyahane">
    SELECT s.stock_id,
           COALESCE(s.stock_code,'')    AS stock_code,
           COALESCE(p.product_name,'')  AS product_name
    FROM stocks s
    LEFT JOIN product p ON s.product_id = p.product_id
    WHERE COALESCE(s.stock_status, true) = true
    ORDER BY s.stock_code
</cfquery>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-sitemap"></i></div>
        <div class="page-header-title">
            <h1>Ürün Ağaçları (BOM)</h1>
            <p>Ürün reçeteleri ve bileşen ağaçları yönetimi</p>
        </div>
    </div>
    <div class="d-flex gap-2 align-items-center">
        <select class="form-select form-select-sm" id="selectStock" style="min-width:280px;">
            <option value="0">Stok seçiniz...</option>
            <cfoutput>
            <cfloop query="getAllStocks">
                <option value="#stock_id#">#htmlEditFormat(stock_code)##len(trim(product_name)) ? " — " & htmlEditFormat(product_name) : ""#</option>
            </cfloop>
            </cfoutput>
        </select>
        <button class="btn-add" onclick="goToTree()">
            <i class="fas fa-sitemap"></i>Ağacı Aç
        </button>
    </div>
</div>

<div class="px-3 pb-5">
    <cfif isDefined("url.success")>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <strong>Başarılı!</strong> Ürün ağacı güncellendi.
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Ürün Ağacı Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="ptGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var ptData = #serializeJSON(ptArr)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    $('##ptGrid').dxDataGrid({
        dataSource: ptData,
        keyExpr: 'stock_id',
        showBorders: true, showRowLines: true, rowAlternationEnabled: true,
        columnAutoWidth: true, allowColumnReordering: true,
        allowColumnResizing: true, columnResizingMode: 'widget',
        width: '100%', height: 'auto',
        scrolling: { mode: 'virtual', rowRenderingMode: 'virtual' },
        paging: { pageSize: 50 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [15, 25, 50, 100] },
        filterRow: { visible: true },
        headerFilter: { visible: true },
        searchPanel: { visible: true, width: 240, placeholder: 'Ara...' },
        sorting: { mode: 'multiple' },
        columnChooser: { enabled: true, mode: 'select', title: 'Sütun Seçimi' },
        export: { enabled: true },
        onExporting: function (e) {
            var workbook = new ExcelJS.Workbook();
            var worksheet = workbook.addWorksheet('UrunAgaclari');
            DevExpress.excelExporter.exportDataGrid({
                component: e.component,
                worksheet: worksheet,
                autoFilterEnabled: true
            }).then(function () {
                workbook.xlsx.writeBuffer().then(function (buffer) {
                    var fileName = 'urun_agaclari_' + new Date().toISOString().slice(0, 10) + '.xlsx';
                    saveAs(new Blob([buffer], { type: 'application/octet-stream' }), fileName);
                });
            });
            e.cancel = true;
        },
        onRowDblClick: function(e) { viewTree(e.data.stock_id); },
        onContentReady: function(e) {
            document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt';
        },
        columns: [
            { dataField: 'stock_id',    caption: 'ID',         width: 65, alignment: 'center', dataType: 'number' },
            { dataField: 'stock_code',  caption: 'Stok Kodu',  width: 160,
                cellTemplate: function(c, o) {
                    $('<a>').attr('href', 'javascript:void(0)').css({ fontWeight: 'bold', cursor: 'pointer' })
                        .text(o.value || '-').on('click', function() { viewTree(o.data.stock_id); }).appendTo(c);
                }
            },
            { dataField: 'product_name',caption: 'Ürün Adı',   minWidth: 220,
                cellTemplate: function(c, o) {
                    $('<a>').attr('href', 'javascript:void(0)').css({ cursor: 'pointer' })
                        .text(o.value || '-').on('click', function() { viewTree(o.data.stock_id); }).appendTo(c);
                }
            },
            { dataField: 'product_cat', caption: 'Kategori',   width: 180,
                cellTemplate: function(c, o) { $('<span>').addClass('small text-muted').text(o.value || '-').appendTo(c); }
            },
            { dataField: 'row_count',   caption: 'Satır Sayısı', width: 110, alignment: 'center', dataType: 'number' },
            { dataField: 'last_update', caption: 'Son Güncelleme', width: 140 },
            {
                caption: 'İşlemler', width: 110, alignment: 'center', allowSorting: false, allowFiltering: false,
                cellTemplate: function(c, o) {
                    var g = $('<div>').addClass('d-flex gap-1 justify-content-center');
                    $('<button>').addClass('btn btn-sm btn-outline-primary').attr('title', 'Ağacı Görüntüle')
                        .html('<i class="fas fa-sitemap"></i>')
                        .on('click', function() { viewTree(o.data.stock_id); })
                        .appendTo(g);
                    g.appendTo(c);
                }
            }
        ]
    });
});

function goToTree() {
    var id = document.getElementById('selectStock').value;
    if (!id || id == '0') { DevExpress.ui.notify('Lütfen bir stok seçiniz.', 'warning', 2500); return; }
    viewTree(id);
}

function viewTree(id) {
    window.location.href = 'index.cfm?fuseaction=product.view_product_tree&stock_id=' + id;
}
</script>
</cfoutput>
