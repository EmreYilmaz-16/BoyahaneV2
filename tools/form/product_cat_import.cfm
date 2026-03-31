<cfprocessingdirective pageEncoding="utf-8">

<!--- jQuery yükleme kontrolü --->
<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<!--- Mevcut kategoriler (referans için) --->
<cfquery name="getCategories" datasource="boyahane">
    SELECT product_catid, product_cat, hierarchy
    FROM product_cat
    ORDER BY hierarchy, product_cat
</cfquery>

<!--- Page Header --->
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-file-excel"></i>
        </div>
        <div class="page-header-title">
            <h1>Excel'den Kategori İçe Aktar</h1>
            <p>Excel dosyasından toplu ürün kategorisi aktarımı yapın</p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=product.list_product_cat" class="btn-back">
        <i class="fas fa-arrow-left"></i>Kategori Listesi
    </a>
</div>

<div class="px-3">

    <!--- Adım Göstergesi --->
    <div class="d-flex align-items-center gap-2 mb-3 flex-wrap">
        <span class="badge bg-primary fs-6 step-badge" id="badge-step1">1 · Dosya Yükle</span>
        <i class="fas fa-chevron-right text-muted"></i>
        <span class="badge bg-secondary fs-6 step-badge" id="badge-step2">2 · Sütun Eşleştir</span>
        <i class="fas fa-chevron-right text-muted"></i>
        <span class="badge bg-secondary fs-6 step-badge" id="badge-step3">3 · Önizle &amp; İçe Aktar</span>
        <i class="fas fa-chevron-right text-muted"></i>
        <span class="badge bg-secondary fs-6 step-badge" id="badge-step4">4 · Sonuç</span>
    </div>

    <!--- ===== ADIM 1: DOSYA YÜKLE ===== --->
    <div id="step1">

        <div class="row g-3">
            <div class="col-md-8">
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Nasıl Kullanılır?</div>
                        <button class="btn btn-sm btn-outline-secondary" type="button" data-bs-toggle="collapse" data-bs-target="#collapseInstructions">
                            <i class="fas fa-chevron-down"></i>
                        </button>
                    </div>
                    <div class="collapse show" id="collapseInstructions">
                        <div class="card-body p-3">
                            <ol class="mb-2">
                                <li><strong>Şablon İndir</strong> butonuna tıklayın.</li>
                                <li>Şablona kategorilerinizi doldurun. <strong>Kategori Adı</strong> zorunludur.</li>
                                <li><strong>Hiyerarşi</strong> alanı kategorinin sıralama kodudur (ör: 01, 01.01, A.01).</li>
                                <li>Dosyayı yükleyip sütunları eşleştirin, önizlemeyi onaylayın.</li>
                            </ol>
                            <div class="alert alert-warning py-2 mb-0">
                                <i class="fas fa-exclamation-triangle me-1"></i>
                                <strong>Zorunlu:</strong> Kategori Adı &nbsp;|&nbsp;
                                <strong>Opsiyonel:</strong> Hiyerarşi, Açıklama
                            </div>
                        </div>
                    </div>
                </div>

                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-upload"></i>Excel Dosyası Yükle</div>
                        <button class="btn btn-success btn-sm" onclick="downloadTemplate()">
                            <i class="fas fa-download me-1"></i>Şablon İndir
                        </button>
                    </div>
                    <div class="card-body p-3">
                        <div id="dropzone"
                             style="border:2px dashed #adb5bd;border-radius:8px;padding:3rem;text-align:center;cursor:pointer;transition:all .2s;"
                             ondragover="event.preventDefault();this.style.borderColor='#0d6efd';this.style.background='#f0f5ff';"
                             ondragleave="this.style.borderColor='#adb5bd';this.style.background='';"
                             ondrop="handleDrop(event)"
                             onclick="document.getElementById('fileInput').click()">
                            <i class="fas fa-file-excel fa-3x text-success mb-3 d-block"></i>
                            <p class="mb-1 fw-semibold">Excel dosyasını buraya sürükleyin</p>
                            <p class="text-muted small mb-0">veya tıklayarak seçin (.xlsx, .xls)</p>
                        </div>
                        <input type="file" id="fileInput" accept=".xlsx,.xls" style="display:none" onchange="handleFileInput(this)">
                        <div id="file-info" class="mt-2 text-success small" style="display:none">
                            <i class="fas fa-check-circle me-1"></i><span id="file-name"></span>
                        </div>
                    </div>
                </div>
            </div>

            <!--- Mevcut Kategoriler Referansı --->
            <div class="col-md-4">
                <div class="grid-card">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-folder"></i>Mevcut Kategoriler</div>
                        <button class="btn btn-sm btn-outline-secondary" type="button" data-bs-toggle="collapse" data-bs-target="#collapseCats">
                            <i class="fas fa-chevron-down"></i>
                        </button>
                    </div>
                    <div class="collapse show" id="collapseCats">
                        <div class="card-body p-0" style="max-height:280px;overflow-y:auto;">
                            <cfif getCategories.recordCount eq 0>
                                <p class="text-muted small p-3 mb-0">Henüz kategori eklenmemiş.</p>
                            <cfelse>
                                <table class="table table-sm table-hover mb-0">
                                    <thead class="table-light sticky-top">
                                        <tr><th>Hiyerarşi</th><th>Kategori</th></tr>
                                    </thead>
                                    <tbody>
                                        <cfoutput query="getCategories">
                                        <tr>
                                            <td><small>#hierarchy#</small></td>
                                            <td><small>#product_cat#</small></td>
                                        </tr>
                                        </cfoutput>
                                    </tbody>
                                </table>
                            </cfif>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!--- ===== ADIM 2: SÜTUN EŞLEŞTİRME ===== --->
    <div id="step2" style="display:none">
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-columns"></i>Sütun Eşleştirme</div>
                <button class="btn btn-sm btn-outline-danger" onclick="resetUpload()">
                    <i class="fas fa-times me-1"></i>Dosyayı Değiştir
                </button>
            </div>
            <div class="card-body p-3">
                <div class="table-responsive">
                    <table class="table table-bordered table-sm align-middle">
                        <thead class="table-light">
                            <tr><th>Excel Sütunu</th><th>Örnek Veri</th><th>Eşleştirilecek Alan</th></tr>
                        </thead>
                        <tbody id="mapper-body"></tbody>
                    </table>
                </div>
                <div class="d-flex gap-2 mt-3">
                    <button class="btn btn-primary" onclick="buildPreview()">
                        <i class="fas fa-eye me-1"></i>Önizleme Oluştur
                    </button>
                </div>
            </div>
        </div>
    </div>

    <!--- ===== ADIM 3: ÖNİZLEME ===== --->
    <div id="step3" style="display:none">
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-table"></i>Veri Önizlemesi</div>
                <button class="btn btn-sm btn-outline-secondary" onclick="goToStep(2)">
                    <i class="fas fa-arrow-left me-1"></i>Eşleştirmeye Dön
                </button>
            </div>
            <div class="card-body p-3">
                <div id="preview-stats" class="mb-3"></div>
                <div class="table-responsive" style="max-height:400px;overflow-y:auto;">
                    <table class="table table-sm table-bordered table-hover">
                        <thead class="table-light sticky-top" id="preview-thead"></thead>
                        <tbody id="preview-tbody"></tbody>
                    </table>
                </div>
                <div class="d-flex gap-2 mt-3 align-items-center flex-wrap">
                    <button class="btn btn-success" id="btn-import" onclick="doImport()">
                        <i class="fas fa-upload me-1"></i>İçe Aktar
                    </button>
                    <div id="import-progress" style="display:none" class="text-muted small">
                        <i class="fas fa-spinner fa-spin me-1"></i>İçe aktarılıyor...
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!--- ===== ADIM 4: SONUÇ ===== --->
    <div id="step4" style="display:none">
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-check-circle"></i>İçe Aktarma Sonucu</div>
            </div>
            <div class="card-body p-3">
                <div id="result-summary" class="mb-3"></div>
                <div id="result-errors"></div>
                <div class="d-flex gap-2 mt-3">
                    <button class="btn btn-primary" onclick="resetUpload()">
                        <i class="fas fa-redo me-1"></i>Yeni İçe Aktarma
                    </button>
                    <a href="/index.cfm?fuseaction=product.list_product_cat" class="btn btn-outline-secondary">
                        <i class="fas fa-list me-1"></i>Kategori Listesine Git
                    </a>
                </div>
            </div>
        </div>
    </div>

