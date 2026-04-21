<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "products": [], "message": "" }>
<cftry>
    <cfparam name="url.ship_id" default="0">
    <cfset shipId = isNumeric(url.ship_id) AND val(url.ship_id) gt 0 ? val(url.ship_id) : 0>

    <cfif shipId eq 0>
        <cfset response.message = "Geçersiz irsaliye ID">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery name="getRows" datasource="boyahane">
        SELECT sr.ship_row_id,
               COALESCE(sr.product_id, 0)                      AS product_id,
               COALESCE(p.product_name, sr.name_product, '')    AS product_name,
               COALESCE(p.product_code, '')                     AS product_code,
               COALESCE(p.product_catid, 0)                     AS product_catid,
               COALESCE(pc.product_cat, '')                     AS product_cat_name,
               COALESCE(sr.amount::text, '0')                   AS amount,
               COALESCE(sr.unit, '')                            AS unit,
               COALESCE(sr.lot_no, '')                          AS lot_no
        FROM ship_row sr
        LEFT JOIN product      p  ON sr.product_id  = p.product_id
        LEFT JOIN product_cat  pc ON p.product_catid = pc.product_catid
        WHERE sr.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
        ORDER BY sr.ship_row_id
    </cfquery>

    <cfset productsArr = []>
    <cfloop query="getRows">
        <cfset arrayAppend(productsArr, {
            "ship_row_id"    : val(ship_row_id),
            "product_id"     : val(product_id),
            "product_name"   : product_name ?: "",
            "product_code"   : product_code ?: "",
            "product_catid"  : val(product_catid),
            "product_cat_name": product_cat_name ?: "",
            "amount"         : isNumeric(amount) ? val(amount) : 0,
            "unit"           : unit ?: "",
            "lot_no"         : lot_no ?: "",
            "display"        : product_code & (len(product_code) ? " - " : "") & product_name &
                               (isNumeric(amount) AND val(amount) gt 0 ? " (" & numberFormat(val(amount),"0.##") & " " & unit & ")" : "")
        })>
    </cfloop>

    <cfset response.success  = true>
    <cfset response.products = productsArr>
<cfcatch type="any">
    <cfset response.message = cfcatch.message>
</cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
<cfabort>
