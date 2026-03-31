<cfprocessingdirective pageEncoding="utf-8">

<!--- jQuery yükleme kontrolü --->
<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<!--- Kategorileri getir --->
<cfquery name="getCategories" datasource="boyahane">
    SELECT product_catid, product_cat, hierarchy
    FROM product_cat
    ORDER BY hierarchy, product_cat
</cfquery>

<!--- Markaları getir --->
<cfquery name="getBrands" datasource="boyahane">
    SELECT brand_id, brand_name, brand_code
    FROM product_brands
    WHERE is_active = true
    ORDER BY brand_name
</cfquery>

<!--- JS için dizi hazırla - hierarchy ayrı alan olarak eklendi --->
<cfset catArr = []>
<cfloop query="getCategories">
    <cfset arrayAppend(catArr, {
        "id":        product_catid,
        "name":      product_cat,
        "hierarchy": hierarchy,
        "display":   hierarchy & " - " & product_cat
    })>
</cfloop>

<cfset brandArr = []>
<cfloop query="getBrands">
    <cfset arrayAppend(brandArr, {
        "id":   brand_id,
        "name": brand_name,
        "code": brand_code ?: ""
    })>
</cfloop>

<!--- Page Header --->
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-file-excel"></i>
        </div>
        <div class="page-header-title">
            <h1>Excel'den Ürün İçe Aktar (Hiyerarşi)</h1>
            <p>Kategori hiyerarşisi kullanarak toplu ürün aktarımı yapın</p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=product.list_product" class="btn-back">
        <i class="fas fa-arrow-left"></i>Ürün Listesi
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

        <!--- Talimatlar --->
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
                        <li>Aşağıdaki <strong>Şablon İndir</strong> butonuna tıklayarak örnek Excel şablonunu indirin.</li>
                        <li>Şablona ürünlerinizi doldurun. <strong>Ürün Adı</strong> ve <strong>Hiyerarşi</strong> zorunludur.</li>
                        <li><strong>Hiyerarşi</strong> sütununa kategori hiyerarşi değerini yazın (sağdaki referans tablosuna bakın).</li>
                        <li>Hiyerarşi değeri tam eşleşmezse kategori adı veya "Hiyerarşi - Kategori Adı" formatı da kabul edilir.</li>
                        <li>Hazırladığınız dosyayı yükleme alanına sürükleyin veya tıklayarak seçin.</li>
                        <li>Sütun eşleştirme ekranında Excel sütunlarını doğru alanlara eşleyin.</li>
                        <li>Önizleme tablosunu kontrol edip <strong>İçe Aktar</strong> butonuna basın.</li>
                    </ol>
                    <div class="alert alert-warning py-2 mb-0">
                        <i class="fas fa-exclamation-triangle me-1"></i>
                        <strong>Zorunlu alanlar:</strong> Ürün Adı, Hiyerarşi &nbsp;|&nbsp;
                        <strong>Varsayılanlar:</strong> KDV=18, Aktif=Evet, Satış=Evet, Satın Alma=Evet
                    </div>
                </div>
            </div>
        </div>

        <div class="row g-3">
            <!--- Yükleme Alanı --->
            <div class="col-md-8">
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

            <!--- Referans Tablolar --->
            <div class="col-md-4">
                <!--- Kategoriler - Hiyerarşi odaklı --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-sitemap"></i>Hiyerarşi Referansı</div>
                        <button class="btn btn-sm btn-outline-secondary" type="button" data-bs-toggle="collapse" data-bs-target="#collapseCats">
                            <i class="fas fa-chevron-down"></i>
                        </button>
                    </div>
                    <div class="collapse show" id="collapseCats">
                        <div class="card-body p-0" style="max-height:200px;overflow-y:auto;">
                            <table class="table table-sm table-hover mb-0">
                                <thead class="table-light sticky-top">
                                    <tr><th>Hiyerarşi</th><th>Kategori Adı</th></tr>
                                </thead>
                                <tbody>
                                    <cfoutput query="getCategories">
                                    <tr>
                                        <td><strong class="text-primary">#hierarchy#</strong></td>
                                        <td><small>#product_cat#</small></td>
                                    </tr>
                                    </cfoutput>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <!--- Markalar --->
                <cfif getBrands.recordCount gt 0>
                <div class="grid-card">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-tag"></i>Marka Referansı</div>
                        <button class="btn btn-sm btn-outline-secondary" type="button" data-bs-toggle="collapse" data-bs-target="#collapseBrands">
                            <i class="fas fa-chevron-down"></i>
                        </button>
                    </div>
                    <div class="collapse show" id="collapseBrands">
                        <div class="card-body p-0" style="max-height:160px;overflow-y:auto;">
                            <table class="table table-sm table-hover mb-0">
                                <thead class="table-light sticky-top">
                                    <tr><th>ID</th><th>Marka</th></tr>
                                </thead>
                                <tbody>
                                    <cfoutput query="getBrands">
                                    <tr>
                                        <td><strong>#brand_id#</strong></td>
                                        <td><small>#brand_name#<cfif len(trim(brand_code))> (#brand_code#)</cfif></small></td>
                                    </tr>
                                    </cfoutput>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
                </cfif>
            </div>
        </div>
    </div><!--- /step1 --->

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
                <p class="text-muted small mb-3">
                    <i class="fas fa-magic me-1"></i>Excel sütunları otomatik eşleştirildi. Yanlış eşleşmeleri aşağıdan düzelterek <strong>Önizleme Oluştur</strong> butonuna tıklayın.
                </p>
                <div class="table-responsive">
                    <table class="table table-bordered table-sm align-middle" id="mapper-table">
                        <thead class="table-light">
                            <tr>
                                <th>Excel Sütunu</th>
                                <th>Örnek Veri</th>
                                <th>Eşleştirilecek Alan</th>
                            </tr>
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
    </div><!--- /step2 --->

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
                    <table class="table table-sm table-bordered table-hover" id="preview-table">
                        <thead class="table-light sticky-top" id="preview-thead"></thead>
                        <tbody id="preview-tbody"></tbody>
                    </table>
                </div>
                <div class="d-flex gap-2 mt-3 align-items-center flex-wrap">
                    <button class="btn btn-success" id="btn-import" onclick="doImport()">
                        <i class="fas fa-upload me-1"></i>İçe Aktar
                    </button>
                    <div id="import-progress" style="display:none" class="text-muted small">
                        <i class="fas fa-spinner fa-spin me-1"></i>İçe aktarılıyor, lütfen bekleyin...
                    </div>
                </div>
            </div>
        </div>
    </div><!--- /step3 --->

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
                    <a href="/index.cfm?fuseaction=product.list_product" class="btn btn-outline-secondary">
                        <i class="fas fa-list me-1"></i>Ürün Listesine Git
                    </a>
                </div>
            </div>
        </div>
    </div><!--- /step4 --->

