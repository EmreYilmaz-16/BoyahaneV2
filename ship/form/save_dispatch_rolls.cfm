<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8" reset="true">
<cfsetting showdebugoutput="false">

<cftry>
    <!--- Mobile API: userid parametresi ile veya session ile auth --->
    <cfset mobileUserId = isDefined("form.userid") AND len(trim(form.userid)) ? trim(form.userid) : "99999999999999">
    <cfif len(mobileUserId)>
        <!--- Mobile: userid veritabanında var ve aktif mi kontrol et --->
        <cfquery name="checkMobileUser" datasource="boyahane">
            SELECT id FROM kullanicilar
            WHERE (id = <cfqueryparam value="#mobileUserId#" cfsqltype="cf_sql_varchar">
               OR w3userid = <cfqueryparam value="#mobileUserId#" cfsqltype="cf_sql_varchar">)
              AND is_active = true
            LIMIT 1
        </cfquery>
        <cfif NOT checkMobileUser.recordCount>
            <cfoutput>#serializeJSON({"success"=false,"message"="Yetkisiz erişim. "})#</cfoutput><cfabort>
        </cfif>
    <cfelseif NOT (structKeyExists(session, "authenticated") AND session.authenticated)>
        <cfoutput>#serializeJSON({"success"=false,"message"="Yetkisiz erişim."})#</cfoutput><cfabort>
    </cfif>

    <cfset rollIdsJson = isDefined("form.roll_ids") AND len(trim(form.roll_ids)) ? form.roll_ids : "[]">
    <cfset dispatchShipId = isDefined("form.dispatch_ship_id") AND isNumeric(form.dispatch_ship_id) ? val(form.dispatch_ship_id) : 0>
    <cfset rollIds = deserializeJSON(rollIdsJson)>

    <cfif NOT isArray(rollIds) OR arrayLen(rollIds) eq 0>
        <cfoutput>#serializeJSON({"success"=false,"message"="Sevk edilecek top listesi boş."})#</cfoutput><cfabort>
    </cfif>

    <cfset normalizedIds = []>
    <cfset seenIds = {}>
    <cfloop array="#rollIds#" index="rollId">
        <cfif NOT isNumeric(rollId) OR val(rollId) lte 0>
            <cfoutput>#serializeJSON({"success"=false,"message"="Geçersiz top ID."})#</cfoutput><cfabort>
        </cfif>
        <cfif NOT structKeyExists(seenIds, val(rollId))>
            <cfset seenIds[val(rollId)] = true>
            <cfset arrayAppend(normalizedIds, val(rollId))>
        </cfif>
    </cfloop>

    <cfif dispatchShipId gt 0>
        <cfquery name="checkShip" datasource="boyahane">
            SELECT ship_id FROM ship
            WHERE ship_id = <cfqueryparam value="#dispatchShipId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif NOT checkShip.recordCount>
            <cfoutput>#serializeJSON({"success"=false,"message"="Sevkiyat/irsaliye bulunamadı."})#</cfoutput><cfabort>
        </cfif>
    </cfif>

    <cfquery name="checkRolls" datasource="boyahane">
        SELECT roll_id, roll_barcode, paket_durumu
        FROM ship_roll
        WHERE roll_id IN (<cfqueryparam value="#arrayToList(normalizedIds)#" cfsqltype="cf_sql_integer" list="true">)
    </cfquery>
    <cfif checkRolls.recordCount neq arrayLen(normalizedIds)>
        <cfoutput>#serializeJSON({"success"=false,"message"="Okutulan toplardan bazıları bulunamadı."})#</cfoutput><cfabort>
    </cfif>
    <cfloop query="checkRolls">
        <cfif len(trim(paket_durumu ?: "")) AND lCase(trim(paket_durumu)) EQ "sevk edildi">
            <cfoutput>#serializeJSON({"success"=false,"message"="Top daha önce sevk edilmiş: #roll_barcode#"})#</cfoutput><cfabort>
        </cfif>
    </cfloop>

    <cftransaction>
        <cfquery name="updRolls" datasource="boyahane">
            UPDATE ship_roll
               SET paket_durumu = 'sevk edildi',
                   dispatch_ship_id = <cfqueryparam value="#dispatchShipId#" cfsqltype="cf_sql_integer" null="#dispatchShipId lte 0#">,
                   dispatch_date = CURRENT_TIMESTAMP,
                   dispatch_emp = <cfqueryparam value="#structKeyExists(session, 'employee_id') ? val(session.employee_id) : 0#" cfsqltype="cf_sql_integer" null="#NOT structKeyExists(session, 'employee_id')#">,
                   update_emp = <cfqueryparam value="#structKeyExists(session, 'employee_id') ? val(session.employee_id) : 0#" cfsqltype="cf_sql_integer" null="#NOT structKeyExists(session, 'employee_id')#">,
                   update_date = CURRENT_TIMESTAMP
             WHERE roll_id IN (<cfqueryparam value="#arrayToList(normalizedIds)#" cfsqltype="cf_sql_integer" list="true">)
        </cfquery>
    </cftransaction>

    <cfoutput>#serializeJSON({
        "success"=true,
        "message"="#arrayLen(normalizedIds)# top sevk edildi.",
        "dispatched_count"=arrayLen(normalizedIds),
        "dispatch_ship_id"=dispatchShipId
    })#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success"=false,"message"=cfcatch.message,"detail"=cfcatch.detail})#</cfoutput>
    </cfcatch>
</cftry>
