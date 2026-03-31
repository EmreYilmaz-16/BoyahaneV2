<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.p_order_id"   default="0">
<cfparam name="url.order_id"     default="0">
<cfparam name="url.order_row_id" default="0">
<cfset editMode      = isNumeric(url.p_order_id) AND val(url.p_order_id) gt 0>
<cfset currentId     = editMode ? val(url.p_order_id) : 0>
<cfset preOrderId    = isNumeric(url.order_id)     AND val(url.order_id)     gt 0 ? val(url.order_id)     : 0>
<cfset preOrderRowId = isNumeric(url.order_row_id) AND val(url.order_row_id) gt 0 ? val(url.order_row_id) : 0>

<cfif editMode>
    <cfquery name="getRec" datasource="boyahane">
        SELECT po.*,
               COALESCE(ci.color_code,'')           AS color_code,
               COALESCE(ci.color_name,'')           AS color_name,
               COALESCE(ci.company_id, 0)           AS color_company_id,
               COALESCE(c.nickname, c.fullname,'')  AS company_name,
               COALESCE(s.stock_code,'')            AS stock_code,
               COALESCE(por.order_row_id, 0)        AS linked_order_row_id
        FROM production_orders po
        LEFT JOIN stocks              s   ON po.stock_id    = s.stock_id
        LEFT JOIN color_info          ci  ON po.stock_id    = ci.stock_id
        LEFT JOIN company             c   ON ci.company_id  = c.company_id
        LEFT JOIN production_orders_row por ON por.p_order_id = po.p_order_id
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

<!--- Siparişler (son 500 açık sipariş) --->
<cfquery name="getOrders" datasource="boyahane">
    SELECT o.order_id,
           COALESCE(o.order_number, '')            AS order_number,
           COALESCE(c.nickname, c.fullname, '')    AS company_name
    FROM orders o
    LEFT JOIN company c ON o.company_id = c.company_id
    WHERE COALESCE(o.order_status, false) = false
    ORDER BY o.order_id DESC
    LIMIT 500
</cfquery>
<cfset ordArr = []>
<cfloop query="getOrders">
    <cfset arrayAppend(ordArr, {
        "order_id"     : val(order_id),
        "order_number" : order_number  ?: "",
        "company_name" : company_name  ?: "",
        "display"      : order_number & (len(company_name) ? " — " & company_name : "")
    })>
</cfloop>

<!--- edit modunda mevcut order_id / order_row_id'yi oku --->
<cfif editMode>
    <cfif isNumeric(getRec.order_id)          AND val(getRec.order_id)          gt 0><cfset preOrderId    = val(getRec.order_id)></cfif>
    <cfif isNumeric(getRec.order_row_id)      AND val(getRec.order_row_id)      gt 0><cfset preOrderRowId = val(getRec.order_row_id)></cfif>
    <cfif isNumeric(getRec.linked_order_row_id) AND val(getRec.linked_order_row_id) gt 0 AND preOrderRowId eq 0>
        <cfset preOrderRowId = val(getRec.linked_order_row_id)>
    </cfif>
</cfif>

<!--- Sipariş satırları (order_row) — tüm açık siparişlerin satırları --->  
<cfquery name="getOrderRows" datasource="boyahane">
    SELECT
        orw.order_row_id,
        orw.order_id,
        orw.stock_id,
        COALESCE(orw.quantity, 0)                           AS quantity,
        COALESCE(orw.product_name, s.stock_code, '')        AS product_name,
        COALESCE(orw.lot_no, '')                            AS lot_no,
        COALESCE(o.order_number, '')                        AS order_number,
        COALESCE(c.nickname, c.fullname, '')                AS company_name,
        COALESCE(ci.color_code, '')                         AS color_code,
        COALESCE(ci.color_name, '')                         AS color_name
    FROM order_row orw
    JOIN orders o    ON orw.order_id  = o.order_id
    LEFT JOIN stocks     s    ON orw.stock_id  = s.stock_id
    LEFT JOIN color_info ci   ON orw.stock_id  = ci.stock_id
    LEFT JOIN company    c    ON o.company_id  = c.company_id
    WHERE COALESCE(o.order_status, false) = false
    ORDER BY orw.order_row_id DESC
    LIMIT 2000
