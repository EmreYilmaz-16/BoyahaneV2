<cfprocessingdirective pageEncoding="utf-8">

<cfset barcode = isDefined("url.barcode") ? trim(url.barcode) : "">
<cfif NOT len(barcode)>
    <div class="alert alert-danger m-3">Refakat barkodu gerekli. <a href="index.cfm?fuseaction=ship.operator_roll_scan">Operatör ekranına dön</a></div>
    <cfabort>
</cfif>
<cfset barcodeOrderId = isNumeric(barcode) ? val(barcode) : 0>

<cfquery name="getParti" datasource="boyahane">
    SELECT o.order_id, o.order_number, o.order_head, o.ref_ship_id,
           COALESCE(c.nickname, c.fullname, '') AS company_name,
           COALESCE(MAX(o.top_adedi), 0) AS top_adedi,
           COALESCE(MAX(p.product_name), MAX(orw.product_name), '') AS product_name,
           COALESCE(MAX(st.stock_code), '') AS stock_code,
           COALESCE(SUM(CASE WHEN LOWER(TRIM(orw.unit)) IN ('mt','metre','m') THEN orw.quantity ELSE 0 END), 0) AS parti_metre,
           COALESCE(SUM(CASE WHEN LOWER(TRIM(orw.unit)) = 'kg' THEN orw.quantity ELSE COALESCE(orw.amount2, 0) END), 0) AS parti_kg,
           COALESCE(s.hk_metre, 0) AS ship_metre,
           COALESCE(s.hk_kg, 0) AS ship_kg,
           COALESCE(s.hk_top_adedi, 0) AS ship_top_adedi
    FROM orders o
    LEFT JOIN order_row orw ON orw.order_id = o.order_id
    LEFT JOIN stocks st ON st.stock_id = orw.stock_id
    LEFT JOIN product p ON p.product_id = st.product_id
    LEFT JOIN company c ON c.company_id = o.company_id
    LEFT JOIN ship s ON s.ship_id = o.ref_ship_id
    WHERE o.order_number = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
       OR o.ref_no = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
       OR (<cfqueryparam value="#barcodeOrderId#" cfsqltype="cf_sql_integer"> > 0 AND o.order_id = <cfqueryparam value="#barcodeOrderId#" cfsqltype="cf_sql_integer">)
    GROUP BY o.order_id, o.order_number, o.order_head, o.ref_ship_id, c.nickname, c.fullname, s.hk_metre, s.hk_kg, s.hk_top_adedi
    ORDER BY o.order_id DESC
    LIMIT 1
</cfquery>

<cfif NOT getParti.recordCount>
    <div class="alert alert-danger m-3">Barkoda ait parti bulunamadı. <a href="index.cfm?fuseaction=ship.operator_roll_scan">Tekrar okut</a></div>
    <cfabort>
</cfif>

<cfset expectedMetre = val(getParti.parti_metre) gt 0 ? val(getParti.parti_metre) : val(getParti.ship_metre)>
<cfset expectedKg = val(getParti.parti_kg) gt 0 ? val(getParti.parti_kg) : val(getParti.ship_kg)>
<cfset expectedTop = val(getParti.top_adedi) gt 0 ? val(getParti.top_adedi) : val(getParti.ship_top_adedi)>
<cfset productLabel = trim((getParti.product_name ?: "") & (len(getParti.stock_code ?: "") ? " - " & getParti.stock_code : ""))>

<cfquery name="getRollStats" datasource="boyahane">
    SELECT COALESCE(COUNT(*), 0) AS roll_count,
           COALESCE(SUM(metre), 0) AS total_metre,
           COALESCE(SUM(kg), 0) AS total_kg,
           COALESCE(MAX(roll_no), 0) AS last_roll_no
    FROM ship_roll
    WHERE order_id = <cfqueryparam value="#getParti.order_id#" cfsqltype="cf_sql_integer">
</cfquery>
<cfset nextRollNo = val(getRollStats.last_roll_no) + 1>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-industry"></i></div>
        <div class="page-header-title">
            <h1>Operatör Sarım Girişi</h1>
            <p>Top sarımı bittiğinde metre ve kg bilgisini girip etikete geçin.</p>
        </div>
    </div>
    <a href="index.cfm?fuseaction=ship.operator_roll_scan" class="btn-back"><i class="fas fa-arrow-left"></i> Yeni Barkod</a>
</div>

