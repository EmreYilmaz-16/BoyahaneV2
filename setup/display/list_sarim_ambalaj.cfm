<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getSarimList" datasource="boyahane">
    SELECT sarim_sekli_id,
           COALESCE(sarim_sekli_adi,'') AS sarim_sekli_adi,
           COALESCE(sort_order, 0)      AS sort_order,
           COALESCE(is_active, true)    AS is_active,
           COALESCE(is_default, false)  AS is_default
    FROM setup_sarim_sekli
    ORDER BY sort_order, sarim_sekli_id
</cfquery>

<cfquery name="getAmbalajList" datasource="boyahane">
    SELECT ambalaj_id,
           COALESCE(ambalaj_adi,'')    AS ambalaj_adi,
           COALESCE(sort_order, 0)     AS sort_order,
           COALESCE(is_active, true)   AS is_active,
           COALESCE(is_default, false) AS is_default
    FROM setup_ambalaj
    ORDER BY sort_order, ambalaj_id
</cfquery>

<cfset sarimArr = []>
<cfloop query="getSarimList">
    <cfset arrayAppend(sarimArr, {
        "row_id"     : val(sarim_sekli_id),
        "adi"        : sarim_sekli_adi ?: "",
        "sort_order" : val(sort_order),
        "is_active"  : is_active,
        "is_default" : is_default
    })>
</cfloop>

