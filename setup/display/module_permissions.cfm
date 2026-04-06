<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getUsers" datasource="boyahane">
    SELECT id,
           TRIM(COALESCE(name, '') || ' ' || COALESCE(surname, '')) AS full_name,
           username,
           is_active
    FROM kullanicilar
    ORDER BY is_active DESC, name, surname
</cfquery>

<cfquery name="getModules" datasource="boyahane">
    SELECT m.module_id,
           m.module_name,
           f.family_name,
           s.solution_name,
           m.is_active
    FROM pbs_module m
    INNER JOIN pbs_family f ON f.family_id = m.family_id
    INNER JOIN pbs_solution s ON s.solution_id = f.solution_id
    ORDER BY s.order_no, f.order_no, m.order_no, m.module_name
</cfquery>

<cfset usersArr = []>
<cfloop query="getUsers">
    <cfset arrayAppend(usersArr, {
        "id": val(id),
        "full_name": full_name,
        "username": username,
        "is_active": is_active
    })>
</cfloop>

<cfset modulesArr = []>
<cfloop query="getModules">
    <cfset arrayAppend(modulesArr, {
        "module_id": val(module_id),
        "module_name": module_name,
        "family_name": family_name,
        "solution_name": solution_name,
        "is_active": is_active
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-user-shield"></i></div>
        <div class="page-header-title">
            <h1>Modül Yetkilendirme</h1>
            <p>Kullanıcı bazlı modül görme / güncelleme / silme yetkileri</p>
        </div>
    </div>
</div>

<div class="px-3 pb-5">
    <div class="grid-card mb-3">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-user"></i>Kullanıcı Seçimi</div>
        </div>
        <div class="card-body p-3">
            <div class="row g-3 align-items-end">
                <div class="col-lg-6 col-md-8">
                    <label class="form-label">Kullanıcı</label>
                    <div id="userSelect"></div>
                </div>
                <div class="col-lg-6 col-md-4 text-md-end">
                    <button class="btn btn-outline-secondary" onclick="reloadPermissions()"><i class="fas fa-sync me-1"></i>Yenile</button>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-lock"></i>Modül Yetki Matrisi</div>
            <span class="record-count" id="recordCount">0 kayıt</span>
        </div>
        <div class="card-body p-2">
            <div id="permissionGrid"></div>
        </div>
    </div>
</div>

<script>
var usersData = #serializeJSON(usersArr)#;
var modulesData = #serializeJSON(modulesArr)#;
var selectedUserId = 0;

$(function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    $('#userSelect').dxSelectBox({
        dataSource: usersData,
        valueExpr: 'id',
        displayExpr: function(item){
            if (!item) return '';
            return item.full_name + ' (@' + item.username + ')' + (item.is_active ? '' : ' [Pasif]');
        },
        searchEnabled: true,
        placeholder: 'Kullanıcı seçin',
        onValueChanged: function(e){
            selectedUserId = parseInt(e.value || 0, 10) || 0;
            loadPermissions();
        }
    });

    if (usersData.length > 0) {
        var firstActive = usersData.find(function(u){ return !!u.is_active; }) || usersData[0];
        selectedUserId = firstActive.id;
        $('#userSelect').dxSelectBox('instance').option('value', selectedUserId);
    } else {
        buildGrid([]);
    }
});

function reloadPermissions() {
    loadPermissions();
}

function loadPermissions() {
    if (!selectedUserId) {
        buildGrid([]);
        return;
    }

    $.getJSON('/setup/form/get_user_module_permissions.cfm', { user_id: selectedUserId }, function(res){
        if (!res || !res.success) {
            DevExpress.ui.notify((res && res.message) || 'Yetkiler okunamadı.', 'error', 3000);
            return;
        }

        var permissionMap = {};
        (res.data || []).forEach(function(row){
            permissionMap[row.module_id] = row;
        });

        var rows = modulesData.map(function(m){
            var p = permissionMap[m.module_id] || {};
            return {
                module_id: m.module_id,
                solution_name: m.solution_name,
                family_name: m.family_name,
                module_name: m.module_name,
                module_active: !!m.is_active,
                can_view: !!p.can_view,
                can_update: !!p.can_update,
                can_delete: !!p.can_delete
            };
        });

        buildGrid(rows);
    }).fail(function(){
        DevExpress.ui.notify('Sunucu hatası.', 'error', 3000);
    });
}

function buildGrid(rows) {
    $('#permissionGrid').dxDataGrid({
        dataSource: rows,
        keyExpr: 'module_id',
        showBorders: true,
        rowAlternationEnabled: true,
        paging: { pageSize: 50 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [25,50,100], showInfo: true },
        searchPanel: { visible: true, placeholder: 'Modül ara...' },
        filterRow: { visible: true },
        onContentReady: function(e) {
            $('#recordCount').text(e.component.totalCount() + ' kayıt');
        },
        columns: [
            { dataField: 'solution_name', caption: 'Çözüm', minWidth: 150 },
            { dataField: 'family_name', caption: 'Aile', minWidth: 150 },
            { dataField: 'module_name', caption: 'Modül', minWidth: 180 },
            {
                dataField: 'module_active', caption: 'Modül Durumu', width: 120, alignment: 'center',
                cellTemplate: function(c, o) {
                    $('<span class="badge bg-' + (o.value ? 'success' : 'secondary') + '">' + (o.value ? 'Aktif' : 'Pasif') + '</span>').appendTo(c);
                }
            },
            { dataField: 'can_view', caption: 'Görme', dataType: 'boolean', width: 90, allowFiltering: false },
            { dataField: 'can_update', caption: 'Güncelleme', dataType: 'boolean', width: 120, allowFiltering: false },
            { dataField: 'can_delete', caption: 'Silme', dataType: 'boolean', width: 90, allowFiltering: false }
        ],
        editing: {
            mode: 'cell',
            allowUpdating: true
        },
        onRowUpdating: function(e) {
            var newData = $.extend({}, e.oldData, e.newData);

            if (!newData.can_view) {
                newData.can_update = false;
                newData.can_delete = false;
            }

            e.cancel = true;
            savePermission(newData, function(ok){
                if (ok) {
                    Object.assign(e.oldData, newData);
                    $('#permissionGrid').dxDataGrid('instance').refresh();
                }
            });
        }
    });
}

function savePermission(row, done) {
    $.post('/setup/form/save_user_module_permission.cfm', {
        user_id: selectedUserId,
        module_id: row.module_id,
        can_view: row.can_view ? 1 : 0,
        can_update: row.can_update ? 1 : 0,
        can_delete: row.can_delete ? 1 : 0
    }, function(res){
        if (res && res.success) {
            DevExpress.ui.notify('Yetki kaydedildi.', 'success', 1500);
            done(true);
        } else {
            DevExpress.ui.notify((res && res.message) || 'Yetki kaydedilemedi.', 'error', 3000);
            done(false);
        }
    }, 'json').fail(function(){
        DevExpress.ui.notify('Sunucu hatası.', 'error', 3000);
        done(false);
    });
}
</script>
</cfoutput>
