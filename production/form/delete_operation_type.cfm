<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfset opId = isDefined("form.operation_type_id") AND isNumeric(form.operation_type_id) ? val(form.operation_type_id) : 0>

    <cfif opId lte 0>
        <cfset response.message = "Geçersiz ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Referans kontrolü --->
    <cfquery name="chkWs" datasource="boyahane">
        SELECT COUNT(*) AS cnt FROM workstations_products
        WHERE operation_type_id = <cfqueryparam value="#opId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif val(chkWs.cnt) gt 0>
        <cfset response.message = "Bu operasyon tipine bağlı " & chkWs.cnt & " istasyon kaydı var. Önce bunları kaldırın.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM operation_types
        WHERE operation_type_id = <cfqueryparam value="#opId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response = { "success": true }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>