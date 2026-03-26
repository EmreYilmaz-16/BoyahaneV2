<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.id" default="0">

<cfif val(url.id) eq 0>
    <cflocation url="/index.cfm?fuseaction=company.list_company_credit" addtoken="false">
    <cfabort>
</cfif>

<cfquery name="getRecord" datasource="boyahane">
    SELECT cc.*, COALESCE(c.nickname, c.fullname, c.member_code, CAST(c.company_id AS VARCHAR)) AS company_name
    FROM company_credit cc
    LEFT JOIN company c ON cc.company_id = c.company_id
    WHERE cc.company_credit_id = <cfqueryparam value="#val(url.id)#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif getRecord.recordCount eq 0>
    <cflocation url="/index.cfm?fuseaction=company.list_company_credit" addtoken="false">
    <cfabort>
</cfif>

<!--- Dropdown verileri --->
<cfquery name="getCompanies" datasource="boyahane">
    SELECT company_id, COALESCE(nickname, fullname, member_code, CAST(company_id AS VARCHAR)) AS display_name
    FROM company WHERE company_status = true ORDER BY display_name
</cfquery>
<cfquery name="getPaymethods" datasource="boyahane">
    SELECT paymethod_id, paymethod FROM setup_paymethod
    WHERE paymethod_status = true OR paymethod_status IS NULL ORDER BY paymethod
</cfquery>
<cfquery name="getShipMethods" datasource="boyahane">
    SELECT ship_method_id, ship_method FROM ship_method ORDER BY ship_method
</cfquery>
<cfquery name="getSalesPriceCats" datasource="boyahane">
    SELECT price_catid, price_cat FROM price_cat
    WHERE price_cat_status = true AND is_sales = 1 ORDER BY price_cat
</cfquery>
<cfquery name="getPurchasePriceCats" datasource="boyahane">
    SELECT price_catid, price_cat FROM price_cat
    WHERE price_cat_status = true AND is_purchase = 1 ORDER BY price_cat
</cfquery>

