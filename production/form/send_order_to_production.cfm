<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Siparişin tüm satırları için üretim emri oluştur.
    POST: order_id
    Dönüş: { success, message, created, skipped }
--->

<cfset response = { "success": false, "message": "", "created": 0, "skipped": 0 }>

<cftry>
    <cfparam name="form.order_id" default="0">
    <cfset orderId = isNumeric(form.order_id) AND val(form.order_id) gt 0 ? val(form.order_id) : 0>

    <cfif orderId eq 0>
        <cfset response.message = "Geçersiz sipariş ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Sipariş var mı kontrol et --->
    <cfquery name="checkOrder" datasource="boyahane">
        SELECT order_id, order_number FROM orders
        WHERE order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif NOT checkOrder.recordCount>
        <cfset response.message = "Sipariş bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Sipariş satırlarını getir (stock_id olanlar) --->
    <cfquery name="getRows" datasource="boyahane">
        SELECT orw.order_row_id, orw.stock_id, orw.product_id, orw.product_name,
               orw.quantity, orw.unit_id
        FROM order_row orw
        WHERE orw.order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
          AND orw.stock_id IS NOT NULL
          AND orw.stock_id > 0
          AND orw.quantity > 0
        ORDER BY orw.order_row_id
    </cfquery>

    <cfif NOT getRows.recordCount>
        <cfset response.message = "Bu siparişte üretime gönderilebilecek satır bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <cfset createdCount = 0>
    <cfset skippedCount = 0>

    <cfloop query="getRows">
        <!--- Aynı sipariş satırı için daha önce üretim emri oluşturulmuş mu? --->
        <cfquery name="chkExisting" datasource="boyahane">
            SELECT p_order_id FROM production_orders
            WHERE order_id     = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
              AND order_row_id  = <cfqueryparam value="#order_row_id#" cfsqltype="cf_sql_integer">
            LIMIT 1
        </cfquery>

        <cfif chkExisting.recordCount>
            <cfset skippedCount++>
            <cfcontinue>
        </cfif>

        <!--- save_production_order.cfm için form değişkenlerini hazırla --->
        <cfset form.p_order_id   = 0>
        <cfset form.stock_id     = val(stock_id)>
        <cfset form.order_id     = orderId>
        <cfset form.order_row_id = val(order_row_id)>
        <cfset form.quantity     = val(quantity)>
        <cfset form.p_order_no   = "UE-" & checkOrder.order_number & "-" & order_row_id>
        <cfset form.station_id   = 0>
        <cfset form.lot_no       = "">
        <cfset form.start_date   = "">
        <cfset form.finish_date  = "">
        <cfset form.status       = 1>
        <cfset form.detail       = "">

        <!--- Üretim emrini oluştur --->
        <cfset variables.isIncluded = true>
        <cfinclude template="save_production_order.cfm">
        <cfset saveResult = duplicate(response)>

        <cfif saveResult.success>
            <cfset createdCount++>
        <cfelse>
            <cfset response = { "success": false, "message": saveResult.message, "created": createdCount, "skipped": skippedCount }>
            <cfoutput>#serializeJSON(response)#</cfoutput>
            <cfabort>
        </cfif>
    </cfloop>

    <cfset response.success  = true>
    <cfset response.created  = createdCount>
    <cfset response.skipped  = skippedCount>
    <cfif createdCount gt 0>
        <cfset response.message = createdCount & " üretim emri oluşturuldu." & (skippedCount gt 0 ? " " & skippedCount & " satır zaten üretimde." : "")>
    <cfelse>
        <cfset response.message = "Tüm satırlar zaten üretimde (" & skippedCount & " satır).">
    </cfif>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message, "created": 0, "skipped": 0 }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
<cfabort>