<div class="px-3 pb-5">
    <div class="row g-3">
        <div class="col-lg-5">
            <div class="grid-card mb-3">
                <div class="grid-card-header"><div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Parti Bilgileri</div></div>
                <div class="card-body p-3">
                    <div class="d-flex justify-content-between py-1"><span class="text-muted">Barkod</span><strong><cfoutput>#xmlFormat(barcode)#</cfoutput></strong></div>
                    <div class="d-flex justify-content-between py-1"><span class="text-muted">Parti</span><strong><cfoutput>#xmlFormat(getParti.order_number ?: '')#</cfoutput></strong></div>
                    <div class="d-flex justify-content-between py-1"><span class="text-muted">Müşteri</span><strong><cfoutput>#xmlFormat(getParti.company_name ?: '')#</cfoutput></strong></div>
                    <div class="py-1"><span class="text-muted">Ürün</span><br><strong><cfoutput>#xmlFormat(productLabel)#</cfoutput></strong></div>
                    <hr>
                    <div class="row g-2 text-center">
                        <div class="col-4"><div class="border rounded p-2"><div class="text-muted small">Parti Mt</div><strong><cfoutput>#numberFormat(expectedMetre, '0.00')#</cfoutput></strong></div></div>
                        <div class="col-4"><div class="border rounded p-2"><div class="text-muted small">Parti Kg</div><strong><cfoutput>#numberFormat(expectedKg, '0.00')#</cfoutput></strong></div></div>
                        <div class="col-4"><div class="border rounded p-2"><div class="text-muted small">Hedef Top</div><strong><cfoutput>#expectedTop#</cfoutput></strong></div></div>
                    </div>
                </div>
            </div>
            <div class="grid-card">
                <div class="grid-card-header"><div class="grid-card-header-title"><i class="fas fa-chart-bar"></i>Girilen Top Özeti</div></div>
                <div class="card-body p-3">
                    <div class="d-flex justify-content-between py-1"><span>Top Adedi</span><strong><cfoutput>#val(getRollStats.roll_count)#</cfoutput></strong></div>
                    <div class="d-flex justify-content-between py-1"><span>Toplam Metre</span><strong><cfoutput>#numberFormat(val(getRollStats.total_metre), '0.00')#</cfoutput> mt</strong></div>
                    <div class="d-flex justify-content-between py-1"><span>Toplam Kg</span><strong><cfoutput>#numberFormat(val(getRollStats.total_kg), '0.00')#</cfoutput> kg</strong></div>
                </div>
            </div>
        </div>

        <div class="col-lg-7">
            <form class="grid-card" id="operatorRollForm">
                <div class="grid-card-header"><div class="grid-card-header-title"><i class="fas fa-stop-circle"></i>Sarım Bitti - Top Bilgisi Gir</div></div>
                <div class="card-body p-3">
                    <input type="hidden" name="order_id" value="<cfoutput>#val(getParti.order_id)#</cfoutput>">
                    <input type="hidden" name="ship_id" value="<cfoutput>#val(getParti.ref_ship_id)#</cfoutput>">
                    <input type="hidden" name="refakat_barcode" value="<cfoutput>#xmlFormat(barcode)#</cfoutput>">
                    <input type="hidden" name="parti_metre" value="<cfoutput>#expectedMetre#</cfoutput>">
                    <input type="hidden" name="parti_kg" value="<cfoutput>#expectedKg#</cfoutput>">
                    <input type="hidden" name="hedef_top_adedi" value="<cfoutput>#expectedTop#</cfoutput>">
                    <div class="row g-3">
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Top No</label>
                            <input type="number" min="1" step="1" class="form-control form-control-lg" name="roll_no" value="<cfoutput>#nextRollNo#</cfoutput>" required>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Metre</label>
                            <input type="number" min="0" step="0.0001" class="form-control form-control-lg" name="metre" id="metreInput" placeholder="0.0000">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Kg</label>
                            <input type="number" min="0" step="0.0001" class="form-control form-control-lg" name="kg" id="kgInput" placeholder="0.0000">
                        </div>
                    </div>
                    <label class="form-label fw-semibold mt-3">Not / Paket Durumu</label>
                    <input type="text" class="form-control" name="paket_durumu" value="paketlendi" maxlength="50">
                    <div class="alert alert-warning mt-3">
                        Şu an metre/kg operatör tarafından elle girilir. Cihaz entegrasyonu geldiğinde bu alanlar cihazdan doldurulacaktır.
                    </div>
                    <div class="d-flex justify-content-end gap-2">
                        <button type="button" class="btn btn-outline-secondary" onclick="window.location.href='index.cfm?fuseaction=ship.operator_roll_scan'">İptal</button>
                        <button type="submit" class="btn btn-success btn-lg"><i class="fas fa-check me-1"></i>Bitti - Etiket Bas</button>
                    </div>
                    <div class="alert alert-danger mt-3 d-none" id="saveError"></div>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
(function(){
    var form = document.getElementById('operatorRollForm');
    var errorBox = document.getElementById('saveError');
    form.addEventListener('submit', function(event){
        event.preventDefault();
        errorBox.classList.add('d-none');
        var metre = parseFloat(String(document.getElementById('metreInput').value || '0').replace(',', '.')) || 0;
        var kg = parseFloat(String(document.getElementById('kgInput').value || '0').replace(',', '.')) || 0;
        if (metre <= 0 && kg <= 0) {
            errorBox.textContent = 'Metre veya kg bilgisinden en az biri girilmelidir.';
            errorBox.classList.remove('d-none');
            return;
        }
        fetch('/ship/form/save_operator_roll.cfm', {method:'POST', body:new FormData(form), credentials:'same-origin'})
            .then(function(response){ return response.json(); })
            .then(function(result){
                if (!result.success) { throw new Error(result.message || 'Top kaydedilemedi.'); }
                window.location.href = result.label_url || ('/ship/display/ship_roll_label.cfm?roll_id=' + result.roll_id);
            })
            .catch(function(error){
                errorBox.textContent = error.message;
                errorBox.classList.remove('d-none');
            });
    });
})();
</script>
