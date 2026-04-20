<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.qc_inspection_id" default="0">
<cfparam name="url.inspection_type"  default="1">
<cfparam name="url.ship_id"          default="0">
<cfparam name="url.p_order_id"       default="0">

<cfset editMode       = isNumeric(url.qc_inspection_id) AND val(url.qc_inspection_id) gt 0>
<cfset currentId      = editMode ? val(url.qc_inspection_id) : 0>
<cfset preType        = isNumeric(url.inspection_type) AND val(url.inspection_type) gt 0 ? val(url.inspection_type) : 1>
<cfset preShipId      = isNumeric(url.ship_id)    AND val(url.ship_id)    gt 0 ? val(url.ship_id)    : 0>
<cfset prePOrderId    = isNumeric(url.p_order_id) AND val(url.p_order_id) gt 0 ? val(url.p_order_id) : 0>

<cfif editMode>
    <cfquery name="getRec" datasource="boyahane">
        SELECT qi.*, COALESCE(p.product_name,'') AS product_name,
               COALESCE(sh.ship_number,'')        AS ship_number,
               COALESCE(po.p_order_no,'')         AS p_order_no
        FROM qc_inspections qi
        LEFT JOIN product          p  ON qi.product_id = p.product_id
        LEFT JOIN ship            sh  ON qi.ship_id    = sh.ship_id
        LEFT JOIN production_orders po ON qi.p_order_id= po.p_order_id
        WHERE qi.qc_inspection_id = <cfqueryparam value="#currentId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getRec.recordCount>
        <cflocation url="index.cfm?fuseaction=quality.list_qc_inspections" addtoken="false">
    </cfif>
<cfelse>
    <cfset getRec = {
        qc_inspection_id: 0, inspection_no: "", inspection_type: preType,
        ship_id: preShipId, p_order_id: prePOrderId,
        product_id: "", product_name: "", stock_id: "",
        qc_plan_id: "", lot_no: "", quantity: 0, sample_quantity: 0,
        inspection_date: dateFormat(now(),"yyyy-mm-dd") & "T" & timeFormat(now(),"HH:mm"),
        inspector_name: "", result: 1, notes: "",
        ship_number: "", p_order_no: ""
    }>
</cfif>

<!--- KK Planları (filtrelenmiş) --->
<cfquery name="getPlans" datasource="boyahane">
    SELECT qc_plan_id, plan_code, plan_name, control_type
    FROM qc_plans WHERE is_active = true ORDER BY plan_name
</cfquery>
<cfset plansArr = []>
<cfloop query="getPlans">
    <cfset arrayAppend(plansArr, {
        "qc_plan_id"   : val(qc_plan_id),
        "plan_code"    : plan_code ?: "",
        "plan_name"    : plan_name ?: "",
        "control_type" : val(control_type),
        "display"      : plan_code & " - " & plan_name
    })>
</cfloop>

<!--- İrsaliyeler (Alış) — Giriş kontrol için --->
<cfquery name="getShips" datasource="boyahane">
    SELECT s.ship_id, s.ship_number, COALESCE(c.nickname,c.fullname,'') AS company_name, s.ship_date
    FROM ship s LEFT JOIN company c ON s.company_id = c.company_id
    WHERE s.purchase_sales = 1 AND COALESCE(s.is_ship_iptal, false) = false
    ORDER BY s.ship_id DESC LIMIT 500
</cfquery>
<cfset shipsArr = []>
<cfloop query="getShips">
    <cfset arrayAppend(shipsArr, {
        "ship_id"     : val(ship_id),
        "ship_number" : ship_number ?: "",
        "company_name": company_name ?: "",
        "ship_date"   : isDate(ship_date) ? dateFormat(ship_date,"dd/mm/yyyy") : "",
        "display"     : ship_number & " — " & company_name & (isDate(ship_date) ? " (" & dateFormat(ship_date,"dd/mm/yyyy") & ")" : "")
    })>
</cfloop>

<!--- Üretim Emirleri --->
<cfquery name="getOrders" datasource="boyahane">
    SELECT po.p_order_id, po.p_order_no, po.status, po.lot_no,
           COALESCE(ci.color_code,'') AS color_code,
           COALESCE(ci.color_name,'') AS color_name,
           COALESCE(c.nickname,c.fullname,'') AS company_name
    FROM production_orders po
    LEFT JOIN stocks       s   ON po.stock_id   = s.stock_id
    LEFT JOIN color_info   ci  ON po.stock_id   = ci.stock_id
    LEFT JOIN company      c   ON ci.company_id = c.company_id
    WHERE po.status IN (1,2,5)
    ORDER BY po.p_order_id DESC LIMIT 500
