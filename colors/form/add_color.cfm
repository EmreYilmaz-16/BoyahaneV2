<cfprocessingdirective pageEncoding="utf-8">

<!---
    Renk Ekle / Düzenle
    url.stock_id  = düzenleme modunda mevcut rengin stock_id'si (opsiyonel)
--->

<cfparam name="url.stock_id" default="0">
<cfset editStockId = isNumeric(url.stock_id) AND val(url.stock_id) gt 0 ? val(url.stock_id) : 0>
<cfset isEdit      = editStockId gt 0>

<!--- Düzenleme modunda mevcut rengi yükle --->
<cfif isEdit>
    <cfquery name="getColor" datasource="boyahane">
        SELECT ci.*, s.stock_code
        FROM color_info ci
        LEFT JOIN stocks s ON ci.stock_id = s.stock_id
        WHERE ci.stock_id = <cfqueryparam value="#editStockId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getColor.recordCount>
        <cflocation url="index.cfm?fuseaction=colors.list_colors" addtoken="false">
    </cfif>
</cfif>

<!--- Müşteri listesi --->
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


<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-palette"></i></div>
        <div class="page-header-title">
            <h1><cfif isEdit>Renk Düzenle<cfelse>Yeni Renk</cfif></h1>
            <p><cfif isEdit>#htmlEditFormat(getColor.color_code)# — #htmlEditFormat(getColor.color_name)#<cfelse>Yeni renk kaydı oluşturun</cfif></p>
        </div>
    </div>
    <div class="d-flex gap-2">
        <button class="btn-add" id="btnSave" onclick="saveColor()">
            <i class="fas fa-save"></i>Kaydet
        </button>
        <a class="btn-back" href="index.cfm?fuseaction=colors.list_colors">
            <i class="fas fa-arrow-left"></i>Listeye Dön
        </a>
    </div>
</div>

<div class="px-3 pb-5">
<div class="row g-3">

<!--- ─── SOL: Renk Bilgileri ─── --->
<div class="col-lg-5">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Renk Bilgileri</div>
        </div>
        <div class="card-body p-3">

            <input type="hidden" id="h_stock_id"   value="#editStockId#">
            <input type="hidden" id="h_company_id" value="#isEdit ? getColor.company_id : ''#">
            <input type="hidden" id="h_product_id" value="#isEdit ? getColor.product_id : ''#">

            <!--- Müşteri --->
            <div class="mb-3">
                <label class="form-label">Müşteri <span class="text-danger">*</span></label>
                <div id="companySelect"></div>
            </div>

            <!--- Ürün / Kumaş --->
            <div class="mb-3">
                <label class="form-label">Ürün / Kumaş <span class="text-danger">*</span></label>
                <div id="productSelect"></div>
                <div class="form-text">Önce müşteri seçin.</div>
            </div>

            <div class="row g-2 mb-3">
                <div class="col-5">
                    <label class="form-label">Renk Kodu</label>
                    <input type="text" class="form-control" id="f_color_code"
                           value="#isEdit ? htmlEditFormat(getColor.color_code) : ''#" maxlength="100" placeholder="R.Kodu">
                </div>
                <div class="col-7">
                    <label class="form-label">Renk Adı</label>
                    <input type="text" class="form-control" id="f_color_name"
                           value="#isEdit ? htmlEditFormat(getColor.color_name) : ''#" maxlength="255" placeholder="Renk adı">
                </div>
            </div>

            <div class="row g-2 mb-3">
                <div class="col-6">
                    <label class="form-label">Kartela No</label>
                    <input type="text" class="form-control" id="f_kartela_no"
                           value="#isEdit ? htmlEditFormat(getColor.kartela_no) : ''#" maxlength="100">
                </div>
                <div class="col-6">
                    <label class="form-label">Kartela Tarihi</label>
                    <input type="date" class="form-control" id="f_kartela_date"
                           value="#isEdit AND isDate(getColor.kartela_date) ? dateFormat(getColor.kartela_date,'yyyy-mm-dd') : ''#">
                </div>
            </div>

            <div class="row g-2 mb-3">
                <div class="col-4">
                    <label class="form-label">R.Tonu</label>
                    <input type="number" min="0" max="9" class="form-control" id="f_renk_tonu"
                           value="#isEdit ? getColor.renk_tonu : ''#">
                </div>
                <div class="col-4">
                    <label class="form-label">Boya C.</label>
                    <input type="text" class="form-control" id="f_boya_derecesi"
                           value="#isEdit ? htmlEditFormat(getColor.boya_derecesi) : ''#" maxlength="50">
                </div>
                <div class="col-4">
                    <label class="form-label">Flote</label>
                    <input type="number" step="0.01" min="0" class="form-control" id="f_flote"
                           value="#isEdit ? getColor.flote : ''#">
                </div>
            </div>

            <div class="mb-3">
                <label class="form-label">Açıklama</label>
                <input type="text" class="form-control" id="f_information"
                       value="#isEdit ? htmlEditFormat(getColor.information) : ''#" maxlength="500">
            </div>

            <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" id="f_is_ready"
                       <cfif isEdit AND getColor.is_ready>checked</cfif>>
                <label class="form-check-label" for="f_is_ready">Hazır</label>
            </div>

        </div>
    </div>
