<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif NOT structKeyExists(session, "authenticated") OR NOT session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset userId = isDefined("form.user_id") AND isNumeric(form.user_id) ? val(form.user_id) : 0>

    <cfif userId LTE 0>
        <cfoutput>{"success":false,"message":"Geçersiz kullanıcı."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Kendini silemesin --->
    <cfif userId EQ val(session.user.id ?: 0)>
        <cfoutput>{"success":false,"message":"Kendi hesabınızı silemezsiniz."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM kullanicilar
        WHERE id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>{"success":true}</cfoutput>

<cfcatch type="any">
    <cfoutput>{"success":false,"message":"Beklenmeyen hata: #jsStringFormat(cfcatch.message)#"}</cfoutput>
</cfcatch>
</cftry>
