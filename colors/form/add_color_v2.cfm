<cfprocessingdirective pageEncoding="utf-8">

<!---
    Renk Ekle / Düzenle
    url.stock_id  = düzenleme modunda mevcut rengin stock_id'si (opsiyonel)
--->

<cfparam name="url.stock_id" default="0">
<cfset editStockId = isNumeric(url.stock_id) AND val(url.stock_id) gt 0 ? val(url.stock_id) : 0>
<cfset isEdit      = editStockId gt 0>

<!--- Stok ID yoksa listeye yönlendir --->
<cfif NOT isEdit>
    <cflocation url="index.cfm?fuseaction=colors.list_colors" addtoken="false">
</cfif>

<!--- Mevcut rengi yükle --->
<cfquery name="getColor" datasource="boyahane">
    SELECT ci.*, s.stock_code,
           COALESCE(c.nickname, c.fullname, '') AS company_name,
           COALESCE(p.product_name, '')         AS product_name
    FROM color_info ci
    LEFT JOIN stocks  s ON ci.stock_id   = s.stock_id
    LEFT JOIN company c ON ci.company_id = c.company_id
    LEFT JOIN product p ON ci.product_id = p.product_id
    WHERE ci.stock_id = <cfqueryparam value="#editStockId#" cfsqltype="cf_sql_integer">
</cfquery>
<cfif NOT getColor.recordCount>
    <cflocation url="index.cfm?fuseaction=colors.list_colors" addtoken="false">
</cfif>



<cfoutput>
<style>
/* ── Renk Formu: Bölüm Başlıkları ── */
.form-section-label {
    display: flex;
    align-items: center;
    gap: 7px;
    font-size: 0.7rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 1.1px;
    color: ##64748b;
    margin: 16px 0 10px;
    padding-bottom: 7px;
    border-bottom: 1px dashed ##e2e8f0;
}
.form-section-label:first-child { margin-top: 0; }
.form-section-label i { color: var(--accent); font-size: 0.68rem; }

/* ── İki panel arasındaki görsel denge ── */
.col-lg-5 .grid-card,
.col-lg-7 .grid-card {
    height: 100%;
}

