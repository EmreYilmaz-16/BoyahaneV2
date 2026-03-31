<cfprocessingdirective pageEncoding="utf-8">

<!--- ============================================================
      Planlanmamış üretim emirleri:
      Makineye atanmamış (station_id NULL) VEYA start_date girilmemiş
      ve tamamlanmamış/iptal edilmemiş (status 2,5,9 dışı)
      ============================================================ --->
<cfquery name="qUnplanned" datasource="boyahane">
    SELECT po.p_order_id,
           po.p_order_no,
           COALESCE(po.quantity, 0)             AS quantity,
           COALESCE(po.lot_no,'')               AS lot_no,
           COALESCE(ci.color_code,'')           AS color_code,
           COALESCE(ci.color_name,'')           AS color_name,
           COALESCE(c.nickname, c.fullname,'') AS company_name,
           COALESCE(s.stock_code,'')            AS stock_code,
           po.start_date,
           po.finish_date,
           po.station_id,
           COALESCE(ws.station_name,'')         AS station_name,
           COALESCE(po.status, 1)               AS status,
           COALESCE(po.is_urgent, false)        AS is_urgent
    FROM production_orders po
    LEFT JOIN stocks       s  ON po.stock_id   = s.stock_id
    LEFT JOIN color_info   ci ON po.stock_id   = ci.stock_id
    LEFT JOIN company      c  ON ci.company_id = c.company_id
    LEFT JOIN workstations ws ON po.station_id = ws.station_id
    WHERE (po.station_id IS NULL OR po.start_date IS NULL)
      AND COALESCE(po.status, 1) NOT IN (2, 5, 9)
    ORDER BY po.is_urgent DESC, po.p_order_id DESC
</cfquery>

<!--- ============================================================
      Planlanmış emirler — operasyon dakika toplamı + duruş bilgisi
      ============================================================ --->
<cfquery name="qPlanned" datasource="boyahane">
    SELECT po.p_order_id,
           po.p_order_no,
           COALESCE(po.quantity, 0)             AS quantity,
           COALESCE(po.lot_no,'')               AS lot_no,
           COALESCE(ci.color_code,'')           AS color_code,
           COALESCE(ci.color_name,'')           AS color_name,
           COALESCE(c.nickname, c.fullname,'') AS company_name,
           COALESCE(s.stock_code,'')            AS stock_code,
           po.start_date,
           po.finish_date,
           po.station_id,
           COALESCE(ws.station_name,'')         AS station_name,
           COALESCE(po.status, 1)               AS status,
           COALESCE(po.is_urgent, false)        AS is_urgent,
           /* Ürün ağacındaki operasyon dakikaları toplamı */
           COALESCE((
               SELECT SUM(COALESCE(po2.o_minute, 0))
               FROM production_operation po2
               WHERE po2.p_order_id = po.p_order_id
           ), 0) AS total_op_minutes,
           /* Aktif duruş var mı */
           COALESCE((
               SELECT COUNT(*)
               FROM setup_prod_pause sp
               WHERE sp.p_order_id = po.p_order_id
                 AND sp.duration_finish_date IS NULL
           ), 0) AS active_pause_count,
           /* Toplam duruş dakikası */
           COALESCE((
               SELECT SUM(COALESCE(sp.prod_duration, 0))
               FROM setup_prod_pause sp
               WHERE sp.p_order_id = po.p_order_id
           ), 0) AS total_pause_minutes
    FROM production_orders po
    LEFT JOIN stocks       s  ON po.stock_id   = s.stock_id
    LEFT JOIN color_info   ci ON po.stock_id   = ci.stock_id
    LEFT JOIN company      c  ON ci.company_id = c.company_id
    LEFT JOIN workstations ws ON po.station_id = ws.station_id
    WHERE po.station_id IS NOT NULL
      AND po.start_date IS NOT NULL
      AND po.status IN (1, 2)
    ORDER BY po.p_order_id DESC
</cfquery>

<!--- ============================================================
      Tüm istasyonlar (gruplar + makineler)
      ============================================================ --->
<cfquery name="qStations" datasource="boyahane">
    SELECT station_id,
           station_name,
           COALESCE(up_station, 0) AS up_station,
           COALESCE(capacity, 0)   AS capacity,
           COALESCE(active, false) AS active
    FROM workstations
    WHERE COALESCE(active, false) = true
    ORDER BY up_station, station_id
</cfquery>

<!--- Gruplar: up_station=0 (veya NULL) olan üst istasyonlar --->
<cfset groupsArr   = []>
<!--- Makineler: up_station>0 olan alt istasyonlar --->
<cfset machinesArr = []>

<cfloop query="qStations">
    <cfif val(up_station) eq 0>
        <!--- Bu bir grup --->
        <cfset arrayAppend(groupsArr, {
            "id"  : val(station_id),
            "text": station_name ?: ("Grup " & val(station_id))
        })>
    <cfelse>
        <!--- Bu gerçek bir makine --->
        <cfset arrayAppend(machinesArr, {
            "id"       : val(station_id),
            "text"     : station_name ?: ("Makina " & val(station_id)),
            "group_id" : val(up_station),
            "color"    : ""
        })>
    </cfif>
</cfloop>

<!--- ---- CF dizileri → JSON ---- --->
<cfset unplannedArr = []>
<cfloop query="qUnplanned">
    <cfset arrayAppend(unplannedArr, {
        "p_order_id"  : val(p_order_id),
        "p_order_no"  : p_order_no   ?: "",
        "quantity"    : isNumeric(quantity) ? val(quantity) : 0,
        "lot_no"      : lot_no       ?: "",
        "color_code"  : color_code   ?: "",
        "color_name"  : color_name   ?: "",
        "company_name": company_name ?: "",
        "stock_code"  : stock_code   ?: "",
        "station_id"  : val(station_id),
        "station_name": station_name ?: "",
        "status"      : val(status),
        "is_urgent"   : is_urgent,
        "start_date"  : isDate(start_date)  ? dateFormat(start_date, "yyyy-mm-dd")  & "T" & timeFormat(start_date,  "HH:mm:ss") : "",
        "finish_date" : isDate(finish_date) ? dateFormat(finish_date,"yyyy-mm-dd")  & "T" & timeFormat(finish_date, "HH:mm:ss") : ""
    })>
</cfloop>

