<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
    <cfset assetId = isDefined("form.asset_id") and isNumeric(form.asset_id) ? val(form.asset_id) : 0>
    <cfset maintenanceType = isDefined("form.maintenance_type") ? uCase(trim(form.maintenance_type)) : "PLANNED">

    <cfif assetId lte 0>
        <cfoutput>{"success":false,"message":"Asset seçimi zorunludur."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="ins" datasource="boyahane">
        INSERT INTO asset_maintenance (
            asset_id, maintenance_type, work_order_no, planned_date, start_date, end_date,
            labor_cost, spare_part_cost, maintenance_status, note, record_emp, record_date
        ) VALUES (
            <cfqueryparam value="#assetId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#left(maintenanceType,20)#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#left(trim(form.work_order_no ?: ''),50)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.work_order_no ?: ''))#">,
            <cfqueryparam value="#form.planned_date#" cfsqltype="cf_sql_date" null="#not (isDefined('form.planned_date') and isDate(form.planned_date))#">,
            <cfqueryparam value="#form.start_date#" cfsqltype="cf_sql_timestamp" null="#not (isDefined('form.start_date') and isDate(form.start_date))#">,
            <cfqueryparam value="#form.end_date#" cfsqltype="cf_sql_timestamp" null="#not (isDefined('form.end_date') and isDate(form.end_date))#">,
            <cfqueryparam value="#isNumeric(form.labor_cost ?: '') ? val(form.labor_cost) : 0#" cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#isNumeric(form.spare_part_cost ?: '') ? val(form.spare_part_cost) : 0#" cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#left(trim(form.maintenance_status ?: 'OPEN'),20)#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#trim(form.note ?: '')#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.note ?: ''))#">,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
        ) RETURNING maintenance_id
    </cfquery>

    <cfoutput>{"success":true,"maintenance_id":#ins.maintenance_id#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
