<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getPriceCats" datasource="boyahane">
    SELECT
        pc.price_catid,
        pc.price_cat,
        pc.price_cat_status,
        pc.is_kdv,
        pc.is_sales,
        pc.is_purchase,
        pc.margin,
        pc.discount,
        pc.startdate,
        pc.finishdate,
        pc.valid_date,
        pc.record_date,
        sm.money_name,
        sm.money_symbol,
        (SELECT COUNT(*) FROM price p WHERE p.price_catid = pc.price_catid) AS price_count
    FROM price_cat pc
    LEFT JOIN setup_money sm ON pc.money_id = sm.money_id
    ORDER BY pc.price_catid DESC
</cfquery>

<cfset catsArray = []>
<cfloop query="getPriceCats">
    <cfset arrayAppend(catsArray, {
        "price_catid":      price_catid,
        "price_cat":        price_cat ?: "",
        "price_cat_status": price_cat_status,
        "is_kdv":           is_kdv,
        "is_sales":         is_sales,
        "is_purchase":      is_purchase,
        "margin":           isNumeric(margin)   ? margin   : 0,
        "discount":         isNumeric(discount) ? discount : 0,
        "money_name":       money_name ?: "TRY",
        "money_symbol":     money_symbol ?: "₺",
        "price_count":      price_count,
        "startdate":        isDate(startdate)  ? dateFormat(startdate,  "dd/mm/yyyy") : "",
        "finishdate":       isDate(finishdate) ? dateFormat(finishdate, "dd/mm/yyyy") : "",
        "valid_date":       isDate(valid_date) ? dateFormat(valid_date, "dd/mm/yyyy") : "",
        "record_date":      isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") & " " & timeFormat(record_date,"HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-tags"></i></div>
        <div class="page-header-title">
            <h1>Fiyat Listeleri</h1>
            <p>Fiyat kategorileri ve ürün fiyatlarını yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="addPriceCat()">
        <i class="fas fa-plus"></i>Yeni Fiyat Listesi
    </button>
</div>

<div class="px-3">

    <!--- Özet Kartlar --->
    <cfoutput>
    <div class="row g-3 mb-3">
        <div class="col-sm-6 col-xl-3">
            <div class="summary-card">
                <div class="summary-icon bg-primary"><i class="fas fa-tags"></i></div>
                <div class="summary-info">
                    <div class="summary-value">#getPriceCats.recordCount#</div>
                    <div class="summary-label">Toplam Liste</div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-3">
            <div class="summary-card">
                <div class="summary-icon bg-success"><i class="fas fa-check-circle"></i></div>
                <div class="summary-info">
                    <cfset activeCount = 0>
                    <cfloop query="getPriceCats"><cfif price_cat_status><cfset activeCount++></cfif></cfloop>
                    <div class="summary-value">#activeCount#</div>
                    <div class="summary-label">Aktif</div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-3">
            <div class="summary-card">
                <div class="summary-icon bg-info"><i class="fas fa-box"></i></div>
                <div class="summary-info">
                    <cfset totalPrices = 0>
                    <cfloop query="getPriceCats"><cfset totalPrices += price_count></cfloop>
                    <div class="summary-value">#totalPrices#</div>
                    <div class="summary-label">Toplam Fiyat Girişi</div>
                </div>
            </div>
        </div>
        <div class="col-sm-6 col-xl-3">
            <div class="summary-card">
                <div class="summary-icon bg-warning"><i class="fas fa-shopping-tag"></i></div>
                <div class="summary-info">
                    <cfset salesCount = 0>
                    <cfloop query="getPriceCats"><cfif is_sales><cfset salesCount++></cfif></cfloop>
                    <div class="summary-value">#salesCount#</div>
                    <div class="summary-label">Satış Listesi</div>
                </div>
            </div>
        </div>
    </div>
    </cfoutput>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title">
                <i class="fas fa-list"></i>Fiyat Listeleri
            </div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="priceCatGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var priceCatData = #serializeJSON(catsArray)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $('##priceCatGrid').dxDataGrid({
            dataSource: priceCatData,
            showBorders: true,
            showRowLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            allowColumnReordering: true,
            allowColumnResizing: true,
            columnResizingMode: 'widget',
            paging: { pageSize: 25 },
            pager: {
                visible: true,
                allowedPageSizes: [10, 25, 50],
                showPageSizeSelector: true,
                showNavigationButtons: true,
                showInfo: true,
                infoText: 'Sayfa {0} / {1} ({2} kayıt)'
            },
            filterRow: { visible: true, applyFilter: 'auto' },
            headerFilter: { visible: true },
            searchPanel: { visible: true, width: 220, placeholder: 'Ara...' },
            export: { enabled: true },
            onExporting: function (e) {
                var workbook = new ExcelJS.Workbook();
                var worksheet = workbook.addWorksheet('FiyatListeleri');
                DevExpress.excelExporter.exportDataGrid({
                    component: e.component,
                    worksheet: worksheet,
                    autoFilterEnabled: true
                }).then(function () {
                    workbook.xlsx.writeBuffer().then(function (buffer) {
                        var fileName = 'fiyat_listeleri_' + new Date().toISOString().slice(0, 10) + '.xlsx';
                        saveAs(new Blob([buffer], { type: 'application/octet-stream' }), fileName);
                    });
                });
                e.cancel = true;
            },
            onContentReady: function(e) {
                document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt';
            },
            columns: [
                { dataField: 'price_catid', caption: 'ID', width: 70, alignment: 'center', sortOrder: 'desc' },
                {
                    dataField: 'price_cat', caption: 'Liste Adı', minWidth: 180,
                    cellTemplate: function(c, o) {
                        $('<a>').attr('href', '##').addClass('fw-semibold text-decoration-none')
                            .text(o.value)
                            .on('click', function(e) {
                                e.preventDefault();
                                managePrices(o.data.price_catid);
                            })
                            .appendTo(c);
                    }
                },
                {
                    dataField: 'money_name', caption: 'Para Birimi', width: 110, alignment: 'center',
                    cellTemplate: function(c, o) {
                        $('<span>').addClass('badge bg-info').text(o.value || 'TRY').appendTo(c);
                    }
                },
                {
                    dataField: 'is_sales', caption: 'Satış', width: 75, alignment: 'center', dataType: 'boolean',
                    cellTemplate: function(c, o) {
                        $('<i>').addClass('fas fa-' + (o.value ? 'check text-success' : 'times text-muted')).appendTo(c);
                    }
                },
                {
                    dataField: 'is_purchase', caption: 'Alış', width: 75, alignment: 'center', dataType: 'boolean',
                    cellTemplate: function(c, o) {
                        $('<i>').addClass('fas fa-' + (o.value ? 'check text-success' : 'times text-muted')).appendTo(c);
                    }
                },
                {
                    dataField: 'is_kdv', caption: 'KDV Dahil', width: 95, alignment: 'center', dataType: 'boolean',
                    cellTemplate: function(c, o) {
                        $('<span>').addClass('badge ' + (o.value ? 'bg-success' : 'bg-secondary')).text(o.value ? 'Dahil' : 'Hariç').appendTo(c);
                    }
                },
                { dataField: 'margin',   caption: 'Marj %',  width: 80, alignment: 'right', dataType: 'number', format: { type:'fixedPoint', precision:2 } },
                { dataField: 'discount', caption: 'İnd. %',  width: 80, alignment: 'right', dataType: 'number', format: { type:'fixedPoint', precision:2 } },
                {
                    dataField: 'price_count', caption: 'Fiyat', width: 80, alignment: 'center',
                    cellTemplate: function(c, o) {
                        $('<span>').addClass('badge bg-primary').text(o.value || 0).appendTo(c);
                    }
                },
                {
                    dataField: 'price_cat_status', caption: 'Durum', width: 90, alignment: 'center',
                    cellTemplate: function(c, o) {
                        $('<span>').addClass('status-badge ' + (o.value ? 'status-active' : 'status-passive'))
                            .text(o.value ? 'Aktif' : 'Pasif').appendTo(c);
                    }
                },
                {
                    caption: 'İşlemler', width: 160, alignment: 'center', allowSorting: false, allowFiltering: false,
                    cellTemplate: function(c, o) {
                        var wrap = $('<div>').addClass('d-flex gap-1 justify-content-center');
                        $('<button>').addClass('btn btn-sm btn-outline-primary')
                            .html('<i class="fas fa-edit"></i>')
                            .attr('title', 'Düzenle')
                            .on('click', function() { editPriceCat(o.data.price_catid); })
                            .appendTo(wrap);
                        $('<button>').addClass('btn btn-sm btn-outline-success')
                            .html('<i class="fas fa-list-ul"></i>')
                            .attr('title', 'Fiyatları Yönet')
                            .on('click', function() { managePrices(o.data.price_catid); })
                            .appendTo(wrap);
                        $('<button>').addClass('btn btn-sm btn-outline-danger')
                            .html('<i class="fas fa-trash"></i>')
                            .attr('title', 'Sil')
                            .on('click', function() { deletePriceCat(o.data.price_catid, o.data.price_cat); })
                            .appendTo(wrap);
                        wrap.appendTo(c);
                    }
                }
            ]
        });
    }
});

function addPriceCat() {
    window.location.href = 'index.cfm?fuseaction=price.add_price_cat';
}
function editPriceCat(id) {
    window.location.href = 'index.cfm?fuseaction=price.add_price_cat&price_catid=' + id;
}
function managePrices(id) {
    window.location.href = 'index.cfm?fuseaction=price.list_price&price_catid=' + id;
}
function deletePriceCat(id, name) {
    if (!confirm('«' + name + '» fiyat listesini silmek istediğinizden emin misiniz?\nBağlı tüm fiyat kayıtları da silinecek!')) return;
    $.ajax({
        url: '/price/form/delete_price_cat.cfm', method: 'POST',
        data: { price_catid: id }, dataType: 'json',
        success: function(res) {
            if (res.success) location.reload();
            else alert('Hata: ' + (res.message || ''));
        }
    });
}
</script>
</cfoutput>
