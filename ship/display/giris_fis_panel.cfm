<cfprocessingdirective pageEncoding="utf-8">

<!--- Giriş Fişi listesi (sol panel için) --->
<cfquery name="getFisler" datasource="boyahane">
    SELECT
        s.ship_id,
        s.ship_number,
        s.hk_metre,
        s.hk_kg,
        s.hk_top_adedi,
        s.hk_parti_no,
        s.is_ship_iptal,
        s.record_date,
        COALESCE(c.nickname, c.fullname, '') AS company_name,
        COALESCE((
            SELECT COUNT(*) FROM orders o
            WHERE o.ref_ship_id = s.ship_id
               OR (o.ref_ship_id IS NULL AND o.ref_no IS NOT NULL AND o.ref_no <> '' AND o.ref_no = s.ship_number)
        ), 0) AS parti_count,
        COALESCE((
            SELECT SUM(orw.quantity)
            FROM orders o
            JOIN order_row orw ON o.order_id = orw.order_id
            WHERE (o.ref_ship_id = s.ship_id
               OR (o.ref_ship_id IS NULL AND o.ref_no IS NOT NULL AND o.ref_no <> '' AND o.ref_no = s.ship_number))
              AND orw.product_id = (
                  SELECT sr2.product_id FROM ship_row sr2
                  WHERE sr2.ship_id = s.ship_id
                  ORDER BY sr2.ship_row_id LIMIT 1
              )
        ), 0) AS parti_metre
    FROM ship s
    LEFT JOIN company c ON s.company_id = c.company_id
    WHERE s.ship_type = 5
    ORDER BY s.ship_id DESC
</cfquery>

<!--- Sarım şekli ve ambalaj (parti modalı için) --->
<cfquery name="getSarimSekli" datasource="boyahane">
    SELECT sarim_sekli_id, sarim_sekli_adi FROM setup_sarim_sekli
    WHERE is_active = true ORDER BY sort_order, sarim_sekli_adi
</cfquery>
<cfquery name="getAmbalaj" datasource="boyahane">
    SELECT ambalaj_id, ambalaj_adi FROM setup_ambalaj
    WHERE is_active = true ORDER BY sort_order, ambalaj_adi
</cfquery>
<cfset sarimArr = []>
<cfloop query="getSarimSekli">
    <cfset arrayAppend(sarimArr, {"id": val(sarim_sekli_id), "label": sarim_sekli_adi ?: ""})>
</cfloop>
<cfset ambalajArr = []>
<cfloop query="getAmbalaj">
    <cfset arrayAppend(ambalajArr, {"id": val(ambalaj_id), "label": ambalaj_adi ?: ""})>
</cfloop>

