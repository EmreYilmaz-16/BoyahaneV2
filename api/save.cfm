<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8" reset="true">
<cfsetting showdebugoutput="false">
<cfscript>
function n(value) { return isNumeric(value) ? val(value) : 0; }
function s(payload, key) { return structKeyExists(payload, key) ? trim(toString(payload[key])) : ""; }
</cfscript>
<cftry>
    <cfset requestBody = trim(toString(getHttpRequestData().content))>
    <cfset payload = len(requestBody) ? deserializeJSON(requestBody) : {}>
    <cfset partyId = isNumeric(s(payload,"party_id")) ? val(s(payload,"party_id")) : 0>
    <cfset barcode = s(payload,"barcode")>
    <cfset meter = structKeyExists(payload,"meter") ? n(payload.meter) : 0>
    <cfset kg = structKeyExists(payload,"kg") ? n(payload.kg) : 0>
    <cfset operatorUserId = s(payload,"operator_userid")>
    <cfif partyId lte 0><cfheader statuscode="400" statustext="Bad Request"><cfoutput>#serializeJSON({"success"=false,"message"="party_id gerekli."})#</cfoutput><cfabort></cfif>
    <cfif meter eq 0 AND kg eq 0><cfheader statuscode="400" statustext="Bad Request"><cfoutput>#serializeJSON({"success"=false,"message"="meter veya kg gerekli."})#</cfoutput><cfabort></cfif>
    <cfquery name="getParti" datasource="boyahane">
        SELECT order_id, order_number, ref_ship_id FROM orders WHERE order_id = <cfqueryparam value="#partyId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getParti.recordCount><cfheader statuscode="404" statustext="Not Found"><cfoutput>#serializeJSON({"success"=false,"message"="Parti bulunamadı."})#</cfoutput><cfabort></cfif>
    <cfquery name="getUser" datasource="boyahane">
        SELECT id FROM kullanicilar
        WHERE w3userid = <cfqueryparam value="#operatorUserId#" cfsqltype="cf_sql_varchar">
           OR (<cfqueryparam value="#isNumeric(operatorUserId) ? val(operatorUserId) : 0#" cfsqltype="cf_sql_integer"> > 0 AND id = <cfqueryparam value="#isNumeric(operatorUserId) ? val(operatorUserId) : 0#" cfsqltype="cf_sql_integer">)
        LIMIT 1
    </cfquery>
    <cftransaction>
        <cfquery name="getPlan" datasource="boyahane">
            SELECT plan_id FROM ship_roll_plan WHERE order_id = <cfqueryparam value="#partyId#" cfsqltype="cf_sql_integer"> AND sarim_tipi = 'topa_top' ORDER BY plan_id DESC LIMIT 1
        </cfquery>
        <cfif getPlan.recordCount><cfset planId = val(getPlan.plan_id)><cfelse>
            <cfquery name="insertPlan" datasource="boyahane">
                INSERT INTO ship_roll_plan (order_id, ship_id, refakat_barcode, sarim_tipi, hedef_metre, hedef_kg, hedef_top_adedi, tolerans_metre, tolerans_kg, record_emp, record_date)
                VALUES (<cfqueryparam value="#partyId#" cfsqltype="cf_sql_integer">,<cfqueryparam value="#getParti.ref_ship_id#" cfsqltype="cf_sql_integer" null="#NOT isNumeric(getParti.ref_ship_id)#">,<cfqueryparam value="#len(barcode) ? barcode : getParti.order_number#" cfsqltype="cf_sql_varchar">,'topa_top',0,0,NULL,0,0,<cfqueryparam value="#getUser.recordCount ? val(getUser.id) : 0#" cfsqltype="cf_sql_integer" null="#NOT getUser.recordCount#">,CURRENT_TIMESTAMP)
                RETURNING plan_id
            </cfquery><cfset planId = val(insertPlan.plan_id)>
        </cfif>
        <cfquery name="getNext" datasource="boyahane">SELECT COALESCE(MAX(roll_no),0)+1 AS next_no FROM ship_roll WHERE order_id = <cfqueryparam value="#partyId#" cfsqltype="cf_sql_integer"></cfquery>
        <cfset rollNo = val(getNext.next_no)>
        <cfset labelBarcode = "SR-" & partyId & "-" & numberFormat(rollNo,"000")>
        <cfquery name="insRoll" datasource="boyahane">
            INSERT INTO ship_roll (plan_id, order_id, ship_id, roll_no, roll_barcode, metre, kg, paket_durumu, etiket_print_count, record_emp, record_date)
            VALUES (<cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">,<cfqueryparam value="#partyId#" cfsqltype="cf_sql_integer">,<cfqueryparam value="#getParti.ref_ship_id#" cfsqltype="cf_sql_integer" null="#NOT isNumeric(getParti.ref_ship_id)#">,<cfqueryparam value="#rollNo#" cfsqltype="cf_sql_integer">,<cfqueryparam value="#labelBarcode#" cfsqltype="cf_sql_varchar">,<cfqueryparam value="#meter#" cfsqltype="cf_sql_numeric">,<cfqueryparam value="#kg#" cfsqltype="cf_sql_numeric">,<cfqueryparam value="#left(s(payload,'notes'),50)#" cfsqltype="cf_sql_varchar" null="#NOT len(s(payload,'notes'))#">,0,<cfqueryparam value="#getUser.recordCount ? val(getUser.id) : 0#" cfsqltype="cf_sql_integer" null="#NOT getUser.recordCount#">,CURRENT_TIMESTAMP)
            RETURNING roll_id
        </cfquery>
        <cfquery name="insApi" datasource="boyahane">
            INSERT INTO operator_quality_records (roll_id, request_payload, error_category, error_code, error_description, operator_name, operator_surname, operator_userid, operator_role, notes, last_measurement, saved_at)
            VALUES (<cfqueryparam value="#insRoll.roll_id#" cfsqltype="cf_sql_integer">,<cfqueryparam value="#requestBody#" cfsqltype="cf_sql_longvarchar">,<cfqueryparam value="#s(payload,'error_category')#" cfsqltype="cf_sql_varchar" null="#NOT len(s(payload,'error_category'))#">,<cfqueryparam value="#s(payload,'error_code')#" cfsqltype="cf_sql_varchar" null="#NOT len(s(payload,'error_code'))#">,<cfqueryparam value="#s(payload,'error_description')#" cfsqltype="cf_sql_varchar" null="#NOT len(s(payload,'error_description'))#">,<cfqueryparam value="#s(payload,'operator_name')#" cfsqltype="cf_sql_varchar" null="#NOT len(s(payload,'operator_name'))#">,<cfqueryparam value="#s(payload,'operator_surname')#" cfsqltype="cf_sql_varchar" null="#NOT len(s(payload,'operator_surname'))#">,<cfqueryparam value="#operatorUserId#" cfsqltype="cf_sql_varchar" null="#NOT len(operatorUserId)#">,<cfqueryparam value="#s(payload,'operator_role')#" cfsqltype="cf_sql_varchar" null="#NOT len(s(payload,'operator_role'))#">,<cfqueryparam value="#s(payload,'notes')#" cfsqltype="cf_sql_longvarchar" null="#NOT len(s(payload,'notes'))#">,<cfqueryparam value="#s(payload,'last_measurement')#" cfsqltype="cf_sql_varchar" null="#NOT len(s(payload,'last_measurement'))#">,<cfqueryparam value="#s(payload,'saved_at')#" cfsqltype="cf_sql_timestamp" null="#NOT isDate(s(payload,'saved_at'))#">)
        </cfquery>
    </cftransaction>
    <cfoutput>#serializeJSON({"success"=true,"record_id"=val(insRoll.roll_id),"barcode"=labelBarcode,"roll_id"=val(insRoll.roll_id),"plan_id"=planId})#</cfoutput>
    <cfcatch type="any"><cfheader statuscode="500" statustext="Internal Server Error"><cfoutput>#serializeJSON({"success"=false,"message"=cfcatch.message,"detail"=cfcatch.detail})#</cfoutput></cfcatch>
</cftry>
