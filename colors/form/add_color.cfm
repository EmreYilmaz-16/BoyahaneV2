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

<!--- ─── Ürün / Kumaş BOM Ağacı ─── --->
<div id="productTreeCard" style="display:none;" class="mt-3">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-sitemap"></i>Ürün / Kumaş BOM Ağacı</div>
            <span class="record-count" id="bomRecordCount"></span>
        </div>
        <div class="card-body p-2">
            <div id="productBomTree"></div>
        </div>
    </div>
</div>

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
    initRecipeTree();
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
            else { clearProductSelect(); clearProductTree(); }
        }
    });
}

function loadProductsByCompany(companyId, selectedProductId) {
    $.get('/colors/api/get_company_products.cfm', { company_id: companyId }, function(res) {
        if (!res || !res.length) { clearProductSelect(); clearProductTree(); return; }
        if ($('##productSelect').data('dxSelectBox')) {
            $('##productSelect').dxSelectBox('instance').option('dataSource', res);
            if (selectedProductId) {
                $('##productSelect').dxSelectBox('instance').option('value', selectedProductId);
                var item = res.find(function(x) { return x.product_id == selectedProductId; });
                if (item && item.stock_id) loadProductTree(item.stock_id);
            }
        } else {
            $('##productSelect').dxSelectBox({
                dataSource: res,
                valueExpr: 'product_id',
                displayExpr: function(item) { return item ? (item.stock_code ? item.stock_code + ' — ' : '') + item.product_name : ''; },
                searchEnabled: true,
                searchExpr: ['product_name','stock_code'],
                placeholder: 'Urun / Kumas sec...',
                value: selectedProductId || null,
                onValueChanged: function(e) {
                    $('##h_product_id').val(e.value || '');
                    var sel = e.component.option('selectedItem');
                    if (sel && sel.stock_id) loadProductTree(sel.stock_id);
                    else clearProductTree();
                }
            });
            if (selectedProductId) {
                var item = res.find(function(x) { return x.product_id == selectedProductId; });
                if (item && item.stock_id) loadProductTree(item.stock_id);
            }
        }
    }, 'json');
}

function clearProductSelect() {
    if ($('##productSelect').data('dxSelectBox')) {
        $('##productSelect').dxSelectBox('instance').option('dataSource', []);
    }
}

function loadProductTree(stockId) {
    document.getElementById('bomRecordCount').textContent = 'Yükleniyor...';
    document.getElementById('productTreeCard').style.display = '';
    $.get('/colors/api/get_product_tree.cfm', { stock_id: stockId }, function(data) {
        if (!data || !data.length) {
            document.getElementById('bomRecordCount').textContent = 'BOM bulunamadı';
            if ($('##productBomTree').data('dxTreeList')) {
                $('##productBomTree').dxTreeList('instance').option('dataSource', []);
            }
            return;
        }
        document.getElementById('bomRecordCount').textContent = data.length + ' satır';
        if ($('##productBomTree').data('dxTreeList')) {
            $('##productBomTree').dxTreeList('instance').option('dataSource', data);
            return;
        }
        $('##productBomTree').dxTreeList({
            dataSource        : data,
            keyExpr           : 'product_tree_id',
            parentIdExpr      : 'related_product_tree_id',
            rootValue         : 0,
            showBorders       : true,
            showRowLines      : true,
            showColumnLines   : true,
            rowAlternationEnabled: true,
            columnAutoWidth   : true,
            allowColumnReordering: true,
            allowColumnResizing : true,
            columnResizingMode  : 'widget',
            autoExpandAll     : true,
            paging            : { enabled: false },
            filterRow         : { visible: true },
            searchPanel       : { visible: true, width: 220, placeholder: 'Ara...' },
            sorting           : { mode: 'multiple' },
            scrolling         : { mode: 'standard' },
            onContentReady    : function(e) {
                var total = e.component.getVisibleRows().length;
                document.getElementById('bomRecordCount').textContent = total + ' satır';
            },
            columns: [
                { dataField: 'line_number', caption: '##', width: 50, alignment: 'center', dataType: 'number' },
                {
                    caption: 'Bileşen', minWidth: 220,
                    cellTemplate: function(c, o) {
                        var d = o.data;
                        var isOp = d.operation_type_id > 0 && d.component_stock_id === 0;
                        if (isOp) {
                            $('<span>').addClass('badge bg-warning text-dark me-1').html('<i class="fas fa-cogs"></i>').appendTo(c);
                            $('<span>').text(d.operation_type_name || 'Operasyon').appendTo(c);
                        } else {
                            $('<span>').addClass('fw-semibold me-1').text(d.component_stock_code || '').appendTo(c);
                            if (d.component_name) $('<span>').addClass('small text-muted').text('— ' + d.component_name).appendTo(c);
                        }
                    }
                },
                { dataField: 'amount', caption: 'Miktar', width: 90, alignment: 'right', dataType: 'number',
                  format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'unit_name', caption: 'Birim', width: 70 },
                { dataField: 'station_name', caption: 'İstasyon', width: 150,
                  cellTemplate: function(c, o) { $('<span>').addClass('small').text(o.value || '-').appendTo(c); } },
                { dataField: 'fire_rate', caption: 'Fire %', width: 70, alignment: 'right', dataType: 'number',
                  format: { type: 'fixedPoint', precision: 2 },
                  cellTemplate: function(c, o) {
                      if (o.value) $('<span>').addClass('small text-warning').text(o.value + '%').appendTo(c);
                  }
                },
                { caption: 'Bayraklar', width: 120, allowSorting: false, allowFiltering: false,
                  cellTemplate: function(c, o) {
                      var d = o.data;
                      if (d.is_phantom)   $('<span>').addClass('badge bg-warning text-dark small me-1').text('Sanal').appendTo(c);
                      if (d.is_configure) $('<span>').addClass('badge bg-info text-dark small me-1').text('Konfigüre').appendTo(c);
                      if (d.is_sevk)      $('<span>').addClass('badge bg-secondary small').text('Sevk').appendTo(c);
                  }
                },
                { dataField: 'detail', caption: 'Detay', minWidth: 120,
                  cellTemplate: function(c, o) { $('<span>').addClass('small text-muted').text(o.value || '').appendTo(c); } }
            ]
        });
    }, 'json');
}

