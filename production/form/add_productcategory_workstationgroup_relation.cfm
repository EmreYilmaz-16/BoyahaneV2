<cfprocessingdirective pageEncoding="utf-8">

<cfset editMode = isDefined("url.id") AND isNumeric(url.id) AND val(url.id) gt 0>
<cfset currentId = editMode ? val(url.id) : 0>

<cfif editMode>
    <cfquery name="getRec" datasource="boyahane">
        SELECT id, product_catid, workstation_id
        FROM productcategory_workstationgroup_relation
        WHERE id = <cfqueryparam value="#currentId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getRec.recordCount>
        <cfset editMode = false>
        <cfset currentId = 0>
    </cfif>
</cfif>

<cfquery name="getCats" datasource="boyahane">
    SELECT product_catid, COALESCE(product_cat, '') AS product_cat, COALESCE(hierarchy, '') AS hierarchy
    FROM product_cat
    ORDER BY hierarchy, product_cat
</cfquery>
<cfset catArr = []>
<cfloop query="getCats">
    <cfset arrayAppend(catArr, {
        "product_catid": isNumeric(product_catid) ? val(product_catid) : 0,
        "product_cat": product_cat ?: "",
        "hierarchy": hierarchy ?: "",
        "label": (len(trim(hierarchy)) ? trim(hierarchy) & " - " : "") & (product_cat ?: "")
    })>
</cfloop>

<cfquery name="getStations" datasource="boyahane">
    SELECT station_id, COALESCE(station_name, '') AS station_name
    FROM workstations
    WHERE COALESCE(active, true) = true
    ORDER BY station_name
</cfquery>
<cfset stationArr = []>
<cfloop query="getStations">
    <cfset arrayAppend(stationArr, {
        "station_id": isNumeric(station_id) ? val(station_id) : 0,
        "station_name": station_name ?: ""
    })>
</cfloop>

<cfset fProductCatId = editMode ? (isNumeric(getRec.product_catid) ? val(getRec.product_catid) : 0) : 0>
<cfset fWorkstationId = editMode ? (isNumeric(getRec.workstation_id) ? val(getRec.workstation_id) : 0) : 0>

<cfif NOT structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-link"></i></div>
        <div class="page-header-title">
            <h1><cfoutput>#editMode ? "Eşleştirme Düzenle" : "Yeni Eşleştirme"#</cfoutput></h1>
            <p>Ürün kategorisini iş istasyonuna bağlayın</p>
        </div>
    </div>
    <button class="btn-back" onclick="window.location.href='index.cfm?fuseaction=production.list_productcategory_workstationgroup_relation'">
        <i class="fas fa-arrow-left"></i>Listeye Dön
    </button>
</div>

<div class="px-3 pb-5">
    <div class="grid-card mb-3">
        <div class="grid-card-header">
            <div class="grid-card-header-title">
                <i class="fas fa-<cfoutput>#editMode ? "edit" : "plus-circle"#</cfoutput>"></i>
                <cfoutput>#editMode ? "Eşleştirme Güncelle" : "Yeni Eşleştirme Ekle"#</cfoutput>
            </div>
        </div>
        <div class="card-body p-3">
            <form id="relationForm" autocomplete="off">
                <cfoutput><input type="hidden" id="relation_id" value="#currentId#"></cfoutput>

                <div class="row g-3">
                    <div class="col-md-6">
                        <label class="form-label">Ürün Kategorisi <span class="text-danger">*</span></label>
                        <select class="form-select" id="f_product_catid" required>
                            <option value="0">Seçiniz...</option>
                            <cfoutput>
                            <cfloop array="#catArr#" index="c">
                                <option value="#c.product_catid#" <cfif fProductCatId eq c.product_catid>selected</cfif>>#htmlEditFormat(c.label)#</option>
                            </cfloop>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">İş İstasyonu <span class="text-danger">*</span></label>
                        <select class="form-select" id="f_workstation_id" required>
                            <option value="0">Seçiniz...</option>
                            <cfoutput>
                            <cfloop array="#stationArr#" index="s">
                                <option value="#s.station_id#" <cfif fWorkstationId eq s.station_id>selected</cfif>>#htmlEditFormat(s.station_name)#</option>
                            </cfloop>
                            </cfoutput>
                        </select>
                    </div>
                </div>

                <div class="row mt-4">
                    <div class="col-12 d-flex gap-2">
                        <button type="submit" class="btn-save" id="btnSave">
                            <i class="fas fa-save me-1"></i>Kaydet
                        </button>
                        <button type="button" class="btn-back" onclick="window.location.href='index.cfm?fuseaction=production.list_productcategory_workstationgroup_relation'">
                            <i class="fas fa-times me-1"></i>İptal
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
$(document).ready(function(){
    $('#relationForm').on('submit', function(e){
        e.preventDefault();

        var productCatId = parseInt($('#f_product_catid').val(), 10) || 0;
        var workstationId = parseInt($('#f_workstation_id').val(), 10) || 0;

        if (!productCatId) { DevExpress.ui.notify('Ürün kategorisi zorunludur.', 'error', 3000); return; }
        if (!workstationId) { DevExpress.ui.notify('İş istasyonu zorunludur.', 'error', 3000); return; }

        var btn = $('#btnSave').prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i>Kaydediliyor...');

        $.ajax({
            url: '/production/form/save_productcategory_workstationgroup_relation.cfm',
            method: 'POST',
            dataType: 'json',
            data: {
                id: $('#relation_id').val(),
                product_catid: productCatId,
                workstation_id: workstationId
            },
            success: function(res){
                if (res && res.success) {
                    window.location.href = 'index.cfm?fuseaction=production.list_productcategory_workstationgroup_relation&success=' + (res.mode || 'added');
                } else {
                    btn.prop('disabled', false).html('<i class="fas fa-save me-1"></i>Kaydet');
                    DevExpress.ui.notify((res && res.message) || 'Kayıt başarısız.', 'error', 3500);
                }
            },
            error: function(){
                btn.prop('disabled', false).html('<i class="fas fa-save me-1"></i>Kaydet');
                DevExpress.ui.notify('Sunucu hatası.', 'error', 3000);
            }
        });
    });
});
</script>
