<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.asset_type" default="">
<cfparam name="url.search"     default="">

<cfquery name="getAssets" datasource="boyahane">
    SELECT am.asset_id,
           am.asset_no,
           am.asset_name,
           am.asset_type,
           am.asset_status,
           am.brand,
           am.model,
           am.serial_no,
           am.purchase_date,
           am.acquisition_cost,
           am.currency,
           ac.category_name,
           al.location_name
    FROM asset_master am
    LEFT JOIN asset_categories ac ON ac.category_id = am.category_id
    LEFT JOIN asset_locations al  ON al.location_id = am.location_id
    WHERE 1 = 1
    <cfif len(trim(url.asset_type))>
        AND am.asset_type = <cfqueryparam value="#trim(url.asset_type)#" cfsqltype="cf_sql_varchar">
    </cfif>
    <cfif len(trim(url.search))>
        AND (
            UPPER(am.asset_name) LIKE UPPER(<cfqueryparam value="%#trim(url.search)#%" cfsqltype="cf_sql_varchar">)
            OR UPPER(COALESCE(am.asset_no,''))   LIKE UPPER(<cfqueryparam value="%#trim(url.search)#%" cfsqltype="cf_sql_varchar">)
            OR UPPER(COALESCE(am.serial_no,''))  LIKE UPPER(<cfqueryparam value="%#trim(url.search)#%" cfsqltype="cf_sql_varchar">)
            OR UPPER(COALESCE(am.brand,''))      LIKE UPPER(<cfqueryparam value="%#trim(url.search)#%" cfsqltype="cf_sql_varchar">)
        )
    </cfif>
    ORDER BY am.asset_id DESC
</cfquery>

<cfset assetArr = []>
<cfloop query="getAssets">
    <cfset typeLbl  = "">
    <cfswitch expression="#asset_type#">
        <cfcase value="PHYSICAL"><cfset typeLbl  = "Fiziki"></cfcase>
        <cfcase value="IT">      <cfset typeLbl  = "BT"></cfcase>
        <cfcase value="VEHICLE"> <cfset typeLbl  = "Araç"></cfcase>
        <cfdefaultcase><cfset typeLbl = asset_type ?: ""></cfdefaultcase>
    </cfswitch>

    <cfset statusLbl = "">
    <cfswitch expression="#asset_status#">
        <cfcase value="ACTIVE">        <cfset statusLbl = "Aktif"></cfcase>
        <cfcase value="IN_MAINTENANCE"><cfset statusLbl = "Bakımda"></cfcase>
        <cfcase value="IN_STOCK">      <cfset statusLbl = "Depoda"></cfcase>
        <cfcase value="TRANSFERRED">   <cfset statusLbl = "Transfer"></cfcase>
        <cfcase value="SCRAPPED">      <cfset statusLbl = "Hurdaya Ayrıldı"></cfcase>
        <cfcase value="SOLD">          <cfset statusLbl = "Satıldı"></cfcase>
        <cfdefaultcase><cfset statusLbl = asset_status ?: ""></cfdefaultcase>
    </cfswitch>

    <cfset arrayAppend(assetArr, {
        "asset_id":       val(asset_id),
        "asset_no":       asset_no       ?: "",
        "asset_name":     asset_name     ?: "",
        "asset_type":     asset_type     ?: "",
        "type_label":     typeLbl,
        "asset_status":   asset_status   ?: "",
        "status_label":   statusLbl,
        "brand":          brand          ?: "",
        "model":          model          ?: "",
        "serial_no":      serial_no      ?: "",
        "purchase_date":  isDate(purchase_date) ? dateFormat(purchase_date,"dd/mm/yyyy") : "",
        "acquisition_cost": isNumeric(acquisition_cost) ? val(acquisition_cost) : 0,
        "currency":       currency       ?: "TRY",
        "category_name":  category_name  ?: "-",
        "location_name":  location_name  ?: "-"
    })>
</cfloop>

<cfset totalAll       = getAssets.recordCount>
<cfset totalPhysical  = 0>
<cfset totalIT        = 0>
<cfset totalVehicle   = 0>
<cfset totalActive    = 0>
<cfset totalInactive  = 0>
<cfloop array="#assetArr#" item="a">
    <cfif a.asset_type eq "PHYSICAL"><cfset totalPhysical++></cfif>
    <cfif a.asset_type eq "IT">      <cfset totalIT++></cfif>
    <cfif a.asset_type eq "VEHICLE"> <cfset totalVehicle++></cfif>
    <cfif a.asset_status eq "ACTIVE"><cfset totalActive++></cfif>
    <cfif a.asset_status neq "ACTIVE" AND len(a.asset_status)><cfset totalInactive++></cfif>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-boxes"></i></div>
        <div class="page-header-title">
            <h1>Varlık Yönetimi</h1>
            <p>Fiziki, BT ve araç varlıklarını takip edin</p>
        </div>
    </div>
    <a href="index.cfm?fuseaction=asset.add_asset" class="btn-add">
        <i class="fas fa-plus"></i>Yeni Varlık
    </a>