function clearProductTree() {
    document.getElementById('productTreeCard').style.display = 'none';
    if ($('##productBomTree').data('dxTreeList')) {
        $('##productBomTree').dxTreeList('instance').option('dataSource', []);
    }
}

function loadExistingRecipe(stockId) {
    $.get('/colors/api/get_recipe.cfm', { stock_id: stockId }, function(res) {
        if (!res || !res.length) return;
        recipeData = res.map(function(row) {
            return {
                product_tree_id        : row.product_tree_id || row.row_id,
                related_product_tree_id: row.related_product_tree_id || 0,
                stock_id               : row.stock_id || 0,
                stock_code             : row.stock_code || '',
                product_name           : row.product_name || '',
                amount                 : parseFloat(row.amount) || 0,
                unit_id                : row.unit_id || 0,
                unit_name              : '',
                tip                    : parseInt(row.tip) || 0,
                line_number            : row.line_number || 0,
                is_operation           : parseInt(row.is_operation) || 0,
                operation_type_id      : row.operation_type_id || 0,
                operation_type_name    : ''
            };
        });
        initRecipeTree();
        RenkHesapla();
    }, 'json');
}

function saveColor() {
    var companyId = $('##h_company_id').val();
    var productId = $('##h_product_id').val();
    if (!companyId || companyId == '0') { DevExpress.ui.notify('Musteri secimi zorunludur.', 'warning', 2500); return; }

    var recipeItems = [];
    recipeData.forEach(function(row) {
        if (row.related_product_tree_id !== 0) return; /* sadece kök öğeleri işle; çocuklar operation grubuyla eklenir */
        if (row.is_operation) {
            var gKey = 'gop_' + Math.abs(row.product_tree_id);
            recipeItems.push({ stock_id: 0, amount: row.amount || 1, unit_id: 0,
                               is_operation: 1, operation_type_id: row.operation_type_id,
                               line_order: row.line_number, parent_id: gKey });
            recipeData.filter(function(c) { return c.related_product_tree_id === row.product_tree_id; })
                      .forEach(function(child) {
                recipeItems.push({ stock_id: child.stock_id, amount: child.amount, unit_id: child.unit_id || 0,
                                   is_operation: 0, operation_type_id: 0,
                                   line_order: child.line_number, parent_id: gKey });
            });
        } else {
            recipeItems.push({ stock_id: row.stock_id, amount: row.amount, unit_id: row.unit_id || 0,
                               is_operation: 0, operation_type_id: 0,
                               line_order: row.line_number, parent_id: '' });
        }
    });
    if (!recipeItems.length) { DevExpress.ui.notify('Reçete boş olamaz.', 'warning', 2500); return; }

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
        //    window.location.href = 'index.cfm?fuseaction=colors.list_colors&success=' + (res.mode || 'added');
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