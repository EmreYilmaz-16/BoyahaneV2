<cfprocessingdirective pageEncoding="utf-8">

<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<cfquery name="getCategories" datasource="boyahane">
    SELECT companycat_id, companycat, companycat_type FROM company_cat WHERE is_active = true ORDER BY companycat
</cfquery>

<cfif structKeyExists(form, "submit")>
    <cfparam name="form.company_status"  default="true">
    <cfparam name="form.companycat_id"   default="0">
    <cfparam name="form.member_code"     default="">
    <cfparam name="form.nickname"        default="">
    <cfparam name="form.fullname"        default="">
    <cfparam name="form.taxoffice"       default="">
    <cfparam name="form.taxno"           default="">
    <cfparam name="form.company_email"   default="">
    <cfparam name="form.homepage"        default="">
    <cfparam name="form.company_tel1"    default="">
    <cfparam name="form.company_tel2"    default="">
    <cfparam name="form.mobiltel"        default="">
    <cfparam name="form.company_address" default="">
    <cfparam name="form.is_buyer"        default="false">
    <cfparam name="form.is_seller"       default="false">
    <cfparam name="form.ispotantial"     default="false">
    <cfparam name="form.is_person"       default="false">
    <cfparam name="form.ozel_kod"        default="">
    <cfparam name="form.ozel_kod_1"      default="">
    <cfparam name="form.ozel_kod_2"      default="">

    <cfif trim(form.nickname) eq "" AND trim(form.fullname) eq "">
        <cfset errorMsg = "Kısa Ad veya Tam Ad alanlarından en az biri zorunludur!">
    <cfelse>
        <cftry>
            <cfquery datasource="boyahane">
                INSERT INTO company (
                    company_status, companycat_id, member_code, nickname, fullname,
                    taxoffice, taxno, company_email, homepage,
                    company_tel1, company_tel2, mobiltel, company_address,
                    is_buyer, is_seller, ispotantial, is_person,
                    ozel_kod, ozel_kod_1, ozel_kod_2,
                    record_date, record_emp, record_ip
                ) VALUES (
                    <cfqueryparam value="#form.company_status eq 'true' OR form.company_status eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#val(form.companycat_id)#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#trim(form.member_code)#" cfsqltype="cf_sql_varchar" null="#trim(form.member_code) eq ''#">,
                    <cfqueryparam value="#trim(form.nickname)#" cfsqltype="cf_sql_varchar" null="#trim(form.nickname) eq ''#">,
                    <cfqueryparam value="#trim(form.fullname)#" cfsqltype="cf_sql_varchar" null="#trim(form.fullname) eq ''#">,
                    <cfqueryparam value="#trim(form.taxoffice)#" cfsqltype="cf_sql_varchar" null="#trim(form.taxoffice) eq ''#">,
                    <cfqueryparam value="#trim(form.taxno)#" cfsqltype="cf_sql_varchar" null="#trim(form.taxno) eq ''#">,
                    <cfqueryparam value="#trim(form.company_email)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_email) eq ''#">,
                    <cfqueryparam value="#trim(form.homepage)#" cfsqltype="cf_sql_varchar" null="#trim(form.homepage) eq ''#">,
                    <cfqueryparam value="#trim(form.company_tel1)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_tel1) eq ''#">,
                    <cfqueryparam value="#trim(form.company_tel2)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_tel2) eq ''#">,
                    <cfqueryparam value="#trim(form.mobiltel)#" cfsqltype="cf_sql_varchar" null="#trim(form.mobiltel) eq ''#">,
                    <cfqueryparam value="#trim(form.company_address)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_address) eq ''#">,
                    <cfqueryparam value="#form.is_buyer eq 'true' OR form.is_buyer eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.is_seller eq 'true' OR form.is_seller eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.ispotantial eq 'true' OR form.ispotantial eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#form.is_person eq 'true' OR form.is_person eq '1'#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#trim(form.ozel_kod)#" cfsqltype="cf_sql_varchar" null="#trim(form.ozel_kod) eq ''#">,
                    <cfqueryparam value="#trim(form.ozel_kod_1)#" cfsqltype="cf_sql_varchar" null="#trim(form.ozel_kod_1) eq ''#">,
                    <cfqueryparam value="#trim(form.ozel_kod_2)#" cfsqltype="cf_sql_varchar" null="#trim(form.ozel_kod_2) eq ''#">,
                    <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    <cfqueryparam value="#structKeyExists(session,'user') ? session.user.id : 0#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                )
            </cfquery>
            <cflocation url="/index.cfm?fuseaction=company.list_company&success=added" addtoken="false">
            <cfabort>
            <cfcatch type="any">
                <cfset errorMsg = "Firma eklenirken hata oluştu: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-building"></i></div>
        <div class="page-header-title">
            <h1>Yeni Firma Ekle</h1>
            <p>Sisteme yeni firma kaydı ekleyin</p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=company.list_company" class="btn-back">
        <i class="fas fa-arrow-left"></i>Firma Listesi
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

    <form method="post" id="companyForm">

        <!--- Temel Bilgiler --->
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Temel Bilgiler</div>
            </div>
            <div class="card-body p-3">
                <div class="row g-3">
                    <div class="col-md-4">
                        <label for="nickname" class="form-label">Kısa Ad <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="nickname" name="nickname"
                               placeholder="Kısa ad / ticari isim"
                               value="<cfif isDefined('form.nickname')><cfoutput>#htmlEditFormat(form.nickname)#</cfoutput></cfif>">
                    </div>
                    <div class="col-md-8">
                        <label for="fullname" class="form-label">Tam Ad / Unvan</label>
                        <input type="text" class="form-control" id="fullname" name="fullname"
                               placeholder="Tam ticaret unvanı"
                               value="<cfif isDefined('form.fullname')><cfoutput>#htmlEditFormat(form.fullname)#</cfoutput></cfif>">
                    </div>
                    <div class="col-md-4">
                        <label for="companycat_id" class="form-label">Kategori</label>
                        <select class="form-select" id="companycat_id" name="companycat_id">
                            <option value="0">-- Kategori Seçin --</option>
                            <cfoutput query="getCategories">
                            <option value="#companycat_id#"
                                <cfif isDefined("form.companycat_id") AND form.companycat_id eq companycat_id>selected</cfif>>
                                #companycat# (#companycat_type ? "Ticari" : "Bireysel"#)
                            </option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label for="member_code" class="form-label">Üye Kodu</label>
                        <input type="text" class="form-control" id="member_code" name="member_code"
                               placeholder="Opsiyonel üye kodu"
                               value="<cfif isDefined('form.member_code')><cfoutput>#htmlEditFormat(form.member_code)#</cfoutput></cfif>">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Durum</label>
                        <div class="form-check form-switch mt-2">
                            <input class="form-check-input" type="checkbox" id="company_status" name="company_status"
                                   value="true" <cfif NOT isDefined("form.company_status") OR (form.company_status eq "true" OR form.company_status eq "1")>checked</cfif>>
                            <label class="form-check-label" for="company_status">Aktif</label>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!--- Tip Bilgileri --->
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-user-tag"></i>Firma Tipi</div>
            </div>
            <div class="card-body p-3">
                <div class="row g-3">
                    <div class="col-md-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" id="is_buyer" name="is_buyer" value="true"
                                   <cfif isDefined("form.is_buyer") AND (form.is_buyer eq "true" OR form.is_buyer eq "1")>checked</cfif>>
                            <label class="form-check-label" for="is_buyer"><i class="fas fa-shopping-cart text-success me-1"></i>Müşteri</label>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" id="is_seller" name="is_seller" value="true"
                                   <cfif isDefined("form.is_seller") AND (form.is_seller eq "true" OR form.is_seller eq "1")>checked</cfif>>
                            <label class="form-check-label" for="is_seller"><i class="fas fa-truck text-primary me-1"></i>Tedarikçi</label>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" id="ispotantial" name="ispotantial" value="true"
                                   <cfif isDefined("form.ispotantial") AND (form.ispotantial eq "true" OR form.ispotantial eq "1")>checked</cfif>>
                            <label class="form-check-label" for="ispotantial"><i class="fas fa-star text-warning me-1"></i>Potansiyel</label>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="form-check form-switch">
                            <input class="form-check-input" type="checkbox" id="is_person" name="is_person" value="true"
                                   <cfif isDefined("form.is_person") AND (form.is_person eq "true" OR form.is_person eq "1")>checked</cfif>>
                            <label class="form-check-label" for="is_person"><i class="fas fa-user me-1"></i>Gerçek Kişi</label>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!--- Vergi Bilgileri --->
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-file-invoice"></i>Vergi Bilgileri</div>
            </div>
            <div class="card-body p-3">
                <div class="row g-3">
                    <div class="col-md-6">
                        <label for="taxoffice" class="form-label">Vergi Dairesi</label>
                        <input type="text" class="form-control" id="taxoffice" name="taxoffice"
                               placeholder="Vergi dairesi adı"
                               value="<cfif isDefined('form.taxoffice')><cfoutput>#htmlEditFormat(form.taxoffice)#</cfoutput></cfif>">
                    </div>
                    <div class="col-md-6">
                        <label for="taxno" class="form-label">Vergi No / TC Kimlik No</label>
                        <input type="text" class="form-control" id="taxno" name="taxno"
                               placeholder="Vergi numarası veya TC kimlik no"
                               value="<cfif isDefined('form.taxno')><cfoutput>#htmlEditFormat(form.taxno)#</cfoutput></cfif>">
                    </div>
                </div>
            </div>
        </div>

        <!--- İletişim Bilgileri --->
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-phone"></i>İletişim Bilgileri</div>
            </div>
            <div class="card-body p-3">
                <div class="row g-3">
                    <div class="col-md-4">
                        <label for="company_tel1" class="form-label">Telefon 1</label>
                        <input type="text" class="form-control" id="company_tel1" name="company_tel1"
                               placeholder="(0xxx) xxx xx xx"
                               value="<cfif isDefined('form.company_tel1')><cfoutput>#htmlEditFormat(form.company_tel1)#</cfoutput></cfif>">
                    </div>
                    <div class="col-md-4">
                        <label for="company_tel2" class="form-label">Telefon 2</label>
                        <input type="text" class="form-control" id="company_tel2" name="company_tel2"
                               placeholder="(0xxx) xxx xx xx"
                               value="<cfif isDefined('form.company_tel2')><cfoutput>#htmlEditFormat(form.company_tel2)#</cfoutput></cfif>">
                    </div>
                    <div class="col-md-4">
                        <label for="mobiltel" class="form-label">Cep Telefonu</label>
                        <input type="text" class="form-control" id="mobiltel" name="mobiltel"
                               placeholder="05xx xxx xx xx"
                               value="<cfif isDefined('form.mobiltel')><cfoutput>#htmlEditFormat(form.mobiltel)#</cfoutput></cfif>">
                    </div>
                    <div class="col-md-6">
                        <label for="company_email" class="form-label">E-posta</label>
                        <input type="email" class="form-control" id="company_email" name="company_email"
                               placeholder="firma@ornek.com"
                               value="<cfif isDefined('form.company_email')><cfoutput>#htmlEditFormat(form.company_email)#</cfoutput></cfif>">
                    </div>
                    <div class="col-md-6">
                        <label for="homepage" class="form-label">Web Sitesi</label>
                        <input type="text" class="form-control" id="homepage" name="homepage"
                               placeholder="www.ornek.com"
                               value="<cfif isDefined('form.homepage')><cfoutput>#htmlEditFormat(form.homepage)#</cfoutput></cfif>">
                    </div>
                    <div class="col-12">
                        <label for="company_address" class="form-label">Adres</label>
                        <textarea class="form-control" id="company_address" name="company_address" rows="3"
                                  placeholder="Açık adres"><cfif isDefined("form.company_address")><cfoutput>#htmlEditFormat(form.company_address)#</cfoutput></cfif></textarea>
                    </div>
                </div>
            </div>
        </div>

        <!--- Özel Kodlar --->
        <div class="grid-card mb-3">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-code"></i>Özel Kodlar</div>
            </div>
            <div class="card-body p-3">
                <div class="row g-3">
                    <div class="col-md-4">
                        <label for="ozel_kod" class="form-label">Özel Kod 1</label>
                        <input type="text" class="form-control" id="ozel_kod" name="ozel_kod"
                               value="<cfif isDefined('form.ozel_kod')><cfoutput>#htmlEditFormat(form.ozel_kod)#</cfoutput></cfif>">
                    </div>
                    <div class="col-md-4">
                        <label for="ozel_kod_1" class="form-label">Özel Kod 2</label>
                        <input type="text" class="form-control" id="ozel_kod_1" name="ozel_kod_1"
                               value="<cfif isDefined('form.ozel_kod_1')><cfoutput>#htmlEditFormat(form.ozel_kod_1)#</cfoutput></cfif>">
                    </div>
                    <div class="col-md-4">
                        <label for="ozel_kod_2" class="form-label">Özel Kod 3</label>
                        <input type="text" class="form-control" id="ozel_kod_2" name="ozel_kod_2"
                               value="<cfif isDefined('form.ozel_kod_2')><cfoutput>#htmlEditFormat(form.ozel_kod_2)#</cfoutput></cfif>">
                    </div>
                </div>
            </div>
        </div>

        <div class="d-flex gap-2 justify-content-end">
            <a href="/index.cfm?fuseaction=company.list_company" class="btn btn-secondary btn-lg">
                <i class="fas fa-times me-1"></i>İptal
            </a>
            <button type="submit" name="submit" value="1" class="btn btn-primary btn-lg">
                <i class="fas fa-save me-1"></i>Kaydet
            </button>
        </div>
    </form>
</div>
