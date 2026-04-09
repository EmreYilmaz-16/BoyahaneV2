<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="qMachines" datasource="boyahane">
    SELECT m.machine_id, m.machine_code, m.machine_name, m.department_id,
           COALESCE(d.department_head, '') AS department_name,
           COALESCE(m.location_text, '') AS location_text,
           m.is_active,
           COALESCE(m.current_status_code, 1) AS current_status_code,
           COALESCE(m.current_status_note, '') AS current_status_note,
           m.next_maintenance_date,
           (
               SELECT COUNT(*)
               FROM machine_faults f
               WHERE f.machine_id = m.machine_id
                 AND f.fault_status IN ('open','in_progress')
           ) AS open_fault_count
    FROM machine_machines m
    LEFT JOIN department d ON d.department_id = m.department_id
    ORDER BY m.machine_name
</cfquery>

<cfquery name="qDepartments" datasource="boyahane">
    SELECT department_id, department_head
    FROM department
    WHERE COALESCE(department_status, true) = true
    ORDER BY department_head
</cfquery>

<cfquery name="qFaults" datasource="boyahane">
    SELECT f.fault_id, f.fault_no, f.machine_id, m.machine_code, m.machine_name,
           f.fault_title, f.priority_level, f.fault_status,
           f.opened_at, f.assigned_at, f.resolved_at,
           f.assigned_emp_id,
           COALESCE(e.name || ' ' || e.surname, '') AS assigned_employee,
           COALESCE(f.intervention_note, '') AS intervention_note,
           COALESCE(f.resolution_note, '') AS resolution_note,
           CASE
               WHEN f.assigned_at IS NOT NULL THEN ROUND(EXTRACT(EPOCH FROM (f.assigned_at - f.opened_at)) / 60.0, 2)
               ELSE NULL
           END AS first_response_min,
           CASE
               WHEN f.resolved_at IS NOT NULL THEN ROUND(EXTRACT(EPOCH FROM (f.resolved_at - f.opened_at)) / 60.0, 2)
               ELSE NULL
           END AS close_duration_min
    FROM machine_faults f
    INNER JOIN machine_machines m ON m.machine_id = f.machine_id
    LEFT JOIN kullanicilar e ON e.id = f.assigned_emp_id
    ORDER BY f.opened_at DESC
    LIMIT 300
</cfquery>

<cfquery name="qFaultEvents" datasource="boyahane">
    SELECT fe.fault_event_id, fe.fault_id, fe.event_type, fe.event_note, fe.event_date,
           COALESCE(e.name || ' ' || e.surname, '') AS event_employee
    FROM machine_fault_events fe
    LEFT JOIN kullanicilar e ON e.id = fe.employee_id
    ORDER BY fe.event_date DESC
    LIMIT 1500
</cfquery>

<cfquery name="qEmployees" datasource="boyahane">
    SELECT id AS employee_id,
           COALESCE(name || ' ' || surname, '') AS employee_fullname
    FROM kullanicilar
    ORDER BY name, surname
</cfquery>

<cfquery name="qMachineFaultStats" datasource="boyahane">
    SELECT f.machine_id, m.machine_code, m.machine_name, f.fault_title,
           COUNT(*) AS fault_count,
           MAX(f.opened_at) AS last_fault_at
    FROM machine_faults f
    INNER JOIN machine_machines m ON m.machine_id = f.machine_id
    GROUP BY f.machine_id, m.machine_code, m.machine_name, f.fault_title
    ORDER BY COUNT(*) DESC, MAX(f.opened_at) DESC
    LIMIT 2000
</cfquery>

<cfquery name="qMachineFaultHistory" datasource="boyahane">
    SELECT f.fault_id, f.fault_no, f.machine_id, m.machine_code, m.machine_name,
           f.fault_title, f.priority_level, f.fault_status, f.opened_at, f.assigned_at, f.resolved_at,
           COALESCE(e.name || ' ' || e.surname, '') AS assigned_employee,
           CASE
               WHEN f.resolved_at IS NOT NULL THEN ROUND(EXTRACT(EPOCH FROM (f.resolved_at - f.opened_at)) / 60.0, 2)
               ELSE NULL
           END AS close_duration_min
    FROM machine_faults f
    INNER JOIN machine_machines m ON m.machine_id = f.machine_id
    LEFT JOIN kullanicilar e ON e.id = f.assigned_emp_id
    ORDER BY f.opened_at DESC
    LIMIT 3000
</cfquery>

<cfquery name="qPlans" datasource="boyahane">
    SELECT p.plan_id, p.machine_id, m.machine_code, m.machine_name,
           p.plan_title, p.period_days, p.next_planned_date, p.last_done_date,
           p.is_active, COALESCE(p.notes, '') AS notes
    FROM machine_maintenance_plans p
    INNER JOIN machine_machines m ON m.machine_id = p.machine_id
    ORDER BY p.next_planned_date NULLS LAST, p.plan_id DESC
    LIMIT 300
