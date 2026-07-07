<cfprocessingdirective pageEncoding="utf-8">

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-truck-loading"></i></div>
        <div class="page-header-title">
            <h1>Top Barkod Sevkiyat Okutma</h1>
            <p>Üretilen top etiketlerini sevkiyat aşamasında okutup sevk edin.</p>
        </div>
    </div>
</div>

<div class="px-3 pb-5">
    <div class="grid-card mb-3">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-barcode"></i>Top Etiketi Okut</div>
        </div>
        <div class="card-body p-3">
            <div class="row g-2 align-items-end">
                <div class="col-lg-5">
                    <label class="form-label fw-semibold" for="rollBarcode">Top Barkodu</label>
                    <div class="input-group input-group-lg">
                        <span class="input-group-text bg-white"><i class="fas fa-qrcode text-primary"></i></span>
                        <input type="text" class="form-control" id="rollBarcode" placeholder="Top etiket barkodunu okutun" autocomplete="off" autofocus>
                        <button type="button" class="btn btn-primary" id="addRollBtn">Ekle</button>
                    </div>
                </div>
                <div class="col-lg-3">
                    <label class="form-label fw-semibold" for="dispatchShipId">Sevkiyat / İrsaliye ID <span class="text-muted">(opsiyonel)</span></label>
                    <input type="number" min="1" step="1" class="form-control form-control-lg" id="dispatchShipId" placeholder="ship_id">
                </div>
                <div class="col-lg-4 text-lg-end">
                    <button type="button" class="btn btn-success btn-lg" id="completeDispatchBtn"><i class="fas fa-check me-1"></i>Okutulanları Sevk Et</button>
                </div>
            </div>
            <div class="alert alert-danger mt-3 d-none" id="dispatchError"></div>
            <div class="alert alert-success mt-3 d-none" id="dispatchSuccess"></div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header d-flex justify-content-between align-items-center">
            <div class="grid-card-header-title"><i class="fas fa-list-check"></i>Okutulan Toplar</div>
            <div class="fw-semibold">Toplam: <span id="scanCount">0</span> top · <span id="scanMetre">0.00</span> mt · <span id="scanKg">0.00</span> kg</div>
        </div>
        <div class="card-body p-3">
            <div class="table-responsive">
                <table class="table table-sm align-middle" id="dispatchRollTable">
                    <thead class="table-light">
                        <tr>
                            <th>Barkod</th>
                            <th>Parti</th>
                            <th>Müşteri</th>
                            <th>Ürün</th>
                            <th class="text-end">Top No</th>
                            <th class="text-end">Metre</th>
                            <th class="text-end">Kg</th>
                            <th>Durum</th>
                            <th style="width:70px"></th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                </table>
            </div>
            <div class="text-muted small">Aynı top barkodu ikinci kez okutulamaz. Daha önce sevk edilmiş toplar listeye eklenmez.</div>
        </div>
    </div>
</div>

<script>
(function(){
    var scanned = [];
    var barcodeInput = document.getElementById('rollBarcode');
    var errorBox = document.getElementById('dispatchError');
    var successBox = document.getElementById('dispatchSuccess');
    var tbody = document.querySelector('#dispatchRollTable tbody');
    function parseNumber(value){ return parseFloat(String(value || '0').replace(',', '.')) || 0; }
    function fmt(value){ return Number(value || 0).toLocaleString('tr-TR', {minimumFractionDigits:2, maximumFractionDigits:2}); }
    function showError(message){ errorBox.textContent = message; errorBox.classList.remove('d-none'); successBox.classList.add('d-none'); }
    function showSuccess(message){ successBox.textContent = message; successBox.classList.remove('d-none'); errorBox.classList.add('d-none'); }
    function clearMessages(){ errorBox.classList.add('d-none'); successBox.classList.add('d-none'); }
    function esc(value){ return String(value == null ? '' : value).replace(/[&<>'"]/g, function(ch){ return {'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[ch]; }); }
    function render(){
        tbody.innerHTML = scanned.map(function(item, index){
            return '<tr>' +
                '<td><strong>' + esc(item.roll_barcode) + '</strong></td>' +
                '<td>' + esc(item.parti_no) + '</td>' +
                '<td>' + esc(item.company_name) + '</td>' +
                '<td>' + esc(item.product_name) + '</td>' +
                '<td class="text-end">' + esc(item.roll_no) + '</td>' +
                '<td class="text-end">' + fmt(item.metre) + '</td>' +
                '<td class="text-end">' + fmt(item.kg) + '</td>' +
                '<td><span class="badge bg-info">Sevkiyata Alındı</span></td>' +
                '<td><button type="button" class="btn btn-sm btn-outline-danger" data-remove="' + index + '">&times;</button></td>' +
            '</tr>';
        }).join('');
        var totalMetre = scanned.reduce(function(sum, item){ return sum + parseNumber(item.metre); }, 0);
        var totalKg = scanned.reduce(function(sum, item){ return sum + parseNumber(item.kg); }, 0);
        document.getElementById('scanCount').textContent = scanned.length;
        document.getElementById('scanMetre').textContent = fmt(totalMetre);
        document.getElementById('scanKg').textContent = fmt(totalKg);
        tbody.querySelectorAll('[data-remove]').forEach(function(btn){
            btn.addEventListener('click', function(){ scanned.splice(parseInt(btn.getAttribute('data-remove'), 10), 1); render(); });
        });
    }
    function addRoll(){
        var barcode = barcodeInput.value.trim();
        clearMessages();
        if (!barcode) { showError('Top barkodunu okutun.'); barcodeInput.focus(); return; }
        if (scanned.some(function(item){ return item.roll_barcode === barcode; })) {
            showError('Bu top zaten okutuldu.'); barcodeInput.select(); return;
        }
        fetch('/ship/form/get_roll_by_barcode.cfm?barcode=' + encodeURIComponent(barcode), {credentials:'same-origin'})
            .then(function(response){ return response.json(); })
            .then(function(result){
                if (!result.success || !result.data) { throw new Error(result.message || 'Top bulunamadı.'); }
                if (result.data.is_dispatched) {
                    throw new Error('Bu top daha önce sevk edilmiş' + (result.data.dispatch_date ? ' (' + result.data.dispatch_date + ')' : '') + '.');
                }
                scanned.push(result.data);
                barcodeInput.value = '';
                barcodeInput.focus();
                render();
            })
            .catch(function(error){ showError(error.message); barcodeInput.select(); });
    }
    function completeDispatch(){
        clearMessages();
        if (!scanned.length) { showError('Sevk edilecek en az bir top okutun.'); return; }
        var formData = new FormData();
        formData.append('roll_ids', JSON.stringify(scanned.map(function(item){ return item.roll_id; })));
        formData.append('dispatch_ship_id', document.getElementById('dispatchShipId').value || '');
        fetch('/ship/form/save_dispatch_rolls.cfm', {method:'POST', body:formData, credentials:'same-origin'})
            .then(function(response){ return response.json(); })
            .then(function(result){
                if (!result.success) { throw new Error(result.message || 'Sevkiyat kaydedilemedi.'); }
                showSuccess(result.message || 'Okutulan toplar sevk edildi.');
                scanned = [];
                render();
                barcodeInput.focus();
            })
            .catch(function(error){ showError(error.message); });
    }
    document.getElementById('addRollBtn').addEventListener('click', addRoll);
    document.getElementById('completeDispatchBtn').addEventListener('click', completeDispatch);
    barcodeInput.addEventListener('keydown', function(event){ if (event.key === 'Enter') { event.preventDefault(); addRoll(); } });
    render();
})();
</script>
