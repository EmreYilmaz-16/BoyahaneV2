<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">

<!--- AJAX request için JSON response --->
<cfheader name="Content-Type" value="application/json">

<!--- ID parametresi kontrolü --->
<cfparam name="form.id" default="0">

<!--- CFC çağrısı --->
<cfinvoke component="product.cfc.product" method="deleteBrand" returnvariable="response">
    <cfinvokeargument name="id" value="#form.id#">
</cfinvoke>

<!--- JSON response döndür --->
<cfoutput>#response#</cfoutput>