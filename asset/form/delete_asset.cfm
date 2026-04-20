<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
    <cfset assetId = isDefined("form.asset_id") and isNumeric(form.asset_id) ? val(form.asset_id) : 0>

    <cfif assetId lte 0>
        <cfoutput>{"success":false,"message":"Geçersiz varlık ID."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM asset_master
        WHERE asset_id = <cfqueryparam value="#assetId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>{"success":true,"redirect":"index.cfm?fuseaction=asset.list_assets"}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
