<cfprocessingdirective pageEncoding="utf-8">

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
    <cfparam name="form.paymethod_status"        default="true">
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
                INSERT INTO setup_paymethod (
                    paymethod, detail, in_advance, due_day, due_month, due_date_rate, compound_rate,
                    money, first_interest_rate, delay_interest_day, delay_interest_rate, due_start_day,
                    payment_means_code, payment_means_code_name, paymethod_status, is_partner, is_public,
                    financial_compound_rate, balanced_payment, no_compound_rate,
                    is_due_endofmonth, is_due_beginofmonth, is_date_control, is_business_due_day,
                    record_date, record_ip
                ) VALUES (
                    <cfqueryparam value="#trim(form.paymethod)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(form.detail)#" cfsqltype="cf_sql_varchar" null="#trim(form.detail) eq ''#">,
                    <cfqueryparam value="#val(form.in_advance)#" cfsqltype="cf_sql_integer" null="#trim(form.in_advance) eq ''#">,
                    <cfqueryparam value="#val(form.due_day)#" cfsqltype="cf_sql_integer" null="#trim(form.due_day) eq ''#">,
                    <cfqueryparam value="#val(form.due_month)#" cfsqltype="cf_sql_integer" null="#trim(form.due_month) eq ''#">,
                    <cfqueryparam value="#val(form.due_date_rate)#" cfsqltype="cf_sql_numeric" null="#trim(form.due_date_rate) eq ''#">,
                    <cfqueryparam value="#val(form.compound_rate)#" cfsqltype="cf_sql_integer" null="#trim(form.compound_rate) eq ''#">,
                    <cfqueryparam value="#trim(form.money)#" cfsqltype="cf_sql_varchar" null="#trim(form.money) eq ''#">,
                    <cfqueryparam value="#val(form.first_interest_rate)#" cfsqltype="cf_sql_numeric" null="#trim(form.first_interest_rate) eq ''#">,
                    <cfqueryparam value="#val(form.delay_interest_day)#" cfsqltype="cf_sql_integer" null="#trim(form.delay_interest_day) eq ''#">,
                    <cfqueryparam value="#val(form.delay_interest_rate)#" cfsqltype="cf_sql_numeric" null="#trim(form.delay_interest_rate) eq ''#">,
                    <cfqueryparam value="#val(form.due_start_day)#" cfsqltype="cf_sql_integer" null="#trim(form.due_start_day) eq ''#">,
                    <cfqueryparam value="#trim(form.payment_means_code)#" cfsqltype="cf_sql_varchar" null="#trim(form.payment_means_code) eq ''#">,
                    <cfqueryparam value="#trim(form.payment_means_code_name)#" cfsqltype="cf_sql_varchar" null="#trim(form.payment_means_code_name) eq ''#">,
                    <cfqueryparam value="#form.paymethod_status eq 'true' OR form.paymethod_status eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.is_partner eq 'true' OR form.is_partner eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.is_public eq 'true' OR form.is_public eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.financial_compound_rate eq 'true' OR form.financial_compound_rate eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.balanced_payment eq 'true' OR form.balanced_payment eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.no_compound_rate eq 'true' OR form.no_compound_rate eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.is_due_endofmonth eq 'true' OR form.is_due_endofmonth eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.is_due_beginofmonth eq 'true' OR form.is_due_beginofmonth eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.is_date_control eq 'true' OR form.is_date_control eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.is_business_due_day eq 'true' OR form.is_business_due_day eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                )
            </cfquery>
            <cflocation url="/index.cfm?fuseaction=company.list_paymethod&success=added" addtoken="false">
            <cfabort>
            <cfcatch type="any">
                <cfset errorMsg = "Kayıt eklenirken hata: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-credit-card"></i></div>
        <div class="page-header-title">
            <h1>Yeni Ödeme Yöntemi</h1>
            <p>Ödeme yöntemi bilgilerini doldurun</p>
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
                <div class="alert alert-danger alert-dismissible fade show mb-3" role="alert">
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
                    </div>
                    <div class="p-4">
                        <div class="row g-3">
                            <div class="col-md-8">
                                <label for="paymethod" class="form-label">Ödeme Yöntemi Adı <span class="text-danger">*</span></label>
                                <input type="text" class="form-control" id="paymethod" name="paymethod"
                                       placeholder="Örn: Nakit, Havale, Çek..."
                                       value="<cfif isDefined('form.paymethod')><cfoutput>#htmlEditFormat(form.paymethod)#</cfoutput></cfif>" required>
                            </div>
                            <div class="col-md-4">
                                <label for="money" class="form-label">Para Birimi</label>
                                <input type="text" class="form-control" id="money" name="money"
                                       placeholder="TRY, USD, EUR..."
                                       value="<cfif isDefined('form.money')><cfoutput>#htmlEditFormat(form.money)#</cfoutput></cfif>">
                            </div>
                            <div class="col-12">
                                <label for="detail" class="form-label">Açıklama</label>
                                <textarea class="form-control" id="detail" name="detail" rows="2"
                                          placeholder="Açıklama (opsiyonel)"><cfif isDefined("form.detail")><cfoutput>#htmlEditFormat(form.detail)#</cfoutput></cfif></textarea>
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
                                       value="<cfif isDefined('form.in_advance')><cfoutput>#htmlEditFormat(form.in_advance)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-3">
                                <label for="due_day" class="form-label">Vade Günü</label>
                                <input type="number" class="form-control" id="due_day" name="due_day" step="1" min="0"
                                       value="<cfif isDefined('form.due_day')><cfoutput>#htmlEditFormat(form.due_day)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-3">
                                <label for="due_month" class="form-label">Vade Ayı</label>
                                <input type="number" class="form-control" id="due_month" name="due_month" step="1" min="0"
                                       value="<cfif isDefined('form.due_month')><cfoutput>#htmlEditFormat(form.due_month)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-3">
                                <label for="due_start_day" class="form-label">Vade Başlangıç Günü</label>
                                <input type="number" class="form-control" id="due_start_day" name="due_start_day" step="1" min="0"
                                       value="<cfif isDefined('form.due_start_day')><cfoutput>#htmlEditFormat(form.due_start_day)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-4">
                                <label for="due_date_rate" class="form-label">Vade Oranı (%)</label>
                                <input type="number" class="form-control" id="due_date_rate" name="due_date_rate" step="0.01"
                                       value="<cfif isDefined('form.due_date_rate')><cfoutput>#htmlEditFormat(form.due_date_rate)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-4">
                                <label for="first_interest_rate" class="form-label">İlk Faiz Oranı (%)</label>
                                <input type="number" class="form-control" id="first_interest_rate" name="first_interest_rate" step="0.01"
                                       value="<cfif isDefined('form.first_interest_rate')><cfoutput>#htmlEditFormat(form.first_interest_rate)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-4">
                                <label for="compound_rate" class="form-label">Bileşik Faiz</label>
                                <input type="number" class="form-control" id="compound_rate" name="compound_rate" step="1"
                                       value="<cfif isDefined('form.compound_rate')><cfoutput>#htmlEditFormat(form.compound_rate)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-4">
                                <label for="delay_interest_day" class="form-label">Gecikme Faiz Günü</label>
                                <input type="number" class="form-control" id="delay_interest_day" name="delay_interest_day" step="1"
                                       value="<cfif isDefined('form.delay_interest_day')><cfoutput>#htmlEditFormat(form.delay_interest_day)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-4">
                                <label for="delay_interest_rate" class="form-label">Gecikme Faiz Oranı (%)</label>
                                <input type="number" class="form-control" id="delay_interest_rate" name="delay_interest_rate" step="0.01"
                                       value="<cfif isDefined('form.delay_interest_rate')><cfoutput>#htmlEditFormat(form.delay_interest_rate)#</cfoutput></cfif>">
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
                                       placeholder="CREDIT, CASH..."
                                       value="<cfif isDefined('form.payment_means_code')><cfoutput>#htmlEditFormat(form.payment_means_code)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-8">
                                <label for="payment_means_code_name" class="form-label">E-Fatura Ödeme Kodu Adı</label>
                                <input type="text" class="form-control" id="payment_means_code_name" name="payment_means_code_name"
                                       value="<cfif isDefined('form.payment_means_code_name')><cfoutput>#htmlEditFormat(form.payment_means_code_name)#</cfoutput></cfif>">
                            </div>

                            <div class="col-12">
                                <div class="row g-3">
                                    <div class="col-md-3"><div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="paymethod_status" name="paymethod_status" value="true"
                                               <cfif NOT isDefined("form.submit") OR (isDefined("form.paymethod_status") AND (form.paymethod_status eq "true" OR form.paymethod_status eq "1"))>checked</cfif>>
                                        <label class="form-check-label" for="paymethod_status">Aktif</label>
                                    </div></div>
                                    <div class="col-md-3"><div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="is_public" name="is_public" value="true"
                                               <cfif isDefined("form.is_public") AND (form.is_public eq "true" OR form.is_public eq "1")>checked</cfif>>
                                        <label class="form-check-label" for="is_public">Genel Kullanım</label>
                                    </div></div>
                                    <div class="col-md-3"><div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="is_partner" name="is_partner" value="true"
                                               <cfif isDefined("form.is_partner") AND (form.is_partner eq "true" OR form.is_partner eq "1")>checked</cfif>>
                                        <label class="form-check-label" for="is_partner">Yetkili Kullanımı</label>
                                    </div></div>
                                    <div class="col-md-3"><div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="financial_compound_rate" name="financial_compound_rate" value="true"
                                               <cfif isDefined("form.financial_compound_rate") AND (form.financial_compound_rate eq "true" OR form.financial_compound_rate eq "1")>checked</cfif>>
                                        <label class="form-check-label" for="financial_compound_rate">Finansal Bileşik Faiz</label>
                                    </div></div>
                                    <div class="col-md-3"><div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="balanced_payment" name="balanced_payment" value="true"
                                               <cfif isDefined("form.balanced_payment") AND (form.balanced_payment eq "true" OR form.balanced_payment eq "1")>checked</cfif>>
                                        <label class="form-check-label" for="balanced_payment">Dengeli Ödeme</label>
                                    </div></div>
                                    <div class="col-md-3"><div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="no_compound_rate" name="no_compound_rate" value="true"
                                               <cfif isDefined("form.no_compound_rate") AND (form.no_compound_rate eq "true" OR form.no_compound_rate eq "1")>checked</cfif>>
                                        <label class="form-check-label" for="no_compound_rate">Bileşik Faiz Yok</label>
                                    </div></div>
                                    <div class="col-md-3"><div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="is_due_endofmonth" name="is_due_endofmonth" value="true"
                                               <cfif isDefined("form.is_due_endofmonth") AND (form.is_due_endofmonth eq "true" OR form.is_due_endofmonth eq "1")>checked</cfif>>
                                        <label class="form-check-label" for="is_due_endofmonth">Ay Sonu Vade</label>
                                    </div></div>
                                    <div class="col-md-3"><div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="is_due_beginofmonth" name="is_due_beginofmonth" value="true"
                                               <cfif isDefined("form.is_due_beginofmonth") AND (form.is_due_beginofmonth eq "true" OR form.is_due_beginofmonth eq "1")>checked</cfif>>
                                        <label class="form-check-label" for="is_due_beginofmonth">Ay Başı Vade</label>
                                    </div></div>
                                    <div class="col-md-3"><div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="is_date_control" name="is_date_control" value="true"
                                               <cfif isDefined("form.is_date_control") AND (form.is_date_control eq "true" OR form.is_date_control eq "1")>checked</cfif>>
                                        <label class="form-check-label" for="is_date_control">Tarih Kontrolü</label>
                                    </div></div>
                                    <div class="col-md-3"><div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" id="is_business_due_day" name="is_business_due_day" value="true"
                                               <cfif isDefined("form.is_business_due_day") AND (form.is_business_due_day eq "true" OR form.is_business_due_day eq "1")>checked</cfif>>
                                        <label class="form-check-label" for="is_business_due_day">İş Günü Vade</label>
                                    </div></div>
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
                        <i class="fas fa-save me-1"></i>Kaydet
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
