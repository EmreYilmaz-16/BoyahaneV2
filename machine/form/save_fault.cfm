<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8"><cfsetting showdebugoutput="false">
<cfset response = {"success":false,"message":""}>

<cftry>
    <cfset machineId      = isDefined("form.machine_id") and isNumeric(form.machine_id) ? val(form.machine_id) : 0>
    <cfset faultTitle     = left(trim(form.fault_title ?: ""), 200)>
    <cfset faultDesc      = left(trim(form.fault_description ?: ""), 4000)>
    <cfset priorityLevel  = isDefined("form.priority_level") and isNumeric(form.priority_level) ? val(form.priority_level) : 2>
    <cfset rootCauseCode  = listFindNoCase("mechanical,electrical,pneumatic,hydraulic,operator_error,wear,other", trim(form.root_cause_code ?: "")) ? trim(form.root_cause_code) : "">
    <cfset downtimeCat    = listFindNoCase("unplanned,planned,production_change,cleaning", trim(form.downtime_category ?: "")) ? trim(form.downtime_category) : "unplanned">

    <cfif machineId lte 0 OR NOT len(faultTitle)>
        <cfset response.message = "Makine ve arıza başlığı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery name="qMachine" datasource="boyahane">
        SELECT machine_id, is_active
        FROM machine_machines
        WHERE machine_id = <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif qMachine.recordCount eq 0>
        <cfset response.message = "Seçilen makine bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif NOT qMachine.is_active>
        <cfset response.message = "Pasif makine için arıza kaydı açılamaz.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset faultNo = "ARZ-" & dateFormat(now(),"yyyymmdd") & "-" & right("0000" & randRange(1,9999),4)>
    <cfquery name="getFaultNo" datasource="boyahane">
        SELECT 'ARZ-' || to_char(CURRENT_DATE, 'YYYYMMDD') || '-' || lpad(nextval('machine_fault_no_seq')::text, 6, '0') AS fault_no
    </cfquery>
    <cfset faultNo = getFaultNo.fault_no>

    <cfquery name="insFault" datasource="boyahane">
        INSERT INTO machine_faults (
            machine_id, fault_no, fault_title, fault_description, priority_level,
            root_cause_code, downtime_category,
            fault_status, opened_at, opened_by, record_date
        ) VALUES (
            <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#faultNo#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#faultTitle#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#faultDesc#" cfsqltype="cf_sql_varchar" null="#NOT len(faultDesc)#">,
            <cfqueryparam value="#priorityLevel#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#rootCauseCode#" cfsqltype="cf_sql_varchar" null="#NOT len(rootCauseCode)#">,
            <cfqueryparam value="#downtimeCat#" cfsqltype="cf_sql_varchar">,
            'open', CURRENT_TIMESTAMP,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">,
            CURRENT_TIMESTAMP
        ) RETURNING fault_id, fault_no
    </cfquery>

    <cfquery datasource="boyahane">
        INSERT INTO machine_fault_events (fault_id, event_type, event_note, event_date, employee_id)
        VALUES (
            <cfqueryparam value="#insFault.fault_id#" cfsqltype="cf_sql_integer">,
            'opened',
            <cfqueryparam value="#faultTitle#" cfsqltype="cf_sql_varchar">,
            CURRENT_TIMESTAMP,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
        )
    </cfquery>

    <cfquery datasource="boyahane">
        UPDATE machine_machines
        SET current_status_code = 3,
            current_status_note = <cfqueryparam value="#'Aktif arıza: ' & faultTitle#" cfsqltype="cf_sql_varchar">,
            update_date = CURRENT_TIMESTAMP
        WHERE machine_id = <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfquery datasource="boyahane">
        INSERT INTO machine_status_history (machine_id, status_code, status_note, source_type, source_id, record_emp)
        VALUES (
            <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">,
            3,
            <cfqueryparam value="#faultTitle#" cfsqltype="cf_sql_varchar">,
            'fault',
            <cfqueryparam value="#insFault.fault_id#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
        )
    </cfquery>

    <cfset response = {"success":true,"fault_id":val(insFault.fault_id),"fault_no":insFault.fault_no}>
    <cfcatch type="any"><cfset response.message = "Arıza kaydı oluşturulurken bir hata oluştu."></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
