<cfprocessingdirective pageEncoding="utf-8">

<!---
    Müşteri bazlı fabrika durum dashboard'u.
    Referanslar:
      - ship_type = 5 gelen/fabrika malı: myhome/welcome.cfm companyShipStats
      - Partilenen miktar: orders + order_row parti_metre yaklaşımı
      - Tamamlanan üretim: daily_dashboard.cfm status = 5 kullanımı
--->

<cfset today = now()>

<cfquery name="qCustomerFactoryStatus" datasource="boyahane">
WITH incoming AS (
    SELECT
        s.company_id,
        COALESCE(SUM(COALESCE(sr.amount, 0)), 0) AS factory_qty
    FROM ship s
    LEFT JOIN ship_row sr ON sr.ship_id = s.ship_id
    WHERE s.ship_type = 5
      AND COALESCE(s.is_ship_iptal, false) = false
    GROUP BY s.company_id
),
partied AS (
    SELECT
        o.company_id,
        COALESCE(SUM(COALESCE(orw.quantity, 0)), 0) AS partied_qty
    FROM orders o
    INNER JOIN order_row orw ON orw.order_id = o.order_id
    WHERE EXISTS (
        SELECT 1
        FROM ship s
        WHERE s.ship_type = 5
          AND COALESCE(s.is_ship_iptal, false) = false
          AND (
              o.ref_ship_id = s.ship_id
              OR (
                  o.ref_ship_id IS NULL
                  AND o.ref_no IS NOT NULL
                  AND o.ref_no <> ''
                  AND o.ref_no = s.ship_number
              )
          )
    )
    GROUP BY o.company_id
),
po_base AS (
    SELECT
        po.p_order_id,
        COALESCE(po.quantity, 0) AS quantity,
        COALESCE(po.status, 1) AS status,
        COALESCE(o.company_id, porc.company_id, ci.company_id) AS company_id,
        COALESCE(ws.station_name, '') AS station_name,
        EXISTS (
            SELECT 1
            FROM production_plan_parter ppp
            WHERE ppp.p_order_id = po.p_order_id
        ) AS has_plan,
        EXISTS (
            SELECT 1
            FROM production_operation pop
            LEFT JOIN operation_types ot ON ot.operation_type_id = pop.operation_type_id
            LEFT JOIN workstations pws ON pws.station_id = pop.station_id
            WHERE pop.p_order_id = po.p_order_id
              AND (
                  COALESCE(ot.operation_type, ot.operation_code, '') ILIKE '%paket%'
                  OR COALESCE(pws.station_name, '') ILIKE '%paket%'
              )
        ) AS has_package_step,
        EXISTS (
            SELECT 1
            FROM production_operation pop
            LEFT JOIN operation_types ot ON ot.operation_type_id = pop.operation_type_id
            LEFT JOIN workstations pws ON pws.station_id = pop.station_id
            WHERE pop.p_order_id = po.p_order_id
              AND COALESCE(pop.stage, 0) = 2
              AND (
                  COALESCE(ot.operation_type, ot.operation_code, '') ILIKE '%paket%'
                  OR COALESCE(pws.station_name, '') ILIKE '%paket%'
              )
        ) AS package_done_step
    FROM production_orders po
    LEFT JOIN orders o ON o.order_id = po.order_id
    LEFT JOIN color_info ci ON ci.stock_id = po.stock_id
    LEFT JOIN workstations ws ON ws.station_id = po.station_id
    LEFT JOIN (
        SELECT
            por.p_order_id,
            MAX(o2.company_id) AS company_id
        FROM production_orders_row por
        LEFT JOIN orders o2 ON o2.order_id = por.order_id
        GROUP BY por.p_order_id
    ) porc ON porc.p_order_id = po.p_order_id
    WHERE COALESCE(po.status, 1) <> 9
),
production_summary AS (
    SELECT
        company_id,
        COALESCE(SUM(CASE WHEN has_plan OR status IN (1, 2, 5) THEN quantity ELSE 0 END), 0) AS planned_qty,
        COALESCE(SUM(CASE WHEN status = 5 THEN quantity ELSE 0 END), 0) AS completed_qty,
        COALESCE(SUM(CASE WHEN (station_name ILIKE '%paket%' OR has_package_step) AND status <> 5 THEN quantity ELSE 0 END), 0) AS packaging_qty,
        COALESCE(SUM(CASE WHEN (station_name ILIKE '%paket%' OR package_done_step) AND status = 5 THEN quantity ELSE 0 END), 0) AS packaged_qty
    FROM po_base
    GROUP BY company_id
),
shipping_scan AS (
    SELECT
        pb.company_id,
        COALESCE(SUM(COALESCE(porr.amount, 0)), 0) AS scanned_qty
    FROM production_order_results_row porr
    INNER JOIN po_base pb ON pb.p_order_id = porr.p_order_id
    WHERE COALESCE(porr.is_sevkiyat, false) = true
    GROUP BY pb.company_id
),
ship_linked AS (
    SELECT
        s.company_id,
        COALESCE(SUM(COALESCE(sr.amount, 0)), 0) AS shipped_qty
    FROM ship s
    INNER JOIN ship_row sr ON sr.ship_id = s.ship_id
    WHERE COALESCE(s.is_ship_iptal, false) = false
      AND s.ship_type <> 5
      AND (sr.order_row IS NOT NULL OR sr.row_order_id IS NOT NULL OR sr.related_action_table ILIKE '%production%')
    GROUP BY s.company_id
),
all_companies AS (
    SELECT company_id FROM incoming
    UNION
    SELECT company_id FROM partied
    UNION
    SELECT company_id FROM production_summary
    UNION
    SELECT company_id FROM shipping_scan
    UNION
    SELECT company_id FROM ship_linked
)
SELECT
    ac.company_id,
    COALESCE(c.nickname, c.fullname, 'Müşteri Belirtilmemiş') AS company_name,
    COALESCE(i.factory_qty, 0) AS factory_qty,
    COALESCE(p.partied_qty, 0) AS partied_qty,
    COALESCE(ps.planned_qty, 0) AS planned_qty,
    COALESCE(ps.completed_qty, 0) AS completed_qty,
    COALESCE(ps.packaging_qty, 0) AS packaging_qty,
    COALESCE(ps.packaged_qty, 0) AS packaged_qty,
    COALESCE(ss.scanned_qty, 0) + COALESCE(sl.shipped_qty, 0) AS shipment_scanned_qty,
    GREATEST(COALESCE(i.factory_qty, 0) - COALESCE(ss.scanned_qty, 0) - COALESCE(sl.shipped_qty, 0), 0) AS remaining_qty,
    CASE
        WHEN COALESCE(i.factory_qty, 0) > 0 THEN ROUND((COALESCE(ps.completed_qty, 0) / COALESCE(i.factory_qty, 0)) * 100, 1)
        ELSE 0
    END AS progress_pct
