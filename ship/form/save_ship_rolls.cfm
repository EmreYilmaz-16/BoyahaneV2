<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cfscript>
function n(value) {
    return isNumeric(value) ? val(value) : 0;
}
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
    <cfif NOT isDefined("session.authenticated") OR NOT session.authenticated>
        <cfoutput>#serializeJSON({"success"=false,"message"="Yetkisiz erişim."})#</cfoutput>
        <cfabort>
    </cfif>

    <cfset shipId = isDefined("form.ship_id") AND isNumeric(form.ship_id) ? val(form.ship_id) : 0>
    <cfset expectedMetre = isDefined("form.parti_metre") AND isNumeric(form.parti_metre) ? val(form.parti_metre) : 0>
    <cfset expectedKg = isDefined("form.parti_kg") AND isNumeric(form.parti_kg) ? val(form.parti_kg) : 0>
    <cfset metreTolerancePercent = isDefined("form.metre_tolerance_percent") AND isNumeric(form.metre_tolerance_percent) ? val(form.metre_tolerance_percent) : 0>
    <cfset kgTolerancePercent = isDefined("form.kg_tolerance_percent") AND isNumeric(form.kg_tolerance_percent) ? val(form.kg_tolerance_percent) : 0>
    <cfset rollsJson = isDefined("form.ship_rolls") AND len(trim(form.ship_rolls)) ? form.ship_rolls : "[]">

    <cfif shipId gt 0 AND (expectedMetre lte 0 OR expectedKg lte 0)>
        <cfquery name="getPartiExpected" datasource="boyahane">
            SELECT COALESCE(hk_metre, 0) AS parti_metre,
                   COALESCE(hk_kg, 0) AS parti_kg
            FROM ship
            WHERE ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif getPartiExpected.recordCount>
            <cfif expectedMetre lte 0><cfset expectedMetre = n(getPartiExpected.parti_metre)></cfif>
            <cfif expectedKg lte 0><cfset expectedKg = n(getPartiExpected.parti_kg)></cfif>
        </cfif>
    </cfif>

    <cfset rolls = deserializeJSON(rollsJson)>
    <cfset actualMetre = 0>
    <cfset actualKg = 0>
    <cfloop array="#rolls#" index="roll">
        <cfset actualMetre += isDefined("roll.metre") ? n(roll.metre) : 0>
        <cfset actualKg += isDefined("roll.kg") ? n(roll.kg) : 0>
    </cfloop>

    <cfset metreSummary = metricSummary(expectedMetre, actualMetre, metreTolerancePercent)>
    <cfset kgSummary = metricSummary(expectedKg, actualKg, kgTolerancePercent)>
    <cfset warnings = []>
    <cfif metreSummary.out_of_tolerance>
        <cfset arrayAppend(warnings, "Metre farkı tolerans dışında: " & metreSummary.status & " (" & numberFormat(metreSummary.diff_percent, "0.00") & "%).")>
    </cfif>
    <cfif kgSummary.out_of_tolerance>
        <cfset arrayAppend(warnings, "Kg farkı tolerans dışında: " & kgSummary.status & " (" & numberFormat(kgSummary.diff_percent, "0.00") & "%).")>
    </cfif>

    <!--- Tolerans dışı fark uyarı olarak döner; kaydı engelleme kararı yetki/iş kuralına bağlanmalıdır. --->
    <cfset response = {
        "success" = true,
        "message" = arrayLen(warnings) ? "Top miktarları tolerans uyarısı ile doğrulandı." : "Top miktarları doğrulandı.",
        "warning" = arrayLen(warnings) gt 0,
        "warnings" = warnings,
        "validation" = {
            "metre" = metreSummary,
            "kg" = kgSummary
        },
        "can_save" = true,
        "requires_business_rule_decision" = arrayLen(warnings) gt 0
    }>
    <cfoutput>#serializeJSON(response)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success"=false,"message"=cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
