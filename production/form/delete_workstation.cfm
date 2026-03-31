<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfset stId = isDefined("form.station_id") AND isNumeric(form.station_id) ? val(form.station_id) : 0>

    <cfif stId lte 0>
        <cfset response.message = "Geçersiz ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- İstasyon-ürün tanımlamaları CASCADE ile silinecek --->
    <cfquery datasource="boyahane">
        DELETE FROM workstations
        WHERE station_id = <cfqueryparam value="#stId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response = { "success": true }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>