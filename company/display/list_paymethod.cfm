<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getPaymethods" datasource="boyahane">
    SELECT paymethod_id, paymethod, detail, due_day, due_month,
           money, paymethod_status, payment_means_code, payment_means_code_name,
           is_partner, is_public, record_date, update_date
    FROM setup_paymethod
    ORDER BY paymethod
</cfquery>

<cfset pmArray = []>
<cfloop query="getPaymethods">
    <cfset arrayAppend(pmArray, {
        "paymethod_id":            paymethod_id,
        "paymethod":               paymethod ?: "",
        "detail":                  detail ?: "",
        "due_day":                 isNumeric(due_day) ? due_day : "",
        "due_month":               isNumeric(due_month) ? due_month : "",
        "money":                   money ?: "",
        "paymethod_status":        paymethod_status,
        "payment_means_code":      payment_means_code ?: "",
        "payment_means_code_name": payment_means_code_name ?: "",
        "is_partner":              is_partner,
        "is_public":               is_public,
        "record_date":             isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : "",
        "update_date":             isDate(update_date) ? dateFormat(update_date, "dd/mm/yyyy") & " " & timeFormat(update_date, "HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-credit-card"></i></div>
        <div class="page-header-title">
            <h1>Ödeme Yöntemleri</h1>
            <p>Tüm ödeme yöntemlerini görüntüleyin ve yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="addPaymethod()">
        <i class="fas fa-plus"></i>Yeni Ödeme Yöntemi
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Ödeme yöntemi eklendi.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Ödeme yöntemi güncellendi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Ödeme Yöntemi Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="pmGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var pmData = #serializeJSON(pmArray)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $("##pmGrid").dxDataGrid({
            dataSource: pmData,
            showBorders: true,
            showRowLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            paging: { pageSize: 25 },
            pager: { visible: true, allowedPageSizes: [10,25,50], showPageSizeSelector: true, showInfo: true, infoText: 'Sayfa {0}/{1} ({2} kayıt)' },
            filterRow: { visible: true },
            searchPanel: { visible: true, width: 200, placeholder: 'Ara...' },
            export: { enabled: true, fileName: 'odeme_yontemleri' },
            onExporting: function(e) {
                var workbook = new ExcelJS.Workbook();
                var worksheet = workbook.addWorksheet('Ödeme Yöntemleri');
                DevExpress.excelExporter.exportDataGrid({
                    component: e.component,
                    worksheet: worksheet,
                    autoFilterEnabled: true
                }).then(function() {
                    workbook.xlsx.writeBuffer().then(function(buffer) {
                        saveAs(new Blob([buffer], { type: 'application/octet-stream' }), 'odeme_yontemleri.xlsx');
                    });
                });
                e.cancel = true;
            },
            columns: [
                { dataField: 'paymethod_id', caption: 'ID', width: 70, alignment: 'center', dataType: 'number', sortOrder: 'asc' },
                { dataField: 'paymethod', caption: 'Ödeme Yöntemi', minWidth: 180,
                    cellTemplate: function(c, o) {
                        $('<a>').attr('href', '##').addClass('fw-bold text-decoration-none')
                            .text(o.value || '-')
                            .on('click', function(e) { e.preventDefault(); e.stopPropagation(); editPaymethod(o.data.paymethod_id); })
                            .appendTo(c);
                    }
                },
                { dataField: 'detail', caption: 'Açıklama', minWidth: 160,
                    cellTemplate: function(c, o) { c.text(o.value || '-'); }
                },
                { dataField: 'due_day', caption: 'Vade Günü', width: 100, alignment: 'center' },
                { dataField: 'due_month', caption: 'Vade Ayı', width: 100, alignment: 'center' },
                { dataField: 'money', caption: 'Para Birimi', width: 110, alignment: 'center' },
                { dataField: 'payment_means_code', caption: 'EFATURA Kodu', width: 130, alignment: 'center' },
                { dataField: 'paymethod_status', caption: 'Aktif', width: 90, alignment: 'center',
                    cellTemplate: function(c, o) {
                        $('<span>').addClass(o.value ? 'status-badge status-active' : 'status-badge status-passive')
                            .text(o.value ? 'Aktif' : 'Pasif').appendTo(c);
                    }
                },
                { dataField: 'is_public', caption: 'Genel', width: 80, alignment: 'center',
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
                            .on('click', function() { editPaymethod(options.data.paymethod_id); }).appendTo(btnGroup);
                        $('<button>').addClass('grid-btn grid-btn-del').attr('title','Sil').html('<i class="fas fa-trash"></i>')
                            .on('click', function() { deletePaymethod(options.data.paymethod_id, options.data.paymethod); }).appendTo(btnGroup);
                        btnGroup.appendTo(container);
                    }
                }
            ],
            onContentReady: function(e) { $('##recordCount').text(e.component.totalCount() + ' kayıt'); }
        });
    }
});

function addPaymethod() {
    window.location.href = '/index.cfm?fuseaction=company.add_paymethod';
}
function editPaymethod(id) {
    window.location.href = '/index.cfm?fuseaction=company.edit_paymethod&id=' + id;
}
function deletePaymethod(id, name) {
    if (typeof DevExpress !== 'undefined' && DevExpress.ui && DevExpress.ui.dialog) {
        DevExpress.ui.dialog.confirm('"' + name + '" ödeme yöntemini silmek istediğinizden emin misiniz?', 'Ödeme Yöntemi Sil')
        .done(function(res) {
            if (!res) return;
            $.ajax({
                url: '/company/cfc/company.cfc?method=deletePaymethod',
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