<cfset fisArr = []>
<cfloop query="getFisler">
    <cfset arrayAppend(fisArr, {
        "ship_id":      val(ship_id),
        "ship_number":  ship_number  ?: "",
        "company_name": company_name ?: "",
        "hk_metre":     isNumeric(hk_metre)     ? val(hk_metre)     : 0,
        "hk_kg":        isNumeric(hk_kg)        ? val(hk_kg)        : 0,
        "hk_top_adedi": isNumeric(hk_top_adedi) ? val(hk_top_adedi) : 0,
        "hk_parti_no":  hk_parti_no  ?: "",
        "is_ship_iptal": (is_ship_iptal EQ true OR is_ship_iptal EQ "true" OR is_ship_iptal EQ "YES"),
        "parti_count":  val(parti_count),
        "parti_metre":  isNumeric(parti_metre)  ? val(parti_metre)  : 0,
        "record_date":  isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") : ""
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-dolly-flatbed"></i></div>
        <div class="page-header-title">
            <h1>Giriş Fişi Paneli</h1>
            <p>Ham kumaş giriş takibi ve parti yönetimi</p>
        </div>
    </div>
</div>

<div class="px-3 pb-5">

    <!--- ══════════════ TOOLBAR (col-12) ══════════════ --->
    <div class="row mb-3">
        <div class="col-12">
            <div class="grid-card">
                <div class="card-body p-2 d-flex flex-wrap gap-2 align-items-center">

                    <button class="btn btn-primary btn-sm" onclick="openYeniFisModal()">
                        <i class="fas fa-plus me-1"></i>Yeni Giriş Fişi
                    </button>
                    <div class="vr mx-1"></div>
                    <button class="btn btn-outline-primary btn-sm" id="btnDuzenle" disabled onclick="editSelected()">
                        <i class="fas fa-edit me-1"></i>Düzenle
                    </button>
                    <button class="btn btn-outline-success btn-sm" id="btnPartiOlustur" disabled onclick="partiOlustur()">
                        <i class="fas fa-cut me-1"></i>Parti Oluştur
                    </button>
                    <button class="btn btn-outline-info btn-sm" id="btnPartiListesi" disabled onclick="partiListesi()">
                        <i class="fas fa-list-ol me-1"></i>Parti Listesi
                    </button>
                    <div class="vr mx-1"></div>
                    <button class="btn btn-outline-danger btn-sm" id="btnSil" disabled onclick="silSelected()" title="Seçili fişi sil">
                        <i class="fas fa-trash me-1"></i>Sil
                    </button>

                    <div class="ms-auto d-flex align-items-center gap-2">
                        <div class="input-group input-group-sm" style="width:220px">
                            <span class="input-group-text bg-white border-end-0"><i class="fas fa-search text-muted" style="font-size:.75rem"></i></span>
                            <input type="text" class="form-control border-start-0 ps-0"
                                   id="listSearch" placeholder="Ara (no, firma, parti no...)"
                                   oninput="filterList(this.value)">
                        </div>
                        <span class="badge bg-secondary" id="listCount">#getFisler.recordCount# kayıt</span>
                    </div>

                </div>
            </div>
        </div>
    </div>

    <!--- ══════════════ ANA PANEL ══════════════ --->
    <div class="row g-3">

        <!--- ─── SOL: Giriş Fişi Listesi (col-3) ─── --->
        <div class="col-xl-3 col-lg-4">
            <div class="grid-card" style="height:calc(100vh - 230px)">
                <div class="grid-card-header py-2 px-3">
                    <div class="grid-card-header-title small fw-semibold">
                        <i class="fas fa-list me-1"></i>Giriş Fişleri
                    </div>
                    <span class="badge bg-primary rounded-pill" id="listBadge">#getFisler.recordCount#</span>
                </div>
                <div id="fisList" style="overflow-y:auto;height:calc(100% - 42px)">
                    <!--- JS ile render edilir --->
                </div>
            </div>
        </div>

        <!--- ─── SAĞ: Detay + Partiler (col-9) ─── --->
        <div class="col-xl-9 col-lg-8">

            <!--- Boş durum --->
            <div id="rightEmpty" class="grid-card d-flex align-items-center justify-content-center text-muted"
                 style="height:calc(100vh - 230px)">
                <div class="text-center">
                    <i class="fas fa-hand-point-left fa-3x mb-3 d-block" style="opacity:.2"></i>
                    <p class="mb-1 fw-semibold">Giriş fişi seçin</p>
                    <small>Sol listeden bir giriş fişine tıklayın</small>
                </div>
            </div>

            <!--- İçerik paneli (başta gizli) --->
            <div id="rightContent" class="d-none" style="height:calc(100vh - 230px);overflow-y:auto;display:flex!important;flex-direction:column;gap:12px">

                <!--- ÜST: Giriş Fişi Detayı --->
                <div class="grid-card flex-shrink-0" id="detayCard">
                    <div class="grid-card-header py-2 px-3">
                        <div class="grid-card-header-title">
                            <i class="fas fa-receipt"></i>
                            <span id="detayTitle">Giriş Fişi Detayı</span>
                        </div>
                        <div id="detayBadges" class="d-flex gap-1 flex-wrap"></div>
                    </div>
                    <div class="card-body p-3" id="detayBody">
                        <div class="text-center text-muted py-4">
                            <i class="fas fa-spinner fa-spin me-2"></i>Yükleniyor...
                        </div>
                    </div>
                </div>

                <!--- ALT: Partiler --->
                <div class="grid-card flex-grow-1" id="partilerCard">
                    <div class="grid-card-header py-2 px-3">
                        <div class="grid-card-header-title">
                            <i class="fas fa-cut"></i>Partiler
                            <span class="badge bg-secondary ms-1 rounded-pill" id="partiBadge">0</span>
                        </div>
                        <button class="btn btn-sm btn-outline-success" id="btnPartiOlusturInline"
                                onclick="partiOlustur()" title="Yeni parti oluştur" style="display:none">
                            <i class="fas fa-plus me-1"></i>Parti Ekle
                        </button>
                    </div>
                    <div class="card-body p-0" id="partilerBody">
                        <div class="text-center text-muted py-4">
                            <i class="fas fa-spinner fa-spin me-2"></i>Yükleniyor...
                        </div>
                    </div>
                </div>

            </div>

        </div>
    </div>

</div>

<!--- ══════════════ MODAL: YENİ GİRİŞ FİŞİ ══════════════ --->
<div class="modal fade" id="modalYeniFis" tabindex="-1" aria-labelledby="modalYeniFisLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-scrollable">
        <div class="modal-content">
            <div class="modal-header py-2">
                <h6 class="modal-title fw-semibold" id="modalYeniFisLabel">
                    <i class="fas fa-plus-circle me-2 text-primary"></i>Yeni Giriş Fişi
                </h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-3">

                <!--- Firma --->
                <div class="mb-3 position-relative">
                    <label class="form-label fw-semibold small mb-1">
                        <i class="fas fa-building me-1 text-primary"></i>Firma <span class="text-danger">*</span>
                    </label>
                    <input type="text" class="form-control form-control-sm" id="mfis_companySearch"
                           placeholder="Firma adı ile arayın..." autocomplete="off"
                           oninput="mfis_filterCompany(this.value)"
                           onfocus="mfis_filterCompany(this.value)">
                    <input type="hidden" id="mfis_company_id" value="0">
                    <div id="mfis_companyDropdown" class="search-dropdown d-none"></div>
                </div>

                <!--- Stok --->
                <div class="mb-3 position-relative">
                    <label class="form-label fw-semibold small mb-1">
                        <i class="fas fa-box me-1 text-primary"></i>Stok / Ürün <span class="text-danger">*</span>
                    </label>
                    <input type="text" class="form-control form-control-sm" id="mfis_stockSearch"
                           placeholder="Önce firma seçin..." autocomplete="off" disabled
                           oninput="mfis_filterStock(this.value)">
                    <input type="hidden" id="mfis_stock_id"   value="0">
                    <input type="hidden" id="mfis_product_id" value="0">
                    <div id="mfis_stockDropdown" class="search-dropdown d-none"></div>
                    <div id="mfis_stockSelected" class="mt-1 d-none">
                        <small class="text-success"><i class="fas fa-check-circle me-1"></i><span id="mfis_stockLabel"></span></small>
                    </div>
                </div>

                <!--- Metrik bilgiler --->
                <div class="row g-2 mb-3">
                    <div class="col-4">
                        <label class="form-label small mb-1 fw-semibold">Metre</label>
                        <input type="number" class="form-control form-control-sm" id="mfis_hk_metre"
                               step="0.001" min="0" placeholder="0.000">
                    </div>
                    <div class="col-4">
                        <label class="form-label small mb-1 fw-semibold">Kg</label>
                        <input type="number" class="form-control form-control-sm" id="mfis_hk_kg"
                               step="0.001" min="0" placeholder="0.000">
                    </div>
                    <div class="col-4">
                        <label class="form-label small mb-1 fw-semibold">Top Adedi</label>
                        <input type="number" class="form-control form-control-sm" id="mfis_hk_top_adedi"
                               step="1" min="0" placeholder="0">
                    </div>
                </div>

                <!--- Toggle'lar --->
                <div class="row g-2 mb-3">
                    <div class="col-6">
                        <label class="form-label small mb-1 fw-semibold d-block">Kumaş Durumu</label>
                        <div class="btn-group w-100" role="group">
                            <input type="radio" class="btn-check" name="mfis_ham_boyali" id="mfis_ham"    value="true"  checked>
                            <label class="btn btn-outline-success btn-sm" for="mfis_ham">Ham</label>
                            <input type="radio" class="btn-check" name="mfis_ham_boyali" id="mfis_boyali" value="false">
                            <label class="btn btn-outline-success btn-sm" for="mfis_boyali">Boyalı</label>
                        </div>
                    </div>
                    <div class="col-6">
                        <label class="form-label small mb-1 fw-semibold d-block">Ücret Durumu</label>
                        <div class="btn-group w-100" role="group">
                            <input type="radio" class="btn-check" name="mfis_ucretli" id="mfis_ucretli_e" value="true"  checked>
                            <label class="btn btn-outline-success btn-sm" for="mfis_ucretli_e">Ücretli</label>
                            <input type="radio" class="btn-check" name="mfis_ucretli" id="mfis_ucretli_h" value="false">
                            <label class="btn btn-outline-success btn-sm" for="mfis_ucretli_h">Ücretsiz</label>
                        </div>
                    </div>
                </div>

                <!--- Açıklama --->
                <div class="mb-0">
                    <label class="form-label small mb-1 fw-semibold">Açıklama <span class="text-muted">(opsiyonel)</span></label>
                    <textarea class="form-control form-control-sm" id="mfis_ship_detail" rows="2"
                              placeholder="Giriş açıklaması..."></textarea>
                </div>

                <div id="mfis_errorMsg" class="alert alert-danger mt-2 py-2 d-none"></div>

            </div>
            <div class="modal-footer py-2">
                <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-sm btn-primary" id="mfis_saveBtn" onclick="saveFisModal()">
                    <i class="fas fa-save me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<!--- ══════════════ MODAL: YENİ PARTİ ══════════════ --->
<div class="modal fade" id="modalYeniParti" tabindex="-1" aria-labelledby="modalYeniPartiLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header py-2">
                <h6 class="modal-title fw-semibold" id="modalYeniPartiLabel">
                    <i class="fas fa-cut me-2 text-success"></i>Yeni Parti
                </h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-3">

                <div id="mprt_loading" class="text-center text-muted py-3">
                    <i class="fas fa-spinner fa-spin me-2"></i>Yükleniyor...
                </div>

                <div id="mprt_form" class="d-none">

                    <!--- Giriş fişi bilgisi --->
                    <div class="alert alert-info py-2 mb-3 small">
                        <i class="fas fa-receipt me-1"></i>
                        <strong id="mprt_fisLabel">—</strong>
                        <span class="text-muted ms-2" id="mprt_companyLabel"></span>
                    </div>

                    <!--- Parti kodu --->
                    <div class="mb-3">
                        <label class="form-label small mb-1 fw-semibold">Parti Kodu</label>
                        <input type="text" class="form-control form-control-sm fw-bold text-primary"
                               id="mprt_parti_kodu" readonly style="background:#f8f9fa;letter-spacing:.04em">
                        <input type="hidden" id="mprt_ship_id"    value="0">
                        <input type="hidden" id="mprt_company_id" value="0">
                        <input type="hidden" id="mprt_stock_id"   value="0">
                        <input type="hidden" id="mprt_product_id" value="0">
                        <input type="hidden" id="mprt_unit"       value="mt">
                        <input type="hidden" id="mprt_unit_id"    value="0">
                        <input type="hidden" id="mprt_product_name" value="">
                        <input type="hidden" id="mprt_ref_no"     value="">
                    </div>

                    <!--- Miktar --->
                    <div class="row g-2 mb-3">
                        <div class="col-6">
                            <label class="form-label small mb-1 fw-semibold">
                                Miktar (mt) <span class="text-danger">*</span>
                            </label>
                            <input type="number" class="form-control form-control-sm" id="mprt_miktar"
                                   step="0.001" min="0.001" placeholder="0.000">
                            <div class="form-text" id="mprt_kalanText"></div>
                        </div>
                        <div class="col-6">
                            <label class="form-label small mb-1 fw-semibold">Kg <span class="text-muted">(opsiyonel)</span></label>
                            <input type="number" class="form-control form-control-sm" id="mprt_kg"
                                   step="0.001" min="0" placeholder="0.000">
                        </div>
                    </div>

                    <!--- Sarım Şekli + Ambalaj --->
                    <div class="row g-2 mb-3">
                        <div class="col-6">
                            <label class="form-label small mb-1 fw-semibold">Sarım Şekli</label>
                            <select class="form-select form-select-sm" id="mprt_sarim_sekli">
                                <option value="0">-- Seçin --</option>
                            </select>
                        </div>
                        <div class="col-6">
                            <label class="form-label small mb-1 fw-semibold">Ambalaj</label>
                            <select class="form-select form-select-sm" id="mprt_ambalaj">
                                <option value="0">-- Seçin --</option>
                            </select>
                        </div>
                    </div>

                    <!--- Açıklama --->
                    <div class="mb-0">
                        <label class="form-label small mb-1 fw-semibold">Açıklama <span class="text-muted">(opsiyonel)</span></label>
                        <input type="text" class="form-control form-control-sm" id="mprt_aciklama"
                               placeholder="Parti notu...">
                    </div>

                </div>

                <div id="mprt_errorMsg" class="alert alert-danger mt-2 py-2 d-none"></div>

            </div>
            <div class="modal-footer py-2">
                <button type="button" class="btn btn-sm btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-sm btn-success d-none" id="mprt_saveBtn" onclick="savePartiModal()">
                    <i class="fas fa-cut me-1"></i>Parti Oluştur
                </button>
            </div>
        </div>
    </div>
</div>

<style>
/* ─── Sol liste ─── */
.fis-item {
    padding: 9px 12px 8px;
    border-bottom: 1px solid ##f0f0f0;
    cursor: pointer;
    transition: background .12s;
    border-left: 3px solid transparent;
}
.fis-item:hover  { background: ##f5f8ff; }
.fis-item.active { background: ##e8f0fe; border-left-color: ##1967d2; }
.fis-item.iptal  { opacity: .55; }
.fis-no   { font-weight: 700; font-size: .83rem; color: ##1967d2; line-height:1.2 }
.fis-firm { font-size: .76rem; color: ##555; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; margin-top:1px }
.fis-meta { font-size: .71rem; color: ##999; margin-top: 3px; display:flex; justify-content:space-between; align-items:center }
.fis-prog { height: 3px; border-radius: 2px; background: ##e9ecef; margin-top: 5px; }
.fis-prog-bar { height: 100%; border-radius: 2px; background: ##198754; }
.fis-prog-bar.full { background: ##6c757d; }
/* ─── Detay tablo ─── */
.detay-tbl td { font-size: .83rem; padding: 3px 8px 3px 0; vertical-align: top; }
.detay-tbl td:first-child { color: ##888; white-space: nowrap; width: 120px; }
/* ─── Partiler tablo ─── */
.parti-tbl th { font-size: .76rem; font-weight: 600; }
.parti-tbl td { font-size: .82rem; vertical-align: middle; }
</style>

<script>
var ALL_FIS        = #serializeJSON(fisArr)#;
var ALL_SARIM      = #serializeJSON(sarimArr)#;
var ALL_AMBALAJ    = #serializeJSON(ambalajArr)#;
var selectedShipId = 0;

/* ════ Sol liste render ════ */
function renderList(items) {
    var el = document.getElementById('fisList');
    document.getElementById('listCount').textContent = items.length + ' kayıt';
    document.getElementById('listBadge').textContent = items.length;
    if (!items.length) {
        el.innerHTML = '<div class="text-center text-muted py-4 small">Kayıt bulunamadı</div>';
        return;
    }
    var html = '';
    items.forEach(function(f) {
        var pct  = f.hk_metre > 0 ? Math.min(100, (f.parti_metre / f.hk_metre) * 100) : 0;
        var full = f.hk_metre > 0 && f.parti_metre >= f.hk_metre;
        var meta = [];
        if (f.hk_metre    > 0) meta.push(f.hk_metre.toFixed(1) + ' mt');
        if (f.hk_top_adedi > 0) meta.push(f.hk_top_adedi + ' top');
        html += '<div class="fis-item' +
            (f.ship_id === selectedShipId ? ' active' : '') +
            (f.is_ship_iptal ? ' iptal' : '') +
            '" data-id="' + f.ship_id + '" onclick="selectFis(' + f.ship_id + ')">' +
            '<div class="fis-no">' + escHtml(f.ship_number) + '</div>' +
            '<div class="fis-firm">' + escHtml(f.company_name) + '</div>' +
            '<div class="fis-meta">' +
            '<span>' + f.record_date + (meta.length ? ' · ' + meta.join(' · ') : '') + '</span>' +
            (f.parti_count > 0
                ? '<span class="badge rounded-pill bg-' + (full ? 'secondary' : 'success') +
                  '" style="font-size:.65rem">' + f.parti_count + ' parti</span>'
                : '<span style="font-size:.68rem;color:##bbb">Parti yok</span>') +
            '</div>';
        if (f.hk_metre > 0) {
            html += '<div class="fis-prog"><div class="fis-prog-bar' + (full ? ' full' : '') +
                    '" style="width:' + pct.toFixed(0) + '%"></div></div>';
        }
        html += '</div>';
    });
    el.innerHTML = html;
}

function filterList(q) {
    q = (q || '').toLowerCase().trim();
    var filtered = q ? ALL_FIS.filter(function(f) {
        return f.ship_number.toLowerCase().includes(q) ||
               f.company_name.toLowerCase().includes(q) ||
               (f.hk_parti_no && f.hk_parti_no.toLowerCase().includes(q));
    }) : ALL_FIS;
    renderList(filtered);
}

/* ════ Seçim ════ */
function selectFis(shipId) {
    selectedShipId = shipId;

    /* Listedeki aktif item */
    document.querySelectorAll('.fis-item').forEach(function(el) {
        el.classList.toggle('active', parseInt(el.dataset.id) === shipId);
    });

    /* Toolbar butonları */
    var fis  = ALL_FIS.find(function(f) { return f.ship_id === shipId; });
    var full = fis && fis.hk_metre > 0 && fis.parti_metre >= fis.hk_metre;
    document.getElementById('btnDuzenle').disabled      = false;
    document.getElementById('btnPartiListesi').disabled = false;
    document.getElementById('btnSil').disabled          = false;
    document.getElementById('btnPartiOlustur').disabled = !!full;

    /* Sağ paneli aç */
    document.getElementById('rightEmpty').classList.add('d-none');
    document.getElementById('rightContent').classList.remove('d-none');

    /* Yükle */
    loadDetail(shipId);
    loadPartiler(shipId);
}

/* ════ Detay ════ */
function loadDetail(shipId) {
    document.getElementById('detayBody').innerHTML =
        '<div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin me-2"></i>Yükleniyor...</div>';
    document.getElementById('detayBadges').innerHTML = '';
    $.ajax({
        url: '/ship/form/get_giris_fis_detail.cfm',
        method: 'GET', data: { ship_id: shipId }, dataType: 'json',
        success: function(res) {
            if (res.success) renderDetail(res.data);
            else document.getElementById('detayBody').innerHTML =
                '<div class="alert alert-danger m-2 py-2">' + escHtml(res.message) + '</div>';
        },
        error: function() {
            document.getElementById('detayBody').innerHTML =
                '<div class="alert alert-danger m-2 py-2">Detay yüklenemedi</div>';
        }
    });
}

function renderDetail(d) {
    document.getElementById('detayTitle').textContent = d.ship_number;

    /* Badges */
    var b = '';
    if (d.is_ship_iptal)  b += '<span class="badge bg-danger">İptal</span>';
    b += d.hk_ucretli
        ? '<span class="badge bg-success">Ücretli</span>'
        : '<span class="badge bg-secondary">Ücretsiz</span>';
    b += d.hk_ham_boyali
        ? '<span class="badge bg-warning text-dark">Ham</span>'
        : '<span class="badge bg-info text-dark">Boyalı</span>';
    document.getElementById('detayBadges').innerHTML = b;

    /* Progress hesapla */
    var pct   = d.hk_metre > 0 ? Math.min(100, (d.parti_metre / d.hk_metre) * 100) : 0;
    var kalan = Math.max(0, d.hk_metre - d.parti_metre);
    var full  = d.hk_metre > 0 && d.parti_metre >= d.hk_metre;
    var strokeColor = full ? '##6c757d' : '##198754';
    var dashArr = (pct * 2.83).toFixed(0);

    /* Bilgi satırları */
    var rows = [
        ['Firma',       '<strong>' + escHtml(d.company_name) + '</strong>'],
        ['Ürün',        escHtml(d.urun_adi) || '—'],
        ['Metre',       d.hk_metre     > 0 ? d.hk_metre.toFixed(3)    + ' <span class="text-muted">mt</span>'  : '—'],
        ['Kg',          d.hk_kg        > 0 ? d.hk_kg.toFixed(3)       + ' <span class="text-muted">kg</span>'  : '—'],
        ['Top Adedi',   d.hk_top_adedi > 0 ? d.hk_top_adedi           + ' <span class="text-muted">top</span>' : '—'],
        ['Ham Gramaj',  d.hk_h_gramaj  > 0 ? d.hk_h_gramaj.toFixed(2) + ' <span class="text-muted">gr</span>'  : '—'],
        ['Gr/Mtül',     d.hk_gr_mtul   > 0 ? d.hk_gr_mtul.toFixed(4)                                           : '—'],
        ['Parti No',    d.hk_parti_no  ? '<code class="text-primary">' + escHtml(d.hk_parti_no) + '</code>' : '—'],
        ['Ref No',      d.ref_no       ? escHtml(d.ref_no) : '—'],
        ['Açıklama',    d.ship_detail  ? escHtml(d.ship_detail) : '—'],
        ['Kayıt Tarihi', escHtml(d.record_date)]
    ];

    var tableHtml = '<table class="detay-tbl w-100">';
    rows.forEach(function(r) {
        tableHtml += '<tr><td>' + r[0] + '</td><td>' + r[1] + '</td></tr>';
    });
    tableHtml += '</table>';

    /* Donut progress */
    var donut = '';
    if (d.hk_metre > 0) {
        donut = '<div class="text-center">' +
            '<div class="text-muted small fw-semibold mb-2">Partileme Durumu</div>' +
            '<div class="position-relative mx-auto" style="width:110px;height:110px">' +
            '<svg viewBox="0 0 100 100" style="width:100%;transform:rotate(-90deg)">' +
            '<circle cx="50" cy="50" r="42" fill="none" stroke="##e9ecef" stroke-width="12"/>' +
            '<circle cx="50" cy="50" r="42" fill="none" stroke="' + strokeColor + '" stroke-width="12"' +
            ' stroke-dasharray="' + dashArr + ' 264" stroke-linecap="round"/></svg>' +
            '<div style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);text-align:center">' +
            '<div style="font-size:1.15rem;font-weight:700;color:' + strokeColor + '">' + pct.toFixed(0) + '%</div>' +
            '<div style="font-size:.67rem;color:##999">partilendi</div></div></div>' +
            '<div class="mt-2 small">' +
            '<div class="d-flex justify-content-between px-2">' +
            '<span class="text-muted">Partilenen</span>' +
            '<span class="fw-semibold text-success">' + d.parti_metre.toFixed(2) + ' mt</span></div>' +
            '<div class="d-flex justify-content-between px-2">' +
            '<span class="text-muted">Kalan</span>' +
            '<span class="fw-semibold ' + (kalan > 0 ? 'text-primary' : 'text-secondary') + '">' + kalan.toFixed(2) + ' mt</span></div>' +
            '</div></div>';
    }

    document.getElementById('detayBody').innerHTML =
        '<div class="row g-0">' +
        '<div class="col-md-8 pe-md-3">' + tableHtml + '</div>' +
        '<div class="col-md-4 border-start ps-md-3 d-flex align-items-center justify-content-center">' + (donut || '<span class="text-muted small">Metre bilgisi girilmemiş</span>') + '</div>' +
        '</div>';
}

/* ════ Partiler ════ */
function loadPartiler(shipId) {
    document.getElementById('partilerBody').innerHTML =
        '<div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin me-2"></i>Yükleniyor...</div>';
    document.getElementById('partiBadge').textContent = '0';
    document.getElementById('btnPartiOlusturInline').style.display = 'none';

    $.ajax({
        url: '/ship/form/get_ship_partiler.cfm',
        method: 'GET', data: { ship_id: shipId }, dataType: 'json',
        success: function(res) {
            if (res.success) renderPartiler(res.data);
            else document.getElementById('partilerBody').innerHTML =
                '<div class="alert alert-danger m-2 py-2">' + escHtml(res.message) + '</div>';
        },
        error: function() {
            document.getElementById('partilerBody').innerHTML =
                '<div class="alert alert-danger m-2 py-2">Partiler yüklenemedi</div>';
        }
    });
}

function renderPartiler(list) {
    document.getElementById('partiBadge').textContent = list.length;

    var fis  = ALL_FIS.find(function(f) { return f.ship_id === selectedShipId; });
    var full = fis && fis.hk_metre > 0 && fis.parti_metre >= fis.hk_metre;
    document.getElementById('btnPartiOlusturInline').style.display = full ? 'none' : '';

    if (!list.length) {
        document.getElementById('partilerBody').innerHTML =
            '<div class="text-center text-muted py-4">' +
            '<i class="fas fa-cut fa-2x mb-2 d-block" style="opacity:.2"></i>' +
            'Henüz parti oluşturulmamış</div>';
        return;
    }

    var stageColors = { 1:'secondary', 2:'primary', 3:'warning', 4:'info', 5:'success', 6:'dark' };

    var html = '<div class="table-responsive">' +
        '<table class="table table-sm table-hover mb-0 parti-tbl">' +
        '<thead class="table-light"><tr>' +
        '<th class="ps-3">Parti No</th><th>Tarih</th><th>Miktar</th><th>Durum</th><th></th>' +
        '</tr></thead><tbody>';

    list.forEach(function(p) {
        var color = stageColors[p.order_stage] || 'secondary';
        html += '<tr>' +
            '<td class="ps-3 fw-semibold">' + escHtml(p.order_number) + '</td>' +
            '<td class="text-muted">' + p.order_date + '</td>' +
            '<td>' + (p.ana_miktar > 0 ? p.ana_miktar.toFixed(2) + ' mt' : '—') + '</td>' +
            '<td><span class="badge bg-' + color + ' rounded-pill" style="font-size:.72rem">' +
            escHtml(p.stage_label) + '</span></td>' +
            '<td class="pe-2 text-end">' +
            '<a href="index.cfm?fuseaction=ship.detail_parti&order_id=' + p.order_id + '" ' +
            'class="btn btn-xs btn-outline-secondary btn-sm py-0 px-2" style="font-size:.72rem" title="Detay">' +
            '<i class="fas fa-eye"></i></a>' +
            '</td></tr>';
    });

    html += '</tbody></table></div>';
    document.getElementById('partilerBody').innerHTML = html;
}

/* ════ Toolbar buton işlemleri ════ */
function editSelected()  { if (selectedShipId) window.location.href = 'index.cfm?fuseaction=ship.add_giris_fis&ship_id=' + selectedShipId; }
function partiOlustur()  { if (selectedShipId) openYeniPartiModal(selectedShipId); }
function partiListesi()  { if (selectedShipId) window.location.href = 'index.cfm?fuseaction=ship.list_partiler&ship_id=' + selectedShipId; }
function silSelected()   {
    if (!selectedShipId || !confirm('Bu giriş fişini silmek istediğinizden emin misiniz?')) return;
    $.ajax({
        url: '/ship/form/save_ship.cfm', method: 'POST',
        data: { ship_id: selectedShipId, action: 'delete' }, dataType: 'json',
        success: function(res) {
            if (res.success) location.reload();
            else alert('Silme hatası: ' + (res.message || ''));
        }
    });
}

function escHtml(str) {
    return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

/* ════ Modal: Yeni Giriş Fişi ════ */
var mfis_allCompanies = [], mfis_companiesLoaded = false;
var mfis_allStocks = [];

function openYeniFisModal() {
    /* Formu temizle */
    document.getElementById('mfis_companySearch').value = '';
    document.getElementById('mfis_company_id').value = '0';
    document.getElementById('mfis_stockSearch').value = '';
    document.getElementById('mfis_stockSearch').disabled = true;
    document.getElementById('mfis_stock_id').value   = '0';
    document.getElementById('mfis_product_id').value = '0';
    document.getElementById('mfis_stockSelected').classList.add('d-none');
    document.getElementById('mfis_stockDropdown').classList.add('d-none');
    document.getElementById('mfis_hk_metre').value     = '';
    document.getElementById('mfis_hk_kg').value        = '';
    document.getElementById('mfis_hk_top_adedi').value = '';
    document.getElementById('mfis_ship_detail').value  = '';
    document.getElementById('mfis_ham').checked         = true;
    document.getElementById('mfis_ucretli_e').checked   = true;
    document.getElementById('mfis_errorMsg').classList.add('d-none');
    mfis_allStocks = [];
    /* Firmalar cache'lenmemişse yükle */
    if (!mfis_companiesLoaded) {
        $.ajax({
            url: '/company/cfc/company.cfc?method=getCompaniesForDropdown',
            method: 'GET', dataType: 'json',
            success: function(data) {
                mfis_allCompanies = Array.isArray(data) ? data : [];
                mfis_companiesLoaded = true;
            }
        });
    }
    var modal = new bootstrap.Modal(document.getElementById('modalYeniFis'));
    modal.show();
}

function mfis_filterCompany(q) {
    var dd = document.getElementById('mfis_companyDropdown');
    if (!q || q.length < 1) { dd.classList.add('d-none'); return; }
    q = q.toLowerCase();
    var results = mfis_allCompanies.filter(function(c) {
        return ((c.display_name || c.fullname || '') + ' ' + (c.nickname || '') + ' ' + (c.member_code || '')).toLowerCase().includes(q);
    }).slice(0, 20);
    if (!results.length) { dd.innerHTML = '<div class="search-item text-muted">Sonuç yok</div>'; dd.classList.remove('d-none'); return; }
    dd.innerHTML = '';
    results.forEach(function(c) {
        var div = document.createElement('div');
        div.className = 'search-item';
        div.innerHTML = '<div>' + escHtml(c.display_name || c.nickname || c.fullname) + '</div>' +
                        '<div class="item-code">' + escHtml(c.member_code || '') + '</div>';
        div.addEventListener('click', function() {
            dd.classList.add('d-none');
            document.getElementById('mfis_companySearch').value = c.display_name || c.nickname || c.fullname;
            document.getElementById('mfis_company_id').value    = c.company_id;
            /* Stokları yükle */
            var si = document.getElementById('mfis_stockSearch');
            si.disabled = false; si.value = ''; si.placeholder = 'Yükleniyor...';
            document.getElementById('mfis_stock_id').value   = '0';
            document.getElementById('mfis_product_id').value = '0';
            document.getElementById('mfis_stockSelected').classList.add('d-none');
            mfis_allStocks = [];
            $.ajax({
                url: '/company/cfc/company.cfc',
                method: 'GET',
                data: { method: 'getStocksByCompany', company_id: c.company_id },
                dataType: 'json',
                success: function(res) {
                    mfis_allStocks = (res.success && Array.isArray(res.data)) ? res.data : [];
                    si.placeholder = mfis_allStocks.length ? 'Stok adı veya kodu...' : 'Bu firmaya ait stok yok';
                },
                error: function() { si.placeholder = 'Stok yüklenemedi'; }
            });
        });
        dd.appendChild(div);
    });
    dd.classList.remove('d-none');
}

function mfis_filterStock(q) {
    var dd = document.getElementById('mfis_stockDropdown');
    if (!q || q.length < 2) { dd.classList.add('d-none'); return; }
    q = q.toLowerCase();
    var results = mfis_allStocks.filter(function(s) {
        return ((s.product_name || '') + ' ' + (s.stock_code || '') + ' ' + (s.barcod || '')).toLowerCase().includes(q);
    }).slice(0, 20);
    if (!results.length) { dd.innerHTML = '<div class="search-item text-muted">Sonuç yok</div>'; dd.classList.remove('d-none'); return; }
    dd.innerHTML = '';
    results.forEach(function(s) {
        var div = document.createElement('div');
        div.className = 'search-item';
        div.innerHTML = '<div>' + escHtml(s.product_name) + '</div>' +
                        '<div class="item-code">' + escHtml(s.stock_code || '') + (s.property ? ' · ' + escHtml(s.property) : '') + '</div>';
        div.addEventListener('click', function() {
            dd.classList.add('d-none');
            document.getElementById('mfis_stockSearch').value = s.product_name + (s.stock_code ? ' — ' + s.stock_code : '');
            document.getElementById('mfis_stock_id').value    = s.stock_id;
            document.getElementById('mfis_product_id').value  = s.product_id || 0;
            document.getElementById('mfis_stockLabel').textContent = s.product_name + (s.stock_code ? ' — ' + s.stock_code : '');
            document.getElementById('mfis_stockSelected').classList.remove('d-none');
        });
        dd.appendChild(div);
    });
    dd.classList.remove('d-none');
}

function saveFisModal() {
    var companyId = parseInt(document.getElementById('mfis_company_id').value) || 0;
    var stockId   = parseInt(document.getElementById('mfis_stock_id').value)   || 0;
    var productId = parseInt(document.getElementById('mfis_product_id').value) || 0;
    var errEl = document.getElementById('mfis_errorMsg');
    errEl.classList.add('d-none');
    if (!companyId) { errEl.textContent = 'Lütfen firma seçin.'; errEl.classList.remove('d-none'); return; }
    if (!stockId)   { errEl.textContent = 'Lütfen stok seçin.';  errEl.classList.remove('d-none'); return; }

    var hamBoyali = document.querySelector('input[name="mfis_ham_boyali"]:checked');
    var ucretli   = document.querySelector('input[name="mfis_ucretli"]:checked');
    var today     = new Date().toISOString().slice(0, 10);

    var rowObj = {
        stock_id:      stockId,
        product_id:    productId,
        name_product:  document.getElementById('mfis_stockLabel').textContent,
        price:  0, amount: parseFloat(document.getElementById('mfis_hk_metre').value) || 0,
        amount2: parseFloat(document.getElementById('mfis_hk_kg').value) || 0,
        unit: 'mt', unit_id: 0, tax: 0, discount: 0,
        discounttotal: 0, grosstotal: 0, nettotal: 0, taxtotal: 0,
        lot_no: '', giris_raf_id: 0, giris_raf_code: '', cikis_raf_id: 0, cikis_raf_code: ''
    };

    var btn = document.getElementById('mfis_saveBtn');
    btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Kaydediliyor...';

    $.ajax({
        url: '/ship/form/save_ship.cfm', method: 'POST', dataType: 'json',
        data: {
            ship_id:       0,
            purchase_sales: 'false',
            ship_type:     '5',
            ship_number:   '',
            ship_date:     today,
            deliver_date:  today,
            company_id:    companyId,
            ship_status:   '1',
            ship_detail:   document.getElementById('mfis_ship_detail').value,
            hk_metre:      document.getElementById('mfis_hk_metre').value     || '',
            hk_kg:         document.getElementById('mfis_hk_kg').value        || '',
            hk_top_adedi:  document.getElementById('mfis_hk_top_adedi').value || '',
            hk_ucretli:    ucretli   ? ucretli.value   : 'true',
            hk_ham_boyali: hamBoyali ? hamBoyali.value : 'true',
            rows:          JSON.stringify([rowObj])
        },
        success: function(res) {
            btn.disabled = false; btn.innerHTML = '<i class="fas fa-save me-1"></i>Kaydet';
            if (res.success) {
                bootstrap.Modal.getInstance(document.getElementById('modalYeniFis')).hide();
                location.reload();
            } else {
                errEl.textContent = res.message || 'Kayıt hatası'; errEl.classList.remove('d-none');
            }
        },
        error: function() {
            btn.disabled = false; btn.innerHTML = '<i class="fas fa-save me-1"></i>Kaydet';
            errEl.textContent = 'Sunucu hatası'; errEl.classList.remove('d-none');
        }
    });
}

/* ════ Modal: Yeni Parti ════ */
function openYeniPartiModal(shipId) {
    /* Formu sıfırla */
    document.getElementById('mprt_loading').classList.remove('d-none');
    document.getElementById('mprt_form').classList.add('d-none');
    document.getElementById('mprt_saveBtn').classList.add('d-none');
    document.getElementById('mprt_errorMsg').classList.add('d-none');
    document.getElementById('mprt_miktar').value    = '';
    document.getElementById('mprt_kg').value        = '';
    document.getElementById('mprt_aciklama').value  = '';

    /* Sarım şekli + ambalaj dolduruluyor mu kontrol */
    var ss = document.getElementById('mprt_sarim_sekli');
    if (ss.options.length <= 1) {
        ALL_SARIM.forEach(function(s) {
            var opt = document.createElement('option');
            opt.value = s.id; opt.textContent = s.label; ss.appendChild(opt);
        });
    }
    var ab = document.getElementById('mprt_ambalaj');
    if (ab.options.length <= 1) {
        ALL_AMBALAJ.forEach(function(a) {
            var opt = document.createElement('option');
            opt.value = a.id; opt.textContent = a.label; ab.appendChild(opt);
        });
    }
    ss.value = '0'; ab.value = '0';

    var modal = new bootstrap.Modal(document.getElementById('modalYeniParti'));
    modal.show();

    /* Endpoint'ten ship_row + parti kodu al */
    $.ajax({
        url: '/ship/form/get_parti_form_data.cfm',
        method: 'GET', data: { ship_id: shipId }, dataType: 'json',
        success: function(res) {
            document.getElementById('mprt_loading').classList.add('d-none');
            if (!res.success) {
                document.getElementById('mprt_errorMsg').textContent = res.message || 'Veri alınamadı';
                document.getElementById('mprt_errorMsg').classList.remove('d-none');
                return;
            }
            var fis = ALL_FIS.find(function(f) { return f.ship_id === shipId; });
            document.getElementById('mprt_ship_id').value      = shipId;
            document.getElementById('mprt_company_id').value   = res.company_id;
            document.getElementById('mprt_stock_id').value     = res.stock_id;
            document.getElementById('mprt_product_id').value   = res.product_id;
            document.getElementById('mprt_unit').value         = res.unit;
            document.getElementById('mprt_unit_id').value      = res.unit_id;
            document.getElementById('mprt_product_name').value = res.product_name;
            document.getElementById('mprt_ref_no').value       = res.ship_number;
            document.getElementById('mprt_parti_kodu').value   = res.parti_kodu;
            document.getElementById('mprt_fisLabel').textContent    = res.ship_number;
            document.getElementById('mprt_companyLabel').textContent = fis ? fis.company_name : '';
            /* Kalan metre --->  */
            if (fis && fis.hk_metre > 0) {
                var kalan = Math.max(0, fis.hk_metre - fis.parti_metre);
                document.getElementById('mprt_kalanText').textContent =
                    'Toplam: ' + fis.hk_metre.toFixed(2) + ' mt · Kalan: ' + kalan.toFixed(2) + ' mt';
                document.getElementById('mprt_miktar').value = kalan > 0 ? kalan.toFixed(3) : '';
            }
            document.getElementById('mprt_form').classList.remove('d-none');
            document.getElementById('mprt_saveBtn').classList.remove('d-none');
        },
        error: function() {
            document.getElementById('mprt_loading').classList.add('d-none');
            document.getElementById('mprt_errorMsg').textContent = 'Veri yüklenemedi';
            document.getElementById('mprt_errorMsg').classList.remove('d-none');
        }
    });
}

function savePartiModal() {
    var shipId    = parseInt(document.getElementById('mprt_ship_id').value)    || 0;
    var companyId = parseInt(document.getElementById('mprt_company_id').value) || 0;
    var stockId   = parseInt(document.getElementById('mprt_stock_id').value)   || 0;
    var productId = parseInt(document.getElementById('mprt_product_id').value) || 0;
    var miktar    = parseFloat(document.getElementById('mprt_miktar').value)   || 0;
    var errEl = document.getElementById('mprt_errorMsg');
    errEl.classList.add('d-none');
    if (miktar <= 0) {
        errEl.textContent = 'Miktar sıfırdan büyük olmalı.'; errEl.classList.remove('d-none'); return;
    }
    if (!productId || !stockId) {
        errEl.textContent = 'Giriş fişine ait ürün bilgisi bulunamadı.'; errEl.classList.remove('d-none'); return;
    }

    var rowObj = {
        stock_id:      stockId,
        product_id:    productId,
        product_name:  document.getElementById('mprt_product_name').value,
        quantity:      miktar,
        unit:          document.getElementById('mprt_unit').value || 'mt',
        unit_id:       parseInt(document.getElementById('mprt_unit_id').value) || 0,
        price:         0, tax: 0, discount_1: 0,
        grosstotal:    0, nettotal: 0, taxtotal: 0
    };

    var btn = document.getElementById('mprt_saveBtn');
    btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i>Kaydediliyor...';

    $.ajax({
        url: '/order/form/save_order.cfm', method: 'POST', dataType: 'json',
        data: {
            order_id:       0,
            purchase_sales: 'false',
            order_stage:    1,
            order_number:   document.getElementById('mprt_parti_kodu').value,
            order_head:     document.getElementById('mprt_aciklama').value,
            ref_no:         document.getElementById('mprt_ref_no').value,
            ref_ship_id:    shipId,
            company_id:     companyId,
            order_date:     new Date().toISOString().slice(0, 10),
            sarim_sekli:    document.getElementById('mprt_sarim_sekli').value || 0,
            ambalaj:        document.getElementById('mprt_ambalaj').value     || 0,
            rows:           JSON.stringify([rowObj])
        },
        success: function(res) {
            btn.disabled = false; btn.innerHTML = '<i class="fas fa-cut me-1"></i>Parti Oluştur';
            if (res.success) {
                bootstrap.Modal.getInstance(document.getElementById('modalYeniParti')).hide();
                /* Sadece seçili fişin partilerini ve listeyi yenile */
                loadPartiler(shipId);
                /* ALL_FIS parti_count ve parti_metre güncelle */
                var fis = ALL_FIS.find(function(f) { return f.ship_id === shipId; });
                if (fis) {
                    fis.parti_count++;
                    fis.parti_metre += miktar;
                    renderList(ALL_FIS);
                    /* Toolbar butonunu duruma göre güncelle */
                    var full = fis.hk_metre > 0 && fis.parti_metre >= fis.hk_metre;
                    document.getElementById('btnPartiOlustur').disabled = !!full;
                    document.getElementById('btnPartiOlusturInline').style.display = full ? 'none' : '';
                }
            } else {
                errEl.textContent = res.message || 'Kayıt hatası'; errEl.classList.remove('d-none');
            }
        },
        error: function() {
            btn.disabled = false; btn.innerHTML = '<i class="fas fa-cut me-1"></i>Parti Oluştur';
            errEl.textContent = 'Sunucu hatası'; errEl.classList.remove('d-none');
        }
    });
}

/* ════ Init ════ */
renderList(ALL_FIS);
</script>
</cfoutput>
