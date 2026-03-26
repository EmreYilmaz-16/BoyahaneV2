<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getCompanies" datasource="boyahane">
    SELECT
        c.company_id, c.company_status, c.companycat_id,
        c.member_code, c.nickname, c.fullname,
        c.taxoffice, c.taxno, c.company_email, c.homepage,
        c.company_tel1, c.mobiltel, c.company_address,
        c.is_buyer, c.is_seller, c.ispotantial, c.is_person,
        c.ozel_kod, c.record_date, c.update_date,
        cc.companycat
    FROM company c
    LEFT JOIN company_cat cc ON c.companycat_id = cc.companycat_id
    ORDER BY c.company_id DESC
</cfquery>

<cfquery name="getCategories" datasource="boyahane">
    SELECT companycat_id, companycat FROM company_cat WHERE is_active = true ORDER BY companycat
</cfquery>

<cfset companiesArray = []>
<cfloop query="getCompanies">
    <cfset arrayAppend(companiesArray, {
        "company_id":      company_id,
        "company_status":  company_status,
        "companycat_id":   companycat_id,
        "companycat":      companycat ?: "",
        "member_code":     member_code ?: "",
        "nickname":        nickname ?: "",
        "fullname":        fullname ?: "",
        "taxoffice":       taxoffice ?: "",
        "taxno":           taxno ?: "",
        "company_email":   company_email ?: "",
        "company_tel1":    company_tel1 ?: "",
        "mobiltel":        mobiltel ?: "",
        "company_address": company_address ?: "",
        "is_buyer":        is_buyer,
        "is_seller":       is_seller,
        "ispotantial":     ispotantial,
        "is_person":       is_person,
        "ozel_kod":        ozel_kod ?: "",
        "record_date":     isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : "",
        "update_date":     isDate(update_date) ? dateFormat(update_date, "dd/mm/yyyy") & " " & timeFormat(update_date, "HH:mm") : ""
    })>
</cfloop>