</div><!--- /px-3 --->

<!--- Kategori ve Marka verilerini JS'e aktar --->
<cfoutput>
<script>
const CATEGORIES = #serializeJSON(catArr)#;
const BRANDS     = #serializeJSON(brandArr)#;
</script>
</cfoutput>

<!--- SheetJS --->
<script src="https://cdn.sheetjs.com/xlsx-latest/package/dist/xlsx.full.min.js"></script>

<script>
/* ====================================================
   ALAN TANIMLARI
   - product_catid yerine hierarchy kullanılıyor
   ==================================================== */
const FIELDS = [
    { key: 'product_name',    label: 'Ürün Adı',        required: true  },
    { key: 'hierarchy',       label: 'Hiyerarşi',        required: true  },
    { key: 'product_code',    label: 'Ürün Kodu',        required: false },
    { key: 'barcod',          label: 'Barkod',           required: false },
    { key: 'brand_id',        label: 'Marka',            required: false },
    { key: 'product_detail',  label: 'Ürün Detayı',      required: false },
    { key: 'tax',             label: 'KDV (%)',          required: false },
    { key: 'manufact_code',   label: 'Üretici Kodu',     required: false },
    { key: 'short_code',      label: 'Kısa Kod',         required: false },
    { key: 'shelf_life',      label: 'Raf Ömrü',         required: false },
    { key: 'product_status',  label: 'Aktif (1/0)',      required: false },
    { key: 'is_sales',        label: 'Satış (1/0)',      required: false },
    { key: 'is_purchase',     label: 'Satın Alma (1/0)', required: false },
];

