<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="qMachineBoard" datasource="boyahane">
    SELECT
        m.machine_id,
        COALESCE(m.machine_code, '') AS machine_code,
        COALESCE(m.machine_name, '') AS machine_name,
        COALESCE(d.department_head, 'Diğer') AS department_name,
        COALESCE(m.current_status_code, 1) AS current_status_code,
        COALESCE(m.current_status_note, '') AS current_status_note,
        COALESCE(m.is_active, true) AS is_active,
        (
            SELECT COUNT(*)
            FROM machine_faults f
            WHERE f.machine_id = m.machine_id
              AND f.fault_status IN ('open', 'in_progress')
        ) AS open_fault_count
    FROM machine_machines m
    LEFT JOIN department d ON d.department_id = m.department_id
    ORDER BY COALESCE(d.department_head, 'Diğer'), m.machine_name
</cfquery>

<cfquery name="qSummary" datasource="boyahane">
    SELECT
        COUNT(*) AS total_machine,
        SUM(CASE WHEN COALESCE(current_status_code, 1) = 1 THEN 1 ELSE 0 END) AS status_ok,
        SUM(CASE WHEN COALESCE(current_status_code, 1) = 2 THEN 1 ELSE 0 END) AS status_maintenance,
        SUM(CASE WHEN COALESCE(current_status_code, 1) = 3 THEN 1 ELSE 0 END) AS status_fault,
        SUM(CASE WHEN COALESCE(is_active, true) = false THEN 1 ELSE 0 END) AS status_inactive
    FROM machine_machines
</cfquery>

<cfset hasMachine = qMachineBoard.recordCount GT 0>

