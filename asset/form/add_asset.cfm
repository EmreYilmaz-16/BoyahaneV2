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
    SELECT *
    FROM asset_master
    WHERE asset_id = <cfqueryparam value="#assetId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfset row = getAsset.recordCount ? getAsset : "">

<div class="container-fluid py-3">
    <h3><cfoutput>#assetId gt 0 ? "Varlık Düzenle" : "Yeni Varlık"#</cfoutput></h3>

    <form method="post" action="index.cfm?fuseaction=asset.save_asset" class="row g-3">
        <cfoutput><input type="hidden" name="asset_id" value="#assetId#"></cfoutput>

        <div class="col-md-3">
            <label class="form-label">Varlık No</label>
            <input type="text" name="asset_no" class="form-control" value="<cfoutput>#assetId gt 0 ? encodeForHTMLAttribute(row.asset_no) : ""#</cfoutput>">
        </div>
        <div class="col-md-5">
            <label class="form-label">Varlık Adı *</label>
            <input type="text" name="asset_name" class="form-control" required value="<cfoutput>#assetId gt 0 ? encodeForHTMLAttribute(row.asset_name) : ""#</cfoutput>">
        </div>
        <div class="col-md-2">
            <label class="form-label">Tip *</label>
            <select name="asset_type" class="form-select" required>
                <cfset selectedType = assetId gt 0 ? row.asset_type : "PHYSICAL">
                <option value="PHYSICAL" <cfif selectedType eq "PHYSICAL">selected</cfif>>Fiziki</option>
                <option value="IT" <cfif selectedType eq "IT">selected</cfif>>BT</option>
                <option value="VEHICLE" <cfif selectedType eq "VEHICLE">selected</cfif>>Araç</option>
            </select>
        </div>
        <div class="col-md-2">
            <label class="form-label">Durum</label>
            <select name="asset_status" class="form-select">
                <cfset selectedStatus = assetId gt 0 ? row.asset_status : "ACTIVE">
                <option value="ACTIVE" <cfif selectedStatus eq "ACTIVE">selected</cfif>>Aktif</option>
                <option value="IN_STOCK" <cfif selectedStatus eq "IN_STOCK">selected</cfif>>Stokta</option>
                <option value="IN_MAINTENANCE" <cfif selectedStatus eq "IN_MAINTENANCE">selected</cfif>>Bakımda</option>
                <option value="TRANSFERRED" <cfif selectedStatus eq "TRANSFERRED">selected</cfif>>Devredildi</option>
                <option value="SCRAPPED" <cfif selectedStatus eq "SCRAPPED">selected</cfif>>Hurda</option>
                <option value="SOLD" <cfif selectedStatus eq "SOLD">selected</cfif>>Satıldı</option>
            </select>
        </div>

        <div class="col-md-4">
            <label class="form-label">Kategori</label>
            <select name="category_id" class="form-select">
                <option value="">Seçiniz</option>
                <cfoutput query="getCategories">
                    <option value="#category_id#" <cfif assetId gt 0 and row.category_id eq category_id>selected</cfif>>#encodeForHTML(category_name)# (#asset_type#)</option>
                </cfoutput>
            </select>
        </div>
        <div class="col-md-4">
            <label class="form-label">Lokasyon</label>
            <select name="location_id" class="form-select">
                <option value="">Seçiniz</option>
                <cfoutput query="getLocations">
                    <option value="#location_id#" <cfif assetId gt 0 and row.location_id eq location_id>selected</cfif>>#encodeForHTML(location_name)#</option>
                </cfoutput>
            </select>
        </div>
        <div class="col-md-2">
            <label class="form-label">Marka</label>
            <input type="text" name="brand" class="form-control" value="<cfoutput>#assetId gt 0 ? encodeForHTMLAttribute(row.brand) : ""#</cfoutput>">
        </div>
        <div class="col-md-2">
            <label class="form-label">Model</label>
            <input type="text" name="model" class="form-control" value="<cfoutput>#assetId gt 0 ? encodeForHTMLAttribute(row.model) : ""#</cfoutput>">
        </div>

        <div class="col-md-3">
            <label class="form-label">Seri No</label>
            <input type="text" name="serial_no" class="form-control" value="<cfoutput>#assetId gt 0 ? encodeForHTMLAttribute(row.serial_no) : ""#</cfoutput>">
        </div>
        <div class="col-md-3">
            <label class="form-label">Satın Alma Tarihi</label>
            <input type="date" name="purchase_date" class="form-control" value="<cfoutput>#assetId gt 0 and isDate(row.purchase_date) ? dateFormat(row.purchase_date, "yyyy-mm-dd") : ""#</cfoutput>">
        </div>
        <div class="col-md-3">
            <label class="form-label">Maliyet</label>
            <input type="number" step="0.01" min="0" name="acquisition_cost" class="form-control" value="<cfoutput>#assetId gt 0 ? row.acquisition_cost : 0#</cfoutput>">
        </div>
        <div class="col-md-3">
            <label class="form-label">Para Birimi</label>
            <input type="text" maxlength="10" name="currency" class="form-control" value="<cfoutput>#assetId gt 0 ? encodeForHTMLAttribute(row.currency) : "TRY"#</cfoutput>">
        </div>

        <div class="col-12">
            <label class="form-label">Açıklama</label>
            <textarea name="detail" rows="3" class="form-control"><cfoutput>#assetId gt 0 ? encodeForHTML(row.detail) : ""#</cfoutput></textarea>
        </div>

        <div class="col-12 d-flex gap-2">
            <button type="submit" class="btn btn-success">Kaydet</button>
            <a href="index.cfm?fuseaction=asset.list_assets" class="btn btn-outline-secondary">Listeye Dön</a>
            <cfif assetId gt 0>
                <button type="submit" formaction="index.cfm?fuseaction=asset.delete_asset" class="btn btn-outline-danger" onclick="return confirm('Varlık silinsin mi?')">Sil</button>
            </cfif>
        </div>
    </form>
</div>
