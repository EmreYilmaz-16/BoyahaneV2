<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
    <cfset assetId = isDefined("form.asset_id") and isNumeric(form.asset_id) ? val(form.asset_id) : 0>
    <cfset plateNo = isDefined("form.plate_no") ? trim(form.plate_no) : "">

    <cfif assetId lte 0>
        <cfoutput>{"success":false,"message":"Araç seçilmelidir."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif not len(plateNo)>
        <cfoutput>{"success":false,"message":"Plaka No zorunludur."}</cfoutput>
        <cfabort>
    </cfif>

    <cfset chassisNo   = isDefined("form.chassis_no")     ? left(trim(form.chassis_no),100)     : "">
    <cfset engineNo    = isDefined("form.engine_no")      ? left(trim(form.engine_no),100)       : "">
    <cfset modelYear   = isDefined("form.model_year")     and isNumeric(form.model_year)  ? val(form.model_year)  : 0>
    <cfset fuelType    = isDefined("form.fuel_type")      ? left(trim(form.fuel_type),20)        : "">
    <cfset currentKm   = isDefined("form.current_km")     and isNumeric(form.current_km)  ? val(form.current_km)  : 0>

    <cfset trafficEnd  = isDefined("form.traffic_ins_end")  and isDate(form.traffic_ins_end)  ? form.traffic_ins_end  : "">
    <cfset cascoEnd    = isDefined("form.casco_end")         and isDate(form.casco_end)         ? form.casco_end        : "">
    <cfset mtvDue      = isDefined("form.mtv_due")           and isDate(form.mtv_due)           ? form.mtv_due          : "">
    <cfset inspDue     = isDefined("form.inspection_due")    and isDate(form.inspection_due)    ? form.inspection_due   : "">
    <cfset emissionDue = isDefined("form.emission_due")      and isDate(form.emission_due)      ? form.emission_due     : "">
    <cfset leaseStart  = isDefined("form.lease_start")       and isDate(form.lease_start)       ? form.lease_start      : "">
    <cfset leaseEnd    = isDefined("form.lease_end")         and isDate(form.lease_end)         ? form.lease_end        : "">

    <cfquery name="ups" datasource="boyahane">
        INSERT INTO vehicle_details (
            asset_id,
            plate_no,
            chassis_no,
            engine_no,
            model_year,
            fuel_type,
            current_km,
            traffic_insurance_end,
            casco_end,
            mtv_due_date,
            inspection_due_date,
            emission_due_date,
            lease_start_date,
            lease_end_date
        ) VALUES (
            <cfqueryparam value="#assetId#"                        cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#left(plateNo,20)#"               cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#chassisNo#"                       cfsqltype="cf_sql_varchar"  null="#not len(chassisNo)#">,
            <cfqueryparam value="#engineNo#"                        cfsqltype="cf_sql_varchar"  null="#not len(engineNo)#">,
            <cfqueryparam value="#modelYear#"                       cfsqltype="cf_sql_integer"  null="#modelYear lte 0#">,
            <cfqueryparam value="#fuelType#"                        cfsqltype="cf_sql_varchar"  null="#not len(fuelType)#">,
            <cfqueryparam value="#currentKm#"                       cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#trafficEnd#"                      cfsqltype="cf_sql_date"     null="#not len(trafficEnd)#">,
            <cfqueryparam value="#cascoEnd#"                        cfsqltype="cf_sql_date"     null="#not len(cascoEnd)#">,
            <cfqueryparam value="#mtvDue#"                          cfsqltype="cf_sql_date"     null="#not len(mtvDue)#">,
            <cfqueryparam value="#inspDue#"                         cfsqltype="cf_sql_date"     null="#not len(inspDue)#">,
            <cfqueryparam value="#emissionDue#"                     cfsqltype="cf_sql_date"     null="#not len(emissionDue)#">,
            <cfqueryparam value="#leaseStart#"                      cfsqltype="cf_sql_date"     null="#not len(leaseStart)#">,
            <cfqueryparam value="#leaseEnd#"                        cfsqltype="cf_sql_date"     null="#not len(leaseEnd)#">
        )
        ON CONFLICT (asset_id) DO UPDATE SET
            plate_no              = EXCLUDED.plate_no,
            chassis_no            = EXCLUDED.chassis_no,
            engine_no             = EXCLUDED.engine_no,
            model_year            = EXCLUDED.model_year,
            fuel_type             = EXCLUDED.fuel_type,
            current_km            = EXCLUDED.current_km,
            traffic_insurance_end = EXCLUDED.traffic_insurance_end,
            casco_end             = EXCLUDED.casco_end,
            mtv_due_date          = EXCLUDED.mtv_due_date,
            inspection_due_date   = EXCLUDED.inspection_due_date,
            emission_due_date     = EXCLUDED.emission_due_date,
            lease_start_date      = EXCLUDED.lease_start_date,
            lease_end_date        = EXCLUDED.lease_end_date
    </cfquery>

    <cfoutput>{"success":true}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
