<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getOrders" datasource="boyahane">
    SELECT
        po.p_order_id,
        po.p_order_no,
        po.stock_id,
        po.order_id,
        COALESCE(s.stock_code,'')                                           AS stock_code,
        COALESCE(s.property,'')                                             AS stock_property,
        COALESCE(ci.color_code, s.stock_code, '')                          AS color_code,
        COALESCE(ci.color_name, s.property, '')                            AS color_name,
        COALESCE(
            oc.nickname,  oc.fullname,
            orc.nickname, orc.fullname,
            ci_c.nickname, ci_c.fullname,
            ''
        )                                                                   AS company_name,
        COALESCE(o.order_number, '')                                         AS order_number,
        po.station_id,
        COALESCE(ws.station_name,'')          AS station_name,
        COALESCE(po.quantity, 0)              AS quantity,
        COALESCE(po.lot_no,'')                AS lot_no,
        po.start_date,
        po.finish_date,
        po.finish_date_real,
        COALESCE(po.status, 1)                AS status,
        COALESCE(po.detail,'')                AS detail,
        COALESCE(po.record_date, CURRENT_TIMESTAMP) AS record_date
    FROM production_orders po
    LEFT JOIN stocks      s    ON po.stock_id    = s.stock_id
    LEFT JOIN color_info  ci   ON po.stock_id    = ci.stock_id
    LEFT JOIN company     ci_c ON ci.company_id  = ci_c.company_id
    LEFT JOIN orders      o    ON po.order_id    = o.order_id
    LEFT JOIN company     oc   ON o.company_id   = oc.company_id
    LEFT JOIN production_orders_row por ON por.p_order_id = po.p_order_id
    LEFT JOIN order_row   orw  ON por.order_row_id = orw.order_row_id
    LEFT JOIN orders      or2  ON orw.order_id   = or2.order_id
    LEFT JOIN company     orc  ON or2.company_id = orc.company_id
    LEFT JOIN workstations ws  ON po.station_id  = ws.station_id
    ORDER BY po.p_order_id DESC
</cfquery>

