<cfprocessingdirective pageEncoding="utf-8">
<cfinclude template="../includes/status_codes.cfm">

<cfquery name="qMachineBoard" datasource="boyahane">
    SELECT
        m.machine_id,
        COALESCE(m.machine_code, '') AS machine_code,
        COALESCE(m.machine_name, '') AS machine_name,
        COALESCE(d.department_head, 'Diğer') AS department_name,
        COALESCE(m.current_status_code, <cfqueryparam value="#STATUS_OK#" cfsqltype="cf_sql_integer">) AS current_status_code,
        COALESCE(m.current_status_note, '') AS current_status_note,
        COALESCE(active_fault.last_event_type, '') AS active_fault_stage,
        COALESCE(m.is_active, true) AS is_active,
        COALESCE(fault_counts.open_fault_count, 0) AS open_fault_count
    FROM machine_machines m
    LEFT JOIN department d ON d.department_id = m.department_id
    LEFT JOIN LATERAL (
        SELECT COUNT(*) AS open_fault_count
        FROM machine_faults f
        WHERE f.machine_id = m.machine_id
          AND f.fault_status IN ('open', 'in_progress')
    ) fault_counts ON true
    LEFT JOIN LATERAL (
        SELECT COALESCE(last_event.event_type, 'opened') AS last_event_type
        FROM machine_faults f
        LEFT JOIN LATERAL (
            SELECT fe.event_type
            FROM machine_fault_events fe
            WHERE fe.fault_id = f.fault_id
            ORDER BY fe.event_date DESC, fe.fault_event_id DESC
            LIMIT 1
        ) last_event ON true
        WHERE f.machine_id = m.machine_id
          AND f.fault_status IN ('open', 'in_progress')
        ORDER BY
            CASE COALESCE(last_event.event_type, 'opened')
                WHEN 'intervention' THEN 3
                WHEN 'assigned' THEN 2
                ELSE 1
            END DESC,
            COALESCE(f.intervention_at, f.assigned_at, f.opened_at) DESC,
            f.fault_id DESC
        LIMIT 1
    ) active_fault ON true
    ORDER BY COALESCE(d.department_head, 'Diğer'), m.machine_name
</cfquery>

<cfquery name="qSummary" datasource="boyahane">
    WITH machine_status AS (
        SELECT
            COALESCE(m.current_status_code, <cfqueryparam value="#STATUS_OK#" cfsqltype="cf_sql_integer">) AS current_status_code,
            COALESCE(m.is_active, true) AS is_active,
            COALESCE(fault_counts.open_fault_count, 0) AS open_fault_count
        FROM machine_machines m
        LEFT JOIN LATERAL (
            SELECT COUNT(*) AS open_fault_count
            FROM machine_faults f
            WHERE f.machine_id = m.machine_id
              AND f.fault_status IN ('open', 'in_progress')
        ) fault_counts ON true
    )
    SELECT
        COUNT(*) AS total_machine,
        SUM(CASE WHEN is_active = true
                  AND current_status_code = <cfqueryparam value="#STATUS_OK#" cfsqltype="cf_sql_integer">
                  AND open_fault_count = 0 THEN 1 ELSE 0 END) AS status_ok,
        SUM(CASE WHEN is_active = true
                  AND current_status_code = <cfqueryparam value="#STATUS_MAINTENANCE#" cfsqltype="cf_sql_integer"> THEN 1 ELSE 0 END) AS status_maintenance,
        SUM(CASE WHEN is_active = true
                  AND current_status_code <> <cfqueryparam value="#STATUS_MAINTENANCE#" cfsqltype="cf_sql_integer">
                  AND (open_fault_count > 0 OR current_status_code = <cfqueryparam value="#STATUS_FAULT#" cfsqltype="cf_sql_integer">) THEN 1 ELSE 0 END) AS status_fault,
        SUM(CASE WHEN is_active = false THEN 1 ELSE 0 END) AS status_inactive
    FROM machine_status
</cfquery>

<cfset hasMachine = qMachineBoard.recordCount GT 0>
<cfset openedFaultMachineCount = 0>
<cfloop query="qMachineBoard">
    <cfif val(open_fault_count) GT 0 AND active_fault_stage EQ "opened">
        <cfset openedFaultMachineCount = openedFaultMachineCount + 1>
    </cfif>
