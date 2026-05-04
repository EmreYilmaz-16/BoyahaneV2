<cfprocessingdirective pageEncoding="utf-8">

<!--- Stok Fişlerini getir --->
<cfquery name="getFisler" datasource="boyahane">
    SELECT 
        sf.fis_id,
        sf.fis_type,
        sf.fis_number,
        sf.fis_date,
        sf.deliver_date,
        sf.employee_id,
        sf.fis_detail,
        sf.is_production,
        sf.is_stock_transfer,
        sf.ref_no,
        sf.record_date,
        sf.record_emp,
        sf.update_date,
        COALESCE((
            SELECT COUNT(*) FROM stock_fis_row sfr WHERE sfr.fis_id = sf.fis_id
        ), 0) AS row_count,
        COALESCE((
            SELECT SUM(sfr.amount) FROM stock_fis_row sfr WHERE sfr.fis_id = sf.fis_id
        ), 0) AS total_amount
    FROM stock_fis sf
    ORDER BY sf.fis_id DESC
</cfquery>

<!--- Veriyi JSON'a çevir --->
<cfset fisArray = []>
<cfloop query="getFisler">
    <cfset fisType = "">
    <cfif fis_type eq 1>
        <cfset fisType = "Giriş">
    <cfelseif fis_type eq 2>
        <cfset fisType = "Çıkış">
    <cfelseif fis_type eq 3>
        <cfset fisType = "Transfer">
    <cfelseif fis_type eq 4>
        <cfset fisType = "Sayım">
    <cfelse>
        <cfset fisType = "Diğer">
    </cfif>

    <cfset fisObj = {
        "fis_id"          = fis_id,
        "fis_type"        = fis_type,
        "fis_type_label"  = fisType,
        "fis_number"      = fis_number ?: "",
        "fis_date"        = isDate(fis_date) ? dateFormat(fis_date, "dd/mm/yyyy") & " " & timeFormat(fis_date, "HH:mm") : "",
        "deliver_date"    = isDate(deliver_date) ? dateFormat(deliver_date, "dd/mm/yyyy") : "",
        "employee_id"     = employee_id ?: 0,
        "fis_detail"      = fis_detail ?: "",
        "ref_no"          = ref_no ?: "",
        "is_production"   = is_production,
        "is_stock_transfer" = is_stock_transfer ?: 0,
        "row_count"       = row_count,
        "total_amount"    = total_amount,
        "record_date"     = isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : ""
    }>
    <cfset arrayAppend(fisArray, fisObj)>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-file-invoice"></i>
        </div>
        <div class="page-header-title">
            <h1>Stok Fişleri</h1>
            <p>Tüm stok giriş/çıkış fişlerini görüntüleyin ve yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="addFis()">
        <i class="fas fa-plus"></i>Yeni Fiş
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added">
                <strong>Başarılı!</strong> Fiş başarıyla oluşturuldu.
            <cfelseif url.success eq "updated">
                <strong>Başarılı!</strong> Fiş başarıyla güncellendi.
            <cfelseif url.success eq "deleted">
                <strong>Başarılı!</strong> Fiş başarıyla silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <!--- Özet Kartlar --->
    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="summary-card summary-card-blue">
                <div class="summary-icon"><i class="fas fa-file-invoice"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Fiş</span>
                    <span class="summary-value" id="sumTotal">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-arrow-down"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Giriş Fişleri</span>
                    <span class="summary-value" id="sumGiris">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-red">
                <div class="summary-icon"><i class="fas fa-arrow-up"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Çıkış Fişleri</span>
                    <span class="summary-value" id="sumCikis">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-exchange-alt"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Transfer Fişleri</span>
                    <span class="summary-value" id="sumTransfer">-</span>
                </div>
            </div>
        </div>
    </div>

    <!--- DataGrid --->
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title">
                <i class="fas fa-list"></i>Fiş Listesi
            </div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="fisGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<style>
