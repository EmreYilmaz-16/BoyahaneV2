<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getOrders" datasource="boyahane">
    SELECT
        o.order_id, o.order_number, o.order_head, o.order_date, 
        o.purchase_sales, o.order_status, o.order_stage,
        o.deliverdate, o.ship_date, o.due_date,
        o.grosstotal, o.discounttotal, o.taxtotal, o.nettotal,
        o.ref_no, o.order_detail,
        o.is_paid, o.is_dispatch, o.is_processed,
        o.cancel_type_id, o.cancel_date,
        o.record_date, o.record_emp,
        COALESCE(c.nickname, c.fullname, '') AS company_name,
        COALESCE(sm.money_name, 'TRY') AS currency_name,
        COALESCE((SELECT COUNT(*) FROM order_row orw WHERE orw.order_id = o.order_id), 0) AS row_count
    FROM orders o
    LEFT JOIN company c ON o.company_id = c.company_id
    LEFT JOIN setup_money sm ON o.order_currency = sm.money_id
    ORDER BY o.order_id DESC
    LIMIT 500
</cfquery>

<cfset orderArr = []>
<cfloop query="getOrders">
    <cfset statusLabel = "">
    <cfif order_status><cfset statusLabel = "Aktif">
    <cfelse><cfset statusLabel = "Pasif">
    </cfif>
    
    <cfset typeLabel = "">
    <cfif purchase_sales><cfset typeLabel = "Satış">
    <cfelse><cfset typeLabel = "Alış">
    </cfif>
    
    <cfset stageLabel = "">
    <cfif order_stage eq 1><cfset stageLabel = "Beklemede">
    <cfelseif order_stage eq 2><cfset stageLabel = "Onaylandı">
    <cfelseif order_stage eq 3><cfset stageLabel = "Üretimde">
    <cfelseif order_stage eq 4><cfset stageLabel = "Hazır">
    <cfelseif order_stage eq 5><cfset stageLabel = "Sevk Edildi">
    <cfelseif order_stage eq 6><cfset stageLabel = "Tamamlandı">
    <cfelse><cfset stageLabel = "Yeni">
    </cfif>
    
    <cfset arrayAppend(orderArr, {
        "order_id":        order_id,
        "order_number":    order_number ?: "",
        "order_head":      order_head ?: "",
        "order_date":      isDate(order_date)   ? dateFormat(order_date,   "dd/mm/yyyy") & " " & timeFormat(order_date,   "HH:mm") : "",
        "deliverdate":     isDate(deliverdate)  ? dateFormat(deliverdate,  "dd/mm/yyyy") : "",
        "ship_date":       isDate(ship_date)    ? dateFormat(ship_date,    "dd/mm/yyyy") : "",
        "due_date":        isDate(due_date)     ? dateFormat(due_date,     "dd/mm/yyyy") : "",
        "purchase_sales":  purchase_sales,
        "type_label":      typeLabel,
        "order_status":    order_status ?: 0,
        "status_label":    statusLabel,
        "order_stage":     order_stage ?: 0,
        "stage_label":     stageLabel,
        "grosstotal":      isNumeric(grosstotal)    ? grosstotal    : 0,
        "discounttotal":   isNumeric(discounttotal) ? discounttotal : 0,
        "taxtotal":        isNumeric(taxtotal)      ? taxtotal      : 0,
        "nettotal":        isNumeric(nettotal)      ? nettotal      : 0,
        "company_name":    company_name ?: "",
        "currency_name":   currency_name ?: "TRY",
        "ref_no":          ref_no ?: "",
        "is_paid":         is_paid,
        "is_dispatch":     is_dispatch,
        "is_processed":    is_processed,
        "is_cancelled":    isNumeric(cancel_type_id) AND cancel_type_id GT 0,
        "cancel_date":     isDate(cancel_date) ? dateFormat(cancel_date, "dd/mm/yyyy") : "",
        "row_count":       row_count,
        "record_date":     isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-shopping-cart"></i></div>
        <div class="page-header-title">
            <h1>Siparişler</h1>
            <p>Alış ve satış siparişleri</p>
        </div>
    </div>
    <div class="d-flex gap-2">
        <button class="btn btn-warning text-dark" onclick="openQuickSale()">
            <i class="fas fa-bolt"></i>Hızlı Satış
        </button>
        <button class="btn-add" onclick="addOrder()">
            <i class="fas fa-plus"></i>Yeni Sipariş
        </button>
    </div>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Sipariş oluşturuldu.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Sipariş güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Sipariş silindi.
            <cfelseif url.success eq "cancelled"><strong>Başarılı!</strong> Sipariş iptal edildi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <!--- Özet Kartlar --->
    <div class="row g-3 mb-3">
        <div class="col-md-2-4">
            <div class="summary-card summary-card-blue">
                <div class="summary-icon"><i class="fas fa-shopping-cart"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Sipariş</span>
                    <span class="summary-value" id="sumTotal">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-2-4">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-chart-line"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Satış</span>
                    <span class="summary-value" id="sumSales">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-2-4">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-shopping-bag"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Alış</span>
                    <span class="summary-value" id="sumPurchase">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-2-4">
            <div class="summary-card summary-card-purple">
                <div class="summary-icon"><i class="fas fa-money-check-alt"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Ödendi</span>
                    <span class="summary-value" id="sumPaid">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-2-4">
            <div class="summary-card summary-card-red">
                <div class="summary-icon"><i class="fas fa-ban"></i></div>
                <div class="summary-info">
                    <span class="summary-label">İptal</span>
                    <span class="summary-value" id="sumCancelled">-</span>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Sipariş Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="orderGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<style>
.col-md-2-4 { flex: 0 0 20%; max-width: 20%; }
@media (max-width: 991px) { .col-md-2-4 { flex: 0 0 50%; max-width: 50%; } }
@media (max-width: 575px) { .col-md-2-4 { flex: 0 0 100%; max-width: 100%; } }

.summary-card { display:flex; align-items:center; gap:14px; padding:16px 20px; border-radius:10px; color:##fff; box-shadow:0 2px 10px rgba(0,0,0,.12); }
.summary-card-blue   { background:linear-gradient(135deg,##1a3a5c,##2563ab); }
.summary-card-green  { background:linear-gradient(135deg,##15803d,##22c55e); }
.summary-card-orange { background:linear-gradient(135deg,##92400e,##f59e0b); }
.summary-card-purple { background:linear-gradient(135deg,##6b21a8,##a855f7); }
.summary-card-red    { background:linear-gradient(135deg,##991b1b,##ef4444); }
.summary-icon { font-size:1.8rem; opacity:.85; }
.summary-label { font-size:.75rem; opacity:.85; display:block; }
.summary-value { font-size:1.6rem; font-weight:700; display:block; }

.badge-type-sales { background:##22c55e; color:##fff; padding:4px 10px; border-radius:12px; font-size:.75rem; font-weight:600; }
.badge-type-purchase { background:##f59e0b; color:##fff; padding:4px 10px; border-radius:12px; font-size:.75rem; font-weight:600; }

.badge-stage-0 { background:##e5e7eb; color:##374151; padding:4px 10px; border-radius:12px; font-size:.75rem; }
.badge-stage-1 { background:##fbbf24; color:##fff; padding:4px 10px; border-radius:12px; font-size:.75rem; }
.badge-stage-2 { background:##3b82f6; color:##fff; padding:4px 10px; border-radius:12px; font-size:.75rem; }
.badge-stage-3 { background:##a855f7; color:##fff; padding:4px 10px; border-radius:12px; font-size:.75rem; }
.badge-stage-4 { background:##10b981; color:##fff; padding:4px 10px; border-radius:12px; font-size:.75rem; }
.badge-stage-5 { background:##06b6d4; color:##fff; padding:4px 10px; border-radius:12px; font-size:.75rem; }
.badge-stage-6 { background:##22c55e; color:##fff; padding:4px 10px; border-radius:12px; font-size:.75rem; }

.status-icon { font-size:.85rem; }
.status-paid { color:##22c55e; }
.status-unpaid { color:##ef4444; }
.status-dispatch { color:##3b82f6; }
.status-cancelled { color:##ef4444; }
</style>

<script>
var orderData = #serializeJSON(orderArr)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    // Özet Kartlar
    var sales = orderData.filter(function(r){ return r.purchase_sales; }).length;
    var purchase = orderData.filter(function(r){ return !r.purchase_sales; }).length;
    var paid = orderData.filter(function(r){ return r.is_paid; }).length;
    var cancelled = orderData.filter(function(r){ return r.is_cancelled; }).length;
    
    document.getElementById('sumTotal').textContent = orderData.length;
    document.getElementById('sumSales').textContent = sales;
    document.getElementById('sumPurchase').textContent = purchase;
    document.getElementById('sumPaid').textContent = paid;
    document.getElementById('sumCancelled').textContent = cancelled;

    // DevExtreme DataGrid
    var grid = new DevExpress.ui.dxDataGrid(document.getElementById('orderGrid'), {
        dataSource: orderData,
        showBorders: true,
        showRowLines: true,
        showColumnLines: true,
        rowAlternationEnabled: true,
        hoverStateEnabled: true,
        columnAutoWidth: true,
        allowColumnReordering: true,
        allowColumnResizing: true,
        columnResizingMode: 'widget',
        wordWrapEnabled: false,
        
        sorting: { mode: 'multiple' },
        filterRow: { visible: true },
        headerFilter: { visible: true },
        searchPanel: { visible: true, width: 240, placeholder: 'Ara...' },
        groupPanel: { visible: true },
        export: {
            enabled: true,
            fileName: 'Siparisler',
            allowExportSelectedData: true
        },
        
        paging: { pageSize: 25 },
        pager: {
            visible: true,
            allowedPageSizes: [10, 25, 50, 100],
            showPageSizeSelector: true,
            showInfo: true,
            showNavigationButtons: true
        },
        
        selection: {
            mode: 'multiple',
            showCheckBoxesMode: 'onClick'
        },
        
        columns: [
            { 
                dataField: 'order_id', 
                caption: 'ID', 
                width: 70, 
                alignment: 'center',
                dataType: 'number'
            },
            { 
                dataField: 'order_number', 
                caption: 'Sipariş No', 
                width: 150,
                cellTemplate: function(container, options) {
                    var html = '<div style="font-weight:600;color:##2563ab;">' + options.value + '</div>';
                    container.innerHTML = html;
                }
            },
            { 
                dataField: 'order_date', 
                caption: 'Sipariş Tarihi', 
                width: 140,
                dataType: 'string'
            },
            { 
                dataField: 'type_label', 
                caption: 'Tip', 
                width: 90,
                alignment: 'center',
                cellTemplate: function(container, options) {
                    var cssClass = options.data.purchase_sales ? 'badge-type-sales' : 'badge-type-purchase';
                    container.innerHTML = '<span class="' + cssClass + '">' + options.value + '</span>';
                }
            },
            { 
                dataField: 'stage_label', 
                caption: 'Aşama', 
                width: 130,
                alignment: 'center',
                cellTemplate: function(container, options) {
                    var cssClass = 'badge-stage-' + options.data.order_stage;
                    container.innerHTML = '<span class="' + cssClass + '">' + options.value + '</span>';
                }
            },
            { 
                dataField: 'company_name', 
                caption: 'Firma', 
                width: 200
            },
            { 
                dataField: 'order_head', 
                caption: 'Başlık', 
                width: 200
            },
            { 
                dataField: 'row_count', 
                caption: 'Satır', 
                width: 70, 
                alignment: 'center',
                dataType: 'number'
            },
            { 
                dataField: 'nettotal', 
                caption: 'Net Tutar', 
                width: 130,
                dataType: 'number',
                format: { type: 'fixedPoint', precision: 2 },
                alignment: 'right',
                cellTemplate: function(container, options) {
                    var formatted = options.value.toLocaleString('tr-TR', {minimumFractionDigits:2, maximumFractionDigits:2});
                    var currency = options.data.currency_name || 'TRY';
                    container.innerHTML = '<div style="font-weight:600;">' + formatted + ' <small style="opacity:0.7;">' + currency + '</small></div>';
                }
            },
            { 
                dataField: 'deliverdate', 
                caption: 'Teslim Tarihi', 
                width: 110,
                dataType: 'string'
            },
            {
                caption: 'Durum',
                width: 120,
                alignment: 'center',
                allowFiltering: false,
                allowSorting: false,
                cellTemplate: function(container, options) {
                    var icons = [];
                    if (options.data.is_paid) {
                        icons.push('<i class="fas fa-check-circle status-icon status-paid" title="Ödendi"></i>');
                    }
                    if (options.data.is_dispatch) {
                        icons.push('<i class="fas fa-truck status-icon status-dispatch" title="Sevk Edildi"></i>');
                    }
                    if (options.data.is_cancelled) {
                        icons.push('<i class="fas fa-ban status-icon status-cancelled" title="İptal"></i>');
                    }
                    if (!options.data.order_status) {
                        icons.push('<i class="fas fa-pause-circle status-icon status-unpaid" title="Pasif"></i>');
                    }
                    container.innerHTML = '<div style="display:flex;gap:8px;justify-content:center;">' + icons.join('') + '</div>';
                }
            },
            { 
                dataField: 'ref_no', 
                caption: 'Ref No', 
                width: 120,
                visible: false
            },
            { 
                dataField: 'record_date', 
                caption: 'Kayıt Tarihi', 
                width: 140,
                visible: false
            },
            {
                caption: 'İşlemler',
                width: 220,
                alignment: 'center',
                allowFiltering: false,
                allowSorting: false,
                allowExporting: false,
                cellTemplate: function(container, options) {
                    var $wrap = $('<div>').css({display:'flex', gap:'4px', justifyContent:'center'});
                    $('<button>').addClass('btn btn-sm btn-info').attr('title','Görüntüle')
                        .html('<i class="fas fa-eye"></i>')
                        .on('click', function(){ viewOrder(options.data.order_id); })
                        .appendTo($wrap);
                    $('<button>').addClass('btn btn-sm btn-warning').attr('title','Düzenle')
                        .html('<i class="fas fa-edit"></i>')
                        .on('click', function(){ editOrder(options.data.order_id); })
                        .appendTo($wrap);
                    if (!options.data.is_cancelled) {
                        $('<button>').addClass('btn btn-sm btn-danger').attr('title','İptal')
                            .html('<i class="fas fa-ban"></i>')
                            .on('click', function(){ cancelOrder(options.data.order_id); })
                            .appendTo($wrap);
                    }
                    if (!options.data.is_cancelled) {
                        $('<button>').addClass('btn btn-sm btn-success btn-send-prod').attr('title','Üretime Gönder')
                            .html('<i class="fas fa-industry"></i>')
                            .on('click', function(){ sendToProduction(options.data.order_id); })
                            .appendTo($wrap);
                    }
                    $wrap.appendTo(container);
                }
            }
        ],
        
        onContentReady: function(e) {
            var totalCount = e.component.totalCount();
            document.getElementById('recordCount').textContent = totalCount + ' kayıt';
        }
    });
});

function addOrder() {
    window.location.href = 'index.cfm?fuseaction=order.add_order';
}

function openQuickSale() {
    window.location.href = 'index.cfm?fuseaction=order.quick_sale';
}

function viewOrder(orderId) {
    window.location.href = 'index.cfm?fuseaction=order.view_order&order_id=' + orderId;
}

function editOrder(orderId) {
    window.location.href = 'index.cfm?fuseaction=order.edit_order&order_id=' + orderId;
}

function cancelOrder(orderId) {
    if (confirm('Bu siparişi iptal etmek istediğinizden emin misiniz?')) {
        window.location.href = 'index.cfm?fuseaction=order.cancel_order&order_id=' + orderId;
    }
}

function sendToProduction(orderId) {
    if (!confirm('Bu siparişin tüm satırları için üretim emri oluşturulacak. Devam etmek istiyor musunuz?')) return;
    $.ajax({
        url: '/production/form/send_order_to_production.cfm',
        type: 'POST',
        data: { order_id: orderId },
        dataType: 'json',
        success: function(res) {
            if (res.success) {
                DevExpress.ui.notify({ message: res.message, width: 400 }, 'success', 4000);
            } else {
                DevExpress.ui.notify({ message: res.message || 'Hata oluştu.', width: 400 }, 'error', 4000);
            }
        },
        error: function() {
            DevExpress.ui.notify({ message: 'Sunucu hatası oluştu.', width: 400 }, 'error', 4000);
        }
    });
}
</script>
</cfoutput>
