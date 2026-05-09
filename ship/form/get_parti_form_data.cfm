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

    <!--- Ürün tekstil özellikleri --->
    <cfset tekstil = { "gramaj":"","en":"","kumas_tipi":"","tuse":"","isi":"","hiz":"","besleme_avans":"","cekme":"" }>
    <cfif getShipRow.recordCount AND val(getShipRow.product_id) gt 0>
        <cfquery name="getTekstil" datasource="boyahane">
            SELECT gramaj, en, kumas_tipi, tuse, isi, hiz, besleme_avans, cekme
            FROM product
            WHERE product_id = <cfqueryparam value="#val(getShipRow.product_id)#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif getTekstil.recordCount>
            <cfset tekstil = {
                "gramaj":        isNumeric(getTekstil.gramaj)        ? val(getTekstil.gramaj)        : "",
                "en":            isNumeric(getTekstil.en)            ? val(getTekstil.en)            : "",
                "kumas_tipi":    len(getTekstil.kumas_tipi    ?: "") ? getTekstil.kumas_tipi         : "",
                "tuse":          len(getTekstil.tuse          ?: "") ? getTekstil.tuse               : "",
                "isi":           isNumeric(getTekstil.isi)           ? val(getTekstil.isi)           : "",
                "hiz":           isNumeric(getTekstil.hiz)           ? val(getTekstil.hiz)           : "",
                "besleme_avans": isNumeric(getTekstil.besleme_avans) ? val(getTekstil.besleme_avans) : "",
                "cekme":         len(getTekstil.cekme         ?: "") ? getTekstil.cekme              : ""
            }>
        </cfif>
    </cfif>

    <!--- Firmaya ait ek işlem ürünleri --->
    <cfset ekIslemArr = []>
    <cfif val(getShip.company_id) gt 0>
        <cfquery name="getEkIslem" datasource="boyahane">
            SELECT s.stock_id, s.stock_code, p.product_id, p.product_name
            FROM stocks s
            JOIN product p ON s.product_id = p.product_id
            WHERE p.company_id   = <cfqueryparam value="#val(getShip.company_id)#" cfsqltype="cf_sql_integer">
              AND p.is_ek_islem  = true
              AND s.stock_status = true
            ORDER BY p.product_name
        </cfquery>
        <cfloop query="getEkIslem">
            <cfset arrayAppend(ekIslemArr, {
                "stock_id":     val(stock_id),
                "product_id":   val(product_id),
                "product_name": product_name ?: "",
                "stock_code":   stock_code   ?: ""
            })>
        </cfloop>
    </cfif>

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
        "unit_id":       getShipRow.recordCount ? val(getShipRow.unit_id ?: 0)    : 0,
        "tekstil":       tekstil,
        "ek_islem":      ekIslemArr
    }>

    <cfoutput>#serializeJSON(result)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":"Hata: #jsStringFormat(cfcatch.message)#"}</cfoutput>
    </cfcatch>
</cftry>
