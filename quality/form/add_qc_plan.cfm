<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.qc_plan_id" default="0">
<cfset editMode  = isNumeric(url.qc_plan_id) AND val(url.qc_plan_id) gt 0>
<cfset currentId = editMode ? val(url.qc_plan_id) : 0>

<cfif editMode>
    <cfquery name="getRec" datasource="boyahane">
        SELECT qp.*, COALESCE(p.product_name,'') AS product_name,
               COALESCE(pc.product_cat,'') AS product_cat_name
        FROM qc_plans qp
        LEFT JOIN product p ON qp.product_id = p.product_id
        LEFT JOIN product_cat pc ON qp.product_catid = pc.product_catid
        WHERE qp.qc_plan_id = <cfqueryparam value="#currentId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getRec.recordCount>
        <cflocation url="index.cfm?fuseaction=quality.list_qc_plans" addtoken="false">
    </cfif>
    <!--- Mevcut kalemler --->
    <cfquery name="getPlanItems" datasource="boyahane">
        SELECT qi.qc_plan_item_id, qi.qc_param_id, qi.is_required,
               COALESCE(qi.min_override::text,'') AS min_override,
               COALESCE(qi.max_override::text,'') AS max_override,
               qi.sort_order,
               qp.param_name, qp.param_code, qp.unit_name, qp.min_value, qp.max_value
        FROM qc_plan_items qi
        JOIN qc_parameters qp ON qi.qc_param_id = qp.qc_param_id
        WHERE qi.qc_plan_id = <cfqueryparam value="#currentId#" cfsqltype="cf_sql_integer">
        ORDER BY qi.sort_order, qp.param_name
    </cfquery>
<cfelse>
    <cfset getRec = { qc_plan_id:0, plan_code:"", plan_name:"", control_type:1,
                      product_id:"", product_name:"", product_catid:"", product_cat_name:"",
                      sample_method:1, sample_value:"", is_active:true, detail:"" }>
</cfif>

<cfquery name="getProducts" datasource="boyahane">
    SELECT product_id, product_name, product_code
    FROM product
    WHERE product_status = true
    ORDER BY product_name
</cfquery>
<cfset productsArr = []>
<cfloop query="getProducts">
    <cfset arrayAppend(productsArr, {
        "product_id"   : val(product_id),
        "product_name" : product_name ?: "",
        "product_code" : product_code ?: ""
    })>
</cfloop>

<!--- Ürün kategorileri --->
<cfquery name="getProductCats" datasource="boyahane">
    SELECT product_catid, product_cat
    FROM product_cat
    ORDER BY product_cat
</cfquery>
<cfset productCatsArr = []>
<cfloop query="getProductCats">
    <cfset arrayAppend(productCatsArr, {
        "product_catid" : val(product_catid),
        "product_cat"   : product_cat ?: ""
    })>
</cfloop>

<!--- Tüm aktif parametreler --->
<cfquery name="getAllParams" datasource="boyahane">
    SELECT qc_param_id, param_code, param_name, unit_name, min_value, max_value
    FROM qc_parameters WHERE is_active = true ORDER BY sort_order, param_name
</cfquery>
<cfset allParamsArr = []>
<cfloop query="getAllParams">
    <cfset arrayAppend(allParamsArr, {
        "qc_param_id" : val(qc_param_id),
        "param_code"  : param_code ?: "",
        "param_name"  : param_name ?: "",
        "unit_name"   : unit_name  ?: "",
        "min_value"   : isNumeric(min_value) ? val(min_value) : "",
        "max_value"   : isNumeric(max_value) ? val(max_value) : "",
        "display"     : param_code & " - " & param_name & (len(unit_name) ? " (" & unit_name & ")" : "")
    })>
</cfloop>

