<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset stockId    = isDefined("url.stock_id")    and isNumeric(url.stock_id)    ? val(url.stock_id)    : 0>
    <cfset locationId = isDefined("url.location_id") and isNumeric(url.location_id) ? val(url.location_id) : 0>

    <cfif stockId lte 0>
        <cfoutput>{"success":false,"message":"Geçersiz stok ID.","data":[]}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Ürüne/stoka tanımlı rafları getir; isteğe bağlı lokasyon filtresi --->
    <cfquery name="getShelves" datasource="boyahane">
        SELECT DISTINCT pp.product_place_id, pp.shelf_code, pp.place_status,
               sl.department_location, d.department_head
        FROM product_place pp
        JOIN product_place_rows ppr ON pp.product_place_id = ppr.product_place_id
        LEFT JOIN stocks_location sl ON pp.location_id = sl.id
        LEFT JOIN department d ON sl.department_id = d.department_id
        WHERE ppr.stock_id = <cfqueryparam value="#stockId#" cfsqltype="cf_sql_integer">
          AND pp.place_status = 1
          <cfif locationId gt 0>
          AND pp.location_id = <cfqueryparam value="#locationId#" cfsqltype="cf_sql_integer">
          </cfif>
        ORDER BY pp.shelf_code
    </cfquery>

    <cfset shelvesList = []>
    <cfloop query="getShelves">
        <cfset shelfLabel = (shelf_code ?: "")>
        <cfif len(trim(department_location ?: ""))>
            <cfset shelfLabel = shelfLabel & " — " & department_location>
        </cfif>
        <cfif len(trim(department_head ?: ""))>
            <cfset shelfLabel = shelfLabel & " (" & department_head & ")">
        </cfif>
        <cfset arrayAppend(shelvesList, {
            "product_place_id"   = product_place_id,
            "shelf_code"         = shelf_code ?: "",
            "department_location"= department_location ?: "",
            "department_head"    = department_head ?: "",
            "label"              = shelfLabel
        })>
    </cfloop>

    <cfoutput>#serializeJSON({"success": true, "data": shelvesList})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success": false, "message": cfcatch.message, "data": []})#</cfoutput>
    </cfcatch>
</cftry>
