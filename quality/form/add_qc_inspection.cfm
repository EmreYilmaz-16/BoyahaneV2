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

<!--- KK Planları --->
<cfquery name="getPlans" datasource="boyahane">
    SELECT qc_plan_id, plan_code, plan_name, control_type,
           COALESCE(product_id, 0)   AS product_id,
           COALESCE(product_catid,0) AS product_catid
    FROM qc_plans WHERE is_active = true ORDER BY plan_name
</cfquery>
<cfset plansArr = []>
<cfloop query="getPlans">
    <cfset arrayAppend(plansArr, {
        "qc_plan_id"   : val(qc_plan_id),
        "plan_code"    : plan_code ?: "",
        "plan_name"    : plan_name ?: "",
        "control_type" : val(control_type),
        "product_id"   : val(product_id),
        "product_catid": val(product_catid),
        "display"      : plan_code & " - " & plan_name
    })>
</cfloop>

<!--- İrsaliyeler (Alış) — Giriş kontrol için --->
<cfquery name="getShips" datasource="boyahane">
    SELECT s.ship_id, s.ship_number, COALESCE(c.nickname,c.fullname,'') AS company_name, s.ship_date
    FROM ship s LEFT JOIN company c ON s.company_id = c.company_id
    WHERE s.purchase_sales = true AND COALESCE(s.is_ship_iptal, false) = false
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
    SELECT po.p_order_id, po.p_order_no, po.status, po.lot_no, po.quantity,
           COALESCE(ci.color_code,'') AS color_code,
           COALESCE(ci.color_name,'') AS color_name,
           COALESCE(c.nickname,c.fullname,'') AS company_name,
           COALESCE(s.product_id, 0)         AS product_id,
           COALESCE(p.product_name,'')        AS product_name,
           COALESCE(p.product_catid, 0)       AS product_catid
    FROM production_orders po
    LEFT JOIN stocks       s   ON po.stock_id   = s.stock_id
    LEFT JOIN product      p   ON s.product_id  = p.product_id
    LEFT JOIN color_info   ci  ON po.stock_id   = ci.stock_id
    LEFT JOIN company      c   ON ci.company_id = c.company_id
    WHERE po.status IN (1,2,5)
    ORDER BY po.p_order_id DESC LIMIT 500
