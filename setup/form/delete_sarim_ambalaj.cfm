<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.table_type" default="">
    <cfparam name="form.row_id"     default="0">

    <cfset tableType = lCase(trim(form.table_type))>
    <cfset rowId     = isNumeric(form.row_id) AND val(form.row_id) gt 0 ? val(form.row_id) : 0>

    <cfif NOT listFind("sarim,ambalaj", tableType)>
        <cfset response.message = "Geçersiz tablo tipi.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif rowId eq 0>
        <cfset response.message = "Geçersiz ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif tableType eq "sarim">
        <cfset tableName = "setup_sarim_sekli">
        <cfset idColumn  = "sarim_sekli_id">
        <!--- Bağlı parti var mı? --->
        <cfquery name="chk" datasource="boyahane">
            SELECT COUNT(*) AS cnt FROM orders WHERE sarim_sekli = <cfqueryparam value="#rowId#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <cfset tableName = "setup_ambalaj">
        <cfset idColumn  = "ambalaj_id">
        <cfquery name="chk" datasource="boyahane">
            SELECT COUNT(*) AS cnt FROM orders WHERE ambalaj = <cfqueryparam value="#rowId#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cfif>

    <cfif val(chk.cnt) gt 0>
        <cfset response.message = "Bu kayıt #val(chk.cnt)# partide kullanılıyor. Silinemez.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM #tableName#
        WHERE #idColumn# = <cfqueryparam value="#rowId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfset response = { "success": true }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
