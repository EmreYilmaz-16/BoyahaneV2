<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.id" default="0">

<cfif val(url.id) eq 0>
    <cflocation url="/index.cfm?fuseaction=company.list_paymethod" addtoken="false">
    <cfabort>
</cfif>

<cfquery name="getRecord" datasource="boyahane">
    SELECT * FROM setup_paymethod
    WHERE paymethod_id = <cfqueryparam value="#val(url.id)#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif getRecord.recordCount eq 0>
    <cflocation url="/index.cfm?fuseaction=company.list_paymethod" addtoken="false">
    <cfabort>
</cfif>

<cfif structKeyExists(form, "submit")>
    <cfparam name="form.paymethod"               default="">
    <cfparam name="form.detail"                  default="">
    <cfparam name="form.in_advance"              default="">
    <cfparam name="form.due_day"                 default="">
    <cfparam name="form.due_month"               default="">
    <cfparam name="form.due_date_rate"           default="">
    <cfparam name="form.compound_rate"           default="">
    <cfparam name="form.money"                   default="">
    <cfparam name="form.first_interest_rate"     default="">
    <cfparam name="form.delay_interest_day"      default="">
    <cfparam name="form.delay_interest_rate"     default="">
    <cfparam name="form.due_start_day"           default="">
    <cfparam name="form.payment_means_code"      default="">
    <cfparam name="form.payment_means_code_name" default="">
    <cfparam name="form.paymethod_status"        default="false">
    <cfparam name="form.is_partner"              default="false">
    <cfparam name="form.is_public"               default="false">
    <cfparam name="form.financial_compound_rate" default="false">
    <cfparam name="form.balanced_payment"        default="false">
    <cfparam name="form.no_compound_rate"        default="false">
    <cfparam name="form.is_due_endofmonth"       default="false">
    <cfparam name="form.is_due_beginofmonth"     default="false">
    <cfparam name="form.is_date_control"         default="false">
    <cfparam name="form.is_business_due_day"     default="false">

    <cfif trim(form.paymethod) eq "">
        <cfset errorMsg = "Ödeme yöntemi adı zorunludur!">
    <cfelse>
        <cftry>
            <cfquery datasource="boyahane">
                UPDATE setup_paymethod SET
                    paymethod               = <cfqueryparam value="#trim(form.paymethod)#" cfsqltype="cf_sql_varchar">,
                    detail                  = <cfqueryparam value="#trim(form.detail)#" cfsqltype="cf_sql_varchar" null="#trim(form.detail) eq ''#">,
                    in_advance              = <cfqueryparam value="#val(form.in_advance)#" cfsqltype="cf_sql_integer" null="#trim(form.in_advance) eq ''#">,
                    due_day                 = <cfqueryparam value="#val(form.due_day)#" cfsqltype="cf_sql_integer" null="#trim(form.due_day) eq ''#">,
                    due_month               = <cfqueryparam value="#val(form.due_month)#" cfsqltype="cf_sql_integer" null="#trim(form.due_month) eq ''#">,
                    due_date_rate           = <cfqueryparam value="#val(form.due_date_rate)#" cfsqltype="cf_sql_numeric" null="#trim(form.due_date_rate) eq ''#">,
                    compound_rate           = <cfqueryparam value="#val(form.compound_rate)#" cfsqltype="cf_sql_integer" null="#trim(form.compound_rate) eq ''#">,
                    money                   = <cfqueryparam value="#trim(form.money)#" cfsqltype="cf_sql_varchar" null="#trim(form.money) eq ''#">,
                    first_interest_rate     = <cfqueryparam value="#val(form.first_interest_rate)#" cfsqltype="cf_sql_numeric" null="#trim(form.first_interest_rate) eq ''#">,
                    delay_interest_day      = <cfqueryparam value="#val(form.delay_interest_day)#" cfsqltype="cf_sql_integer" null="#trim(form.delay_interest_day) eq ''#">,
                    delay_interest_rate     = <cfqueryparam value="#val(form.delay_interest_rate)#" cfsqltype="cf_sql_numeric" null="#trim(form.delay_interest_rate) eq ''#">,
                    due_start_day           = <cfqueryparam value="#val(form.due_start_day)#" cfsqltype="cf_sql_integer" null="#trim(form.due_start_day) eq ''#">,
                    payment_means_code      = <cfqueryparam value="#trim(form.payment_means_code)#" cfsqltype="cf_sql_varchar" null="#trim(form.payment_means_code) eq ''#">,
                    payment_means_code_name = <cfqueryparam value="#trim(form.payment_means_code_name)#" cfsqltype="cf_sql_varchar" null="#trim(form.payment_means_code_name) eq ''#">,
                    paymethod_status        = <cfqueryparam value="#form.paymethod_status eq 'true' OR form.paymethod_status eq '1'#" cfsqltype="cf_sql_bit">,
                    is_partner              = <cfqueryparam value="#form.is_partner eq 'true' OR form.is_partner eq '1'#" cfsqltype="cf_sql_bit">,
                    is_public               = <cfqueryparam value="#form.is_public eq 'true' OR form.is_public eq '1'#" cfsqltype="cf_sql_bit">,
                    financial_compound_rate = <cfqueryparam value="#form.financial_compound_rate eq 'true' OR form.financial_compound_rate eq '1'#" cfsqltype="cf_sql_bit">,
                    balanced_payment        = <cfqueryparam value="#form.balanced_payment eq 'true' OR form.balanced_payment eq '1'#" cfsqltype="cf_sql_bit">,
                    no_compound_rate        = <cfqueryparam value="#form.no_compound_rate eq 'true' OR form.no_compound_rate eq '1'#" cfsqltype="cf_sql_bit">,
                    is_due_endofmonth       = <cfqueryparam value="#form.is_due_endofmonth eq 'true' OR form.is_due_endofmonth eq '1'#" cfsqltype="cf_sql_bit">,
                    is_due_beginofmonth     = <cfqueryparam value="#form.is_due_beginofmonth eq 'true' OR form.is_due_beginofmonth eq '1'#" cfsqltype="cf_sql_bit">,
                    is_date_control         = <cfqueryparam value="#form.is_date_control eq 'true' OR form.is_date_control eq '1'#" cfsqltype="cf_sql_bit">,
                    is_business_due_day     = <cfqueryparam value="#form.is_business_due_day eq 'true' OR form.is_business_due_day eq '1'#" cfsqltype="cf_sql_bit">,
                    update_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    update_ip   = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                WHERE paymethod_id = <cfqueryparam value="#val(url.id)#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cflocation url="/index.cfm?fuseaction=company.list_paymethod&success=updated" addtoken="false">
            <cfabort>
            <cfcatch type="any">
                <cfset errorMsg = "Güncelleme sırasında hata: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
    <cfquery name="getRecord" datasource="boyahane">
        SELECT * FROM setup_paymethod WHERE paymethod_id = <cfqueryparam value="#val(url.id)#" cfsqltype="cf_sql_integer">
    </cfquery>
