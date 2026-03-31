<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.p_order_id" default="0">
<cfset pOrderId = isNumeric(url.p_order_id) AND val(url.p_order_id) gt 0 ? val(url.p_order_id) : 0>

<cfif pOrderId eq 0>
    <cflocation url="index.cfm?fuseaction=production.list_production_orders" addtoken="false">
</cfif>

<!--- Üretim emri başlık --->
<cfquery name="getOrder" datasource="boyahane">
    SELECT po.p_order_id, po.p_order_no, po.status, po.quantity,
           COALESCE(po.lot_no,'') AS lot_no,
           COALESCE(ci.color_code,'') AS color_code,
           COALESCE(ci.color_name,'') AS color_name,
           COALESCE(ws.station_name,'') AS station_name,
           COALESCE(c.nickname, c.fullname,'') AS company_name
    FROM production_orders po
    LEFT JOIN stocks       s  ON po.stock_id   = s.stock_id
    LEFT JOIN color_info   ci ON po.stock_id   = ci.stock_id
    LEFT JOIN company      c  ON ci.company_id = c.company_id
    LEFT JOIN workstations ws ON po.station_id = ws.station_id
    WHERE po.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getOrder.recordCount>
    <cflocation url="index.cfm?fuseaction=production.list_production_orders" addtoken="false">
</cfif>

<!--- Operasyonlar --->
<cfquery name="getOps" datasource="boyahane">
    SELECT po2.p_operation_id,
           COALESCE(ot.operation_type,'')  AS operation_type,
           COALESCE(ot.operation_code,'') AS operation_code,
           COALESCE(ws.station_name,'')   AS station_name,
           COALESCE(po2.stage, 0)         AS stage,
           COALESCE(po2.amount, 0)        AS amount,
           COALESCE(po2.o_minute, 0)      AS o_minute,
           po2.o_start_date,
           po2.o_finish_date
    FROM production_operation po2
    LEFT JOIN operation_types ot ON po2.operation_type_id = ot.operation_type_id
    LEFT JOIN workstations    ws ON po2.station_id        = ws.station_id
    WHERE po2.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    ORDER BY po2.p_operation_id
</cfquery>

<!--- Duruş kayıtları --->
<cfquery name="getPauses" datasource="boyahane">
    SELECT sp.prod_pause_id,
           COALESCE(spt.prod_pause_type,'') AS pause_type_name,
           COALESCE(sp.prod_duration, 0)    AS prod_duration,
           COALESCE(sp.prod_detail,'')      AS prod_detail,
           COALESCE(sp.is_working_time, false) AS is_working_time,
           sp.action_date,
           sp.duration_start_date,
           sp.duration_finish_date
    FROM setup_prod_pause sp
    LEFT JOIN setup_prod_pause_type spt ON sp.prod_pause_type_id = spt.prod_pause_type_id
    WHERE sp.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    ORDER BY sp.prod_pause_id DESC
</cfquery>

<!--- Duruş tipleri — modal için --->
<cfquery name="getPauseTypes" datasource="boyahane">
    SELECT prod_pause_type_id, prod_pause_type
    FROM setup_prod_pause_type
    WHERE is_active = true
    ORDER BY prod_pause_type
</cfquery>

<cfset opsArr    = []>
<cfloop query="getOps">
    <cfset arrayAppend(opsArr, {
        "p_operation_id" : val(p_operation_id),
        "operation_type" : operation_type  ?: "",
        "operation_code" : operation_code  ?: "",
        "station_name"   : station_name    ?: "",
        "stage"          : val(stage),
        "amount"         : isNumeric(amount) ? val(amount) : 0,
        "o_minute"       : val(o_minute),
        "o_start_date"   : isDate(o_start_date)  ? dateFormat(o_start_date,"dd/mm/yyyy") & " " & timeFormat(o_start_date,"HH:mm") : "",
        "o_finish_date"  : isDate(o_finish_date) ? dateFormat(o_finish_date,"dd/mm/yyyy") & " " & timeFormat(o_finish_date,"HH:mm") : ""
    })>
</cfloop>

<cfset pausesArr = []>
<cfloop query="getPauses">
    <cfset arrayAppend(pausesArr, {
        "prod_pause_id"   : val(prod_pause_id),
        "pause_type_name" : pause_type_name ?: "",
        "prod_duration"   : val(prod_duration),
        "prod_detail"     : prod_detail     ?: "",
        "is_working_time" : is_working_time,
        "action_date"     : isDate(action_date) ? dateFormat(action_date,"dd/mm/yyyy") & " " & timeFormat(action_date,"HH:mm") : ""
    })>
</cfloop>

