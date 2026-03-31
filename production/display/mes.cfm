<cfprocessingdirective pageEncoding="utf-8">

<!--- Aktif (Planlandı=1) ve Devam Eden (=2) emirleri çek --->
<cfquery name="qOrders" datasource="boyahane">
    SELECT po.p_order_id, po.p_order_no, po.status,
           po.start_date_real, po.start_date, po.finish_date,
           COALESCE(po.quantity, 0)              AS quantity,
           COALESCE(po.lot_no, '')               AS lot_no,
           COALESCE(ci.color_code, '')           AS color_code,
           COALESCE(ci.color_name, '')           AS color_name,
           COALESCE(c.nickname, c.fullname, '')  AS company_name,
           COALESCE(s.stock_code, '')            AS stock_code,
           COALESCE(ws.station_name, '')         AS station_name,
           po.station_id
    FROM production_orders po
    LEFT JOIN stocks       s  ON po.stock_id   = s.stock_id
    LEFT JOIN color_info   ci ON po.stock_id   = ci.stock_id
    LEFT JOIN company      c  ON ci.company_id = c.company_id
    LEFT JOIN workstations ws ON po.station_id = ws.station_id
    WHERE po.status IN (1, 2)
    ORDER BY po.status DESC, po.p_order_id DESC
</cfquery>

<!--- Duruş tipleri --->
<cfquery name="qPauseTypes" datasource="boyahane">
    SELECT prod_pause_type_id, prod_pause_type
    FROM setup_prod_pause_type
    WHERE is_active = true
    ORDER BY prod_pause_type
</cfquery>

