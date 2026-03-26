<cfprocessingdirective pageEncoding="utf-8">

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
                INSERT INTO company_credit (
                    company_id, process_stage,
                    open_account_risk_limit, open_account_risk_limit_other,
                    forward_sale_limit, forward_sale_limit_other,
                    total_risk_limit, total_risk_limit_other,
                    money, paymethod_id, due_datex, ship_method_id,
                    price_cat, price_cat_purchase,
                    first_payment_interest, last_payment_interest,
                    payment_blokaj, payment_blokaj_type,
                    is_blacklist, blacklist_date, is_instalment_info,
                    record_date, record_ip
                ) VALUES (
                    <cfqueryparam value="#val(form.company_id)#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#val(form.process_stage)#" cfsqltype="cf_sql_integer" null="#trim(form.process_stage) eq ''#">,
                    <cfqueryparam value="#val(form.open_account_risk_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.open_account_risk_limit) eq ''#">,
                    <cfqueryparam value="#val(form.open_account_risk_limit_other)#" cfsqltype="cf_sql_numeric" null="#trim(form.open_account_risk_limit_other) eq ''#">,
                    <cfqueryparam value="#val(form.forward_sale_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.forward_sale_limit) eq ''#">,
                    <cfqueryparam value="#val(form.forward_sale_limit_other)#" cfsqltype="cf_sql_numeric" null="#trim(form.forward_sale_limit_other) eq ''#">,
                    <cfqueryparam value="#val(form.total_risk_limit)#" cfsqltype="cf_sql_numeric" null="#trim(form.total_risk_limit) eq ''#">,
                    <cfqueryparam value="#val(form.total_risk_limit_other)#" cfsqltype="cf_sql_numeric" null="#trim(form.total_risk_limit_other) eq ''#">,
                    <cfqueryparam value="#trim(form.money)#" cfsqltype="cf_sql_varchar" null="#trim(form.money) eq ''#">,
                    <cfqueryparam value="#val(form.paymethod_id)#" cfsqltype="cf_sql_integer" null="#val(form.paymethod_id) eq 0#">,
                    <cfqueryparam value="#val(form.due_datex)#" cfsqltype="cf_sql_integer" null="#trim(form.due_datex) eq ''#">,
                    <cfqueryparam value="#val(form.ship_method_id)#" cfsqltype="cf_sql_integer" null="#val(form.ship_method_id) eq 0#">,
                    <cfqueryparam value="#val(form.price_cat)#" cfsqltype="cf_sql_integer" null="#trim(form.price_cat) eq ''#">,
                    <cfqueryparam value="#val(form.price_cat_purchase)#" cfsqltype="cf_sql_integer" null="#trim(form.price_cat_purchase) eq ''#">,
                    <cfqueryparam value="#val(form.first_payment_interest)#" cfsqltype="cf_sql_numeric" null="#trim(form.first_payment_interest) eq ''#">,
                    <cfqueryparam value="#val(form.last_payment_interest)#" cfsqltype="cf_sql_numeric" null="#trim(form.last_payment_interest) eq ''#">,
                    <cfqueryparam value="#val(form.payment_blokaj)#" cfsqltype="cf_sql_numeric" null="#trim(form.payment_blokaj) eq ''#">,
                    <cfqueryparam value="#val(form.payment_blokaj_type)#" cfsqltype="cf_sql_integer" null="#trim(form.payment_blokaj_type) eq ''#">,
                    <cfqueryparam value="#form.is_blacklist eq 'true' OR form.is_blacklist eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#trim(form.blacklist_date)#" cfsqltype="cf_sql_timestamp" null="#trim(form.blacklist_date) eq ''#">,
                    <cfqueryparam value="#form.is_instalment_info eq 'true' OR form.is_instalment_info eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                )
            </cfquery>
            <cflocation url="/index.cfm?fuseaction=company.list_company_credit&success=added" addtoken="false">
            <cfabort>
            <cfcatch type="any">
                <cfset errorMsg = "Kayıt eklenirken hata: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-shield-alt"></i></div>
        <div class="page-header-title">
            <h1>Yeni Kredi Kaydı</h1>
            <p>Firma kredi ve risk limit bilgilerini doldurun</p>
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
                <div class="alert alert-danger alert-dismissible fade show mb-3" role="alert">
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
                                            <cfif isDefined("form.company_id") AND form.company_id eq company_id>selected</cfif>
                                        >#htmlEditFormat(display_name)#</option>
                                    </cfloop>
                                    </cfoutput>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="process_stage" class="form-label">İşlem Aşaması</label>
                                <input type="number" class="form-control" id="process_stage" name="process_stage" min="0"
                                       value="<cfif isDefined('form.process_stage')><cfoutput>#htmlEditFormat(form.process_stage)#</cfoutput></cfif>">
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
                                <input type="text" class="form-control" id="money" name="money" placeholder="TRY"
                                       value="<cfif isDefined('form.money')><cfoutput>#htmlEditFormat(form.money)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-5">
                                <label for="open_account_risk_limit" class="form-label">Açık Hesap Risk Limiti</label>
                                <input type="number" class="form-control" id="open_account_risk_limit" name="open_account_risk_limit" step="0.01"
                                       value="<cfif isDefined('form.open_account_risk_limit')><cfoutput>#htmlEditFormat(form.open_account_risk_limit)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-5">
                                <label for="open_account_risk_limit_other" class="form-label">Açık Hesap Limiti (Diğer)</label>
                                <input type="number" class="form-control" id="open_account_risk_limit_other" name="open_account_risk_limit_other" step="0.01"
                                       value="<cfif isDefined('form.open_account_risk_limit_other')><cfoutput>#htmlEditFormat(form.open_account_risk_limit_other)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-6">
                                <label for="forward_sale_limit" class="form-label">Vadeli Satış Limiti</label>
                                <input type="number" class="form-control" id="forward_sale_limit" name="forward_sale_limit" step="0.01"
                                       value="<cfif isDefined('form.forward_sale_limit')><cfoutput>#htmlEditFormat(form.forward_sale_limit)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-6">
                                <label for="forward_sale_limit_other" class="form-label">Vadeli Satış Limiti (Diğer)</label>
                                <input type="number" class="form-control" id="forward_sale_limit_other" name="forward_sale_limit_other" step="0.01"
                                       value="<cfif isDefined('form.forward_sale_limit_other')><cfoutput>#htmlEditFormat(form.forward_sale_limit_other)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-6">
                                <label for="total_risk_limit" class="form-label">Toplam Risk Limiti</label>
                                <input type="number" class="form-control" id="total_risk_limit" name="total_risk_limit" step="0.01"
                                       value="<cfif isDefined('form.total_risk_limit')><cfoutput>#htmlEditFormat(form.total_risk_limit)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-6">
                                <label for="total_risk_limit_other" class="form-label">Toplam Risk Limiti (Diğer)</label>
                                <input type="number" class="form-control" id="total_risk_limit_other" name="total_risk_limit_other" step="0.01"
                                       value="<cfif isDefined('form.total_risk_limit_other')><cfoutput>#htmlEditFormat(form.total_risk_limit_other)#</cfoutput></cfif>">
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
                                        <option value="#paymethod_id#"
                                            <cfif isDefined("form.paymethod_id") AND form.paymethod_id eq paymethod_id>selected</cfif>
                                        >#htmlEditFormat(paymethod)#</option>
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
                                        <option value="#ship_method_id#"
                                            <cfif isDefined("form.ship_method_id") AND form.ship_method_id eq ship_method_id>selected</cfif>
                                        >#htmlEditFormat(ship_method)#</option>
                                    </cfloop>
                                    </cfoutput>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="due_datex" class="form-label">Vade (Gün)</label>
                                <input type="number" class="form-control" id="due_datex" name="due_datex" min="0"
                                       value="<cfif isDefined('form.due_datex')><cfoutput>#htmlEditFormat(form.due_datex)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-3">
                                <label for="first_payment_interest" class="form-label">İlk Ödeme Faizi (%)</label>
                                <input type="number" class="form-control" id="first_payment_interest" name="first_payment_interest" step="0.01"
                                       value="<cfif isDefined('form.first_payment_interest')><cfoutput>#htmlEditFormat(form.first_payment_interest)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-3">
                                <label for="last_payment_interest" class="form-label">Son Ödeme Faizi (%)</label>
                                <input type="number" class="form-control" id="last_payment_interest" name="last_payment_interest" step="0.01"
                                       value="<cfif isDefined('form.last_payment_interest')><cfoutput>#htmlEditFormat(form.last_payment_interest)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-3">
                                <label for="payment_blokaj" class="form-label">Ödeme Blokajı</label>
                                <input type="number" class="form-control" id="payment_blokaj" name="payment_blokaj" step="0.01"
                                       value="<cfif isDefined('form.payment_blokaj')><cfoutput>#htmlEditFormat(form.payment_blokaj)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-3">
                                <label for="payment_blokaj_type" class="form-label">Blokaj Tipi</label>
                                <input type="number" class="form-control" id="payment_blokaj_type" name="payment_blokaj_type" min="0"
                                       value="<cfif isDefined('form.payment_blokaj_type')><cfoutput>#htmlEditFormat(form.payment_blokaj_type)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-3">
                                <label for="price_cat" class="form-label">Satış Fiyat Listesi</label>
                                <select class="form-select" id="price_cat" name="price_cat">
                                    <option value="">-- Seçin --</option>
                                    <cfoutput>
                                    <cfloop query="getSalesPriceCats">
                                        <option value="#price_catid#"
                                            <cfif isDefined("form.price_cat") AND val(form.price_cat) eq price_catid>selected</cfif>
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
                                            <cfif isDefined("form.price_cat_purchase") AND val(form.price_cat_purchase) eq price_catid>selected</cfif>
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
                                           <cfif isDefined("form.is_blacklist") AND (form.is_blacklist eq "true" OR form.is_blacklist eq "1")>checked</cfif>>
                                    <label class="form-check-label fw-bold text-danger" for="is_blacklist">Kara Listede</label>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <label for="blacklist_date" class="form-label">Kara Liste Tarihi</label>
                                <input type="date" class="form-control" id="blacklist_date" name="blacklist_date"
                                       value="<cfif isDefined('form.blacklist_date') AND trim(form.blacklist_date) neq ''><cfoutput>#dateFormat(trim(form.blacklist_date), 'yyyy-mm-dd')#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-4">
                                <div class="form-check form-switch mt-4">
                                    <input class="form-check-input" type="checkbox" id="is_instalment_info" name="is_instalment_info" value="true"
                                           <cfif isDefined("form.is_instalment_info") AND (form.is_instalment_info eq "true" OR form.is_instalment_info eq "1")>checked</cfif>>
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
                        <i class="fas fa-save me-1"></i>Kaydet
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
