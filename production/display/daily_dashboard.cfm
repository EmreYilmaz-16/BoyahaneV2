<cfprocessingdirective pageEncoding="utf-8">

<cfset today = now()>
<cfset todayStart = createDateTime(year(today), month(today), day(today), 0, 0, 0)>
<cfset todayEnd   = createDateTime(year(today), month(today), day(today), 23, 59, 59)>

<!--- Bugünkü üretim emirleri özeti (status bazlı sayım ve toplam miktar) --->
<cfquery name="qDailySummary" datasource="boyahane">
    SELECT
        COUNT(*)                                                                        AS total_orders,
        SUM(CASE WHEN COALESCE(po.status,1) = 1 THEN 1 ELSE 0 END)                    AS total_planned,
        SUM(CASE WHEN COALESCE(po.status,1) = 2 THEN 1 ELSE 0 END)                    AS total_active,
        SUM(CASE WHEN COALESCE(po.status,1) = 5 THEN 1 ELSE 0 END)                    AS total_done,
        SUM(CASE WHEN COALESCE(po.status,1) = 9 THEN 1 ELSE 0 END)                    AS total_cancelled,
        COALESCE(SUM(CASE WHEN COALESCE(po.status,1) = 5 THEN COALESCE(po.quantity,0) ELSE 0 END), 0) AS qty_done,
        COALESCE(SUM(CASE WHEN COALESCE(po.status,1) = 2 THEN COALESCE(po.quantity,0) ELSE 0 END), 0) AS qty_active,
        COALESCE(SUM(COALESCE(po.quantity,0)), 0)                                       AS qty_total
    FROM production_orders po
    WHERE DATE(COALESCE(po.start_date, po.record_date)) = CURRENT_DATE
       OR DATE(po.finish_date_real) = CURRENT_DATE
</cfquery>

<!--- İstasyon bazlı üretim durumu --->
<cfquery name="qByStation" datasource="boyahane">
    SELECT
        COALESCE(ws.station_name, 'Atanmamış')                                  AS station_name,
        COUNT(*)                                                                 AS order_count,
        SUM(CASE WHEN COALESCE(po.status,1) = 2 THEN 1 ELSE 0 END)             AS active_count,
        SUM(CASE WHEN COALESCE(po.status,1) = 5 THEN 1 ELSE 0 END)             AS done_count,
        COALESCE(SUM(CASE WHEN COALESCE(po.status,1) = 5
                     THEN COALESCE(po.quantity,0) ELSE 0 END), 0)               AS done_qty,
        COALESCE(SUM(COALESCE(po.quantity,0)),0)                                AS total_qty
    FROM production_orders po
    LEFT JOIN workstations ws ON ws.station_id = po.station_id
    WHERE COALESCE(po.status,1) NOT IN (9)
      AND (DATE(COALESCE(po.start_date, po.record_date)) = CURRENT_DATE
           OR DATE(po.finish_date_real) = CURRENT_DATE
           OR COALESCE(po.status,1) = 2)
    GROUP BY ws.station_id, ws.station_name
    ORDER BY active_count DESC, done_count DESC
</cfquery>

<!--- Aktif üretim emirleri (devam eden) --->
<cfquery name="qActiveOrders" datasource="boyahane">
    SELECT
        po.p_order_id,
        COALESCE(po.p_order_no,'')                          AS p_order_no,
        COALESCE(ci.color_code, s.stock_code, '')           AS color_code,
        COALESCE(ci.color_name, s.property, '')             AS color_name,
        COALESCE(c.nickname, c.fullname,'')                 AS company_name,
        COALESCE(ws.station_name,'')                        AS station_name,
        COALESCE(po.quantity, 0)                            AS quantity,
        COALESCE(po.lot_no,'')                              AS lot_no,
        po.start_date,
        po.finish_date,
        COALESCE(po.is_urgent, false)                       AS is_urgent,
        COALESCE((
            SELECT COUNT(*) FROM setup_prod_pause sp
            WHERE sp.p_order_id = po.p_order_id
              AND sp.duration_finish_date IS NULL
        ), 0)                                               AS active_pause_count,
        COALESCE((
            SELECT SUM(COALESCE(sp.prod_duration,0)) FROM setup_prod_pause sp
            WHERE sp.p_order_id = po.p_order_id
        ), 0)                                               AS total_pause_min
    FROM production_orders po
    LEFT JOIN stocks       s   ON po.stock_id   = s.stock_id
    LEFT JOIN color_info   ci  ON po.stock_id   = ci.stock_id
    LEFT JOIN company      c   ON ci.company_id = c.company_id
    LEFT JOIN workstations ws  ON po.station_id = ws.station_id
    WHERE po.status = 2
    ORDER BY po.is_urgent DESC, po.start_date ASC
