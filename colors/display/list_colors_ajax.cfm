<cfprocessingdirective pageEncoding="utf-8">

<!--- Renk listesi --->
<cfquery name="getColors" datasource="boyahane">
    SELECT
        ci.color_id,
        ci.stock_id,
        ci.color_code,
        ci.color_name,
        ci.kartela_no,
        ci.renk_tonu,
        ci.boya_derecesi,
        ci.flote,
        ci.is_ready,
        ci.information,
        ci.kartela_date,
        ci.record_date,
        COALESCE(c.nickname, c.fullname, '') AS company_name,
        ci.company_id,
        COALESCE(p.product_name, '')          AS product_name,
        ci.product_id,
        COALESCE(s.stock_code, '')            AS stock_code
    FROM color_info ci
    LEFT JOIN company c  ON ci.company_id = c.company_id
    LEFT JOIN product p  ON ci.product_id = p.product_id
    LEFT JOIN stocks  s  ON ci.stock_id   = s.stock_id
    ORDER BY ci.record_date DESC
</cfquery>

<cfset colorsArr = []>
<cfloop query="getColors">
    <cfset arrayAppend(colorsArr, {
        "color_id"     : val(color_id),
        "stock_id"     : val(stock_id),
        "color_code"   : color_code    ?: "",
        "color_name"   : color_name    ?: "",
        "kartela_no"   : kartela_no    ?: "",
        "renk_tonu"    : isNumeric(renk_tonu) ? val(renk_tonu) : 0,
        "boya_derecesi": boya_derecesi ?: "",
        "flote"        : isNumeric(flote) ? val(flote) : 0,
        "is_ready"     : is_ready,
        "information"  : information   ?: "",
        "kartela_date" : isDate(kartela_date) ? dateFormat(kartela_date,"dd/mm/yyyy") : "",
        "company_id"   : val(company_id),
        "company_name" : company_name  ?: "",
        "product_id"   : val(product_id),
        "product_name" : product_name  ?: "",
        "stock_code"   : stock_code    ?: "",
        "record_date"  : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") : ""
    })>
</cfloop>

<!--- Müşteri listesi (popup için) --->
<cfquery name="getCompanies" datasource="boyahane">
    SELECT company_id, COALESCE(nickname, fullname, '') AS company_name, member_code
    FROM company
    WHERE company_status = true
    ORDER BY nickname, fullname
