<cfprocessingdirective pageEncoding="utf-8">

<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<cfparam name="url.id" default="0">
<cfif val(url.id) eq 0>
    <cflocation url="/index.cfm?fuseaction=company.list_company&error=notfound" addtoken="false">
    <cfabort>
</cfif>

<cfquery name="getCompany" datasource="boyahane">
    SELECT c.*, cc.companycat FROM company c
    LEFT JOIN company_cat cc ON c.companycat_id = cc.companycat_id
    WHERE c.company_id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif getCompany.recordCount eq 0>
    <cflocation url="/index.cfm?fuseaction=company.list_company&error=notfound" addtoken="false">
    <cfabort>
</cfif>

<cfquery name="getCategories" datasource="boyahane">
    SELECT companycat_id, companycat, companycat_type FROM company_cat WHERE is_active = true ORDER BY companycat
</cfquery>

<cfif structKeyExists(form, "submit")>
    <cfparam name="form.company_status"  default="false">
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
                UPDATE company SET
                    company_status  = <cfqueryparam value="#form.company_status eq 'true' OR form.company_status eq '1'#" cfsqltype="cf_sql_bit">,
                    companycat_id   = <cfqueryparam value="#val(form.companycat_id)#" cfsqltype="cf_sql_integer">,
                    member_code     = <cfqueryparam value="#trim(form.member_code)#" cfsqltype="cf_sql_varchar" null="#trim(form.member_code) eq ''#">,
                    nickname        = <cfqueryparam value="#trim(form.nickname)#" cfsqltype="cf_sql_varchar" null="#trim(form.nickname) eq ''#">,
                    fullname        = <cfqueryparam value="#trim(form.fullname)#" cfsqltype="cf_sql_varchar" null="#trim(form.fullname) eq ''#">,
                    taxoffice       = <cfqueryparam value="#trim(form.taxoffice)#" cfsqltype="cf_sql_varchar" null="#trim(form.taxoffice) eq ''#">,
                    taxno           = <cfqueryparam value="#trim(form.taxno)#" cfsqltype="cf_sql_varchar" null="#trim(form.taxno) eq ''#">,
                    company_email   = <cfqueryparam value="#trim(form.company_email)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_email) eq ''#">,
                    homepage        = <cfqueryparam value="#trim(form.homepage)#" cfsqltype="cf_sql_varchar" null="#trim(form.homepage) eq ''#">,
                    company_tel1    = <cfqueryparam value="#trim(form.company_tel1)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_tel1) eq ''#">,
                    company_tel2    = <cfqueryparam value="#trim(form.company_tel2)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_tel2) eq ''#">,
                    mobiltel        = <cfqueryparam value="#trim(form.mobiltel)#" cfsqltype="cf_sql_varchar" null="#trim(form.mobiltel) eq ''#">,
                    company_address = <cfqueryparam value="#trim(form.company_address)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_address) eq ''#">,
                    is_buyer        = <cfqueryparam value="#form.is_buyer eq 'true' OR form.is_buyer eq '1'#" cfsqltype="cf_sql_bit">,
                    is_seller       = <cfqueryparam value="#form.is_seller eq 'true' OR form.is_seller eq '1'#" cfsqltype="cf_sql_bit">,
                    ispotantial     = <cfqueryparam value="#form.ispotantial eq 'true' OR form.ispotantial eq '1'#" cfsqltype="cf_sql_bit">,
                    is_person       = <cfqueryparam value="#form.is_person eq 'true' OR form.is_person eq '1'#" cfsqltype="cf_sql_bit">,
                    ozel_kod        = <cfqueryparam value="#trim(form.ozel_kod)#" cfsqltype="cf_sql_varchar" null="#trim(form.ozel_kod) eq ''#">,
                    ozel_kod_1      = <cfqueryparam value="#trim(form.ozel_kod_1)#" cfsqltype="cf_sql_varchar" null="#trim(form.ozel_kod_1) eq ''#">,
                    ozel_kod_2      = <cfqueryparam value="#trim(form.ozel_kod_2)#" cfsqltype="cf_sql_varchar" null="#trim(form.ozel_kod_2) eq ''#">,
                    update_date     = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                    update_emp      = <cfqueryparam value="#structKeyExists(session,'user') ? session.user.id : 0#" cfsqltype="cf_sql_integer">,
                    update_ip       = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
                WHERE company_id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cflocation url="/index.cfm?fuseaction=company.list_company&success=updated" addtoken="false">
            <cfabort>
            <cfcatch type="any">
                <cfset errorMsg = "Firma güncellenirken hata oluştu: #cfcatch.message#">
            </cfcatch>
        </cftry>
    </cfif>
</cfif>

<!--- Şube ve Yetkili verileri JSON'a çevir --->
<cfquery name="getBranches" datasource="boyahane">
    SELECT compbranch_id, compbranch__name, compbranch__nickname, compbranch_tel1, compbranch_email, compbranch_address, compbranch_status
    FROM company_branch WHERE company_id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
    ORDER BY compbranch_id DESC
