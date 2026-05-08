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
            SELECT COUNT(*) FROM orders o WHERE o.ref_ship_id = s.ship_id
        ), 0) AS parti_count,
        COALESCE((
            SELECT SUM(orw.quantity)
            FROM orders o
            JOIN order_row orw ON o.order_id = orw.order_id
            WHERE o.ref_ship_id = s.ship_id
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

                    <a href="index.cfm?fuseaction=ship.add_giris_fis" class="btn btn-primary btn-sm">
                        <i class="fas fa-plus me-1"></i>Yeni Giriş Fişi
                    </a>
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
var ALL_FIS = #serializeJSON(fisArr)#;
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
                : '<span style="font-size:.68rem;color:#bbb">Parti yok</span>') +
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
function partiOlustur()  { if (selectedShipId) window.location.href = 'index.cfm?fuseaction=ship.add_parti&ship_id='     + selectedShipId; }
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

/* ════ Init ════ */
renderList(ALL_FIS);
</script>
</cfoutput>
