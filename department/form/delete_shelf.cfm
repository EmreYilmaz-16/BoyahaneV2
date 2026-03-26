<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset shelfId = isDefined("form.shelf_id") and isNumeric(form.shelf_id) ? val(form.shelf_id) : 0>

    <cfif shelfId lte 0>
        <cfoutput>{"success":false,"message":"Geçersiz raf ID."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- product_place_rows FK CASCADE ile silinir; yine de açık silelim --->
    <cfquery datasource="boyahane">
        DELETE FROM product_place_rows
        WHERE product_place_id = <cfqueryparam value="#shelfId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfquery datasource="boyahane">
        DELETE FROM product_place
        WHERE product_place_id = <cfqueryparam value="#shelfId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>{"success":true}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