<cfset ambalajArr = []>
<cfloop query="getAmbalajList">
    <cfset arrayAppend(ambalajArr, {
        "row_id"     : val(ambalaj_id),
        "adi"        : ambalaj_adi ?: "",
        "sort_order" : val(sort_order),
        "is_active"  : is_active,
        "is_default" : is_default
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-layer-group"></i></div>
        <div class="page-header-title">
            <h1>Sarım &amp; Ambalaj Tipleri</h1>
            <p>Sarım şekli ve ambalaj tipi tanımları</p>
        </div>
    </div>
</div>

<div class="px-3 pb-5">

    <!--- SARIM ŞEKLİ BÖLÜMÜ --->
    <div class="grid-card mb-4">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-wind"></i>Sarım Şekilleri</div>
            <div class="d-flex align-items-center gap-2">
                <span class="record-count" id="sarimCount">Yükleniyor...</span>
                <button class="btn-add btn-sm" onclick="addRow('sarim')">
                    <i class="fas fa-plus"></i>Yeni Sarım Şekli
                </button>
            </div>
        </div>
        <div class="card-body p-2">
            <div id="sarimGrid"></div>
        </div>
    </div>

    <!--- AMBALAJ BÖLÜMÜ --->
    <div class="grid-card mb-4">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-box"></i>Ambalaj Tipleri</div>
            <div class="d-flex align-items-center gap-2">
                <span class="record-count" id="ambalajCount">Yükleniyor...</span>
                <button class="btn-add btn-sm" onclick="addRow('ambalaj')">
                    <i class="fas fa-plus"></i>Yeni Ambalaj Tipi
                </button>
            </div>
        </div>
        <div class="card-body p-2">
            <div id="ambalajGrid"></div>
        </div>
    </div>

</div>

<!--- MODAL --->
<div id="sarimAmbalajModal" class="modal fade" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="modalTitle">Tanım</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="fld_row_id" value="0">
                <input type="hidden" id="fld_table_type" value="">
                <div class="row g-3">
                    <div class="col-md-8">
                        <label class="form-label">Ad <span class="text-danger">*</span></label>
                        <div id="fld_adi_dx"></div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Sıra No</label>
                        <div id="fld_sort_order_dx"></div>
                    </div>
                    <div class="col-12 d-flex gap-4">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="fld_is_active" checked>
                            <label class="form-check-label" for="fld_is_active">Aktif</label>
                        </div>
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="fld_is_default">
                            <label class="form-check-label" for="fld_is_default">Varsayılan</label>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Vazgeç</button>
                <button type="button" class="btn btn-primary" id="btnSaveRow" onclick="saveRow()">
                    <i class="fas fa-save me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<div id="deleteConfirmContainer"></div>

<script>
var sarimData   = #serializeJSON(sarimArr)#;
var ambalajData = #serializeJSON(ambalajArr)#;

$(function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    document.body.appendChild(document.getElementById('sarimAmbalajModal'));

    $('##fld_adi_dx').dxTextBox({ placeholder: 'Ad giriniz...' });
    $('##fld_sort_order_dx').dxNumberBox({ value: 0, min: 0, max: 9999 });

    buildGrid('sarim');
    buildGrid('ambalaj');
});

function buildGrid(tableType) {
    var gridId   = tableType === 'sarim' ? '##sarimGrid'   : '##ambalajGrid';
    var countId  = tableType === 'sarim' ? 'sarimCount'    : 'ambalajCount';
    var data     = tableType === 'sarim' ? sarimData       : ambalajData;

    $(gridId).dxDataGrid({
        dataSource: data,
        keyExpr: 'row_id',
        showBorders: true,
        rowAlternationEnabled: true,
        columnAutoWidth: false,
        paging: { pageSize: 25 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [15,25,50], showInfo: true },
        searchPanel: { visible: true, placeholder: 'Ara...' },
        filterRow: { visible: false },
        onContentReady: function(e) {
            document.getElementById(countId).textContent = e.component.totalCount() + ' kayıt';
        },
        columns: [
            { dataField:'row_id',     caption:'ID',   width:65,  alignment:'center', dataType:'number', sortOrder:'asc' },
            { dataField:'adi',        caption:'Ad',   minWidth:200 },
            { dataField:'sort_order', caption:'Sıra', width:80,  alignment:'center', dataType:'number' },
            {
                dataField:'is_default', caption:'Varsayılan', width:110, alignment:'center',
                cellTemplate: function(c,o) {
                    if (o.value) $('<span class="badge bg-primary"><i class="fas fa-star me-1"></i>Varsayılan</span>').appendTo(c);
                }
            },
            {
                dataField:'is_active', caption:'Aktif', width:80, alignment:'center',
                cellTemplate: function(c,o) {
                    $('<span class="badge bg-' + (o.value ? 'success' : 'secondary') + '">' + (o.value ? 'Aktif' : 'Pasif') + '</span>').appendTo(c);
                }
            },
            {
                caption:'İşlemler', width:110, alignment:'center', allowFiltering:false, allowSorting:false,
                cellTemplate: function(c,o) {
                    var d = o.data;
                    $('<button class="btn btn-xs btn-outline-warning me-1" title="Düzenle"><i class="fas fa-edit"></i></button>')
                        .on('click', function(){ editRow(tableType, d); }).appendTo(c);
                    $('<button class="btn btn-xs btn-outline-danger" title="Sil"><i class="fas fa-trash"></i></button>')
                        .on('click', function(){ deleteRow(tableType, d); }).appendTo(c);
                }
            }
        ]
    });
}

function addRow(tableType) {
    clearModal();
    document.getElementById('fld_table_type').value = tableType;
    document.getElementById('modalTitle').textContent = tableType === 'sarim' ? 'Yeni Sarım Şekli' : 'Yeni Ambalaj Tipi';
    new bootstrap.Modal(document.getElementById('sarimAmbalajModal')).show();
}

function editRow(tableType, d) {
    clearModal();
    document.getElementById('fld_table_type').value = tableType;
    document.getElementById('fld_row_id').value = d.row_id;
    document.getElementById('modalTitle').textContent = tableType === 'sarim' ? 'Sarım Şekli Düzenle' : 'Ambalaj Tipi Düzenle';
    $('##fld_adi_dx').dxTextBox('instance').option('value', d.adi);
    $('##fld_sort_order_dx').dxNumberBox('instance').option('value', d.sort_order || 0);
    document.getElementById('fld_is_active').checked  = !!d.is_active;
    document.getElementById('fld_is_default').checked = !!d.is_default;
    new bootstrap.Modal(document.getElementById('sarimAmbalajModal')).show();
}

function clearModal() {
    document.getElementById('fld_row_id').value = 0;
    document.getElementById('fld_table_type').value = '';
    $('##fld_adi_dx').dxTextBox('instance').option('value', '');
    $('##fld_sort_order_dx').dxNumberBox('instance').option('value', 0);
    document.getElementById('fld_is_active').checked  = true;
    document.getElementById('fld_is_default').checked = false;
}

function saveRow() {
    var tableType = document.getElementById('fld_table_type').value;
    var adi       = ($('##fld_adi_dx').dxTextBox('instance').option('value') || '').trim();
    if (!adi) { DevExpress.ui.notify('Ad alanı zorunludur.', 'warning', 2500); return; }

    var payload = {
        table_type : tableType,
        row_id     : parseInt(document.getElementById('fld_row_id').value) || 0,
        adi        : adi,
        sort_order : $('##fld_sort_order_dx').dxNumberBox('instance').option('value') || 0,
        is_active  : document.getElementById('fld_is_active').checked  ? 1 : 0,
        is_default : document.getElementById('fld_is_default').checked ? 1 : 0
    };

    $('##btnSaveRow').prop('disabled', true);
    $.post('/setup/form/save_sarim_ambalaj.cfm', payload, function(res) {
        if (res && res.success) {
            bootstrap.Modal.getInstance(document.getElementById('sarimAmbalajModal')).hide();

            var dataArr  = tableType === 'sarim' ? sarimData : ambalajData;
            var gridSel  = tableType === 'sarim' ? '##sarimGrid' : '##ambalajGrid';

            // Diğer varsayılanları kaldır (UI)
            if (payload.is_default) {
                dataArr.forEach(function(x) { x.is_default = false; });
            }

            if (payload.row_id > 0) {
                var row = dataArr.find(function(x){ return x.row_id == payload.row_id; });
                if (row) { Object.assign(row, { adi: payload.adi, sort_order: payload.sort_order, is_active: !!payload.is_active, is_default: !!payload.is_default }); }
            } else {
                payload.row_id = res.row_id;
                dataArr.push(payload);
            }
            $(gridSel).dxDataGrid('instance').option('dataSource', dataArr);
            DevExpress.ui.notify('Kaydedildi.', 'success', 2000);
        } else {
            DevExpress.ui.notify((res && res.message) || 'Kayıt başarısız.', 'error', 3000);
        }
    }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); })
              .always(function(){ $('##btnSaveRow').prop('disabled', false); });
}

function deleteRow(tableType, d) {
    var label = d.adi;
    $('##deleteConfirmContainer').dxDialog({
        title: 'Sil',
        messageHtml: '<b>' + label + '</b> kaydını silmek istiyor musunuz?',
        buttons: [
            {
                text: 'Evet, Sil', type: 'danger',
                onClick: function() {
                    $.post('/setup/form/delete_sarim_ambalaj.cfm', { table_type: tableType, row_id: d.row_id }, function(res) {
                        if (res && res.success) {
                            var gridSel = tableType === 'sarim' ? '##sarimGrid' : '##ambalajGrid';
                            if (tableType === 'sarim') {
                                sarimData = sarimData.filter(function(x){ return x.row_id != d.row_id; });
                                $('##sarimGrid').dxDataGrid('instance').option('dataSource', sarimData);
                            } else {
                                ambalajData = ambalajData.filter(function(x){ return x.row_id != d.row_id; });
                                $('##ambalajGrid').dxDataGrid('instance').option('dataSource', ambalajData);
                            }
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
