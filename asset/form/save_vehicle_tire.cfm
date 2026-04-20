<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
    <cfset assetId   = isDefined("form.asset_id")   and isNumeric(form.asset_id)  ? val(form.asset_id)  : 0>
    <cfset logDate   = isDefined("form.log_date")    and isDate(form.log_date)     ? form.log_date       : "">
    <cfset logType   = isDefined("form.log_type")    ? uCase(trim(form.log_type)) : "OTHER">

    <cfif assetId lte 0>
        <cfoutput>{"success":false,"message":"Araç seçilmelidir."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif not len(logDate)>
        <cfoutput>{"success":false,"message":"Tarih zorunludur."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Validate log_type against allowed values --->
    <cfif not listFindNoCase("CHANGE,BALANCE,ROTATION,OTHER", logType)>
        <cfset logType = "OTHER">
    </cfif>

    <cfset odomKm      = isDefined("form.odometer_km")   and isNumeric(form.odometer_km)  ? val(form.odometer_km)  : 0>
    <cfset tirePos     = isDefined("form.tire_position")  ? left(trim(form.tire_position),50)   : "">
    <cfset tireBrand   = isDefined("form.tire_brand")     ? left(trim(form.tire_brand),100)      : "">
    <cfset tireSize    = isDefined("form.tire_size")      ? left(trim(form.tire_size),50)        : "">
    <cfset cost        = isDefined("form.cost")           and isNumeric(form.cost)          ? val(form.cost)         : 0>
    <cfset note        = isDefined("form.note")           ? trim(form.note)                 : "">

    <cfquery name="ins" datasource="boyahane">
        INSERT INTO vehicle_tire_logs (
            asset_id,
            log_date,
            log_type,
            odometer_km,
            tire_position,
            tire_brand,
            tire_size,
            cost,
            note,
            record_date
        ) VALUES (
            <cfqueryparam value="#assetId#"    cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#logDate#"    cfsqltype="cf_sql_date">,
            <cfqueryparam value="#logType#"    cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#odomKm#"     cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#tirePos#"    cfsqltype="cf_sql_varchar" null="#not len(tirePos)#">,
            <cfqueryparam value="#tireBrand#"  cfsqltype="cf_sql_varchar" null="#not len(tireBrand)#">,
            <cfqueryparam value="#tireSize#"   cfsqltype="cf_sql_varchar" null="#not len(tireSize)#">,
            <cfqueryparam value="#cost#"       cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#note#"       cfsqltype="cf_sql_varchar" null="#not len(note)#">,
            <cfqueryparam value="#now()#"      cfsqltype="cf_sql_timestamp">
        ) RETURNING tire_log_id
    </cfquery>

    <cfoutput>{"success":true,"tire_log_id":#ins.tire_log_id#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
