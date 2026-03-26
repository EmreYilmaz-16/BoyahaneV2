<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getCredits" datasource="boyahane">
    SELECT cc.company_credit_id, cc.company_id, cc.process_stage,
           COALESCE(c.nickname, c.fullname, c.member_code, CAST(c.company_id AS VARCHAR)) AS company_name,
           cc.open_account_risk_limit, cc.forward_sale_limit, cc.total_risk_limit,
           cc.money, cc.due_datex, cc.is_blacklist, cc.blacklist_date,
           pm.paymethod, sm.ship_method,
           cc.record_date, cc.update_date
    FROM company_credit cc
    LEFT JOIN company c        ON cc.company_id    = c.company_id
    LEFT JOIN setup_paymethod pm ON cc.paymethod_id  = pm.paymethod_id
    LEFT JOIN ship_method sm   ON cc.ship_method_id = sm.ship_method_id
    ORDER BY cc.company_credit_id DESC
</cfquery>

<cfset ccArray = []>
<cfloop query="getCredits">
    <cfset arrayAppend(ccArray, {
        "company_credit_id":        company_credit_id,
        "company_id":               company_id,
        "company_name":             company_name ?: "",
        "process_stage":            isNumeric(process_stage) ? process_stage : "",
        "open_account_risk_limit":  isNumeric(open_account_risk_limit) ? open_account_risk_limit : 0,
        "forward_sale_limit":       isNumeric(forward_sale_limit) ? forward_sale_limit : 0,
        "total_risk_limit":         isNumeric(total_risk_limit) ? total_risk_limit : 0,
        "money":                    money ?: "",
        "due_datex":                isNumeric(due_datex) ? due_datex : "",
        "paymethod":                paymethod ?: "",
        "ship_method":              ship_method ?: "",
        "is_blacklist":             is_blacklist,
        "blacklist_date":           isDate(blacklist_date) ? dateFormat(blacklist_date, "dd/mm/yyyy") : "",
        "record_date":              isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : "",
        "update_date":              isDate(update_date) ? dateFormat(update_date, "dd/mm/yyyy") & " " & timeFormat(update_date, "HH:mm") : ""
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-shield-alt"></i></div>
        <div class="page-header-title">
            <h1>Firma Kredi & Risk Limitleri</h1>
            <p>Firma bazında kredi ve risk limit bilgilerini yönetin</p>
        </div>
    </div>
    <button class="btn-add" onclick="addCredit()">
        <i class="fas fa-plus"></i>Yeni Kredi Kaydı
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3" role="alert">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Kredi kaydı eklendi.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Kredi kaydı güncellendi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Kredi Kayıtları</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="ccGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var ccData = #serializeJSON(ccArray)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $("##ccGrid").dxDataGrid({
            dataSource: ccData,
            showBorders: true,
            showRowLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            paging: { pageSize: 25 },
            pager: { visible: true, allowedPageSizes: [10,25,50], showPageSizeSelector: true, showInfo: true, infoText: 'Sayfa {0}/{1} ({2} kayıt)' },
            filterRow: { visible: true },
            searchPanel: { visible: true, width: 200, placeholder: 'Ara...' },
            export: { enabled: true, fileName: 'firma_kredi_limitleri' },
            columns: [
                { dataField: 'company_credit_id', caption: 'ID', width: 70, alignment: 'center', dataType: 'number' },
                { dataField: 'company_name', caption: 'Firma', minWidth: 180,
                    cellTemplate: function(c, o) { $('<strong>').text(o.value || '-').appendTo(c); }
                },
                { dataField: 'open_account_risk_limit', caption: 'Açık Hesap Limiti', width: 150, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 2 } },
                { dataField: 'forward_sale_limit',       caption: 'Vadeli Satış Limiti', width: 150, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 2 } },
                { dataField: 'total_risk_limit',         caption: 'Toplam Risk Limiti', width: 150, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 2 } },
                { dataField: 'money',      caption: 'Para Birimi', width: 100, alignment: 'center' },
                { dataField: 'due_datex',  caption: 'Vade (Gün)', width: 100, alignment: 'center' },
                { dataField: 'paymethod',  caption: 'Ödeme Yöntemi', width: 150 },
                { dataField: 'ship_method', caption: 'Sevkiyat', width: 130 },
                { dataField: 'is_blacklist', caption: 'Kara Liste', width: 100, alignment: 'center',
                    cellTemplate: function(c, o) {
                        if (o.value) {
                            $('<span>').addClass('badge bg-danger').html('<i class="fas fa-ban me-1"></i>Kara Liste').appendTo(c);
                        } else {
                            $('<span>').addClass('badge bg-secondary').text('Hayır').appendTo(c);
                        }
                    }
                },
                { dataField: 'record_date', caption: 'Kayıt Tarihi', width: 140, alignment: 'center', dataType: 'string' },
                {
                    caption: 'İşlemler', width: 130, alignment: 'center',
                    allowFiltering: false, allowSorting: false,
                    cellTemplate: function(container, options) {
                        var btnGroup = $('<div>').css({ display:'flex', gap:'5px', justifyContent:'center' });
                        $('<button>').addClass('grid-btn grid-btn-edit').attr('title','Düzenle').html('<i class="fas fa-edit"></i>')
                            .on('click', function() { editCredit(options.data.company_credit_id); }).appendTo(btnGroup);
                        $('<button>').addClass('grid-btn grid-btn-del').attr('title','Sil').html('<i class="fas fa-trash"></i>')
                            .on('click', function() { deleteCredit(options.data.company_credit_id, options.data.company_name); }).appendTo(btnGroup);
                        btnGroup.appendTo(container);
                    }
                }
            ],
            onContentReady: function(e) { $('##recordCount').text(e.component.totalCount() + ' kayıt'); }
        });
    }
});

function addCredit() {
    window.location.href = '/index.cfm?fuseaction=company.add_company_credit';
}
function editCredit(id) {
    window.location.href = '/index.cfm?fuseaction=company.edit_company_credit&id=' + id;
}
function deleteCredit(id, name) {
    if (typeof DevExpress !== 'undefined' && DevExpress.ui && DevExpress.ui.dialog) {
        DevExpress.ui.dialog.confirm('"' + name + '" firmasının kredi kaydını silmek istediğinizden emin misiniz?', 'Kredi Kaydı Sil')
        .done(function(res) {
            if (!res) return;
            $.ajax({
                url: '/company/cfc/company.cfc?method=deleteCompanyCredit',
                method: 'POST', data: { id: id }, dataType: 'json',
                success: function(r) {
                    DevExpress.ui.notify({ message: r.message, type: r.success ? 'success' : 'error', displayTime: 3500 });
                    if (r.success) setTimeout(function() { location.reload(); }, 1000);
                },
                error: function() { DevExpress.ui.notify({ message: 'Bir hata oluştu!', type: 'error', displayTime: 3000 }); }
            });
        });
    }
}
</script>
</cfoutput>
