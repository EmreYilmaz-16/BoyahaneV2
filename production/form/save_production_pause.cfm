<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Üretim duruşu kaydet (INSERT)
    form.p_order_id    : Üretim emri ID
    form.pause_type_id : Duruş tipi ID
    form.prod_duration : Süre (dakika)
    form.prod_detail   : Açıklama
    form.action_date   : Duruş tarihi (opsiyonel, default now())
    form.station_id    : İstasyon ID (opsiyonel)
    form.employee_id   : Çalışan ID (opsiyonel)
--->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.p_order_id"    default="0">
    <cfparam name="form.pause_type_id" default="0">
    <cfparam name="form.prod_duration" default="0">
    <cfparam name="form.prod_detail"   default="">
    <cfparam name="form.action_date"   default="">
    <cfparam name="form.station_id"    default="0">
    <cfparam name="form.employee_id"   default="0">
    <cfparam name="form.is_working_time" default="0">
    <cfparam name="form.duration_start_date"  default="">
    <cfparam name="form.duration_finish_date" default="">

    <cfset pOrderId    = isNumeric(form.p_order_id) AND val(form.p_order_id) gt 0 ? val(form.p_order_id) : 0>
    <cfset pauseTypeId = isNumeric(form.pause_type_id) AND val(form.pause_type_id) gt 0 ? val(form.pause_type_id) : javaCast("null","")>
    <cfset duration    = isNumeric(form.prod_duration) ? val(form.prod_duration) : 0>
    <cfset detailVal   = trim(form.prod_detail)>
    <cfset stationId   = isNumeric(form.station_id) AND val(form.station_id) gt 0 ? val(form.station_id) : javaCast("null","")>
    <cfset employeeId  = isNumeric(form.employee_id) AND val(form.employee_id) gt 0 ? val(form.employee_id) : javaCast("null","")>
    <cfset isWrk       = (form.is_working_time eq "1" OR form.is_working_time eq "true")>

    <cfset actionDate = (len(trim(form.action_date)) AND isDate(form.action_date))
        ? createODBCDateTime(parseDateTime(Replace(form.action_date,'T',' ','all')))
        : createODBCDateTime(now())>

    <cfset startDate  = (len(trim(form.duration_start_date)) AND isDate(form.duration_start_date))
        ? createODBCDateTime(parseDateTime(Replace(form.duration_start_date,'T',' ','all')))
        : javaCast("null","")>
    <cfset finishDate = (len(trim(form.duration_finish_date)) AND isDate(form.duration_finish_date))
        ? createODBCDateTime(parseDateTime(Replace(form.duration_finish_date,'T',' ','all')))
        : javaCast("null","")>

    <cfif pOrderId eq 0>
        <cfset response.message = "Geçersiz üretim emri ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Süre hesapla eğer start/finish verilmişse ve duration yoksa --->
    <cfif duration eq 0 AND NOT isNull(startDate) AND NOT isNull(finishDate)>
        <cfset diffMs   = (finishDate.getTime() - startDate.getTime())>
        <cfset duration = int(diffMs / 60000)>
    </cfif>

    <cfquery name="ins" datasource="boyahane">
        INSERT INTO setup_prod_pause (
            p_order_id, prod_pause_type_id, prod_duration, prod_detail,
            is_working_time, action_date, station_id, employee_id,
            duration_start_date, duration_finish_date,
            record_date, record_ip
        ) VALUES (
            <cfqueryparam value="#pOrderId#"   cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#isNull(pauseTypeId) ? '' : pauseTypeId#" cfsqltype="cf_sql_integer" null="#isNull(pauseTypeId)#">,
            <cfqueryparam value="#duration#"   cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#detailVal#"  cfsqltype="cf_sql_varchar" null="#NOT len(detailVal)#">,
            <cfqueryparam value="#isWrk#"      cfsqltype="cf_sql_bit">,
            <cfqueryparam value="#actionDate#" cfsqltype="cf_sql_timestamp">,
            <cfqueryparam value="#isNull(stationId) ? '' : stationId#"  cfsqltype="cf_sql_integer" null="#isNull(stationId)#">,
            <cfqueryparam value="#isNull(employeeId) ? '' : employeeId#" cfsqltype="cf_sql_integer" null="#isNull(employeeId)#">,
            <cfqueryparam value="#isNull(startDate) ? '' : startDate#"  cfsqltype="cf_sql_timestamp" null="#isNull(startDate)#">,
            <cfqueryparam value="#isNull(finishDate) ? '' : finishDate#" cfsqltype="cf_sql_timestamp" null="#isNull(finishDate)#">,
            CURRENT_TIMESTAMP,
            <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
        )
        RETURNING prod_pause_id
    </cfquery>

    <cfset response = { "success": true, "prod_pause_id": val(ins.prod_pause_id) }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>