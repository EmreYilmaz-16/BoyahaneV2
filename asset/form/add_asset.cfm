<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.asset_id" default="0">
<cfset assetId = isNumeric(url.asset_id) ? val(url.asset_id) : 0>

<cfquery name="getCategories" datasource="boyahane">
    SELECT category_id, category_name, asset_type
    FROM asset_categories
    WHERE is_active = true
    ORDER BY category_name
</cfquery>

<cfquery name="getLocations" datasource="boyahane">
    SELECT location_id, location_name
    FROM asset_locations
    WHERE is_active = true
    ORDER BY location_name
</cfquery>

<cfquery name="getAsset" datasource="boyahane">
    SELECT * FROM asset_master
    WHERE asset_id = <cfqueryparam value="#assetId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfset isEdit = assetId gt 0 and getAsset.recordCount gt 0>
<cfset row    = isEdit ? getAsset : "">

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <cfif isEdit><i class="fas fa-pen"></i><cfelse><i class="fas fa-box-open"></i></cfif>
        </div>
        <div class="page-header-title">
            <cfif isEdit>
                <h1>Varlık Düzenle</h1>
                <p><cfoutput>#encodeForHTML(row.asset_name)#</cfoutput></p>
            <cfelse>
                <h1>Yeni Varlık</h1>
                <p>Varlık bilgilerini doldurun ve kaydedin</p>
            </cfif>
        </div>
    </div>
    <a href="index.cfm?fuseaction=asset.list_assets" class="btn-add" style="background:var(--primary);border-color:var(--primary);">
        <i class="fas fa-list"></i>Listeye Dön
    </a>
</div>

<div class="px-3 pb-4">
    <form id="assetForm">
        <cfoutput><input type="hidden" name="asset_id" value="#assetId#"></cfoutput>

        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Temel Bilgiler</div>
            </div>
            <div class="card-body p-3">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Varlık No</label>
                        <input type="text" name="asset_no" class="form-control"
                               value="<cfoutput>#isEdit ? encodeForHTMLAttribute(row.asset_no) : ""#</cfoutput>">
                    </div>
                    <div class="col-md-5">
                        <label class="form-label fw-semibold">Varlık Adı <span class="text-danger">*</span></label>
                        <input type="text" name="asset_name" class="form-control" required
                               value="<cfoutput>#isEdit ? encodeForHTMLAttribute(row.asset_name) : ""#</cfoutput>">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label fw-semibold">Tip <span class="text-danger">*</span></label>
                        <select name="asset_type" class="form-select" required>
                            <cfset selectedType = isEdit ? row.asset_type : "PHYSICAL">
                            <option value="PHYSICAL" <cfif selectedType eq "PHYSICAL">selected</cfif>>Fiziki</option>
                            <option value="IT"       <cfif selectedType eq "IT">selected</cfif>>BT / IT</option>
                            <option value="VEHICLE"  <cfif selectedType eq "VEHICLE">selected</cfif>>Araç</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label fw-semibold">Durum</label>
                        <select name="asset_status" class="form-select">
                            <cfset selectedStatus = isEdit ? row.asset_status : "ACTIVE">
                            <option value="ACTIVE"        <cfif selectedStatus eq "ACTIVE">selected</cfif>>Aktif</option>
                            <option value="IN_STOCK"      <cfif selectedStatus eq "IN_STOCK">selected</cfif>>Stokta</option>
                            <option value="IN_MAINTENANCE"<cfif selectedStatus eq "IN_MAINTENANCE">selected</cfif>>Bakımda</option>
                            <option value="TRANSFERRED"   <cfif selectedStatus eq "TRANSFERRED">selected</cfif>>Devredildi</option>
                            <option value="SCRAPPED"      <cfif selectedStatus eq "SCRAPPED">selected</cfif>>Hurda</option>
                            <option value="SOLD"          <cfif selectedStatus eq "SOLD">selected</cfif>>Satıldı</option>
                        </select>
                    </div>
                </div>
            </div>
        </div>

        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-tags"></i>Sınıflandırma</div>
            </div>
            <div class="card-body p-3">
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Kategori</label>
                        <select name="category_id" class="form-select">
                            <option value="">-- Seçiniz --</option>
                            <cfoutput query="getCategories">
                                <option value="#category_id#"
                                    <cfif isEdit and row.category_id eq category_id>selected</cfif>
                                >#encodeForHTML(category_name)# (#asset_type#)</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Lokasyon</label>
                        <select name="location_id" class="form-select">
                            <option value="">-- Seçiniz --</option>
                            <cfoutput query="getLocations">
                                <option value="#location_id#"
                                    <cfif isEdit and row.location_id eq location_id>selected</cfif>
                                >#encodeForHTML(location_name)#</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label fw-semibold">Marka</label>
                        <input type="text" name="brand" class="form-control"
                               value="<cfoutput>#isEdit ? encodeForHTMLAttribute(row.brand) : ""#</cfoutput>">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label fw-semibold">Model</label>
                        <input type="text" name="model" class="form-control"
                               value="<cfoutput>#isEdit ? encodeForHTMLAttribute(row.model) : ""#</cfoutput>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Seri No</label>
                        <input type="text" name="serial_no" class="form-control"
                               value="<cfoutput>#isEdit ? encodeForHTMLAttribute(row.serial_no) : ""#</cfoutput>">
                    </div>
                </div>
            </div>
        </div>

        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-coins"></i>Finansal Bilgiler</div>
            </div>
            <div class="card-body p-3">
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Satın Alma Tarihi</label>
                        <input type="date" name="purchase_date" class="form-control"
                               value="<cfoutput>#isEdit and isDate(row.purchase_date) ? dateFormat(row.purchase_date,"yyyy-mm-dd") : ""#</cfoutput>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Edinim Maliyeti</label>
                        <input type="number" step="0.01" min="0" name="acquisition_cost" class="form-control"
                               value="<cfoutput>#isEdit ? row.acquisition_cost : 0#</cfoutput>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Para Birimi</label>
                        <select name="currency" class="form-select">
                            <cfset selCur = isEdit ? row.currency : "TRY">
                            <option value="TRY" <cfif selCur eq "TRY">selected</cfif>>TRY - Türk Lirası</option>
                            <option value="USD" <cfif selCur eq "USD">selected</cfif>>USD - Dolar</option>
                            <option value="EUR" <cfif selCur eq "EUR">selected</cfif>>EUR - Euro</option>
                        </select>
                    </div>
                </div>
            </div>
        </div>

        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-align-left"></i>Açıklama</div>
            </div>
            <div class="card-body p-3">
                <textarea name="detail" rows="3" class="form-control" placeholder="Varlıkla ilgili ek açıklama..."><cfoutput>#isEdit ? encodeForHTML(row.detail) : ""#</cfoutput></textarea>
            </div>
        </div>

        <div id="saveMsg" class="mb-3"></div>

        <div class="d-flex gap-2 flex-wrap">
            <button type="button" id="btnSave" class="btn btn-warning text-dark fw-bold px-4" onclick="submitAsset()">
                <i class="fas fa-save me-2"></i>Kaydet
            </button>
            <a href="index.cfm?fuseaction=asset.list_assets" class="btn btn-outline-secondary px-4">
                <i class="fas fa-times me-2"></i>İptal
            </a>
            <cfif isEdit>
                <button type="button" class="btn btn-outline-danger px-4 ms-auto" onclick="deleteAsset()">
                    <i class="fas fa-trash me-2"></i>Sil
                </button>
            </cfif>
        </div>

    </form>
