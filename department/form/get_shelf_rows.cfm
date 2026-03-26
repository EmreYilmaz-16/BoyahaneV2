<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset shelfId = isDefined("url.shelf_id") and isNumeric(url.shelf_id) ? val(url.shelf_id) : 0>

    <cfif shelfId lte 0>
        <cfoutput>{"success":false,"message":"Geçersiz raf ID."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Raf bilgisi --->
    <cfquery name="getShelf" datasource="boyahane">
        SELECT pp.*, p.product_name, p.product_code
        FROM product_place pp
        LEFT JOIN product p ON pp.product_id = p.product_id
        WHERE pp.product_place_id = <cfqueryparam value="#shelfId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif getShelf.recordCount eq 0>
        <cfoutput>{"success":false,"message":"Raf bulunamadı."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Raf satırları --->
    <cfquery name="getRows" datasource="boyahane">
        SELECT ppr.product_place_row_id, ppr.product_id, ppr.stock_id, ppr.amount,
               p.product_name, p.product_code,
               s.stock_code, s.barcod
        FROM product_place_rows ppr
        LEFT JOIN product p ON ppr.product_id = p.product_id
        LEFT JOIN stocks   s ON ppr.stock_id   = s.stock_id
        WHERE ppr.product_place_id = <cfqueryparam value="#shelfId#" cfsqltype="cf_sql_integer">
        ORDER BY ppr.product_place_row_id
    </cfquery>

    <cfset shelfData = {
        "product_place_id" = getShelf.product_place_id,
        "shelf_code"       = getShelf.shelf_code ?: "",
        "place_status"     = getShelf.place_status ?: 0,
        "shelf_type"       = getShelf.shelf_type ?: 0,
        "quantity"         = getShelf.quantity ?: 0,
        "detail"           = getShelf.detail ?: "",
        "store_id"         = getShelf.store_id ?: 0,
        "product_id"       = getShelf.product_id ?: 0,
        "product_name"     = getShelf.product_name ?: "",
        "product_code"     = getShelf.product_code ?: "",
        "start_date"       = isDate(getShelf.start_date)  ? dateFormat(getShelf.start_date,  "yyyy-mm-dd") : "",
        "finish_date"      = isDate(getShelf.finish_date)  ? dateFormat(getShelf.finish_date, "yyyy-mm-dd") : "",
        "width"            = getShelf.width  ?: 0,
        "height"           = getShelf.height ?: 0,
        "depth"            = getShelf.depth  ?: 0,
        "x_coordinate"     = getShelf.x_coordinate ?: "",
        "y_coordinate"     = getShelf.y_coordinate ?: "",
        "z_coordinate"     = getShelf.z_coordinate ?: ""
    }>

    <cfset rowsArr = []>
    <cfloop query="getRows">
        <cfset arrayAppend(rowsArr, {
            "product_place_row_id" = product_place_row_id,
            "product_id"   = product_id ?: 0,
            "stock_id"     = stock_id   ?: 0,
            "amount"       = amount     ?: 0,
            "product_name" = product_name ?: "",
            "product_code" = product_code ?: "",
            "stock_code"   = stock_code   ?: "",
            "barcod"       = barcod       ?: ""
        })>
    </cfloop>

    <cfset result = {"success": true, "shelf": shelfData, "rows": rowsArr}>
    <cfoutput>#serializeJSON(result)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
