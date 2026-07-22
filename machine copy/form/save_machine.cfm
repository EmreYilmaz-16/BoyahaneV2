<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8"><cfsetting showdebugoutput="false">

<cfset response = {"success":false,"message":""}>
<cftry>
    <cfset machineId   = isDefined("form.machine_id") and isNumeric(form.machine_id) ? val(form.machine_id) : 0>
    <cfset machineCode = left(trim(form.machine_code ?: ""), 50)>
    <cfset machineName = left(trim(form.machine_name ?: ""), 150)>
    <cfset departmentId = isDefined("form.department_id") and isNumeric(form.department_id) and val(form.department_id) gt 0 ? val(form.department_id) : javaCast("null","")>
    <cfset locationText = left(trim(form.location_text ?: ""), 150)>
    <cfset isActive = isDefined("form.is_active") and val(form.is_active) eq 0 ? false : true>
    <cfset statusCode = isDefined("form.current_status_code") and isNumeric(form.current_status_code) ? val(form.current_status_code) : 1>
    <cfset statusNote = left(trim(form.current_status_note ?: ""), 500)>

    <cfif NOT len(machineCode) OR NOT len(machineName)>
        <cfset response.message = "Makine kodu ve adı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif machineId gt 0>
        <cfquery datasource="boyahane">
            UPDATE machine_machines SET
                machine_code = <cfqueryparam value="#machineCode#" cfsqltype="cf_sql_varchar">,
                machine_name = <cfqueryparam value="#machineName#" cfsqltype="cf_sql_varchar">,
                department_id = <cfqueryparam value="#isNull(departmentId)?'':departmentId#" cfsqltype="cf_sql_integer" null="#isNull(departmentId)#">,
                location_text = <cfqueryparam value="#locationText#" cfsqltype="cf_sql_varchar" null="#NOT len(locationText)#">,
                is_active = <cfqueryparam value="#isActive#" cfsqltype="cf_sql_bit">,
                current_status_code = <cfqueryparam value="#statusCode#" cfsqltype="cf_sql_integer">,
                current_status_note = <cfqueryparam value="#statusNote#" cfsqltype="cf_sql_varchar" null="#NOT len(statusNote)#">,
                update_date = CURRENT_TIMESTAMP,
                update_emp = <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">,
                update_ip = <cfqueryparam value="#cgi.remote_addr ?: ''#" cfsqltype="cf_sql_varchar" null="#NOT len(cgi.remote_addr ?: '')#">
            WHERE machine_id = <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset savedId = machineId>
    <cfelse>
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO machine_machines (
                machine_code, machine_name, department_id, location_text,
                is_active, current_status_code, current_status_note,
                record_date, record_emp, record_ip
            ) VALUES (
                <cfqueryparam value="#machineCode#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#machineName#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#isNull(departmentId)?'':departmentId#" cfsqltype="cf_sql_integer" null="#isNull(departmentId)#">,
                <cfqueryparam value="#locationText#" cfsqltype="cf_sql_varchar" null="#NOT len(locationText)#">,
                <cfqueryparam value="#isActive#" cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#statusCode#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#statusNote#" cfsqltype="cf_sql_varchar" null="#NOT len(statusNote)#">,
                CURRENT_TIMESTAMP,
                <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">,
                <cfqueryparam value="#cgi.remote_addr ?: ''#" cfsqltype="cf_sql_varchar" null="#NOT len(cgi.remote_addr ?: '')#">
            ) RETURNING machine_id
        </cfquery>
        <cfset savedId = val(ins.machine_id)>

        <cfquery datasource="boyahane">
            INSERT INTO machine_status_history (machine_id, status_code, status_note, source_type, source_id, record_emp)
            VALUES (
                <cfqueryparam value="#savedId#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#statusCode#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#statusNote#" cfsqltype="cf_sql_varchar" null="#NOT len(statusNote)#">,
                'manual',
                NULL,
                <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
            )
        </cfquery>
    </cfif>

    <cfset response = {"success":true,"machine_id":savedId}>
    <cfcatch type="any"><cfset response.message = cfcatch.message></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
