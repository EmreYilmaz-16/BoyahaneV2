<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8"><cfsetting showdebugoutput="false">
<cfset response = {"success":false,"message":""}>

<cftry>
    <cfset machineId      = isDefined("form.machine_id") and isNumeric(form.machine_id) ? val(form.machine_id) : 0>
    <cfset planId         = isDefined("form.plan_id") and isNumeric(form.plan_id) and val(form.plan_id) gt 0 ? val(form.plan_id) : javaCast("null","")>
    <cfset maintenanceType= left(trim(form.maintenance_type ?: "planned"), 30)>
    <cfset startRaw       = trim(form.maintenance_start ?: "")>
    <cfset endRaw         = trim(form.maintenance_end ?: "")>
    <cfset resultStatus   = left(trim(form.maintenance_result ?: "completed"), 30)>
    <cfset resultNote     = left(trim(form.result_note ?: ""), 2000)>

    <cfif machineId lte 0>
        <cfset response.message = "Makine seçimi zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset startDate = (len(startRaw) AND isDate(startRaw)) ? createODBCDateTime(parseDateTime(replace(startRaw,'T',' ','all'))) : javaCast("null","")>
    <cfset endDate   = (len(endRaw)   AND isDate(endRaw))   ? createODBCDateTime(parseDateTime(replace(endRaw,'T',' ','all')))   : javaCast("null","")>

    <cfquery datasource="boyahane">
        INSERT INTO machine_maintenance_logs (
            machine_id, plan_id, maintenance_type, maintenance_start, maintenance_end,
            maintenance_result, result_note, performed_by, record_date, record_emp
        ) VALUES (
            <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#isNull(planId)?'':planId#" cfsqltype="cf_sql_integer" null="#isNull(planId)#">,
            <cfqueryparam value="#maintenanceType#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#isNull(startDate)?'':startDate#" cfsqltype="cf_sql_timestamp" null="#isNull(startDate)#">,
            <cfqueryparam value="#isNull(endDate)?'':endDate#" cfsqltype="cf_sql_timestamp" null="#isNull(endDate)#">,
            <cfqueryparam value="#resultStatus#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#resultNote#" cfsqltype="cf_sql_varchar" null="#NOT len(resultNote)#">,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">,
            CURRENT_TIMESTAMP,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
        )
    </cfquery>

    <cfquery datasource="boyahane">
        UPDATE machine_machines
        SET current_status_code = 1,
            current_status_note = 'Bakım tamamlandı',
            last_maintenance_date = CURRENT_TIMESTAMP,
            update_date = CURRENT_TIMESTAMP
        WHERE machine_id = <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfquery datasource="boyahane">
        INSERT INTO machine_status_history (machine_id, status_code, status_note, source_type, source_id, record_emp)
        VALUES (
            <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">,
            1,
            'Bakım sonucu girildi',
            'maintenance',
            NULL,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
        )
    </cfquery>

    <cfif NOT isNull(planId)>
        <cfquery datasource="boyahane">
            UPDATE machine_maintenance_plans
            SET last_done_date = CURRENT_TIMESTAMP,
                next_planned_date = CURRENT_TIMESTAMP + (period_days || ' day')::interval,
                update_date = CURRENT_TIMESTAMP,
                update_emp = <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
            WHERE plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cfif>

    <cfset response = {"success":true}>
    <cfcatch type="any"><cfset response.message = cfcatch.message></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
