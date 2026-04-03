<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.process_type" default="0">
<cfparam name="url.doc_id"       default="0">
<cfparam name="url.form_id"      default="0">

<cfset processType = val(url.process_type)>
<cfset docId       = val(url.doc_id)>
<cfset selectedTpl = val(url.form_id)>

<!--- Mevcut kategorinin adını getir --->
<cfquery name="getCat" datasource="boyahane">
    SELECT print_name FROM setup_print_files_cats
    WHERE print_type = <cfqueryparam value="#processType#" cfsqltype="cf_sql_integer">
    LIMIT 1
</cfquery>

<cfset catName = getCat.recordCount ? getCat.print_name : "Belge">

<!--- Bu process_type için aktif şablonları listele --->
<cfquery name="getTemplates" datasource="boyahane">
    SELECT form_id, name, detail, is_default
    FROM setup_print_files
    WHERE process_type = <cfqueryparam value="#processType#" cfsqltype="cf_sql_integer">
      AND active = true
    ORDER BY is_default DESC, name
</cfquery>

<cfif NOT getTemplates.recordCount>
    <div class="alert alert-warning mt-3">
        <i class="fas fa-exclamation-triangle me-2"></i>
        Bu belge türü (<cfoutput>#htmlEditFormat(catName)#</cfoutput>) için tanımlı aktif şablon bulunamadı.
        <a href="index.cfm?fuseaction=setup.add_print_template" class="alert-link">Şablon Ekle &rarr;</a>
    </div>
    <cfabort>
</cfif>

<!--- Şablon seçili değilse varsayılanı al --->
<cfif selectedTpl EQ 0>
    <cfquery name="getDefault" datasource="boyahane">
        SELECT form_id FROM setup_print_files
        WHERE process_type = <cfqueryparam value="#processType#" cfsqltype="cf_sql_integer">
          AND active = true AND is_default = true
        LIMIT 1
    </cfquery>
    <cfif getDefault.recordCount>
        <cfset selectedTpl = val(getDefault.form_id)>
    <cfelse>
        <cfset selectedTpl = val(getTemplates.form_id[1])>
    </cfif>
</cfif>

<!--- Seçili şablon bilgisi --->
<cfquery name="getTpl" datasource="boyahane">
    SELECT form_id, name, template_file
    FROM setup_print_files
    WHERE form_id       = <cfqueryparam value="#selectedTpl#"   cfsqltype="cf_sql_integer">
      AND process_type  = <cfqueryparam value="#processType#"   cfsqltype="cf_sql_integer">
      AND active = true
</cfquery>

<!--- Şablon listesini JS dizisi olarak hazırla --->
<cfset tplArr = []>
<cfloop query="getTemplates">
    <cfset arrayAppend(tplArr, {
        "form_id"   : val(form_id),
        "name"      : name ?: "",
        "is_default": is_default
    })>
</cfloop>

<!--- Print amaçlı minimal CSS (bu sayfa popup/standart olarak açılabilir) --->
<cfoutput>
<style>
/* Yazdırma kontrolleri ekranda görünür, yazdırırken gizlenir */
@media print {
    .print-controls, .sidebar, .navbar, nav, .page-header,
    .sidebar-backdrop, .content-wrapper > .print-controls { display: none !important; }
    .print-body { margin: 0 !important; padding: 0 !important; }
}
.print-controls {
    position: sticky;
    top: 0;
    z-index: 1000;
    background: ##f8f9fa;
    border-bottom: 1px solid ##dee2e6;
    padding: 10px 16px;
    display: flex;
    align-items: center;
    gap: 10px;
    flex-wrap: wrap;
}
.print-body {
    padding: 16px;
}
</style>

<!--- Kontrol Çubuğu --->
<div class="print-controls">
    <strong class="me-2"><i class="fas fa-print me-1"></i>#htmlEditFormat(catName)#</strong>

    <div id="selTemplate" style="min-width:260px;"></div>

    <button onclick="applyTemplate()" class="btn btn-sm btn-primary">
        <i class="fas fa-check me-1"></i> Şablonu Uygula
    </button>
    <button onclick="window.print()" class="btn btn-sm btn-success">
        <i class="fas fa-print me-1"></i> Yazdır
    </button>
    <a href="javascript:window.close()" class="btn btn-sm btn-light ms-auto">
        <i class="fas fa-times"></i> Kapat
    </a>
</div>

<div class="print-body">
</cfoutput>

<!---
    =====================================================================
    ŞABLON INCLUDE
    Seçili şablonun CFM dosyası buraya dahil edilir.
    Şablon CFM'e aktarılan context değişkenleri:
        request.docId       — belgenin birincil ID'si (fis_id, order_id vb.)
        request.processType — belge türü (process_type)
        request.tplFormId   — şablon ID'si
    =====================================================================
--->
<cfif getTpl.recordCount AND len(trim(getTpl.template_file))>

    <!--- Güvenlik: path traversal engelli, sadece dosya adı, sadece .cfm --->
    <cfset safeFile = getFileFromPath(getTpl.template_file)>
    <cfset safeFile = reReplace(safeFile, "[^a-zA-Z0-9_\-\.]", "", "all")>
    <cfset tplPath  = "/documents/print_files/" & safeFile>
    <cfset absPath  = expandPath(tplPath)>

    <cfif fileExists(absPath) AND lcase(listLast(safeFile,".")) EQ "cfm">
        <!--- Şablon CFM request scope üzerinden belge ID'sine erişir --->
        <cfset request.docId       = docId>
        <cfset request.processType = processType>
        <cfset request.tplFormId   = selectedTpl>

        <cftry>
            <cfinclude template="#tplPath#">
            <cfcatch type="any">
                <div class="alert alert-danger">
                    <i class="fas fa-exclamation-triangle me-2"></i>
                    Şablon çalıştırılırken hata: <strong><cfoutput>#htmlEditFormat(cfcatch.message)#</cfoutput></strong>
                </div>
            </cfcatch>
        </cftry>
    <cfelse>
        <div class="alert alert-warning">
            <i class="fas fa-file-times me-2"></i>
            Şablon dosyası sunucuda bulunamadı: <code><cfoutput>#htmlEditFormat(safeFile)#</cfoutput></code>
        </div>
    </cfif>

<cfelse>
    <div class="alert alert-info">
        <cfif NOT getTpl.recordCount>
            <i class="fas fa-info-circle me-2"></i>
            Bu şablon bu belge türüne ait değil veya artık aktif değil.
        <cfelse>
            <i class="fas fa-info-circle me-2"></i>
            Seçili şablona henüz bir CFM dosyası yüklenmemiş.
            <a href="index.cfm?fuseaction=setup.add_print_template&form_id=<cfoutput>#selectedTpl#</cfoutput>">Düzenle &rarr;</a>
        </cfif>
    </div>
</cfif>

<cfoutput>
</div><!--- /.print-body --->

<script>
var tplData      = #serializeJSON(tplArr)#;
var processType  = #processType#;
var docId        = #docId#;
var selectedTpl  = #selectedTpl#;

$(function() {
    $("##selTemplate").dxSelectBox({
        dataSource : tplData,
        valueExpr  : "form_id",
        displayExpr: "name",
        value      : selectedTpl,
        stylingMode: "outlined",
        width      : "100%"
    });
});

function applyTemplate() {
    var fid = $("##selTemplate").dxSelectBox("instance").option("value");
    if (!fid) return;
    var url = "index.cfm?fuseaction=setup.print_document"
            + "&process_type=" + processType
            + "&doc_id="       + docId
            + "&form_id="      + fid;
    window.location.href = url;
}
</script>
</cfoutput>
