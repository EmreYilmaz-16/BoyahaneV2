<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.user_id" default="0">
    <cfparam name="form.module_id" default="0">
    <cfparam name="form.can_view" default="0">
    <cfparam name="form.can_update" default="0">
    <cfparam name="form.can_delete" default="0">

    <cfset userId = isNumeric(form.user_id) AND val(form.user_id) gt 0 ? val(form.user_id) : 0>
    <cfset moduleId = isNumeric(form.module_id) AND val(form.module_id) gt 0 ? val(form.module_id) : 0>
    <cfset canView = (form.can_view eq "1" OR form.can_view eq "true") ? true : false>
    <cfset canUpdate = (form.can_update eq "1" OR form.can_update eq "true") ? true : false>
    <cfset canDelete = (form.can_delete eq "1" OR form.can_delete eq "true") ? true : false>

    <cfif userId eq 0 OR moduleId eq 0>
        <cfset response.message = "Kullanıcı ve modül bilgisi zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif NOT canView>
        <cfset canUpdate = false>
        <cfset canDelete = false>
    </cfif>

    <cfquery datasource="boyahane">
        INSERT INTO user_module_permissions
            (user_id, module_id, can_view, can_update, can_delete, record_date, update_date)
        VALUES (
            <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#moduleId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#canView#" cfsqltype="cf_sql_bit">,
            <cfqueryparam value="#canUpdate#" cfsqltype="cf_sql_bit">,
            <cfqueryparam value="#canDelete#" cfsqltype="cf_sql_bit">,
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        )
        ON CONFLICT (user_id, module_id)
        DO UPDATE SET
            can_view = EXCLUDED.can_view,
            can_update = EXCLUDED.can_update,
            can_delete = EXCLUDED.can_delete,
            update_date = CURRENT_TIMESTAMP
    </cfquery>

    <cfset response = { "success": true }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