</cfquery>
<cfset branchesArr = []>
<cfloop query="getBranches">
    <cfset arrayAppend(branchesArr, {
        "compbranch_id":        compbranch_id,
        "compbranch__name":     compbranch__name ?: "",
        "compbranch__nickname": compbranch__nickname ?: "",
        "compbranch_tel1":      compbranch_tel1 ?: "",
        "compbranch_email":     compbranch_email ?: "",
        "compbranch_address":   compbranch_address ?: "",
        "compbranch_status":    compbranch_status
    })>
</cfloop>

<cfquery name="getPartners" datasource="boyahane">
    SELECT partner_id, company_partner_name, company_partner_surname, company_partner_email, mobiltel, company_partner_tel, title, company_partner_status
    FROM company_partner WHERE company_id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
    ORDER BY partner_id DESC
</cfquery>
<cfset partnersArr = []>
<cfloop query="getPartners">
    <cfset arrayAppend(partnersArr, {
        "partner_id":              partner_id,
        "company_partner_name":    company_partner_name ?: "",
        "company_partner_surname": company_partner_surname ?: "",
        "company_partner_email":   company_partner_email ?: "",
        "mobiltel":                mobiltel ?: "",
        "company_partner_tel":     company_partner_tel ?: "",
        "title":                   title ?: "",
        "company_partner_status":  company_partner_status
    })>
</cfloop>

<!--- Kredi kayıtları --->
<cfquery name="getCredits" datasource="boyahane">
    SELECT cc.company_credit_id, cc.money, cc.paymethod_id, cc.ship_method_id,
           cc.open_account_risk_limit, cc.forward_sale_limit, cc.total_risk_limit,
           cc.due_datex, cc.is_blacklist,
           pm.paymethod, sm.ship_method
    FROM company_credit cc
    LEFT JOIN setup_paymethod pm ON cc.paymethod_id = pm.paymethod_id
    LEFT JOIN ship_method sm     ON cc.ship_method_id = sm.ship_method_id
    WHERE cc.company_id = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
    ORDER BY cc.company_credit_id DESC
</cfquery>
<cfset creditsArr = []>
<cfloop query="getCredits">
    <cfset arrayAppend(creditsArr, {
        "company_credit_id":      company_credit_id,
        "money":                  money ?: "TRY",
        "open_account_risk_limit":isNumeric(open_account_risk_limit) ? open_account_risk_limit : 0,
        "forward_sale_limit":     isNumeric(forward_sale_limit) ? forward_sale_limit : 0,
        "total_risk_limit":       isNumeric(total_risk_limit) ? total_risk_limit : 0,
        "due_datex":              isNumeric(due_datex) ? due_datex : "",
        "is_blacklist":           is_blacklist,
        "paymethod_id":           isNumeric(paymethod_id) ? paymethod_id : 0,
        "ship_method_id":         isNumeric(ship_method_id) ? ship_method_id : 0,
        "paymethod":              paymethod ?: "",
        "ship_method":            ship_method ?: ""
    })>
</cfloop>

