<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cfif NOT structKeyExists(session, "authenticated") OR NOT session.authenticated>
    <cfoutput>[]</cfoutput>
    <cfabort>
</cfif>

<cfparam name="url.keyword" default="">
<cfparam name="url.by_id"   default="0">

<cfset keyword = trim(url.keyword)>
<cfset byId    = val(url.by_id)>

<cftry>
    <cfif byId GT 0>
        <!--- Seçili kaydı id ile getir (dxSelectBox byKey için) --->
        <cfquery name="qResult" datasource="boyahane" maxrows="1">
            SELECT company_id,
                   COALESCE(nickname, fullname, member_code, 'Firma') AS display_name,
                   COALESCE(member_code, '') AS company_code
            FROM company
            WHERE company_id = <cfqueryparam value="#byId#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelseif len(keyword) GTE 2>
        <!--- Keyword araması --->
        <cfquery name="qResult" datasource="boyahane" maxrows="80">
            SELECT company_id,
                   COALESCE(nickname, fullname, member_code, 'Firma') AS display_name,
                   COALESCE(member_code, '') AS company_code
            FROM company
            WHERE COALESCE(nickname, fullname, member_code, '') ILIKE <cfqueryparam value="%#keyword#%" cfsqltype="cf_sql_varchar">
               OR COALESCE(member_code, '') ILIKE <cfqueryparam value="%#keyword#%" cfsqltype="cf_sql_varchar">
            ORDER BY COALESCE(nickname, fullname, member_code, 'Firma')
        </cfquery>
    <cfelse>
        <cfoutput>[]</cfoutput>
        <cfabort>
    </cfif>

    <cfset result = []>
    <cfloop query="qResult">
        <cfset arrayAppend(result, {
            "company_id"   : val(company_id),
            "display_name" : display_name  ?: "",
            "company_code" : company_code  ?: ""
        })>
    </cfloop>

    <cfoutput>#serializeJSON(result)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>[]</cfoutput>
    </cfcatch>
</cftry>