</cfquery>

<!--- Bugün tamamlanan emirler --->
<cfquery name="qCompletedToday" datasource="boyahane">
    SELECT
        po.p_order_id,
        COALESCE(po.p_order_no,'')                          AS p_order_no,
        COALESCE(ci.color_code, s.stock_code, '')           AS color_code,
        COALESCE(ci.color_name, s.property, '')             AS color_name,
        COALESCE(c.nickname, c.fullname,'')                 AS company_name,
        COALESCE(ws.station_name,'')                        AS station_name,
        COALESCE(po.quantity, 0)                            AS quantity,
        COALESCE(po.lot_no,'')                              AS lot_no,
        po.finish_date_real
    FROM production_orders po
    LEFT JOIN stocks       s   ON po.stock_id   = s.stock_id
    LEFT JOIN color_info   ci  ON po.stock_id   = ci.stock_id
    LEFT JOIN company      c   ON ci.company_id = c.company_id
    LEFT JOIN workstations ws  ON po.station_id = ws.station_id
    WHERE po.status = 5
      AND DATE(po.finish_date_real) = CURRENT_DATE
    ORDER BY po.finish_date_real DESC
</cfquery>

<!--- Geciken emirler (bitiş tarihi geçmiş, tamamlanmamış) --->
<cfquery name="qOverdue" datasource="boyahane">
    SELECT
        po.p_order_id,
        COALESCE(po.p_order_no,'')                          AS p_order_no,
        COALESCE(ci.color_code, s.stock_code, '')           AS color_code,
        COALESCE(ci.color_name, s.property, '')             AS color_name,
        COALESCE(c.nickname, c.fullname,'')                 AS company_name,
        COALESCE(ws.station_name,'')                        AS station_name,
        COALESCE(po.quantity, 0)                            AS quantity,
        po.finish_date,
        CURRENT_DATE - po.finish_date                       AS overdue_days
    FROM production_orders po
    LEFT JOIN stocks       s   ON po.stock_id   = s.stock_id
    LEFT JOIN color_info   ci  ON po.stock_id   = ci.stock_id
    LEFT JOIN company      c   ON ci.company_id = c.company_id
    LEFT JOIN workstations ws  ON po.station_id = ws.station_id
    WHERE po.finish_date < CURRENT_DATE
      AND COALESCE(po.status,1) NOT IN (5, 9)
    ORDER BY po.finish_date ASC
    LIMIT 20
</cfquery>

<cfset completionRate = 0>
<cfif val(qDailySummary.total_orders) gt 0>
    <cfset completionRate = int((val(qDailySummary.total_done) / val(qDailySummary.total_orders)) * 100)>
</cfif>

<cfoutput>
<style>
/* ===== DAILY DASHBOARD ===== */
.dd-page { padding: 0 4px 32px; }

