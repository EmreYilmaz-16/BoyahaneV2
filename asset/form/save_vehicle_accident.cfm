<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
    <cfset assetId = isDefined("form.asset_id") and isNumeric(form.asset_id) ? val(form.asset_id) : 0>

    <cfif assetId lte 0>
        <cfoutput>{"success":false,"message":"Araç varlığı seçilmelidir."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="ins" datasource="boyahane">
        INSERT INTO vehicle_accidents (
            asset_id, accident_date, driver_employee_id, damage_description,
            estimated_cost, actual_cost, insurance_claim_no, process_status, record_date
        ) VALUES (
            <cfqueryparam value="#assetId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#form.accident_date#" cfsqltype="cf_sql_date" null="#not (isDefined('form.accident_date') and isDate(form.accident_date))#">,
            <cfqueryparam value="#isNumeric(form.driver_employee_id ?: '') ? val(form.driver_employee_id) : 0#" cfsqltype="cf_sql_integer" null="#not isNumeric(form.driver_employee_id ?: '')#">,
            <cfqueryparam value="#trim(form.damage_description ?: '')#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.damage_description ?: ''))#">,
            <cfqueryparam value="#isNumeric(form.estimated_cost ?: '') ? val(form.estimated_cost) : 0#" cfsqltype="cf_sql_numeric" null="#not isNumeric(form.estimated_cost ?: '')#">,
            <cfqueryparam value="#isNumeric(form.actual_cost ?: '') ? val(form.actual_cost) : 0#" cfsqltype="cf_sql_numeric" null="#not isNumeric(form.actual_cost ?: '')#">,
            <cfqueryparam value="#left(trim(form.insurance_claim_no ?: ''),100)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.insurance_claim_no ?: ''))#">,
            <cfqueryparam value="#left(trim(form.process_status ?: 'OPEN'),20)#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
        ) RETURNING accident_id
    </cfquery>

    <cfoutput>{"success":true,"accident_id":#ins.accident_id#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
