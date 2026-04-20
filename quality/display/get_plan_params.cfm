<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfparam name="url.qc_plan_id" default="0">
<cfset planId = isNumeric(url.qc_plan_id) AND val(url.qc_plan_id) gt 0 ? val(url.qc_plan_id) : 0>

<cftry>
    <cfquery name="getParams" datasource="boyahane">
        SELECT qp.qc_param_id,
               qp.param_code,
               qp.param_name,
               qp.param_type,
               qp.unit_name,
               COALESCE(pi.min_value, qp.min_value) AS min_value,
               COALESCE(pi.max_value, qp.max_value) AS max_value
        FROM qc_plan_items pi
        JOIN qc_parameters qp ON pi.qc_param_id = qp.qc_param_id
        WHERE pi.qc_plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
          AND qp.is_active = true
        ORDER BY qp.sort_order, qp.param_name
    </cfquery>

    <cfset params = []>
    <cfloop query="getParams">
        <cfset row = {}>
        <cfset row["qc_param_id"]  = val(qc_param_id)>
        <cfset row["param_code"]   = htmlEditFormat(param_code)>
        <cfset row["param_name"]   = htmlEditFormat(param_name)>
        <cfset row["param_type"]   = val(param_type)>
        <cfset row["unit_name"]    = htmlEditFormat(unit_name)>
        <cfset row["min_value"]    = isNumeric(min_value) ? val(min_value) : javaCast("null", "")>
        <cfset row["max_value"]    = isNumeric(max_value) ? val(max_value) : javaCast("null", "")>
        <cfset arrayAppend(params, row)>
    </cfloop>

    <cfoutput>#serializeJSON({"success": true, "params": params})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success": false, "params": [], "message": cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