<cfset plannedArr = []>
<cfloop query="qPlanned">
    <!--- Bitiş tarihi: start_date + operasyon toplamı (dk). Toplam 0 ise DB'deki finish_date kullan, o da yoksa +8 saat --->
    <cfset sDate    = isDate(start_date) ? start_date : now()>
    <cfset opMins   = isNumeric(total_op_minutes) ? val(total_op_minutes) : 0>
    <cfif opMins gt 0>
        <cfset fDate = dateAdd("n", opMins, sDate)>
    <cfelseif isDate(finish_date)>
        <cfset fDate = finish_date>
    <cfelse>
        <cfset fDate = dateAdd("h", 8, sDate)>
    </cfif>
    <cfset arrayAppend(plannedArr, {
        "p_order_id"         : val(p_order_id),
        "p_order_no"         : p_order_no   ?: "",
        "quantity"           : isNumeric(quantity) ? val(quantity) : 0,
        "lot_no"             : lot_no       ?: "",
        "color_code"         : color_code   ?: "",
        "color_name"         : color_name   ?: "",
        "company_name"       : company_name ?: "",
        "stock_code"         : stock_code   ?: "",
        "station_id"         : val(station_id),
        "station_name"       : station_name ?: "",
        "status"             : val(status),
        "is_urgent"          : is_urgent,
        "total_op_minutes"   : opMins,
        "active_pause_count" : isNumeric(active_pause_count) ? val(active_pause_count) : 0,
        "total_pause_minutes": isNumeric(total_pause_minutes) ? val(total_pause_minutes) : 0,
        "startDate"          : dateFormat(sDate,"yyyy-mm-dd") & "T" & timeFormat(sDate, "HH:mm:ss"),
        "endDate"            : dateFormat(fDate,"yyyy-mm-dd") & "T" & timeFormat(fDate, "HH:mm:ss"),
        "text"               : (p_order_no ?: "Emir") & " | " & (color_code ?: "") & " " & (color_name ?: ""),
        "resourceId"         : val(station_id)
    })>
</cfloop>

<!--- stationsArr artık machinesArr'dan geliyor (gruplar dahil değil) --->

<cfoutput>
<!--- Bağımlılıkları dinamik yükle (ajaxpage modunda layout head devreye girmeyebilir) --->
<script>
(function() {
    function addLink(href) {
        var l = document.createElement('link');
        l.rel = 'stylesheet'; l.href = href;
        document.head.appendChild(l);
    }
    function addScript(src, onload) {
        var s = document.createElement('script');
        s.src = src;
        if (onload) s.onload = onload;
        document.head.appendChild(s);
    }
    if (typeof jQuery === 'undefined') {
        addScript('https://code.jquery.com/jquery-3.7.1.min.js', function() {
            addScript('https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js');
            if (typeof DevExpress === 'undefined') {
                addLink('https://cdn3.devexpress.com/jslib/23.2.5/css/dx.common.css');
                addLink('https://cdn3.devexpress.com/jslib/23.2.5/css/dx.light.css');
                addScript('https://cdn3.devexpress.com/jslib/23.2.5/js/dx.all.js');
            }
        });
    } else if (typeof DevExpress === 'undefined') {
        addLink('https://cdn3.devexpress.com/jslib/23.2.5/css/dx.common.css');
        addLink('https://cdn3.devexpress.com/jslib/23.2.5/css/dx.light.css');
        addScript('https://cdn3.devexpress.com/jslib/23.2.5/js/dx.all.js');
    }
}());
</script>
<!--- ================================================================
      STYLES
      ================================================================ --->
<style>
/* ---- Layout ------------------------------------------------------- */
.planner-wrapper {
    display: flex;
    flex-direction: column;
    height: calc(100vh - 80px);
    overflow: hidden;
    padding: 0;
}