/* Otomatik başlık eşleştirme tablosu */
const AUTO_HEADER_MAP = {
    'ürün kodu':'product_code', 'urun kodu':'product_code', 'product code':'product_code',
    'product_code':'product_code', 'kod':'product_code',
    'ürün adı':'product_name', 'urun adi':'product_name', 'ürün':'product_name',
    'product name':'product_name', 'product_name':'product_name', 'ad':'product_name',
    'adı':'product_name', 'name':'product_name',
    'hiyerarşi':'hierarchy', 'hiyerarsi':'hierarchy', 'hierarchy':'hierarchy',
    'kategori hiyerarşisi':'hierarchy', 'kategori hiyerarsisi':'hierarchy',
    'hiyerarşi kodu':'hierarchy', 'grup':'hierarchy',
    'barkod':'barcod', 'barcode':'barcod', 'barcod':'barcod',
    'marka id':'brand_id', 'marka':'brand_id', 'brand id':'brand_id',
    'brand_id':'brand_id', 'marka adı':'brand_id',
    'ürün detayı':'product_detail', 'urun detayi':'product_detail', 'detay':'product_detail',
    'product detail':'product_detail', 'product_detail':'product_detail', 'açıklama':'product_detail',
    'kdv':'tax', 'kdv (%)':'tax', 'vergi':'tax', 'tax':'tax', 'kdv oranı':'tax',
    'üretici kodu':'manufact_code', 'uretici kodu':'manufact_code',
    'manufact code':'manufact_code', 'manufact_code':'manufact_code', 'üretici':'manufact_code',
    'kısa kod':'short_code', 'kisa kod':'short_code', 'short code':'short_code',
    'short_code':'short_code',
    'raf ömrü':'shelf_life', 'raf omru':'shelf_life', 'shelf life':'shelf_life',
    'shelf_life':'shelf_life',
    'aktif':'product_status', 'durum':'product_status', 'status':'product_status',
    'product_status':'product_status',
    'satış':'is_sales', 'satis':'is_sales', 'is_sales':'is_sales', 'sales':'is_sales',
    'satın alma':'is_purchase', 'satin alma':'is_purchase', 'is_purchase':'is_purchase',
    'purchase':'is_purchase',
};

/* ====================================================
   DURUM
   ==================================================== */
let excelHeaders  = [];
let excelRows     = [];
let columnMapping = {};

/* ====================================================
   YARDIMCI FONKSİYONLAR
   ==================================================== */
function toBool(val, def = true) {
    if (val === null || val === undefined || val === '') return def;
    if (typeof val === 'boolean') return val;
    const s = String(val).toLowerCase().trim();
    return s === '1' || s === 'true' || s === 'evet' || s === 'yes';
}

/**
 * Hiyerarşi değerini arama önceliğine göre kategori kaydına çevirir.
 * 1. Tam hiyerarşi eşleşmesi  (c.hierarchy)
 * 2. Tam display eşleşmesi    ("hierarchy - name")
 * 3. Tam kategori adı eşleşmesi (c.name)
 * 4. Hiyerarşi içerik araması  (içerir)
 * Bulunamazsa null döner.
 */
function resolveCategoryByHierarchy(val) {
    if (val === null || val === undefined || String(val).trim() === '') return null;
    const s = String(val).toLowerCase().trim();

    // 1. Tam hiyerarşi eşleşmesi
    let cat = CATEGORIES.find(c => c.hierarchy.toLowerCase() === s);
    if (cat) return cat;

    // 2. Tam "hiyerarşi - kategori adı" display eşleşmesi
    cat = CATEGORIES.find(c => c.display.toLowerCase() === s);
    if (cat) return cat;

    // 3. Tam kategori adı eşleşmesi
    cat = CATEGORIES.find(c => c.name.toLowerCase() === s);
    if (cat) return cat;

    // 4. Hiyerarşi starts-with araması
    cat = CATEGORIES.find(c => c.hierarchy.toLowerCase().startsWith(s) || s.startsWith(c.hierarchy.toLowerCase()));
    if (cat) return cat;

    return null;
}

