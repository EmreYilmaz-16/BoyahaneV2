<cfprocessingdirective pageEncoding="utf-8">
<cfheader name="Content-Type" value="application/json; charset=utf-8">

<cftry>
    <cfparam name="url.id"                          default="0">
    <cfparam name="form.company_id"                 default="0">
    <cfparam name="form.company_partner_name"        default="">
    <cfparam name="form.company_partner_surname"     default="">
    <cfparam name="form.title"                      default="">
    <cfparam name="form.mobiltel"                   default="">
    <cfparam name="form.company_partner_tel"        default="">
    <cfparam name="form.company_partner_email"      default="">
    <cfparam name="form.company_partner_status"     default="false">

    <cfif trim(form.company_partner_name) eq "">
        <cfoutput>#serializeJSON({"success": false, "message": "Yetkili adı zorunludur!"})#</cfoutput>
        <cfabort>
    </cfif>

    <cfset isEdit = val(url.id) gt 0>

    <cfif isEdit>
        <cfquery datasource="boyahane">
            UPDATE company_partner SET
                company_partner_name    = <cfqueryparam value="#trim(form.company_partner_name)#" cfsqltype="cf_sql_varchar">,
                company_partner_surname = <cfqueryparam value="#trim(form.company_partner_surname)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_partner_surname) eq ''#">,
                title                   = <cfqueryparam value="#trim(form.title)#" cfsqltype="cf_sql_varchar" null="#trim(form.title) eq ''#">,
                mobiltel                = <cfqueryparam value="#trim(form.mobiltel)#" cfsqltype="cf_sql_varchar" null="#trim(form.mobiltel) eq ''#">,
                company_partner_tel     = <cfqueryparam value="#trim(form.company_partner_tel)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_partner_tel) eq ''#">,
                company_partner_email   = <cfqueryparam value="#trim(form.company_partner_email)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_partner_email) eq ''#">,
                company_partner_status  = <cfqueryparam value="#form.company_partner_status eq 'true' OR form.company_partner_status eq '1'#" cfsqltype="cf_sql_bit">,
                update_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                update_ip   = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            WHERE partner_id = <cfqueryparam value="#val(url.id)#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <cfquery datasource="boyahane">
            INSERT INTO company_partner (company_id, company_partner_name, company_partner_surname, title, mobiltel, company_partner_tel, company_partner_email, company_partner_status, record_date, record_ip)
            VALUES (
                <cfqueryparam value="#val(form.company_id)#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#trim(form.company_partner_name)#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#trim(form.company_partner_surname)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_partner_surname) eq ''#">,
                <cfqueryparam value="#trim(form.title)#" cfsqltype="cf_sql_varchar" null="#trim(form.title) eq ''#">,
                <cfqueryparam value="#trim(form.mobiltel)#" cfsqltype="cf_sql_varchar" null="#trim(form.mobiltel) eq ''#">,
                <cfqueryparam value="#trim(form.company_partner_tel)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_partner_tel) eq ''#">,
                <cfqueryparam value="#trim(form.company_partner_email)#" cfsqltype="cf_sql_varchar" null="#trim(form.company_partner_email) eq ''#">,
                <cfqueryparam value="#form.company_partner_status eq 'true' OR form.company_partner_status eq '1'#" cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
    </cfif>

    <cfoutput>#serializeJSON({"success": true, "message": "Yetkili kaydedildi"})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success": false, "message": "Yetkili kaydedilirken hata: " & cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