FROM all_companies ac
LEFT JOIN company c ON c.company_id = ac.company_id
LEFT JOIN incoming i ON i.company_id IS NOT DISTINCT FROM ac.company_id
LEFT JOIN partied p ON p.company_id IS NOT DISTINCT FROM ac.company_id
LEFT JOIN production_summary ps ON ps.company_id IS NOT DISTINCT FROM ac.company_id
LEFT JOIN shipping_scan ss ON ss.company_id IS NOT DISTINCT FROM ac.company_id
LEFT JOIN ship_linked sl ON sl.company_id IS NOT DISTINCT FROM ac.company_id
ORDER BY company_name
</cfquery>

<cfquery name="qTotals" dbtype="query">
    SELECT
        SUM(factory_qty) AS factory_qty,
        SUM(partied_qty) AS partied_qty,
        SUM(planned_qty) AS planned_qty,
        SUM(completed_qty) AS completed_qty,
        SUM(packaging_qty) AS packaging_qty,
        SUM(packaged_qty) AS packaged_qty,
        SUM(shipment_scanned_qty) AS shipment_scanned_qty,
        SUM(remaining_qty) AS remaining_qty
    FROM qCustomerFactoryStatus
</cfquery>

<cfset totalProgress = 0>
<cfif val(qTotals.factory_qty) gt 0>
    <cfset totalProgress = round((val(qTotals.completed_qty) / val(qTotals.factory_qty)) * 1000) / 10>
</cfif>

