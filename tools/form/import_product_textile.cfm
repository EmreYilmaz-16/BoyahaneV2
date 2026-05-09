<cfprocessingdirective pageEncoding="utf-8">

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-tshirt"></i></div>
        <div class="page-header-title">
            <h1>Tekstil Özellikleri İçe Aktar</h1>
            <p>Excel'den ürün kartlarına tekstil/kumaş bilgilerini toplu aktarın — eşleşme <strong>Üretici Kodu</strong> üzerinden yapılır</p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=product.list_product" class="btn-back">
        <i class="fas fa-arrow-left"></i>Ürün Listesi
    </a>
</div>

<div class="px-3">

    <!--- Adım Göstergesi --->
    <div class="d-flex align-items-center gap-2 mb-3 flex-wrap">
        <span class="badge bg-primary fs-6 step-badge" id="tx-badge-step1">1 · Dosya Yükle</span>
        <i class="fas fa-chevron-right text-muted"></i>
        <span class="badge bg-secondary fs-6 step-badge" id="tx-badge-step2">2 · Sütun Eşleştir</span>
        <i class="fas fa-chevron-right text-muted"></i>
        <span class="badge bg-secondary fs-6 step-badge" id="tx-badge-step3">3 · Önizle &amp; Aktar</span>
        <i class="fas fa-chevron-right text-muted"></i>
        <span class="badge bg-secondary fs-6 step-badge" id="tx-badge-step4">4 · Sonuç</span>
    </div>

    <!--- ===== ADIM 1: DOSYA ===== --->
    <div id="tx-step1">
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Nasıl Kullanılır?</div>
                <button class="btn btn-sm btn-outline-secondary" type="button" data-bs-toggle="collapse" data-bs-target="#txCollapseInfo">
                    <i class="fas fa-chevron-down"></i>
                </button>
            </div>
            <div class="collapse show" id="txCollapseInfo">
                <div class="card-body p-3">
                    <ol class="mb-2">
                        <li><strong>Şablon İndir</strong> butonuna tıklayarak örnek Excel şablonunu indirin.</li>
                        <li>Excel'e <strong>Üretici Kodu (manufact_code)</strong> ve güncellemek istediğiniz tekstil alanlarını doldurun.</li>
                        <li>Üretici Kodu <strong>zorunludur</strong>; eşleşme bu alan üzerinden yapılır.</li>
                        <li>Eşleşen üründe yalnızca doldurulan alanlar güncellenir; boş bırakılan alanlar değiştirilmez.</li>
                        <li>Üretici Koduna göre ürün bulunamazsa o satır hata olarak raporlanır.</li>
                    </ol>
                    <div class="alert alert-info py-2 mb-2">
                        <i class="fas fa-table me-1"></i>
                        <strong>Güncellenecek alanlar:</strong>
                        En (m) · Tuşe · Çekme · Isı Direnci · Hız · Gramaj · Besleme Avans · Kumaş Tipi · Kullanılan Kimyassal
                    </div>
                    <div class="alert alert-warning py-2 mb-0">
                        <i class="fas fa-exclamation-triangle me-1"></i>
                        Tek seferde en fazla <strong>5.000 satır</strong> aktarabilirsiniz.
                    </div>
                </div>
            </div>
        </div>

        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-upload"></i>Excel Dosyası Yükle</div>
                <button class="btn btn-success btn-sm" onclick="txDownloadTemplate()">
                    <i class="fas fa-download me-1"></i>Şablon İndir
                </button>
            </div>
            <div class="card-body p-3">
                <div id="tx-dropzone"
                     style="border:2px dashed #adb5bd;border-radius:8px;padding:3rem;text-align:center;cursor:pointer;transition:all .2s;"
                     ondragover="event.preventDefault();this.style.borderColor='#0d6efd';this.style.background='#f0f5ff';"
                     ondragleave="this.style.borderColor='#adb5bd';this.style.background='';"
                     ondrop="txHandleDrop(event)"
                     onclick="document.getElementById('txFileInput').click()">
                    <i class="fas fa-file-excel fa-3x text-success mb-3 d-block"></i>
                    <p class="mb-1 fw-semibold">Excel dosyasını buraya sürükleyin</p>
                    <p class="text-muted small mb-0">veya tıklayarak seçin (.xlsx, .xls)</p>
                </div>
                <input type="file" id="txFileInput" accept=".xlsx,.xls" style="display:none" onchange="txHandleFileInput(this)">
                <div id="tx-file-info" class="mt-2 text-success small" style="display:none">
                    <i class="fas fa-check-circle me-1"></i><span id="tx-file-name"></span>
                </div>
            </div>
        </div>
    </div><!--- /step1 --->

    <!--- ===== ADIM 2: SÜTUN EŞLEŞTİRME ===== --->
    <div id="tx-step2" style="display:none">
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-columns"></i>Sütun Eşleştirme</div>
                <button class="btn btn-sm btn-outline-danger" onclick="txReset()">
                    <i class="fas fa-times me-1"></i>Dosyayı Değiştir
                </button>
            </div>
            <div class="card-body p-3">
                <p class="text-muted small mb-3">
                    <i class="fas fa-magic me-1"></i>Excel sütunları otomatik eşleştirildi. Yanlış eşleşmeleri düzelterek <strong>Önizleme Oluştur</strong>'a tıklayın.
                </p>
                <div class="table-responsive">
                    <table class="table table-bordered table-sm align-middle">
                        <thead class="table-light">
                            <tr>
                                <th>Excel Sütunu</th>
                                <th>Örnek Veri</th>
                                <th>Eşleştirilecek Alan</th>
                            </tr>
                        </thead>
                        <tbody id="tx-mapper-body"></tbody>
                    </table>
                </div>
                <button class="btn btn-primary mt-2" onclick="txBuildPreview()">
                    <i class="fas fa-eye me-1"></i>Önizleme Oluştur
                </button>
            </div>
        </div>
    </div><!--- /step2 --->

    <!--- ===== ADIM 3: ÖNİZLEME ===== --->
    <div id="tx-step3" style="display:none">
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-table"></i>Veri Önizlemesi</div>
                <button class="btn btn-sm btn-outline-secondary" onclick="txGoToStep(2)">
                    <i class="fas fa-arrow-left me-1"></i>Eşleştirmeye Dön
                </button>
            </div>
            <div class="card-body p-3">
                <div id="tx-preview-stats" class="mb-3"></div>
                <div class="table-responsive" style="max-height:420px;overflow-y:auto;">
                    <table class="table table-sm table-bordered table-hover">
                        <thead class="table-light sticky-top" id="tx-preview-thead"></thead>
                        <tbody id="tx-preview-tbody"></tbody>
                    </table>
                </div>
                <div class="d-flex gap-2 mt-3 align-items-center flex-wrap">
                    <button class="btn btn-success" id="tx-btn-import" onclick="txDoImport()">
                        <i class="fas fa-upload me-1"></i>İçe Aktar
                    </button>
                    <div id="tx-import-progress" style="display:none" class="text-muted small">
                        <i class="fas fa-spinner fa-spin me-1"></i>Güncelleniyor, lütfen bekleyin...
                    </div>
                </div>
            </div>
        </div>
    </div><!--- /step3 --->

    <!--- ===== ADIM 4: SONUÇ ===== --->
    <div id="tx-step4" style="display:none">
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-check-circle"></i>İçe Aktarma Sonucu</div>
            </div>
            <div class="card-body p-3">
                <div id="tx-result-summary" class="mb-3"></div>
                <div id="tx-result-errors"></div>
                <div class="d-flex gap-2 mt-3">
                    <button class="btn btn-primary" onclick="txReset()">
                        <i class="fas fa-redo me-1"></i>Yeni İçe Aktarma
                    </button>
                    <a href="/index.cfm?fuseaction=product.list_product" class="btn btn-outline-secondary">
                        <i class="fas fa-list me-1"></i>Ürün Listesine Git
                    </a>
                </div>
            </div>
        </div>
    </div><!--- /step4 --->