</div>

<cfoutput>
<style>
.grid-card-header { padding:14px 20px 12px;border-bottom:1px solid ##e9ecef;display:flex;align-items:center;justify-content:space-between; }
.grid-card-header-title { font-size:.95rem;font-weight:700;color:var(--primary);display:flex;align-items:center;gap:8px; }
.grid-card-header-title i { color:var(--accent); }
.grid-card { background:##fff;border-radius:10px;box-shadow:0 2px 12px rgba(0,0,0,.07);overflow:hidden; }
.form-label { color:##374151; }
.btn-outline-danger:hover { background:##ef4444;color:##fff; }
</style>
<script>
function submitAsset() {
    var form = document.getElementById('assetForm');
    var assetName = form.querySelector('[name=asset_name]').value.trim();
    if (!assetName) {
        document.getElementById('saveMsg').innerHTML = '<div class="alert alert-warning py-2">Varlık adı zorunludur.</div>';
        form.querySelector('[name=asset_name]').focus();
        return;
    }

    var btn = document.getElementById('btnSave');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';
    document.getElementById('saveMsg').innerHTML = '';

    $.ajax({
        url: '/asset/form/save_asset.cfm',
        method: 'POST',
        dataType: 'json',
        data: $(form).serialize(),
        success: function(res) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet';
            if (res && res.success) {
                document.getElementById('saveMsg').innerHTML = '<div class="alert alert-success py-2"><i class="fas fa-check-circle me-2"></i>Başarıyla kaydedildi. Yönlendiriliyorsunuz...</div>';
                setTimeout(function(){
                    window.location.href = res.redirect || 'index.cfm?fuseaction=asset.list_assets';
                }, 900);
            } else {
                document.getElementById('saveMsg').innerHTML = '<div class="alert alert-danger py-2"><i class="fas fa-exclamation-circle me-2"></i>' + (res.message || 'Bir hata oluştu.') + '</div>';
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet';
            document.getElementById('saveMsg').innerHTML = '<div class="alert alert-danger py-2">Sunucu hatası oluştu.</div>';
        }
    });
}

function deleteAsset() {
    if (!confirm('Bu varlık kalıcı olarak silinecek. Emin misiniz?')) return;
    var assetId = document.querySelector('[name=asset_id]').value;
    $.ajax({
        url: '/asset/form/delete_asset.cfm',
        method: 'POST',
        dataType: 'json',
        data: { asset_id: assetId },
        success: function(res) {
            if (res && res.success) {
                window.location.href = res.redirect || 'index.cfm?fuseaction=asset.list_assets';
            } else {
                document.getElementById('saveMsg').innerHTML = '<div class="alert alert-danger py-2">' + (res.message || 'Silinemedi.') + '</div>';
            }
        },
        error: function() {
            document.getElementById('saveMsg').innerHTML = '<div class="alert alert-danger py-2">Sunucu hatası oluştu.</div>';
        }
    });
}
</script>
</cfoutput>