<cfoutput>
<style>
.machine-board-page { padding: 10px 16px 20px; }
.machine-board-header { display:flex; justify-content:space-between; align-items:center; gap:10px; margin-bottom:14px; flex-wrap:wrap; }
.machine-board-header h2 { margin:0; font-size:24px; font-weight:700; color:#334155; }
.machine-board-sub { color:#64748b; margin-top:4px; font-size:13px; }
.machine-board-summary { display:grid; grid-template-columns:repeat(auto-fit, minmax(160px, 1fr)); gap:10px; margin-bottom:14px; }
.machine-summary-item { background:#fff; border:1px solid #e5e7eb; border-radius:10px; padding:10px 12px; }
.machine-summary-label { color:#64748b; font-size:12px; }
.machine-summary-val { font-size:22px; font-weight:700; margin-top:4px; }
.machine-summary-ok { color:#16a34a; }
.machine-summary-maint { color:#d97706; }
.machine-summary-fault { color:#dc2626; }
.machine-summary-inactive { color:#6b7280; }
.machine-dept-card { background:#fff; border:1px solid #e5e7eb; border-radius:12px; margin-bottom:12px; overflow:hidden; }
.machine-dept-title { border-bottom:1px solid #e5e7eb; padding:10px 12px; font-size:20px; color:#ef8585; font-weight:700; }
.machine-list { display:flex; flex-wrap:wrap; gap:8px; padding:12px; }
.machine-tile { width:96px; min-height:84px; border-radius:12px; color:#fff; padding:8px 6px; font-weight:700; position:relative; text-align:center; box-shadow:0 1px 2px rgba(0,0,0,.12); display:flex; flex-direction:column; justify-content:space-between; }
.machine-icon { font-size:13px; line-height:1; }
.machine-code { font-size:16px; line-height:1.1; text-transform:uppercase; }
.machine-name { font-size:11px; line-height:1.1; font-weight:600; opacity:.9; }
.machine-status-ok { background:linear-gradient(180deg,#169c2d 0%,#0f8b22 100%); }
.machine-status-maint { background:linear-gradient(180deg,#f7b500 0%,#ea9d00 100%); }
.machine-status-fault { background:linear-gradient(180deg,#ef4444 0%,#dc2626 100%); }
.machine-status-inactive { background:linear-gradient(180deg,#9ca3af 0%,#6b7280 100%); }
.machine-fault-pill { position:absolute; top:6px; right:6px; background:rgba(255,255,255,.9); color:#b91c1c; font-size:10px; font-weight:700; border-radius:999px; padding:1px 5px; }
.machine-legend { display:flex; flex-wrap:wrap; gap:8px; align-items:center; font-size:12px; color:#475569; margin-bottom:10px; }
.machine-dot { width:10px; height:10px; border-radius:50%; display:inline-block; margin-right:4px; vertical-align:middle; }
.machine-empty { background:#fff; border:1px dashed #d1d5db; border-radius:10px; padding:24px; text-align:center; color:#64748b; }
</style>

<div class="machine-board-page">
    <div class="machine-board-header">
        <div>
            <h2>Makine Durum Takip Ekranı</h2>
            <div class="machine-board-sub">Makineler anlık aşama durumuna göre renklendirilir.</div>
        </div>
        <a href="/index.cfm?fuseaction=machine.dashboard" class="btn btn-outline-secondary btn-sm"><i class="fas fa-arrow-left"></i> Dashboard</a>
    </div>

    <div class="machine-board-summary">
        <div class="machine-summary-item"><div class="machine-summary-label">Toplam Makine</div><div class="machine-summary-val">#val(qSummary.total_machine)#</div></div>
        <div class="machine-summary-item"><div class="machine-summary-label">Çalışıyor</div><div class="machine-summary-val machine-summary-ok">#val(qSummary.status_ok)#</div></div>
        <div class="machine-summary-item"><div class="machine-summary-label">Bakımda</div><div class="machine-summary-val machine-summary-maint">#val(qSummary.status_maintenance)#</div></div>
        <div class="machine-summary-item"><div class="machine-summary-label">Arızalı</div><div class="machine-summary-val machine-summary-fault">#val(qSummary.status_fault)#</div></div>
        <div class="machine-summary-item"><div class="machine-summary-label">Pasif</div><div class="machine-summary-val machine-summary-inactive">#val(qSummary.status_inactive)#</div></div>
    </div>

    <div class="machine-legend">
        <span><i class="machine-dot" style="background:#0f8b22"></i>Çalışıyor</span>
        <span><i class="machine-dot" style="background:#ea9d00"></i>Bakımda</span>
        <span><i class="machine-dot" style="background:#dc2626"></i>Arızalı</span>
        <span><i class="machine-dot" style="background:#6b7280"></i>Pasif</span>
        <span class="text-muted">(Sağ üstteki sayı: açık arıza adedi)</span>
    </div>

    <cfif NOT hasMachine>
        <div class="machine-empty">Kayıtlı makine bulunamadı.</div>
    <cfelse>
        <cfset currentDepartment = "">
        <cfloop query="qMachineBoard">
            <cfif currentDepartment NEQ qMachineBoard.department_name>
                <cfif currentDepartment NEQ "">
                        </div>
                    </div>
                </cfif>
                <cfset currentDepartment = qMachineBoard.department_name>
                <div class="machine-dept-card">
                    <div class="machine-dept-title">#htmlEditFormat(currentDepartment)#</div>
                    <div class="machine-list">
            </cfif>

            <cfset tileClass = "machine-status-ok">
            <cfset tileIcon = "fa-check-square">
            <cfif NOT qMachineBoard.is_active>
                <cfset tileClass = "machine-status-inactive">
                <cfset tileIcon = "fa-pause-circle">
            <cfelseif qMachineBoard.current_status_code EQ 2>
                <cfset tileClass = "machine-status-maint">
                <cfset tileIcon = "fa-tools">
            <cfelseif qMachineBoard.current_status_code EQ 3>
                <cfset tileClass = "machine-status-fault">
                <cfset tileIcon = "fa-exclamation-triangle">
            </cfif>

            <div class="machine-tile #tileClass#" title="#htmlEditFormat(qMachineBoard.machine_name)# - #htmlEditFormat(qMachineBoard.current_status_note)#">
                <cfif val(qMachineBoard.open_fault_count) GT 0>
                    <span class="machine-fault-pill">#val(qMachineBoard.open_fault_count)#</span>
                </cfif>
                <div class="machine-icon"><i class="fas #tileIcon#"></i></div>
                <div class="machine-code">#htmlEditFormat(qMachineBoard.machine_code)#</div>
                <div class="machine-name">#htmlEditFormat(qMachineBoard.machine_name)#</div>
            </div>
        </cfloop>
                    </div>
                </div>
    </cfif>
</div>
</cfoutput>