</cfquery>
<cfset ordersArr2 = []>
<cfloop query="getOrders">
    <cfset arrayAppend(ordersArr2, {
        "p_order_id"   : val(p_order_id),
        "p_order_no"   : p_order_no   ?: "",
        "status"       : val(status),
        "lot_no"       : lot_no       ?: "",
        "color_code"   : color_code   ?: "",
        "color_name"   : color_name   ?: "",
        "company_name" : company_name  ?: "",
        "product_id"   : val(product_id),
        "product_name" : product_name  ?: "",
        "product_catid": val(product_catid),
        "quantity"     : isNumeric(quantity) ? val(quantity) : 0,
        "display"      : p_order_no & " — " & color_code & (len(company_name) ? " / " & company_name : "")
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
                <div class="col-md-4" id="shipRefDiv">
                    <label class="form-label">İrsaliye (Alış)</label>
                    <div id="shipSelectBox"></div>
                    <input type="hidden" id="ship_id" name="ship_id" value="#val(getRec.ship_id)#">
                </div>
                <!--- Giriş Kontrol → İrsaliye Ürünü --->
                <div class="col-md-4" id="shipProductDiv" style="display:none">
                    <label class="form-label">İrsaliyedeki Ürün <span class="text-danger">*</span></label>
                    <div id="shipProductSelectBox"></div>
                    <input type="hidden" id="insp_product_id" name="product_id" value="#isNumeric(getRec.product_id) ? val(getRec.product_id) : ''#">
                    <input type="hidden" id="insp_product_catid" value="">
                </div>
                <!--- Operasyon / Final → Üretim Emri --->
                <div class="col-md-4" id="orderRefDiv">
                    <label class="form-label">Üretim Emri — Operasyon/Final için</label>
                    <div id="orderSelectBox"></div>
                    <input type="hidden" id="p_order_id" name="p_order_id" value="#val(getRec.p_order_id)#">
                </div>
                <!--- Üretim Emri bilgi kartı --->
                <div class="col-12" id="orderInfoCard" style="display:none">
                    <div class="alert alert-info py-2 mb-0 d-flex align-items-center gap-2">
                        <i class="fas fa-info-circle"></i>
                        <div id="orderInfoText"></div>
                    </div>
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
            <button type="button" class="btn btn-sm btn-success" onclick="openParamPickerModal()">
                <i class="fas fa-plus me-1"></i>Parametre Ekle
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
            <button type="button" class="btn btn-sm btn-warning" onclick="openDefectPickerModal()">
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

<!--- Parametre Seçim Modalı --->
<div class="modal fade" id="paramPickerModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fas fa-ruler me-2"></i>Ölçüm Parametresi Seç</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-0">
                <div class="p-3 border-bottom">
                    <input type="text" id="paramSearchInput" class="form-control"
                           placeholder="Ara: kod, ad veya birim..." oninput="filterParamList()">
                </div>
                <div style="max-height:420px;overflow-y:auto">
                    <table class="table table-hover table-sm mb-0" id="paramPickerTable">
                        <thead class="table-light sticky-top">
                            <tr>
                                <th>Kod</th>
                                <th>Parametre Adı</th>
                                <th>Tip</th>
                                <th>Birim</th>
                                <th>Min / Max</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody id="paramPickerBody"></tbody>
                    </table>
                </div>
            </div>
            <div class="modal-footer">
                <small class="text-muted me-auto" id="paramPickerCount"></small>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Kapat</button>
            </div>
        </div>
    </div>
</div>

<!--- Hata Tipi Seçim Modalı --->
<div class="modal fade" id="defectPickerModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fas fa-bug me-2"></i>Hata Tipi Seç</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-0">
                <div class="p-3 border-bottom">
                    <input type="text" id="defectSearchInput" class="form-control"
                           placeholder="Ara: kod veya ad..." oninput="filterDefectList()">
                </div>
                <div style="max-height:420px;overflow-y:auto">
                    <table class="table table-hover table-sm mb-0">
                        <thead class="table-light sticky-top">
                            <tr>
                                <th>Kod</th>
                                <th>Hata Adı</th>
                                <th>Önem</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody id="defectPickerBody"></tbody>
                    </table>
                </div>
            </div>
            <div class="modal-footer">
                <small class="text-muted me-auto" id="defectPickerCount"></small>
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Kapat</button>
            </div>
        </div>
    </div>
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

var shipProductSB  = null; // irsaliye ürünleri selectbox instance
var planSB         = null; // plan selectbox instance

$(function(){
    // Modal'ları body'e taşı — content-wrapper stacking context'inden kaç
    var pm = document.getElementById('paramPickerModal');
    if (pm) document.body.appendChild(pm);
    var dm = document.getElementById('defectPickerModal');
    if (dm) document.body.appendChild(dm);

    // İrsaliye SelectBox
    new DevExpress.ui.dxSelectBox(document.getElementById('shipSelectBox'), {
        dataSource: allShips,
        displayExpr: 'display',
        valueExpr: 'ship_id',
        searchEnabled: true,
        showClearButton: true,
        placeholder: 'İrsaliye seçin...',
        value: currentShipId > 0 ? currentShipId : null,
        onValueChanged: function(e){
            document.getElementById('ship_id').value = e.value || 0;
            if (e.value) {
                loadShipProducts(e.value);
            } else {
                document.getElementById('shipProductDiv').style.display = 'none';
                document.getElementById('insp_product_id').value = '';
                document.getElementById('insp_product_catid').value = '';
                resetPlanFilter();
            }
        }
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
        onValueChanged: function(e){
            document.getElementById('p_order_id').value = e.value || 0;
            if (e.value) {
                showOrderInfo(e.value);
            } else {
                document.getElementById('orderInfoCard').style.display = 'none';
                document.getElementById('insp_product_id').value = '';
                document.getElementById('insp_product_catid').value = '';
                resetPlanFilter();
            }
        }
    });

    // Plan SelectBox
    planSB = new DevExpress.ui.dxSelectBox(document.getElementById('planSelectBox'), {
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
    renderParamPickerBody(allParams2);
    renderDefectPickerBody(defectTypes);
});

/* =================== Kontrol Tipi =================== */
function onTypeChange() {
    var t = parseInt(document.getElementById('inspectionType').value);
    document.getElementById('shipRefDiv').style.display      = t === 1 ? '' : 'none';
    document.getElementById('shipProductDiv').style.display  = 'none';
    document.getElementById('orderRefDiv').style.display     = (t === 2 || t === 3) ? '' : 'none';
    document.getElementById('orderInfoCard').style.display   = 'none';
    resetPlanFilter();
}

/* =================== İrsaliye Ürünleri =================== */
function loadShipProducts(shipId) {
    $.getJSON('index.cfm?fuseaction=quality.get_ship_products&ship_id=' + shipId, function(data){
        if (!data || !data.success) return;
        document.getElementById('shipProductDiv').style.display = '';
        // Önceki instance'ı temizle
        if (shipProductSB) {
            try { shipProductSB.dispose(); } catch(ex) {}
            document.getElementById('shipProductSelectBox').innerHTML = '';
        }
        shipProductSB = new DevExpress.ui.dxSelectBox(document.getElementById('shipProductSelectBox'), {
            dataSource: data.products,
            displayExpr: 'display',
            valueExpr: 'product_id',
            searchEnabled: true,
            showClearButton: true,
            placeholder: 'Ürün seçin...',
            onValueChanged: function(e){
                var pid = e.value || 0;
                document.getElementById('insp_product_id').value = pid;
                if (pid) {
                    var found = data.products.find(function(p){ return p.product_id == pid; });
                    var catId = found ? (found.product_catid || 0) : 0;
                    document.getElementById('insp_product_catid').value = catId;
                    // Lot No otomatik doldur
                    if (found && found.lot_no) {
                        var lotInput = document.querySelector('[name="lot_no"]');
                        if (lotInput && !lotInput.value) lotInput.value = found.lot_no;
                    }
                    filterPlansByProduct(pid, catId);
                } else {
                    document.getElementById('insp_product_catid').value = '';
                    resetPlanFilter();
                }
            }
        });
    });
}

/* =================== Üretim Emri Bilgi Kartı =================== */
function showOrderInfo(orderId) {
    var ord = allOrders2.find(function(o){ return o.p_order_id == orderId; });
    if (!ord) return;

    var html = '<b>' + ord.p_order_no + '</b>';
    if (ord.product_name) html += ' &nbsp;|&nbsp; <i class="fas fa-box fa-xs"></i> ' + ord.product_name;
    if (ord.color_code)   html += ' &nbsp;|&nbsp; ' + ord.color_code + (ord.color_name ? ' ' + ord.color_name : '');
    if (ord.company_name) html += ' &nbsp;|&nbsp; <i class="fas fa-building fa-xs"></i> ' + ord.company_name;
    if (ord.lot_no)       html += ' &nbsp;|&nbsp; Lot: <b>' + ord.lot_no + '</b>';
    if (ord.quantity)     html += ' &nbsp;|&nbsp; Miktar: ' + ord.quantity;

    document.getElementById('orderInfoText').innerHTML = html;
    document.getElementById('orderInfoCard').style.display = '';

    // Lot No otomatik doldur
    if (ord.lot_no) {
        var lotInput = document.querySelector('[name="lot_no"]');
        if (lotInput && !lotInput.value) lotInput.value = ord.lot_no;
    }

    // product_id ve plan filtrele
    document.getElementById('insp_product_id').value    = ord.product_id || '';
    document.getElementById('insp_product_catid').value = ord.product_catid || 0;
    if (ord.product_id) filterPlansByProduct(ord.product_id, ord.product_catid || 0);
    else resetPlanFilter();
}

/* =================== Plan Filtreleme =================== */
function filterPlansByProduct(productId, productCatId) {
    var inspType = parseInt(document.getElementById('inspectionType').value);
    var filtered = allPlans.filter(function(p){
        // Kontrol tipi eşleşmesi (0 = tüm tipler)
        var typeMatch = !p.control_type || p.control_type === inspType;
        // Ürün / Kategori eşleşmesi: plan ürün kısıtı yoksa herkese açık
        var noRestrict = (!p.product_id && !p.product_catid);
        var prodMatch  = (p.product_id  && p.product_id  == productId);
        var catMatch   = (p.product_catid && productCatId && p.product_catid == productCatId);
        return typeMatch && (noRestrict || prodMatch || catMatch);
    });
    if (planSB) planSB.option('dataSource', filtered);
}

function resetPlanFilter() {
    if (planSB) planSB.option('dataSource', allPlans);
}

/* =================== Plan Parametreleri Yükle =================== */
function loadPlanParams(planId) {
    $.getJSON('index.cfm?fuseaction=quality.get_plan_params&qc_plan_id=' + planId, function(data){
        if (!data || !data.success || !data.params || data.params.length === 0) return;
        var existingRows = document.querySelectorAll('##measBody tr').length;
        if (existingRows > 0) {
            if (!confirm('Plan parametrelerini yüklemek için mevcut ' + existingRows + ' satır silinecek. Devam edilsin mi?')) return;
        }
        document.getElementById('measBody').innerHTML = '';
        data.params.forEach(function(p){ addMeasRowWithParam(p); });
    });
}

/* =================== Parametre Picker Modal =================== */
function renderParamPickerBody(list) {
    var severityMap = {1:'Sayısal',2:'Metin',3:'Geçti/Kaldı'};
    var html = '';
    list.forEach(function(p){
        html += '<tr>' +
            '<td><span class="badge bg-secondary">' + (p.param_code||'') + '</span></td>' +
            '<td>' + (p.param_name||'') + '</td>' +
            '<td><small>' + (severityMap[p.param_type]||'') + '</small></td>' +
            '<td>' + (p.unit_name||'') + '</td>' +
            '<td><small>' +
                (p.min_value !== '' && p.min_value !== null ? 'Min:' + p.min_value : '') +
                (p.max_value !== '' && p.max_value !== null ? ' Max:' + p.max_value : '') +
            '</small></td>' +
            '<td><button type="button" class="btn btn-xs btn-primary btn-sm py-0 px-2" ' +
                'onclick="pickParam(' + p.qc_param_id + ')"><i class="fas fa-plus"></i></button></td>' +
            '</tr>';
    });
    document.getElementById('paramPickerBody').innerHTML = html;
    document.getElementById('paramPickerCount').textContent = list.length + ' parametre';
}

function filterParamList() {
    var q = document.getElementById('paramSearchInput').value.toLowerCase();
    var filtered = allParams2.filter(function(p){
        return !q || (p.param_code||'').toLowerCase().includes(q) ||
                     (p.param_name||'').toLowerCase().includes(q) ||
                     (p.unit_name||'').toLowerCase().includes(q);
    });
    renderParamPickerBody(filtered);
}

function openParamPickerModal() {
    document.getElementById('paramSearchInput').value = '';
    renderParamPickerBody(allParams2);
    new bootstrap.Modal(document.getElementById('paramPickerModal')).show();
}

function pickParam(paramId) {
    var p = allParams2.find(function(x){ return x.qc_param_id == paramId; });
    if (!p) return;
    addMeasRowWithParam(p);
    bootstrap.Modal.getInstance(document.getElementById('paramPickerModal')).hide();
}

/* =================== Hata Picker Modal =================== */
var severityLabels = {1:'<span class="badge bg-info text-dark">Düşük</span>',
                      2:'<span class="badge bg-warning text-dark">Orta</span>',
                      3:'<span class="badge bg-danger">Yüksek</span>'};

function renderDefectPickerBody(list) {
    var html = '';
    list.forEach(function(d){
        html += '<tr>' +
            '<td><span class="badge bg-secondary">' + (d.defect_code||'') + '</span></td>' +
            '<td>' + (d.defect_name||'') + '</td>' +
            '<td>' + (severityLabels[d.severity]||'') + '</td>' +
            '<td><button type="button" class="btn btn-xs btn-warning btn-sm py-0 px-2" ' +
                'onclick="pickDefect(' + d.defect_type_id + ')"><i class="fas fa-plus"></i></button></td>' +
            '</tr>';
    });
    document.getElementById('defectPickerBody').innerHTML = html;
    document.getElementById('defectPickerCount').textContent = list.length + ' hata tipi';
}

function filterDefectList() {
    var q = document.getElementById('defectSearchInput').value.toLowerCase();
    var filtered = defectTypes.filter(function(d){
        return !q || (d.defect_code||'').toLowerCase().includes(q) ||
                     (d.defect_name||'').toLowerCase().includes(q);
    });
    renderDefectPickerBody(filtered);
}

function openDefectPickerModal() {
    document.getElementById('defectSearchInput').value = '';
    renderDefectPickerBody(defectTypes);
    new bootstrap.Modal(document.getElementById('defectPickerModal')).show();
}

function pickDefect(defectTypeId) {
    var d = defectTypes.find(function(x){ return x.defect_type_id == defectTypeId; });
    if (!d) return;
    var tr = document.createElement('tr');
    tr.innerHTML =
        '<td><span class="fw-semibold">' + d.defect_code + '</span> \u2014 ' + d.defect_name +
        '<input type="hidden" class="dr-defect-id" value="'+d.defect_type_id+'"></td>' +
        '<td><input type="number" class="form-control form-control-sm dr-count" value="1" min="1"></td>' +
        '<td><input type="text" class="form-control form-control-sm dr-location" maxlength="200" placeholder="Konum..."></td>' +
        '<td><input type="text" class="form-control form-control-sm dr-notes" maxlength="500" placeholder="Not..."></td>' +
        '<td><button type="button" class="btn btn-sm btn-outline-danger" onclick="this.closest(\'tr\').remove()"><i class="fas fa-times"></i></button></td>';
    document.getElementById('defectBody').appendChild(tr);
    bootstrap.Modal.getInstance(document.getElementById('defectPickerModal')).hide();
}

/* =================== Ölçüm Satırı =================== */
function addMeasRow() { openParamPickerModal(); }

function addMeasRowWithParam(p) {
    var isNumType  = p.param_type === 1;
    var isRequired = (p.is_required === true || p.is_required === 'true');
    var tr = document.createElement('tr');
    tr.innerHTML =
        '<td><span class="fw-semibold">' + (p.param_code||'') + '</span> \u2014 ' + (p.param_name||'') +
        (p.unit_name ? ' <small class="text-muted">('+p.unit_name+')</small>' : '') +
        (isRequired ? ' <span class="text-danger fw-bold" title="Zorunlu alan">*</span>' : '') +
        '<br><small class="text-muted">' +
        (p.min_value !== '' && p.min_value !== null ? 'Min:'+p.min_value : '') +
        (p.max_value !== '' && p.max_value !== null ? ' Max:'+p.max_value : '') +
        '</small>' +
        '<input type="hidden" class="mr-param-id"    value="'+p.qc_param_id+'">' +
        '<input type="hidden" class="mr-is-required" value="'+(isRequired?'true':'false')+'"></td>' +
        '<td><input type="number" step="any" class="form-control form-control-sm mr-measured" ' +
        (isNumType ? '' : 'disabled') + ' placeholder="' + (isNumType ? '0.00' : '\u2014') + '"></td>' +
        '<td><input type="text" class="form-control form-control-sm mr-text" ' +
        (!isNumType ? '' : 'disabled') + ' placeholder="' + (!isNumType ? 'Sonu\u00e7...' : '\u2014') + '" maxlength="500"></td>' +
        '<td><select class="form-select form-select-sm mr-pass">' +
            '<option value="true">\u2705 Ge\u00e7ti</option>' +
            '<option value="false">\u274c Kald\u0131</option>' +
        '</select></td>' +
        '<td><input type="text" class="form-control form-control-sm mr-notes" maxlength="500" placeholder="Not..."></td>' +
        '<td><button type="button" class="btn btn-sm btn-outline-danger" onclick="this.closest(\'tr\').remove()"><i class="fas fa-times"></i></button></td>';
    document.getElementById('measBody').appendChild(tr);
}

/* =================== Hata Satırı (eski prompt — artık modal) =================== */
function addDefectRow() { openDefectPickerModal(); }

/* =================== Collect =================== */
function collectResults() {
    return Array.from(document.querySelectorAll('##measBody tr')).map(function(tr){
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
    return Array.from(document.querySelectorAll('##defectBody tr')).map(function(tr){
        return {
            defect_type_id  : parseInt(tr.querySelector('.dr-defect-id').value),
            defect_count    : parseInt(tr.querySelector('.dr-count').value) || 1,
            defect_location : tr.querySelector('.dr-location').value,
            notes           : tr.querySelector('.dr-notes').value
        };
    });
}

/* =================== Form Submit =================== */
document.getElementById('inspForm').addEventListener('submit', function(e){
    e.preventDefault();

    // Zorunlu parametre validation
    var missingParams = [];
    document.querySelectorAll('##measBody tr').forEach(function(tr){
        var isRequired = tr.querySelector('.mr-is-required') && tr.querySelector('.mr-is-required').value === 'true';
        if (!isRequired) return;
        var isNumType = !tr.querySelector('.mr-measured').disabled;
        var valNum  = tr.querySelector('.mr-measured').value.trim();
        var valText = tr.querySelector('.mr-text').value.trim();
        var filled  = isNumType ? valNum !== '' : valText !== '';
        if (!filled) {
            var paramName = tr.querySelector('td:first-child').textContent.trim().split('\n')[0].trim();
            missingParams.push(paramName);
            var inp = isNumType ? tr.querySelector('.mr-measured') : tr.querySelector('.mr-text');
            inp.classList.add('is-invalid');
        } else {
            var inp = isNumType ? tr.querySelector('.mr-measured') : tr.querySelector('.mr-text');
            inp.classList.remove('is-invalid');
        }
    });
    if (missingParams.length > 0) {
        alert('Aşağıdaki zorunlu parametreler doldurulmamış:\n\n\u2022 ' + missingParams.join('\n\u2022 '));
        return;
    }

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
