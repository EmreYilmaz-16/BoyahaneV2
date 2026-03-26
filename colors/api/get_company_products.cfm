<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Müşteriye ait is_main_stock = true stokları (kumaşlar) döndürür
    Parametre: url.company_id
    Geri döner: [ { product_id, product_name, stock_code } ]
--->

<cfparam name="url.company_id" default="0">
<cfset cid = isNumeric(url.company_id) AND val(url.company_id) gt 0 ? val(url.company_id) : 0>

<cfif cid eq 0>
    <cfoutput>[]</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfquery name="getProds" datasource="boyahane">
        SELECT
            s.stock_id,
            s.stock_code,
            COALESCE(p.product_name,'') AS product_name,
            COALESCE(p.product_id, 0)  AS product_id
        FROM stocks s
        LEFT JOIN product p ON s.product_id = p.product_id
        WHERE p.company_id  = <cfqueryparam value="#cid#" cfsqltype="cf_sql_integer">
          AND COALESCE(s.is_main_stock, false) = true
          AND COALESCE(s.stock_status, true)   = true
        ORDER BY s.stock_code
    </cfquery>

    <cfset arr = []>
    <cfloop query="getProds">
        <cfset arrayAppend(arr, {
            "stock_id"    : val(stock_id),
            "product_id"  : val(product_id),
            "stock_code"  : stock_code    ?: "",
            "product_name": product_name  ?: ""
        })>
    </cfloop>

    <cfoutput>#serializeJSON(arr)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>[]</cfoutput>
    </cfcatch>
</cftry>
