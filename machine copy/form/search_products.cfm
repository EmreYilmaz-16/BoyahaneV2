<cfprocessingdirective pageEncoding="utf-8">
<cfheader name="Content-Type" value="application/json; charset=utf-8">
<cfset q = trim(url.q ?: "")>
<cfif len(q) LT 2>
    <cfoutput>[]</cfoutput>
    <cfabort>
</cfif>
<cfset searchVal = "%" & q & "%">
<cftry>
    <cfquery name="qProducts" datasource="boyahane">
        SELECT product_id, product_name, COALESCE(product_code,'') AS product_code
        FROM product
        WHERE (
              product_name ILIKE <cfqueryparam value="#searchVal#" cfsqltype="cf_sql_varchar">
           OR product_code ILIKE <cfqueryparam value="#searchVal#" cfsqltype="cf_sql_varchar">
        )
        ORDER BY product_name
        LIMIT 20
    </cfquery>
    <cfset arr = []>
    <cfloop query="qProducts">
        <cfset arrayAppend(arr, {
            "product_id":   val(product_id),
            "product_name": product_name ?: "",
            "product_code": product_code ?: "",
            "label":        (product_name ?: "") & (len(product_code ?: "") ? " [" & product_code & "]" : "")
        })>
    </cfloop>
    <cfoutput>#serializeJSON(arr)#</cfoutput>
    <cfcatch type="any">
        <cfoutput>[]</cfoutput>
    </cfcatch>
</cftry>
