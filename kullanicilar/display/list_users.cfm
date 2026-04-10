<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="qUsers" datasource="boyahane">
    SELECT
        k.id,
        COALESCE(k.name, '')        AS name,
        COALESCE(k.surname, '')     AS surname,
        COALESCE(k.username, '')    AS username,
        COALESCE(k.w3userid, '')    AS w3userid,
        COALESCE(k.is_active, true) AS is_active,
        k.last_login,
        k.created_at,
        k.updated_at
    FROM kullanicilar k
    ORDER BY k.name, k.surname
</cfquery>

<cfquery name="qSummary" datasource="boyahane">
    SELECT
        COUNT(*)                                                         AS total_users,
        SUM(CASE WHEN COALESCE(is_active, true) THEN 1 ELSE 0 END)      AS active_users,
        SUM(CASE WHEN NOT COALESCE(is_active, true) THEN 1 ELSE 0 END)  AS passive_users,
        SUM(CASE WHEN last_login >= (CURRENT_TIMESTAMP - INTERVAL '7 day') THEN 1 ELSE 0 END) AS recent_logins
    FROM kullanicilar
</cfquery>

<cfset usersArr = []>
<cfloop query="qUsers">
    <cfset arrayAppend(usersArr, {
        "id"          : val(id),
        "name"        : name        ?: "",
        "surname"     : surname     ?: "",
        "fullname"    : trim(name & " " & surname),
        "username"    : username    ?: "",
        "w3userid"    : w3userid    ?: "",
        "is_active"   : isBoolean(is_active) ? is_active : true,
        "last_login"  : isDate(last_login)   ? dateFormat(last_login,"dd/mm/yyyy") & " " & timeFormat(last_login,"HH:mm") : "",
        "created_at"  : isDate(created_at)   ? dateFormat(created_at,"dd/mm/yyyy") : "",
        "updated_at"  : isDate(updated_at)   ? dateFormat(updated_at,"dd/mm/yyyy") : ""
    })>
</cfloop>

<cfoutput>
<style>
/* ===== KULLANICILAR ===== */
.usr-page { padding: 0 4px 32px; }

