<cfcomponent output="false" hint="Para Birimi ve Kur Yönetimi">

    <!--- Para Birimi Sil --->
    <cffunction name="deleteMoney" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cfset var result = {}>
        <cftry>
            <cfquery datasource="boyahane">
                DELETE FROM setup_money WHERE money_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset result = {"success": true, "message": "Para birimi silindi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Silme hatası: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Kur Geçmişi Sil --->
    <cffunction name="deleteMoneyHistory" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        <cfset var result = {}>
        <cftry>
            <cfquery datasource="boyahane">
                DELETE FROM money_history WHERE money_history_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset result = {"success": true, "message": "Kayıt silindi"}>
            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Silme hatası: #cfcatch.message#"}>
            </cfcatch>
        </cftry>
        <cfreturn serializeJSON(result)>
    </cffunction>

</cfcomponent>