<!--- Form değerleri: submit başarısızsa form'dan, aksi halde DB'den --->
<cfset f = {
    "company_status":  structKeyExists(form,"company_status")  ? (form.company_status eq "true" OR form.company_status eq "1")    : getCompany.company_status,
    "companycat_id":   structKeyExists(form,"companycat_id")   ? val(form.companycat_id)                                          : getCompany.companycat_id,
    "member_code":     structKeyExists(form,"member_code")     ? form.member_code     : getCompany.member_code,
    "nickname":        structKeyExists(form,"nickname")        ? form.nickname        : getCompany.nickname,
    "fullname":        structKeyExists(form,"fullname")        ? form.fullname        : getCompany.fullname,
    "taxoffice":       structKeyExists(form,"taxoffice")       ? form.taxoffice       : getCompany.taxoffice,
    "taxno":           structKeyExists(form,"taxno")           ? form.taxno           : getCompany.taxno,
    "company_email":   structKeyExists(form,"company_email")   ? form.company_email   : getCompany.company_email,
    "homepage":        structKeyExists(form,"homepage")        ? form.homepage        : getCompany.homepage,
    "company_tel1":    structKeyExists(form,"company_tel1")    ? form.company_tel1    : getCompany.company_tel1,
    "company_tel2":    structKeyExists(form,"company_tel2")    ? form.company_tel2    : getCompany.company_tel2,
    "mobiltel":        structKeyExists(form,"mobiltel")        ? form.mobiltel        : getCompany.mobiltel,
    "company_address": structKeyExists(form,"company_address") ? form.company_address : getCompany.company_address,
    "is_buyer":        structKeyExists(form,"is_buyer")        ? (form.is_buyer eq "true" OR form.is_buyer eq "1")                : getCompany.is_buyer,
    "is_seller":       structKeyExists(form,"is_seller")       ? (form.is_seller eq "true" OR form.is_seller eq "1")              : getCompany.is_seller,
    "ispotantial":     structKeyExists(form,"ispotantial")     ? (form.ispotantial eq "true" OR form.ispotantial eq "1")          : getCompany.ispotantial,
    "is_person":       structKeyExists(form,"is_person")       ? (form.is_person eq "true" OR form.is_person eq "1")              : getCompany.is_person,
    "ozel_kod":        structKeyExists(form,"ozel_kod")        ? form.ozel_kod        : getCompany.ozel_kod,
    "ozel_kod_1":      structKeyExists(form,"ozel_kod_1")      ? form.ozel_kod_1      : getCompany.ozel_kod_1,
    "ozel_kod_2":      structKeyExists(form,"ozel_kod_2")      ? form.ozel_kod_2      : getCompany.ozel_kod_2
}>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-building"></i></div>
        <div class="page-header-title">
            <h1>Firma Düzenle</h1>
            <p><cfoutput>#getCompany.nickname ?: getCompany.fullname#</cfoutput></p>
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

    <div class="row g-3">
        <!--- Sol kolon: Form alanları --->
        <div class="col-lg-8">
            <cfoutput>
            <form method="post" id="companyForm" action="/index.cfm?fuseaction=company.edit_company&id=#url.id#">

                <!--- Temel Bilgiler --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Temel Bilgiler</div>
                    </div>
                    <div class="card-body p-3">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label for="nickname" class="form-label">Kısa Ad</label>
                                <input type="text" class="form-control" id="nickname" name="nickname"
                                       value="#htmlEditFormat(f.nickname)#">
                            </div>
                            <div class="col-md-8">
                                <label for="fullname" class="form-label">Tam Ad / Unvan</label>
                                <input type="text" class="form-control" id="fullname" name="fullname"
                                       value="#htmlEditFormat(f.fullname)#">
                            </div>
                            <div class="col-md-4">
                                <label for="companycat_id" class="form-label">Kategori</label>
                                <select class="form-select" id="companycat_id" name="companycat_id">
                                    <option value="0">-- Kategori Seçin --</option>
                                    <cfloop query="getCategories">
                                    <option value="#companycat_id#" #f.companycat_id eq companycat_id ? 'selected' : ''#>
                                        #companycat# (#companycat_type ? "Ticari" : "Bireysel"#)
                                    </option>
                                    </cfloop>
                                </select>
                            </div>
                            <div class="col-md-4">
                                <label for="member_code" class="form-label">Üye Kodu</label>
                                <input type="text" class="form-control" id="member_code" name="member_code"
                                       value="#htmlEditFormat(f.member_code)#">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label">Durum</label>
                                <div class="form-check form-switch mt-2">
                                    <input class="form-check-input" type="checkbox" id="company_status" name="company_status"
                                           value="true" #f.company_status ? 'checked' : ''#>
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
                                    <input class="form-check-input" type="checkbox" id="is_buyer" name="is_buyer" value="true" #f.is_buyer ? 'checked' : ''#>
                                    <label class="form-check-label" for="is_buyer"><i class="fas fa-shopping-cart text-success me-1"></i>Müşteri</label>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="is_seller" name="is_seller" value="true" #f.is_seller ? 'checked' : ''#>
                                    <label class="form-check-label" for="is_seller"><i class="fas fa-truck text-primary me-1"></i>Tedarikçi</label>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="ispotantial" name="ispotantial" value="true" #f.ispotantial ? 'checked' : ''#>
                                    <label class="form-check-label" for="ispotantial"><i class="fas fa-star text-warning me-1"></i>Potansiyel</label>
                                </div>
                            </div>
                            <div class="col-md-3">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="is_person" name="is_person" value="true" #f.is_person ? 'checked' : ''#>
                                    <label class="form-check-label" for="is_person"><i class="fas fa-user me-1"></i>Gerçek Kişi</label>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <!--- Vergi --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-file-invoice"></i>Vergi Bilgileri</div>
                    </div>
                    <div class="card-body p-3">
                        <div class="row g-3">
                            <div class="col-md-6">
                                <label for="taxoffice" class="form-label">Vergi Dairesi</label>
                                <input type="text" class="form-control" id="taxoffice" name="taxoffice" value="#htmlEditFormat(f.taxoffice)#">
                            </div>
                            <div class="col-md-6">
                                <label for="taxno" class="form-label">Vergi No / TC Kimlik No</label>
                                <input type="text" class="form-control" id="taxno" name="taxno" value="#htmlEditFormat(f.taxno)#">
                            </div>
                        </div>
                    </div>
                </div>

                <!--- İletişim --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-phone"></i>İletişim Bilgileri</div>
                    </div>
                    <div class="card-body p-3">
                        <div class="row g-3">
                            <div class="col-md-4">
                                <label for="company_tel1" class="form-label">Telefon 1</label>
                                <input type="text" class="form-control" id="company_tel1" name="company_tel1" value="#htmlEditFormat(f.company_tel1)#">
                            </div>
                            <div class="col-md-4">
                                <label for="company_tel2" class="form-label">Telefon 2</label>
                                <input type="text" class="form-control" id="company_tel2" name="company_tel2" value="#htmlEditFormat(f.company_tel2)#">
                            </div>
                            <div class="col-md-4">
                                <label for="mobiltel" class="form-label">Cep Telefonu</label>
                                <input type="text" class="form-control" id="mobiltel" name="mobiltel" value="#htmlEditFormat(f.mobiltel)#">
                            </div>
                            <div class="col-md-6">
                                <label for="company_email" class="form-label">E-posta</label>
                                <input type="email" class="form-control" id="company_email" name="company_email" value="#htmlEditFormat(f.company_email)#">
                            </div>
                            <div class="col-md-6">
                                <label for="homepage" class="form-label">Web Sitesi</label>
                                <input type="text" class="form-control" id="homepage" name="homepage" value="#htmlEditFormat(f.homepage)#">
                            </div>
                            <div class="col-12">
                                <label for="company_address" class="form-label">Adres</label>
                                <textarea class="form-control" id="company_address" name="company_address" rows="3">#htmlEditFormat(f.company_address)#</textarea>
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
                                <input type="text" class="form-control" id="ozel_kod" name="ozel_kod" value="#htmlEditFormat(f.ozel_kod)#">
                            </div>
                            <div class="col-md-4">
                                <label for="ozel_kod_1" class="form-label">Özel Kod 2</label>
                                <input type="text" class="form-control" id="ozel_kod_1" name="ozel_kod_1" value="#htmlEditFormat(f.ozel_kod_1)#">
                            </div>
                            <div class="col-md-4">
                                <label for="ozel_kod_2" class="form-label">Özel Kod 3</label>
                                <input type="text" class="form-control" id="ozel_kod_2" name="ozel_kod_2" value="#htmlEditFormat(f.ozel_kod_2)#">
                            </div>
                        </div>
                    </div>
                </div>

                <div class="d-flex gap-2 justify-content-end mb-4">
                    <a href="/index.cfm?fuseaction=company.list_company" class="btn btn-secondary btn-lg">
                        <i class="fas fa-times me-1"></i>İptal
                    </a>
                    <button type="submit" name="submit" value="1" class="btn btn-primary btn-lg">
                        <i class="fas fa-save me-1"></i>Güncelle
                    </button>
                </div>
            </form>
            </cfoutput>
        </div>

        <!--- Sağ kolon: Şubeler + Yetkililer --->
        <div class="col-lg-4">

            <!--- Şubeler --->
            <div class="grid-card mb-3">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-code-branch"></i>Şubeler</div>
                    <button class="btn btn-sm btn-success" onclick="showAddBranchModal()">
                        <i class="fas fa-plus"></i>
                    </button>
                </div>
                <div class="card-body p-2">
                    <div id="branchList"></div>
                </div>
            </div>

            <!--- Yetkililer --->
            <div class="grid-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-users"></i>Yetkililer</div>
                    <button class="btn btn-sm btn-success" onclick="showAddPartnerModal()">
                        <i class="fas fa-plus"></i>
                    </button>
                </div>
                <div class="card-body p-2">
                    <div id="partnerList"></div>
                </div>
            </div>

            <!--- Kredi & Risk Limiti --->
            <div class="grid-card mt-3">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-shield-alt"></i>Kredi &amp; Risk Limiti</div>
                    <button class="btn btn-sm btn-success" onclick="showAddCreditModal()">
                        <i class="fas fa-plus"></i>
                    </button>
                </div>
                <div class="card-body p-2">
                    <div id="creditList"></div>
                </div>
            </div>

        </div>
    </div>
