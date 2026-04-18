<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!--- Operasyon başlık satırları: related_product_tree_id IS NULL, operation_type_id dolu --->
<cfquery name="getOperations" datasource="boyahane">
    SELECT pt.product_tree_id, pt.operation_type_id, pt.operation_line_number, ot.operation_type
    FROM product_tree pt
    LEFT JOIN operation_types ot ON ot.operation_type_id = pt.operation_type_id
    WHERE pt.stock_id = <cfqueryparam value="#url.stock_id#" cfsqltype="cf_sql_integer">
      AND pt.related_product_tree_id IS NULL
      AND pt.operation_type_id IS NOT NULL
    ORDER BY pt.operation_line_number
</cfquery>

<cfset TreeArr = []>
<cfloop query="getOperations">

    <!--- Bu operasyona ait ürün satırları --->
    <cfquery name="getItems" datasource="boyahane">
        SELECT pt.related_id, pt.product_id, pt.line_number, pt.amount, pt.related_product_tree_id,
               p.product_name, p.product_code, p.product_catid
        FROM product_tree pt
        LEFT JOIN stocks s ON pt.related_id = s.stock_id
        LEFT JOIN product p ON p.product_id = s.product_id
        WHERE pt.related_product_tree_id = <cfqueryparam value="#product_tree_id#" cfsqltype="cf_sql_integer">
        ORDER BY pt.line_number
    </cfquery>

    <cfset items = []>
    <cfloop query="getItems">
        <cfset arrayAppend(items, {
            "related_id"              : val(related_id),
            "product_id"              : val(product_id),
            "line_number"             : val(line_number),
            "related_product_tree_id" : val(related_product_tree_id),
            "product_name"            : product_name ?: "",
            "product_code"            : product_code ?: "",
            "amount"                  : val(amount),
            "productcat_id"           : val(product_catid)
        })>
    </cfloop>

    <cfset arrayAppend(TreeArr, {
        "product_tree_id"     : val(product_tree_id),
        "operation_type_id"   : val(operation_type_id),
        "operation_type"      : operation_type ?: "",
        "operation_line_number": val(operation_line_number),
        "items"               : items
    })>
</cfloop>

<cfoutput>#serializeJSON(TreeArr)#</cfoutput>
<cfabort>