<cfprocessingdirective pageEncoding="utf-8">

<!--- Kullanıcı listesi --->
<cfquery name="qUsers" datasource="boyahane">
    SELECT id, name, surname, username
    FROM kullanicilar
    WHERE COALESCE(is_active, true) = true
    ORDER BY name, surname
</cfquery>

<!--- Tüm aktif fuseaction listesi (pbs_objects) --->
<cfquery name="qFuseactions" datasource="boyahane">
    SELECT full_fuseaction, object_title
    FROM pbs_objects
    WHERE is_active = true
      AND object_type = 'page'
    ORDER BY full_fuseaction
</cfquery>

<!--- Mevcut kısıtlamalar --->
<cfquery name="qDeny" datasource="boyahane">
    SELECT
        d.deny_id,
        d.user_id,
        d.fuseaction,
        d.reason,
        d.created_at,
        k.name       AS user_name,
        k.surname    AS user_surname,
        k.username   AS user_username,
        o.object_title
    FROM user_fuseaction_deny d
    JOIN kullanicilar k ON k.id = d.user_id
    LEFT JOIN pbs_objects o ON o.full_fuseaction = d.fuseaction
    ORDER BY k.name, k.surname, d.fuseaction
</cfquery>

<cfset denyArr = []>
<cfloop query="qDeny">
    <cfset arrayAppend(denyArr, {
        "deny_id"      : val(deny_id),
        "user_id"      : val(user_id),
        "fuseaction"   : fuseaction    ?: "",
        "reason"       : reason        ?: "",
        "created_at"   : isDate(created_at) ? dateFormat(created_at,"dd/mm/yyyy") & " " & timeFormat(created_at,"HH:mm") : "",
        "user_name"    : user_name     ?: "",
        "user_surname" : user_surname  ?: "",
        "fullname"     : trim((user_name ?: "") & " " & (user_surname ?: "")),
        "username"     : user_username ?: "",
        "object_title" : len(trim(object_title ?: "")) ? object_title : fuseaction
    })>
</cfloop>

<cfset usersArr = []>
<cfloop query="qUsers">
    <cfset arrayAppend(usersArr, {
        "id"       : val(id),
        "fullname" : trim(name & " " & surname) & " (" & username & ")",
        "name"     : name ?: "",
        "surname"  : surname ?: "",
        "username" : username ?: ""
    })>
</cfloop>

<cfset faArr = []>
<cfloop query="qFuseactions">
    <cfset arrayAppend(faArr, {
        "fuseaction"   : full_fuseaction ?: "",
        "object_title" : len(trim(object_title ?: "")) ? object_title : full_fuseaction
    })>
</cfloop>

<cfoutput>
<style>
/* ===== FUSEACTION DENY ===== */
.fad-page { padding: 0 4px 32px; }

