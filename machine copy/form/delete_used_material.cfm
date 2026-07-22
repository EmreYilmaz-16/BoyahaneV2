<cfprocessingdirective pageEncoding="utf-8">
<cfheader name="Content-Type" value="application/json; charset=utf-8">
<cftry>
    <cfset materialId = val(url.material_id ?: 0)>
    <cfif materialId LTE 0>
        <cfoutput>{"success":false,"message":"Geçersiz malzeme ID."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM machine_used_materials
        WHERE material_id = <cfqueryparam value="#materialId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfoutput>{"success":true,"message":"Malzeme silindi."}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":"#JSStringFormat(cfcatch.message)#"}</cfoutput>
    </cfcatch>
</cftry>