</cfquery>
<cfset rowArr = []>
<cfloop query="getOrderRows">
    <cfset arrayAppend(rowArr, {
        "order_row_id" : val(order_row_id),
        "order_id"     : val(order_id),
        "stock_id"     : val(stock_id),
        "quantity"     : isNumeric(quantity) ? val(quantity) : 0,
        "product_name" : product_name  ?: "",
        "lot_no"       : lot_no        ?: "",
        "order_number" : order_number  ?: "",
        "company_name" : company_name  ?: "",
        "color_code"   : color_code    ?: "",
        "color_name"   : color_name    ?: "",
        "display"      : order_number & " — " & (len(color_code) ? color_code & " " : "") & (len(color_name) ? color_name : product_name)
    })>
</cfloop>

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

<style>
/* ---- add_production_order ---- */
.apo-recipe-group {
    border-left: 3px solid var(--accent, #e67e22);
    border-radius: 0 6px 6px 0;
    background: #fffaf5;
    margin-bottom: 10px;
    padding: 8px 10px;
}
.apo-op-title {
    font-size: 0.75rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: .05em;
    color: var(--accent, #e67e22);
    margin-bottom: 6px;
}
.apo-recipe-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 0.8rem;
    padding: 3px 0;
    border-bottom: 1px dashed #ede8e0;
}
.apo-recipe-row:last-child { border-bottom: none; }
.apo-recipe-name { color: #2c3e50; }
.apo-recipe-amt { color: #8a98a8; font-size: 0.75rem; white-space: nowrap; }
.apo-recipe-amt strong { color: #2c3e50; font-size: 0.8rem; }
.apo-recipe-empty { text-align: center; padding: 20px 0; color: #b0bbc8; font-size: 0.82rem; }
</style>

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
        <cfif editMode>
        <button class="btn btn-danger" id="btnDelete" onclick="deleteOrder()">
            <i class="fas fa-trash"></i> Sil
        </button>
        </cfif>
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
            <input type="hidden" id="h_p_order_id"   value="#currentId#">
            <input type="hidden" id="h_order_id"     value="#preOrderId#">
            <input type="hidden" id="h_order_row_id" value="#preOrderRowId#">

            <div class="mb-3">
                <label class="form-label">Sipariş Satırı <span style="color:##94a3b8;font-weight:400;font-size:.78rem;">(opsiyonel — seçince renk ve miktar otomatik gelir)</span></label>
                <div id="orderRowSelect"></div>
                <div id="orderRowBadge" style="display:none;margin-top:.4rem;"></div>
            </div>

            <div class="mb-3">
                <label class="form-label required-field">Renk Kartı</label>
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
                <label class="form-label required-field">Makina</label>
                <div id="stationSelect"></div>
            </div>

            <div class="mb-3">
                <label class="form-label required-field">Miktar (kg)</label>
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
                        <div class="apo-recipe-empty"><i class="fas fa-flask fa-2x mb-1 d-block opacity-25"></i>Renk seçince reçete görünür.</div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

</div><!--- row --->
</div><!--- px-3 --->

<script>
var colorsData    = #serializeJSON(colArr)#;
var stationsData  = #serializeJSON(stArr)#;
var ordersData    = #serializeJSON(ordArr)#;
var orderRowsData = #serializeJSON(rowArr)#;
var editMode      = #editMode ? 'true' : 'false'#;
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
    var preOrderRowId = parseInt(document.getElementById('h_order_row_id').value) || 0;

    $('##orderRowSelect').dxSelectBox({
        dataSource    : orderRowsData,
        valueExpr     : 'order_row_id',
        displayExpr   : 'display',
        searchEnabled : true,
        searchExpr    : ['order_number', 'company_name', 'color_code', 'color_name', 'product_name'],
        placeholder   : 'Sipariş satırı ara... (sipariş no, renk, ürün)',
        showClearButton: true,
        value         : preOrderRowId > 0 ? preOrderRowId : null,
        onValueChanged: function(e) {
            var badge = document.getElementById('orderRowBadge');
            if (e.value) {
                var row = orderRowsData.find(function(r) { return r.order_row_id == e.value; });
                if (row) {
                    document.getElementById('h_order_row_id').value = row.order_row_id;
                    document.getElementById('h_order_id').value     = row.order_id;
                    /* Renk kartını otomatik seç */
                    if (row.stock_id) {
                        $('##colorSelect').dxSelectBox('instance').option('value', row.stock_id);
                        loadRecipePreview(row.stock_id);
                    }
                    /* Miktar otomatik doldur */
                    if (row.quantity > 0) document.getElementById('f_quantity').value = row.quantity;
                    /* Lot no otomatik doldur */
                    if (row.lot_no) document.getElementById('f_lot_no').value = row.lot_no;
                    /* Badge */
                    var info = (row.company_name ? '<i class="fas fa-building me-1"></i>' + row.company_name + ' &nbsp;' : '')
                             + (row.order_number ? '<i class="fas fa-file-alt me-1"></i>' + row.order_number + ' &nbsp;' : '')
                             + (row.color_code   ? '<i class="fas fa-palette me-1"></i>' + row.color_code + (row.color_name ? ' — ' + row.color_name : '') : '');
                    badge.style.display = 'block';
                    badge.innerHTML = '<span style="background:##dbeafe;color:##1d4ed8;border-radius:6px;padding:.2rem .75rem;font-size:.8rem;font-weight:600;">' + info + '</span>';
                }
            } else {
                badge.style.display = 'none';
                document.getElementById('h_order_row_id').value = 0;
                document.getElementById('h_order_id').value     = 0;
            }
        }
    });

    /* Edit modunda sipariş satırı zaten seçiliyse badge göster */
    if (preOrderRowId > 0) {
        var preRow = orderRowsData.find(function(r) { return r.order_row_id == preOrderRowId; });
        if (preRow) {
            var badge = document.getElementById('orderRowBadge');
            var info = (preRow.company_name ? '<i class="fas fa-building me-1"></i>' + preRow.company_name + ' &nbsp;' : '')
                     + (preRow.order_number ? '<i class="fas fa-file-alt me-1"></i>' + preRow.order_number + ' &nbsp;' : '')
                     + (preRow.color_code   ? '<i class="fas fa-palette me-1"></i>' + preRow.color_code + (preRow.color_name ? ' — ' + preRow.color_name : '') : '');
            badge.style.display = 'block';
            badge.innerHTML = '<span style="background:##dbeafe;color:##1d4ed8;border-radius:6px;padding:.2rem .75rem;font-size:.8rem;font-weight:600;">' + info + '</span>';
        }
    }

    $('##colorSelect').dxSelectBox({
        dataSource    : colorsData,
        valueExpr     : 'stock_id',
        displayExpr   : 'display',
        searchEnabled : true,
        searchExpr    : ['color_code','color_name','company_name','stock_code'],
        placeholder   : 'Renk ara...',
        value         : <cfif editMode AND isNumeric(getRec.stock_id) AND val(getRec.stock_id) gt 0>#val(getRec.stock_id)#<cfelse>null</cfif>,
        onValueChanged: function(e) { if (e.value) loadRecipePreview(e.value); else $('##recipePreview').html('<div class="apo-recipe-empty"><i class="fas fa-flask fa-2x mb-1 d-block opacity-25"></i>Renk seçince reçete görünür.</div>'); }
    });

    $('##stationSelect').dxSelectBox({
        dataSource    : stationsData,
        valueExpr     : 'station_id',
        displayExpr   : 'station_name',
        searchEnabled : true,
        placeholder   : 'Makina seçin...',
        value         : <cfif editMode AND isNumeric(getRec.station_id) AND val(getRec.station_id) gt 0>#val(getRec.station_id)#<cfelse>null</cfif>
    });

    $('##statusSelect').dxSelectBox({
        dataSource  : statusData,
        valueExpr   : 'id',
        displayExpr : 'label',
        value       : <cfif editMode AND isNumeric(getRec.status) AND val(getRec.status) gt 0>#val(getRec.status)#<cfelse>1</cfif>
    });

    <cfif editMode AND isNumeric(getRec.stock_id) AND val(getRec.stock_id) gt 0>
    loadRecipePreview(#val(getRec.stock_id)#);
    </cfif>
}

function loadRecipePreview(stockId) {
    $('##recipePreview').html('<div class="apo-recipe-empty"><i class="fas fa-spinner fa-spin"></i></div>');
    $.get('/colors/api/get_recipe.cfm', { stock_id: stockId }, function(res) {
        if (!res || !res.length) {
            $('##recipePreview').html('<div class="apo-recipe-empty"><i class="fas fa-flask fa-2x mb-1 d-block opacity-25"></i>Bu renk için reçete bulunamadı.</div>');
            return;
        }

        var ops         = res.filter(function(r) { return r.is_operation == 1; });
        var ingredients = res.filter(function(r) { return r.is_operation == 0; });
        var html        = '';

        function renderItem(c) {
            return '<div class="apo-recipe-row">'
                + '<span class="apo-recipe-name">'
                + (c.stock_code ? '<strong style="color:var(--primary,##1a3a5c);margin-right:4px">' + c.stock_code + '</strong>' : '')
                + (c.product_name || '')
                + '</span>'
                + '<span class="apo-recipe-amt"><strong>' + c.amount + '</strong></span>'
                + '</div>';
        }

        if (ops.length) {
            var opTreeIds = ops.map(function(o) { return o.product_tree_id; });
            ops.forEach(function(op) {
                var children = ingredients.filter(function(c) { return c.related_product_tree_id == op.product_tree_id; });
                if (!children.length) return;
                html += '<div class="apo-recipe-group">';
                html += '<div class="apo-op-title"><i class="fas fa-cog me-1"></i>' + (op.product_name || 'Operasyon') + '</div>';
                children.forEach(function(c) { html += renderItem(c); });
                html += '</div>';
            });
            // Items not linked to any operation
            var standalone = ingredients.filter(function(c) {
                return !c.related_product_tree_id || opTreeIds.indexOf(c.related_product_tree_id) === -1;
            });
            if (standalone.length) {
                html += '<div class="apo-recipe-group">';
                html += '<div class="apo-op-title"><i class="fas fa-list me-1"></i>Diğer Maddeler</div>';
                standalone.forEach(function(c) { html += renderItem(c); });
                html += '</div>';
            }
        } else {
            // No operations, flat list
            ingredients.forEach(function(c) { html += renderItem(c); });
        }

        $('##recipePreview').html(html || '<div class="apo-recipe-empty"><i class="fas fa-flask fa-2x mb-1 d-block opacity-25"></i>Bu renk için reçete bulunamadı.</div>');
    }, 'json').fail(function() {
        $('##recipePreview').html('<div class="apo-recipe-empty" style="color:##e74c3c"><i class="fas fa-exclamation-circle me-1"></i>Reçete yüklenemedi.</div>');
    });
}

function deleteOrder() {
    if (!confirm('Bu üretim emrini silmek istediğinizden emin misiniz?')) return;
    var btn = document.getElementById('btnDelete');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
    $.post('/production/form/delete_production_order.cfm', {
        p_order_id: document.getElementById('h_p_order_id').value
    }, function(res) {
        if (res && res.success) {
            window.location.href = 'index.cfm?fuseaction=production.list_production_orders&success=deleted';
        } else {
            DevExpress.ui.notify((res && res.message) || 'Silme başarısız.', 'error', 3500);
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-trash"></i> Sil';
        }
    }, 'json').fail(function() {
        DevExpress.ui.notify('Sunucu hatası.', 'error', 3000);
        btn.disabled = false;
        btn.innerHTML = '<i class="fas fa-trash"></i> Sil';
    });
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
        order_id     : document.getElementById('h_order_id').value,
        order_row_id : document.getElementById('h_order_row_id').value,
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
