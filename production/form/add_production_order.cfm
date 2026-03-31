<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.p_order_id" default="0">
<cfset editMode   = isNumeric(url.p_order_id) AND val(url.p_order_id) gt 0>
<cfset currentId  = editMode ? val(url.p_order_id) : 0>

<cfif editMode>
    <cfquery name="getRec" datasource="boyahane">
        SELECT po.*,
               COALESCE(ci.color_code,'')           AS color_code,
               COALESCE(ci.color_name,'')           AS color_name,
               COALESCE(ci.company_id, 0)           AS color_company_id,
               COALESCE(c.nickname, c.fullname,'')  AS company_name,
               COALESCE(s.stock_code,'')            AS stock_code
        FROM production_orders po
        LEFT JOIN stocks      s  ON po.stock_id    = s.stock_id
        LEFT JOIN color_info  ci ON po.stock_id    = ci.stock_id
        LEFT JOIN company     c  ON ci.company_id  = c.company_id
        WHERE po.p_order_id = <cfqueryparam value="#currentId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getRec.recordCount>
        <cflocation url="index.cfm?fuseaction=production.list_production_orders" addtoken="false">
    </cfif>
<cfelse>
    <cfset getRec = {
        p_order_id   : 0,
        p_order_no   : "",
        lot_no       : "",
        quantity     : "",
        detail       : "",
        start_date   : "",
        finish_date  : "",
        status       : 1,
        stock_id     : 0,
        station_id   : 0
    }>
</cfif>

<!--- İş istasyonları --->
<cfquery name="getStations" datasource="boyahane">
    SELECT station_id, station_name, COALESCE(capacity,0) AS capacity
    FROM workstations
    WHERE COALESCE(active, false) = true
    ORDER BY station_name
</cfquery>
<cfset stArr = []>
<cfloop query="getStations">
    <cfset arrayAppend(stArr, { "station_id": val(station_id), "station_name": station_name ?: "", "capacity": val(capacity) })>
</cfloop>

<!--- Renk listesi (tüm renk kartları) --->
<cfquery name="getColors" datasource="boyahane">
    SELECT ci.stock_id,
           ci.color_code,
           ci.color_name,
           COALESCE(c.nickname, c.fullname,'')  AS company_name,
           COALESCE(s.stock_code,'')            AS stock_code
    FROM color_info ci
    LEFT JOIN stocks  s ON ci.stock_id   = s.stock_id
    LEFT JOIN company c ON ci.company_id = c.company_id
    ORDER BY ci.color_code, ci.color_name