/* Header */
.usr-header {
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
.usr-header-left  { display: flex; align-items: center; gap: 16px; }
.usr-header-icon  {
    width: 48px; height: 48px;
    background: ##e67e22;
    border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.35rem; color: ##fff;
    box-shadow: 0 4px 14px rgba(230,126,34,.4);
    flex-shrink: 0;
}
.usr-header-title { font-size: 1.25rem; font-weight: 800; color: ##fff; margin: 0 0 3px; }
.usr-header-sub   { font-size: 0.78rem; color: rgba(255,255,255,.55); margin: 0; }
.usr-header-btn {
    background: rgba(255,255,255,.12);
    border: 1px solid rgba(255,255,255,.2);
    color: ##fff;
    font-size: 0.82rem; font-weight: 600;
    padding: 7px 16px; border-radius: 8px;
    display: inline-flex; align-items: center; gap: 6px;
    cursor: pointer; transition: background .15s;
}
.usr-header-btn:hover { background: rgba(255,255,255,.22); color: ##fff; }
.usr-header-btn-accent { background: ##e67e22; border-color: ##e67e22; }
.usr-header-btn-accent:hover { background: ##d35400; border-color: ##d35400; }

/* Özet Kartlar */
.usr-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 12px;
    margin-bottom: 22px;
}
.usr-stat {
    background: ##fff;
    border-radius: 12px;
    padding: 16px;
    display: flex; align-items: center; gap: 14px;
    box-shadow: 0 2px 10px rgba(0,0,0,.06);
    border: 1px solid ##f1f5f9;
}
.usr-stat-icon {
    width: 44px; height: 44px;
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.2rem; flex-shrink: 0;
}
.usr-stat-icon.total   { background: ##eff6ff; color: ##3b82f6; }
.usr-stat-icon.active  { background: ##f0fdf4; color: ##16a34a; }
.usr-stat-icon.passive { background: ##fef2f2; color: ##dc2626; }
.usr-stat-icon.recent  { background: ##fef3c7; color: ##d97706; }
.usr-stat-label { font-size: 0.7rem; font-weight: 600; color: ##94a3b8; text-transform: uppercase; letter-spacing: .04em; margin-bottom: 2px; }
.usr-stat-val   { font-size: 1.65rem; font-weight: 800; line-height: 1.1; color: ##0f172a; }

/* Tablo kartı */
.usr-table-card {
    background: ##fff;
    border-radius: 14px;
    box-shadow: 0 2px 10px rgba(0,0,0,.06);
    border: 1px solid ##e5e7eb;
    overflow: hidden;
}
.usr-table-card .table { margin: 0; }
.usr-table-card thead th {
    background: var(--primary, ##1a3a5c);
    color: ##fff;
    font-size: 0.75rem; font-weight: 600;
    text-transform: uppercase; letter-spacing: .04em;
    border: none; padding: 10px 12px; white-space: nowrap;
}
.usr-table-card tbody td { font-size: 0.82rem; padding: 10px 12px; vertical-align: middle; border-color: ##f1f5f9; }
.usr-table-card tbody tr:last-child td { border-bottom: none; }
.usr-table-card tbody tr:hover td { background: ##f8fafc; }

/* Avatar */
.usr-avatar {
    width: 34px; height: 34px;
    border-radius: 50%;
    background: linear-gradient(135deg, ##1a3a5c, ##e67e22);
    color: ##fff;
    font-size: 0.78rem; font-weight: 700;
    display: inline-flex; align-items: center; justify-content: center;
    flex-shrink: 0; text-transform: uppercase;
}

/* Arama kutusu */
.usr-search-bar {
    padding: 14px 16px;
    border-bottom: 1px solid ##f1f5f9;
    display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
}
.usr-search-input {
    border: 1px solid ##e5e7eb;
    border-radius: 8px;
    padding: 7px 12px 7px 34px;
    font-size: 0.82rem;
    outline: none;
    min-width: 240px;
    background: ##f8fafc url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='14' height='14' fill='%2394a3b8' viewBox='0 0 16 16'%3E%3Cpath d='M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001c.03.04.062.078.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1.007 1.007 0 0 0-.115-.099zm-5.242 1.156a5.5 5.5 0 1 1 0-11 5.5 5.5 0 0 1 0 11z'/%3E%3C/svg%3E") no-repeat 10px center;
    transition: border-color .15s;
}
.usr-search-input:focus { border-color: ##1a3a5c; background-color: ##fff; }
</style>

<div class="usr-page">

    <!--- Header --->
    <div class="usr-header">
        <div class="usr-header-left">
            <div class="usr-header-icon"><i class="fas fa-users"></i></div>
            <div>
                <p class="usr-header-title">Kullanıcı Yönetimi</p>
                <p class="usr-header-sub">Sistem kullanıcılarını görüntüle ve yönet</p>
            </div>
        </div>
        <button class="usr-header-btn usr-header-btn-accent" onclick="openUserModal(null)">
            <i class="fas fa-user-plus"></i> Yeni Kullanıcı
        </button>
    </div>

    <!--- Özet Kartlar --->
    <div class="usr-stats">
        <div class="usr-stat">
            <div class="usr-stat-icon total"><i class="fas fa-users"></i></div>
            <div>
                <div class="usr-stat-label">Toplam</div>
                <div class="usr-stat-val">#val(qSummary.total_users)#</div>
            </div>
        </div>
        <div class="usr-stat">
            <div class="usr-stat-icon active"><i class="fas fa-user-check"></i></div>
            <div>
                <div class="usr-stat-label">Aktif</div>
                <div class="usr-stat-val">#val(qSummary.active_users)#</div>
            </div>
        </div>
        <div class="usr-stat">
            <div class="usr-stat-icon passive"><i class="fas fa-user-xmark"></i></div>
            <div>
                <div class="usr-stat-label">Pasif</div>
                <div class="usr-stat-val">#val(qSummary.passive_users)#</div>
            </div>
        </div>
        <div class="usr-stat">
            <div class="usr-stat-icon recent"><i class="fas fa-clock-rotate-left"></i></div>
            <div>
                <div class="usr-stat-label">Son 7 Gün</div>
                <div class="usr-stat-val">#val(qSummary.recent_logins)#</div>
            </div>
        </div>
    </div>

    <!--- Tablo --->
    <div class="usr-table-card">
        <div class="usr-search-bar">
            <input type="text" class="usr-search-input" id="usrSearch" placeholder="Ad, kullanıcı adı veya W3 ID ile ara..." oninput="filterUsers()">
            <span class="text-muted" style="font-size:0.78rem;" id="usrCount">#val(qSummary.total_users)# kullanıcı</span>
        </div>
        <div class="table-responsive">
            <table class="table table-hover table-sm align-middle" id="usrTable">
                <thead>
                    <tr>
                        <th style="width:44px;"></th>
                        <th>Ad Soyad</th>
                        <th>Kullanıcı Adı</th>
                        <th>W3 User ID</th>
                        <th class="text-center">Durum</th>
                        <th>Son Giriş</th>
                        <th>Kayıt Tarihi</th>
                        <th style="width:100px;"></th>
                    </tr>
                </thead>
                <tbody id="usrTableBody">
                    <cfif qUsers.recordCount gt 0>
                        <cfloop query="qUsers">
                        <cfset initials = uCase(left(trim(name),1)) & uCase(left(trim(surname),1))>
                        <tr data-search="#lCase(name)# #lCase(surname)# #lCase(username)# #lCase(w3userid)#">
                            <td>
                                <div class="usr-avatar">#htmlEditFormat(initials)#</div>
                            </td>
                            <td>
                                <span class="fw-semibold">#htmlEditFormat(name)# #htmlEditFormat(surname)#</span>
                            </td>
                            <td>
                                <code style="font-size:0.78rem;background:##f1f5f9;padding:2px 7px;border-radius:5px;">#htmlEditFormat(username)#</code>
                            </td>
                            <td style="font-size:0.78rem;color:##64748b;">#len(trim(w3userid)) ? htmlEditFormat(w3userid) : "—"#</td>
                            <td class="text-center">
                                <cfif is_active>
                                    <span class="badge" style="background:##f0fdf4;color:##16a34a;font-weight:700;font-size:0.72rem;">
                                        <i class="fas fa-circle me-1" style="font-size:.45rem;"></i>Aktif
                                    </span>
                                <cfelse>
                                    <span class="badge" style="background:##fef2f2;color:##dc2626;font-weight:700;font-size:0.72rem;">
                                        <i class="fas fa-circle me-1" style="font-size:.45rem;"></i>Pasif
                                    </span>
                                </cfif>
                            </td>
                            <td style="font-size:0.78rem;color:##64748b;">
                                <cfif isDate(last_login)>
                                    <i class="fas fa-clock me-1"></i>#dateFormat(last_login,"dd/mm/yyyy")# #timeFormat(last_login,"HH:mm")#
                                <cfelse>
                                    <span class="text-muted">—</span>
                                </cfif>
                            </td>
                            <td style="font-size:0.78rem;color:##94a3b8;">
                                #isDate(created_at) ? dateFormat(created_at,"dd/mm/yyyy") : ""#
                            </td>
                            <td>
                                <div class="d-flex gap-1">
                                    <button class="btn btn-sm" style="background:##eff6ff;color:##3b82f6;border:none;padding:4px 9px;border-radius:6px;font-size:0.75rem;"
                                            onclick="openUserModal({id:#val(id)#,name:'#jsStringFormat(name)#',surname:'#jsStringFormat(surname)#',username:'#jsStringFormat(username)#',w3userid:'#jsStringFormat(w3userid)#',is_active:#is_active ? 'true' : 'false'#})">
                                        <i class="fas fa-pencil"></i>
                                    </button>
                                    <button class="btn btn-sm" style="background:##fef2f2;color:##dc2626;border:none;padding:4px 9px;border-radius:6px;font-size:0.75rem;"
                                            onclick="confirmDelete(#val(id)#,'#jsStringFormat(name & ' ' & surname)#')">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </div>
                            </td>
                        </tr>
                        </cfloop>
                    <cfelse>
                        <tr id="emptyRow">
                            <td colspan="8" class="text-center py-5 text-muted">
                                <i class="fas fa-users" style="font-size:2.5rem;display:block;margin-bottom:12px;color:##cbd5e1;"></i>
                                Kayıtlı kullanıcı bulunamadı.
                            </td>
                        </tr>
                    </cfif>
                </tbody>
            </table>
        </div>
    </div>

</div>

<!--- Modal: Kullanıcı Ekle / Güncelle --->
<div class="modal fade" id="userModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header" style="background:linear-gradient(135deg,##1a3a5c,##0d2137);">
                <h5 class="modal-title text-white" id="userModalTitle">
                    <i class="fas fa-user-plus me-2"></i>Yeni Kullanıcı
                </h5>
                <button class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="u_id" value="0">
                <div class="row g-3">
                    <div class="col-6">
                        <label class="form-label fw-semibold">Ad <span class="text-danger">*</span></label>
                        <input id="u_name" class="form-control" placeholder="Ad" maxlength="100">
                    </div>
                    <div class="col-6">
                        <label class="form-label fw-semibold">Soyad <span class="text-danger">*</span></label>
                        <input id="u_surname" class="form-control" placeholder="Soyad" maxlength="100">
                    </div>
                    <div class="col-6">
                        <label class="form-label fw-semibold">Kullanıcı Adı <span class="text-danger">*</span></label>
                        <input id="u_username" class="form-control" placeholder="ornek_kullanici" maxlength="50" autocomplete="off">
                    </div>
                    <div class="col-6">
                        <label class="form-label fw-semibold">W3 User ID</label>
                        <input id="u_w3userid" class="form-control" placeholder="USR001" maxlength="100">
                    </div>
                    <div class="col-12" id="u_password_row">
                        <label class="form-label fw-semibold">Şifre <span class="text-danger" id="u_pass_required">*</span></label>
                        <input id="u_password" type="password" class="form-control" placeholder="Şifre" maxlength="100" autocomplete="new-password">
                        <div class="form-text" id="u_pass_hint" style="display:none;">Boş bırakılırsa şifre değiştirilmez.</div>
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Durum</label>
                        <select id="u_is_active" class="form-select">
                            <option value="1">Aktif</option>
                            <option value="0">Pasif</option>
                        </select>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-light" data-bs-dismiss="modal">İptal</button>
                <button class="btn px-4" style="background:##e67e22;color:##fff;border:none;font-weight:600;" onclick="saveUser()">
                    <i class="fas fa-floppy-disk me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<!--- Modal: Silme Onayı --->
<div class="modal fade" id="deleteModal" tabindex="-1">
    <div class="modal-dialog modal-sm">
        <div class="modal-content">
            <div class="modal-header border-0 pb-0">
                <h6 class="modal-title fw-bold"><i class="fas fa-triangle-exclamation text-danger me-2"></i>Kullanıcı Sil</h6>
                <button class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body pt-2">
                <p class="mb-0" style="font-size:0.85rem;">
                    <strong id="deleteUserName"></strong> adlı kullanıcı silinecek. Bu işlem geri alınamaz.
                </p>
            </div>
            <div class="modal-footer border-0 pt-0">
                <button class="btn btn-sm btn-light" data-bs-dismiss="modal">Vazgeç</button>
                <button class="btn btn-sm px-3" style="background:##dc2626;color:##fff;border:none;font-weight:600;" onclick="deleteUser()">
                    <i class="fas fa-trash me-1"></i>Sil
                </button>
            </div>
        </div>
    </div>
</div>

<script>
var usersData = #serializeJSON(usersArr)#;
var deleteUserId = 0;

function openUserModal(row) {
    var isEdit = row && row.id > 0;
    document.getElementById('userModalTitle').innerHTML = isEdit
        ? '<i class="fas fa-pencil me-2"></i>Kullanıcı Güncelle'
        : '<i class="fas fa-user-plus me-2"></i>Yeni Kullanıcı';

    document.getElementById('u_id').value       = isEdit ? row.id : 0;
    document.getElementById('u_name').value     = isEdit ? row.name : '';
    document.getElementById('u_surname').value  = isEdit ? row.surname : '';
    document.getElementById('u_username').value = isEdit ? row.username : '';
    document.getElementById('u_w3userid').value = isEdit ? row.w3userid : '';
    document.getElementById('u_password').value = '';
    document.getElementById('u_is_active').value = isEdit && row.is_active === false ? '0' : '1';

    // Şifre alanı davranışı
    document.getElementById('u_pass_required').style.display = isEdit ? 'none' : '';
    document.getElementById('u_pass_hint').style.display     = isEdit ? '' : 'none';

    var el = document.getElementById('userModal');
    if (el.parentElement !== document.body) document.body.appendChild(el);
    new bootstrap.Modal(el).show();
}

function saveUser() {
    var id       = parseInt(document.getElementById('u_id').value) || 0;
    var name     = document.getElementById('u_name').value.trim();
    var surname  = document.getElementById('u_surname').value.trim();
    var username = document.getElementById('u_username').value.trim();
    var password = document.getElementById('u_password').value;
    var w3userid = document.getElementById('u_w3userid').value.trim();
    var isActive = document.getElementById('u_is_active').value;

    if (!name)     { usrNotify('Ad zorunludur.',           'warning'); return; }
    if (!surname)  { usrNotify('Soyad zorunludur.',        'warning'); return; }
    if (!username) { usrNotify('Kullanıcı adı zorunludur.','warning'); return; }
    if (id === 0 && !password) { usrNotify('Şifre zorunludur.', 'warning'); return; }

    $.post('/kullanicilar/form/save_user.cfm', {
        user_id:   id,
        name:      name,
        surname:   surname,
        username:  username,
        password:  password,
        w3userid:  w3userid,
        is_active: isActive
    }, function(res) {
        if (res && res.success) {
            var mEl = document.getElementById('userModal');
            var mInst = bootstrap.Modal.getInstance(mEl);
            if (mInst) mInst.hide();
            usrNotify('Kullanıcı kaydedildi.', 'success');
            setTimeout(function(){ location.reload(); }, 1000);
        } else {
            usrNotify((res && res.message) || 'İşlem başarısız.', 'error');
        }
    }, 'json').fail(function(){ usrNotify('Sunucu hatası.', 'error'); });
}

function confirmDelete(id, fullname) {
    deleteUserId = id;
    document.getElementById('deleteUserName').textContent = fullname;
    var el = document.getElementById('deleteModal');
    if (el.parentElement !== document.body) document.body.appendChild(el);
    new bootstrap.Modal(el).show();
}

function deleteUser() {
    if (!deleteUserId) return;
    $.post('/kullanicilar/form/delete_user.cfm', { user_id: deleteUserId }, function(res) {
        if (res && res.success) {
            var mEl = document.getElementById('deleteModal');
            var mInst = bootstrap.Modal.getInstance(mEl);
            if (mInst) mInst.hide();
            usrNotify('Kullanıcı silindi.', 'success');
            setTimeout(function(){ location.reload(); }, 1000);
        } else {
            usrNotify((res && res.message) || 'İşlem başarısız.', 'error');
        }
    }, 'json').fail(function(){ usrNotify('Sunucu hatası.', 'error'); });
}

/* ---- Bildirim fonksiyonu ---- */
function usrNotify(msg, type) {
    var colors = { success: '##16a34a', error: '##dc2626', warning: '##d97706', info: '##3b82f6' };
    var icons  = { success: 'fa-circle-check', error: 'fa-circle-xmark', warning: 'fa-triangle-exclamation', info: 'fa-circle-info' };
    var t = document.createElement('div');
    t.style.cssText = 'position:fixed;top:18px;right:18px;z-index:99999;background:##fff;border-left:4px solid '+(colors[type]||colors.info)+';border-radius:8px;padding:12px 18px;box-shadow:0 4px 20px rgba(0,0,0,.15);display:flex;align-items:center;gap:10px;font-size:.85rem;max-width:340px;';
    t.innerHTML = '<i class="fas '+(icons[type]||icons.info)+'" style="color:'+(colors[type]||colors.info)+';font-size:1rem;flex-shrink:0;"></i><span>'+msg+'</span>';
    document.body.appendChild(t);
    setTimeout(function(){ t.style.opacity='0'; t.style.transition='opacity .4s'; setTimeout(function(){ t.remove(); }, 400); }, 2800);
}

function filterUsers() {
    var q = document.getElementById('usrSearch').value.toLowerCase().trim();
    var rows = document.querySelectorAll('##usrTable tbody tr[data-search]');
    var visible = 0;
    rows.forEach(function(row) {
        var match = !q || row.dataset.search.indexOf(q) !== -1;
        row.style.display = match ? '' : 'none';
        if (match) visible++;
    });
    document.getElementById('usrCount').textContent = visible + ' kullanıcı';
}
</script>
</cfoutput>
