<cfprocessingdirective pageEncoding="utf-8">

<cfset editMode = isDefined("url.operation_type_id") AND isNumeric(url.operation_type_id) AND val(url.operation_type_id) gt 0>
<cfset currentId  = editMode ? val(url.operation_type_id) : 0>

<cfif editMode>
    <cfquery name="getRec" datasource="boyahane">
        SELECT * FROM operation_types
        WHERE operation_type_id = <cfqueryparam value="#currentId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getRec.recordCount>
        <cfset editMode = false>
        <cfset currentId  = 0>
    </cfif>
</cfif>

<!--- Stok listesi (stok seçimi için) --->
<cfquery name="getStocks" datasource="boyahane">
    SELECT s.stock_id, s.stock_code,
           COALESCE(p.product_name,'') AS product_name
    FROM stocks s
    LEFT JOIN product p ON s.product_id = p.product_id
    WHERE s.stock_status = true
    ORDER BY s.stock_code
</cfquery>
<cfset stocksArr = []>
<cfloop query="getStocks">
    <cfset arrayAppend(stocksArr, {
        "stock_id"    : val(stock_id),
        "stock_code"  : stock_code   ?: "",
        "product_name": product_name ?: "",
        "label"       : stock_code & (len(product_name) ? " — " & product_name : "")
    })>
</cfloop>

<!--- Mevcut değerleri hazırla --->
<cfset fOpType    = editMode ? (getRec.operation_type    ?: "") : "">
<cfset fOpCode    = editMode ? (getRec.operation_code    ?: "") : "">
<cfset fOpCost    = editMode ? (isNumeric(getRec.operation_cost) ? val(getRec.operation_cost) : 0) : 0>
<cfset fMoney     = editMode ? (getRec.money             ?: "") : "">
<cfset fOHour     = editMode ? (isNumeric(getRec.o_hour) ? val(getRec.o_hour) : 0) : 0>
<cfset fOMinute   = editMode ? (isNumeric(getRec.o_minute) ? val(getRec.o_minute) : 0) : 0>
<cfset fStatus    = editMode ? (getRec.operation_status eq true OR getRec.operation_status eq "true") : true>
<cfset fComment   = editMode ? (getRec.comment           ?: "") : "">
<cfset fComment2  = editMode ? (getRec.comment2          ?: "") : "">
<cfset fEzgiSure  = editMode ? (isNumeric(getRec.ezgi_h_sure) ? val(getRec.ezgi_h_sure) : 0) : 0>
<cfset fEzgiForm  = editMode ? (getRec.ezgi_formul        ?: "") : "">
<cfset fStockId   = editMode ? (isNumeric(getRec.stock_id) ? val(getRec.stock_id) : 0) : 0>
<cfset fProdName  = editMode ? (getRec.product_name      ?: "") : "">

<cfif NOT structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-cog"></i></div>
        <div class="page-header-title">
            <h1><cfoutput>#editMode ? "Operasyon Tipi Düzenle" : "Yeni Operasyon Tipi"#</cfoutput></h1>
            <p>Üretim operasyon tipi bilgileri</p>
        </div>
    </div>
    <button class="btn-back" onclick="window.location.href='index.cfm?fuseaction=production.list_operation_types'">
        <i class="fas fa-arrow-left"></i>Listeye Dön
    </button>
</div>