/* ── Hazır switch kutusu ── */
.ready-switch-wrap {
    background: linear-gradient(135deg, ##f0fdf4, ##dcfce7);
    border: 1px solid ##bbf7d0;
    border-radius: 10px;
    padding: 11px 14px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 10px;
}
.ready-switch-wrap > span {
    font-size: 0.82rem;
    font-weight: 600;
    color: ##15803d;
}
.ready-switch-wrap .form-check-input:checked {
    background-color: ##16a34a;
    border-color: ##16a34a;
}

/* ── Reçete Paneli: Gömülü page-header ve dış boşlukları gizle ── */
.recipe-panel .page-header              { display: none !important; }
.recipe-panel .px-3.pb-5               { padding: 0 !important; }
.recipe-panel .grid-card               { box-shadow: none !important; border: none !important; border-radius: 0 !important; }
.recipe-panel .grid-card-header        { border-radius: 0; border-top: 1px solid ##eef1f6; padding: 10px 16px; }
.recipe-panel ##treeGrid                { max-height: 520px; }

/* ── Grid-card header içindeki düğmeler ── */
.grid-card-header .btn-outline-primary {
    border-color: var(--accent);
    color: var(--accent);
    font-size: 0.78rem;
    padding: 4px 10px;
}
.grid-card-header .btn-outline-primary:hover {
    background: var(--accent);
    color: ##fff;
}
</style>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-palette"></i></div>
        <div class="page-header-title">
            <h1>Renk Düzenle</h1>
            <p>#htmlEditFormat(getColor.color_code)# — #htmlEditFormat(getColor.color_name)#</p>
        </div>
    </div>
    <div class="d-flex gap-2">
        <a class="btn-back" href="index.cfm?fuseaction=colors.list_colors">
            <i class="fas fa-arrow-left"></i>Listeye Dön
        </a>
    </div>
</div>

<div class="px-3 pb-5">
<div class="row g-3">

<!--- ─── SOL: Renk Bilgileri ─── --->
<div class="col-lg-5">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Renk Bilgileri</div>
        </div>
        <div class="card-body p-3">

            <div class="form-section-label"><i class="fas fa-link"></i>Bağlantı</div>

            <!--- Müşteri --->
            <div class="mb-3">
                <label class="form-label">Müşteri</label>
                <div class="form-control bg-light" style="cursor:default;">#htmlEditFormat(getColor.company_name)#</div>
            </div>

            <!--- Ürün / Kumaş --->
            <div class="mb-3">
                <label class="form-label">Ürün / Kumaş</label>
                <div class="form-control bg-light" style="cursor:default;">#htmlEditFormat(getColor.product_name)#</div>
            </div>

            <div class="form-section-label"><i class="fas fa-fill-drip"></i>Renk Tanımı</div>

            <div class="row g-2 mb-3">
                <div class="col-5">
                    <label class="form-label">Renk Kodu</label>
                    <input type="text" class="form-control bg-light" id="f_color_code" readonly
                           value="#htmlEditFormat(getColor.color_code)#" maxlength="100" placeholder="R.Kodu">
                </div>
                <div class="col-7">
                    <label class="form-label">Renk Adı</label>
                    <input type="text" class="form-control bg-light" id="f_color_name" readonly
                           value="#htmlEditFormat(getColor.color_name)#" maxlength="255" placeholder="Renk adı">
                </div>
            </div>

            <div class="form-section-label"><i class="fas fa-id-card"></i>Kartela Bilgisi</div>

            <div class="row g-2 mb-3">
                <div class="col-6">
                    <label class="form-label">Kartela No</label>
                    <input type="text" class="form-control bg-light" id="f_kartela_no" readonly
                           value="#htmlEditFormat(getColor.kartela_no)#" maxlength="100">
                </div>
                <div class="col-6">
                    <label class="form-label">Kartela Tarihi</label>
                    <input type="date" class="form-control bg-light" id="f_kartela_date" readonly
                           value="#isDate(getColor.kartela_date) ? dateFormat(getColor.kartela_date,'yyyy-mm-dd') : ''#">
                </div>
            </div>

            <div class="form-section-label"><i class="fas fa-flask"></i>Boyama Parametreleri</div>

            <div class="row g-2 mb-3">
                <div class="col-4">
                    <label class="form-label">R.Tonu</label>
                    <input type="number" min="0" max="9" class="form-control bg-light" id="f_renk_tonu" readonly
                           value="#getColor.renk_tonu#">
                </div>
                <div class="col-4">
                    <label class="form-label">Boya C.</label>
                    <input type="text" class="form-control bg-light" id="f_boya_derecesi" readonly
                           value="#htmlEditFormat(getColor.boya_derecesi)#" maxlength="50">
                </div>
                <div class="col-4">
                    <label class="form-label">Flote</label>
                    <input type="number" step="0.01" min="0" class="form-control bg-light" id="f_flote" readonly
                           value="#getColor.flote#">
                </div>
            </div>

            <div class="form-section-label"><i class="fas fa-sticky-note"></i>Ek Bilgi</div>

            <div class="mb-3">
                <label class="form-label">Açıklama</label>
                <input type="text" class="form-control bg-light" id="f_information" readonly
                       value="#htmlEditFormat(getColor.information)#" maxlength="500">
            </div>

            <div class="ready-switch-wrap">
                <span><i class="fas fa-check-circle me-2"></i>Renk hazır mı?</span>
                <div class="form-check form-switch mb-0">
                    <input class="form-check-input" type="checkbox" id="f_is_ready" disabled
                           <cfif getColor.is_ready>checked</cfif>>
                    <label class="form-check-label" for="f_is_ready">Hazır</label>
                </div>
            </div>

        </div>
    </div>
</div>

<!--- ─── SAĞ: Boya Reçetesi ─── --->
<div class="col-lg-7">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title">
                <i class="fas fa-flask"></i>Boya Reçetesi
                <span class="ms-2 text-muted" style="font-weight:400;font-size:0.75rem;">— BOM / Malzeme Listesi</span>
            </div>
            <button class="btn btn-sm btn-outline-primary" onclick="OpenOperationPopup()">
                <i class="fas fa-plus me-1"></i>Operasyon Ekle
            </button>
        </div>
        <div class="card-body p-0">
            <div class="recipe-panel">
                <cfinclude template="/product/display/view_product_tree.cfm">
            </div>
        </div>
    </div>
</div>

</div><!--- row --->

</div><!--- px-3 pb-5 --->

<script>
var editStockId = #editStockId#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
});
</script>

</cfoutput>