</div>

<script src="https://cdn.sheetjs.com/xlsx-latest/package/dist/xlsx.full.min.js"></script>

<script>
/* ================================================================
   ALAN TANIMLARI
   ================================================================ */
const TX_FIELDS = [
    { key: 'manufact_code',       label: 'Üretici Kodu',        required: true,  type: 'str'   },
    { key: 'en',                  label: 'En (m)',               required: false, type: 'float' },
    { key: 'tuse',                label: 'Tuşe',                 required: false, type: 'str'   },
    { key: 'cekme',               label: 'Çekme',                required: false, type: 'str'   },
    { key: 'isi',                 label: 'Isı Direnci',          required: false, type: 'float' },
    { key: 'hiz',                 label: 'Hız',                  required: false, type: 'float' },
    { key: 'gramaj',              label: 'Gramaj',               required: false, type: 'float' },
    { key: 'besleme_avans',       label: 'Besleme Avans',        required: false, type: 'float' },
    { key: 'kumas_tipi',          label: 'Kumaş Tipi',           required: false, type: 'str'   },
    { key: 'kullanilan_kimyassal',label: 'Kullanılan Kimyassal', required: false, type: 'int'   },
];

const TX_AUTO_MAP = {
    'üretici kodu':'manufact_code', 'uretici kodu':'manufact_code',
    'manufact_code':'manufact_code', 'manufact code':'manufact_code',
    'üretici':'manufact_code', 'kod':'manufact_code',
    'en':'en', 'en (m)':'en', 'genişlik':'en', 'en (metre)':'en',
    'tuşe':'tuse', 'tuse':'tuse', 'tuşe değeri':'tuse',
    'çekme':'cekme', 'cekme':'cekme', 'çekme oranı':'cekme',
    'ısı':'isi', 'isi':'isi', 'ısı direnci':'isi',
    'hız':'hiz', 'hiz':'hiz',
    'gramaj':'gramaj', 'gram':'gramaj', 'g/m²':'gramaj', 'g/m2':'gramaj',
    'besleme avans':'besleme_avans', 'besleme_avans':'besleme_avans', 'avans':'besleme_avans',
    'kumaş tipi':'kumas_tipi', 'kumas tipi':'kumas_tipi', 'kumas_tipi':'kumas_tipi',
    'kumaş':'kumas_tipi', 'tip':'kumas_tipi',
    'kimyasal':'kullanilan_kimyassal', 'kullanilan kimyassal':'kullanilan_kimyassal',
    'kullanilan_kimyassal':'kullanilan_kimyassal', 'kimyassal id':'kullanilan_kimyassal',
};

