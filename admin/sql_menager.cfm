<cfprocessingdirective pageEncoding="utf-8">
<!--- ============================================================
      SQL Yöneticisi / Editor - Rasih Çelik Boyahane
      ============================================================ --->

<!--- Session kontrolü --->
<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cflocation url="/login.cfm" addtoken="false">
    <cfabort>
</cfif>

<cfscript>
    variables.dsn          = "boyahane";
    variables.sqlInput     = structKeyExists(form, "sqlInput") ? trim(form.sqlInput) : "";
    variables.hasResult    = false;
    variables.isError      = false;
    variables.errorMsg     = "";
    variables.execTime     = 0;
    variables.affectedRows = 0;
    variables.resultData   = queryNew(""); 
    variables.historyKey   = "sql_history_boyahane";

    // Sorgu geçmişi (session bazlı, max 30)
    if (!structKeyExists(session, variables.historyKey)) {
        session[variables.historyKey] = [];
    }
</cfscript>

<!--- ===================== AJAX: Şema bilgisi ===================== --->
<cfif structKeyExists(url, "action") and url.action eq "getSchema">
    <cfheader name="Content-Type" value="application/json; charset=utf-8">
    <cftry>
        <cfquery name="qTables" datasource="#variables.dsn#">
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_type = 'BASE TABLE'
            ORDER BY table_name
        </cfquery>
        <cfset schemaArr = []>
        <cfloop query="qTables">
            <cfquery name="qCols" datasource="#variables.dsn#">
                SELECT column_name, data_type, character_maximum_length, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_schema = 'public' AND table_name = <cfqueryparam value="#qTables.table_name#" cfsqltype="cf_sql_varchar">
                ORDER BY ordinal_position
            </cfquery>
            <cfset cols = []>
            <cfloop query="qCols">
                <cfset arrayAppend(cols, {
                    name: qCols.column_name,
                    type: qCols.data_type,
                    maxLen: isNull(qCols.character_maximum_length) ? "" : qCols.character_maximum_length,
                    nullable: qCols.is_nullable
                })>
            </cfloop>
            <cfset arrayAppend(schemaArr, {table: qTables.table_name, columns: cols})>
        </cfloop>
        <cfoutput>#serializeJSON(schemaArr)#</cfoutput>
    <cfcatch>
        <cfoutput>[]</cfoutput>
    </cfcatch>
    </cftry>
    <cfabort>
</cfif>

<!--- ===================== AJAX: Geçmişi temizle ===================== --->
<cfif structKeyExists(url, "action") and url.action eq "clearHistory">
    <cfset session[variables.historyKey] = []>
    <cfheader name="Content-Type" value="application/json; charset=utf-8">
    <cfoutput>{"ok":true}</cfoutput>
    <cfabort>
</cfif>