</div>

<!--- Şube Modal --->
<div class="modal fade" id="branchModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="branchModalTitle"><i class="fas fa-code-branch me-2"></i>Şube</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="branchId" value="0">
                <div class="mb-3">
                    <label class="form-label">Şube Adı <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" id="branchName" placeholder="Şube adı">
                </div>
                <div class="mb-3">
                    <label class="form-label">Kısa Ad</label>
                    <input type="text" class="form-control" id="branchNickname" placeholder="Kısa ad / takma ad">
                </div>
                <div class="mb-3">
                    <label class="form-label">Telefon</label>
                    <input type="text" class="form-control" id="branchTel" placeholder="(0xxx) xxx xx xx">
                </div>
                <div class="mb-3">
                    <label class="form-label">E-posta</label>
                    <input type="email" class="form-control" id="branchEmail" placeholder="sube@firma.com">
                </div>
                <div class="mb-3">
                    <label class="form-label">Adres</label>
                    <textarea class="form-control" id="branchAddress" rows="2"></textarea>
                </div>
                <div class="form-check form-switch">
                    <input class="form-check-input" type="checkbox" id="branchStatus" checked>
                    <label class="form-check-label" for="branchStatus">Aktif</label>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-primary" onclick="saveBranch()"><i class="fas fa-save me-1"></i>Kaydet</button>
            </div>
        </div>
    </div>