</div>

<script src="https://cdn.sheetjs.com/xlsx-latest/package/dist/xlsx.full.min.js"></script>
<script>
const FIELDS = [
    { key: 'product_cat', label: 'Kategori Adı',  required: true  },
    { key: 'hierarchy',   label: 'Hiyerarşi',     required: false },
    { key: 'detail',      label: 'Açıklama',      required: false },
];

const AUTO_HEADER_MAP = {
    'kategori adı':'product_cat', 'kategori adi':'product_cat', 'kategori':'product_cat',
    'category name':'product_cat', 'product_cat':'product_cat', 'ad':'product_cat',
    'adı':'product_cat', 'name':'product_cat',
    'hiyerarşi':'hierarchy', 'hiyerarsi':'hierarchy', 'hierarchy':'hierarchy',
    'kod':'hierarchy', 'sıra':'hierarchy', 'sira':'hierarchy',
    'açıklama':'detail', 'aciklama':'detail', 'detail':'detail', 'detay':'detail',
};

let excelHeaders = [], excelRows = [], columnMapping = {};

function goToStep(n) {
    [1,2,3,4].forEach(i => {
        document.getElementById('step' + i).style.display = i === n ? '' : 'none';
        const b = document.getElementById('badge-step' + i);
        b.className = 'badge fs-6 step-badge ' + (i === n ? 'bg-primary' : (i < n ? 'bg-success' : 'bg-secondary'));
    });
}

