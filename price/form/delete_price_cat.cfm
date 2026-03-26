<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfparam name="form.price_catid" default="0">
    <cfset catId = val(form.price_catid)>

    <cfif catId lte 0>
        <cfoutput>#serializeJSON({"success": false, "message": "Geçersiz fiyat listesi ID."})#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Önce price satırları CASCADE ile silinir (FK ON DELETE CASCADE) --->
    <cfquery datasource="boyahane">
        DELETE FROM price_cat WHERE price_catid = <cfqueryparam value="#catId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>#serializeJSON({"success": true})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success": false, "message": cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