<cfoutput>
<style>
.dd-page { padding: 0 4px 32px; }
.dd-header { background: linear-gradient(135deg, ##1a3a5c 0%, ##0d2137 100%); border-radius: 14px; padding: 20px 24px; margin-bottom: 20px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 12px; box-shadow: 0 4px 18px rgba(13,33,55,.25); }
.dd-header-left { display: flex; align-items: center; gap: 16px; }
.dd-header-icon { width: 48px; height: 48px; background: ##e67e22; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 1.35rem; color: ##fff; box-shadow: 0 4px 14px rgba(230,126,34,.4); flex-shrink: 0; }
.dd-header-title { font-size: 1.25rem; font-weight: 800; color: ##fff; margin: 0 0 3px; }
.dd-header-sub { font-size: 0.78rem; color: rgba(255,255,255,.55); margin: 0; }
.dd-header-btn { background: rgba(255,255,255,.12); border: 1px solid rgba(255,255,255,.2); color: ##fff; font-size: 0.82rem; font-weight: 600; padding: 7px 16px; border-radius: 8px; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; transition: background .15s; cursor: pointer; }
.dd-header-btn:hover { background: rgba(255,255,255,.22); color: ##fff; }
.dd-stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 12px; margin-bottom: 22px; }
.dd-stat { background: ##fff; border-radius: 12px; padding: 16px; display: flex; align-items: center; gap: 14px; box-shadow: 0 2px 10px rgba(0,0,0,.06); border: 1px solid ##f1f5f9; }
.dd-stat-icon { width: 44px; height: 44px; border-radius: 11px; display: flex; align-items: center; justify-content: center; font-size: 1.2rem; flex-shrink: 0; }
.dd-stat-icon.total { background: ##eff6ff; color: ##3b82f6; }
.dd-stat-icon.active { background: ##fef3c7; color: ##d97706; }
.dd-stat-icon.done { background: ##f0fdf4; color: ##16a34a; }
.dd-stat-icon.overdue { background: ##fef2f2; color: ##dc2626; }
.dd-stat-icon.qty { background: ##f5f3ff; color: ##7c3aed; }
.dd-stat-label { font-size: 0.7rem; font-weight: 600; color: ##94a3b8; text-transform: uppercase; letter-spacing: .04em; margin-bottom: 2px; }
.dd-stat-val { font-size: 1.45rem; font-weight: 800; line-height: 1.1; color: ##0f172a; }
.dd-stat-sub { font-size: 0.7rem; color: ##94a3b8; margin-top: 1px; }
.dd-section-title { font-size: 0.8rem; font-weight: 700; color: ##475569; text-transform: uppercase; letter-spacing: .06em; margin: 0 0 10px; display: flex; align-items: center; gap: 7px; }
.dd-section-title::after { content: ''; flex: 1; height: 1px; background: ##e2e8f0; }
.dd-progress-bar-wrap { background: ##f1f5f9; border-radius: 99px; height: 8px; overflow: hidden; margin-top: 6px; }
.dd-progress-bar-fill { height: 100%; border-radius: 99px; background: linear-gradient(90deg, ##16a34a, ##22c55e); transition: width .6s ease; }
.dd-table-card { background: ##fff; border-radius: 14px; box-shadow: 0 2px 10px rgba(0,0,0,.06); border: 1px solid ##e5e7eb; overflow: hidden; margin-bottom: 22px; }
.dd-table-card .table { margin: 0; }
.dd-table-card thead th { background: var(--primary, ##1a3a5c); color: ##fff; font-size: 0.72rem; font-weight: 600; text-transform: uppercase; letter-spacing: .04em; border: none; padding: 10px 12px; white-space: nowrap; }
.dd-table-card tbody td { font-size: 0.82rem; padding: 9px 12px; vertical-align: middle; border-color: ##f1f5f9; }
.dd-table-card tbody tr:hover td { background: ##f8fafc; }
.dd-empty { text-align: center; padding: 28px 16px; color: ##94a3b8; }
.dd-empty i { font-size: 2rem; display: block; margin-bottom: 8px; }
.dd-empty p { font-size: 0.82rem; margin: 0; }
.fs-company { min-width: 190px; font-weight: 700; color: ##0f172a; }
.fs-num { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
.fs-progress-cell { min-width: 150px; }
</style>

<div class="dd-page">
    <div class="dd-header">
        <div class="dd-header-left">
            <div class="dd-header-icon"><i class="bi bi-building-gear"></i></div>
            <div>
                <p class="dd-header-title">Fabrika Müşteri Durum Özeti</p>
                <p class="dd-header-sub"><i class="bi bi-calendar3 me-1"></i>#dateFormat(today, "dd MMMM yyyy")# &nbsp;|&nbsp; Son güncelleme: #timeFormat(today, "HH:mm")#</p>
            </div>
        </div>
        <button class="dd-header-btn" onclick="location.reload()"><i class="bi bi-arrow-clockwise"></i> Yenile</button>
    </div>

    <div class="dd-stats">
        <div class="dd-stat"><div class="dd-stat-icon total"><i class="bi bi-box-seam"></i></div><div><div class="dd-stat-label">Fabrikadaki Mal</div><div class="dd-stat-val">#numberFormat(val(qTotals.factory_qty), "_.,00")#</div><div class="dd-stat-sub">ship_type=5 giriş</div></div></div>
        <div class="dd-stat"><div class="dd-stat-icon active"><i class="bi bi-ui-checks-grid"></i></div><div><div class="dd-stat-label">Partilenen</div><div class="dd-stat-val">#numberFormat(val(qTotals.partied_qty), "_.,00")#</div><div class="dd-stat-sub">orders/order_row</div></div></div>
        <div class="dd-stat"><div class="dd-stat-icon qty"><i class="bi bi-calendar2-week"></i></div><div><div class="dd-stat-label">Planlanan</div><div class="dd-stat-val">#numberFormat(val(qTotals.planned_qty), "_.,00")#</div><div class="dd-stat-sub">üretim emri</div></div></div>
        <div class="dd-stat"><div class="dd-stat-icon done"><i class="bi bi-check-circle"></i></div><div><div class="dd-stat-label">Tamamlanan</div><div class="dd-stat-val">#numberFormat(val(qTotals.completed_qty), "_.,00")#</div><div class="dd-stat-sub">status=5</div></div></div>
        <div class="dd-stat"><div class="dd-stat-icon overdue"><i class="bi bi-truck"></i></div><div><div class="dd-stat-label">Sevkiyata Okutulan</div><div class="dd-stat-val">#numberFormat(val(qTotals.shipment_scanned_qty), "_.,00")#</div><div class="dd-stat-sub">sonuç/irsaliye</div></div></div>
    </div>

    <p class="dd-section-title"><i class="bi bi-people"></i> Müşteri Bazlı Grid</p>
    <div class="dd-table-card">
        <cfif qCustomerFactoryStatus.recordCount gt 0>
            <div class="table-responsive">
                <table class="table table-hover table-sm align-middle">
                    <thead>
                        <tr>
                            <th>Müşteri</th>
                            <th class="text-end">Fabrikadaki Mal</th>
                            <th class="text-end">Partilenen</th>
                            <th class="text-end">Planlanan</th>
                            <th class="text-end">Üretimi Tamamlanan</th>
                            <th class="text-end">Paketlemede</th>
                            <th class="text-end">Paketlemeden Geçen</th>
                            <th class="text-end">Sevkiyata Okutulan</th>
                            <th>Kalan / İlerleme</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop query="qCustomerFactoryStatus">
                            <cfset rowProgress = min(100, max(0, val(progress_pct)))>
                            <tr>
                                <td class="fs-company">#htmlEditFormat(company_name)#</td>
                                <td class="fs-num">#numberFormat(val(factory_qty), "_.,00")#</td>
                                <td class="fs-num">#numberFormat(val(partied_qty), "_.,00")#</td>
                                <td class="fs-num">#numberFormat(val(planned_qty), "_.,00")#</td>
                                <td class="fs-num">#numberFormat(val(completed_qty), "_.,00")#</td>
                                <td class="fs-num">#numberFormat(val(packaging_qty), "_.,00")#</td>
                                <td class="fs-num">#numberFormat(val(packaged_qty), "_.,00")#</td>
                                <td class="fs-num">#numberFormat(val(shipment_scanned_qty), "_.,00")#</td>
                                <td class="fs-progress-cell">
                                    <div class="d-flex justify-content-between align-items-center" style="gap:10px;">
                                        <span class="fw-semibold">#numberFormat(val(remaining_qty), "_.,00")#</span>
                                        <span class="text-muted">%#numberFormat(rowProgress, "_.,0.0")#</span>
                                    </div>
                                    <div class="dd-progress-bar-wrap"><div class="dd-progress-bar-fill" style="width:#rowProgress#%;"></div></div>
                                </td>
                            </tr>
                        </cfloop>
                    </tbody>
                    <tfoot>
                        <tr class="fw-bold">
                            <td>TOPLAM</td>
                            <td class="fs-num">#numberFormat(val(qTotals.factory_qty), "_.,00")#</td>
                            <td class="fs-num">#numberFormat(val(qTotals.partied_qty), "_.,00")#</td>
                            <td class="fs-num">#numberFormat(val(qTotals.planned_qty), "_.,00")#</td>
                            <td class="fs-num">#numberFormat(val(qTotals.completed_qty), "_.,00")#</td>
                            <td class="fs-num">#numberFormat(val(qTotals.packaging_qty), "_.,00")#</td>
                            <td class="fs-num">#numberFormat(val(qTotals.packaged_qty), "_.,00")#</td>
                            <td class="fs-num">#numberFormat(val(qTotals.shipment_scanned_qty), "_.,00")#</td>
                            <td>%#numberFormat(totalProgress, "_.,0.0")#</td>
                        </tr>
                    </tfoot>
                </table>
            </div>
        <cfelse>
            <div class="dd-empty"><i class="bi bi-inbox"></i><p>Gösterilecek müşteri bazlı fabrika durum verisi bulunamadı.</p></div>
        </cfif>
    </div>
</div>
</cfoutput>
