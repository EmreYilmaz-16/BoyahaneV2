<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>
<cftry>
    <cfparam name="form.qc_inspection_id" default="0">
    <cfparam name="form.inspection_no"    default="">
    <cfparam name="form.inspection_type"  default="1">
    <cfparam name="form.ship_id"          default="0">
    <cfparam name="form.p_order_id"       default="0">
    <cfparam name="form.product_id"        default="">
    <cfparam name="form.qc_plan_id"       default="">
    <cfparam name="form.lot_no"           default="">
    <cfparam name="form.quantity"         default="0">
    <cfparam name="form.sample_quantity"  default="0">
    <cfparam name="form.inspection_date"  default="">
    <cfparam name="form.inspector_name"   default="">
    <cfparam name="form.result"           default="1">
    <cfparam name="form.notes"            default="">
    <cfparam name="form.results"          default="[]">
    <cfparam name="form.defects"          default="[]">

    <cfset inspId   = isNumeric(form.qc_inspection_id) ? val(form.qc_inspection_id) : 0>
    <cfset inspType = isNumeric(form.inspection_type)  ? val(form.inspection_type)  : 1>
    <cfset shipId   = (len(trim(form.ship_id))    AND isNumeric(form.ship_id)    AND val(form.ship_id)    gt 0) ? val(form.ship_id)    : javaCast("null","")>
    <cfset pOrdId   = (len(trim(form.p_order_id)) AND isNumeric(form.p_order_id) AND val(form.p_order_id) gt 0) ? val(form.p_order_id) : javaCast("null","")>
    <cfset planId   = (len(trim(form.qc_plan_id)) AND isNumeric(form.qc_plan_id) AND val(form.qc_plan_id) gt 0) ? val(form.qc_plan_id) : javaCast("null","")>
    <cfset productId = (len(trim(form.product_id)) AND isNumeric(form.product_id) AND val(form.product_id) gt 0) ? val(form.product_id) : javaCast("null","")>
    <cfset lotNo    = trim(form.lot_no)>
    <cfset qty      = isNumeric(form.quantity)        ? val(form.quantity)        : 0>
    <cfset sampleQty= isNumeric(form.sample_quantity) ? val(form.sample_quantity) : 0>
    <cfset insDate  = (len(trim(form.inspection_date)) AND isDate(Replace(form.inspection_date,'T',' ','all')))
                       ? createODBCDateTime(parseDateTime(Replace(form.inspection_date,'T',' ','all')))
                       : createODBCDateTime(now())>
    <cfset inspector= trim(form.inspector_name)>
    <cfset result   = isNumeric(form.result) ? val(form.result) : 1>
    <cfset notes    = trim(form.notes)>

    <!--- Muayene no otomatik üret --->
    <cfset inspNo = trim(form.inspection_no)>
    <cfif NOT len(inspNo)>
        <cfset typePrefix = inspType eq 1 ? "GK" : (inspType eq 2 ? "OK" : "FK")>
        <cfset inspNo = typePrefix & "-" & dateFormat(now(),"yyyymmdd") & "-" & right("0000" & randRange(1,9999),4)>
    </cfif>

    <cfif inspId gt 0>
        <!--- Güncelle --->
        <cfquery datasource="boyahane">
            UPDATE qc_inspections SET
                inspection_no   = <cfqueryparam value="#inspNo#"     cfsqltype="cf_sql_varchar">,
                inspection_type = <cfqueryparam value="#inspType#"   cfsqltype="cf_sql_smallint">,
                ship_id         = <cfqueryparam value="#isNull(shipId)?'':shipId#"   cfsqltype="cf_sql_integer" null="#isNull(shipId)#">,
                p_order_id      = <cfqueryparam value="#isNull(pOrdId)?'':pOrdId#"  cfsqltype="cf_sql_integer" null="#isNull(pOrdId)#">,
                product_id      = <cfqueryparam value="#isNull(productId)?'':productId#" cfsqltype="cf_sql_integer" null="#isNull(productId)#">,
                qc_plan_id      = <cfqueryparam value="#isNull(planId)?'':planId#"  cfsqltype="cf_sql_integer" null="#isNull(planId)#">,
                lot_no          = <cfqueryparam value="#lotNo#"       cfsqltype="cf_sql_varchar"  null="#NOT len(lotNo)#">,
                quantity        = <cfqueryparam value="#qty#"         cfsqltype="cf_sql_numeric">,
                sample_quantity = <cfqueryparam value="#sampleQty#"   cfsqltype="cf_sql_numeric">,
                inspection_date = <cfqueryparam value="#insDate#"     cfsqltype="cf_sql_timestamp">,
                inspector_name  = <cfqueryparam value="#inspector#"   cfsqltype="cf_sql_varchar"  null="#NOT len(inspector)#">,
                result          = <cfqueryparam value="#result#"      cfsqltype="cf_sql_smallint">,
                notes           = <cfqueryparam value="#notes#"       cfsqltype="cf_sql_varchar"  null="#NOT len(notes)#">,
                record_ip       = <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
            WHERE qc_inspection_id = <cfqueryparam value="#inspId#"  cfsqltype="cf_sql_integer">
        </cfquery>
        <!--- Eski satırları sil --->
        <cfquery datasource="boyahane">
            DELETE FROM qc_inspection_results WHERE qc_inspection_id = <cfqueryparam value="#inspId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfquery datasource="boyahane">
            DELETE FROM qc_inspection_defects WHERE qc_inspection_id = <cfqueryparam value="#inspId#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <!--- Yeni kayıt --->
        <cfquery name="insInsp" datasource="boyahane">
            INSERT INTO qc_inspections (
                inspection_no, inspection_type, ship_id, p_order_id, product_id, qc_plan_id,
                lot_no, quantity, sample_quantity, inspection_date,
                inspector_name, result, notes, is_active,
                record_date, record_ip
            ) VALUES (
                <cfqueryparam value="#inspNo#"     cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#inspType#"   cfsqltype="cf_sql_smallint">,
                <cfqueryparam value="#isNull(shipId)?'':shipId#"   cfsqltype="cf_sql_integer" null="#isNull(shipId)#">,
                <cfqueryparam value="#isNull(pOrdId)?'':pOrdId#"  cfsqltype="cf_sql_integer" null="#isNull(pOrdId)#">,
                <cfqueryparam value="#isNull(productId)?'':productId#" cfsqltype="cf_sql_integer" null="#isNull(productId)#">,
                <cfqueryparam value="#isNull(planId)?'':planId#"  cfsqltype="cf_sql_integer" null="#isNull(planId)#">,
                <cfqueryparam value="#lotNo#"       cfsqltype="cf_sql_varchar"  null="#NOT len(lotNo)#">,
                <cfqueryparam value="#qty#"         cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#sampleQty#"   cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#insDate#"     cfsqltype="cf_sql_timestamp">,
                <cfqueryparam value="#inspector#"   cfsqltype="cf_sql_varchar"  null="#NOT len(inspector)#">,
                <cfqueryparam value="#result#"      cfsqltype="cf_sql_smallint">,
                <cfqueryparam value="#notes#"       cfsqltype="cf_sql_varchar"  null="#NOT len(notes)#">,
                true,
                CURRENT_TIMESTAMP,
                <cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">
            ) RETURNING qc_inspection_id
        </cfquery>
        <cfset inspId = val(insInsp.qc_inspection_id)>
    </cfif>

    <!--- Ölçüm Sonuçları --->
    <cfset resultsArr = []>
    <cftry><cfset resultsArr = deserializeJSON(form.results)><cfcatch><cfset resultsArr = []></cfcatch></cftry>

    <!--- Zorunlu parametre kontrolü (plan seçilmişse) --->
    <cfif NOT isNull(planId)>
        <cfquery name="qRequiredParams" datasource="boyahane">
            SELECT pi.qc_param_id, p.param_name, p.param_code, p.param_type
            FROM qc_plan_items pi
            JOIN qc_parameters p ON pi.qc_param_id = p.qc_param_id
            WHERE pi.qc_plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
              AND pi.is_required = true
              AND p.is_active = true
        </cfquery>
        <cfset missingList = []>
        <cfloop query="qRequiredParams">
            <!--- Bu parametre sonuçlar içinde dolu gelmiş mi? --->
            <cfset found = false>
            <cfif isArray(resultsArr)>
                <cfloop array="#resultsArr#" index="r">
                    <cfif isNumeric(r.qc_param_id ?: '') AND val(r.qc_param_id) EQ val(qRequiredParams.qc_param_id)>
                        <cfset isNumericParam = (val(qRequiredParams.param_type) EQ 1)>
                        <cfif isNumericParam>
                            <cfset filled = (structKeyExists(r,'measured_value') AND len(trim(r.measured_value ?: '')) AND isNumeric(r.measured_value))>
                        <cfelse>
                            <cfset filled = (structKeyExists(r,'text_result') AND len(trim(r.text_result ?: '')))>
                        </cfif>
                        <cfif filled><cfset found = true></cfif>
                        <cfbreak>
                    </cfif>
                </cfloop>
            </cfif>
            <cfif NOT found>
                <cfset arrayAppend(missingList, param_code & " - " & param_name)>
            </cfif>
        </cfloop>
        <cfif arrayLen(missingList) GT 0>
            <cfset response.message = "Zorunlu parametreler eksik: " & arrayToList(missingList, ", ")>
            <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
        </cfif>
    </cfif>

    <cfif isArray(resultsArr)>
        <cfloop array="#resultsArr#" index="r">
            <cfset rParamId = isNumeric(r.qc_param_id ?: '') ? val(r.qc_param_id) : 0>
            <cfif rParamId eq 0><cfcontinue></cfif>
            <cfset rMeas    = (structKeyExists(r,'measured_value') AND len(trim(r.measured_value)) AND isNumeric(r.measured_value))
                              ? val(r.measured_value) : javaCast("null","")>
            <cfset rText    = trim(r.text_result ?: "")>
            <cfset rPass    = (lcase(trim(r.is_pass ?: 'true')) eq "true")>
            <cfset rNotes   = trim(r.notes ?: "")>
            <cfquery datasource="boyahane">
                INSERT INTO qc_inspection_results (qc_inspection_id, qc_param_id, measured_value, text_result, is_pass, notes)
                VALUES (
                    <cfqueryparam value="#inspId#"                     cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#rParamId#"                   cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#isNull(rMeas)?'':rMeas#"     cfsqltype="cf_sql_numeric"  null="#isNull(rMeas)#">,
                    <cfqueryparam value="#rText#"                      cfsqltype="cf_sql_varchar"  null="#NOT len(rText)#">,
                    <cfqueryparam value="#rPass#"                      cfsqltype="cf_sql_boolean">,
                    <cfqueryparam value="#rNotes#"                     cfsqltype="cf_sql_varchar"  null="#NOT len(rNotes)#">
                )
            </cfquery>
        </cfloop>
    </cfif>

    <!--- Tespit Edilen Hatalar --->
    <cfset defectsArr = []>
    <cftry><cfset defectsArr = deserializeJSON(form.defects)><cfcatch><cfset defectsArr = []></cfcatch></cftry>
    <cfif isArray(defectsArr)>
        <cfloop array="#defectsArr#" index="d">
            <cfset dTypeId = isNumeric(d.defect_type_id ?: '') ? val(d.defect_type_id) : 0>
            <cfif dTypeId eq 0><cfcontinue></cfif>
            <cfset dCount  = isNumeric(d.defect_count ?: 1) ? val(d.defect_count) : 1>
            <cfset dLoc    = trim(d.defect_location ?: "")>
            <cfset dNotes  = trim(d.notes ?: "")>
            <cfquery datasource="boyahane">
                INSERT INTO qc_inspection_defects (qc_inspection_id, defect_type_id, defect_count, defect_location, notes)
                VALUES (
                    <cfqueryparam value="#inspId#"   cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#dTypeId#"  cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#dCount#"   cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#dLoc#"     cfsqltype="cf_sql_varchar" null="#NOT len(dLoc)#">,
                    <cfqueryparam value="#dNotes#"   cfsqltype="cf_sql_varchar" null="#NOT len(dNotes)#">
                )
            </cfquery>
        </cfloop>
    </cfif>

    <cfset response.success = true>
    <cfset response.qc_inspection_id = inspId>
    <cfcatch type="any"><cfset response.message = cfcatch.message></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
<cfabort>