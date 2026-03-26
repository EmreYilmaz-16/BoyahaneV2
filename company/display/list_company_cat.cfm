<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getCategories" datasource="boyahane">
    SELECT companycat_id, companycat, detail, companycat_type, is_active, is_view, record_date, update_date
    FROM company_cat
    ORDER BY companycat
</cfquery>

<cfset catsArray = []>
<cfloop query="getCategories">
    <cfset arrayAppend(catsArray, {
        "companycat_id":   companycat_id,
        "companycat":      companycat ?: "",
        "detail":          detail ?: "",
        "companycat_type": companycat_type,
        "is_active":       is_active,
        "is_view":         is_view,
        "record_date":     isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : "",
        "update_date":     isDate(update_date) ? dateFormat(update_date, "dd/mm/yyyy") & " " & timeFormat(update_date, "HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-tags"></i></div>
        <div class="page-header-title">
            <h1>Firma Kategorileri</h1>
            <p>Tüm firma kategorilerini görüntüleyin ve yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="addCategory()">
        <i class="fas fa-plus"></i>Yeni Kategori
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Kategori eklendi.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Kategori güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Kategori silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Kategori Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="catsGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var catsData = #serializeJSON(catsArray)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $("##catsGrid").dxDataGrid({
            dataSource: catsData,
            showBorders: true,
            showRowLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            paging: { pageSize: 25 },
            pager: { visible: true, allowedPageSizes: [10,25,50], showPageSizeSelector: true, showInfo: true, infoText: 'Sayfa {0}/{1} ({2} kayıt)' },
            filterRow: { visible: true },
            searchPanel: { visible: true, width: 200, placeholder: 'Ara...' },
            export: { enabled: true, fileName: 'firma_kategorileri' },
            columns: [
                { dataField: 'companycat_id', caption: 'ID', width: 70, alignment: 'center', dataType: 'number', sortOrder: 'asc' },
                { dataField: 'companycat', caption: 'Kategori Adı', minWidth: 180,
                    cellTemplate: function(c, o) { $('<strong>').text(o.value || '-').appendTo(c); }
                },
                { dataField: 'detail', caption: 'Açıklama', minWidth: 200,
                    cellTemplate: function(c, o) { c.text(o.value || '-'); }
                },
                { dataField: 'companycat_type', caption: 'Tip', width: 100, alignment: 'center',
                    cellTemplate: function(c, o) {
                        $('<span>').addClass(o.value ? 'badge bg-primary' : 'badge bg-secondary')
                            .text(o.value ? 'Ticari' : 'Bireysel').appendTo(c);
                    }
                },
                { dataField: 'is_active', caption: 'Aktif', width: 90, alignment: 'center',
                    cellTemplate: function(c, o) {
                        $('<span>').addClass(o.value ? 'status-badge status-active' : 'status-badge status-passive')
                            .text(o.value ? 'Aktif' : 'Pasif').appendTo(c);
                    }
                },
                { dataField: 'record_date', caption: 'Kayıt Tarihi', width: 140, alignment: 'center', dataType: 'string' },
                {
                    caption: 'İşlemler', width: 130, alignment: 'center',
                    allowFiltering: false, allowSorting: false,
                    cellTemplate: function(container, options) {
                        var btnGroup = $('<div>').css({ display:'flex', gap:'5px', justifyContent:'center' });
                        $('<button>').addClass('grid-btn grid-btn-edit').attr('title','Düzenle').html('<i class="fas fa-edit"></i>')
                            .on('click', function() { editCategory(options.data.companycat_id); }).appendTo(btnGroup);
                        $('<button>').addClass('grid-btn grid-btn-del').attr('title','Sil').html('<i class="fas fa-trash"></i>')
                            .on('click', function() { deleteCategory(options.data.companycat_id, options.data.companycat); }).appendTo(btnGroup);
                        btnGroup.appendTo(container);
                    }
                }
            ],
            onContentReady: function(e) { $('##recordCount').text(e.component.totalCount() + ' kayıt'); }
        });
    }
});

function addCategory() {
    window.location.href = '/index.cfm?fuseaction=company.add_company_cat';
}
function editCategory(id) {
    window.location.href = '/index.cfm?fuseaction=company.edit_company_cat&id=' + id;
}
function deleteCategory(id, name) {
    if (typeof DevExpress !== 'undefined' && DevExpress.ui && DevExpress.ui.dialog) {
        DevExpress.ui.dialog.confirm('"' + name + '" kategorisini silmek istediğinizden emin misiniz?', 'Kategori Sil')
        .done(function(res) {
            if (!res) return;
            $.ajax({
                url: '/company/cfc/company.cfc?method=deleteCompanyCat',
                method: 'POST', data: { id: id }, dataType: 'json',
                success: function(r) {
                    DevExpress.ui.notify({ message: r.message, type: r.success ? 'success' : 'error', displayTime: 3000 });
                    if (r.success) setTimeout(function() { location.reload(); }, 1000);
                },
                error: function() { DevExpress.ui.notify({ message: 'Bir hata oluştu!', type: 'error', displayTime: 3000 }); }
            });
        });
    }
}
</script>
</cfoutput>
