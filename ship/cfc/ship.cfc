<cfcomponent output="false" hint="İrsaliye / Sevkiyat Yönetimi">

    <!--- İrsaliye Sil --->
    <cffunction name="deleteShip" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cfset var result = {}>
        <cftry>
            <cfquery datasource="boyahane">
                DELETE FROM ship_row WHERE ship_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfquery datasource="boyahane">
                DELETE FROM ship_money WHERE action_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfquery datasource="boyahane">
                DELETE FROM ship WHERE ship_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset result = {"success": true, "message": "İrsaliye silindi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Silme hatası: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- İrsaliye Satırı Sil --->
    <cffunction name="deleteShipRow" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cfset var result = {}>
        <cftry>
            <cfquery datasource="boyahane">
                DELETE FROM ship_row WHERE ship_row_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset result = {"success": true, "message": "Satır silindi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

</cfcomponent>
