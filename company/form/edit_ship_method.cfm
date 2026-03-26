<cfprocessingdirective pageEncoding="utf-8">

<cfparam name="url.id" default="0">

<cfif val(url.id) eq 0>
    <cflocation url="/index.cfm?fuseaction=company.list_ship_method" addtoken="false">
    <cfabort>
</cfif>

<cfquery name="getRecord" datasource="boyahane">
    SELECT * FROM ship_method
    WHERE ship_method_id = <cfqueryparam value="#val(url.id)#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif getRecord.recordCount eq 0>
    <cflocation url="/index.cfm?fuseaction=company.list_ship_method" addtoken="false">
    <cfabort>
</cfif>

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
                UPDATE ship_method SET
                    ship_method  = <cfqueryparam value="#trim(form.ship_method)#" cfsqltype="cf_sql_varchar">,
                    calculate    = <cfqueryparam value="#trim(form.calculate)#" cfsqltype="cf_sql_varchar" null="#trim(form.calculate) eq ''#">,
                    ship_day     = <cfqueryparam value="#trim(form.ship_day)#" cfsqltype="cf_sql_varchar" null="#trim(form.ship_day) eq ''#">,
                    ship_hour    = <cfqueryparam value="#trim(form.ship_hour)#" cfsqltype="cf_sql_varchar" null="#trim(form.ship_hour) eq ''#">,
                    is_opposite  = <cfqueryparam value="#form.is_opposite eq 'true' OR form.is_opposite eq '1'#" cfsqltype="cf_sql_bit">,
                    is_internet  = <cfqueryparam value="#form.is_internet eq 'true' OR form.is_internet eq '1'#" cfsqltype="cf_sql_bit">,
                    update_date  = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    update_ip    = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                WHERE ship_method_id = <cfqueryparam value="#val(url.id)#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cflocation url="/index.cfm?fuseaction=company.list_ship_method&success=updated" addtoken="false">
            <cfabort>
            <cfcatch type="any">
                <cfset errorMsg = "Güncelleme sırasında hata: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
    <!--- re-fetch after failed update --->
    <cfquery name="getRecord" datasource="boyahane">
        SELECT * FROM ship_method WHERE ship_method_id = <cfqueryparam value="#val(url.id)#" cfsqltype="cf_sql_integer">
    </cfquery>
</cfif>

<cfset rec = getRecord>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-truck"></i></div>
        <div class="page-header-title">
            <h1>Sevkiyat Yöntemi Düzenle</h1>
            <p><cfoutput>#htmlEditFormat(rec.ship_method)#</cfoutput></p>
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
                    <small class="text-muted">ID: <cfoutput>#rec.ship_method_id#</cfoutput></small>
                </div>
                <div class="p-4">
                    <form method="post" id="smForm">

                        <div class="mb-3">
                            <label for="ship_method" class="form-label">Sevkiyat Yöntemi <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="ship_method" name="ship_method"
                                   value="<cfoutput>#htmlEditFormat(structKeyExists(form,'ship_method') ? form.ship_method : rec.ship_method)#</cfoutput>" required>
                        </div>

                        <div class="mb-3">
                            <label for="calculate" class="form-label">Hesaplama Formülü</label>
                            <input type="text" class="form-control" id="calculate" name="calculate"
                                   value="<cfoutput>#htmlEditFormat(structKeyExists(form,'calculate') ? form.calculate : (rec.calculate ?: ''))#</cfoutput>">
                        </div>

                        <div class="row g-3 mb-3">
                            <div class="col-md-6">
                                <label for="ship_day" class="form-label">Teslimat Günü</label>
                                <input type="text" class="form-control" id="ship_day" name="ship_day"
                                       value="<cfoutput>#htmlEditFormat(structKeyExists(form,'ship_day') ? form.ship_day : (rec.ship_day ?: ''))#</cfoutput>">
                            </div>
                            <div class="col-md-6">
                                <label for="ship_hour" class="form-label">Teslimat Saati</label>
                                <input type="text" class="form-control" id="ship_hour" name="ship_hour"
                                       value="<cfoutput>#htmlEditFormat(structKeyExists(form,'ship_hour') ? form.ship_hour : (rec.ship_hour ?: ''))#</cfoutput>">
                            </div>
                        </div>

                        <div class="row g-3 mb-4">
                            <div class="col-md-6">
                                <label class="form-label">Karşı Ödemeli</label>
                                <div class="form-check form-switch mt-1">
                                    <input class="form-check-input" type="checkbox" id="is_opposite" name="is_opposite"
                                           value="true" <cfoutput><cfif (structKeyExists(form,'is_opposite') AND (form.is_opposite eq 'true' OR form.is_opposite eq '1')) OR (NOT structKeyExists(form,'submit') AND isBoolean(rec.is_opposite) AND rec.is_opposite)>checked</cfif></cfoutput>>
                                    <label class="form-check-label" for="is_opposite">Karşı ödemeli</label>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label">İnternet</label>
                                <div class="form-check form-switch mt-1">
                                    <input class="form-check-input" type="checkbox" id="is_internet" name="is_internet"
                                           value="true" <cfoutput><cfif (structKeyExists(form,'is_internet') AND (form.is_internet eq 'true' OR form.is_internet eq '1')) OR (NOT structKeyExists(form,'submit') AND isBoolean(rec.is_internet) AND rec.is_internet)>checked</cfif></cfoutput>>
                                    <label class="form-check-label" for="is_internet">İnternet teslimat</label>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex gap-2 justify-content-end">
                            <a href="/index.cfm?fuseaction=company.list_ship_method" class="btn btn-secondary">
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
    </div>
</div>
