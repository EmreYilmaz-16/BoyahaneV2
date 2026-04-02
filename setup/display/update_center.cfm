<div class="container-fluid py-3">
    <div class="d-flex justify-content-between align-items-center mb-3">
        <h3 class="mb-0"><i class="fas fa-sync-alt me-2"></i>Update Merkezi</h3>
        <div>
            <button class="btn btn-outline-primary btn-sm" onclick="loadAllData()"><i class="fas fa-rotate"></i> Yenile</button>
        </div>
    </div>

    <div id="updateAlert"></div>

    <div class="row g-3">
        <div class="col-lg-7">
            <div class="card shadow-sm">
                <div class="card-header bg-light"><strong>Git & Deployment Ayarları</strong></div>
                <div class="card-body">
                    <div class="row g-2">
                        <div class="col-md-8">
                            <label class="form-label">Repo URL</label>
                            <input id="repo_url" class="form-control" placeholder="https://github.com/org/repo.git">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Branch</label>
                            <input id="repo_branch" class="form-control" value="main">
                        </div>
                        <div class="col-md-8">
                            <label class="form-label">Local Path</label>
                            <input id="repo_local_path" class="form-control" value="/workspace/BoyahaneV2">
                        </div>
                        <div class="col-md-4">
                            <label class="form-label">Docker Build Komutu</label>
                            <input id="docker_compose_cmd" class="form-control" value="docker compose up -d --build">
                        </div>
                        <div class="col-md-6 form-check ms-2 mt-3">
                            <input type="checkbox" id="check_releases" class="form-check-input">
                            <label class="form-check-label" for="check_releases">GitHub release kontrol et</label>
                        </div>
                        <div class="col-md-6 form-check ms-2 mt-3">
                            <input type="checkbox" id="auto_pull_on_release" class="form-check-input">
                            <label class="form-check-label" for="auto_pull_on_release">Yeni release varsa otomatik pull + docker build</label>
                        </div>
                    </div>
                    <div class="mt-3 d-flex gap-2">
                        <button class="btn btn-primary" onclick="saveSettings()"><i class="fas fa-save me-1"></i>Kaydet</button>
                        <button class="btn btn-warning" onclick="checkUpdates()"><i class="fas fa-magnifying-glass me-1"></i>Güncelleme Kontrol Et</button>
                        <button class="btn btn-success" onclick="applyUpdates()"><i class="fas fa-download me-1"></i>Pull + Rebuild</button>
                        <button class="btn btn-outline-danger" onclick="discardLocalChanges()"><i class="fas fa-trash-can me-1"></i>Yerel Değişiklikleri Discard Et</button>
                    </div>
                    <pre class="mt-3 p-2 bg-dark text-light rounded" style="max-height:220px;overflow:auto;" id="updateLog">Durum logu...</pre>
                </div>
            </div>

            <div class="card shadow-sm mt-3">
                <div class="card-header bg-light"><strong>Şema Compare Ayarları</strong></div>
                <div class="card-body">
                    <div class="row g-2">
                        <div class="col-md-4"><label class="form-label">DB Host/IP</label><input id="remote_db_host" class="form-control"></div>
                        <div class="col-md-2"><label class="form-label">Port</label><input id="remote_db_port" class="form-control" value="5432"></div>
                        <div class="col-md-3"><label class="form-label">DB Name</label><input id="remote_db_name" class="form-control"></div>
                        <div class="col-md-3"><label class="form-label">Schema</label><input id="remote_db_schema" class="form-control" value="public"></div>
                        <div class="col-md-6"><label class="form-label">DB User</label><input id="remote_db_user" class="form-control"></div>
                        <div class="col-md-6"><label class="form-label">DB Password</label><input id="remote_db_password" type="password" class="form-control"></div>
                    </div>
                    <div class="mt-3 d-flex gap-2">
                        <button class="btn btn-outline-primary" onclick="saveSettings()">Şema Ayarlarını Kaydet</button>
                        <button class="btn btn-outline-dark" onclick="compareSchema()">Şema Compare Çalıştır</button>
                    </div>
                    <ul class="list-group mt-3" id="schemaDiffList"></ul>
                </div>
            </div>
        </div>

        <div class="col-lg-5">
            <div class="card shadow-sm">
                <div class="card-header bg-light"><strong>Sürüm Notları</strong></div>
                <div class="card-body">
                    <div class="mb-2"><input id="note_tag" class="form-control" placeholder="Tag (örn: v2.1.0)"></div>
                    <div class="mb-2"><input id="note_name" class="form-control" placeholder="Release adı"></div>
                    <div class="mb-2"><input id="note_url" class="form-control" placeholder="Release linki"></div>
                    <div class="mb-2"><textarea id="note_body" class="form-control" rows="4" placeholder="Sürüm notu"></textarea></div>
                    <button class="btn btn-outline-success btn-sm" onclick="addReleaseNote()">Sürüm Notu Yayınla</button>
                    <hr>
                    <div id="releaseNotesList" style="max-height:480px;overflow:auto;"></div>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
const svc = '/cfc/systemUpdateService.cfc';

