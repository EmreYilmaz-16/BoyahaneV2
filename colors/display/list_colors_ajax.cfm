<cfprocessingdirective pageEncoding="utf-8">

<!--- Renk listesi --->
<cfquery name="getColors" datasource="boyahane">
    SELECT
        ci.color_id,
        ci.stock_id,
        ci.color_code,
        ci.color_name,
        ci.kartela_no,
        ci.renk_tonu,
        ci.boya_derecesi,
        ci.flote,
        ci.is_ready,
        ci.information,
        ci.kartela_date,
        ci.record_date,
        COALESCE(c.nickname, c.fullname, '') AS company_name,
        ci.company_id,
        COALESCE(p.product_name, '')          AS product_name,
        ci.product_id,
        COALESCE(s.stock_code, '')            AS stock_code
    FROM color_info ci
    LEFT JOIN company c  ON ci.company_id = c.company_id
    LEFT JOIN product p  ON ci.product_id = p.product_id
    LEFT JOIN stocks  s  ON ci.stock_id   = s.stock_id
    ORDER BY ci.record_date DESC
</cfquery>

<cfset colorsArr = []>
<cfloop query="getColors">
    <cfset arrayAppend(colorsArr, {
        "color_id"     : val(color_id),
        "stock_id"     : val(stock_id),
        "color_code"   : color_code    ?: "",
        "color_name"   : color_name    ?: "",
        "kartela_no"   : kartela_no    ?: "",
        "renk_tonu"    : isNumeric(renk_tonu) ? val(renk_tonu) : 0,
        "boya_derecesi": boya_derecesi ?: "",
        "flote"        : isNumeric(flote) ? val(flote) : 0,
        "is_ready"     : is_ready,
        "information"  : information   ?: "",
        "kartela_date" : isDate(kartela_date) ? dateFormat(kartela_date,"dd/mm/yyyy") : "",
        "company_id"   : val(company_id),
        "company_name" : company_name  ?: "",
        "product_id"   : val(product_id),
        "product_name" : product_name  ?: "",
        "stock_code"   : stock_code    ?: "",
        "record_date"  : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-palette"></i></div>
        <div class="page-header-title">
            <h1>Renk Kartoteksi</h1>
            <p>Tüm renk kayıtlarını görüntüleyin ve yönetin</p>
        </div>
    </div>
    <a class="btn-add" href="index.cfm?fuseaction=colors.add_color">
        <i class="fas fa-plus"></i>Yeni Renk
    </a>
</div>

<cfif isDefined("url.success")>
    <cfoutput>
    <div class="alert alert-success alert-dismissible fade show mb-3 mx-3">
        <i class="fas fa-check-circle me-2"></i>
        <cfif url.success eq "added"><strong>Başarılı!</strong> Renk oluşturuldu.
        <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Renk güncellendi.
        <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Renk silindi.
        </cfif>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    </cfoutput>
</cfif>

<div class="px-3 pb-5">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Renk Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="colorGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var colorData = #serializeJSON(colorsArr)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    initGrid();
});

function initGrid() {
    $('##colorGrid').dxDataGrid({
        dataSource: colorData,
        keyExpr: 'color_id',
        showBorders: true, showRowLines: true, showColumnLines: true,
        rowAlternationEnabled: true, columnAutoWidth: false,
        allowColumnReordering: true, allowColumnResizing: true, columnResizingMode: 'widget',
        paging:      { enabled: true, pageSize: 50 },
        filterRow:   { visible: true },
        headerFilter:{ visible: true },
        searchPanel: { visible: true, width: 240, placeholder: 'Ara...' },
        sorting:     { mode: 'multiple' },
        columnChooser: { enabled: true, mode: 'select', title: 'Sütun Seçimi' },
        onContentReady: function(e) {
            document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt';
        },
        columns: [
            { dataField: 'color_code',    caption: 'Renk Kodu',   width: 120 },
            { dataField: 'color_name',    caption: 'Renk Adı',    minWidth: 150 },
            { dataField: 'company_name',  caption: 'Müşteri',     minWidth: 160 },
            { dataField: 'product_name',  caption: 'Ürün',        minWidth: 150 },
            { dataField: 'kartela_no',    caption: 'Kartela',     width: 120 },
            { dataField: 'kartela_date',  caption: 'K.Tarihi',    width: 110, alignment: 'center' },
            { dataField: 'renk_tonu',     caption: 'R.Tonu',      width: 80, alignment: 'center' },
            { dataField: 'boya_derecesi', caption: 'Boya C',      width: 90 },
            { dataField: 'flote',         caption: 'Flote',       width: 80, alignment: 'right',
              format: { type: 'fixedPoint', precision: 2 } },
            { dataField: 'is_ready',      caption: 'Hazır',       width: 70, alignment: 'center', dataType: 'boolean' },
            { dataField: 'information',   caption: 'Açıklama',    minWidth: 120,
              cellTemplate: function(c,o){ $('<span>').addClass('small text-muted').text(o.value||'').appendTo(c); } },
            {
                caption: 'İşlemler', width: 130, alignment: 'center', allowSorting: false, allowFiltering: false,
                cellTemplate: function(c, o) {
                    var g = $('<div>').addClass('d-flex gap-1 justify-content-center');
                    $('<a>').addClass('btn btn-sm btn-outline-primary').attr('title','Düzenle')
                        .attr('href','index.cfm?fuseaction=colors.add_color&stock_id='+o.data.stock_id)
                        .html('<i class="fas fa-edit"></i>').appendTo(g);
                    $('<a>').addClass('btn btn-sm btn-outline-secondary').attr('title','Reçeteyi Görüntüle')
                        .attr('href','index.cfm?fuseaction=product.view_product_tree&stock_id='+o.data.stock_id)
                        .html('<i class="fas fa-sitemap"></i>').appendTo(g);
                    $('<button>').addClass('btn btn-sm btn-outline-danger').attr('title','Sil')
                        .html('<i class="fas fa-trash"></i>')
                        .on('click', function(){ deleteColor(o.data.color_id, o.data.color_code || o.data.color_name); })
                        .appendTo(g);
                    g.appendTo(c);
                }
            }
        ]
    });
}

function deleteColor(id, label) {
    DevExpress.ui.dialog.confirm(
        '"' + label + '" rengini silmek istiyor musunuz?', 'Silme Onayı'
    ).then(function(ok) {
        if (!ok) return;
        $.post('/colors/form/delete_color.cfm', { color_id: id }, function(res) {
            if (res && res.success) {
                colorData = colorData.filter(function(x){ return x.color_id !== id; });
                $('##colorGrid').dxDataGrid('instance').option('dataSource', colorData);
                DevExpress.ui.notify('Renk silindi.', 'success', 2500);
            } else {
                DevExpress.ui.notify((res && res.message) || 'Silme başarısız.', 'error', 3500);
            }
        }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); });
    });
}
</script>
</cfoutput>