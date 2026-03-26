<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfif NOT isDefined("session.authenticated") OR NOT session.authenticated>
        <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Params --->
    <cfset papersId   = isDefined("form.general_papers_id") AND isNumeric(form.general_papers_id) ? val(form.general_papers_id) : 0>
    <cfset fieldKey   = isDefined("form.field_key")   ? trim(lcase(form.field_key))  : "">
    <cfset noValue    = isDefined("form.no_value")    ? trim(form.no_value)           : "">
    <cfset numValue   = isDefined("form.number_value") AND isNumeric(form.number_value) ? val(form.number_value) : 0>

    <cfif papersId lte 0>
        <cfoutput>{"success":false,"message":"Geçersiz kayıt ID."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Güvenli alan adı beyaz listesi --->
    <cfset validKeys = "offer,order,campaign,promotion,catalog,target_market,cat_prom,prod_order,support,opportunity,service_app,stock_fis,ship_fis,subscription,production_result,production_lot,credit,pro_material,internal,virman,incoming_transfer,outgoing_transfer,purchase_doviz,sale_doviz,creditcard_revenue,creditcard_payment,cari_to_cari,debit_claim,cash_to_cash,cash_payment,expense_cost,income_cost,budget_plan,correspondence,purchasedemand,expenditure_request,quality_control,production_quality_control,creditcard_debit_payment,securefund,credit_revenue,credit_payment,creditcard_cc_bank_action,buying_securities,securities_sale,tahakkuk_plan,system_paper,receipt,travel_demand,mkdad,budget_transfer_demand,ship_internal,req,production_party,waste_collection,waste_operation,sample_analysis,work,cashregister">

    <cfif NOT listFind(validKeys, fieldKey)>
        <cfoutput>{"success":false,"message":"Geçersiz alan adı."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Kolon adlarını oluştur (whitelist'ten geçmiş, SQL injection riski yok) --->
    <cfset noCol  = fieldKey & "_no">
    <cfset numCol = fieldKey & "_number">

    <cfquery datasource="boyahane">
        UPDATE general_papers
        SET   #noCol#  = <cfqueryparam value="#noValue#"  cfsqltype="cf_sql_varchar">,
              #numCol# = <cfqueryparam value="#numValue#" cfsqltype="cf_sql_integer">
        WHERE general_papers_id = <cfqueryparam value="#papersId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>{"success":true,"field_key":"#fieldKey#","message":"Kaydedildi."}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":"#jsStringFormat(cfcatch.message)#"}</cfoutput>
    </cfcatch>
</cftry>
