<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif NOT structKeyExists(session, "authenticated") OR NOT session.authenticated>
    <cfoutput>{"success":false,"message":"Oturum gerekli."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset userId   = session.user.id>
    <cfset name     = isDefined("form.name")     ? left(trim(form.name),    100) : "">
    <cfset surname  = isDefined("form.surname")  ? left(trim(form.surname), 100) : "">
    <cfset username = isDefined("form.username") ? left(lCase(trim(form.username)), 50) : "">
    <cfset w3userid = isDefined("form.w3userid") ? left(trim(form.w3userid), 100) : "">
    <cfset defaultFuseaction = isDefined("form.default_fuseaction") ? lCase(trim(form.default_fuseaction)) : "">

    <cfif NOT len(name)>
        <cfoutput>{"success":false,"message":"Ad zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif NOT len(surname)>
        <cfoutput>{"success":false,"message":"Soyad zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif NOT len(username)>
        <cfoutput>{"success":false,"message":"Kullanıcı adı zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif NOT reFind("^[a-z0-9_]{3,50}$", username)>
        <cfoutput>{"success":false,"message":"Kullanıcı adı 3-50 karakter; yalnızca küçük harf, rakam ve alt çizgi içerebilir."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif len(defaultFuseaction) AND NOT reFindNoCase("^[a-z0-9_]+\.[a-z0-9_]+$", defaultFuseaction)>
        <cfoutput>{"success":false,"message":"Varsayılan sayfa formatı geçersiz. Örnek: myhome.welcome"}</cfoutput>
        <cfabort>
    </cfif>

    <!-- Kullanıcı adı çakışma kontrolü (kendisi hariç) -->
    <cfquery name="checkUsername" datasource="boyahane">
        SELECT id FROM kullanicilar
        WHERE username = <cfqueryparam value="#username#" cfsqltype="cf_sql_varchar">
          AND id <> <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
        LIMIT 1
    </cfquery>
    <cfif checkUsername.recordCount GT 0>
        <cfoutput>{"success":false,"message":"Bu kullanıcı adı zaten kullanılıyor."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        UPDATE kullanicilar SET
            name       = <cfqueryparam value="#name#"     cfsqltype="cf_sql_varchar">,
            surname    = <cfqueryparam value="#surname#"  cfsqltype="cf_sql_varchar">,
            username   = <cfqueryparam value="#username#" cfsqltype="cf_sql_varchar">,
            w3userid   = <cfqueryparam value="#w3userid#" cfsqltype="cf_sql_varchar" null="#NOT len(w3userid)#">,
            default_fuseaction = <cfqueryparam value="#defaultFuseaction#" cfsqltype="cf_sql_varchar" null="#NOT len(defaultFuseaction)#">,
            updated_at = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
        WHERE id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <!-- Session bilgilerini güncelle -->
    <cflock scope="session" type="exclusive" timeout="10">
        <cfset session.user.name     = name>
        <cfset session.user.surname  = surname>
        <cfset session.user.username = username>
        <cfset session.user.fullname = name & " " & surname>
        <cfset session.user.w3userid = w3userid>
        <cfset session.user.default_fuseaction = defaultFuseaction>
    </cflock>

    <cfoutput>{"success":true}</cfoutput>

<cfcatch type="any">
    <cfoutput>{"success":false,"message":"Hata: #jsStringFormat(cfcatch.message)#"}</cfoutput>
</cfcatch>
</cftry>