</div>

<!--- Yetkili Modal --->
<div class="modal fade" id="partnerModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="partnerModalTitle"><i class="fas fa-user me-2"></i>Yetkili</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="partnerId" value="0">
                <div class="row g-2">
                    <div class="col-md-6">
                        <label class="form-label">Ad <span class="text-danger">*</span></label>
                        <input type="text" class="form-control" id="partnerName" placeholder="Ad">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Soyad</label>
                        <input type="text" class="form-control" id="partnerSurname" placeholder="Soyad">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Unvan / Görev</label>
                        <input type="text" class="form-control" id="partnerTitle" placeholder="Müdür, Yetkili...">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Cep Telefonu</label>
                        <input type="text" class="form-control" id="partnerMobil" placeholder="05xx xxx xx xx">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Telefon</label>
                        <input type="text" class="form-control" id="partnerTel" placeholder="(0xxx) xxx xx xx">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">E-posta</label>
                        <input type="email" class="form-control" id="partnerEmail" placeholder="yetkili@firma.com">
                    </div>
                </div>
                <div class="form-check form-switch mt-2">
                    <input class="form-check-input" type="checkbox" id="partnerStatus" checked>
                    <label class="form-check-label" for="partnerStatus">Aktif</label>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-primary" onclick="savePartner()"><i class="fas fa-save me-1"></i>Kaydet</button>
            </div>
        </div>
    </div>
</div>

<!--- Kredi & Risk Limiti Modal --->
<div class="modal fade" id="creditModal" tabindex="-1">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="creditModalTitle"><i class="fas fa-shield-alt me-2"></i>Kredi &amp; Risk Limiti</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <input type="hidden" id="creditId" value="0">
                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label">Para Birimi</label>
                        <select class="form-select" id="creditMoney">
                            <option value="TRY">TRY</option>
                            <option value="USD">USD</option>
                            <option value="EUR">EUR</option>
                            <option value="GBP">GBP</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">Vade (Gün)</label>
                        <input type="number" class="form-control" id="creditDueDatex" placeholder="0" min="0">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Ödeme Yöntemi</label>
                        <select class="form-select" id="creditPaymethod">
                            <option value="0">-- Seçiniz --</option>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Açık Hesap Risk Limiti</label>
                        <input type="number" class="form-control" id="creditOpenLimit" placeholder="0.00" step="0.01" min="0">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Vadeli Satış Limiti</label>
                        <input type="number" class="form-control" id="creditForwardLimit" placeholder="0.00" step="0.01" min="0">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Toplam Risk Limiti</label>
                        <input type="number" class="form-control" id="creditTotalLimit" placeholder="0.00" step="0.01" min="0">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Sevkiyat Yöntemi</label>
                        <select class="form-select" id="creditShipMethod">
                            <option value="0">-- Seçiniz --</option>
                        </select>
                    </div>
                    <div class="col-md-6 d-flex align-items-center">
                        <div class="form-check form-switch mt-3">
                            <input class="form-check-input" type="checkbox" id="creditIsBlacklist">
                            <label class="form-check-label" for="creditIsBlacklist"><span class="text-danger fw-semibold">Kara Listeye Al</span></label>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-primary" onclick="saveCredit()"><i class="fas fa-save me-1"></i>Kaydet</button>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<script>
var companyId = #val(url.id)#;
var branchesData = #serializeJSON(branchesArr)#;
var partnersData = #serializeJSON(partnersArr)#;

function renderBranches(data) {
    var container = $('##branchList');
    if (!data || data.length === 0) {
        container.html('<p class="text-muted text-center py-3" style="font-size:13px">Şube kaydı yok</p>');
        return;
    }
    var html = '<ul class="list-group list-group-flush">';
    for (var i = 0; i < data.length; i++) {
        var b = data[i];
        html += '<li class="list-group-item px-2 py-2" style="font-size:13px">';
        html += '<div class="d-flex justify-content-between align-items-start">';
        html += '<div><strong>' + (b.compbranch__name || '-') + '</strong>';
        if (b.compbranch__nickname) html += ' <small class="text-muted">(' + b.compbranch__nickname + ')</small>';
        if (b.compbranch_tel1) html += '<br><i class="fas fa-phone fa-xs text-muted me-1"></i>' + b.compbranch_tel1;
        if (b.compbranch_email) html += '<br><i class="fas fa-envelope fa-xs text-muted me-1"></i>' + b.compbranch_email;
        html += '</div>';
        html += '<div class="d-flex gap-1">';
        html += '<button class="btn btn-xs btn-outline-primary" style="padding:2px 6px;font-size:11px" onclick="editBranch(' + b.compbranch_id + ')"><i class="fas fa-edit"></i></button>';
        html += '<button class="btn btn-xs btn-outline-danger" style="padding:2px 6px;font-size:11px" onclick="deleteBranch(' + b.compbranch_id + ')"><i class="fas fa-trash"></i></button>';
        html += '</div></div></li>';
    }
    html += '</ul>';
    container.html(html);
}

