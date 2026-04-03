<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getMoney" datasource="boyahane">
    SELECT money_id, money, money_name, money_symbol, currency_code,
           rate1, rate2, rate3,
           dsp_rate_sale, dsp_rate_pur, effective_sale, effective_pur,
           dsp_effective_sale, dsp_effective_pur,
           money_status, dsp_update_date, record_date, update_date
    FROM setup_money
    ORDER BY money
</cfquery>

<cfset moneyArr = []>
<cfloop query="getMoney">
    <cfset arrayAppend(moneyArr, {
        "money_id":          money_id,
        "money":             money ?: "",
        "money_name":        money_name ?: "",
        "money_symbol":      money_symbol ?: "",
        "currency_code":     currency_code ?: "",
        "rate1":             isNumeric(rate1) ? rate1 : 0,
        "rate2":             isNumeric(rate2) ? rate2 : 0,
        "rate3":             isNumeric(rate3) ? rate3 : 0,
        "dsp_rate_sale":     isNumeric(dsp_rate_sale) ? dsp_rate_sale : 0,
        "dsp_rate_pur":      isNumeric(dsp_rate_pur) ? dsp_rate_pur : 0,
        "effective_sale":    isNumeric(effective_sale) ? effective_sale : 0,
        "effective_pur":     isNumeric(effective_pur) ? effective_pur : 0,
        "money_status":      money_status,
        "dsp_update_date":   isDate(dsp_update_date) ? dateFormat(dsp_update_date, "dd/mm/yyyy") & " " & timeFormat(dsp_update_date, "HH:mm") : "",
        "record_date":       isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-coins"></i></div>
        <div class="page-header-title">
            <h1>Para Birimleri</h1>
            <p>Döviz kurları ve para birimi tanımları</p>
        </div>
    </div>
    <div class="d-flex gap-2">
  
        <a href="/index.cfm?fuseaction=money.list_money_history" class="btn btn-outline-secondary btn-sm">
            <i class="fas fa-history me-1"></i>Kur Geçmişi
        </a>
        <button class="btn-add" onclick="addMoney()">
            <i class="fas fa-plus"></i>Yeni Para Birimi
        </button>
    </div>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Para birimi eklendi.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Para birimi güncellendi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Para Birimi Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="moneyGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var moneyData = #serializeJSON(moneyArr)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $("##moneyGrid").dxDataGrid({
            dataSource: moneyData,
            showBorders: true,
            showRowLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            paging: { pageSize: 25 },
            pager: { visible: true, allowedPageSizes: [10,25,50], showPageSizeSelector: true, showInfo: true, infoText: 'Sayfa {0}/{1} ({2} kayıt)' },
            filterRow: { visible: true },
            searchPanel: { visible: true, width: 200, placeholder: 'Ara...' },
            export: { enabled: true, fileName: 'para_birimleri' },
            columns: [
                { dataField: 'money_id', caption: 'ID', width: 60, alignment: 'center', dataType: 'number', sortOrder: 'asc' },
                { dataField: 'money', caption: 'Kod', width: 80, alignment: 'center',
                    cellTemplate: function(c, o) {
                        $('<strong>').css('font-size','15px').text(o.value || '-').appendTo(c);
                    }
                },
                { dataField: 'money_symbol', caption: 'Sembol', width: 70, alignment: 'center' },
                { dataField: 'money_name', caption: 'Para Birimi Adı', minWidth: 150 },
                { dataField: 'rate1', caption: 'Alış', width: 120, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'rate2', caption: 'Satış', width: 120, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'rate3', caption: 'Ortalama', width: 120, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'effective_sale', caption: 'Efk. Satış', width: 120, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'effective_pur', caption: 'Efk. Alış', width: 120, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'dsp_update_date', caption: 'Son Güncelleme', width: 150, alignment: 'center', dataType: 'string' },
                { dataField: 'money_status', caption: 'Durum', width: 90, alignment: 'center',
                    cellTemplate: function(c, o) {
                        $('<span>').addClass(o.value ? 'badge bg-success' : 'badge bg-danger')
                            .text(o.value ? 'Aktif' : 'Pasif').appendTo(c);
                    }
                },
                {
                    caption: 'İşlemler', width: 130, alignment: 'center',
                    allowFiltering: false, allowSorting: false,
                    cellTemplate: function(container, options) {
                        var g = $('<div>').css({ display:'flex', gap:'5px', justifyContent:'center' });
                        $('<button>').addClass('grid-btn grid-btn-edit').attr('title','Düzenle').html('<i class="fas fa-edit"></i>')
                            .on('click', function() { editMoney(options.data.money_id); }).appendTo(g);
                        $('<button>').addClass('grid-btn grid-btn-del').attr('title','Sil').html('<i class="fas fa-trash"></i>')
                            .on('click', function() { deleteMoney(options.data.money_id, options.data.money); }).appendTo(g);
                        g.appendTo(container);
                    }
                }
            ],
            onContentReady: function(e) { $('##recordCount').text(e.component.totalCount() + ' kayıt'); }
        });
    }
});

function addMoney() {
    window.location.href = '/index.cfm?fuseaction=money.add_money';
}
function editMoney(id) {
    window.location.href = '/index.cfm?fuseaction=money.edit_money&id=' + id;
}
function deleteMoney(id, name) {
    DevExpress.ui.dialog.confirm('"' + (name || id) + '" para birimini silmek istediğinizden emin misiniz?', 'Silme Onayı')
        .then(function(ok) {
            if (!ok) return;
            $.ajax({
                url: '/money/cfc/money.cfc?method=deleteMoney',
                method: 'POST', data: { id: id }, dataType: 'json',
                success: function(r) {
                    if (r.success) {
                        DevExpress.ui.notify('Para birimi silindi', 'success', 2000);
                        moneyData = moneyData.filter(function(x) { return x.money_id != id; });
                        $('##moneyGrid').dxDataGrid('instance').option('dataSource', moneyData);
                    } else {
                        DevExpress.ui.notify(r.message || 'Hata oluştu!', 'error', 3000);
                    }
                },
                error: function() { DevExpress.ui.notify('Silme işlemi başarısız!', 'error', 3000); }
            });
        });
}
</script>
</cfoutput>
