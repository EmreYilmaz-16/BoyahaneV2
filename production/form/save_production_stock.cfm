<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!--- Hammadde tüketim satırı güncelle veya sil --->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.por_stock_id" default="0">
    <cfparam name="form.amount"       default="0">
    <cfparam name="form._delete"      default="0">

    <cfset rowId    = isNumeric(form.por_stock_id) AND val(form.por_stock_id) gt 0 ? val(form.por_stock_id) : 0>
    <cfset delMode  = (form._delete eq "1" OR form._delete eq "true")>
    <cfset amt      = isNumeric(form.amount) ? val(form.amount) : 0>

    <cfif rowId eq 0>
        <cfset response.message = "Geçersiz kayıt ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif delMode>
        <cfquery datasource="boyahane">
            DELETE FROM production_orders_stocks
            WHERE por_stock_id = <cfqueryparam value="#rowId#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <cfquery datasource="boyahane">
            UPDATE production_orders_stocks
            SET amount = <cfqueryparam value="#amt#" cfsqltype="cf_sql_numeric">
            WHERE por_stock_id = <cfqueryparam value="#rowId#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cfif>

    <cfset response = { "success": true, "por_stock_id": rowId }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>