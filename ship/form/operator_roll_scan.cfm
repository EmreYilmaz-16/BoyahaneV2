<cfprocessingdirective pageEncoding="utf-8">

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-user-cog"></i></div>
        <div class="page-header-title">
            <h1>Operatör Ekranı</h1>
            <p>Refakat kartı barkodunu okutun; sarım bitiş verisi giriş ekranına yönlendirilirsiniz.</p>
        </div>
    </div>
</div>

<div class="px-3 pb-5">
    <div class="row justify-content-center">
        <div class="col-lg-6">
            <div class="grid-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-barcode"></i>Refakat Barkodu Okut</div>
                </div>
                <div class="card-body p-4">
                    <label class="form-label fw-semibold" for="operatorBarcode">Refakat Kartı Barkodu</label>
                    <div class="input-group input-group-lg mb-3">
                        <span class="input-group-text bg-white"><i class="fas fa-qrcode text-primary"></i></span>
                        <input type="text" class="form-control" id="operatorBarcode" placeholder="Barkodu okutun veya yazın" autocomplete="off" autofocus>
                        <button type="button" class="btn btn-primary" id="continueBtn">Devam</button>
                    </div>
                    <div class="alert alert-info mb-0">
                        Operatör bu ekranda sadece barkodu okutur. Metre/Kg girişi bir sonraki ekranda, top sarımı bittiğinde yapılır.
                    </div>
                    <div class="alert alert-danger mt-3 d-none" id="scanError"></div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
(function(){
    var barcodeInput = document.getElementById('operatorBarcode');
    var errorBox = document.getElementById('scanError');
    function showError(message) {
        errorBox.textContent = message;
        errorBox.classList.remove('d-none');
    }
    function goNext() {
        var barcode = barcodeInput.value.trim();
        errorBox.classList.add('d-none');
        if (!barcode) {
            showError('Lütfen refakat barkodunu okutun.');
            barcodeInput.focus();
            return;
        }
        fetch('/ship/form/get_parti_by_barcode.cfm?barcode=' + encodeURIComponent(barcode), {credentials:'same-origin'})
            .then(function(response){ return response.json(); })
            .then(function(result){
                if (!result.success || !result.data || !result.data.order_id) {
                    throw new Error(result.message || 'Barkoda ait parti bulunamadı.');
                }
                window.location.href = 'index.cfm?fuseaction=ship.operator_roll_entry&barcode=' + encodeURIComponent(barcode);
            })
            .catch(function(error){ showError(error.message); });
    }
    document.getElementById('continueBtn').addEventListener('click', goNext);
    barcodeInput.addEventListener('keydown', function(event){
        if (event.key === 'Enter') {
            event.preventDefault();
            goNext();
        }
    });
})();
</script>
