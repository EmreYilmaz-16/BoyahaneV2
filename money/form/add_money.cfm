<cfprocessingdirective pageEncoding="utf-8">

<cfif structKeyExists(form, "submit")>
    <cfparam name="form.money"          default="">
    <cfparam name="form.money_name"     default="">
    <cfparam name="form.money_symbol"   default="">
    <cfparam name="form.currency_code"  default="">
    <cfparam name="form.rate1"          default="">
    <cfparam name="form.rate2"          default="">
    <cfparam name="form.rate3"          default="">
    <cfparam name="form.effective_sale" default="">
    <cfparam name="form.effective_pur"  default="">
    <cfparam name="form.money_status"   default="false">

    <cfif trim(form.money) eq "">
        <cfset errorMsg = "Para birimi kodu zorunludur!">
    <cfelse>
        <cftry>
            <cfquery datasource="boyahane">
                INSERT INTO setup_money (money, money_name, money_symbol, currency_code, rate1, rate2, rate3, effective_sale, effective_pur, money_status, record_date, record_ip)
                VALUES (
                    <cfqueryparam value="#uCase(trim(form.money))#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(form.money_name)#" cfsqltype="cf_sql_varchar" null="#trim(form.money_name) eq ''#">,
                    <cfqueryparam value="#trim(form.money_symbol)#" cfsqltype="cf_sql_varchar" null="#trim(form.money_symbol) eq ''#">,
                    <cfqueryparam value="#uCase(trim(form.currency_code))#" cfsqltype="cf_sql_varchar" null="#trim(form.currency_code) eq ''#">,
                    <cfqueryparam value="#val(form.rate1)#" cfsqltype="cf_sql_numeric" null="#trim(form.rate1) eq ''#">,
                    <cfqueryparam value="#val(form.rate2)#" cfsqltype="cf_sql_numeric" null="#trim(form.rate2) eq ''#">,
                    <cfqueryparam value="#val(form.rate3)#" cfsqltype="cf_sql_numeric" null="#trim(form.rate3) eq ''#">,
                    <cfqueryparam value="#val(form.effective_sale)#" cfsqltype="cf_sql_numeric" null="#trim(form.effective_sale) eq ''#">,
                    <cfqueryparam value="#val(form.effective_pur)#" cfsqltype="cf_sql_numeric" null="#trim(form.effective_pur) eq ''#">,
                    <cfqueryparam value="#form.money_status eq 'true' OR form.money_status eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                )
            </cfquery>
            <cflocation url="/index.cfm?fuseaction=money.list_money&success=added" addtoken="false">
            <cfabort>
            <cfcatch type="any">
                <cfset errorMsg = "Kayıt eklenirken hata: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-coins"></i></div>
        <div class="page-header-title">
            <h1>Yeni Para Birimi</h1>
            <p>Para birimi bilgilerini doldurun</p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=money.list_money" class="btn-back">
        <i class="fas fa-arrow-left"></i>Geri Dön
    </a>
</div>

<div class="px-3 pb-4">
    <cfif isDefined("errorMsg")>
        <div class="alert alert-danger alert-dismissible fade show mb-3" role="alert">
            <i class="fas fa-exclamation-circle me-2"></i>
            <cfoutput>#errorMsg#</cfoutput>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </cfif>

    <cfoutput>
    <form method="post" action="/index.cfm?fuseaction=money.add_money">

        <!--- Temel Bilgiler --->
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Temel Bilgiler</div>
            </div>
            <div class="card-body p-3">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label">Para Birimi Kodu <span class="text-danger">*</span></label>
                        <input type="text" class="form-control text-uppercase" name="money" maxlength="10"
                               placeholder="USD, EUR, TRY..." style="font-weight:bold;font-size:18px;letter-spacing:2px"
                               value="#htmlEditFormat(structKeyExists(form,'money') ? form.money : '')#">
                        <div class="form-text">TCMB'deki ISO 4217 kodu (ör: USD, EUR)</div>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Sembol</label>
                        <input type="text" class="form-control text-center" name="money_symbol" maxlength="10"
                               placeholder="$, €, ₺" style="font-size:20px"
                               value="#htmlEditFormat(structKeyExists(form,'money_symbol') ? form.money_symbol : '')#">
                    </div>
                    <div class="col-md-5">
                        <label class="form-label">Para Birimi Adı</label>
                        <input type="text" class="form-control" name="money_name" maxlength="100"
                               placeholder="Amerikan Doları, Euro, Türk Lirası..."
                               value="#htmlEditFormat(structKeyExists(form,'money_name') ? form.money_name : '')#">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">TCMB Kodu</label>
                        <input type="text" class="form-control text-uppercase" name="currency_code" maxlength="10"
                               placeholder="USD"
                               value="#htmlEditFormat(structKeyExists(form,'currency_code') ? form.currency_code : '')#">
                        <div class="form-text">XML'deki CurrencyCode</div>
                    </div>
                    <div class="col-md-2 d-flex align-items-end pb-2">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" id="money_status" name="money_status" value="true"
                                   #(!structKeyExists(form,'submit') OR (structKeyExists(form,'money_status') AND (form.money_status eq 'true' OR form.money_status eq '1'))) ? 'checked' : ''#>
                            <label class="form-check-label" for="money_status">Aktif</label>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!--- Kur Bilgileri --->
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-chart-line"></i>Kur Bilgileri</div>
            </div>
            <div class="card-body p-3">
                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label">Alış Kuru (Döviz)</label>
                        <input type="number" class="form-control" name="rate1" step="0.000001" min="0"
                               placeholder="0.000000"
                               value="#structKeyExists(form,'rate1') ? form.rate1 : ''#">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Satış Kuru (Döviz)</label>
                        <input type="number" class="form-control" name="rate2" step="0.000001" min="0"
                               placeholder="0.000000"
                               value="#structKeyExists(form,'rate2') ? form.rate2 : ''#">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Ortalama Kur</label>
                        <input type="number" class="form-control" name="rate3" step="0.000001" min="0"
                               placeholder="0.000000"
                               value="#structKeyExists(form,'rate3') ? form.rate3 : ''#">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Efektif Alış</label>
                        <input type="number" class="form-control" name="effective_pur" step="0.000001" min="0"
                               placeholder="0.000000"
                               value="#structKeyExists(form,'effective_pur') ? form.effective_pur : ''#">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Efektif Satış</label>
                        <input type="number" class="form-control" name="effective_sale" step="0.000001" min="0"
                               placeholder="0.000000"
                               value="#structKeyExists(form,'effective_sale') ? form.effective_sale : ''#">
                    </div>
                </div>
            </div>
        </div>

        <div class="d-flex gap-2 justify-content-end mb-4">
            <a href="/index.cfm?fuseaction=money.list_money" class="btn btn-secondary btn-lg">
                <i class="fas fa-times me-1"></i>İptal
            </a>
            <button type="submit" name="submit" value="1" class="btn btn-primary btn-lg">
                <i class="fas fa-save me-1"></i>Kaydet
            </button>
        </div>
    </form>
    </cfoutput>
</div>