</cfquery>

<cfquery name="qMaintLogs" datasource="boyahane">
    SELECT l.maintenance_log_id, l.machine_id, m.machine_code, m.machine_name,
           l.plan_id, l.maintenance_type, l.maintenance_start, l.maintenance_end,
           l.maintenance_result, COALESCE(l.result_note, '') AS result_note,
           CASE
               WHEN l.maintenance_start IS NOT NULL AND l.maintenance_end IS NOT NULL
               THEN ROUND(EXTRACT(EPOCH FROM (l.maintenance_end - l.maintenance_start)) / 60.0, 2)
               ELSE NULL
           END AS duration_min
    FROM machine_maintenance_logs l
    INNER JOIN machine_machines m ON m.machine_id = l.machine_id
    ORDER BY l.record_date DESC
    LIMIT 300
</cfquery>

<cfquery name="qSummary" datasource="boyahane">
    SELECT
      COUNT(*) AS total_machine,
      SUM(CASE WHEN current_status_code = 1 THEN 1 ELSE 0 END) AS status_ok,
      SUM(CASE WHEN current_status_code = 2 THEN 1 ELSE 0 END) AS status_maintenance,
      SUM(CASE WHEN current_status_code = 3 THEN 1 ELSE 0 END) AS status_fault,
      SUM(CASE WHEN is_active THEN 1 ELSE 0 END) AS active_machine
    FROM machine_machines
</cfquery>

<cfquery name="qFaultSummary" datasource="boyahane">
    SELECT
      SUM(CASE WHEN fault_status = 'open' THEN 1 ELSE 0 END) AS open_count,
      SUM(CASE WHEN fault_status = 'in_progress' THEN 1 ELSE 0 END) AS in_progress_count,
      SUM(CASE WHEN fault_status = 'resolved' THEN 1 ELSE 0 END) AS resolved_count
    FROM machine_faults
    WHERE opened_at >= (CURRENT_TIMESTAMP - INTERVAL '30 day')
</cfquery>

<cfset machinesArr = []>
<cfloop query="qMachines">
    <cfset arrayAppend(machinesArr, {
        "machine_id": val(machine_id),
        "machine_code": machine_code ?: "",
        "machine_name": machine_name ?: "",
        "department_id": isNumeric(department_id) ? val(department_id) : 0,
        "department_name": department_name ?: "",
        "location_text": location_text ?: "",
        "is_active": is_active,
        "current_status_code": val(current_status_code),
        "current_status_note": current_status_note ?: "",
        "next_maintenance_date": isDate(next_maintenance_date) ? dateFormat(next_maintenance_date, "dd/mm/yyyy") & " " & timeFormat(next_maintenance_date, "HH:mm") : "",
        "open_fault_count": val(open_fault_count)
    })>
</cfloop>

<cfset faultsArr = []>
<cfloop query="qFaults">
    <cfset arrayAppend(faultsArr, {
        "fault_id": val(fault_id), "fault_no": fault_no ?: "", "machine_id": val(machine_id),
        "machine_code": machine_code ?: "", "machine_name": machine_name ?: "", "fault_title": fault_title ?: "",
        "priority_level": val(priority_level), "fault_status": fault_status ?: "",
        "assigned_emp_id": isNumeric(assigned_emp_id) ? val(assigned_emp_id) : 0,
        "assigned_employee": assigned_employee ?: "",
        "opened_at": isDate(opened_at) ? dateFormat(opened_at, "dd/mm/yyyy") & " " & timeFormat(opened_at, "HH:mm") : "",
        "assigned_at": isDate(assigned_at) ? dateFormat(assigned_at, "dd/mm/yyyy") & " " & timeFormat(assigned_at, "HH:mm") : "",
        "resolved_at": isDate(resolved_at) ? dateFormat(resolved_at, "dd/mm/yyyy") & " " & timeFormat(resolved_at, "HH:mm") : "",
        "intervention_note": intervention_note ?: "", "resolution_note": resolution_note ?: "",
        "first_response_min": isNumeric(first_response_min) ? val(first_response_min) : javacast("null",""),
        "close_duration_min": isNumeric(close_duration_min) ? val(close_duration_min) : javacast("null","")
    })>
</cfloop>

<cfset faultEventsArr = []>
<cfloop query="qFaultEvents">
    <cfset arrayAppend(faultEventsArr, {
        "fault_event_id": val(fault_event_id),
        "fault_id": val(fault_id),
        "event_type": event_type ?: "",
        "event_note": event_note ?: "",
        "event_date": isDate(event_date) ? dateFormat(event_date, "dd/mm/yyyy") & " " & timeFormat(event_date, "HH:mm") : "",
        "event_employee": event_employee ?: ""
    })>
</cfloop>