<!--- ===================== Sorgu çalıştır ===================== --->
<cfif cgi.request_method eq "POST" and len(variables.sqlInput)>

    <!--- Tehlikeli komutları engelle: DROP DATABASE/SCHEMA, TRUNCATE (isteğe bağlı) --->
    <cfset variables.dangerPattern = "(?i)\b(drop\s+database|drop\s+schema)\b">
    <cfif reFind(variables.dangerPattern, variables.sqlInput)>
        <cfset variables.isError  = true>
        <cfset variables.errorMsg = "GÜVENLİK: DROP DATABASE / DROP SCHEMA komutları bu arayüzden çalıştırılamaz.">
    <cfelse>
        <cfset variables.t0 = getTickCount()>
        <cftry>
            <!--- SELECT mi diğeri mi? --->
            <cfset variables.firstWord = lcase(trim(listFirst(reReplace(trim(variables.sqlInput), "\s+", " ", "ALL"), " ")))>
            <cfif variables.firstWord eq "select" or variables.firstWord eq "with" or variables.firstWord eq "show" or variables.firstWord eq "explain">
                <cfquery name="variables.resultData" datasource="#variables.dsn#">
                    #preserveSingleQuotes(variables.sqlInput)#
                </cfquery>
                <cfset variables.hasResult = true>
                <cfset variables.affectedRows = variables.resultData.recordCount>
            <cfelse>
                <cfquery datasource="#variables.dsn#" result="qResult">
                    #preserveSingleQuotes(variables.sqlInput)#
                </cfquery>
                <cfset variables.hasResult    = false>
                <cfset variables.affectedRows = structKeyExists(qResult,"recordCount") ? qResult.recordCount : (structKeyExists(qResult,"rowsAffected") ? qResult.rowsAffected : 0)>
            </cfif>
            <cfset variables.execTime = getTickCount() - variables.t0>

            <!--- Geçmişe ekle --->
            <cfset newEntry = {
                sql: variables.sqlInput,
                ts: now(),
                ms: variables.execTime,
                ok: true
            }>
            <cfset arrayPrepend(session[variables.historyKey], newEntry)>
            <cfif arrayLen(session[variables.historyKey]) gt 30>
                <cfset arrayDeleteAt(session[variables.historyKey], 31)>
            </cfif>

        <cfcatch>
            <cfset variables.isError  = true>
            <cfset variables.errorMsg = cfcatch.message & (len(cfcatch.detail) ? " — " & cfcatch.detail : "")>
            <cfset variables.execTime = getTickCount() - variables.t0>

            <cfset errEntry = {
                sql: variables.sqlInput,
                ts: now(),
                ms: variables.execTime,
                ok: false
            }>
            <cfset arrayPrepend(session[variables.historyKey], errEntry)>
            <cfif arrayLen(session[variables.historyKey]) gt 30>
                <cfset arrayDeleteAt(session[variables.historyKey], 31)>
            </cfif>
        </cfcatch>
        </cftry>
    </cfif>
</cfif>

