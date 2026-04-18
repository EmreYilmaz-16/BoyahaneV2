<cfparam name="url.color_id" default="0">

<cfquery name="getColors" datasource="boyahane">
    SELECT *
    FROM color_info
    WHERE color_id = <cfqueryparam value="#val(url.color_id)#" cfsqltype="cf_sql_integer">
</cfquery>

<cfoutput>
<link rel="stylesheet" href="/colors/form/productTree.css">

<cfif NOT getColors.recordCount>
    <div class="alert alert-warning"><i class="fas fa-exclamation-triangle me-2"></i>Renk bulunamadı.</div>
    <cfabort>
</cfif>

<cfset isReady = (getColors.is_ready EQ 1 OR getColors.is_ready EQ "true" OR getColors.is_ready EQ "Yes")>

<div class="row g-3 h-100">

    <!--- COL-2: Renk Bilgi Paneli --->
    <div class="col-2">
        <div class="color-side-panel">

            <div class="color-side-header">
                <div class="color-side-header-icon"><i class="fas fa-palette"></i></div>
                <div style="overflow:hidden;">
                    <div class="color-side-header-title">#htmlEditFormat(getColors.color_code)#</div>
                    <div class="color-side-header-sub">#htmlEditFormat(getColors.color_name)#</div>
                </div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-hashtag"></i>Renk Kodu</div>
                <div class="csr-value">#htmlEditFormat(getColors.color_code)#</div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-tag"></i>Renk Adı</div>
                <div class="csr-value">#htmlEditFormat(getColors.color_name)#</div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-swatchbook"></i>Kartela No</div>
                <div class="csr-value">#htmlEditFormat(getColors.kartela_no)#</div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-calendar-alt"></i>Kartela Tarihi</div>
                <div class="csr-value">#dateFormat(getColors.kartela_date, "DD.MM.YYYY")#</div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-fill-drip"></i>Renk Tonu</div>
                <div class="csr-value" id="renkTonu">#htmlEditFormat(getColors.renk_tonu)#</div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-thermometer-half"></i>Boya Derecesi</div>
                <div class="csr-value">#htmlEditFormat(getColors.boya_derecesi)#</div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-check-circle"></i>Durum</div>
                <div class="csr-value">
                    <span class="status-badge #isReady ? 'status-active' : 'status-passive'#">
                        <i class="fas fa-#isReady ? 'check' : 'hourglass-half'#"></i>
                        #isReady ? 'Hazır' : 'Beklemede'#
                    </span>
                </div>
            </div>

        </div>
    </div>

    <!--- COL-10: İçerik Alanı --->
    <div class="col-10">
        <!--- Buraya sayfa içeriği gelecek --->
        <div class="page-header">
            <div class="page-header-title">
                <i class="fas fa-sitemap"></i>
                Renk Kaydet / Güncelle
            </div>
            <button class="btn-add" onclick="saveTree()">
                <i class="fas fa-save"></i> Kaydet
            </button>
        </div>
        <div style="position:relative;">
            <input type="text" id="opSearchInput" class="form-control mt-2" onkeydown="searchOperations(this,event)" placeholder="Operasyon ara... (Enter ile ara)" autocomplete="off">
            <div id="OperationSearchResult" style="display:none;position:absolute;top:calc(100% + 2px);left:0;right:0;z-index:1050;background:##fff;border:1px solid ##dde3ec;border-radius:0 0 10px 10px;box-shadow:0 8px 24px rgba(0,0,0,0.12);max-height:280px;overflow-y:auto;"></div>
        </div>
        <div id="treeArea" class="mt-3"></div>
    </div>

</div>

<!--- Ürün Seçme Modal --->
<div id="productPickerModal" style="display:none;position:fixed;inset:0;z-index:2000;">
    <div style="position:absolute;inset:0;background:rgba(0,0,0,0.45);" onclick="closeProductPicker()"></div>
    <div style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:460px;max-width:95vw;background:##fff;border-radius:14px;box-shadow:0 16px 48px rgba(0,0,0,0.22);overflow:hidden;">
        <div style="background:linear-gradient(135deg,var(--primary-dk),var(--primary));border-bottom:2px solid var(--accent);padding:14px 18px;display:flex;align-items:center;justify-content:space-between;">
            <div style="display:flex;align-items:center;gap:9px;">
                <div style="width:32px;height:32px;background:var(--accent);border-radius:7px;display:flex;align-items:center;justify-content:center;">
                    <i class="fas fa-plus" style="color:##fff;font-size:0.8rem;"></i>
                </div>
                <span style="font-size:0.9rem;font-weight:700;color:##fff;">Ürün Ekle</span>
            </div>
            <button onclick="closeProductPicker()" style="background:rgba(255,255,255,0.15);border:none;border-radius:7px;width:30px;height:30px;color:##fff;cursor:pointer;font-size:1rem;display:flex;align-items:center;justify-content:center;">&times;</button>
        </div>
        <div style="padding:14px 16px;border-bottom:1px solid ##eef1f6;">
            <input type="text" id="productPickerSearch" class="form-control" placeholder="Ürün adı veya kodu ile ara..." autocomplete="off"
                oninput="searchProductPicker(this.value)">
        </div>
        <div id="productPickerList" style="max-height:320px;overflow-y:auto;"></div>
        <div style="padding:10px 16px;background:##f8fafc;border-top:1px solid ##eef1f6;font-size:0.72rem;color:##94a3b8;">
            <i class="fas fa-info-circle me-1"></i>Ürüne tıklayarak seçebilirsiniz.
        </div>
    </div>
</div>

</cfoutput>
<script src="/colors/form/colorTreeFunctions.js"></script>


<cfoutput>
<script>
document.addEventListener('DOMContentLoaded', function() {
    var stockId = #val(getColors.stock_id)#;
    if (stockId > 0) {
        LoadColorTree(stockId);
    }
});
</script>

</cfoutput>