<cfif structKeyExists(form, "submit")>
    <cfparam name="form.company_id"                    default="0">
    <cfparam name="form.process_stage"                 default="">
    <cfparam name="form.open_account_risk_limit"       default="">
    <cfparam name="form.open_account_risk_limit_other" default="">
    <cfparam name="form.forward_sale_limit"            default="">
    <cfparam name="form.forward_sale_limit_other"      default="">
    <cfparam name="form.total_risk_limit"              default="">
    <cfparam name="form.total_risk_limit_other"        default="">
    <cfparam name="form.money"                         default="">
    <cfparam name="form.paymethod_id"                  default="">
    <cfparam name="form.due_datex"                     default="">
    <cfparam name="form.ship_method_id"                default="">
    <cfparam name="form.price_cat"                     default="">
    <cfparam name="form.price_cat_purchase"            default="">
    <cfparam name="form.first_payment_interest"        default="">
    <cfparam name="form.last_payment_interest"         default="">
    <cfparam name="form.payment_blokaj"                default="">
    <cfparam name="form.payment_blokaj_type"           default="">
    <cfparam name="form.is_blacklist"                  default="false">
    <cfparam name="form.blacklist_date"                default="">
    <cfparam name="form.is_instalment_info"            default="false">

    <cfif val(form.company_id) eq 0>
        <cfset errorMsg = "Firma seçimi zorunludur!">
    <cfelse>
        <cftry>
            <cfquery datasource="boyahane">
                UPDATE company_credit SET
                    company_id                    = <cfqueryparam value="#val(form.company_id)#" cfsqltype="cf_sql_integer">,
                    process_stage                 = <cfqueryparam value="#val(form.process_stage)#" cfsqltype="cf_sql_integer" null="#trim(form.process_stage) eq ''#">,
                    open_account_risk_limit       = <cfqueryparam value="#val(form.open_account_risk_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.open_account_risk_limit) eq ''#">,
                    open_account_risk_limit_other = <cfqueryparam value="#val(form.open_account_risk_limit_other)#" cfsqltype="cf_sql_numeric" null="#trim(form.open_account_risk_limit_other) eq ''#">,
                    forward_sale_limit            = <cfqueryparam value="#val(form.forward_sale_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.forward_sale_limit) eq ''#">,
                    forward_sale_limit_other      = <cfqueryparam value="#val(form.forward_sale_limit_other)#" cfsqltype="cf_sql_numeric" null="#trim(form.forward_sale_limit_other) eq ''#">,
                    total_risk_limit              = <cfqueryparam value="#val(form.total_risk_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.total_risk_limit) eq ''#">,
                    total_risk_limit_other        = <cfqueryparam value="#val(form.total_risk_limit_other)#" cfsqltype="cf_sql_numeric" null="#trim(form.total_risk_limit_other) eq ''#">,
                    money                         = <cfqueryparam value="#trim(form.money)#" cfsqltype="cf_sql_varchar" null="#trim(form.money) eq ''#">,
                    paymethod_id                  = <cfqueryparam value="#val(form.paymethod_id)#" cfsqltype="cf_sql_integer" null="#val(form.paymethod_id) eq 0#">,
                    due_datex                     = <cfqueryparam value="#val(form.due_datex)#" cfsqltype="cf_sql_integer" null="#trim(form.due_datex) eq ''#">,
                    ship_method_id                = <cfqueryparam value="#val(form.ship_method_id)#" cfsqltype="cf_sql_integer" null="#val(form.ship_method_id) eq 0#">,
                    price_cat                     = <cfqueryparam value="#val(form.price_cat)#" cfsqltype="cf_sql_integer" null="#trim(form.price_cat) eq ''#">,
                    price_cat_purchase            = <cfqueryparam value="#val(form.price_cat_purchase)#" cfsqltype="cf_sql_integer" null="#trim(form.price_cat_purchase) eq ''#">,
                    first_payment_interest        = <cfqueryparam value="#val(form.first_payment_interest)#" cfsqltype="cf_sql_numeric" null="#trim(form.first_payment_interest) eq ''#">,
                    last_payment_interest         = <cfqueryparam value="#val(form.last_payment_interest)#" cfsqltype="cf_sql_numeric" null="#trim(form.last_payment_interest) eq ''#">,
                    payment_blokaj                = <cfqueryparam value="#val(form.payment_blokaj)#" cfsqltype="cf_sql_numeric" null="#trim(form.payment_blokaj) eq ''#">,
                    payment_blokaj_type           = <cfqueryparam value="#val(form.payment_blokaj_type)#" cfsqltype="cf_sql_integer" null="#trim(form.payment_blokaj_type) eq ''#">,
                    is_blacklist                  = <cfqueryparam value="#form.is_blacklist eq 'true' OR form.is_blacklist eq '1'#" cfsqltype="cf_sql_bit">,
                    blacklist_date                = <cfqueryparam value="#trim(form.blacklist_date)#" cfsqltype="cf_sql_timestamp" null="#trim(form.blacklist_date) eq ''#">,
                    is_instalment_info            = <cfqueryparam value="#form.is_instalment_info eq 'true' OR form.is_instalment_info eq '1'#" cfsqltype="cf_sql_bit">,
                    update_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    update_ip   = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                WHERE company_credit_id = <cfqueryparam value="#val(url.id)#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cflocation url="/index.cfm?fuseaction=company.list_company_credit&success=updated" addtoken="false">
            <cfabort>
            <cfcatch type="any">
                <cfset errorMsg = "Güncelleme sırasında hata: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
    <cfquery name="getRecord" datasource="boyahane">
        SELECT cc.*, COALESCE(c.nickname, c.fullname, c.member_code, CAST(c.company_id AS VARCHAR)) AS company_name
        FROM company_credit cc LEFT JOIN company c ON cc.company_id = c.company_id
        WHERE cc.company_credit_id = <cfqueryparam value="#val(url.id)#" cfsqltype="cf_sql_integer">
    </cfquery>