<cfset employeesArr = []>
<cfloop query="qEmployees">
    <cfset arrayAppend(employeesArr, {
        "employee_id": val(employee_id),
        "employee_fullname": employee_fullname ?: ""
    })>
</cfloop>

<cfset plansArr = []>
<cfloop query="qPlans">
    <cfset arrayAppend(plansArr, {
        "plan_id": val(plan_id), "machine_id": val(machine_id), "machine_code": machine_code ?: "", "machine_name": machine_name ?: "",
        "plan_title": plan_title ?: "", "period_days": val(period_days),
        "next_planned_date": isDate(next_planned_date) ? dateFormat(next_planned_date, "dd/mm/yyyy") & " " & timeFormat(next_planned_date, "HH:mm") : "",
        "last_done_date": isDate(last_done_date) ? dateFormat(last_done_date, "dd/mm/yyyy") & " " & timeFormat(last_done_date, "HH:mm") : "",
        "is_active": is_active, "notes": notes ?: ""
    })>
</cfloop>

<cfset maintArr = []>
<cfloop query="qMaintLogs">
    <cfset arrayAppend(maintArr, {
        "maintenance_log_id": val(maintenance_log_id), "machine_id": val(machine_id), "machine_code": machine_code ?: "", "machine_name": machine_name ?: "",
        "plan_id": isNumeric(plan_id) ? val(plan_id) : 0, "maintenance_type": maintenance_type ?: "", "maintenance_result": maintenance_result ?: "",
        "maintenance_start": isDate(maintenance_start) ? dateFormat(maintenance_start, "dd/mm/yyyy") & " " & timeFormat(maintenance_start, "HH:mm") : "",
        "maintenance_end": isDate(maintenance_end) ? dateFormat(maintenance_end, "dd/mm/yyyy") & " " & timeFormat(maintenance_end, "HH:mm") : "",
        "duration_min": isNumeric(duration_min) ? val(duration_min) : javacast("null",""),
        "result_note": result_note ?: ""
    })>
</cfloop>

<cfset deptArr = []>
<cfloop query="qDepartments"><cfset arrayAppend(deptArr,{"department_id":val(department_id),"department_head":department_head ?: ""})></cfloop>

<cfset machineFaultStatsArr = []>
<cfloop query="qMachineFaultStats">
    <cfset arrayAppend(machineFaultStatsArr, {
        "machine_id": val(machine_id),
        "machine_code": machine_code ?: "",
        "machine_name": machine_name ?: "",
        "fault_title": fault_title ?: "",
        "fault_count": val(fault_count),
        "last_fault_at": isDate(last_fault_at) ? dateFormat(last_fault_at, "dd/mm/yyyy") & " " & timeFormat(last_fault_at, "HH:mm") : ""
    })>
</cfloop>

<cfset machineFaultHistoryArr = []>
<cfloop query="qMachineFaultHistory">
    <cfset arrayAppend(machineFaultHistoryArr, {
        "fault_id": val(fault_id),
        "fault_no": fault_no ?: "",
        "machine_id": val(machine_id),
        "machine_code": machine_code ?: "",
        "machine_name": machine_name ?: "",
        "fault_title": fault_title ?: "",
        "priority_level": val(priority_level),
        "fault_status": fault_status ?: "",
        "opened_at": isDate(opened_at) ? dateFormat(opened_at, "dd/mm/yyyy") & " " & timeFormat(opened_at, "HH:mm") : "",
        "assigned_at": isDate(assigned_at) ? dateFormat(assigned_at, "dd/mm/yyyy") & " " & timeFormat(assigned_at, "HH:mm") : "",
        "resolved_at": isDate(resolved_at) ? dateFormat(resolved_at, "dd/mm/yyyy") & " " & timeFormat(resolved_at, "HH:mm") : "",
        "assigned_employee": assigned_employee ?: "",
        "close_duration_min": isNumeric(close_duration_min) ? val(close_duration_min) : javacast("null","")
    })>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-tools"></i></div>
        <div class="page-header-title">
            <h1>Makine Bakım &amp; Arıza Dashboard</h1>
            <p>Makine ekleme, bakım planlama, arıza yaşam döngüsü ve süre takibi</p>
        </div>
    </div>
    <div class="d-flex gap-2">
        <button class="btn btn-primary btn-sm" onclick="showMachineModal()"><i class="fas fa-plus"></i> Makine Ekle</button>
        <button class="btn btn-warning btn-sm" onclick="showPlanModal()"><i class="fas fa-calendar-plus"></i> Bakım Planı</button>
        <button class="btn btn-danger btn-sm" onclick="showFaultModal()"><i class="fas fa-exclamation-triangle"></i> Arıza Bildir</button>
        <button class="btn btn-success btn-sm" onclick="showMaintenanceModal()"><i class="fas fa-check-circle"></i> Bakım Sonucu</button>
    </div>
