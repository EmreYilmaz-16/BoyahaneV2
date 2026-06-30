<cfprocessingdirective pageEncoding="utf-8">
<cfparam name="attributes.keyword" default="">
<cfparam name="attributes.stage" default="">
<cfparam name="attributes.fuseaction_filter" default="">
<cfset keyword = trim(attributes.keyword)>
<cfset stageFilter = trim(attributes.stage)>
<cfset fuseactionFilter = trim(attributes.fuseaction_filter)>

<cfquery name="qSummary" datasource="boyahane">
    SELECT
        (SELECT COUNT(*) FROM fuseaction_notes) AS note_count,
        (SELECT COUNT(*) FROM fuseaction_tasks) AS task_count,
        (SELECT COUNT(*) FROM fuseaction_tasks WHERE stage = 'beklemede') AS waiting_count,
        (SELECT COUNT(*) FROM fuseaction_tasks WHERE stage = 'calisiliyor') AS active_count,
        (SELECT COUNT(*) FROM fuseaction_tasks WHERE stage = 'bitti') AS done_count
</cfquery>

<cfquery name="qTasks" datasource="boyahane">
    SELECT task_id, fuseaction, task_title, task_description, stage, created_at, updated_at
    FROM fuseaction_tasks
    WHERE 1 = 1
    <cfif len(keyword)>
        AND (LOWER(task_title) LIKE <cfqueryparam value="%#lcase(keyword)#%" cfsqltype="cf_sql_varchar">
             OR LOWER(task_description) LIKE <cfqueryparam value="%#lcase(keyword)#%" cfsqltype="cf_sql_varchar">
             OR LOWER(fuseaction) LIKE <cfqueryparam value="%#lcase(keyword)#%" cfsqltype="cf_sql_varchar">)
    </cfif>
    <cfif listFindNoCase("beklemede,calisiliyor,bitti", stageFilter)>
        AND stage = <cfqueryparam value="#stageFilter#" cfsqltype="cf_sql_varchar">
    </cfif>
    <cfif len(fuseactionFilter)>
        AND LOWER(fuseaction) LIKE <cfqueryparam value="%#lcase(fuseactionFilter)#%" cfsqltype="cf_sql_varchar">
    </cfif>
    ORDER BY CASE stage WHEN 'calisiliyor' THEN 1 WHEN 'beklemede' THEN 2 WHEN 'bitti' THEN 3 ELSE 4 END, updated_at DESC, task_id DESC
</cfquery>

<cfquery name="qNotes" datasource="boyahane">
    SELECT note_id, fuseaction, note_title, note_body, created_at, updated_at
    FROM fuseaction_notes
    WHERE 1 = 1
    <cfif len(keyword)>
        AND (LOWER(note_title) LIKE <cfqueryparam value="%#lcase(keyword)#%" cfsqltype="cf_sql_varchar">
             OR LOWER(note_body) LIKE <cfqueryparam value="%#lcase(keyword)#%" cfsqltype="cf_sql_varchar">
             OR LOWER(fuseaction) LIKE <cfqueryparam value="%#lcase(keyword)#%" cfsqltype="cf_sql_varchar">)
    </cfif>
    <cfif len(fuseactionFilter)>
        AND LOWER(fuseaction) LIKE <cfqueryparam value="%#lcase(fuseactionFilter)#%" cfsqltype="cf_sql_varchar">
    </cfif>
    ORDER BY updated_at DESC, note_id DESC
</cfquery>

<cfoutput>
<div class="page-header mb-3">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-layer-group"></i></div>
        <div class="page-header-title">
            <h4>Not ve Görev Merkezi</h4>
            <small>Tüm sayfalardaki görevleri ve notları tek ekranda listeleyin</small>
        </div>
    </div>
</div>

<div class="row g-3 mb-3">
    <div class="col-md col-6"><div class="card h-100"><div class="card-body"><small class="text-muted">Toplam Not</small><h3 class="mb-0">#qSummary.note_count#</h3></div></div></div>
    <div class="col-md col-6"><div class="card h-100"><div class="card-body"><small class="text-muted">Toplam Görev</small><h3 class="mb-0">#qSummary.task_count#</h3></div></div></div>
    <div class="col-md col-6"><div class="card h-100"><div class="card-body"><small class="text-muted">Beklemede</small><h3 class="mb-0 text-secondary">#qSummary.waiting_count#</h3></div></div></div>
    <div class="col-md col-6"><div class="card h-100"><div class="card-body"><small class="text-muted">Çalışılıyor</small><h3 class="mb-0 text-warning">#qSummary.active_count#</h3></div></div></div>
    <div class="col-md col-6"><div class="card h-100"><div class="card-body"><small class="text-muted">Bitti</small><h3 class="mb-0 text-success">#qSummary.done_count#</h3></div></div></div>