<!--- Seçili emir (URL'den) --->
<cfparam name="url.p_order_id" default="0">
<cfset selOrderId = isNumeric(url.p_order_id) AND val(url.p_order_id) gt 0 ? val(url.p_order_id) : 0>

<!--- Seçili emir detayı + duruş geçmişi --->
<cfif selOrderId gt 0>
    <cfquery name="qSel" datasource="boyahane">
        SELECT po.p_order_id, po.p_order_no, po.status,
               po.start_date_real, po.start_date, po.finish_date,
               COALESCE(po.quantity, 0)             AS quantity,
               COALESCE(po.lot_no, '')              AS lot_no,
               COALESCE(ci.color_code, '')          AS color_code,
               COALESCE(ci.color_name, '')          AS color_name,
               COALESCE(c.nickname, c.fullname, '') AS company_name,
               COALESCE(s.stock_code, '')           AS stock_code,
               COALESCE(ws.station_name, '')        AS station_name,
               po.station_id
        FROM production_orders po
        LEFT JOIN stocks       s  ON po.stock_id   = s.stock_id
        LEFT JOIN color_info   ci ON po.stock_id   = ci.stock_id
        LEFT JOIN company      c  ON ci.company_id = c.company_id
        LEFT JOIN workstations ws ON po.station_id = ws.station_id
        WHERE po.p_order_id = <cfqueryparam value="#selOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfquery name="qPauses" datasource="boyahane">
        SELECT sp.prod_pause_id,
               sp.action_date,
               COALESCE(sp.prod_duration, 0)    AS prod_duration,
               COALESCE(sp.prod_detail, '')      AS prod_detail,
               COALESCE(spt.prod_pause_type, '') AS pause_type,
               sp.is_working_time,
               sp.duration_start_date,
               sp.duration_finish_date
        FROM setup_prod_pause sp
        LEFT JOIN setup_prod_pause_type spt ON sp.prod_pause_type_id = spt.prod_pause_type_id
        WHERE sp.p_order_id = <cfqueryparam value="#selOrderId#" cfsqltype="cf_sql_integer">
        ORDER BY sp.prod_pause_id DESC
    </cfquery>

    <!--- Toplam duruş dakikası --->
    <cfset totalPauseMin = 0>
    <cfloop query="qPauses">
        <cfset totalPauseMin += val(prod_duration)>
    </cfloop>
<cfelse>
    <cfset qSel = queryNew("")>
</cfif>

<!--- Seçili emir için JS değişkenleri --->
<cfset jsOrderId     = selOrderId>
<cfset jsStatus      = selOrderId gt 0 AND qSel.recordCount ? val(qSel.status) : 0>
<cfset jsStartReal   = "">
<cfif selOrderId gt 0 AND qSel.recordCount AND isDate(qSel.start_date_real)>
    <cfset jsStartReal = dateFormat(qSel.start_date_real,"yyyy-mm-dd") & "T" & timeFormat(qSel.start_date_real,"HH:mm:ss") & "Z">
</cfif>

<cfoutput>
<!--- ======================================================
      STYLES
      ====================================================== --->
<style>
/* ---- MES layout ---------------------------------------- */
.mes-wrapper {
    display: flex;
    flex-direction: column;
    gap: 1rem;
    padding: 1rem 1.25rem 3rem;
    max-width: 960px;
    margin: 0 auto;
}

/* Page header */
.mes-page-header {
    background: linear-gradient(135deg, ##0d2137 0%, ##1a3a5c 100%);
    color: ##fff;
    padding: 18px 24px;
    border-bottom: 2px solid ##e67e22;
    border-radius: 10px;
    box-shadow: 0 4px 16px rgba(0,0,0,.18);
    display: flex;
    align-items: center;
    gap: 14px;
}
.mes-page-header .mes-icon {
    width: 44px; height: 44px;
    border-radius: 10px;
    background: ##e67e22;
    box-shadow: 0 3px 10px rgba(230,126,34,.45);
    display: flex; align-items: center; justify-content: center;
    color: ##fff; font-size: 1.15rem;
    flex-shrink: 0;
}
.mes-page-header h1 { margin: 0; font-size: 1.15rem; font-weight: 700; color: ##fff; }
.mes-page-header p  { margin: 0; font-size: .75rem; color: rgba(255,255,255,.55); }

/* Order selector card */
.mes-card {
    background: ##fff;
    border: 1px solid ##e8edf3;
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 2px 14px rgba(0,0,0,.07);
}
.mes-card-header {
    padding: 14px 20px;
    background: ##fafbfc;
    border-bottom: 1px solid ##eef1f6;
    font-size: .88rem;
    font-weight: 600;
    color: ##1a3a5c;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: .5rem;
}
.mes-card-header i { color: ##e67e22; }
.mes-card-body { padding: 1rem; }

/* Select dropdown */
.mes-select {
    width: 100%;
    padding: .55rem .75rem;
    border: 1.5px solid ##cbd5e1;
    border-radius: 8px;
    font-size: .9rem;
    color: ##1e293b;
    background: ##fff;
    cursor: pointer;
    outline: none;
    transition: border-color .2s;
}
.mes-select:focus { border-color: ##e67e22; }
option.status-2 { font-weight: 600; color: ##16a34a; }

/* Info grid */
.order-info-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
    gap: .75rem;
}
.order-info-item label {
    display: block;
    font-size: .72rem;
    font-weight: 600;
    color: ##94a3b8;
    text-transform: uppercase;
    letter-spacing: .04em;
    margin-bottom: .2rem;
}
.order-info-item span {
    font-size: .9rem;
    font-weight: 600;
    color: ##1e293b;
}

/* Status badge */
.mes-badge {
    display: inline-flex;
    align-items: center;
    gap: .3rem;
    padding: .25rem .65rem;
    border-radius: 20px;
    font-size: .75rem;
    font-weight: 600;
}
.mes-badge-planned  { background: ##d6e4f0; color: ##1a3a5c; }
.mes-badge-running  { background: ##dcfce7; color: ##15803d; animation: pulse-green 1.8s infinite; }
.mes-badge-done     { background: ##f0fdf4; color: ##15803d; }
.mes-badge-cancelled{ background: ##fee2e2; color: ##dc2626; }

@keyframes pulse-green {
    0%, 100% { box-shadow: 0 0 0 0 rgba(22,163,74,.35); }
    50%       { box-shadow: 0 0 0 6px rgba(22,163,74,0); }
}

/* Timer */
.mes-timer-card {
    text-align: center;
    padding: 1.5rem 1rem;
    background: linear-gradient(135deg, ##0d2137 0%, ##1a3a5c 100%);
    border-radius: 12px;
    color: ##fff;
}
.mes-timer-label {
    font-size: .75rem;
    text-transform: uppercase;
    letter-spacing: .1em;
    color: ##94a3b8;
    margin-bottom: .4rem;
}
.mes-timer-value {
    font-size: 3rem;
    font-weight: 800;
    font-variant-numeric: tabular-nums;
    letter-spacing: .05em;
    color: ##4ade80;
    text-shadow: 0 0 20px rgba(74,222,128,.4);
    font-family: 'Courier New', monospace;
}
.mes-timer-value.paused { color: ##fbbf24; text-shadow: 0 0 20px rgba(251,191,36,.4); }
.mes-timer-value.idle   { color: ##94a3b8; text-shadow: none; }
.mes-timer-sub {
    margin-top: .4rem;
    font-size: .78rem;
    color: ##64748b;
}
.mes-pause-badge {
    display: inline-block;
    margin-top: .6rem;
    padding: .2rem .7rem;
    border-radius: 12px;
    background: rgba(251,191,36,.15);
    color: ##fbbf24;
    font-size: .75rem;
    font-weight: 600;
}

/* Action buttons */
.mes-actions {
    display: flex;
    gap: .75rem;
    flex-wrap: wrap;
}
.mes-btn {
    flex: 1;
    min-width: 130px;
    padding: .75rem 1rem;
    border: none;
    border-radius: 10px;
    font-size: .9rem;
    font-weight: 700;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: .5rem;
    transition: transform .1s, box-shadow .2s, opacity .2s;
}
.mes-btn:active { transform: scale(.97); }
.mes-btn:disabled { opacity: .4; cursor: not-allowed; }
.mes-btn-start    { background: linear-gradient(135deg, ##16a34a, ##22c55e); color: ##fff; box-shadow: 0 4px 12px rgba(22,163,74,.35); }
.mes-btn-start:hover:not(:disabled)  { box-shadow: 0 6px 16px rgba(22,163,74,.45); }
.mes-btn-stop     { background: linear-gradient(135deg, ##dc2626, ##ef4444); color: ##fff; box-shadow: 0 4px 12px rgba(220,38,38,.3); }
.mes-btn-stop:hover:not(:disabled)   { box-shadow: 0 6px 16px rgba(220,38,38,.4); }
.mes-btn-pause    { background: linear-gradient(135deg, ##d97706, ##f59e0b); color: ##fff; box-shadow: 0 4px 12px rgba(217,119,6,.3); }
.mes-btn-pause:hover:not(:disabled)  { box-shadow: 0 6px 16px rgba(217,119,6,.4); }
.mes-btn-complete { background: linear-gradient(135deg, ##0d2137, ##1a3a5c); color: ##fff; box-shadow: 0 4px 12px rgba(26,58,92,.35); }
.mes-btn-complete:hover:not(:disabled){ box-shadow: 0 6px 16px rgba(26,58,92,.5); }

/* Pause live timer */
.pause-live-card {
    text-align: center;
    padding: 1.5rem 1rem;
    background: linear-gradient(135deg, ##431407 0%, ##7c2d12 100%);
    border-radius: 12px;
    color: ##fff;
    border: 2px solid ##f97316;
}
.pause-live-label {
    font-size: .75rem;
    text-transform: uppercase;
    letter-spacing: .1em;
    color: ##fed7aa;
    margin-bottom: .4rem;
}
.pause-live-value {
    font-size: 3rem;
    font-weight: 800;
    font-variant-numeric: tabular-nums;
    letter-spacing: .05em;
    color: ##fbbf24;
    text-shadow: 0 0 20px rgba(251,191,36,.5);
    font-family: 'Courier New', monospace;
    animation: blink-pause .9s step-start infinite;
}
@keyframes blink-pause {
    0%,100% { opacity: 1; }
    50%      { opacity: .65; }
}
.pause-live-sub {
    margin-top: .4rem;
    font-size: .78rem;
    color: ##fdba74;
}

/* Pause history table */
.mes-table { width: 100%; border-collapse: collapse; font-size: .845rem; }
.mes-table th {
    background: ##f1f5f9;
    color: ##475569;
    font-weight: 600;
    font-size: .75rem;
    text-transform: uppercase;
    letter-spacing: .04em;
    padding: .5rem .75rem;
    border-bottom: 1px solid ##e2e8f0;
    text-align: left;
}
.mes-table td {
    padding: .5rem .75rem;
    border-bottom: 1px solid ##f1f5f9;
    color: ##334155;
    vertical-align: middle;
}
.mes-table tr:last-child td { border-bottom: none; }
.mes-table tr:hover td { background: ##f8fafc; }
.mes-empty { text-align: center; padding: 1.5rem; color: ##94a3b8; font-size: .85rem; }

/* Summary row */
.pause-summary {
    display: flex;
    gap: 1rem;
    padding: .65rem 1rem;
    background: ##fef9c3;
    border-top: 1px solid ##fde68a;
    font-size: .8rem;
    color: ##92400e;
    font-weight: 600;
}

/* Modal overlay */
.mes-modal-overlay {
    display: none;
    position: fixed; inset: 0;
    background: rgba(0,0,0,.55);
    z-index: 9000;
    align-items: center;
    justify-content: center;
}
.mes-modal-overlay.active { display: flex; }
.mes-modal {
    background: ##fff;
    border-radius: 14px;
    width: 100%;
    max-width: 440px;
    margin: 1rem;
    overflow: hidden;
    box-shadow: 0 20px 60px rgba(0,0,0,.3);
    animation: slideUp .2s ease;
}
@keyframes slideUp {
    from { transform: translateY(20px); opacity: 0; }
    to   { transform: translateY(0);    opacity: 1; }
}
.mes-modal-header {
    padding: .9rem 1.1rem;
    background: linear-gradient(135deg, ##d97706, ##f59e0b);
    color: ##fff;
    display: flex;
    align-items: center;
    justify-content: space-between;
}
.mes-modal-header h5 { margin: 0; font-size: 1rem; font-weight: 700; }
.mes-modal-close {
    background: none; border: none; color: ##fff;
    font-size: 1.2rem; cursor: pointer; line-height: 1;
}
.mes-modal-body { padding: 1.1rem; display: flex; flex-direction: column; gap: .85rem; }
.mes-form-group label {
    display: block;
    font-size: .78rem;
    font-weight: 600;
    color: ##475569;
    margin-bottom: .3rem;
}
.mes-form-control {
    width: 100%;
    padding: .5rem .75rem;
    border: 1.5px solid ##cbd5e1;
    border-radius: 8px;
    font-size: .875rem;
    outline: none;
    transition: border-color .2s;
    box-sizing: border-box;
}
.mes-form-control:focus { border-color: ##f59e0b; }
.mes-modal-footer {
    padding: .75rem 1.1rem;
    background: ##f8fafc;
    border-top: 1px solid ##e2e8f0;
    display: flex;
    gap: .65rem;
    justify-content: flex-end;
}
.mes-btn-sm {
    padding: .45rem .9rem;
    border: none;
    border-radius: 7px;
    font-size: .85rem;
    font-weight: 600;
    cursor: pointer;
}
.mes-btn-sm-cancel   { background: ##f1f5f9; color: ##475569; }
.mes-btn-sm-save     { background: linear-gradient(135deg, ##d97706, ##f59e0b); color: ##fff; }
.mes-btn-sm-complete { background: linear-gradient(135deg, ##0d2137, ##1a3a5c); color: ##fff; }

/* Toast notification */
.mes-toast {
    position: fixed;
    bottom: 1.5rem; right: 1.5rem;
    padding: .75rem 1.25rem;
    border-radius: 10px;
    color: ##fff;
    font-weight: 600;
    font-size: .875rem;
    z-index: 9999;
    display: flex;
    align-items: center;
    gap: .5rem;
    opacity: 0;
    transform: translateY(10px);
    transition: opacity .25s, transform .25s;
    pointer-events: none;
    max-width: 320px;
}
.mes-toast.show { opacity: 1; transform: translateY(0); }
.mes-toast.success { background: ##16a34a; }
.mes-toast.error   { background: ##dc2626; }
.mes-toast.info    { background: ##1a3a5c; }

/* Confirm modal (başlat/durdur) */
.mes-confirm-modal .mes-modal-header { background: linear-gradient(135deg, ##0d2137, ##1a3a5c); }
.mes-confirm-stop .mes-modal-header  { background: linear-gradient(135deg, ##b91c1c, ##ef4444); }
</style>

<!--- ======================================================
      HTML
      ====================================================== --->
<div class="mes-wrapper">

    <!--- Page Header --->
    <div class="mes-page-header">
        <div class="mes-icon"><i class="fas fa-industry"></i></div>
        <div>
            <h1>MES — Üretim Takip</h1>
            <p>Üretim emri seç · başlat · durdur · duruş ekle</p>
        </div>
    </div>

    <!--- Order Selector --->
    <div class="mes-card">
        <div class="mes-card-header">
            <span><i class="fas fa-list-ul"></i> Üretim Emri Seç</span>
        </div>
        <div class="mes-card-body">
            <select class="mes-select" id="orderSelect" onchange="selectOrder(this.value)">
                <option value="">-- Emir seçin --</option>
                <cfloop query="qOrders">
                    <option value="#val(p_order_id)#"
                        <cfif val(p_order_id) eq selOrderId>selected</cfif>
                        <cfif val(status) eq 2>class="status-2"</cfif>>
                        #p_order_no# — #color_code# #color_name# / #station_name#
                        <cfswitch expression="#val(status)#">
                            <cfcase value="1"> (Planlandı)</cfcase>
                            <cfcase value="2"> ▶ ÇALIŞIYOR</cfcase>
                        </cfswitch>
                    </option>
                </cfloop>
            </select>
        </div>
    </div>

    <cfif selOrderId gt 0 AND qSel.recordCount>

    <!--- Order Info Card --->
    <div class="mes-card">
        <div class="mes-card-header">
            <span><i class="fas fa-clipboard-list"></i> Emir Bilgileri</span>
            <span>
                <cfswitch expression="#val(qSel.status)#">
                    <cfcase value="1"><span class="mes-badge mes-badge-planned"><i class="fas fa-clock"></i> Planlandı</span></cfcase>
                    <cfcase value="2"><span class="mes-badge mes-badge-running"><i class="fas fa-circle" style="font-size:.5rem;"></i> Çalışıyor</span></cfcase>
                    <cfcase value="5"><span class="mes-badge mes-badge-done"><i class="fas fa-check"></i> Tamamlandı</span></cfcase>
                    <cfcase value="9"><span class="mes-badge mes-badge-cancelled"><i class="fas fa-times"></i> İptal</span></cfcase>
                </cfswitch>
            </span>
        </div>
        <div class="mes-card-body">
            <div class="order-info-grid">
                <div class="order-info-item">
                    <label>Emir No</label>
                    <span>#htmlEditFormat(qSel.p_order_no)#</span>
                </div>
                <div class="order-info-item">
                    <label>Stok Kodu</label>
                    <span>#htmlEditFormat(qSel.stock_code)#</span>
                </div>
                <div class="order-info-item">
                    <label>Renk</label>
                    <span>#htmlEditFormat(qSel.color_code)# #htmlEditFormat(qSel.color_name)#</span>
                </div>
                <div class="order-info-item">
                    <label>Firma</label>
                    <span>#htmlEditFormat(qSel.company_name)#</span>
                </div>
                <div class="order-info-item">
                    <label>İstasyon</label>
                    <span>#htmlEditFormat(qSel.station_name)#</span>
                </div>
                <div class="order-info-item">
                    <label>Miktar</label>
                    <span>#numberFormat(qSel.quantity, "__.___")# kg</span>
                </div>
                <div class="order-info-item">
                    <label>Lot No</label>
                    <span>#len(qSel.lot_no) ? htmlEditFormat(qSel.lot_no) : "—"#</span>
                </div>
                <cfif isDate(qSel.start_date)>
                <div class="order-info-item">
                    <label>Plan. Başlangıç</label>
                    <span>#dateFormat(qSel.start_date,"dd/mm/yyyy")# #timeFormat(qSel.start_date,"HH:mm")#</span>
                </div>
                </cfif>
                <cfif isDate(qSel.finish_date)>
                <div class="order-info-item">
                    <label>Plan. Bitiş</label>
                    <span>#dateFormat(qSel.finish_date,"dd/mm/yyyy")# #timeFormat(qSel.finish_date,"HH:mm")#</span>
                </div>
                </cfif>
            </div>
        </div>
    </div>

    <!--- Production Timer Card --->
    <div class="mes-timer-card" id="timerCard">
        <div class="mes-timer-label"><i class="fas fa-stopwatch"></i> Geçen Üretim Süresi</div>
        <div class="mes-timer-value idle" id="timerDisplay">--:--:--</div>
        <div class="mes-timer-sub" id="timerSub">
            <cfif isDate(qSel.start_date_real)>
                Başladı: #dateFormat(qSel.start_date_real,"dd/mm/yyyy")# #timeFormat(qSel.start_date_real,"HH:mm:ss")#
            <cfelse>
                Henüz başlatılmadı
            </cfif>
        </div>
        <cfif val(qSel.status) eq 2 AND qPauses.recordCount gt 0>
        <div class="mes-pause-badge" id="totalPauseBadge">
            <i class="fas fa-pause-circle"></i>
            Toplam Duruş: <span id="totalPauseMinDisplay">#totalPauseMin#</span> dk
        </div>
        </cfif>
    </div>

    <!--- Pause Live Timer Card (hidden by default) --->
    <div class="pause-live-card" id="pauseLiveCard" style="display:none;">
        <div class="pause-live-label"><i class="fas fa-pause-circle"></i> Duruş Süresi</div>
        <div class="pause-live-value" id="pauseTimerDisplay">00:00:00</div>
        <div class="pause-live-sub" id="pauseTimerSub">Duruş başladı — devam etmek için butona basın</div>
    </div>

    <!--- Action Buttons --->
    <div class="mes-actions" id="actionButtons">
        <cfif val(qSel.status) eq 1>
        <button class="mes-btn mes-btn-start" onclick="confirmStart()">
            <i class="fas fa-play"></i> Başlat
        </button>
        <cfelseif val(qSel.status) eq 2>
        <button class="mes-btn mes-btn-pause" id="btnDurus" onclick="openPauseModal()">
            <i class="fas fa-pause"></i> Duruş Ekle
        </button>
        <button class="mes-btn mes-btn-complete" id="btnTamamla" onclick="confirmComplete()">
            <i class="fas fa-check-double"></i> Tamamla
        </button>
        <button class="mes-btn mes-btn-stop" id="btnIptal" onclick="confirmStop()">
            <i class="fas fa-stop"></i> İptal Et
        </button>
        </cfif>
    </div>
    <!--- Devam Et button (shown only during active pause) --->
    <div id="devamEtArea" style="display:none;">
        <button class="mes-btn" style="background:linear-gradient(135deg,##15803d,##22c55e);color:##fff;box-shadow:0 4px 12px rgba(21,128,61,.4);width:100%;" onclick="endPause()">
            <i class="fas fa-play"></i> Devam Et (Duruşu Bitir)
        </button>
    </div>

    <!--- Pause History --->
    <div class="mes-card" id="pauseHistorySection">
        <div class="mes-card-header">
            <span><i class="fas fa-history"></i> Duruş Geçmişi</span>
            <span style="font-size:.78rem; font-weight:500; color:##8a98a8; background:##f0f4f8; padding:2px 10px; border-radius:20px;">
                #qPauses.recordCount# kayıt
            </span>
        </div>
        <cfif qPauses.recordCount>
        <div style="overflow-x:auto;">
            <table class="mes-table">
                <thead>
                    <tr>
                        <th>Tarih</th>
                        <th>Tip</th>
                        <th>Süre (dk)</th>
                        <th>Çarpma Süresi</th>
                        <th>Açıklama</th>
                        <th>Ç.Süre?</th>
                    </tr>
                </thead>
                <tbody>
                    <cfloop query="qPauses">
                    <tr>
                        <td>#isDate(action_date) ? dateFormat(action_date,"dd/mm/yyyy") & " " & timeFormat(action_date,"HH:mm") : "—"#</td>
                        <td>#len(pause_type) ? htmlEditFormat(pause_type) : "—"#</td>
                        <td><strong>#val(prod_duration)#</strong></td>
                        <td style="font-size:.78rem; color:##64748b;">
                            <cfif isDate(duration_start_date) AND isDate(duration_finish_date)>
                                #timeFormat(duration_start_date,"HH:mm")# – #timeFormat(duration_finish_date,"HH:mm")#
                            <cfelse>—</cfif>
                        </td>
                        <td>#len(prod_detail) ? htmlEditFormat(prod_detail) : "—"#</td>
                        <td>
                            <cfif is_working_time>
                                <span class="mes-badge mes-badge-running" style="font-size:.7rem;">Evet</span>
                            <cfelse>
                                <span class="mes-badge mes-badge-planned" style="font-size:.7rem;">Hayır</span>
                            </cfif>
                        </td>
                    </tr>
                    </cfloop>
                </tbody>
            </table>
        </div>
        <div class="pause-summary">
            <span><i class="fas fa-clock"></i> Toplam Duruş: <strong>#totalPauseMin# dk</strong></span>
            <span>(<strong>#int(totalPauseMin/60)#</strong> sa <strong>#totalPauseMin mod 60#</strong> dk)</span>
        </div>
        <cfelse>
        <div class="mes-empty"><i class="fas fa-check-circle" style="color:##22c55e;"></i> Duruş kaydı bulunmuyor.</div>
        </cfif>
    </div>

    <cfelse>
    <!--- No order selected --->
    <div class="mes-card">
        <div class="mes-card-body mes-empty" style="padding:2.5rem;">
            <i class="fas fa-arrow-up" style="font-size:2rem; color:##cbd5e1; display:block; margin-bottom:.75rem;"></i>
            Yukarıdan bir üretim emri seçin.
        </div>
    </div>
    </cfif>

</div>

<!--- ---------------------- DURUŞ BAŞLAT MODAL (Adım 1) ----------------------- --->
<div class="mes-modal-overlay" id="pauseModal">
    <div class="mes-modal">
        <div class="mes-modal-header">
            <h5><i class="fas fa-pause-circle"></i> Duruş Başlat</h5>
            <button class="mes-modal-close" onclick="closePauseModal()">&times;</button>
        </div>
        <div class="mes-modal-body">
            <div class="mes-form-group">
                <label>Duruş Tipi</label>
                <select class="mes-form-control" id="pauseTypeId">
                    <option value="">-- Seçin (opsiyonel) --</option>
                    <cfloop query="qPauseTypes">
                    <option value="#val(prod_pause_type_id)#">#htmlEditFormat(prod_pause_type)#</option>
                    </cfloop>
                </select>
            </div>
            <div class="mes-form-group">
                <label>Açıklama <span style="color:##94a3b8;font-weight:400;">(opsiyonel)</span></label>
                <textarea class="mes-form-control" id="pauseDetail" rows="2" placeholder="Duruş nedeni..."></textarea>
            </div>
            <div class="mes-form-group">
                <label style="display:flex; align-items:center; gap:.5rem; cursor:pointer;">
                    <input type="checkbox" id="pauseIsWorking" style="width:16px;height:16px;">
                    Çalışma süresine say
                </label>
            </div>
            <div style="background:##fef3c7;border:1px solid ##fde68a;border-radius:8px;padding:.75rem;font-size:.82rem;color:##92400e;">
                <i class="fas fa-info-circle"></i>
                "Duruşa Geç" butonuna basınca duruş sayacı başlayacak.
                Hazır olduğunuzda <strong>Devam Et</strong> butonuyla duruşu bitirebilirsiniz.
            </div>
        </div>
        <div class="mes-modal-footer">
            <button class="mes-btn-sm mes-btn-sm-cancel" onclick="closePauseModal()">İptal</button>
            <button class="mes-btn-sm" style="background:linear-gradient(135deg,##d97706,##f59e0b);color:##fff;" onclick="startPause()">
                <i class="fas fa-pause"></i> Duruşa Geç
            </button>
        </div>
    </div>
</div>

<!--- ---------------------- BAŞLAT CONFIRM ----------------------- --->
<div class="mes-modal-overlay mes-confirm-modal" id="startModal">
    <div class="mes-modal">
        <div class="mes-modal-header">
            <h5><i class="fas fa-play"></i> Üretimi Başlat</h5>
            <button class="mes-modal-close" onclick="closeModal('startModal')">&times;</button>
        </div>
        <div class="mes-modal-body" style="align-items:center; padding:1.5rem;">
            <i class="fas fa-play-circle" style="font-size:3rem; color:##16a34a;"></i>
            <p style="text-align:center; color:##1e293b; font-weight:600; margin:.5rem 0 0;">
                Üretim emri başlatılsın mı?
            </p>
            <p style="text-align:center; color:##64748b; font-size:.85rem; margin:.25rem 0 0;" id="startOrderLabel"></p>
        </div>
        <div class="mes-modal-footer">
            <button class="mes-btn-sm mes-btn-sm-cancel" onclick="closeModal('startModal')">İptal</button>
            <button class="mes-btn-sm mes-btn-sm-save" onclick="doStart()">
                <i class="fas fa-play"></i> Başlat
            </button>
        </div>
    </div>
</div>

<!--- ---------------------- TAMAMLA CONFIRM ----------------------- --->
<div class="mes-modal-overlay mes-confirm-modal" id="completeModal">
    <div class="mes-modal">
        <div class="mes-modal-header" style="background:linear-gradient(135deg,##0d2137,##1a3a5c);">
            <h5><i class="fas fa-check-double"></i> Üretimi Tamamla</h5>
            <button class="mes-modal-close" onclick="closeModal('completeModal')">&times;</button>
        </div>
        <div class="mes-modal-body" style="align-items:center; padding:1.5rem;">
            <i class="fas fa-check-circle" style="font-size:3rem; color:##1a3a5c;"></i>
            <p style="text-align:center; color:##1e293b; font-weight:600; margin:.5rem 0 0;">
                Üretim tamamlandı olarak işaretlensin mi?
            </p>
        </div>
        <div class="mes-modal-footer">
            <button class="mes-btn-sm mes-btn-sm-cancel" onclick="closeModal('completeModal')">İptal</button>
            <button class="mes-btn-sm mes-btn-sm-complete" onclick="doStatusChange(5)">
                <i class="fas fa-check"></i> Tamamla
            </button>
        </div>
    </div>
</div>

<!--- ---------------------- İPTAL CONFIRM ----------------------- --->
<div class="mes-modal-overlay mes-confirm-stop" id="stopModal">
    <div class="mes-modal">
        <div class="mes-modal-header">
            <h5><i class="fas fa-stop"></i> Üretimi İptal Et</h5>
            <button class="mes-modal-close" onclick="closeModal('stopModal')">&times;</button>
        </div>
        <div class="mes-modal-body" style="align-items:center; padding:1.5rem;">
            <i class="fas fa-exclamation-triangle" style="font-size:3rem; color:##ef4444;"></i>
            <p style="text-align:center; color:##1e293b; font-weight:600; margin:.5rem 0 0;">
                Üretim emri iptal edilsin mi?
            </p>
            <p style="text-align:center; color:##64748b; font-size:.85rem;">Bu işlem geri alınamaz.</p>
        </div>
        <div class="mes-modal-footer">
            <button class="mes-btn-sm mes-btn-sm-cancel" onclick="closeModal('stopModal')">Vazgeç</button>
            <button class="mes-btn-sm" style="background:##ef4444;color:##ffffff;" onclick="doStatusChange(9)">
                <i class="fas fa-stop"></i> İptal Et
            </button>
        </div>
    </div>
</div>

<!--- Toast --->
<div class="mes-toast" id="mesToast"></div>

<!--- ======================================================
      JAVASCRIPT
      ====================================================== --->
<script>
(function() {
    /* ================================================================
       STATE
    ================================================================ */
    var orderId   = #val(jsOrderId)#;
    var status    = #val(jsStatus)#;
    var startReal = "#jsStringFormat(jsStartReal)#";

    /* Production timer */
    var prodInterval = null;
    var prodStartTs  = startReal ? new Date(startReal).getTime() : 0;
    var prodPausedMs = 0;   /* total ms paused so far (to offset prod timer) */

    /* Pause timer state */
    var pauseInterval  = null;
    var pauseStartTs   = 0;    /* ms timestamp when current pause started */
    var pauseTypeId    = '';
    var pauseDetail    = '';
    var pauseIsWorking = false;

    /* ================================================================
       INIT
    ================================================================ */
    if (status === 2 && prodStartTs > 0) {
        startProdTimer();
    }

    /* ================================================================
       ORDER SELECT
    ================================================================ */
    window.selectOrder = function(v) {
        if (!v) return;
        window.location.href = 'index.cfm?fuseaction=production.mes&p_order_id=' + v;
    };

    /* ================================================================
       PRODUCTION TIMER
    ================================================================ */
    function startProdTimer() {
        updateProdTimer();
        prodInterval = setInterval(updateProdTimer, 1000);
        var td = document.getElementById('timerDisplay');
        td.classList.remove('idle', 'paused');
    }

    function stopProdTimer() {
        clearInterval(prodInterval);
        prodInterval = null;
        var td = document.getElementById('timerDisplay');
        td.classList.add('paused');
    }

    function resumeProdTimer() {
        var td = document.getElementById('timerDisplay');
        td.classList.remove('paused');
        prodInterval = setInterval(updateProdTimer, 1000);
    }

    function updateProdTimer() {
        if (!prodStartTs) return;
        /* subtract time spent in pauses so far */
        var elapsed = Math.floor((Date.now() - prodStartTs - prodPausedMs) / 1000);
        if (elapsed < 0) elapsed = 0;
        document.getElementById('timerDisplay').textContent = formatSec(elapsed);
    }

    /* ================================================================
       PAUSE TIMER
    ================================================================ */
    function startPauseTimer() {
        pauseStartTs = Date.now();
        updatePauseTimer();
        pauseInterval = setInterval(updatePauseTimer, 1000);
    }

    function updatePauseTimer() {
        var elapsed = Math.floor((Date.now() - pauseStartTs) / 1000);
        document.getElementById('pauseTimerDisplay').textContent = formatSec(elapsed);
    }

    function stopPauseTimer() {
        clearInterval(pauseInterval);
        pauseInterval = null;
    }

    function formatSec(total) {
        var h = Math.floor(total / 3600);
        var m = Math.floor((total % 3600) / 60);
        var s = total % 60;
        return pad(h) + ':' + pad(m) + ':' + pad(s);
    }
    function pad(n) { return n < 10 ? '0' + n : '' + n; }

    /* ================================================================
       PAUSE MODAL — STEP 1: collect type + detail, then go to live timer
    ================================================================ */
    window.openPauseModal = function() {
        document.getElementById('pauseTypeId').value    = '';
        document.getElementById('pauseDetail').value    = '';
        document.getElementById('pauseIsWorking').checked = false;
        openModal('pauseModal');
    };
    window.closePauseModal = function() { closeModal('pauseModal'); };

    /* "Duruşa Geç" button in modal */
    window.startPause = function() {
        pauseTypeId    = document.getElementById('pauseTypeId').value;
        pauseDetail    = document.getElementById('pauseDetail').value.trim();
        pauseIsWorking = document.getElementById('pauseIsWorking').checked;

        closePauseModal();

        /* Stop production timer — show pause timer */
        stopProdTimer();

        document.getElementById('pauseLiveCard').style.display  = 'block';
        document.getElementById('timerCard').style.opacity      = '0.35';
        document.getElementById('actionButtons').style.display  = 'none';
        document.getElementById('devamEtArea').style.display    = 'block';

        startPauseTimer();
    };

    /* ================================================================
       "DEVAM ET" — end pause, save to DB, resume production
    ================================================================ */
    window.endPause = function() {
        var pauseEndTs = Date.now();
        stopPauseTimer();

        var durationMs  = pauseEndTs - pauseStartTs;
        var durationMin = Math.max(1, Math.round(durationMs / 60000));

        /* accumulate paused millis so production timer stays accurate */
        prodPausedMs += durationMs;

        var startIso = toISOLocal(new Date(pauseStartTs));
        var endIso   = toISOLocal(new Date(pauseEndTs));

        /* Disable button immediately to prevent double-click */
        var btn = document.querySelector('##devamEtArea button');
        if (btn) { btn.disabled = true; btn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Kaydediliyor...'; }

        $.ajax({
            url:  'index.cfm?fuseaction=production.save_production_pause',
            type: 'POST',
            data: {
                p_order_id:           orderId,
                pause_type_id:        pauseTypeId,
                prod_duration:        durationMin,
                prod_detail:          pauseDetail,
                duration_start_date:  startIso,
                duration_finish_date: endIso,
                is_working_time:      pauseIsWorking ? '1' : '0'
            },
            dataType: 'json',
            success: function(r) {
                if (r && r.success) {
                    /* Update total pause badge without reloading */
                    var badge = document.getElementById('totalPauseBadge');
                    var span  = document.getElementById('totalPauseMinDisplay');
                    if (span) {
                        var prev = parseInt(span.textContent) || 0;
                        span.textContent = prev + durationMin;
                    }
                    if (badge) badge.style.display = 'inline-block';

                    showToast('Duruş kaydedildi. Üretim devam ediyor.', 'success');

                    /* Refresh pause history via AJAX */
                    loadPauseHistory();

                    /* Restore production UI */
                    document.getElementById('pauseLiveCard').style.display  = 'none';
                    document.getElementById('timerCard').style.opacity      = '1';
                    document.getElementById('actionButtons').style.display  = 'flex';
                    document.getElementById('devamEtArea').style.display    = 'none';

                    resumeProdTimer();
                } else {
                    showToast((r && r.message) ? r.message : 'Kayıt hatası.', 'error');
                    if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-play"></i> Devam Et (Duruşu Bitir)'; }
                }
            },
            error: function() {
                showToast('Sunucu hatası.', 'error');
                if (btn) { btn.disabled = false; btn.innerHTML = '<i class="fas fa-play"></i> Devam Et (Duruşu Bitir)'; }
            }
        });
    };

    /* Load pause history via AJAX and rebuild the section */
    function loadPauseHistory() {
        if (!orderId) return;
        $.getJSON('mes_pauses_ajax.cfm?p_order_id=' + orderId, function(data) {
            if (!data || !data.success) return;

            var sec = document.getElementById('pauseHistorySection');
            if (!sec) return;

            /* Update total pause badge */
            var span = document.getElementById('totalPauseMinDisplay');
            var badge = document.getElementById('totalPauseBadge');
            if (span) span.textContent = data.totalPauseMin;
            if (badge) badge.style.display = data.totalPauseMin > 0 ? 'inline-block' : 'none';

            var html = '<div class="mes-card-header">' +
                '<span><i class="fas fa-history"></i> Duruş Geçmişi</span>' +
                '<span style="font-size:.78rem;font-weight:500;color:##8a98a8;background:##f0f4f8;padding:2px 10px;border-radius:20px;">' +
                data.recordCount + ' kayıt</span></div>';

            if (data.recordCount > 0) {
                html += '<div style="overflow-x:auto;"><table class="mes-table"><thead><tr>' +
                    '<th>Tarih</th><th>Tip</th><th>Süre (dk)</th><th>Çarpma Süresi</th><th>Açıklama</th><th>Ç.Süre?</th>' +
                    '</tr></thead><tbody>';
                data.rows.forEach(function(r) {
                    var timeRange = (r.duration_start_date && r.duration_finish_date)
                        ? r.duration_start_date + ' – ' + r.duration_finish_date : '—';
                    html += '<tr>' +
                        '<td>' + (r.action_date || '—') + '</td>' +
                        '<td>' + (r.pause_type  || '—') + '</td>' +
                        '<td><strong>' + r.prod_duration + '</strong></td>' +
                        '<td style="font-size:.78rem;color: ##64748b;">' + timeRange + '</td>' +
                        '<td>' + (r.prod_detail || '—') + '</td>' +
                        '<td>' + (r.is_working_time
                            ? '<span class="mes-badge mes-badge-running" style="font-size:.7rem;">Evet</span>'
                            : '<span class="mes-badge mes-badge-planned" style="font-size:.7rem;">Hayır</span>') + '</td>' +
                        '</tr>';
                });
                var h = Math.floor(data.totalPauseMin / 60);
                var m = data.totalPauseMin % 60;
                html += '</tbody></table></div>' +
                    '<div class="pause-summary">' +
                    '<span><i class="fas fa-clock"></i> Toplam Duruş: <strong>' + data.totalPauseMin + ' dk</strong></span>' +
                    '<span>(<strong>' + h + '</strong> sa <strong>' + m + '</strong> dk)</span></div>';
            } else {
                html += '<div class="mes-empty"><i class="fas fa-check-circle" style="color:##22c55e;"></i> Duruş kaydı bulunmuyor.</div>';
            }

            sec.innerHTML = html;
        });
    }

    /* ================================================================
       STATUS CHANGES (Başlat / Tamamla / İptal)
    ================================================================ */
    window.confirmStart    = function() {
        var sel = document.getElementById('orderSelect');
        var txt = sel ? sel.options[sel.selectedIndex].text : '';
        document.getElementById('startOrderLabel').textContent = txt;
        openModal('startModal');
    };
    window.confirmComplete = function() { openModal('completeModal'); };
    window.confirmStop     = function() { openModal('stopModal'); };

    window.doStart = function() {
        closeModal('startModal');
        doStatusChange(2);
    };

    window.doStatusChange = function(newStatus) {
        closeModal('completeModal');
        closeModal('stopModal');
        if (!orderId) { showToast('Üretim emri seçilmedi.', 'error'); return; }
        $.ajax({
            url:  'index.cfm?fuseaction=production.update_production_status',
            type: 'POST',
            data: { p_order_id: orderId, status: newStatus },
            dataType: 'json',
            success: function(r) {
                if (r && r.success) {
                    showToast(
                        newStatus === 2 ? 'Üretim başlatıldı.' :
                        newStatus === 5 ? 'Üretim tamamlandı.' :
                        newStatus === 9 ? 'Üretim iptal edildi.' : 'Durum güncellendi.',
                        'success'
                    );
                    setTimeout(function() {
                        window.location.href = 'index.cfm?fuseaction=production.mes&p_order_id=' + orderId;
                    }, 900);
                } else {
                    showToast((r && r.message) ? r.message : 'Bir hata oluştu.', 'error');
                }
            },
            error: function() { showToast('Sunucu hatası.', 'error'); }
        });
    };

    /* ================================================================
       UTILITIES
    ================================================================ */
    function openModal(id)  { document.getElementById(id).classList.add('active'); }
    window.closeModal = function(id) { document.getElementById(id).classList.remove('active'); };

    function showToast(msg, type) {
        var t = document.getElementById('mesToast');
        t.className = 'mes-toast ' + type;
        t.innerHTML = '<i class="fas fa-' +
            (type==='success' ? 'check-circle' : type==='error' ? 'exclamation-circle' : 'info-circle') +
            '"></i> ' + msg;
        t.classList.add('show');
        setTimeout(function() { t.classList.remove('show'); }, 3500);
    }

    function toISOLocal(d) {
        var p = function(n) { return n < 10 ? '0'+n : n; };
        return d.getFullYear() + '-' + p(d.getMonth()+1) + '-' + p(d.getDate()) +
               'T' + p(d.getHours()) + ':' + p(d.getMinutes()) + ':' + p(d.getSeconds());
    }

    document.querySelectorAll('.mes-modal-overlay').forEach(function(el) {
        el.addEventListener('click', function(e) {
            if (e.target === el) el.classList.remove('active');
        });
    });

})();
</script>
</cfoutput>
