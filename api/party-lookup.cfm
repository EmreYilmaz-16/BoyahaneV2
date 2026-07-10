<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8" reset="true">
<cfsetting showdebugoutput="false">
<cftry>
    <cfparam name="url.barcode" default="">
    <cfset barcode = trim(url.barcode)>
    <cfset barcodeOrderId = isNumeric(barcode) ? val(barcode) : 0>
    <cfif NOT len(barcode)><cfheader statuscode="400" statustext="Bad Request"><cfoutput>#serializeJSON({"success"=false,"message"="barcode gerekli."})#</cfoutput><cfabort></cfif>
    <cfquery name="getParti" datasource="boyahane">
        SELECT o.order_id, o.order_number, o.ref_no, o.order_head, o.main_color,
               COALESCE(c.nickname, c.fullname, '') AS customer_name,
               COALESCE(MAX(p.product_name), MAX(orw.product_name), '') AS product_name,
               COALESCE(MAX(st.stock_code), '') AS stock_code,
               o.ek_aciklama as kalite_talimati
        FROM orders o
        LEFT JOIN order_row orw ON orw.order_id = o.order_id
        LEFT JOIN stocks st ON st.stock_id = orw.stock_id
        LEFT JOIN product p ON p.product_id = st.product_id
        LEFT JOIN company c ON c.company_id = o.company_id
        WHERE o.order_number = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
           OR o.ref_no = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
           OR (<cfqueryparam value="#barcodeOrderId#" cfsqltype="cf_sql_integer"> > 0 AND o.order_id = <cfqueryparam value="#barcodeOrderId#" cfsqltype="cf_sql_integer">)
        GROUP BY o.order_id, o.order_number, o.ref_no, o.order_head, o.main_color, c.nickname, c.fullname
        ORDER BY o.order_id DESC
        LIMIT 1
    </cfquery>
    <cfif NOT getParti.recordCount><cfheader statuscode="404" statustext="Not Found"><cfoutput>#serializeJSON({"success"=false,"message"="Barkoda ait parti bulunamadı."})#</cfoutput><cfabort></cfif>
    <cfset kalite = len(trim(getParti.product_name ?: "")) ? getParti.product_name : getParti.stock_code>
    <cfoutput>#serializeJSON({"barcode"=barcode,"customer"=getParti.customer_name ?: "","party_no"=getParti.order_number ?: "","party_id"=toString(getParti.order_id),"sarj_no"=len(trim(getParti.ref_no ?: "")) ? getParti.ref_no : getParti.order_head,"kalite"=kalite,"renk"=getParti.main_color ?: "","kalite_talimati"=getParti.kalite_talimati ?: ""})#</cfoutput>
    <cfcatch type="any"><cfheader statuscode="500" statustext="Internal Server Error"><cfoutput>#serializeJSON({"success"=false,"message"=cfcatch.message})#</cfoutput></cfcatch>
</cftry>
