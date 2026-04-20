<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.asset_type" default="">
<cfparam name="url.search" default="">

<cfquery name="getAssets" datasource="boyahane">
    SELECT am.asset_id,
           am.asset_no,
           am.asset_name,
           am.asset_type,
           am.asset_status,
           am.brand,
           am.model,
           am.serial_no,
           am.purchase_date,
           am.acquisition_cost,
           ac.category_name,
           al.location_name
    FROM asset_master am
    LEFT JOIN asset_categories ac ON ac.category_id = am.category_id
    LEFT JOIN asset_locations al ON al.location_id = am.location_id
    WHERE 1 = 1
    <cfif len(trim(url.asset_type))>
        AND am.asset_type = <cfqueryparam value="#trim(url.asset_type)#" cfsqltype="cf_sql_varchar">
    </cfif>
    <cfif len(trim(url.search))>
        AND (
            UPPER(am.asset_name) LIKE UPPER(<cfqueryparam value="%#trim(url.search)#%" cfsqltype="cf_sql_varchar">)
            OR UPPER(COALESCE(am.asset_no,'')) LIKE UPPER(<cfqueryparam value="%#trim(url.search)#%" cfsqltype="cf_sql_varchar">)
            OR UPPER(COALESCE(am.serial_no,'')) LIKE UPPER(<cfqueryparam value="%#trim(url.search)#%" cfsqltype="cf_sql_varchar">)
        )
    </cfif>
    ORDER BY am.asset_id DESC
</cfquery>

<div class="container-fluid py-3">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h3 class="mb-0">Varlık Yönetimi</h3>
        <a href="index.cfm?fuseaction=asset.add_asset" class="btn btn-primary">Yeni Varlık</a>
    </div>

    <form method="get" action="index.cfm" class="row g-2 mb-3">
        <input type="hidden" name="fuseaction" value="asset.list_assets">
        <div class="col-md-3">
            <select name="asset_type" class="form-select">
                <option value="">Tümü</option>
                <option value="PHYSICAL" <cfif url.asset_type eq "PHYSICAL">selected</cfif>>Fiziki Varlık</option>
                <option value="IT" <cfif url.asset_type eq "IT">selected</cfif>>BT Varlığı</option>
                <option value="VEHICLE" <cfif url.asset_type eq "VEHICLE">selected</cfif>>Araç</option>
            </select>
        </div>
        <div class="col-md-5">
            <input type="text" name="search" class="form-control" placeholder="Varlık no / ad / seri no" value="<cfoutput>#encodeForHTMLAttribute(url.search)#</cfoutput>">
        </div>
        <div class="col-md-4 d-flex gap-2">
            <button type="submit" class="btn btn-outline-primary">Filtrele</button>
            <a href="index.cfm?fuseaction=asset.list_assets" class="btn btn-outline-secondary">Temizle</a>
        </div>
    </form>

    <div class="table-responsive">
        <table class="table table-sm table-striped align-middle">
            <thead>
                <tr>
                    <th>#</th>
                    <th>Varlık No</th>
                    <th>Varlık Adı</th>
                    <th>Tip</th>
                    <th>Kategori</th>
                    <th>Lokasyon</th>
                    <th>Durum</th>
                    <th class="text-end">Maliyet</th>
                    <th>İşlem</th>
                </tr>
            </thead>
            <tbody>
                <cfoutput query="getAssets">
                    <tr>
                        <td>#asset_id#</td>
                        <td>#encodeForHTML(asset_no ?: "-")#</td>
                        <td>#encodeForHTML(asset_name)#</td>
                        <td>#encodeForHTML(asset_type)#</td>
                        <td>#encodeForHTML(category_name ?: "-")#</td>
                        <td>#encodeForHTML(location_name ?: "-")#</td>
                        <td>#encodeForHTML(asset_status)#</td>
                        <td class="text-end">#numberFormat(acquisition_cost ?: 0, "9,999,999.99")#</td>
                        <td>
                            <a class="btn btn-sm btn-outline-primary" href="index.cfm?fuseaction=asset.add_asset&asset_id=#asset_id#">Düzenle</a>
                        </td>
                    </tr>
                </cfoutput>
            </tbody>
        </table>
    </div>
</div>
