<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "", "order_id": 0, "rolls": [] }>

<cftry>
    <cfif NOT isDefined("session.authenticated") OR NOT session.authenticated>
        <cfset response.message = "Yetkisiz erişim.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfparam name="form.order_id" default="0">
    <cfparam name="form.rolls" default="[]">

    <cfset orderId = isNumeric(form.order_id) AND val(form.order_id) gt 0 ? val(form.order_id) : 0>
    <cfif orderId eq 0>
        <cfset response.message = "Geçersiz sipariş ID.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset inputRolls = deserializeJSON(form.rolls)>
    <cfif NOT isArray(inputRolls) OR arrayLen(inputRolls) eq 0>
        <cfset response.message = "Kaydedilecek top satırı bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cftransaction action="begin">
        <cftry>
            <!--- Aynı order_id için eşzamanlı barkod üretimini sıraya al. --->
            <cfquery datasource="boyahane">
                SELECT pg_advisory_xact_lock(<cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">)
            </cfquery>

            <cfquery name="getMaxRollNo" datasource="boyahane">
                SELECT COALESCE(MAX(roll_no), 0) AS max_roll_no
                FROM ship_rolls
                WHERE order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset nextRollNo = val(getMaxRollNo.max_roll_no) + 1>

            <cfset savedRolls = []>

            <cfloop array="#inputRolls#" index="rollItem">
                <cfset rollNo = nextRollNo>
                <cfset rollNoText = rollNo lt 1000 ? right("000" & rollNo, 3) : toString(rollNo)>
                <cfset rollBarcode = "SR-" & orderId & "-" & rollNoText>
                <cfset rollWeight = structKeyExists(rollItem, "weight") AND isNumeric(rollItem.weight) ? val(rollItem.weight) : 0>
                <cfset rollMeter = structKeyExists(rollItem, "meter") AND isNumeric(rollItem.meter) ? val(rollItem.meter) : 0>
                <cfset rollNote = structKeyExists(rollItem, "note") ? trim(rollItem.note) : "">

                <!--- Kaydetmeden önce barkod çakışması kontrolü. Unique constraint ayrıca DB seviyesinde korur. --->
                <cfquery name="checkBarcode" datasource="boyahane">
                    SELECT ship_roll_id
                    FROM ship_rolls
                    WHERE roll_barcode = <cfqueryparam value="#rollBarcode#" cfsqltype="cf_sql_varchar">
                    LIMIT 1
                </cfquery>
                <cfif checkBarcode.recordCount>
                    <cfthrow type="ShipRolls.DuplicateBarcode" message="Barkod zaten mevcut: #rollBarcode#">
                </cfif>

                <cfquery name="insertRoll" datasource="boyahane">
                    INSERT INTO ship_rolls (
                        order_id, roll_no, roll_barcode, weight, meter, note, created_at
                    ) VALUES (
                        <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#rollNo#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#rollBarcode#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#rollWeight#" cfsqltype="cf_sql_numeric" null="#rollWeight eq 0#">,
                        <cfqueryparam value="#rollMeter#" cfsqltype="cf_sql_numeric" null="#rollMeter eq 0#">,
                        <cfqueryparam value="#rollNote#" cfsqltype="cf_sql_varchar" null="#NOT len(rollNote)#">,
                        NOW()
                    )
                    RETURNING ship_roll_id
                </cfquery>

                <cfset arrayAppend(savedRolls, {
                    "ship_roll_id": val(insertRoll.ship_roll_id),
                    "order_id": orderId,
                    "roll_no": rollNo,
                    "roll_no_text": rollNoText,
                    "roll_barcode": rollBarcode,
                    "weight": rollWeight,
                    "meter": rollMeter,
                    "note": rollNote
                })>
                <cfset nextRollNo = nextRollNo + 1>
            </cfloop>

            <cftransaction action="commit">

            <cfset response.success = true>
            <cfset response.message = "Top satırları kaydedildi.">
            <cfset response.order_id = orderId>
            <cfset response.rolls = savedRolls>

            <cfcatch type="any">
                <cftransaction action="rollback">
                <cfrethrow>
            </cfcatch>
        </cftry>
    </cftransaction>

    <cfcatch type="any">
        <cfset response.success = false>
        <cfset response.message = cfcatch.message>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
<cfabort>