</cfquery>
<cfset colArr = []>
<cfloop query="getColors">
    <cfset arrayAppend(colArr, {
        "stock_id"    : val(stock_id),
        "stock_code"  : stock_code    ?: "",
        "color_code"  : color_code    ?: "",
        "color_name"  : color_name    ?: "",
        "company_name": company_name  ?: "",
        "display"     : (len(color_code) ? color_code & " — " : "") & color_name & (len(company_name) ? " (" & company_name & ")" : "")
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-industry"></i></div>
        <div class="page-header-title">
            <h1><cfif editMode>Üretim Emri Düzenle<cfelse>Yeni Üretim Emri</cfif></h1>
            <p><cfif editMode>#htmlEditFormat(getRec.p_order_no)#<cfelse>Yeni boyama emri oluşturun</cfif></p>
        </div>
    </div>
    <div class="d-flex gap-2">
        <button class="btn-add" id="btnSave" onclick="saveOrder()">
            <i class="fas fa-save"></i>Kaydet
        </button>
        <a class="btn-back" href="index.cfm?fuseaction=production.list_production_orders">
            <i class="fas fa-arrow-left"></i>Listeye Dön
        </a>
    </div>
</div>

<div class="px-3 pb-5">
<div class="row g-3">

<!--- SOL --->
<div class="col-lg-6">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Emir Bilgileri</div>
        </div>
        <div class="card-body p-3">
            <input type="hidden" id="h_p_order_id" value="#currentId#">

            <div class="mb-3">
                <label class="form-label">Renk Kartı <span class="text-danger">*</span></label>
                <div id="colorSelect"></div>
            </div>

            <div class="row g-2 mb-3">
                <div class="col-6">
                    <label class="form-label">Emir No</label>
                    <input type="text" class="form-control" id="f_p_order_no"
                           value="#isEdit(editMode, htmlEditFormat(getRec.p_order_no))#"
                           maxlength="50" placeholder="Otomatik oluşturulur">
                </div>
                <div class="col-6">
                    <label class="form-label">Lot No</label>
                    <input type="text" class="form-control" id="f_lot_no"
                           value="#isEdit(editMode, htmlEditFormat(getRec.lot_no))#" maxlength="100">
                </div>
            </div>

            <div class="mb-3">
                <label class="form-label">Makina <span class="text-danger">*</span></label>
                <div id="stationSelect"></div>
            </div>

            <div class="mb-3">
                <label class="form-label">Miktar (kg) <span class="text-danger">*</span></label>
                <input type="number" step="0.001" min="0" class="form-control" id="f_quantity"
                       value="#isEdit(editMode, getRec.quantity)#" placeholder="0.000">
            </div>

            <div class="mb-3">
                <label class="form-label">Açıklama</label>
                <textarea class="form-control" id="f_detail" rows="2" maxlength="2000">#isEdit(editMode, htmlEditFormat(getRec.detail))#</textarea>
            </div>
        </div>
    </div>
</div>

<!--- SAĞ --->
<div class="col-lg-6">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-calendar-alt"></i>Tarih & Durum</div>
        </div>
        <div class="card-body p-3">

            <div class="row g-2 mb-3">
                <div class="col-6">
                    <label class="form-label">Planlanan Başlangıç</label>
                    <input type="datetime-local" class="form-control" id="f_start_date"
                           value="#isEdit(editMode, (isDate(getRec.start_date) ? dateFormat(getRec.start_date,'yyyy-mm-dd') & 'T' & timeFormat(getRec.start_date,'HH:mm') : ''))#">
                </div>
                <div class="col-6">
                    <label class="form-label">Planlanan Bitiş</label>
                    <input type="datetime-local" class="form-control" id="f_finish_date"
                           value="#isEdit(editMode, (isDate(getRec.finish_date) ? dateFormat(getRec.finish_date,'yyyy-mm-dd') & 'T' & timeFormat(getRec.finish_date,'HH:mm') : ''))#">
                </div>
            </div>

            <div class="mb-3">
                <label class="form-label">Durum</label>
                <div id="statusSelect"></div>
            </div>

            <!--- Seçilen renge ait reçete önizleme --->
            <div class="grid-card mt-3">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-flask"></i>Reçete Önizleme</div>
                </div>
                <div class="card-body p-2">
                    <div id="recipePreview">
                        <p class="text-muted small mb-0">Renk seçince reçete görünür.</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

</div><!--- row --->
</div><!--- px-3 --->

<script>
var colorsData   = #serializeJSON(colArr)#;
var stationsData = #serializeJSON(stArr)#;
var editMode     = #editMode ? 'true' : 'false'#;
var statusData = [
    { id: 1, label: 'Planlandı' },
    { id: 2, label: 'Devam Ediyor' },
    { id: 5, label: 'Tamamlandı' },
    { id: 9, label: 'İptal' }
];

$(function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    initSelects();
});

function initSelects() {
    $('##colorSelect').dxSelectBox({
        dataSource    : colorsData,
        valueExpr     : 'stock_id',
        displayExpr   : 'display',
        searchEnabled : true,
        searchExpr    : ['color_code','color_name','company_name','stock_code'],
        placeholder   : 'Renk ara...',
        value         : <cfif editMode>#getRec.stock_id#<cfelse>null</cfif>,
        onValueChanged: function(e) { if (e.value) loadRecipePreview(e.value); else $('##recipePreview').html('<p class="text-muted small mb-0">Renk seçince reçete görünür.</p>'); }
    });

    $('##stationSelect').dxSelectBox({
        dataSource    : stationsData,
        valueExpr     : 'station_id',
        displayExpr   : 'station_name',
        searchEnabled : true,
        placeholder   : 'Makina seçin...',
        value         : <cfif editMode>#getRec.station_id#<cfelse>null</cfif>
    });

    $('##statusSelect').dxSelectBox({
        dataSource  : statusData,
        valueExpr   : 'id',
        displayExpr : 'label',
        value       : <cfif editMode>#getRec.status#<cfelse>1</cfif>
    });

    <cfif editMode>
    loadRecipePreview(#getRec.stock_id#);
    </cfif>
}

function loadRecipePreview(stockId) {
    $.get('/colors/api/get_recipe.cfm', { stock_id: stockId }, function(res) {
        if (!res || !res.length) {
            $('##recipePreview').html('<p class="text-muted small mb-0">Bu renk için reçete bulunamadı.</p>');
            return;
        }
        var html = '';
        res.forEach(function(op) {
            html += '<div class="mb-2"><strong class="small"><i class="fas fa-cog text-muted me-1"></i>' + (op.PRODUCT_NAME || 'Operasyon') + '</strong><ul class="list-unstyled ms-3 mb-0">';
            (op.TREE || []).forEach(function(c) {
                html += '<li class="small text-secondary"><i class="fas fa-circle" style="font-size:6px;vertical-align:middle"></i> ' + c.PRODUCT_NAME + ' — <b>' + c.AMOUNT + '</b></li>';
            });
            html += '</ul></div>';
        });
        $('##recipePreview').html(html);
    }, 'json').fail(function(){ $('##recipePreview').html('<p class="text-danger small mb-0">Reçete yüklenemedi.</p>'); });
}

function saveOrder() {
    var colorSid   = $('##colorSelect').dxSelectBox('instance').option('value');
    var stationId  = $('##stationSelect').dxSelectBox('instance').option('value');
    var qty        = parseFloat(document.getElementById('f_quantity').value) || 0;

    if (!colorSid)   { DevExpress.ui.notify('Renk kartı seçimi zorunludur.', 'warning', 2500); return; }
    if (!stationId)  { DevExpress.ui.notify('Makina seçimi zorunludur.',     'warning', 2500); return; }
    if (qty <= 0)    { DevExpress.ui.notify('Miktar sıfırdan büyük olmalıdır.', 'warning', 2500); return; }

    var btn = document.getElementById('btnSave');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Kaydediliyor...';

    $.post('/production/form/save_production_order.cfm', {
        p_order_id   : document.getElementById('h_p_order_id').value,
        stock_id     : colorSid,
        station_id   : stationId,
        quantity     : qty,
        p_order_no   : document.getElementById('f_p_order_no').value.trim(),
        lot_no       : document.getElementById('f_lot_no').value.trim(),
        start_date   : document.getElementById('f_start_date').value,
        finish_date  : document.getElementById('f_finish_date').value,
        status       : $('##statusSelect').dxSelectBox('instance').option('value'),
        detail       : document.getElementById('f_detail').value.trim()
    }, function(res) {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-save"></i> Kaydet';
        if (res && res.success) {
            window.location.href = 'index.cfm?fuseaction=production.view_production_order&p_order_id=' + res.p_order_id;
        } else {
            DevExpress.ui.notify((res && res.message) || 'Kayıt başarısız.', 'error', 3500);
        }
    }, 'json').fail(function() {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-save"></i> Kaydet';
        DevExpress.ui.notify('Sunucu hatası.', 'error', 3000);
    });
}
</script>
</cfoutput>

<cffunction name="isEdit" returntype="string">
    <cfargument name="editMode" type="boolean">
    <cfargument name="val"      type="any" default="">
    <cfif arguments.editMode><cfreturn arguments.val></cfif>
    <cfreturn "">
</cffunction>