</div>

<div class="px-3 pb-4">

    <div class="row g-3 mb-3">
        <div class="col-md-2-4">
            <div class="summary-card summary-card-blue">
                <div class="summary-icon"><i class="fas fa-boxes"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Varlık</span>
                    <span class="summary-value"><cfoutput>#totalAll#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-2-4">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-check-circle"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Aktif</span>
                    <span class="summary-value"><cfoutput>#totalActive#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-2-4">
            <div class="summary-card" style="background:linear-gradient(135deg,##0f4c75,##1b6ca8);color:##fff;box-shadow:0 2px 10px rgba(0,0,0,.12);">
                <div class="summary-icon"><i class="fas fa-industry"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Fiziki Varlık</span>
                    <span class="summary-value"><cfoutput>#totalPhysical#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-2-4">
            <div class="summary-card summary-card-purple">
                <div class="summary-icon"><i class="fas fa-laptop"></i></div>
                <div class="summary-info">
                    <span class="summary-label">BT Varlığı</span>
                    <span class="summary-value"><cfoutput>#totalIT#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-2-4">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-truck"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Araç</span>
                    <span class="summary-value"><cfoutput>#totalVehicle#</cfoutput></span>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Varlık Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-3">
            <div class="row g-2 mb-3">
                <div class="col-md-3">
                    <select id="filterType" class="form-select form-select-sm">
                        <option value="">Tüm Tipler</option>
                        <option value="PHYSICAL">Fiziki Varlık</option>
                        <option value="IT">BT Varlığı</option>
                        <option value="VEHICLE">Araç</option>
                    </select>
                </div>
                <div class="col-md-3">
                    <select id="filterStatus" class="form-select form-select-sm">
                        <option value="">Tüm Durumlar</option>
                        <option value="ACTIVE">Aktif</option>
                        <option value="IN_MAINTENANCE">Bakımda</option>
                        <option value="IN_STOCK">Depoda</option>
                        <option value="TRANSFERRED">Transfer</option>
                        <option value="SCRAPPED">Hurdaya Ayrıldı</option>
                        <option value="SOLD">Satıldı</option>
                    </select>
                </div>
                <div class="col-md-4">
                    <input type="text" id="filterSearch" class="form-control form-control-sm" placeholder="Varlık no / ad / seri no / marka ara...">
                </div>
                <div class="col-md-2">
                    <button class="btn btn-outline-secondary btn-sm w-100" onclick="clearFilters()">
                        <i class="fas fa-eraser me-1"></i>Temizle
                    </button>
                </div>
            </div>
            <div id="assetGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<style>
.col-md-2-4 { flex: 0 0 20%; max-width: 20%; }
@media (max-width: 991px) { .col-md-2-4 { flex: 0 0 50%; max-width: 50%; } }
@media (max-width: 575px) { .col-md-2-4 { flex: 0 0 100%; max-width: 100%; } }

