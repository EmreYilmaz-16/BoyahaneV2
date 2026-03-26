var _prodPopupParentTreeId = 0;
var OperationModal = { show: function(){ if(typeof operationPopup !== 'undefined' && operationPopup) operationPopup.show(); } };
var ProductModal   = { show: function(){ if(typeof renkEklePopup  !== 'undefined' && renkEklePopup)  renkEklePopup.show();  } };

var recipeData  = [];
var _tempIdCtr  = 0;
function nextTempId() { return --_tempIdCtr; }

/* ─── dxTreeList: başlatma / yenileme ─── */
function initRecipeTree() {
    if ($('#CurrentTree').data('dxTreeList')) { refreshRecipeTree(); return; }
    $('#CurrentTree').dxTreeList({
        dataSource          : new DevExpress.data.ArrayStore({ key: 'product_tree_id', data: recipeData }),
        keyExpr             : 'product_tree_id',
        parentIdExpr        : 'related_product_tree_id',
        rootValue           : 0,
        showBorders         : true,
        showRowLines        : true,
        showColumnLines     : true,
        rowAlternationEnabled: true,
        columnAutoWidth     : true,
        autoExpandAll       : true,
        paging              : { enabled: false },
        editing             : { mode: 'cell', allowUpdating: true, selectTextOnEditStart: true, startEditAction: 'click' },
        onCellValueChanged  : function(e) { if (e.column.dataField === 'amount') RenkHesapla(); },
        columns: [
            {
                dataField  : 'line_number',
                caption    : '#',
                width      : 55,
                alignment  : 'center',
                dataType   : 'number',
                allowEditing: true
            },
            {
                caption     : 'Bileşen',
                minWidth    : 200,
                allowEditing: false,
                cellTemplate: function(c, o) {
                    var d = o.data;
                    if (d.is_operation) {
                        $('<span>').addClass('badge bg-warning text-dark me-1').html('<i class="fas fa-cogs"></i>').appendTo(c);
                        $('<span>').text(d.operation_type_name || 'Operasyon').appendTo(c);
                    } else {
                        if (d.stock_code) $('<span>').addClass('fw-semibold me-1').text(d.stock_code).appendTo(c);
                        if (d.product_name) $('<span>').addClass('text-muted small').text(d.stock_code ? '— ' + d.product_name : d.product_name).appendTo(c);
                    }
                }
            },
            {
                dataField  : 'amount',
                caption    : 'Miktar',
                width      : 110,
                alignment  : 'right',
                dataType   : 'number',
                allowEditing: true,
                format     : { type: 'fixedPoint', precision: 4 }
            },
            {
                caption     : 'Tip',
                width       : 110,
                allowEditing: false,
                allowSorting: false,
                cellTemplate: function(c, o) {
                    var d = o.data;
                    if (!d.is_operation) {
                        var t      = parseInt(d.tip) || 0;
                        var labels = ['Boyarmadde', 'Yardımcı', 'Kimyasal'];
                        var cls    = ['bg-danger', 'bg-warning text-dark', 'bg-info text-dark'];
                        if (labels[t]) $('<span>').addClass('badge ' + cls[t] + ' small').text(labels[t]).appendTo(c);
                    }
                }
            },
            {
                caption     : 'İşlemler',
                width       : 90,
                alignment   : 'center',
                allowSorting: false,
                allowEditing: false,
                cellTemplate: function(c, o) {
                    var d = o.data;
                    var g = $('<div>').addClass('d-flex gap-1 justify-content-center');
                    if (!d.is_operation) {
                        $('<button>').addClass('btn btn-sm btn-outline-success p-1').attr('title', 'Alt Satır Ekle')
                            .html('<i class="fas fa-plus"></i>')
                            .on('click', function(ev) { ev.stopPropagation(); OpenProductpopup(d.product_tree_id); })
                            .appendTo(g);
                    }
                    $('<button>').addClass('btn btn-sm btn-outline-danger p-1').attr('title', 'Sil')
                        .html('<i class="fas fa-trash"></i>')
                        .on('click', function(ev) { ev.stopPropagation(); removeRecipeRow(d.product_tree_id); })
                        .appendTo(g);
                    g.appendTo(c);
                }
            }
        ]
    });
}

function refreshRecipeTree() {
    var inst = $('#CurrentTree').data('dxTreeList') ? $('#CurrentTree').dxTreeList('instance') : null;
    if (!inst) { initRecipeTree(); return; }
    inst.option('dataSource', new DevExpress.data.ArrayStore({ key: 'product_tree_id', data: recipeData }));
}

function removeRecipeRow(treeId) {
    var toRemove = [treeId];
    (function collectChildren(pid) {
        recipeData.forEach(function(r) {
            if (r.related_product_tree_id === pid) {
                toRemove.push(r.product_tree_id);
                collectChildren(r.product_tree_id);
            }
        });
    })(treeId);
    recipeData = recipeData.filter(function(r) { return toRemove.indexOf(r.product_tree_id) === -1; });
    refreshRecipeTree();
    RenkHesapla();
}

/* ─── Operasyon popup ─── */
function OpenOperationPopup() { OperationModal.show(); }