<cfset pauseTypeOpts = []>
<cfloop query="getPauseTypes">
    <cfset arrayAppend(pauseTypeOpts, { "id": val(prod_pause_type_id), "text": prod_pause_type ?: "" })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-tasks"></i></div>
        <div class="page-header-title">
            <h1>Operasyonlar & Duruşlar</h1>
            <p><b>#htmlEditFormat(getOrder.p_order_no)#</b> — #htmlEditFormat(getOrder.color_code)# #htmlEditFormat(getOrder.color_name)# / #htmlEditFormat(getOrder.station_name)#</p>
        </div>
    </div>
    <a class="btn-back" href="index.cfm?fuseaction=production.view_production_order&p_order_id=#pOrderId#">
        <i class="fas fa-arrow-left"></i>Emre Dön
    </a>
</div>

<div class="px-3 pb-5">
<div class="row g-3">

<!--- OPERASYONLAR --->
<div class="col-lg-7">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-cogs"></i>Operasyonlar</div>
        </div>
        <div class="card-body p-2">
            <div id="opsGrid"></div>
        </div>
    </div>
</div>

<!--- DURUŞ KAYITLARI --->
<div class="col-lg-5">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-pause-circle"></i>Duruş Kayıtları</div>
            <cfif getOrder.status lt 5>
                <button class="btn btn-sm btn-outline-warning" onclick="openPauseModal()">
                    <i class="fas fa-plus"></i> Duruş Ekle
                </button>
            </cfif>
        </div>
        <div class="card-body p-2">
            <div id="pauseGrid"></div>
        </div>
    </div>
</div>

</div><!--- row --->
</div><!--- px-3 --->

<!--- DURUŞ EKLEME MODAL --->
<div id="pauseModal" class="modal fade" tabindex="-1">
    <div class="modal-dialog modal-md">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Duruş Kaydı Ekle</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-12">
                        <label class="form-label">Duruş Tipi</label>
                        <div id="fld_pause_type_dx"></div>
                    </div>
                    <div class="col-6">
                        <label class="form-label">Başlangıç</label>
                        <div id="fld_duration_start_dx"></div>
                    </div>
                    <div class="col-6">
                        <label class="form-label">Bitiş</label>
                        <div id="fld_duration_finish_dx"></div>
                    </div>
                    <div class="col-4">
                        <label class="form-label">Süre (dk) <small class="text-muted">otomatik</small></label>
                        <div id="fld_prod_duration_dx"></div>
                    </div>
                    <div class="col-8">
                        <label class="form-label">Açıklama</label>
                        <div id="fld_prod_detail_dx"></div>
                    </div>
                    <div class="col-12">
                        <div class="form-check">
                            <input class="form-check-input" type="checkbox" id="fld_is_working_time">
                            <label class="form-check-label" for="fld_is_working_time">Çalışma süresine sayılsın</label>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Vazgeç</button>
                <button type="button" class="btn btn-warning" id="btnSavePause" onclick="savePause()">
                    <i class="fas fa-save me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<script>
var opsData     = #serializeJSON(opsArr)#;
var pausesData  = #serializeJSON(pausesArr)#;
var pauseTypes  = #serializeJSON(pauseTypeOpts)#;
var pOrderId    = #val(pOrderId)#;

var stageLabels = { 0:'Bekliyor', 1:'Devam Ediyor', 2:'Tamamlandı', 9:'İptal' };
var stageColors = { 0:'secondary', 1:'primary', 2:'success', 9:'danger' };

$(function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    // Operasyon grid
    $('##opsGrid').dxDataGrid({
        dataSource: opsData,
        keyExpr: 'p_operation_id',
        showBorders: true,
        rowAlternationEnabled: true,
        columnAutoWidth: true,
        wordWrapEnabled: false,
        paging: { enabled: false },
        columns: [
            { dataField:'operation_type', caption:'Operasyon',  minWidth:130 },
            { dataField:'station_name',   caption:'Makina',     width:130 },
            { dataField:'amount',         caption:'Miktar',     width:85, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
            { dataField:'o_minute',       caption:'Süre (dk)',  width:85, alignment:'right' },
            { dataField:'o_start_date',   caption:'Başlangıç',  width:130, alignment:'center' },
            { dataField:'o_finish_date',  caption:'Bitiş',      width:130, alignment:'center' },
            {
                dataField:'stage', caption:'Durum', width:110, alignment:'center',
                cellTemplate: function(c,o) {
                    var s = o.value || 0;
                    $('<span class="badge bg-' + (stageColors[s]||'secondary') + '">' + (stageLabels[s]||s) + '</span>').appendTo(c);
                }
            }
        ]
    });

    // Duruş grid
    $('##pauseGrid').dxDataGrid({
        dataSource: pausesData,
        keyExpr: 'prod_pause_id',
        showBorders: true,
        rowAlternationEnabled: true,
        columnAutoWidth: true,
        paging: { enabled: false },
        columns: [
            { dataField:'pause_type_name', caption:'Duruş Tipi', minWidth:120 },
            { dataField:'prod_duration',   caption:'Süre (dk)',  width:80,  alignment:'right' },
            { dataField:'action_date',     caption:'Tarih',      width:130, alignment:'center' },
            { dataField:'prod_detail',     caption:'Açıklama',   minWidth:140 },
            {
                dataField:'is_working_time', caption:'Süreye Say', width:90, alignment:'center',
                cellTemplate: function(c,o) {
                    $('<span class="badge bg-' + (o.value ? 'success':'secondary') + '">' + (o.value?'Evet':'Hayır') + '</span>').appendTo(c);
                }
            }
        ]
    });

    // Modal DX widget'ları
    $('##fld_pause_type_dx').dxSelectBox({
        dataSource: pauseTypes,
        valueExpr: 'id',
        displayExpr: 'text',
        placeholder: 'Duruş tipi seçin...',
        searchEnabled: true
    });
    $('##fld_duration_start_dx').dxDateBox({
        type: 'datetime',
        displayFormat: 'dd/MM/yyyy HH:mm',
        value: new Date(),
        onValueChanged: calcDuration
    });
    $('##fld_duration_finish_dx').dxDateBox({
        type: 'datetime',
        displayFormat: 'dd/MM/yyyy HH:mm',
        onValueChanged: calcDuration
    });
    $('##fld_prod_duration_dx').dxNumberBox({ min: 0, value: 0 });
    $('##fld_prod_detail_dx').dxTextBox({ placeholder: 'Açıklama...' });
});

