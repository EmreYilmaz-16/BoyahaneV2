<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfparam name="url.price_catid" default="0">
    <cfset catId = val(url.price_catid)>

    <cfif catId lte 0>
        <cfoutput>#serializeJSON([])#</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="getPrices" datasource="boyahane">
        SELECT
            pr.price_id,
            pr.product_id,
            pr.stock_id,
            pr.price,
            pr.price_kdv,
            pr.is_kdv,
            p.tax,
            pr.price_discount,
            pr.unit,
            pr.money,
            pr.startdate,
            pr.finishdate,
            p.product_name,
            p.product_code,
            p.barcod AS product_barcod,
            s.stock_code,
            s.barcod AS stock_barcod,
            s.property
        FROM price pr
        LEFT JOIN product p ON pr.product_id = p.product_id
        LEFT JOIN stocks  s ON pr.stock_id   = s.stock_id
        WHERE pr.price_catid = <cfqueryparam value="#catId#" cfsqltype="cf_sql_integer">
        ORDER BY p.product_name, s.stock_code
    </cfquery>

    <cfset result = []>
    <cfloop query="getPrices">
        <cfset displayName = (product_name ?: "") & (len(stock_code) ? " [" & stock_code & "]" : "")>
        <cfset arrayAppend(result, {
            "price_id":       price_id,
            "product_id":     product_id ?: 0,
            "stock_id":       stock_id ?: 0,
            "product_name":   displayName,
            "product_code":   product_code ?: "",
            "stock_code":     stock_code ?: "",
            "barcod":         len(stock_barcod) ? stock_barcod : (product_barcod ?: ""),
            "property":       property ?: "",
            "price":          isNumeric(price) ? price : 0,
            "price_kdv":      isNumeric(price_kdv) ? price_kdv : 0,
            "is_kdv":         is_kdv,
            "tax":            isNumeric(tax) ? tax : 0,
            "price_discount": isNumeric(price_discount) ? price_discount : 0,
            "money":          money ?: "",
            "startdate":      isDate(startdate)  ? dateFormat(startdate,  "yyyy-mm-dd") : "",
            "finishdate":     isDate(finishdate) ? dateFormat(finishdate, "yyyy-mm-dd") : ""
        })>
    </cfloop>

    <cfoutput>#serializeJSON(result)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON([])#</cfoutput>
    </cfcatch>
</cftry>
