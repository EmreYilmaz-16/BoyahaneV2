<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8" reset="true">
<cfsetting showdebugoutput="false">
<cfparam name="url.barcode" default="">
<cfparam name="form.barcode" default="#url.barcode#">
<cfset barcode = trim(form.barcode)>
<cfset barcodeOrderId = isNumeric(barcode) ? val(barcode) : 0>
<cfif NOT len(barcode)>
    <cfoutput>#serializeJSON({"success":false,"message":"Barkod boş olamaz."})#</cfoutput><cfabort>
</cfif>
<cftry>
    <cfquery name="getParti" datasource="boyahane">
        SELECT o.order_id, o.order_number, o.order_head, o.company_id, o.ref_ship_id, o.ref_no,
               COALESCE(c.nickname, c.fullname, '') AS company_name,
               COALESCE(SUM(CASE WHEN LOWER(TRIM(orw.unit)) IN ('mt','metre','m') THEN orw.quantity ELSE 0 END), 0) AS parti_metre,
               COALESCE(SUM(CASE WHEN LOWER(TRIM(orw.unit)) = 'kg' THEN orw.quantity ELSE COALESCE(orw.amount2, 0) END), 0) AS parti_kg,
               COALESCE(MAX(o.top_adedi), 0) AS top_adedi,
               COALESCE(MAX(p.product_name), MAX(orw.product_name), '') AS product_name,
               COALESCE(MAX(st.stock_code), '') AS stock_code,
               COALESCE(s.hk_metre, 0) AS ship_metre,
               COALESCE(s.hk_kg, 0) AS ship_kg,
               COALESCE(s.hk_top_adedi, 0) AS ship_top_adedi
        FROM orders o
        LEFT JOIN order_row orw ON orw.order_id = o.order_id
        LEFT JOIN stocks st ON st.stock_id = orw.stock_id
        LEFT JOIN product p ON p.product_id = st.product_id
        LEFT JOIN company c ON c.company_id = o.company_id
        LEFT JOIN ship s ON s.ship_id = o.ref_ship_id
        WHERE o.order_number = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
           OR o.ref_no = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
           OR (<cfqueryparam value="#barcodeOrderId#" cfsqltype="cf_sql_integer"> > 0 AND o.order_id = <cfqueryparam value="#barcodeOrderId#" cfsqltype="cf_sql_integer">)
        GROUP BY o.order_id, o.order_number, o.order_head, o.company_id, o.ref_ship_id, o.ref_no, c.nickname, c.fullname, s.hk_metre, s.hk_kg, s.hk_top_adedi
        ORDER BY o.order_id DESC
        LIMIT 1
    </cfquery>
    <cfif NOT getParti.recordCount>
        <cfoutput>#serializeJSON({"success":false,"message":"Barkoda ait parti bulunamadı."})#</cfoutput><cfabort>
    </cfif>
    <cfset metre = val(getParti.parti_metre) GT 0 ? val(getParti.parti_metre) : val(getParti.ship_metre)>
    <cfset kg = val(getParti.parti_kg) GT 0 ? val(getParti.parti_kg) : val(getParti.ship_kg)>
    <cfset topAdedi = val(getParti.top_adedi) GT 0 ? val(getParti.top_adedi) : val(getParti.ship_top_adedi)>
    <cfset data = {
        "order_id": val(getParti.order_id),
        "ship_id": isNumeric(getParti.ref_ship_id) ? val(getParti.ref_ship_id) : 0,
        "parti_no": getParti.order_number ?: "",
        "parti_adi": getParti.order_head ?: "",
        "company_id": val(getParti.company_id),
        "company_name": getParti.company_name ?: "",
        "product_name": trim((getParti.product_name ?: "") & (len(getParti.stock_code ?: "") ? " - " & getParti.stock_code : "")),
        "metre": metre,
        "kg": kg,
        "top_adedi": topAdedi
    }>
    <cfoutput>#serializeJSON({"success":true,"data":data})#</cfoutput>
    <cfcatch><cfoutput>#serializeJSON({"success":false,"message":cfcatch.message})#</cfoutput></cfcatch>
</cftry>
