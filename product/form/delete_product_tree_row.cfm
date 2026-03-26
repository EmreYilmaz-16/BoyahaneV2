<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    product_tree satırı sil
    Sahiplik kontrolü: product_tree_id + stock_id = root_stock_id
    Recursive CTE ile alt dallar dahil tüm torunlar silinir.
--->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.product_tree_id" default="0">
    <cfparam name="form.root_stock_id"   default="0">

    <cfset treeId      = isNumeric(form.product_tree_id) ? val(form.product_tree_id) : 0>
    <cfset rootStockId = isNumeric(form.root_stock_id)   ? val(form.root_stock_id)   : 0>

    <cfif treeId eq 0 OR rootStockId eq 0>
        <cfset response.message = "Geçersiz parametre.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Sahiplik kontrolü --->
    <cfquery name="chkOwn" datasource="boyahane">
        SELECT product_tree_id FROM product_tree
        WHERE product_tree_id = <cfqueryparam value="#treeId#"      cfsqltype="cf_sql_integer">
          AND stock_id         = <cfqueryparam value="#rootStockId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif chkOwn.recordCount eq 0>
        <cfset response.message = "Kayıt bulunamadı veya silme yetkiniz yok.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Recursive CTE ile tüm torunları da dahil ederek sil --->
    <cfquery name="delRows" datasource="boyahane">
        WITH RECURSIVE descendants AS (
            SELECT product_tree_id
            FROM   product_tree
            WHERE  product_tree_id = <cfqueryparam value="#treeId#" cfsqltype="cf_sql_integer">

            UNION ALL

            SELECT pt.product_tree_id
            FROM   product_tree pt
            INNER JOIN descendants d ON pt.related_product_tree_id = d.product_tree_id
        )
        DELETE FROM product_tree
        WHERE  product_tree_id IN (SELECT product_tree_id FROM descendants)
        RETURNING product_tree_id
    </cfquery>

    <cfset deletedIds = []>
    <cfloop query="delRows">
        <cfset arrayAppend(deletedIds, val(delRows.product_tree_id))>
    </cfloop>

    <cfset response = { "success": true, "deleted_ids": deletedIds }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
