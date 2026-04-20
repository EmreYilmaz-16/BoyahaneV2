<cfprocessingdirective pageEncoding="utf-8">
<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <!--- Silme işlemi --->
    <cfif isDefined("form.action") and form.action eq "delete">
        <cfif not (isDefined("form.log_id") and isNumeric(form.log_id) and val(form.log_id) gt 0)>
            <cfoutput>{"success":false,"message":"Log ID zorunludur."}</cfoutput>
            <cfabort>
        </cfif>
        <cfquery datasource="boyahane">
            DELETE FROM it_service_logs
            WHERE log_id = <cfqueryparam value="#val(form.log_id)#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfoutput>{"success":true,"action":"delete"}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Zorunlu alanlar --->
    <cfif not (isDefined("form.asset_id") and isNumeric(form.asset_id) and val(form.asset_id) gt 0)>
        <cfoutput>{"success":false,"message":"Cihaz seçimi zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif not (isDefined("form.log_date") and isDate(form.log_date) and len(trim(form.log_date)))>
        <cfoutput>{"success":false,"message":"Tarih zorunludur."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Whitelist --->
    <cfset allowedTypes   = "REPAIR,SOFTWARE_UPDATE,FORMAT,COMPONENT_CHANGE,ANTIVIRUS,NETWORK_CONFIG,OTHER">
    <cfset allowedStatuses = "OPEN,IN_PROGRESS,COMPLETED,CANCELLED">

    <cfset logTypeVal = isDefined("form.log_type") ? UCase(trim(form.log_type)) : "REPAIR">
    <cfif not listFind(allowedTypes, logTypeVal)>  <cfset logTypeVal = "REPAIR"> </cfif>

    <cfset statusVal = isDefined("form.status") ? UCase(trim(form.status)) : "OPEN">
    <cfif not listFind(allowedStatuses, statusVal)> <cfset statusVal = "OPEN"> </cfif>

    <!--- Null bayrakları --->
    <cfset logIdNull       = not (isDefined("form.log_id")       and isNumeric(form.log_id)       and val(form.log_id)       gt 0)>
    <cfset costNull        = not (isDefined("form.service_cost") and isNumeric(form.service_cost))>

    <!--- Değerler --->
    <cfset assetId          = val(form.asset_id)>
    <cfset isWarranty       = isDefined("form.is_warranty") and (form.is_warranty eq "1" or form.is_warranty eq "true")>
    <cfset serviceCost      = costNull ? 0 : val(form.service_cost)>
    <cfset techName         = isDefined("form.technician_name")     ? left(trim(form.technician_name),    150) : "">
    <cfset componentChanged = isDefined("form.component_changed")   ? left(trim(form.component_changed),  200) : "">
    <cfset problemDesc      = isDefined("form.problem_description") ? trim(form.problem_description)           : "">
    <cfset resolutionNotes  = isDefined("form.resolution_notes")    ? trim(form.resolution_notes)              : "">

    <!--- Varlığın BT tipinde olduğunu doğrula --->
    <cfquery name="qCheck" datasource="boyahane">
        SELECT asset_id, asset_type FROM asset_master
        WHERE asset_id = <cfqueryparam value="#assetId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif qCheck.recordCount eq 0>
        <cfoutput>{"success":false,"message":"Varlık bulunamadı."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif qCheck.asset_type neq "IT">
        <cfoutput>{"success":false,"message":"Bu varlık BT tipinde değil."}</cfoutput>
        <cfabort>
    </cfif>

    <cfif logIdNull>
        <!--- INSERT --->
        <cfquery name="qInsert" datasource="boyahane">
            INSERT INTO it_service_logs (
                asset_id, log_date, log_type,
                problem_description, resolution_notes, component_changed,
                technician_name, is_warranty, service_cost, status, record_date
            ) VALUES (
                <cfqueryparam value="#assetId#"       cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#form.log_date#" cfsqltype="cf_sql_date">,
                <cfqueryparam value="#logTypeVal#"    cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#problemDesc#"      cfsqltype="cf_sql_longvarchar" null="#not len(problemDesc)#">,
                <cfqueryparam value="#resolutionNotes#"  cfsqltype="cf_sql_longvarchar" null="#not len(resolutionNotes)#">,
                <cfqueryparam value="#componentChanged#" cfsqltype="cf_sql_varchar"     null="#not len(componentChanged)#">,
                <cfqueryparam value="#techName#"         cfsqltype="cf_sql_varchar"     null="#not len(techName)#">,
                <cfqueryparam value="#isWarranty#"    cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#serviceCost#"   cfsqltype="cf_sql_decimal" scale="2">,
                <cfqueryparam value="#statusVal#"     cfsqltype="cf_sql_varchar">,
                CURRENT_TIMESTAMP
            )
            RETURNING log_id
        </cfquery>
        <cfoutput>{"success":true,"log_id":#qInsert.log_id#,"action":"insert"}</cfoutput>
    <cfelse>
        <!--- UPDATE --->
        <cfset logId = val(form.log_id)>
        <cfquery datasource="boyahane">
            UPDATE it_service_logs SET
                asset_id            = <cfqueryparam value="#assetId#"       cfsqltype="cf_sql_integer">,
                log_date            = <cfqueryparam value="#form.log_date#" cfsqltype="cf_sql_date">,
                log_type            = <cfqueryparam value="#logTypeVal#"    cfsqltype="cf_sql_varchar">,
                problem_description = <cfqueryparam value="#problemDesc#"      cfsqltype="cf_sql_longvarchar" null="#not len(problemDesc)#">,
                resolution_notes    = <cfqueryparam value="#resolutionNotes#"  cfsqltype="cf_sql_longvarchar" null="#not len(resolutionNotes)#">,
                component_changed   = <cfqueryparam value="#componentChanged#" cfsqltype="cf_sql_varchar"     null="#not len(componentChanged)#">,
                technician_name     = <cfqueryparam value="#techName#"         cfsqltype="cf_sql_varchar"     null="#not len(techName)#">,
                is_warranty         = <cfqueryparam value="#isWarranty#"    cfsqltype="cf_sql_bit">,
                service_cost        = <cfqueryparam value="#serviceCost#"   cfsqltype="cf_sql_decimal" scale="2">,
                status              = <cfqueryparam value="#statusVal#"     cfsqltype="cf_sql_varchar">
            WHERE log_id = <cfqueryparam value="#logId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfoutput>{"success":true,"log_id":#logId#,"action":"update"}</cfoutput>
    </cfif>

<cfcatch type="any">
    <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
</cfcatch>
</cftry>
