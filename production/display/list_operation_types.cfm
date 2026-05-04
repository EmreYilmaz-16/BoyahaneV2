<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getOperations" datasource="boyahane">
    SELECT ot.operation_type_id,
           ot.operation_type,
           ot.operation_code,
           ot.operation_cost,
           COALESCE(ot.money,'')         AS money,
           COALESCE(ot.o_hour, 0)        AS o_hour,
           COALESCE(ot.o_minute, 0)      AS o_minute,
           COALESCE(ot.operation_status, false) AS operation_status,
           COALESCE(ot.comment,'')       AS comment,
           COALESCE(ot.comment2,'')      AS comment2,
           COALESCE(ot.ezgi_h_sure, 0)   AS ezgi_h_sure,
           COALESCE(ot.ezgi_formul,'')   AS ezgi_formul,
           COALESCE(ot.stock_id, 0)      AS stock_id,
           COALESCE(ot.product_name,'')  AS product_name,
           COALESCE(st.stock_code,'')    AS stock_code,
           ot.record_date
    FROM operation_types ot
    LEFT JOIN stocks st ON ot.stock_id = st.stock_id
    ORDER BY ot.operation_type_id DESC
</cfquery>

<cfset opArr = []>
<cfloop query="getOperations">
    <cfset arrayAppend(opArr, {
        "operation_type_id": val(operation_type_id),
        "operation_type":    operation_type    ?: "",
        "operation_code":    operation_code    ?: "",
        "operation_cost":    isNumeric(operation_cost) ? val(operation_cost) : 0,
        "money":             money             ?: "",
        "o_hour":            val(o_hour),
        "o_minute":          val(o_minute),
        "operation_status":  operation_status,
        "comment":           comment           ?: "",
        "stock_id":          val(stock_id),
        "stock_code":        stock_code        ?: "",
        "product_name":      product_name      ?: "",
        "ezgi_h_sure":       isNumeric(ezgi_h_sure) ? val(ezgi_h_sure) : 0,
        "ezgi_formul":       ezgi_formul       ?: "",
        "record_date":       isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") & " " & timeFormat(record_date,"HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-cogs"></i></div>
        <div class="page-header-title">
            <h1>Operasyon Tipleri</h1>
            <p>Üretim operasyon tipleri ve süreleri</p>
        </div>
    </div>
    <button class="btn-add" onclick="addOperation()">
        <i class="fas fa-plus"></i>Yeni Operasyon
    </button>
</div>

<div class="px-3 pb-5">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Operasyon tipi oluşturuldu.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Operasyon tipi güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Operasyon tipi silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Operasyon Tipi Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="operationGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var opData = #serializeJSON(opArr)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $('##operationGrid').dxDataGrid({
            dataSource: opData,
            showBorders: true, showRowLines: true, showColumnLines: true,
            rowAlternationEnabled: true, columnAutoWidth: true,
            allowColumnReordering: true, allowColumnResizing: true, columnResizingMode: 'widget',
            width: '100%', height: 'auto',
            scrolling: { mode: 'virtual', rowRenderingMode: 'virtual' },
            paging: { pageSize: 50 },
            pager: { visible:true, allowedPageSizes:[10,25,50,100], showPageSizeSelector:true, showNavigationButtons:true, showInfo:true, infoText:'Sayfa {0}/{1} ({2} kayıt)' },
            filterRow: { visible:true }, headerFilter: { visible:true },
            searchPanel: { visible:true, width:240, placeholder:'Ara...' },
            sorting: { mode:'multiple' },
            columnChooser: { enabled:true, mode:'select', title:'Sütun Seçimi' },
            export: { enabled: true },
            onExporting: function (e) {
                var workbook = new ExcelJS.Workbook();
                var worksheet = workbook.addWorksheet('OperasyonTipleri');
                DevExpress.excelExporter.exportDataGrid({
                    component: e.component,
                    worksheet: worksheet,
                    autoFilterEnabled: true
                }).then(function () {
                    workbook.xlsx.writeBuffer().then(function (buffer) {
                        var fileName = 'operasyon_tipleri_' + new Date().toISOString().slice(0, 10) + '.xlsx';
                        saveAs(new Blob([buffer], { type: 'application/octet-stream' }), fileName);
                    });
                });
                e.cancel = true;
            },
            onRowDblClick: function(e) { editOperation(e.data.operation_type_id); },
            onContentReady: function(e) { document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt'; },
            columns: [
                { dataField:'operation_type_id', caption:'ID', width:65, alignment:'center', dataType:'number', sortOrder:'desc' },
                { dataField:'operation_code',    caption:'Kod', width:110,
                    cellTemplate: function(c,o){ $('<span>').addClass('font-monospace small').text(o.value||'-').appendTo(c); }
                },
                { dataField:'operation_type',    caption:'Operasyon Adı', minWidth:200,
                    cellTemplate: function(c,o){
                        $('<a>').attr('href','javascript:void(0)').css({fontWeight:'bold',cursor:'pointer'})
                            .text(o.value||'-').on('click',function(){ editOperation(o.data.operation_type_id); }).appendTo(c);
                    }
                },
                { dataField:'operation_cost',    caption:'Maliyet', width:110, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'money',             caption:'Para Birimi', width:90 },
                { dataField:'o_hour',            caption:'Saat', width:70, alignment:'center', dataType:'number' },
                { dataField:'o_minute',          caption:'Dakika', width:75, alignment:'center', dataType:'number' },
                { dataField:'ezgi_h_sure',       caption:'H.Süre', width:80, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'stock_code',        caption:'Stok Kodu', width:140,
                    cellTemplate: function(c,o){
                        if (o.value) $('<span>').addClass('badge bg-light text-dark border').text(o.value).appendTo(c);
                        else $('<span>').addClass('text-muted').text('-').appendTo(c);
                    }
                },
                { dataField:'comment',           caption:'Açıklama', minWidth:160,
                    cellTemplate: function(c,o){ $('<span>').addClass('small text-muted').text(o.value||'-').appendTo(c); }
                },
                { dataField:'operation_status',  caption:'Durum', width:90, alignment:'center',
                    cellTemplate: function(c,o){
                        $('<span>').addClass(o.value ? 'badge bg-success' : 'badge bg-secondary').text(o.value ? 'Aktif' : 'Pasif').appendTo(c);
                    }
                },
                { dataField:'record_date', caption:'Kayıt Tarihi', width:135 },
                {
                    caption:'İşlemler', width:100, alignment:'center', allowSorting:false, allowFiltering:false,
                    cellTemplate: function(c,o) {
                        var g = $('<div>').addClass('d-flex gap-1 justify-content-center');
                        $('<button>').addClass('btn btn-sm btn-outline-primary').attr('title','Düzenle').html('<i class="fas fa-edit"></i>')
                            .on('click', function(){ editOperation(o.data.operation_type_id); }).appendTo(g);
                        $('<button>').addClass('btn btn-sm btn-outline-danger').attr('title','Sil').html('<i class="fas fa-trash"></i>')
                            .on('click', function(){ deleteOperation(o.data.operation_type_id, o.data.operation_type); }).appendTo(g);
                        g.appendTo(c);
                    }
                }
            ],
            summary: {
                totalItems: [{ column:'operation_type_id', summaryType:'count', displayFormat:'{0} operasyon' }]
            }
        });
    }
});

function addOperation()       { window.location.href = 'index.cfm?fuseaction=production.add_operation_type'; }
function editOperation(id)    { window.location.href = 'index.cfm?fuseaction=production.add_operation_type&operation_type_id=' + id; }

function deleteOperation(id, name) {
    DevExpress.ui.dialog.confirm('"' + (name||id) + '" operasyon tipini silmek istiyor musunuz?', 'Silme Onayı')
        .then(function(ok) {
            if (!ok) return;
            $.post('/production/form/delete_operation_type.cfm', { operation_type_id: id }, function(res) {
                if (res && res.success) {
                    DevExpress.ui.notify('Operasyon tipi silindi.', 'success', 2500);
                    opData = opData.filter(function(x){ return x.operation_type_id != id; });
                    $('##operationGrid').dxDataGrid('instance').option('dataSource', opData);
                    document.getElementById('recordCount').textContent = opData.length + ' kayıt';
                } else {
                    DevExpress.ui.notify((res && res.message) || 'Silme başarısız.', 'error', 3500);
                }
            }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); });
        });
}
</script>
</cfoutput>
