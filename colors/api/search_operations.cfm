<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">


<cfquery name="getProducts" datasource="boyahane">
    SELECT product.*,s.stock_id FROM product left join stocks s on product.product_id = s.product_id where 1=1 and (
        lower(product_name) LIKE <cfqueryparam value="%#lCase(url.query)#%" cfsqltype="cf_sql_varchar">
        OR lower(product_code) LIKE <cfqueryparam value="%#lCase(url.query)#%" cfsqltype="cf_sql_varchar">

    )

</cfquery>
<!----<cfdump var="#getProducts#">---->

<cfset arr = []>
<cfloop query="getProducts">
    <cfset arrayAppend(arr, {
        "product_id"  : val(product_id),
        "product_code": product_code ?: "",
        "product_name": product_name ?: "",
        "stock_id"    : val(stock_id),
        "productcat_id": val(product_catid)
        

    })>
</cfloop>
<cfoutput>#serializeJSON(arr)#</cfoutput>
<cfabort>