<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif NOT structKeyExists(session, "authenticated") OR NOT session.authenticated>
    <cfoutput>{"success":false,"message":"Oturum gerekli."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset currentPw = isDefined("form.current_password") ? trim(form.current_password) : "">
    <cfset newPw     = isDefined("form.new_password")     ? trim(form.new_password)     : "">

    <cfif NOT len(currentPw)>
        <cfoutput>{"success":false,"message":"Mevcut şifre boş olamaz."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif NOT len(newPw)>
        <cfoutput>{"success":false,"message":"Yeni şifre boş olamaz."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif len(newPw) LT 4>
        <cfoutput>{"success":false,"message":"Yeni şifre en az 4 karakter olmalıdır."}</cfoutput>
        <cfabort>
    </cfif>

    
    <cfquery name="checkPw" datasource="boyahane">
        SELECT id FROM kullanicilar
        WHERE id       = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
          AND password = <cfqueryparam value="#currentPw#"       cfsqltype="cf_sql_varchar">
        LIMIT 1
    </cfquery>
    <cfif NOT checkPw.recordCount>
        <cfoutput>{"success":false,"message":"Mevcut şifre yanlış."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        UPDATE kullanicilar SET
            password   = <cfqueryparam value="#newPw#" cfsqltype="cf_sql_varchar">,
            updated_at = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
        WHERE id = <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>{"success":true}</cfoutput>

<cfcatch type="any">
    <cfoutput>{"success":false,"message":"Hata: #jsStringFormat(cfcatch.message)#"}</cfoutput>
</cfcatch>
</cftry>
<cfabort>