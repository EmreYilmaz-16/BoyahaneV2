<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>
<cftry>
    <cfparam name="form.defect_type_id" default="0">
    <cfparam name="form.defect_code"    default="">
    <cfparam name="form.defect_name"    default="">
    <cfparam name="form.severity"       default="2">
    <cfparam name="form.is_active"      default="true">
    <cfparam name="form.sort_order"     default="0">
    <cfparam name="form.detail"         default="">

    <cfset defId   = isNumeric(form.defect_type_id) ? val(form.defect_type_id) : 0>
    <cfset dCode   = trim(form.defect_code)>
    <cfset dName   = trim(form.defect_name)>

    <cfif NOT len(dCode) OR NOT len(dName)>
        <cfset response.message = "Hata kodu ve adı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset sev      = isNumeric(form.severity)   ? val(form.severity)   : 2>
    <cfset isActive = (lcase(trim(form.is_active)) eq "true")>
    <cfset sortOrd  = isNumeric(form.sort_order) ? val(form.sort_order) : 0>
    <cfset detail   = trim(form.detail)>

    <cfif defId gt 0>
        <cfquery datasource="boyahane">
            UPDATE qc_defect_types SET
                defect_code = <cfqueryparam value="#dCode#"   cfsqltype="cf_sql_varchar">,
                defect_name = <cfqueryparam value="#dName#"   cfsqltype="cf_sql_varchar">,
                severity    = <cfqueryparam value="#sev#"     cfsqltype="cf_sql_smallint">,
                is_active   = <cfqueryparam value="#isActive#" cfsqltype="cf_sql_boolean">,
                sort_order  = <cfqueryparam value="#sortOrd#" cfsqltype="cf_sql_integer">,
                detail      = <cfqueryparam value="#detail#"  cfsqltype="cf_sql_varchar" null="#NOT len(detail)#">,
                record_ip   = <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
            WHERE defect_type_id = <cfqueryparam value="#defId#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <cfquery datasource="boyahane">
            INSERT INTO qc_defect_types (defect_code,defect_name,severity,is_active,sort_order,detail,record_date,record_ip)
            VALUES (
                <cfqueryparam value="#dCode#"   cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#dName#"   cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#sev#"     cfsqltype="cf_sql_smallint">,
                <cfqueryparam value="#isActive#" cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#sortOrd#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#detail#"  cfsqltype="cf_sql_varchar" null="#NOT len(detail)#">,
                CURRENT_TIMESTAMP,
                <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
    </cfif>
    <cfset response.success = true>
    <cfcatch type="any"><cfset response.message = cfcatch.message></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