<cfset ordersArr = []>
<cfloop query="getOrders">
    <cfset statusLabel = "">
    <cfswitch expression="#status#">
        <cfcase value="1"><cfset statusLabel = "Planlandı"></cfcase>
        <cfcase value="2"><cfset statusLabel = "Devam Ediyor"></cfcase>
        <cfcase value="5"><cfset statusLabel = "Tamamlandı"></cfcase>
        <cfcase value="9"><cfset statusLabel = "İptal"></cfcase>
        <cfdefaultcase><cfset statusLabel = "Bilinmiyor"></cfdefaultcase>
    </cfswitch>
    <cfset arrayAppend(ordersArr, {
        "p_order_id"  : val(p_order_id),
        "p_order_no"  : p_order_no   ?: "",
        "stock_id"    : val(stock_id),
        "stock_code"  : stock_code   ?: "",
        "color_code"  : color_code   ?: "",
        "color_name"  : color_name   ?: "",
        "company_name": company_name ?: "",
        "order_number": order_number  ?: "",
        "station_id"  : val(station_id),
        "station_name": station_name ?: "",
        "quantity"    : isNumeric(quantity) ? val(quantity) : 0,
        "lot_no"      : lot_no       ?: "",
        "start_date"  : isDate(start_date)        ? dateFormat(start_date,"dd/mm/yyyy")        : "",
        "finish_date" : isDate(finish_date)       ? dateFormat(finish_date,"dd/mm/yyyy")       : "",
        "finish_date_real": isDate(finish_date_real) ? dateFormat(finish_date_real,"dd/mm/yyyy") : "",
        "status"      : val(status),
        "status_label": statusLabel,
        "detail"      : detail       ?: "",
        "record_date" : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") : ""
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-industry"></i></div>
        <div class="page-header-title">
            <h1>Üretim Emirleri</h1>
            <p>Boyama emirleri — açma, takip ve sonuçlandırma</p>
        </div>
    </div>
    <button class="btn-add" onclick="addOrder()">
        <i class="fas fa-plus"></i>Yeni Emir
    </button>
</div>

<div class="px-3 pb-5">
    <cfif isDefined("url.success")>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Üretim emri oluşturuldu.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Üretim emri güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Üretim emri silindi.
            <cfelseif url.success eq "finalized"><strong>Başarılı!</strong> Üretim emri tamamlandı.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Emir Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="ordersGrid"></div>
        </div>
    </div>
</div>

<div id="deleteConfirmContainer"></div>

<script>
var ordersData = #serializeJSON(ordersArr)#;

$(function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    buildGrid();
});

var statusColors = { 1: 'secondary', 2: 'primary', 5: 'success', 9: 'danger' };

function buildGrid() {
    $('##ordersGrid').dxDataGrid({
        dataSource: ordersData,
        keyExpr: 'p_order_id',
        showBorders: true,
        rowAlternationEnabled: true,
        columnAutoWidth: false,
        wordWrapEnabled: false,
        width: '100%', height: 'auto',
        scrolling: { mode: 'virtual', rowRenderingMode: 'virtual' },
        paging: { pageSize: 50 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [15,25,50,100], showInfo: true },
        searchPanel: { visible: true, placeholder: 'Ara...' },
        filterRow: { visible: true },
        export: { enabled: true },
        onExporting: function (e) {
            var workbook = new ExcelJS.Workbook();
            var worksheet = workbook.addWorksheet('UretimEmirleri');
            DevExpress.excelExporter.exportDataGrid({
                component: e.component,
                worksheet: worksheet,
                autoFilterEnabled: true
            }).then(function () {
                workbook.xlsx.writeBuffer().then(function (buffer) {
                    var fileName = 'uretim_emirleri_' + new Date().toISOString().slice(0, 10) + '.xlsx';
                    saveAs(new Blob([buffer], { type: 'application/octet-stream' }), fileName);
                });
            });
            e.cancel = true;
        },
        onContentReady: function(e) {
            document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt';
        },
        onRowDblClick: function(e) { viewOrder(e.data.p_order_id); },
        columns: [
            { dataField:'p_order_id',   caption:'ID',         width:65,  alignment:'center', dataType:'number', sortOrder:'desc' },
            { dataField:'p_order_no',   caption:'Emir No',    width:130,
                cellTemplate: function(container, options) {
                    $('<a>').attr('href','javascript:void(0)').css({fontWeight:'bold',cursor:'pointer'})
                        .text(options.value||'-').on('click',function(){ viewOrder(options.data.p_order_id); }).appendTo(container);
                }
            },
            { dataField:'color_code',   caption:'Renk Kodu',  width:110 },
            { dataField:'color_name',   caption:'Renk Adı',   width:160 },
            { dataField:'company_name', caption:'Müşteri',    minWidth:140,
                cellTemplate: function(container, options) {
                    var html = options.value || '';
                    if (options.data.order_number) html += (html ? ' <span style="color:##94a3b8;font-size:.75rem">' : '<span style="font-size:.8rem">') + '(' + options.data.order_number + ')</span>';
                    container.html(html || '<span style="color:##94a3b8">—</span>');
                }
            },
            { dataField:'station_name', caption:'Makina',     width:140 },
            { dataField:'quantity',     caption:'Miktar (kg)',width:100,  alignment:'right', dataType:'number', format: { type:'fixedPoint', precision:2 } },
            { dataField:'lot_no',       caption:'Lot No',     width:110 },
            { dataField:'start_date',   caption:'Başlangıç',  width:110, alignment:'center', dataType:'string' },
            { dataField:'finish_date',  caption:'Planlanan B.',width:120, alignment:'center', dataType:'string' },
            { dataField:'finish_date_real', caption:'Gerçekleşen B.', width:130, alignment:'center', dataType:'string' },
            {
                dataField: 'status_label',
                caption: 'Durum',
                width: 130,
                alignment: 'center',
                cellTemplate: function(container, options) {
                    var clr = statusColors[options.data.status] || 'secondary';
                    $('<span class="badge bg-' + clr + '">' + options.value + '</span>').appendTo(container);
                }
            },
            {
                caption: 'İşlemler',
                width: 180,
                alignment: 'center',
                allowFiltering: false,
                allowSorting: false,
                cellTemplate: function(container, options) {
                    var d = options.data;
                    $('<button class="btn btn-xs btn-outline-info me-1" title="Görüntüle"><i class="fas fa-eye"></i></button>')
                        .on('click', function(){ viewOrder(d.p_order_id); }).appendTo(container);
                    if (d.status < 5) {
                        $('<button class="btn btn-xs btn-outline-warning me-1" title="Düzenle"><i class="fas fa-edit"></i></button>')
                            .on('click', function(){ editOrder(d.p_order_id); }).appendTo(container);
                        $('<button class="btn btn-xs btn-outline-success me-1" title="Başlat/İlerlet"><i class="fas fa-play"></i></button>')
                            .on('click', function(){ updateStatus(d.p_order_id, d.status < 2 ? 2 : 5); }).appendTo(container);
                    }
                    $('<button class="btn btn-xs btn-outline-danger" title="Sil"><i class="fas fa-trash"></i></button>')
                        .on('click', function(){ deleteOrder(d.p_order_id, d.p_order_no || d.p_order_id); }).appendTo(container);
                }
            }
        ]
    });
}

function addOrder()       { window.location.href = 'index.cfm?fuseaction=production.add_production_order'; }
function editOrder(id)    { window.location.href = 'index.cfm?fuseaction=production.add_production_order&p_order_id=' + id; }
function viewOrder(id)    { window.location.href = 'index.cfm?fuseaction=production.view_production_order&p_order_id=' + id; }

function updateStatus(id, newStatus) {
    var label = newStatus === 2 ? 'başlatmak' : 'tamamlandı olarak işaretlemek';
    if (!confirm('Bu emri ' + label + ' istediğinizden emin misiniz?')) return;
    $.post('/production/form/update_production_status.cfm',
           { p_order_id: id, status: newStatus },
           function(res) {
               if (res && res.success) {
                   var row = ordersData.find(function(x){ return x.p_order_id == id; });
                   if (row) {
                       row.status = newStatus;
                       var labels = { 1:'Planlandı', 2:'Devam Ediyor', 5:'Tamamlandı', 9:'İptal' };
                       row.status_label = labels[newStatus] || '';
                   }
                   $('##ordersGrid').dxDataGrid('instance').refresh();
               } else {
                   DevExpress.ui.notify((res && res.message) || 'Güncelleme başarısız.', 'error', 3000);
               }
           }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); });
}

function deleteOrder(id, label) {
    $('##deleteConfirmContainer').dxDialog({
        title: 'Sil',
        messageHtml: '<b>' + label + '</b> nolu emri silmek istiyor musunuz?',
        buttons: [
            {
                text: 'Evet, Sil',
                type: 'danger',
                onClick: function() {
                    $.post('/production/form/delete_production_order.cfm', { p_order_id: id }, function(res) {
                        if (res && res.success) {
                            ordersData = ordersData.filter(function(x){ return x.p_order_id != id; });
                            $('##ordersGrid').dxDataGrid('instance').option('dataSource', ordersData);
                        } else {
                            DevExpress.ui.notify((res && res.message) || 'Silinemedi.', 'error', 3000);
                        }
                    }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); });
                }
            },
            { text: 'Vazgeç' }
        ]
    }).dxDialog('instance').show();
}
</script>
</cfoutput>
