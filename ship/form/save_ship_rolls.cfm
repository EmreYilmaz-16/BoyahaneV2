<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8" reset="true">
<cfsetting showdebugoutput="false">

<cfscript>
function n(value) { return isNumeric(value) ? val(value) : 0; }
function rollStatus(diff, percent, tolerance) {
    if (abs(percent) <= tolerance || abs(diff) < 0.000001) return "uygun";
    return diff < 0 ? "çekme" : "salma/artış";
}
function metricSummary(expected, actual, tolerance) {
    var diff = actual - expected;
    var percent = expected > 0 ? (diff / expected) * 100 : 0;
    var status = rollStatus(diff, percent, tolerance);
    return {
        "expected" = expected,
        "actual" = actual,
        "diff" = diff,
        "diff_percent" = percent,
        "tolerance_percent" = tolerance,
        "status" = status,
        "out_of_tolerance" = status != "uygun"
    };
}
</cfscript>

<cftry>
    <cfif NOT (structKeyExists(session, "authenticated") AND session.authenticated)>
        <cfoutput>#serializeJSON({"success"=false,"message"="Yetkisiz erişim."})#</cfoutput>
        <cfabort>
    </cfif>

    <cfset orderId = isDefined("form.order_id") AND isNumeric(form.order_id) ? val(form.order_id) : 0>
    <cfset shipId = isDefined("form.ship_id") AND isNumeric(form.ship_id) ? val(form.ship_id) : 0>
    <cfset sarimTipi = isDefined("form.sarim_tipi") ? trim(form.sarim_tipi) : "standart">
    <cfset expectedMetre = isDefined("form.parti_metre") AND isNumeric(form.parti_metre) ? val(form.parti_metre) : 0>
    <cfset expectedKg = isDefined("form.parti_kg") AND isNumeric(form.parti_kg) ? val(form.parti_kg) : 0>
    <cfset metreTolerancePercent = isDefined("form.metre_tolerance_percent") AND isNumeric(form.metre_tolerance_percent) ? val(form.metre_tolerance_percent) : 0>
    <cfset kgTolerancePercent = isDefined("form.kg_tolerance_percent") AND isNumeric(form.kg_tolerance_percent) ? val(form.kg_tolerance_percent) : 0>
    <cfset hedefTopAdedi = isDefined("form.hedef_top_adedi") AND isNumeric(form.hedef_top_adedi) ? val(form.hedef_top_adedi) : 0>
    <cfset rollsJson = isDefined("form.ship_rolls") AND len(trim(form.ship_rolls)) ? form.ship_rolls : "[]">

    <cfif NOT listFindNoCase("standart,kg_bazli,topa_top", sarimTipi)>
        <cfoutput>#serializeJSON({"success"=false,"message"="Geçersiz sarım tipi."})#</cfoutput><cfabort>
    </cfif>
    <cfif orderId lte 0>
        <cfoutput>#serializeJSON({"success"=false,"message"="order_id gerekli. Önce refakat barkodunu okutun."})#</cfoutput><cfabort>
    </cfif>

    <cfquery name="getParti" datasource="boyahane">
        SELECT o.order_id, o.order_number, o.ref_ship_id,
               COALESCE(s.hk_metre, 0) AS ship_metre,
               COALESCE(s.hk_kg, 0) AS ship_kg,
               COALESCE(s.hk_top_adedi, 0) AS ship_top_adedi
        FROM orders o
        LEFT JOIN ship s ON s.ship_id = o.ref_ship_id
        WHERE o.order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getParti.recordCount>
        <cfoutput>#serializeJSON({"success"=false,"message"="Parti bulunamadı."})#</cfoutput><cfabort>
    </cfif>
    <cfif shipId lte 0 AND isNumeric(getParti.ref_ship_id)><cfset shipId = val(getParti.ref_ship_id)></cfif>
    <cfif expectedMetre lte 0><cfset expectedMetre = n(getParti.ship_metre)></cfif>
    <cfif expectedKg lte 0><cfset expectedKg = n(getParti.ship_kg)></cfif>
    <cfif hedefTopAdedi lte 0><cfset hedefTopAdedi = n(getParti.ship_top_adedi)></cfif>

    <cfset rolls = deserializeJSON(rollsJson)>
    <cfif NOT isArray(rolls) OR arrayLen(rolls) eq 0>
        <cfoutput>#serializeJSON({"success"=false,"message"="En az bir top satırı girilmelidir."})#</cfoutput><cfabort>
    </cfif>

    <cfset normalizedRolls = []>
    <cfset seenRollNos = {}>
    <cfset actualMetre = 0>
    <cfset actualKg = 0>
    <cfloop from="1" to="#arrayLen(rolls)#" index="i">
        <cfset roll = rolls[i]>
        <cfset rollNo = structKeyExists(roll, "roll_no") AND isNumeric(roll.roll_no) AND val(roll.roll_no) gt 0 ? val(roll.roll_no) : i>
        <cfset metre = structKeyExists(roll, "metre") ? n(roll.metre) : 0>
        <cfset kg = structKeyExists(roll, "kg") ? n(roll.kg) : 0>
        <cfif metre lt 0 OR kg lt 0>
            <cfoutput>#serializeJSON({"success"=false,"message"="Metre/Kg negatif olamaz."})#</cfoutput><cfabort>
        </cfif>
        <cfif metre eq 0 AND kg eq 0>
            <cfoutput>#serializeJSON({"success"=false,"message"="Her top satırında metre veya kg değeri olmalıdır."})#</cfoutput><cfabort>
        </cfif>
        <cfif structKeyExists(seenRollNos, rollNo)>
            <cfoutput>#serializeJSON({"success"=false,"message"="Top no tekrar ediyor: #rollNo#"})#</cfoutput><cfabort>
        </cfif>
        <cfset seenRollNos[rollNo] = true>
        <cfset actualMetre += metre>
        <cfset actualKg += kg>
        <cfset arrayAppend(normalizedRolls, {"roll_no"=rollNo,"metre"=metre,"kg"=kg})>
    </cfloop>

    <cfset metreSummary = metricSummary(expectedMetre, actualMetre, metreTolerancePercent)>
    <cfset kgSummary = metricSummary(expectedKg, actualKg, kgTolerancePercent)>
    <cfset warnings = []>
    <cfif metreSummary.out_of_tolerance><cfset arrayAppend(warnings, "Metre farkı tolerans dışında: " & metreSummary.status & " (" & numberFormat(metreSummary.diff_percent, "0.00") & "%).")></cfif>
    <cfif kgSummary.out_of_tolerance><cfset arrayAppend(warnings, "Kg farkı tolerans dışında: " & kgSummary.status & " (" & numberFormat(kgSummary.diff_percent, "0.00") & "%).")></cfif>

    <cftransaction>
        <cfquery name="insertPlan" datasource="boyahane">
            INSERT INTO ship_roll_plan (
                order_id, ship_id, refakat_barcode, sarim_tipi, hedef_metre, hedef_kg,
                hedef_top_adedi, tolerans_metre, tolerans_kg, record_emp, record_date
            ) VALUES (
                <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer" null="#shipId lte 0#">,
                <cfqueryparam value="#getParti.order_number#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#sarimTipi#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#expectedMetre#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#expectedKg#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#hedefTopAdedi#" cfsqltype="cf_sql_integer" null="#hedefTopAdedi lte 0#">,
                <cfqueryparam value="#metreTolerancePercent#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#kgTolerancePercent#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#structKeyExists(session, 'employee_id') ? val(session.employee_id) : 0#" cfsqltype="cf_sql_integer" null="#NOT structKeyExists(session, 'employee_id')#">,
                CURRENT_TIMESTAMP
            )
            RETURNING plan_id
        </cfquery>
        <cfset planId = val(insertPlan.plan_id)>
        <cfset savedRolls = []>
        <cfloop array="#normalizedRolls#" index="roll">
            <cfset barcode = "SR-" & orderId & "-" & numberFormat(roll.roll_no, "000")>
            <cfquery name="insRoll" datasource="boyahane">
                INSERT INTO ship_roll (
                    plan_id, order_id, ship_id, roll_no, roll_barcode, metre, kg,
                    paket_durumu, etiket_print_count, record_emp, record_date
                ) VALUES (
                    <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer" null="#shipId lte 0#">,
                    <cfqueryparam value="#roll.roll_no#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#roll.metre#" cfsqltype="cf_sql_numeric">,
                    <cfqueryparam value="#roll.kg#" cfsqltype="cf_sql_numeric">,
                    <cfqueryparam value="paketlendi" cfsqltype="cf_sql_varchar">,
                    0,
                    <cfqueryparam value="#structKeyExists(session, 'employee_id') ? val(session.employee_id) : 0#" cfsqltype="cf_sql_integer" null="#NOT structKeyExists(session, 'employee_id')#">,
                    CURRENT_TIMESTAMP
                )
                RETURNING roll_id
            </cfquery>
            <cfset arrayAppend(savedRolls, {"roll_id"=val(insRoll.roll_id),"roll_no"=roll.roll_no,"roll_barcode"=barcode,"metre"=roll.metre,"kg"=roll.kg})>
        </cfloop>
    </cftransaction>

    <cfset response = {
        "success" = true,
        "message" = arrayLen(warnings) ? "Toplar kaydedildi; tolerans uyarısı var." : "Toplar kaydedildi ve barkodlar üretildi.",
        "warning" = arrayLen(warnings) gt 0,
        "warnings" = warnings,
        "plan_id" = planId,
        "rolls" = savedRolls,
        "validation" = {"metre" = metreSummary, "kg" = kgSummary}
    }>
    <cfoutput>#serializeJSON(response)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success"=false,"message"=cfcatch.message,"detail"=cfcatch.detail})#</cfoutput>
    </cfcatch>
</cftry>
