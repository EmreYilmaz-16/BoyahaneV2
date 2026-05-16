<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getParams" datasource="boyahane">
    SELECT param_id,
           COALESCE(parametre_adi,'') AS parametre_adi,
           COALESCE(deger,'')         AS deger,
           COALESCE(aciklama,'')      AS aciklama,
           TO_CHAR(record_date, 'DD/MM/YYYY HH24:MI') AS record_date,
           TO_CHAR(update_date, 'DD/MM/YYYY HH24:MI') AS update_date
    FROM boyahane_params
    ORDER BY parametre_adi
</cfquery>

<cfset paramArr = []>
<cfloop query="getParams">
    <cfset arrayAppend(paramArr, {
        "param_id"     : val(param_id),
        "parametre_adi": parametre_adi ?: "",
        "deger"        : deger         ?: "",
        "aciklama"     : aciklama      ?: "",
        "record_date"  : record_date   ?: "",
        "update_date"  : update_date   ?: ""
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-sliders-h"></i></div>
        <div class="page-header-title">
            <h1>Sistem Parametreleri</h1>
            <p>Uygulama genelinde kullanılan anahtar-değer parametreler</p>
        </div>
    </div>
    <button class="btn-add" onclick="addParam()">
        <i class="fas fa-plus"></i>Yeni Parametre
    </button>
</div>

<div class="px-3 pb-5">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Parametre Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="paramGrid"></div>
        </div>
    </div>
</div>

<!--- MODAL --->
<div id="paramModal" class="modal fade" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="paramModalTitle">Parametre</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="fld_param_id" value="0">
                <div class="row g-3">
                    <div class="col-md-5">
                        <label class="form-label">Parametre Adı <span class="text-danger">*</span></label>
                        <div id="fld_parametre_adi_dx"></div>
                        <div class="form-text text-muted">Kodda kullanacağınız anahtar (örn: <code>VARSAYILAN_RENK</code>)</div>
                    </div>
                    <div class="col-md-7">
                        <label class="form-label">Değer <span class="text-danger">*</span></label>
                        <div id="fld_deger_dx"></div>
                    </div>
                    <div class="col-12">
                        <label class="form-label">Açıklama</label>
                        <div id="fld_aciklama_dx"></div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Vazgeç</button>
                <button type="button" class="btn btn-primary" id="btnSaveParam" onclick="saveParam()">
                    <i class="fas fa-save me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<script>
var paramData = #serializeJSON(paramArr)#;

$(function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    document.body.appendChild(document.getElementById('paramModal'));

    $('##fld_parametre_adi_dx').dxTextBox({ placeholder: 'PARAMETRE_ADI' });
    $('##fld_deger_dx').dxTextBox({ placeholder: 'Değer...' });
    $('##fld_aciklama_dx').dxTextArea({ height: 70, placeholder: 'İsteğe bağlı açıklama...' });

    buildGrid();
});

function buildGrid() {
    $('##paramGrid').dxDataGrid({
        dataSource: paramData,
        keyExpr: 'param_id',
        showBorders: true,
        rowAlternationEnabled: true,
        columnAutoWidth: false,
        paging: { pageSize: 50 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [25,50,100], showInfo: true },
        searchPanel: { visible: true, placeholder: 'Ara...' },
        filterRow: { visible: true },
        onContentReady: function(e) {
            document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt';
        },
        columns: [
            { dataField:'param_id',      caption:'ID',            width:65,  alignment:'center', dataType:'number' },
            {
                dataField:'parametre_adi', caption:'Parametre Adı', minWidth:180,
                cellTemplate: function(c,o) {
                    $('<code style="font-size:.85rem;color:##1967d2">' + escHtml(o.value) + '</code>').appendTo(c);
                }
            },
            { dataField:'deger',         caption:'Değer',          minWidth:200 },
            { dataField:'aciklama',      caption:'Açıklama',       minWidth:150 },
            { dataField:'record_date',   caption:'Oluşturuldu',    width:140, alignment:'center' },
            { dataField:'update_date',   caption:'Güncellendi',    width:140, alignment:'center' },
            {
                caption:'İşlemler', width:110, alignment:'center', allowFiltering:false, allowSorting:false,
                cellTemplate: function(c,o) {
                    var d = o.data;
                    $('<button class="btn btn-xs btn-outline-warning me-1" title="Düzenle"><i class="fas fa-edit"></i></button>')
                        .on('click', function(){ editParam(d); }).appendTo(c);
                    $('<button class="btn btn-xs btn-outline-danger" title="Sil"><i class="fas fa-trash"></i></button>')
                        .on('click', function(){ deleteParam(d.param_id, d.parametre_adi); }).appendTo(c);
                }
            }
        ]
    });
}

function addParam() {
    clearModal();
    document.getElementById('paramModalTitle').textContent = 'Yeni Parametre';
    new bootstrap.Modal(document.getElementById('paramModal')).show();
}

function editParam(d) {
    clearModal();
    document.getElementById('paramModalTitle').textContent = 'Parametre Düzenle';
    document.getElementById('fld_param_id').value = d.param_id;
    $('##fld_parametre_adi_dx').dxTextBox('instance').option('value', d.parametre_adi);
    $('##fld_deger_dx').dxTextBox('instance').option('value', d.deger);
    $('##fld_aciklama_dx').dxTextArea('instance').option('value', d.aciklama);
    new bootstrap.Modal(document.getElementById('paramModal')).show();
}

function clearModal() {
    document.getElementById('fld_param_id').value = 0;
    $('##fld_parametre_adi_dx').dxTextBox('instance').option('value', '');
    $('##fld_deger_dx').dxTextBox('instance').option('value', '');
    $('##fld_aciklama_dx').dxTextArea('instance').option('value', '');
}

function saveParam() {
    var adi   = ($('##fld_parametre_adi_dx').dxTextBox('instance').option('value') || '').trim();
    var deger = ($('##fld_deger_dx').dxTextBox('instance').option('value') || '').trim();
    if (!adi)   { DevExpress.ui.notify('Parametre adı zorunludur.', 'warning', 2500); return; }
    if (!deger) { DevExpress.ui.notify('Değer zorunludur.',         'warning', 2500); return; }

    var payload = {
        param_id     : parseInt(document.getElementById('fld_param_id').value) || 0,
        parametre_adi: adi,
        deger        : deger,
        aciklama     : ($('##fld_aciklama_dx').dxTextArea('instance').option('value') || '').trim()
    };

    $('##btnSaveParam').prop('disabled', true);
    $.post('/setup/form/save_param.cfm', payload, function(res) {
        if (res && res.success) {
            bootstrap.Modal.getInstance(document.getElementById('paramModal')).hide();
            var now = new Date();
            var fmt = ('0'+now.getDate()).slice(-2) + '/' + ('0'+(now.getMonth()+1)).slice(-2) + '/' + now.getFullYear() +
                      ' ' + ('0'+now.getHours()).slice(-2) + ':' + ('0'+now.getMinutes()).slice(-2);
            if (payload.param_id > 0) {
                var row = paramData.find(function(x){ return x.param_id == payload.param_id; });
                if (row) { Object.assign(row, { parametre_adi: payload.parametre_adi, deger: payload.deger, aciklama: payload.aciklama, update_date: fmt }); }
            } else {
                paramData.push({ param_id: res.param_id, parametre_adi: payload.parametre_adi, deger: payload.deger, aciklama: payload.aciklama, record_date: fmt, update_date: '' });
            }
            $('##paramGrid').dxDataGrid('instance').option('dataSource', paramData);
            DevExpress.ui.notify('Kaydedildi.', 'success', 2000);
        } else {
            DevExpress.ui.notify((res && res.message) || 'Kayıt başarısız.', 'error', 3500);
        }
    }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); })
              .always(function(){ $('##btnSaveParam').prop('disabled', false); });
}

function deleteParam(id, label) {
    DevExpress.ui.dialog.confirm(
        '<b>' + escHtml(label) + '</b> parametresini silmek istiyor musunuz?',
        'Sil'
    ).done(function(confirmed) {
        if (!confirmed) return;
        $.post('/setup/form/delete_param.cfm', { param_id: id }, function(res) {
            if (res && res.success) {
                paramData = paramData.filter(function(x){ return x.param_id != id; });
                $('##paramGrid').dxDataGrid('instance').option('dataSource', paramData);
                DevExpress.ui.notify('Silindi.', 'success', 2000);
            } else {
                DevExpress.ui.notify((res && res.message) || 'Silinemedi.', 'error', 3000);
            }
        }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); });
    });
}

function escHtml(str) {
    return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
</script>
</cfoutput>
