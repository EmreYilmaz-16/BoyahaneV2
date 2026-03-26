<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getShipMethods" datasource="boyahane">
    SELECT ship_method_id, ship_method, calculate, ship_day, ship_hour,
           is_opposite, is_internet, record_date, update_date
    FROM ship_method
    ORDER BY ship_method
</cfquery>

<cfset smArray = []>
<cfloop query="getShipMethods">
    <cfset arrayAppend(smArray, {
        "ship_method_id": ship_method_id,
        "ship_method":    ship_method ?: "",
        "calculate":      calculate ?: "",
        "ship_day":       ship_day ?: "",
        "ship_hour":      ship_hour ?: "",
        "is_opposite":    is_opposite,
        "is_internet":    is_internet,
        "record_date":    isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : "",
        "update_date":    isDate(update_date) ? dateFormat(update_date, "dd/mm/yyyy") & " " & timeFormat(update_date, "HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-truck"></i></div>
        <div class="page-header-title">
            <h1>Sevkiyat Yöntemleri</h1>
            <p>Tüm sevkiyat yöntemlerini görüntüleyin ve yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="addShipMethod()">
        <i class="fas fa-plus"></i>Yeni Sevkiyat Yöntemi
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Sevkiyat yöntemi eklendi.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Sevkiyat yöntemi güncellendi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Sevkiyat Yöntemi Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="smGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var smData = #serializeJSON(smArray)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $("##smGrid").dxDataGrid({
            dataSource: smData,
            showBorders: true,
            showRowLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            paging: { pageSize: 25 },
            pager: { visible: true, allowedPageSizes: [10,25,50], showPageSizeSelector: true, showInfo: true, infoText: 'Sayfa {0}/{1} ({2} kayıt)' },
            filterRow: { visible: true },
            searchPanel: { visible: true, width: 200, placeholder: 'Ara...' },
            export: { enabled: true, fileName: 'sevkiyat_yontemleri' },
            columns: [
                { dataField: 'ship_method_id', caption: 'ID', width: 70, alignment: 'center', dataType: 'number', sortOrder: 'asc' },
                { dataField: 'ship_method', caption: 'Sevkiyat Yöntemi', minWidth: 180,
                    cellTemplate: function(c, o) { $('<strong>').text(o.value || '-').appendTo(c); }
                },
                { dataField: 'calculate', caption: 'Hesaplama', minWidth: 150,
                    cellTemplate: function(c, o) { c.text(o.value || '-'); }
                },
                { dataField: 'ship_day', caption: 'Gün', width: 100, alignment: 'center' },
                { dataField: 'ship_hour', caption: 'Saat', width: 100, alignment: 'center' },
                { dataField: 'is_opposite', caption: 'Karşı Ödemeli', width: 120, alignment: 'center',
                    cellTemplate: function(c, o) {
                        $('<span>').addClass(o.value ? 'badge bg-warning text-dark' : 'badge bg-secondary')
                            .text(o.value ? 'Evet' : 'Hayır').appendTo(c);
                    }
                },
                { dataField: 'is_internet', caption: 'İnternet', width: 100, alignment: 'center',
                    cellTemplate: function(c, o) {
                        $('<span>').addClass(o.value ? 'badge bg-info' : 'badge bg-secondary')
                            .text(o.value ? 'Evet' : 'Hayır').appendTo(c);
                    }
                },
                { dataField: 'record_date', caption: 'Kayıt Tarihi', width: 140, alignment: 'center', dataType: 'string' },
                {
                    caption: 'İşlemler', width: 130, alignment: 'center',
                    allowFiltering: false, allowSorting: false,
                    cellTemplate: function(container, options) {
                        var btnGroup = $('<div>').css({ display:'flex', gap:'5px', justifyContent:'center' });
                        $('<button>').addClass('grid-btn grid-btn-edit').attr('title','Düzenle').html('<i class="fas fa-edit"></i>')
                            .on('click', function() { editShipMethod(options.data.ship_method_id); }).appendTo(btnGroup);
                        $('<button>').addClass('grid-btn grid-btn-del').attr('title','Sil').html('<i class="fas fa-trash"></i>')
                            .on('click', function() { deleteShipMethod(options.data.ship_method_id, options.data.ship_method); }).appendTo(btnGroup);
                        btnGroup.appendTo(container);
                    }
                }
            ],
            onContentReady: function(e) { $('##recordCount').text(e.component.totalCount() + ' kayıt'); }
        });
    }
});

function addShipMethod() {
    window.location.href = '/index.cfm?fuseaction=company.add_ship_method';
}
function editShipMethod(id) {
    window.location.href = '/index.cfm?fuseaction=company.edit_ship_method&id=' + id;
}
function deleteShipMethod(id, name) {
    if (typeof DevExpress !== 'undefined' && DevExpress.ui && DevExpress.ui.dialog) {
        DevExpress.ui.dialog.confirm('"' + name + '" sevkiyat yöntemini silmek istediğinizden emin misiniz?', 'Sevkiyat Yöntemi Sil')
        .done(function(res) {
            if (!res) return;
            $.ajax({
                url: '/company/cfc/company.cfc?method=deleteShipMethod',
                method: 'POST', data: { id: id }, dataType: 'json',
                success: function(r) {
                    DevExpress.ui.notify({ message: r.message, type: r.success ? 'success' : 'error', displayTime: 3500 });
                    if (r.success) setTimeout(function() { location.reload(); }, 1000);
                },
                error: function() { DevExpress.ui.notify({ message: 'Bir hata oluştu!', type: 'error', displayTime: 3000 }); }
            });
        });
    }
}
</script>
</cfoutput>