</cfif>

<cfset rec = getRecord>

<cffunction name="fval" returntype="string" output="false">
    <cfargument name="fieldName" type="string">
    <cfargument name="dbVal" default="">
    <cfif structKeyExists(form, arguments.fieldName)>
        <cfreturn htmlEditFormat(form[arguments.fieldName])>
    </cfif>
    <cfreturn htmlEditFormat(arguments.dbVal ?: "")>
</cffunction>
<cffunction name="chk" returntype="string" output="false">
    <cfargument name="fieldName" type="string">
    <cfargument name="dbVal">
    <cfif structKeyExists(form, "submit")>
        <cfif structKeyExists(form, arguments.fieldName) AND (form[arguments.fieldName] eq "true" OR form[arguments.fieldName] eq "1")>
            <cfreturn "checked">
        </cfif>
    <cfelse>
        <cfif isBoolean(arguments.dbVal) AND arguments.dbVal>
            <cfreturn "checked">
        </cfif>
    </cfif>
    <cfreturn "">
</cffunction>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-shield-alt"></i></div>
        <div class="page-header-title">
            <h1>Kredi Kaydı Düzenle</h1>
            <p><cfoutput>#htmlEditFormat(rec.company_name)#</cfoutput></p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=company.list_company_credit" class="btn-back">
        <i class="fas fa-arrow-left"></i>Geri Dön
    </a>
</div>