function resolveBrandId(val) {
    if (!val && val !== 0) return 0;
    const n = parseInt(val);
    if (!isNaN(n) && n > 0) return n;
    const name = String(val).toLowerCase().trim();
    const brand = BRANDS.find(b =>
        b.name.toLowerCase() === name ||
        (b.code && b.code.toLowerCase() === name)
    );
    return brand ? brand.id : 0;
}

function getBrandDisplay(id) {
    const brand = BRANDS.find(b => b.id == id);
    return brand ? brand.name : (id ? 'ID: ' + id : '');
}

/* ====================================================
   ADIM YÖNETİMİ
   ==================================================== */
function goToStep(n) {
    document.getElementById('step1').style.display = n === 1 ? '' : 'none';
    document.getElementById('step2').style.display = n === 2 ? '' : 'none';
    document.getElementById('step3').style.display = n === 3 ? '' : 'none';
    document.getElementById('step4').style.display = n === 4 ? '' : 'none';
    for (let i = 1; i <= 4; i++) {
        const badge = document.getElementById('badge-step' + i);
        badge.className = 'badge fs-6 step-badge ' + (i === n ? 'bg-primary' : (i < n ? 'bg-success' : 'bg-secondary'));
    }
}

function resetUpload() {
    excelHeaders  = [];
    excelRows     = [];
    columnMapping = {};
    document.getElementById('fileInput').value = '';
    document.getElementById('file-info').style.display = 'none';
    goToStep(1);
}

/* ====================================================
   DOSYA İŞLEME
   ==================================================== */
function handleDrop(e) {
    e.preventDefault();
    const dropzone = document.getElementById('dropzone');
    dropzone.style.borderColor = '#adb5bd';
    dropzone.style.background = '';
    const file = e.dataTransfer.files[0];
    if (file) processFile(file);
}

function handleFileInput(input) {
    if (input.files[0]) processFile(input.files[0]);
}

function processFile(file) {
    const allowed = ['.xlsx', '.xls'];
    const ext = file.name.substring(file.name.lastIndexOf('.')).toLowerCase();
    if (!allowed.includes(ext)) {
        alert('Lütfen .xlsx veya .xls dosyası seçin.');
        return;
    }

    const reader = new FileReader();
    reader.onload = function(e) {
        try {
            const data     = new Uint8Array(e.target.result);
            const workbook = XLSX.read(data, { type: 'array' });
            const sheet    = workbook.Sheets[workbook.SheetNames[0]];
            const rows     = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: '' });

            if (!rows || rows.length < 2) {
                alert('Excel dosyası en az bir başlık satırı ve bir veri satırı içermelidir.');
                return;
            }

            excelHeaders = rows[0].map(h => String(h).trim());
            excelRows    = rows.slice(1).filter(r => r.some(cell => String(cell).trim() !== ''));

            if (excelRows.length === 0) {
                alert('Excel dosyasında veri satırı bulunamadı.');
                return;
            }
            if (excelRows.length > 5000) {
                alert('Tek seferde en fazla 5000 satır aktarabilirsiniz. Dosyanızda ' + excelRows.length + ' satır var.');
                return;
            }

            // Otomatik eşleştir
            columnMapping = {};
            excelHeaders.forEach(h => {
                const key = AUTO_HEADER_MAP[h.toLowerCase()] || null;
                columnMapping[h] = key;
            });

            document.getElementById('file-name').textContent =
                file.name + ' (' + excelRows.length + ' satır)';
            document.getElementById('file-info').style.display = '';

            renderMapper();
            goToStep(2);
        } catch (err) {
            alert('Dosya okunurken hata oluştu: ' + err.message);
        }
    };
    reader.readAsArrayBuffer(file);
}