function resetUpload() {
    excelHeaders = []; excelRows = []; columnMapping = {};
    document.getElementById('fileInput').value = '';
    document.getElementById('file-info').style.display = 'none';
    goToStep(1);
}

function handleDrop(e) {
    e.preventDefault();
    const dz = document.getElementById('dropzone');
    dz.style.borderColor = '#adb5bd'; dz.style.background = '';
    if (e.dataTransfer.files[0]) processFile(e.dataTransfer.files[0]);
}

function handleFileInput(input) { if (input.files[0]) processFile(input.files[0]); }

function processFile(file) {
    const ext = file.name.substring(file.name.lastIndexOf('.')).toLowerCase();
    if (!['.xlsx','.xls'].includes(ext)) { alert('Lütfen .xlsx veya .xls dosyası seçin.'); return; }
    const reader = new FileReader();
    reader.onload = function(e) {
        try {
            const wb   = XLSX.read(new Uint8Array(e.target.result), { type: 'array' });
            const rows = XLSX.utils.sheet_to_json(wb.Sheets[wb.SheetNames[0]], { header: 1, defval: '' });
            if (!rows || rows.length < 2) { alert('Dosyada başlık + veri satırı bulunamadı.'); return; }
            excelHeaders = rows[0].map(h => String(h).trim());
            excelRows    = rows.slice(1).filter(r => r.some(c => String(c).trim() !== ''));
            if (!excelRows.length) { alert('Veri satırı bulunamadı.'); return; }
            if (excelRows.length > 5000) { alert('En fazla 5000 satır aktarabilirsiniz.'); return; }
            columnMapping = {};
            excelHeaders.forEach(h => { columnMapping[h] = AUTO_HEADER_MAP[h.toLowerCase()] || null; });
            document.getElementById('file-name').textContent = file.name + ' (' + excelRows.length + ' satır)';
            document.getElementById('file-info').style.display = '';
            renderMapper();
            goToStep(2);
        } catch(err) { alert('Dosya okunurken hata: ' + err.message); }
    };
    reader.readAsArrayBuffer(file);
}

function renderMapper() {
    const opts = '<option value="">— Yoksay —</option>' +
        FIELDS.map(f => '<option value="' + f.key + '">' + f.label + (f.required ? ' *' : '') + '</option>').join('');
    const sample = excelRows[0] || [];
    document.getElementById('mapper-body').innerHTML = excelHeaders.map((h, i) => {
        const mapped = columnMapping[h] || '';
        const sv     = String(sample[i] || '').substring(0, 50);
        const o      = opts.replace('value="' + mapped + '">', 'value="' + mapped + '" selected>');
        return '<tr><td><strong>' + escHtml(h) + '</strong></td>' +
               '<td><small class="text-muted">' + escHtml(sv) + '</small></td>' +
               '<td><select class="form-select form-select-sm col-mapper" data-col="' + escHtml(h) + '">' + o + '</select></td></tr>';
    }).join('');
    document.querySelectorAll('.col-mapper').forEach(s => s.addEventListener('change', function() {
        columnMapping[this.dataset.col] = this.value || null;
    }));
}

