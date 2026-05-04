<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getStations" datasource="boyahane">
    SELECT ws.station_id,
           ws.station_name,
           COALESCE(ws.up_station, 0)        AS up_station,
           COALESCE(ws.active, false)        AS active,
           COALESCE(ws.capacity, 0)          AS capacity,
           COALESCE(ws.cost, 0)              AS cost,
           COALESCE(ws.cost_money,'')        AS cost_money,
           COALESCE(ws.employee_number, 0)   AS employee_number,
           COALESCE(ws.comment,'')           AS comment,
           COALESCE(ws.department, 0)        AS department_id,
           COALESCE(d.department_head,'')    AS department_name,
           COALESCE(ws.outsource_partner, 0) AS outsource_partner_id,
           COALESCE(c.nickname, c.fullname,'') AS company_name,
           COALESCE(ws.record_date, CURRENT_TIMESTAMP) AS record_date
    FROM workstations ws
    LEFT JOIN department d ON ws.department = d.department_id
    LEFT JOIN company    c ON ws.outsource_partner = c.company_id
    ORDER BY ws.station_id DESC
</cfquery>

<cfset stArr = []>
<cfloop query="getStations">
    <cfset arrayAppend(stArr, {
        "station_id"          : val(station_id),
        "station_name"        : station_name        ?: "",
        "up_station"          : val(up_station),
        "active"              : active,
        "capacity"            : val(capacity),
        "cost"                : isNumeric(cost) ? val(cost) : 0,
        "cost_money"          : cost_money           ?: "",
        "employee_number"     : val(employee_number),
        "comment"             : comment              ?: "",
        "department_id"       : val(department_id),
        "department_name"     : department_name      ?: "",
        "outsource_partner_id": val(outsource_partner_id),
        "company_name"        : company_name         ?: "",
        "record_date"         : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-industry"></i></div>
        <div class="page-header-title">
            <h1>İş İstasyonları</h1>
            <p>Üretim iş istasyonları ve kapasiteleri</p>
        </div>
    </div>
    <button class="btn-add" onclick="addStation()">
        <i class="fas fa-plus"></i>Yeni İstasyon
    </button>
</div>

<div class="px-3 pb-5">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> İstasyon oluşturuldu.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> İstasyon güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> İstasyon silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>İstasyon Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="stationGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var stData = #serializeJSON(stArr)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    if (typeof $ !== 'undefined' && $.fn.dxTreeList) {
        $('##stationGrid').dxTreeList({
            dataSource: stData,
            keyExpr: 'station_id',
            parentIdExpr: 'up_station',
            rootValue: 0,
            showBorders: true, showRowLines: true, showColumnLines: true,
            rowAlternationEnabled: true, columnAutoWidth: true,
            allowColumnReordering: true, allowColumnResizing: true, columnResizingMode: 'widget',
            width: '100%',
            autoExpandAll: true,
            paging: { enabled: false },
            filterRow: { visible:true },
            headerFilter: { visible:true },
            searchPanel: { visible:true, width:240, placeholder:'Ara...' },
            sorting: { mode:'multiple' },
            columnChooser: { enabled:true, mode:'select', title:'Sütun Seçimi' },
            export: { enabled: true },
            onExporting: function (e) {
                var workbook = new ExcelJS.Workbook();
                var worksheet = workbook.addWorksheet('IsIstasyonlari');
                DevExpress.excelExporter.exportDataGrid({
                    component: e.component,
                    worksheet: worksheet,
                    autoFilterEnabled: true
                }).then(function () {
                    workbook.xlsx.writeBuffer().then(function (buffer) {
                        var fileName = 'is_istasyonlari_' + new Date().toISOString().slice(0, 10) + '.xlsx';
                        saveAs(new Blob([buffer], { type: 'application/octet-stream' }), fileName);
                    });
                });
                e.cancel = true;
            },
            scrolling: { mode: 'standard' },
            onRowDblClick: function(e) { editStation(e.data.station_id); },
            onContentReady: function(e) {
                var total = e.component.getVisibleRows().length;
                document.getElementById('recordCount').textContent = total + ' kayıt';
            },
            columns: [
                { dataField:'station_id',       caption:'ID',           width:65, alignment:'center', dataType:'number' },
                { dataField:'station_name',      caption:'İstasyon Adı', minWidth:180,
                    cellTemplate: function(c,o){
                        $('<a>').attr('href','javascript:void(0)').css({fontWeight:'bold',cursor:'pointer'})
                            .text(o.value||'-').on('click',function(){ editStation(o.data.station_id); }).appendTo(c);
                    }
                },
                { dataField:'department_name',   caption:'Departman',    width:160,
                    cellTemplate: function(c,o){ $('<span>').addClass('small').text(o.value||'-').appendTo(c); }
                },
                { dataField:'active',            caption:'Durum',        width:85, alignment:'center',
                    cellTemplate: function(c,o){ $('<span>').addClass(o.value ? 'badge bg-success' : 'badge bg-secondary').text(o.value ? 'Aktif' : 'Pasif').appendTo(c); }
                },
                { dataField:'capacity',          caption:'Kapasite',     width:90, alignment:'right', dataType:'number' },
                { dataField:'cost',              caption:'Maliyet',      width:100, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'cost_money',        caption:'Para Bir.',    width:80 },
                { dataField:'employee_number',   caption:'Çalışan',      width:80, alignment:'center', dataType:'number' },
                { dataField:'company_name',      caption:'Dış Kaynak',   width:180,
                    cellTemplate: function(c,o){ $('<span>').addClass('small text-muted').text(o.value||'-').appendTo(c); }
                },
                { dataField:'comment',           caption:'Açıklama',     minWidth:150,
                    cellTemplate: function(c,o){ $('<span>').addClass('small text-muted').text(o.value||'').appendTo(c); }
                },
                {
                    caption:'İşlemler', width:100, alignment:'center', allowSorting:false, allowFiltering:false,
                    cellTemplate: function(c,o) {
                        var g = $('<div>').addClass('d-flex gap-1 justify-content-center');
                        $('<button>').addClass('btn btn-sm btn-outline-primary').attr('title','Düzenle').html('<i class="fas fa-edit"></i>')
                            .on('click', function(){ editStation(o.data.station_id); }).appendTo(g);
                        $('<button>').addClass('btn btn-sm btn-outline-danger').attr('title','Sil').html('<i class="fas fa-trash"></i>')
                            .on('click', function(){ deleteStation(o.data.station_id, o.data.station_name); }).appendTo(g);
                        g.appendTo(c);
                    }
                }
            ]
        });
    }
});

function addStation()     { window.location.href = 'index.cfm?fuseaction=production.add_workstation'; }
function editStation(id)  { window.location.href = 'index.cfm?fuseaction=production.add_workstation&station_id=' + id; }

function deleteStation(id, name) {
    DevExpress.ui.dialog.confirm('"' + (name||id) + '" istasyonunu silmek istiyor musunuz?<br><small class="text-muted">Bağlı ürün tanımlamaları da silinecektir.</small>', 'Silme Onayı')
        .then(function(ok) {
            if (!ok) return;
            $.post('/production/form/delete_workstation.cfm', { station_id: id }, function(res) {
                if (res && res.success) {
                    DevExpress.ui.notify('İstasyon silindi.', 'success', 2500);
                    stData = stData.filter(function(x){ return x.station_id != id; });
                    $('##stationGrid').dxTreeList('instance').option('dataSource', stData);
                    document.getElementById('recordCount').textContent = stData.length + ' kayıt';
                } else {
                    DevExpress.ui.notify((res && res.message) || 'Silme başarısız.', 'error', 3500);
                }
            }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); });
        });
}
</script>
</cfoutput>
