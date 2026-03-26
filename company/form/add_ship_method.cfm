<cfprocessingdirective pageEncoding="utf-8">

<cfif structKeyExists(form, "submit")>
    <cfparam name="form.ship_method" default="">
    <cfparam name="form.calculate"   default="">
    <cfparam name="form.ship_day"    default="">
    <cfparam name="form.ship_hour"   default="">
    <cfparam name="form.is_opposite" default="false">
    <cfparam name="form.is_internet" default="false">

    <cfif trim(form.ship_method) eq "">
        <cfset errorMsg = "Sevkiyat yöntemi adı zorunludur!">
    <cfelse>
        <cftry>
            <cfquery datasource="boyahane">
                INSERT INTO ship_method (ship_method, calculate, ship_day, ship_hour, is_opposite, is_internet, record_date, record_ip)
                VALUES (
                    <cfqueryparam value="#trim(form.ship_method)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(form.calculate)#" cfsqltype="cf_sql_varchar" null="#trim(form.calculate) eq ''#">,
                    <cfqueryparam value="#trim(form.ship_day)#" cfsqltype="cf_sql_varchar" null="#trim(form.ship_day) eq ''#">,
                    <cfqueryparam value="#trim(form.ship_hour)#" cfsqltype="cf_sql_varchar" null="#trim(form.ship_hour) eq ''#">,
                    <cfqueryparam value="#form.is_opposite eq 'true' OR form.is_opposite eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.is_internet eq 'true' OR form.is_internet eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                )
            </cfquery>
            <cflocation url="/index.cfm?fuseaction=company.list_ship_method&success=added" addtoken="false">
            <cfabort>
            <cfcatch type="any">
                <cfset errorMsg = "Kayıt eklenirken hata: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-truck"></i></div>
        <div class="page-header-title">
            <h1>Yeni Sevkiyat Yöntemi</h1>
            <p>Sevkiyat yöntemi bilgilerini doldurun</p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=company.list_ship_method" class="btn-back">
        <i class="fas fa-arrow-left"></i>Geri Dön
    </a>
</div>

<div class="px-3 pb-4">
    <div class="row justify-content-center">
        <div class="col-lg-7">
            <cfif isDefined("errorMsg")>
                <div class="alert alert-danger alert-dismissible fade show mb-3" role="alert">
                    <i class="fas fa-exclamation-circle me-2"></i>
                    <cfoutput>#errorMsg#</cfoutput>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            </cfif>

            <div class="grid-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-truck"></i>Sevkiyat Bilgileri</div>
                </div>
                <div class="p-4">
                    <form method="post" id="smForm">

                        <div class="mb-3">
                            <label for="ship_method" class="form-label">Sevkiyat Yöntemi <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="ship_method" name="ship_method"
                                   placeholder="Örn: Kargo, Motorlu Kurye, Tır..."
                                   value="<cfif isDefined('form.ship_method')><cfoutput>#htmlEditFormat(form.ship_method)#</cfoutput></cfif>" required>
                        </div>

                        <div class="mb-3">
                            <label for="calculate" class="form-label">Hesaplama Formülü</label>
                            <input type="text" class="form-control" id="calculate" name="calculate"
                                   placeholder="Hesaplama formülü (opsiyonel)"
                                   value="<cfif isDefined('form.calculate')><cfoutput>#htmlEditFormat(form.calculate)#</cfoutput></cfif>">
                        </div>

                        <div class="row g-3 mb-3">
                            <div class="col-md-6">
                                <label for="ship_day" class="form-label">Teslimat Günü</label>
                                <input type="text" class="form-control" id="ship_day" name="ship_day"
                                       placeholder="Örn: 1-3 iş günü"
                                       value="<cfif isDefined('form.ship_day')><cfoutput>#htmlEditFormat(form.ship_day)#</cfoutput></cfif>">
                            </div>
                            <div class="col-md-6">
                                <label for="ship_hour" class="form-label">Teslimat Saati</label>
                                <input type="text" class="form-control" id="ship_hour" name="ship_hour"
                                       placeholder="Örn: 09:00-18:00"
                                       value="<cfif isDefined('form.ship_hour')><cfoutput>#htmlEditFormat(form.ship_hour)#</cfoutput></cfif>">
                            </div>
                        </div>

                        <div class="row g-3 mb-4">
                            <div class="col-md-6">
                                <label class="form-label">Karşı Ödemeli</label>
                                <div class="form-check form-switch mt-1">
                                    <input class="form-check-input" type="checkbox" id="is_opposite" name="is_opposite"
                                           value="true" <cfif isDefined("form.is_opposite") AND (form.is_opposite eq "true" OR form.is_opposite eq "1")>checked</cfif>>
                                    <label class="form-check-label" for="is_opposite">Karşı ödemeli sevkiyat</label>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">İnternet</label>
                                <div class="form-check form-switch mt-1">
                                    <input class="form-check-input" type="checkbox" id="is_internet" name="is_internet"
                                           value="true" <cfif isDefined("form.is_internet") AND (form.is_internet eq "true" OR form.is_internet eq "1")>checked</cfif>>
                                    <label class="form-check-label" for="is_internet">İnternet üzerinden teslimat</label>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex gap-2 justify-content-end">
                            <a href="/index.cfm?fuseaction=company.list_ship_method" class="btn btn-secondary">
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
    </div>
</div>