function renderPartners(data) {
    var container = $('##partnerList');
    if (!data || data.length === 0) {
        container.html('<p class="text-muted text-center py-3" style="font-size:13px">Yetkili kaydı yok</p>');
        return;
    }
    var html = '<ul class="list-group list-group-flush">';
    for (var i = 0; i < data.length; i++) {
        var p = data[i];
        var fullName = ((p.company_partner_name || '') + ' ' + (p.company_partner_surname || '')).trim();
        html += '<li class="list-group-item px-2 py-2" style="font-size:13px">';
        html += '<div class="d-flex justify-content-between align-items-start">';
        html += '<div><strong>' + (fullName || '-') + '</strong>';
        if (p.title) html += ' <small class="badge bg-secondary">' + p.title + '</small>';
        if (p.mobiltel) html += '<br><i class="fas fa-mobile-alt fa-xs text-muted me-1"></i>' + p.mobiltel;
        if (p.company_partner_email) html += '<br><i class="fas fa-envelope fa-xs text-muted me-1"></i>' + p.company_partner_email;
        html += '</div>';
        html += '<div class="d-flex gap-1">';
        html += '<button class="btn btn-xs btn-outline-primary" style="padding:2px 6px;font-size:11px" onclick="editPartner(' + p.partner_id + ')"><i class="fas fa-edit"></i></button>';
        html += '<button class="btn btn-xs btn-outline-danger" style="padding:2px 6px;font-size:11px" onclick="deletePartner(' + p.partner_id + ')"><i class="fas fa-trash"></i></button>';
        html += '</div></div></li>';
    }
    html += '</ul>';
    container.html(html);
}

renderBranches(branchesData);
renderPartners(partnersData);

// Modalleri content-wrapper dışına taşı (overflow kırpma sorunu)
document.body.appendChild(document.getElementById('branchModal'));
document.body.appendChild(document.getElementById('partnerModal'));
// ---------- ŞUBE ----------
function showAddBranchModal() {
    $('##branchModalTitle').text('Yeni Şube');
    $('##branchId').val(0);
    $('##branchName,##branchNickname,##branchTel,##branchEmail,##branchAddress').val('');
    $('##branchStatus').prop('checked', true);
    new bootstrap.Modal(document.getElementById('branchModal')).show();
}

function editBranch(id) {
    var b = branchesData.find(function(x) { return x.compbranch_id == id; });
    if (!b) return;
    $('##branchModalTitle').text('Şube Düzenle');
    $('##branchId').val(b.compbranch_id);
    $('##branchName').val(b.compbranch__name);
    $('##branchNickname').val(b.compbranch__nickname);
    $('##branchTel').val(b.compbranch_tel1);
    $('##branchEmail').val(b.compbranch_email);
    $('##branchAddress').val(b.compbranch_address);
    $('##branchStatus').prop('checked', b.compbranch_status);
    new bootstrap.Modal(document.getElementById('branchModal')).show();
}

function saveBranch() {
    var name = $('##branchName').val().trim();
    if (!name) { alert('Şube adı zorunludur!'); return; }
    var branchId = parseInt($('##branchId').val());
    var data = {
        company_id:         companyId,
        compbranch__name:   name,
        compbranch__nickname: $('##branchNickname').val(),
        compbranch_tel1:    $('##branchTel').val(),
        compbranch_email:   $('##branchEmail').val(),
        compbranch_address: $('##branchAddress').val(),
        compbranch_status:  $('##branchStatus').is(':checked') ? 'true' : 'false'
    };
    var url = branchId > 0
        ? '/company/form/save_branch.cfm?id=' + branchId
        : '/company/form/save_branch.cfm';
    $.ajax({
        url: url, method: 'POST', data: data, dataType: 'json',
        success: function(r) {
            if (r.success) {
                bootstrap.Modal.getInstance(document.getElementById('branchModal')).hide();
                location.reload();
            } else { alert(r.message || 'Hata oluştu!'); }
        },
        error: function() { alert('Şube kaydedilirken hata oluştu!'); }
    });
}

function deleteBranch(id) {
    if (!confirm('Bu şubeyi silmek istediğinizden emin misiniz?')) return;
    $.ajax({
        url: '/company/cfc/company.cfc?method=deleteBranch',
        method: 'POST', data: { id: id }, dataType: 'json',
        success: function(r) {
            if (r.success) { branchesData = branchesData.filter(function(x) { return x.compbranch_id != id; }); renderBranches(branchesData); }
            else alert(r.message || 'Hata oluştu!');
        },
        error: function() { alert('Şube silinirken hata oluştu!'); }
    });
}