</div>

<!--- ─── SAĞ: Boya Reçetesi ─── --->
<div class="col-lg-7">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-flask"></i>Boya Reçetesi</div>
            <button class="btn btn-sm btn-outline-primary" onclick="OpenOperationPopup()">
                <i class="fas fa-plus me-1"></i>Operasyon
            </button>
        </div>
        <div class="card-body p-3">
            <div id="CurrentTree"></div>
        </div>
    </div>
</div>

</div><!--- row --->
</div><!--- px-3 --->

<!--- ─── Popup container'lar ─── --->
<div id="operationPopupContainer"></div>
<div id="renkEklePopupContainer"></div>

<script>
var companiesData = #serializeJSON(companiesArr)#;
var editStockId   = #editStockId#;
var operationPopup = null;
var renkEklePopup  = null;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    initCompanySelect();
    initPopups();
    <cfif isEdit>
    loadExistingRecipe(#editStockId#);
    loadProductsByCompany(#getColor.company_id#, #getColor.product_id#);
    </cfif>
});

function initPopups() {
    $('##operationPopupContainer').dxPopup({
        title: 'Boya Ara / Ekle',
        width: 650,
        height: 'auto',
        maxHeight: '80vh',
        showCloseButton: true,
        dragEnabled: true,
        contentTemplate: '<table class="table"><tr><td><input type="text" class="form-control form-control-sm" id="Modkeyword" placeholder="Urun ara..." onkeydown="keypp(this,event)"></td><td><button class="btn btn-success btn-sm" onclick="SearchProd()">Ara</button></td></tr></table><div id="Div_1"></div>'
    });
    operationPopup = $('##operationPopupContainer').dxPopup('instance');

    $('##renkEklePopupContainer').dxPopup({
        title: 'Ic Bilesen Ekle',
        width: 650,
        height: 'auto',
        maxHeight: '80vh',
        showCloseButton: true,
        dragEnabled: true,
        contentTemplate: '<table class="table"><tr><td><input type="text" class="form-control form-control-sm" id="Prokeyword" placeholder="Urun ara..." onkeydown="keypps(this,event)"></td><td><button class="btn btn-success btn-sm" onclick="SearchProd_2()">Ara</button></td></tr></table><div id="Div_1_PROD"></div>'
    });
    renkEklePopup = $('##renkEklePopupContainer').dxPopup('instance');
}

function initCompanySelect() {
    $('##companySelect').dxSelectBox({
        dataSource: companiesData,
        valueExpr: 'company_id',
        displayExpr: function(item) { return item ? (item.member_code ? item.member_code + ' — ' : '') + item.company_name : ''; },
        searchEnabled: true,
        searchExpr: ['company_name','member_code'],
        placeholder: 'Musteri secin...',
        value: <cfif isEdit>#getColor.company_id#<cfelse>null</cfif>,
        onValueChanged: function(e) {
            $('##h_company_id').val(e.value || '');
            $('##h_product_id').val('');
            if (e.value) loadProductsByCompany(e.value, null);
            else clearProductSelect();
        }
    });
}

