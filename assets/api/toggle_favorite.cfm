<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cfif NOT structKeyExists(session, "authenticated") OR NOT session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cfparam name="form.fuseaction"  default="">
<cfparam name="form.page_title"  default="">
<cfparam name="form.page_icon"   default="fas fa-star">

<cfset userId     = session.user.id>
<cfset fuseaction = trim(form.fuseaction)>
<cfset pageTitle  = trim(form.page_title)>
<cfset pageIcon   = trim(form.page_icon)>

<cfif NOT len(fuseaction)>
    <cfoutput>{"success":false,"message":"Fuseaction gereklidir."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <!--- Mevcut favori var mı? --->
    <cfquery name="checkFav" datasource="boyahane">
        SELECT favorite_id
        FROM user_favorites
        WHERE user_id    = <cfqueryparam value="#userId#"     cfsqltype="cf_sql_integer">
          AND fuseaction  = <cfqueryparam value="#fuseaction#" cfsqltype="cf_sql_varchar">
    </cfquery>

    <cfif checkFav.recordCount>
        <!--- Var → sil --->
        <cfquery datasource="boyahane">
            DELETE FROM user_favorites
            WHERE user_id   = <cfqueryparam value="#userId#"     cfsqltype="cf_sql_integer">
              AND fuseaction = <cfqueryparam value="#fuseaction#" cfsqltype="cf_sql_varchar">
        </cfquery>
        <cfoutput>{"success":true,"action":"removed","is_favorite":false}</cfoutput>
    <cfelse>
        <!--- Yok → ekle --->
        <cfif NOT len(pageTitle)>
            <cfset pageTitle = fuseaction>
        </cfif>
        <cfquery datasource="boyahane">
            INSERT INTO user_favorites (user_id, fuseaction, page_title, page_icon, added_date)
            VALUES (
                <cfqueryparam value="#userId#"     cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#fuseaction#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#pageTitle#"  cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#pageIcon#"   cfsqltype="cf_sql_varchar">,
                NOW()
            )
        </cfquery>
        <cfoutput>{"success":true,"action":"added","is_favorite":true}</cfoutput>
    </cfif>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":"Veritabanı hatası: #jsStringFormat(cfcatch.message)#"}</cfoutput>
    </cfcatch>
</cftry>
