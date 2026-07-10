<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8" reset="true">
<cfsetting showdebugoutput="false">
<cftry>
    <cfset requestBody = trim(toString(getHttpRequestData().content))>
    <cfset payload = len(requestBody) ? deserializeJSON(requestBody) : {}>
    <cfset password = structKeyExists(payload, "password") ? trim(payload.password) : "">
    <cfif NOT len(password)>
        <cfheader statuscode="400" statustext="Bad Request"><cfoutput>#serializeJSON({"success"=false,"message"="password gerekli."})#</cfoutput><cfabort>
    </cfif>
    <cfquery name="getUser" datasource="boyahane">
        SELECT id, name, surname, username, w3userid, is_active
        FROM kullanicilar
        WHERE password = <cfqueryparam value="#password#" cfsqltype="cf_sql_varchar">
          AND is_active = true
        ORDER BY CASE WHEN username = 'admin' THEN 0 ELSE 1 END, id
        LIMIT 1
    </cfquery>
    <cfif NOT getUser.recordCount>
        <cfheader statuscode="401" statustext="Unauthorized"><cfoutput>#serializeJSON({"success"=false,"message"="Geçersiz operatör şifresi."})#</cfoutput><cfabort>
    </cfif>
    <cfset role = compareNoCase(trim(getUser.username), "admin") eq 0 ? "admin" : "user">
    <cfoutput>#serializeJSON({"name"=getUser.name ?: "","surname"=getUser.surname ?: "","userid"=len(trim(getUser.w3userid ?: "")) ? getUser.w3userid : toString(getUser.id),"userrole"=role})#</cfoutput>
    <cfcatch type="any"><cfheader statuscode="500" statustext="Internal Server Error"><cfoutput>#serializeJSON({"success"=false,"message"=cfcatch.message})#</cfoutput></cfcatch>
</cftry>