<!DOCTYPE html>
<html lang="tr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SQL Yöneticisi - Rasih Çelik Boyahane</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <!--- CodeMirror SQL Editor --->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/theme/dracula.min.css">
    <style>
        :root { --primary:#4361ee; }
        body { background:#f5f6fa; font-family:'Segoe UI',sans-serif; height:100vh; display:flex; flex-direction:column; margin:0; overflow:hidden; }
        .top-bar {
            background: linear-gradient(135deg,#4361ee 0%,#3a0ca3 100%);
            color:#fff; padding:.6rem 1.2rem;
            display:flex; align-items:center; gap:1rem;
            box-shadow:0 3px 12px rgba(67,97,238,.35);
            flex-shrink:0;
        }
        .main-area { display:flex; flex:1; overflow:hidden; }
        /* Sidebar */
        #sidebar {
            width:240px; min-width:180px; background:#fff;
            border-right:1px solid #e9ecef;
            display:flex; flex-direction:column; overflow:hidden;
            flex-shrink:0; transition:width .2s;
        }
        #sidebar.collapsed { width:0; }
        .sidebar-header { padding:.6rem .8rem; font-weight:600; font-size:.8rem; color:#6c757d; background:#f8f9fa; border-bottom:1px solid #e9ecef; }
        #schemaTree { overflow-y:auto; flex:1; font-size:.78rem; }
        .tree-table { cursor:pointer; padding:.35rem .6rem; display:flex; align-items:center; gap:.4rem; color:#333; }
        .tree-table:hover { background:#eef0fd; color:var(--primary); }
        .tree-table i { color:#f6c90e; }
        .tree-cols { display:none; padding-left:1.4rem; }
        .tree-cols.open { display:block; }
        .tree-col { padding:.2rem .5rem; font-size:.73rem; color:#6c757d; display:flex; justify-content:space-between; }
        .tree-col:hover { background:#f0f4ff; cursor:pointer; }
        .col-type { font-size:.68rem; color:#adb5bd; }
        /* Editor area */
        .editor-area { flex:1; display:flex; flex-direction:column; overflow:hidden; }
        .editor-toolbar { background:#fff; border-bottom:1px solid #e9ecef; padding:.4rem .8rem; display:flex; gap:.5rem; align-items:center; flex-shrink:0; }
        .CodeMirror { height:220px !important; font-size:13px; border-bottom:1px solid #dee2e6; }
        /* Results */
        #resultPanel { flex:1; overflow:auto; padding:0; }
        .result-toolbar { background:#f8f9fa; border-bottom:1px solid #e9ecef; padding:.4rem .8rem; font-size:.8rem; display:flex; gap:1rem; align-items:center; flex-shrink:0; }
        .result-table-wrap { overflow:auto; max-height:calc(100vh - 420px); }
        .result-table { font-size:.8rem; border-collapse:collapse; width:100%; white-space:nowrap; }
        .result-table th { background:#4361ee; color:#fff; position:sticky; top:0; padding:.4rem .7rem; font-weight:600; }
        .result-table td { padding:.3rem .7rem; border-bottom:1px solid #f0f0f0; max-width:300px; overflow:hidden; text-overflow:ellipsis; }
        .result-table tr:hover td { background:#eef0fd; }
        .null-cell { color:#adb5bd; font-style:italic; }
        /* History */
        #historyPanel { max-height:160px; overflow-y:auto; background:#fff; border-top:1px solid #e9ecef; }
        .history-item { padding:.3rem .8rem; font-size:.75rem; display:flex; align-items:center; gap:.5rem; border-bottom:1px solid #f5f5f5; cursor:pointer; }
        .history-item:hover { background:#eef0fd; }
        .history-sql { flex:1; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; font-family:monospace; }
        .badge-ok { background:#d1fae5; color:#065f46; }
        .badge-err { background:#fee2e2; color:#991b1b; }
        /* Resize handle */
        #resizer { width:5px; background:#e9ecef; cursor:col-resize; flex-shrink:0; }
        #resizer:hover { background:#4361ee; }
        .export-btn { margin-left:auto; }
    </style>
</head>
<body>

<!--- TOP BAR --->
<div class="top-bar">
    <button class="btn btn-sm btn-light" id="sidebarToggle" title="Şema Paneli">
        <i class="fa fa-database"></i>
    </button>
    <i class="fa fa-terminal"></i>
    <strong>SQL Yöneticisi</strong>
    <span class="badge bg-light text-dark ms-1" style="font-size:.75rem">boyahane</span>
    <a href="/index.cfm?fuseaction=myhome.welcome" class="btn btn-sm btn-light ms-auto">
        <i class="fa fa-arrow-left me-1"></i>Ana Sayfa
    </a>
</div>

<div class="main-area">

    <!--- SIDEBAR: Şema --->
    <div id="sidebar">
        <div class="sidebar-header d-flex align-items-center justify-content-between">
            <span><i class="fa fa-table me-1"></i>Tablolar</span>
            <button class="btn btn-sm p-0 text-muted" id="refreshSchema" title="Yenile"><i class="fa fa-rotate-right"></i></button>
        </div>
        <div id="schemaTree"><div class="p-2 text-muted" style="font-size:.75rem">Yükleniyor...</div></div>
    </div>
    <div id="resizer"></div>

    <!--- ANA ALAN --->
    <div class="editor-area">

        <!--- TOOLBAR --->
        <div class="editor-toolbar">
            <button class="btn btn-success btn-sm" id="runBtn" title="Çalıştır (Ctrl+Enter)">
                <i class="fa fa-play me-1"></i>Çalıştır
            </button>
            <button class="btn btn-outline-secondary btn-sm" id="clearBtn" title="Temizle">
                <i class="fa fa-eraser me-1"></i>Temizle
            </button>
            <button class="btn btn-outline-secondary btn-sm" id="formatBtn" title="Formatla">
                <i class="fa fa-align-left me-1"></i>Formatla
            </button>
            <div class="vr mx-1"></div>
            <select class="form-select form-select-sm" id="snippetSelect" style="width:160px">
                <option value="">Snippet ekle...</option>
                <option value="SELECT * FROM ">SELECT *</option>
                <option value="SELECT COUNT(*) FROM ">SELECT COUNT(*)</option>
                <option value="INSERT INTO  () VALUES ()">INSERT INTO</option>
                <option value="UPDATE  SET  WHERE ">UPDATE</option>
                <option value="DELETE FROM  WHERE ">DELETE FROM</option>
                <option value="SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name">Tablo Listesi</option>
                <option value="SELECT column_name, data_type FROM information_schema.columns WHERE table_name=''">Kolon Listesi</option>
            </select>
            <div class="ms-auto d-flex gap-1">
                <button class="btn btn-outline-primary btn-sm export-btn" id="exportCsvBtn" style="display:none">
                    <i class="fa fa-file-csv me-1"></i>CSV
                </button>
                <button class="btn btn-danger btn-sm" id="clearHistBtn" title="Geçmişi Temizle">
                    <i class="fa fa-clock-rotate-left me-1"></i>Geçmişi Sil
                </button>
            </div>
        </div>

        <!--- EDITOR --->
        <form method="post" action="sql_menager.cfm" id="sqlForm">
            <textarea name="sqlInput" id="sqlInput"><cfoutput>#htmlEditFormat(variables.sqlInput)#</cfoutput></textarea>
        </form>

        <!--- RESULT PANEL --->
        <div id="resultPanel">

            <!--- Hata --->
            <cfif variables.isError>
                <div class="alert alert-danger m-2 py-2 d-flex align-items-start gap-2">
                    <i class="fa fa-circle-xmark mt-1"></i>
                    <div style="font-size:.85rem;font-family:monospace;word-break:break-all"><cfoutput>#htmlEditFormat(variables.errorMsg)#</cfoutput></div>
                </div>
            </cfif>

            <!--- SELECT sonuçları --->
            <cfif variables.hasResult and not variables.isError>
                <div class="result-toolbar">
                    <i class="fa fa-table text-primary"></i>
                    <strong><cfoutput>#variables.affectedRows#</cfoutput></strong> satır &nbsp;|&nbsp;
                    <cfif variables.resultData.recordCount gt 0>
                        <cfoutput>#listLen(variables.resultData.columnList)#</cfoutput> kolon
                    </cfif>
                    &nbsp;|&nbsp; <i class="fa fa-clock text-muted me-1"></i><cfoutput>#variables.execTime#</cfoutput> ms
                </div>
                <div class="result-table-wrap">
                    <table class="result-table" id="resultTbl">
                        <thead>
                            <tr>
                                <cfloop list="#variables.resultData.columnList#" index="col">
                                    <th><cfoutput>#col#</cfoutput></th>
                                </cfloop>
                            </tr>
                        </thead>
                        <tbody>
                            <cfoutput query="variables.resultData">
                                <tr>
                                    <cfloop list="#variables.resultData.columnList#" index="col">
                                        <cfset cellVal = variables.resultData[col][currentRow]>
                                        <td <cfif isNull(cellVal)>class="null-cell"</cfif> title="#htmlEditFormat(isNull(cellVal) ? 'NULL' : cellVal)#">
                                            <cfif isNull(cellVal)>NULL<cfelse>#htmlEditFormat(cellVal)#</cfif>
                                        </td>
                                    </cfloop>
                                </tr>
                            </cfoutput>
                        </tbody>
                    </table>
                </div>
            </cfif>

            <!--- DML sonucu --->
            <cfif not variables.hasResult and not variables.isError and len(variables.sqlInput)>
                <div class="alert alert-success m-2 py-2 d-flex align-items-center gap-2">
                    <i class="fa fa-check-circle"></i>
                    Sorgu başarıyla çalıştırıldı.
                    <cfif variables.affectedRows gt 0>
                        <strong><cfoutput>#variables.affectedRows#</cfoutput> satır</strong> etkilendi.
                    </cfif>
                    &nbsp;<span class="text-muted" style="font-size:.8rem"><cfoutput>#variables.execTime#</cfoutput> ms</span>
                </div>
            </cfif>

            <!--- Başlangıç ekranı --->
            <cfif not len(variables.sqlInput) and not variables.isError>
                <div class="text-center text-muted pt-4" style="font-size:.9rem">
                    <i class="fa fa-terminal fa-3x mb-3 d-block" style="color:#dee2e6"></i>
                    SQL yazın ve <kbd>Ctrl+Enter</kbd> ile çalıştırın
                </div>
            </cfif>
        </div>

        <!--- GEÇMİŞ --->
        <div id="historyPanel">
            <div class="p-1 px-2 text-muted" style="font-size:.72rem;background:#f8f9fa;border-bottom:1px solid #eee">
                <i class="fa fa-clock me-1"></i>Sorgu Geçmişi
            </div>
            <cfif arrayLen(session[variables.historyKey]) eq 0>
                <div class="p-2 text-muted" style="font-size:.75rem">Henüz sorgu yok.</div>
            </cfif>
            <cfloop from="1" to="#arrayLen(session[variables.historyKey])#" index="hi">
                <cfset hItem = session[variables.historyKey][hi]>
                <div class="history-item" onclick="loadHistory(this)" data-sql="#htmlEditFormat(hItem.sql)#">
                    <span class="badge #hItem.ok ? 'badge-ok' : 'badge-err'#">#hItem.ok ? 'OK' : 'ERR'#</span>
                    <span class="history-sql">#htmlEditFormat(hItem.sql)#</span>
                    <span class="text-muted" style="font-size:.7rem">#timeFormat(hItem.ts,'HH:mm:ss')#</span>
                    <span class="text-muted" style="font-size:.7rem">#hItem.ms#ms</span>
                </div>
            </cfloop>
        </div>

    </div><!--- /.editor-area --->
</div><!--- /.main-area --->

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/codemirror.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/mode/sql/sql.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/addon/hint/show-hint.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/addon/hint/sql-hint.min.js"></script>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.16/addon/hint/show-hint.min.css">
<script>
// ── CodeMirror ──────────────────────────────────────────
var editor = CodeMirror.fromTextArea(document.getElementById('sqlInput'), {
    mode: 'text/x-pgsql',
    theme: 'dracula',
    lineNumbers: true,
    tabSize: 2,
    indentWithTabs: false,
    extraKeys: {
        'Ctrl-Enter': runQuery,
        'Ctrl-Space': 'autocomplete'
    },
    hintOptions: { completeSingle: false }
});

// Ctrl+Enter
function runQuery() {
    document.getElementById('sqlForm').submit();
}

// Temizle
document.getElementById('clearBtn').onclick = function() { editor.setValue(''); editor.focus(); };

// Snippet
document.getElementById('snippetSelect').onchange = function() {
    if (this.value) { editor.replaceSelection(this.value); this.value=''; editor.focus(); }
};

// Formatla (basit SQL formatter)
document.getElementById('formatBtn').onclick = function() {
    var sql = editor.getValue();
    var kw = ['SELECT','FROM','WHERE','AND','OR','NOT','INSERT','INTO','VALUES','UPDATE','SET',
              'DELETE','CREATE','TABLE','DROP','ALTER','JOIN','LEFT','RIGHT','INNER','OUTER',
              'ON','GROUP BY','ORDER BY','HAVING','LIMIT','OFFSET','UNION','ALL','DISTINCT',
              'AS','WITH','RETURNING'];
    kw.forEach(function(k) {
        sql = sql.replace(new RegExp('\\b' + k + '\\b','gi'), '\n' + k);
    });
    sql = sql.replace(/\n+/g, '\n').trim();
    editor.setValue(sql);
};

// Sorgu çalıştır
document.getElementById('runBtn').onclick = function() { runQuery(); };

// Geçmişten yükle
function loadHistory(el) {
    editor.setValue(el.getAttribute('data-sql'));
    editor.focus();
}

// Geçmişi temizle
document.getElementById('clearHistBtn').onclick = function() {
    fetch('sql_menager.cfm?action=clearHistory').then(function() { location.reload(); });
};

// CSV export
document.getElementById('exportCsvBtn') && document.getElementById('exportCsvBtn').addEventListener('click', function() {
    var tbl = document.getElementById('resultTbl');
    if (!tbl) return;
    var rows = tbl.querySelectorAll('tr');
    var csv = Array.from(rows).map(function(row) {
        return Array.from(row.querySelectorAll('th,td')).map(function(cell) {
            return '"' + cell.innerText.replace(/"/g,'""') + '"';
        }).join(',');
    }).join('\n');
    var blob = new Blob(['\ufeff' + csv], {type:'text/csv;charset=utf-8'});
    var a = document.createElement('a'); a.href = URL.createObjectURL(blob);
    a.download = 'sorgu_sonucu.csv'; a.click();
});
// CSV butonu görünürlüğü
<cfif variables.hasResult and not variables.isError>
document.getElementById('exportCsvBtn').style.display = '';
</cfif>

// ── Sidebar sidebar ──────────────────────────────────────
document.getElementById('sidebarToggle').onclick = function() {
    document.getElementById('sidebar').classList.toggle('collapsed');
};

// Şema yükle
function loadSchema() {
    fetch('sql_menager.cfm?action=getSchema')
        .then(function(r){ return r.json(); })
        .then(function(data) {
            var tree = document.getElementById('schemaTree');
            if (!data.length) { tree.innerHTML = '<div class="p-2 text-muted">Tablo yok.</div>'; return; }
            tree.innerHTML = data.map(function(t) {
                var cols = (t.COLUMNS || t.columns || []).map(function(c) {
                    return '<div class="tree-col" onclick="insertCol(\'' + esc(t.TABLE) + '\',\'' + esc(c.NAME) + '\')">' +
                           '<span>' + esc(c.NAME) + '</span>' +
                           '<span class="col-type">' + esc(c.TYPE) + '</span></div>';
                }).join('');
                return '<div class="tree-table" onclick="toggleCols(this,\'' + esc(t.TABLE) + '\')">' +
                       '<i class="fa fa-table"></i><span>' + esc(t.TABLE) + '</span>' +
                       '<i class="fa fa-chevron-right ms-auto" style="font-size:.6rem"></i></div>' +
                       '<div class="tree-cols" id="cols_' + esc(t.TABLE) + '">' + cols + '</div>';
            }).join('');
        })
        .catch(function() {
            document.getElementById('schemaTree').innerHTML = '<div class="p-2 text-danger">Şema yüklenemedi.</div>';
        });
}
loadSchema();
document.getElementById('refreshSchema').onclick = loadSchema;

function toggleCols(el, tbl) {
    var panel = document.getElementById('cols_' + tbl);
    panel.classList.toggle('open');
    el.querySelector('.fa-chevron-right').style.transform = panel.classList.contains('open') ? 'rotate(90deg)' : '';
}

function insertCol(tbl, col) {
    editor.replaceSelection(tbl + '.' + col);
    editor.focus();
}

// Tablo adına tıklayarak SELECT snippet ekle
document.getElementById('schemaTree').addEventListener('click', function(e) {
    var tblEl = e.target.closest('.tree-table');
    if (tblEl && e.ctrlKey) {
        var tbl = tblEl.querySelector('span').textContent;
        editor.setValue('SELECT *\nFROM ' + tbl + '\nLIMIT 100');
        editor.focus();
    }
});

// ── Resize sidebar ──────────────────────────────────────
(function() {
    var resizer = document.getElementById('resizer');
    var sidebar = document.getElementById('sidebar');
    var dragging = false;
    resizer.addEventListener('mousedown', function(e) { dragging = true; e.preventDefault(); });
    document.addEventListener('mousemove', function(e) {
        if (!dragging) return;
        var w = e.clientX - sidebar.getBoundingClientRect().left;
        if (w > 120 && w < 500) sidebar.style.width = w + 'px';
    });
    document.addEventListener('mouseup', function() { dragging = false; });
})();

function esc(s) { return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/'/g,'&#39;'); }
</script>
</body>
</html>
