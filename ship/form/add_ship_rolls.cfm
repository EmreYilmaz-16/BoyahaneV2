<cfprocessingdirective pageEncoding="utf-8">

<cfset shipId = isDefined("url.ship_id") AND isNumeric(url.ship_id) ? val(url.ship_id) : 0>
<cfset partiMetre = isDefined("url.parti_metre") AND isNumeric(url.parti_metre) ? val(url.parti_metre) : 0>
<cfset partiKg = isDefined("url.parti_kg") AND isNumeric(url.parti_kg) ? val(url.parti_kg) : 0>
<cfset metreTolerancePercent = isDefined("url.metre_tolerance_percent") AND isNumeric(url.metre_tolerance_percent) ? val(url.metre_tolerance_percent) : 0>
<cfset kgTolerancePercent = isDefined("url.kg_tolerance_percent") AND isNumeric(url.kg_tolerance_percent) ? val(url.kg_tolerance_percent) : 0>

<cfif shipId gt 0 AND (partiMetre lte 0 OR partiKg lte 0)>
    <cfquery name="getPartiExpected" datasource="boyahane">
        SELECT COALESCE(hk_metre, 0) AS parti_metre,
               COALESCE(hk_kg, 0) AS parti_kg
        FROM ship
        WHERE ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif getPartiExpected.recordCount>
        <cfif partiMetre lte 0><cfset partiMetre = isNumeric(getPartiExpected.parti_metre) ? val(getPartiExpected.parti_metre) : 0></cfif>
        <cfif partiKg lte 0><cfset partiKg = isNumeric(getPartiExpected.parti_kg) ? val(getPartiExpected.parti_kg) : 0></cfif>
    </cfif>
</cfif>

<div class="card shadow-sm" id="shipRollsCard">
    <div class="card-header d-flex justify-content-between align-items-center">
        <div>
            <h5 class="mb-0">Top / Metre-Kg Kontrolü</h5>
            <small class="text-muted">Girilen top satırları parti miktarları ile canlı karşılaştırılır.</small>
        </div>
        <button type="button" class="btn btn-sm btn-primary" id="addShipRollRowBtn">
            <i class="fas fa-plus me-1"></i>Top Ekle
        </button>
    </div>
    <div class="card-body">
        <input type="hidden" id="ship_id" name="ship_id" value="<cfoutput>#shipId#</cfoutput>">
        <input type="hidden" id="parti_metre" name="parti_metre" value="<cfoutput>#partiMetre#</cfoutput>">
        <input type="hidden" id="parti_kg" name="parti_kg" value="<cfoutput>#partiKg#</cfoutput>">
        <input type="hidden" id="metre_tolerance_percent" name="metre_tolerance_percent" value="<cfoutput>#metreTolerancePercent#</cfoutput>">
        <input type="hidden" id="kg_tolerance_percent" name="kg_tolerance_percent" value="<cfoutput>#kgTolerancePercent#</cfoutput>">
        <input type="hidden" id="ship_rolls_json" name="ship_rolls" value="[]">

        <div class="table-responsive mb-3">
            <table class="table table-sm align-middle" id="shipRollsTable">
                <thead class="table-light">
                    <tr>
                        <th style="width:70px">Top No</th>
                        <th>Metre</th>
                        <th>Kg</th>
                        <th style="width:60px"></th>
                    </tr>
                </thead>
                <tbody></tbody>
            </table>
        </div>

        <div class="row g-3" id="shipRollsSummary">
            <div class="col-md-6">
                <div class="border rounded p-3 h-100" data-summary-unit="metre">
                    <div class="fw-semibold mb-2">Metre Özeti</div>
                    <div>Beklenen: <strong data-field="expected">0.00</strong> mt</div>
                    <div>Gerçekleşen: <strong data-field="actual">0.00</strong> mt</div>
                    <div>Fark: <strong data-field="diff">0.00</strong> mt (<span data-field="percent">0.00</span>%)</div>
                    <div>Durum: <span class="badge" data-field="status">uygun</span></div>
                </div>
            </div>
            <div class="col-md-6">
                <div class="border rounded p-3 h-100" data-summary-unit="kg">
                    <div class="fw-semibold mb-2">Kg Özeti</div>
                    <div>Beklenen: <strong data-field="expected">0.00</strong> kg</div>
                    <div>Gerçekleşen: <strong data-field="actual">0.00</strong> kg</div>
                    <div>Fark: <strong data-field="diff">0.00</strong> kg (<span data-field="percent">0.00</span>%)</div>
                    <div>Durum: <span class="badge" data-field="status">uygun</span></div>
                </div>
            </div>
        </div>
        <div class="alert alert-warning mt-3 d-none" id="shipRollsToleranceWarning"></div>
    </div>
</div>