</cfloop>

<cfquery name="qOpenFaults" datasource="boyahane">
    SELECT f.fault_id, f.fault_no, f.machine_id,
           f.fault_title, f.priority_level, f.fault_status,
           f.assigned_emp_id,
           COALESCE(e.name || ' ' || e.surname, '') AS assigned_employee
    FROM machine_faults f
    LEFT JOIN kullanicilar e ON e.id = f.assigned_emp_id
    WHERE f.fault_status IN ('open', 'in_progress')
    ORDER BY f.opened_at DESC
</cfquery>

<cfquery name="qSbEmployees" datasource="boyahane">
    SELECT id AS employee_id,
           COALESCE(name || ' ' || surname, '') AS employee_fullname
    FROM kullanicilar
    ORDER BY name, surname
</cfquery>

<cfset openFaultsArr = []>
<cfloop query="qOpenFaults">
    <cfset arrayAppend(openFaultsArr, {
        "fault_id": val(fault_id),
        "fault_no": fault_no ?: "",
        "machine_id": val(machine_id),
        "fault_title": fault_title ?: "",
        "priority_level": val(priority_level),
        "fault_status": fault_status ?: "",
        "assigned_emp_id": isNumeric(assigned_emp_id) ? val(assigned_emp_id) : 0,
        "assigned_employee": assigned_employee ?: ""
    })>
</cfloop>

<cfset sbEmployeesArr = []>
<cfloop query="qSbEmployees">
    <cfset arrayAppend(sbEmployeesArr, {
        "employee_id": val(employee_id),
        "employee_fullname": employee_fullname ?: ""
    })>
</cfloop>

<cfoutput>
<style>
/* ===== STATUS BOARD ===== */
.sb-page { padding: 0 4px 24px; }

