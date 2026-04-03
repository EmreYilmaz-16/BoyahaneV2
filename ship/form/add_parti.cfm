
<cfprocessingdirective pageEncoding="utf-8">
<cfset shipId = isDefined("attributes.ship_id") AND isNumeric(attributes.ship_id) ? val(attributes.ship_id) : (isDefined("url.ship_id") AND isNumeric(url.ship_id) ? val(url.ship_id) : 0)>

<cfif shipId lte 0>
    <div class="alert alert-warning m-3"><i class="fas fa-exclamation-triangle me-2"></i>Lütfen bir irsaliye seçin (ship_id gerekli).</div>
    <cfabort>
</cfif>

<!--- İrsaliye bilgisi --->
<cfquery name="getShip" datasource="boyahane">
    SELECT s.ship_id, s.ship_number, s.company_id,
           COALESCE(c.nickname, c.fullname, '') AS company_name
    FROM ship s
    LEFT JOIN company c ON s.company_id = c.company_id
    WHERE s.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getShip.recordCount>
    <div class="alert alert-danger m-3">İrsaliye bulunamadı (#shipId#).</div>
    <cfabort>
</cfif>

<!--- Ana ürün satırı (irsaliyenin ilk ship_row'u) --->
<cfquery name="getShipRow" datasource="boyahane">
    SELECT sr.ship_row_id, sr.stock_id, sr.product_id,
           sr.name_product, sr.amount, sr.amount2, sr.unit, sr.unit_id
    FROM ship_row sr
    WHERE sr.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
    ORDER BY sr.ship_row_id
    LIMIT 1
</cfquery>

<!--- Mevcut parti sayısı (ref_no ile bağlı siparişler) --->
<cfquery name="countParts" datasource="boyahane">
    SELECT COUNT(*) AS c FROM orders
    WHERE ref_no = <cfqueryparam value="#getShip.ship_number#" cfsqltype="cf_sql_varchar">
</cfquery>
<cfset partiNo   = countParts.c + 1>
<cfset partiKodu = getShip.ship_number & "-P" & partiNo>

<!--- Ek işlem ürünleri (bu firmaya ait) --->
<cfquery name="getEkIslem" datasource="boyahane">
    SELECT s.stock_id, s.stock_code, p.product_id, p.product_name, p.product_code
    FROM stocks s
    JOIN product p ON s.product_id = p.product_id
    WHERE p.company_id      = <cfqueryparam value="#getShip.company_id#" cfsqltype="cf_sql_integer">
      AND p.product_detail2 = 'Ek İşlem'
      AND s.stock_status    = true
    ORDER BY p.product_name
</cfquery>

<!--- Ek işlemleri JSON dizisine çevir (JS için) --->
<cfset ekIslemArray = []>
<cfloop query="getEkIslem">
    <cfset arrayAppend(ekIslemArray, {
        "stock_id":     stock_id,
        "product_id":   product_id,
        "product_name": product_name ?: "",
        "product_code": product_code ?: "",
        "stock_code":   stock_code   ?: ""
    })>
</cfloop>

<!--- Ana ürün değerleri --->
<cfset mainStockId   = getShipRow.recordCount ? val(getShipRow.stock_id   ?: 0) : 0>
<cfset mainProductId = getShipRow.recordCount ? val(getShipRow.product_id ?: 0) : 0>
<cfset mainName      = getShipRow.recordCount ? (getShipRow.name_product  ?: "") : "">
<cfset mainMetre     = getShipRow.recordCount AND isNumeric(getShipRow.amount)  ? getShipRow.amount  : "">
<cfset mainKg        = getShipRow.recordCount AND isNumeric(getShipRow.amount2) ? getShipRow.amount2 : "">
<cfset mainUnit      = getShipRow.recordCount ? (getShipRow.unit   ?: "mt") : "mt">
<cfset mainUnitId    = getShipRow.recordCount ? val(getShipRow.unit_id ?: 0) : 0>

<!--- Müşteri satış fiyat listesi --->
<cfset companyPriceCat = 0>
<cfquery name="getCompanyCat" datasource="boyahane">
    SELECT price_cat FROM company_credit
    WHERE company_id = <cfqueryparam value="#getShip.company_id#" cfsqltype="cf_sql_integer">
    LIMIT 1
</cfquery>
<cfif getCompanyCat.recordCount AND isNumeric(getCompanyCat.price_cat) AND val(getCompanyCat.price_cat) gt 0>
    <cfset companyPriceCat = val(getCompanyCat.price_cat)>
</cfif>

<cfset priceList = []>
<cfif companyPriceCat gt 0>
    <cfquery name="getCompanyPrices" datasource="boyahane">
        SELECT pr.stock_id, pr.price,
               COALESCE(p.tax, 0) AS tax
        FROM price pr
        LEFT JOIN product p ON pr.product_id = p.product_id
        WHERE pr.price_catid = <cfqueryparam value="#companyPriceCat#" cfsqltype="cf_sql_integer">
          AND pr.stock_id IS NOT NULL
    </cfquery>
    <cfloop query="getCompanyPrices">
        <cfif val(stock_id) gt 0>
            <cfset arrayAppend(priceList, {
                "stock_id": val(stock_id),
                "price":    isNumeric(price) ? price : 0,
                "tax":      isNumeric(tax)   ? tax   : 0
            })>
        </cfif>
    </cfloop>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-cut"></i></div>
        <div class="page-header-title">
            <cfoutput>
            <h1>Parti Oluştur <small class="text-muted fs-6">#partiKodu#</small></h1>
            <p>İrsaliye <strong>#getShip.ship_number#</strong> — <strong>#xmlFormat(getShip.company_name)#</strong></p>
            </cfoutput>
        </div>
    </div>
    <a href="index.cfm?fuseaction=ship.list_ship" class="btn-back">
        <i class="fas fa-arrow-left"></i>İrsaliye Listesi
    </a>
</div>

<div class="px-3 pb-5">
    <div class="row g-3">

        <!--- ═══════ SOL: PARTİ BİLGİLERİ ═══════ --->
        <div class="col-lg-5">
            <div class="grid-card sticky-top-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title">
                        <i class="fas fa-tag"></i>Parti Bilgileri
                    </div>
                </div>
                <div class="card-body p-3">

                    <!--- Sipariş No (Parti Kodu) --->
                    <div class="mb-3">
                        <label class="form-label fw-semibold">
                            <i class="fas fa-hashtag me-1 text-primary"></i>Parti Kodu
                        </label>
                        <input type="text" class="form-control" id="parti_kodu"
                               value="<cfoutput>#xmlFormat(partiKodu)#</cfoutput>">
                        <small class="text-muted">Varsayılan otomatik oluşturuldu, değiştirilebilir.</small>
                    </div>

                    <!--- Aşama --->
                    <div class="mb-3">
                        <label class="form-label fw-semibold">
                            <i class="fas fa-tasks me-1 text-primary"></i>Aşama
                        </label>
                        <select class="form-select" id="order_stage">
                            <option value="1" selected>Beklemede</option>
                            <option value="2">Onaylandı</option>
                            <option value="3">Üretimde</option>
                            <option value="4">Hazır</option>
                            <option value="5">Sevk Edildi</option>
                            <option value="6">Tamamlandı</option>
                        </select>
                    </div>

                    <!--- Teslim Tarihi --->
                    <div class="mb-3">
                        <label class="form-label fw-semibold">
                            <i class="fas fa-calendar-alt me-1 text-primary"></i>Teslim Tarihi
                        </label>
                        <input type="date" class="form-control" id="deliverdate">
                    </div>

                    <!--- Açıklama --->
                    <div class="mb-3">
                        <label class="form-label fw-semibold">
                            <i class="fas fa-sticky-note me-1 text-primary"></i>Açıklama
                        </label>
                        <textarea class="form-control" id="order_detail" rows="3"
                                  placeholder="Parti açıklaması..."></textarea>
                    </div>

                    <!--- Kaydet --->
                    <div class="d-grid mt-3">
                        <button type="button" class="btn btn-primary" id="saveBtn" onclick="saveParti()">
                            <i class="fas fa-save me-2"></i>Parti Oluştur
                        </button>
                    </div>

                </div>
            </div>
        </div>

        <!--- ═══════ SAĞ: ANA ÜRÜN + EK İŞLEMLER ═══════ --->
        <div class="col-lg-7">

            <!--- Ana ürün kartı --->
            <div class="grid-card mb-3">
                <div class="grid-card-header">
                    <div class="grid-card-header-title">
                        <i class="fas fa-tshirt"></i>Ana Ürün
                        <small class="text-muted ms-2">(irsaliyeden)</small>
                    </div>
                </div>
                <div class="card-body p-3">

                    <div class="p-3 rounded mb-3" style="background:#f0f7ff;border:1px solid #b3d4ff;">
                        <div class="fw-semibold text-primary mb-1">
                            <i class="fas fa-box me-1"></i>
                            <cfoutput>#xmlFormat(mainName)#</cfoutput>
                        </div>
                        <cfif mainUnit neq "">
                        <small class="text-muted">Birim: <cfoutput>#xmlFormat(mainUnit)#</cfoutput></small>
                        </cfif>
                    </div>

                    <div class="row g-2">
                        <div class="col-sm-4">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-ruler me-1 text-primary"></i>Metre
                            </label>
                            <input type="number" step="0.0001" class="form-control" id="main_metre"
                                   value="<cfoutput>#mainMetre#</cfoutput>"
                                   placeholder="0.0000">
                        </div>
                        <div class="col-sm-4">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-weight me-1 text-primary"></i>Kg
                            </label>
                            <input type="number" step="0.0001" class="form-control" id="main_kg"
                                   value="<cfoutput>#mainKg#</cfoutput>"
                                   placeholder="0.0000">
                        </div>
                        <div class="col-sm-4">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-boxes me-1 text-primary"></i>Top Adedi
                            </label>
                            <input type="number" step="1" class="form-control" id="main_top"
                                   placeholder="0">
                        </div>
                    </div>

                    <div class="row g-2 mt-1">
                        <div class="col-sm-6">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-palette me-1 text-primary"></i>Müşteri Renk / Açıklama
                            </label>
                            <input type="text" class="form-control" id="main_color"
                                   placeholder="Renk kodu, açıklama...">
                        </div>
                        <div class="col-sm-6">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-barcode me-1 text-primary"></i>Lot No
                            </label>
                            <input type="text" class="form-control" id="main_lot_no"
                                   placeholder="Lot / Parti no">
                        </div>
                    </div>

                </div>
            </div>

            <!--- Ek İşlemler kartı --->
            <div class="grid-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title">
                        <i class="fas fa-cogs"></i>Ek İşlemler
                        <small class="text-muted ms-2">(sipariş satırı olarak eklenir)</small>
                    </div>
                    <span class="badge bg-secondary" id="ekIslemCount">
                        <cfoutput>#getEkIslem.recordCount#</cfoutput> adet
                    </span>
                </div>
                <div class="card-body p-3">

                    <cfif NOT getEkIslem.recordCount>
                        <div class="text-center text-muted py-4">
                            <i class="fas fa-info-circle fs-4 mb-2 d-block"></i>
                            Bu firmaya ait "Ek İşlem" ürünü tanımlı değil.
                        </div>
                    <cfelse>
                        <div class="mb-2">
                            <small class="text-muted">İşaretlenen her ek işlem, ana ürünün miktarıyla sipariş satırı olarak eklenir.</small>
                        </div>
                        <div id="ekIslemList">
                            <cfoutput query="getEkIslem">
                            <div class="ek-islem-row p-2 mb-2 rounded" style="border:1px solid ##e9ecef;background:##fafafa;" id="ek_row_#stock_id#">
                                <div class="d-flex align-items-center gap-3">
                                    <div class="form-check mb-0">
                                        <input class="form-check-input ek-chk" type="checkbox"
                                               id="ek_chk_#stock_id#"
                                               data-stock-id="#stock_id#"
                                               data-product-id="#product_id#"
                                               data-product-name="#xmlFormat(product_name)#"
                                               data-product-code="#xmlFormat(product_code ?: '')#"
                                               data-stock-code="#xmlFormat(stock_code ?: '')#">
                                        <label class="form-check-label fw-semibold" for="ek_chk_#stock_id#">
                                            #xmlFormat(product_name)#
                                            <cfif len(trim(stock_code))>
                                            <small class="text-muted">(#xmlFormat(stock_code)#)</small>
                                            </cfif>
                                        </label>
                                    </div>

                                </div>
                            </div>
                            </cfoutput>
                        </div>
                    </cfif>

                </div>
            </div>

        </div><!--- /col-lg-7 --->

    </div><!--- /row --->
</div>

<cfoutput>
<style>
.ek-islem-row { transition: background .15s; }
.ek-islem-row.selected { background: ##e8f5e9 !important; border-color: ##a5d6a7 !important; }
@media(min-width:992px){ .sticky-top-card { position:sticky; top:70px; } }
</style>

<script>
/* ─── Fiyat haritası (firma satış fiyat listesi) ─── */
var priceListData = #serializeJSON(priceList)#;
var companyPriceMap = {};
priceListData.forEach(function(r) {
    if (r.STOCK_ID > 0) companyPriceMap[r.STOCK_ID] = { price: r.PRICE || 0, tax: r.TAX || 0 };
});

/* ─── Ek işlem checkbox toggle ─── */
document.querySelectorAll('.ek-chk').forEach(function(chk) {
    chk.addEventListener('change', function() {
        var row = document.getElementById('ek_row_' + this.dataset.stockId);
        if (this.checked) row.classList.add('selected');
        else              row.classList.remove('selected');
    });
});

/* ─── Kaydet ─── */
function saveParti() {
    var mainMetre = parseFloat(document.getElementById('main_metre').value) || 0;
    var mainKg    = parseFloat(document.getElementById('main_kg').value)    || 0;
    var mainTop   = parseFloat(document.getElementById('main_top').value)   || 0;

    if (mainMetre <= 0 && mainKg <= 0) {
        alert('Lütfen ana ürün için en az Metre veya Kg girin.');
        document.getElementById('main_metre').focus();
        return;
    }

    /* Ana ürün satırı — miktar olarak metre kullanılır (>0 ise), yoksa kg */
    var mainQty = mainMetre > 0 ? mainMetre : mainKg;
    var mainUnit = '#jsStringFormat(mainUnit)#';

    var mainPriceInfo = companyPriceMap[#mainStockId#] || { price: 0, tax: 0 };
    var mainRowUnit = mainQty === mainMetre ? (mainUnit || 'mt') : 'kg';

    var rows = [{
        stock_id:     #mainStockId#,
        product_id:   #mainProductId#,
        product_name: '#jsStringFormat(mainName)#',
        product_code: '',
        quantity:     mainQty,
        price:        mainPriceInfo.price,
        unit:         mainRowUnit,
        unit_id:      #mainUnitId#,
        tax:          mainPriceInfo.tax,
        discount_1:   0,
        lot_no:       document.getElementById('main_lot_no').value || ''
    }];

    /* Ek işlem satırları — ana ürünün miktarı ve birimi, firma fiyat listesinden fiyat */
    document.querySelectorAll('.ek-chk:checked').forEach(function(chk) {
        var ekSid       = parseInt(chk.dataset.stockId);
        var ekPriceInfo = companyPriceMap[ekSid] || { price: 0, tax: 0 };
        rows.push({
            stock_id:     ekSid,
            product_id:   parseInt(chk.dataset.productId),
            product_name: chk.dataset.productName || '',
            product_code: chk.dataset.productCode || '',
            quantity:     mainQty,
            price:        ekPriceInfo.price,
            unit:         mainRowUnit,
            unit_id:      0,
            tax:          ekPriceInfo.tax,
            discount_1:   0,
            lot_no:       ''
        });
    });

    var today = new Date();
    var todayStr = today.toISOString().slice(0, 10) + 'T' + today.toTimeString().slice(0, 5);

    var data = {
        order_id:       0,
        purchase_sales: 'true',
        order_stage:    document.getElementById('order_stage').value,
        order_number:   document.getElementById('parti_kodu').value,
        order_head:     '#jsStringFormat(getShip.company_name)# — ' + document.getElementById('parti_kodu').value,
        ref_no:         '#jsStringFormat(getShip.ship_number)#',
        order_detail:   document.getElementById('order_detail').value,
        order_date:     todayStr,
        deliverdate:    document.getElementById('deliverdate').value || '',
        company_id:     #getShip.company_id#,
        member_type:    3,
        ref_company_id: #getShip.company_id#,
        paymethod:      0,
        ship_method:    0,
        order_currency: 0,
        order_status:   '1',
        rows:           JSON.stringify(rows)
    };

    var btn = document.getElementById('saveBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url:      '/order/form/save_order.cfm',
        method:   'POST',
        data:     data,
        dataType: 'json',
        success: function(res) {
            if (res.success) {
                window.location.href = 'index.cfm?fuseaction=ship.list_partiler&ship_id=#getShip.ship_id#';
            } else {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-save me-2"></i>Sipariş Olarak Kaydet';
                alert('Hata: ' + (res.message || 'Bilinmeyen hata'));
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Sipariş Olarak Kaydet';
            alert('Sunucu hatası! Lütfen tekrar deneyin.');
        }
    });
}
</script>
</cfoutput>
