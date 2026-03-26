<cfprocessingdirective pageEncoding="utf-8">

<!---
    Renk Ekle / Düzenle
    url.stock_id  = düzenleme modunda mevcut rengin stock_id'si (opsiyonel)
--->

<cfparam name="url.stock_id" default="0">
<cfset editStockId = isNumeric(url.stock_id) AND val(url.stock_id) gt 0 ? val(url.stock_id) : 0>
<cfset isEdit      = editStockId gt 0>

<!--- Düzenleme modunda mevcut rengi yükle --->
<cfif isEdit>
    <cfquery name="getColor" datasource="boyahane">
        SELECT ci.*, s.stock_code
        FROM color_info ci
        LEFT JOIN stocks s ON ci.stock_id = s.stock_id
        WHERE ci.stock_id = <cfqueryparam value="#editStockId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getColor.recordCount>
        <cflocation url="index.cfm?fuseaction=colors.list_colors" addtoken="false">
    </cfif>
</cfif>

<!--- Müşteri listesi --->
<cfquery name="getCompanies" datasource="boyahane">
    SELECT company_id, COALESCE(nickname, fullname, '') AS company_name, member_code
    FROM company
    WHERE company_status = true
    ORDER BY nickname, fullname
</cfquery>
<cfset companiesArr = []>
<cfloop query="getCompanies">
    <cfset arrayAppend(companiesArr, {
        "company_id"  : val(company_id),
        "company_name": company_name ?: "",
        "member_code" : member_code  ?: ""
    })>
</cfloop>


<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-palette"></i></div>
        <div class="page-header-title">
            <h1><cfif isEdit>Renk Düzenle<cfelse>Yeni Renk</cfif></h1>
            <p><cfif isEdit>#htmlEditFormat(getColor.color_code)# — #htmlEditFormat(getColor.color_name)#<cfelse>Yeni renk kaydı oluşturun</cfif></p>
        </div>
    </div>
    <div class="d-flex gap-2">
        <button class="btn-add" id="btnSave" onclick="saveColor()">
            <i class="fas fa-save"></i>Kaydet
        </button>
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

            <input type="hidden" id="h_stock_id"   value="#editStockId#">
            <input type="hidden" id="h_company_id" value="#isEdit ? getColor.company_id : ''#">
            <input type="hidden" id="h_product_id" value="#isEdit ? getColor.product_id : ''#">

            <!--- Müşteri --->
            <div class="mb-3">
                <label class="form-label">Müşteri <span class="text-danger">*</span></label>
                <div id="companySelect"></div>
            </div>

            <!--- Ürün / Kumaş --->
            <div class="mb-3">
                <label class="form-label">Ürün / Kumaş <span class="text-danger">*</span></label>
                <div id="productSelect"></div>
                <div class="form-text">Önce müşteri seçin.</div>
            </div>

            <div class="row g-2 mb-3">
                <div class="col-5">
                    <label class="form-label">Renk Kodu</label>
                    <input type="text" class="form-control" id="f_color_code"
                           value="#isEdit ? htmlEditFormat(getColor.color_code) : ''#" maxlength="100" placeholder="R.Kodu">
                </div>
                <div class="col-7">
                    <label class="form-label">Renk Adı</label>
                    <input type="text" class="form-control" id="f_color_name"
                           value="#isEdit ? htmlEditFormat(getColor.color_name) : ''#" maxlength="255" placeholder="Renk adı">
                </div>
            </div>

            <div class="row g-2 mb-3">
                <div class="col-6">
                    <label class="form-label">Kartela No</label>
                    <input type="text" class="form-control" id="f_kartela_no"
                           value="#isEdit ? htmlEditFormat(getColor.kartela_no) : ''#" maxlength="100">
                </div>
                <div class="col-6">
                    <label class="form-label">Kartela Tarihi</label>
                    <input type="date" class="form-control" id="f_kartela_date"
                           value="#isEdit AND isDate(getColor.kartela_date) ? dateFormat(getColor.kartela_date,'yyyy-mm-dd') : ''#">
                </div>
            </div>

            <div class="row g-2 mb-3">
                <div class="col-4">
                    <label class="form-label">R.Tonu</label>
                    <input type="number" min="0" max="9" class="form-control" id="f_renk_tonu"
                           value="#isEdit ? getColor.renk_tonu : ''#">
                </div>
                <div class="col-4">
                    <label class="form-label">Boya C.</label>
                    <input type="text" class="form-control" id="f_boya_derecesi"
                           value="#isEdit ? htmlEditFormat(getColor.boya_derecesi) : ''#" maxlength="50">
                </div>
                <div class="col-4">
                    <label class="form-label">Flote</label>
                    <input type="number" step="0.01" min="0" class="form-control" id="f_flote"
                           value="#isEdit ? getColor.flote : ''#">
                </div>
            </div>

            <div class="mb-3">
                <label class="form-label">Açıklama</label>
                <input type="text" class="form-control" id="f_information"
                       value="#isEdit ? htmlEditFormat(getColor.information) : ''#" maxlength="500">
            </div>

            <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" id="f_is_ready"
                       <cfif isEdit AND getColor.is_ready>checked</cfif>>
                <label class="form-check-label" for="f_is_ready">Hazır</label>
            </div>

        </div>
    </div>
</div>

<!--- ─── SAĞ: Boya Reçetesi ─── --->
<div class="col-lg-7">
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-flask"></i>Boya Reçetesi</div>
            <button class="btn btn-sm btn-outline-primary" onclick="OpenOperationPopup()">
                <i class="fas fa-plus me-1"></i>Operasyon
            </button>
        </div>
        <div class="card-body p-3">
            <div id="CurrentTree"></div>
        </div>
    </div>
</div>

</div><!--- row --->

</div><!--- px-3 pb-5 --->
</cfoutput>

<script>
    var uri="/index.cfm?fuseaction=product.view_product_tree_ajax&stock_id=<cfoutput>#editStockId#</cfoutput>";
    $.ajax({
        url: uri,
        method: "GET",
        dataType: "html"
    }).done(function(data){
        var $wrapper = $("<div>").html(data);
        var scripts = [];

        $wrapper.find("script").each(function(){
            var $script = $(this);
            scripts.push({
                src: $script.attr("src"),
                type: ($script.attr("type") || "").toLowerCase(),
                text: $script.html()
            });
            $script.remove();
        });

        $("#CurrentTree").html($wrapper.html());

        scripts.forEach(function(s){
            if (s.type && s.type !== "text/javascript" && s.type !== "application/javascript") return;
            var tag = document.createElement("script");
            if (s.src) {
                tag.src = s.src;
            } else if (s.text) {
                tag.text = s.text;
            }
            document.body.appendChild(tag);
        });
    }).fail(function(xhr){
        var msg = "Ürün ağacı yüklenemedi.";
        if (xhr && xhr.status) msg += " (HTTP " + xhr.status + ")";
        $("#CurrentTree").html('<div class="alert alert-warning mb-0">' + msg + '</div>');
    });
</script>
