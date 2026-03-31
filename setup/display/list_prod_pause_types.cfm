<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getPauseTypes" datasource="boyahane">
    SELECT prod_pause_type_id,
           COALESCE(prod_pause_type,'')      AS prod_pause_type,
           COALESCE(prod_pause_type_code,'') AS prod_pause_type_code,
           COALESCE(is_active, true)         AS is_active,
           COALESCE(pause_detail,'')         AS pause_detail,
           COALESCE(prod_pause_cat_id, 0)    AS prod_pause_cat_id,
           record_date
    FROM setup_prod_pause_type
    ORDER BY prod_pause_type_id DESC
</cfquery>

<cfset typeArr = []>
<cfloop query="getPauseTypes">
    <cfset arrayAppend(typeArr, {
        "prod_pause_type_id"  : val(prod_pause_type_id),
        "prod_pause_type"     : prod_pause_type      ?: "",
        "prod_pause_type_code": prod_pause_type_code ?: "",
        "is_active"           : is_active,
        "pause_detail"        : pause_detail         ?: "",
        "prod_pause_cat_id"   : val(prod_pause_cat_id),
        "record_date"         : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") : ""
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-pause-circle"></i></div>
        <div class="page-header-title">
            <h1>Duruş Tipleri</h1>
            <p>Üretim duruş/bekleme tip tanımları</p>
        </div>
    </div>
    <button class="btn-add" onclick="addPauseType()">
        <i class="fas fa-plus"></i>Yeni Duruş Tipi
    </button>
</div>

<div class="px-3 pb-5">
    <cfif isDefined("url.success")>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Duruş tipi eklendi.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Duruş tipi güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Duruş tipi silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Duruş Tipi Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="pauseTypeGrid"></div>
        </div>
    </div>
</div>

<div id="pauseTypeModal" class="modal fade" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="pauseTypeModalTitle">Duruş Tipi</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="fld_prod_pause_type_id" value="0">
                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label">Duruş Tipi Adı <span class="text-danger">*</span></label>
                        <div id="fld_prod_pause_type_dx"></div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Kod</label>
                        <div id="fld_prod_pause_type_code_dx"></div>
                    </div>
                    <div class="col-md-2 d-flex align-items-end">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="fld_is_active" checked>
                            <label class="form-check-label" for="fld_is_active">Aktif</label>
                        </div>
                    </div>
                    <div class="col-12">
                        <label class="form-label">Açıklama</label>
                        <div id="fld_pause_detail_dx"></div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Vazgeç</button>
                <button type="button" class="btn btn-primary" id="btnSavePauseType" onclick="savePauseType()">
                    <i class="fas fa-save me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<div id="deleteConfirmContainer"></div>

<script>
var pauseTypeData = #serializeJSON(typeArr)#;

$(function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    // Modal'ı body'e taşı: content-wrapper'ın stacking context'i z-index'i kısıtlıyor
    document.body.appendChild(document.getElementById('pauseTypeModal'));

    $('##fld_prod_pause_type_dx').dxTextBox({ placeholder: 'Duruş tipi adı' });
    $('##fld_prod_pause_type_code_dx').dxTextBox({ placeholder: 'Örn: ARIZA' });
    $('##fld_pause_detail_dx').dxTextArea({ height: 80, placeholder: 'Açıklama...' });

    buildGrid();
});

function buildGrid() {
    $('##pauseTypeGrid').dxDataGrid({
        dataSource: pauseTypeData,
        keyExpr: 'prod_pause_type_id',
        showBorders: true,
        rowAlternationEnabled: true,
        columnAutoWidth: false,
        wordWrapEnabled: false,
        paging: { pageSize: 25 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [15,25,50], showInfo: true },
        searchPanel: { visible: true, placeholder: 'Ara...' },
        filterRow: { visible: true },
        onContentReady: function(e) {
            document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt';
        },
        columns: [
            { dataField:'prod_pause_type_id',   caption:'ID',    width:65,  alignment:'center', dataType:'number', sortOrder:'desc' },
            { dataField:'prod_pause_type',       caption:'Duruş Tipi', minWidth:180 },
            { dataField:'prod_pause_type_code',  caption:'Kod',   width:120 },
            {
                dataField:'is_active', caption:'Aktif', width:80, alignment:'center',
                cellTemplate: function(c,o) {
                    $('<span class="badge bg-' + (o.value ? 'success' : 'secondary') + '">' + (o.value ? 'Aktif' : 'Pasif') + '</span>').appendTo(c);
                }
            },
            { dataField:'pause_detail', caption:'Açıklama', minWidth:200 },
            { dataField:'record_date',  caption:'Kayıt Tarihi', width:120, alignment:'center' },
            {
                caption:'İşlemler', width:110, alignment:'center', allowFiltering:false, allowSorting:false,
                cellTemplate: function(c,o) {
                    var d = o.data;
                    $('<button class="btn btn-xs btn-outline-warning me-1" title="Düzenle"><i class="fas fa-edit"></i></button>')
                        .on('click', function(){ editPauseType(d); }).appendTo(c);
                    $('<button class="btn btn-xs btn-outline-danger" title="Sil"><i class="fas fa-trash"></i></button>')
                        .on('click', function(){ deletePauseType(d.prod_pause_type_id, d.prod_pause_type); }).appendTo(c);
                }
            }
        ]
    });
}

function addPauseType() {
    clearModal();
    $('##pauseTypeModalTitle').text('Yeni Duruş Tipi');
    new bootstrap.Modal(document.getElementById('pauseTypeModal')).show();
}

function editPauseType(d) {
    clearModal();
    $('##pauseTypeModalTitle').text('Duruş Tipi Düzenle');
    $('##fld_prod_pause_type_id').val(d.prod_pause_type_id);
    $('##fld_prod_pause_type_dx').dxTextBox('instance').option('value', d.prod_pause_type);
    $('##fld_prod_pause_type_code_dx').dxTextBox('instance').option('value', d.prod_pause_type_code);
    $('##fld_pause_detail_dx').dxTextArea('instance').option('value', d.pause_detail);
    document.getElementById('fld_is_active').checked = d.is_active;
    new bootstrap.Modal(document.getElementById('pauseTypeModal')).show();
}

function clearModal() {
    $('##fld_prod_pause_type_id').val(0);
    $('##fld_prod_pause_type_dx').dxTextBox('instance').option('value', '');
    $('##fld_prod_pause_type_code_dx').dxTextBox('instance').option('value', '');
    $('##fld_pause_detail_dx').dxTextArea('instance').option('value', '');
    document.getElementById('fld_is_active').checked = true;
}

function savePauseType() {
    var name = $('##fld_prod_pause_type_dx').dxTextBox('instance').option('value') || '';
    if (!name.trim()) { DevExpress.ui.notify('Duruş tipi adı zorunludur.', 'warning', 2500); return; }

    var payload = {
        prod_pause_type_id  : parseInt($('##fld_prod_pause_type_id').val()) || 0,
        prod_pause_type     : name,
        prod_pause_type_code: ($('##fld_prod_pause_type_code_dx').dxTextBox('instance').option('value') || '').trim(),
        is_active           : document.getElementById('fld_is_active').checked ? 1 : 0,
        pause_detail        : ($('##fld_pause_detail_dx').dxTextArea('instance').option('value') || '').trim()
    };

    $('##btnSavePauseType').prop('disabled', true);
    $.post('/setup/form/save_prod_pause_type.cfm', payload, function(res) {
        if (res && res.success) {
            bootstrap.Modal.getInstance(document.getElementById('pauseTypeModal')).hide();
            if (payload.prod_pause_type_id > 0) {
                var row = pauseTypeData.find(function(x){ return x.prod_pause_type_id == payload.prod_pause_type_id; });
                if (row) { Object.assign(row, { prod_pause_type: payload.prod_pause_type, prod_pause_type_code: payload.prod_pause_type_code, is_active: !!payload.is_active, pause_detail: payload.pause_detail }); }
            } else {
                payload.prod_pause_type_id = res.prod_pause_type_id;
                pauseTypeData.unshift(payload);
            }
            $('##pauseTypeGrid').dxDataGrid('instance').option('dataSource', pauseTypeData);
            DevExpress.ui.notify('Kaydedildi.', 'success', 2000);
        } else {
            DevExpress.ui.notify((res && res.message) || 'Kayıt başarısız.', 'error', 3000);
        }
    }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); })
              .always(function(){ $('##btnSavePauseType').prop('disabled', false); });
}

function deletePauseType(id, label) {
    $('##deleteConfirmContainer').dxDialog({
        title: 'Sil',
        messageHtml: '<b>' + label + '</b> duruş tipini silmek istiyor musunuz?',
        buttons: [
            {
                text: 'Evet, Sil', type: 'danger',
                onClick: function() {
                    $.post('/setup/form/delete_prod_pause_type.cfm', { prod_pause_type_id: id }, function(res) {
                        if (res && res.success) {
                            pauseTypeData = pauseTypeData.filter(function(x){ return x.prod_pause_type_id != id; });
                            $('##pauseTypeGrid').dxDataGrid('instance').option('dataSource', pauseTypeData);
                            DevExpress.ui.notify('Silindi.', 'success', 2000);
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
