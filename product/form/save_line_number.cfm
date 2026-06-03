<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.product_tree_id" default="0">
    <cfparam name="form.line_number"     default="0">

    <cfset treeId  = isNumeric(form.product_tree_id) ? val(form.product_tree_id) : 0>
    <cfset lineNum = isNumeric(form.line_number)     ? int(val(form.line_number)) : 0>

    <cfif treeId eq 0>
        <cfset response.message = "Geçersiz satır.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        UPDATE product_tree
        SET line_number = <cfqueryparam value="#lineNum#" cfsqltype="cf_sql_integer">
        WHERE product_tree_id = <cfqueryparam value="#treeId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response = { "success": true }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
