<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.prod_pause_type_id" default="0">
    <cfset typeId = isNumeric(form.prod_pause_type_id) AND val(form.prod_pause_type_id) gt 0 ? val(form.prod_pause_type_id) : 0>

    <cfif typeId eq 0>
        <cfset response.message = "Geçersiz ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Bağlı kayıt var mı? --->
    <cfquery name="chk" datasource="boyahane">
        SELECT COUNT(*) AS cnt FROM setup_prod_pause
        WHERE prod_pause_type_id = <cfqueryparam value="#typeId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif val(chk.cnt) gt 0>
        <cfset response.message = "Bu duruş tipine bağlı #val(chk.cnt)# kayıt var. Önce ilgili kayıtları silin.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM setup_prod_pause_type
        WHERE prod_pause_type_id = <cfqueryparam value="#typeId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfset response = { "success": true }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
