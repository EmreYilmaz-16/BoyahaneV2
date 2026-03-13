<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">

<!--- AJAX request için JSON response --->
<cfheader name="Content-Type" value="application/json">

<!--- ID parametresi kontrolü --->
<cfparam name="form.id" default="0">

<cfif val(form.id) eq 0>
    <cfset response = {
        "success": false,
        "message": "Geçersiz kategori ID"
    }>
    <cfoutput>#serializeJSON(response)#</cfoutput>
    <cfabort>
</cfif>

<!--- Kategoriye bağlı ürün var mı kontrol et --->
<cftry>
    <cfquery name="checkProducts" datasource="boyahane">
        SELECT COUNT(*) as product_count
        FROM product
        WHERE product_catid = <cfqueryparam value="#form.id#" cfsqltype="cf_sql_integer">
    </cfquery>
    
    <cfif checkProducts.product_count gt 0>
        <cfset response = {
            "success": false,
            "message": "Bu kategoriye bağlı #checkProducts.product_count# adet ürün bulunmaktadır. Önce ürünleri silmelisiniz."
        }>
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>
    
    <!--- Kategoriyi sil --->
    <cfquery datasource="boyahane">
        DELETE FROM product_cat
        WHERE product_catid = <cfqueryparam value="#form.id#" cfsqltype="cf_sql_integer">
    </cfquery>
    
    <cfset response = {
        "success": true,
        "message": "Kategori başarıyla silindi"
    }>
    
    <cfcatch type="any">
        <cfset response = {
            "success": false,
            "message": "Kategori silinirken bir hata oluştu: #cfcatch.message#"
        }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
