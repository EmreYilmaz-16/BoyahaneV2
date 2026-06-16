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

<!--- ================================================================
      Bağımlılıkları dinamik yükle (ajaxpage modunda layout head devreye girmeyebilir)
      ÖNEMLİ: dxGantt için 'dx-gantt.js' (Gantt motoru) gereklidir.
      Çift yükleme (E0024) ve eksik motor (E1041) hatalarını önlemek için:
        - Zaten yüklü scriptler tekrar EKLENMEZ.
        - dx.all.js yoksa yüklenir; varsa dokunulmaz.
        - dx-gantt.js her durumda yüklenir/teyit edilir ve hazır bayrağı set edilir.
      ================================================================ --->
<script>
(function() {
    var DX = 'https://cdn3.devexpress.com/jslib/23.2.5/';

    function hasScript(srcPart) {
        return Array.prototype.some.call(document.scripts, function(s) {
            return s.src && s.src.indexOf(srcPart) !== -1;
        });
    }
    function hasLink(hrefPart) {
        return Array.prototype.some.call(document.querySelectorAll('link[rel="stylesheet"]'), function(l) {
            return l.href && l.href.indexOf(hrefPart) !== -1;
        });
    }
    function addLink(href) {
        if (hasLink(href)) return;
        var l = document.createElement('link');
        l.rel = 'stylesheet'; l.href = href;
        document.head.appendChild(l);
    }
    function addScript(src, onload) {
        if (hasScript(src)) { if (onload) onload(); return; }
        var s = document.createElement('script');
        s.src = src;
        if (onload) s.onload = onload;
        document.head.appendChild(s);
    }

    function loadGanttEngine(next) {
        /* Gantt motoru — dxGantt widget'ından ÖNCE değerlendirilmiş olmalı */
        addScript(DX + 'js/dx-gantt.js', function() {
            window.__ganttEngineReady = true;
            if (next) next();
        });
    }

    function loadDevExtreme() {
        addLink(DX + 'css/dx.common.css');
        addLink(DX + 'css/dx.light.css');
        if (typeof DevExpress === 'undefined' && !hasScript('dx.all.js')) {
            /* DevExtreme yoksa: önce Gantt motoru, sonra dx.all.js (doğru sıra) */
            loadGanttEngine(function() {
                addScript(DX + 'js/dx.all.js');
            });
        } else {
            /* DevExtreme zaten yüklü: sadece Gantt motorunu ekle (lazy widget oluşturmada yeterli) */
            loadGanttEngine();
        }
    }

    if (typeof jQuery === 'undefined') {
        addScript('https://code.jquery.com/jquery-3.7.1.min.js', function() {
            addScript('https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js');
            loadDevExtreme();
        });
    } else {
        loadDevExtreme();
    }
}());
</script>