<!--- Mevcut plan kalemleri JSON'a çevir --->
<cfset planItemsArr = []>
<cfif editMode>
    <cfloop query="getPlanItems">
        <cfset arrayAppend(planItemsArr, {
            "qc_plan_item_id" : val(qc_plan_item_id),
            "qc_param_id"     : val(qc_param_id),
            "param_code"      : param_code      ?: "",
            "param_name"      : param_name      ?: "",
            "unit_name"       : unit_name        ?: "",
            "min_value"       : isNumeric(min_value) ? val(min_value) : "",
            "max_value"       : isNumeric(max_value) ? val(max_value) : "",
            "min_override"    : isNumeric(min_override) ? val(min_override) : "",
            "max_override"    : isNumeric(max_override) ? val(max_override) : "",
            "is_required"     : isBoolean(is_required) ? is_required : true,
            "sort_order"      : val(sort_order)
        })>
    </cfloop>
</cfif>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-clipboard-list"></i></div>
        <div class="page-header-title">
            <h1>#editMode ? 'KK Planı Düzenle' : 'Yeni KK Planı'#</h1>
        </div>
    </div>
    <a href="index.cfm?fuseaction=quality.list_qc_plans" class="btn btn-outline-secondary">
        <i class="fas fa-arrow-left me-1"></i>Listeye Dön
    </a>
</div>

<div class="px-3">
    <form id="planForm">
        <input type="hidden" id="qc_plan_id" name="qc_plan_id" value="#currentId#">
        <input type="hidden" id="planItemsJson" name="plan_items" value="">

        <div class="row g-3 mb-4">
            <div class="col-12"><div class="card"><div class="card-header fw-bold"><i class="fas fa-info-circle me-1"></i>Plan Bilgileri</div><div class="card-body">
            <div class="row g-3">
                <div class="col-md-2">
                    <label class="form-label">Plan Kodu <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" name="plan_code"
                           value="#htmlEditFormat(getRec.plan_code)#" maxlength="50" required>
                </div>
                <div class="col-md-4">
                    <label class="form-label">Plan Adı <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" name="plan_name"
                           value="#htmlEditFormat(getRec.plan_name)#" maxlength="200" required>
                </div>
                <div class="col-md-3">
                    <label class="form-label">Kontrol Tipi <span class="text-danger">*</span></label>
                    <select class="form-select" name="control_type">
                        <option value="1" #val(getRec.control_type) eq 1 ? 'selected' : ''#>Giriş Kontrol</option>
                        <option value="2" #val(getRec.control_type) eq 2 ? 'selected' : ''#>Operasyon Kontrol</option>
                        <option value="3" #val(getRec.control_type) eq 3 ? 'selected' : ''#>Final / Çıkış Kontrol</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label">Ürün Kategorisi (isteğe bağlı)</label>
                    <div id="productCatSelect"></div>
                    <small class="text-muted">Seçilirse o kategorideki tüm ürünlere uygulanır</small>
                </div>
                <div class="col-md-3">
                    <label class="form-label">Ürün (isteğe bağlı)</label>
                    <div id="productSelect"></div>
                    <small class="text-muted">Tek ürün seçmek için kullanın</small>
                </div>
                <div class="col-md-2">
                    <label class="form-label">Numune Yöntemi</label>
                    <select class="form-select" name="sample_method" id="sample_method" onchange="toggleSampleValue()">
                        <option value="1" #val(getRec.sample_method) eq 1 ? 'selected' : ''#>Sabit Miktar</option>
                        <option value="2" #val(getRec.sample_method) eq 2 ? 'selected' : ''#>Yüzde (%)</option>
                        <option value="3" #val(getRec.sample_method) eq 3 ? 'selected' : ''#>Tümü</option>
                    </select>
                </div>
                <div class="col-md-2" id="sampleValueDiv">
                    <label class="form-label">Numune Değeri</label>
                    <input type="number" step="any" class="form-control" name="sample_value"
                           value="#isNumeric(getRec.sample_value) ? getRec.sample_value : ''#">
                </div>
                <div class="col-md-1">
                    <label class="form-label">Durum</label>
                    <select class="form-select" name="is_active">
                        <option value="true"  #(isBoolean(getRec.is_active) AND getRec.is_active) ? 'selected' : ''#>Aktif</option>
                        <option value="false" #(isBoolean(getRec.is_active) AND NOT getRec.is_active) ? 'selected' : ''#>Pasif</option>
                    </select>
                </div>
                <div class="col-12">
                    <label class="form-label">Açıklama</label>
                    <textarea class="form-control" name="detail" rows="2">#htmlEditFormat(getRec.detail ?: '')#</textarea>
                </div>
            </div>
            </div></div></div>

            <!--- Parametre Kalemleri --->
            <div class="col-12">
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center fw-bold">
                        <span><i class="fas fa-list-check me-1"></i>Kontrol Parametreleri</span>
                        <button type="button" class="btn btn-sm btn-success" onclick="addParamRow()">
                            <i class="fas fa-plus me-1"></i>Parametre Ekle
                        </button>
                    </div>
                    <div class="card-body p-0">
                        <table class="table table-sm mb-0" id="itemsTable">
                            <thead class="table-light">
                                <tr>
                                    <th>Parametre</th>
                                    <th style="width:110px">Min (Override)</th>
                                    <th style="width:110px">Max (Override)</th>
                                    <th style="width:100px">Zorunlu</th>
                                    <th style="width:80px">Sıra</th>
                                    <th style="width:60px"></th>
                                </tr>
                            </thead>
                            <tbody id="itemsBody"></tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <div class="d-flex gap-2">
            <input type="hidden" id="productCatIdHidden" name="product_catid" value="#isNumeric(getRec.product_catid) ? val(getRec.product_catid) : ''#">
            <input type="hidden" id="productIdHidden" name="product_id" value="#isNumeric(getRec.product_id) ? val(getRec.product_id) : ''#">
            <button type="submit" class="btn btn-primary"><i class="fas fa-save me-1"></i>#editMode ? 'Güncelle' : 'Kaydet'#</button>
            <a href="index.cfm?fuseaction=quality.list_qc_plans" class="btn btn-secondary">İptal</a>
        </div>
    </form>
