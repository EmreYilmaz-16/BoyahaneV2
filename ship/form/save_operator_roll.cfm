<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8" reset="true">
<cfsetting showdebugoutput="false">

<cfscript>
function n(value) { return isNumeric(value) ? val(value) : 0; }
</cfscript>

<cftry>
    <cfif NOT (structKeyExists(session, "authenticated") AND session.authenticated)>
        <cfoutput>#serializeJSON({"success"=false,"message"="Yetkisiz erişim."})#</cfoutput><cfabort>
    </cfif>

    <cfset orderId = isDefined("form.order_id") AND isNumeric(form.order_id) ? val(form.order_id) : 0>
    <cfset shipId = isDefined("form.ship_id") AND isNumeric(form.ship_id) ? val(form.ship_id) : 0>
    <cfset rollNo = isDefined("form.roll_no") AND isNumeric(form.roll_no) ? val(form.roll_no) : 0>
    <cfset metre = isDefined("form.metre") ? n(form.metre) : 0>
    <cfset kg = isDefined("form.kg") ? n(form.kg) : 0>
    <cfset refakatBarcode = isDefined("form.refakat_barcode") ? trim(form.refakat_barcode) : "">
    <cfset paketDurumu = isDefined("form.paket_durumu") AND len(trim(form.paket_durumu)) ? left(trim(form.paket_durumu), 50) : "paketlendi">
    <cfset expectedMetre = isDefined("form.parti_metre") ? n(form.parti_metre) : 0>
    <cfset expectedKg = isDefined("form.parti_kg") ? n(form.parti_kg) : 0>
    <cfset hedefTopAdedi = isDefined("form.hedef_top_adedi") AND isNumeric(form.hedef_top_adedi) ? val(form.hedef_top_adedi) : 0>

    <cfif orderId lte 0><cfoutput>#serializeJSON({"success"=false,"message"="order_id gerekli."})#</cfoutput><cfabort></cfif>
    <cfif rollNo lte 0><cfoutput>#serializeJSON({"success"=false,"message"="Top no gerekli."})#</cfoutput><cfabort></cfif>
    <cfif metre lt 0 OR kg lt 0><cfoutput>#serializeJSON({"success"=false,"message"="Metre/Kg negatif olamaz."})#</cfoutput><cfabort></cfif>
    <cfif metre eq 0 AND kg eq 0><cfoutput>#serializeJSON({"success"=false,"message"="Metre veya kg bilgisinden en az biri girilmelidir."})#</cfoutput><cfabort></cfif>

    <cfquery name="getParti" datasource="boyahane">
        SELECT order_id, order_number, ref_ship_id
        FROM orders
        WHERE order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getParti.recordCount><cfoutput>#serializeJSON({"success"=false,"message"="Parti bulunamadı."})#</cfoutput><cfabort></cfif>
    <cfif shipId lte 0 AND isNumeric(getParti.ref_ship_id)><cfset shipId = val(getParti.ref_ship_id)></cfif>
    <cfif NOT len(refakatBarcode)><cfset refakatBarcode = getParti.order_number ?: ""></cfif>

    <cftransaction>
        <cfquery name="getPlan" datasource="boyahane">
            SELECT plan_id
            FROM ship_roll_plan
            WHERE order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
              AND sarim_tipi = 'topa_top'
            ORDER BY plan_id DESC
            LIMIT 1
        </cfquery>
        <cfif getPlan.recordCount>
            <cfset planId = val(getPlan.plan_id)>
        <cfelse>
            <cfquery name="insertPlan" datasource="boyahane">
                INSERT INTO ship_roll_plan (
                    order_id, ship_id, refakat_barcode, sarim_tipi, hedef_metre, hedef_kg,
                    hedef_top_adedi, tolerans_metre, tolerans_kg, record_emp, record_date
                ) VALUES (
                    <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer" null="#shipId lte 0#">,
                    <cfqueryparam value="#refakatBarcode#" cfsqltype="cf_sql_varchar">,
                    'topa_top',
                    <cfqueryparam value="#expectedMetre#" cfsqltype="cf_sql_numeric">,
                    <cfqueryparam value="#expectedKg#" cfsqltype="cf_sql_numeric">,
                    <cfqueryparam value="#hedefTopAdedi#" cfsqltype="cf_sql_integer" null="#hedefTopAdedi lte 0#">,
                    0,
                    0,
                    <cfqueryparam value="#structKeyExists(session, 'employee_id') ? val(session.employee_id) : 0#" cfsqltype="cf_sql_integer" null="#NOT structKeyExists(session, 'employee_id')#">,
                    CURRENT_TIMESTAMP
                )
                RETURNING plan_id
            </cfquery>
            <cfset planId = val(insertPlan.plan_id)>
        </cfif>

        <cfquery name="checkRoll" datasource="boyahane">
            SELECT roll_id
            FROM ship_roll
            WHERE order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
              AND roll_no = <cfqueryparam value="#rollNo#" cfsqltype="cf_sql_integer">
            LIMIT 1
        </cfquery>
        <cfif checkRoll.recordCount>
            <cfthrow message="Bu parti için top no zaten kayıtlı: #rollNo#">
        </cfif>

        <cfset barcode = "SR-" & orderId & "-" & numberFormat(rollNo, "000")>
        <cfquery name="insRoll" datasource="boyahane">
            INSERT INTO ship_roll (
                plan_id, order_id, ship_id, roll_no, roll_barcode, metre, kg,
                paket_durumu, etiket_print_count, record_emp, record_date
            ) VALUES (
                <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer" null="#shipId lte 0#">,
                <cfqueryparam value="#rollNo#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#barcode#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#metre#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#kg#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#paketDurumu#" cfsqltype="cf_sql_varchar">,
                0,
                <cfqueryparam value="#structKeyExists(session, 'employee_id') ? val(session.employee_id) : 0#" cfsqltype="cf_sql_integer" null="#NOT structKeyExists(session, 'employee_id')#">,
                CURRENT_TIMESTAMP
            )
            RETURNING roll_id
        </cfquery>
    </cftransaction>

    <cfset rollId = val(insRoll.roll_id)>
    <cfoutput>#serializeJSON({
        "success"=true,
        "message"="Top kaydedildi. Etiket ekranına yönlendiriliyor.",
        "plan_id"=planId,
        "roll_id"=rollId,
        "roll_barcode"=barcode,
        "label_url"="/ship/display/ship_roll_label.cfm?roll_id=#rollId#"
    })#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success"=false,"message"=cfcatch.message,"detail"=cfcatch.detail})#</cfoutput>
    </cfcatch>
</cftry>
