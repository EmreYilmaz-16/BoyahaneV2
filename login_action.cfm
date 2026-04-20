<cfprocessingdirective pageEncoding="utf-8">
<!--- Login Action - Kullanıcı doğrulama işlemi --->

<cfparam name="form.username" default="">
<cfparam name="form.password" default="">
<cfparam name="form.remember" default="0">

<!--- Form alanları boş mu kontrol et --->
<cfif trim(form.username) eq "" or trim(form.password) eq "">
    <cflocation url="login.cfm?error=empty" addtoken="false">
    <cfabort>
</cfif>

<!--- Veritabanından kullanıcı bilgilerini kontrol et --->
<cfquery name="getUser" datasource="boyahane">
    SELECT 
        id,
        name,
        surname,
        username,
        password,
        w3userid,
        is_active,
        default_fuseaction
    FROM 
        kullanicilar
    WHERE 
        username = <cfqueryparam value="#trim(form.username)#" cfsqltype="cf_sql_varchar">
        AND password = <cfqueryparam value="#trim(form.password)#" cfsqltype="cf_sql_varchar">
</cfquery>

<!--- Kullanıcı bulunamadı --->
<cfif getUser.recordCount eq 0>
    <cflocation url="login.cfm?error=invalid" addtoken="false">
    <cfabort>
</cfif>

<!--- Kullanıcı aktif değil --->
<cfif not getUser.is_active>
    <cflocation url="login.cfm?error=inactive" addtoken="false">
    <cfabort>
</cfif>

<!--- Giriş başarılı - Session oluştur --->
<cflock scope="session" type="exclusive" timeout="10">
    <cfset session.authenticated = true>
    <cfset session.user = structNew()>
    <cfset session.user.id = getUser.id>
    <cfset session.user.name = getUser.name>
    <cfset session.user.surname = getUser.surname>
    <cfset session.user.username = getUser.username>
    <cfset session.user.w3userid = getUser.w3userid>
    <cfset session.user.default_fuseaction = trim(getUser.default_fuseaction ?: "")>
    <cfset session.user.fullname = getUser.name & " " & getUser.surname>
    <cfset session.user.loginTime = now()>
</cflock>

<!--- Son giriş zamanını güncelle --->
<cfquery datasource="boyahane">
    UPDATE kullanicilar
    SET last_login = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
    WHERE id = <cfqueryparam value="#getUser.id#" cfsqltype="cf_sql_integer">
</cfquery>

<!--- "Beni Hatırla" özelliği için cookie oluştur (opsiyonel) --->
<cfif form.remember eq "on">
    <cfcookie name="boyahane_remember" value="#hash(getUser.username, 'SHA-256')#" expires="30">
</cfif>

<!--- Personele özel varsayılan sayfaya yönlendir --->
<cfset redirectFuseaction = "myhome.welcome">
<cfif len(trim(getUser.default_fuseaction ?: "")) AND reFindNoCase("^[a-z0-9_]+\.[a-z0-9_]+$", trim(getUser.default_fuseaction))>
    <cfset redirectFuseaction = trim(getUser.default_fuseaction)>
</cfif>
<cflocation url="index.cfm?fuseaction=#urlEncodedFormat(redirectFuseaction)#" addtoken="false">
