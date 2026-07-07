<cfprocessingdirective pageEncoding="utf-8">

<cfset initialBarcode = isDefined("url.barcode") ? trim(url.barcode) : "">
<cfset initialOrderId = isDefined("url.order_id") AND isNumeric(url.order_id) ? val(url.order_id) : 0>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-barcode"></i></div>
        <div class="page-header-title">
            <h1>Sevkiyat Sarım / Top Üretim</h1>
            <p>Refakat barkodundan parti bilgilerini getirip top barkodlarını oluşturun.</p>
        </div>
    </div>
</div>

<div class="px-3 pb-5">
    <div class="row g-3">
        <div class="col-lg-4">
            <div class="grid-card mb-3">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-qrcode"></i>Refakat Barkodu</div>
                </div>
                <div class="card-body p-3">
                    <label class="form-label fw-semibold">Barkod / Parti No</label>
                    <div class="input-group mb-2">
                        <span class="input-group-text bg-white"><i class="fas fa-barcode text-primary"></i></span>
                        <input type="text" class="form-control" id="refakatBarcode" value="<cfoutput>#xmlFormat(len(initialBarcode) ? initialBarcode : initialOrderId)#</cfoutput>" placeholder="Refakat barkodunu okutun" autofocus>
                        <button type="button" class="btn btn-primary" id="loadPartiBtn">Getir</button>
                    </div>
                    <div class="alert alert-danger d-none" id="loadError"></div>
                </div>
            </div>

            <div class="grid-card mb-3 d-none" id="partiInfoCard">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Parti Bilgileri</div>
                </div>
                <div class="card-body p-3 small">
                    <div class="d-flex justify-content-between py-1"><span class="text-muted">Parti</span><strong id="infoPartiNo">—</strong></div>
                    <div class="d-flex justify-content-between py-1"><span class="text-muted">Müşteri</span><strong id="infoCompany">—</strong></div>
                    <div class="py-1"><span class="text-muted">Ürün</span><br><strong id="infoProduct">—</strong></div>
                    <hr>
                    <div class="d-flex justify-content-between py-1"><span class="text-muted">Metre</span><strong><span id="infoMetre">0</span> mt</strong></div>
                    <div class="d-flex justify-content-between py-1"><span class="text-muted">Kg</span><strong><span id="infoKg">0</span> kg</strong></div>
                    <div class="d-flex justify-content-between py-1"><span class="text-muted">Top</span><strong><span id="infoTop">0</span></strong></div>
                </div>
            </div>
        </div>

        <div class="col-lg-8">
            <form id="rollForm">
                <input type="hidden" id="order_id" name="order_id" value="0">
                <input type="hidden" id="ship_id" name="ship_id" value="0">
                <input type="hidden" id="parti_metre" name="parti_metre" value="0">
                <input type="hidden" id="parti_kg" name="parti_kg" value="0">
                <input type="hidden" id="ship_rolls_json" name="ship_rolls" value="[]">

                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-cogs"></i>Sarım Planı</div>
                    </div>
                    <div class="card-body p-3">
                        <div class="row g-2 align-items-end">
                            <div class="col-md-4">
                                <label class="form-label fw-semibold">Sarım Tipi</label>
                                <select class="form-select" id="sarim_tipi" name="sarim_tipi">
                                    <option value="standart">Standart Sarım</option>
                                    <option value="kg_bazli">Kg Bazlı Sarım</option>
                                    <option value="topa_top">Topa Top Sarım</option>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label fw-semibold">Top Adedi</label>
                                <input type="number" min="1" step="1" class="form-control" id="plan_top_adedi" name="hedef_top_adedi">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label fw-semibold">Top Mt</label>
                                <input type="number" step="0.0001" class="form-control" id="plan_top_metre">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label fw-semibold">Top Kg</label>
                                <input type="number" step="0.0001" class="form-control" id="plan_top_kg">
                            </div>
                            <div class="col-md-2">
                                <button type="button" class="btn btn-outline-primary w-100" id="generateRowsBtn">Topları Oluştur</button>
                            </div>
                        </div>
                        <div class="row g-2 mt-2">
                            <div class="col-md-3">
                                <label class="form-label small">Metre Tolerans %</label>
                                <input type="number" step="0.01" class="form-control form-control-sm" id="metre_tolerance_percent" name="metre_tolerance_percent" value="0">
                            </div>
                            <div class="col-md-3">
                                <label class="form-label small">Kg Tolerans %</label>
                                <input type="number" step="0.01" class="form-control form-control-sm" id="kg_tolerance_percent" name="kg_tolerance_percent" value="0">
                            </div>
                            <div class="col-md-6 d-flex align-items-end justify-content-end gap-2">
                                <button type="button" class="btn btn-sm btn-secondary" id="addShipRollRowBtn"><i class="fas fa-plus me-1"></i>Satır Ekle</button>
                                <button type="submit" class="btn btn-sm btn-success"><i class="fas fa-save me-1"></i>Kaydet ve Barkod Üret</button>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="grid-card mb-3">
                    <div class="grid-card-header"><div class="grid-card-header-title"><i class="fas fa-boxes"></i>Top Satırları</div></div>
                    <div class="card-body p-3">
                        <div class="table-responsive mb-3">
                            <table class="table table-sm align-middle" id="shipRollsTable">
                                <thead class="table-light"><tr><th style="width:90px">Top No</th><th>Metre</th><th>Kg</th><th style="width:80px"></th></tr></thead>
                                <tbody></tbody>
                            </table>
                        </div>
                        <div class="row g-3" id="shipRollsSummary">
                            <div class="col-md-6"><div class="border rounded p-3 h-100" data-summary-unit="metre"><div class="fw-semibold mb-2">Metre Özeti</div><div>Beklenen: <strong data-field="expected">0.00</strong> mt</div><div>Gerçekleşen: <strong data-field="actual">0.00</strong> mt</div><div>Fark: <strong data-field="diff">0.00</strong> mt (<span data-field="percent">0.00</span>%)</div><div>Durum: <span class="badge" data-field="status">uygun</span></div></div></div>
                            <div class="col-md-6"><div class="border rounded p-3 h-100" data-summary-unit="kg"><div class="fw-semibold mb-2">Kg Özeti</div><div>Beklenen: <strong data-field="expected">0.00</strong> kg</div><div>Gerçekleşen: <strong data-field="actual">0.00</strong> kg</div><div>Fark: <strong data-field="diff">0.00</strong> kg (<span data-field="percent">0.00</span>%)</div><div>Durum: <span class="badge" data-field="status">uygun</span></div></div></div>
                        </div>
                        <div class="alert alert-warning mt-3 d-none" id="shipRollsToleranceWarning"></div>
                        <div class="alert alert-success mt-3 d-none" id="saveResult"></div>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