function loadProductsByCompany(companyId, selectedProductId) {
    $.get('/colors/api/get_company_products.cfm', { company_id: companyId }, function(res) {
        if (!res || !res.length) { clearProductSelect(); return; }
        if ($('##productSelect').data('dxSelectBox')) {
            $('##productSelect').dxSelectBox('instance').option('dataSource', res);
            if (selectedProductId) $('##productSelect').dxSelectBox('instance').option('value', selectedProductId);
        } else {
            $('##productSelect').dxSelectBox({
                dataSource: res,
                valueExpr: 'product_id',
                displayExpr: function(item) { return item ? (item.stock_code ? item.stock_code + ' — ' : '') + item.product_name : ''; },
                searchEnabled: true,
                searchExpr: ['product_name','stock_code'],
                placeholder: 'Urun / Kumas sec...',
                value: selectedProductId || null,
                onValueChanged: function(e) { $('##h_product_id').val(e.value || ''); }
            });
        }
    }, 'json');
}

function clearProductSelect() {
    if ($('##productSelect').data('dxSelectBox')) {
        $('##productSelect').dxSelectBox('instance').option('dataSource', []);
    }
}

function loadExistingRecipe(stockId) {
    $.get('/colors/api/get_recipe.cfm', { stock_id: stockId }, function(res) {
        if (!res || !res.length) return;
        var html = '<ul class="list-group"><li data-id="0" class="list-group-item py-1 px-2">'
                 + '<ul class="urun_agac_liste" id="urun_0_0" style="margin-top:8px">';
        res.forEach(function(row, idx) {
            var tip = parseInt(row.tip) || 0;
            html += '<li style="margin-top:5px" data-id="' + row.stock_id + '" data-parent="0">'
                  + '<div style="display:flex;align-items:center;gap:6px">'
                  + '<input type="text" style="width:25px" value="' + (idx + 1) + '">'
                  + escHtml(row.stock_code || '') + ' ' + escHtml(row.product_name || '')
                  + '<button style="margin-inline-start:auto" class="btn btn-sm btn-danger" onclick="reminner(this,0,0)">-</button>'
                  + '<input type="number" class="form-control form-control-sm RT_' + tip + '" onchange="RenkHesapla()" style="width:70px" value="' + (parseFloat(row.amount) || 0) + '">'
                  + '</div></li>';
        });
        html += '</ul></li></ul>';
        $('##CurrentTree').html(html);
        RenkHesapla();
    }, 'json');
}

function saveColor() {
    var companyId = $('##h_company_id').val();
    var productId = $('##h_product_id').val();
    if (!companyId || companyId == '0') { DevExpress.ui.notify('Musteri secimi zorunludur.', 'warning', 2500); return; }

    var recipeItems = [];
    $('##CurrentTree .urun_agac_liste li[data-id]').each(function() {
        var sid = parseInt($(this).data('id'));
        var amt = parseFloat($(this).find('input[type=number]').val()) || 0;
        if (sid > 0) recipeItems.push({ stock_id: sid, amount: amt, unit_id: 0 });
    });
    if (!recipeItems.length) { DevExpress.ui.notify('Recete bos olamaz.', 'warning', 2500); return; }

    var btn = document.getElementById('btnSave');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Kaydediliyor...';

    $.post('/colors/form/save_color.cfm', {
        stock_id      : editStockId,
        company_id    : companyId,
        product_id    : productId || '',
        color_code    : document.getElementById('f_color_code').value.trim(),
        color_name    : document.getElementById('f_color_name').value.trim(),
        kartela_no    : document.getElementById('f_kartela_no').value.trim(),
        kartela_date  : document.getElementById('f_kartela_date').value,
        renk_tonu     : document.getElementById('f_renk_tonu').value,
        boya_derecesi : document.getElementById('f_boya_derecesi').value.trim(),
        flote         : document.getElementById('f_flote').value,
        information   : document.getElementById('f_information').value.trim(),
        is_ready      : document.getElementById('f_is_ready').checked ? 'true' : 'false',
        recipe_json   : JSON.stringify(recipeItems)
    }, function(res) {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-save"></i> Kaydet';
        if (res && res.success) {
            window.location.href = 'index.cfm?fuseaction=colors.list_colors&success=' + (res.mode || 'added');
        } else {
            DevExpress.ui.notify((res && res.message) || 'Kayit basarisiz.', 'error', 3500);
        }
    }, 'json').fail(function() {
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-save"></i> Kaydet';
        DevExpress.ui.notify('Sunucu hatasi.', 'error', 3000);
    });
}

function escHtml(s) {
    return String(s || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

<cfinclude template="agac_func.js">
</script>
</cfoutput>