<cfprocessingdirective pageEncoding="utf-8">
<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfset orderRowId = isDefined("form.order_row_id") AND isNumeric(form.order_row_id) ? val(form.order_row_id) : 0>
    <cfset newStockId  = isDefined("form.stock_id")     AND isNumeric(form.stock_id)     ? val(form.stock_id)     : 0>

    <cfif orderRowId lte 0 OR newStockId lte 0>
        <cfset response.message = "Geçersiz parametre.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Yeni stok kartının bilgilerini al --->
    <cfquery name="getStock" datasource="boyahane">
        SELECT s.stock_id, s.stock_code, s.stock_code_2, s.property, s.is_main_stock,
               p.product_name, p.product_id
        FROM stocks s
        LEFT JOIN product p ON s.product_id = p.product_id
        WHERE s.stock_id = <cfqueryparam value="#newStockId#" cfsqltype="cf_sql_integer">
        LIMIT 1
    </cfquery>

    <cfif NOT getStock.recordCount>
        <cfset response.message = "Stok kartı bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- order_row_id'nin var olduğunu ve güvenli olduğunu doğrula --->
    <cfquery name="checkRow" datasource="boyahane">
        SELECT order_row_id FROM order_row
        WHERE order_row_id = <cfqueryparam value="#orderRowId#" cfsqltype="cf_sql_integer">
        LIMIT 1
    </cfquery>

    <cfif NOT checkRow.recordCount>
        <cfset response.message = "Sipariş satırı bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Ürün adını oluştur: ürün adı + renk/özellik --->
    <cfset baseProductName = trim(getStock.product_name ?: "")>
    <cfset colorProp = trim(getStock.property ?: "")>
    <cfset colorCode = trim(getStock.stock_code_2 ?: "")>
    <cfif len(colorProp) gt 0>
        <cfset newProductName = baseProductName & " — " & colorProp>
    <cfelseif len(colorCode) gt 0>
        <cfset newProductName = baseProductName & " (" & colorCode & ")">
    <cfelse>
        <cfset newProductName = baseProductName>
    </cfif>

    <!--- Güncelle --->
    <cfquery datasource="boyahane">
        UPDATE order_row
        SET stock_id     = <cfqueryparam value="#newStockId#"    cfsqltype="cf_sql_integer">,
            product_name = <cfqueryparam value="#newProductName#" cfsqltype="cf_sql_varchar">
        WHERE order_row_id = <cfqueryparam value="#orderRowId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response = {
        "success":      true,
        "stock_id":     val(getStock.stock_id),
        "stock_code":   getStock.stock_code ?: "",
        "stock_code_2": getStock.stock_code_2 ?: "",
        "property":     getStock.property ?: "",
        "product_name": newProductName,
        "is_main_stock": getStock.is_main_stock
    }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfcontent type="application/json; charset=utf-8">
<cfoutput>#serializeJSON(response)#</cfoutput>
