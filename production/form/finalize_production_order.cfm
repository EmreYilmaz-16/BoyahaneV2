<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Üretim emrini tamamlandı olarak sonuçlandırır.
    result_amount ve finish_date_real güncellenir, status=5 yapılır.
--->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.p_order_id"     default="0">
    <cfparam name="form.result_amount"  default="0">
    <cfparam name="form.note"           default="">

    <cfset pOrderId    = isNumeric(form.p_order_id) AND val(form.p_order_id) gt 0 ? val(form.p_order_id) : 0>
    <cfset resultAmt   = isNumeric(form.result_amount) AND val(form.result_amount) gt 0 ? val(form.result_amount) : 0>
    <cfset noteVal     = trim(form.note)>

    <cfif pOrderId eq 0>
        <cfset response.message = "Geçersiz üretim emri ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>
    <cfif resultAmt lte 0>
        <cfset response.message = "Gerçekleşen miktar girilmelidir.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Emrin mevcut durumunu kontrol et --->
    <cfquery name="chk" datasource="boyahane">
        SELECT status FROM production_orders
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT chk.recordCount>
        <cfset response.message = "Üretim emri bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>
    <cfif val(chk.status) eq 5>
        <cfset response.message = "Bu emir zaten tamamlanmış.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>
    <cfif val(chk.status) eq 9>
        <cfset response.message = "İptal edilmiş emirler sonuçlandırılamaz.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        UPDATE production_orders SET
            status           = 5,
            result_amount    = <cfqueryparam value="#resultAmt#" cfsqltype="cf_sql_numeric">,
            finish_date_real = CURRENT_TIMESTAMP,
            detail           = CASE WHEN <cfqueryparam value="#len(noteVal)#" cfsqltype="cf_sql_integer"> > 0
                                    THEN COALESCE(detail,'') || ' | Sonuç notu: ' || <cfqueryparam value="#noteVal#" cfsqltype="cf_sql_varchar">
                                    ELSE detail
                               END,
            update_date      = CURRENT_TIMESTAMP
        WHERE p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response = { "success": true, "p_order_id": pOrderId, "result_amount": resultAmt }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>