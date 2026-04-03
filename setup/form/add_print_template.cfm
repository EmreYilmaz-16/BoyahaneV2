<cfprocessingdirective pageEncoding="utf-8">

<cfset editMode = structKeyExists(url,"form_id") AND isNumeric(url.form_id) AND val(url.form_id) GT 0>

<cfif editMode>
    <cfquery name="getTpl" datasource="boyahane">
        SELECT * FROM setup_print_files
        WHERE form_id = <cfqueryparam value="#val(url.form_id)#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getTpl.recordCount>
        <cflocation url="index.cfm?fuseaction=setup.list_print_templates" addtoken="false">
    </cfif>
</cfif>

<!--- Kategori listesi --->
<cfquery name="getCats" datasource="boyahane">
    SELECT print_cat_id, print_name, print_type
    FROM setup_print_files_cats
    ORDER BY print_type
</cfquery>
<cfset catsArr = []>
<cfloop query="getCats">
    <cfset arrayAppend(catsArr, {
        "print_cat_id": val(print_cat_id),
        "print_name"  : print_name ?: "",
        "print_type"  : val(print_type)
    })>
</cfloop>

<cffunction name="fv" output="false">
    <cfargument name="col">
    <cfif editMode AND getTpl.recordCount>
        <cfreturn htmlEditFormat(getTpl[col][1])>
    </cfif>
    <cfreturn "">
</cffunction>
<cffunction name="fb" output="false">
    <cfargument name="col">
    <cfargument name="default" default="false">
    <cfif editMode AND getTpl.recordCount>
        <cfreturn getTpl[col][1]>
    </cfif>
    <cfreturn arguments.default>
</cffunction>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-print"></i></div>
        <div class="page-header-info">
            <h1 class="page-title">#editMode ? "Şablon Düzenle" : "Yeni Şablon"#</h1>
            <p class="page-subtitle">CFM tabanlı yazdırma şablonu #editMode ? "güncelle" : "ekle"#</p>
        </div>
    </div>
    <div class="page-header-right">
        <a href="index.cfm?fuseaction=setup.list_print_templates" class="btn btn-light">
            <i class="fas fa-arrow-left me-1"></i> Listeye Dön
        </a>
    </div>
</div>

<div class="card shadow-sm">
    <div class="card-body">
        <form id="tplForm" method="post" enctype="multipart/form-data">
            <input type="hidden" name="form_id" value="#editMode ? val(url.form_id) : 0#">

            <div class="row g-3">
                <div class="col-md-6">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Şablon Adı <span class="text-danger">*</span></label>
                        <div id="txtName"></div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Belge Kategorisi <span class="text-danger">*</span></label>
                        <div id="selCat"></div>
                        <div class="form-text">Hangi belge türü için kullanılacak? (process_type)</div>
                    </div>
                    <div class="mb-3">
                        <label class="form-label fw-semibold">Açıklama</label>
                        <div id="txtDetail"></div>
                    </div>
                </div>

                <div class="col-md-6">
                    <div class="mb-3">
                        <label class="form-label fw-semibold">CFM Şablon Dosyası</label>
                        <input type="file" class="form-control" name="template_cfm_file" accept=".cfm">
                        <div class="form-text">
                            <cfif editMode AND len(trim(fv("template_file")))>
                                Mevcut: <code>#fv("template_file")#</code> — yeni seçilirse üzerine yazılır.
                            <cfelse>
                                Sadece <code>.cfm</code> uzantılı dosya. Yüklendikten sonra <code>/documents/print_files/</code> altına kaydedilir.
                            </cfif>
                        </div>
                    </div>
                    <div class="mb-3 d-flex flex-column gap-2 pt-2">
                        <div id="chkActive"></div>
                        <div id="chkIsDefault"></div>
                        <div id="chkIsStandart"></div>
                    </div>
                </div>
            </div>

            <hr>
            <div class="d-flex gap-2">
                <button type="button" onclick="saveTpl()" class="btn btn-primary">
                    <i class="fas fa-save me-1"></i> #editMode ? "Güncelle" : "Kaydet"#
                </button>
                <a href="index.cfm?fuseaction=setup.list_print_templates" class="btn btn-light">
                    <i class="fas fa-times me-1"></i> İptal
                </a>
            </div>
        </form>
    </div>
</div>

<script>
var catsData   = #serializeJSON(catsArr)#;
var editMode   = #editMode ? "true" : "false"#;
var curCatType = #editMode AND getTpl.recordCount ? val(getTpl.process_type[1]) : 0#;

$(function() {
    $("##txtName").dxTextBox({
        value: "#jsstringformat(fv("name"))#",
        placeholder: "Şablon adı...",
        stylingMode: "outlined"
    });

    $("##selCat").dxSelectBox({
        dataSource: catsData,
        valueExpr: "print_type",
        displayExpr: "print_name",
        value: curCatType || null,
        placeholder: "Belge türü seçin...",
        stylingMode: "outlined",
        searchEnabled: true
    });

    $("##txtDetail").dxTextArea({
        value: "#jsstringformat(fv("detail"))#",
        placeholder: "Kısa açıklama...",
        stylingMode: "outlined",
        height: 70
    });

    $("##chkActive").dxCheckBox({
        value: #fb("active","true")#,
        text: "Aktif — kullanıcılar bu şablonu seçebilir"
    });

    $("##chkIsDefault").dxCheckBox({
        value: #fb("is_default","false")#,
        text: "Varsayılan şablon (bu kategoride önce göster)"
    });

    $("##chkIsStandart").dxCheckBox({
        value: #fb("is_standart","true")#,
        text: "Standart şablon"
    });
});

function saveTpl() {
    var name = $("##txtName").dxTextBox("instance").option("value");
    var cat  = $("##selCat").dxSelectBox("instance").option("value");

    if (!name || !name.trim()) {
        DevExpress.ui.notify("Şablon adı zorunludur.", "warning", 2500);
        return;
    }
    if (!cat) {
        DevExpress.ui.notify("Belge kategorisi seçiniz.", "warning", 2500);
        return;
    }

    var fd = new FormData(document.getElementById("tplForm"));
    fd.set("name",        name.trim());
    fd.set("process_type", cat);
    fd.set("detail",      $("##txtDetail").dxTextArea("instance").option("value") || "");
    fd.set("active",      $("##chkActive").dxCheckBox("instance").option("value") ? "true" : "false");
    fd.set("is_default",  $("##chkIsDefault").dxCheckBox("instance").option("value") ? "true" : "false");
    fd.set("is_standart", $("##chkIsStandart").dxCheckBox("instance").option("value") ? "true" : "false");

    $.ajax({
        url: "index.cfm?fuseaction=setup.save_print_template",
        type: "POST",
        data: fd,
        processData: false,
        contentType: false,
        success: function(resp) {
            var r = typeof resp === "string" ? JSON.parse(resp) : resp;
            if (r.success) {
                window.location.href = "index.cfm?fuseaction=setup.list_print_templates&success=" + (r.mode || "added");
            } else {
                DevExpress.ui.notify(r.message || "Kayıt başarısız.", "error", 4000);
            }
        },
        error: function() {
            DevExpress.ui.notify("Sunucu hatası.", "error", 4000);
        }
    });
}
</script>
</cfoutput>
