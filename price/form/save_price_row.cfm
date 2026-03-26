<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfparam name="form.price_id"       default="0">
    <cfparam name="form.price_catid"    default="0">
    <cfparam name="form.product_id"     default="0">
    <cfparam name="form.stock_id"       default="0">
    <cfparam name="form.price"          default="0">
    <cfparam name="form.tax"            default="0">
    <cfparam name="form.price_discount" default="0">
    <cfparam name="form.startdate"      default="">
    <cfparam name="form.finishdate"     default="">

    <cfset priceId    = val(form.price_id)>
    <cfset catId      = val(form.price_catid)>
    <cfset productId  = val(form.product_id)>
    <cfset stockId    = val(form.stock_id)>
    <cfset priceVal   = val(form.price)>
    <cfset taxVal     = val(form.tax)>
    <cfset priceKdv   = priceVal * (1 + taxVal / 100)>
    <cfset discountV  = val(form.price_discount)>
    <cfset nowTS      = now()>

    <cfif catId lte 0>
        <cfoutput>#serializeJSON({"success": false, "message": "Geçersiz fiyat listesi."})#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Tarihler --->
    <cfset hasStartDate  = (len(trim(form.startdate))  gt 0 AND isDate(form.startdate))>
    <cfset hasFinishDate = (len(trim(form.finishdate)) gt 0 AND isDate(form.finishdate))>
    <cfif hasStartDate><cfset startDateV  = parseDateTime(form.startdate)></cfif>
    <cfif hasFinishDate><cfset finishDateV = parseDateTime(form.finishdate)></cfif>

    <cfif priceId gt 0>
        <!--- UPDATE mevcut satır --->
        <cfquery datasource="boyahane">
            UPDATE price SET
                price          = <cfqueryparam value="#priceVal#"  cfsqltype="cf_sql_numeric">,
                price_kdv      = <cfqueryparam value="#priceKdv#"  cfsqltype="cf_sql_numeric">,
                price_discount = <cfqueryparam value="#discountV#" cfsqltype="cf_sql_numeric">
                <cfif hasStartDate>,
                startdate      = <cfqueryparam value="#startDateV#" cfsqltype="cf_sql_timestamp"></cfif>
                ,
                finishdate     = <cfqueryparam value="#hasFinishDate ? finishDateV : ''#" cfsqltype="cf_sql_timestamp" null="#NOT hasFinishDate#">
            WHERE price_id = <cfqueryparam value="#priceId#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfoutput>#serializeJSON({"success": true, "price_id": priceId})#</cfoutput>
    <cfelse>
        <!--- INSERT yeni satır --->
        <cfif productId lte 0 AND stockId lte 0>
            <cfoutput>#serializeJSON({"success": false, "message": "Ürün veya stok seçilmedi."})#</cfoutput>
            <cfabort>
        </cfif>

        <!--- Aynı price_catid + stock_id varsa güncelle --->
        <cfif stockId gt 0>
            <cfquery name="chkExist" datasource="boyahane">
                SELECT price_id FROM price
                WHERE price_catid = <cfqueryparam value="#catId#"     cfsqltype="cf_sql_integer">
                  AND stock_id    = <cfqueryparam value="#stockId#"   cfsqltype="cf_sql_integer">
                LIMIT 1
            </cfquery>
            <cfif chkExist.recordCount>
                <cfquery datasource="boyahane">
                    UPDATE price SET
                        price          = <cfqueryparam value="#priceVal#"  cfsqltype="cf_sql_numeric">,
                        price_kdv      = <cfqueryparam value="#priceKdv#"  cfsqltype="cf_sql_numeric">,
                        price_discount = <cfqueryparam value="#discountV#" cfsqltype="cf_sql_numeric">
                        <cfif hasStartDate>,
                        startdate      = <cfqueryparam value="#startDateV#" cfsqltype="cf_sql_timestamp"></cfif>
                        ,
                        finishdate     = <cfqueryparam value="#hasFinishDate ? finishDateV : ''#" cfsqltype="cf_sql_timestamp" null="#NOT hasFinishDate#">
                    WHERE price_id = <cfqueryparam value="#chkExist.price_id#" cfsqltype="cf_sql_integer">
                </cfquery>
                <cfoutput>#serializeJSON({"success": true, "price_id": chkExist.price_id, "updated": true})#</cfoutput>
                <cfabort>
            </cfif>
        </cfif>

        <cfquery datasource="boyahane" result="ins">
            INSERT INTO price (
                price_catid, product_id, stock_id, price, price_kdv, is_kdv,
                price_discount, unit, money, startdate, finishdate, record_date
            ) VALUES (
                <cfqueryparam value="#catId#"     cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#productId#" cfsqltype="cf_sql_integer" null="#productId eq 0#">,
                <cfqueryparam value="#stockId#"   cfsqltype="cf_sql_integer" null="#stockId eq 0#">,
                <cfqueryparam value="#priceVal#"  cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#priceKdv#"  cfsqltype="cf_sql_numeric">,
                true,
                <cfqueryparam value="#discountV#" cfsqltype="cf_sql_numeric">,
                0,
                '',
                <cfqueryparam value="#hasStartDate ? startDateV : nowTS#" cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#hasFinishDate ? finishDateV : ''#" cfsqltype="cf_sql_timestamp" null="#NOT hasFinishDate#">,
                <cfqueryparam value="#nowTS#"      cfsqltype="cf_sql_timestamp">
            )
            RETURNING price_id
        </cfquery>

        <cfset newId = ins.GENERATEDKEY ?: 0>
        <cfoutput>#serializeJSON({"success": true, "price_id": newId})#</cfoutput>
    </cfif>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success": false, "message": cfcatch.message & " " & cfcatch.detail})#</cfoutput>
    </cfcatch>
</cftry>