.summary-card {
    display: flex;
    align-items: center;
    gap: 14px;
    padding: 16px 20px;
    border-radius: 10px;
    color: ##fff;
    box-shadow: 0 2px 10px rgba(0,0,0,0.12);
}
.summary-card-blue   { background: linear-gradient(135deg,##1a3a5c,##2563ab); }
.summary-card-green  { background: linear-gradient(135deg,##15803d,##22c55e); }
.summary-card-red    { background: linear-gradient(135deg,##991b1b,##ef4444); }
.summary-card-orange { background: linear-gradient(135deg,##92400e,##f59e0b); }
.summary-icon { font-size: 1.8rem; opacity: .85; }
.summary-label { font-size: .75rem; opacity: .85; display: block; }
.summary-value { font-size: 1.6rem; font-weight: 700; display: block; }
</style>

<script>
var fisData = #serializeJSON(fisArray)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') {
        DevExpress.localization.locale('tr');
    }

    // Özet hesapla
    var giris = fisData.filter(function(r){ return r.fis_type == 1; }).length;
    var cikis = fisData.filter(function(r){ return r.fis_type == 2; }).length;
    var transfer = fisData.filter(function(r){ return r.fis_type == 3; }).length;
    document.getElementById('sumTotal').textContent = fisData.length;
    document.getElementById('sumGiris').textContent = giris;
    document.getElementById('sumCikis').textContent = cikis;
    document.getElementById('sumTransfer').textContent = transfer;

    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $("##fisGrid").dxDataGrid({
            dataSource: fisData,
            showBorders: true,
            showRowLines: true,
            showColumnLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            wordWrapEnabled: false,
            allowColumnReordering: true,
            allowColumnResizing: true,
            columnResizingMode: 'widget',

            paging: { pageSize: 25 },
            pager: {
                visible: true,
                allowedPageSizes: [10, 25, 50, 100],
                showPageSizeSelector: true,
                showNavigationButtons: true,
                showInfo: true,
                infoText: 'Sayfa {0} / {1} ({2} kayıt)'
            },
            filterRow: { visible: true, applyFilter: 'auto' },
            headerFilter: { visible: true },
            searchPanel: { visible: true, width: 240, placeholder: 'Ara...' },
            sorting: { mode: 'multiple' },
            columnChooser: { enabled: true, mode: 'select', title: 'Sütun Seçimi' },
            groupPanel: { visible: true, emptyPanelText: 'Gruplamak için sütun başlığını sürükleyin' },
            grouping: { autoExpandAll: false },
            export: {
                enabled: true,
                allowExportSelectedData: false
            },
            onExporting: function (e) {
                var workbook = new ExcelJS.Workbook();
                var worksheet = workbook.addWorksheet('StokFisleri');
                DevExpress.excelExporter.exportDataGrid({
                    component: e.component,
                    worksheet: worksheet,
                    autoFilterEnabled: true
                }).then(function () {
                    workbook.xlsx.writeBuffer().then(function (buffer) {
                        var fileName = 'stok_fisleri_' + new Date().toISOString().slice(0, 10) + '.xlsx';
                        saveAs(new Blob([buffer], { type: 'application/octet-stream' }), fileName);
                    });
                });
                e.cancel = true;
            },

            onRowDblClick: function(e) {
                openFis(e.data.fis_id);
            },

            onContentReady: function(e) {
                var count = e.component.totalCount();
                document.getElementById('recordCount').textContent = count + ' kayıt';
            },

            columns: [
                {
                    dataField: 'fis_id',
                    caption: 'Fiş No',
                    width: 90,
                    alignment: 'center',
                    dataType: 'number',
                    sortOrder: 'desc'
                },
                {
                    dataField: 'fis_number',
                    caption: 'Fiş Numarası',
                    width: 140,
                    cellTemplate: function(con, opt) {
                        if (opt.value) {
                            $('<a>').attr('href', '##').addClass('fw-bold text-decoration-none')
                                .text(opt.value)
                                .on('click', function(e) {
                                    e.preventDefault();
                                    openFis(opt.data.fis_id);
                                })
                                .appendTo(con);
                        } else {
                            $('<span>').addClass('text-muted').text('-').appendTo(con);
                        }
                    }
                },
                {
                    dataField: 'fis_type_label',
                    caption: 'Fiş Tipi',
                    width: 110,
                    cellTemplate: function(con, opt) {
                        var cls = 'bg-secondary';
                        if (opt.data.fis_type == 1) cls = 'bg-success';
                        else if (opt.data.fis_type == 2) cls = 'bg-danger';
                        else if (opt.data.fis_type == 3) cls = 'bg-warning text-dark';
                        else if (opt.data.fis_type == 4) cls = 'bg-info';
                        $('<span>').addClass('badge ' + cls).text(opt.value).appendTo(con);
                    }
                },
                {
                    dataField: 'fis_date',
                    caption: 'Fiş Tarihi',
                    width: 130
                },
                {
                    dataField: 'deliver_date',
                    caption: 'Teslim Tarihi',
                    width: 120,
                    cellTemplate: function(con, opt) {
                        if (opt.value) {
                            con.text(opt.value);
                        } else {
                            $('<span>').addClass('text-muted').text('-').appendTo(con);
                        }
                    }
                },
                {
                    dataField: 'ref_no',
                    caption: 'Referans No',
                    width: 150,
                    cellTemplate: function(con, opt) {
                        if (opt.value) {
                            $('<span>').addClass('font-monospace small').text(opt.value).appendTo(con);
                        } else {
                            $('<span>').addClass('text-muted').text('-').appendTo(con);
                        }
                    }
                },
                {
                    dataField: 'row_count',
                    caption: 'Kalem Sayısı',
                    width: 110,
                    alignment: 'center',
                    dataType: 'number',
                    cellTemplate: function(con, opt) {
                        $('<span>').addClass('badge bg-primary rounded-pill').text(opt.value).appendTo(con);
                    }
                },
                {
                    dataField: 'total_amount',
                    caption: 'Top. Miktar',
                    width: 110,
                    alignment: 'right',
                    dataType: 'number',
                    format: { type: 'fixedPoint', precision: 2 }
                },
                {
                    dataField: 'is_production',
                    caption: 'Üretim',
                    width: 85,
                    alignment: 'center',
                    cellTemplate: function(con, opt) {
                        if (opt.value) {
                            $('<i>').addClass('fas fa-check text-success').appendTo(con);
                        } else {
                            $('<i>').addClass('fas fa-times text-muted').appendTo(con);
                        }
                    }
                },
                {
                    dataField: 'fis_detail',
                    caption: 'Açıklama',
                    minWidth: 180,
                    cellTemplate: function(con, opt) {
                        if (opt.value) {
                            con.text(opt.value);
                        } else {
                            $('<span>').addClass('text-muted').text('-').appendTo(con);
                        }
                    }
                },
                {
                    dataField: 'record_date',
                    caption: 'Kayıt Tarihi',
                    width: 130
                },
                {
                    caption: 'İşlemler',
                    width: 120,
                    alignment: 'center',
                    allowSorting: false,
                    allowFiltering: false,
                    cellTemplate: function(con, opt) {
                        var wrap = $('<div>').addClass('d-flex gap-1 justify-content-center');
                        $('<button>')
                            .addClass('btn btn-sm btn-outline-primary')
                            .attr('title', 'Fişi Aç')
                            .html('<i class="fas fa-eye"></i>')
                            .on('click', function(){ openFis(opt.data.fis_id); })
                            .appendTo(wrap);
                        $('<button>')
                            .addClass('btn btn-sm btn-outline-danger')
                            .attr('title', 'Sil')
                            .html('<i class="fas fa-trash"></i>')
                            .on('click', function(){ deleteFis(opt.data.fis_id, opt.data.fis_number); })
                            .appendTo(wrap);
                        wrap.appendTo(con);
                    }
                }
            ]
        });
    }
});

function addFis() {
    window.location.href = 'index.cfm?fuseaction=stock.add_fis';
}

function openFis(fisId) {
    window.location.href = 'index.cfm?fuseaction=stock.add_fis&fis_id=' + fisId;
}

function deleteFis(fisId, fisNumber) {
    var label = fisNumber ? fisNumber : ('##' + fisId);
    if (confirm('Fiş "' + label + '" silinecek. Emin misiniz?')) {
        $.post('stock/form/delete_fis.cfm', { fis_id: fisId }, function(resp) {
            try {
                var r = JSON.parse(resp);
                if (r.success) {
                    window.location.href = 'index.cfm?fuseaction=stock.list_fis&success=deleted';
                } else {
                    alert('Hata: ' + (r.message || 'Silme işlemi başarısız.'));
                }
            } catch(e) {
                alert('Sunucu hatası oluştu.');
            }
        });
    }
}
</script>
</cfoutput>