/* ─── Boya arama popup ─── */
function SearchProd() {
    var keyword = $('#Modkeyword').val();
    $.ajax({
        url    : 'cfc/boyahane.cfc?method=getProdTreeWithName_yeni&keyword=' + encodeURIComponent(keyword),
        success: function(retdat) { SatirDoldur(Array.isArray(retdat) ? retdat : JSON.parse(retdat)); }
    });
}
function keypp(elem, ev)  { if (ev.keyCode === 13) SearchProd();   }
function keypps(elem, ev) { if (ev.keyCode === 13) SearchProd_2(); }
/* Popup sonuç listesi — sadece önizleme, ağaca eklemez */
function SatirDoldur(data) {
    var html = '';
    for (var i = 0; i < data.length; i++) {
        html += '<ul class="list-group"><li class="list-group-item py-1">' + escHtml(data[i].PRODUCT_NAME || '');
        html += '<button style="float:right" class="btn btn-sm btn-success" onclick="AgacaEkle(' + data[i].STOCK_ID + ')">+</button>';
        var tree = data[i].TREE || [];
        if (tree.length) {
            html += '<ul>';
            for (var j = 0; j < tree.length; j++) {
                if (tree[j].IS_OPERATION == 1) continue;
                html += '<li class="small text-muted">' + escHtml(tree[j].PRODUCT_NAME || '') + '</li>';
            }
            html += '</ul>';
        }
        html += '</li></ul>';
    }
    $('#Div_1').html(html);
}

/* Seçilen ürünün BOM satırlarını recipeData'ya kök seviyede ekle */
function SatirDoldur_1(data) {
    for (var i = 0; i < data.length; i++) {
        var d    = data[i];
        var tree = d.TREE || [];
        var lineChild = 0;
        for (var j = 0; j < tree.length; j++) {
            var t = tree[j];
            if (t.IS_OPERATION != 1) lineChild++;
            recipeData.push({
                product_tree_id        : nextTempId(),
                related_product_tree_id: 0,
                stock_id               : t.STOCK_ID || 0,
                stock_code             : '',
                product_name           : t.PRODUCT_NAME || '',
                amount                 : parseFloat(t.AMOUNT) || 0,
                unit_id                : t.PRODUCT_UNIT_ID || 0,
                unit_name              : t.MAIN_UNIT || '',
                tip                    : parseInt(t.tip) || 0,
                line_number            : t.IS_OPERATION == 1 ? 0 : lineChild,
                is_operation           : t.IS_OPERATION == 1 ? 1 : 0,
                operation_type_id      : t.OPERATION_TYPE_ID || 0,
                operation_type_name    : t.OPERATION_TYPE_NAME || ''
            });
        }
    }
    refreshRecipeTree();
    RenkHesapla();
}
/* Alt bileşen arama popup için önizleme listesi */
function SatirDoldur_2(data) {
    var html = '';
    for (var i = 0; i < data.length; i++) {
        html += '<ul class="list-group"><li class="list-group-item py-1">' + escHtml(data[i].PRODUCT_NAME || '');
        html += '<button style="float:right" class="btn btn-sm btn-success" onclick="icineEkle(' + data[i].STOCK_ID + ')">+</button>';
        html += '</li></ul>';
    }
    $('#Div_1_PROD').html(html);
}

function AgacaEkle(stock_id) {
    $.ajax({
        url    : 'cfc/boyahane.cfc?method=getProdTreeWithName_yeni&stock_id=' + stock_id,
        success: function(retdat) { SatirDoldur_1(Array.isArray(retdat) ? retdat : JSON.parse(retdat)); }
    });
}

function SearchProd_2() {
    var keyword = $('#Prokeyword').val();
    $.ajax({
        url    : 'cfc/boyahane.cfc?method=getProdTreeWithName_yeni&keyword=' + encodeURIComponent(keyword),
        success: function(retdat) { SatirDoldur_2(Array.isArray(retdat) ? retdat : JSON.parse(retdat)); }
    });
}

/* ─── Alt satır popup ─── */
function OpenProductpopup(parentTreeId) {
    _prodPopupParentTreeId = parentTreeId;
    ProductModal.show();
}

/* Seçilen ürünü parentTreeId'nin altına ekle */
function icineEkle(stock_id) {
    var parentId = _prodPopupParentTreeId;
    $.ajax({
        url    : 'cfc/boyahane.cfc?method=getProdTreeWithName_yeni&stock_id=' + stock_id,
        success: function(retdat) {
            var obj = Array.isArray(retdat) ? retdat : JSON.parse(retdat);
            if (!obj || !obj.length) return;
            var d        = obj[0];
            var siblings = recipeData.filter(function(r) { return r.related_product_tree_id === parentId; }).length;
            recipeData.push({
                product_tree_id        : nextTempId(),
                related_product_tree_id: parentId,
                stock_id               : d.STOCK_ID || 0,
                stock_code             : '',
                product_name           : d.PRODUCT_NAME || '',
                amount                 : parseFloat(d.AMOUNT) || 0,
                unit_id                : d.PRODUCT_UNIT_ID || 0,
                unit_name              : d.MAIN_UNIT || '',
                tip                    : parseInt(d.tip) || 0,
                line_number            : siblings + 1,
                is_operation           : d.IS_OPERATION ? 1 : 0,
                operation_type_id      : d.OPERATION_TYPE_ID || 0,
                operation_type_name    : d.OPERATION_TYPE_NAME || ''
            });
            refreshRecipeTree();
            RenkHesapla();
        }
    });
}

function remProd()   {}
function reminner()  {}

function RenkHesapla() {
    var total = 0;
    recipeData.forEach(function(r) {
        if (!r.is_operation && parseInt(r.tip) === 0) total += parseFloat(r.amount) || 0;
    });
    var t = 1;
    if      (total < 0.2) t = 1;
    else if (total < 0.5) t = 2;
    else if (total < 1)   t = 3;
    else if (total < 2)   t = 4;
    else if (total < 3)   t = 5;
    else                  t = 6;
    $('#f_renk_tonu').val(t);
}

function CoppyCollor() {
    openModal_partner('/index.cfm?fuseaction=labratuvar.emptypopup_ajaxpage_list_color', 'modal-dialog-scrollable modal-xl');
}