<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.color_id" default="0">
    <cfset colorId = isNumeric(form.color_id) AND val(form.color_id) gt 0 ? val(form.color_id) : 0>

    <cfif colorId eq 0>
        <cfset response.message = "Geçersiz color_id.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- color_info'dan stock_id'yi al --->
    <cfquery name="getCI" datasource="boyahane">
        SELECT stock_id FROM color_info WHERE color_id = <cfqueryparam value="#colorId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getCI.recordCount>
        <cfset response.message = "Renk kaydı bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>
    <cfset stockId = val(getCI.stock_id)>

    <!--- Reçete satırlarını sil --->
    <cfquery datasource="boyahane">
        DELETE FROM product_tree WHERE stock_id = <cfqueryparam value="#stockId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <!--- color_info sil --->
    <cfquery datasource="boyahane">
        DELETE FROM color_info WHERE color_id = <cfqueryparam value="#colorId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <!--- Stock sil --->
    <cfquery datasource="boyahane">
        DELETE FROM stocks WHERE stock_id = <cfqueryparam value="#stockId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response = { "success": true, "deleted_color_id": colorId }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