</div>

<div class="px-3 pb-4">
    <div class="row g-3 mb-3">
        <div class="col-md-2"><div class="card shadow-sm border-0"><div class="card-body"><small>Toplam Makine</small><h3>#val(qSummary.total_machine)#</h3></div></div></div>
        <div class="col-md-2"><div class="card shadow-sm border-0"><div class="card-body"><small>Arıza Yok</small><h3 class="text-success">#val(qSummary.status_ok)#</h3></div></div></div>
        <div class="col-md-2"><div class="card shadow-sm border-0"><div class="card-body"><small>Bakımda</small><h3 class="text-warning">#val(qSummary.status_maintenance)#</h3></div></div></div>
        <div class="col-md-2"><div class="card shadow-sm border-0"><div class="card-body"><small>Arızalı</small><h3 class="text-danger">#val(qSummary.status_fault)#</h3></div></div></div>
        <div class="col-md-2"><div class="card shadow-sm border-0"><div class="card-body"><small>Açık Arıza</small><h3 class="text-danger">#val(qFaultSummary.open_count)#</h3></div></div></div>
        <div class="col-md-2"><div class="card shadow-sm border-0"><div class="card-body"><small>Devam Eden</small><h3 class="text-primary">#val(qFaultSummary.in_progress_count)#</h3></div></div></div>
    </div>

    <ul class="nav nav-tabs" id="machineTab" role="tablist">
      <li class="nav-item"><button class="nav-link active" data-bs-toggle="tab" data-bs-target="##tab-machines" type="button">Makineler</button></li>
      <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="##tab-faults" type="button">Arızalar</button></li>
      <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="##tab-plans" type="button">Bakım Planları</button></li>
      <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="##tab-maint" type="button">Bakım Kayıtları</button></li>
      <li class="nav-item"><button class="nav-link" data-bs-toggle="tab" data-bs-target="##tab-fault-analysis" type="button">Makine Arıza Analiz</button></li>
    </ul>

    <div class="tab-content border border-top-0 p-2 bg-white">
      <div class="tab-pane fade show active" id="tab-machines"><div id="machinesGrid"></div></div>
      <div class="tab-pane fade" id="tab-faults"><div id="faultsGrid"></div></div>
      <div class="tab-pane fade" id="tab-plans"><div id="plansGrid"></div></div>
      <div class="tab-pane fade" id="tab-maint"><div id="maintGrid"></div></div>
      <div class="tab-pane fade" id="tab-fault-analysis">
        <div class="row g-2 align-items-end mb-3">
          <div class="col-md-5">
            <label class="form-label mb-1">Makine seç</label>
            <select id="analysisMachine" class="form-select"></select>
          </div>
          <div class="col-md-3">
            <button class="btn btn-outline-primary" onclick="refreshMachineAnalysis()"><i class="fas fa-filter"></i> Uygula</button>
          </div>
          <div class="col-md-4 text-md-end">
            <div id="topFaultInfo" class="small text-muted">Makine seçerek en çok arıza tipini görün.</div>
          </div>
        </div>
        <div class="row g-3">
          <div class="col-lg-5"><div id="machineFaultFreqGrid"></div></div>
          <div class="col-lg-7"><div id="machineFaultHistoryGrid"></div></div>
        </div>
      </div>
    </div>
</div>

<!-- Modals -->
<div class="modal fade" id="machineModal" tabindex="-1"><div class="modal-dialog modal-lg"><div class="modal-content"><div class="modal-header"><h5>Makine Ekle / Güncelle</h5><button class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body"><div class="row g-2">
<div class="col-md-4"><label>Kod</label><input id="m_code" class="form-control"></div>
<div class="col-md-8"><label>Makine Adı</label><input id="m_name" class="form-control"></div>
<div class="col-md-4"><label>Departman</label><select id="m_dept" class="form-select"></select></div>
<div class="col-md-4"><label>Lokasyon</label><input id="m_loc" class="form-control"></div>
<div class="col-md-2"><label>Durum</label><select id="m_status" class="form-select"><option value="1">Arıza Yok</option><option value="2">Bakımda</option><option value="3">Arızalı</option></select></div>
<div class="col-md-2"><label>Aktif</label><select id="m_active" class="form-select"><option value="1">Evet</option><option value="0">Hayır</option></select></div>
<div class="col-12"><label>Not</label><input id="m_note" class="form-control"></div>
</div></div><div class="modal-footer"><button class="btn btn-secondary" data-bs-dismiss="modal">Kapat</button><button class="btn btn-primary" onclick="saveMachine()">Kaydet</button></div></div></div></div>