.summary-card { display:flex; align-items:center; gap:14px; padding:16px 20px; border-radius:10px; color:##fff; box-shadow:0 2px 10px rgba(0,0,0,.12); }
.summary-card-blue   { background:linear-gradient(135deg,##1a3a5c,##2563ab); }
.summary-card-green  { background:linear-gradient(135deg,##15803d,##22c55e); }
.summary-card-orange { background:linear-gradient(135deg,##92400e,##f59e0b); }
.summary-card-purple { background:linear-gradient(135deg,##6b21a8,##a855f7); }
.summary-icon  { font-size:1.8rem; opacity:.85; }
.summary-label { font-size:.75rem; opacity:.85; display:block; }
.summary-value { font-size:1.6rem; font-weight:700; display:block; }

.badge-type { display:inline-block; padding:3px 10px; border-radius:10px; font-size:.72rem; font-weight:600; }
.badge-type-PHYSICAL { background:##dbeafe; color:##1e40af; }
.badge-type-IT       { background:##ede9fe; color:##6d28d9; }
.badge-type-VEHICLE  { background:##fef3c7; color:##92400e; }

.badge-status { display:inline-block; padding:3px 10px; border-radius:10px; font-size:.72rem; font-weight:600; }
.badge-status-ACTIVE        { background:##dcfce7; color:##15803d; }
.badge-status-IN_MAINTENANCE{ background:##fef9c3; color:##a16207; }
.badge-status-IN_STOCK      { background:##dbeafe; color:##1e40af; }
.badge-status-TRANSFERRED   { background:##ede9fe; color:##6d28d9; }
.badge-status-SCRAPPED      { background:##fee2e2; color:##b91c1c; }
.badge-status-SOLD          { background:##ffedd5; color:##c2410c; }

.action-link { color:##1a3a5c; text-decoration:none; font-weight:600; font-size:.8rem;
    border:1px solid ##1a3a5c; padding:3px 10px; border-radius:6px; display:inline-block; }
.action-link:hover { background:##1a3a5c; color:##fff; }
</style>

<script>
var allAssets = #serializeJSON(assetArr)#;

function renderGrid(data) {
    document.getElementById('recordCount').textContent = data.length + ' kayıt';

    var typeBadge = {
        'PHYSICAL': '<span class="badge-type badge-type-PHYSICAL"><i class="fas fa-industry me-1"></i>Fiziki</span>',
        'IT':       '<span class="badge-type badge-type-IT"><i class="fas fa-laptop me-1"></i>BT</span>',
        'VEHICLE':  '<span class="badge-type badge-type-VEHICLE"><i class="fas fa-truck me-1"></i>Araç</span>'
    };
    var statusBadge = {
        'ACTIVE':         '<span class="badge-status badge-status-ACTIVE">Aktif</span>',
        'IN_MAINTENANCE': '<span class="badge-status badge-status-IN_MAINTENANCE">Bakımda</span>',
        'IN_STOCK':       '<span class="badge-status badge-status-IN_STOCK">Depoda</span>',
        'TRANSFERRED':    '<span class="badge-status badge-status-TRANSFERRED">Transfer</span>',
        'SCRAPPED':       '<span class="badge-status badge-status-SCRAPPED">Hurda</span>',
        'SOLD':           '<span class="badge-status badge-status-SOLD">Satıldı</span>'
    };

    $("##assetGrid").dxDataGrid({
        dataSource: data,
        keyExpr: "asset_id",
        showBorders: false,
        showRowLines: true,
        showColumnLines: false,
        rowAlternationEnabled: true,
        hoverStateEnabled: true,
        wordWrapEnabled: false,
        paging: { pageSize: 25 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [25, 50, 100], showInfo: true, showNavigationButtons: true },
        sorting: { mode: "multiple" },
        columnChooser: { enabled: true },
        export: { enabled: true, fileName: "varlik_listesi" },
        headerFilter: { visible: true },
        columns: [
            { dataField: "asset_id",   caption: "##",          width: 60,  alignment: "center", sortOrder: "desc" },
            { dataField: "asset_no",   caption: "Varlık No",  width: 110 },
            { dataField: "asset_name", caption: "Varlık Adı", minWidth: 180 },
            {
                dataField: "asset_type", caption: "Tip", width: 110, alignment: "center",
                cellTemplate: function(el, info){
                    el.html(typeBadge[info.value] || info.value || '-');
                }
            },
            { dataField: "category_name", caption: "Kategori", width: 140 },
            { dataField: "brand",  caption: "Marka",  width: 110 },
            { dataField: "model",  caption: "Model",  width: 110 },
            { dataField: "serial_no", caption: "Seri No", width: 130 },
            { dataField: "location_name", caption: "Lokasyon", width: 140 },
            { dataField: "purchase_date", caption: "Satın Alma", width: 110, alignment: "center" },
            {
                dataField: "acquisition_cost", caption: "Maliyet", width: 120, alignment: "right",
                cellTemplate: function(el, info){
                    var val = parseFloat(info.value || 0);
                    el.text(val.toLocaleString('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' ' + (info.data.currency || 'TRY'));
                }
            },
            {
                dataField: "asset_status", caption: "Durum", width: 120, alignment: "center",
                cellTemplate: function(el, info){
                    el.html(statusBadge[info.value] || info.value || '-');
                }
            },
            {
                caption: "İşlem", width: 80, alignment: "center", allowSorting: false, allowFiltering: false,
                cellTemplate: function(el, info){
                    el.html('<a class="action-link" href="index.cfm?fuseaction=asset.add_asset&asset_id=' + info.data.asset_id + '"><i class="fas fa-pen"></i></a>');
                }
            }
        ]
    });
}

function applyFilters() {
    var typeVal   = document.getElementById('filterType').value;
    var statusVal = document.getElementById('filterStatus').value;
    var searchVal = (document.getElementById('filterSearch').value || '').trim().toLowerCase();

    var filtered = allAssets.filter(function(a){
        if (typeVal   && a.asset_type   !== typeVal)   return false;
        if (statusVal && a.asset_status !== statusVal) return false;
        if (searchVal) {
            var hay = (a.asset_name + ' ' + a.asset_no + ' ' + a.serial_no + ' ' + a.brand + ' ' + a.model).toLowerCase();
            if (hay.indexOf(searchVal) === -1) return false;
        }
        return true;
    });

    var grid = $("##assetGrid").dxDataGrid("instance");
    if (grid) {
        grid.option("dataSource", filtered);
        document.getElementById('recordCount').textContent = filtered.length + ' kayıt';
    }
}

function clearFilters() {
    document.getElementById('filterType').value   = '';
    document.getElementById('filterStatus').value = '';
    document.getElementById('filterSearch').value = '';
    applyFilters();
}

window.addEventListener('load', function(){
    renderGrid(allAssets);
    document.getElementById('filterType').addEventListener('change', applyFilters);
    document.getElementById('filterStatus').addEventListener('change', applyFilters);
    var st; document.getElementById('filterSearch').addEventListener('input', function(){ clearTimeout(st); st = setTimeout(applyFilters, 300); });
});
</script>
</cfoutput>