<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfif NOT structKeyExists(session, "authenticated") OR NOT session.authenticated>
        <cfoutput>{"success":false,"message":"Oturum gerekli."}</cfoutput>
        <cfabort>
    </cfif>

    <cfparam name="url.company_id" default="0">
    <cfset cid = val(url.company_id)>

    <cfif cid LTE 0>
        <cfoutput>{"success":false,"message":"Geçersiz firma."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="q" datasource="boyahane" maxrows="1">
        SELECT
            COALESCE(cc.paymethod_id,   0) AS paymethod_id,
            COALESCE(cc.ship_method_id, 0) AS ship_method_id,
            COALESCE(cc.price_cat,      0) AS price_cat
        FROM company_credit cc
        WHERE cc.company_id = <cfqueryparam value="#cid#" cfsqltype="cf_sql_integer">
        ORDER BY cc.company_credit_id DESC
    </cfquery>

    <cfif q.recordCount>
        <cfoutput>{"success":true,"paymethod_id":#val(q.paymethod_id)#,"ship_method_id":#val(q.ship_method_id)#,"price_cat":#val(q.price_cat)#}</cfoutput>
    <cfelse>
        <cfoutput>{"success":false}</cfoutput>
    </cfif>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