/* ====================================================
   SÜTUN EŞLEŞTİRME EKRANI
   ==================================================== */
function renderMapper() {
    const optionsHtml = '<option value="">— Yoksay —</option>' +
        FIELDS.map(f => '<option value="' + f.key + '">' + f.label + (f.required ? ' *' : '') + '</option>').join('');

    const sample = excelRows[0] || [];
    const tbody  = document.getElementById('mapper-body');
    tbody.innerHTML = excelHeaders.map((h, i) => {
        const mapped    = columnMapping[h] || '';
        const sampleVal = String(sample[i] || '').substring(0, 50);
        const opts      = optionsHtml.replace('value="' + mapped + '">', 'value="' + mapped + '" selected>');
        return '<tr>' +
            '<td><strong>' + escHtml(h) + '</strong></td>' +
            '<td><small class="text-muted">' + escHtml(sampleVal) + '</small></td>' +
            '<td><select class="form-select form-select-sm col-mapper" data-col="' + escHtml(h) + '">' + opts + '</select></td>' +
            '</tr>';
    }).join('');

    document.querySelectorAll('.col-mapper').forEach(sel => {
        sel.addEventListener('change', function() {
            columnMapping[this.dataset.col] = this.value || null;
        });
    });
}

/* ====================================================
   ÖNİZLEME OLUŞTUR
   ==================================================== */
function buildPreview() {
    const hasProdName  = Object.values(columnMapping).includes('product_name');
    const hasHierarchy = Object.values(columnMapping).includes('hierarchy');
    if (!hasProdName)  { alert('"Ürün Adı" alanını bir sütuna eşleştirmeniz zorunludur.'); return; }
    if (!hasHierarchy) { alert('"Hiyerarşi" alanını bir sütuna eşleştirmeniz zorunludur.'); return; }

    // Ters map: fieldKey -> colIndex
    const fieldToColIdx = {};
    excelHeaders.forEach((h, i) => {
        if (columnMapping[h]) fieldToColIdx[columnMapping[h]] = i;
    });

    // Eşleştirilen alanları belirle
    const mappedFields = FIELDS.filter(f => fieldToColIdx.hasOwnProperty(f.key));

    // Başlık
    const thead = document.getElementById('preview-thead');
    thead.innerHTML = '<tr><th>#</th>' +
        mappedFields.map(f => '<th>' + f.label + (f.required ? ' <span class="text-danger">*</span>' : '') + '</th>').join('') +
        '<th>Kategori (Çözümlendi)</th><th>Durum</th></tr>';

    let validCount = 0, invalidCount = 0;
    const tbody = document.getElementById('preview-tbody');
    const maxPreview = Math.min(excelRows.length, 500);
    const rows = [];

    for (let i = 0; i < maxPreview; i++) {
        const raw    = excelRows[i];
        const errors = [];

        const pName   = String(raw[fieldToColIdx['product_name']] || '').trim();
        const hierRaw = fieldToColIdx.hasOwnProperty('hierarchy')
            ? raw[fieldToColIdx['hierarchy']]
            : '';
        const resolvedCat = resolveCategoryByHierarchy(hierRaw);
        const catId       = resolvedCat ? resolvedCat.id : 0;

        if (!pName)  errors.push('Ürün adı boş');
        if (!catId)  errors.push('Hiyerarşi bulunamadı: "' + hierRaw + '"');

        const rowClass = errors.length ? 'table-danger' : 'table-success';
        if (errors.length) invalidCount++; else validCount++;

        const cells = mappedFields.map(f => {
            let val = raw[fieldToColIdx[f.key]] !== undefined ? raw[fieldToColIdx[f.key]] : '';
            if (f.key === 'brand_id') {
                const bid = resolveBrandId(val);
                val = bid ? getBrandDisplay(bid) : (val ? '⚠ ' + val : '');
            } else if (f.key === 'product_status' || f.key === 'is_sales' || f.key === 'is_purchase') {
                val = toBool(val, true) ? '✓ Evet' : '✗ Hayır';
            } else if (f.key === 'tax') {
                val = (parseFloat(val) || 18) + '%';
            }
            return '<td>' + escHtml(String(val).substring(0, 80)) + '</td>';
        }).join('');

        // Çözümlenen kategori sütunu
        const catCell = resolvedCat
            ? '<td><span class="badge bg-success">' + escHtml(resolvedCat.display) + '</span></td>'
            : '<td><span class="badge bg-danger">⚠ ' + escHtml(String(hierRaw)) + '</span></td>';

        const statusCell = errors.length
            ? '<td><span class="badge bg-danger">' + errors.join(', ') + '</span></td>'
            : '<td><span class="badge bg-success">Geçerli</span></td>';

        rows.push('<tr class="' + rowClass + '"><td>' + (i + 2) + '</td>' + cells + catCell + statusCell + '</tr>');
    }

    tbody.innerHTML = rows.join('');

    const hidden = excelRows.length - maxPreview;
    const statsHtml = '<div class="d-flex gap-3 flex-wrap">' +
        '<span class="badge bg-success fs-6"><i class="fas fa-check me-1"></i>' + validCount + ' Geçerli</span>' +
        '<span class="badge bg-danger fs-6"><i class="fas fa-times me-1"></i>' + invalidCount + ' Hatalı</span>' +
        '<span class="text-muted small">Toplam: ' + excelRows.length + ' satır' + (hidden ? ' (ilk 500 gösteriliyor)' : '') + '</span>' +
        '</div>';
    document.getElementById('preview-stats').innerHTML = statsHtml;

    if (validCount === 0) {
        alert('Geçerli kayıt bulunamadı. Lütfen hiyerarşi değerlerini ve sütun eşleştirmelerini kontrol edin.');
        return;
    }

    goToStep(3);
}

