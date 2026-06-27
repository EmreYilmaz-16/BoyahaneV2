<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
    <cfset currentUserId = 0>
    <cfif structKeyExists(session, "user") AND structKeyExists(session.user, "id") AND isNumeric(session.user.id)>
        <cfset currentUserId = val(session.user.id)>
    <cfelseif structKeyExists(session, "ep") AND structKeyExists(session.ep, "userid") AND isNumeric(session.ep.userid)>
        <cfset currentUserId = val(session.ep.userid)>
    </cfif>

    <cfif currentUserId lte 0>
        <cfoutput>#serializeJSON({"success":false,"message":"Kullanıcı bilgisi bulunamadı."})#</cfoutput><cfabort>
    </cfif>

    <cfparam name="form.selected_fields" default="">
    <cfset allowedFields = "plan_rn,parti_rn,firma_adi,kumas_cinsi,renk_kodu,renk_adi,kg,sure,plan_bas,plan_bit">
    <cfset cleanFields = []>
    <cfloop list="#form.selected_fields#" index="fieldKey">
        <cfset fieldKey = trim(fieldKey)>
        <cfif len(fieldKey) AND listFindNoCase(allowedFields, fieldKey) AND NOT listFindNoCase(arrayToList(cleanFields), fieldKey)>
            <cfset arrayAppend(cleanFields, fieldKey)>
        </cfif>
    </cfloop>
    <cfset prefValue = arrayToList(cleanFields)>

    <cfquery datasource="boyahane">
        CREATE TABLE IF NOT EXISTS production_user_preferences (
            user_id INTEGER NOT NULL,
            pref_key VARCHAR(100) NOT NULL,
            pref_value TEXT,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (user_id, pref_key)
        )
    </cfquery>

    <cfquery datasource="boyahane">
        INSERT INTO production_user_preferences (user_id, pref_key, pref_value, updated_at)
        VALUES (
            <cfqueryparam value="#currentUserId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="production_timeline_vis_label_fields" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#prefValue#" cfsqltype="cf_sql_longvarchar">,
            CURRENT_TIMESTAMP
        )
        ON CONFLICT (user_id, pref_key)
        DO UPDATE SET pref_value = EXCLUDED.pref_value,
                      updated_at = CURRENT_TIMESTAMP
    </cfquery>

    <cfoutput>#serializeJSON({"success":true,"message":"Sabitler kaydedildi.","selected_fields":cleanFields})#</cfoutput>
    <cfcatch>
        <cfoutput>#serializeJSON({"success":false,"message":"Sabitler kaydedilemedi: " & cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