</cfquery>
<cfset companiesArr = []>
<cfloop query="getCompanies">
    <cfset arrayAppend(companiesArr, {
        "company_id"  : val(company_id),
        "company_name": company_name ?: "",
        "member_code" : member_code  ?: ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-palette"></i></div>
        <div class="page-header-title">
            <h1>Renk Kartoteksi</h1>
            <p>Tüm renk kayıtlarını görüntüleyin ve yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="openAddColorModal()">
        <i class="fas fa-plus"></i>Yeni Renk
    </button>
</div>

<cfif isDefined("url.success")>
    <cfoutput>
    <div class="alert alert-success alert-dismissible fade show mb-3 mx-3">
        <i class="fas fa-check-circle me-2"></i>
        <cfif url.success eq "added"><strong>Başarılı!</strong> Renk oluşturuldu.
        <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Renk güncellendi.
        <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Renk silindi.
        </cfif>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    </cfoutput>
</cfif>

<div class="px-3 pb-5">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Renk Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="colorGrid"></div>
        </div>
    </div>
</div>

<!--- ======================== YENİ RENK POPUP ======================== --->
<style>
.add-color-modal .modal-header { background: var(--primary); color: #fff; }
.add-color-modal .modal-footer { background: #f8fafc; }
.add-color-modal .popup-section-label {
    display: flex;
    align-items: center;
    gap: 7px;
    font-size: 0.7rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1.1px;
    color: #64748b;
    margin: 14px 0 8px;
    padding-bottom: 6px;
    border-bottom: 1px dashed #e2e8f0;
}
.add-color-modal .popup-section-label:first-child { margin-top: 0; }
.add-color-modal .popup-section-label i { color: var(--accent); font-size: 0.68rem; }
.add-color-modal .ready-switch-wrap {
    background: linear-gradient(135deg, #f0fdf4, #dcfce7);
    border: 1px solid #bbf7d0;
    border-radius: 10px;
    padding: 9px 14px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
    height: 100%;
}
.add-color-modal .ready-switch-wrap > span {
    font-size: 0.82rem;
    font-weight: 600;
    color: #15803d;
}
.add-color-modal .ready-switch-wrap .form-check-input:checked {
    background-color: #16a34a;
    border-color: #16a34a;
}
</style>

<div class="modal fade add-color-modal" id="modalAddColor" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fas fa-palette me-2"></i>Yeni Renk Ekle</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-4">
                <div class="row g-2">

                    <!--- Bağlantı --->
                    <div class="col-12"><div class="popup-section-label"><i class="fas fa-link"></i>Bağlantı</div></div>
                    <div class="col-md-6">
                        <label class="form-label">Müşteri <span class="text-danger">*</span></label>
                        <div id="popupCompanySelect"></div>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Ürün / Kumaş</label>
                        <div id="popupProductSelect"></div>
                        <div class="form-text">Önce müşteri seçin.</div>
                    </div>

                    <!--- Renk Tanımı --->
                    <div class="col-12"><div class="popup-section-label"><i class="fas fa-fill-drip"></i>Renk Tanımı</div></div>
                    <div class="col-md-4">
                        <label class="form-label">Renk Kodu</label>
                        <input type="text" class="form-control" id="p_color_code" maxlength="100" placeholder="R.Kodu">
                    </div>
                    <div class="col-md-8">
                        <label class="form-label">Renk Adı</label>
                        <input type="text" class="form-control" id="p_color_name" maxlength="255" placeholder="Renk adı">
                    </div>

                    <!--- Kartela --->
                    <div class="col-12"><div class="popup-section-label"><i class="fas fa-id-card"></i>Kartela Bilgisi</div></div>
                    <div class="col-md-6">
                        <label class="form-label">Kartela No</label>
                        <input type="text" class="form-control" id="p_kartela_no" maxlength="100">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Kartela Tarihi</label>
                        <input type="date" class="form-control" id="p_kartela_date">
                    </div>

                    <!--- Boyama Parametreleri --->
                    <div class="col-12"><div class="popup-section-label"><i class="fas fa-flask"></i>Boyama Parametreleri</div></div>
                    <div class="col-md-4">
                        <label class="form-label">R.Tonu</label>
                        <input type="number" min="0" max="9" class="form-control" id="p_renk_tonu">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Boya C.</label>
                        <input type="text" class="form-control" id="p_boya_derecesi" maxlength="50">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Flote</label>
                        <input type="number" step="0.01" min="0" class="form-control" id="p_flote">
                    </div>

                    <!--- Ek Bilgi --->
                    <div class="col-12"><div class="popup-section-label"><i class="fas fa-sticky-note"></i>Ek Bilgi</div></div>
                    <div class="col-md-8">
                        <label class="form-label">Açıklama</label>
                        <input type="text" class="form-control" id="p_information" maxlength="500">
                    </div>
                    <div class="col-md-4 d-flex align-items-end">
                        <div class="ready-switch-wrap w-100">
                            <span><i class="fas fa-check-circle me-1"></i>Hazır?</span>
                            <div class="form-check form-switch mb-0">
                                <input class="form-check-input" type="checkbox" id="p_is_ready">
                                <label class="form-check-label" for="p_is_ready">Hazır</label>
                            </div>
                        </div>
                    </div>

                </div><!--- row --->
            </div><!--- modal-body --->
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">
                    <i class="fas fa-times me-1"></i>İptal
                </button>
                <button type="button" class="btn btn-primary btn-sm" id="btnPopupSave" onclick="saveNewColor()">
                    <i class="fas fa-save me-1"></i>Kaydet ve Reçeteye Git
                </button>
            </div>
        </div>
    </div>
</div>
<!--- ================================================================ --->

<cfoutput>
<script>
var colorData = #serializeJSON(colorsArr)#;
var companiesData = #serializeJSON(companiesArr)#;
var popupSelectsInitialized = false;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    /* Modal'ı body'ye taşı: content-wrapper'ın fixed+overflow stacking context'inden kurtar */
    var modal = document.getElementById('modalAddColor');
    if (modal) document.body.appendChild(modal);
    initGrid();
});

function initGrid() {
    $('##colorGrid').dxDataGrid({
        dataSource: colorData,
        keyExpr: 'color_id',
        showBorders: true, showRowLines: true, showColumnLines: true,
        rowAlternationEnabled: true, columnAutoWidth: false,
        allowColumnReordering: true, allowColumnResizing: true, columnResizingMode: 'widget',
        width: '100%', height: 'auto',
        scrolling: { mode: 'virtual', rowRenderingMode: 'virtual' },
        paging:      { enabled: true, pageSize: 50 },
        filterRow:   { visible: true },
        headerFilter:{ visible: true },
        searchPanel: { visible: true, width: 240, placeholder: 'Ara...' },
        sorting:     { mode: 'multiple' },
        columnChooser: { enabled: true, mode: 'select', title: 'Sütun Seçimi' },
        export: { enabled: true },
        onExporting: function (e) {
            var workbook = new ExcelJS.Workbook();
            var worksheet = workbook.addWorksheet('RenkKartoteksi');
            DevExpress.excelExporter.exportDataGrid({
                component: e.component,
                worksheet: worksheet,
                autoFilterEnabled: true
            }).then(function () {
                workbook.xlsx.writeBuffer().then(function (buffer) {
                    var fileName = 'renk_kartoteksi_' + new Date().toISOString().slice(0, 10) + '.xlsx';
                    saveAs(new Blob([buffer], { type: 'application/octet-stream' }), fileName);
                });
            });
            e.cancel = true;
        },
        onContentReady: function(e) {
            document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt';
        },
        columns: [
            { dataField: 'color_code',    caption: 'Renk Kodu',   width: 120,
              cellTemplate: function(c,o){
                  $('<a>').attr('href','index.cfm?fuseaction=colors.add_color&color_id='+o.data.color_id)
                      .css({fontWeight:'bold',cursor:'pointer'}).text(o.value||'-').appendTo(c);
              }
            },
            { dataField: 'color_name',    caption: 'Renk Adı',    minWidth: 150,
              cellTemplate: function(c,o){
                  $('<a>').attr('href','index.cfm?fuseaction=colors.add_color&color_id='+o.data.color_id)
                      .css({cursor:'pointer'}).text(o.value||'-').appendTo(c);
              }
            },
            { dataField: 'company_name',  caption: 'Müşteri',     minWidth: 160 },
            { dataField: 'product_name',  caption: 'Ürün',        minWidth: 150 },
            { dataField: 'kartela_no',    caption: 'Kartela',     width: 120 },
            { dataField: 'kartela_date',  caption: 'K.Tarihi',    width: 110, alignment: 'center' },
            { dataField: 'renk_tonu',     caption: 'R.Tonu',      width: 80, alignment: 'center' },
            { dataField: 'boya_derecesi', caption: 'Boya C',      width: 90 },
            { dataField: 'flote',         caption: 'Flote',       width: 80, alignment: 'right',
              format: { type: 'fixedPoint', precision: 2 } },
            { dataField: 'is_ready',      caption: 'Hazır',       width: 70, alignment: 'center', dataType: 'boolean' },
            { dataField: 'information',   caption: 'Açıklama',    minWidth: 120,
              cellTemplate: function(c,o){ $('<span>').addClass('small text-muted').text(o.value||'').appendTo(c); } },
            {
                caption: 'İşlemler', width: 130, alignment: 'center', allowSorting: false, allowFiltering: false,
                cellTemplate: function(c, o) {
                    var g = $('<div>').addClass('d-flex gap-1 justify-content-center');
                    $('<a>').addClass('btn btn-sm btn-outline-primary').attr('title','Düzenle')
                        .attr('href','index.cfm?fuseaction=colors.add_color&color_id='+o.data.color_id)
                        .html('<i class="fas fa-edit"></i>').appendTo(g);
                    $('<a>').addClass('btn btn-sm btn-outline-secondary').attr('title','Reçeteyi Görüntüle')
                        .attr('href','index.cfm?fuseaction=product.view_product_tree&stock_id='+o.data.stock_id)
                        .html('<i class="fas fa-sitemap"></i>').appendTo(g);
                    $('<button>').addClass('btn btn-sm btn-outline-danger').attr('title','Sil')
                        .html('<i class="fas fa-trash"></i>')
                        .on('click', function(){ deleteColor(o.data.color_id, o.data.color_code || o.data.color_name); })
                        .appendTo(g);
                    g.appendTo(c);
                }
            }
        ]
    });
}

function deleteColor(id, label) {
    DevExpress.ui.dialog.confirm(
        '"' + label + '" rengini silmek istiyor musunuz?', 'Silme Onayı'
    ).then(function(ok) {
        if (!ok) return;
        $.post('/colors/form/delete_color.cfm', { color_id: id }, function(res) {
            if (res && res.success) {
                colorData = colorData.filter(function(x){ return x.color_id !== id; });
                $('##colorGrid').dxDataGrid('instance').option('dataSource', colorData);
                DevExpress.ui.notify('Renk silindi.', 'success', 2500);
            } else {
                DevExpress.ui.notify((res && res.message) || 'Silme başarısız.', 'error', 3500);
            }
        }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); });
    });
}
/* ── Yeni Renk Popup ── */
function openAddColorModal() {
    ['p_color_code','p_color_name','p_kartela_no','p_kartela_date',
     'p_renk_tonu','p_boya_derecesi','p_flote','p_information'
    ].forEach(function(id) { var el = document.getElementById(id); if (el) el.value = ''; });
    var cb = document.getElementById('p_is_ready'); if (cb) cb.checked = false;
    if (popupSelectsInitialized) {
        if ($('##popupCompanySelect').data('dxSelectBox'))
            $('##popupCompanySelect').dxSelectBox('instance').option('value', null);
        clearPopupProducts();
    }
    new bootstrap.Modal(document.getElementById('modalAddColor')).show();
}

$('##modalAddColor').on('shown.bs.modal', function() {
    if (popupSelectsInitialized) return;
    popupSelectsInitialized = true;
    $('##popupCompanySelect').dxSelectBox({
        dataSource  : companiesData,
        valueExpr   : 'company_id',
        displayExpr : function(item) {
            return item ? (item.member_code ? item.member_code + ' \u2014 ' : '') + item.company_name : '';
        },
        searchEnabled : true,
        searchExpr    : ['company_name','member_code'],
        placeholder   : 'M\u00fc\u015fteri se\u00e7in...',
        value         : null,
        onValueChanged: function(e) {
            if (e.value) { loadPopupProducts(e.value); }
            else { clearPopupProducts(); }
        }
    });
});

function loadPopupProducts(companyId) {
    $.get('/colors/api/get_company_products.cfm', { company_id: companyId }, function(res) {
        if (!res || !res.length) { clearPopupProducts(); return; }
        var opts = {
            dataSource  : res,
            valueExpr   : 'product_id',
            displayExpr : function(item) {
                return item ? (item.stock_code ? item.stock_code + ' \u2014 ' : '') + item.product_name : '';
            },
            searchEnabled: true,
            searchExpr   : ['product_name','stock_code'],
            placeholder  : '\u00dcr\u00fcn / Kuma\u015f se\u00e7...',
            value        : null
        };
        if ($('##popupProductSelect').data('dxSelectBox')) {
            var inst = $('##popupProductSelect').dxSelectBox('instance');
            inst.option('dataSource', res);
            inst.option('value', null);
        } else {
            $('##popupProductSelect').dxSelectBox(opts);
        }
    }, 'json');
}

function clearPopupProducts() {
    if ($('##popupProductSelect').data('dxSelectBox')) {
        var inst = $('##popupProductSelect').dxSelectBox('instance');
        inst.option('dataSource', []);
        inst.option('value', null);
    } else {
        $('##popupProductSelect').empty();
    }
}

function saveNewColor() {
    var companyId = $('##popupCompanySelect').data('dxSelectBox')
        ? $('##popupCompanySelect').dxSelectBox('instance').option('value') : null;
    if (!companyId) {
        DevExpress.ui.notify('M\u00fc\u015fteri se\u00e7imi zorunludur.', 'warning', 2500); return;
    }
    var productId = $('##popupProductSelect').data('dxSelectBox')
        ? $('##popupProductSelect').dxSelectBox('instance').option('value') : null;

    var btn = document.getElementById('btnPopupSave');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Kaydediliyor...';

    $.post('/colors/form/save_color.cfm', {
        stock_id      : 0,
        company_id    : companyId,
        product_id    : productId || '',
        color_code    : document.getElementById('p_color_code').value,
        color_name    : document.getElementById('p_color_name').value,
        kartela_no    : document.getElementById('p_kartela_no').value,
        kartela_date  : document.getElementById('p_kartela_date').value,
        renk_tonu     : document.getElementById('p_renk_tonu').value,
        boya_derecesi : document.getElementById('p_boya_derecesi').value,
        flote         : document.getElementById('p_flote').value,
        information   : document.getElementById('p_information').value,
        is_ready      : document.getElementById('p_is_ready').checked ? 'true' : 'false',
        recipe_json   : '[]'
    }, function(res) {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-save me-1"></i>Kaydet ve Re\u00e7eteye Git';
        if (res && res.success) {
            DevExpress.ui.notify('Renk olu\u015fturuldu, re\u00e7ete sayfas\u0131na y\u00f6nlendiriliyorsunuz...', 'success', 2500);
            setTimeout(function() {
                window.location.href = 'index.cfm?fuseaction=colors.add_color&color_id=' + res.color_id;
            }, 1800);
        } else {
            DevExpress.ui.notify((res && res.message) || 'Kay\u0131t ba\u015far\u0131s\u0131z.', 'error', 3500);
        }
    }, 'json').fail(function() {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-save me-1"></i>Kaydet ve Re\u00e7eteye Git';
        DevExpress.ui.notify('Sunucu hatas\u0131.', 'error', 3000);
    });
}</script>
</cfoutput>