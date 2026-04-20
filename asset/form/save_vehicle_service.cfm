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
        INSERT INTO vehicle_service_logs (
            asset_id, service_type, service_date, odometer_km, supplier_company_id,
            labor_cost, material_cost, next_service_date, note, record_date
        ) VALUES (
            <cfqueryparam value="#assetId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#left(trim(form.service_type ?: 'OTHER'),40)#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.service_date#" cfsqltype="cf_sql_date" null="#not (isDefined('form.service_date') and isDate(form.service_date))#">,
            <cfqueryparam value="#isNumeric(form.odometer_km ?: '') ? val(form.odometer_km) : 0#" cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#isNumeric(form.supplier_company_id ?: '') ? val(form.supplier_company_id) : 0#" cfsqltype="cf_sql_integer" null="#not isNumeric(form.supplier_company_id ?: '')#">,
            <cfqueryparam value="#isNumeric(form.labor_cost ?: '') ? val(form.labor_cost) : 0#" cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#isNumeric(form.material_cost ?: '') ? val(form.material_cost) : 0#" cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#form.next_service_date#" cfsqltype="cf_sql_date" null="#not (isDefined('form.next_service_date') and isDate(form.next_service_date))#">,
            <cfqueryparam value="#trim(form.note ?: '')#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.note ?: ''))#">,
            <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
        ) RETURNING service_id
    </cfquery>

    <cfoutput>{"success":true,"service_id":#ins.service_id#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
