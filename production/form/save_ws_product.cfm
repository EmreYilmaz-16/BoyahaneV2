<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.ws_p_id"            default="0">
    <cfparam name="form.ws_id"              default="0">
    <cfparam name="form.stock_id"           default="0">
    <cfparam name="form.operation_type_id"  default="0">
    <cfparam name="form.capacity"           default="0">
    <cfparam name="form.production_time"    default="0">
    <cfparam name="form.setup_time"         default="0">

    <cfset wpId   = isNumeric(form.ws_p_id) ? val(form.ws_p_id) : 0>
    <cfset wsId   = isNumeric(form.ws_id)   ? val(form.ws_id)   : 0>
    <cfset stkId  = isNumeric(form.stock_id) AND val(form.stock_id) gt 0 ? val(form.stock_id) : 0>
    <cfset opId   = isNumeric(form.operation_type_id) AND val(form.operation_type_id) gt 0 ? val(form.operation_type_id) : javaCast("null","")>
    <cfset cap    = isNumeric(form.capacity)        ? val(form.capacity)        : 0>
    <cfset pTime  = isNumeric(form.production_time) ? val(form.production_time) : 0>
    <cfset sTime  = isNumeric(form.setup_time)      ? val(form.setup_time)      : 0>

    <cfif wsId lte 0>
        <cfset response.message = "İstasyon ID zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>
    <cfif stkId lte 0>
        <cfset response.message = "Stok seçilmedi.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <cfif wpId gt 0>
        <!--- UPDATE --->
        <cfquery datasource="boyahane">
            UPDATE workstations_products SET
                stock_id          = <cfqueryparam value="#stkId#" cfsqltype="cf_sql_integer">,
                operation_type_id = <cfqueryparam value="#isNull(opId)?'':opId#" cfsqltype="cf_sql_integer" null="#isNull(opId)#">,
                capacity          = <cfqueryparam value="#cap#"   cfsqltype="cf_sql_numeric">,
                production_time   = <cfqueryparam value="#pTime#" cfsqltype="cf_sql_numeric">,
                setup_time        = <cfqueryparam value="#sTime#" cfsqltype="cf_sql_numeric">
            WHERE ws_p_id = <cfqueryparam value="#wpId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset response = { "success": true, "ws_p_id": wpId, "mode": "updated" }>
    <cfelse>
        <!--- INSERT --->
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO workstations_products
                (ws_id, stock_id, operation_type_id, capacity, production_time, setup_time)
            VALUES (
                <cfqueryparam value="#wsId#"  cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#stkId#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#isNull(opId)?'':opId#" cfsqltype="cf_sql_integer" null="#isNull(opId)#">,
                <cfqueryparam value="#cap#"   cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#pTime#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#sTime#" cfsqltype="cf_sql_numeric">
            )
            RETURNING ws_p_id
        </cfquery>
        <cfset response = { "success": true, "ws_p_id": val(ins.ws_p_id), "mode": "added" }>
    </cfif>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
