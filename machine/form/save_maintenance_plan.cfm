<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8"><cfsetting showdebugoutput="false">
<cfset response = {"success":false,"message":""}>

<cftry>
    <cfset planId      = isDefined("form.plan_id") and isNumeric(form.plan_id) ? val(form.plan_id) : 0>
    <cfset machineId   = isDefined("form.machine_id") and isNumeric(form.machine_id) ? val(form.machine_id) : 0>
    <cfset planTitle   = left(trim(form.plan_title ?: ""), 200)>
    <cfset periodDays  = isDefined("form.period_days") and isNumeric(form.period_days) ? val(form.period_days) : 0>
    <cfset nextDateRaw = trim(form.next_planned_date ?: "")>
    <cfset notes       = left(trim(form.notes ?: ""), 1000)>
    <cfset isActive    = isDefined("form.is_active") and val(form.is_active) eq 0 ? false : true>

    <cfif machineId lte 0 OR NOT len(planTitle) OR periodDays lte 0>
        <cfset response.message = "Makine, plan başlığı ve periyot zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset nextDate = (len(nextDateRaw) AND isDate(nextDateRaw)) ? createODBCDateTime(parseDateTime(replace(nextDateRaw,'T',' ','all'))) : javaCast("null","")>

    <cfif planId gt 0>
        <cfquery datasource="boyahane">
            UPDATE machine_maintenance_plans SET
                plan_title = <cfqueryparam value="#planTitle#" cfsqltype="cf_sql_varchar">,
                period_days = <cfqueryparam value="#periodDays#" cfsqltype="cf_sql_integer">,
                next_planned_date = <cfqueryparam value="#isNull(nextDate)?'':nextDate#" cfsqltype="cf_sql_timestamp" null="#isNull(nextDate)#">,
                notes = <cfqueryparam value="#notes#" cfsqltype="cf_sql_varchar" null="#NOT len(notes)#">,
                is_active = <cfqueryparam value="#isActive#" cfsqltype="cf_sql_bit">,
                update_date = CURRENT_TIMESTAMP,
                update_emp = <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
            WHERE plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset savedId = planId>
    <cfelse>
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO machine_maintenance_plans (
                machine_id, plan_title, period_days, next_planned_date, notes, is_active, record_date, record_emp
            ) VALUES (
                <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#planTitle#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#periodDays#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#isNull(nextDate)?'':nextDate#" cfsqltype="cf_sql_timestamp" null="#isNull(nextDate)#">,
                <cfqueryparam value="#notes#" cfsqltype="cf_sql_varchar" null="#NOT len(notes)#">,
                <cfqueryparam value="#isActive#" cfsqltype="cf_sql_bit">,
                CURRENT_TIMESTAMP,
                <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
            ) RETURNING plan_id
        </cfquery>
        <cfset savedId = val(ins.plan_id)>
    </cfif>

    <cfset response = {"success":true,"plan_id":savedId}>
    <cfcatch type="any"><cfset response.message = cfcatch.message></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
