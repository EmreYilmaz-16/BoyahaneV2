<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "params": [] }>
<cftry>
    <cfparam name="url.qc_plan_id" default="0">
    <cfset planId = isNumeric(url.qc_plan_id) ? val(url.qc_plan_id) : 0>

    <cfif planId EQ 0>
        <cfset response.message = "Geçersiz plan ID">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="qPlanItems" datasource="boyahane">
        SELECT
            pi.qc_plan_item_id,
            pi.qc_param_id,
            pi.is_required,
            pi.sort_order,
            COALESCE(pi.min_override, p.min_value) AS min_value,
            COALESCE(pi.max_override, p.max_value) AS max_value,
            p.param_code,
            p.param_name,
            p.param_type,
            COALESCE(p.unit_name, '') AS unit_name
        FROM qc_plan_items pi
        JOIN qc_parameters p ON pi.qc_param_id = p.qc_param_id
        WHERE pi.qc_plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
          AND p.is_active = true
        ORDER BY pi.sort_order, p.param_name
    </cfquery>

    <cfset paramsArr = []>
    <cfloop query="qPlanItems">
        <cfset arrayAppend(paramsArr, {
            "qc_param_id"     : val(qc_param_id),
            "param_code"      : param_code  ?: "",
            "param_name"      : param_name  ?: "",
            "param_type"      : val(param_type),
            "unit_name"       : unit_name   ?: "",
            "min_value"       : isNumeric(min_value) ? val(min_value) : "",
            "max_value"       : isNumeric(max_value) ? val(max_value) : "",
            "is_required"     : isBoolean(is_required) ? is_required : true
        })>
    </cfloop>

    <cfset response.success = true>
    <cfset response.params  = paramsArr>

    <cfcatch type="any">
        <cfset response.message = cfcatch.message>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
<cfabort>