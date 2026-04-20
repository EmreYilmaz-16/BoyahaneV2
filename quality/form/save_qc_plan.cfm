<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>
<cftry>
    <cfparam name="form.qc_plan_id"    default="0">
    <cfparam name="form.plan_code"     default="">
    <cfparam name="form.plan_name"     default="">
    <cfparam name="form.control_type"  default="1">
    <cfparam name="form.product_id"    default="">
    <cfparam name="form.sample_method" default="1">
    <cfparam name="form.sample_value"  default="">
    <cfparam name="form.is_active"     default="true">
    <cfparam name="form.detail"        default="">
    <cfparam name="form.plan_items"    default="[]">

    <cfset planId    = isNumeric(form.qc_plan_id) ? val(form.qc_plan_id) : 0>
    <cfset planCode  = trim(form.plan_code)>
    <cfset planName  = trim(form.plan_name)>

    <cfif NOT len(planCode) OR NOT len(planName)>
        <cfset response.message = "Plan kodu ve adı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset ctType    = isNumeric(form.control_type)  ? val(form.control_type)  : 1>
    <cfset productId = (len(trim(form.product_id)) AND isNumeric(form.product_id) AND val(form.product_id) gt 0)
                       ? val(form.product_id) : javaCast("null","")>
    <cfset sampMeth  = isNumeric(form.sample_method) ? val(form.sample_method) : 1>
    <cfset sampVal   = (len(trim(form.sample_value)) AND isNumeric(form.sample_value))
                       ? val(form.sample_value) : javaCast("null","")>
    <cfset isActive  = (lcase(trim(form.is_active)) eq "true")>
    <cfset detail    = trim(form.detail)>

    <cfset itemsArr = []>
    <cftry>
        <cfset itemsArr = deserializeJSON(form.plan_items)>
        <cfcatch><cfset itemsArr = []></cfcatch>
    </cftry>

    <cfif planId gt 0>
        <!--- Güncelle başlık --->
        <cfquery datasource="boyahane">
            UPDATE qc_plans SET
                plan_code     = <cfqueryparam value="#planCode#"   cfsqltype="cf_sql_varchar">,
                plan_name     = <cfqueryparam value="#planName#"   cfsqltype="cf_sql_varchar">,
                control_type  = <cfqueryparam value="#ctType#"     cfsqltype="cf_sql_smallint">,
                product_id    = <cfqueryparam value="#isNull(productId)?'':productId#" cfsqltype="cf_sql_integer" null="#isNull(productId)#">,
                sample_method = <cfqueryparam value="#sampMeth#"   cfsqltype="cf_sql_smallint">,
                sample_value  = <cfqueryparam value="#isNull(sampVal)?'':sampVal#" cfsqltype="cf_sql_numeric" null="#isNull(sampVal)#">,
                is_active     = <cfqueryparam value="#isActive#"   cfsqltype="cf_sql_boolean">,
                detail        = <cfqueryparam value="#detail#"     cfsqltype="cf_sql_varchar" null="#NOT len(detail)#">,
                record_ip     = <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
            WHERE qc_plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <!--- Eski kalemleri sil --->
        <cfquery datasource="boyahane">
            DELETE FROM qc_plan_items WHERE qc_plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <!--- Yeni plan --->
        <cfquery name="insplan" datasource="boyahane">
            INSERT INTO qc_plans (plan_code,plan_name,control_type,product_id,sample_method,sample_value,is_active,detail,record_date,record_ip)
            VALUES (
                <cfqueryparam value="#planCode#"   cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#planName#"   cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#ctType#"     cfsqltype="cf_sql_smallint">,
                <cfqueryparam value="#isNull(productId)?'':productId#" cfsqltype="cf_sql_integer" null="#isNull(productId)#">,
                <cfqueryparam value="#sampMeth#"   cfsqltype="cf_sql_smallint">,
                <cfqueryparam value="#isNull(sampVal)?'':sampVal#" cfsqltype="cf_sql_numeric" null="#isNull(sampVal)#">,
                <cfqueryparam value="#isActive#"   cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#detail#"     cfsqltype="cf_sql_varchar" null="#NOT len(detail)#">,
                CURRENT_TIMESTAMP,
                <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
            ) RETURNING qc_plan_id
        </cfquery>
        <cfset planId = val(insplan.qc_plan_id)>
    </cfif>

    <!--- Kalem satırlarını ekle --->
    <cfif isArray(itemsArr) AND arrayLen(itemsArr) gt 0>
        <cfloop array="#itemsArr#" index="item">
            <cfset pId  = isNumeric(item.qc_param_id ?: '') ? val(item.qc_param_id) : 0>
            <cfif pId eq 0><cfcontinue></cfif>
            <cfset mino = (structKeyExists(item,'min_override') AND len(trim(item.min_override)) AND isNumeric(item.min_override))
                          ? val(item.min_override) : javaCast("null","")>
            <cfset maxo = (structKeyExists(item,'max_override') AND len(trim(item.max_override)) AND isNumeric(item.max_override))
                          ? val(item.max_override) : javaCast("null","")>
            <cfset ireq = (lcase(trim(item.is_required ?: 'true')) eq "true")>
            <cfset sort = isNumeric(item.sort_order ?: 0) ? val(item.sort_order) : 0>

            <cfquery datasource="boyahane">
                INSERT INTO qc_plan_items (qc_plan_id, qc_param_id, is_required, min_override, max_override, sort_order)
                VALUES (
                    <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#pId#"    cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#ireq#"   cfsqltype="cf_sql_boolean">,
                    <cfqueryparam value="#isNull(mino)?'':mino#" cfsqltype="cf_sql_numeric" null="#isNull(mino)#">,
                    <cfqueryparam value="#isNull(maxo)?'':maxo#" cfsqltype="cf_sql_numeric" null="#isNull(maxo)#">,
                    <cfqueryparam value="#sort#"   cfsqltype="cf_sql_integer">
                )
                ON CONFLICT (qc_plan_id, qc_param_id) DO NOTHING
            </cfquery>
        </cfloop>
    </cfif>

    <cfset response.success = true>
    <cfcatch type="any"><cfset response.message = cfcatch.message></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