<cfset categoriesArray = []>
<cfloop query="getCategories">
    <cfset arrayAppend(categoriesArray, { "companycat_id": companycat_id, "companycat": companycat ?: "" })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-building"></i></div>
        <div class="page-header-title">
            <h1>Firmalar</h1>
            <p>Tüm firma kayıtlarını görüntüleyin ve yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="addCompany()">
        <i class="fas fa-plus"></i>Yeni Firma
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Firma eklendi.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Firma güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Firma silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Firma Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="companiesGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var companiesData   = #serializeJSON(companiesArray)#;
var categoriesData  = #serializeJSON(categoriesArray)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    if (typeof $ === 'undefined' || !$.fn.dxDataGrid) return;

    $("##companiesGrid").dxDataGrid({
        dataSource: companiesData,
        showBorders: true,
        showRowLines: true,
        rowAlternationEnabled: true,
        columnAutoWidth: true,
        allowColumnReordering: true,
        allowColumnResizing: true,
        columnResizingMode: 'widget',
        paging: { pageSize: 25, pageIndex: 0 },
        pager: { visible: true, allowedPageSizes: [10,25,50,100], showPageSizeSelector: true, showNavigationButtons: true, showInfo: true, infoText: 'Sayfa {0}/{1} ({2} kayıt)' },
        filterRow: { visible: true, applyFilter: 'auto' },
        headerFilter: { visible: true },
        searchPanel: { visible: true, width: 240, placeholder: 'Ara...' },
        sorting: { mode: 'multiple' },
        columnChooser: { enabled: true, mode: 'select', title: 'Sütun Seçimi' },
        groupPanel: { visible: true, emptyPanelText: 'Gruplamak için sütun başlığını buraya sürükleyin' },
        export: { enabled: true, fileName: 'firmalar_' + new Date().toISOString().slice(0,10) },
        selection: { mode: 'multiple', showCheckBoxesMode: 'always' },

        columns: [
            { dataField: 'company_id', caption: 'ID', width: 70, alignment: 'center', dataType: 'number', sortOrder: 'desc' },
            { dataField: 'member_code', caption: 'Üye Kodu', width: 110,
                cellTemplate: function(c, o) { c.text(o.value || '-'); }
            },
            { dataField: 'nickname', caption: 'Kısa Ad', minWidth: 150,
                cellTemplate: function(c, o) { $('<strong>').text(o.value || '-').appendTo(c); }
            },
            { dataField: 'fullname', caption: 'Tam Ad / Unvan', minWidth: 200,
                cellTemplate: function(c, o) { c.text(o.value || '-'); }
            },
            { dataField: 'companycat', caption: 'Kategori', width: 130,
                cellTemplate: function(c, o) {
                    if (o.value) $('<span>').addClass('badge bg-info').text(o.value).appendTo(c);
                    else $('<span>').addClass('text-muted').text('-').appendTo(c);
                }
            },
            { dataField: 'taxno', caption: 'Vergi No', width: 120,
                cellTemplate: function(c, o) { c.text(o.value || '-'); }
            },
            { dataField: 'company_tel1', caption: 'Telefon', width: 120,
                cellTemplate: function(c, o) { c.text(o.value || '-'); }
            },
            { dataField: 'company_email', caption: 'E-posta', width: 180,
                cellTemplate: function(c, o) {
                    if (o.value) $('<a>').attr('href', 'mailto:' + o.value).text(o.value).appendTo(c);
                    else $('<span>').addClass('text-muted').text('-').appendTo(c);
                }
            },
            { dataField: 'is_buyer', caption: 'Müşteri', width: 90, alignment: 'center',
                cellTemplate: function(c, o) {
                    $('<i>').addClass(o.value ? 'fas fa-check text-success' : 'fas fa-times text-danger').appendTo(c);
                }
            },
            { dataField: 'is_seller', caption: 'Tedarikçi', width: 90, alignment: 'center',
                cellTemplate: function(c, o) {
                    $('<i>').addClass(o.value ? 'fas fa-check text-success' : 'fas fa-times text-danger').appendTo(c);
                }
            },
            { dataField: 'ispotantial', caption: 'Potansiyel', width: 100, alignment: 'center',
                cellTemplate: function(c, o) {
                    if (o.value) $('<span>').addClass('badge bg-warning text-dark').text('Potansiyel').appendTo(c);
                }
            },
            { dataField: 'company_status', caption: 'Durum', width: 90, alignment: 'center',
                cellTemplate: function(c, o) {
                    $('<span>').addClass(o.value ? 'status-badge status-active' : 'status-badge status-passive')
                        .text(o.value ? 'Aktif' : 'Pasif').appendTo(c);
                }
            },
            { dataField: 'record_date', caption: 'Kayıt Tarihi', width: 140, alignment: 'center', dataType: 'string' },
            {
                caption: 'İşlemler', width: 185, alignment: 'center',
                allowFiltering: false, allowSorting: false, allowGrouping: false,
                cellTemplate: function(container, options) {
                    var btnGroup = $('<div>').css({ display:'flex', gap:'5px', justifyContent:'center' });

                    $('<button>').addClass('grid-btn grid-btn-view').attr('title','Görüntüle').html('<i class="fas fa-eye"></i>')
                        .on('click', function() { viewCompany(options.data.company_id); }).appendTo(btnGroup);

                    $('<button>').addClass('grid-btn grid-btn-edit').attr('title','Düzenle').html('<i class="fas fa-edit"></i>')
                        .on('click', function() { editCompany(options.data.company_id); }).appendTo(btnGroup);

                    $('<button>').addClass('grid-btn grid-btn-del').attr('title','Sil').html('<i class="fas fa-trash"></i>')
                        .on('click', function() { deleteCompany(options.data.company_id, options.data.nickname || options.data.fullname); }).appendTo(btnGroup);

                    btnGroup.appendTo(container);
                }
            }
        ],

        onToolbarPreparing: function(e) {
            e.toolbarOptions.items.unshift({
                location: 'after', widget: 'dxButton',
                options: { icon: 'refresh', text: 'Yenile', onClick: function() { location.reload(); } }
            });
        },
        loadPanel: { enabled: true, text: 'Yükleniyor...' },
        noDataText: 'Firma bulunamadı',
        onContentReady: function(e) { $('##recordCount').text(e.component.totalCount() + ' kayıt'); }
    });
});

function addCompany() {
    window.location.href = '/index.cfm?fuseaction=company.add_company';
}

function editCompany(id) {
    window.location.href = '/index.cfm?fuseaction=company.edit_company&id=' + id;
}

function viewCompany(id) {
    $.ajax({
        url: '/company/cfc/company.cfc?method=getCompany',
        method: 'GET', data: { id: id }, dataType: 'json',
        success: function(response) {
            if (response.success) showCompanyModal(response.data);
            else DevExpress.ui.notify({ message: response.message, type: 'error', displayTime: 3000 });
        },
        error: function() { DevExpress.ui.notify({ message: 'Bilgiler alınırken hata oluştu!', type: 'error', displayTime: 3000 }); }
    });
}