<div class="modal fade" id="planModal" tabindex="-1"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><h5>Bakım Planı</h5><button class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body">
<div class="mb-2"><label>Makine</label><select id="p_machine" class="form-select"></select></div>
<div class="mb-2"><label>Plan Başlığı</label><input id="p_title" class="form-control"></div>
<div class="mb-2"><label>Periyot (gün)</label><input id="p_days" type="number" class="form-control" value="30"></div>
<div class="mb-2"><label>Sonraki Plan Tarihi</label><input id="p_next" type="datetime-local" class="form-control"></div>
<div><label>Not</label><textarea id="p_note" class="form-control" rows="2"></textarea></div>
</div><div class="modal-footer"><button class="btn btn-secondary" data-bs-dismiss="modal">Kapat</button><button class="btn btn-warning" onclick="savePlan()">Kaydet</button></div></div></div></div>

<div class="modal fade" id="faultModal" tabindex="-1"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><h5>Arıza Bildirimi</h5><button class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body">
<div class="mb-2"><label>Makine</label><select id="f_machine" class="form-select"></select></div>
<div class="mb-2"><label>Başlık</label><input id="f_title" class="form-control"></div>
<div class="mb-2"><label>Öncelik</label><select id="f_priority" class="form-select"><option value="1">Düşük</option><option value="2" selected>Orta</option><option value="3">Yüksek</option><option value="4">Kritik</option></select></div>
<div><label>Açıklama</label><textarea id="f_desc" class="form-control" rows="3"></textarea></div>
</div><div class="modal-footer"><button class="btn btn-secondary" data-bs-dismiss="modal">Kapat</button><button class="btn btn-danger" onclick="saveFault()">Arıza Aç</button></div></div></div></div>

<div class="modal fade" id="maintenanceModal" tabindex="-1"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><h5>Bakım Sonucu</h5><button class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body">
<div class="mb-2"><label>Makine</label><select id="r_machine" class="form-select"></select></div>
<div class="mb-2"><label>Bakım Planı (opsiyonel)</label><select id="r_plan" class="form-select"><option value="">Plan seçmeden kaydet</option></select></div>
<div class="mb-2"><label>Başlangıç</label><input id="r_start" type="datetime-local" class="form-control"></div>
<div class="mb-2"><label>Bitiş</label><input id="r_end" type="datetime-local" class="form-control"></div>
<div class="mb-2"><label>Sonuç</label><select id="r_result" class="form-select"><option value="completed">Tamamlandı</option><option value="partial">Kısmi</option><option value="failed">Başarısız</option></select></div>
<div><label>Not</label><textarea id="r_note" class="form-control" rows="2"></textarea></div>
</div><div class="modal-footer"><button class="btn btn-secondary" data-bs-dismiss="modal">Kapat</button><button class="btn btn-success" onclick="saveMaintenance()">Kaydet</button></div></div></div></div>

<div class="modal fade" id="faultStageModal" tabindex="-1"><div class="modal-dialog"><div class="modal-content"><div class="modal-header"><h5>Arıza Aşama Güncelle</h5><button class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body">
<div class="mb-2"><label>Arıza No</label><input id="s_fault_no" class="form-control" readonly></div>
<div class="mb-2"><label>Makine</label><input id="s_machine_name" class="form-control" readonly></div>
<div class="mb-2"><label>Aşama</label><select id="s_stage" class="form-select"><option value="assigned">Atandı</option><option value="intervention">Müdahale</option><option value="resolved">Çöz</option><option value="cancelled">İptal</option></select></div>
<div class="mb-2"><label>Atanan Personel</label><select id="s_assigned_emp" class="form-select"><option value="">Personel seçiniz</option></select></div>
<div><label>Aşama Notu</label><textarea id="s_stage_note" class="form-control" rows="3"></textarea></div>
</div><div class="modal-footer"><button class="btn btn-secondary" data-bs-dismiss="modal">Kapat</button><button class="btn btn-primary" onclick="saveFaultStage()">Kaydet</button></div></div></div></div>

<div class="modal fade" id="faultHistoryModal" tabindex="-1"><div class="modal-dialog modal-lg"><div class="modal-content"><div class="modal-header"><h5>Arıza İşlem Tarihçesi</h5><button class="btn-close" data-bs-dismiss="modal"></button></div><div class="modal-body"><div id="faultHistoryGrid"></div></div></div></div></div>

<script>
var machinesData = #serializeJSON(machinesArr)#;
var faultsData = #serializeJSON(faultsArr)#;
var plansData = #serializeJSON(plansArr)#;
var maintData = #serializeJSON(maintArr)#;
var departments = #serializeJSON(deptArr)#;
var employeesData = #serializeJSON(employeesArr)#;
var faultEventsData = #serializeJSON(faultEventsArr)#;
var machineFaultStatsData = #serializeJSON(machineFaultStatsArr)#;
var machineFaultHistoryData = #serializeJSON(machineFaultHistoryArr)#;
var selectedFaultForStage = null;

