<cfprocessingdirective pageEncoding="utf-8">

<cfif NOT structKeyExists(session, "authenticated") OR NOT session.authenticated>
    <cflocation url="/login.cfm" addtoken="false">
    <cfabort>
</cfif>

<cfquery name="getUser" datasource="boyahane">
    SELECT id, name, surname, username, w3userid, default_fuseaction,
           is_active, created_at, updated_at, last_login
    FROM kullanicilar
    WHERE id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
    LIMIT 1
</cfquery>

<cfif NOT getUser.recordCount>
    <div class="alert alert-danger m-4">Kullanıcı bulunamadı.</div>
    <cfabort>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-user-circle"></i></div>
        <div class="page-header-title">
            <h1>Profilim</h1>
            <cfoutput><p>#encodeForHTML(getUser.name)# #encodeForHTML(getUser.surname)#</p></cfoutput>
        </div>
    </div>
</div>

<div class="px-3 pb-4">
    <div class="row g-3">

        <!-- Sol: Profil Kartı -->
        <div class="col-lg-4">
            <div class="grid-card mb-3">
                <div class="card-body p-4 text-center">
                    <div class="profile-avatar-lg mx-auto mb-3">
                        <cfoutput>#UCase(Left(getUser.name,1))##UCase(Left(getUser.surname,1))#</cfoutput>
                    </div>
                    <h5 class="fw-bold mb-1">
                        <cfoutput>#encodeForHTML(getUser.name)# #encodeForHTML(getUser.surname)#</cfoutput>
                    </h5>
                    <p class="text-muted small mb-3">
                        <cfoutput>@#encodeForHTML(getUser.username)#</cfoutput>
                    </p>
                    <span class="badge rounded-pill px-3 py-2
                        <cfif getUser.is_active>text-bg-success<cfelse>text-bg-secondary</cfif>">
                        <i class="fas fa-<cfif getUser.is_active>circle-check<cfelse>ban</cfif> me-1"></i>
                        <cfif getUser.is_active>Aktif<cfelse>Pasif</cfif>
                    </span>
                </div>
                <div class="card-body border-top pt-3 pb-3 px-4">
                    <div class="info-row">
                        <span class="info-label"><i class="fas fa-clock me-2 text-muted"></i>Son Giriş</span>
                        <span class="info-value">
                            <cfoutput><cfif isDate(getUser.last_login)>#dateFormat(getUser.last_login,"dd/mm/yyyy")# #timeFormat(getUser.last_login,"HH:mm")#<cfelse>-</cfif></cfoutput>
                        </span>
                    </div>
                    <div class="info-row">
                        <span class="info-label"><i class="fas fa-calendar-plus me-2 text-muted"></i>Kayıt Tarihi</span>
                        <span class="info-value">
                            <cfoutput><cfif isDate(getUser.created_at)>#dateFormat(getUser.created_at,"dd/mm/yyyy")#<cfelse>-</cfif></cfoutput>
                        </span>
                    </div>
                    <div class="info-row">
                        <span class="info-label"><i class="fas fa-rotate me-2 text-muted"></i>Son Güncelleme</span>
                        <span class="info-value">
                            <cfoutput><cfif isDate(getUser.updated_at)>#dateFormat(getUser.updated_at,"dd/mm/yyyy")#<cfelse>-</cfif></cfoutput>
                        </span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Sağ: Bilgi Düzenleme + Şifre -->
        <div class="col-lg-8">

            <!-- Kişisel Bilgiler -->
            <div class="grid-card mb-3">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-id-card"></i>Kişisel Bilgiler</div>
                </div>
                <div class="card-body p-4">
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Ad <span class="text-danger">*</span></label>
                            <input readonly type="text" id="p_name" class="form-control"
                                   value="<cfoutput>#encodeForHTMLAttribute(getUser.name)#</cfoutput>" maxlength="100">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Soyad <span class="text-danger">*</span></label>
                            <input readonly type="text" id="p_surname" class="form-control"
                                   value="<cfoutput>#encodeForHTMLAttribute(getUser.surname)#</cfoutput>" maxlength="100">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">Kullanıcı Adı <span class="text-danger">*</span></label>
                            <input readonly type="text" id="p_username" class="form-control"
                                   value="<cfoutput>#encodeForHTMLAttribute(getUser.username)#</cfoutput>" maxlength="50">
                        </div>
                        <div class="col-md-6">
                            <label class="form-label fw-semibold">W3 Kullanıcı ID</label>
                            <input readonly type="text" id="p_w3userid" class="form-control"
                                   value="<cfoutput>#encodeForHTMLAttribute(getUser.w3userid ?: '')#</cfoutput>" maxlength="100">
                        </div>
                        <div class="col-12">
                            <label class="form-label fw-semibold">Varsayılan Giriş Sayfası</label>
                            <input readonly type="text" id="p_default_fuseaction" class="form-control"
                                   placeholder="myhome.welcome"
                                   value="<cfoutput>#encodeForHTMLAttribute(getUser.default_fuseaction ?: '')#</cfoutput>" maxlength="100">
                            <div class="form-text">Örnek: <code>myhome.welcome</code></div>
                        </div>
                    </div>
                    <div id="profileMsg" class="mt-3"></div>
                    <div style="display:none" class="mt-3">
                        <button class="btn btn-warning text-dark fw-bold px-4" onclick="saveProfile()">
                            <i class="fas fa-save me-2"></i>Bilgileri Kaydet
                        </button>
                    </div>
                </div>
            </div>

            <!-- Şifre Değiştir -->
            <div class="grid-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-lock"></i>Şifre Değiştir</div>
                </div>
                <div class="card-body p-4">
                    <div class="row g-3">
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Mevcut Şifre <span class="text-danger">*</span></label>
                            <div class="input-group">
                                <input type="password" id="pw_current" class="form-control" autocomplete="current-password">
                                <button class="btn btn-outline-secondary" type="button" onclick="togglePw('pw_current',this)">
                                    <i class="fas fa-eye"></i>
                                </button>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Yeni Şifre <span class="text-danger">*</span></label>
                            <div class="input-group">
                                <input type="password" id="pw_new" class="form-control" autocomplete="new-password">
                                <button class="btn btn-outline-secondary" type="button" onclick="togglePw('pw_new',this)">
                                    <i class="fas fa-eye"></i>
                                </button>
                            </div>
                        </div>
                        <div class="col-md-4">
                            <label class="form-label fw-semibold">Yeni Şifre (Tekrar) <span class="text-danger">*</span></label>
                            <div class="input-group">
                                <input type="password" id="pw_confirm" class="form-control" autocomplete="new-password">
                                <button class="btn btn-outline-secondary" type="button" onclick="togglePw('pw_confirm',this)">
                                    <i class="fas fa-eye"></i>
                                </button>
                            </div>
                        </div>
                    </div>
                    <!-- Şifre gücü göstergesi -->
                    <div class="mt-2" id="pwStrengthBar" style="display:none;">
                        <div class="d-flex justify-content-between mb-1">
                            <small class="text-muted">Şifre Gücü</small>
                            <small id="pwStrengthLabel"></small>
                        </div>
                        <div class="progress" style="height:6px;">
                            <div id="pwStrengthProgress" class="progress-bar" style="width:0%;transition:width .3s;"></div>
                        </div>
                    </div>
                    <div id="passwordMsg" class="mt-3"></div>
                    <div class="mt-3">
                        <button class="btn btn-danger fw-bold px-4" onclick="changePassword()">
                            <i class="fas fa-key me-2"></i>Şifreyi Değiştir
                        </button>
                    </div>
                </div>
            </div>

        </div>
    </div>
