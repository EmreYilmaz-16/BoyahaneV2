<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8" reset="true">
<cfsetting showdebugoutput="false">
<cftry>
    <cfquery name="ping" datasource="boyahane">SELECT 1 AS ok</cfquery>
    <cfoutput>#serializeJSON({"status"="ok","service"="kalite-operator-api"})#</cfoutput>
    <cfcatch type="any"><cfheader statuscode="503" statustext="Service Unavailable"><cfoutput>#serializeJSON({"status"="error","message"=cfcatch.message})#</cfoutput></cfcatch>
</cftry>