.fad-header {
    background: linear-gradient(135deg, ##1a3a5c 0%, ##0d2137 100%);
    border-radius: 14px;
    padding: 20px 24px;
    margin-bottom: 20px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 12px;
    box-shadow: 0 4px 18px rgba(13,33,55,.25);
}
.fad-header-left  { display: flex; align-items: center; gap: 16px; }
.fad-header-icon  {
    width: 48px; height: 48px;
    background: ##dc2626;
    border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.35rem; color: ##fff;
    box-shadow: 0 4px 14px rgba(220,38,38,.4);
    flex-shrink: 0;
}
.fad-header-title { font-size: 1.25rem; font-weight: 800; color: ##fff; margin: 0 0 3px; }
.fad-header-sub   { font-size: 0.78rem; color: rgba(255,255,255,.55); margin: 0; }
.fad-header-btn {
    background: ##dc2626;
    border: 1px solid ##b91c1c;
    color: ##fff;
    font-size: 0.82rem; font-weight: 600;
    padding: 7px 16px; border-radius: 8px;
    display: inline-flex; align-items: center; gap: 6px;
    cursor: pointer; transition: background .15s;
}
.fad-header-btn:hover { background: ##b91c1c; }

/* Stat Kartlar */
.fad-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 12px;
    margin-bottom: 22px;
}
.fad-stat {
    background: ##fff;
    border-radius: 12px;
    padding: 16px;
    display: flex; align-items: center; gap: 14px;
    box-shadow: 0 2px 10px rgba(0,0,0,.06);
    border: 1px solid ##f1f5f9;
}
.fad-stat-icon {
    width: 44px; height: 44px;
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.2rem; flex-shrink: 0;
}
.fad-stat-icon.total   { background: ##fef2f2; color: ##dc2626; }
.fad-stat-icon.users   { background: ##eff6ff; color: ##3b82f6; }
.fad-stat-icon.fas-cnt { background: ##fef3c7; color: ##d97706; }
.fad-stat-label { font-size: 0.7rem; font-weight: 600; color: ##94a3b8; text-transform: uppercase; letter-spacing: .04em; margin-bottom: 2px; }
.fad-stat-val   { font-size: 1.65rem; font-weight: 800; line-height: 1.1; color: ##0f172a; }

/* Tablo kartı */
.fad-table-card {
    background: ##fff;
    border-radius: 14px;
    box-shadow: 0 2px 10px rgba(0,0,0,.06);
    border: 1px solid ##e5e7eb;
    overflow: hidden;
}
.fad-table-card .table { margin: 0; }
.fad-table-card thead th {
    background: var(--primary, ##1a3a5c);
    color: ##fff;
    font-size: 0.75rem; font-weight: 600;
    text-transform: uppercase; letter-spacing: .04em;
    border: none; padding: 10px 12px; white-space: nowrap;
}
.fad-table-card tbody td { font-size: 0.82rem; padding: 10px 12px; vertical-align: middle; border-color: ##f1f5f9; }
.fad-table-card tbody tr:last-child td { border-bottom: none; }
.fad-table-card tbody tr:hover td { background: ##fef9f9; }

.fad-avatar {
    width: 34px; height: 34px;
    border-radius: 50%;
    background: linear-gradient(135deg, ##1a3a5c, ##dc2626);
    color: ##fff;
    font-size: 0.78rem; font-weight: 700;
    display: inline-flex; align-items: center; justify-content: center;
    flex-shrink: 0; text-transform: uppercase;
}

.fad-search-bar {
    padding: 14px 16px;
    border-bottom: 1px solid ##f1f5f9;
    display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
}
.fad-search-input {
    border: 1px solid ##e5e7eb;
    border-radius: 8px;
    padding: 7px 12px 7px 34px;
    font-size: 0.82rem;
    outline: none;
    min-width: 260px;
    background: ##f8fafc url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='14' height='14' fill='%2394a3b8' viewBox='0 0 16 16'%3E%3Cpath d='M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001c.03.04.062.078.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1.007 1.007 0 0 0-.115-.099zm-5.242 1.156a5.5 5.5 0 1 1 0-11 5.5 5.5 0 0 1 0 11z'/%3E%3C/svg%3E") no-repeat 10px center;
    transition: border-color .15s;
}
.fad-search-input:focus { border-color: ##dc2626; background-color: ##fff; }

.fa-badge {
    display: inline-block;
    background: ##fef2f2;
    color: ##dc2626;
    border: 1px solid ##fecaca;
    border-radius: 6px;
    padding: 2px 8px;
    font-size: 0.72rem;
    font-weight: 700;
    font-family: monospace;
}
</style>

<div class="fad-page">

    <!--- Header --->
    <div class="fad-header">
        <div class="fad-header-left">
            <div class="fad-header-icon"><i class="fas fa-ban"></i></div>
            <div>
                <p class="fad-header-title">Fuseaction Kısıtlamaları</p>
                <p class="fad-header-sub">Kullanıcı bazlı sayfa erişim engel listesi</p>
            </div>
        </div>
        <button class="fad-header-btn" onclick="openDenyModal(null)">
            <i class="fas fa-plus"></i> Yeni Kısıtlama
        </button>
    </div>

    <!--- Stat Kartlar --->
    <cfset uniqueUsers = structNew()>
    <cfset uniqueFuseactions = structNew()>
    <cfloop array="#denyArr#" index="d">
        <cfset uniqueUsers[d.user_id] = 1>
        <cfset uniqueFuseactions[d.fuseaction] = 1>
    </cfloop>

    <div class="fad-stats">
        <div class="fad-stat">
            <div class="fad-stat-icon total"><i class="fas fa-ban"></i></div>
            <div>
                <div class="fad-stat-label">Toplam Kısıtlama</div>
                <div class="fad-stat-val">#arrayLen(denyArr)#</div>
            </div>
        </div>
        <div class="fad-stat">
            <div class="fad-stat-icon users"><i class="fas fa-users"></i></div>
            <div>
                <div class="fad-stat-label">Etkilenen Kullanıcı</div>
                <div class="fad-stat-val">#structCount(uniqueUsers)#</div>
            </div>
        </div>
        <div class="fad-stat">
            <div class="fad-stat-icon fas-cnt"><i class="fas fa-link-slash"></i></div>
            <div>
                <div class="fad-stat-label">Engellenen Sayfa</div>
                <div class="fad-stat-val">#structCount(uniqueFuseactions)#</div>
            </div>
        </div>
        <div class="fad-stat">
            <div class="fad-stat-icon" style="background:##f0fdf4;color:##16a34a;"><i class="fas fa-shield-halved"></i></div>
            <div>
                <div class="fad-stat-label">Aktif Sayfa Sayısı</div>
                <div class="fad-stat-val">#qFuseactions.recordCount#</div>
            </div>
        </div>
    </div>

    <!--- Tablo --->
    <div class="fad-table-card">
        <div class="fad-search-bar">
            <input type="text" class="fad-search-input" id="fadSearch"
                   placeholder="Kullanıcı adı, fuseaction veya açıklama ile ara..."
                   oninput="filterDeny()">
            <span class="text-muted" style="font-size:0.78rem;" id="fadCount">#arrayLen(denyArr)# kısıtlama</span>
        </div>
        <div class="table-responsive">
            <table class="table table-hover table-sm align-middle" id="fadTable">
                <thead>
                    <tr>
                        <th style="width:44px;"></th>
                        <th>Kullanıcı</th>
                        <th>Engellenen Fuseaction</th>
                        <th>Sayfa Başlığı</th>
                        <th>Açıklama / Neden</th>
                        <th>Eklenme Tarihi</th>
                        <th style="width:80px;"></th>
                    </tr>
                </thead>
                <tbody id="fadTableBody">
                    <cfif arrayLen(denyArr) gt 0>
                        <cfloop array="#denyArr#" index="d">
                        <cfset initials = uCase(left(trim(d.user_name),1)) & uCase(left(trim(d.user_surname),1))>
                        <tr data-search="#lCase(d.fullname)# #lCase(d.username)# #lCase(d.fuseaction)# #lCase(d.object_title)# #lCase(d.reason)#"
                            data-id="#d.deny_id#">
                            <td><div class="fad-avatar">#htmlEditFormat(initials)#</div></td>
                            <td>
                                <span class="fw-semibold">#htmlEditFormat(d.fullname)#</span><br>
                                <code style="font-size:0.72rem;background:##f1f5f9;padding:1px 6px;border-radius:4px;">#htmlEditFormat(d.username)#</code>
                            </td>
                            <td>
                                <span class="fa-badge">#htmlEditFormat(d.fuseaction)#</span>
                            </td>
                            <td style="color:##475569;font-size:0.8rem;">#htmlEditFormat(d.object_title)#</td>
                            <td style="color:##64748b;font-size:0.8rem;max-width:220px;">
                                #len(trim(d.reason)) ? htmlEditFormat(d.reason) : '<span class="text-muted">—</span>'#
                            </td>
                            <td style="font-size:0.78rem;color:##94a3b8;">
                                #len(d.created_at) ? '<i class="fas fa-clock me-1"></i>' & d.created_at : "—"#
                            </td>
                            <td>
                                <button class="btn btn-sm"
                                        style="background:##fef2f2;color:##dc2626;border:none;padding:4px 9px;border-radius:6px;font-size:0.75rem;"
                                        onclick="confirmDelete(#d.deny_id#,'#jsStringFormat(d.fullname)#','#jsStringFormat(d.fuseaction)#')">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </td>
                        </tr>
                        </cfloop>
                    <cfelse>
                        <tr id="emptyRow">
                            <td colspan="7" class="text-center py-5 text-muted">
                                <i class="fas fa-shield-check" style="font-size:2.5rem;display:block;margin-bottom:12px;color:##cbd5e1;"></i>
                                Kayıtlı fuseaction kısıtlaması bulunamadı.
                            </td>
                        </tr>
                    </cfif>
                </tbody>
            </table>
        </div>
    </div>

</div>

<!--- Modal: Yeni Kısıtlama Ekle --->
<div class="modal fade" id="denyModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header" style="background:linear-gradient(135deg,##1a3a5c,##0d2137);">
                <h5 class="modal-title text-white">
                    <i class="fas fa-ban me-2"></i>Yeni Fuseaction Kısıtlaması
                </h5>
                <button class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-12">
                        <label class="form-label fw-semibold">Kullanıcı <span class="text-danger">*</span></label>
                        <select id="d_user_id" class="form-select">
                            <option value="">— Kullanıcı seçin —</option>
                            <cfloop array="#usersArr#" index="u">
                            <option value="#u.id#">#htmlEditFormat(trim(u.name & " " & u.surname) & " (" & u.username & ")")#</option>
                            </cfloop>
                        </select>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Engellenen Fuseaction <span class="text-danger">*</span></label>
                        <select id="d_fuseaction_select" class="form-select" onchange="syncFuseactionInput(this.value)">
                            <option value="">— Listeden seçin veya aşağıya yazın —</option>
                            <cfloop array="#faArr#" index="fa">
                            <option value="#htmlEditFormat(fa.fuseaction)#">#htmlEditFormat(fa.fuseaction)##len(trim(fa.object_title)) && fa.object_title != fa.fuseaction ? " — " & fa.object_title : ""#</option>
                            </cfloop>
                        </select>
                        <div class="mt-2">
                            <input id="d_fuseaction" class="form-control" placeholder="veya manuel girin: modul.action" maxlength="255" autocomplete="off"
                                   oninput="document.getElementById('d_fuseaction_select').value = ''">
                        </div>
                        <div class="form-text">Listeden seçin ya da doğrudan yazın (örn: <strong>production.list_orders</strong>).</div>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Açıklama / Neden</label>
                        <input id="d_reason" class="form-control" placeholder="Kısıtlama nedeni (isteğe bağlı)" maxlength="255">
                    </div>
                </div>
                <div class="alert alert-warning mt-3 mb-0 p-2" style="font-size:0.8rem;">
                    <i class="fas fa-triangle-exclamation me-1"></i>
                    Eklenen kısıtlama, kullanıcının o sayfaya erişimini anında engeller.
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-light" data-bs-dismiss="modal">İptal</button>
                <button class="btn px-4" style="background:##dc2626;color:##fff;border:none;font-weight:600;" onclick="saveDeny()">
                    <i class="fas fa-ban me-1"></i>Kısıtla
                </button>
            </div>
        </div>
    </div>
</div>

<!--- Modal: Silme Onayı --->
<div class="modal fade" id="deleteDenyModal" tabindex="-1">
    <div class="modal-dialog modal-sm">
        <div class="modal-content">
            <div class="modal-header border-0 pb-0">
                <h6 class="modal-title fw-bold"><i class="fas fa-triangle-exclamation text-danger me-2"></i>Kısıtlamayı Kaldır</h6>
                <button class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body pt-2" style="font-size:0.85rem;">
                <strong id="deleteDenyUser"></strong> adlı kullanıcının
                <code id="deleteDenyFa" style="background:##fef2f2;color:##dc2626;padding:1px 6px;border-radius:4px;"></code>
                fuseaction kısıtlaması kaldırılacak.
            </div>
            <div class="modal-footer border-0 pt-0">
                <button class="btn btn-sm btn-light" data-bs-dismiss="modal">Vazgeç</button>
                <button class="btn btn-sm px-3" style="background:##dc2626;color:##fff;border:none;font-weight:600;" onclick="deleteDeny()">
                    <i class="fas fa-trash me-1"></i>Kaldır
                </button>
            </div>
        </div>
    </div>
</div>

<script>
var deleteDenyId = 0;

function openDenyModal(row) {
    document.getElementById('d_user_id').value = '';
    document.getElementById('d_fuseaction_select').value = '';
    document.getElementById('d_fuseaction').value = '';
    document.getElementById('d_reason').value = '';

    var el = document.getElementById('denyModal');
    if (el.parentElement !== document.body) document.body.appendChild(el);
    new bootstrap.Modal(el).show();
}

function syncFuseactionInput(val) {
    document.getElementById('d_fuseaction').value = val;
}

function saveDeny() {
    var userId     = document.getElementById('d_user_id').value;
    var fuseaction = document.getElementById('d_fuseaction').value.trim();
    var reason     = document.getElementById('d_reason').value.trim();

    if (!userId)     { fadNotify('Kullanıcı seçilmedi.',        'warning'); return; }
    if (!fuseaction) { fadNotify('Fuseaction girilmedi.',        'warning'); return; }
    if (!/^[a-z0-9_\.]+$/i.test(fuseaction)) {
        fadNotify('Fuseaction geçersiz karakter içeriyor.', 'warning');
        return;
    }

    $.post('/kullanicilar/form/save_fuseaction_deny.cfm', {
        action:      'add',
        user_id:     userId,
        fuseaction:  fuseaction,
        reason:      reason
    }, function(res) {
        if (res && res.success) {
            var mEl = document.getElementById('denyModal');
            var mInst = bootstrap.Modal.getInstance(mEl);
            if (mInst) mInst.hide();
            fadNotify('Kısıtlama eklendi.', 'success');
            setTimeout(function(){ location.reload(); }, 900);
        } else {
            fadNotify((res && res.message) || 'İşlem başarısız.', 'error');
        }
    }, 'json').fail(function(){ fadNotify('Sunucu hatası.', 'error'); });
}

function confirmDelete(denyId, fullname, fuseaction) {
    deleteDenyId = denyId;
    document.getElementById('deleteDenyUser').textContent = fullname;
    document.getElementById('deleteDenyFa').textContent   = fuseaction;
    var el = document.getElementById('deleteDenyModal');
    if (el.parentElement !== document.body) document.body.appendChild(el);
    new bootstrap.Modal(el).show();
}

function deleteDeny() {
    if (!deleteDenyId) return;
    $.post('/kullanicilar/form/save_fuseaction_deny.cfm', {
        action:  'delete',
        deny_id: deleteDenyId
    }, function(res) {
        if (res && res.success) {
            var mEl = document.getElementById('deleteDenyModal');
            var mInst = bootstrap.Modal.getInstance(mEl);
            if (mInst) mInst.hide();
            fadNotify('Kısıtlama kaldırıldı.', 'success');
            setTimeout(function(){ location.reload(); }, 900);
        } else {
            fadNotify((res && res.message) || 'İşlem başarısız.', 'error');
        }
    }, 'json').fail(function(){ fadNotify('Sunucu hatası.', 'error'); });
}

function filterDeny() {
    var q = document.getElementById('fadSearch').value.toLowerCase().trim();
    var rows = document.querySelectorAll('#fadTable tbody tr[data-search]');
    var visible = 0;
    rows.forEach(function(row) {
        var match = !q || row.dataset.search.indexOf(q) !== -1;
        row.style.display = match ? '' : 'none';
        if (match) visible++;
    });
    document.getElementById('fadCount').textContent = visible + ' kısıtlama';
}

function fadNotify(msg, type) {
    var colors = { success: '##16a34a', error: '##dc2626', warning: '##d97706', info: '##3b82f6' };
    var icons  = { success: 'fa-circle-check', error: 'fa-circle-xmark', warning: 'fa-triangle-exclamation', info: 'fa-circle-info' };
    var t = document.createElement('div');
    t.style.cssText = 'position:fixed;top:18px;right:18px;z-index:99999;background:#fff;border-left:4px solid '+(colors[type]||colors.info)+';border-radius:8px;padding:12px 18px;box-shadow:0 4px 20px rgba(0,0,0,.15);display:flex;align-items:center;gap:10px;font-size:.85rem;max-width:340px;';
    t.innerHTML = '<i class="fas '+(icons[type]||icons.info)+'" style="color:'+(colors[type]||colors.info)+';font-size:1rem;flex-shrink:0;"></i><span>'+msg+'</span>';
    document.body.appendChild(t);
    setTimeout(function(){ t.style.opacity='0'; t.style.transition='opacity .4s'; setTimeout(function(){ t.remove(); }, 400); }, 2800);
}
</script>
</cfoutput>
