<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8"><cfsetting showdebugoutput="false">
<cfset response = {"success":false,"message":""}>

<cftry>
    <cfset faultId      = isDefined("form.fault_id") and isNumeric(form.fault_id) ? val(form.fault_id) : 0>
    <cfset stage        = lcase(trim(form.stage ?: ""))>
    <cfset stageNote    = left(trim(form.stage_note ?: ""), 2000)>
    <cfset assignedEmp  = isDefined("form.assigned_emp_id") and isNumeric(form.assigned_emp_id) and val(form.assigned_emp_id) gt 0 ? val(form.assigned_emp_id) : javaCast("null","")>

    <cfif faultId lte 0 OR NOT listFindNoCase("assigned,intervention,resolved,cancelled", stage)>
        <cfset response.message = "Geçersiz arıza veya aşama.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery name="getFault" datasource="boyahane">
        SELECT fault_id, machine_id, fault_status, opened_at, assigned_at, resolved_at
        FROM machine_faults
        WHERE fault_id = <cfqueryparam value="#faultId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif getFault.recordCount eq 0>
        <cfset response.message = "Arıza kaydı bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset newStatus = getFault.fault_status>
    <cfif stage eq "assigned" OR stage eq "intervention"><cfset newStatus = "in_progress"></cfif>
    <cfif stage eq "resolved"><cfset newStatus = "resolved"></cfif>
    <cfif stage eq "cancelled"><cfset newStatus = "cancelled"></cfif>

    <cfquery datasource="boyahane">
        UPDATE machine_faults SET
            fault_status = <cfqueryparam value="#newStatus#" cfsqltype="cf_sql_varchar">,
            assigned_emp_id = <cfqueryparam value="#isNull(assignedEmp)?'':assignedEmp#" cfsqltype="cf_sql_integer" null="#isNull(assignedEmp)#">,
            assigned_at = CASE WHEN <cfqueryparam value="#stage#" cfsqltype="cf_sql_varchar"> IN ('assigned','intervention') AND assigned_at IS NULL THEN CURRENT_TIMESTAMP ELSE assigned_at END,
            resolved_at = CASE WHEN <cfqueryparam value="#stage#" cfsqltype="cf_sql_varchar"> = 'resolved' THEN CURRENT_TIMESTAMP ELSE resolved_at END,
            intervention_note = CASE WHEN <cfqueryparam value="#stage#" cfsqltype="cf_sql_varchar"> = 'intervention' THEN <cfqueryparam value="#stageNote#" cfsqltype="cf_sql_varchar" null="#NOT len(stageNote)#"> ELSE intervention_note END,
            resolution_note = CASE WHEN <cfqueryparam value="#stage#" cfsqltype="cf_sql_varchar"> = 'resolved' THEN <cfqueryparam value="#stageNote#" cfsqltype="cf_sql_varchar" null="#NOT len(stageNote)#"> ELSE resolution_note END,
            update_date = CURRENT_TIMESTAMP
        WHERE fault_id = <cfqueryparam value="#faultId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfquery datasource="boyahane">
        INSERT INTO machine_fault_events (fault_id, event_type, event_note, event_date, employee_id)
        VALUES (
            <cfqueryparam value="#faultId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#stage#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#stageNote#" cfsqltype="cf_sql_varchar" null="#NOT len(stageNote)#">,
            CURRENT_TIMESTAMP,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
        )
    </cfquery>

    <cfset machineStatus = 3>
    <cfset machineStatusNote = "Aktif arıza mevcut">
    <cfif newStatus eq "resolved" OR newStatus eq "cancelled">
        <cfquery name="qOpen" datasource="boyahane">
            SELECT count(*) AS open_count
            FROM machine_faults
            WHERE machine_id = <cfqueryparam value="#getFault.machine_id#" cfsqltype="cf_sql_integer">
              AND fault_status IN ('open','in_progress')
        </cfquery>
        <cfif val(qOpen.open_count) eq 0>
            <cfset machineStatus = 1>
            <cfset machineStatusNote = "Arıza yok">
        </cfif>
    </cfif>

    <cfquery datasource="boyahane">
        UPDATE machine_machines
        SET current_status_code = <cfqueryparam value="#machineStatus#" cfsqltype="cf_sql_integer">,
            current_status_note = <cfqueryparam value="#machineStatusNote#" cfsqltype="cf_sql_varchar">,
            update_date = CURRENT_TIMESTAMP
        WHERE machine_id = <cfqueryparam value="#getFault.machine_id#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfquery datasource="boyahane">
        INSERT INTO machine_status_history (machine_id, status_code, status_note, source_type, source_id, record_emp)
        VALUES (
            <cfqueryparam value="#getFault.machine_id#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#machineStatus#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#'Arıza aşaması: ' & stage#" cfsqltype="cf_sql_varchar">,
            'fault',
            <cfqueryparam value="#faultId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
        )
    </cfquery>

    <cfset response = {"success":true}>
    <cfcatch type="any"><cfset response.message = cfcatch.message></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