</div>

<script>
var allParams          = #serializeJSON(allParamsArr)#;
var planItems          = #serializeJSON(planItemsArr)#;
var productCats        = #serializeJSON(productCatsArr)#;
var products           = #serializeJSON(productsArr)#;
var selectedProductCatId = #isNumeric(getRec.product_catid) ? val(getRec.product_catid) : 0#;
var selectedProductId    = #isNumeric(getRec.product_id) ? val(getRec.product_id) : 0#;

$(function(){
    // Ürün Kategorisi seçici
    new DevExpress.ui.dxSelectBox(document.getElementById('productCatSelect'), {
        dataSource: productCats,
        displayExpr: 'product_cat',
        valueExpr: 'product_catid',
        searchEnabled: true,
        showClearButton: true,
        placeholder: 'Tüm kategoriler için boş bırakın...',
        value: selectedProductCatId > 0 ? selectedProductCatId : null,
        onValueChanged: function(e) {
            selectedProductCatId = e.value || 0;
            document.getElementById('productCatIdHidden').value = selectedProductCatId;
        }
    });

    // Ürün seçici
    new DevExpress.ui.dxSelectBox(document.getElementById('productSelect'), {
        dataSource: products,
        displayExpr: 'product_name',
        valueExpr: 'product_id',
        searchEnabled: true,
        showClearButton: true,
        placeholder: 'Tüm ürünler için boş bırakın...',
        value: selectedProductId > 0 ? selectedProductId : null,
        onValueChanged: function(e) {
            selectedProductId = e.value || 0;
            document.getElementById('productIdHidden').value = selectedProductId;
        }
    });

    // Mevcut kalemleri render et
    planItems.forEach(function(item){ renderItemRow(item); });
    toggleSampleValue();
});

function toggleSampleValue() {
    var m = document.getElementById('sample_method').value;
    document.getElementById('sampleValueDiv').style.display = m === '3' ? 'none' : '';
}

