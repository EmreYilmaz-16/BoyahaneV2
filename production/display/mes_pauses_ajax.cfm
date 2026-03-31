<cfprocessingdirective pageEncoding="utf-8">
<cfheader name="Content-Type" value="application/json; charset=utf-8">
<cfparam name="url.p_order_id" default="0">
<cfset pOrderId = isNumeric(url.p_order_id) AND val(url.p_order_id) gt 0 ? val(url.p_order_id) : 0>

<cfif pOrderId eq 0>
    <cfoutput>{"success":false,"message":"Geçersiz p_order_id"}</cfoutput>
    <cfabort>
</cfif>

<cfquery name="qPauses" datasource="boyahane">
    SELECT sp.prod_pause_id,
           sp.action_date,
           COALESCE(sp.prod_duration, 0)    AS prod_duration,
           COALESCE(sp.prod_detail, '')      AS prod_detail,
           COALESCE(spt.prod_pause_type, '') AS pause_type,
           sp.is_working_time,
           sp.duration_start_date,
           sp.duration_finish_date
    FROM setup_prod_pause sp
    LEFT JOIN setup_prod_pause_type spt ON sp.prod_pause_type_id = spt.prod_pause_type_id
    WHERE sp.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    ORDER BY sp.prod_pause_id DESC
</cfquery>

<cfset totalPauseMin = 0>
<cfloop query="qPauses">
    <cfset totalPauseMin += val(prod_duration)>
</cfloop>

<cfset rows = []>
<cfloop query="qPauses">
    <cfset row = {}>
    <cfset row["action_date"]          = isDate(action_date) ? dateFormat(action_date,"dd/mm/yyyy") & " " & timeFormat(action_date,"HH:mm") : "">
    <cfset row["pause_type"]           = len(pause_type) ? pause_type : "">
    <cfset row["prod_duration"]        = val(prod_duration)>
    <cfset row["duration_start_date"]  = isDate(duration_start_date) ? timeFormat(duration_start_date,"HH:mm") : "">
    <cfset row["duration_finish_date"] = isDate(duration_finish_date) ? timeFormat(duration_finish_date,"HH:mm") : "">
    <cfset row["prod_detail"]          = len(prod_detail) ? prod_detail : "">
    <cfset row["is_working_time"]      = is_working_time ? true : false>
    <cfset arrayAppend(rows, row)>
</cfloop>

<cfoutput>#serializeJSON({
    "success"       : true,
    "recordCount"   : qPauses.recordCount,
    "totalPauseMin" : totalPauseMin,
    "rows"          : rows
})#</cfoutput>
