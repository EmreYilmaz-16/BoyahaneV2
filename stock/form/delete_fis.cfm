<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset fisId = isDefined("form.fis_id") and isNumeric(form.fis_id) ? val(form.fis_id) : 0>

    <cfif fisId lte 0>
        <cfoutput>{"success":false,"message":"Geçersiz fiş ID."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Önce satırları sil --->
    <cfquery datasource="boyahane">
        DELETE FROM stock_fis_row
        WHERE fis_id = <cfqueryparam value="#fisId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <!--- Sonra fişi sil --->
    <cfquery name="delResult" datasource="boyahane">
        DELETE FROM stock_fis
        WHERE fis_id = <cfqueryparam value="#fisId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>{"success":true}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