/* ====================================================
   İÇE AKTAR
   ==================================================== */
function doImport() {
    const fieldToColIdx = {};
    excelHeaders.forEach((h, i) => {
        if (columnMapping[h]) fieldToColIdx[columnMapping[h]] = i;
    });

    const products = [];
    excelRows.forEach((raw, i) => {
        const pName   = String(raw[fieldToColIdx['product_name']] || '').trim();
        const hierRaw = fieldToColIdx.hasOwnProperty('hierarchy')
            ? raw[fieldToColIdx['hierarchy']]
            : '';
        const resolvedCat = resolveCategoryByHierarchy(hierRaw);
        const catId       = resolvedCat ? resolvedCat.id : 0;

        // Geçersiz satırları atla
        if (!pName || !catId) return;

        const brandRaw = fieldToColIdx.hasOwnProperty('brand_id') ? raw[fieldToColIdx['brand_id']] : '';

        products.push({
            row_num:        i + 2,
            product_name:   pName,
            product_catid:  catId,
            product_code:   String(fieldToColIdx.hasOwnProperty('product_code')  ? raw[fieldToColIdx['product_code']]  : '').trim(),
            barcod:         String(fieldToColIdx.hasOwnProperty('barcod')         ? raw[fieldToColIdx['barcod']]         : '').trim(),
            brand_id:       resolveBrandId(brandRaw),
            product_detail: String(fieldToColIdx.hasOwnProperty('product_detail') ? raw[fieldToColIdx['product_detail']] : '').trim(),
            tax:            parseFloat(fieldToColIdx.hasOwnProperty('tax')         ? raw[fieldToColIdx['tax']]            : 18) || 18,
            manufact_code:  String(fieldToColIdx.hasOwnProperty('manufact_code')  ? raw[fieldToColIdx['manufact_code']]  : '').trim(),
            short_code:     String(fieldToColIdx.hasOwnProperty('short_code')     ? raw[fieldToColIdx['short_code']]     : '').trim(),
            shelf_life:     String(fieldToColIdx.hasOwnProperty('shelf_life')     ? raw[fieldToColIdx['shelf_life']]     : '').trim(),
            product_status: toBool(fieldToColIdx.hasOwnProperty('product_status') ? raw[fieldToColIdx['product_status']] : 1, true),
            is_sales:       toBool(fieldToColIdx.hasOwnProperty('is_sales')       ? raw[fieldToColIdx['is_sales']]       : 1, true),
            is_purchase:    toBool(fieldToColIdx.hasOwnProperty('is_purchase')    ? raw[fieldToColIdx['is_purchase']]    : 1, true),
        });
    });

    if (products.length === 0) {
        alert('İçe aktarılacak geçerli kayıt bulunamadı.');
        return;
    }

    document.getElementById('btn-import').disabled = true;
    document.getElementById('import-progress').style.display = '';

    $.ajax({
        url:  '/product/cfc/product.cfc?method=importProducts',
        type: 'POST',
        data: { productsJSON: JSON.stringify(products) },
        dataType: 'json',
        success: function(res) {
            showResults(res);
        },
        error: function(xhr) {
            let msg = 'Sunucu hatası oluştu.';
            try { msg = JSON.parse(xhr.responseText).message || msg; } catch (e) { /* ignore */ }
            alert('Hata: ' + msg);
            document.getElementById('btn-import').disabled = false;
            document.getElementById('import-progress').style.display = 'none';
        }
    });
}