function buildPreview() {
    if (!Object.values(columnMapping).includes('product_cat')) {
        alert('"Kategori Adı" alanını bir sütuna eşleştirmeniz zorunludur.'); return;
    }
    const f2i = {};
    excelHeaders.forEach((h, i) => { if (columnMapping[h]) f2i[columnMapping[h]] = i; });
    const mapped = FIELDS.filter(f => f2i.hasOwnProperty(f.key));

    document.getElementById('preview-thead').innerHTML =
        '<tr><th>#</th>' + mapped.map(f => '<th>' + f.label + (f.required ? ' <span class="text-danger">*</span>' : '') + '</th>').join('') + '<th>Durum</th></tr>';

    let ok = 0, bad = 0;
    const max  = Math.min(excelRows.length, 500);
    const rows = [];

    for (let i = 0; i < max; i++) {
        const raw  = excelRows[i];
        const errs = [];
        const name = String(raw[f2i['product_cat']] || '').trim();
        if (!name) errs.push('Kategori adı boş');

        const cells = mapped.map(f => {
            const val = (raw[f2i[f.key]] !== undefined ? raw[f2i[f.key]] : '');
            return '<td>' + escHtml(String(val).substring(0, 80)) + '</td>';
        }).join('');

        const status = errs.length
            ? '<td><span class="badge bg-danger">' + errs.join(', ') + '</span></td>'
            : '<td><span class="badge bg-success">Geçerli</span></td>';

        if (errs.length) bad++; else ok++;
        rows.push('<tr class="' + (errs.length ? 'table-danger' : 'table-success') + '"><td>' + (i+2) + '</td>' + cells + status + '</tr>');
    }

    document.getElementById('preview-tbody').innerHTML = rows.join('');
    const hidden = excelRows.length - max;
    document.getElementById('preview-stats').innerHTML =
        '<div class="d-flex gap-3 flex-wrap">' +
        '<span class="badge bg-success fs-6"><i class="fas fa-check me-1"></i>' + ok + ' Geçerli</span>' +
        '<span class="badge bg-danger fs-6"><i class="fas fa-times me-1"></i>' + bad + ' Hatalı</span>' +
        '<span class="text-muted small">Toplam: ' + excelRows.length + ' satır' + (hidden ? ' (ilk 500 gösteriliyor)' : '') + '</span></div>';

    if (ok === 0) { alert('Geçerli kayıt bulunamadı.'); return; }
    goToStep(3);
}

function doImport() {
    const f2i = {};
    excelHeaders.forEach((h, i) => { if (columnMapping[h]) f2i[columnMapping[h]] = i; });

    const cats = [];
    excelRows.forEach((raw, i) => {
        const name = String(raw[f2i['product_cat']] || '').trim();
        if (!name) return;
        cats.push({
            row_num:     i + 2,
            product_cat: name,
            hierarchy:   String(f2i.hasOwnProperty('hierarchy') ? raw[f2i['hierarchy']] : '').trim(),
            detail:      String(f2i.hasOwnProperty('detail')    ? raw[f2i['detail']]    : '').trim(),
        });
    });

    if (!cats.length) { alert('Geçerli kayıt bulunamadı.'); return; }
    document.getElementById('btn-import').disabled = true;
    document.getElementById('import-progress').style.display = '';

    $.ajax({
        url:      '/product/cfc/product.cfc?method=importProductCats',
        type:     'POST',
        data:     { catsJSON: JSON.stringify(cats) },
        dataType: 'json',
        success:  showResults,
        error: function(xhr) {
            let msg = 'Sunucu hatası.';
            try { msg = JSON.parse(xhr.responseText).message || msg; } catch(e) {}
            alert('Hata: ' + msg);
            document.getElementById('btn-import').disabled = false;
            document.getElementById('import-progress').style.display = 'none';
        }
    });
}

function showResults(res) {
    goToStep(4);
    const s = document.getElementById('result-summary');
    if (res.success) {
        s.innerHTML = '<div class="d-flex gap-3 flex-wrap">' +
            '<div class="alert alert-success py-2 mb-0"><i class="fas fa-check-circle me-1"></i><strong>' + res.inserted + '</strong> kategori eklendi.</div>' +
            (res.error_count > 0 ? '<div class="alert alert-warning py-2 mb-0"><i class="fas fa-exclamation-triangle me-1"></i><strong>' + res.error_count + '</strong> hata.</div>' : '') +
            '</div>';
    } else {
        s.innerHTML = '<div class="alert alert-danger"><i class="fas fa-times-circle me-1"></i>' + escHtml(res.message) + '</div>';
    }
    const ed = document.getElementById('result-errors');
    ed.innerHTML = (res.errors && res.errors.length)
        ? '<div class="grid-card mt-3"><div class="grid-card-header"><div class="grid-card-header-title"><i class="fas fa-exclamation-circle text-warning"></i>Hata Detayları</div></div><div class="card-body p-3"><ul class="mb-0">' +
          res.errors.map(e => '<li class="text-danger small">' + escHtml(e) + '</li>').join('') + '</ul></div></div>'
        : '';
}

function downloadTemplate() {
    const headers = ['Kategori Adı', 'Hiyerarşi', 'Açıklama'];
    const example = ['Örnek Kategori', '01', 'Kategori açıklaması'];
    const wb = XLSX.utils.book_new();
    const ws = XLSX.utils.aoa_to_sheet([headers, example]);
    ws['!cols'] = [25, 12, 35].map(w => ({ wch: w }));
    XLSX.utils.book_append_sheet(wb, ws, 'Kategoriler');
    XLSX.writeFile(wb, 'kategori_import_sablonu.xlsx');
}

function escHtml(str) {
    return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
</script>