</cfquery>
<cfset ordersArr2 = []>
<cfloop query="getOrders">
    <cfset arrayAppend(ordersArr2, {
        "p_order_id"  : val(p_order_id),
        "p_order_no"  : p_order_no  ?: "",
        "status"      : val(status),
        "lot_no"      : lot_no      ?: "",
        "color_code"  : color_code  ?: "",
        "company_name": company_name ?: "",
        "display"     : p_order_no & " — " & color_code & (len(company_name) ? " / " & company_name : "")
    })>
</cfloop>

<!--- Aktif parametreler --->
<cfquery name="getAllParams" datasource="boyahane">
    SELECT qc_param_id, param_code, param_name, param_type, unit_name, min_value, max_value
    FROM qc_parameters WHERE is_active = true ORDER BY sort_order, param_name
</cfquery>
<cfset allParamsArr2 = []>
<cfloop query="getAllParams">
    <cfset arrayAppend(allParamsArr2, {
        "qc_param_id" : val(qc_param_id),
        "param_code"  : param_code  ?: "",
        "param_name"  : param_name  ?: "",
        "param_type"  : val(param_type),
        "unit_name"   : unit_name   ?: "",
        "min_value"   : isNumeric(min_value) ? val(min_value) : "",
        "max_value"   : isNumeric(max_value) ? val(max_value) : ""
    })>
</cfloop>

<!--- Hata tipleri --->
<cfquery name="getDefectTypes" datasource="boyahane">
    SELECT defect_type_id, defect_code, defect_name, severity
    FROM qc_defect_types WHERE is_active = true ORDER BY sort_order, defect_name
