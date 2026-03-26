<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getShips" datasource="boyahane">
    SELECT
        s.ship_id, s.ship_number, s.serial_number, s.purchase_sales,
        s.ship_type, s.ship_date, s.deliver_date, s.ship_status,
        s.grosstotal, s.discounttotal, s.taxtotal, s.nettotal,
        s.ref_no, s.ship_detail, s.is_ship_iptal, s.is_dispatch,
        s.record_date,
        COALESCE(c.nickname, c.fullname, '') AS company_name,
        COALESCE((SELECT COUNT(*) FROM ship_row sr WHERE sr.ship_id = s.ship_id), 0) AS row_count
    FROM ship s
    LEFT JOIN company c ON s.company_id = c.company_id
    ORDER BY s.ship_id DESC
</cfquery>

<cfset shipArr = []>
<cfloop query="getShips">
    <cfset shipTypeLabel = "">
    <cfif ship_type eq 1><cfset shipTypeLabel = "Satış">
    <cfelseif ship_type eq 2><cfset shipTypeLabel = "Alış">
    <cfelseif ship_type eq 3><cfset shipTypeLabel = "İade">
    <cfelseif ship_type eq 4><cfset shipTypeLabel = "Transfer">
    <cfelse><cfset shipTypeLabel = "Diğer">
    </cfif>
    <cfset arrayAppend(shipArr, {
        "ship_id":        ship_id,
        "ship_number":    ship_number ?: "",
        "serial_number":  serial_number ?: "",
        "purchase_sales": purchase_sales,
        "ship_type":      ship_type ?: 0,
        "ship_type_label":shipTypeLabel,
        "ship_date":      isDate(ship_date)    ? dateFormat(ship_date,    "dd/mm/yyyy") & " " & timeFormat(ship_date,    "HH:mm") : "",
        "deliver_date":   isDate(deliver_date) ? dateFormat(deliver_date, "dd/mm/yyyy") : "",
        "ship_status":    ship_status ?: 1,
        "grosstotal":     isNumeric(grosstotal)    ? grosstotal    : 0,
        "discounttotal":  isNumeric(discounttotal) ? discounttotal : 0,
        "taxtotal":       isNumeric(taxtotal)      ? taxtotal      : 0,
        "nettotal":       isNumeric(nettotal)      ? nettotal      : 0,
        "company_name":   company_name ?: "",
        "ref_no":         ref_no ?: "",
        "is_ship_iptal":  is_ship_iptal,
        "is_dispatch":    is_dispatch,
        "row_count":      row_count,
        "record_date":    isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-file-invoice"></i></div>
        <div class="page-header-title">
            <h1>İrsaliyeler</h1>
            <p>Tüm sevkiyat/irsaliye kayıtları</p>
        </div>
    </div>
    <button class="btn-add" onclick="addShip()">
        <i class="fas fa-plus"></i>Yeni İrsaliye
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> İrsaliye oluşturuldu.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> İrsaliye güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> İrsaliye silindi.
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
                    <span class="summary-label">Toplam İrsaliye</span>
                    <span class="summary-value" id="sumTotal">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-truck-loading"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Satış İrsaliyesi</span>
                    <span class="summary-value" id="sumSatis">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-truck"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Alış İrsaliyesi</span>
                    <span class="summary-value" id="sumAlis">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-red">
                <div class="summary-icon"><i class="fas fa-ban"></i></div>
                <div class="summary-info">
                    <span class="summary-label">İptal</span>
                    <span class="summary-value" id="sumIptal">-</span>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>İrsaliye Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="shipGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<style>
.summary-card { display:flex; align-items:center; gap:14px; padding:16px 20px; border-radius:10px; color:##fff; box-shadow:0 2px 10px rgba(0,0,0,.12); }
.summary-card-blue   { background:linear-gradient(135deg,##1a3a5c,##2563ab); }
.summary-card-green  { background:linear-gradient(135deg,##15803d,##22c55e); }
.summary-card-orange { background:linear-gradient(135deg,##92400e,##f59e0b); }
.summary-card-red    { background:linear-gradient(135deg,##991b1b,##ef4444); }
.summary-icon { font-size:1.8rem; opacity:.85; }
.summary-label { font-size:.75rem; opacity:.85; display:block; }
.summary-value { font-size:1.6rem; font-weight:700; display:block; }
</style>

<script>
var shipData = #serializeJSON(shipArr)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    var satis = shipData.filter(function(r){ return r.ship_type == 1; }).length;
    var alis  = shipData.filter(function(r){ return r.ship_type == 2; }).length;
    var iptal = shipData.filter(function(r){ return r.is_ship_iptal; }).length;
    document.getElementById('sumTotal').textContent = shipData.length;
    document.getElementById('sumSatis').textContent = satis;
    document.getElementById('sumAlis').textContent  = alis;
    document.getElementById('sumIptal').textContent = iptal;

    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $("##shipGrid").dxDataGrid({
            dataSource: shipData,
            showBorders: true, showRowLines: true, showColumnLines: true,
            rowAlternationEnabled: true, columnAutoWidth: true,
            allowColumnReordering: true, allowColumnResizing: true, columnResizingMode: 'widget',
            paging: { pageSize: 25 },
            pager: { visible:true, allowedPageSizes:[10,25,50,100], showPageSizeSelector:true, showNavigationButtons:true, showInfo:true, infoText:'Sayfa {0}/{1} ({2} kayıt)' },
            filterRow: { visible:true }, headerFilter: { visible:true },
            searchPanel: { visible:true, width:240, placeholder:'Ara...' },
            sorting: { mode:'multiple' },
            columnChooser: { enabled:true, mode:'select', title:'Sütun Seçimi' },
            export: { enabled:true, fileName:'irsaliyeler_' + new Date().toISOString().slice(0,10) },
            onRowDblClick: function(e) { openShip(e.data.ship_id); },
            onContentReady: function(e) { document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt'; },
            columns: [
                { dataField:'ship_id', caption:'ID', width:80, alignment:'center', dataType:'number', sortOrder:'desc' },
                { dataField:'ship_number', caption:'İrsaliye No', width:140,
                    cellTemplate: function(c,o) { $('<strong>').text(o.value||'-').appendTo(c); }
                },
                { dataField:'serial_number', caption:'Seri No', width:120,
                    cellTemplate: function(c,o) { $('<span>').addClass('font-monospace small').text(o.value||'-').appendTo(c); }
                },
                { dataField:'purchase_sales', caption:'Tip', width:80, alignment:'center',
                    cellTemplate: function(c,o) {
                        $('<span>').addClass(o.value ? 'badge bg-success' : 'badge bg-warning text-dark')
                            .text(o.value ? 'Satış' : 'Alış').appendTo(c);
                    }
                },
                { dataField:'ship_type_label', caption:'İrs. Tipi', width:110,
                    cellTemplate: function(c,o) {
                        var t = o.data.ship_type;
                        var cls = t==1?'bg-success':t==2?'bg-warning text-dark':t==3?'bg-danger':t==4?'bg-info':'bg-secondary';
                        $('<span>').addClass('badge '+cls).text(o.value||'-').appendTo(c);
                    }
                },
                { dataField:'company_name', caption:'Firma', minWidth:160 },
                { dataField:'ship_date', caption:'İrs. Tarihi', width:130 },
                { dataField:'deliver_date', caption:'Sevk Tarihi', width:110 },
                { dataField:'row_count', caption:'Kalem', width:75, alignment:'center', dataType:'number',
                    cellTemplate: function(c,o) { $('<span>').addClass('badge bg-primary rounded-pill').text(o.value).appendTo(c); }
                },
                { dataField:'grosstotal', caption:'Brüt Toplam', width:130, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'taxtotal', caption:'KDV', width:110, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'nettotal', caption:'Net Toplam', width:130, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2},
                    cellTemplate: function(c,o) { $('<strong>').text(parseFloat(o.value||0).toLocaleString('tr-TR',{minimumFractionDigits:2})).appendTo(c); }
                },
                { dataField:'ship_status', caption:'Durum', width:90, alignment:'center',
                    cellTemplate: function(c,o) {
                        var d = o.data;
                        if (d.is_ship_iptal) { $('<span>').addClass('badge bg-danger').text('İptal').appendTo(c); }
                        else if (d.is_dispatch) { $('<span>').addClass('badge bg-success').text('Sevk Edildi').appendTo(c); }
                        else { $('<span>').addClass('badge bg-secondary').text('Bekliyor').appendTo(c); }
                    }
                },
                { dataField:'ref_no', caption:'Ref No', width:130,
                    cellTemplate: function(c,o) { $('<span>').addClass('text-muted small').text(o.value||'-').appendTo(c); }
                },
                { dataField:'record_date', caption:'Kayıt Tarihi', width:130 },
                {
                    caption:'İşlemler', width:120, alignment:'center', allowSorting:false, allowFiltering:false,
                    cellTemplate: function(c, o) {
                        var g = $('<div>').addClass('d-flex gap-1 justify-content-center');
                        $('<button>').addClass('btn btn-sm btn-outline-primary').attr('title','Aç').html('<i class="fas fa-eye"></i>')
                            .on('click', function(){ openShip(o.data.ship_id); }).appendTo(g);
                        $('<button>').addClass('btn btn-sm btn-outline-danger').attr('title','Sil').html('<i class="fas fa-trash"></i>')
                            .on('click', function(){ deleteShip(o.data.ship_id, o.data.ship_number); }).appendTo(g);
                        g.appendTo(c);
                    }
                }
            ]
        });
    }
});

function addShip()  { window.location.href = '/index.cfm?fuseaction=ship.add_ship'; }
function openShip(id) { window.location.href = '/index.cfm?fuseaction=ship.add_ship&ship_id=' + id; }

function deleteShip(id, no) {
    var label = no ? no : ('##' + id);
    DevExpress.ui.dialog.confirm('"' + label + '" irsaliyesini silmek istediğinizden emin misiniz?', 'Silme Onayı')
        .then(function(ok) {
            if (!ok) return;
            $.ajax({
                url: '/ship/form/delete_ship.cfm', method:'POST', data:{ ship_id: id }, dataType:'json',
                success: function(r) {
                    if (r.success) {
                        DevExpress.ui.notify('İrsaliye silindi','success',2000);
                        shipData = shipData.filter(function(x){ return x.ship_id != id; });
                        $('##shipGrid').dxDataGrid('instance').option('dataSource', shipData);
                        document.getElementById('sumTotal').textContent = shipData.length;
                    } else DevExpress.ui.notify(r.message||'Hata!','error',3000);
                },
                error: function() { DevExpress.ui.notify('Silme başarısız!','error',3000); }
            });
        });
}
</script>
</cfoutput>
