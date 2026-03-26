<cfprocessingdirective pageEncoding="utf-8">

<!--- Mevcut kaydı getir (zone_type = 0, varsayılan) --->
<cfquery name="getPapers" datasource="boyahane">
    SELECT * FROM general_papers
    WHERE zone_type = 0
    ORDER BY general_papers_id
    LIMIT 1
</cfquery>

<!--- Kayıt yoksa otomatik oluştur --->
<cfif NOT getPapers.recordCount>
    <cfquery datasource="boyahane">
        INSERT INTO general_papers (zone_type) VALUES (0)
    </cfquery>
    <cfquery name="getPapers" datasource="boyahane">
        SELECT * FROM general_papers WHERE zone_type = 0 ORDER BY general_papers_id LIMIT 1
    </cfquery>
</cfif>

<!--- Tüm alanları küçük harfli anahtar ile struct'a al --->
<cfset papersStruct = {}>
<cfif getPapers.recordCount>
    <cfloop list="#getPapers.columnList#" index="col">
        <cfset papersStruct[lcase(col)] = getPapers[col][1] ?: "">
    </cfloop>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-hashtag"></i></div>
        <div class="page-header-title">
            <h1>Belge Numaraları</h1>
            <p>Sistem genelindeki belge numarası önekleri ve sayaçları</p>
        </div>
    </div>
</div>

<div class="px-3 pb-5" id="paperGroups">
    <!--- JS tarafından doldurulur --->
</div>

<!--- Düzenleme Modalı --->
<div class="modal fade" id="editModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header bg-primary text-white">
                <h5 class="modal-title">
                    <i class="fas fa-edit me-2"></i>
                    <span id="modalTitle">Belge Düzenle</span>
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="editKey">
                <div class="mb-3">
                    <label class="form-label fw-semibold"><i class="fas fa-tag me-1 text-primary"></i>Ön Ek (Prefix)</label>
                    <input type="text" class="form-control" id="editNo"
                           placeholder="Örn: TEK, SIP, URN...">
                    <div class="form-text">Belge numarasının metin ön eki</div>
                </div>
                <div class="mb-3">
                    <label class="form-label fw-semibold"><i class="fas fa-sort-numeric-up me-1 text-primary"></i>Sayaç</label>
                    <input type="number" class="form-control" id="editNumber"
                           min="0" step="1" placeholder="0">
                    <div class="form-text">Bir sonraki belge bu sayıdan devam eder</div>
                </div>
                <div id="previewBox" class="alert alert-info py-2 mt-3 d-none">
                    <i class="fas fa-eye me-1"></i>Önizleme: <strong id="previewText"></strong>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-primary" onclick="savePaper()">
                    <i class="fas fa-save me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<style>
