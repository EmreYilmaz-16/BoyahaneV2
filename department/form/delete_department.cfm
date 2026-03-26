<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset deptId = isDefined("form.department_id") and isNumeric(form.department_id) ? val(form.department_id) : 0>

    <cfif deptId lte 0>
        <cfoutput>{"success":false,"message":"Geçersiz departman ID."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Önce bağlı lokasyonları sil (FK CASCADE var ama yine de açık yapalım) --->
    <cfquery datasource="boyahane">
        DELETE FROM stocks_location
        WHERE department_id = <cfqueryparam value="#deptId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfquery datasource="boyahane">
        DELETE FROM department
        WHERE department_id = <cfqueryparam value="#deptId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>{"success":true}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