function showCompanyModal(d) {
    var html = '<div class="row g-3 p-3">' +
        '<div class="col-md-6"><label class="form-label text-muted">Kısa Ad</label><div class="fw-bold">' + (d.nickname||'-') + '</div></div>' +
        '<div class="col-md-6"><label class="form-label text-muted">Tam Ad / Unvan</label><div class="fw-bold">' + (d.fullname||'-') + '</div></div>' +
        '<div class="col-md-6"><label class="form-label text-muted">Kategori</label><div>' + (d.companycat||'-') + '</div></div>' +
        '<div class="col-md-6"><label class="form-label text-muted">Üye Kodu</label><div>' + (d.member_code||'-') + '</div></div>' +
        '<div class="col-md-6"><label class="form-label text-muted">Vergi Dairesi</label><div>' + (d.taxoffice||'-') + '</div></div>' +
        '<div class="col-md-6"><label class="form-label text-muted">Vergi No</label><div>' + (d.taxno||'-') + '</div></div>' +
        '<div class="col-md-6"><label class="form-label text-muted">Telefon</label><div>' + (d.company_tel1||'-') + '</div></div>' +
        '<div class="col-md-6"><label class="form-label text-muted">Mobil</label><div>' + (d.mobiltel||'-') + '</div></div>' +
        '<div class="col-md-6"><label class="form-label text-muted">E-posta</label><div>' + (d.company_email||'-') + '</div></div>' +
        '<div class="col-md-6"><label class="form-label text-muted">Web</label><div>' + (d.homepage||'-') + '</div></div>' +
        '<div class="col-12"><label class="form-label text-muted">Adres</label><div>' + (d.company_address||'-') + '</div></div>' +
        '<div class="col-md-3"><label class="form-label text-muted">Müşteri</label><div>' + (d.is_buyer ? '<i class="fas fa-check text-success"></i> Evet' : '<i class="fas fa-times text-danger"></i> Hayır') + '</div></div>' +
        '<div class="col-md-3"><label class="form-label text-muted">Tedarikçi</label><div>' + (d.is_seller ? '<i class="fas fa-check text-success"></i> Evet' : '<i class="fas fa-times text-danger"></i> Hayır') + '</div></div>' +
        '<div class="col-md-3"><label class="form-label text-muted">Potansiyel</label><div>' + (d.ispotantial ? '<span class="badge bg-warning text-dark">Evet</span>' : 'Hayır') + '</div></div>' +
        '<div class="col-md-3"><label class="form-label text-muted">Durum</label><div>' + (d.company_status ? '<span class="status-badge status-active">Aktif</span>' : '<span class="status-badge status-passive">Pasif</span>') + '</div></div>' +
        '<div class="col-md-6"><label class="form-label text-muted">Kayıt Tarihi</label><div>' + (d.record_date||'-') + '</div></div>' +
        '<div class="col-md-6"><label class="form-label text-muted">Güncelleme</label><div>' + (d.update_date||'-') + '</div></div>' +
        '</div>';

    var el = $('<div>').appendTo('body');
    var popup = el.dxPopup({
        titleTemplate: function() { return $('<div>').html('<i class="fas fa-building me-2"></i>' + (d.nickname || d.fullname)); },
        width: 750, height: 'auto', showTitle: true, dragEnabled: true,
        closeOnOutsideClick: true, showCloseButton: true,
        contentTemplate: function() { return $('<div>').html(html); },
        toolbarItems: [
            { widget: 'dxButton', location: 'after', toolbar: 'bottom', options: { text: 'Düzenle', type: 'default', icon: 'edit', onClick: function() { popup.hide(); editCompany(d.company_id); } } },
            { widget: 'dxButton', location: 'after', toolbar: 'bottom', options: { text: 'Kapat', onClick: function() { popup.hide(); } } }
        ],
        onHidden: function() { el.remove(); }
    }).dxPopup('instance');
    popup.show();
}

function deleteCompany(id, name) {
    if (typeof DevExpress !== 'undefined' && DevExpress.ui && DevExpress.ui.dialog) {
        DevExpress.ui.dialog.confirm('"' + name + '" firmasını silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!', 'Firma Sil')
        .done(function(res) {
            if (!res) return;
            $.ajax({
                url: '/company/cfc/company.cfc?method=deleteCompany',
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
