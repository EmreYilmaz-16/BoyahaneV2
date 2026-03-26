<cfprocessingdirective pageEncoding="utf-8">

<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<cfparam name="url.id" default="0">
<cfif val(url.id) eq 0>
    <cflocation url="/index.cfm?fuseaction=company.list_company_cat&error=notfound" addtoken="false">
    <cfabort>
</cfif>

<cfquery name="getCategory" datasource="boyahane">
    SELECT companycat_id, companycat, detail, companycat_type, is_active, is_view
    FROM company_cat
    WHERE companycat_id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif getCategory.recordCount eq 0>
    <cflocation url="/index.cfm?fuseaction=company.list_company_cat&error=notfound" addtoken="false">
    <cfabort>
</cfif>

<cfif structKeyExists(form, "submit")>
    <cfparam name="form.companycat"      default="">
    <cfparam name="form.detail"          default="">
    <cfparam name="form.companycat_type" default="false">
    <cfparam name="form.is_active"       default="false">
    <cfparam name="form.is_view"         default="false">

    <cfif trim(form.companycat) eq "">
        <cfset errorMsg = "Kategori adı zorunludur!">
    <cfelse>
        <cftry>
            <cfquery datasource="boyahane">
                UPDATE company_cat SET
                    companycat      = <cfqueryparam value="#trim(form.companycat)#" cfsqltype="cf_sql_varchar">,
                    detail          = <cfqueryparam value="#trim(form.detail)#" cfsqltype="cf_sql_varchar" null="#trim(form.detail) eq ''#">,
                    companycat_type = <cfqueryparam value="#form.companycat_type eq 'true' OR form.companycat_type eq '1'#" cfsqltype="cf_sql_bit">,
                    is_active       = <cfqueryparam value="#form.is_active eq 'true' OR form.is_active eq '1'#" cfsqltype="cf_sql_bit">,
                    is_view         = <cfqueryparam value="#form.is_view eq 'true' OR form.is_view eq '1'#" cfsqltype="cf_sql_bit">,
                    update_date     = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    update_emp      = <cfqueryparam value="#structKeyExists(session,'user') ? session.user.id : 0#" cfsqltype="cf_sql_integer">,
                    update_ip       = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                WHERE companycat_id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cflocation url="/index.cfm?fuseaction=company.list_company_cat&success=updated" addtoken="false">
            <cfabort>
            <cfcatch type="any">
                <cfset errorMsg = "Kategori güncellenirken hata oluştu: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<!--- Form değerleri: submit başarısızsa form'dan, aksi halde DB'den --->
<cfset fCompanycat      = structKeyExists(form,"companycat")      ? form.companycat      : getCategory.companycat>
<cfset fDetail          = structKeyExists(form,"detail")          ? form.detail          : getCategory.detail>
<cfset fCatType         = structKeyExists(form,"companycat_type") ? (form.companycat_type eq "true" OR form.companycat_type eq "1") : getCategory.companycat_type>
<cfset fIsActive        = structKeyExists(form,"is_active")       ? (form.is_active eq "true" OR form.is_active eq "1")            : getCategory.is_active>
<cfset fIsView          = structKeyExists(form,"is_view")         ? (form.is_view eq "true" OR form.is_view eq "1")                : getCategory.is_view>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-tags"></i></div>
        <div class="page-header-title">
            <h1>Firma Kategorisi Düzenle</h1>
            <p><cfoutput>#getCategory.companycat#</cfoutput></p>
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
                    <div class="grid-card-header-title"><i class="fas fa-edit"></i>Kategori Bilgileri</div>
                </div>
                <div class="p-4">
                    <cfoutput>
                    <form method="post" id="catForm" action="/index.cfm?fuseaction=company.edit_company_cat&id=#url.id#">

                        <div class="mb-3">
                            <label for="companycat" class="form-label">Kategori Adı <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="companycat" name="companycat"
                                   value="#htmlEditFormat(fCompanycat)#" required>
                        </div>

                        <div class="mb-3">
                            <label for="detail" class="form-label">Açıklama</label>
                            <textarea class="form-control" id="detail" name="detail" rows="3">#htmlEditFormat(fDetail)#</textarea>
                        </div>

                        <div class="row g-3 mb-3">
                            <div class="col-md-4">
                                <label class="form-label">Kategori Tipi</label>
                                <div class="form-check form-switch mt-1">
                                    <input class="form-check-input" type="checkbox" id="companycat_type" name="companycat_type"
                                           value="true" #fCatType ? 'checked' : ''#>
                                    <label class="form-check-label" for="companycat_type">Ticari</label>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Aktif</label>
                                <div class="form-check form-switch mt-1">
                                    <input class="form-check-input" type="checkbox" id="is_active" name="is_active"
                                           value="true" #fIsActive ? 'checked' : ''#>
                                    <label class="form-check-label" for="is_active">Aktif</label>
                                </div>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Görünür</label>
                                <div class="form-check form-switch mt-1">
                                    <input class="form-check-input" type="checkbox" id="is_view" name="is_view"
                                           value="true" #fIsView ? 'checked' : ''#>
                                    <label class="form-check-label" for="is_view">Görünür</label>
                                </div>
                            </div>
                        </div>

                        <div class="d-flex gap-2 justify-content-end mt-4">
                            <a href="/index.cfm?fuseaction=company.list_company_cat" class="btn btn-secondary">
                                <i class="fas fa-times me-1"></i>İptal
                            </a>
                            <button type="submit" name="submit" value="1" class="btn btn-primary">
                                <i class="fas fa-save me-1"></i>Güncelle
                            </button>
                        </div>
                    </form>
                    </cfoutput>
                </div>
            </div>
        </div>
    </div>
</div>
