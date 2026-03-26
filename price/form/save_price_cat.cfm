<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfparam name="form.price_catid"      default="0">
    <cfparam name="form.price_cat"        default="">
    <cfparam name="form.is_kdv"           default="0">
    <cfparam name="form.is_sales"         default="0">
    <cfparam name="form.is_purchase"      default="0">
    <cfparam name="form.price_cat_status" default="0">
    <cfparam name="form.money_id"         default="1">
    <cfparam name="form.paymethod"        default="0">
    <cfparam name="form.margin"           default="0">
    <cfparam name="form.discount"         default="0">
    <cfparam name="form.startdate"        default="">
    <cfparam name="form.finishdate"       default="">
    <cfparam name="form.rows"             default="[]">

    <cfset catId    = val(form.price_catid)>
    <cfset catName  = trim(form.price_cat)>
    <cfset editMode = catId gt 0>

    <cfif NOT len(catName)>
        <cfoutput>#serializeJSON({"success": false, "message": "Liste adı zorunludur."})#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Satırları parse et --->
    <cftry>
        <cfset rowsData = deserializeJSON(form.rows)>
        <cfcatch><cfset rowsData = []></cfcatch>
    </cftry>
    <cfif NOT isArray(rowsData)><cfset rowsData = []></cfif>

    <!--- Tarih yardımcıları --->
    <cfset nowTS       = now()>
    <cfset startDateV  = (len(trim(form.startdate))  gt 0 AND isDate(form.startdate))  ? parseDateTime(form.startdate)  : javacast("null","")>
    <cfset finishDateV = (len(trim(form.finishdate)) gt 0 AND isDate(form.finishdate)) ? parseDateTime(form.finishdate) : javacast("null","")>

    <cfset isKdvVal    = form.is_kdv eq "1" OR form.is_kdv eq true>
    <cfset isSalesVal  = form.is_sales eq "1" OR form.is_sales eq true>
    <cfset isPurchVal  = form.is_purchase eq "1" OR form.is_purchase eq true>
    <cfset statusVal   = form.price_cat_status eq "1" OR form.price_cat_status eq true>
    <cfset moneyIdVal  = val(form.money_id)  ?: 1>
    <cfset paymethVal  = val(form.paymethod) ?: 0>

    <cfif editMode>
        <!--- UPDATE --->
        <cfquery datasource="boyahane">
            UPDATE price_cat SET
                price_cat        = <cfqueryparam value="#catName#" cfsqltype="cf_sql_varchar">,
                price_cat_status = <cfqueryparam value="#statusVal#" cfsqltype="cf_sql_boolean">,
                is_kdv           = <cfqueryparam value="#isKdvVal#" cfsqltype="cf_sql_boolean">,
                is_sales         = <cfqueryparam value="#isSalesVal#" cfsqltype="cf_sql_integer">,
                is_purchase      = <cfqueryparam value="#isPurchVal#" cfsqltype="cf_sql_integer">,
                money_id         = <cfqueryparam value="#moneyIdVal#" cfsqltype="cf_sql_integer">,
                paymethod        = <cfqueryparam value="#paymethVal#" cfsqltype="cf_sql_integer" null="#paymethVal eq 0#">,
                margin           = <cfqueryparam value="#val(form.margin)#" cfsqltype="cf_sql_numeric">,
                discount         = <cfqueryparam value="#val(form.discount)#" cfsqltype="cf_sql_numeric">,
                startdate        = <cfqueryparam value="#startDateV#" cfsqltype="cf_sql_timestamp" null="#isNull(startDateV)#">,
                finishdate       = <cfqueryparam value="#finishDateV#" cfsqltype="cf_sql_timestamp" null="#isNull(finishDateV)#">,
                update_date      = <cfqueryparam value="#nowTS#" cfsqltype="cf_sql_timestamp">
            WHERE price_catid = <cfqueryparam value="#catId#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <!--- INSERT --->
        <cfquery datasource="boyahane" result="insertResult">
            INSERT INTO price_cat (
                price_cat, price_cat_status, is_kdv, is_sales, is_purchase,
                money_id, paymethod, margin, discount, startdate, finishdate, record_date
            ) VALUES (
                <cfqueryparam value="#catName#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#statusVal#" cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#isKdvVal#" cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#isSalesVal#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#isPurchVal#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#moneyIdVal#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#paymethVal#" cfsqltype="cf_sql_integer" null="#paymethVal eq 0#">,
                <cfqueryparam value="#val(form.margin)#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#val(form.discount)#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#startDateV#" cfsqltype="cf_sql_timestamp" null="#isNull(startDateV)#">,
                <cfqueryparam value="#finishDateV#" cfsqltype="cf_sql_timestamp" null="#isNull(finishDateV)#">,
                <cfqueryparam value="#nowTS#" cfsqltype="cf_sql_timestamp">
            )
            RETURNING price_catid
        </cfquery>

        <cfset catId = insertResult.GENERATEDKEY ?: 0>
        <cfif NOT catId>
            <cfquery name="getNewId" datasource="boyahane">
                SELECT currval(pg_get_serial_sequence('price_cat','price_catid')) AS new_id
            </cfquery>
            <cfset catId = val(getNewId.new_id)>
        </cfif>
    </cfif>

    <!--- Fiyat satırlarını sil ve yeniden yaz --->
    <cfquery datasource="boyahane">
        DELETE FROM price WHERE price_catid = <cfqueryparam value="#catId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfloop array="#rowsData#" item="row">
        <cfset rStockId   = isNumeric(row.stock_id)       ? val(row.stock_id)       : 0>
        <cfset rProductId = isNumeric(row.product_id)     ? val(row.product_id)     : 0>
        <cfset rPrice     = isNumeric(row.price)          ? row.price               : 0>
        <cfset rPriceKdv  = isNumeric(row.price_kdv)      ? row.price_kdv           : 0>
        <cfset rTax       = isNumeric(row.tax)            ? row.tax                 : 0>
        <cfset rDiscount  = isNumeric(row.price_discount) ? row.price_discount      : 0>
        <cfset rUnit      = isNumeric(row.unit)           ? val(row.unit)           : 0>
        <cfset rMoney     = isDefined("row.money")        ? trim(row.money)         : "">
        <cfset rIsKdv     = isDefined("row.is_kdv")       ? (row.is_kdv eq true OR row.is_kdv eq "true" OR row.is_kdv eq 1) : isKdvVal>
        <cfset rStartV    = (isDefined("row.startdate")  AND len(trim(row.startdate))  gt 0 AND isDate(row.startdate))  ? parseDateTime(row.startdate)  : javacast("null","")>
        <cfset rFinishV   = (isDefined("row.finishdate") AND len(trim(row.finishdate)) gt 0 AND isDate(row.finishdate)) ? parseDateTime(row.finishdate) : javacast("null","")>

        <cfif rProductId gt 0 OR rStockId gt 0>
            <cfquery datasource="boyahane">
                INSERT INTO price (
                    price_catid, product_id, stock_id, price, price_kdv, is_kdv, tax,
                    price_discount, unit, money, startdate, finishdate, record_date
                ) VALUES (
                    <cfqueryparam value="#catId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#rProductId#" cfsqltype="cf_sql_integer" null="#rProductId eq 0#">,
                    <cfqueryparam value="#rStockId#" cfsqltype="cf_sql_integer" null="#rStockId eq 0#">,
                    <cfqueryparam value="#rPrice#" cfsqltype="cf_sql_numeric">,
                    <cfqueryparam value="#rPriceKdv#" cfsqltype="cf_sql_numeric">,
                    <cfqueryparam value="#rIsKdv#" cfsqltype="cf_sql_boolean">,
                    <cfqueryparam value="#rTax#" cfsqltype="cf_sql_numeric">,
                    <cfqueryparam value="#rDiscount#" cfsqltype="cf_sql_numeric">,
                    <cfqueryparam value="#rUnit#" cfsqltype="cf_sql_integer" null="#rUnit eq 0#">,
                    <cfqueryparam value="#rMoney#" cfsqltype="cf_sql_varchar" null="#NOT len(rMoney)#">,
                    <cfqueryparam value="#rStartV#" cfsqltype="cf_sql_timestamp" null="#isNull(rStartV)#">,
                    <cfqueryparam value="#rFinishV#" cfsqltype="cf_sql_timestamp" null="#isNull(rFinishV)#">,
                    <cfqueryparam value="#nowTS#" cfsqltype="cf_sql_timestamp">
                )
            </cfquery>
        </cfif>
    </cfloop>

    <cfoutput>#serializeJSON({"success": true, "price_catid": catId})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success": false, "message": cfcatch.message & " " & cfcatch.detail})#</cfoutput>
    </cfcatch>
</cftry>
