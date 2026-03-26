<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfif NOT isDefined("session.authenticated") OR NOT session.authenticated>
        <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
        <cfabort>
    </cfif>

    <cfset ship_id = isDefined("form.ship_id") AND isNumeric(form.ship_id) ? val(form.ship_id) : 0>

    <cfif ship_id lte 0>
        <cfoutput>{"success":false,"message":"Geçersiz ID."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM ship_row WHERE ship_id = <cfqueryparam value="#ship_id#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfquery datasource="boyahane">
        DELETE FROM ship_money WHERE action_id = <cfqueryparam value="#ship_id#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfquery datasource="boyahane">
        DELETE FROM ship WHERE ship_id = <cfqueryparam value="#ship_id#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>{"success":true,"message":"İrsaliye silindi."}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":"#jsStringFormat(cfcatch.message)#"}</cfoutput>
    </cfcatch>
</cftry>
