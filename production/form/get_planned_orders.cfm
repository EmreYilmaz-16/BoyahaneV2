<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "", "data": [] }>

<cftry>
    <cfparam name="url.start_date" default="">
    <cfparam name="url.end_date" default="">

    <cfset rawStart = (len(trim(url.start_date)) AND isDate(url.start_date))
        ? parseDateTime(Replace(trim(url.start_date), "T", " ", "all"))
        : dateAdd("d", -1, now())>
    <cfset rawEnd = (len(trim(url.end_date)) AND isDate(url.end_date))
        ? parseDateTime(Replace(trim(url.end_date), "T", " ", "all"))
        : dateAdd("d", 4, rawStart)>

    <cfif rawEnd lte rawStart>
        <cfset rawEnd = dateAdd("d", 4, rawStart)>
    </cfif>

    <!--- UI'ı yanlışlıkla çok geniş sorguyla yormamak için aralığı sınırla. --->
    <cfif dateDiff("d", rawStart, rawEnd) gt 45>
        <cfset rawEnd = dateAdd("d", 45, rawStart)>
    </cfif>

    <cfquery name="qPlanned" datasource="boyahane">
        SELECT po.p_order_id,
               po.p_order_no,
               COALESCE(po.quantity, 0)             AS quantity,
               COALESCE(po.lot_no,'')               AS lot_no,
               COALESCE(ci.color_code,'')           AS color_code,
               COALESCE(ci.color_name,'')           AS color_name,
               COALESCE(c.nickname, c.fullname,'') AS company_name,
               COALESCE(s.stock_code,'')            AS stock_code,
               COALESCE(p.product_id, 0)           AS product_id,
               COALESCE(p.product_catid, 0)        AS product_catid,
               po.start_date,
               po.finish_date,
               po.station_id,
               COALESCE(ws.station_name,'')         AS station_name,
               COALESCE(po.status, 1)               AS status,
               COALESCE(po.is_urgent, false)        AS is_urgent,
               COALESCE(po.plan_water_amount, 0)  AS plan_water_amount,
               COALESCE((
                   SELECT SUM(COALESCE(po2.o_minute, 0))
                   FROM production_operation po2
                   WHERE po2.p_order_id = po.p_order_id
               ), 0) AS total_op_minutes,
               COALESCE((
                   SELECT COUNT(*)
                   FROM setup_prod_pause sp
                   WHERE sp.p_order_id = po.p_order_id
                     AND sp.duration_finish_date IS NULL
               ), 0) AS active_pause_count,
               COALESCE((
                   SELECT SUM(COALESCE(sp.prod_duration, 0))
                   FROM setup_prod_pause sp
                   WHERE sp.p_order_id = po.p_order_id
               ), 0) AS total_pause_minutes
        FROM production_orders po
        LEFT JOIN stocks       s  ON po.stock_id   = s.stock_id
        LEFT JOIN product      p  ON s.product_id  = p.product_id
        LEFT JOIN color_info   ci ON po.stock_id   = ci.stock_id
        LEFT JOIN company      c  ON ci.company_id = c.company_id
        LEFT JOIN workstations ws ON po.station_id = ws.station_id
        WHERE po.station_id IS NOT NULL
          AND po.start_date IS NOT NULL
          AND po.finish_date IS NOT NULL
          AND po.status IN (1, 2, 5)
          AND po.start_date  < <cfqueryparam value="#createODBCDateTime(rawEnd)#" cfsqltype="cf_sql_timestamp">
          AND po.finish_date > <cfqueryparam value="#createODBCDateTime(rawStart)#" cfsqltype="cf_sql_timestamp">
        ORDER BY po.start_date ASC, po.p_order_id ASC
    </cfquery>

    <cfloop query="qPlanned">
        <cfset sDate = isDate(start_date) ? start_date : now()>
        <cfset opMins = isNumeric(total_op_minutes) ? val(total_op_minutes) : 0>
        <cfif isDate(finish_date)>
            <cfset fDate = finish_date>
        <cfelseif opMins gt 0>
            <cfset fDate = dateAdd("n", opMins, sDate)>
        <cfelse>
            <cfset fDate = dateAdd("h", 8, sDate)>
        </cfif>

        <cfset arrayAppend(response.data, {
            "p_order_id"         : val(p_order_id),
            "p_order_no"         : p_order_no   ?: "",
            "quantity"           : isNumeric(quantity) ? val(quantity) : 0,
            "lot_no"             : lot_no       ?: "",
            "color_code"         : color_code   ?: "",
            "color_name"         : color_name   ?: "",
            "company_name"       : company_name ?: "",
            "stock_code"         : stock_code   ?: "",
            "product_id"         : isNumeric(product_id) ? val(product_id) : 0,
            "product_catid"      : isNumeric(product_catid) ? val(product_catid) : 0,
            "station_id"         : val(station_id),
            "station_name"       : station_name ?: "",
            "status"             : val(status),
            "is_urgent"          : is_urgent,
            "plan_water_amount"   : isNumeric(plan_water_amount) ? val(plan_water_amount) : 0,
            "total_op_minutes"   : opMins,
            "active_pause_count" : isNumeric(active_pause_count) ? val(active_pause_count) : 0,
            "total_pause_minutes": isNumeric(total_pause_minutes) ? val(total_pause_minutes) : 0,
            "startDate"          : dateFormat(sDate,"yyyy-mm-dd") & "T" & timeFormat(sDate, "HH:mm:ss"),
            "endDate"            : dateFormat(fDate,"yyyy-mm-dd") & "T" & timeFormat(fDate, "HH:mm:ss"),
            "text"               : (p_order_no ?: "Emir") & " | " & (color_code ?: "") & " " & (color_name ?: ""),
            "resourceId"         : val(station_id)
        })>
    </cfloop>

    <cfset response.success = true>

<cfcatch type="any">
    <cfset response.message = "Sunucu hatası: " & htmlEditFormat(cfcatch.message)>
</cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
