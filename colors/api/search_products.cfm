<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Boya / bileşen / hammadde arama
    Parametre: url.keyword
    Geri döner: [ { stock_id, stock_code, product_name, tip, tip_label } ]
--->

<cfparam name="url.keyword" default="">
<cfset kw = trim(url.keyword)>

<cfif NOT len(kw)>
    <cfoutput>[]</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfquery name="getProds" datasource="boyahane">
        SELECT DISTINCT
            s.stock_id,
            COALESCE(s.stock_code,'')    AS stock_code,
            COALESCE(p.product_name,'')  AS product_name,
            COALESCE(p.product_code,'')  AS product_code,
            COALESCE(pc.hierarchy,'')    AS pc_hierarchy
        FROM stocks s
        LEFT JOIN product p      ON s.product_id    = p.product_id
        LEFT JOIN product_cat pc ON p.product_catid = pc.product_catid
        WHERE COALESCE(s.stock_status, true) = true
          AND (
            p.product_name ILIKE <cfqueryparam value="%#kw#%" cfsqltype="cf_sql_varchar">
            OR s.stock_code ILIKE <cfqueryparam value="%#kw#%" cfsqltype="cf_sql_varchar">
            OR p.product_code ILIKE <cfqueryparam value="%#kw#%" cfsqltype="cf_sql_varchar">
          )
        ORDER BY stock_code
        LIMIT 50
    </cfquery>

    <cfset arr = []>
    <cfloop query="getProds">
        <!---
            TIP classificaton (eski sistemdeki PRODUCT_CODE prefix mantığı):
              0 = Ana Boya        (hierarchy starts with '150.01' or 'boya')
              1 = Aux / Yardımcı  (hierarchy starts with '150.02')
              2 = Kimyasal        (hierarchy starts with '150.03')
              default = 0 (boya)
        --->
        <cfset tip = 0>
        <cfset tipLabel = "Boya">
        <cfif pc_hierarchy CONTAINS "150.02" OR pc_hierarchy CONTAINS "aux">
            <cfset tip = 1><cfset tipLabel = "Yardımcı">
        <cfelseif pc_hierarchy CONTAINS "150.03" OR pc_hierarchy CONTAINS "kimya">
            <cfset tip = 2><cfset tipLabel = "Kimyasal">
        </cfif>

        <cfset arrayAppend(arr, {
            "stock_id"    : val(stock_id),
            "stock_code"  : stock_code    ?: "",
            "product_name": product_name  ?: "",
            "product_code": product_code  ?: "",
            "tip"         : tip,
            "tip_label"   : tipLabel
        })>
    </cfloop>

    <cfoutput>#serializeJSON(arr)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>[]</cfoutput>
    </cfcatch>
</cftry>