(function(){
    var tbody = document.querySelector('#shipRollsTable tbody');
    var rollsInput = document.getElementById('ship_rolls_json');
    var warningEl = document.getElementById('shipRollsToleranceWarning');
    var saveResult = document.getElementById('saveResult');
    function parseNumber(value){ return parseFloat(String(value || '').replace(',', '.')) || 0; }
    function fmt(value){ return Number(value || 0).toLocaleString('tr-TR', {minimumFractionDigits:2, maximumFractionDigits:2}); }
    function statusFor(diff, percent, tolerance){ if (Math.abs(percent) <= tolerance || Math.abs(diff) < 0.000001) return 'uygun'; return diff < 0 ? 'çekme' : 'salma/artış'; }
    function badgeClass(status){ return status === 'uygun' ? 'bg-success' : (status === 'çekme' ? 'bg-warning text-dark' : 'bg-danger'); }
    function renderSummary(unit, data){ var box = document.querySelector('[data-summary-unit="' + unit + '"]'); box.querySelector('[data-field="expected"]').textContent = fmt(data.expected); box.querySelector('[data-field="actual"]').textContent = fmt(data.actual); box.querySelector('[data-field="diff"]').textContent = fmt(data.diff); box.querySelector('[data-field="percent"]').textContent = fmt(data.percent); var status = box.querySelector('[data-field="status"]'); status.textContent = data.status; status.className = 'badge ' + badgeClass(data.status); }
    function collectRolls(){ return Array.prototype.map.call(tbody.querySelectorAll('tr'), function(row, idx){ return { roll_no: parseInt(row.querySelector('[data-roll-no]').value, 10) || (idx + 1), metre: parseNumber(row.querySelector('[data-metre]').value), kg: parseNumber(row.querySelector('[data-kg]').value) }; }); }
    function calculate(){ var rolls = collectRolls(); var expectedMetre = parseNumber(document.getElementById('parti_metre').value); var expectedKg = parseNumber(document.getElementById('parti_kg').value); var actualMetre = rolls.reduce(function(sum, roll){ return sum + roll.metre; }, 0); var actualKg = rolls.reduce(function(sum, roll){ return sum + roll.kg; }, 0); var metreDiff = actualMetre - expectedMetre; var kgDiff = actualKg - expectedKg; var metrePercent = expectedMetre > 0 ? (metreDiff / expectedMetre) * 100 : 0; var kgPercent = expectedKg > 0 ? (kgDiff / expectedKg) * 100 : 0; var metreStatus = statusFor(metreDiff, metrePercent, parseNumber(document.getElementById('metre_tolerance_percent').value)); var kgStatus = statusFor(kgDiff, kgPercent, parseNumber(document.getElementById('kg_tolerance_percent').value)); renderSummary('metre', { expected: expectedMetre, actual: actualMetre, diff: metreDiff, percent: metrePercent, status: metreStatus }); renderSummary('kg', { expected: expectedKg, actual: actualKg, diff: kgDiff, percent: kgPercent, status: kgStatus }); rollsInput.value = JSON.stringify(rolls); var warnings = []; if (metreStatus !== 'uygun') warnings.push('Metre farkı tolerans dışında: ' + metreStatus + ' (' + fmt(metrePercent) + '%).'); if (kgStatus !== 'uygun') warnings.push('Kg farkı tolerans dışında: ' + kgStatus + ' (' + fmt(kgPercent) + '%).'); warningEl.classList.toggle('d-none', warnings.length === 0); warningEl.textContent = warnings.join(' '); }
    function addRow(data){ var tr = document.createElement('tr'); tr.innerHTML = '<td><input type="number" min="1" step="1" class="form-control form-control-sm" data-roll-no></td><td><input type="number" step="0.0001" class="form-control form-control-sm" data-metre></td><td><input type="number" step="0.0001" class="form-control form-control-sm" data-kg></td><td><button type="button" class="btn btn-sm btn-outline-danger" data-remove>&times;</button></td>'; tbody.appendChild(tr); tr.querySelector('[data-roll-no]').value = data && data.roll_no ? data.roll_no : tbody.querySelectorAll('tr').length; tr.querySelector('[data-metre]').value = data && data.metre ? data.metre : ''; tr.querySelector('[data-kg]').value = data && data.kg ? data.kg : ''; tr.addEventListener('input', calculate); tr.querySelector('[data-remove]').addEventListener('click', function(){ tr.remove(); calculate(); }); calculate(); }
    function clearRows(){ tbody.innerHTML = ''; calculate(); }
    function generateRows(){ var count = parseInt(document.getElementById('plan_top_adedi').value, 10) || 0; var mt = parseNumber(document.getElementById('plan_top_metre').value); var kg = parseNumber(document.getElementById('plan_top_kg').value); if (count <= 0) { alert('Top adedi girin.'); return; } clearRows(); for (var i = 1; i <= count; i++) addRow({roll_no:i, metre:mt, kg:kg}); }
    function setParti(data){ document.getElementById('order_id').value = data.order_id || 0; document.getElementById('ship_id').value = data.ship_id || 0; document.getElementById('parti_metre').value = data.metre || 0; document.getElementById('parti_kg').value = data.kg || 0; document.getElementById('infoPartiNo').textContent = data.parti_no || '—'; document.getElementById('infoCompany').textContent = data.company_name || '—'; document.getElementById('infoProduct').textContent = data.product_name || '—'; document.getElementById('infoMetre').textContent = fmt(data.metre || 0); document.getElementById('infoKg').textContent = fmt(data.kg || 0); document.getElementById('infoTop').textContent = data.top_adedi || 0; document.getElementById('plan_top_adedi').value = data.top_adedi || ''; document.getElementById('partiInfoCard').classList.remove('d-none'); calculate(); }
    function loadParti(){ var err = document.getElementById('loadError'); err.classList.add('d-none'); var barcode = document.getElementById('refakatBarcode').value.trim(); if (!barcode) { err.textContent = 'Barkod girin.'; err.classList.remove('d-none'); return; } fetch('/ship/form/get_parti_by_barcode.cfm?barcode=' + encodeURIComponent(barcode), {credentials:'same-origin'}).then(function(r){ return r.json(); }).then(function(res){ if (!res.success) throw new Error(res.message || 'Parti bulunamadı.'); setParti(res.data); }).catch(function(e){ err.textContent = e.message; err.classList.remove('d-none'); }); }
    document.getElementById('loadPartiBtn').addEventListener('click', loadParti);
    document.getElementById('refakatBarcode').addEventListener('keydown', function(e){ if (e.key === 'Enter') { e.preventDefault(); loadParti(); }});
    document.getElementById('addShipRollRowBtn').addEventListener('click', function(){ addRow({}); });
    document.getElementById('generateRowsBtn').addEventListener('click', generateRows);
    document.getElementById('sarim_tipi').addEventListener('change', function(){ document.getElementById('plan_top_metre').disabled = this.value === 'kg_bazli'; });
    document.getElementById('rollForm').addEventListener('submit', function(e){ e.preventDefault(); calculate(); if (!(parseInt(document.getElementById('order_id').value, 10) > 0)) { alert('Önce refakat barkodunu okutun.'); return; } if (collectRolls().length === 0) { alert('En az bir top satırı girin.'); return; } var fd = new FormData(this); fetch('/ship/form/save_ship_rolls.cfm', {method:'POST', body:fd, credentials:'same-origin'}).then(function(r){ return r.json(); }).then(function(res){ if (!res.success) throw new Error(res.message || 'Kayıt başarısız.'); saveResult.classList.remove('d-none'); saveResult.innerHTML = (res.message || 'Kaydedildi.') + (res.plan_id ? '<br>Plan No: <strong>' + res.plan_id + '</strong> <a class="btn btn-sm btn-outline-dark ms-2" target="_blank" href="/ship/display/roll_barcode_label.cfm?plan_id=' + res.plan_id + '">Etiketleri Yazdır</a>' : ''); }).catch(function(e){ alert(e.message); }); });
    addRow({});
    if (document.getElementById('refakatBarcode').value.trim()) loadParti();
})();
</script>