<div class="px-3 pb-4">
    <div class="row justify-content-center">
        <div class="col-lg-10">
            <cfif isDefined("errorMsg")>
                <div class="alert alert-danger alert-dismissible fade show mb-3">
                    <i class="fas fa-exclamation-circle me-2"></i>
                    <cfoutput>#errorMsg#</cfoutput>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            </cfif>

            <form method="post" id="ccForm">

                <!--- Firma Seçimi --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-building"></i>Firma Bilgileri</div>
                        <small class="text-muted">ID: <cfoutput>#rec.company_credit_id#</cfoutput></small>
                    </div>
                    <div class="p-4">
                        <div class="row g-3">
                            <div class="col-md-8">
                                <label for="company_id" class="form-label">Firma <span class="text-danger">*</span></label>
                                <select class="form-select" id="company_id" name="company_id" required>
                                    <option value="0">-- Firma Seçin --</option>
                                    <cfoutput>
                                    <cfloop query="getCompanies">
                                        <option value="#company_id#"
                                            <cfset selCompanyId = structKeyExists(form,"company_id") ? form.company_id : rec.company_id>
                                            <cfif selCompanyId eq company_id>selected</cfif>
                                        >#htmlEditFormat(display_name)#</option>
                                    </cfloop>
                                    </cfoutput>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="process_stage" class="form-label">İşlem Aşaması</label>
                                <input type="number" class="form-control" id="process_stage" name="process_stage" min="0"
                                       value="<cfoutput>#fval('process_stage', rec.process_stage)#</cfoutput>">
                            </div>
                        </div>
                    </div>
                </div>

                <!--- Risk Limitleri --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-chart-line"></i>Risk Limitleri</div>
                    </div>
                    <div class="p-4">
                        <div class="row g-3">
                            <div class="col-md-2">
                                <label for="money" class="form-label">Para Birimi</label>
                                <input type="text" class="form-control" id="money" name="money"
                                       value="<cfoutput>#fval('money', rec.money)#</cfoutput>">
                            </div>
                            <div class="col-md-5">
                                <label for="open_account_risk_limit" class="form-label">Açık Hesap Risk Limiti</label>
                                <input type="number" class="form-control" id="open_account_risk_limit" name="open_account_risk_limit" step="0.01"
                                       value="<cfoutput>#fval('open_account_risk_limit', rec.open_account_risk_limit)#</cfoutput>">
                            </div>
                            <div class="col-md-5">
                                <label for="open_account_risk_limit_other" class="form-label">Açık Hesap Limiti (Diğer)</label>
                                <input type="number" class="form-control" id="open_account_risk_limit_other" name="open_account_risk_limit_other" step="0.01"
                                       value="<cfoutput>#fval('open_account_risk_limit_other', rec.open_account_risk_limit_other)#</cfoutput>">
                            </div>
                            <div class="col-md-6">
                                <label for="forward_sale_limit" class="form-label">Vadeli Satış Limiti</label>
                                <input type="number" class="form-control" id="forward_sale_limit" name="forward_sale_limit" step="0.01"
                                       value="<cfoutput>#fval('forward_sale_limit', rec.forward_sale_limit)#</cfoutput>">
                            </div>
                            <div class="col-md-6">
                                <label for="forward_sale_limit_other" class="form-label">Vadeli Satış Limiti (Diğer)</label>
                                <input type="number" class="form-control" id="forward_sale_limit_other" name="forward_sale_limit_other" step="0.01"
                                       value="<cfoutput>#fval('forward_sale_limit_other', rec.forward_sale_limit_other)#</cfoutput>">
                            </div>
                            <div class="col-md-6">
                                <label for="total_risk_limit" class="form-label">Toplam Risk Limiti</label>
                                <input type="number" class="form-control" id="total_risk_limit" name="total_risk_limit" step="0.01"
                                       value="<cfoutput>#fval('total_risk_limit', rec.total_risk_limit)#</cfoutput>">
                            </div>
                            <div class="col-md-6">
                                <label for="total_risk_limit_other" class="form-label">Toplam Risk Limiti (Diğer)</label>
                                <input type="number" class="form-control" id="total_risk_limit_other" name="total_risk_limit_other" step="0.01"
                                       value="<cfoutput>#fval('total_risk_limit_other', rec.total_risk_limit_other)#</cfoutput>">
                            </div>
                        </div>
                    </div>
                </div>

                <!--- Ödeme & Sevkiyat --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-credit-card"></i>Ödeme & Sevkiyat Ayarları</div>
                    </div>
                    <div class="p-4">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label for="paymethod_id" class="form-label">Ödeme Yöntemi</label>
                                <select class="form-select" id="paymethod_id" name="paymethod_id">
                                    <option value="0">-- Seçin --</option>
                                    <cfoutput>
                                    <cfloop query="getPaymethods">
                                        <cfset selPmId = structKeyExists(form,"paymethod_id") ? form.paymethod_id : rec.paymethod_id>
                                        <option value="#paymethod_id#" <cfif selPmId eq paymethod_id>selected</cfif>>#htmlEditFormat(paymethod)#</option>
                                    </cfloop>
                                    </cfoutput>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="ship_method_id" class="form-label">Sevkiyat Yöntemi</label>
                                <select class="form-select" id="ship_method_id" name="ship_method_id">
                                    <option value="0">-- Seçin --</option>
                                    <cfoutput>
                                    <cfloop query="getShipMethods">
                                        <cfset selSmId = structKeyExists(form,"ship_method_id") ? form.ship_method_id : rec.ship_method_id>
                                        <option value="#ship_method_id#" <cfif selSmId eq ship_method_id>selected</cfif>>#htmlEditFormat(ship_method)#</option>
                                    </cfloop>
                                    </cfoutput>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="due_datex" class="form-label">Vade (Gün)</label>
                                <input type="number" class="form-control" id="due_datex" name="due_datex" min="0"
                                       value="<cfoutput>#fval('due_datex', rec.due_datex)#</cfoutput>">
                            </div>
                            <div class="col-md-3">
                                <label for="first_payment_interest" class="form-label">İlk Ödeme Faizi (%)</label>
                                <input type="number" class="form-control" id="first_payment_interest" name="first_payment_interest" step="0.01"
                                       value="<cfoutput>#fval('first_payment_interest', rec.first_payment_interest)#</cfoutput>">
                            </div>
                            <div class="col-md-3">
                                <label for="last_payment_interest" class="form-label">Son Ödeme Faizi (%)</label>
                                <input type="number" class="form-control" id="last_payment_interest" name="last_payment_interest" step="0.01"
                                       value="<cfoutput>#fval('last_payment_interest', rec.last_payment_interest)#</cfoutput>">
                            </div>
                            <div class="col-md-3">
                                <label for="payment_blokaj" class="form-label">Ödeme Blokajı</label>
                                <input type="number" class="form-control" id="payment_blokaj" name="payment_blokaj" step="0.01"
                                       value="<cfoutput>#fval('payment_blokaj', rec.payment_blokaj)#</cfoutput>">
                            </div>
                            <div class="col-md-3">
                                <label for="payment_blokaj_type" class="form-label">Blokaj Tipi</label>
                                <input type="number" class="form-control" id="payment_blokaj_type" name="payment_blokaj_type" min="0"
                                       value="<cfoutput>#fval('payment_blokaj_type', rec.payment_blokaj_type)#</cfoutput>">
                            </div>
                            <div class="col-md-3">
                                <label for="price_cat" class="form-label">Satış Fiyat Listesi</label>
                                <select class="form-select" id="price_cat" name="price_cat">
                                    <option value="">-- Seçin --</option>
                                    <cfoutput>
                                    <cfloop query="getSalesPriceCats">
                                        <option value="#price_catid#"
                                            <cfif val(fval('price_cat', rec.price_cat)) eq price_catid>selected</cfif>
                                        >#htmlEditFormat(price_cat)#</option>
                                    </cfloop>
                                    </cfoutput>
                                </select>
                            </div>
                            <div class="col-md-3">
                                <label for="price_cat_purchase" class="form-label">Alış Fiyat Listesi</label>
                                <select class="form-select" id="price_cat_purchase" name="price_cat_purchase">
                                    <option value="">-- Seçin --</option>
                                    <cfoutput>
                                    <cfloop query="getPurchasePriceCats">
                                        <option value="#price_catid#"
                                            <cfif val(fval('price_cat_purchase', rec.price_cat_purchase)) eq price_catid>selected</cfif>
                                        >#htmlEditFormat(price_cat)#</option>
                                    </cfloop>
                                    </cfoutput>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>

                <!--- Kara Liste --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-ban"></i>Kara Liste & Diğer</div>
                    </div>
                    <div class="p-4">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <div class="form-check form-switch mt-4">
                                    <input class="form-check-input" type="checkbox" id="is_blacklist" name="is_blacklist" value="true"
                                           <cfoutput>#chk('is_blacklist', rec.is_blacklist)#</cfoutput>>
                                    <label class="form-check-label fw-bold text-danger" for="is_blacklist">Kara Listede</label>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <label for="blacklist_date" class="form-label">Kara Liste Tarihi</label>
                                <input type="date" class="form-control" id="blacklist_date" name="blacklist_date"
                                       value="<cfoutput><cfif NOT structKeyExists(form,'submit') AND isDate(rec.blacklist_date)>#dateFormat(rec.blacklist_date,'yyyy-mm-dd')#<cfelseif structKeyExists(form,'blacklist_date') AND trim(form.blacklist_date) neq ''>#dateFormat(trim(form.blacklist_date),'yyyy-mm-dd')#</cfif></cfoutput>">
                            </div>
                            <div class="col-md-4">
                                <div class="form-check form-switch mt-4">
                                    <input class="form-check-input" type="checkbox" id="is_instalment_info" name="is_instalment_info" value="true"
                                           <cfoutput>#chk('is_instalment_info', rec.is_instalment_info)#</cfoutput>>
                                    <label class="form-check-label" for="is_instalment_info">Taksit Bilgisi</label>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="d-flex gap-2 justify-content-end">
                    <a href="/index.cfm?fuseaction=company.list_company_credit" class="btn btn-secondary">
                        <i class="fas fa-times me-1"></i>İptal
                    </a>
                    <button type="submit" name="submit" value="1" class="btn btn-primary">
                        <i class="fas fa-save me-1"></i>Güncelle
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
