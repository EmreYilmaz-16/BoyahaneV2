<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
    <cfset softwareName = isDefined("form.software_name") ? left(trim(form.software_name),150) : "">

    <cfif not len(softwareName)>
        <cfoutput>{"success":false,"message":"Yazılım adı zorunludur."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="ins" datasource="boyahane">
        INSERT INTO it_software_licenses (
            asset_id, software_name, vendor_name, license_key,
            total_seat, used_seat, purchase_date, expiry_date,
            compliance_status, annual_cost, currency, note, record_date
        ) VALUES (
            <cfqueryparam value="#isNumeric(form.asset_id ?: '') ? val(form.asset_id) : 0#" cfsqltype="cf_sql_integer" null="#not isNumeric(form.asset_id ?: '')#">,
            <cfqueryparam value="#softwareName#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#left(trim(form.vendor_name ?: ''),150)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.vendor_name ?: ''))#">,
            <cfqueryparam value="#left(trim(form.license_key ?: ''),250)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.license_key ?: ''))#">,
            <cfqueryparam value="#isNumeric(form.total_seat ?: '') ? val(form.total_seat) : 1#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#isNumeric(form.used_seat ?: '') ? val(form.used_seat) : 0#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#form.purchase_date#" cfsqltype="cf_sql_date" null="#not (isDefined('form.purchase_date') and isDate(form.purchase_date))#">,
            <cfqueryparam value="#form.expiry_date#" cfsqltype="cf_sql_date" null="#not (isDefined('form.expiry_date') and isDate(form.expiry_date))#">,
            <cfqueryparam value="#left(trim(form.compliance_status ?: 'VALID'),20)#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#isNumeric(form.annual_cost ?: '') ? val(form.annual_cost) : 0#" cfsqltype="cf_sql_numeric">,
            <cfqueryparam value="#left(trim(form.currency ?: 'TRY'),10)#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#trim(form.note ?: '')#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.note ?: ''))#">,
            <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
        ) RETURNING license_id
    </cfquery>

    <cfoutput>{"success":true,"license_id":#ins.license_id#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