function statusText(code){ return ({1:'Arıza Yok',2:'Bakımda',3:'Arızalı'})[code] || '-'; }
function priorityText(code){ return ({1:'Düşük',2:'Orta',3:'Yüksek',4:'Kritik'})[code] || '-'; }
function stageText(code){ return ({assigned:'Atandı',intervention:'Müdahale',resolved:'Çöz',cancelled:'İptal',opened:'Açıldı'})[code] || code || '-'; }

$(function(){
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    buildGrids();
    fillSelects();
    refreshMachineAnalysis();
    $('##analysisMachine').on('change', refreshMachineAnalysis);
});

function buildGrids(){
  $('##machinesGrid').dxDataGrid({
    dataSource: machinesData, keyExpr:'machine_id', showBorders:true, rowAlternationEnabled:true,
    searchPanel:{visible:true}, filterRow:{visible:true}, paging:{pageSize:15},
    columns:[
      {dataField:'machine_code',caption:'Kod',width:120},
      {dataField:'machine_name',caption:'Makine',minWidth:180},
      {dataField:'department_name',caption:'Departman',width:150},
      {dataField:'location_text',caption:'Lokasyon',width:120},
      {dataField:'current_status_code',caption:'Durum',width:120, cellTemplate:function(c,o){ c.html('<span class="badge bg-'+(o.value==1?'success':o.value==2?'warning text-dark':'danger')+'">'+statusText(o.value)+'</span>'); }},
      {dataField:'open_fault_count',caption:'Açık Arıza',width:95,alignment:'center'},
      {dataField:'next_maintenance_date',caption:'Sonraki Bakım',width:150},
      {caption:'İşlem',width:80,allowFiltering:false,allowSorting:false,cellTemplate:function(c,o){ $('<button class="btn btn-sm btn-outline-primary"><i class="fas fa-edit"></i></button>').on('click',function(){showMachineModal(o.data);}).appendTo(c);} }
    ]
  });

  $('##faultsGrid').dxDataGrid({
    dataSource:faultsData, keyExpr:'fault_id', showBorders:true, rowAlternationEnabled:true, searchPanel:{visible:true}, filterRow:{visible:true}, paging:{pageSize:15},
    columns:[
      {dataField:'fault_no',caption:'Arıza No',width:130}, {dataField:'machine_name',caption:'Makine',minWidth:150}, {dataField:'fault_title',caption:'Başlık',minWidth:180},
      {dataField:'priority_level',caption:'Öncelik',width:90, cellTemplate:function(c,o){c.text(priorityText(o.value));}},
      {dataField:'fault_status',caption:'Durum',width:110, cellTemplate:function(c,o){var t=o.value;var cls=t=='open'?'danger':t=='in_progress'?'primary':t=='resolved'?'success':'secondary'; c.html('<span class="badge bg-'+cls+'">'+t+'</span>');}},
      {dataField:'assigned_employee',caption:'Atanan',width:150},
      {dataField:'opened_at',caption:'Açılış',width:140}, {dataField:'assigned_at',caption:'Müdahale',width:140}, {dataField:'resolved_at',caption:'Bitiş',width:140},
      {dataField:'first_response_min',caption:'İlk Müd. (dk)',width:110,alignment:'right'}, {dataField:'close_duration_min',caption:'Toplam (dk)',width:110,alignment:'right'},
      {caption:'Aksiyon',width:250,allowFiltering:false,allowSorting:false,cellTemplate:function(c,o){
        $('<button class="btn btn-sm btn-outline-primary me-1">Aşama Güncelle</button>').on('click',function(){showFaultStageModal(o.data);}).appendTo(c);
        $('<button class="btn btn-sm btn-outline-dark">Tarihçe</button>').on('click',function(){showFaultHistoryModal(o.data);}).appendTo(c);
      }}
    ]
  });

  $('##plansGrid').dxDataGrid({ dataSource:plansData,keyExpr:'plan_id',showBorders:true,rowAlternationEnabled:true,searchPanel:{visible:true},paging:{pageSize:15},columns:[
    {dataField:'machine_name',caption:'Makine',minWidth:170},{dataField:'plan_title',caption:'Plan',minWidth:170},{dataField:'period_days',caption:'Periyot',width:90},{dataField:'next_planned_date',caption:'Sonraki Tarih',width:150},{dataField:'last_done_date',caption:'Son Yapılan',width:150},{dataField:'is_active',caption:'Aktif',width:70}
  ]});

  $('##maintGrid').dxDataGrid({ dataSource:maintData,keyExpr:'maintenance_log_id',showBorders:true,rowAlternationEnabled:true,searchPanel:{visible:true},paging:{pageSize:15},columns:[
    {dataField:'machine_name',caption:'Makine',minWidth:170},{dataField:'maintenance_type',caption:'Tip',width:100},{dataField:'maintenance_result',caption:'Sonuç',width:100},{dataField:'maintenance_start',caption:'Başlangıç',width:150},{dataField:'maintenance_end',caption:'Bitiş',width:150},{dataField:'duration_min',caption:'Süre (dk)',width:90},{dataField:'result_note',caption:'Not',minWidth:200}
  ]});

  $('##faultHistoryGrid').dxDataGrid({
    dataSource: [], keyExpr: 'fault_event_id', showBorders:true, rowAlternationEnabled:true, searchPanel:{visible:true}, paging:{pageSize:10},
    columns:[
      {dataField:'event_date',caption:'Tarih',width:150},
      {dataField:'event_type',caption:'Aşama',width:120, cellTemplate:function(c,o){c.text(stageText(o.value));}},
      {dataField:'event_employee',caption:'İşlemi Yapan',width:180},
      {dataField:'event_note',caption:'Not',minWidth:250}
    ]
  });

  $('##machineFaultFreqGrid').dxDataGrid({
    dataSource:[], keyExpr:'fault_title', showBorders:true, rowAlternationEnabled:true, searchPanel:{visible:true}, paging:{pageSize:10},
    columns:[
      {dataField:'fault_title',caption:'Arıza Tipi',minWidth:180},
      {dataField:'fault_count',caption:'Adet',width:90,alignment:'right'},
      {dataField:'last_fault_at',caption:'Son Görülme',width:150}
    ]
  });

  $('##machineFaultHistoryGrid').dxDataGrid({
    dataSource:[], keyExpr:'fault_id', showBorders:true, rowAlternationEnabled:true, searchPanel:{visible:true}, paging:{pageSize:12},
    columns:[
      {dataField:'fault_no',caption:'Arıza No',width:130},
      {dataField:'fault_title',caption:'Başlık',minWidth:180},
      {dataField:'priority_level',caption:'Öncelik',width:90, cellTemplate:function(c,o){c.text(priorityText(o.value));}},
      {dataField:'fault_status',caption:'Durum',width:110},
      {dataField:'assigned_employee',caption:'Personel',width:150},
      {dataField:'opened_at',caption:'Açılış',width:140},
      {dataField:'resolved_at',caption:'Kapanış',width:140},
      {dataField:'close_duration_min',caption:'Süre (dk)',width:90,alignment:'right'}
    ]
  });
}

