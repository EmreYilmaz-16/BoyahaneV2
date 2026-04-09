<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfparam name="url.search" default="">
    <cfparam name="url.sort"   default="name">
    <cfparam name="url.page"   default="1">

    <cfset search  = trim(url.search)>
    <cfset sort    = (url.sort eq "code") ? "code" : "name">
    <cfset pageNum = max(1, int(val(url.page)))>
    <cfset pageSize = 30>
    <cfset offset   = (pageNum - 1) * pageSize>

    <cfif len(search) lt 2>
        <cfoutput>#serializeJSON({"items": [], "hasMore": false, "page": 1})#</cfoutput>
        <cfabort>
    </cfif>

    <cfset searchParam = "%" & search & "%">
    <cfset orderBy = (sort eq "code") ? "s.stock_code, p.product_name" : "p.product_name, s.stock_code">

    <cfquery name="getProducts" datasource="boyahane">
        SELECT s.stock_id, s.stock_code, s.barcod,
               p.product_id, p.product_name, p.product_code
        FROM stocks s
        LEFT JOIN product p ON p.product_id = s.product_id
        WHERE s.stock_status = true
          AND (
              p.product_name ILIKE <cfqueryparam value="#searchParam#" cfsqltype="cf_sql_varchar">
           OR p.product_code ILIKE <cfqueryparam value="#searchParam#" cfsqltype="cf_sql_varchar">
           OR s.stock_code   ILIKE <cfqueryparam value="#searchParam#" cfsqltype="cf_sql_varchar">
           OR s.barcod        ILIKE <cfqueryparam value="#searchParam#" cfsqltype="cf_sql_varchar">
          )
        ORDER BY #orderBy#
        LIMIT #pageSize + 1#
        OFFSET #offset#
    </cfquery>

    <cfset hasMore = (getProducts.recordCount gt pageSize)>
    <cfset items = []>
    <cfset rowNum = 0>
    <cfloop query="getProducts">
        <cfset rowNum++>
        <cfif rowNum lte pageSize>
            <cfset arrayAppend(items, {
                "stock_id":     stock_id,
                "product_id":   product_id ?: 0,
                "product_name": product_name ?: "Ürün",
                "product_code": product_code ?: "",
                "stock_code":   stock_code ?: "",
                "barcod":       barcod ?: ""
            })>
        </cfif>
    </cfloop>

    <cfoutput>#serializeJSON({"items": items, "hasMore": hasMore, "page": pageNum})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"items": [], "hasMore": false, "error": cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
