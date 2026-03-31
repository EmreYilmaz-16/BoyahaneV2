<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.operation_type_id"  default="0">
    <cfparam name="form.operation_type"     default="">
    <cfparam name="form.operation_code"     default="">
    <cfparam name="form.operation_cost"     default="0">
    <cfparam name="form.money"              default="">
    <cfparam name="form.o_hour"             default="0">
    <cfparam name="form.o_minute"           default="0">
    <cfparam name="form.operation_status"   default="false">
    <cfparam name="form.comment"            default="">
    <cfparam name="form.comment2"           default="">
    <cfparam name="form.ezgi_h_sure"        default="0">
    <cfparam name="form.ezgi_formul"        default="">
    <cfparam name="form.stock_id"           default="0">
    <cfparam name="form.product_name"       default="">

    <cfset opId     = isNumeric(form.operation_type_id) ? val(form.operation_type_id) : 0>
    <cfset opName   = trim(form.operation_type)>
    <cfset opStatus = (form.operation_status eq "true" OR form.operation_status eq "1")>
    <cfset opCost   = isNumeric(form.operation_cost) ? val(form.operation_cost) : 0>
    <cfset oHour    = isNumeric(form.o_hour)   ? val(form.o_hour)   : 0>
    <cfset oMinute  = isNumeric(form.o_minute) ? val(form.o_minute) : 0>
    <cfset stockId  = isNumeric(form.stock_id) AND val(form.stock_id) gt 0 ? val(form.stock_id) : javaCast("null","")>
    <cfset ezgiSure = isNumeric(form.ezgi_h_sure) ? val(form.ezgi_h_sure) : 0>

    <cfif NOT len(opName)>
        <cfset response.message = "Operasyon adı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <cfif opId gt 0>
        <!--- UPDATE --->
        <cfquery datasource="boyahane">
            UPDATE operation_types SET
                operation_type   = <cfqueryparam value="#opName#"                cfsqltype="cf_sql_varchar">,
                operation_code   = <cfqueryparam value="#trim(form.operation_code)#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.operation_code))#">,
                operation_cost   = <cfqueryparam value="#opCost#"                cfsqltype="cf_sql_numeric">,
                money            = <cfqueryparam value="#trim(form.money)#"      cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.money))#">,
                o_hour           = <cfqueryparam value="#oHour#"                 cfsqltype="cf_sql_integer">,
                o_minute         = <cfqueryparam value="#oMinute#"               cfsqltype="cf_sql_integer">,
                operation_status = <cfqueryparam value="#opStatus#"              cfsqltype="cf_sql_bit">,
                comment          = <cfqueryparam value="#trim(form.comment)#"    cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.comment))#">,
                comment2         = <cfqueryparam value="#trim(form.comment2)#"   cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.comment2))#">,
                ezgi_h_sure      = <cfqueryparam value="#ezgiSure#"              cfsqltype="cf_sql_numeric">,
                ezgi_formul      = <cfqueryparam value="#trim(form.ezgi_formul)#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.ezgi_formul))#">,
                stock_id         = <cfqueryparam value="#isNull(stockId) ? '' : stockId#" cfsqltype="cf_sql_integer" null="#isNull(stockId)#">,
                product_name     = <cfqueryparam value="#trim(form.product_name)#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.product_name))#">
            WHERE operation_type_id = <cfqueryparam value="#opId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset response = { "success": true, "operation_type_id": opId, "mode": "updated" }>
    <cfelse>
        <!--- INSERT --->
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO operation_types
                (operation_type, operation_code, operation_cost, money, o_hour, o_minute,
                 operation_status, comment, comment2, ezgi_h_sure, ezgi_formul,
                 stock_id, product_name, record_date)
            VALUES (
                <cfqueryparam value="#opName#"                cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#trim(form.operation_code)#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.operation_code))#">,
                <cfqueryparam value="#opCost#"                cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#trim(form.money)#"      cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.money))#">,
                <cfqueryparam value="#oHour#"                 cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#oMinute#"               cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#opStatus#"              cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#trim(form.comment)#"    cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.comment))#">,
                <cfqueryparam value="#trim(form.comment2)#"   cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.comment2))#">,
                <cfqueryparam value="#ezgiSure#"              cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#trim(form.ezgi_formul)#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.ezgi_formul))#">,
                <cfqueryparam value="#isNull(stockId) ? '' : stockId#" cfsqltype="cf_sql_integer" null="#isNull(stockId)#">,
                <cfqueryparam value="#trim(form.product_name)#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.product_name))#">,
                CURRENT_TIMESTAMP
            )
            RETURNING operation_type_id
        </cfquery>
        <cfset response = { "success": true, "operation_type_id": val(ins.operation_type_id), "mode": "added" }>
    </cfif>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>