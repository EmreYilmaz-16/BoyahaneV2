<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8" reset="true">
<cfsetting showdebugoutput="false">
<cfparam name="form.order_id" default="0">
<cfparam name="form.roll_type" default="">
<cfparam name="form.rolls_json" default="[]">
<cfset orderId = val(form.order_id)>
<cfset rollType = trim(form.roll_type)>
<cftry>
    <cfif orderId LTE 0 OR NOT listFindNoCase("standard,kg,top", rollType)>
        <cfoutput>#serializeJSON({"success":false,"message":"Parti ve sarım tipi zorunludur."})#</cfoutput><cfabort>
    </cfif>
    <cfset rolls = deserializeJSON(form.rolls_json)>
    <cfif NOT isArray(rolls) OR arrayLen(rolls) EQ 0>
        <cfoutput>#serializeJSON({"success":false,"message":"En az bir top girilmelidir."})#</cfoutput><cfabort>
    </cfif>
    <cfquery datasource="boyahane">
        CREATE TABLE IF NOT EXISTS ship_rolls (
            roll_id SERIAL PRIMARY KEY,
            order_id INTEGER NOT NULL,
            roll_type VARCHAR(20) NOT NULL,
            roll_no INTEGER NOT NULL,
            metre NUMERIC(18,4) DEFAULT 0,
            kg NUMERIC(18,4) DEFAULT 0,
            record_date TIMESTAMP DEFAULT NOW()
        )
    </cfquery>
    <cftransaction>
        <cfquery datasource="boyahane">
            DELETE FROM ship_rolls WHERE order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfloop from="1" to="#arrayLen(rolls)#" index="i">
            <cfset r = rolls[i]>
            <cfquery datasource="boyahane">
                INSERT INTO ship_rolls (order_id, roll_type, roll_no, metre, kg)
                VALUES (
                    <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#rollType#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#i#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#structKeyExists(r, 'metre') AND isNumeric(r.metre) ? val(r.metre) : 0#" cfsqltype="cf_sql_decimal">,
                    <cfqueryparam value="#structKeyExists(r, 'kg') AND isNumeric(r.kg) ? val(r.kg) : 0#" cfsqltype="cf_sql_decimal">
                )
            </cfquery>
        </cfloop>
    </cftransaction>
    <cfoutput>#serializeJSON({"success":true,"message":"Sarım topları kaydedildi.","count":arrayLen(rolls)})#</cfoutput>
    <cfcatch><cfoutput>#serializeJSON({"success":false,"message":cfcatch.message})#</cfoutput></cfcatch>
</cftry>