</div>

<cfoutput>
<style>
.profile-avatar-lg {
    width:80px;height:80px;border-radius:50%;
    background:linear-gradient(135deg,##1a3a5c,##2563ab);
    color:##fff;font-size:1.8rem;font-weight:700;
    display:flex;align-items:center;justify-content:center;
    box-shadow:0 4px 16px rgba(26,58,92,.35);
}
.grid-card { background:##fff;border-radius:10px;box-shadow:0 2px 12px rgba(0,0,0,.07);overflow:hidden; }
.grid-card-header { padding:14px 20px 12px;border-bottom:1px solid ##e9ecef;display:flex;align-items:center;justify-content:space-between; }
.grid-card-header-title { font-size:.95rem;font-weight:700;color:var(--primary);display:flex;align-items:center;gap:8px; }
.grid-card-header-title i { color:var(--accent); }
.info-row { display:flex;justify-content:space-between;align-items:center;padding:8px 0;border-bottom:1px solid ##f3f4f6;font-size:.875rem; }
.info-row:last-child { border-bottom:none; }
.info-label { color:##6b7280; }
.info-value { font-weight:500;color:##111827; }
</style>
<script>
function saveProfile() {
    var name     = document.getElementById('p_name').value.trim();
    var surname  = document.getElementById('p_surname').value.trim();
    var username = document.getElementById('p_username').value.trim();
    if (!name)    { showMsg('profileMsg','Ad zorunludur.','danger'); return; }
    if (!surname) { showMsg('profileMsg','Soyad zorunludur.','danger'); return; }
    if (!username){ showMsg('profileMsg','Kullanıcı adı zorunludur.','danger'); return; }

    var btn = event.currentTarget;
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url: '/kullanicilar/form/save_my_profile.cfm',
        method: 'POST', dataType: 'json',
        data: {
            name:               name,
            surname:            surname,
            username:           username,
            w3userid:           document.getElementById('p_w3userid').value.trim(),
            default_fuseaction: document.getElementById('p_default_fuseaction').value.trim()
        },
        success: function(res) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Bilgileri Kaydet';
            if (res && res.success) {
                showMsg('profileMsg','Bilgileriniz güncellendi.','success');
            } else {
                showMsg('profileMsg', res.message || 'Hata oluştu.','danger');
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Bilgileri Kaydet';
            showMsg('profileMsg','Sunucu hatası.','danger');
        }
    });
}

function changePassword() {
    var cur  = document.getElementById('pw_current').value;
    var nw   = document.getElementById('pw_new').value;
    var conf = document.getElementById('pw_confirm').value;
    if (!cur)  { showMsg('passwordMsg','Mevcut şifrenizi girin.','danger'); return; }
    if (!nw)   { showMsg('passwordMsg','Yeni şifre boş olamaz.','danger'); return; }
    if (nw !== conf) { showMsg('passwordMsg','Yeni şifreler eşleşmiyor.','danger'); return; }
    if (nw.length < 4) { showMsg('passwordMsg','Şifre en az 4 karakter olmalı.','danger'); return; }

    var btn = event.currentTarget;
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Değiştiriliyor...';

    $.ajax({
        url: '/kullanicilar/form/change_password.cfm',
        method: 'POST', dataType: 'json',
        data: { current_password: cur, new_password: nw },
        success: function(res) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-key me-2"></i>Şifreyi Değiştir';
            if (res && res.success) {
                showMsg('passwordMsg','Şifreniz başarıyla değiştirildi.','success');
                document.getElementById('pw_current').value = '';
                document.getElementById('pw_new').value = '';
                document.getElementById('pw_confirm').value = '';
                document.getElementById('pwStrengthBar').style.display = 'none';
            } else {
                showMsg('passwordMsg', res.message || 'Hata oluştu.','danger');
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-key me-2"></i>Şifreyi Değiştir';
            showMsg('passwordMsg','Sunucu hatası.','danger');
        }
    });
}

function showMsg(elId, msg, type) {
    document.getElementById(elId).innerHTML =
        '<div class="alert alert-'+type+' py-2 mb-0"><i class="fas fa-'+(type==='success'?'check-circle':'exclamation-circle')+' me-2"></i>'+msg+'</div>';
}

function togglePw(inputId, btn) {
    var el = document.getElementById(inputId);
    var isPass = el.type === 'password';
    el.type = isPass ? 'text' : 'password';
    btn.innerHTML = '<i class="fas fa-eye' + (isPass ? '-slash' : '') + '"></i>';
}

// Şifre gücü
document.addEventListener('DOMContentLoaded', function(){
    document.getElementById('pw_new').addEventListener('input', function(){
        var v = this.value;
        var bar = document.getElementById('pwStrengthBar');
        var prog = document.getElementById('pwStrengthProgress');
        var lbl = document.getElementById('pwStrengthLabel');
        if (!v) { bar.style.display='none'; return; }
        bar.style.display='';
        var score = 0;
        if (v.length >= 6)  score++;
        if (v.length >= 10) score++;
        if (/[A-Z]/.test(v)) score++;
        if (/[0-9]/.test(v)) score++;
        if (/[^A-Za-z0-9]/.test(v)) score++;
        var levels = [
            {w:20, cls:'bg-danger',  txt:'Çok Zayıf', col:'##dc2626'},
            {w:40, cls:'bg-danger',  txt:'Zayıf',     col:'##dc2626'},
            {w:60, cls:'bg-warning', txt:'Orta',       col:'##d97706'},
            {w:80, cls:'bg-info',    txt:'İyi',        col:'##0891b2'},
            {w:100,cls:'bg-success', txt:'Güçlü',      col:'##16a34a'}
        ];
        var l = levels[Math.min(score, 4)];
        prog.style.width = l.w + '%';
        prog.className = 'progress-bar ' + l.cls;
        lbl.textContent = l.txt;
        lbl.style.color = l.col;
    });
});
</script>
</cfoutput>