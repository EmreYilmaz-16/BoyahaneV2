<cfparam name="url.color_id" default="0">

<cfquery name="getColors" datasource="boyahane">
    SELECT *
    FROM color_info
    WHERE color_id = <cfqueryparam value="#val(url.color_id)#" cfsqltype="cf_sql_integer">
</cfquery>

<cfoutput>
<link rel="stylesheet" href="/colors/form/productTree.css">
<style>
.ci-input {
    width: 100%;
    background: transparent;
    border: none;
    border-bottom: 1px solid ##e2e8f0;
    padding: 2px 0;
    font-size: 0.82rem;
    font-weight: 600;
    color: ##1e293b;
    outline: none;
    font-family: inherit;
}
.ci-input:focus { border-bottom-color: var(--accent); }
select.ci-input { cursor: pointer; }
</style>

<cfif NOT getColors.recordCount>
    <div class="alert alert-warning"><i class="fas fa-exclamation-triangle me-2"></i>Renk bulunamadı.</div>
    <cfabort>
</cfif>

<cfset isReady = (getColors.is_ready EQ 1 OR getColors.is_ready EQ "true" OR getColors.is_ready EQ "Yes")>

<div class="row g-3 h-100">

    <!--- COL-2: Renk Bilgi Paneli --->
    <div class="col-2">
        <div class="color-side-panel" style="display:flex;flex-direction:column;">

            <div class="color-side-header">
                <div class="color-side-header-icon"><i class="fas fa-palette"></i></div>
                <div style="overflow:hidden;">
                    <div class="color-side-header-title" id="sidePanelCode">#htmlEditFormat(getColors.color_code)#</div>
                    <div class="color-side-header-sub" id="sidePanelName">#htmlEditFormat(getColors.color_name)#</div>
                </div>
            </div>

            <input type="hidden" id="ci_stock_id" value="#val(getColors.stock_id)#">

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-hashtag"></i>Renk Kodu</div>
                <div class="csr-value">
                    <input type="text" id="ci_color_code" class="ci-input" value="#htmlEditFormat(getColors.color_code)#"
                           oninput="document.getElementById('sidePanelCode').textContent=this.value">
                </div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-tag"></i>Renk Adı</div>
                <div class="csr-value">
                    <input type="text" id="ci_color_name" class="ci-input" value="#htmlEditFormat(getColors.color_name)#"
                           oninput="document.getElementById('sidePanelName').textContent=this.value">
                </div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-swatchbook"></i>Kartela No</div>
                <div class="csr-value">
                    <input type="text" id="ci_kartela_no" class="ci-input" value="#htmlEditFormat(getColors.kartela_no)#">
                </div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-calendar-alt"></i>Kartela Tarihi</div>
                <div class="csr-value">
                    <input type="date" id="ci_kartela_date" class="ci-input"
                           value="#len(trim(getColors.kartela_date)) ? dateFormat(getColors.kartela_date,'YYYY-MM-DD') : ''#">
                </div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-fill-drip"></i>Renk Tonu</div>
                <div class="csr-value">
                    <input type="number" id="ci_renk_tonu" class="ci-input" min="0" value="#val(getColors.renk_tonu)#">
                </div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-thermometer-half"></i>Boya Derecesi</div>
                <div class="csr-value">
                    <input type="text" id="ci_boya_derecesi" class="ci-input" value="#htmlEditFormat(getColors.boya_derecesi)#">
                </div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-check-circle"></i>Durum</div>
                <div class="csr-value">
                    <select id="ci_is_ready" class="ci-input">
                        <option value="true"  #isReady ? 'selected' : ''#>Hazır</option>
                        <option value="false" #isReady ? '' : 'selected'#>Beklemede</option>
                    </select>
                </div>
            </div>

            <div class="color-side-row">
                <div class="csr-label"><i class="fas fa-clock"></i>Toplam Süre</div>
                <div class="csr-value">
                    <span id="totalDurationDisplay" style="font-size:0.82rem;font-weight:600;color:#1e293b;">—</span>
                </div>
            </div>

            <div class="color-side-row" style="flex-direction:column;align-items:flex-start;gap:4px;">
                <div class="csr-label"><i class="fas fa-sticky-note"></i>Açıklama</div>
                <div class="csr-value" style="width:100%;">
                    <textarea id="ci_information" class="ci-input" rows="3"
                        style="resize:vertical;line-height:1.4;padding:3px 0;"
                        placeholder="Notlar, özel talimatlar...">#htmlEditFormat(getColors.information ?: '')#</textarea>
                </div>
            </div>

            <div style="padding:10px 14px;margin-top:auto;border-top:1px solid ##f1f5f9;">
                <button type="button" id="ci_saveBtn" onclick="saveColorInfo()"
                        style="width:100%;background:var(--accent);border:none;border-radius:7px;color:##fff;font-size:0.78rem;font-weight:700;padding:8px 0;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:6px;">
                    <i class="fas fa-save"></i> Bilgileri Güncelle
                </button>
                <div id="ci_msg" style="display:none;font-size:0.72rem;text-align:center;margin-top:6px;padding:4px 8px;border-radius:5px;"></div>
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
            <div style="display:flex;gap:0;margin-left:auto;">
                <button class="btn-add" onclick="saveTree()" style="border-radius:8px 0 0 8px;border-right:1px solid rgba(255,255,255,0.25);">
                    <i class="fas fa-save"></i> Kaydet
                </button>
                <a href="/index.cfm?fuseaction=production.add_operation_type" target="_blank" class="btn-add" style="text-decoration:none;border-radius:0 8px 8px 0;">
                    <i class="fas fa-plus-circle"></i> Operasyon Ekle
                </a>
            </div>
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

function saveColorInfo() {
    var btn  = document.getElementById('ci_saveBtn');
    var msgEl = document.getElementById('ci_msg');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Kaydediliyor...';
    msgEl.style.display = 'none';

    $.ajax({
        url: '/colors/form/upd_color_info.cfm',
        method: 'POST',
        dataType: 'json',
        data: {
            stock_id:      document.getElementById('ci_stock_id').value,
            color_code:    document.getElementById('ci_color_code').value,
            color_name:    document.getElementById('ci_color_name').value,
            kartela_no:    document.getElementById('ci_kartela_no').value,
            kartela_date:  document.getElementById('ci_kartela_date').value,
            renk_tonu:     document.getElementById('ci_renk_tonu').value,
            boya_derecesi: document.getElementById('ci_boya_derecesi').value,
            is_ready:      document.getElementById('ci_is_ready').value,
            information:   document.getElementById('ci_information').value
        },
        success: function(res) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save"></i> Bilgileri Güncelle';
            msgEl.style.display = 'block';
            if (res.success) {
                msgEl.style.background = '##dcfce7';
                msgEl.style.color = '##166534';
                msgEl.textContent = res.message;
            } else {
                msgEl.style.background = '##fee2e2';
                msgEl.style.color = '##991b1b';
                msgEl.textContent = res.message || 'Kayıt hatası';
            }
            setTimeout(function() { msgEl.style.display = 'none'; }, 3000);
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save"></i> Bilgileri Güncelle';
            msgEl.style.display = 'block';
            msgEl.style.background = '##fee2e2';
            msgEl.style.color = '##991b1b';
            msgEl.textContent = 'Sunucu hatası';
        }
    });
}
</script>

</cfoutput>

