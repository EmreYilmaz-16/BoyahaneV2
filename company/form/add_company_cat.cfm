<cfprocessingdirective pageEncoding="utf-8">

<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<cfif structKeyExists(form, "submit")>
    <cfparam name="form.companycat"      default="">
    <cfparam name="form.detail"          default="">
    <cfparam name="form.companycat_type" default="false">
    <cfparam name="form.is_active"       default="true">
    <cfparam name="form.is_view"         default="false">

    <cfif trim(form.companycat) eq "">
        <cfset errorMsg = "Kategori adı zorunludur!">
    <cfelse>
        <cftry>
            <cfquery datasource="boyahane">
                INSERT INTO company_cat (companycat, detail, companycat_type, is_active, is_view, record_date, record_emp, record_ip)
                VALUES (
                    <cfqueryparam value="#trim(form.companycat)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(form.detail)#" cfsqltype="cf_sql_varchar" null="#trim(form.detail) eq ''#">,
                    <cfqueryparam value="#form.companycat_type eq 'true' OR form.companycat_type eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.is_active eq 'true' OR form.is_active eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.is_view eq 'true' OR form.is_view eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    <cfqueryparam value="#structKeyExists(session,'user') ? session.user.id : 0#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                )
            </cfquery>
            <cflocation url="/index.cfm?fuseaction=company.list_company_cat&success=added" addtoken="false">
            <cfabort>
            <cfcatch type="any">
                <cfset errorMsg = "Kategori eklenirken hata oluştu: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-tags"></i></div>
        <div class="page-header-title">
            <h1>Yeni Firma Kategorisi</h1>
            <p>Yeni kategori bilgilerini doldurun</p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=company.list_company_cat" class="btn-back">
        <i class="fas fa-arrow-left"></i>Geri Dön
    </a>
</div>

<div class="px-3 pb-4">
    <div class="row justify-content-center">
        <div class="col-lg-6">

            <cfif isDefined("errorMsg")>
                <div class="alert alert-danger alert-dismissible fade show mb-3" role="alert">
                    <i class="fas fa-exclamation-circle me-2"></i>
                    <cfoutput>#errorMsg#</cfoutput>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
            </cfif>

            <div class="grid-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-tags"></i>Kategori Bilgileri</div>
                </div>
                <div class="p-4">
                    <form method="post" id="catForm">

                        <div class="mb-3">
                            <label for="companycat" class="form-label">Kategori Adı <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="companycat" name="companycat"
                                   placeholder="Kategori adını giriniz"
                                   value="<cfif isDefined('form.companycat')><cfoutput>#htmlEditFormat(form.companycat)#</cfoutput></cfif>" required>
                        </div>

                        <div class="mb-3">
                            <label for="detail" class="form-label">Açıklama</label>
                            <textarea class="form-control" id="detail" name="detail" rows="3"
                                      placeholder="Açıklama (opsiyonel)"><cfif isDefined("form.detail")><cfoutput>#htmlEditFormat(form.detail)#</cfoutput></cfif></textarea>
                        </div>

                        <div class="row g-3 mb-3">
                            <div class="col-md-4">
                                <label class="form-label">Kategori Tipi</label>
                                <div class="form-check form-switch mt-1">
                                    <input class="form-check-input" type="checkbox" id="companycat_type" name="companycat_type"
                                           value="true" <cfif isDefined("form.companycat_type") AND (form.companycat_type eq "true" OR form.companycat_type eq "1")>checked</cfif>>
                                    <label class="form-check-label" for="companycat_type">Ticari (işaretli = Ticari, işaretsiz = Bireysel)</label>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Aktif</label>
                                <div class="form-check form-switch mt-1">
                                    <input class="form-check-input" type="checkbox" id="is_active" name="is_active"
                                           value="true" <cfif NOT isDefined("form.is_active") OR (form.is_active eq "true" OR form.is_active eq "1")>checked</cfif>>
                                    <label class="form-check-label" for="is_active">Aktif</label>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Görünür</label>
                                <div class="form-check form-switch mt-1">
                                    <input class="form-check-input" type="checkbox" id="is_view" name="is_view"
                                           value="true" <cfif isDefined("form.is_view") AND (form.is_view eq "true" OR form.is_view eq "1")>checked</cfif>>
                                    <label class="form-check-label" for="is_view">Görünür</label>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex gap-2 justify-content-end mt-4">
                            <a href="/index.cfm?fuseaction=company.list_company_cat" class="btn btn-secondary">
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