// ---------- YETKİLİ ----------
function showAddPartnerModal() {
    $('##partnerModalTitle').text('Yeni Yetkili');
    $('##partnerId').val(0);
    $('##partnerName,##partnerSurname,##partnerTitle,##partnerMobil,##partnerTel,##partnerEmail').val('');
    $('##partnerStatus').prop('checked', true);
    new bootstrap.Modal(document.getElementById('partnerModal')).show();
}

function editPartner(id) {
    var p = partnersData.find(function(x) { return x.partner_id == id; });
    if (!p) return;
    $('##partnerModalTitle').text('Yetkili Düzenle');
    $('##partnerId').val(p.partner_id);
    $('##partnerName').val(p.company_partner_name);
    $('##partnerSurname').val(p.company_partner_surname);
    $('##partnerTitle').val(p.title);
    $('##partnerMobil').val(p.mobiltel);
    $('##partnerTel').val(p.company_partner_tel);
    $('##partnerEmail').val(p.company_partner_email);
    $('##partnerStatus').prop('checked', p.company_partner_status);
    new bootstrap.Modal(document.getElementById('partnerModal')).show();
}

function savePartner() {
    var name = $('##partnerName').val().trim();
    if (!name) { alert('Ad zorunludur!'); return; }
    var partnerId = parseInt($('##partnerId').val());
    var data = {
        company_id:               companyId,
        company_partner_name:     name,
        company_partner_surname:  $('##partnerSurname').val(),
        title:                    $('##partnerTitle').val(),
        mobiltel:                 $('##partnerMobil').val(),
        company_partner_tel:      $('##partnerTel').val(),
        company_partner_email:    $('##partnerEmail').val(),
        company_partner_status:   $('##partnerStatus').is(':checked') ? 'true' : 'false'
    };
    var url = partnerId > 0
        ? '/company/form/save_partner.cfm?id=' + partnerId
        : '/company/form/save_partner.cfm';
    $.ajax({
        url: url, method: 'POST', data: data, dataType: 'json',
        success: function(r) {
            if (r.success) {
                bootstrap.Modal.getInstance(document.getElementById('partnerModal')).hide();
                location.reload();
            } else { alert(r.message || 'Hata oluştu!'); }
        },
        error: function() { alert('Yetkili kaydedilirken hata oluştu!'); }
    });
}

function deletePartner(id) {
    if (!confirm('Bu yetkiliyi silmek istediğinizden emin misiniz?')) return;
    $.ajax({
        url: '/company/cfc/company.cfc?method=deletePartner',
        method: 'POST', data: { id: id }, dataType: 'json',
        success: function(r) {
            if (r.success) { partnersData = partnersData.filter(function(x) { return x.partner_id != id; }); renderPartners(partnersData); }
            else alert(r.message || 'Hata oluştu!');
        },
        error: function() { alert('Yetkili silinirken hata oluştu!'); }
    });
}

// ---------- KREDİ & RİSK LİMİTİ ----------
var creditsData = #serializeJSON(creditsArr)#;
var paymethodOptions = [];
var shipMethodOptions = [];

// Dropdown seçeneklerini yükle
$.ajax({
    url: '/company/cfc/company.cfc?method=getPaymethodsForDropdown',
    method: 'GET', dataType: 'json',
    success: function(r) {
        paymethodOptions = r || [];
        var sel = $('##creditPaymethod');
        sel.find('option:not(:first)').remove();
        paymethodOptions.forEach(function(o) { sel.append('<option value="' + o.paymethod_id + '">' + o.paymethod + '</option>'); });
    }
});
$.ajax({
    url: '/company/cfc/company.cfc?method=getShipMethodsForDropdown',
    method: 'GET', dataType: 'json',
    success: function(r) {
        shipMethodOptions = r || [];
        var sel = $('##creditShipMethod');
        sel.find('option:not(:first)').remove();
        shipMethodOptions.forEach(function(o) { sel.append('<option value="' + o.ship_method_id + '">' + o.ship_method + '</option>'); });
    }
});

