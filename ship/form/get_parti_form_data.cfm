<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cftry>
    <cfset shipId = isDefined("url.ship_id") AND isNumeric(url.ship_id) ? val(url.ship_id) : 0>
    <cfif shipId lte 0>
        <cfoutput>{"success":false,"message":"ship_id gerekli"}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="getShip" datasource="boyahane">
        SELECT s.ship_id, s.ship_number, s.company_id, s.hk_metre
        FROM ship s
        WHERE s.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif NOT getShip.recordCount>
        <cfoutput>{"success":false,"message":"Kayıt bulunamadı"}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="getShipRow" datasource="boyahane">
        SELECT sr.ship_row_id, sr.stock_id, sr.product_id,
               sr.name_product, sr.amount, sr.amount2, sr.unit, sr.unit_id
        FROM ship_row sr
        WHERE sr.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
        ORDER BY sr.ship_row_id
        LIMIT 1
    </cfquery>

    <cfquery name="countParts" datasource="boyahane">
        SELECT COUNT(*) AS c FROM orders
        WHERE ref_ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
           OR (ref_ship_id IS NULL AND ref_no IS NOT NULL AND ref_no <> ''
               AND ref_no = <cfqueryparam value="#getShip.ship_number#" cfsqltype="cf_sql_varchar">)
    </cfquery>

    <cfset nextPartiNo = val(countParts.c) + 1>
    <cfset partiKodu   = getShip.ship_number & "-P" & nextPartiNo>

    <cfset result = {
        "success":       true,
        "ship_number":   getShip.ship_number  ?: "",
        "company_id":    val(getShip.company_id),
        "hk_metre":      isNumeric(getShip.hk_metre) ? val(getShip.hk_metre) : 0,
        "parti_kodu":    partiKodu,
        "next_parti_no": nextPartiNo,
        "stock_id":      getShipRow.recordCount ? val(getShipRow.stock_id  ?: 0)  : 0,
        "product_id":    getShipRow.recordCount ? val(getShipRow.product_id ?: 0) : 0,
        "product_name":  getShipRow.recordCount ? (getShipRow.name_product ?: "") : "",
        "unit":          getShipRow.recordCount ? (getShipRow.unit ?: "mt")       : "mt",
        "unit_id":       getShipRow.recordCount ? val(getShipRow.unit_id ?: 0)    : 0
    }>

    <cfoutput>#serializeJSON(result)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":"Hata: #jsStringFormat(cfcatch.message)#"}</cfoutput>
    </cfcatch>
</cftry>
