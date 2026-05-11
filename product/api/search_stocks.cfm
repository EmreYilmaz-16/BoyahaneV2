<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfparam name="url.q"     default="">
<cfparam name="url.limit" default="50">

<cfset q     = trim(url.q)>
<cfset lim   = (isNumeric(url.limit) AND val(url.limit) gt 0) ? min(val(url.limit), 200) : 50>

<cftry>
    <cfquery name="getStocks" datasource="boyahane">
        SELECT s.stock_id,
               COALESCE(s.stock_code,'')   AS stock_code,
               COALESCE(p.product_name,'') AS product_name
        FROM stocks s
        LEFT JOIN product p ON s.product_id = p.product_id
        WHERE COALESCE(s.stock_status, true) = true
        <cfif len(q)>
            AND (
                s.stock_code    ILIKE <cfqueryparam value="%#q#%" cfsqltype="cf_sql_varchar">
                OR p.product_name ILIKE <cfqueryparam value="%#q#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>
        ORDER BY s.stock_code
        LIMIT <cfqueryparam value="#lim#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset result = []>
    <cfloop query="getStocks">
        <cfset arrayAppend(result, {
            "stock_id"    : val(stock_id),
            "stock_code"  : stock_code   ?: "",
            "product_name": product_name ?: ""
        })>
    </cfloop>

    <cfoutput>#serializeJSON(result)#</cfoutput>
<cfcatch>
    <cfoutput>[]</cfoutput>
</cfcatch>
</cftry>