</cfif>

<cfset rec = getRecord>

<!--- Helper macro: boolean field checked state --->
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

<cffunction name="fval" returntype="string" output="false">
    <cfargument name="fieldName" type="string">
    <cfargument name="dbVal" default="">
    <cfif structKeyExists(form, fieldName)>
        <cfreturn htmlEditFormat(form[arguments.fieldName])>
    </cfif>
    <cfreturn htmlEditFormat(arguments.dbVal ?: "")>
</cffunction>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-credit-card"></i></div>
        <div class="page-header-title">
            <h1>Ödeme Yöntemi Düzenle</h1>
            <p><cfoutput>#htmlEditFormat(rec.paymethod)#</cfoutput></p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=company.list_paymethod" class="btn-back">
        <i class="fas fa-arrow-left"></i>Geri Dön
    </a>
</div>

<div class="px-3 pb-4">
    <div class="row justify-content-center">
        <div class="col-lg-9">
            <cfif isDefined("errorMsg")>
                <div class="alert alert-danger alert-dismissible fade show mb-3">
                    <i class="fas fa-exclamation-circle me-2"></i>
                    <cfoutput>#errorMsg#</cfoutput>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            </cfif>

            <form method="post" id="pmForm">

                <!--- Temel Bilgiler --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Temel Bilgiler</div>
                        <small class="text-muted">ID: <cfoutput>#rec.paymethod_id#</cfoutput></small>
                    </div>
                    <div class="p-4">
                        <div class="row g-3">
                            <div class="col-md-8">
                                <label for="paymethod" class="form-label">Ödeme Yöntemi Adı <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" id="paymethod" name="paymethod"
                                       value="<cfoutput>#fval('paymethod', rec.paymethod)#</cfoutput>" required>
                            </div>
                            <div class="col-md-4">
                                <label for="money" class="form-label">Para Birimi</label>
                                <input type="text" class="form-control" id="money" name="money"
                                       value="<cfoutput>#fval('money', rec.money)#</cfoutput>">
                            </div>
                            <div class="col-12">
                                <label for="detail" class="form-label">Açıklama</label>
                                <textarea class="form-control" id="detail" name="detail" rows="2"><cfoutput>#fval('detail', rec.detail)#</cfoutput></textarea>
                            </div>
                        </div>
                    </div>
                </div>

                <!--- Vade Bilgileri --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-calendar-alt"></i>Vade & Faiz Bilgileri</div>
                    </div>
                    <div class="p-4">
                        <div class="row g-3">
                            <div class="col-md-3">
                                <label for="in_advance" class="form-label">Ön Ödeme</label>
                                <input type="number" class="form-control" id="in_advance" name="in_advance" step="1" min="0"
                                       value="<cfoutput>#fval('in_advance', rec.in_advance)#</cfoutput>">
                            </div>
                            <div class="col-md-3">
                                <label for="due_day" class="form-label">Vade Günü</label>
                                <input type="number" class="form-control" id="due_day" name="due_day" step="1" min="0"
                                       value="<cfoutput>#fval('due_day', rec.due_day)#</cfoutput>">
                            </div>
                            <div class="col-md-3">
                                <label for="due_month" class="form-label">Vade Ayı</label>
                                <input type="number" class="form-control" id="due_month" name="due_month" step="1" min="0"
                                       value="<cfoutput>#fval('due_month', rec.due_month)#</cfoutput>">
                            </div>
                            <div class="col-md-3">
                                <label for="due_start_day" class="form-label">Vade Başlangıç Günü</label>
                                <input type="number" class="form-control" id="due_start_day" name="due_start_day" step="1" min="0"
                                       value="<cfoutput>#fval('due_start_day', rec.due_start_day)#</cfoutput>">
                            </div>
                            <div class="col-md-4">
                                <label for="due_date_rate" class="form-label">Vade Oranı (%)</label>
                                <input type="number" class="form-control" id="due_date_rate" name="due_date_rate" step="0.01"
                                       value="<cfoutput>#fval('due_date_rate', rec.due_date_rate)#</cfoutput>">
                            </div>
                            <div class="col-md-4">
                                <label for="first_interest_rate" class="form-label">İlk Faiz Oranı (%)</label>
                                <input type="number" class="form-control" id="first_interest_rate" name="first_interest_rate" step="0.01"
                                       value="<cfoutput>#fval('first_interest_rate', rec.first_interest_rate)#</cfoutput>">
                            </div>
                            <div class="col-md-4">
                                <label for="compound_rate" class="form-label">Bileşik Faiz</label>
                                <input type="number" class="form-control" id="compound_rate" name="compound_rate" step="1"
                                       value="<cfoutput>#fval('compound_rate', rec.compound_rate)#</cfoutput>">
                            </div>
                            <div class="col-md-4">
                                <label for="delay_interest_day" class="form-label">Gecikme Faiz Günü</label>
                                <input type="number" class="form-control" id="delay_interest_day" name="delay_interest_day" step="1"
                                       value="<cfoutput>#fval('delay_interest_day', rec.delay_interest_day)#</cfoutput>">
                            </div>
                            <div class="col-md-4">
                                <label for="delay_interest_rate" class="form-label">Gecikme Faiz Oranı (%)</label>
                                <input type="number" class="form-control" id="delay_interest_rate" name="delay_interest_rate" step="0.01"
                                       value="<cfoutput>#fval('delay_interest_rate', rec.delay_interest_rate)#</cfoutput>">
                            </div>
                        </div>
                    </div>
                </div>

                <!--- E-Fatura & Seçenekler --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-file-invoice"></i>E-Fatura & Seçenekler</div>
                    </div>
                    <div class="p-4">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label for="payment_means_code" class="form-label">E-Fatura Ödeme Kodu</label>
                                <input type="text" class="form-control" id="payment_means_code" name="payment_means_code"
                                       value="<cfoutput>#fval('payment_means_code', rec.payment_means_code)#</cfoutput>">
                            </div>
                            <div class="col-md-8">
                                <label for="payment_means_code_name" class="form-label">E-Fatura Ödeme Kodu Adı</label>
                                <input type="text" class="form-control" id="payment_means_code_name" name="payment_means_code_name"
                                       value="<cfoutput>#fval('payment_means_code_name', rec.payment_means_code_name)#</cfoutput>">
                            </div>

                            <div class="col-12">
                                <div class="row g-3">
                                    <cfset switches = [
                                        {"f":"paymethod_status",        "l":"Aktif"},
                                        {"f":"is_public",               "l":"Genel Kullanım"},
                                        {"f":"is_partner",              "l":"Yetkili Kullanımı"},
                                        {"f":"financial_compound_rate", "l":"Finansal Bileşik Faiz"},
                                        {"f":"balanced_payment",        "l":"Dengeli Ödeme"},
                                        {"f":"no_compound_rate",        "l":"Bileşik Faiz Yok"},
                                        {"f":"is_due_endofmonth",       "l":"Ay Sonu Vade"},
                                        {"f":"is_due_beginofmonth",     "l":"Ay Başı Vade"},
                                        {"f":"is_date_control",         "l":"Tarih Kontrolü"},
                                        {"f":"is_business_due_day",     "l":"İş Günü Vade"}
                                    ]>
                                    <cfoutput>
                                    <cfloop array="#switches#" item="sw">
                                        <div class="col-md-3"><div class="form-check form-switch">
                                            <input class="form-check-input" type="checkbox" id="#sw.f#" name="#sw.f#" value="true" #chk(sw.f, rec[sw.f])#>
                                            <label class="form-check-label" for="#sw.f#">#sw.l#</label>
                                        </div></div>
                                    </cfloop>
                                    </cfoutput>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="d-flex gap-2 justify-content-end">
                    <a href="/index.cfm?fuseaction=company.list_paymethod" class="btn btn-secondary">
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