/* Header */
.dd-header {
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
.dd-header-left  { display: flex; align-items: center; gap: 16px; }
.dd-header-icon  {
    width: 48px; height: 48px;
    background: ##e67e22;
    border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.35rem; color: ##fff;
    box-shadow: 0 4px 14px rgba(230,126,34,.4);
    flex-shrink: 0;
}
.dd-header-title { font-size: 1.25rem; font-weight: 800; color: ##fff; margin: 0 0 3px; }
.dd-header-sub   { font-size: 0.78rem; color: rgba(255,255,255,.55); margin: 0; }
.dd-header-btn {
    background: rgba(255,255,255,.12);
    border: 1px solid rgba(255,255,255,.2);
    color: ##fff;
    font-size: 0.82rem; font-weight: 600;
    padding: 7px 16px;
    border-radius: 8px;
    text-decoration: none;
    display: inline-flex; align-items: center; gap: 6px;
    transition: background .15s;
    cursor: pointer;
}
.dd-header-btn:hover { background: rgba(255,255,255,.22); color: ##fff; }

/* Özet Kartları */
.dd-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 12px;
    margin-bottom: 22px;
}
.dd-stat {
    background: ##fff;
    border-radius: 12px;
    padding: 16px;
    display: flex; align-items: center; gap: 14px;
    box-shadow: 0 2px 10px rgba(0,0,0,.06);
    border: 1px solid ##f1f5f9;
    transition: transform .15s, box-shadow .15s;
}
.dd-stat:hover { transform: translateY(-2px); box-shadow: 0 6px 18px rgba(0,0,0,.10); }
.dd-stat-icon {
    width: 44px; height: 44px;
    border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.2rem; flex-shrink: 0;
}
.dd-stat-icon.total    { background: ##eff6ff; color: ##3b82f6; }
.dd-stat-icon.active   { background: ##fef3c7; color: ##d97706; }
.dd-stat-icon.done     { background: ##f0fdf4; color: ##16a34a; }
.dd-stat-icon.overdue  { background: ##fef2f2; color: ##dc2626; }
.dd-stat-icon.qty      { background: ##f5f3ff; color: ##7c3aed; }
.dd-stat-label { font-size: 0.7rem; font-weight: 600; color: ##94a3b8; text-transform: uppercase; letter-spacing: .04em; margin-bottom: 2px; }
.dd-stat-val   { font-size: 1.65rem; font-weight: 800; line-height: 1.1; color: ##0f172a; }
.dd-stat-sub   { font-size: 0.7rem; color: ##94a3b8; margin-top: 1px; }

/* Bölüm başlıkları */
.dd-section-title {
    font-size: 0.8rem;
    font-weight: 700;
    color: ##475569;
    text-transform: uppercase;
    letter-spacing: .06em;
    margin: 0 0 10px;
    display: flex; align-items: center; gap: 7px;
}
.dd-section-title::after {
    content: '';
    flex: 1;
    height: 1px;
    background: ##e2e8f0;
}

/* Tamamlanma çubuğu */
.dd-progress-bar-wrap {
    background: ##f1f5f9;
    border-radius: 99px;
    height: 8px;
    overflow: hidden;
    margin-top: 6px;
}
.dd-progress-bar-fill {
    height: 100%;
    border-radius: 99px;
    background: linear-gradient(90deg, ##16a34a, ##22c55e);
    transition: width .6s ease;
}

/* İstasyon kartları */
.dd-station-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
    gap: 12px;
    margin-bottom: 22px;
}
.dd-station-card {
    background: ##fff;
    border-radius: 12px;
    padding: 14px 16px;
    box-shadow: 0 2px 10px rgba(0,0,0,.06);
    border: 1px solid ##e5e7eb;
    border-left: 4px solid ##1a3a5c;
}
.dd-station-name { font-weight: 700; font-size: 0.88rem; color: ##0f172a; margin-bottom: 8px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.dd-station-meta { font-size: 0.75rem; color: ##64748b; display: flex; justify-content: space-between; }
.dd-station-badge { font-size: 0.68rem; font-weight: 700; padding: 2px 8px; border-radius: 99px; }

/* Tablo kartı */
.dd-table-card {
    background: ##fff;
    border-radius: 14px;
    box-shadow: 0 2px 10px rgba(0,0,0,.06);
    border: 1px solid ##e5e7eb;
    overflow: hidden;
    margin-bottom: 22px;
}
.dd-table-card .table { margin: 0; }
.dd-table-card thead th {
    background: var(--primary, ##1a3a5c);
    color: ##fff;
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: .04em;
    border: none;
    padding: 10px 12px;
    white-space: nowrap;
}
.dd-table-card tbody td { font-size: 0.82rem; padding: 9px 12px; vertical-align: middle; border-color: ##f1f5f9; }
.dd-table-card tbody tr:last-child td { border-bottom: none; }
.dd-table-card tbody tr:hover td { background: ##f8fafc; }

/* Boş durum */
.dd-empty {
    text-align: center;
    padding: 28px 16px;
    color: ##94a3b8;
}
.dd-empty i { font-size: 2rem; display: block; margin-bottom: 8px; }
.dd-empty p { font-size: 0.82rem; margin: 0; }

/* Acil badge */
.badge-urgent { background: ##dc2626; color: ##fff; font-size: 0.65rem; padding: 2px 7px; border-radius: 99px; font-weight: 700; }
/* Duruştaki buton */
.badge-pause { background: ##f59e0b; color: ##fff; font-size: 0.65rem; padding: 2px 7px; border-radius: 99px; font-weight: 700; }
</style>

<div class="dd-page">

    <!--- HEADER --->
    <div class="dd-header">
        <div class="dd-header-left">
            <div class="dd-header-icon"><i class="bi bi-speedometer2"></i></div>
            <div>
                <p class="dd-header-title">Günlük Üretim Özeti</p>
                <p class="dd-header-sub">
                    <i class="bi bi-calendar3 me-1"></i>#dateFormat(today, "dd MMMM yyyy")# &nbsp;|&nbsp;
                    Son güncelleme: #timeFormat(today, "HH:mm")#
                </p>
            </div>
        </div>
        <div class="d-flex gap-2 flex-wrap">
            <a href="index.cfm?fuseaction=production.list_production_orders" class="dd-header-btn">
                <i class="bi bi-list-ul"></i> Tüm Emirler
            </a>
            <button class="dd-header-btn" onclick="location.reload()">
                <i class="bi bi-arrow-clockwise"></i> Yenile
            </button>
        </div>
    </div>

    <!--- ÖZET KARTLARI --->
    <div class="dd-stats">
        <div class="dd-stat">
            <div class="dd-stat-icon total"><i class="bi bi-file-earmark-text"></i></div>
            <div>
                <div class="dd-stat-label">Toplam Emir</div>
                <div class="dd-stat-val">#val(qDailySummary.total_orders)#</div>
                <div class="dd-stat-sub">bugün</div>
            </div>
        </div>
        <div class="dd-stat">
            <div class="dd-stat-icon active"><i class="bi bi-play-circle"></i></div>
            <div>
                <div class="dd-stat-label">Devam Eden</div>
                <div class="dd-stat-val">#val(qDailySummary.total_active)#</div>
                <div class="dd-stat-sub">#val(qDailySummary.qty_active)# kg aktif</div>
            </div>
        </div>
        <div class="dd-stat">
            <div class="dd-stat-icon done"><i class="bi bi-check-circle"></i></div>
            <div>
                <div class="dd-stat-label">Tamamlanan</div>
                <div class="dd-stat-val">#val(qDailySummary.total_done)#</div>
                <div class="dd-stat-sub">#val(qDailySummary.qty_done)# kg üretildi</div>
            </div>
        </div>
        <div class="dd-stat">
            <div class="dd-stat-icon overdue"><i class="bi bi-exclamation-triangle"></i></div>
            <div>
                <div class="dd-stat-label">Geciken</div>
                <div class="dd-stat-val">#qOverdue.recordCount#</div>
                <div class="dd-stat-sub">emir gecikmiş</div>
            </div>
        </div>
        <div class="dd-stat">
            <div class="dd-stat-icon qty"><i class="bi bi-bar-chart"></i></div>
            <div>
                <div class="dd-stat-label">Tamamlanma</div>
                <div class="dd-stat-val">#completionRate#%</div>
                <div class="dd-progress-bar-wrap" style="width:80px;">
                    <div class="dd-progress-bar-fill" style="width:#completionRate#%;"></div>
                </div>
            </div>
        </div>
    </div>

    <!--- İSTASYON BAZLI DURUM --->
    <p class="dd-section-title"><i class="bi bi-diagram-3"></i> İstasyon Durumu</p>
    <cfif qByStation.recordCount gt 0>
        <div class="dd-station-grid">
            <cfloop query="qByStation">
            <cfset stationProgress = val(total_qty) gt 0 ? int((val(done_qty) / val(total_qty)) * 100) : 0>
            <div class="dd-station-card">
                <div class="dd-station-name" title="#htmlEditFormat(station_name)#">
                    <i class="bi bi-gear-fill me-1" style="color:var(--accent);font-size:.75rem;"></i>
                    #htmlEditFormat(station_name)#
                </div>
                <div class="dd-station-meta mb-2">
                    <span>#val(order_count)# emir</span>
                    <span>
                        <cfif val(active_count) gt 0>
                            <span class="dd-station-badge" style="background:var(--accent);color:var(--primary);">#val(active_count)# aktif</span>
                        </cfif>
                        <cfif val(done_count) gt 0>
                            <span class="dd-station-badge ms-1" style="background:var(--content-bg);color:var(--primary);">#val(done_count)# bitti</span>
                        </cfif>
                    </span>
                </div>
                <div style="font-size:0.72rem;color:##64748b;margin-bottom:4px;">
                    #val(done_qty)# / #val(total_qty)# kg &mdash; %#stationProgress#
                </div>
                <div class="dd-progress-bar-wrap">
                    <div class="dd-progress-bar-fill" style="width:#stationProgress#%;"></div>
                </div>
            </div>
            </cfloop>
        </div>
    <cfelse>
        <div class="dd-empty mb-4">
            <i class="bi bi-diagram-3"></i>
            <p>Bugün için istasyon verisi bulunamadı.</p>
        </div>
    </cfif>

    <div class="row g-3">

        <!--- AKTİF ÜRETİM EMİRLERİ --->
        <div class="col-12 col-xl-8">
            <p class="dd-section-title"><i class="bi bi-play-circle-fill" style="color:var(--accent);"></i> Aktif Emirler (#qActiveOrders.recordCount#)</p>
            <div class="dd-table-card">
                <cfif qActiveOrders.recordCount gt 0>
                    <div class="table-responsive">
                        <table class="table table-hover table-sm align-middle">
                            <thead>
                                <tr>
                                    <th>Emir No</th>
                                    <th>Renk / Stok</th>
                                    <th>Firma</th>
                                    <th>İstasyon</th>
                                    <th class="text-end">Miktar</th>
                                    <th>Başlangıç</th>
                                    <th>Bitiş</th>
                                    <th>Durum</th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop query="qActiveOrders">
                                <tr>
                                    <td>
                                        <a href="index.cfm?fuseaction=production.view_production_order&p_order_id=#val(p_order_id)#" class="fw-semibold text-decoration-none" style="color:var(--primary);">
                                            #htmlEditFormat(p_order_no)#
                                        </a>
                                        <cfif is_urgent>
                                            <span class="badge-urgent ms-1">ACİL</span>
                                        </cfif>
                                    </td>
                                    <td>
                                        <span class="fw-semibold text-dark d-block" style="font-size:0.8rem;">#htmlEditFormat(color_code)#</span>
                                        <span class="text-muted" style="font-size:0.72rem;">#htmlEditFormat(color_name)#</span>
                                    </td>
                                    <td style="max-width:140px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;"
                                        title="#htmlEditFormat(company_name)#">
                                        #htmlEditFormat(company_name)#
                                    </td>
                                    <td>
                                        <span class="badge bg-secondary bg-opacity-25 text-dark" style="font-size:0.72rem;">
                                            #htmlEditFormat(station_name)#
                                        </span>
                                    </td>
                                    <td class="text-end fw-semibold">#val(quantity)#</td>
                                    <td style="font-size:0.78rem;">#isDate(start_date) ? dateFormat(start_date,"dd/mm") : ""#</td>
                                    <td style="font-size:0.78rem; <cfif isDate(finish_date) AND finish_date LT now()>color:var(--accent);font-weight:700;<cfelse>color:var(--sidebar-bg);</cfif>">
                                        #isDate(finish_date) ? dateFormat(finish_date,"dd/mm") : ""#
                                    </td>
                                    <td>
                                        <cfif val(active_pause_count) gt 0>
                                            <span class="badge-pause"><i class="bi bi-pause-fill"></i> Duruşta</span>
                                        <cfelse>
                                            <span class="dd-station-badge" style="background:var(--content-bg);color:var(--primary);">
                                                <i class="bi bi-play-fill"></i> Üretiyor
                                            </span>
                                        </cfif>
                                        <cfif val(total_pause_min) gt 0>
                                            <span class="d-block" style="font-size:0.65rem;color:var(--sidebar-bg);margin-top:2px;">
                                                #val(total_pause_min)# dk duruş
                                            </span>
                                        </cfif>
                                    </td>
                                </tr>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <div class="dd-empty">
                        <i class="bi bi-play-circle"></i>
                        <p>Şu anda aktif üretim emri yok.</p>
                    </div>
                </cfif>
            </div>
        </div>

        <!--- GECİKEN EMİRLER --->
        <div class="col-12 col-xl-4">
            <p class="dd-section-title"><i class="bi bi-exclamation-triangle-fill" style="color:var(--accent);"></i> Geciken Emirler</p>
            <div class="dd-table-card">
                <cfif qOverdue.recordCount gt 0>
                    <div class="table-responsive">
                        <table class="table table-sm align-middle">
                            <thead>
                                <tr>
                                    <th>Emir</th>
                                    <th>İstasyon</th>
                                    <th class="text-center">Gecikme</th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop query="qOverdue">
                                <tr>
                                    <td>
                                        <a href="index.cfm?fuseaction=production.view_production_order&p_order_id=#val(p_order_id)#"
                                           class="fw-semibold text-decoration-none" style="color:var(--primary);font-size:0.8rem;">
                                            #htmlEditFormat(p_order_no)#
                                        </a>
                                        <span class="d-block text-muted" style="font-size:0.7rem;">#htmlEditFormat(color_name)#</span>
                                    </td>
                                    <td style="font-size:0.75rem;">#htmlEditFormat(station_name)#</td>
                                    <td class="text-center">
                                        <span class="badge" style="background:var(--content-bg);color:var(--primary);font-weight:700;font-size:0.72rem;">
                                            #val(overdue_days)# gün
                                        </span>
                                    </td>
                                </tr>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                <cfelse>
                    <div class="dd-empty">
                        <i class="bi bi-check2-all" style="color:var(--primary);"></i>
                        <p>Geciken emir yok. Harika!</p>
                    </div>
                </cfif>
            </div>
        </div>

    </div>

    <!--- BUGÜN TAMAMLANANLAR --->
    <p class="dd-section-title"><i class="bi bi-check-circle-fill" style="color:var(--primary);"></i> Bugün Tamamlananlar (#qCompletedToday.recordCount#)</p>
    <div class="dd-table-card">
        <cfif qCompletedToday.recordCount gt 0>
            <div class="table-responsive">
                <table class="table table-hover table-sm align-middle">
                    <thead>
                        <tr>
                            <th>Emir No</th>
                            <th>Renk / Stok</th>
                            <th>Firma</th>
                            <th>İstasyon</th>
                            <th class="text-end">Miktar</th>
                            <th>Bitiş Saati</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop query="qCompletedToday">
                        <tr>
                            <td>
                                <a href="index.cfm?fuseaction=production.view_production_order&p_order_id=#val(p_order_id)#"
                                   class="fw-semibold text-decoration-none" style="color:var(--primary);">
                                    #htmlEditFormat(p_order_no)#
                                </a>
                            </td>
                            <td>
                                <span class="fw-semibold d-block" style="font-size:0.8rem;">#htmlEditFormat(color_code)#</span>
                                <span class="text-muted" style="font-size:0.72rem;">#htmlEditFormat(color_name)#</span>
                            </td>
                            <td style="max-width:160px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;"
                                title="#htmlEditFormat(company_name)#">
                                #htmlEditFormat(company_name)#
                            </td>
                            <td>
                                <span class="badge bg-secondary bg-opacity-25 text-dark" style="font-size:0.72rem;">
                                    #htmlEditFormat(station_name)#
                                </span>
                            </td>
                            <td class="text-end fw-semibold">#val(quantity)#</td>
                            <td style="font-size:0.78rem;color:var(--primary);font-weight:600;">
                                <i class="bi bi-check-circle me-1"></i>
                                #isDate(finish_date_real) ? timeFormat(finish_date_real,"HH:mm") : ""#
                            </td>
                        </tr>
                        </cfloop>
                    </tbody>
                </table>
            </div>
        <cfelse>
            <div class="dd-empty">
                <i class="bi bi-inbox"></i>
                <p>Bugün henüz tamamlanan emir yok.</p>
            </div>
        </cfif>
    </div>

</div><!--- /dd-page --->

<script>
(function() {
    // Her 5 dakikada bir otomatik yenile
    var refreshMs = 5 * 60 * 1000;
    var timer = setTimeout(function() { location.reload(); }, refreshMs);

    // Sayfa odakta değilken sayacı durdur, döndüğünde hemen yenile
    document.addEventListener('visibilitychange', function() {
        if (document.hidden) {
            clearTimeout(timer);
        } else {
            location.reload();
        }
    });
})();
</script>
</cfoutput>