/* ================================================================
   DURUM
   ================================================================ */
let txHeaders = [];
let txRows    = [];
let txColMap  = {};  // excelHeader -> fieldKey | null

/* ================================================================
   ADIM YÖNETİMİ
   ================================================================ */
function txGoToStep(n) {
    [1,2,3,4].forEach(function(i){
        document.getElementById('tx-step' + i).style.display = (i === n) ? '' : 'none';
        var badge = document.getElementById('tx-badge-step' + i);
        if (i === n)      badge.className = 'badge fs-6 step-badge bg-primary';
        else if (i < n)   badge.className = 'badge fs-6 step-badge bg-success';
        else              badge.className = 'badge fs-6 step-badge bg-secondary';
    });
}

function txReset() {
    txHeaders = []; txRows = []; txColMap = {};
    document.getElementById('txFileInput').value = '';
    document.getElementById('tx-file-info').style.display = 'none';
    txGoToStep(1);
}

/* ================================================================
   DOSYA YÜKLEME
   ================================================================ */
function txHandleDrop(e) {
    e.preventDefault();
    var dz = document.getElementById('tx-dropzone');
    dz.style.borderColor = '#adb5bd'; dz.style.background = '';
    var file = e.dataTransfer.files[0];
    if (file) txProcessFile(file);
}

function txHandleFileInput(input) {
    if (input.files[0]) txProcessFile(input.files[0]);
}

function txProcessFile(file) {
    var ext = file.name.substring(file.name.lastIndexOf('.')).toLowerCase();
    if (ext !== '.xlsx' && ext !== '.xls') {
        alert('Lütfen .xlsx veya .xls dosyası seçin.');
        return;
    }
    var reader = new FileReader();
    reader.onload = function(e) {
        try {
            var wb   = XLSX.read(new Uint8Array(e.target.result), { type: 'array' });
            var ws   = wb.Sheets[wb.SheetNames[0]];
            var rows = XLSX.utils.sheet_to_json(ws, { header: 1, defval: '' });

            if (!rows || rows.length < 2) {
                alert('Dosya en az başlık + 1 veri satırı içermelidir.');
                return;
            }
            txHeaders = rows[0].map(function(h){ return String(h).trim(); });
            txRows    = rows.slice(1).filter(function(r){ return r.some(function(c){ return String(c).trim() !== ''; }); });

            if (txRows.length === 0) { alert('Veri satırı bulunamadı.'); return; }
            if (txRows.length > 5000) { alert('En fazla 5.000 satır aktarabilirsiniz. Dosyada ' + txRows.length + ' satır var.'); return; }

            // Otomatik eşleştir
            txColMap = {};
            txHeaders.forEach(function(h){
                txColMap[h] = TX_AUTO_MAP[h.toLowerCase()] || null;
            });

            document.getElementById('tx-file-name').textContent = file.name + ' (' + txRows.length + ' satır)';
            document.getElementById('tx-file-info').style.display = '';
            txRenderMapper();
            txGoToStep(2);
        } catch(err) {
            alert('Dosya okunurken hata: ' + err.message);
        }
    };
    reader.readAsArrayBuffer(file);
}