function fillSelects(){
  var deptOpt = '<option value="">Seçiniz</option>';
  departments.forEach(function(d){ deptOpt += '<option value="'+d.department_id+'">'+d.department_head+'</option>'; });
  $('##m_dept').html(deptOpt);

  var machineOpt = '<option value="">Seçiniz</option>';
  machinesData.forEach(function(m){ machineOpt += '<option value="'+m.machine_id+'">'+m.machine_code+' - '+m.machine_name+'</option>'; });
  $('##p_machine, ##f_machine, ##r_machine, ##analysisMachine').html(machineOpt);

  var planOpt = '<option value="">Plan seçmeden kaydet</option>';
  plansData.forEach(function(p){ planOpt += '<option value="'+p.plan_id+'">'+p.machine_code+' - '+p.plan_title+'</option>'; });
  $('##r_plan').html(planOpt);

  var empOpt = '<option value="">Personel seçiniz</option>';
  employeesData.forEach(function(e){ empOpt += '<option value="'+e.employee_id+'">'+e.employee_fullname+'</option>'; });
  $('##s_assigned_emp').html(empOpt);
}

var editingMachineId = 0;
function showMachineModal(row){
  editingMachineId = row ? row.machine_id : 0;
  $('##m_code').val(row ? row.machine_code : ''); $('##m_name').val(row ? row.machine_name : ''); $('##m_dept').val(row ? row.department_id : '');
  $('##m_loc').val(row ? row.location_text : ''); $('##m_status').val(row ? row.current_status_code : '1'); $('##m_active').val(row && row.is_active===false ? '0' : '1');
  $('##m_note').val(row ? row.current_status_note : '');
  var mel = document.getElementById('machineModal');
  if (mel.parentElement !== document.body) document.body.appendChild(mel);
  new bootstrap.Modal(mel).show();
}
function showPlanModal(){
  var el = document.getElementById('planModal');
  if (el.parentElement !== document.body) document.body.appendChild(el);
  new bootstrap.Modal(el).show();
}
function showFaultModal(){
  var el = document.getElementById('faultModal');
  if (el.parentElement !== document.body) document.body.appendChild(el);
  new bootstrap.Modal(el).show();
}
function showMaintenanceModal(){
  var el = document.getElementById('maintenanceModal');
  if (el.parentElement !== document.body) document.body.appendChild(el);
  new bootstrap.Modal(el).show();
}