/* ---- Top bar ------------------------------------------------------ */
.planner-topbar {
    display: flex;
    align-items: center;
    gap: .75rem;
    padding: .75rem 1.25rem;
    background: ##fff;
    border-bottom: 1px solid ##e2e8f0;
    flex-shrink: 0;
}
.planner-topbar .topbar-icon {
    width: 40px; height: 40px;
    border-radius: 10px;
    background: linear-gradient(135deg, ##1e40af, ##3b82f6);
    display: flex; align-items: center; justify-content: center;
    color: ##fff; font-size: 1rem; flex-shrink: 0;
}
.planner-topbar h1 { margin: 0; font-size: 1.25rem; font-weight: 700; color: ##1e293b; }
.planner-topbar p  { margin: 0; font-size: .75rem; color: ##64748b; }
.planner-topbar .ms-auto { margin-left: auto; display: flex; gap: .5rem; align-items: center; }

/* ---- Group filter ------------------------------------------------- */
.group-filter-wrap {
    display: flex;
    align-items: center;
    gap: .4rem;
    background: ##f1f5f9;
    border: 1.5px solid ##cbd5e1;
    border-radius: 8px;
    padding: .28rem .6rem;
}
.group-filter-wrap label {
    font-size: .75rem;
    font-weight: 600;
    color: ##64748b;
    white-space: nowrap;
    margin: 0;
}
.group-filter-wrap select {
    border: none;
    background: transparent;
    font-size: .82rem;
    color: ##1e293b;
    outline: none;
    cursor: pointer;
    padding: 0 .25rem;
}
.group-filter-wrap select:focus { outline: none; }

/* ---- Main split --------------------------------------------------- */
.planner-body {
    display: flex;
    flex: 1;
    overflow: hidden;
    gap: 0;
}

/* ---- Left panel: unplanned orders --------------------------------- */
.orders-panel {
    width: 280px;
    min-width: 240px;
    max-width: 320px;
    display: flex;
    flex-direction: column;
    background: ##f8fafc;
    border-right: 2px solid ##e2e8f0;
    overflow: hidden;
    flex-shrink: 0;
}
.orders-panel-header {
    padding: .6rem .75rem;
    background: ##1e293b;
    color: ##fff;
    font-size: .8rem;
    font-weight: 600;
    display: flex;
    align-items: center;
    gap: .5rem;
    flex-shrink: 0;
}
.orders-panel-header .badge-count {
    margin-left: auto;
    background: ##3b82f6;
    color: ##fff;
    border-radius: 12px;
    padding: 2px 8px;
    font-size: .72rem;
}
.orders-search {
    padding: .5rem .5rem;
    border-bottom: 1px solid ##e2e8f0;
    flex-shrink: 0;
}
.orders-search input {
    width: 100%;
    padding: .4rem .65rem;
    border: 1.5px solid ##cbd5e1;
    border-radius: 8px;
    font-size: .8rem;
    outline: none;
    box-sizing: border-box;
}
.orders-search input:focus { border-color: ##3b82f6; }

.orders-list {
    flex: 1;
    overflow-y: auto;
    padding: .4rem;
    display: flex;
    flex-direction: column;
    gap: .35rem;
}

/* ---- Order card --------------------------------------------------- */
.order-card {
    background: ##fff;
    border: 1.5px solid ##e2e8f0;
    border-left: 4px solid ##3b82f6;
    border-radius: 8px;
    padding: .5rem .65rem;
    cursor: grab;
    user-select: none;
    transition: box-shadow .15s, border-color .15s, opacity .15s;
    font-size: .78rem;
}
.order-card:hover { box-shadow: 0 3px 10px rgba(0,0,0,.12); border-color: ##93c5fd; }
.order-card.urgent { border-left-color: ##ef4444; }
.order-card.dragging { opacity: .45; box-shadow: none; cursor: grabbing; }

.order-card .oc-no   { font-weight: 700; color: ##1e293b; font-size: .82rem; }
.order-card .oc-info { color: ##64748b; margin-top: 2px; line-height: 1.4; }
.order-card .oc-qty  {
    display: inline-block;
    margin-top: 4px;
    background: ##eff6ff;
    color: ##1d4ed8;
    border-radius: 6px;
    padding: 1px 7px;
    font-weight: 600;
    font-size: .74rem;
}
.order-card .oc-urgent-badge {
    display: inline-block;
    margin-left: 4px;
    background: ##fee2e2;
    color: ##b91c1c;
    border-radius: 6px;
    padding: 1px 6px;
    font-weight: 600;
    font-size: .7rem;
}

/* ---- Right panel: scheduler --------------------------------------- */
.scheduler-panel {
    flex: 1;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    background: ##fff;
}
.scheduler-panel-header {
    padding: .55rem 1rem;
    background: ##f1f5f9;
    border-bottom: 1px solid ##e2e8f0;
    font-size: .8rem;
    font-weight: 600;
    color: ##475569;
    display: flex;
    align-items: center;
    gap: .5rem;
    flex-shrink: 0;
}
.scheduler-panel-header .view-btns { margin-left: auto; display: flex; gap: .4rem; }
.scheduler-panel-header .view-btns button {
    padding: .28rem .7rem;
    border: 1px solid ##cbd5e1;
    border-radius: 6px;
    background: ##fff;
    font-size: .75rem;
    cursor: pointer;
    color: ##475569;
    transition: all .15s;
}
.scheduler-panel-header .view-btns button.active,
.scheduler-panel-header .view-btns button:hover {
    background: ##1e40af; color: ##fff; border-color: ##1e40af;
}

##schedulerContainer {
    flex: 1;
    overflow: hidden;
}

/* ---- Drop overlay -------------------------------------------------  */
.drop-zone-overlay {
    position: absolute;
    inset: 0;
    background: rgba(59, 130, 246, .08);
    border: 3px dashed ##3b82f6;
    border-radius: 10px;
    display: none;
    align-items: center;
    justify-content: center;
    color: ##1d4ed8;
    font-weight: 600;
    font-size: 1rem;
    pointer-events: none;
    z-index: 9999;
}
.drop-zone-overlay.visible { display: flex; }

/* ---- Plan modal --------------------------------------------------- */
##planModal .modal-header { background: ##1e293b; color: ##fff; }
##planModal .modal-header .btn-close { filter: invert(1); }
.form-label-sm { font-size: .8rem; font-weight: 600; color: ##374151; margin-bottom: .2rem; }
.form-control-sm-custom {
    width: 100%; padding: .45rem .65rem;
    border: 1.5px solid ##cbd5e1; border-radius: 8px;
    font-size: .85rem; outline: none;
}
.form-control-sm-custom:focus { border-color: ##3b82f6; }
</style>

<!--- ================================================================
      HTML
      ================================================================ --->
<div class="planner-wrapper">

    <!--- Top bar --->
    <div class="planner-topbar">
        <div class="topbar-icon"><i class="fas fa-calendar-alt"></i></div>
        <div>
            <h1>Üretim Planlama</h1>
            <p>Planlanmamış emirleri makinalara sürükleyip bırakarak planlayın</p>
        </div>
        <div class="ms-auto">
            <div class="group-filter-wrap">
                <label><i class="fas fa-layer-group me-1"></i>Grup:</label>
                <select id="groupFilter" onchange="applyGroupFilter(this.value)">
                    <option value="0">— Tümü —</option>
                </select>
            </div>
            <span id="unplannedBadge" class="badge bg-warning text-dark">
                <i class="fas fa-clock me-1"></i><span id="unplannedCount">0</span> Planlanmamış
            </span>
            <button class="btn btn-sm btn-outline-secondary" onclick="refreshPage()" title="Yenile">
                <i class="fas fa-sync-alt"></i>
            </button>
        </div>
    </div>

    <!--- Body --->
    <div class="planner-body">

        <!--- LEFT: unplanned orders panel --->
        <div class="orders-panel">
            <div class="orders-panel-header">
                <i class="fas fa-inbox"></i>Planlanmamış Emirler
                <span class="badge-count" id="panelCount">0</span>
            </div>
            <div class="orders-search">
                <input type="text" id="orderSearch" placeholder="Ara (renk, emir no, lot...)" oninput="filterOrders(this.value)">
            </div>
            <div class="orders-list" id="ordersList" ondragover="event.preventDefault()" ondrop="handleDropToUnplanned(event)">
                <!--- JS ile dolacak --->
            </div>
        </div>

        <!--- RIGHT: scheduler --->
        <div class="scheduler-panel">
            <div class="scheduler-panel-header">
                <i class="fas fa-calendar-week"></i>Makina Planlaması
                <span style="color:##94a3b8;font-weight:400;font-size:.75rem;margin-left:.4rem">
                    — Emri sürükleyip makina satırına bırakın, tarih/saat ayarlayın
                </span>
                <div class="view-btns">
                    <button id="btnDay"   onclick="switchView('timelineDay')"   class="active">Günlük</button>
                    <button id="btnWeek"  onclick="switchView('timelineWeek')"          >Haftalık</button>
                    <button id="btnMonth" onclick="switchView('timelineMonth')"         >Aylık</button>
                </div>
            </div>
            <div style="position:relative;flex:1;overflow:hidden;">
                <div id="schedulerContainer"></div>
                <div class="drop-zone-overlay" id="dropOverlay">
                    <i class="fas fa-arrow-down me-2"></i>Emri buraya bırakın
                </div>
            </div>
        </div>

    </div>
</div>

<!--- ================================================================
      PLAN MODAL
      ================================================================ --->
<div class="modal fade" id="planModal" tabindex="-1" aria-labelledby="planModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="planModalLabel"><i class="fas fa-calendar-plus me-2"></i>Planlama Onayı</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="row g-3">
                    <div class="col-12">
                        <div class="p-3 rounded" style="background:##f8fafc;border:1px solid ##e2e8f0;">
                            <div style="font-size:.85rem;font-weight:700;color:##1e293b;" id="modalOrderTitle">-</div>
                            <div style="font-size:.78rem;color:##64748b;margin-top:2px;" id="modalOrderSub">-</div>
                        </div>
                    </div>
                    <div class="col-12">
                        <label class="form-label-sm">Makina</label>
                        <select class="form-control-sm-custom" id="modalStation"></select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label-sm">Başlangıç Tarihi / Saati</label>
                        <input type="datetime-local" class="form-control-sm-custom" id="modalStartDate">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label-sm">Bitiş Tarihi / Saati</label>
                        <input type="datetime-local" class="form-control-sm-custom" id="modalEndDate">
                    </div>
                    <div class="col-12">
                        <label class="form-label-sm">Durum</label>
                        <select class="form-control-sm-custom" id="modalStatus">
                            <option value="0">Bekliyor</option>
                            <option value="1" selected>Planlandı</option>
                            <option value="2">Devam Ediyor</option>
                        </select>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary btn-sm" data-bs-dismiss="modal">İptal</button>
                <button class="btn btn-primary btn-sm" id="btnSavePlan" onclick="savePlan()">
                    <i class="fas fa-save me-1"></i>Planla
                </button>
            </div>
        </div>
    </div>
</div>

<!--- ================================================================
      SCRIPT
      ================================================================ --->
<script>
/* ---- raw data from CF --------------------------------------------- */
var RAW_UNPLANNED = #serializeJSON(unplannedArr)#;
var RAW_PLANNED   = #serializeJSON(plannedArr)#;
var ALL_STATIONS  = #serializeJSON(machinesArr)#;  /* sadece gerçek makineler */
var GROUPS        = #serializeJSON(groupsArr)#;    /* üst istasyon grupları */

/* ---- state --------------------------------------------------------- */
var unplannedList  = [];   // filtered working copy
var schedulerInst  = null;
var dragItem       = null; // order being dragged from left panel
var pendingDrop    = null; // { order, stationId, startDate, endDate }
var currentView    = 'timelineDay';
var planModalBs    = null;
var activeGroupId  = 0;    // 0 = tümü

/* ---- palette for machines ----------------------------------------- */
var PALETTE = [
    '##3b82f6','##10b981','##f59e0b','##ef4444','##8b5cf6',
    '##ec4899','##14b8a6','##f97316','##6366f1','##84cc16'
];
ALL_STATIONS.forEach(function(s, i) {
    s.color = PALETTE[i % PALETTE.length];
});

/* filtrelenmiş aktif makine listesi (gruba göre) */
function getActiveStations() {
    if (!activeGroupId) return ALL_STATIONS;
    return ALL_STATIONS.filter(function(s) { return s.group_id === activeGroupId; });
}

/* aktif istasyona ait appointment'lar */
function getActiveAppointments() {
    var ids = getActiveStations().map(function(s){ return s.id; });
    return ALL_APPOINTMENTS.filter(function(a) { return ids.indexOf(a.resourceId) !== -1; });
}

var ALL_APPOINTMENTS = [];

/* ================================================================
   Init — deps yoksa 50ms aralıklarla bekle
   ================================================================ */
(function poll() {
    if (typeof jQuery === 'undefined' ||
        typeof DevExpress === 'undefined' ||
        typeof bootstrap === 'undefined' ||
        typeof bootstrap.Modal !== 'function') {
        setTimeout(poll, 50);
        return;
    }
    DevExpress.localization.locale('tr');

    /* Grup filtresi populate */
    var gsel = document.getElementById('groupFilter');
    GROUPS.forEach(function(g) {
        var opt = document.createElement('option');
        opt.value = g.id;
        opt.textContent = g.text;
        gsel.appendChild(opt);
    });

    /* Eğer hiç grup yoksa filtre alanını gizle */
    if (!GROUPS.length) {
        var fw = document.querySelector('.group-filter-wrap');
        if (fw) fw.style.display = 'none';
    }

    /* ALL_APPOINTMENTS doldur */
    ALL_APPOINTMENTS = buildAppointments();

    unplannedList = RAW_UNPLANNED.slice();
    renderOrderCards(unplannedList);
    updateCounts();
    buildScheduler();

    /* Bootstrap modal instance */
    planModalBs = new bootstrap.Modal(document.getElementById('planModal'));

    /* Modal makine seçimi doldur (tüm makineler) */
    populateModalStations(ALL_STATIONS);
}());

function populateModalStations(list) {
    var sel = document.getElementById('modalStation');
    sel.innerHTML = '<option value="">— Makina Seçin —</option>';
    list.forEach(function(s) {
        var opt = document.createElement('option');
        opt.value = s.id;
        opt.textContent = s.text;
        sel.appendChild(opt);
    });
}

/* Grup filtresi değişince scheduler'ı yeniden kur */
function applyGroupFilter(val) {
    activeGroupId = parseInt(val, 10) || 0;

    /* Modal makine listesini güncelle */
    populateModalStations(getActiveStations());

    /* Scheduler'ı yeniden oluştur */
    if (schedulerInst) {
        schedulerInst.dispose();
        schedulerInst = null;
    }
    document.getElementById('schedulerContainer').innerHTML = '';
    buildScheduler();
}

/* ================================================================
   Left panel — order cards
   ================================================================ */
function renderOrderCards(list) {
    var container = document.getElementById('ordersList');
    container.innerHTML = '';

    if (!list || list.length === 0) {
        container.innerHTML = '<div style="text-align:center;color:##94a3b8;padding:2rem;font-size:.8rem;">'
            + '<i class="fas fa-check-circle" style="font-size:1.5rem;color:##10b981;display:block;margin-bottom:.5rem;"></i>'
            + 'Tüm emirler planlandı!</div>';
        return;
    }

    list.forEach(function(order) {
        var card = document.createElement('div');
        card.className = 'order-card' + (order.is_urgent ? ' urgent' : '');
        card.draggable = true;
        card.dataset.id = order.p_order_id;

        card.innerHTML =
            '<div class="oc-no">' + htmlEnc(order.p_order_no || ('Emir ##' + order.p_order_id))
                + (order.is_urgent ? '<span class="oc-urgent-badge">ACİL</span>' : '') + '</div>'
            + '<div class="oc-info">'
                + '<b>' + htmlEnc(order.color_code) + '</b>'
                + (order.color_name ? ' — ' + htmlEnc(order.color_name) : '')
                + '<br>' + htmlEnc(order.company_name || '')
                + (order.lot_no ? ' · Lot: ' + htmlEnc(order.lot_no) : '')
            + '</div>'
            + '<span class="oc-qty">' + fmtQty(order.quantity) + ' kg</span>';

        card.addEventListener('dragstart', function(e) {
            dragItem = order;
            card.classList.add('dragging');
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', String(order.p_order_id));
        });
        card.addEventListener('dragend', function() {
            card.classList.remove('dragging');
        });

        /* click to plan via modal */
        card.addEventListener('click', function() {
            openPlanModal(order, null, null, null);
        });

        container.appendChild(card);
    });
}

function filterOrders(q) {
    q = (q || '').toLowerCase().trim();
    var filtered = RAW_UNPLANNED.filter(function(o) {
        if (!q) return true;
        return (o.p_order_no  || '').toLowerCase().includes(q)
            || (o.color_code  || '').toLowerCase().includes(q)
            || (o.color_name  || '').toLowerCase().includes(q)
            || (o.company_name || '').toLowerCase().includes(q)
            || (o.lot_no      || '').toLowerCase().includes(q);
    });
    unplannedList = filtered;
    renderOrderCards(filtered);
}

function updateCounts() {
    var n = RAW_UNPLANNED.length;
    document.getElementById('unplannedCount').textContent = n;
    document.getElementById('panelCount').textContent     = n;
}

/* ================================================================
   DevExtreme Scheduler
   ================================================================ */
function buildScheduler() {
    var stations     = getActiveStations();
    var appointments = getActiveAppointments();

    schedulerInst = $('##schedulerContainer').dxScheduler({
        dataSource       : appointments,
        views            : ['timelineDay','timelineWeek','timelineMonth'],
        currentView      : currentView,
        currentDate      : new Date(),
        height           : '100%',
        startDayHour     : 6,
        endDayHour       : 22,
        cellDuration     : 30,
        showAllDayPanel  : false,
        crossScrollingEnabled: true,
        groups           : ['resourceId'],
        resources: [{
            fieldExpr    : 'resourceId',
            dataSource   : stations,
            label        : 'Makina',
            useColorAsDefault: true
        }],
        appointmentTemplate: appointmentTpl,
        onAppointmentDblClick: function(e) {
            e.cancel = true;
            openEditModal(e.appointmentData);
        },
        onAppointmentUpdated: function(e) {
            syncAppointmentUpdate(e.appointmentData);
        },
        onAppointmentDeleted: function(e) {
            moveBackToUnplanned(e.appointmentData.p_order_id);
        },
        editing: {
            allowAdding   : false,
            allowDeleting : true,
            allowUpdating : true,
            allowResizing : false,
            allowDragging : true
        }
    }).dxScheduler('instance');

    /* ---- drag-over / drop on scheduler panel ---- */
    var schedulerEl = document.getElementById('schedulerContainer');
    var dropOverlay = document.getElementById('dropOverlay');

    schedulerEl.addEventListener('dragover', function(e) {
        if (!dragItem) return;
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
        dropOverlay.classList.add('visible');
    });
    schedulerEl.addEventListener('dragleave', function(e) {
        if (!schedulerEl.contains(e.relatedTarget)) {
            dropOverlay.classList.remove('visible');
        }
    });
    schedulerEl.addEventListener('drop', function(e) {
        e.preventDefault();
        dropOverlay.classList.remove('visible');
        if (!dragItem) return;

        /* Bırakılan hücreden makine + tarih bilgisini al, direk kaydet */
        var info = getDropInfo(e, schedulerInst);
        var order = dragItem;
        dragItem = null;
        directSavePlan(order, info.stationId, info.startDate, info.endDate);
    });
}

function buildAppointments() {
    return RAW_PLANNED.map(function(o) {
        return {
            p_order_id       : o.p_order_id,
            text             : o.text || (o.p_order_no + ' | ' + o.color_code + ' ' + o.color_name),
            startDate        : new Date(o.startDate),
            endDate          : new Date(o.endDate),
            resourceId       : o.station_id,
            color_code       : o.color_code,
            color_name       : o.color_name,
            company_name     : o.company_name,
            quantity         : o.quantity,
            lot_no           : o.lot_no,
            status           : o.status,
            total_op_minutes : o.total_op_minutes  || 0,
            active_pause_count: o.active_pause_count || 0,
            total_pause_minutes: o.total_pause_minutes || 0
        };
    });
}

/* ALL_APPOINTMENTS dizisine yeni appointment ekle/güncelle (grup filtresi sonrası kaybolmasın) */
function upsertAllAppointment(appt) {
    var idx = ALL_APPOINTMENTS.findIndex(function(a){ return a.p_order_id === appt.p_order_id; });
    if (idx >= 0) ALL_APPOINTMENTS[idx] = appt;
    else ALL_APPOINTMENTS.push(appt);
}

function removeAllAppointment(id) {
    ALL_APPOINTMENTS = ALL_APPOINTMENTS.filter(function(a){ return a.p_order_id !== id; });
}

var STATUS_META = {
    1: { label: 'Planlandı',    bg: '##1976d2', fg: '##fff' },
    2: { label: 'Çalışıyor',   bg: '##2e7d32', fg: '##fff' },
    5: { label: 'Tamamlandı',  bg: '##757575', fg: '##fff' },
    9: { label: 'İptal',       bg: '##b71c1c', fg: '##fff' }
};

function fmtMins(mins) {
    if (!mins) return '';
    var h = Math.floor(mins / 60), m = mins % 60;
    return h ? (h + 's ' + (m ? m + 'dk' : '')) : (m + 'dk');
}

function appointmentTpl(model) {
    var data   = model.appointmentData;
    var st     = STATUS_META[data.status] || { label: 'Bilinmiyor', bg: '##9e9e9e', fg: '##fff' };
    var pauseHtml = (data.active_pause_count > 0)
        ? '<span style="background:##e65100;color:##fff;border-radius:3px;padding:1px 4px;font-size:.68rem;margin-left:4px;">&##9646;&##9646; Duruşta</span>'
        : '';
    var durationHtml = data.total_op_minutes
        ? '<span style="font-size:.68rem;opacity:.8;margin-left:4px;">⏱ ' + fmtMins(data.total_op_minutes) + '</span>'
        : '';
    return $('<div style="padding:3px 5px;overflow:hidden;line-height:1.4;">'
        + '<div style="font-weight:700;font-size:.78rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">'
            + htmlEnc(data.text || '')
        + '</div>'
        + '<div style="font-size:.72rem;opacity:.85;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">'
            + htmlEnc(data.company_name || '') + ' · ' + fmtQty(data.quantity) + ' kg'
        + '</div>'
        + '<div style="margin-top:2px;">'
            + '<span style="background:' + st.bg + ';color:' + st.fg + ';border-radius:3px;padding:1px 5px;font-size:.68rem;">' + st.label + '</span>'
            + pauseHtml + durationHtml
        + '</div>'
        + '</div>');
}

function switchView(view) {
    currentView = view;
    if (schedulerInst) schedulerInst.option('currentView', view);
    document.querySelectorAll('.view-btns button').forEach(function(b) { b.classList.remove('active'); });
    var map = { 'timelineDay': 'btnDay', 'timelineWeek': 'btnWeek', 'timelineMonth': 'btnMonth' };
    var el = document.getElementById(map[view]);
    if (el) el.classList.add('active');
}

/* ================================================================
   Drop position → station + date resolution
   Timeline scheduler'da getCellData() groups'u güvenilir dönürmez.
   Bunun yerine:
     - STASYOn: bırakılan Y'yi, resource header satır yükseklikleriyle karşılaştır
     - TARİH  : bırakılan X'i, date-table hücresi konumlarıyla karşılaştır
   ================================================================ */
function getDropInfo(ev, inst) {
    var result = { stationId: null, startDate: null, endDate: null };

    try {
        /* ---- 1. Stasyon: Y koordinatından makine satırını bul ---- */
        var activeStations = getActiveStations();

        /* Timeline'da her kaynak için bir satır var; header hücrelerinden
           satır yüksekliklerini oku (dx-scheduler-group-header-content veya
           dx-scheduler-header-panel-cell) */
        var resourceRows = document.querySelectorAll(
            '##schedulerContainer .dx-scheduler-group-row .dx-scheduler-group-header,' +
            '##schedulerContainer .dx-scheduler-date-table-row'
        );

        /* En güvenilir yol: date-table row'larının Y aralıklarına göre index bul */
        var tableRows = document.querySelectorAll(
            '##schedulerContainer .dx-scheduler-date-table-row'
        );

        var rowIndex = -1;
        for (var i = 0; i < tableRows.length; i++) {
            var rect = tableRows[i].getBoundingClientRect();
            if (ev.clientY >= rect.top && ev.clientY < rect.bottom) {
                rowIndex = i;
                break;
            }
        }

        if (rowIndex >= 0 && rowIndex < activeStations.length) {
            result.stationId = activeStations[rowIndex].id;
        }

        /* ---- 2. Tarih: X koordinatından hücreyi bul ---- */
        /* Önce tam olarak hangi hücrenin üzerinde olduğumuzu bul */
        var el = document.elementFromPoint(ev.clientX, ev.clientY);
        while (el && !el.classList.contains('dx-scheduler-date-table-cell')
                  && el !== document.body) {
            el = el.parentElement;
        }

        if (el && el.classList.contains('dx-scheduler-date-table-cell')) {
            /* getCellData sadece tarih için burada çalışıyor */
            try {
                var cd = inst.getCellData(el);
                if (cd && cd.startDate) {
                    result.startDate = cd.startDate;
                    result.endDate   = new Date(cd.startDate.getTime() + 8 * 3600000);
                }
            } catch(e2) { /* ignore, fallback below */ }

            /* getCellData çalışmazsa: hücrenin kolon sırasını bul → currentDate + cellDuration hesapla */
            if (!result.startDate) {
                var allCells = el.parentElement ? el.parentElement.querySelectorAll('.dx-scheduler-date-table-cell') : [];
                var colIdx = Array.prototype.indexOf.call(allCells, el);
                if (colIdx >= 0) {
                    var baseDate  = new Date(inst.option('currentDate'));
                    var startHour = inst.option('startDayHour') || 0;
                    var cellDur   = inst.option('cellDuration')  || 60; /* dakika */
                    var view      = inst.option('currentView') || 'timelineDay';

                    if (view === 'timelineDay') {
                        baseDate.setHours(startHour, 0, 0, 0);
                        baseDate = new Date(baseDate.getTime() + colIdx * cellDur * 60000);
                    } else if (view === 'timelineWeek') {
                        /* haftanın başı pazartesi */
                        var dow = baseDate.getDay() || 7;
                        baseDate.setDate(baseDate.getDate() - dow + 1);
                        baseDate.setHours(startHour, 0, 0, 0);
                        baseDate = new Date(baseDate.getTime() + colIdx * cellDur * 60000);
                    } else {
                        /* month: sadece gün seviyesi */
                        baseDate.setDate(1);
                        baseDate.setHours(0, 0, 0, 0);
                        baseDate.setDate(baseDate.getDate() + colIdx);
                    }
                    result.startDate = baseDate;
                    result.endDate   = new Date(baseDate.getTime() + 8 * 3600000);
                }
            }
        }
    } catch(err) { /* ignore */ }

    /* ---- Fallback ---- */
    if (!result.startDate) {
        result.startDate = new Date();
        result.startDate.setMinutes(0, 0, 0);
        result.endDate = new Date(result.startDate.getTime() + 8 * 3600000);
    }
    if (!result.stationId) {
        var sts = getActiveStations();
        if (sts.length) result.stationId = sts[0].id;
    }
    return result;
}

/* ================================================================
   Direkt kayıt — modal açmadan sürükle-bırak sonucu planla
   ================================================================ */
function directSavePlan(order, stationId, startDate, endDate) {
    if (!stationId) {
        showToast('Makina belirlenemedi, lütfen emri bir makine satırına bırakın.', 'danger');
        return;
    }

    var sd  = startDate instanceof Date ? startDate : new Date();
    var ed  = endDate   instanceof Date ? endDate   : new Date(sd.getTime() + 8 * 3600000);

    /* Scheduler üzerinde geçici bir yükleniyor göstergesi */
    showToast('Planlanıyor...', 'info');

    $.ajax({
        url    : '/production/form/save_plan.cfm',
        method : 'POST',
        data   : {
            p_order_id : order.p_order_id,
            station_id : stationId,
            start_date : fmtDTForServer(sd),
            finish_date: fmtDTForServer(ed),
            status     : 1
        },
        dataType: 'json',
        success : function(resp) {
            if (resp && resp.success) {
                /* Sunucudan dönen tarihleri kullan (auto-snap veya op-dakika hesaplı) */
                var serverStart = (resp.start_date && isValidDateStr(resp.start_date))
                                ? new Date(resp.start_date.replace('T', ' '))
                                : sd;
                var serverEnd = (resp.finish_date && isValidDateStr(resp.finish_date))
                                ? new Date(resp.finish_date.replace('T', ' '))
                                : ed;
                var newAppt = {
                    p_order_id       : order.p_order_id,
                    text             : (order.p_order_no || ('Emir ##' + order.p_order_id)) + ' | ' + (order.color_code || '') + ' ' + (order.color_name || ''),
                    startDate        : serverStart,
                    endDate          : serverEnd,
                    resourceId       : stationId,
                    color_code       : order.color_code   || '',
                    color_name       : order.color_name   || '',
                    company_name     : order.company_name || '',
                    quantity         : order.quantity     || 0,
                    lot_no           : order.lot_no       || '',
                    status           : 1,
                    total_op_minutes : resp.total_op_minutes || 0,
                    active_pause_count: 0,
                    total_pause_minutes: 0
                };
                removeFromUnplanned(order.p_order_id);
                upsertAllAppointment(newAppt);

                /* Scheduler'a ekle (aktif grupta görünüyorsa) */
                var inActiveGroup = getActiveStations().some(function(s){ return s.id === stationId; });
                if (inActiveGroup) {
                    var ds = schedulerInst.option('dataSource');
                    var existing = ds.find(function(a){ return a.p_order_id === order.p_order_id; });
                    if (existing) schedulerInst.updateAppointment(existing, newAppt);
                    else          schedulerInst.addAppointment(newAppt);
                }
                var stObj = getActiveStations().find(function(s){ return s.id === stationId; })
                         || ALL_STATIONS.find(function(s){ return s.id === stationId; });
                var snapNote = resp.snapped ? ' (başlangıç kaydırıldı: ' + serverStart.toLocaleTimeString('tr-TR',{hour:'2-digit',minute:'2-digit'}) + ')' : '';
                showToast('Planlandı: ' + (order.p_order_no || 'Emir ##' + order.p_order_id)
                    + (stObj ? ' → ' + stObj.text : '') + snapNote, 'success');
            } else {
                showToast((resp && resp.message) || 'Kayıt hatası!', 'danger');
            }
        },
        error: function() {
            showToast('Sunucu hatası, lütfen tekrar deneyin.', 'danger');
        }
    });
}

/* ================================================================
   Plan Modal (kart tıklama + çift tıklama düzenleme için)
   ================================================================ */
function openPlanModal(order, stationId, startDate, endDate) {
    pendingDrop = { order: order, stationId: stationId, startDate: startDate, endDate: endDate };

    document.getElementById('modalOrderTitle').textContent =
        (order.p_order_no || ('Emir ##' + order.p_order_id))
        + ' — ' + (order.color_code || '') + ' ' + (order.color_name || '');
    document.getElementById('modalOrderSub').textContent =
        (order.company_name || '') + (order.lot_no ? ' · Lot: ' + order.lot_no : '')
        + ' · ' + fmtQty(order.quantity) + ' kg';

    /* station select */
    var sel = document.getElementById('modalStation');
    if (stationId) sel.value = stationId;

    /* dates */
    var sd = startDate || new Date();
    sd.setMinutes(0,0,0);
    var ed = endDate || new Date(sd.getTime() + 8 * 3600000);
    document.getElementById('modalStartDate').value = toLocalDTInput(sd);
    document.getElementById('modalEndDate').value   = toLocalDTInput(ed);
    document.getElementById('modalStatus').value    = '1';

    planModalBs.show();
}

function openEditModal(apptData) {
    /* Re-use plan modal for editing existing scheduled appointment */
    var fakeOrder = {
        p_order_id  : apptData.p_order_id,
        p_order_no  : apptData.text ? apptData.text.split(' | ')[0] : ('Emir ##' + apptData.p_order_id),
        color_code  : apptData.color_code  || '',
        color_name  : apptData.color_name  || '',
        company_name: apptData.company_name|| '',
        lot_no      : apptData.lot_no      || '',
        quantity    : apptData.quantity    || 0
    };
    openPlanModal(fakeOrder, apptData.resourceId, apptData.startDate, apptData.endDate);
    document.getElementById('modalStatus').value = apptData.status || 1;
}

function savePlan() {
    if (!pendingDrop) return;

    var stationId = parseInt(document.getElementById('modalStation').value, 10);
    var startVal  = document.getElementById('modalStartDate').value;
    var endVal    = document.getElementById('modalEndDate').value;
    var statusVal = parseInt(document.getElementById('modalStatus').value, 10);

    if (!stationId || isNaN(stationId)) {
        alert('Lütfen makina seçin.'); return;
    }
    if (!startVal) { alert('Başlangıç tarihi zorunludur.'); return; }

    var startDate = new Date(startVal);
    var endDate   = endVal ? new Date(endVal) : new Date(startDate.getTime() + 8 * 3600000);
    if (endDate <= startDate) {
        alert('Bitiş tarihi başlangıçtan büyük olmalıdır.'); return;
    }

    var order = pendingDrop.order;
    var btn   = document.getElementById('btnSavePlan');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner-border spinner-border-sm me-1"></span>Kaydediliyor...';

    $.ajax({
        url    : '/production/form/save_plan.cfm',
        method : 'POST',
        data   : {
            p_order_id : order.p_order_id,
            station_id : stationId,
            start_date : startVal.replace('T',' '),
            finish_date: endVal.replace('T',' '),
            status     : statusVal
        },
        dataType: 'json',
        success : function(resp) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-1"></i>Planla';

            if (resp && resp.success) {
                planModalBs.hide();
                /* update scheduler */
                var stationObj = getActiveStations().find(function(s){ return s.id === stationId; })
                              || ALL_STATIONS.find(function(s){ return s.id === stationId; });
                var newAppt = {
                    p_order_id  : order.p_order_id,
                    text        : (order.p_order_no || ('Emir ##' + order.p_order_id)) + ' | ' + order.color_code + ' ' + order.color_name,
                    startDate   : startDate,
                    endDate     : endDate,
                    resourceId  : stationId,
                    color_code  : order.color_code,
                    color_name  : order.color_name,
                    company_name: order.company_name,
                    quantity    : order.quantity,
                    lot_no      : order.lot_no,
                    status      : statusVal
                };

                /* remove from unplanned if already there */
                removeFromUnplanned(order.p_order_id);

                /* ALL_APPOINTMENTS güncelle (filtre değişse de kaybolmasın) */
                upsertAllAppointment(newAppt);

                /* add/update appointment on scheduler (sadece aktif grupta görünüyorsa) */
                var inActiveGroup = getActiveStations().some(function(s){ return s.id === stationId; });
                if (inActiveGroup) {
                    var ds = schedulerInst.option('dataSource');
                    var existing = ds.find(function(a){ return a.p_order_id === order.p_order_id; });
                    if (existing) {
                        schedulerInst.updateAppointment(existing, newAppt);
                    } else {
                        schedulerInst.addAppointment(newAppt);
                    }
                }
                showToast('Emir planlandı: ' + (order.p_order_no || 'Emir ##' + order.p_order_id), 'success');
            } else {
                showToast((resp && resp.message) || 'Kayıt hatası!', 'danger');
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-1"></i>Planla';
            showToast('Sunucu hatası, lütfen tekrar deneyin.', 'danger');
        }
    });
}

/* ================================================================
   Drop back to unplanned panel
   ================================================================ */
function handleDropToUnplanned(e) {
    e.preventDefault();
    var idStr = e.dataTransfer.getData('text/plain');
    var id    = parseInt(idStr, 10);
    if (!id) return;

    /* find in scheduled appointments */
    var ds    = schedulerInst ? schedulerInst.option('dataSource') : [];
    var appt  = ds.find(function(a){ return a.p_order_id === id; });
    if (!appt) return;

    /* send unplan request */
    $.ajax({
        url    : '../form/unplan_order.cfm',
        method : 'POST',
        data   : { p_order_id: id },
        dataType: 'json',
        success: function(resp) {
            if (resp && resp.success) {
                /* scheduler'dan kaldır (eğer aktif görünümdeyse) */
                var dsAppt = (schedulerInst ? schedulerInst.option('dataSource') : []).find(function(a){ return a.p_order_id === id; });
                if (dsAppt) schedulerInst.deleteAppointment(dsAppt);
                /* ALL_APPOINTMENTS'dan kaldır */
                removeAllAppointment(id);
                /* add back to raw unplanned */
                var alreadyThere = RAW_UNPLANNED.some(function(o){ return o.p_order_id === id; });
                if (!alreadyThere) {
                    var src = appt || {};
                    RAW_UNPLANNED.push({
                        p_order_id  : id,
                        p_order_no  : src.text ? src.text.split(' | ')[0] : ('Emir ##' + id),
                        color_code  : src.color_code  || '',
                        color_name  : src.color_name  || '',
                        company_name: src.company_name|| '',
                        lot_no      : src.lot_no      || '',
                        quantity    : src.quantity    || 0,
                        is_urgent   : false,
                        status      : 0
                    });
                }
                filterOrders(document.getElementById('orderSearch').value);
                updateCounts();
                showToast('Emir plandan kaldırıldı.', 'warning');
            }
        }
    });
}

/* ================================================================
   Scheduler appointment update (drag/resize within scheduler)
   ================================================================ */
function syncAppointmentUpdate(apptData) {
    /* ALL_APPOINTMENTS içinde de güncelle */
    upsertAllAppointment(apptData);
    $.ajax({
        url    : '/production/form/save_plan.cfm',
        method : 'POST',
        data   : {
            p_order_id : apptData.p_order_id,
            station_id : apptData.resourceId,
            start_date : fmtDTForServer(apptData.startDate),
            finish_date: fmtDTForServer(apptData.endDate),
            status     : apptData.status || 1
        },
        dataType: 'json'
    });
}

/* ================================================================
   Helpers
   ================================================================ */
function removeFromUnplanned(id) {
    RAW_UNPLANNED = RAW_UNPLANNED.filter(function(o){ return o.p_order_id !== id; });
    filterOrders(document.getElementById('orderSearch').value);
    updateCounts();
}

function moveBackToUnplanned(id) {
    /* called after appointment deleted from scheduler via delete button */
    removeAllAppointment(id);
    $.ajax({
        url    : '../form/unplan_order.cfm',
        method : 'POST',
        data   : { p_order_id: id },
        dataType: 'json'
    });
    showToast('Emir plandan kaldırıldı.', 'warning');
}

function fmtQty(n) {
    var num = parseFloat(n) || 0;
    return num.toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 2 });
}

function htmlEnc(str) {
    return (str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

function isValidDateStr(s) {
    if (!s) return false;
    var d = new Date(s.replace('T',' '));
    return !isNaN(d.getTime());
}

function toLocalDTInput(d) {
    var pad = function(n){ return n < 10 ? '0'+n : n; };
    return d.getFullYear() + '-' + pad(d.getMonth()+1) + '-' + pad(d.getDate())
         + 'T' + pad(d.getHours()) + ':' + pad(d.getMinutes());
}

function fmtDTForServer(d) {
    if (!(d instanceof Date)) d = new Date(d);
    var pad = function(n){ return n < 10 ? '0'+n : n; };
    return d.getFullYear() + '-' + pad(d.getMonth()+1) + '-' + pad(d.getDate())
         + ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':00';
}

function refreshPage() {
    window.location.reload();
}

/* ---- Toast -------------------------------------------------------- */
function showToast(msg, type) {
    type = type || 'info';
    var colors = { success:'##10b981', danger:'##ef4444', warning:'##f59e0b', info:'##3b82f6' };
    var t = document.createElement('div');
    t.style.cssText = [
        'position:fixed;bottom:1.5rem;right:1.5rem;z-index:99999',
        'background:' + (colors[type] || colors.info),
        'color:##fff;padding:.65rem 1.1rem;border-radius:10px',
        'font-size:.83rem;font-weight:600;box-shadow:0 4px 14px rgba(0,0,0,.2)',
        'display:flex;align-items:center;gap:.5rem;max-width:320px'
    ].join(';');
    t.innerHTML = '<i class="fas fa-'
        + (type==='success'?'check-circle':type==='danger'?'times-circle':'info-circle') + '"></i>'
        + htmlEnc(msg);
    document.body.appendChild(t);
    setTimeout(function() {
        t.style.transition = 'opacity .4s';
        t.style.opacity = '0';
        setTimeout(function(){ document.body.removeChild(t); }, 400);
    }, 3500);
}
</script>
</cfoutput>
