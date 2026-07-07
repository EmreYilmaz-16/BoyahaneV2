<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8" reset="true">
<cfsetting showdebugoutput="false">
<cfparam name="url.barcode" default="">
<cfparam name="form.barcode" default="#url.barcode#">
<cfset barcode = trim(form.barcode)>

<cfif NOT len(barcode)>
    <cfoutput>#serializeJSON({"success"=false,"message"="Top barkodu boş olamaz."})#</cfoutput><cfabort>
</cfif>

<cftry>
    <cfquery name="getRoll" datasource="boyahane">
        SELECT sr.roll_id, sr.plan_id, sr.order_id, sr.ship_id, sr.roll_no, sr.roll_barcode,
               sr.metre, sr.kg, sr.paket_durumu, sr.dispatch_ship_id, sr.dispatch_date,
               o.order_number,
               COALESCE(c.nickname, c.fullname, '') AS company_name,
               COALESCE((
                   SELECT orw.product_name
                   FROM order_row orw
                   LEFT JOIN stocks st ON orw.stock_id = st.stock_id
                   WHERE orw.order_id = sr.order_id
                     AND COALESCE(st.is_main_stock, true) = true
                   ORDER BY orw.order_row_id
                   LIMIT 1
               ), '') AS product_name,
               COALESCE(ds.ship_number, '') AS dispatch_ship_number
        FROM ship_roll sr
        LEFT JOIN orders o ON sr.order_id = o.order_id
        LEFT JOIN company c ON o.company_id = c.company_id
        LEFT JOIN ship ds ON sr.dispatch_ship_id = ds.ship_id
        WHERE sr.roll_barcode = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
        LIMIT 1
    </cfquery>

    <cfif NOT getRoll.recordCount>
        <cfoutput>#serializeJSON({"success"=false,"message"="Bu barkoda ait top bulunamadı."})#</cfoutput><cfabort>
    </cfif>

    <cfset isDispatched = len(trim(getRoll.paket_durumu ?: "")) AND lCase(trim(getRoll.paket_durumu)) EQ "sevk edildi">
    <cfset data = {
        "roll_id" = val(getRoll.roll_id),
        "plan_id" = val(getRoll.plan_id),
        "order_id" = val(getRoll.order_id),
        "source_ship_id" = isNumeric(getRoll.ship_id) ? val(getRoll.ship_id) : 0,
        "roll_no" = isNumeric(getRoll.roll_no) ? val(getRoll.roll_no) : 0,
        "roll_barcode" = getRoll.roll_barcode ?: "",
        "metre" = isNumeric(getRoll.metre) ? val(getRoll.metre) : 0,
        "kg" = isNumeric(getRoll.kg) ? val(getRoll.kg) : 0,
        "paket_durumu" = getRoll.paket_durumu ?: "",
        "is_dispatched" = isDispatched,
        "dispatch_ship_id" = isNumeric(getRoll.dispatch_ship_id) ? val(getRoll.dispatch_ship_id) : 0,
        "dispatch_ship_number" = getRoll.dispatch_ship_number ?: "",
        "dispatch_date" = isDate(getRoll.dispatch_date) ? dateFormat(getRoll.dispatch_date, "dd/mm/yyyy") & " " & timeFormat(getRoll.dispatch_date, "HH:mm") : "",
        "parti_no" = getRoll.order_number ?: "",
        "company_name" = getRoll.company_name ?: "",
        "product_name" = getRoll.product_name ?: ""
    }>
    <cfoutput>#serializeJSON({"success"=true,"data"=data})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success"=false,"message"=cfcatch.message,"detail"=cfcatch.detail})#</cfoutput>
    </cfcatch>
</cftry>
