<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.prod_pause_type_id"   default="0">
    <cfparam name="form.prod_pause_type"      default="">
    <cfparam name="form.prod_pause_type_code" default="">
    <cfparam name="form.is_active"            default="1">
    <cfparam name="form.pause_detail"         default="">

    <cfset typeId   = isNumeric(form.prod_pause_type_id) AND val(form.prod_pause_type_id) gt 0 ? val(form.prod_pause_type_id) : 0>
    <cfset typeName = trim(form.prod_pause_type)>
    <cfset typeCode = trim(form.prod_pause_type_code)>
    <cfset isActive = (form.is_active eq "1" OR form.is_active eq "true") ? true : false>
    <cfset detail   = trim(form.pause_detail)>

    <cfif NOT len(typeName)>
        <cfset response.message = "Duruş tipi adı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif typeId gt 0>
        <cfquery datasource="boyahane">
            UPDATE setup_prod_pause_type SET
                prod_pause_type      = <cfqueryparam value="#typeName#" cfsqltype="cf_sql_varchar">,
                prod_pause_type_code = <cfqueryparam value="#typeCode#" cfsqltype="cf_sql_varchar" null="#NOT len(typeCode)#">,
                is_active            = <cfqueryparam value="#isActive#" cfsqltype="cf_sql_bit">,
                pause_detail         = <cfqueryparam value="#detail#"   cfsqltype="cf_sql_varchar" null="#NOT len(detail)#">,
                update_date          = CURRENT_TIMESTAMP,
                update_ip            = <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
            WHERE prod_pause_type_id = <cfqueryparam value="#typeId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset response = { "success": true, "prod_pause_type_id": typeId, "mode": "updated" }>
    <cfelse>
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO setup_prod_pause_type
                (prod_pause_type, prod_pause_type_code, is_active, pause_detail, record_date, record_ip)
            VALUES (
                <cfqueryparam value="#typeName#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#typeCode#" cfsqltype="cf_sql_varchar" null="#NOT len(typeCode)#">,
                <cfqueryparam value="#isActive#" cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#detail#"   cfsqltype="cf_sql_varchar" null="#NOT len(detail)#">,
                CURRENT_TIMESTAMP,
                <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
            )
            RETURNING prod_pause_type_id
        </cfquery>
        <cfset response = { "success": true, "prod_pause_type_id": val(ins.prod_pause_type_id), "mode": "added" }>
    </cfif>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