<!--- ================================================================
      STYLES  (cfoutput dışında — tek # ile hex renkler)
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
    gap: 14px;
    padding: 18px 24px;
    background: linear-gradient(135deg, #0d2137 0%, #1a3a5c 100%);
    border-bottom: 2px solid #e67e22;
    border-radius: 10px;
    box-shadow: 0 4px 16px rgba(0,0,0,.18);
    flex-shrink: 0;
}
.planner-topbar .topbar-icon {
    width: 44px; height: 44px;
    border-radius: 10px;
    background: #e67e22;
    box-shadow: 0 3px 10px rgba(230,126,34,.45);
    display: flex; align-items: center; justify-content: center;
    color: #fff; font-size: 1.1rem; flex-shrink: 0;
}
.planner-topbar h1 { margin: 0; font-size: 1.15rem; font-weight: 700; color: #fff; }
.planner-topbar p  { margin: 0; font-size: .75rem; color: rgba(255,255,255,.55); }
.planner-topbar .ms-auto { margin-left: auto; display: flex; gap: .5rem; align-items: center; }

/* ---- Group filter ------------------------------------------------- */
.group-filter-wrap {
    display: flex;
    align-items: center;
    gap: .4rem;
    background: rgba(255,255,255,.12);
    border: 1.5px solid rgba(255,255,255,.25);
    border-radius: 8px;
    padding: .28rem .6rem;
}
.group-filter-wrap label {
    font-size: .75rem;
    font-weight: 600;
    color: rgba(255,255,255,.75);
    white-space: nowrap;
    margin: 0;
}
.group-filter-wrap select {
    border: none;
    background: transparent;
    font-size: .82rem;
    color: #fff;
    outline: none;
    cursor: pointer;
    padding: 0 .25rem;
    color-scheme: dark;
}
.group-filter-wrap select option {
    background: #1a3a5c;
    color: #fff;
}
.group-filter-wrap select:focus { outline: none; }

/* ---- Main split --------------------------------------------------- */
.planner-body {
    display: flex;
    flex: 1;
    min-height: 0;
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
    background: #f8fafc;
    border-right: 2px solid #e2e8f0;
    overflow: hidden;
    flex-shrink: 0;
}
.orders-panel-header {
    padding: .6rem .75rem;
    background: #0d2137;
    color: #fff;
    font-size: .8rem;
    font-weight: 600;
    display: flex;
    align-items: center;
    gap: .5rem;
    flex-shrink: 0;
}
.orders-panel-header .badge-count {
    margin-left: auto;
    background: #e67e22;
    color: #fff;
    border-radius: 12px;
    padding: 2px 8px;
    font-size: .72rem;
}
.orders-search {
    padding: .5rem .5rem;
    border-bottom: 1px solid #e2e8f0;
    flex-shrink: 0;
}
.orders-search input {
    width: 100%;
    padding: .4rem .65rem;
    border: 1.5px solid #cbd5e1;
    border-radius: 8px;
    font-size: .8rem;
    outline: none;
    box-sizing: border-box;
}
.orders-search input:focus { border-color: #e67e22; }

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
    background: #fff;
    border: 1.5px solid #e8edf3;
    border-left: 4px solid #e67e22;
    border-radius: 8px;
    padding: .5rem .65rem;
    cursor: grab;
    user-select: none;
    transition: box-shadow .15s, border-color .15s, opacity .15s;
    font-size: .78rem;
    box-shadow: 0 1px 4px rgba(0,0,0,.05);
}
.order-card:hover { box-shadow: 0 4px 12px rgba(0,0,0,.1); border-color: #f0a060; }
.order-card.urgent { border-left-color: #ef4444; }
.order-card.dragging { opacity: .45; box-shadow: none; cursor: grabbing; }

.order-card .oc-no   { font-weight: 700; color: #1a3a5c; font-size: .82rem; }
.order-card .oc-info { color: #64748b; margin-top: 2px; line-height: 1.4; }
.order-card .oc-qty  {
    display: inline-block;
    margin-top: 4px;
    background: #fdf0e8;
    color: #c0621a;
    border-radius: 6px;
    padding: 1px 7px;
    font-weight: 600;
    font-size: .74rem;
}
.order-card .oc-urgent-badge {
    display: inline-block;
    margin-left: 4px;
    background: #fee2e2;
    color: #b91c1c;
    border-radius: 6px;
    padding: 1px 6px;
    font-weight: 600;
    font-size: .7rem;
}

/* ---- Right panel: gantt ------------------------------------------- */
.scheduler-panel {
    flex: 1;
    min-width: 0;
    min-height: 0;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    background: #fff;
}
.scheduler-panel-header {
    padding: .55rem 1rem;
    background: #fafbfc;
    border-bottom: 1px solid #eef1f6;
    font-size: .88rem;
    font-weight: 600;
    color: #1a3a5c;
    display: flex;
    align-items: center;
    gap: .5rem;
    flex-shrink: 0;
}
.scheduler-panel-header i { color: #e67e22; margin-right: 2px; }
.scheduler-panel-header .view-btns { margin-left: auto; display: flex; gap: .4rem; }
.scheduler-panel-header .view-btns button {
    padding: .28rem .7rem;
    border: 1px solid #cbd5e1;
    border-radius: 6px;
    background: #fff;
    font-size: .75rem;
    cursor: pointer;
    color: #6b7280;
    transition: all .15s;
}
.scheduler-panel-header .view-btns button.active,
.scheduler-panel-header .view-btns button:hover {
    background: #1a3a5c; color: #fff; border-color: #1a3a5c;
}

#ganttContainer {
    flex: 1 1 auto;
    min-height: 0;
    min-width: 0;
    height: 100%;
    width: 100%;
    position: relative;
    overflow: hidden;
}

/* ---- Drop overlay -------------------------------------------------  */
.drop-zone-overlay {
    position: absolute;
    inset: 0;
    background: rgba(230, 126, 34, .07);
    border: 3px dashed #e67e22;
    border-radius: 10px;
    display: none;
    align-items: center;
    justify-content: center;
    color: #c0621a;
    font-weight: 600;
    font-size: 1rem;
    pointer-events: none;
    z-index: 9999;
}
.drop-zone-overlay.visible { display: flex; }

/* ---- Plan modal --------------------------------------------------- */
#planModal .modal-header { background: linear-gradient(135deg, #0d2137, #1a3a5c); color: #fff; border-bottom: 2px solid #e67e22; }
#planModal .modal-header .btn-close { filter: invert(1); }

/* DevExtreme bileşenleri yüksek z-index kullanabilir;
   Bootstrap modal ve backdrop'ı onların üstüne çık */
#planModal       { z-index: 100000 !important; }
.modal-backdrop   { z-index:  99999 !important; }
.form-label-sm { font-size: .8rem; font-weight: 600; color: #1a3a5c; margin-bottom: .2rem; }
.form-control-sm-custom {
    width: 100%; padding: .45rem .65rem;
    border: 1.5px solid #cbd5e1; border-radius: 8px;
    font-size: .85rem; outline: none;
}
.form-control-sm-custom:focus { border-color: #e67e22; }

/* ---- Sabitler (etiket alan seçici) -------------------------------- */
.sabitler-wrap { position: relative; }
.sabitler-btn {
    display: flex;
    align-items: center;
    gap: .4rem;
    background: rgba(255,255,255,.12);
    border: 1.5px solid rgba(255,255,255,.25);
    border-radius: 8px;
    padding: .28rem .75rem;
    color: #fff;
    font-size: .82rem;
    font-weight: 600;
    cursor: pointer;
    white-space: nowrap;
    transition: background .15s;
}
.sabitler-btn:hover { background: rgba(255,255,255,.22); }
.sabitler-btn .sabitler-arrow { font-size: .65rem; opacity: .75; transition: transform .2s; }
.sabitler-btn.open .sabitler-arrow { transform: rotate(180deg); }

.sabitler-dropdown {
    display: none;
    position: absolute;
    top: calc(100% + 8px);
    right: 0;
    background: #fff;
    border: 1.5px solid #e2e8f0;
    border-radius: 10px;
    box-shadow: 0 8px 28px rgba(0,0,0,.16);
    z-index: 99998;
    width: 210px;
    max-height: 440px;
    overflow: hidden;
    flex-direction: column;
}
.sabitler-dropdown.open { display: flex; }
.sd-header {
    padding: .55rem .85rem;
    background: #0d2137;
    color: #fff;
    font-size: .8rem;
    font-weight: 700;
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-shrink: 0;
    border-radius: 8px 8px 0 0;
}
.sd-header-actions { display: flex; gap: .4rem; }
.sd-header-actions button {
    background: rgba(255,255,255,.15);
    border: 1px solid rgba(255,255,255,.3);
    border-radius: 5px;
    color: #fff;
    font-size: .7rem;
    padding: 2px 7px;
    cursor: pointer;
    transition: background .12s;
}
.sd-header-actions button:hover { background: rgba(255,255,255,.28); }
.sd-body {
    overflow-y: auto;
    padding: .4rem .35rem;
}
.sd-item {
    display: flex;
    align-items: center;
    gap: .45rem;
    padding: .3rem .5rem;
    border-radius: 5px;
    cursor: pointer;
    font-size: .8rem;
    color: #1e293b;
    user-select: none;
    transition: background .1s;
}
.sd-item:hover { background: #f1f5f9; }
.sd-item input[type=checkbox] {
    cursor: pointer;
    accent-color: #e67e22;
    width: 14px;
    height: 14px;
    flex-shrink: 0;
}
</style>

<!--- ================================================================
      HTML
      ================================================================ --->
<div class="planner-wrapper">

    <!--- Top bar --->
    <div class="planner-topbar">
        <div class="topbar-icon"><i class="fas fa-stream"></i></div>
        <div>
            <h1>Üretim Planlama — Gantt</h1>
            <p>Planlanmamış emirleri makinalara planlayın; Gantt çubuklarını kaydırarak tarih güncelleyin</p>
        </div>
        <div class="ms-auto">
            <div class="group-filter-wrap">
                <label><i class="fas fa-layer-group me-1"></i>Grup:</label>
                <select id="groupFilter" onchange="applyGroupFilter(this.value)">
                    <option value="0">— Tümü —</option>
                </select>
            </div>
            <!--- Sabitler / Etiket Alan Seçici --->
            <div class="sabitler-wrap">
                <button class="sabitler-btn" id="sabitlerBtn" onclick="toggleSabitlerDropdown(event)">
                    <i class="fas fa-sliders-h"></i>Sabitler
                    <i class="fas fa-chevron-down sabitler-arrow"></i>
                </button>
                <div class="sabitler-dropdown" id="sabitlerDropdown">
                    <div class="sd-header">
                        <span><i class="fas fa-tag me-1"></i>Etiket Alanları</span>
                        <div class="sd-header-actions">
                            <button onclick="selectAllFields()">Tümü</button>
                            <button onclick="clearAllFields()">Temizle</button>
                        </div>
                    </div>
                    <div class="sd-body" id="sabitlerBody">
                        <!--- JS ile dolacak --->
                    </div>
                </div>
            </div>
            <span id="unplannedBadge" style="background:rgba(255,255,255,.15);color:#fff;border:1px solid rgba(255,255,255,.3);border-radius:20px;padding:4px 12px;font-size:.75rem;font-weight:600;">
                <i class="fas fa-clock me-1"></i><span id="unplannedCount">0</span> Planlanmamış
            </span>
            <button style="background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.25);color:#fff;border-radius:7px;padding:5px 10px;cursor:pointer;font-size:.82rem;" onclick="refreshPage()" title="Yenile">
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

        <!--- RIGHT: gantt --->
        <div class="scheduler-panel">
            <div class="scheduler-panel-header">
                <i class="fas fa-stream"></i>Makina Gantt Planlaması
                <span style="color:#94a3b8;font-weight:400;font-size:.75rem;margin-left:.4rem">
                    — Emri sürükleyip Gantt'a bırakın veya kartı tıklayın; çubukları kaydırarak güncelleyin
                </span>
                <div class="view-btns">
                    <button id="btnHour"  onclick="switchScale('hours')"  class="active">Saatlik</button>
                    <button id="btnDay"   onclick="switchScale('days')"            >Günlük</button>
                    <button id="btnWeek"  onclick="switchScale('weeks')"           >Haftalık</button>
                    <button id="btnMonth" onclick="switchScale('months')"          >Aylık</button>
                </div>
            </div>
            <div style="position:relative;flex:1;overflow:hidden;">
                <div id="ganttContainer"></div>
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
                        <div class="p-3 rounded" style="background:#f8fafc;border:1px solid #e2e8f0;">
                            <div style="font-size:.85rem;font-weight:700;color:#1e293b;" id="modalOrderTitle">-</div>
                            <div style="font-size:.78rem;color:#64748b;margin-top:2px;" id="modalOrderSub">-</div>
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
      VERİ ENJEKSİYONU (tek cfoutput — # kaçışı gerektiren tek yer)
      ================================================================ --->
<cfoutput>
<script>
window.RAW_UNPLANNED = #serializeJSON(unplannedArr)#;
window.RAW_PLANNED   = #serializeJSON(plannedArr)#;
window.ALL_STATIONS  = #serializeJSON(machinesArr)#;
window.GROUPS        = #serializeJSON(groupsArr)#;
</script>
</cfoutput>

<!--- ================================================================
      SCRIPT  (cfoutput dışında — normal # kullanımı)
      ================================================================ --->
<script>
/* ---- raw data from CF --------------------------------------------- */
var RAW_UNPLANNED = window.RAW_UNPLANNED || [];
var RAW_PLANNED   = window.RAW_PLANNED   || [];
var ALL_STATIONS  = window.ALL_STATIONS  || [];   /* sadece gerçek makineler */
var GROUPS        = window.GROUPS        || [];   /* üst istasyon grupları */

/* ---- durum tanımları ---------------------------------------------- */
var STATUS_META = {
    1: { label: 'Planlandı',   bg: '#1a3a5c', fg: '#fff' },
    2: { label: 'Çalışıyor',   bg: '#2e7d32', fg: '#fff' },
    5: { label: 'Tamamlandı',  bg: '#757575', fg: '#fff' },
    9: { label: 'İptal',       bg: '#b71c1c', fg: '#fff' }
};

/* ---- Sabitler — etiket alan tanımları ----------------------------- */
var LABEL_FIELDS = [
    { key: 'plan_rn',        label: 'PlanRN',               getValue: function(d) { return d.p_order_no || (d.text ? d.text.split(' | ')[0] : '') || (d.p_order_id ? '#' + d.p_order_id : ''); } },
    { key: 'parti_rn',       label: 'PartiRN',              getValue: function(d) { return d.lot_no || ''; } },
    { key: 'parti_durum',    label: 'PartiDurum',           getValue: function(d) { var m = STATUS_META[d.status]; return m ? m.label : ''; } },
    { key: 'giris_rn',       label: 'GirisRN',              getValue: function(d) { return d.giris_rn || ''; } },
    { key: 'kazan',          label: 'Kazan',                getValue: function(d) { return d.kazan || ''; } },
    { key: 'metre',          label: 'Metre',                getValue: function(d) { return d.metre ? (fmtQty(d.metre) + ' m') : ''; } },
    { key: 'kg',             label: 'Kg',                   getValue: function(d) { return d.quantity ? (fmtQty(d.quantity) + ' kg') : ''; } },
    { key: 'top_adet',       label: 'TopAdet',              getValue: function(d) { return d.top_adet || ''; } },
    { key: 'gramaj',         label: 'Gramaj',               getValue: function(d) { return d.gramaj || ''; } },
    { key: 'firma_kodu',     label: 'FirmaKodu',            getValue: function(d) { return d.firma_kodu || ''; } },
    { key: 'firma_adi',      label: 'FirmaAdi',             getValue: function(d) { return d.company_name || ''; } },
    { key: 'kumas_cinsi',    label: 'KumasCinsi',           getValue: function(d) { return d.kumas_cinsi || d.stock_code || ''; } },
    { key: 'renk_no',        label: 'RenkNo',               getValue: function(d) { return d.renk_no || ''; } },
    { key: 'renk_adi',       label: 'RenkAdi',              getValue: function(d) { return d.color_name || ''; } },
    { key: 'renk_tonu',      label: 'RenkTonu',             getValue: function(d) { return d.renk_tonu || ''; } },
    { key: 'renk_kodu',      label: 'RenkKodu',             getValue: function(d) { return d.color_code || ''; } },
    { key: 'plan_bas',       label: 'Planlanan Başlangıç',  getValue: function(d) { var v = d.startDate || d.start_date; return v ? fmtDateShort(v) : ''; } },
    { key: 'plan_bit',       label: 'Planlanan Bitiş',      getValue: function(d) { var v = d.endDate || d.finish_date; return v ? fmtDateShort(v) : ''; } },
    { key: 'fiili_bas',      label: 'Plan/Fiili Başlangıç', getValue: function(d) { return d.fiili_bas ? fmtDateShort(d.fiili_bas) : ''; } },
    { key: 'fiili_bit',      label: 'Plan/Fiili Bitiş',     getValue: function(d) { return d.fiili_bit ? fmtDateShort(d.fiili_bit) : ''; } },
    { key: 'kartela',        label: 'Kartela',              getValue: function(d) { return d.kartela || ''; } },
    { key: 'flote',          label: 'Flote',                getValue: function(d) { return d.flote || ''; } },
    { key: 'parti_aciklama', label: 'Parti Açıklama',       getValue: function(d) { return d.parti_aciklama || ''; } }
];

/* Varsayılan seçili alanlar */
var selectedFields = new Set(['plan_rn', 'renk_kodu', 'renk_adi', 'firma_adi', 'kg']);

/* ---- state --------------------------------------------------------- */
var unplannedList = [];     // filtered working copy
var PLANNED_ALL   = [];     // planlı emirlerin çalışma kopyası
var ganttInst     = null;
var dragItem      = null;   // sol panelden sürüklenen emir
var pendingDrop   = null;   // { order, stationId, startDate, endDate }
var currentScale  = 'hours';
var planModalBs   = null;
var activeGroupId = 0;      // 0 = tümü

/* ---- palette for machines ----------------------------------------- */
var PALETTE = [
    '#3b82f6','#10b981','#f59e0b','#ef4444','#8b5cf6',
    '#ec4899','#14b8a6','#f97316','#6366f1','#84cc16'
];
ALL_STATIONS.forEach(function(s, i) {
    s.color = PALETTE[i % PALETTE.length];
});

/* filtrelenmiş aktif makine listesi (gruba göre) */
function getActiveStations() {
    if (!activeGroupId) return ALL_STATIONS;
    return ALL_STATIONS.filter(function(s) { return s.group_id === activeGroupId; });
}

/* ================================================================
   Init — deps yoksa 50ms aralıklarla bekle
   ================================================================ */
(function poll() {
    if (typeof jQuery === 'undefined' ||
        typeof DevExpress === 'undefined' ||
        typeof bootstrap === 'undefined' ||
        typeof bootstrap.Modal !== 'function' ||
        !jQuery.fn || typeof jQuery.fn.dxGantt !== 'function' ||
        !window.__ganttEngineReady) {
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
    if (!GROUPS.length) {
        var fw = document.querySelector('.group-filter-wrap');
        if (fw) fw.style.display = 'none';
    }

    /* Planlı emirlerin çalışma kopyası */
    PLANNED_ALL = RAW_PLANNED.map(function(o) { return Object.assign({}, o); });

    unplannedList = RAW_UNPLANNED.slice();
    renderOrderCards(unplannedList);
    updateCounts();
    buildGantt();

    /* Bootstrap modal — Gantt'ın stacking context'inden kaçınmak için body'e taşı */
    var modalEl = document.getElementById('planModal');
    if (modalEl.parentElement !== document.body) {
        document.body.appendChild(modalEl);
    }
    planModalBs = new bootstrap.Modal(modalEl);

    populateModalStations(ALL_STATIONS);
    initSabitlerDropdown();
}());

/* ================================================================
   Gantt (dxGantt)
   - Her aktif makine bir üst (parent) satır
   - Planlı emirler ilgili makinanın altında çubuk
   ================================================================ */
function machineKey(id) { return -Math.abs(parseInt(id, 10)); }

function buildTaskTitle(o) {
    var parts = [];
    LABEL_FIELDS.forEach(function(f) {
        if (!selectedFields.has(f.key)) return;
        var v = f.getValue(o);
        if (v === null || v === undefined || v === '') return;
        parts.push(String(v));
    });
    return parts.join('  ·  ') || (o.p_order_no || ('Emir #' + o.p_order_id));
}

function statusProgress(s) {
    s = parseInt(s, 10);
    return s === 2 ? 50 : (s === 5 ? 100 : 0);
}

function buildTasks() {
    var stations = getActiveStations();
    var ids = stations.map(function(s) { return s.id; });
    var tasks = [];

    /* makine üst satırları */
    stations.forEach(function(st) {
        tasks.push({ id: machineKey(st.id), parentId: 0, title: st.text, _machine: true });
    });

    /* emir çubukları */
    PLANNED_ALL.forEach(function(o) {
        if (ids.indexOf(o.station_id) === -1) return;
        var s = toDate(o.startDate || o.start_date);
        var e = toDate(o.endDate   || o.finish_date);
        if (!s) s = new Date();
        if (!e) e = new Date(s.getTime() + 8 * 3600000);
        tasks.push({
            id       : o.p_order_id,
            parentId : machineKey(o.station_id),
            title    : buildTaskTitle(o),
            start    : s,
            end      : e,
            progress : statusProgress(o.status),
            _order   : true
        });
    });
    return tasks;
}

function buildGantt() {
    ganttInst = $('#ganttContainer').dxGantt({
        tasks: {
            dataSource  : buildTasks(),
            keyExpr     : 'id',
            parentIdExpr: 'parentId',
            titleExpr   : 'title',
            startExpr   : 'start',
            endExpr     : 'end',
            progressExpr: 'progress'
        },
        columns: [
            { dataField: 'title', caption: 'Makina / Emir', width: 320 }
        ],
        scaleType        : currentScale,
        taskListWidth    : 340,
        taskTitlePosition: 'inside',
        showRowLines     : true,
        showDependencies : false,
        height           : '100%',
        editing: {
            enabled              : true,
            allowTaskAdding      : false,
            allowTaskDeleting    : true,
            allowTaskUpdating    : true,
            allowDependencyAdding: false,
            allowDependencyDeleting: false,
            allowResourceAdding  : false,
            allowResourceDeleting: false
        },
        validation: { autoUpdateParentTasks: true },
        onTaskDblClick: function(e) {
            e.cancel = true;
            var o = findPlanned(e.key);
            if (o) openEditModalFromOrder(o);
        },
        onTaskUpdated: function(e) { onGanttTaskUpdated(e); },
        onTaskDeleted: function(e) { unplanById(e.key); }
    }).dxGantt('instance');

    /* sol panelden Gantt'a bırakınca modal aç */
    var ganttEl = document.getElementById('ganttContainer');
    var dropOverlay = document.getElementById('dropOverlay');

    ganttEl.addEventListener('dragover', function(e) {
        if (!dragItem) return;
        e.preventDefault();
        e.dataTransfer.dropEffect = 'move';
        dropOverlay.classList.add('visible');
    });
    ganttEl.addEventListener('dragleave', function(e) {
        if (!ganttEl.contains(e.relatedTarget)) dropOverlay.classList.remove('visible');
    });
    ganttEl.addEventListener('drop', function(e) {
        e.preventDefault();
        dropOverlay.classList.remove('visible');
        if (!dragItem) return;
        var order = dragItem;
        dragItem = null;
        openPlanModal(order, null, null, null);
    });

    /* SPA enjeksiyonunda kapsayıcı boyutu geç oturabilir → render'ı tazele.
       Birkaç kare boyunca repaint çağırarak grafik panelinin doğru
       genişlik/yükseklikle çizilmesini garantiye al. */
    scheduleGanttRepaint();
}

function scheduleGanttRepaint() {
    var tries = 0;
    function tick() {
        if (!ganttInst) return;
        try { ganttInst.repaint(); } catch (err) {}
        if (++tries < 5) {
            requestAnimationFrame(function() { setTimeout(tick, 60); });
        }
    }
    requestAnimationFrame(tick);
}

function refreshGantt() {
    if (ganttInst) ganttInst.option('tasks.dataSource', buildTasks());
}

/* Gantt çubuğu sürükle/yeniden boyutlandır → tarih güncelle */
function onGanttTaskUpdated(e) {
    var o = findPlanned(e.key);
    if (!o) return;
    var v = e.values || {};
    if (v.start) o.startDate = v.start;
    if (v.end)   o.endDate   = v.end;
    savePlanQuiet(o);
}

function savePlanQuiet(o) {
    $.ajax({
        url    : '/production/form/save_plan.cfm',
        method : 'POST',
        data   : {
            p_order_id : o.p_order_id,
            station_id : o.station_id,
            start_date : fmtDTForServer(toDate(o.startDate)),
            finish_date: fmtDTForServer(toDate(o.endDate)),
            status     : o.status || 1
        },
        dataType: 'json',
        success : function(resp) {
            if (resp && resp.success) {
                /* sunucu tarihleri döndürdüyse senkronla */
                if (resp.start_date && isValidDateStr(resp.start_date))  o.startDate = new Date(resp.start_date.replace('T', ' '));
                if (resp.finish_date && isValidDateStr(resp.finish_date)) o.endDate   = new Date(resp.finish_date.replace('T', ' '));
                if (Array.isArray(resp.shifted_orders) && resp.shifted_orders.length) {
                    resp.shifted_orders.forEach(function(sh) {
                        var sid = parseInt(sh.p_order_id, 10);
                        if (!sid || !sh.start_date || !sh.finish_date) return;
                        var ex = findPlanned(sid);
                        if (ex) { ex.startDate = new Date(sh.start_date.replace('T', ' ')); ex.endDate = new Date(sh.finish_date.replace('T', ' ')); }
                    });
                    refreshGantt();
                }
                showToast('Güncellendi.', 'success');
            } else {
                showToast((resp && resp.message) || 'Kayıt hatası!', 'danger');
                refreshGantt();
            }
        },
        error: function() { showToast('Sunucu hatası, lütfen tekrar deneyin.', 'danger'); refreshGantt(); }
    });
}

/* ---- ölçek (görünüm) değiştir ------------------------------------- */
function switchScale(scale) {
    currentScale = scale;
    if (ganttInst) ganttInst.option('scaleType', scale);
    document.querySelectorAll('.view-btns button').forEach(function(b) { b.classList.remove('active'); });
    var map = { hours: 'btnHour', days: 'btnDay', weeks: 'btnWeek', months: 'btnMonth' };
    var el = document.getElementById(map[scale]);
    if (el) el.classList.add('active');
}

/* ---- grup filtresi ------------------------------------------------ */
function applyGroupFilter(val) {
    activeGroupId = parseInt(val, 10) || 0;
    populateModalStations(getActiveStations());
    refreshGantt();
}

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

/* ================================================================
   Sol panel — emir kartları
   ================================================================ */
function renderOrderCards(list) {
    var container = document.getElementById('ordersList');
    container.innerHTML = '';

    if (!list || list.length === 0) {
        container.innerHTML = '<div style="text-align:center;color:#94a3b8;padding:2rem;font-size:.8rem;">'
            + '<i class="fas fa-check-circle" style="font-size:1.5rem;color:#10b981;display:block;margin-bottom:.5rem;"></i>'
            + 'Tüm emirler planlandı!</div>';
        return;
    }

    list.forEach(function(order) {
        var card = document.createElement('div');
        card.className = 'order-card' + (order.is_urgent ? ' urgent' : '');
        card.draggable = true;
        card.dataset.id = order.p_order_id;

        card.innerHTML =
            '<div class="oc-no">' + htmlEnc(order.p_order_no || ('Emir #' + order.p_order_id))
                + (order.is_urgent ? '<span class="oc-urgent-badge">ACİL</span>' : '') + '</div>'
            + buildOrderCardFields(order);

        card.addEventListener('dragstart', function(e) {
            dragItem = order;
            card.classList.add('dragging');
            e.dataTransfer.effectAllowed = 'move';
            e.dataTransfer.setData('text/plain', String(order.p_order_id));
        });
        card.addEventListener('dragend', function() {
            card.classList.remove('dragging');
        });
        card.addEventListener('click', function() {
            openPlanModal(order, null, null, null);
        });

        container.appendChild(card);
    });
}

function buildOrderCardFields(order) {
    var parts = [];
    LABEL_FIELDS.forEach(function(f) {
        if (!selectedFields.has(f.key)) return;
        var val = f.getValue(order);
        if (val === null || val === undefined || val === '') return;
        parts.push('<span style="white-space:nowrap;font-size:.74rem;color:#475569;">'
            + '<span style="color:#94a3b8;font-size:.68rem;">' + htmlEnc(f.label) + ':</span>'
            + ' <b>' + htmlEnc(String(val)) + '</b></span>');
    });
    if (!parts.length) return '';
    return '<div style="display:flex;flex-wrap:wrap;gap:2px 8px;margin-top:4px;">' + parts.join('') + '</div>';
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

function removeFromUnplanned(id) {
    id = parseInt(id, 10);
    RAW_UNPLANNED = RAW_UNPLANNED.filter(function(o) { return o.p_order_id !== id; });
    filterOrders(document.getElementById('orderSearch').value);
    updateCounts();
}

/* ================================================================
   Plan Modal
   ================================================================ */
function openPlanModal(order, stationId, startDate, endDate) {
    pendingDrop = { order: order, stationId: stationId, startDate: startDate, endDate: endDate };

    document.getElementById('modalOrderTitle').textContent =
        (order.p_order_no || ('Emir #' + order.p_order_id))
        + ' — ' + (order.color_code || '') + ' ' + (order.color_name || '');
    document.getElementById('modalOrderSub').textContent =
        (order.company_name || '') + (order.lot_no ? ' · Lot: ' + order.lot_no : '')
        + ' · ' + fmtQty(order.quantity) + ' kg';

    var sel = document.getElementById('modalStation');
    if (stationId) sel.value = stationId;

    var sd = startDate ? toDate(startDate) : new Date();
    if (!sd) sd = new Date();
    sd = new Date(sd.getTime());
    sd.setMinutes(0, 0, 0);
    var ed = endDate ? toDate(endDate) : new Date(sd.getTime() + 8 * 3600000);
    if (!ed) ed = new Date(sd.getTime() + 8 * 3600000);

    document.getElementById('modalStartDate').value = toLocalDTInput(sd);
    document.getElementById('modalEndDate').value   = toLocalDTInput(ed);
    document.getElementById('modalStatus').value    = '1';

    planModalBs.show();
}

function openEditModalFromOrder(o) {
    openPlanModal(o, o.station_id, toDate(o.startDate || o.start_date), toDate(o.endDate || o.finish_date));
    document.getElementById('modalStatus').value = o.status || 1;
}

function savePlan() {
    if (!pendingDrop) return;

    var stationId = parseInt(document.getElementById('modalStation').value, 10);
    var startVal  = document.getElementById('modalStartDate').value;
    var endVal    = document.getElementById('modalEndDate').value;
    var statusVal = parseInt(document.getElementById('modalStatus').value, 10);

    if (!stationId || isNaN(stationId)) { alert('Lütfen makina seçin.'); return; }
    if (!startVal) { alert('Başlangıç tarihi zorunludur.'); return; }

    var startDate = new Date(startVal);
    var endDate   = endVal ? new Date(endVal) : new Date(startDate.getTime() + 8 * 3600000);
    if (endDate <= startDate) { alert('Bitiş tarihi başlangıçtan büyük olmalıdır.'); return; }

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
            start_date : startVal.replace('T', ' '),
            finish_date: endVal ? endVal.replace('T', ' ') : fmtDTForServer(endDate),
            status     : statusVal
        },
        dataType: 'json',
        success : function(resp) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-1"></i>Planla';

            if (resp && resp.success) {
                planModalBs.hide();

                var serverStart = (resp.start_date  && isValidDateStr(resp.start_date))
                                ? new Date(resp.start_date.replace('T', ' ')) : startDate;
                var serverEnd   = (resp.finish_date && isValidDateStr(resp.finish_date))
                                ? new Date(resp.finish_date.replace('T', ' ')) : endDate;

                var planned = Object.assign({}, order, {
                    station_id      : stationId,
                    startDate       : serverStart,
                    endDate         : serverEnd,
                    status          : statusVal,
                    total_op_minutes: resp.total_op_minutes || order.total_op_minutes || 0
                });
                upsertPlanned(planned);
                removeFromUnplanned(order.p_order_id);

                /* ötelenen emirler */
                if (Array.isArray(resp.shifted_orders) && resp.shifted_orders.length) {
                    resp.shifted_orders.forEach(function(sh) {
                        var sid = parseInt(sh.p_order_id, 10);
                        if (!sid || !sh.start_date || !sh.finish_date) return;
                        var ex = findPlanned(sid);
                        if (ex) { ex.startDate = new Date(sh.start_date.replace('T', ' ')); ex.endDate = new Date(sh.finish_date.replace('T', ' ')); }
                    });
                }

                refreshGantt();

                var stObj = ALL_STATIONS.find(function(s) { return s.id === stationId; });
                var snapNote = resp.snapped
                    ? ' (başlangıç kaydırıldı: ' + serverStart.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' }) + ')'
                    : '';
                var shiftNote = (resp.shifted_count && parseInt(resp.shifted_count, 10) > 0)
                    ? (' | Sonraki ' + resp.shifted_count + ' emir ötelenmiştir') : '';
                showToast('Planlandı: ' + (order.p_order_no || 'Emir #' + order.p_order_id)
                    + (stObj ? ' → ' + stObj.text : '') + snapNote + shiftNote, 'success');
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
   Plandan kaldırma (Gantt'tan task silinince)
   ================================================================ */
function unplanById(id) {
    id = parseInt(id, 10);
    if (!id) return;
    var o = findPlanned(id);

    $.ajax({
        url    : '/production/form/unplan_order.cfm',
        method : 'POST',
        data   : { p_order_id: id },
        dataType: 'json',
        success: function(resp) {
            if (resp && resp.success) {
                removePlanned(id);
                if (o && !RAW_UNPLANNED.some(function(x) { return x.p_order_id === id; })) {
                    RAW_UNPLANNED.push(Object.assign({}, o, { is_urgent: o.is_urgent || false, status: 0 }));
                }
                filterOrders(document.getElementById('orderSearch').value);
                updateCounts();
                refreshGantt();
                showToast('Emir plandan kaldırıldı.', 'warning');
            } else {
                showToast((resp && resp.message) || 'Kaldırma hatası!', 'danger');
                refreshGantt();
            }
        },
        error: function() { showToast('Sunucu hatası, lütfen tekrar deneyin.', 'danger'); refreshGantt(); }
    });
}

/* Gantt çubukları HTML5 ile panele sürüklenemez — no-op */
function handleDropToUnplanned(e) { e.preventDefault(); }

/* ================================================================
   PLANNED_ALL yardımcıları
   ================================================================ */
function findPlanned(id) {
    id = parseInt(id, 10);
    return PLANNED_ALL.find(function(o) { return o.p_order_id === id; });
}
function upsertPlanned(o) {
    var i = PLANNED_ALL.findIndex(function(x) { return x.p_order_id === o.p_order_id; });
    if (i >= 0) PLANNED_ALL[i] = o;
    else        PLANNED_ALL.push(o);
}
function removePlanned(id) {
    id = parseInt(id, 10);
    PLANNED_ALL = PLANNED_ALL.filter(function(o) { return o.p_order_id !== id; });
}

/* ================================================================
   Sabitler dropdown
   ================================================================ */
function fmtDateShort(d) {
    if (!d) return '';
    var dt = (d instanceof Date) ? d : new Date(String(d).replace('T', ' '));
    if (isNaN(dt.getTime())) return '';
    var pad = function(n) { return n < 10 ? '0' + n : n; };
    return pad(dt.getDate()) + '.' + pad(dt.getMonth() + 1) + '.' + dt.getFullYear()
         + ' ' + pad(dt.getHours()) + ':' + pad(dt.getMinutes());
}

function initSabitlerDropdown() {
    var body = document.getElementById('sabitlerBody');
    if (!body) return;
    body.innerHTML = '';
    LABEL_FIELDS.forEach(function(f) {
        var lbl = document.createElement('label');
        lbl.className = 'sd-item';
        var chk = document.createElement('input');
        chk.type = 'checkbox';
        chk.checked = selectedFields.has(f.key);
        chk.onchange = (function(key) {
            return function(e) { toggleField(key, e.target.checked); };
        }(f.key));
        var txt = document.createTextNode(f.label);
        lbl.appendChild(chk);
        lbl.appendChild(txt);
        body.appendChild(lbl);
    });
}

function toggleSabitlerDropdown(e) {
    e.stopPropagation();
    var btn = document.getElementById('sabitlerBtn');
    var dd  = document.getElementById('sabitlerDropdown');
    var isOpen = dd.classList.toggle('open');
    btn.classList.toggle('open', isOpen);
}

function toggleField(key, checked) {
    if (checked) selectedFields.add(key);
    else         selectedFields.delete(key);
    refreshVisuals();
}

function selectAllFields() {
    LABEL_FIELDS.forEach(function(f) { selectedFields.add(f.key); });
    initSabitlerDropdown();
    refreshVisuals();
}

function clearAllFields() {
    selectedFields.clear();
    initSabitlerDropdown();
    refreshVisuals();
}

function refreshVisuals() {
    renderOrderCards(unplannedList);
    refreshGantt();
}

/* ================================================================
   Yardımcılar
   ================================================================ */
function fmtQty(n) {
    var num = parseFloat(n) || 0;
    return num.toLocaleString('tr-TR', { minimumFractionDigits: 0, maximumFractionDigits: 2 });
}

function htmlEnc(str) {
    return (str || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

function toDate(v) {
    if (!v) return null;
    if (v instanceof Date) return v;
    var d = new Date(String(v).replace('T', ' '));
    return isNaN(d.getTime()) ? null : d;
}

function isValidDateStr(s) {
    if (!s) return false;
    var d = new Date(String(s).replace('T', ' '));
    return !isNaN(d.getTime());
}

function toLocalDTInput(d) {
    var pad = function(n) { return n < 10 ? '0' + n : n; };
    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate())
         + 'T' + pad(d.getHours()) + ':' + pad(d.getMinutes());
}

function fmtDTForServer(d) {
    if (!(d instanceof Date)) d = new Date(d);
    var pad = function(n) { return n < 10 ? '0' + n : n; };
    return d.getFullYear() + '-' + pad(d.getMonth() + 1) + '-' + pad(d.getDate())
         + ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':00';
}

function refreshPage() {
    window.location.reload();
}

/* ---- Toast -------------------------------------------------------- */
function showToast(msg, type) {
    type = type || 'info';
    var colors = { success: '#27ae60', danger: '#e74c3c', warning: '#f39c12', info: '#1a3a5c' };
    var t = document.createElement('div');
    t.style.cssText = [
        'position:fixed;bottom:1.5rem;right:1.5rem;z-index:99999',
        'background:' + (colors[type] || colors.info),
        'color:#fff;padding:.65rem 1.1rem;border-radius:10px',
        'font-size:.83rem;font-weight:600;box-shadow:0 4px 14px rgba(0,0,0,.2)',
        'display:flex;align-items:center;gap:.5rem;max-width:320px'
    ].join(';');
    t.innerHTML = '<i class="fas fa-'
        + (type === 'success' ? 'check-circle' : type === 'danger' ? 'times-circle' : 'info-circle') + '"></i>'
        + htmlEnc(msg);
    document.body.appendChild(t);
    setTimeout(function() {
        t.style.transition = 'opacity .4s';
        t.style.opacity = '0';
        setTimeout(function() { document.body.removeChild(t); }, 400);
    }, 3500);
}

/* ---- Sabitler dropdown dışına tıklayınca kapat ------------------- */
document.addEventListener('click', function(e) {
    var dd  = document.getElementById('sabitlerDropdown');
    var btn = document.getElementById('sabitlerBtn');
    if (dd && dd.classList.contains('open')) {
        if (!dd.contains(e.target) && btn && !btn.contains(e.target)) {
            dd.classList.remove('open');
            btn.classList.remove('open');
        }
    }
});
</script>