function saveMachine(){
  $.post('/machine/form/save_machine.cfm',{machine_id:editingMachineId,machine_code:$('##m_code').val(),machine_name:$('##m_name').val(),department_id:$('##m_dept').val(),location_text:$('##m_loc').val(),current_status_code:$('##m_status').val(),is_active:$('##m_active').val(),current_status_note:$('##m_note').val()},ajaxDone,'json').fail(ajaxFail);
}
function savePlan(){
  $.post('/machine/form/save_maintenance_plan.cfm',{machine_id:$('##p_machine').val(),plan_title:$('##p_title').val(),period_days:$('##p_days').val(),next_planned_date:$('##p_next').val(),notes:$('##p_note').val()},ajaxDone,'json').fail(ajaxFail);
}
function saveFault(){
  $.post('/machine/form/save_fault.cfm',{machine_id:$('##f_machine').val(),fault_title:$('##f_title').val(),fault_description:$('##f_desc').val(),priority_level:$('##f_priority').val()},ajaxDone,'json').fail(ajaxFail);
}
function saveMaintenance(){
  $.post('/machine/form/save_maintenance_result.cfm',{machine_id:$('##r_machine').val(),plan_id:$('##r_plan').val(),maintenance_start:$('##r_start').val(),maintenance_end:$('##r_end').val(),maintenance_result:$('##r_result').val(),result_note:$('##r_note').val()},ajaxDone,'json').fail(ajaxFail);
}

function showFaultStageModal(row){
  selectedFaultForStage = row || null;
  if(!selectedFaultForStage){ return; }
  $('##s_fault_no').val(selectedFaultForStage.fault_no || '');
  $('##s_machine_name').val(selectedFaultForStage.machine_name || '');
  $('##s_stage').val(selectedFaultForStage.fault_status === 'resolved' ? 'resolved' : 'assigned');
  $('##s_assigned_emp').val(selectedFaultForStage.assigned_emp_id ? String(selectedFaultForStage.assigned_emp_id) : '');
  $('##s_stage_note').val('');

  var el = document.getElementById('faultStageModal');
  if (el.parentElement !== document.body) document.body.appendChild(el);
  new bootstrap.Modal(el).show();
}

function saveFaultStage(){
  if(!selectedFaultForStage){ return; }
  var stage = $('##s_stage').val();
  var assignedEmpId = $('##s_assigned_emp').val();
  if(stage !== 'cancelled' && !assignedEmpId){
    DevExpress.ui.notify('Arıza ataması için personel seçimi zorunludur.', 'warning', 3000);
    return;
  }

  $.post('/machine/form/update_fault_stage.cfm',{
    fault_id:selectedFaultForStage.fault_id,
    stage:stage,
    stage_note:$('##s_stage_note').val(),
    assigned_emp_id:assignedEmpId
  },ajaxDone,'json').fail(ajaxFail);
}

function showFaultHistoryModal(row){
  if(!row){ return; }
  var events = faultEventsData.filter(function(e){ return Number(e.fault_id) === Number(row.fault_id); });
  var grid = $('##faultHistoryGrid').dxDataGrid('instance');
  if(grid){ grid.option('dataSource', events); }
  var el = document.getElementById('faultHistoryModal');
  if (el.parentElement !== document.body) document.body.appendChild(el);
  new bootstrap.Modal(el).show();
}

function refreshMachineAnalysis(){
  var machineId = Number($('##analysisMachine').val() || 0);
  var filteredStats = machineId > 0 ? machineFaultStatsData.filter(function(x){ return Number(x.machine_id) === machineId; }) : machineFaultStatsData;
  var filteredHistory = machineId > 0 ? machineFaultHistoryData.filter(function(x){ return Number(x.machine_id) === machineId; }) : machineFaultHistoryData;

  var freqGrid = $('##machineFaultFreqGrid').dxDataGrid('instance');
  var historyGrid = $('##machineFaultHistoryGrid').dxDataGrid('instance');
  if(freqGrid){ freqGrid.option('dataSource', filteredStats); }
  if(historyGrid){ historyGrid.option('dataSource', filteredHistory); }

  if(machineId > 0 && filteredStats.length){
    var top = filteredStats.slice().sort(function(a,b){ return Number(b.fault_count) - Number(a.fault_count); })[0];
    $('##topFaultInfo').text('En sık arıza: ' + (top.fault_title || '-') + ' (' + top.fault_count + ' kez)');
  } else if(machineId > 0){
    $('##topFaultInfo').text('Seçilen makine için arıza kaydı bulunamadı.');
  } else {
    $('##topFaultInfo').text('Tüm makineler görüntüleniyor.');
  }
}

function ajaxDone(res){
  if(res && res.success){ DevExpress.ui.notify('İşlem başarılı. Sayfa yenileniyor...', 'success', 1500); setTimeout(function(){ location.reload(); }, 600); }
  else{ DevExpress.ui.notify((res && res.message) || 'İşlem başarısız.', 'error', 3000); }
}
function ajaxFail(){ DevExpress.ui.notify('Sunucu hatası.', 'error', 3000); }
</script>
</cfoutput>
