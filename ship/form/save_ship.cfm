
<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfif NOT isDefined("session.authenticated") OR NOT session.authenticated>
        <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Params --->
    <cfset ship_id      = isDefined("form.ship_id")      AND isNumeric(form.ship_id)      ? val(form.ship_id)      : 0>
    <cfset purchase_sales = isDefined("form.purchase_sales") AND form.purchase_sales eq "true" ? true : false>
    <cfset ship_type    = isDefined("form.ship_type")    AND isNumeric(form.ship_type)    ? val(form.ship_type)    : 1>
    <cfset ship_number  = isDefined("form.ship_number")  ? trim(form.ship_number)  : "">
    <cfset serial_number= isDefined("form.serial_number") ? trim(form.serial_number) : "">
    <cfset ship_date    = isDefined("form.ship_date")    AND isDate(form.ship_date)    ? form.ship_date    : now()>
    <cfset deliver_date = isDefined("form.deliver_date") AND isDate(form.deliver_date) ? form.deliver_date : "">
    <cfset company_id   = isDefined("form.company_id")   AND isNumeric(form.company_id)   AND val(form.company_id) gt 0 ? val(form.company_id) : javaCast("null","")>
    <cfset paymethod_id = isDefined("form.paymethod_id") AND isNumeric(form.paymethod_id) AND val(form.paymethod_id) gt 0 ? val(form.paymethod_id) : javaCast("null","")>
    <cfset ship_method  = isDefined("form.ship_method")  AND isNumeric(form.ship_method)  AND val(form.ship_method) gt 0 ? val(form.ship_method) : javaCast("null","")>
    <cfset location_in  = isDefined("form.location_in") AND isNumeric(form.location_in) AND val(form.location_in) gt 0 ? val(form.location_in) : javaCast("null","")>
    <cfset location_out = isDefined("form.location_out") AND isNumeric(form.location_out) AND val(form.location_out) gt 0 ? val(form.location_out) : javaCast("null","")>
    <cfset ship_status  = isDefined("form.ship_status")  AND isNumeric(form.ship_status)  ? val(form.ship_status)  : 1>
    <cfset ref_no       = isDefined("form.ref_no")       ? trim(form.ref_no)       : "">
    <cfset ship_detail  = isDefined("form.ship_detail")  ? trim(form.ship_detail)  : "">
    <cfset rowsJson     = isDefined("form.rows")         ? form.rows               : "[]">
    <!--- Ham Kumaş alanları — yalnızca ship_type=5 (Ham Kumaş Alış) için --->
    <cfif ship_type eq 5>
        <cfset hk_metre      = isDefined("form.hk_metre")      AND isNumeric(form.hk_metre)      ? val(form.hk_metre)      : "">
        <cfset hk_kg         = isDefined("form.hk_kg")         AND isNumeric(form.hk_kg)         ? val(form.hk_kg)         : "">
        <cfset hk_top_adedi  = isDefined("form.hk_top_adedi")  AND isNumeric(form.hk_top_adedi)  ? val(form.hk_top_adedi)  : "">
        <cfset hk_h_gramaj   = isDefined("form.hk_h_gramaj")   AND isNumeric(form.hk_h_gramaj)   ? val(form.hk_h_gramaj)   : "">
        <cfset hk_gr_mtul    = isDefined("form.hk_gr_mtul")    AND isNumeric(form.hk_gr_mtul)    ? val(form.hk_gr_mtul)    : "">
        <cfset hk_ucretli    = isDefined("form.hk_ucretli")    ? form.hk_ucretli eq "true"       : true>
        <cfset hk_ham_boyali = isDefined("form.hk_ham_boyali") ? form.hk_ham_boyali eq "true"    : true>
    <cfelse>
        <cfset hk_metre      = "">
        <cfset hk_kg         = "">
        <cfset hk_top_adedi  = "">
        <cfset hk_h_gramaj   = "">
        <cfset hk_gr_mtul    = "">
        <cfset hk_ucretli    = true>
        <cfset hk_ham_boyali = true>
    </cfif>

    <!--- Parse rows --->
    <cfset rows = deserializeJSON(rowsJson)>

    <!--- Calculate totals --->
    <cfset totalGross    = 0>
    <cfset totalDiscount = 0>
    <cfset totalNet      = 0>
    <cfset totalTax      = 0>
    <cfloop array="#rows#" index="row">
        <cfset totalGross    = totalGross    + (isNumeric(row.grosstotal)    ? row.grosstotal    : 0)>
        <cfset totalDiscount = totalDiscount + (isNumeric(row.discounttotal) ? row.discounttotal : 0)>
        <cfset totalNet      = totalNet      + (isNumeric(row.nettotal)      ? row.nettotal      : 0)>
        <cfset totalTax      = totalTax      + (isNumeric(row.taxtotal)      ? row.taxtotal      : 0)>
    </cfloop>

    <cfif ship_id gt 0>
        <!--- UPDATE --->
        <cfquery datasource="boyahane">
            UPDATE ship SET
                purchase_sales = <cfqueryparam value="#purchase_sales#" cfsqltype="cf_sql_bit">,
                ship_type      = <cfqueryparam value="#ship_type#"      cfsqltype="cf_sql_integer">,
                ship_number    = <cfqueryparam value="#ship_number#"    cfsqltype="cf_sql_varchar">,
                serial_number  = <cfqueryparam value="#serial_number#"  cfsqltype="cf_sql_varchar">,
                ship_date      = <cfqueryparam value="#ship_date#"       cfsqltype="cf_sql_timestamp">,
                deliver_date   = <cfif deliver_date neq ""><cfqueryparam value="#deliver_date#" cfsqltype="cf_sql_date"><cfelse>NULL</cfif>,
                company_id     = <cfif NOT isNull(company_id)><cfqueryparam value="#company_id#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                paymethod_id   = <cfif NOT isNull(paymethod_id)><cfqueryparam value="#paymethod_id#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                ship_method    = <cfif NOT isNull(ship_method)><cfqueryparam value="#ship_method#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                location_in    = <cfif NOT isNull(location_in)><cfqueryparam value="#location_in#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                deliver_store_id = <cfif NOT isNull(location_out)><cfqueryparam value="#location_out#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                ship_status    = <cfqueryparam value="#ship_status#"    cfsqltype="cf_sql_integer">,
                ref_no         = <cfqueryparam value="#ref_no#"         cfsqltype="cf_sql_varchar">,
                ship_detail    = <cfqueryparam value="#ship_detail#"    cfsqltype="cf_sql_longvarchar">,
                grosstotal     = <cfqueryparam value="#totalGross#"     cfsqltype="cf_sql_numeric">,
                discounttotal  = <cfqueryparam value="#totalDiscount#"  cfsqltype="cf_sql_numeric">,
                nettotal       = <cfqueryparam value="#totalNet#"       cfsqltype="cf_sql_numeric">,
                taxtotal       = <cfqueryparam value="#totalTax#"       cfsqltype="cf_sql_numeric">,
                hk_metre       = <cfqueryparam value="#val(hk_metre)#"     cfsqltype="cf_sql_double"  null="#NOT isNumeric(hk_metre)#">,
                hk_kg          = <cfqueryparam value="#val(hk_kg)#"        cfsqltype="cf_sql_double"  null="#NOT isNumeric(hk_kg)#">,
                hk_top_adedi   = <cfqueryparam value="#val(hk_top_adedi)#" cfsqltype="cf_sql_integer" null="#NOT isNumeric(hk_top_adedi)#">,
                hk_h_gramaj    = <cfqueryparam value="#val(hk_h_gramaj)#"  cfsqltype="cf_sql_double"  null="#NOT isNumeric(hk_h_gramaj)#">,
                hk_gr_mtul     = <cfqueryparam value="#val(hk_gr_mtul)#"   cfsqltype="cf_sql_double"  null="#NOT isNumeric(hk_gr_mtul)#">,
                hk_ucretli     = <cfqueryparam value="#hk_ucretli#"        cfsqltype="cf_sql_bit">,
                hk_ham_boyali  = <cfqueryparam value="#hk_ham_boyali#"     cfsqltype="cf_sql_bit">
            WHERE ship_id = <cfqueryparam value="#ship_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <!--- Delete old rows --->
        <cfquery datasource="boyahane">
            DELETE FROM ship_row WHERE ship_id = <cfqueryparam value="#ship_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <!--- İrsaliyeye ait eski stok hareketlerini sil (process_type 10-49 → yalnızca irsaliye, fiş kayıtlarına dokunma) --->
        <cfquery datasource="boyahane">
            DELETE FROM stocks_row
            WHERE upd_id      = <cfqueryparam value="#ship_id#" cfsqltype="cf_sql_integer">
              AND process_type BETWEEN 10 AND 49
        </cfquery>

    <cfelse>
        <!--- INSERT --->
        <cfquery datasource="boyahane">
            INSERT INTO ship (
                purchase_sales, ship_type, ship_number, serial_number,
                ship_date, deliver_date, company_id, paymethod_id, ship_method,
                location_in, deliver_store_id, ship_status, ref_no, ship_detail,
                grosstotal, discounttotal, nettotal, taxtotal,
                hk_metre, hk_kg, hk_top_adedi, hk_h_gramaj, hk_gr_mtul, hk_ucretli, hk_ham_boyali
            ) VALUES (
                <cfqueryparam value="#purchase_sales#" cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#ship_type#"      cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#ship_number#"    cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#serial_number#"  cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#ship_date#"       cfsqltype="cf_sql_timestamp">,
                <cfif deliver_date neq ""><cfqueryparam value="#deliver_date#" cfsqltype="cf_sql_date"><cfelse>NULL</cfif>,
                <cfif NOT isNull(company_id)><cfqueryparam value="#company_id#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                <cfif NOT isNull(paymethod_id)><cfqueryparam value="#paymethod_id#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                <cfif NOT isNull(ship_method)><cfqueryparam value="#ship_method#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                <cfif NOT isNull(location_in)><cfqueryparam value="#location_in#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                <cfif NOT isNull(location_out)><cfqueryparam value="#location_out#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                <cfqueryparam value="#ship_status#"   cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#ref_no#"         cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#ship_detail#"    cfsqltype="cf_sql_longvarchar">,
                <cfqueryparam value="#totalGross#"     cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#totalDiscount#"  cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#totalNet#"       cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#totalTax#"       cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#val(hk_metre)#"     cfsqltype="cf_sql_double"  null="#NOT isNumeric(hk_metre)#">,
                <cfqueryparam value="#val(hk_kg)#"        cfsqltype="cf_sql_double"  null="#NOT isNumeric(hk_kg)#">,
                <cfqueryparam value="#val(hk_top_adedi)#" cfsqltype="cf_sql_integer" null="#NOT isNumeric(hk_top_adedi)#">,
                <cfqueryparam value="#val(hk_h_gramaj)#"  cfsqltype="cf_sql_double"  null="#NOT isNumeric(hk_h_gramaj)#">,
                <cfqueryparam value="#val(hk_gr_mtul)#"   cfsqltype="cf_sql_double"  null="#NOT isNumeric(hk_gr_mtul)#">,
                <cfqueryparam value="#hk_ucretli#"        cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#hk_ham_boyali#"     cfsqltype="cf_sql_bit">
            )
        </cfquery>

        <cfquery name="getLastId" datasource="boyahane">SELECT lastval() AS new_id</cfquery>
        <cfset ship_id = getLastId.new_id>
    </cfif>

    <!--- Depo department_id'sini bir kez bul (tüm satırlar için ortak) --->
    <!--- process_type: ship_type*10 — Satış İrs.=10, Alış İrs.=20, İade=30, Ham Kumaş Alış=50 --->
    <cfset irsaliyeProcessType = ship_type * 10>
    <!--- İade durumunda hareket yönü tersine döner: Satış+İade=giriş, Alış+İade=çıkış --->
    <cfset isIade          = (ship_type eq 3)>
    <cfset isGirisHareketi = (NOT purchase_sales AND NOT isIade) OR (purchase_sales AND isIade)>
    <!--- Hareket yönüne göre ilgili deponun department_id'sini bul --->
    <cfset locDeptId = 0>
    <cfset locIdForDept = isGirisHareketi ? (NOT isNull(location_in) AND location_in gt 0 ? location_in : 0) : (NOT isNull(location_out) AND location_out gt 0 ? location_out : 0)>
    <cfif locIdForDept gt 0>
        <cfquery name="getLocDept" datasource="boyahane">
            SELECT department_id FROM stocks_location
            WHERE id = <cfqueryparam value="#locIdForDept#" cfsqltype="cf_sql_integer">
            LIMIT 1
        </cfquery>
        <cfif getLocDept.recordCount>
            <cfset locDeptId = val(getLocDept.department_id ?: 0)>
        </cfif>
    </cfif>

    <!--- Insert rows --->
    <cfloop array="#rows#" index="row">
        <cfset rProductId  = isNumeric(row.product_id)   AND row.product_id gt 0 ? val(row.product_id) : javaCast("null","")>
        <cfset rUnitId     = isNumeric(row.unit_id)      AND row.unit_id gt 0    ? val(row.unit_id)    : javaCast("null","")>
        <cfset rPrice      = isNumeric(row.price)        ? val(row.price)        : 0>
        <cfset rAmount     = isNumeric(row.amount)       ? val(row.amount)       : 0>
        <cfset rAmount2    = isDefined("row.amount2") AND isNumeric(row.amount2) ? val(row.amount2) : 0>
        <cfset rTax        = isNumeric(row.tax)          ? val(row.tax)          : 0>
        <cfset rDiscount   = isNumeric(row.discount)     ? val(row.discount)     : 0>
        <cfset rGross      = isNumeric(row.grosstotal)   ? val(row.grosstotal)   : 0>
        <cfset rDiscTot    = isNumeric(row.discounttotal) ? val(row.discounttotal): 0>
        <cfset rNet        = isNumeric(row.nettotal)     ? val(row.nettotal)     : 0>
        <cfset rTaxTot     = isNumeric(row.taxtotal)     ? val(row.taxtotal)     : 0>
        <cfset rLotNo      = isDefined("row.lot_no") AND row.lot_no neq "" ? row.lot_no : "">
        <!--- Raf: hareket yönüne göre giriş veya çıkış raf --->
        <cfset rShelfNumber = isGirisHareketi
            ? (isDefined("row.giris_raf_id") AND isNumeric(row.giris_raf_id) AND val(row.giris_raf_id) gt 0 ? val(row.giris_raf_id) : 0)
            : (isDefined("row.cikis_raf_id") AND isNumeric(row.cikis_raf_id) AND val(row.cikis_raf_id) gt 0 ? val(row.cikis_raf_id) : 0)>
        <!--- stock_id: önce row'dan al, yoksa product_id ile bul --->
        <cfset rStockId = isDefined("row.stock_id") AND isNumeric(row.stock_id) AND val(row.stock_id) gt 0 ? val(row.stock_id) : 0>

        <cfquery datasource="boyahane">
            INSERT INTO ship_row (
                ship_id, stock_id, product_id, name_product, price, amount, amount2, unit, unit_id,
                tax, discount, discounttotal, grosstotal, nettotal, taxtotal, lot_no, shelf_number
            ) VALUES (
                <cfqueryparam value="#ship_id#"                  cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#rStockId#"                 cfsqltype="cf_sql_integer" null="#rStockId eq 0#">,
                <cfif NOT isNull(rProductId)><cfqueryparam value="#rProductId#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                <cfqueryparam value="#row.name_product#"        cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#rPrice#"                  cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rAmount#"                 cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rAmount2#"                cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#row.unit ?: ''#"          cfsqltype="cf_sql_varchar">,
                <cfif NOT isNull(rUnitId)><cfqueryparam value="#rUnitId#" cfsqltype="cf_sql_integer"><cfelse>NULL</cfif>,
                <cfqueryparam value="#rTax#"                    cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rDiscount#"               cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rDiscTot#"                cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rGross#"                  cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rNet#"                    cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rTaxTot#"                 cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#rLotNo#"                  cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#rShelfNumber#"            cfsqltype="cf_sql_integer" null="#rShelfNumber eq 0#">
            )
        </cfquery>

        <!--- Stok hareketi (irsaliye — process_type: Satış=10 Alış=20 İade=30 Transfer=40, fiş kayıtları 1-9 ile karışmaz) --->
        <cfif NOT isNull(rProductId) AND rProductId gt 0>
            <!--- stock_id: row'dan zaten hesaplandı; 0 ise product_id ile bul --->
            <cfif rStockId eq 0>
                <cfquery name="getMainStock" datasource="boyahane">
                    SELECT stock_id FROM stocks
                    WHERE product_id = <cfqueryparam value="#rProductId#" cfsqltype="cf_sql_integer">
                    ORDER BY CASE WHEN is_main_stock = true THEN 0 ELSE 1 END, stock_id ASC
                    LIMIT 1
                </cfquery>
                <cfif getMainStock.recordCount AND val(getMainStock.stock_id) gt 0>
                    <cfset rStockId = val(getMainStock.stock_id)>
                </cfif>
            </cfif>
            <!--- Giriş/çıkış depo bağlı location ve shelf --->
            <cfset rLocIn  = NOT isNull(location_in)  AND location_in  gt 0 ? location_in  : 0>
            <cfset rLocOut = NOT isNull(location_out) AND location_out gt 0 ? location_out : 0>
            <!--- Hareket yönüne göre store_location --->
            <cfset rStoreLocation = isGirisHareketi ? rLocIn : rLocOut>
            <cfquery datasource="boyahane">
                INSERT INTO stocks_row (
                    stock_id, product_id, upd_id, process_type,
                    stock_in, stock_out, store, store_location, shelf_number,
                    process_date, lot_no, deliver_date
                ) VALUES (
                    <cfqueryparam value="#rStockId#"   cfsqltype="cf_sql_integer" null="#rStockId eq 0#">,
                    <cfqueryparam value="#rProductId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#ship_id#"    cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#irsaliyeProcessType#" cfsqltype="cf_sql_integer">,
                    <cfif isGirisHareketi><cfqueryparam value="#rAmount#" cfsqltype="cf_sql_double"><cfelse>0</cfif>,
                    <cfif NOT isGirisHareketi><cfqueryparam value="#rAmount#" cfsqltype="cf_sql_double"><cfelse>0</cfif>,
                    <cfqueryparam value="#locDeptId#"  cfsqltype="cf_sql_integer" null="#locDeptId eq 0#">,
                    <cfqueryparam value="#rStoreLocation#" cfsqltype="cf_sql_integer" null="#rStoreLocation eq 0#">,
                    <cfqueryparam value="#rShelfNumber#" cfsqltype="cf_sql_integer" null="#rShelfNumber eq 0#">,
                    <cfqueryparam value="#ship_date#"  cfsqltype="cf_sql_timestamp">,
                    <cfqueryparam value="#rLotNo#"     cfsqltype="cf_sql_varchar" null="#NOT len(rLotNo)#">,
                    <cfif deliver_date neq ""><cfqueryparam value="#deliver_date#" cfsqltype="cf_sql_date"><cfelse>NULL</cfif>
                )
            </cfquery>
        </cfif>
    </cfloop>

    <cfoutput>{"success":true,"ship_id":#ship_id#,"message":"İrsaliye kaydedildi."}</cfoutput>

    <cfcatch type="any">
        <cfdump var="#cfcatch#">
        <cfoutput>{"success":false,"message":<cfif isJSON(cfcatch.message)>#cfcatch.message#<cfelse>"#jsStringFormat(cfcatch.message)#"</cfif>}</cfoutput>
    </cfcatch>
</cftry>
