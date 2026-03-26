<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset locId = isDefined("url.loc_id") and isNumeric(url.loc_id) ? val(url.loc_id) : 0>

    <cfif locId lte 0>
        <cfoutput>[]</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="getShelves" datasource="boyahane">
        SELECT pp.product_place_id, pp.shelf_code, pp.place_status, pp.shelf_type,
               pp.quantity, pp.detail, pp.store_id, pp.product_id,
               pp.start_date, pp.finish_date,
               pp.width, pp.height, pp.depth,
               pp.x_coordinate, pp.y_coordinate, pp.z_coordinate,
               p.product_name, p.product_code,
               COUNT(ppr.product_place_row_id) AS row_count
        FROM product_place pp
        LEFT JOIN product_place_rows ppr ON pp.product_place_id = ppr.product_place_id
        LEFT JOIN product p ON pp.product_id = p.product_id
        WHERE pp.location_id = <cfqueryparam value="#locId#" cfsqltype="cf_sql_integer">
        GROUP BY pp.product_place_id, pp.shelf_code, pp.place_status, pp.shelf_type,
                 pp.quantity, pp.detail, pp.store_id, pp.product_id,
                 pp.start_date, pp.finish_date,
                 pp.width, pp.height, pp.depth,
                 pp.x_coordinate, pp.y_coordinate, pp.z_coordinate,
                 p.product_name, p.product_code
        ORDER BY pp.shelf_code
    </cfquery>

    <cfset arr = []>
    <cfloop query="getShelves">
        <cfset arrayAppend(arr, {
            "product_place_id" = product_place_id,
            "shelf_code"       = shelf_code ?: "",
            "place_status"     = place_status ?: 0,
            "shelf_type"       = shelf_type ?: 0,
            "quantity"         = quantity ?: 0,
            "detail"           = detail ?: "",
            "store_id"         = store_id ?: 0,
            "product_id"       = product_id ?: 0,
            "product_name"     = product_name ?: "",
            "product_code"     = product_code ?: "",
            "start_date"       = isDate(start_date)  ? dateFormat(start_date,  "yyyy-mm-dd") : "",
            "finish_date"      = isDate(finish_date)  ? dateFormat(finish_date, "yyyy-mm-dd") : "",
            "width"            = width  ?: 0,
            "height"           = height ?: 0,
            "depth"            = depth  ?: 0,
            "x_coordinate"     = x_coordinate ?: "",
            "y_coordinate"     = y_coordinate ?: "",
            "z_coordinate"     = z_coordinate ?: "",
            "row_count"        = row_count
        })>
    </cfloop>

    <cfoutput>#serializeJSON(arr)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"error":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
