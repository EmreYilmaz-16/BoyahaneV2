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
        INSERT INTO vehicle_fuel_logs (
            asset_id, fuel_date, odometer_km, liters, amount, station_name, invoice_no, note, record_date
        ) VALUES (
            <cfqueryparam value="#assetId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#form.fuel_date#" cfsqltype="cf_sql_date" null="#not (isDefined('form.fuel_date') and isDate(form.fuel_date))#">,
            <cfqueryparam value="#isNumeric(form.odometer_km ?: '') ? val(form.odometer_km) : 0#" cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#isNumeric(form.liters ?: '') ? val(form.liters) : 0#" cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#isNumeric(form.amount ?: '') ? val(form.amount) : 0#" cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#left(trim(form.station_name ?: ''),150)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.station_name ?: ''))#">,
            <cfqueryparam value="#left(trim(form.invoice_no ?: ''),50)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.invoice_no ?: ''))#">,
            <cfqueryparam value="#trim(form.note ?: '')#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.note ?: ''))#">,
            <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
        ) RETURNING fuel_log_id
    </cfquery>

    <cfoutput>{"success":true,"fuel_log_id":#ins.fuel_log_id#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
