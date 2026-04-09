<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif NOT structKeyExists(session, "authenticated") OR NOT session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset userId   = isDefined("form.user_id")   AND isNumeric(form.user_id)   ? val(form.user_id)   : 0>
    <cfset name     = isDefined("form.name")       ? left(trim(form.name),    100) : "">
    <cfset surname  = isDefined("form.surname")    ? left(trim(form.surname), 100) : "">
    <cfset username = isDefined("form.username")   ? left(lCase(trim(form.username)), 50) : "">
    <cfset password = isDefined("form.password")   ? trim(form.password) : "">
    <cfset w3userid = isDefined("form.w3userid")   ? left(trim(form.w3userid), 100) : "">
    <cfset isActive = isDefined("form.is_active")  AND val(form.is_active) EQ 1>

    <!--- Zorunlu alan kontrolleri --->
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
    <cfif userId EQ 0 AND NOT len(password)>
        <cfoutput>{"success":false,"message":"Şifre zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <!--- Kullanıcı adı yalnızca harf, rakam, alt çizgi içerebilir --->
    <cfif NOT reFind("^[a-z0-9_]{3,50}$", username)>
        <cfoutput>{"success":false,"message":"Kullanıcı adı 3-50 karakter uzunluğunda olmalı; yalnızca küçük harf, rakam ve alt çizgi içerebilir."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Kullanıcı adı çakışma kontrolü --->
    <cfquery name="checkUsername" datasource="boyahane">
        SELECT id FROM kullanicilar
        WHERE username = <cfqueryparam value="#username#" cfsqltype="cf_sql_varchar">
        <cfif userId GT 0>
            AND id <> <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
        </cfif>
        LIMIT 1
    </cfquery>
    <cfif checkUsername.recordCount GT 0>
        <cfoutput>{"success":false,"message":"Bu kullanıcı adı zaten kullanılıyor."}</cfoutput>
        <cfabort>
    </cfif>

    <cfif userId GT 0>
        <!--- GÜNCELLEME --->
        <cfif len(password)>
            <cfquery datasource="boyahane">
                UPDATE kullanicilar SET
                    name       = <cfqueryparam value="#name#"      cfsqltype="cf_sql_varchar">,
                    surname    = <cfqueryparam value="#surname#"   cfsqltype="cf_sql_varchar">,
                    username   = <cfqueryparam value="#username#"  cfsqltype="cf_sql_varchar">,
                    password   = <cfqueryparam value="#password#"  cfsqltype="cf_sql_varchar">,
                    w3userid   = <cfqueryparam value="#w3userid#"  cfsqltype="cf_sql_varchar" null="#NOT len(w3userid)#">,
                    is_active  = <cfqueryparam value="#isActive#"  cfsqltype="cf_sql_bit">,
                    updated_at = <cfqueryparam value="#now()#"     cfsqltype="cf_sql_timestamp">
                WHERE id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
            </cfquery>
        <cfelse>
            <!--- Şifresiz güncelleme --->
            <cfquery datasource="boyahane">
                UPDATE kullanicilar SET
                    name       = <cfqueryparam value="#name#"      cfsqltype="cf_sql_varchar">,
                    surname    = <cfqueryparam value="#surname#"   cfsqltype="cf_sql_varchar">,
                    username   = <cfqueryparam value="#username#"  cfsqltype="cf_sql_varchar">,
                    w3userid   = <cfqueryparam value="#w3userid#"  cfsqltype="cf_sql_varchar" null="#NOT len(w3userid)#">,
                    is_active  = <cfqueryparam value="#isActive#"  cfsqltype="cf_sql_bit">,
                    updated_at = <cfqueryparam value="#now()#"     cfsqltype="cf_sql_timestamp">
                WHERE id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>
        <cfoutput>{"success":true,"user_id":#userId#}</cfoutput>
    <cfelse>
        <!--- YENİ KAYIT --->
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO kullanicilar (name, surname, username, password, w3userid, is_active, created_at, updated_at)
            VALUES (
                <cfqueryparam value="#name#"      cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#surname#"   cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#username#"  cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#password#"  cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#w3userid#"  cfsqltype="cf_sql_varchar" null="#NOT len(w3userid)#">,
                <cfqueryparam value="#isActive#"  cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#now()#"     cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#now()#"     cfsqltype="cf_sql_timestamp">
            )
            RETURNING id
        </cfquery>
        <cfoutput>{"success":true,"user_id":#val(ins.id)#}</cfoutput>
    </cfif>

<cfcatch type="any">
    <cfoutput>{"success":false,"message":"Beklenmeyen hata: #jsStringFormat(cfcatch.message)#"}</cfoutput>
</cfcatch>
</cftry>
