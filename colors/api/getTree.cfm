<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfquery name="getProductTree" datasource="boyahane">
    select pt.related_id,pt.product_id,pt.operation_type_id,pt.line_number,pt.related_product_tree_id,p.product_name,p.product_code,ot.operation_type,pt.amount,pc.product_catid 
from product_tree pt
left join stocks s on pt.related_id=s.stock_id
left join product p on p.product_id=s.product_id
left join product_cat pc on pc.product_catid=p.product_catid
left join operation_types  ot on ot.operation_type_id=pt.operation_type_id
 where pt.stock_id=<cfqueryparam value="#url.stock_id#" cfsqltype="cf_sql_integer">
order  by pt.line_number
</cfquery>
<cfset arr = []>
<cfloop query="getProductTree">
    <cfset arrayAppend(arr, {
        "related_id"         : val(related_id),
        "product_id"         : val(product_id),
        "operation_type_id"  : val(operation_type_id),
        "line_number"        : val(line_number),
        "related_product_tree_id": val(related_product_tree_id),
        "product_name"       : product_name ?: "",
        "product_code"       : product_code ?: "",
        "operation_type"     : operation_type ?: "",
        "amount"             : val(amount),
        "productcat_id"      : val(product_catid)
    })>
</cfloop>

<cfoutput>#serializeJSON(arr)#</cfoutput>
<cfabort>
