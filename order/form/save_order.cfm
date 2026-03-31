<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <!--- Params --->
    <cfparam name="form.order_id"       default="0">
    <cfparam name="form.purchase_sales" default="true">
    <cfparam name="form.order_stage"    default="1">
    <cfparam name="form.order_number"   default="">
    <cfparam name="form.order_head"     default="">
    <cfparam name="form.ref_no"         default="">
    <cfparam name="form.order_detail"   default="">
    <cfparam name="form.order_date"     default="">
    <cfparam name="form.deliverdate"    default="">
    <cfparam name="form.company_id"     default="0">
    <cfparam name="form.paymethod"      default="0">
    <cfparam name="form.ship_method"    default="0">
    <cfparam name="form.order_currency" default="0">
    <cfparam name="form.order_status"   default="0">
    <cfparam name="form.member_type"    default="0">
    <cfparam name="form.ref_company_id" default="0">
    <cfparam name="form.rows"           default="[]">

    <cfset orderId      = val(form.order_id)>
    <cfset companyId    = val(form.company_id)>
    <cfset memberTypeVal = val(form.member_type)>
    <cfset refCompanyIdVal = val(form.ref_company_id)>
    <cfset orderStage   = val(form.order_stage)>
    <cfset paymethodVal = val(form.paymethod)>
    <cfset shipMethodVal= val(form.ship_method)>
    <cfset currencyVal  = val(form.order_currency)>
    <cfset editMode     = orderId gt 0>

    <!--- Parti ekranından kayıt gelirken company_id boş gelebilirse irsaliyeden tamamla --->
    <cfif companyId lte 0 AND len(trim(form.ref_no))>
        <cfquery name="getShipCompany" datasource="boyahane">
            SELECT company_id
            FROM ship
            WHERE ship_number = <cfqueryparam value="#trim(form.ref_no)#" cfsqltype="cf_sql_varchar">
            ORDER BY ship_id DESC
            LIMIT 1
        </cfquery>
        <cfif getShipCompany.recordCount AND isNumeric(getShipCompany.company_id)>
            <cfset companyId = val(getShipCompany.company_id)>
        </cfif>
    </cfif>

    <cfif companyId gt 0>
        <cfif memberTypeVal lte 0><cfset memberTypeVal = 3></cfif>
        <cfif refCompanyIdVal lte 0><cfset refCompanyIdVal = companyId></cfif>
    </cfif>

    <cfif companyId lte 0>
        <cfoutput>#serializeJSON({"success": false, "message": "Firma seçilmeden kayıt yapılamaz."})#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Satırları parse et --->
    <cfset rowsJson = form.rows>
    <cftry>
        <cfset rowsData = deserializeJSON(rowsJson)>
        <cfcatch type="any">
            <cfset rowsData = []>
        </cfcatch>
    </cftry>

    <cfif NOT isArray(rowsData) OR arrayLen(rowsData) eq 0>
        <cfoutput>#serializeJSON({"success": false, "message": "En az bir ürün satırı gereklidir."})#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Toplamları hesapla --->
    <cfset totalGross    = 0>
    <cfset totalDiscount = 0>
    <cfset totalTax      = 0>
    <cfset totalNet      = 0>

    <cfloop array="#rowsData#" item="row">
        <cfset rQty  = isNumeric(row.quantity)   ? row.quantity   : 0>
        <cfset rPrc  = isNumeric(row.price)      ? row.price      : 0>
        <cfset rTax  = isNumeric(row.tax)        ? row.tax        : 0>
        <cfset rDisc = isNumeric(row.discount_1) ? row.discount_1 : 0>
        <cfset rGross = rQty * rPrc>
        <cfset rDiscAmt = rGross * (rDisc / 100)>
        <cfset rTaxAmt  = (rGross - rDiscAmt) * (rTax / 100)>
        <cfset totalGross    += rGross>
        <cfset totalDiscount += rDiscAmt>
        <cfset totalTax      += rTaxAmt>
        <cfset totalNet      += (rGross - rDiscAmt + rTaxAmt)>
    </cfloop>

    <!--- Tarih yardımcıları --->
    <cfset nowTS = now()>
    <cfset orderDateVal   = (len(trim(form.order_date))   gt 0 AND isDate(form.order_date))   ? parseDateTime(form.order_date)   : nowTS>
    <cfset hasDeliverDate = (len(trim(form.deliverdate)) gt 0 AND isDate(form.deliverdate))>
    <cfif hasDeliverDate><cfset deliverDateVal = parseDateTime(form.deliverdate)></cfif>

    <!--- INSERT / UPDATE --->
    <cfif editMode>
        <!--- UPDATE --->
        <cfquery datasource="boyahane">
            UPDATE orders SET
                purchase_sales  = <cfqueryparam value="#form.purchase_sales eq 'true' OR form.purchase_sales eq true#" cfsqltype="cf_sql_boolean">,
                order_stage     = <cfqueryparam value="#orderStage#" cfsqltype="cf_sql_integer">,
                order_number    = <cfqueryparam value="#trim(form.order_number)#" cfsqltype="cf_sql_varchar">,
                order_head      = <cfqueryparam value="#trim(form.order_head)#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.order_head))#">,
                order_detail    = <cfqueryparam value="#trim(form.order_detail)#" cfsqltype="cf_sql_longvarchar" null="#NOT len(trim(form.order_detail))#">,
                ref_no          = <cfqueryparam value="#trim(form.ref_no)#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.ref_no))#">,
                order_date      = <cfqueryparam value="#orderDateVal#" cfsqltype="cf_sql_timestamp">,
                deliverdate     = <cfqueryparam value="#hasDeliverDate ? deliverDateVal : ''#" cfsqltype="cf_sql_timestamp" null="#NOT hasDeliverDate#">,
                company_id      = <cfqueryparam value="#companyId#" cfsqltype="cf_sql_integer">,
                member_type     = <cfqueryparam value="#memberTypeVal#" cfsqltype="cf_sql_integer" null="#memberTypeVal eq 0#">,
                ref_company_id  = <cfqueryparam value="#refCompanyIdVal#" cfsqltype="cf_sql_integer" null="#refCompanyIdVal eq 0#">,
                paymethod       = <cfqueryparam value="#paymethodVal#" cfsqltype="cf_sql_integer" null="#paymethodVal eq 0#">,
                ship_method     = <cfqueryparam value="#shipMethodVal#" cfsqltype="cf_sql_integer" null="#shipMethodVal eq 0#">,
                order_currency  = <cfqueryparam value="#currencyVal#" cfsqltype="cf_sql_integer" null="#currencyVal eq 0#">,
                order_status    = <cfqueryparam value="#form.order_status eq '1' OR form.order_status eq true#" cfsqltype="cf_sql_boolean">,
                grosstotal      = <cfqueryparam value="#totalGross#" cfsqltype="cf_sql_numeric">,
                discounttotal   = <cfqueryparam value="#totalDiscount#" cfsqltype="cf_sql_numeric">,
                taxtotal        = <cfqueryparam value="#totalTax#" cfsqltype="cf_sql_numeric">,
                nettotal        = <cfqueryparam value="#totalNet#" cfsqltype="cf_sql_numeric">,
                update_date     = <cfqueryparam value="#nowTS#" cfsqltype="cf_sql_timestamp">
            WHERE order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
        </cfquery>

    <cfelse>
        <!--- INSERT --->
        <cfquery datasource="boyahane" result="insertResult">
            INSERT INTO orders (
                purchase_sales, order_stage, order_number, order_head, order_detail, ref_no,
                order_date, deliverdate, company_id, member_type, ref_company_id, paymethod, ship_method, order_currency,
                order_status, grosstotal, discounttotal, taxtotal, nettotal, record_date
            ) VALUES (
                <cfqueryparam value="#form.purchase_sales eq 'true' OR form.purchase_sales eq true#" cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#orderStage#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#trim(form.order_number)#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#trim(form.order_head)#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.order_head))#">,
                <cfqueryparam value="#trim(form.order_detail)#" cfsqltype="cf_sql_longvarchar" null="#NOT len(trim(form.order_detail))#">,
                <cfqueryparam value="#trim(form.ref_no)#" cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.ref_no))#">,
                <cfqueryparam value="#orderDateVal#" cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#hasDeliverDate ? deliverDateVal : ''#" cfsqltype="cf_sql_timestamp" null="#NOT hasDeliverDate#">,
                <cfqueryparam value="#companyId#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#memberTypeVal#" cfsqltype="cf_sql_integer" null="#memberTypeVal eq 0#">,
                <cfqueryparam value="#refCompanyIdVal#" cfsqltype="cf_sql_integer" null="#refCompanyIdVal eq 0#">,
                <cfqueryparam value="#paymethodVal#" cfsqltype="cf_sql_integer" null="#paymethodVal eq 0#">,
                <cfqueryparam value="#shipMethodVal#" cfsqltype="cf_sql_integer" null="#shipMethodVal eq 0#">,
                <cfqueryparam value="#currencyVal#" cfsqltype="cf_sql_integer" null="#currencyVal eq 0#">,
                <cfqueryparam value="#form.order_status eq '1' OR form.order_status eq true#" cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#totalGross#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#totalDiscount#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#totalTax#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#totalNet#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#nowTS#" cfsqltype="cf_sql_timestamp">
            )
            RETURNING order_id
        </cfquery>

        <cfset orderId = insertResult.GENERATEDKEY ?: 0>

        <cfif NOT orderId>
            <cfquery name="getNewId" datasource="boyahane">
                SELECT currval(pg_get_serial_sequence('orders','order_id')) AS new_id
            </cfquery>
            <cfset orderId = val(getNewId.new_id)>
        </cfif>
    </cfif>

    <!--- Mevcut satırları sil ve yeniden yaz --->
    <cfquery datasource="boyahane">
        DELETE FROM order_row WHERE order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfloop array="#rowsData#" item="row">
        <cfset rStockId   = isNumeric(row.stock_id)   ? val(row.stock_id)   : 0>
        <cfset rProductId = isNumeric(row.product_id) ? val(row.product_id) : 0>
        <cfset rProdName  = isDefined("row.product_name") ? trim(row.product_name) : "">
        <cfset rProdCode  = isDefined("row.product_code") ? trim(row.product_code) : "">
        <cfset rQty       = isNumeric(row.quantity)   ? row.quantity   : 0>
        <cfset rPrc       = isNumeric(row.price)      ? row.price      : 0>
        <cfset rTaxR      = isNumeric(row.tax)        ? row.tax        : 0>
        <cfset rDisc1     = isNumeric(row.discount_1) ? row.discount_1 : 0>
        <cfset rUnit      = isDefined("row.unit")     ? trim(row.unit)     : "">
        <cfset rUnitId    = isNumeric(row.unit_id)    ? val(row.unit_id)   : 0>
        <cfset rLotNo     = isDefined("row.lot_no")   ? trim(row.lot_no)   : "">

        <cfset rGross   = rQty * rPrc>
        <cfset rDiscAmt = rGross * (rDisc1 / 100)>
        <cfset rTaxAmt  = (rGross - rDiscAmt) * (rTaxR / 100)>
        <cfset rNet     = rGross - rDiscAmt + rTaxAmt>

        <cfquery datasource="boyahane">
            INSERT INTO order_row (
                order_id, stock_id, product_id, product_name, product_name2,
                quantity, price, unit, unit_id, tax, discount_1, nettotal, lot_no
            ) VALUES (
                <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#rStockId#" cfsqltype="cf_sql_integer" null="#rStockId eq 0#">,
                <cfqueryparam value="#rProductId#" cfsqltype="cf_sql_integer" null="#rProductId eq 0#">,
                <cfqueryparam value="#rProdName#" cfsqltype="cf_sql_varchar" null="#NOT len(rProdName)#">,
                <cfqueryparam value="#rProdCode#" cfsqltype="cf_sql_varchar" null="#NOT len(rProdCode)#">,
                <cfqueryparam value="#rQty#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rPrc#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rUnit#" cfsqltype="cf_sql_varchar" null="#NOT len(rUnit)#">,
                <cfqueryparam value="#rUnitId#" cfsqltype="cf_sql_integer" null="#rUnitId eq 0#">,
                <cfqueryparam value="#rTaxR#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rDisc1#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rNet#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rLotNo#" cfsqltype="cf_sql_varchar" null="#NOT len(rLotNo)#">
            )
        </cfquery>
    </cfloop>

    <cfoutput>#serializeJSON({"success": true, "order_id": orderId})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success": false, "message": cfcatch.message & " " & cfcatch.detail})#</cfoutput>
    </cfcatch>
</cftry>