</cfquery>
<cfset defectTypesArr = []>
<cfloop query="getDefectTypes">
    <cfset arrayAppend(defectTypesArr, {
        "defect_type_id" : val(defect_type_id),
        "defect_code"    : defect_code  ?: "",
        "defect_name"    : defect_name  ?: "",
        "severity"       : val(severity),
        "display"        : defect_code & " - " & defect_name
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-microscope"></i></div>
        <div class="page-header-title">
            <h1>#editMode ? 'Muayene Düzenle' : 'Yeni Kalite Kontrol Muayenesi'#</h1>
        </div>
    </div>
    <a href="index.cfm?fuseaction=quality.list_qc_inspections" class="btn btn-outline-secondary">
        <i class="fas fa-arrow-left me-1"></i>Listeye Dön
    </a>
</div>

<div class="px-3">
<form id="inspForm">
    <input type="hidden" name="qc_inspection_id" value="#currentId#">
    <input type="hidden" id="resultsJson"   name="results"  value="[]">
    <input type="hidden" id="defectsJson"   name="defects"  value="[]">

    <!--- Bölüm 1: Temel Bilgiler --->
    <div class="card mb-3">
        <div class="card-header fw-bold"><i class="fas fa-info-circle me-1"></i>Temel Bilgiler</div>
        <div class="card-body">
            <div class="row g-3">
                <div class="col-md-3">
                    <label class="form-label">Kontrol Tipi <span class="text-danger">*</span></label>
                    <select class="form-select" name="inspection_type" id="inspectionType" onchange="onTypeChange()">
                        <option value="1" #val(getRec.inspection_type) eq 1 ? 'selected' : ''#>1 — Giriş Kontrol</option>
                        <option value="2" #val(getRec.inspection_type) eq 2 ? 'selected' : ''#>2 — Operasyon Kontrol</option>
                        <option value="3" #val(getRec.inspection_type) eq 3 ? 'selected' : ''#>3 — Final / Çıkış Kontrol</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label">Muayene No</label>
                    <input type="text" class="form-control" name="inspection_no"
                           value="#htmlEditFormat(getRec.inspection_no)#"
                           placeholder="Boş bırakılırsa otomatik">
                </div>
                <div class="col-md-3">
                    <label class="form-label">Kontrol Tarihi</label>
                    <input type="datetime-local" class="form-control" name="inspection_date"
                           value="#getRec.inspection_date#">
                </div>
                <div class="col-md-3">
                    <label class="form-label">Kontrolör Adı</label>
                    <input type="text" class="form-control" name="inspector_name"
                           value="#htmlEditFormat(getRec.inspector_name)#" maxlength="200">
                </div>
            </div>
        </div>
    </div>

    <!--- Bölüm 2: Referans Bağlantısı --->
    <div class="card mb-3" id="refSection">
        <div class="card-header fw-bold"><i class="fas fa-link me-1"></i>Referans Bağlantısı</div>
        <div class="card-body">
            <div class="row g-3">
                <!--- Giriş Kontrol → İrsaliye --->
                <div class="col-md-6" id="shipRefDiv">
                    <label class="form-label">İrsaliye (Alış) — Giriş Kontrol için</label>
                    <div id="shipSelectBox"></div>
                    <input type="hidden" id="ship_id" name="ship_id" value="#val(getRec.ship_id)#">
                </div>
                <!--- Operasyon / Final → Üretim Emri --->
                <div class="col-md-6" id="orderRefDiv">
                    <label class="form-label">Üretim Emri — Operasyon/Final Kontrol için</label>
                    <div id="orderSelectBox"></div>
                    <input type="hidden" id="p_order_id" name="p_order_id" value="#val(getRec.p_order_id)#">
                </div>
            </div>
        </div>
    </div>

    <!--- Bölüm 3: Ürün & Miktar --->
    <div class="card mb-3">
        <div class="card-header fw-bold"><i class="fas fa-box me-1"></i>Ürün & Miktar</div>
        <div class="card-body">
            <div class="row g-3">
                <div class="col-md-3">
                    <label class="form-label">Lot No</label>
                    <input type="text" class="form-control" name="lot_no"
                           value="#htmlEditFormat(getRec.lot_no)#" maxlength="100">
                </div>
                <div class="col-md-2">
                    <label class="form-label">Kontrol Miktarı</label>
                    <input type="number" step="any" class="form-control" name="quantity"
                           value="#isNumeric(getRec.quantity) ? getRec.quantity : 0#" min="0">
                </div>
                <div class="col-md-2">
                    <label class="form-label">Numune Miktarı</label>
                    <input type="number" step="any" class="form-control" name="sample_quantity"
                           value="#isNumeric(getRec.sample_quantity) ? getRec.sample_quantity : 0#" min="0">
                </div>
                <div class="col-md-3">
                    <label class="form-label">KK Planı</label>
                    <div id="planSelectBox"></div>
                    <input type="hidden" id="qc_plan_id" name="qc_plan_id" value="#isNumeric(getRec.qc_plan_id) ? val(getRec.qc_plan_id) : ''#">
                </div>
                <div class="col-md-2">
                    <label class="form-label">Genel Sonuç</label>
                    <select class="form-select" name="result" id="overallResult">
                        <option value="1" #val(getRec.result) eq 1 ? 'selected' : ''#>✅ Kabul</option>
                        <option value="2" #val(getRec.result) eq 2 ? 'selected' : ''#>⚠️ Koşullu Kabul</option>
                        <option value="3" #val(getRec.result) eq 3 ? 'selected' : ''#>❌ Ret</option>
                    </select>
                </div>
                <div class="col-12">
                    <label class="form-label">Notlar</label>
                    <textarea class="form-control" name="notes" rows="2">#htmlEditFormat(getRec.notes ?: '')#</textarea>
                </div>
            </div>
        </div>
    </div>

    <!--- Bölüm 4: Ölçüm Sonuçları --->
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center fw-bold">
            <span><i class="fas fa-ruler me-1"></i>Ölçüm Sonuçları</span>
            <button type="button" class="btn btn-sm btn-success" onclick="addMeasRow()">
                <i class="fas fa-plus me-1"></i>Satır Ekle
            </button>
        </div>
        <div class="card-body p-0">
            <table class="table table-sm mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Parametre</th>
                        <th style="width:130px">Ölçülen Değer</th>
                        <th style="width:200px">Metin Sonuç</th>
                        <th style="width:110px">Durum</th>
                        <th style="width:200px">Not</th>
                        <th style="width:50px"></th>
                    </tr>
                </thead>
                <tbody id="measBody"></tbody>
            </table>
        </div>
    </div>

    <!--- Bölüm 5: Tespit Edilen Hatalar --->
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center fw-bold">
            <span><i class="fas fa-bug me-1"></i>Tespit Edilen Hatalar</span>
            <button type="button" class="btn btn-sm btn-warning" onclick="addDefectRow()">
                <i class="fas fa-plus me-1"></i>Hata Ekle
            </button>
        </div>
        <div class="card-body p-0">
            <table class="table table-sm mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Hata Tipi</th>
                        <th style="width:100px">Adet</th>
                        <th style="width:200px">Konum</th>
                        <th style="width:250px">Not</th>
                        <th style="width:50px"></th>
                    </tr>
                </thead>
                <tbody id="defectBody"></tbody>
            </table>
        </div>
    </div>

    <div class="d-flex gap-2 mb-4">
        <button type="submit" class="btn btn-primary btn-lg">
            <i class="fas fa-save me-1"></i>#editMode ? 'Güncelle' : 'Kaydet'#
        </button>
        <a href="index.cfm?fuseaction=quality.list_qc_inspections" class="btn btn-secondary btn-lg">İptal</a>
    </div>
</form>
</div>

<script>
var allParams2    = #serializeJSON(allParamsArr2)#;
var defectTypes   = #serializeJSON(defectTypesArr)#;
var allPlans      = #serializeJSON(plansArr)#;
var allShips      = #serializeJSON(shipsArr)#;
var allOrders2    = #serializeJSON(ordersArr2)#;
var currentShipId  = #val(getRec.ship_id)#;
var currentOrderId = #val(getRec.p_order_id)#;
var currentPlanId  = #isNumeric(getRec.qc_plan_id) ? val(getRec.qc_plan_id) : 0#;

$(function(){
    // İrsaliye SelectBox
    new DevExpress.ui.dxSelectBox(document.getElementById('shipSelectBox'), {
        dataSource: allShips,
        displayExpr: 'display',
        valueExpr: 'ship_id',
        searchEnabled: true,
        showClearButton: true,
        placeholder: 'İrsaliye seçin...',
        value: currentShipId > 0 ? currentShipId : null,
        onValueChanged: function(e){ document.getElementById('ship_id').value = e.value || 0; }
    });

    // Üretim Emri SelectBox
    new DevExpress.ui.dxSelectBox(document.getElementById('orderSelectBox'), {
        dataSource: allOrders2,
        displayExpr: 'display',
        valueExpr: 'p_order_id',
        searchEnabled: true,
        showClearButton: true,
        placeholder: 'Üretim emri seçin...',
        value: currentOrderId > 0 ? currentOrderId : null,
        onValueChanged: function(e){ document.getElementById('p_order_id').value = e.value || 0; }
    });

    // Plan SelectBox
    new DevExpress.ui.dxSelectBox(document.getElementById('planSelectBox'), {
        dataSource: allPlans,
        displayExpr: 'display',
        valueExpr: 'qc_plan_id',
        searchEnabled: true,
        showClearButton: true,
        placeholder: 'Plan seçin (isteğe bağlı)...',
        value: currentPlanId > 0 ? currentPlanId : null,
        onValueChanged: function(e){
            document.getElementById('qc_plan_id').value = e.value || '';
            if (e.value) loadPlanParams(e.value);
        }
    });

    onTypeChange();
});

function onTypeChange() {
    var t = parseInt(document.getElementById('inspectionType').value);
    document.getElementById('shipRefDiv').style.display  = t === 1 ? '' : 'none';
    document.getElementById('orderRefDiv').style.display = (t === 2 || t === 3) ? '' : 'none';
}

function loadPlanParams(planId) {
    $.getJSON('index.cfm?fuseaction=quality.get_plan_params&qc_plan_id=' + planId, function(data){
        if (!data || !data.params) return;
        // Tabloya ekle (mevcut satırları temizlemeden üstüne ekle istemiyoruz)
        if (!confirm('Plan parametrelerini tabloya otomatik ekleyelim mi? (Mevcut satırlar silinecek)')) return;
        document.getElementById('measBody').innerHTML = '';
        data.params.forEach(function(p){ addMeasRowWithParam(p); });
    });
}

function addMeasRow() {
    var paramName = prompt(
        'Parametre seçin (numara girin):\n' +
        allParams2.map(function(p,i){ return (i+1)+'. '+p.param_code+' - '+p.param_name; }).join('\n')
    );
    if (!paramName) return;
    var idx = parseInt(paramName) - 1;
    if (isNaN(idx) || idx < 0 || idx >= allParams2.length) { alert('Geçersiz seçim'); return; }
    addMeasRowWithParam(allParams2[idx]);
}

function addMeasRowWithParam(p) {
    var isNumType = p.param_type === 1;
    var tr = document.createElement('tr');
    tr.innerHTML =
        '<td><span class="fw-semibold">' + (p.param_code||'') + '</span> — ' + (p.param_name||'') +
        (p.unit_name ? ' <small class="text-muted">('+p.unit_name+')</small>' : '') +
        '<br><small class="text-muted">Hedef: ' +
        (p.min_value !== '' && p.min_value !== null ? 'Min:'+p.min_value : '') +
        (p.max_value !== '' && p.max_value !== null ? ' Max:'+p.max_value : '') +
        '</small>' +
        '<input type="hidden" class="mr-param-id" value="'+p.qc_param_id+'"></td>' +
        '<td><input type="number" step="any" class="form-control form-control-sm mr-measured" ' +
        (isNumType ? '' : 'disabled') + ' placeholder="' + (isNumType ? '0.00' : '—') + '"></td>' +
        '<td><input type="text" class="form-control form-control-sm mr-text" ' +
        (!isNumType ? '' : 'disabled') + ' placeholder="' + (!isNumType ? 'Sonuç...' : '—') + '" maxlength="500"></td>' +
        '<td><select class="form-select form-select-sm mr-pass">' +
            '<option value="true">✅ Geçti</option>' +
            '<option value="false">❌ Kaldı</option>' +
        '</select></td>' +
        '<td><input type="text" class="form-control form-control-sm mr-notes" maxlength="500" placeholder="Not..."></td>' +
        '<td><button type="button" class="btn btn-sm btn-outline-danger" onclick="this.closest(\'tr\').remove()"><i class="fas fa-times"></i></button></td>';
    document.getElementById('measBody').appendChild(tr);
}

function addDefectRow() {
    var pick = prompt(
        'Hata tipi seçin (numara):\n' +
        defectTypes.map(function(d,i){ return (i+1)+'. '+d.defect_code+' - '+d.defect_name; }).join('\n')
    );
    if (!pick) return;
    var idx = parseInt(pick) - 1;
    if (isNaN(idx) || idx < 0 || idx >= defectTypes.length) { alert('Geçersiz seçim'); return; }
    var d = defectTypes[idx];
    var tr = document.createElement('tr');
    tr.innerHTML =
        '<td><span class="fw-semibold">' + d.defect_code + '</span> — ' + d.defect_name +
        '<input type="hidden" class="dr-defect-id" value="'+d.defect_type_id+'"></td>' +
        '<td><input type="number" class="form-control form-control-sm dr-count" value="1" min="1"></td>' +
        '<td><input type="text" class="form-control form-control-sm dr-location" maxlength="200" placeholder="Konum..."></td>' +
        '<td><input type="text" class="form-control form-control-sm dr-notes" maxlength="500" placeholder="Not..."></td>' +
        '<td><button type="button" class="btn btn-sm btn-outline-danger" onclick="this.closest(\'tr\').remove()"><i class="fas fa-times"></i></button></td>';
    document.getElementById('defectBody').appendChild(tr);
}

function collectResults() {
    return Array.from(document.querySelectorAll('#measBody tr')).map(function(tr){
        return {
            qc_param_id    : parseInt(tr.querySelector('.mr-param-id').value),
            measured_value : tr.querySelector('.mr-measured').value,
            text_result    : tr.querySelector('.mr-text').value,
            is_pass        : tr.querySelector('.mr-pass').value,
            notes          : tr.querySelector('.mr-notes').value
        };
    });
}

function collectDefects() {
    return Array.from(document.querySelectorAll('#defectBody tr')).map(function(tr){
        return {
            defect_type_id  : parseInt(tr.querySelector('.dr-defect-id').value),
            defect_count    : parseInt(tr.querySelector('.dr-count').value) || 1,
            defect_location : tr.querySelector('.dr-location').value,
            notes           : tr.querySelector('.dr-notes').value
        };
    });
}

document.getElementById('inspForm').addEventListener('submit', function(e){
    e.preventDefault();
    document.getElementById('resultsJson').value = JSON.stringify(collectResults());
    document.getElementById('defectsJson').value = JSON.stringify(collectDefects());

    var fd = new FormData(this), data = {};
    fd.forEach(function(v,k){ data[k] = v; });

    $.post('index.cfm?fuseaction=quality.save_qc_inspection', data, function(res){
        var r = typeof res === 'string' ? JSON.parse(res) : res;
        if (r.success) {
            var act = data.qc_inspection_id > 0 ? 'updated' : 'added';
            window.location.href = 'index.cfm?fuseaction=quality.list_qc_inspections&success=' + act;
        } else {
            alert('Hata: ' + (r.message || 'Kaydedilemedi'));
        }
    });
});
</script>
</cfoutput>