function calcDuration() {
    var s = $('##fld_duration_start_dx').dxDateBox('instance').option('value');
    var f = $('##fld_duration_finish_dx').dxDateBox('instance').option('value');
    if (s && f) {
        var diff = Math.round((new Date(f).getTime() - new Date(s).getTime()) / 60000);
        if (diff > 0) $('##fld_prod_duration_dx').dxNumberBox('instance').option('value', diff);
    }
}

function openPauseModal() {
    $('##fld_pause_type_dx').dxSelectBox('instance').option('value', null);
    $('##fld_duration_start_dx').dxDateBox('instance').option('value', new Date());
    $('##fld_duration_finish_dx').dxDateBox('instance').option('value', null);
    $('##fld_prod_duration_dx').dxNumberBox('instance').option('value', 0);
    $('##fld_prod_detail_dx').dxTextBox('instance').option('value', '');
    document.getElementById('fld_is_working_time').checked = false;
    new bootstrap.Modal(document.getElementById('pauseModal')).show();
}

function savePause() {
    var startInst  = $('##fld_duration_start_dx').dxDateBox('instance');
    var finishInst = $('##fld_duration_finish_dx').dxDateBox('instance');
    var startVal   = startInst.option('value');
    var finishVal  = finishInst.option('value');

    var payload = {
        p_order_id           : pOrderId,
        pause_type_id        : $('##fld_pause_type_dx').dxSelectBox('instance').option('value') || 0,
        prod_duration        : $('##fld_prod_duration_dx').dxNumberBox('instance').option('value') || 0,
        prod_detail          : ($('##fld_prod_detail_dx').dxTextBox('instance').option('value') || '').trim(),
        is_working_time      : document.getElementById('fld_is_working_time').checked ? 1 : 0,
        action_date          : startVal ? formatDateTime(startVal) : '',
        duration_start_date  : startVal  ? formatDateTime(startVal)  : '',
        duration_finish_date : finishVal ? formatDateTime(finishVal) : ''
    };

    $('##btnSavePause').prop('disabled', true);
    $.post('/production/form/save_production_pause.cfm', payload, function(res) {
        if (res && res.success) {
            bootstrap.Modal.getInstance(document.getElementById('pauseModal')).hide();
            var typeName = '';
            pauseTypes.forEach(function(t){ if (t.id == payload.pause_type_id) typeName = t.text; });
            var newRow = {
                prod_pause_id   : res.prod_pause_id,
                pause_type_name : typeName,
                prod_duration   : payload.prod_duration,
                prod_detail     : payload.prod_detail,
                is_working_time : !!payload.is_working_time,
                action_date     : formatDisplayDate(startVal || new Date())
            };
            pausesData.unshift(newRow);
            $('##pauseGrid').dxDataGrid('instance').option('dataSource', pausesData);
            DevExpress.ui.notify('Duruş kaydedildi.', 'success', 2000);
        } else {
            DevExpress.ui.notify((res && res.message) || 'Kayıt başarısız.', 'error', 3000);
        }
    }, 'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); })
              .always(function(){ $('##btnSavePause').prop('disabled', false); });
}

function formatDateTime(d) {
    var dt = new Date(d);
    return dt.getFullYear() + '-' +
           String(dt.getMonth()+1).padStart(2,'0') + '-' +
           String(dt.getDate()).padStart(2,'0') + 'T' +
           String(dt.getHours()).padStart(2,'0') + ':' +
           String(dt.getMinutes()).padStart(2,'0');
}
function formatDisplayDate(d) {
    var dt = new Date(d);
    return String(dt.getDate()).padStart(2,'0') + '/' +
           String(dt.getMonth()+1).padStart(2,'0') + '/' +
           dt.getFullYear() + ' ' +
           String(dt.getHours()).padStart(2,'0') + ':' +
           String(dt.getMinutes()).padStart(2,'0');
}
</script>
</cfoutput>