function renderCredits(data) {
    var container = $('##creditList');
    if (!data || data.length === 0) {
        container.html('<p class="text-muted text-center py-3" style="font-size:13px">Kredi kaydı yok</p>');
        return;
    }
    var html = '';
    for (var i = 0; i < data.length; i++) {
        var c = data[i];
        var blacklistBadge = c.is_blacklist ? '<span class="badge bg-danger ms-1">Kara Liste</span>' : '';
        html += '<div class="border rounded p-2 mb-2" style="font-size:13px">';
        html += '<div class="d-flex justify-content-between align-items-center mb-1">';
        html += '<strong>' + (c.money || 'TRY') + '</strong>' + blacklistBadge;
        html += '<div class="d-flex gap-1">';
        html += '<button class="btn btn-xs btn-outline-primary" style="padding:2px 6px;font-size:11px" onclick="editCredit(' + c.company_credit_id + ')"><i class="fas fa-edit"></i></button>';
        html += '<button class="btn btn-xs btn-outline-danger" style="padding:2px 6px;font-size:11px" onclick="deleteCredit(' + c.company_credit_id + ')"><i class="fas fa-trash"></i></button>';
        html += '</div></div>';
        html += '<div class="row g-1" style="font-size:12px">';
        html += '<div class="col-12"><span class="text-muted">Açık Hesap:</span> <strong>' + (c.open_account_risk_limit || 0).toLocaleString() + '</strong></div>';
        html += '<div class="col-12"><span class="text-muted">Vadeli Satış:</span> <strong>' + (c.forward_sale_limit || 0).toLocaleString() + '</strong></div>';
        html += '<div class="col-12"><span class="text-muted">Toplam Risk:</span> <strong>' + (c.total_risk_limit || 0).toLocaleString() + '</strong></div>';
        if (c.paymethod) html += '<div class="col-12"><i class="fas fa-money-bill fa-xs text-muted me-1"></i>' + c.paymethod + '</div>';
        if (c.ship_method) html += '<div class="col-12"><i class="fas fa-truck fa-xs text-muted me-1"></i>' + c.ship_method + '</div>';
        if (c.due_datex) html += '<div class="col-12"><span class="text-muted">Vade:</span> ' + c.due_datex + ' gün</div>';
        html += '</div></div>';
    }
    container.html(html);
}

renderCredits(creditsData);
document.body.appendChild(document.getElementById('creditModal'));

function showAddCreditModal() {
    $('##creditModalTitle').text('Yeni Kredi Kaydı');
    $('##creditId').val(0);
    $('##creditMoney').val('TRY');
    $('##creditOpenLimit,##creditForwardLimit,##creditTotalLimit,##creditDueDatex').val('');
    $('##creditPaymethod,##creditShipMethod').val('0');
    $('##creditIsBlacklist').prop('checked', false);
    new bootstrap.Modal(document.getElementById('creditModal')).show();
}

function editCredit(id) {
    var c = creditsData.find(function(x) { return x.company_credit_id == id; });
    if (!c) return;
    $('##creditModalTitle').text('Kredi Kaydı Düzenle');
    $('##creditId').val(c.company_credit_id);
    $('##creditMoney').val(c.money || 'TRY');
    $('##creditOpenLimit').val(c.open_account_risk_limit || '');
    $('##creditForwardLimit').val(c.forward_sale_limit || '');
    $('##creditTotalLimit').val(c.total_risk_limit || '');
    $('##creditDueDatex').val(c.due_datex || '');
    $('##creditIsBlacklist').prop('checked', c.is_blacklist);
    // Dropdown değerlerini doğru seç (AJAX yüklemesi tamamlandıktan sonra da çalışır)
    setTimeout(function() {
        $('##creditPaymethod').val(c.paymethod_id || '0');
        $('##creditShipMethod').val(c.ship_method_id || '0');
    }, 100);
    new bootstrap.Modal(document.getElementById('creditModal')).show();
}

function saveCredit() {
    var creditId = parseInt($('##creditId').val()) || 0;
    var data = {
        credit_id:               creditId,
        company_id:              companyId,
        money:                   $('##creditMoney').val(),
        open_account_risk_limit: $('##creditOpenLimit').val(),
        forward_sale_limit:      $('##creditForwardLimit').val(),
        total_risk_limit:        $('##creditTotalLimit').val(),
        due_datex:               $('##creditDueDatex').val(),
        paymethod_id:            $('##creditPaymethod').val() || '0',
        ship_method_id:          $('##creditShipMethod').val() || '0',
        is_blacklist:            $('##creditIsBlacklist').is(':checked') ? 'true' : 'false'
    };
    $.ajax({
        url: '/company/cfc/company.cfc?method=saveCompanyCredit',
        method: 'POST', data: data, dataType: 'json',
        success: function(r) {
            if (r.success) {
                bootstrap.Modal.getInstance(document.getElementById('creditModal')).hide();
                location.reload();
            } else { alert(r.message || 'Hata oluştu!'); }
        },
        error: function() { alert('Kredi kaydedilirken hata oluştu!'); }
    });
}

function deleteCredit(id) {
    if (!confirm('Bu kredi kaydını silmek istediğinizden emin misiniz?')) return;
    $.ajax({
        url: '/company/cfc/company.cfc?method=deleteCompanyCredit',
        method: 'POST', data: { id: id }, dataType: 'json',
        success: function(r) {
            if (r.success) { creditsData = creditsData.filter(function(x) { return x.company_credit_id != id; }); renderCredits(creditsData); }
            else alert(r.message || 'Hata oluştu!');
        },
        error: function() { alert('Kredi silinirken hata oluştu!'); }
    });
}
</script>
</cfoutput>
