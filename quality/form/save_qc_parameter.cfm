<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.qc_param_id" default="0">
    <cfparam name="form.param_code"  default="">
    <cfparam name="form.param_name"  default="">
    <cfparam name="form.param_type"  default="1">
    <cfparam name="form.unit_name"   default="">
    <cfparam name="form.min_value"   default="">
    <cfparam name="form.max_value"   default="">
    <cfparam name="form.is_active"   default="true">
    <cfparam name="form.sort_order"  default="0">
    <cfparam name="form.detail"      default="">

    <cfset paramId   = isNumeric(form.qc_param_id) ? val(form.qc_param_id) : 0>
    <cfset paramCode = trim(form.param_code)>
    <cfset paramName = trim(form.param_name)>

    <cfif NOT len(paramCode) OR NOT len(paramName)>
        <cfset response.message = "Parametre kodu ve adı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset paramType  = isNumeric(form.param_type) ? val(form.param_type) : 1>
    <cfset unitName   = trim(form.unit_name)>
    <cfset minVal     = (len(trim(form.min_value)) AND isNumeric(form.min_value)) ? val(form.min_value) : javaCast("null","")>
    <cfset maxVal     = (len(trim(form.max_value)) AND isNumeric(form.max_value)) ? val(form.max_value) : javaCast("null","")>
    <cfset isActive   = (lcase(trim(form.is_active)) eq "true")>
    <cfset sortOrder  = isNumeric(form.sort_order) ? val(form.sort_order) : 0>
    <cfset detail     = trim(form.detail)>

    <cfif paramId gt 0>
        <!--- Güncelle --->
        <cfquery datasource="boyahane">
            UPDATE qc_parameters SET
                param_code  = <cfqueryparam value="#paramCode#"  cfsqltype="cf_sql_varchar">,
                param_name  = <cfqueryparam value="#paramName#"  cfsqltype="cf_sql_varchar">,
                param_type  = <cfqueryparam value="#paramType#"  cfsqltype="cf_sql_smallint">,
                unit_name   = <cfqueryparam value="#unitName#"   cfsqltype="cf_sql_varchar"  null="#NOT len(unitName)#">,
                min_value   = <cfqueryparam value="#isNull(minVal)?'':minVal#" cfsqltype="cf_sql_numeric" null="#isNull(minVal)#">,
                max_value   = <cfqueryparam value="#isNull(maxVal)?'':maxVal#" cfsqltype="cf_sql_numeric" null="#isNull(maxVal)#">,
                is_active   = <cfqueryparam value="#isActive#"   cfsqltype="cf_sql_boolean">,
                sort_order  = <cfqueryparam value="#sortOrder#"  cfsqltype="cf_sql_integer">,
                detail      = <cfqueryparam value="#detail#"     cfsqltype="cf_sql_varchar"  null="#NOT len(detail)#">,
                record_ip   = <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
            WHERE qc_param_id = <cfqueryparam value="#paramId#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <!--- Yeni kayıt --->
        <cfquery datasource="boyahane">
            INSERT INTO qc_parameters (
                param_code, param_name, param_type, unit_name,
                min_value, max_value, is_active, sort_order, detail,
                record_date, record_ip
            ) VALUES (
                <cfqueryparam value="#paramCode#"  cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#paramName#"  cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#paramType#"  cfsqltype="cf_sql_smallint">,
                <cfqueryparam value="#unitName#"   cfsqltype="cf_sql_varchar"  null="#NOT len(unitName)#">,
                <cfqueryparam value="#isNull(minVal)?'':minVal#" cfsqltype="cf_sql_numeric" null="#isNull(minVal)#">,
                <cfqueryparam value="#isNull(maxVal)?'':maxVal#" cfsqltype="cf_sql_numeric" null="#isNull(maxVal)#">,
                <cfqueryparam value="#isActive#"   cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#sortOrder#"  cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#detail#"     cfsqltype="cf_sql_varchar"  null="#NOT len(detail)#">,
                CURRENT_TIMESTAMP,
                <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
    </cfif>

    <cfset response.success = true>
    <cfcatch type="any">
        <cfset response.message = cfcatch.message>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