/* ================================================================
   SÜTUN EŞLEŞTİRME
   ================================================================ */
function txRenderMapper() {
    var optBase = '<option value="">— Yoksay —</option>' +
        TX_FIELDS.map(function(f){
            return '<option value="' + f.key + '">' + f.label + (f.required ? ' *' : '') + '</option>';
        }).join('');

    var sample = txRows[0] || [];
    var html = '';
    txHeaders.forEach(function(h, i){
        var mapped   = txColMap[h] || '';
        var sampleV  = String(sample[i] || '').substring(0,60);
        var opts     = optBase.replace('value="' + mapped + '"', 'value="' + mapped + '" selected');
        html += '<tr>' +
            '<td><strong>' + txEsc(h) + '</strong></td>' +
            '<td><small class="text-muted">' + txEsc(sampleV) + '</small></td>' +
            '<td><select class="form-select form-select-sm tx-col-mapper" data-col="' + txEsc(h) + '">' + opts + '</select></td>' +
            '</tr>';
    });
    document.getElementById('tx-mapper-body').innerHTML = html;
    document.querySelectorAll('.tx-col-mapper').forEach(function(sel){
        sel.addEventListener('change', function(){ txColMap[this.dataset.col] = this.value || null; });
    });
}

/* ================================================================
   ÖNİZLEME
   ================================================================ */
function txBuildPreview() {
    var hasKey = Object.values(txColMap).indexOf('manufact_code') !== -1;
    if (!hasKey) { alert('"Üretici Kodu" alanını bir sütuna eşleştirmeniz zorunludur.'); return; }

    // ters map: fieldKey -> colIndex
    var f2i = {};
    txHeaders.forEach(function(h, i){ if (txColMap[h]) f2i[txColMap[h]] = i; });

    // eşleştirilen alanlar (manufact_code dahil)
    var mapped = TX_FIELDS.filter(function(f){ return f2i.hasOwnProperty(f.key); });

    // başlık
    document.getElementById('tx-preview-thead').innerHTML =
        '<tr><th>#</th>' + mapped.map(function(f){
            return '<th>' + f.label + (f.required ? ' <span class="text-danger">*</span>' : '') + '</th>';
        }).join('') + '<th>Durum</th></tr>';

    var validCnt = 0, invalidCnt = 0;
    var maxP = Math.min(txRows.length, 500);
    var rows = [];

    for (var i = 0; i < maxP; i++) {
        var raw  = txRows[i];
        var mCode = String(raw[f2i['manufact_code']] !== undefined ? raw[f2i['manufact_code']] : '').trim();
        var errs = [];
        if (!mCode) errs.push('Üretici Kodu boş');

        if (errs.length) invalidCnt++; else validCnt++;
        var cls = errs.length ? 'table-danger' : '';

        var cells = mapped.map(function(f){
            var val = raw[f2i[f.key]] !== undefined ? raw[f2i[f.key]] : '';
            if (f.type === 'float') val = val !== '' ? parseFloat(val) : '';
            if (f.type === 'int')   val = val !== '' ? parseInt(val)   : '';
            return '<td>' + txEsc(String(val).substring(0,80)) + '</td>';
        }).join('');

        var statusCell = errs.length
            ? '<td><span class="badge bg-danger">' + errs.join(', ') + '</span></td>'
            : '<td><span class="badge bg-success">Geçerli</span></td>';

        rows.push('<tr class="' + cls + '"><td>' + (i+2) + '</td>' + cells + statusCell + '</tr>');
    }

    document.getElementById('tx-preview-tbody').innerHTML = rows.join('');

    var hidden = txRows.length - maxP;
    document.getElementById('tx-preview-stats').innerHTML =
        '<div class="d-flex gap-3 flex-wrap">' +
        '<span class="badge bg-success fs-6"><i class="fas fa-check me-1"></i>' + validCnt + ' Geçerli</span>' +
        '<span class="badge bg-danger fs-6"><i class="fas fa-times me-1"></i>' + invalidCnt + ' Hatalı</span>' +
        '<span class="text-muted small">Toplam: ' + txRows.length + ' satır' + (hidden ? ' (ilk 500 gösteriliyor)' : '') + '</span>' +
        '</div>';

    if (validCnt === 0) { alert('Geçerli kayıt bulunamadı.'); return; }
    txGoToStep(3);
}

/* ================================================================
   İÇE AKTAR
   ================================================================ */