.group-card { background:##fff; border-radius:12px; border:1px solid ##e9ecef; margin-bottom:20px; box-shadow:0 2px 8px rgba(0,0,0,.06); overflow:hidden; }
.group-card-header { display:flex; align-items:center; gap:10px; padding:12px 18px; font-weight:600; font-size:.9rem; border-bottom:1px solid ##e9ecef; }
.group-card-header .cnt { margin-left:auto; font-size:.8rem; font-weight:400; opacity:.75; }
.papers-table th { background:##f8f9fa; font-size:.78rem; font-weight:600; text-transform:uppercase; letter-spacing:.03em; color:##6c757d; white-space:nowrap; }
.papers-table td { font-size:.875rem; vertical-align:middle; }
.papers-table tr:hover td { background:##f0f6ff; }
.prefix-badge { font-family:monospace; font-size:.8rem; background:##e9ecef; padding:2px 8px; border-radius:6px; color:##495057; }
.counter-val { font-weight:700; color:##1a3a5c; }
.zero-counter { color:##adb5bd; }
</style>

<script>
var papersData = #serializeJSON(papersStruct)#;
var papersId   = #val(papersStruct.general_papers_id ?: 0)#;

var groups = [
    {
        label: 'Satış & Ticaret', icon: 'fa-handshake', color: '##198754',
        items: [
            {key:'offer',               label:'Teklif'},
            {key:'order',               label:'Sipariş'},
            {key:'campaign',            label:'Kampanya'},
            {key:'promotion',           label:'Promosyon'},
            {key:'catalog',             label:'Katalog'},
            {key:'target_market',       label:'Hedef Pazar'},
            {key:'cat_prom',            label:'Katalog Promosyon'},
            {key:'correspondence',      label:'Yazışma'},
            {key:'purchasedemand',      label:'Satın Alma Talebi'},
            {key:'expenditure_request', label:'Harcama Talebi'}
        ]
    },
    {
        label: 'Stok & Sevkiyat', icon: 'fa-boxes', color: '##0d6efd',
        items: [
            {key:'stock_fis',    label:'Stok Fişi'},
            {key:'ship_fis',     label:'Sevk Fişi'},
            {key:'ship_internal',label:'İç Sevkiyat'},
            {key:'req',          label:'Talep'}
        ]
    },
    {
        label: 'Üretim', icon: 'fa-industry', color: '##fd7e14',
        items: [
            {key:'prod_order',                    label:'Üretim Emri'},
            {key:'production_result',             label:'Üretim Sonucu'},
            {key:'production_lot',                label:'Üretim Partisi'},
            {key:'production_party',              label:'Üretim Partisi (Party)'},
            {key:'pro_material',                  label:'Üretim Malzemesi'},
            {key:'quality_control',               label:'Kalite Kontrol'},
            {key:'production_quality_control',    label:'Üretim Kalite Kontrol'},
            {key:'work',                          label:'İş'}
        ]
    },
    {
        label: 'Finans', icon: 'fa-wallet', color: '##6f42c1',
        items: [
            {key:'virman',                      label:'Virman'},
            {key:'incoming_transfer',           label:'Gelen Transfer'},
            {key:'outgoing_transfer',           label:'Giden Transfer'},
            {key:'purchase_doviz',              label:'Alış Döviz'},
            {key:'sale_doviz',                  label:'Satış Döviz'},
            {key:'credit',                      label:'Kredi'},
            {key:'credit_revenue',              label:'Kredi Tahsilat'},
            {key:'credit_payment',              label:'Kredi Ödeme'},
            {key:'creditcard_revenue',          label:'Kredi Kartı Tahsilat'},
            {key:'creditcard_payment',          label:'Kredi Kartı Ödeme'},
            {key:'creditcard_debit_payment',    label:'KK Borç Ödeme'},
            {key:'creditcard_cc_bank_action',   label:'KK Banka İşlemi'},
            {key:'cari_to_cari',                label:'Cari-Cari Transfer'},
            {key:'debit_claim',                 label:'Borç Alacak'},
            {key:'cash_to_cash',                label:'Kasa-Kasa Transfer'},
            {key:'cash_payment',                label:'Kasa Ödeme'},
            {key:'expense_cost',                label:'Gider Masraf'},
            {key:'income_cost',                 label:'Gelir Masraf'},
            {key:'buying_securities',           label:'Menkul Kıymet Alım'},
            {key:'securities_sale',             label:'Menkul Kıymet Satış'},
            {key:'tahakkuk_plan',               label:'Tahakkuk Planı'},
            {key:'receipt',                     label:'Makbuz'},
            {key:'cashregister',                label:'Kasa Kaydı'},
            {key:'securefund',                  label:'Teminat Fonu'}
        ]
    },
    {
        label: 'Destek & Diğer', icon: 'fa-layer-group', color: '##6c757d',
        items: [
            {key:'support',                  label:'Destek'},
            {key:'opportunity',              label:'Fırsat'},
            {key:'service_app',              label:'Servis Başvurusu'},
            {key:'subscription',             label:'Abonelik'},
            {key:'budget_plan',              label:'Bütçe Planı'},
            {key:'budget_transfer_demand',   label:'Bütçe Transfer Talebi'},
            {key:'travel_demand',            label:'Seyahat Talebi'},
            {key:'mkdad',                    label:'MKDAD'},
            {key:'waste_collection',         label:'Atık Toplama'},
            {key:'waste_operation',          label:'Atık İşlem'},
            {key:'sample_analysis',          label:'Numune Analiz'},
            {key:'system_paper',             label:'Sistem Belgesi'},
            {key:'internal',                 label:'İç Belge'}
        ]
    }
];

function getVal(key, suffix) {
    var k = (key + suffix).toLowerCase();
    return papersData[k] !== undefined ? papersData[k] : '';
}

function renderGroups() {
    var container = document.getElementById('paperGroups');
    container.innerHTML = '';
    groups.forEach(function(grp) {
        var card = document.createElement('div');
        card.className = 'group-card';

        var hdr = '<div class="group-card-header" style="border-left:4px solid ' + grp.color + '">' +
            '<i class="fas ' + grp.icon + '" style="color:' + grp.color + '"></i>' +
            grp.label +
            '<span class="cnt">' + grp.items.length + ' belge tipi</span>' +
            '</div>';

        var tbl = '<div class="table-responsive"><table class="table table-hover mb-0 papers-table">' +
            '<thead><tr>' +
            '<th style="width:40%">Belge Tipi</th>' +
            '<th style="width:25%">Ön Ek (Prefix)</th>' +
            '<th style="width:20%">Sayaç</th>' +
            '<th style="width:15%"></th>' +
            '</tr></thead><tbody>';

        grp.items.forEach(function(item) {
            var noVal  = getVal(item.key, '_no');
            var numVal = getVal(item.key, '_number');
            var numInt = parseInt(numVal) || 0;
            var noBadge  = noVal ? '<span class="prefix-badge">' + escHtml(noVal) + '</span>' : '<span class="text-muted small">—</span>';
            var numBadge = numInt > 0
                ? '<span class="counter-val">' + numInt.toLocaleString('tr-TR') + '</span>'
                : '<span class="zero-counter">0</span>';

            tbl += '<tr>' +
                '<td><i class="fas fa-file-alt me-2 text-muted"></i>' + escHtml(item.label) + '</td>' +
                '<td>' + noBadge + '</td>' +
                '<td>' + numBadge + '</td>' +
                '<td class="text-center">' +
                    '<button class="btn btn-sm btn-outline-primary" onclick="editPaper(\'' + item.key + '\',\'' + escHtml(item.label) + '\')">' +
                        '<i class="fas fa-pen"></i>' +
                    '</button>' +
                '</td>' +
                '</tr>';
        });

        tbl += '</tbody></table></div>';
        card.innerHTML = hdr + tbl;
        container.appendChild(card);
    });
}

function editPaper(key, label) {
    document.getElementById('editKey').value       = key;
    document.getElementById('modalTitle').textContent = label + ' — Numaratör';
    document.getElementById('editNo').value        = getVal(key, '_no');
    document.getElementById('editNumber').value    = parseInt(getVal(key, '_number')) || 0;
    updatePreview();
    var modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('editModal'));
    modal.show();
}

function updatePreview() {
    var no  = document.getElementById('editNo').value.trim();
    var num = parseInt(document.getElementById('editNumber').value) || 0;
    var box = document.getElementById('previewBox');
    if (no) {
        document.getElementById('previewText').textContent = no + '-' + String(num + 1).padStart(5, '0');
        box.classList.remove('d-none');
    } else {
        box.classList.add('d-none');
    }
}

document.addEventListener('DOMContentLoaded', function(){
    document.getElementById('editNo').addEventListener('input', updatePreview);
    document.getElementById('editNumber').addEventListener('input', updatePreview);

    // Modal'ı body'e taşı
    var m = document.getElementById('editModal');
    if (m && m.parentNode !== document.body) document.body.appendChild(m);

    renderGroups();
});

function savePaper() {
    var key    = document.getElementById('editKey').value;
    var noVal  = document.getElementById('editNo').value.trim();
    var numVal = parseInt(document.getElementById('editNumber').value) || 0;

    $.ajax({
        url:      '/papers/form/save_papers.cfm',
        method:   'POST',
        dataType: 'json',
        data:     { general_papers_id: papersId, field_key: key, no_value: noVal, number_value: numVal },
        success: function(r) {
            if (r.success) {
                papersData[(key + '_no').toLowerCase()]     = noVal;
                papersData[(key + '_number').toLowerCase()] = numVal;
                renderGroups();
                bootstrap.Modal.getInstance(document.getElementById('editModal')).hide();
                DevExpress.ui.notify('Kaydedildi!', 'success', 2000);
            } else {
                DevExpress.ui.notify(r.message || 'Hata!', 'error', 3000);
            }
        },
        error: function() { DevExpress.ui.notify('İstek başarısız!', 'error', 3000); }
    });
}

function escHtml(str) {
    return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
</script>
</cfoutput>
