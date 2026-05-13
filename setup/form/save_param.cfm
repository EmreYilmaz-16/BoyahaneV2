<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.param_id"      default="0">
    <cfparam name="form.parametre_adi" default="">
    <cfparam name="form.deger"         default="">
    <cfparam name="form.aciklama"      default="">

    <cfset paramId      = isNumeric(form.param_id) AND val(form.param_id) gt 0 ? val(form.param_id) : 0>
    <cfset parametreAdi = trim(form.parametre_adi)>
    <cfset deger        = trim(form.deger)>
    <cfset aciklama     = trim(form.aciklama)>

    <cfif NOT len(parametreAdi)>
        <cfset response.message = "Parametre adı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Benzersizlik kontrolü --->
    <cfquery name="chkUnique" datasource="boyahane">
        SELECT param_id FROM boyahane_params
        WHERE parametre_adi = <cfqueryparam value="#parametreAdi#" cfsqltype="cf_sql_varchar">
        <cfif paramId gt 0>
            AND param_id <> <cfqueryparam value="#paramId#" cfsqltype="cf_sql_integer">
        </cfif>
    </cfquery>
    <cfif chkUnique.recordCount>
        <cfset response.message = "'#parametreAdi#' adında bir parametre zaten mevcut.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif paramId gt 0>
        <cfquery datasource="boyahane">
            UPDATE boyahane_params SET
                parametre_adi = <cfqueryparam value="#parametreAdi#" cfsqltype="cf_sql_varchar">,
                deger         = <cfqueryparam value="#deger#"        cfsqltype="cf_sql_varchar">,
                aciklama      = <cfqueryparam value="#aciklama#"     cfsqltype="cf_sql_varchar" null="#NOT len(aciklama)#">,
                update_date   = CURRENT_TIMESTAMP
            WHERE param_id = <cfqueryparam value="#paramId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset response = { "success": true, "param_id": paramId, "mode": "updated" }>
    <cfelse>
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO boyahane_params (parametre_adi, deger, aciklama)
            VALUES (
                <cfqueryparam value="#parametreAdi#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#deger#"        cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#aciklama#"     cfsqltype="cf_sql_varchar" null="#NOT len(aciklama)#">
            )
            RETURNING param_id
        </cfquery>
        <cfset response = { "success": true, "param_id": val(ins.param_id), "mode": "added" }>
    </cfif>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
