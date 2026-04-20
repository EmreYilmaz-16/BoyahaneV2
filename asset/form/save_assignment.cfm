<cfprocessingdirective pageEncoding="utf-8">
<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <!--- Zorunlu alanlar --->
    <cfif not (isDefined("form.asset_id") and isNumeric(form.asset_id) and val(form.asset_id) gt 0)>
        <cfoutput>{"success":false,"message":"Demirbaş seçimi zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif not (isDefined("form.assigned_to_name") and len(trim(form.assigned_to_name)))>
        <cfoutput>{"success":false,"message":"Personel adı zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif not (isDefined("form.assigned_date") and isDate(form.assigned_date))>
        <cfoutput>{"success":false,"message":"Zimmet tarihi zorunludur."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Durum whitelist --->
    <cfset allowedStatus = "ACTIVE,RETURNED,LOST,DAMAGED">
    <cfset statusVal = isDefined("form.assignment_status") ? UCase(trim(form.assignment_status)) : "ACTIVE">
    <cfif not listFind(allowedStatus, statusVal)>
        <cfset statusVal = "ACTIVE">
    </cfif>

    <!--- Null bayrakları --->
    <cfset assignmentIdNull   = not (isDefined("form.assignment_id")   and isNumeric(form.assignment_id)   and val(form.assignment_id)   gt 0)>
    <cfset userIdNull         = not (isDefined("form.user_id")         and isNumeric(form.user_id)         and val(form.user_id)         gt 0)>
    <cfset deptIdNull         = not (isDefined("form.department_id")   and isNumeric(form.department_id)   and val(form.department_id)   gt 0)>
    <cfset expectedReturnNull = not (isDefined("form.expected_return_date") and isDate(form.expected_return_date) and len(trim(form.expected_return_date)))>

    <cfset assetId          = val(form.asset_id)>
    <cfset userId           = assignmentIdNull ? 0 : val(form.user_id)>
    <cfset deptId           = deptIdNull ? 0 : val(form.department_id)>
    <cfset assignedToName   = left(trim(form.assigned_to_name), 200)>
    <cfset assignedToTitle  = isDefined("form.assigned_to_title")    ? left(trim(form.assigned_to_title),  100) : "">
    <cfset departmentName   = isDefined("form.department_name")      ? left(trim(form.department_name),    150) : "">
    <cfset assignedBy       = isDefined("form.assigned_by")          ? left(trim(form.assigned_by),        100) : "">
    <cfset notes            = isDefined("form.notes")                ? trim(form.notes)                        : "">

    <cfif assignmentIdNull>
        <!--- INSERT --->
        <cfquery name="qInsert" datasource="boyahane">
            INSERT INTO asset_assignments (
                asset_id, user_id, assigned_to_name, assigned_to_title,
                department_id, department_name,
                assigned_date, expected_return_date,
                assignment_status, notes, assigned_by, record_date
            ) VALUES (
                <cfqueryparam value="#assetId#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#val(form.user_id)#" cfsqltype="cf_sql_integer" null="#userIdNull#">,
                <cfqueryparam value="#assignedToName#"  cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#assignedToTitle#" cfsqltype="cf_sql_varchar" null="#not len(assignedToTitle)#">,
                <cfqueryparam value="#val(form.department_id)#" cfsqltype="cf_sql_integer" null="#deptIdNull#">,
                <cfqueryparam value="#departmentName#" cfsqltype="cf_sql_varchar" null="#not len(departmentName)#">,
                <cfqueryparam value="#form.assigned_date#" cfsqltype="cf_sql_date">,
                <cfqueryparam value="#form.expected_return_date#" cfsqltype="cf_sql_date" null="#expectedReturnNull#">,
                <cfqueryparam value="#statusVal#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#notes#" cfsqltype="cf_sql_longvarchar" null="#not len(notes)#">,
                <cfqueryparam value="#assignedBy#" cfsqltype="cf_sql_varchar" null="#not len(assignedBy)#">,
                CURRENT_TIMESTAMP
            )
            RETURNING assignment_id
        </cfquery>
        <cfset newId = qInsert.assignment_id>
        <cfoutput>{"success":true,"assignment_id":#newId#,"action":"insert"}</cfoutput>
    <cfelse>
        <!--- UPDATE --->
        <cfset assignmentId = val(form.assignment_id)>
        <cfquery name="qUpdate" datasource="boyahane">
            UPDATE asset_assignments SET
                asset_id              = <cfqueryparam value="#assetId#" cfsqltype="cf_sql_integer">,
                user_id               = <cfqueryparam value="#val(form.user_id)#" cfsqltype="cf_sql_integer" null="#userIdNull#">,
                assigned_to_name      = <cfqueryparam value="#assignedToName#"  cfsqltype="cf_sql_varchar">,
                assigned_to_title     = <cfqueryparam value="#assignedToTitle#" cfsqltype="cf_sql_varchar" null="#not len(assignedToTitle)#">,
                department_id         = <cfqueryparam value="#val(form.department_id)#" cfsqltype="cf_sql_integer" null="#deptIdNull#">,
                department_name       = <cfqueryparam value="#departmentName#" cfsqltype="cf_sql_varchar" null="#not len(departmentName)#">,
                assigned_date         = <cfqueryparam value="#form.assigned_date#" cfsqltype="cf_sql_date">,
                expected_return_date  = <cfqueryparam value="#form.expected_return_date#" cfsqltype="cf_sql_date" null="#expectedReturnNull#">,
                assignment_status     = <cfqueryparam value="#statusVal#" cfsqltype="cf_sql_varchar">,
                notes                 = <cfqueryparam value="#notes#" cfsqltype="cf_sql_longvarchar" null="#not len(notes)#">,
                assigned_by           = <cfqueryparam value="#assignedBy#" cfsqltype="cf_sql_varchar" null="#not len(assignedBy)#">
            WHERE assignment_id = <cfqueryparam value="#assignmentId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfoutput>{"success":true,"assignment_id":#assignmentId#,"action":"update"}</cfoutput>
    </cfif>

<cfcatch type="any">
    <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
</cfcatch>
</cftry>
