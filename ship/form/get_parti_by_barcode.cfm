<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cftry>
    <cfset barcode = "">
    <cfif structKeyExists(url, "barcode")>
        <cfset barcode = trim(url.barcode ?: "")>
    <cfelseif structKeyExists(form, "barcode")>
        <cfset barcode = trim(form.barcode ?: "")>
    </cfif>

    <cfif NOT len(barcode)>
        <cfoutput>#serializeJSON({"success":false,"message":"barcode gerekli"})#</cfoutput>
        <cfabort>
    </cfif>

    <!--- İleride parti barkod kolonu eklendiğinde endpoint kırılmadan desteklemek için var olan kolonları kontrol et. --->
    <cfquery name="getOrderBarcodeColumns" datasource="boyahane">
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = current_schema()
          AND table_name = 'orders'
          AND column_name IN ('barcode', 'barcod', 'barkod', 'parti_barcode', 'party_barcode', 'lot_no')
    </cfquery>

    <cfset orderBarcodeColumns = []>
    <cfloop query="getOrderBarcodeColumns">
        <cfset arrayAppend(orderBarcodeColumns, lCase(column_name))>
    </cfloop>

    <!--- Parti (order) bilgisi: refakat kartındaki getOrder sorgusu temel alınmıştır. --->
    <cfquery name="getOrder" datasource="boyahane">
        SELECT o.order_id, o.order_number, o.order_head, o.order_detail,
               o.order_date, o.order_stage,
               o.ref_no, o.ref_ship_id,
               o.sarim_sekli, o.ambalaj,
               o.top_adedi, o.main_color,
               COALESCE(c.nickname, c.fullname, '') AS company_name,
               COALESCE(ss.sarim_sekli_adi, '')     AS sarim_sekli_adi,
               COALESCE(ab.ambalaj_adi,     '')     AS ambalaj_adi
        FROM orders o
        LEFT JOIN company           c  ON o.company_id  = c.company_id
        LEFT JOIN setup_sarim_sekli ss ON o.sarim_sekli = ss.sarim_sekli_id
        LEFT JOIN setup_ambalaj     ab ON o.ambalaj     = ab.ambalaj_id
        WHERE 1 = 1
          AND (
              <cfif isNumeric(barcode)>
                  o.order_id = <cfqueryparam value="#val(barcode)#" cfsqltype="cf_sql_integer">
                  OR
              </cfif>
              o.order_number = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
              OR o.ref_no = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
              <cfif arrayFindNoCase(orderBarcodeColumns, "barcode")>
                  OR o.barcode = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
              </cfif>
              <cfif arrayFindNoCase(orderBarcodeColumns, "barcod")>
                  OR o.barcod = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
              </cfif>
              <cfif arrayFindNoCase(orderBarcodeColumns, "barkod")>
                  OR o.barkod = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
              </cfif>
              <cfif arrayFindNoCase(orderBarcodeColumns, "parti_barcode")>
                  OR o.parti_barcode = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
              </cfif>
              <cfif arrayFindNoCase(orderBarcodeColumns, "party_barcode")>
                  OR o.party_barcode = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
              </cfif>
              <cfif arrayFindNoCase(orderBarcodeColumns, "lot_no")>
                  OR o.lot_no = <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">
              </cfif>
          )
        ORDER BY
          <cfif isNumeric(barcode)>
              CASE WHEN o.order_id = <cfqueryparam value="#val(barcode)#" cfsqltype="cf_sql_integer"> THEN 0 ELSE 1 END,
          </cfif>
          o.order_id DESC
        LIMIT 1
    </cfquery>

    <cfif NOT getOrder.recordCount>
        <cfoutput>#serializeJSON({"success":false,"message":"Parti bulunamadı"})#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Ana ürün (kumaş cinsi + parti metre/kg): refakat kartındaki getMainRow sorgusu temel alınmıştır. --->
    <cfquery name="getMainRow" datasource="boyahane">
        SELECT orw.product_name, orw.quantity, orw.amount2, orw.unit2
        FROM order_row orw
        LEFT JOIN stocks st ON orw.stock_id = st.stock_id
        WHERE orw.order_id = <cfqueryparam value="#val(getOrder.order_id)#" cfsqltype="cf_sql_integer">
          AND COALESCE(st.is_main_stock, true) = true
        ORDER BY orw.order_row_id
        LIMIT 1
    </cfquery>

    <!--- Eski format: ayrı kg satırı (geriye dönük uyumluluk), refakat kartındaki getKgRow sorgusu temel alınmıştır. --->
    <cfquery name="getKgRow" datasource="boyahane">
        SELECT orw.quantity AS kg_qty
        FROM order_row orw
        JOIN stocks  st ON orw.stock_id  = st.stock_id
        JOIN product  p ON st.product_id = p.product_id
        WHERE orw.order_id = <cfqueryparam value="#val(getOrder.order_id)#" cfsqltype="cf_sql_integer">
          AND LOWER(TRIM(orw.unit)) = 'kg'
          AND COALESCE(p.is_ek_islem, false) = false
        ORDER BY orw.order_row_id
        LIMIT 1
    </cfquery>

    <cfset partiMetre = (getMainRow.recordCount AND isNumeric(getMainRow.quantity) AND val(getMainRow.quantity) gt 0) ? val(getMainRow.quantity) : "">
    <cfif getMainRow.recordCount AND isNumeric(getMainRow.amount2) AND val(getMainRow.amount2) gt 0>
        <cfset partiKg = val(getMainRow.amount2)>
    <cfelseif getKgRow.recordCount AND isNumeric(getKgRow.kg_qty) AND val(getKgRow.kg_qty) gt 0>
        <cfset partiKg = val(getKgRow.kg_qty)>
    <cfelse>
        <cfset partiKg = "">
    </cfif>

    <cfset result = {
        "success": true,
        "order_id": val(getOrder.order_id),
        "ship_id": isNumeric(getOrder.ref_ship_id) ? val(getOrder.ref_ship_id) : "",
        "ref_ship_id": isNumeric(getOrder.ref_ship_id) ? val(getOrder.ref_ship_id) : "",
        "parti_no": getOrder.order_number ?: "",
        "order_number": getOrder.order_number ?: "",
        "company_name": getOrder.company_name ?: "",
        "product_name": getMainRow.recordCount ? (getMainRow.product_name ?: "") : "",
        "parti_metre": partiMetre,
        "parti_kg": partiKg,
        "top_adedi": (isNumeric(getOrder.top_adedi) AND val(getOrder.top_adedi) gt 0) ? val(getOrder.top_adedi) : "",
        "sarim_sekli": getOrder.sarim_sekli_adi ?: "",
        "ambalaj": getOrder.ambalaj_adi ?: ""
    }>

    <cfoutput>#serializeJSON(result)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success":false,"message":cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