</div>

<div class="card mb-3">
    <div class="card-header fw-bold"><i class="fas fa-filter me-1"></i>Filtreler</div>
    <div class="card-body">
        <form method="get" action="index.cfm" class="row g-2 align-items-end">
            <input type="hidden" name="fuseaction" value="productivity.overview">
            <div class="col-md-4"><label class="form-label">Arama</label><input class="form-control" name="keyword" value="#htmlEditFormat(keyword)#" placeholder="Başlık, içerik veya fuseaction ara..."></div>
            <div class="col-md-3"><label class="form-label">Fuseaction</label><input class="form-control" name="fuseaction_filter" value="#htmlEditFormat(fuseactionFilter)#" placeholder="Örn: stock.list_fis"></div>
            <div class="col-md-3"><label class="form-label">Görev Aşaması</label><select class="form-select" name="stage"><option value="">Tümü</option><option value="beklemede" <cfif stageFilter EQ 'beklemede'>selected</cfif>>Beklemede</option><option value="calisiliyor" <cfif stageFilter EQ 'calisiliyor'>selected</cfif>>Üzerinde Çalışılıyor</option><option value="bitti" <cfif stageFilter EQ 'bitti'>selected</cfif>>Bitti</option></select></div>
            <div class="col-md-2 d-flex gap-2"><button class="btn btn-primary flex-fill"><i class="fas fa-search me-1"></i>Listele</button><a class="btn btn-outline-secondary" href="index.cfm?fuseaction=productivity.overview">Temizle</a></div>
        </form>
    </div>
</div>

<div class="row g-3">
    <div class="col-xl-7">
        <div class="card h-100"><div class="card-header fw-bold"><i class="fas fa-list-check me-1"></i>Görevler (#qTasks.recordCount#)</div><div class="table-responsive"><table class="table table-hover align-middle mb-0"><thead><tr><th>Görev</th><th>Sayfa</th><th>Aşama</th><th>Güncelleme</th><th></th></tr></thead><tbody>
        <cfloop query="qTasks"><cfset badgeClass = stage EQ 'bitti' ? 'success' : (stage EQ 'calisiliyor' ? 'warning' : 'secondary')><tr><td><strong>#htmlEditFormat(task_title)#</strong><cfif len(task_description)><div class="text-muted small">#htmlEditFormat(left(task_description, 160))#<cfif len(task_description) GT 160>...</cfif></div></cfif></td><td><code>#htmlEditFormat(fuseaction)#</code></td><td><span class="badge bg-#badgeClass#">#htmlEditFormat(stage)#</span></td><td><small>#dateFormat(updated_at,'dd.mm.yyyy')# #timeFormat(updated_at,'HH:nn')#</small></td><td class="text-end"><a class="btn btn-sm btn-outline-primary" href="index.cfm?fuseaction=productivity.page_tasks&target_fuseaction=#urlEncodedFormat(fuseaction)#">Aç</a></td></tr></cfloop>
        <cfif qTasks.recordCount EQ 0><tr><td colspan="5" class="text-center text-muted py-4">Filtreye uygun görev bulunamadı.</td></tr></cfif>
        </tbody></table></div></div>
    </div>
    <div class="col-xl-5">
        <div class="card h-100"><div class="card-header fw-bold"><i class="fas fa-note-sticky me-1"></i>Notlar (#qNotes.recordCount#)</div><div class="list-group list-group-flush">
        <cfloop query="qNotes"><div class="list-group-item"><div class="d-flex justify-content-between gap-2"><div><strong>#htmlEditFormat(note_title)#</strong><div><code>#htmlEditFormat(fuseaction)#</code></div></div><small class="text-muted text-nowrap">#dateFormat(updated_at,'dd.mm.yyyy')# #timeFormat(updated_at,'HH:nn')#</small></div><cfif len(note_body)><div class="text-muted small mt-2" style="white-space:pre-wrap">#htmlEditFormat(left(note_body, 220))#<cfif len(note_body) GT 220>...</cfif></div></cfif><a class="btn btn-sm btn-outline-primary mt-2" href="index.cfm?fuseaction=productivity.page_notes&target_fuseaction=#urlEncodedFormat(fuseaction)#">Notları Aç</a></div></cfloop>
        <cfif qNotes.recordCount EQ 0><div class="list-group-item text-center text-muted py-4">Filtreye uygun not bulunamadı.</div></cfif>
        </div></div>
    </div>
</div>
</cfoutput>
