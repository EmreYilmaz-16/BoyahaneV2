<cfprocessingdirective pageEncoding="utf-8">
<!--- ============================================================
      Dosya Yöneticisi - Rasih Çelik Boyahane
      Gezinme / Upload / Download / Klasör Oluşturma / Silme
      ============================================================ --->

<!--- Session kontrolü --->
<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cflocation url="/login.cfm" addtoken="false">
    <cfabort>
</cfif>

<cfscript>
    // Temel dizin: web kökü (path traversal engeli için canonicalize)
    variables.jFile     = createObject("java","java.io.File");
    variables.baseDir   = variables.jFile.init(expandPath("/")).getCanonicalPath();

    // URL'den gelen göreli yol
    variables.relPath = structKeyExists(url,"path") ? trim(url.path) : "";

    // Güvenlik: tehlikeli dizin geçişlerini temizle
    variables.relPath = replace(variables.relPath, "\", "/", "ALL");
    variables.relPath = reReplace(variables.relPath, "\.\.", "", "ALL");
    variables.relPath = reReplace(variables.relPath, "^/+", "", "ONE");
    variables.relPath = replace(variables.relPath, "//", "/", "ALL");

    // Tam yol ve canonicalize
    variables.fullPath = variables.jFile.init(variables.baseDir & "/" & variables.relPath).getCanonicalPath();

    // Güvenlik: çıkış engeli
    if (lcase(left(variables.fullPath, len(variables.baseDir))) neq lcase(variables.baseDir)) {
        variables.fullPath = variables.baseDir;
        variables.relPath  = "";
    }

    variables.action  = structKeyExists(url,"action")  ? trim(url.action)  : "";
    variables.message = "";
    variables.msgType = "success";
</cfscript>

<!--- ===================== DOWNLOAD ===================== --->
<cfif variables.action eq "download">
    <cfset variables.dlFile = variables.jFile.init(variables.fullPath)>
    <cfif variables.dlFile.exists() and variables.dlFile.isFile()>
        <cfheader name="Content-Disposition" value='attachment; filename="#getFileFromPath(variables.fullPath)#"'>
        <cfcontent type="application/octet-stream" file="#variables.fullPath#" deletefile="false">
    <cfelse>
        <cfset variables.message = "Dosya bulunamadı.">
        <cfset variables.msgType = "danger">
    </cfif>
    <cfabort>
</cfif>

<!--- ===================== DELETE ===================== --->
<cfif variables.action eq "delete">
    <cfset variables.dlFile = variables.jFile.init(variables.fullPath)>
    <cfset variables.parentRel = "">
    <cfif len(variables.relPath) gt 0>
        <cfset variables.parentFull = variables.jFile.init(variables.fullPath).getParent()>
        <cfset variables.parentRel  = replace(variables.parentFull, variables.baseDir, "", "ONE")>
        <cfset variables.parentRel  = reReplace(variables.parentRel, "^[/\\]+", "")>
    </cfif>
    <cftry>
        <cfif variables.dlFile.isFile()>
            <cffile action="delete" file="#variables.fullPath#">
            <cfset variables.message = "Dosya silindi.">
        <cfelseif variables.dlFile.isDirectory()>
            <cfdirectory action="delete" directory="#variables.fullPath#" recurse="true">
            <cfset variables.message = "Klasör silindi.">
        </cfif>
        <cflocation url="file_explorer.cfm?path=#urlEncodedFormat(variables.parentRel)#&msg=deleted" addtoken="false">
        <cfcatch>
            <cfset variables.message = "Silme hatası: #cfcatch.message#">
            <cfset variables.msgType = "danger">
        </cfcatch>
    </cftry>
</cfif>

<!--- ===================== MKDIR ===================== --->
<cfif variables.action eq "mkdir" and structKeyExists(form,"dirname") and len(trim(form.dirname))>
    <cfset variables.newDirName = reReplace(trim(form.dirname), "[^a-zA-Z0-9_\-\. \(\)]", "", "ALL")>
    <cfif len(variables.newDirName)>
        <cfset variables.newDirPath = variables.fullPath & "/" & variables.newDirName>
        <cftry>
            <cfdirectory action="create" directory="#variables.newDirPath#">
            <cflocation url="file_explorer.cfm?path=#urlEncodedFormat(variables.relPath)#&msg=mkdir" addtoken="false">
            <cfcatch>
                <cfset variables.message = "Klasör oluşturma hatası: #cfcatch.message#">
                <cfset variables.msgType = "danger">
            </cfcatch>
        </cftry>
    <cfelse>
        <cfset variables.message = "Geçersiz klasör adı.">
        <cfset variables.msgType = "warning">
    </cfif>
</cfif>

<!--- ===================== UPLOAD ===================== --->
<cfif cgi.request_method eq "POST" and variables.action eq "upload">
    <cfif structKeyExists(form,"filedata") and len(form.filedata)>
        <!--- blockedExtForFileUpload Application.cfc'de tanımlı --->
        <cftry>
            <cffile action="upload"
                    filefield="filedata"
                    destination="#variables.fullPath#"
                    nameconflict="makeunique"
                    result="uploadResult">
            <cfset variables.message = "Dosya yüklendi: #uploadResult.serverFile#">
            <cflocation url="file_explorer.cfm?path=#urlEncodedFormat(variables.relPath)#&msg=uploaded" addtoken="false">
            <cfcatch>
                <cfset variables.message = "Yükleme hatası: #cfcatch.message#">
                <cfset variables.msgType = "danger">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<!--- ===================== Mesaj URL parametresinden al ===================== --->
<cfif structKeyExists(url,"msg") and variables.message eq "">
    <cfswitch expression="#url.msg#">
        <cfcase value="deleted"><cfset variables.message = "Başarıyla silindi."></cfcase>
        <cfcase value="uploaded"><cfset variables.message = "Dosya başarıyla yüklendi."></cfcase>
        <cfcase value="mkdir"><cfset variables.message = "Klasör başarıyla oluşturuldu."></cfcase>
    </cfswitch>
</cfif>

<!--- ===================== Dizin listeleme ===================== --->
<cfset variables.targetDir = variables.jFile.init(variables.fullPath)>
<cfif not variables.targetDir.isDirectory()>
    <cfset variables.fullPath = variables.baseDir>
    <cfset variables.relPath  = "">
    <cfset variables.targetDir = variables.jFile.init(variables.fullPath)>
</cfif>

<cfdirectory action="list" directory="#variables.fullPath#" name="dirList" sort="type asc, name asc">

<!--- Breadcrumb parçala --->
<cfset variables.crumbs = []>
<cfif len(variables.relPath)>
    <cfset variables.parts = listToArray(replace(variables.relPath,"\","/","ALL"), "/")>
    <cfset variables.cumPath = "">
    <cfloop array="#variables.parts#" index="p">
        <cfset variables.cumPath = variables.cumPath & (len(variables.cumPath) ? "/" : "") & p>
        <cfset arrayAppend(variables.crumbs, {name: p, path: variables.cumPath})>
    </cfloop>
</cfif>

<!--- Üst klasör yolu --->
<cfset variables.parentRel = "">
<cfif len(variables.relPath)>
    <cfset variables.pathParts = listToArray(replace(variables.relPath,"\","/","ALL"), "/")>
    <cfif arrayLen(variables.pathParts) gt 1>
        <cfset arrayDeleteAt(variables.pathParts, arrayLen(variables.pathParts))>
        <cfset variables.parentRel = arrayToList(variables.pathParts, "/")>
    </cfif>
</cfif>

<!--- Dosya boyutu formatla --->
<cffunction name="formatSize" returntype="string" output="false">
    <cfargument name="bytes" type="numeric" required="true">
    <cfif arguments.bytes lt 1024>
        <cfreturn arguments.bytes & " B">
    <cfelseif arguments.bytes lt 1048576>
        <cfreturn numberFormat(arguments.bytes/1024,"__.0") & " KB">
    <cfelseif arguments.bytes lt 1073741824>
        <cfreturn numberFormat(arguments.bytes/1048576,"__.0") & " MB">
    <cfelse>
        <cfreturn numberFormat(arguments.bytes/1073741824,"__.0") & " GB">
    </cfif>
</cffunction>

<!--- Dosya ikonu --->
<cffunction name="fileIcon" returntype="string" output="false">
    <cfargument name="ext" type="string" required="true">
    <cfset local.e = lcase(arguments.ext)>
    <cfif listFind("jpg,jpeg,png,gif,svg,webp,bmp,ico",local.e)>
        <cfreturn "fa-file-image text-success">
    <cfelseif listFind("pdf",local.e)>
        <cfreturn "fa-file-pdf text-danger">
    <cfelseif listFind("doc,docx",local.e)>
        <cfreturn "fa-file-word text-primary">
    <cfelseif listFind("xls,xlsx,csv",local.e)>
        <cfreturn "fa-file-excel text-success">
    <cfelseif listFind("ppt,pptx",local.e)>
        <cfreturn "fa-file-powerpoint text-warning">
    <cfelseif listFind("zip,rar,7z,tar,gz",local.e)>
        <cfreturn "fa-file-zipper text-secondary">
    <cfelseif listFind("mp3,wav,ogg,flac",local.e)>
        <cfreturn "fa-file-audio text-info">
    <cfelseif listFind("mp4,avi,mkv,mov,webm",local.e)>
        <cfreturn "fa-file-video text-danger">
    <cfelseif listFind("js,ts",local.e)>
        <cfreturn "fa-file-code text-warning">
    <cfelseif listFind("cfm,cfc,cfml",local.e)>
        <cfreturn "fa-file-code text-info">
    <cfelseif listFind("html,htm",local.e)>
        <cfreturn "fa-file-code text-orange">
    <cfelseif listFind("css,scss,sass,less",local.e)>
        <cfreturn "fa-file-code text-primary">
    <cfelseif listFind("sql",local.e)>
        <cfreturn "fa-database text-secondary">
    <cfelseif listFind("txt,md,log",local.e)>
        <cfreturn "fa-file-lines text-secondary">
    <cfelse>
        <cfreturn "fa-file text-muted">
    </cfif>
</cffunction>

<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dosya Yöneticisi - Rasih Çelik Boyahane</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        :root {
            --primary: #4361ee;
            --primary-light: #eef0fd;
            --hover-bg: #f0f4ff;
        }
        body { background: #f5f6fa; font-family: 'Segoe UI', sans-serif; }
        .fm-header {
            background: linear-gradient(135deg, #4361ee 0%, #3a0ca3 100%);
            color: white;
            padding: 1rem 1.5rem;
            border-radius: 0 0 16px 16px;
            box-shadow: 0 4px 15px rgba(67,97,238,.3);
        }
        .fm-card {
            border: none;
            border-radius: 12px;
            box-shadow: 0 2px 12px rgba(0,0,0,.08);
        }
        .breadcrumb-item a { color: var(--primary); text-decoration: none; }
        .breadcrumb-item a:hover { text-decoration: underline; }
        .file-row { transition: background .15s; cursor: default; }
        .file-row:hover { background: var(--hover-bg); }
        .file-row td { vertical-align: middle; padding: .55rem .75rem; }
        .file-name-link {
            color: inherit;
            text-decoration: none;
            font-weight: 500;
        }
        .file-name-link:hover { color: var(--primary); }
        .folder-icon { color: #f6c90e; font-size: 1.25rem; }
        .file-icon { font-size: 1.15rem; }
        .btn-sm { font-size: .78rem; }
        .drop-zone {
            border: 2px dashed #b0bcf0;
            border-radius: 10px;
            padding: 1.5rem;
            text-align: center;
            background: var(--primary-light);
            transition: border-color .2s, background .2s;
            cursor: pointer;
        }
        .drop-zone.dragover {
            border-color: var(--primary);
            background: #dde3fc;
        }
        .drop-zone input[type="file"] { display: none; }
        .size-col, .date-col { font-size: .82rem; color: #6c757d; }
        thead th { font-size: .8rem; font-weight: 600; color: #6c757d; border-bottom: 2px solid #e9ecef; }
        .search-box { max-width: 260px; }
        #fileTable tr.d-none-search { display: none !important; }
    </style>
</head>
<body>

<!--- HEADER --->
<div class="fm-header d-flex align-items-center justify-content-between">
    <div class="d-flex align-items-center gap-3">
        <i class="fa fa-folder-open fa-lg"></i>
        <div>
            <h5 class="mb-0 fw-bold">Dosya Yöneticisi</h5>
            <small class="opacity-75">Rasih Çelik Boyahane</small>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=myhome.welcome" class="btn btn-light btn-sm">
        <i class="fa fa-arrow-left me-1"></i> Ana Sayfa
    </a>
</div>

<div class="container-fluid p-3">

    <!--- Mesaj --->
    <cfif len(variables.message)>
        <div class="alert alert-#variables.msgType# alert-dismissible d-flex align-items-center gap-2 py-2" role="alert">
            <i class="fa fa-#(variables.msgType eq 'success' ? 'check-circle' : (variables.msgType eq 'danger' ? 'times-circle' : 'exclamation-triangle'))#"></i>
            <span>#variables.message#</span>
            <button type="button" class="btn-close ms-auto py-0" data-bs-dismiss="alert"></button>
        </div>
    </cfif>

    <div class="row g-3">
        <!--- SOL: Dosya listesi --->
        <div class="col-lg-8">
            <div class="card fm-card">
                <div class="card-body p-0">
                    <!--- Toolbar --->
                    <div class="d-flex align-items-center gap-2 p-3 border-bottom flex-wrap">
                        <!--- Breadcrumb --->
                        <nav aria-label="breadcrumb" class="flex-grow-1">
                            <ol class="breadcrumb mb-0">
                                <li class="breadcrumb-item">
                                    <a href="file_explorer.cfm"><i class="fa fa-house me-1"></i>Kök</a>
                                </li>
                                <cfset variables.crumbLast = arrayLen(variables.crumbs)>
                                <cfoutput>
                                <cfloop from="1" to="#variables.crumbLast#" index="ci">
                                    <cfset crumb = variables.crumbs[ci]>
                                    <cfif ci eq variables.crumbLast>
                                        <li class="breadcrumb-item active">#crumb.name#</li>
                                    <cfelse>
                                        <li class="breadcrumb-item">
                                            <a href="file_explorer.cfm?path=#urlEncodedFormat(crumb.path)#">#crumb.name#</a>
                                        </li>
                                    </cfif>
                                </cfloop>
                                </cfoutput>
                            </ol>
                        </nav>
                        <!--- Üst klasör --->
                        <cfif len(variables.relPath)>
                            <a href="file_explorer.cfm?path=#urlEncodedFormat(variables.parentRel)#" class="btn btn-outline-secondary btn-sm" title="Üst klasör">
                                <i class="fa fa-level-up-alt"></i>
                            </a>
                        </cfif>
                        <!--- Arama --->
                        <input type="search" id="fileSearch" class="form-control form-control-sm search-box"
                               placeholder="Ara..." oninput="filterFiles(this.value)">
                    </div>

                    <!--- İçerik tablosu --->
                    <div class="table-responsive">
                        <table class="table table-hover mb-0" id="fileTable">
                            <thead>
                                <tr>
                                    <th style="width:40px"></th>
                                    <th>Ad</th>
                                    <th class="size-col">Boyut</th>
                                    <th class="date-col d-none d-md-table-cell">Tarih</th>
                                    <th style="width:100px" class="text-end">İşlem</th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfif dirList.recordCount eq 0>
                                    <tr>
                                        <td colspan="5" class="text-center text-muted py-4">
                                            <i class="fa fa-folder-open me-2"></i>Bu klasör boş.
                                        </td>
                                    </tr>
                                </cfif>
                                <cfoutput>
                                <cfloop query="dirList">
                                    <cfset itemRel = (len(variables.relPath) ? variables.relPath & "/" : "") & dirList.name>
                                    <tr class="file-row" data-name="#lcase(dirList.name)#">
                                        <td class="text-center">
                                            <cfif dirList.type eq "Dir">
                                                <i class="fa fa-folder folder-icon"></i>
                                            <cfelse>
                                                <cfset fext = listLast(dirList.name,".")>
                                                <i class="fa #fileIcon(fext)# file-icon"></i>
                                            </cfif>
                                        </td>
                                        <td>
                                            <cfif dirList.type eq "Dir">
                                                <a href="file_explorer.cfm?path=#urlEncodedFormat(itemRel)#" class="file-name-link">
                                                    #dirList.name#
                                                </a>
                                            <cfelse>
                                                <span class="file-name-link">#dirList.name#</span>
                                            </cfif>
                                        </td>
                                        <td class="size-col">
                                            <cfif dirList.type eq "Dir">
                                                <span class="badge bg-light text-secondary">Klasör</span>
                                            <cfelse>
                                                #formatSize(dirList.size)#
                                            </cfif>
                                        </td>
                                        <td class="date-col d-none d-md-table-cell">
                                            #dateFormat(dirList.dateLastModified,"DD.MM.YYYY")#
                                            #timeFormat(dirList.dateLastModified,"HH:mm")#
                                        </td>
                                        <td class="text-end">
                                            <div class="d-flex gap-1 justify-content-end">
                                                <cfif dirList.type eq "File">
                                                    <a href="file_explorer.cfm?path=#urlEncodedFormat(itemRel)#&action=download"
                                                       class="btn btn-outline-primary btn-sm" title="İndir">
                                                        <i class="fa fa-download"></i>
                                                    </a>
                                                </cfif>
                                                <button type="button"
                                                        class="btn btn-outline-danger btn-sm"
                                                        title="Sil"
                                                        onclick="confirmDelete('#urlEncodedFormat(itemRel)#','#jsStringFormat(dirList.name)#','#dirList.type#')">
                                                    <i class="fa fa-trash"></i>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </cfloop>
                                </cfoutput>
                            </tbody>
                        </table>
                    </div>
<cfoutput>
                    <!--- Footer: özet --->
                    <div class="px-3 py-2 border-top text-muted" style="font-size:.8rem">
                        <cfquery name="qDirs" dbtype="query">
                            SELECT name FROM dirList WHERE type='Dir'
                        </cfquery>
                        <cfquery name="qFiles" dbtype="query">
                            SELECT name FROM dirList WHERE type='File'
                        </cfquery>
                        <i class="fa fa-folder me-1"></i>#qDirs.recordCount# klasör &nbsp;
                        <i class="fa fa-file me-1"></i>#qFiles.recordCount# dosya
                    </div>
                </div>
            </div>
        </div>
</cfoutput>
        <!--- SAĞ: Araçlar --->
        <div class="col-lg-4 d-flex flex-column gap-3">
<cfoutput>
            <!--- Upload --->
            <div class="card fm-card">
                <div class="card-header bg-white border-bottom-0 pt-3 pb-0">
                    <h6 class="mb-0"><i class="fa fa-upload me-2 text-primary"></i>Dosya Yükle</h6>
                </div>
                <div class="card-body pt-2">
                    <form method="post" action="file_explorer.cfm?path=#urlEncodedFormat(variables.relPath)#&action=upload"
                          enctype="multipart/form-data" id="uploadForm">
                        <div class="drop-zone" id="dropZone"
                             ondragover="event.preventDefault(); this.classList.add('dragover')"
                             ondragleave="this.classList.remove('dragover')"
                             ondrop="handleDrop(event)"
                             onclick="document.getElementById('filedata').click()">
                            <input type="file" name="filedata" id="filedata" multiple
                                   onchange="handleFileSelect(this)">
                            <i class="fa fa-cloud-upload-alt fa-2x text-primary mb-2 d-block"></i>
                            <p class="mb-1 fw-semibold">Dosya sürükle bırak</p>
                            <small class="text-muted">veya seçmek için tıkla</small>
                        </div>
                        <div id="selectedFiles" class="mt-2 d-none">
                            <div class="d-flex align-items-center justify-content-between">
                                <small class="text-muted" id="fileCount"></small>
                                <button type="submit" class="btn btn-primary btn-sm">
                                    <i class="fa fa-upload me-1"></i>Yükle
                                </button>
                            </div>
                            <ul id="fileList" class="list-unstyled mt-1 mb-0" style="font-size:.82rem;max-height:120px;overflow-y:auto"></ul>
                        </div>
                    </form>
                </div>
            </div>

            <!--- Klasör oluştur --->
            <div class="card fm-card">
                <div class="card-header bg-white border-bottom-0 pt-3 pb-0">
                    <h6 class="mb-0"><i class="fa fa-folder-plus me-2 text-warning"></i>Yeni Klasör</h6>
                </div>
                <div class="card-body pt-2">
                    <form method="post" action="file_explorer.cfm?path=#urlEncodedFormat(variables.relPath)#&action=mkdir">
                        <div class="input-group">
                            <input type="text" name="dirname" class="form-control"
                                   placeholder="Klasör adı" maxlength="100"
                                   pattern="[a-zA-Z0-9_\-\. \(\)]+"
                                   required>
                            <button class="btn btn-warning" type="submit">
                                <i class="fa fa-plus"></i>
                            </button>
                        </div>
                    </form>
                </div>
            </div>

            <!--- Mevcut konum bilgisi --->
            <div class="card fm-card">
                <div class="card-header bg-white border-bottom-0 pt-3 pb-0">
                    <h6 class="mb-0"><i class="fa fa-circle-info me-2 text-info"></i>Konum</h6>
                </div>
                <div class="card-body pt-2">
                    <small class="text-muted d-block mb-1">Göreli Yol:</small>
                    <code style="font-size:.8rem;word-break:break-all">/#len(variables.relPath) ? variables.relPath : ""#</code>
                </div>
            </div>

        </div>
    </div>
</div>
</cfoutput>
<!--- SİLME ONAY MODAL --->
<div class="modal fade" id="deleteModal" tabindex="-1">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header border-0">
                <h5 class="modal-title text-danger"><i class="fa fa-triangle-exclamation me-2"></i>Silme Onayı</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <p class="mb-2"><span id="deleteTypeTxt"></span> silinecek:</p>
                <div class="alert alert-danger py-2 mb-0">
                    <i class="fa fa-folder me-1" id="deleteIcon"></i>
                    <strong id="deleteNameTxt"></strong>
                </div>
                <p class="mt-3 mb-0 text-muted small">Bu işlem geri alınamaz!</p>
            </div>
            <div class="modal-footer border-0">
                <button class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <a id="deleteConfirmBtn" href="#" class="btn btn-danger">
                    <i class="fa fa-trash me-1"></i>Evet, Sil
                </a>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
// Silme onayı
function confirmDelete(encodedPath, name, type) {
    var modal = new bootstrap.Modal(document.getElementById('deleteModal'));
    document.getElementById('deleteNameTxt').textContent = name;
    document.getElementById('deleteTypeTxt').textContent = type === 'Dir' ? 'Klasör' : 'Dosya';
    document.getElementById('deleteIcon').className = type === 'Dir' ? 'fa fa-folder me-1' : 'fa fa-file me-1';
    document.getElementById('deleteConfirmBtn').href =
        'file_explorer.cfm?path=' + encodedPath + '&action=delete';
    modal.show();
}

// Dosya ara
function filterFiles(q) {
    q = q.toLowerCase().trim();
    document.querySelectorAll('#fileTable tbody tr[data-name]').forEach(function(row) {
        if (!q || row.dataset.name.includes(q)) {
            row.classList.remove('d-none-search');
        } else {
            row.classList.add('d-none-search');
        }
    });
}

// Upload - dosya seçimi göster
function handleFileSelect(input) {
    showSelectedFiles(input.files);
}

function handleDrop(e) {
    e.preventDefault();
    document.getElementById('dropZone').classList.remove('dragover');
    var files = e.dataTransfer.files;
    document.getElementById('filedata').files = files;
    showSelectedFiles(files);
}

function showSelectedFiles(files) {
    if (!files || files.length === 0) return;
    var panel = document.getElementById('selectedFiles');
    var list  = document.getElementById('fileList');
    var count = document.getElementById('fileCount');
    panel.classList.remove('d-none');
    count.textContent = files.length + ' dosya seçildi';
    list.innerHTML = '';
    for (var i = 0; i < files.length; i++) {
        var li = document.createElement('li');
        li.innerHTML = '<i class="fa fa-file me-1 text-muted"></i>' +
                       escHtml(files[i].name) +
                       ' <span class="text-muted">(' + formatBytes(files[i].size) + ')</span>';
        list.appendChild(li);
    }
}

function formatBytes(b) {
    if (b < 1024) return b + ' B';
    if (b < 1048576) return (b/1024).toFixed(1) + ' KB';
    return (b/1048576).toFixed(1) + ' MB';
}

function escHtml(s) {
    return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}
</script>
</body>
</html>
