<cfprocessingdirective pageEncoding="utf-8">
<cfparam name="attributes.target_fuseaction" default="">
<cfset targetFuseaction = trim(attributes.target_fuseaction)>
<cfif NOT len(targetFuseaction)><cfset targetFuseaction = attributes.fuseaction></cfif>
<cfset pageMessage = "">
<cfset pageError = "">

<cfif structKeyExists(form, "note_action")>
    <cftry>
        <cfif form.note_action EQ "save">
            <cfif val(structKeyExists(form, "note_id") ? form.note_id : 0) GT 0>
                <cfquery datasource="boyahane">
                    UPDATE fuseaction_notes
                    SET note_title = <cfqueryparam value="#trim(form.note_title)#" cfsqltype="cf_sql_varchar">,
                        note_body = <cfqueryparam value="#trim(form.note_body)#" cfsqltype="cf_sql_longvarchar">,
                        updated_by = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">,
                        updated_at = NOW()
                    WHERE note_id = <cfqueryparam value="#val(form.note_id)#" cfsqltype="cf_sql_integer">
                      AND fuseaction = <cfqueryparam value="#targetFuseaction#" cfsqltype="cf_sql_varchar">
                </cfquery>
                <cfset pageMessage = "Not güncellendi.">
            <cfelse>
                <cfquery datasource="boyahane">
                    INSERT INTO fuseaction_notes (fuseaction, note_title, note_body, created_by, updated_by)
                    VALUES (
                        <cfqueryparam value="#targetFuseaction#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#trim(form.note_title)#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#trim(form.note_body)#" cfsqltype="cf_sql_longvarchar">,
                        <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
                    )
                </cfquery>
                <cfset pageMessage = "Not kaydedildi.">
            </cfif>
        <cfelseif form.note_action EQ "delete" AND val(structKeyExists(form, "note_id") ? form.note_id : 0) GT 0>
            <cfquery datasource="boyahane">
                DELETE FROM fuseaction_notes
                WHERE note_id = <cfqueryparam value="#val(form.note_id)#" cfsqltype="cf_sql_integer">
                  AND fuseaction = <cfqueryparam value="#targetFuseaction#" cfsqltype="cf_sql_varchar">
            </cfquery>
            <cfset pageMessage = "Not silindi.">
        </cfif>
        <cfcatch type="any"><cfset pageError = cfcatch.message></cfcatch>
    </cftry>
</cfif>

<cfquery name="qNotes" datasource="boyahane">
    SELECT note_id, fuseaction, note_title, note_body, created_at, updated_at
    FROM fuseaction_notes
    WHERE fuseaction = <cfqueryparam value="#targetFuseaction#" cfsqltype="cf_sql_varchar">
    ORDER BY updated_at DESC, note_id DESC
</cfquery>

<cfoutput>
<div class="page-header mb-3">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-note-sticky"></i></div>
        <div class="page-header-title"><h4>Sayfa Notları</h4><small>#htmlEditFormat(targetFuseaction)# için not ekle, listele ve güncelle</small></div>
    </div>
    <div class="d-flex gap-2"><a class="btn btn-outline-secondary btn-sm" href="index.cfm?fuseaction=productivity.overview"><i class="fas fa-layer-group me-1"></i>Merkez</a><a class="btn btn-outline-primary btn-sm" href="index.cfm?fuseaction=productivity.page_tasks&target_fuseaction=#urlEncodedFormat(targetFuseaction)#"><i class="fas fa-list-check me-1"></i>Görevlere Git</a></div>
</div>
<cfif len(pageMessage)><div class="alert alert-success">#htmlEditFormat(pageMessage)#</div></cfif>
<cfif len(pageError)><div class="alert alert-danger">#htmlEditFormat(pageError)#</div></cfif>
<div class="card mb-3"><div class="card-header fw-bold">Not Ekle / Güncelle</div><div class="card-body">
<form method="post" id="noteForm">
<input type="hidden" name="note_action" value="save"><input type="hidden" name="note_id" id="note_id" value="0">
<div class="mb-2"><label class="form-label">Başlık</label><input class="form-control" name="note_title" id="note_title" required maxlength="255"></div>
<div class="mb-2"><label class="form-label">Not</label><textarea class="form-control" name="note_body" id="note_body" rows="5" required></textarea></div>
<button class="btn btn-primary"><i class="fas fa-save me-1"></i>Kaydet</button>
<button type="button" class="btn btn-secondary" onclick="resetNoteForm()">Temizle</button>
</form></div></div>
<div class="row g-3">
<cfloop query="qNotes">
<div class="col-md-6"><div class="card h-100"><div class="card-body">
<h5>#htmlEditFormat(note_title)#</h5><p style="white-space:pre-wrap">#htmlEditFormat(note_body)#</p>
<small class="text-muted">Güncelleme: #dateFormat(updated_at,'dd.mm.yyyy')# #timeFormat(updated_at,'HH:nn')#</small>
</div><div class="card-footer d-flex gap-2">
<button class="btn btn-sm btn-outline-primary" onclick="editNote('#note_id#','#jsStringFormat(note_title)#','#jsStringFormat(note_body)#')"><i class="fas fa-pen me-1"></i>Düzenle</button>
<form method="post" onsubmit="return confirm('Not silinsin mi?')"><input type="hidden" name="note_action" value="delete"><input type="hidden" name="note_id" value="#note_id#"><button class="btn btn-sm btn-outline-danger"><i class="fas fa-trash me-1"></i>Sil</button></form>
</div></div></div>
</cfloop>
<cfif qNotes.recordCount EQ 0><div class="col-12"><div class="alert alert-info">Bu fuseaction için henüz not yok.</div></div></cfif>
</div>
<script>
function editNote(id,title,body){document.getElementById('note_id').value=id;document.getElementById('note_title').value=title;document.getElementById('note_body').value=body;window.scrollTo({top:0,behavior:'smooth'});} 
function resetNoteForm(){document.getElementById('noteForm').reset();document.getElementById('note_id').value=0;}
</script>
</cfoutput>