<div class="px-3 pb-5">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title">
                <i class="fas fa-<cfoutput>#editMode ? "edit" : "plus-circle"#</cfoutput>"></i>
                <cfoutput>#editMode ? "Operasyon Tipi Güncelle" : "Yeni Operasyon Tipi Ekle"#</cfoutput>
            </div>
        </div>
        <div class="card-body p-3">
            <form id="opTypeForm" autocomplete="off">
                <cfoutput><input type="hidden" id="operation_type_id" value="#currentId#"></cfoutput>

                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label">Operasyon Adı <span class="text-danger">*</span></label>
                        <cfoutput><input type="text" class="form-control" id="f_operation_type" value="#htmlEditFormat(fOpType)#" placeholder="Operasyon adı..." required></cfoutput>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">Operasyon Kodu</label>
                        <cfoutput><input type="text" class="form-control" id="f_operation_code" value="#htmlEditFormat(fOpCode)#" placeholder="OP-001"></cfoutput>
                    </div>
                    <div class="col-md-3 d-flex align-items-end">
                        <div class="form-check form-switch ms-1">
                            <cfoutput><input class="form-check-input" type="checkbox" id="f_operation_status" #fStatus ? "checked" : ""#></cfoutput>
                            <label class="form-check-label" for="f_operation_status">Aktif</label>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mt-1">
                    <div class="col-md-3">
                        <label class="form-label">Maliyet</label>
                        <cfoutput><input type="number" step="0.01" class="form-control" id="f_operation_cost" value="#fOpCost#"></cfoutput>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">Para Birimi</label>
                        <select class="form-select" id="f_money">
                            <option value="">Seçiniz...</option>
                            <cfoutput>
                            <option value="TL"  #fMoney eq "TL"  ? "selected" : ""#>TL</option>
                            <option value="USD" #fMoney eq "USD" ? "selected" : ""#>USD</option>
                            <option value="EUR" #fMoney eq "EUR" ? "selected" : ""#>EUR</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">Süre — Saat</label>
                        <cfoutput><input type="number" min="0" class="form-control" id="f_o_hour" value="#fOHour#"></cfoutput>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">Süre — Dakika</label>
                        <cfoutput><input type="number" min="0" max="59" class="form-control" id="f_o_minute" value="#fOMinute#"></cfoutput>
                    </div>
                </div>

                <div class="row g-3 mt-1">
                    <div class="col-md-6">
                        <label class="form-label">Açıklama 1</label>
                        <cfoutput><input type="text" class="form-control" id="f_comment" value="#htmlEditFormat(fComment)#"></cfoutput>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Açıklama 2</label>
                        <cfoutput><input type="text" class="form-control" id="f_comment2" value="#htmlEditFormat(fComment2)#"></cfoutput>
                    </div>
                </div>

                <hr class="my-3">
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label">Bağlı Stok (Opsiyonel)</label>
                        <select class="form-select" id="f_stock_id">
                            <option value="0">Yok</option>
                            <cfoutput>
                            <cfloop array="#stocksArr#" index="s">
                                <option value="#s.stock_id#" <cfif fStockId eq s.stock_id>selected</cfif>>#htmlEditFormat(s.label)#</option>
                            </cfloop>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Ürün Adı (stok seçilince otomatik)</label>
                        <cfoutput><input type="text" class="form-control" id="f_product_name" value="#htmlEditFormat(fProdName)#"></cfoutput>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Ezgi H.Süre</label>
                        <cfoutput><input type="number" step="0.01" class="form-control" id="f_ezgi_h_sure" value="#fEzgiSure#"></cfoutput>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Ezgi Formül</label>
                        <cfoutput><input type="text" class="form-control" id="f_ezgi_formul" value="#htmlEditFormat(fEzgiForm)#"></cfoutput>
                    </div>
                </div>

                <div class="row mt-4">
                    <div class="col-12 d-flex gap-2">
                        <button type="submit" class="btn-save" id="btnSave">
                            <i class="fas fa-save me-1"></i>Kaydet
                        </button>
                        <button type="button" class="btn-back" onclick="window.location.href='index.cfm?fuseaction=production.list_operation_types'">
                            <i class="fas fa-times me-1"></i>İptal
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<cfoutput>
<script>
var stocksData = #serializeJSON(stocksArr)#;

$(document).ready(function(){

    // Stok seçilince ürün adını doldur
    $('##f_stock_id').on('change', function(){
        var sid = parseInt($(this).val());
        if (sid > 0) {
            var s = stocksData.find(function(x){ return x.stock_id === sid; });
            if (s) $('##f_product_name').val(s.product_name);
        }
    });

    $('##opTypeForm').on('submit', function(e){
        e.preventDefault();
        var opName = $('##f_operation_type').val().trim();
        if (!opName) { DevExpress.ui.notify('Operasyon adı zorunludur.', 'error', 3000); return; }

        var btn = $('##btnSave').prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i>Kaydediliyor...');

        $.ajax({
            url: '/production/form/save_operation_type.cfm',
            method: 'POST',
            data: {
                operation_type_id : $('##operation_type_id').val(),
                operation_type    : opName,
                operation_code    : $('##f_operation_code').val(),
                operation_cost    : $('##f_operation_cost').val() || 0,
                money             : $('##f_money').val(),
                o_hour            : $('##f_o_hour').val() || 0,
                o_minute          : $('##f_o_minute').val() || 0,
                operation_status  : $('##f_operation_status').is(':checked'),
                comment           : $('##f_comment').val(),
                comment2          : $('##f_comment2').val(),
                stock_id          : $('##f_stock_id').val() || 0,
                product_name      : $('##f_product_name').val(),
                ezgi_h_sure       : $('##f_ezgi_h_sure').val() || 0,
                ezgi_formul       : $('##f_ezgi_formul').val()
            },
            dataType: 'json',
            success: function(res){
                if (res && res.success) {
                    DevExpress.ui.notify('Operasyon tipi kaydedildi.', 'success', 2500);
                    setTimeout(function(){
                        window.location.href = 'index.cfm?fuseaction=production.list_operation_types&success=' + (res.mode || 'added');
                    }, 900);
                } else {
                    DevExpress.ui.notify((res && res.message) || 'Kayıt başarısız.', 'error', 4000);
                    $('##btnSave').prop('disabled', false).html('<i class="fas fa-save me-1"></i>Kaydet');
                }
            },
            error: function(){
                DevExpress.ui.notify('Sunucu hatası.', 'error', 3000);
                $('##btnSave').prop('disabled', false).html('<i class="fas fa-save me-1"></i>Kaydet');
            }
        });
    });
});
</script>
</cfoutput>