function addParamRow() {
    var paramId = prompt('Parametre seçmek için lütfen formu aşağıdaki listeden kullanın.\n\n' +
        allParams.map(function(p,i){ return (i+1)+'. '+p.display; }).join('\n') +
        '\n\nNumara girin:');
    if (!paramId) return;
    var idx = parseInt(paramId) - 1;
    if (isNaN(idx) || idx < 0 || idx >= allParams.length) { alert('Geçersiz seçim'); return; }
    var p = allParams[idx];
    // Zaten eklendi mi?
    var existing = document.querySelectorAll('[data-param-id="' + p.qc_param_id + '"]');
    if (existing.length > 0) { alert(p.param_name + ' zaten listede'); return; }
    renderItemRow({ qc_plan_item_id: 0, qc_param_id: p.qc_param_id, param_name: p.param_name,
        param_code: p.param_code, unit_name: p.unit_name,
        min_value: p.min_value, max_value: p.max_value,
        min_override: '', max_override: '', is_required: true, sort_order: 0 });
}

function renderItemRow(item) {
    var tr = document.createElement('tr');
    tr.setAttribute('data-param-id', item.qc_param_id);
    tr.innerHTML = '<td>' +
        '<span class="fw-semibold">' + (item.param_code||'') + '</span> - ' + (item.param_name||'') +
        (item.unit_name ? ' <small class="text-muted">(' + item.unit_name + ')</small>' : '') +
        '<br><small class="text-muted">Varsayılan: ' +
        (item.min_value !== '' && item.min_value !== null ? 'Min:' + item.min_value : '') +
        (item.max_value !== '' && item.max_value !== null ? ' Max:' + item.max_value : '') +
        '</small>' +
        '<input type="hidden" class="fi-param-id" value="' + item.qc_param_id + '">' +
        '<input type="hidden" class="fi-item-id" value="' + (item.qc_plan_item_id||0) + '">' +
        '</td>' +
        '<td><input type="number" step="any" class="form-control form-control-sm fi-min" value="' + (item.min_override||'') + '" placeholder="—"></td>' +
        '<td><input type="number" step="any" class="form-control form-control-sm fi-max" value="' + (item.max_override||'') + '" placeholder="—"></td>' +
        '<td><select class="form-select form-select-sm fi-required">' +
            '<option value="true"'  + (item.is_required ? ' selected' : '') + '>Zorunlu</option>' +
            '<option value="false"' + (!item.is_required ? ' selected' : '') + '>İsteğe Bağlı</option>' +
        '</select></td>' +
        '<td><input type="number" class="form-control form-control-sm fi-sort" value="' + (item.sort_order||0) + '" min="0"></td>' +
        '<td><button type="button" class="btn btn-sm btn-outline-danger" onclick="removeRow(this)"><i class="fas fa-times"></i></button></td>';
    document.getElementById('itemsBody').appendChild(tr);
}

function removeRow(btn) { btn.closest('tr').remove(); }

function collectItems() {
    var rows = document.querySelectorAll('##itemsBody tr');
    var items = [];
    rows.forEach(function(tr){
        items.push({
            qc_plan_item_id : parseInt(tr.querySelector('.fi-item-id').value) || 0,
            qc_param_id     : parseInt(tr.querySelector('.fi-param-id').value),
            min_override    : tr.querySelector('.fi-min').value,
            max_override    : tr.querySelector('.fi-max').value,
            is_required     : tr.querySelector('.fi-required').value,
            sort_order      : parseInt(tr.querySelector('.fi-sort').value) || 0
        });
    });
    return items;
}

document.getElementById('planForm').addEventListener('submit', function(e){
    e.preventDefault();
    document.getElementById('planItemsJson').value = JSON.stringify(collectItems());

    var fd = new FormData(this);
    fd.set('product_id', selectedProductId || '');
    var data = {};
    fd.forEach(function(v,k){ data[k] = v; });

    $.post('index.cfm?fuseaction=quality.save_qc_plan', data, function(res){
        var r = typeof res === 'string' ? JSON.parse(res) : res;
        if (r.success) {
            var act = data.qc_plan_id > 0 ? 'updated' : 'added';
            window.location.href = 'index.cfm?fuseaction=quality.list_qc_plans&success=' + act;
        } else {
            alert('Hata: ' + (r.message || 'Kaydedilemedi'));
        }
    });
});
</script>
</cfoutput>