function showResults(res) {
    goToStep(4);

    const summary = document.getElementById('result-summary');
    if (res.success) {
        summary.innerHTML = '<div class="row g-3">' +
            '<div class="col-auto"><div class="alert alert-success py-2 mb-0">' +
            '<i class="fas fa-check-circle me-1"></i><strong>' + res.inserted + '</strong> ürün başarıyla eklendi.</div></div>' +
            (res.error_count > 0 ? '<div class="col-auto"><div class="alert alert-warning py-2 mb-0">' +
            '<i class="fas fa-exclamation-triangle me-1"></i><strong>' + res.error_count + '</strong> satırda hata oluştu.</div></div>' : '') +
            '</div>';
    } else {
        summary.innerHTML = '<div class="alert alert-danger"><i class="fas fa-times-circle me-1"></i>' + escHtml(res.message) + '</div>';
    }

    const errDiv = document.getElementById('result-errors');
    if (res.errors && res.errors.length > 0) {
        errDiv.innerHTML = '<div class="grid-card mt-3"><div class="grid-card-header">' +
            '<div class="grid-card-header-title"><i class="fas fa-exclamation-circle text-warning"></i>Hata Detayları</div></div>' +
            '<div class="card-body p-3"><ul class="mb-0">' +
            res.errors.map(e => '<li class="text-danger small">' + escHtml(e) + '</li>').join('') +
            '</ul></div></div>';
    } else {
        errDiv.innerHTML = '';
    }
}

/* ====================================================
   ŞABLON İNDİR
   ==================================================== */
function downloadTemplate() {
    const headers = [
        'Ürün Kodu', 'Ürün Adı', 'Hiyerarşi', 'Barkod', 'Marka ID',
        'Ürün Detayı', 'KDV (%)', 'Üretici Kodu', 'Kısa Kod', 'Raf Ömrü',
        'Aktif', 'Satış', 'Satın Alma'
    ];
    const exampleHierarchy = CATEGORIES.length ? CATEGORIES[0].hierarchy : 'Örnek Hiyerarşi';
    const example = [
        'BOYA001', 'Örnek Ürün Adı',
        exampleHierarchy,
        '1234567890123',
        BRANDS.length ? BRANDS[0].id : '',
        'Örnek ürün açıklaması', 18, 'ÜR-001', 'KOD1', '12 ay', 1, 1, 1
    ];

    const wb = XLSX.utils.book_new();
    const ws = XLSX.utils.aoa_to_sheet([headers, example]);

    ws['!cols'] = [10, 25, 20, 18, 10, 30, 8, 15, 12, 12, 8, 8, 12].map(w => ({ wch: w }));

    XLSX.utils.book_append_sheet(wb, ws, 'Ürünler');
    XLSX.writeFile(wb, 'urun_import_hiyerarsi_sablonu.xlsx');
}

/* ====================================================
   YARDIMCI
   ==================================================== */
function escHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}
</script>
