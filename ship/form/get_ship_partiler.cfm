<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cftry>
    <cfset shipId = isDefined("url.ship_id") AND isNumeric(url.ship_id) ? val(url.ship_id) : 0>
    <cfif shipId lte 0>
        <cfoutput>{"success":false,"message":"ship_id gerekli"}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="getPartiler" datasource="boyahane">
        SELECT o.order_id, o.order_number, o.order_stage, o.order_date, o.record_date,
               o.nettotal, o.grosstotal,
               COALESCE((
                   SELECT SUM(orw2.quantity)
                   FROM order_row orw2
                   JOIN stocks st2  ON orw2.stock_id  = st2.stock_id
                   JOIN product p2  ON st2.product_id = p2.product_id
                   WHERE orw2.order_id = o.order_id
                     AND COALESCE(p2.is_ek_islem, false) = false
                     AND COALESCE(LOWER(TRIM(orw2.unit)), '') <> 'kg'
               ), 0) AS ana_miktar
        FROM orders o
        JOIN ship s ON s.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
        WHERE o.ref_ship_id = s.ship_id
           OR (o.ref_ship_id IS NULL AND o.ref_no IS NOT NULL AND o.ref_no <> '' AND o.ref_no = s.ship_number)
        ORDER BY o.order_id
    </cfquery>

    <cfset result = []>
    <cfloop query="getPartiler">
        <cfset stageLabel = "">
        <cfswitch expression="#val(order_stage)#">
            <cfcase value="1"><cfset stageLabel = "Beklemede"></cfcase>
            <cfcase value="2"><cfset stageLabel = "Onaylandı"></cfcase>
            <cfcase value="3"><cfset stageLabel = "Üretimde"></cfcase>
            <cfcase value="4"><cfset stageLabel = "Hazır"></cfcase>
            <cfcase value="5"><cfset stageLabel = "Sevk Edildi"></cfcase>
            <cfcase value="6"><cfset stageLabel = "Tamamlandı"></cfcase>
            <cfcase value="7"><cfset stageLabel = "Renkli"></cfcase>
            <cfdefaultcase><cfset stageLabel = "Bilinmiyor"></cfdefaultcase>
        </cfswitch>
        <cfset arrayAppend(result, {
            "order_id":    val(order_id),
            "ship_id":     shipId,
            "order_number": order_number ?: "",
            "order_stage": val(order_stage),
            "stage_label": stageLabel,
            "order_date":  isDate(order_date)  ? dateFormat(order_date,  "dd/mm/yyyy") : "",
            "record_date": isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") : "",
            "ana_miktar":  isNumeric(ana_miktar) ? val(ana_miktar) : 0,
            "nettotal":    isNumeric(nettotal)   ? val(nettotal)   : 0
        })>
    </cfloop>

    <cfoutput>{"success":true,"data":#serializeJSON(result)#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