<script>
(function(){
    var tbody = document.querySelector('#shipRollsTable tbody');
    var rollsInput = document.getElementById('ship_rolls_json');
    var warningEl = document.getElementById('shipRollsToleranceWarning');
    function parseNumber(value){ return parseFloat(String(value || '').replace(',', '.')) || 0; }
    function fmt(value){ return Number(value || 0).toLocaleString('tr-TR', {minimumFractionDigits:2, maximumFractionDigits:2}); }
    function statusFor(diff, percent, tolerance){
        if (Math.abs(percent) <= tolerance || Math.abs(diff) < 0.000001) return 'uygun';
        return diff < 0 ? 'çekme' : 'salma/artış';
    }
    function badgeClass(status){ return status === 'uygun' ? 'bg-success' : (status === 'çekme' ? 'bg-warning text-dark' : 'bg-danger'); }
    function renderSummary(unit, data){
        var box = document.querySelector('[data-summary-unit="' + unit + '"]');
        box.querySelector('[data-field="expected"]').textContent = fmt(data.expected);
        box.querySelector('[data-field="actual"]').textContent = fmt(data.actual);
        box.querySelector('[data-field="diff"]').textContent = fmt(data.diff);
        box.querySelector('[data-field="percent"]').textContent = fmt(data.percent);
        var status = box.querySelector('[data-field="status"]');
        status.textContent = data.status;
        status.className = 'badge ' + badgeClass(data.status);
    }
    function collectRolls(){
        return Array.prototype.map.call(tbody.querySelectorAll('tr'), function(row){
            return { roll_no: row.querySelector('[data-roll-no]').value || '', metre: parseNumber(row.querySelector('[data-metre]').value), kg: parseNumber(row.querySelector('[data-kg]').value) };
        });
    }
    function calculate(){
        var rolls = collectRolls();
        var expectedMetre = parseNumber(document.getElementById('parti_metre').value);
        var expectedKg = parseNumber(document.getElementById('parti_kg').value);
        var actualMetre = rolls.reduce(function(sum, roll){ return sum + roll.metre; }, 0);
        var actualKg = rolls.reduce(function(sum, roll){ return sum + roll.kg; }, 0);
        var metreDiff = actualMetre - expectedMetre;
        var kgDiff = actualKg - expectedKg;
        var metrePercent = expectedMetre > 0 ? (metreDiff / expectedMetre) * 100 : 0;
        var kgPercent = expectedKg > 0 ? (kgDiff / expectedKg) * 100 : 0;
        var metreTolerance = parseNumber(document.getElementById('metre_tolerance_percent').value);
        var kgTolerance = parseNumber(document.getElementById('kg_tolerance_percent').value);
        var metreStatus = statusFor(metreDiff, metrePercent, metreTolerance);
        var kgStatus = statusFor(kgDiff, kgPercent, kgTolerance);
        renderSummary('metre', { expected: expectedMetre, actual: actualMetre, diff: metreDiff, percent: metrePercent, status: metreStatus });
        renderSummary('kg', { expected: expectedKg, actual: actualKg, diff: kgDiff, percent: kgPercent, status: kgStatus });
        rollsInput.value = JSON.stringify(rolls);
        var warnings = [];
        if (metreStatus !== 'uygun') warnings.push('Metre farkı tolerans dışında: ' + metreStatus + ' (' + fmt(metrePercent) + '%).');
        if (kgStatus !== 'uygun') warnings.push('Kg farkı tolerans dışında: ' + kgStatus + ' (' + fmt(kgPercent) + '%).');
        warningEl.classList.toggle('d-none', warnings.length === 0);
        warningEl.textContent = warnings.join(' ');
    }
    function addRow(data){
        var tr = document.createElement('tr');
        tr.innerHTML = '<td><input type="text" class="form-control form-control-sm" data-roll-no></td>' +
            '<td><input type="number" step="0.0001" class="form-control form-control-sm" data-metre></td>' +
            '<td><input type="number" step="0.0001" class="form-control form-control-sm" data-kg></td>' +
            '<td><button type="button" class="btn btn-sm btn-outline-danger" data-remove>&times;</button></td>';
        tbody.appendChild(tr);
        tr.querySelector('[data-roll-no]').value = data && data.roll_no ? data.roll_no : '';
        tr.querySelector('[data-metre]').value = data && data.metre ? data.metre : '';
        tr.querySelector('[data-kg]').value = data && data.kg ? data.kg : '';
        tr.addEventListener('input', calculate);
        tr.querySelector('[data-remove]').addEventListener('click', function(){ tr.remove(); calculate(); });
        calculate();
    }
    document.getElementById('addShipRollRowBtn').addEventListener('click', function(){ addRow({}); });
    addRow({});
})();
</script>