function txDoImport() {
    var f2i = {};
    txHeaders.forEach(function(h, i){ if (txColMap[h]) f2i[txColMap[h]] = i; });

    var records = [];
    txRows.forEach(function(raw, i){
        var mCode = String(raw[f2i['manufact_code']] !== undefined ? raw[f2i['manufact_code']] : '').trim();
        if (!mCode) return;

        var rec = { row_num: i + 2, manufact_code: mCode };
        TX_FIELDS.forEach(function(f){
            if (f.key === 'manufact_code') return;
            if (!f2i.hasOwnProperty(f.key)) return;
            var val = raw[f2i[f.key]];
            if (val === null || val === undefined || String(val).trim() === '') return; // boşsa gönderme
            if (f.type === 'float') { var n = parseFloat(val); if (!isNaN(n)) rec[f.key] = n; }
            else if (f.type === 'int') { var n = parseInt(val); if (!isNaN(n)) rec[f.key] = n; }
            else rec[f.key] = String(val).trim();
        });
        records.push(rec);
    });

    if (records.length === 0) { alert('İçe aktarılacak geçerli kayıt bulunamadı.'); return; }

    document.getElementById('tx-btn-import').disabled = true;
    document.getElementById('tx-import-progress').style.display = '';

    $.ajax({
        url:      '/tools/form/save_import_product_textile.cfm',
        type:     'POST',
        dataType: 'json',
        data:     { recordsJSON: JSON.stringify(records) },
        success:  function(res){ txShowResults(res); },
        error: function(xhr){
            var msg = 'Sunucu hatası oluştu.';
            try { msg = JSON.parse(xhr.responseText).message || msg; } catch(e){}
            alert('Hata: ' + msg);
            document.getElementById('tx-btn-import').disabled = false;
            document.getElementById('tx-import-progress').style.display = 'none';
        }
    });
}

/* ================================================================
   SONUÇ
   ================================================================ */
function txShowResults(res) {
    txGoToStep(4);
    var sum = document.getElementById('tx-result-summary');
    if (res.success) {
        sum.innerHTML =
            '<div class="row g-3">' +
            '<div class="col-auto"><div class="alert alert-success py-2 mb-0">' +
            '<i class="fas fa-check-circle me-1"></i><strong>' + res.updated + '</strong> ürün güncellendi.</div></div>' +
            (res.not_found > 0
                ? '<div class="col-auto"><div class="alert alert-warning py-2 mb-0">' +
                  '<i class="fas fa-search me-1"></i><strong>' + res.not_found + '</strong> üretici kodu eşleşmedi.</div></div>' : '') +
            (res.error_count > 0
                ? '<div class="col-auto"><div class="alert alert-danger py-2 mb-0">' +
                  '<i class="fas fa-exclamation-triangle me-1"></i><strong>' + res.error_count + '</strong> satırda hata oluştu.</div></div>' : '') +
            '</div>';
    } else {
        sum.innerHTML = '<div class="alert alert-danger"><i class="fas fa-times-circle me-1"></i>' + txEsc(res.message) + '</div>';
    }

    var errDiv = document.getElementById('tx-result-errors');
    if (res.errors && res.errors.length > 0) {
        errDiv.innerHTML =
            '<div class="grid-card mt-3"><div class="grid-card-header">' +
            '<div class="grid-card-header-title"><i class="fas fa-exclamation-circle text-warning"></i>Detaylar</div></div>' +
            '<div class="card-body p-3"><ul class="mb-0">' +
            res.errors.map(function(e){ return '<li class="text-danger small">' + txEsc(e) + '</li>'; }).join('') +
            '</ul></div></div>';
    } else {
        errDiv.innerHTML = '';
    }
}

/* ================================================================
   ŞABLON İNDİR
   ================================================================ */
function txDownloadTemplate() {
    var headers = [
        'Üretici Kodu', 'En (m)', 'Tuşe', 'Çekme', 'Isı Direnci',
        'Hız', 'Gramaj', 'Besleme Avans', 'Kumaş Tipi', 'Kullanılan Kimyassal'
    ];
    var example = ['UR-001', 1.5, 'Soft', '%5', 120, 300, 180, 10.5, 'Pamuk', 3];
    var wb = XLSX.utils.book_new();
    var ws = XLSX.utils.aoa_to_sheet([headers, example]);
    ws['!cols'] = [16,10,12,12,14,10,10,14,16,20].map(function(w){ return { wch: w }; });
    XLSX.utils.book_append_sheet(wb, ws, 'Tekstil');
    XLSX.writeFile(wb, 'tekstil_import_sablonu.xlsx');
}

/* ================================================================
   YARDIMCI
   ================================================================ */
function txEsc(str) {
    return String(str)
        .replace(/&/g,'&amp;').replace(/</g,'&lt;')
        .replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
</script>
