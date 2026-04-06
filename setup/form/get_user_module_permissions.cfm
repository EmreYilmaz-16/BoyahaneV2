<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "", "data": [] }>

<cftry>
    <cfparam name="url.user_id" default="0">
    <cfset userId = isNumeric(url.user_id) AND val(url.user_id) gt 0 ? val(url.user_id) : 0>

    <cfif userId eq 0>
        <cfset response.message = "Geçersiz kullanıcı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery name="getPerms" datasource="boyahane">
        SELECT module_id, can_view, can_update, can_delete
        FROM user_module_permissions
        WHERE user_id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset dataArr = []>
    <cfloop query="getPerms">
        <cfset arrayAppend(dataArr, {
            "module_id": val(module_id),
            "can_view": can_view,
            "can_update": can_update,
            "can_delete": can_delete
        })>
    </cfloop>

    <cfset response = { "success": true, "data": dataArr }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message, "data": [] }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
