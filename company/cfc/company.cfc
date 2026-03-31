<cfcomponent output="false">

    <!--- Firma Kategorisi Sil --->
    <cffunction name="deleteCompanyCat" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfset var result = {}>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfif val(arguments.id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz kategori ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>
            <cfquery name="checkCompanies" datasource="boyahane">
                SELECT COUNT(*) AS cnt FROM company
                WHERE companycat_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfif checkCompanies.cnt gt 0>
                <cfset result = {"success": false, "message": "Bu kategoriye bağlı #checkCompanies.cnt# adet firma bulunmaktadır. Önce firmaları taşıyın veya silin."}>
                <cfreturn serializeJSON(result)>
            </cfif>
            <cfquery datasource="boyahane">
                DELETE FROM company_cat WHERE companycat_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset result = {"success": true, "message": "Kategori başarıyla silindi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Kategori silinirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Firma Sil --->
    <cffunction name="deleteCompany" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfset var result = {}>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfif val(arguments.id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz firma ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>
            <cfquery datasource="boyahane">
                DELETE FROM company WHERE company_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset result = {"success": true, "message": "Firma başarıyla silindi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Firma silinirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Firma Getir (tek kayıt) --->
    <cffunction name="getCompany" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfset var result = {}>
        <cfset var qry = "">
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery name="qry" datasource="boyahane">
                SELECT c.*, cc.companycat
                FROM company c
                LEFT JOIN company_cat cc ON c.companycat_id = cc.companycat_id
                WHERE c.company_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfif qry.recordCount eq 0>
                <cfset result = {"success": false, "message": "Firma bulunamadı"}>
            <cfelse>
                <cfset result = {
                    "success": true,
                    "data": {
                        "company_id":       qry.company_id,
                        "company_status":   qry.company_status,
                        "companycat_id":    qry.companycat_id,
                        "companycat":       qry.companycat ?: "",
                        "member_code":      qry.member_code ?: "",
                        "nickname":         qry.nickname ?: "",
                        "fullname":         qry.fullname ?: "",
                        "taxoffice":        qry.taxoffice ?: "",
                        "taxno":            qry.taxno ?: "",
                        "company_email":    qry.company_email ?: "",
                        "homepage":         qry.homepage ?: "",
                        "company_tel1":     qry.company_tel1 ?: "",
                        "company_tel2":     qry.company_tel2 ?: "",
                        "mobiltel":         qry.mobiltel ?: "",
                        "company_address":  qry.company_address ?: "",
                        "is_buyer":         qry.is_buyer,
                        "is_seller":        qry.is_seller,
                        "ispotantial":      qry.ispotantial,
                        "is_person":        qry.is_person,
                        "ozel_kod":         qry.ozel_kod ?: "",
                        "ozel_kod_1":       qry.ozel_kod_1 ?: "",
                        "ozel_kod_2":       qry.ozel_kod_2 ?: "",
                        "record_date":      isDate(qry.record_date) ? dateFormat(qry.record_date, "dd/mm/yyyy") & " " & timeFormat(qry.record_date, "HH:mm") : "",
                        "update_date":      isDate(qry.update_date) ? dateFormat(qry.update_date, "dd/mm/yyyy") & " " & timeFormat(qry.update_date, "HH:mm") : ""
                    }
                }>
            </cfif>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Firma getirilirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Firma Kategorileri Listele (dropdown için) --->
    <cffunction name="getCompanyCategories" access="remote" returnformat="plain" output="false">
        <cfset var result = {}>
        <cfset var qry = "">
        <cfset var arr = []>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery name="qry" datasource="boyahane">
                SELECT companycat_id, companycat, companycat_type
                FROM company_cat
                WHERE is_active = true
                ORDER BY companycat
            </cfquery>
            <cfloop query="qry">
                <cfset arrayAppend(arr, {
                    "companycat_id":   qry.companycat_id,
                    "companycat":      qry.companycat ?: "",
                    "companycat_type": qry.companycat_type
                })>
            </cfloop>
            <cfset result = {"success": true, "data": arr}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Kategoriler getirilirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Şube Listesi (firma detayı için) --->
    <cffunction name="getBranchesByCompany" access="remote" returnformat="plain" output="false">
        <cfargument name="company_id" type="numeric" required="true">
        <cfset var result = {}>
        <cfset var qry = "">
        <cfset var arr = []>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery name="qry" datasource="boyahane">
                SELECT compbranch_id, compbranch__name, compbranch__nickname,
                       compbranch_tel1, compbranch_email, compbranch_address,
                       compbranch_status, record_date
                FROM company_branch
                WHERE company_id = <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_integer">
                ORDER BY compbranch_id DESC
            </cfquery>
            <cfloop query="qry">
                <cfset arrayAppend(arr, {
                    "compbranch_id":       qry.compbranch_id,
                    "compbranch__name":    qry.compbranch__name ?: "",
                    "compbranch__nickname":qry.compbranch__nickname ?: "",
                    "compbranch_tel1":     qry.compbranch_tel1 ?: "",
                    "compbranch_email":    qry.compbranch_email ?: "",
                    "compbranch_address":  qry.compbranch_address ?: "",
                    "compbranch_status":   qry.compbranch_status,
                    "record_date":         isDate(qry.record_date) ? dateFormat(qry.record_date, "dd/mm/yyyy") : ""
                })>
            </cfloop>
            <cfset result = {"success": true, "data": arr}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Şubeler getirilirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Yetkili Listesi (firma detayı için) --->
    <cffunction name="getPartnersByCompany" access="remote" returnformat="plain" output="false">
        <cfargument name="company_id" type="numeric" required="true">
        <cfset var result = {}>
        <cfset var qry = "">
        <cfset var arr = []>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery name="qry" datasource="boyahane">
                SELECT partner_id, company_partner_name, company_partner_surname,
                       company_partner_email, mobiltel, company_partner_tel,
                       title, company_partner_status, record_date
                FROM company_partner
                WHERE company_id = <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_integer">
                ORDER BY partner_id DESC
            </cfquery>
            <cfloop query="qry">
                <cfset arrayAppend(arr, {
                    "partner_id":             qry.partner_id,
                    "company_partner_name":   qry.company_partner_name ?: "",
                    "company_partner_surname":qry.company_partner_surname ?: "",
                    "company_partner_email":  qry.company_partner_email ?: "",
                    "mobiltel":               qry.mobiltel ?: "",
                    "company_partner_tel":    qry.company_partner_tel ?: "",
                    "title":                  qry.title ?: "",
                    "company_partner_status": qry.company_partner_status,
                    "record_date":            isDate(qry.record_date) ? dateFormat(qry.record_date, "dd/mm/yyyy") : ""
                })>
            </cfloop>
            <cfset result = {"success": true, "data": arr}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Yetkililer getirilirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Şube Sil --->
    <cffunction name="deleteBranch" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfset var result = {}>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery datasource="boyahane">
                DELETE FROM company_branch WHERE compbranch_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset result = {"success": true, "message": "Şube silindi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Şube silinirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Yetkili Sil --->
    <cffunction name="deletePartner" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfset var result = {}>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery datasource="boyahane">
                DELETE FROM company_partner WHERE partner_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset result = {"success": true, "message": "Yetkili silindi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Yetkili silinirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Sevkiyat Yöntemi Sil --->
    <cffunction name="deleteShipMethod" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfset var result = {}>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery name="checkUse" datasource="boyahane">
                SELECT COUNT(*) AS cnt FROM company_credit
                WHERE ship_method_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfif checkUse.cnt gt 0>
                <cfset result = {"success": false, "message": "Bu sevkiyat yöntemi #checkUse.cnt# adet kredi kaydında kullanılmaktadır. Önce o kayıtları güncelleyin."}>
                <cfreturn serializeJSON(result)>
            </cfif>
            <cfquery datasource="boyahane">
                DELETE FROM ship_method WHERE ship_method_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset result = {"success": true, "message": "Sevkiyat yöntemi silindi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Sevkiyat yöntemi silinirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Ödeme Yöntemi Sil --->
    <cffunction name="deletePaymethod" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfset var result = {}>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery name="checkUse" datasource="boyahane">
                SELECT COUNT(*) AS cnt FROM company_credit
                WHERE paymethod_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfif checkUse.cnt gt 0>
                <cfset result = {"success": false, "message": "Bu ödeme yöntemi #checkUse.cnt# adet kredi kaydında kullanılmaktadır. Önce o kayıtları güncelleyin."}>
                <cfreturn serializeJSON(result)>
            </cfif>
            <cfquery datasource="boyahane">
                DELETE FROM setup_paymethod WHERE paymethod_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset result = {"success": true, "message": "Ödeme yöntemi silindi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Ödeme yöntemi silinirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Firma Kredi Kayıtları Listele --->
    <cffunction name="getCreditsByCompany" access="remote" returnformat="plain" output="false">
        <cfargument name="company_id" type="numeric" required="true">
        <cfset var qry = "">
        <cfset var arr = []>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery name="qry" datasource="boyahane">
                SELECT cc.company_credit_id, cc.money,
                       cc.open_account_risk_limit, cc.forward_sale_limit, cc.total_risk_limit,
                       cc.due_datex, cc.is_blacklist,
                       pm.paymethod, sm.ship_method
                FROM company_credit cc
                LEFT JOIN setup_paymethod pm ON cc.paymethod_id = pm.paymethod_id
                LEFT JOIN ship_method sm     ON cc.ship_method_id = sm.ship_method_id
                WHERE cc.company_id = <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_integer">
                ORDER BY cc.company_credit_id DESC
            </cfquery>
            <cfloop query="qry">
                <cfset arrayAppend(arr, {
                    "company_credit_id":      qry.company_credit_id,
                    "money":                  qry.money ?: "TRY",
                    "open_account_risk_limit":isNumeric(qry.open_account_risk_limit) ? qry.open_account_risk_limit : 0,
                    "forward_sale_limit":     isNumeric(qry.forward_sale_limit) ? qry.forward_sale_limit : 0,
                    "total_risk_limit":       isNumeric(qry.total_risk_limit) ? qry.total_risk_limit : 0,
                    "due_datex":              isNumeric(qry.due_datex) ? qry.due_datex : "",
                    "is_blacklist":           qry.is_blacklist,
                    "paymethod":              qry.paymethod ?: "",
                    "ship_method":            qry.ship_method ?: ""
                })>
            </cfloop>
            <cfcatch type="any"><!---ignore---></cfcatch>
        </cftry>
        <cfreturn serializeJSON(arr)>
    </cffunction>

    <!--- Kredi Kaydı Kaydet (INSERT veya UPDATE) --->
    <cffunction name="saveCompanyCredit" access="remote" returnformat="plain" output="false">
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cfset var result = {}>
        <cftry>
            <cfparam name="form.credit_id"                     default="0">
            <cfparam name="form.company_id"                    default="0">
            <cfparam name="form.money"                         default="TRY">
            <cfparam name="form.open_account_risk_limit"       default="">
            <cfparam name="form.forward_sale_limit"            default="">
            <cfparam name="form.total_risk_limit"              default="">
            <cfparam name="form.due_datex"                     default="">
            <cfparam name="form.paymethod_id"                  default="0">
            <cfparam name="form.ship_method_id"                default="0">
            <cfparam name="form.is_blacklist"                  default="false">

            <cfif val(form.company_id) eq 0>
                <cfset result = {"success": false, "message": "Firma ID eksik!"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfif val(form.credit_id) gt 0>
                <cfquery datasource="boyahane">
                    UPDATE company_credit SET
                        money                   = <cfqueryparam value="#trim(form.money)#" cfsqltype="cf_sql_varchar" null="#trim(form.money) eq ''#">,
                        open_account_risk_limit = <cfqueryparam value="#val(form.open_account_risk_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.open_account_risk_limit) eq ''#">,
                        forward_sale_limit      = <cfqueryparam value="#val(form.forward_sale_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.forward_sale_limit) eq ''#">,
                        total_risk_limit        = <cfqueryparam value="#val(form.total_risk_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.total_risk_limit) eq ''#">,
                        due_datex               = <cfqueryparam value="#val(form.due_datex)#" cfsqltype="cf_sql_integer" null="#trim(form.due_datex) eq ''#">,
                        paymethod_id            = <cfqueryparam value="#val(form.paymethod_id)#" cfsqltype="cf_sql_integer" null="#val(form.paymethod_id) eq 0#">,
                        ship_method_id          = <cfqueryparam value="#val(form.ship_method_id)#" cfsqltype="cf_sql_integer" null="#val(form.ship_method_id) eq 0#">,
                        is_blacklist            = <cfqueryparam value="#form.is_blacklist eq 'true' OR form.is_blacklist eq '1'#" cfsqltype="cf_sql_bit">,
                        update_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                        update_ip   = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                    WHERE company_credit_id = <cfqueryparam value="#val(form.credit_id)#" cfsqltype="cf_sql_integer">
                </cfquery>
            <cfelse>
                <cfquery datasource="boyahane">
                    INSERT INTO company_credit (company_id, money, open_account_risk_limit, forward_sale_limit, total_risk_limit, due_datex, paymethod_id, ship_method_id, is_blacklist, record_date, record_ip)
                    VALUES (
                        <cfqueryparam value="#val(form.company_id)#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#trim(form.money)#" cfsqltype="cf_sql_varchar" null="#trim(form.money) eq ''#">,
                        <cfqueryparam value="#val(form.open_account_risk_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.open_account_risk_limit) eq ''#">,
                        <cfqueryparam value="#val(form.forward_sale_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.forward_sale_limit) eq ''#">,
                        <cfqueryparam value="#val(form.total_risk_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.total_risk_limit) eq ''#">,
                        <cfqueryparam value="#val(form.due_datex)#" cfsqltype="cf_sql_integer" null="#trim(form.due_datex) eq ''#">,
                        <cfqueryparam value="#val(form.paymethod_id)#" cfsqltype="cf_sql_integer" null="#val(form.paymethod_id) eq 0#">,
                        <cfqueryparam value="#val(form.ship_method_id)#" cfsqltype="cf_sql_integer" null="#val(form.ship_method_id) eq 0#">,
                        <cfqueryparam value="#form.is_blacklist eq 'true' OR form.is_blacklist eq '1'#" cfsqltype="cf_sql_bit">,
                        <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                        <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                    )
                </cfquery>
            </cfif>
            <cfset result = {"success": true, "message": "Kredi kaydı kaydedildi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Kredi Kaydı Sil --->
    <cffunction name="deleteCompanyCredit" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfset var result = {}>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery datasource="boyahane">
                DELETE FROM company_credit WHERE company_credit_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset result = {"success": true, "message": "Kredi kaydı silindi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Kredi kaydı silinirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Ödeme Yöntemleri Dropdown --->
    <cffunction name="getPaymethodsForDropdown" access="remote" returnformat="plain" output="false">
        <cfset var qry = "">
        <cfset var arr = []>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery name="qry" datasource="boyahane">
                SELECT paymethod_id, paymethod FROM setup_paymethod
                WHERE paymethod_status = true OR paymethod_status IS NULL
                ORDER BY paymethod
            </cfquery>
            <cfloop query="qry">
                <cfset arrayAppend(arr, {"paymethod_id": qry.paymethod_id, "paymethod": qry.paymethod ?: ""})>
            </cfloop>
            <cfcatch type="any"><!---ignore---></cfcatch>
        </cftry>
        <cfreturn serializeJSON(arr)>
    </cffunction>

    <!--- Sevkiyat Yöntemleri Dropdown --->
    <cffunction name="getShipMethodsForDropdown" access="remote" returnformat="plain" output="false">
        <cfset var qry = "">
        <cfset var arr = []>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery name="qry" datasource="boyahane">
                SELECT ship_method_id, ship_method FROM ship_method ORDER BY ship_method
            </cfquery>
            <cfloop query="qry">
                <cfset arrayAppend(arr, {"ship_method_id": qry.ship_method_id, "ship_method": qry.ship_method ?: ""})>
            </cfloop>
            <cfcatch type="any"><!---ignore---></cfcatch>
        </cftry>
        <cfreturn serializeJSON(arr)>
    </cffunction>

    <!--- Firma Risk / Ödeme & Sevk Bilgisi --->
    <cffunction name="getCompanyRisk" access="remote" returnformat="plain" output="false">
        <cfargument name="company_id" type="numeric" required="true">
        <cfset var qry = "">
        <cfset var result = {}>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery name="qry" datasource="boyahane">
                SELECT cc.paymethod_id,
                       pm.paymethod AS paymethod_name,
                       cc.ship_method_id AS ship_method,
                       sm.ship_method   AS ship_method_name,
                       cc.price_cat,
                       cc.price_cat_purchase
                FROM company_credit cc
                LEFT JOIN setup_paymethod pm ON cc.paymethod_id    = pm.paymethod_id
                LEFT JOIN ship_method     sm ON cc.ship_method_id  = sm.ship_method_id
                WHERE cc.company_id = <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_integer">
                ORDER BY cc.company_credit_id DESC
                LIMIT 1
            </cfquery>
            <cfif qry.recordCount>
                <cfset result = {
                    "success": true,
                    "data": {
                        "paymethod_id":       isNumeric(qry.paymethod_id) ? val(qry.paymethod_id) : 0,
                        "paymethod_name":     qry.paymethod_name ?: "",
                        "ship_method":        isNumeric(qry.ship_method) ? val(qry.ship_method) : 0,
                        "ship_method_name":   qry.ship_method_name ?: "",
                        "price_cat":          isNumeric(qry.price_cat) ? val(qry.price_cat) : 0,
                        "price_cat_purchase": isNumeric(qry.price_cat_purchase) ? val(qry.price_cat_purchase) : 0
                    }
                }>
            <cfelse>
                <cfset result = {"success": false, "message": "Risk kaydı bulunamadı"}>
            </cfif>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Firmalar Dropdown (kredi formu için) --->
    <cffunction name="getCompaniesForDropdown" access="remote" returnformat="plain" output="false">
        <cfset var qry = "">
        <cfset var arr = []>
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cftry>
            <cfquery name="qry" datasource="boyahane">
                SELECT company_id, COALESCE(nickname, fullname, member_code, CAST(company_id AS VARCHAR)) AS display_name
                FROM company
                WHERE company_status = true
                ORDER BY display_name
            </cfquery>
            <cfloop query="qry">
                <cfset arrayAppend(arr, {"company_id": qry.company_id, "display_name": qry.display_name ?: ""})>
            </cfloop>
            <cfcatch type="any"><!---ignore---></cfcatch>
        </cftry>
        <cfreturn serializeJSON(arr)>
    </cffunction>

    <!--- ==================== EXCEL IMPORT ==================== --->

    <!--- Toplu Firma İçe Aktarma --->
    <cffunction name="importCompanies" access="remote" returnformat="plain" output="false">
        <cfargument name="companiesJSON" type="string" required="true">

        <cfset var result    = {}>
        <cfset var companies = []>
        <cfset var inserted  = 0>
        <cfset var errList   = []>
        <cfset var catMap    = {}>
        <cfset var qAllCats  = "">

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif len(trim(arguments.companiesJSON)) eq 0>
                <cfset result = {"success": false, "message": "Veri boş olamaz"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfset companies = deserializeJSON(arguments.companiesJSON)>

            <cfif not isArray(companies) or arrayLen(companies) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz veri formatı"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfif arrayLen(companies) gt 5000>
                <cfset result = {"success": false, "message": "En fazla 5000 kayıt aktarabilirsiniz"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <!--- Kategori ID'lerini önbelleğe al --->
            <cfquery name="qAllCats" datasource="boyahane">
                SELECT companycat_id FROM company_cat
            </cfquery>
            <cfloop query="qAllCats">
                <cfset catMap[companycat_id] = true>
            </cfloop>

            <cfloop array="#companies#" index="row">
                <cfset rowNum  = structKeyExists(row, "row_num") ? row.row_num : 0>
                <cfset nick    = structKeyExists(row, "nickname") ? trim(row.nickname) : "">
                <cfset full    = structKeyExists(row, "fullname") ? trim(row.fullname) : "">

                <cfif len(nick) eq 0 and len(full) eq 0>
                    <cfset arrayAppend(errList, "Satır #rowNum#: Kısa ad veya firma adı zorunludur")>
                    <cfcontinue>
                </cfif>

                <cfset cCatId    = structKeyExists(row, "companycat_id") ? val(row.companycat_id) : 0>
                <cfset cMemCode  = structKeyExists(row, "member_code")     ? trim(row.member_code)     : "">
                <cfset cTaxOff   = structKeyExists(row, "taxoffice")        ? trim(row.taxoffice)        : "">
                <cfset cTaxno    = structKeyExists(row, "taxno")             ? trim(row.taxno)             : "">
                <cfset cEmail    = structKeyExists(row, "company_email")    ? trim(row.company_email)    : "">
                <cfset cTel1     = structKeyExists(row, "company_tel1")     ? trim(row.company_tel1)     : "">
                <cfset cMobil    = structKeyExists(row, "mobiltel")          ? trim(row.mobiltel)          : "">
                <cfset cAddress  = structKeyExists(row, "company_address")  ? trim(row.company_address)  : "">
                <cfset cOzelKod  = structKeyExists(row, "ozel_kod")          ? trim(row.ozel_kod)          : "">
                <cfset cIsBuyer  = structKeyExists(row, "is_buyer")    ? (row.is_buyer    eq true or row.is_buyer    eq 1) : true>
                <cfset cIsSeller = structKeyExists(row, "is_seller")   ? (row.is_seller   eq true or row.is_seller   eq 1) : true>
                <cfset cIsPot    = structKeyExists(row, "ispotantial")  ? (row.ispotantial eq true or row.ispotantial eq 1) : false>
                <cfset cIsPerson = structKeyExists(row, "is_person")   ? (row.is_person   eq true or row.is_person   eq 1) : false>

                <!--- Geçersiz kategori ID'si varsa sıfırla --->
                <cfif cCatId gt 0 and not structKeyExists(catMap, cCatId)>
                    <cfset cCatId = 0>
                </cfif>

                <cftry>
                    <cfquery datasource="boyahane">
                        INSERT INTO company (
                            company_status, nickname, fullname, companycat_id,
                            member_code, taxoffice, taxno, company_email, company_tel1,
                            mobiltel, company_address, ozel_kod,
                            is_buyer, is_seller, ispotantial, is_person,
                            record_date, record_emp
                        ) VALUES (
                            true,
                            <cfqueryparam value="#nick#"      cfsqltype="cf_sql_varchar" null="#len(nick) eq 0#">,
                            <cfqueryparam value="#full#"      cfsqltype="cf_sql_varchar" null="#len(full) eq 0#">,
                            <cfqueryparam value="#cCatId#"    cfsqltype="cf_sql_integer" null="#cCatId eq 0#">,
                            <cfqueryparam value="#cMemCode#"  cfsqltype="cf_sql_varchar" null="#len(cMemCode) eq 0#">,
                            <cfqueryparam value="#cTaxOff#"   cfsqltype="cf_sql_varchar" null="#len(cTaxOff) eq 0#">,
                            <cfqueryparam value="#cTaxno#"    cfsqltype="cf_sql_varchar" null="#len(cTaxno) eq 0#">,
                            <cfqueryparam value="#cEmail#"    cfsqltype="cf_sql_varchar" null="#len(cEmail) eq 0#">,
                            <cfqueryparam value="#cTel1#"     cfsqltype="cf_sql_varchar" null="#len(cTel1) eq 0#">,
                            <cfqueryparam value="#cMobil#"    cfsqltype="cf_sql_varchar" null="#len(cMobil) eq 0#">,
                            <cfqueryparam value="#cAddress#"  cfsqltype="cf_sql_varchar" null="#len(cAddress) eq 0#">,
                            <cfqueryparam value="#cOzelKod#"  cfsqltype="cf_sql_varchar" null="#len(cOzelKod) eq 0#">,
                            <cfqueryparam value="#cIsBuyer#"  cfsqltype="cf_sql_bit">,
                            <cfqueryparam value="#cIsSeller#" cfsqltype="cf_sql_bit">,
                            <cfqueryparam value="#cIsPot#"    cfsqltype="cf_sql_bit">,
                            <cfqueryparam value="#cIsPerson#" cfsqltype="cf_sql_bit">,
                            CURRENT_TIMESTAMP,
                            1
                        )
                    </cfquery>
                    <cfset inserted = inserted + 1>
                    <cfcatch type="any">
                        <cfset dispName = len(nick) ? nick : full>
                        <cfset arrayAppend(errList, "Satır #rowNum# (#dispName#): #cfcatch.message#")>
                    </cfcatch>
                </cftry>
            </cfloop>

            <cfset result = {
                "success":     true,
                "inserted":    inserted,
                "error_count": arrayLen(errList),
                "errors":      errList,
                "message":     inserted & " firma eklendi" & (arrayLen(errList) gt 0 ? ", " & arrayLen(errList) & " hata" : "")
            }>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "İçe aktarma hatası: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

</cfcomponent>
