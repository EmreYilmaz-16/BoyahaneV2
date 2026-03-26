<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Mevcut bir rengin boya reçetesini döndürür (düzenleme modu için)
    Parametre: url.stock_id
    Geri döner: [ { product_tree_id, stock_id, product_name, stock_code, amount, unit_id, tip, line_number,
                    is_operation, operation_type_id, related_product_tree_id } ]
--->

<cfparam name="url.stock_id" default="0">
<cfset sid = isNumeric(url.stock_id) AND val(url.stock_id) gt 0 ? val(url.stock_id) : 0>

<cfif sid eq 0>
    <cfoutput>[]</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfquery name="getRecipe" datasource="boyahane">
        SELECT
            pt.product_tree_id                          AS product_tree_id,
            pt.related_id                               AS stock_id,
            COALESCE(s.stock_code,'')                   AS stock_code,
            COALESCE(p.product_name,'')                 AS product_name,
            COALESCE(pt.amount, 1)                      AS amount,
            COALESCE(pt.unit_id, 0)                     AS unit_id,
            COALESCE(pt.line_number, 0)                 AS line_number,
            COALESCE(pc.hierarchy,'')                   AS pc_hierarchy,
            CASE WHEN pt.related_id IS NULL AND pt.operation_type_id IS NOT NULL
                 THEN 1 ELSE 0 END                      AS is_operation,
            COALESCE(pt.operation_type_id, 0)           AS operation_type_id,
            COALESCE(pt.related_product_tree_id, 0)     AS related_product_tree_id
        FROM product_tree pt
        LEFT JOIN stocks  s  ON pt.related_id     = s.stock_id
        LEFT JOIN product p  ON s.product_id      = p.product_id
        LEFT JOIN product_cat pc ON p.product_catid = pc.product_catid
        WHERE pt.stock_id = <cfqueryparam value="#sid#" cfsqltype="cf_sql_integer">
          AND (
              pt.related_id IS NOT NULL
              OR (pt.related_id IS NULL AND pt.operation_type_id IS NOT NULL)
          )
        ORDER BY pt.line_number, pt.product_tree_id
    </cfquery>

    <cfset arr = []>
    <cfset ctr  = 0>
    <cfloop query="getRecipe">
        <cfset ctr++>
        <cfset tip = 0>
        <cfif pc_hierarchy CONTAINS "150.02" OR pc_hierarchy CONTAINS "aux">
            <cfset tip = 1>
        <cfelseif pc_hierarchy CONTAINS "150.03" OR pc_hierarchy CONTAINS "kimya">
            <cfset tip = 2>
        </cfif>
        <cfset arrayAppend(arr, {
            "row_id"                 : ctr,
            "product_tree_id"        : val(product_tree_id),
            "stock_id"               : (val(stock_id) gt 0 ? val(stock_id) : javaCast("null","")),
            "stock_code"             : stock_code    ?: "",
            "product_name"           : product_name  ?: "",
            "amount"                 : isNumeric(amount) ? val(amount) : 1,
            "unit_id"                : val(unit_id),
            "tip"                    : tip,
            "line_number"            : val(line_number),
            "is_operation"           : val(is_operation),
            "operation_type_id"      : val(operation_type_id),
            "related_product_tree_id": val(related_product_tree_id)
        })>
    </cfloop>

    <cfoutput>#serializeJSON(arr)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>[]</cfoutput>
    </cfcatch>
</cftry>
