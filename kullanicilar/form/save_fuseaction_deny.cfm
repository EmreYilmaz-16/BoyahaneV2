<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif NOT structKeyExists(session, "authenticated") OR NOT session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset action = isDefined("form.action") ? lCase(trim(form.action)) : "">

    <!--- ============================================================
          ADD: Yeni fuseaction kısıtlaması ekle
    ============================================================ --->
    <cfif action EQ "add">

        <cfset userId     = isDefined("form.user_id")    AND isNumeric(form.user_id) ? val(form.user_id) : 0>
        <cfset fuseaction = isDefined("form.fuseaction") ? lCase(trim(form.fuseaction)) : "">
        <cfset reason     = isDefined("form.reason")     ? left(trim(form.reason), 255) : "">

        <!--- Validation --->
        <cfif userId LTE 0>
            <cfoutput>{"success":false,"message":"Geçerli bir kullanıcı seçilmedi."}</cfoutput>
            <cfabort>
        </cfif>
        <cfif NOT len(fuseaction)>
            <cfoutput>{"success":false,"message":"Fuseaction boş olamaz."}</cfoutput>
            <cfabort>
        </cfif>
        <cfif NOT reFind("^[a-z0-9_\.]+$", fuseaction)>
            <cfoutput>{"success":false,"message":"Fuseaction geçersiz karakter içeriyor."}</cfoutput>
            <cfabort>
        </cfif>
        <cfif len(fuseaction) GT 255>
            <cfoutput>{"success":false,"message":"Fuseaction çok uzun (maks. 255 karakter)."}</cfoutput>
            <cfabort>
        </cfif>

        <!--- Kullanıcı var mı kontrol --->
        <cfquery name="chkUser" datasource="boyahane">
            SELECT id FROM kullanicilar
            WHERE id = <cfqueryparam value="#userId#" cfsqltype="cf_sql_integer">
            LIMIT 1
        </cfquery>
        <cfif chkUser.recordCount EQ 0>
            <cfoutput>{"success":false,"message":"Kullanıcı bulunamadı."}</cfoutput>
            <cfabort>
        </cfif>

        <!--- Mükerrer kayıt kontrolü --->
        <cfquery name="chkDup" datasource="boyahane">
            SELECT deny_id FROM user_fuseaction_deny
            WHERE user_id    = <cfqueryparam value="#userId#"     cfsqltype="cf_sql_integer">
              AND fuseaction  = <cfqueryparam value="#fuseaction#" cfsqltype="cf_sql_varchar">
            LIMIT 1
        </cfquery>
        <cfif chkDup.recordCount GT 0>
            <cfoutput>{"success":false,"message":"Bu kullanıcı için aynı fuseaction kısıtlaması zaten mevcut."}</cfoutput>
            <cfabort>
        </cfif>

        <!--- Kaydet --->
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO user_fuseaction_deny (user_id, fuseaction, reason, created_at)
            VALUES (
                <cfqueryparam value="#userId#"     cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#fuseaction#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#reason#"     cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#now()#"      cfsqltype="cf_sql_timestamp">
            )
            RETURNING deny_id
        </cfquery>

        <cfoutput>{"success":true,"deny_id":#val(ins.deny_id)#}</cfoutput>

    <!--- ============================================================
          DELETE: Kısıtlamayı kaldır
    ============================================================ --->
    <cfelseif action EQ "delete">

        <cfset denyId = isDefined("form.deny_id") AND isNumeric(form.deny_id) ? val(form.deny_id) : 0>

        <cfif denyId LTE 0>
            <cfoutput>{"success":false,"message":"Geçerli bir kayıt ID girilmedi."}</cfoutput>
            <cfabort>
        </cfif>

        <!--- Kayıt var mı kontrol --->
        <cfquery name="chkExist" datasource="boyahane">
            SELECT deny_id FROM user_fuseaction_deny
            WHERE deny_id = <cfqueryparam value="#denyId#" cfsqltype="cf_sql_integer">
            LIMIT 1
        </cfquery>
        <cfif chkExist.recordCount EQ 0>
            <cfoutput>{"success":false,"message":"Kısıtlama kaydı bulunamadı."}</cfoutput>
            <cfabort>
        </cfif>

        <cfquery datasource="boyahane">
            DELETE FROM user_fuseaction_deny
            WHERE deny_id = <cfqueryparam value="#denyId#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfoutput>{"success":true}</cfoutput>

    <cfelse>
        <cfoutput>{"success":false,"message":"Geçersiz işlem."}</cfoutput>
    </cfif>

<cfcatch type="any">
    <cfoutput>{"success":false,"message":"Beklenmeyen hata: #jsStringFormat(cfcatch.message)#"}</cfoutput>
</cfcatch>
</cftry>