/* Header */
.sb-header {
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
.sb-header-left { display:flex; align-items:center; gap:16px; }
.sb-header-icon {
    width: 48px; height: 48px;
    background: ##e67e22;
    border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.35rem; color: ##fff;
    box-shadow: 0 4px 14px rgba(230,126,34,.4);
    flex-shrink: 0;
}
.sb-header-title { font-size: 1.25rem; font-weight: 800; color: ##fff; margin: 0 0 3px; line-height: 1.2; }
.sb-header-sub  { font-size: 0.78rem; color: rgba(255,255,255,.55); margin: 0; }
.sb-header-btn {
    background: rgba(255,255,255,.12);
    border: 1px solid rgba(255,255,255,.2);
    color: ##fff;
    font-size: 0.82rem;
    font-weight: 600;
    padding: 7px 16px;
    border-radius: 8px;
    text-decoration: none;
    display: inline-flex; align-items: center; gap: 6px;
    transition: background .15s;
}
.sb-header-btn:hover { background: rgba(255,255,255,.22); color: ##fff; }

/* Summary strip */
.sb-summary {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
    gap: 12px;
    margin-bottom: 20px;
}
.sb-stat {
    background: ##fff;
    border-radius: 12px;
    padding: 14px 16px;
    display: flex; align-items: center; gap: 14px;
    box-shadow: 0 2px 10px rgba(0,0,0,.06);
    border: 1px solid ##f1f5f9;
}
.sb-stat-icon {
    width: 42px; height: 42px;
    border-radius: 10px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.1rem; flex-shrink: 0;
}
.sb-stat-icon.total    { background: ##eff6ff; color: ##3b82f6; }
.sb-stat-icon.ok       { background: ##f0fdf4; color: ##16a34a; }
.sb-stat-icon.maint    { background: ##f3f4f6; color: ##4b5563; }
.sb-stat-icon.fault    { background: ##fef2f2; color: ##dc2626; }
.sb-stat-icon.openfault{ background: ##fff7ed; color: ##ea580c; }
.sb-stat-icon.inactive { background: ##f8fafc; color: ##6b7280; }
.sb-stat-label { font-size: 0.72rem; font-weight: 600; color: ##94a3b8; text-transform: uppercase; letter-spacing: .04em; }
.sb-stat-val   { font-size: 1.6rem; font-weight: 800; line-height: 1.1; color: ##0f172a; }

/* Legend */
.sb-legend {
    display: flex;
    flex-wrap: wrap;
    gap: 6px 16px;
    align-items: center;
    margin-bottom: 16px;
    font-size: 0.8rem;
    color: ##475569;
}
.sb-legend-dot {
    width: 10px; height: 10px;
    border-radius: 50%;
    display: inline-block;
    margin-right: 5px;
    vertical-align: middle;
    box-shadow: 0 1px 3px rgba(0,0,0,.2);
}
.sb-legend-hint { font-size: 0.75rem; color: ##94a3b8; font-style: italic; }
<cfinclude template="_status_board_styles.cfm">

/* Department card */
.sb-dept-card {
    background: ##fff;
    border: 1px solid ##e5e7eb;
    border-radius: 14px;
    margin-bottom: 14px;
    overflow: hidden;
    box-shadow: 0 2px 10px rgba(0,0,0,.05);
}
.sb-dept-header {
    background: linear-gradient(90deg, ##1a3a5c 0%, ##1e4570 100%);
    padding: 10px 18px;
    display: flex;
    align-items: center;
    gap: 10px;
}
.sb-dept-icon {
    width: 30px; height: 30px;
    background: rgba(255,255,255,.12);
    border-radius: 8px;
    display: flex; align-items: center; justify-content: center;
    font-size: 0.85rem; color: ##e67e22;
}
.sb-dept-name { font-size: 0.95rem; font-weight: 700; color: ##fff; }
.sb-machine-list { display: flex; flex-wrap: wrap; gap: 10px; padding: 14px 16px; }

/* Machine tile */
.sb-tile {
    width: 108px;
    min-height: 96px;
    border-radius: 12px;
    color: ##fff;
    padding: 10px 8px 8px;
    position: relative;
    text-align: center;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: space-between;
    gap: 4px;
    cursor: pointer;
    transition: transform .15s, box-shadow .15s;
    box-shadow: 0 3px 10px rgba(0,0,0,.18);
}
.sb-tile:hover { transform: translateY(-3px); box-shadow: 0 8px 22px rgba(0,0,0,.22); }
.sb-tile-inactive { cursor: default; }
.sb-tile-inactive:hover { transform: none !important; box-shadow: 0 3px 10px rgba(0,0,0,.18) !important; }

.sb-tile-ok      { background: linear-gradient(160deg, ##22c55e 0%, ##15803d 100%); }
.sb-tile-maint   { background: linear-gradient(160deg, ##9ca3af 0%, ##4b5563 100%); }
.sb-tile-assigned{ background: linear-gradient(160deg, ##60a5fa 0%, ##1d4ed8 100%); }
.sb-tile-open-fault { background: linear-gradient(160deg, ##fb923c 0%, ##ea580c 100%); }
.sb-tile-intervention { background: linear-gradient(160deg, ##facc15 0%, ##ca8a04 100%); color: ##1f2937; }
.sb-tile-fault   { background: linear-gradient(160deg, ##f87171 0%, ##b91c1c 100%); }
.sb-tile-inactive{ background: linear-gradient(160deg, ##cbd5e1 0%, ##64748b 100%); }

.sb-tile-icon { font-size: 1.2rem; opacity: .9; line-height: 1; }
.sb-tile-code { font-size: 0.95rem; font-weight: 800; line-height: 1.1; text-transform: uppercase; letter-spacing: .03em; }
.sb-tile-name { font-size: 0.68rem; font-weight: 600; opacity: .85; line-height: 1.2; }
.sb-tile-status {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 4px;
    max-width: 100%;
    padding: 2px 6px;
    border-radius: 999px;
    background: rgba(255,255,255,.22);
    border: 1px solid rgba(255,255,255,.3);
    font-size: 0.58rem;
    font-weight: 800;
    line-height: 1.15;
    letter-spacing: .02em;
    text-transform: uppercase;
    white-space: nowrap;
}
.sb-tile-intervention .sb-tile-status { background: rgba(255,255,255,.45); border-color: rgba(31,41,55,.18); }

.sb-fault-badge {
    position: absolute;
    top: -5px; right: -5px;
    width: 20px; height: 20px;
    background: ##fff;
    color: ##b91c1c;
    font-size: 0.68rem;
    font-weight: 800;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    box-shadow: 0 2px 6px rgba(0,0,0,.25);
    border: 2px solid ##fecaca;
}

/* Empty state */
.sb-empty {
    background: ##fff;
    border: 2px dashed ##e2e8f0;
    border-radius: 12px;
    padding: 48px 24px;
    text-align: center;
    color: ##94a3b8;
}
.sb-empty i { font-size: 2.5rem; margin-bottom: 12px; display: block; color: ##cbd5e1; }
</style>

<div class="sb-page">

    <!--- Header --->
    <div class="sb-header">
        <div class="sb-header-left">
            <div class="sb-header-icon"><i class="fas fa-desktop"></i></div>
            <div>
                <div class="sb-header-title">Makine Durum Takip Ekranı</div>
                <div class="sb-header-sub">Makineler arıza aşamasına ve bakım durumuna göre renklendirilir</div>
            </div>
        </div>
        <a href="/index.cfm?fuseaction=machine.dashboard" class="sb-header-btn">
            <i class="fas fa-arrow-left"></i> Dashboard
        </a>
    </div>

    <!--- Summary strip --->
    <div class="sb-summary">
        <div class="sb-stat">
            <div class="sb-stat-icon total"><i class="fas fa-industry"></i></div>
            <div><div class="sb-stat-label">Toplam</div><div class="sb-stat-val">#val(qSummary.total_machine)#</div></div>
        </div>
        <div class="sb-stat">
            <div class="sb-stat-icon #machineStatusDefinitions[STATUS_OK].summaryClass#"><i class="fas #machineStatusDefinitions[STATUS_OK].icon#"></i></div>
            <div><div class="sb-stat-label">#machineStatusDefinitions[STATUS_OK].label#</div><div class="sb-stat-val" style="color:#machineStatusDefinitions[STATUS_OK].color#">#val(qSummary.status_ok)#</div></div>
        </div>
        <div class="sb-stat">
            <div class="sb-stat-icon #machineStatusDefinitions[STATUS_MAINTENANCE].summaryClass#"><i class="fas #machineStatusDefinitions[STATUS_MAINTENANCE].icon#"></i></div>
            <div><div class="sb-stat-label">#machineStatusDefinitions[STATUS_MAINTENANCE].label#</div><div class="sb-stat-val" style="color:#machineStatusDefinitions[STATUS_MAINTENANCE].color#">#val(qSummary.status_maintenance)#</div></div>
        </div>
        <div class="sb-stat">
            <div class="sb-stat-icon #machineStatusDefinitions[STATUS_FAULT].summaryClass#"><i class="fas #machineStatusDefinitions[STATUS_FAULT].icon#"></i></div>
            <div><div class="sb-stat-label">#machineStatusDefinitions[STATUS_FAULT].label#</div><div class="sb-stat-val" style="color:#machineStatusDefinitions[STATUS_FAULT].color#">#val(qSummary.status_fault)#</div></div>
        </div>
        <div class="sb-stat">
            <div class="sb-stat-icon #machineStatusInactive.summaryClass#"><i class="fas #machineStatusInactive.icon#"></i></div>
            <div><div class="sb-stat-label">#machineStatusInactive.label#</div><div class="sb-stat-val" style="color:#machineStatusInactive.color#">#val(qSummary.status_inactive)#</div></div>
        </div>
    </div>

    <!--- Legend --->
    <div class="sb-legend">
        <span><i class="sb-legend-dot" style="background:#machineStatusDefinitions[STATUS_OK].color#"></i>#machineStatusDefinitions[STATUS_OK].legendLabel#</span>
        <span><i class="sb-legend-dot" style="background:#machineStatusDefinitions[STATUS_MAINTENANCE].color#"></i>#machineStatusDefinitions[STATUS_MAINTENANCE].legendLabel#</span>
        <span><i class="sb-legend-dot" style="background:#machineFaultStageDefinitions.assigned.color#"></i>#machineFaultStageDefinitions.assigned.label#</span>
        <span><i class="sb-legend-dot" style="background:#machineFaultStageDefinitions.intervention.color#"></i>#machineFaultStageDefinitions.intervention.label#</span>
        <span><i class="sb-legend-dot" style="background:#machineStatusDefinitions[STATUS_FAULT].color#"></i>#machineStatusDefinitions[STATUS_FAULT].legendLabel#</span>
        <span><i class="sb-legend-dot" style="background:#machineStatusInactive.color#"></i>#machineStatusInactive.label#</span>
        <span class="sb-legend-hint"><i class="fas fa-circle-exclamation me-1"></i>Sağ üstteki sayı: açık arıza adedi</span>
    </div>

    <!--- Machine tiles by department --->
    <cfif NOT hasMachine>
        <div class="sb-empty">
            <i class="fas fa-industry"></i>
            Kayıtlı makine bulunamadı.
        </div>
    <cfelse>
        <cfset currentDepartment = "">
        <cfloop query="qMachineBoard">
            <cfif currentDepartment NEQ qMachineBoard.department_name>
                <cfif currentDepartment NEQ "">
                        </div>
                    </div>
                </cfif>
                <cfset currentDepartment = qMachineBoard.department_name>
                <div class="sb-dept-card">
                    <div class="sb-dept-header">
                        <div class="sb-dept-icon"><i class="fas fa-building"></i></div>
                        <div class="sb-dept-name">#htmlEditFormat(currentDepartment)#</div>
                    </div>
                    <div class="sb-machine-list">
            </cfif>

            <cfset tileClass = machineStatusDefinitions[STATUS_OK].tileClass>
            <cfset tileIcon  = machineStatusDefinitions[STATUS_OK].icon>
            <cfif NOT qMachineBoard.is_active>
                <cfset tileClass = machineStatusInactive.tileClass>
                <cfset tileIcon  = machineStatusInactive.icon>
            <cfelseif qMachineBoard.current_status_code EQ STATUS_MAINTENANCE>
                <cfset tileClass = machineStatusDefinitions[STATUS_MAINTENANCE].tileClass>
                <cfset tileIcon  = machineStatusDefinitions[STATUS_MAINTENANCE].icon>
            <cfelseif qMachineBoard.active_fault_stage EQ "intervention">
                <cfset tileClass = machineFaultStageDefinitions.intervention.tileClass>
                <cfset tileIcon  = machineFaultStageDefinitions.intervention.icon>
            <cfelseif qMachineBoard.active_fault_stage EQ "assigned">
                <cfset tileClass = machineFaultStageDefinitions.assigned.tileClass>
                <cfset tileIcon  = machineFaultStageDefinitions.assigned.icon>
            <cfelseif val(qMachineBoard.open_fault_count) GT 0>
                <cfset tileClass = machineStatusDefinitions[STATUS_FAULT].tileClass>
                <cfset tileIcon  = machineStatusDefinitions[STATUS_FAULT].icon>
            </cfif>

            <cfset tileTitle = htmlEditFormat(qMachineBoard.machine_name) & " | Durum: " & htmlEditFormat(tileStatusLabel) & " | Açık arıza: " & val(qMachineBoard.open_fault_count) & (len(trim(qMachineBoard.current_status_note)) ? " | Not: " & htmlEditFormat(qMachineBoard.current_status_note) : "")>
            <div class="sb-tile #tileClass#"
                 title="#htmlEditFormat(qMachineBoard.machine_name)##len(trim(qMachineBoard.current_status_note)) ? ' — ' & htmlEditFormat(qMachineBoard.current_status_note) : ''#"
                 <cfif tileClass NEQ machineStatusInactive.tileClass>onclick="sbTileClick(#val(qMachineBoard.machine_id)#,'#jsStringFormat(qMachineBoard.machine_name)#',#val(qMachineBoard.current_status_code)#,#val(qMachineBoard.open_fault_count)#)"</cfif>>
                <cfif val(qMachineBoard.open_fault_count) GT 0>
                    <span class="sb-fault-badge">#val(qMachineBoard.open_fault_count)#</span>
                </cfif>
                <div class="sb-tile-icon"><i class="fas #tileIcon#"></i></div>
                <div class="sb-tile-code">#htmlEditFormat(qMachineBoard.machine_code)#</div>
                <div class="sb-tile-name">#htmlEditFormat(qMachineBoard.machine_name)#</div>
                <div class="sb-tile-status"><i class="fas #tileIcon#"></i> #htmlEditFormat(tileStatusLabel)#</div>
            </div>
        </cfloop>
                    </div>
                </div>
    </cfif>

</div>

<!--- Modal: Yeni Arıza Kaydı --->
<div class="modal fade" id="sbFaultModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="fas fa-exclamation-triangle text-danger me-2"></i>Arıza Kaydı Oluştur</h5>
        <button class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="mb-3 p-2 rounded bg-light border">
          <small class="text-muted d-block">Makine</small>
          <div class="fw-bold" id="sb_machine_display">—</div>
        </div>
        <div class="mb-2"><label class="form-label fw-semibold">Arıza Başlığı <span class="text-danger">*</span></label><input id="sb_f_title" class="form-control" placeholder="Kısa ve net bir başlık"></div>
        <div class="row g-2 mb-2">
          <div class="col-6"><label class="form-label">Öncelik</label><select id="sb_f_priority" class="form-select"><option value="1">Düşük</option><option value="2" selected>Orta</option><option value="3">Yüksek</option><option value="4">Kritik</option></select></div>
          <div class="col-6"><label class="form-label">Duruş Türü</label><select id="sb_f_downtime_cat" class="form-select"><option value="unplanned">Planlanmamış (Arıza)</option><option value="planned">Planlı Duruş</option><option value="production_change">Ürün Değişimi</option><option value="cleaning">Temizlik</option></select></div>
        </div>
        <div class="mb-2"><label class="form-label">Kök Neden</label><select id="sb_f_root_cause" class="form-select"><option value="">Bilinmiyor</option><option value="mechanical">Mekanik</option><option value="electrical">Elektrik</option><option value="pneumatic">Pnömatik</option><option value="hydraulic">Hidrolik</option><option value="operator_error">Operatör Hatası</option><option value="wear">Yıpranma / Eskime</option><option value="other">Diğer</option></select></div>
        <div><label class="form-label">Açıklama</label><textarea id="sb_f_desc" class="form-control" rows="3" placeholder="Arıza detayları..."></textarea></div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" data-bs-dismiss="modal">Kapat</button>
        <button class="btn btn-danger" onclick="saveSbFault()"><i class="fas fa-exclamation-circle me-1"></i>Arıza Aç</button>
      </div>
    </div>
  </div>
</div>

<!--- Modal: Arıza İlerlet / Sonuçlandır --->
<div class="modal fade" id="sbStageModal" tabindex="-1">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title"><i class="fas fa-tasks text-primary me-2"></i>Arıza İlerlet / Sonuçlandır</h5>
        <button class="btn-close" data-bs-dismiss="modal"></button>
      </div>
      <div class="modal-body">
        <div class="mb-3 p-2 rounded bg-light border">
          <small class="text-muted d-block">Makine</small>
          <div class="fw-bold" id="sb_s_machine_display">—</div>
        </div>
        <div class="mb-2"><label class="form-label fw-semibold">Arıza <span class="text-danger">*</span></label><select id="sb_s_fault" class="form-select"></select></div>
        <div class="row g-2 mb-2">
          <div class="col-6"><label class="form-label">Aşama</label><select id="sb_s_stage" class="form-select"><option value="assigned">Atandı</option><option value="intervention">Müdahale</option><option value="resolved">Çözüldü ✓</option><option value="cancelled">İptal</option></select></div>
          <div class="col-6"><label class="form-label">Personel</label><select id="sb_s_emp" class="form-select"></select></div>
        </div>
        <div><label class="form-label">Not</label><textarea id="sb_s_note" class="form-control" rows="3" placeholder="Müdahale notu, çözüm açıklaması..."></textarea></div>
      </div>
      <div class="modal-footer">
        <button class="btn btn-secondary" data-bs-dismiss="modal">Kapat</button>
        <button class="btn btn-primary" onclick="saveSbStage()"><i class="fas fa-check me-1"></i>Kaydet</button>
      </div>
    </div>
  </div>
</div>

<script>
var sbOpenFaults = #serializeJSON(openFaultsArr)#;
var sbEmployees  = #serializeJSON(sbEmployeesArr)#;
var sbCurrentMachineId = 0;

(function(){
    var opt = '<option value="">Personel seçiniz</option>';
    sbEmployees.forEach(function(e){ opt += '<option value="'+e.employee_id+'">'+e.employee_fullname+'</option>'; });
    document.getElementById('sb_s_emp').innerHTML = opt;
})();

function sbTileClick(machineId, machineName, statusCode, openFaultCount) {
    if (Number(openFaultCount) > 0) {
        openSbStageModal(machineId, machineName);
    } else {
        openSbFaultModal(machineId, machineName);
    }
}

function openSbFaultModal(machineId, machineName) {
    sbCurrentMachineId = machineId;
    document.getElementById('sb_machine_display').textContent = machineName;
    document.getElementById('sb_f_title').value = '';
    document.getElementById('sb_f_priority').value = '2';
    document.getElementById('sb_f_root_cause').value = '';
    document.getElementById('sb_f_downtime_cat').value = 'unplanned';
    document.getElementById('sb_f_desc').value = '';
    var el = document.getElementById('sbFaultModal');
    if (el.parentElement !== document.body) document.body.appendChild(el);
    new bootstrap.Modal(el).show();
}

function openSbStageModal(machineId, machineName) {
    sbCurrentMachineId = machineId;
    var faults = sbOpenFaults.filter(function(f){ return Number(f.machine_id) === Number(machineId); });
    document.getElementById('sb_s_machine_display').textContent = machineName;
    var faultOpt = faults.length === 0
        ? '<option value="">Açık arıza bulunamadı</option>'
        : faults.map(function(f){ return '<option value="'+f.fault_id+'">'+f.fault_no+' — '+f.fault_title+'</option>'; }).join('');
    document.getElementById('sb_s_fault').innerHTML = faultOpt;
    var first = faults[0];
    document.getElementById('sb_s_emp').value = first && first.assigned_emp_id ? String(first.assigned_emp_id) : '';
    document.getElementById('sb_s_stage').value = 'assigned';
    document.getElementById('sb_s_note').value = '';
    var el = document.getElementById('sbStageModal');
    if (el.parentElement !== document.body) document.body.appendChild(el);
    new bootstrap.Modal(el).show();
}

function saveSbFault() {
    var title = document.getElementById('sb_f_title').value.trim();
    if (!title) { sbNotify('Arıza başlığı zorunludur.', 'warning'); return; }
    $.post('/machine/form/save_fault.cfm', {
        machine_id:        sbCurrentMachineId,
        fault_title:       title,
        fault_description: document.getElementById('sb_f_desc').value,
        priority_level:    document.getElementById('sb_f_priority').value,
        root_cause_code:   document.getElementById('sb_f_root_cause').value,
        downtime_category: document.getElementById('sb_f_downtime_cat').value
    }, sbAjaxDone, 'json').fail(sbAjaxFail);
}

function saveSbStage() {
    var faultId = document.getElementById('sb_s_fault').value;
    var stage   = document.getElementById('sb_s_stage').value;
    var empId   = document.getElementById('sb_s_emp').value;
    if (!faultId) { sbNotify('Arıza seçiniz.', 'warning'); return; }
    if (stage !== 'cancelled' && !empId) { sbNotify('Personel ataması zorunludur.', 'warning'); return; }
    $.post('/machine/form/update_fault_stage.cfm', {
        fault_id:      faultId,
        stage:         stage,
        stage_note:    document.getElementById('sb_s_note').value,
        assigned_emp_id: empId
    }, sbAjaxDone, 'json').fail(sbAjaxFail);
}

function sbAjaxDone(res) {
    if (res && res.success) {
        sbNotify('İşlem başarılı. Sayfa yenileniyor...', 'success');
        setTimeout(function(){ location.reload(); }, 700);
    } else {
        sbNotify((res && res.message) || 'İşlem başarısız.', 'error');
    }
}
function sbAjaxFail() { sbNotify('Sunucu hatası.', 'error'); }
function sbNotify(msg, type) {
    if (typeof DevExpress !== 'undefined') { DevExpress.ui.notify(msg, type || 'info', 3000); }
    else { alert(msg); }
}
</script>
</cfoutput>
