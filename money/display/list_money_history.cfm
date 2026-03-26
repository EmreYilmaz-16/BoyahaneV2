<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getHistory" datasource="boyahane">
    SELECT money_history_id, money, rate1, rate2, rate3,
           effective_sale, effective_pur,
           validate_date, validate_hour, record_date
    FROM money_history
    ORDER BY money_history_id DESC
    LIMIT 1000
</cfquery>

<cfset histArr = []>
<cfloop query="getHistory">
    <cfset arrayAppend(histArr, {
        "money_history_id": money_history_id,
        "money":            money ?: "",
        "rate1":            isNumeric(rate1) ? rate1 : 0,
        "rate2":            isNumeric(rate2) ? rate2 : 0,
        "rate3":            isNumeric(rate3) ? rate3 : 0,
        "effective_sale":   isNumeric(effective_sale) ? effective_sale : 0,
        "effective_pur":    isNumeric(effective_pur) ? effective_pur : 0,
        "validate_date":    isDate(validate_date) ? dateFormat(validate_date, "dd/mm/yyyy") : "",
        "validate_hour":    validate_hour ?: "",
        "record_date":      isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-history"></i></div>
        <div class="page-header-title">
            <h1>Kur Geçmişi</h1>
            <p>Döviz kuru geçmiş kayıtları</p>
        </div>
    </div>
    <div class="d-flex gap-2 align-items-center">
        <a href="/index.cfm?fuseaction=money.list_money" class="btn btn-outline-secondary btn-sm">
            <i class="fas fa-coins me-1"></i>Para Birimleri
        </a>
        <button class="btn btn-warning btn-sm fw-semibold" id="btnTcmb" onclick="fetchTcmbRates()">
            <i class="fas fa-sync-alt me-1"></i>TCMB'den Güncelle
        </button>
    </div>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
            <i class="fas fa-check-circle me-2"></i>
            <strong>Başarılı!</strong> Kur bilgileri TCMB'den güncellendi.
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <!--- TCMB sonuç paneli --->
    <div id="tcmbResult" class="mb-3" style="display:none"></div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Kur Geçmişi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="histGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var histData = #serializeJSON(histArr)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $("##histGrid").dxDataGrid({
            dataSource: histData,
            showBorders: true,
            showRowLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            paging: { pageSize: 50 },
            pager: { visible: true, allowedPageSizes: [25,50,100], showPageSizeSelector: true, showInfo: true, infoText: 'Sayfa {0}/{1} ({2} kayıt)' },
            filterRow: { visible: true },
            searchPanel: { visible: true, width: 200, placeholder: 'Ara...' },
            export: { enabled: true, fileName: 'kur_gecmisi' },
            columns: [
                { dataField: 'money_history_id', caption: 'ID', width: 70, alignment: 'center', dataType: 'number', sortOrder: 'desc' },
                { dataField: 'money', caption: 'Döviz', width: 90, alignment: 'center',
                    cellTemplate: function(c, o) { $('<strong>').text(o.value || '-').appendTo(c); }
                },
                { dataField: 'validate_date', caption: 'Geç. Tarihi', width: 120, alignment: 'center' },
                { dataField: 'validate_hour', caption: 'Saat', width: 90, alignment: 'center' },
                { dataField: 'rate1', caption: 'Alış Kuru', width: 130, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'rate2', caption: 'Satış Kuru', width: 130, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'rate3', caption: 'Ortalama', width: 130, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'effective_sale', caption: 'Efk. Satış', width: 130, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'effective_pur', caption: 'Efk. Alış', width: 130, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'record_date', caption: 'Kayıt Tarihi', width: 150, alignment: 'center', dataType: 'string' },
                {
                    caption: 'İşlem', width: 80, alignment: 'center',
                    allowFiltering: false, allowSorting: false,
                    cellTemplate: function(container, options) {
                        $('<button>').addClass('grid-btn grid-btn-del').attr('title','Sil').html('<i class="fas fa-trash"></i>')
                            .on('click', function() { deleteHistory(options.data.money_history_id); })
                            .appendTo(container);
                    }
                }
            ],
            onContentReady: function(e) { $('##recordCount').text(e.component.totalCount() + ' kayıt'); }
        });
    }
});

function deleteHistory(id) {
    DevExpress.ui.dialog.confirm('Bu kur geçmişi kaydını silmek istediğinizden emin misiniz?', 'Silme Onayı')
        .then(function(ok) {
            if (!ok) return;
            $.ajax({
                url: '/money/cfc/money.cfc?method=deleteMoneyHistory',
                method: 'POST', data: { id: id }, dataType: 'json',
                success: function(r) {
                    if (r.success) {
                        DevExpress.ui.notify('Kayıt silindi', 'success', 2000);
                        histData = histData.filter(function(x) { return x.money_history_id != id; });
                        $('##histGrid').dxDataGrid('instance').option('dataSource', histData);
                    } else {
                        DevExpress.ui.notify(r.message || 'Hata!', 'error', 3000);
                    }
                }
            });
        });
}

function fetchTcmbRates() {
    var btn = document.getElementById('btnTcmb');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Güncelleniyor...';

    $.ajax({
        url: '/money/form/fetch_tcmb.cfm',
        method: 'POST',
        dataType: 'json',
        timeout: 30000,
        success: function(r) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-sync-alt me-1"></i>TCMB\'den Güncelle';
            var panel = $('##tcmbResult');
            if (r.success) {
                var html = '<div class="alert alert-success alert-dismissible fade show">';
                html += '<i class="fas fa-check-circle me-2"></i>';
                html += '<strong>' + r.message + '</strong>';
                if (r.updated && r.updated.length > 0) {
                    html += '<ul class="mb-0 mt-2">';
                    for (var i = 0; i < r.updated.length; i++) {
                        var u = r.updated[i];
                        html += '<li><strong>' + u.money + '</strong> → Alış: ' + parseFloat(u.rate1).toFixed(4) + ' / Satış: ' + parseFloat(u.rate2).toFixed(4) + '</li>';
                    }
                    html += '</ul>';
                }
                html += '<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>';
                panel.html(html).show();
                // Gridin güncellenmesi için sayfayı yenile
                setTimeout(function() { location.reload(); }, 3000);
            } else {
                var errHtml = '<div class="alert alert-danger alert-dismissible fade show">';
                errHtml += '<i class="fas fa-exclamation-circle me-2"></i>';
                errHtml += r.message || 'TCMB verisi alınamadı!';
                errHtml += '<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>';
                panel.html(errHtml).show();
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-sync-alt me-1"></i>TCMB\'den Güncelle';
            var errHtml = '<div class="alert alert-danger alert-dismissible fade show">';
            errHtml += '<i class="fas fa-exclamation-circle me-2"></i>Sunucuya bağlanılamadı!';
            errHtml += '<button type="button" class="btn-close" data-bs-dismiss="alert"></button></div>';
            $('##tcmbResult').html(errHtml).show();
        }
    });
}
</script>
</cfoutput>
