<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset deptId     = isDefined("form.department_id")   and isNumeric(form.department_id)   ? val(form.department_id)   : 0>
    <cfset deptHead   = isDefined("form.department_head") ? left(trim(form.department_head), 100) : "">
    <cfset hierarchy  = isDefined("form.hierarchy")       ? left(trim(form.hierarchy),  75)   : "">
    <cfset specialCode= isDefined("form.special_code")    ? left(trim(form.special_code), 50) : "">
    <cfset deptDetail = isDefined("form.department_detail")? left(trim(form.department_detail), 150) : "">
    <cfset deptStatus = isDefined("form.department_status") and val(form.department_status) eq 1>
    <cfset isProduction = isDefined("form.is_production")   and val(form.is_production)   eq 1>
    <cfset isStore    = isDefined("form.is_store")          and val(form.is_store)         eq 1 ? 1 : 0>

    <cfif not len(deptHead)>
        <cfoutput>{"success":false,"message":"Departman adı zorunludur."}</cfoutput>
        <cfabort>
    </cfif>

    <cfif deptId gt 0>
        <!--- Güncelle --->
        <cfquery datasource="boyahane">
            UPDATE department SET
                department_head   = <cfqueryparam value="#deptHead#"    cfsqltype="cf_sql_varchar">,
                hierarchy         = <cfqueryparam value="#hierarchy#"   cfsqltype="cf_sql_varchar" null="#not len(hierarchy)#">,
                special_code      = <cfqueryparam value="#specialCode#" cfsqltype="cf_sql_varchar" null="#not len(specialCode)#">,
                department_detail = <cfqueryparam value="#deptDetail#"  cfsqltype="cf_sql_varchar" null="#not len(deptDetail)#">,
                department_status = <cfqueryparam value="#deptStatus#"  cfsqltype="cf_sql_bit">,
                is_production     = <cfqueryparam value="#isProduction#" cfsqltype="cf_sql_bit">,
                is_store          = <cfqueryparam value="#isStore#"     cfsqltype="cf_sql_integer">,
                update_date       = <cfqueryparam value="#now()#"       cfsqltype="cf_sql_timestamp">,
                update_emp        = <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
                update_ip         = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            WHERE department_id = <cfqueryparam value="#deptId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfoutput>{"success":true,"department_id":#deptId#}</cfoutput>
    <cfelse>
        <!--- Yeni ekle --->
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO department (
                department_head, hierarchy, special_code, department_detail,
                department_status, is_production, is_store,
                record_date, record_emp, record_ip
            ) VALUES (
                <cfqueryparam value="#deptHead#"    cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#hierarchy#"   cfsqltype="cf_sql_varchar" null="#not len(hierarchy)#">,
                <cfqueryparam value="#specialCode#" cfsqltype="cf_sql_varchar" null="#not len(specialCode)#">,
                <cfqueryparam value="#deptDetail#"  cfsqltype="cf_sql_varchar" null="#not len(deptDetail)#">,
                <cfqueryparam value="#deptStatus#"  cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#isProduction#" cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#isStore#"     cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#now()#"        cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">
            ) RETURNING department_id
        </cfquery>
        <cfoutput>{"success":true,"department_id":#ins.department_id#}</cfoutput>
    </cfif>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
