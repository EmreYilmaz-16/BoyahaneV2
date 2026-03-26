<cfprocessingdirective pageEncoding="utf-8">
<cfheader name="Content-Type" value="application/json; charset=utf-8">

<cftry>
    <cfparam name="url.id"               default="0">
    <cfparam name="form.company_id"      default="0">
    <cfparam name="form.compbranch__name"     default="">
    <cfparam name="form.compbranch__nickname" default="">
    <cfparam name="form.compbranch_tel1"      default="">
    <cfparam name="form.compbranch_email"     default="">
    <cfparam name="form.compbranch_address"   default="">
    <cfparam name="form.compbranch_status"    default="false">

    <cfif trim(form.compbranch__name) eq "">
        <cfoutput>#serializeJSON({"success": false, "message": "Şube adı zorunludur!"})#</cfoutput>
        <cfabort>
    </cfif>

    <cfset isEdit = val(url.id) gt 0>

    <cfif isEdit>
        <cfquery datasource="boyahane">
            UPDATE company_branch SET
                compbranch__name     = <cfqueryparam value="#trim(form.compbranch__name)#" cfsqltype="cf_sql_varchar">,
                compbranch__nickname = <cfqueryparam value="#trim(form.compbranch__nickname)#" cfsqltype="cf_sql_varchar" null="#trim(form.compbranch__nickname) eq ''#">,
                compbranch_tel1      = <cfqueryparam value="#trim(form.compbranch_tel1)#" cfsqltype="cf_sql_varchar" null="#trim(form.compbranch_tel1) eq ''#">,
                compbranch_email     = <cfqueryparam value="#trim(form.compbranch_email)#" cfsqltype="cf_sql_varchar" null="#trim(form.compbranch_email) eq ''#">,
                compbranch_address   = <cfqueryparam value="#trim(form.compbranch_address)#" cfsqltype="cf_sql_varchar" null="#trim(form.compbranch_address) eq ''#">,
                compbranch_status    = <cfqueryparam value="#form.compbranch_status eq 'true' OR form.compbranch_status eq '1'#" cfsqltype="cf_sql_bit">,
                update_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                update_ip   = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            WHERE compbranch_id = <cfqueryparam value="#val(url.id)#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <cfquery datasource="boyahane">
            INSERT INTO company_branch (company_id, compbranch__name, compbranch__nickname, compbranch_tel1, compbranch_email, compbranch_address, compbranch_status, record_date, record_ip)
            VALUES (
                <cfqueryparam value="#val(form.company_id)#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#trim(form.compbranch__name)#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#trim(form.compbranch__nickname)#" cfsqltype="cf_sql_varchar" null="#trim(form.compbranch__nickname) eq ''#">,
                <cfqueryparam value="#trim(form.compbranch_tel1)#" cfsqltype="cf_sql_varchar" null="#trim(form.compbranch_tel1) eq ''#">,
                <cfqueryparam value="#trim(form.compbranch_email)#" cfsqltype="cf_sql_varchar" null="#trim(form.compbranch_email) eq ''#">,
                <cfqueryparam value="#trim(form.compbranch_address)#" cfsqltype="cf_sql_varchar" null="#trim(form.compbranch_address) eq ''#">,
                <cfqueryparam value="#form.compbranch_status eq 'true' OR form.compbranch_status eq '1'#" cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            )
        </cfquery>
    </cfif>

    <cfoutput>#serializeJSON({"success": true, "message": "Şube kaydedildi"})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success": false, "message": "Şube kaydedilirken hata: " & cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