function showAlert(type, text){
    document.getElementById('updateAlert').innerHTML = `<div class="alert alert-${type} py-2">${text}</div>`;
}

async function callService(method, body){
    const url = `${svc}?method=${method}&returnformat=json`;
    const opts = body ? {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(body)} : {method:'GET'};
    const res = await fetch(url, opts);
    return await res.json();
}

function getFormData(){
    return {
        repo_url: document.getElementById('repo_url').value,
        repo_branch: document.getElementById('repo_branch').value,
        repo_local_path: document.getElementById('repo_local_path').value,
        check_releases: document.getElementById('check_releases').checked,
        auto_pull_on_release: document.getElementById('auto_pull_on_release').checked,
        docker_compose_cmd: document.getElementById('docker_compose_cmd').value,
        remote_db_host: document.getElementById('remote_db_host').value,
        remote_db_port: document.getElementById('remote_db_port').value,
        remote_db_name: document.getElementById('remote_db_name').value,
        remote_db_user: document.getElementById('remote_db_user').value,
        remote_db_password: document.getElementById('remote_db_password').value,
        remote_db_schema: document.getElementById('remote_db_schema').value
    };
}

async function loadSettings(){
    const r = await callService('getSettings');
    if(!r.success){ showAlert('danger', r.message); return; }
    const d = r.data;
    Object.keys(d).forEach(k => {
        const el = document.getElementById(k.toLowerCase());
        if(!el) return;
        if(el.type === 'checkbox') el.checked = !!d[k];
        else el.value = d[k] ?? '';
    });
}

async function saveSettings(){
    const r = await callService('saveSettings', getFormData());
    showAlert(r.success ? 'success' : 'danger', r.message || 'Kaydedilemedi');
}

async function checkUpdates(){
    document.getElementById('updateLog').textContent = 'Kontrol ediliyor...';
    const r = await callService('checkUpdates');
    if(r.success){
        showAlert(r.update_available ? 'warning' : 'success', r.message);
        document.getElementById('updateLog').textContent = JSON.stringify(r, null, 2);
    } else {
        showAlert('danger', r.message || 'Hata');
        document.getElementById('updateLog').textContent = JSON.stringify(r, null, 2);
    }
    await loadReleaseNotes();
}

async function applyUpdates(){
    document.getElementById('updateLog').textContent = 'Pull + rebuild çalışıyor...';
    const r = await callService('applyUpdates');
    showAlert(r.success ? 'success' : 'danger', r.message);
    document.getElementById('updateLog').textContent = JSON.stringify(r, null, 2);
}

async function discardLocalChanges(){
    const approved = confirm('Bu işlem yerel değişiklikleri geri alınamaz şekilde silecektir. Devam etmek istiyor musunuz?');
    if(!approved){
        return;
    }
    document.getElementById('updateLog').textContent = 'Yerel değişiklikler discard ediliyor...';
    const r = await callService('discardLocalChanges');
    showAlert(r.success ? 'success' : 'danger', r.message || 'İşlem başarısız');
    document.getElementById('updateLog').textContent = JSON.stringify(r, null, 2);
}

async function compareSchema(){
    const r = await callService('compareSchema');
    const list = document.getElementById('schemaDiffList');
    list.innerHTML = '';
    if(!r.success){
        showAlert('danger', r.message);
        return;
    }
    if(!r.missing_tables || !r.missing_tables.length){
        list.innerHTML = '<li class="list-group-item text-success">Eksik tablo yok.</li>';
    } else {
        r.missing_tables.forEach(t => {
            list.innerHTML += `<li class="list-group-item d-flex justify-content-between"><span>${t}</span><span class="badge text-bg-warning">Uzakta var, lokalde yok</span></li>`;
        });
    }
    showAlert('info', r.message);
}

async function addReleaseNote(){
    const payload = {
        release_tag: document.getElementById('note_tag').value,
        release_name: document.getElementById('note_name').value,
        release_url: document.getElementById('note_url').value,
        published_at: new Date().toISOString(),
        note_body: document.getElementById('note_body').value
    };
    const r = await callService('addReleaseNote', payload);
    showAlert(r.success ? 'success' : 'danger', r.message);
    await loadReleaseNotes();
}

async function loadReleaseNotes(){
    const r = await callService('getReleaseNotes');
    const box = document.getElementById('releaseNotesList');
    if(!r.success){ box.innerHTML = '<div class="text-danger">Sürüm notları yüklenemedi.</div>'; return; }
    box.innerHTML = (r.data || []).map(n => `
        <div class="border rounded p-2 mb-2">
            <div class="d-flex justify-content-between">
                <strong>${n.release_tag}</strong>
                <small class="text-muted">${n.source_type || ''}</small>
            </div>
            <div>${n.release_name || ''}</div>
            <div class="small text-muted">${n.published_at || ''}</div>
            ${n.release_url ? `<a href="${n.release_url}" target="_blank">Release Link</a>` : ''}
            <pre class="small mt-2 mb-0" style="white-space:pre-wrap;">${n.note_body || ''}</pre>
        </div>
    `).join('');
}

async function loadAllData(){
    await loadSettings();
    await loadReleaseNotes();
}

loadAllData();
</script>
