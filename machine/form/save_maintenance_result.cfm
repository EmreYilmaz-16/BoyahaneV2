<cfprocessingdirective pageEncoding="utf-8">
<cfinclude template="../includes/status_codes.cfm">
<cfcontent type="application/json; charset=utf-8"><cfsetting showdebugoutput="false">
<cfset response = {"success":false,"message":""}>

<cftry>
    <cfset machineId      = isDefined("form.machine_id") and isNumeric(form.machine_id) ? val(form.machine_id) : 0>
    <cfset planId         = isDefined("form.plan_id") and isNumeric(form.plan_id) and val(form.plan_id) gt 0 ? val(form.plan_id) : javaCast("null","")>
    <cfset maintenanceType= left(trim(form.maintenance_type ?: "planned"), 30)>
    <cfset startRaw       = trim(form.maintenance_start ?: "")>
    <cfset endRaw         = trim(form.maintenance_end ?: "")>
    <cfset resultStatus   = lcase(left(trim(form.maintenance_result ?: "completed"), 30))>
    <cfset resultNote     = left(trim(form.result_note ?: ""), 2000)>

    <cfif NOT listFindNoCase("completed,partial,failed", resultStatus)>
        <cfset response.message = "Geçersiz bakım sonucu. İzinli değerler: completed, partial, failed.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif machineId lte 0>
        <cfset response.message = "Makine seçimi zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery name="qMachine" datasource="boyahane">
        SELECT machine_id, is_active
        FROM machine_machines
        WHERE machine_id = <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif qMachine.recordCount eq 0>
        <cfset response.message = "Seçilen makine bulunamadı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif NOT qMachine.is_active>
        <cfset response.message = "Pasif makine için bakım sonucu girilemez.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif NOT isNull(planId)>
        <cfquery name="qPlan" datasource="boyahane">
            SELECT plan_id
            FROM machine_maintenance_plans
            WHERE plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
                AND machine_id = <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfif qPlan.recordCount eq 0>
            <cfset response.message = "Seçilen bakım planı bu makineye ait değil veya bulunamadı.">
            <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
        </cfif>
    </cfif>

    <cfset startDate = (len(startRaw) AND isDate(startRaw)) ? createODBCDateTime(parseDateTime(replace(startRaw,'T',' ','all'))) : javaCast("null","")>
    <cfset endDate   = (len(endRaw)   AND isDate(endRaw))   ? createODBCDateTime(parseDateTime(replace(endRaw,'T',' ','all')))   : javaCast("null","")>

    <cfif NOT isNull(startDate) AND NOT isNull(endDate) AND dateCompare(endDate, startDate, "s") LT 0>
        <cfset response.message = "Bakım bitiş zamanı başlangıçtan önce olamaz.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfset machineStatusCode = STATUS_OK>
    <cfset machineStatusNote = "Bakım tamamlandı">
    <cfset machineHistoryNote = "Bakım sonucu girildi">
    <cfif NOT isNull(startDate) AND isNull(endDate)>
        <cfset machineStatusCode = STATUS_MAINTENANCE>
        <cfset machineStatusNote = "Bakımda">
        <cfset machineHistoryNote = "Bakım başlatıldı">
    <cfelseif NOT isNull(endDate)>
        <cfif resultStatus EQ "partial">
            <cfset machineStatusNote = "Bakım kısmi tamamlandı">
        <cfelseif resultStatus EQ "failed">
            <cfset machineStatusNote = "Bakım başarısız tamamlandı">
        </cfif>
    </cfif>

    <cfquery datasource="boyahane">
        INSERT INTO machine_maintenance_logs (
            machine_id, plan_id, maintenance_type, maintenance_start, maintenance_end,
            maintenance_result, result_note, performed_by, record_date, record_emp
        ) VALUES (
            <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#isNull(planId)?'':planId#" cfsqltype="cf_sql_integer" null="#isNull(planId)#">,
            <cfqueryparam value="#maintenanceType#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#isNull(startDate)?'':startDate#" cfsqltype="cf_sql_timestamp" null="#isNull(startDate)#">,
            <cfqueryparam value="#isNull(endDate)?'':endDate#" cfsqltype="cf_sql_timestamp" null="#isNull(endDate)#">,
            <cfqueryparam value="#resultStatus#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#resultNote#" cfsqltype="cf_sql_varchar" null="#NOT len(resultNote)#">,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">,
            CURRENT_TIMESTAMP,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
        )
    </cfquery>

    <cfset machineStatusCode = STATUS_OK>
    <cfset machineStatusNote = "Bakım tamamlandı">
    <cfset historyStatusNote = "Bakım sonucu girildi">

    <cfif resultStatus eq "partial">
        <cfset machineStatusCode = STATUS_MAINTENANCE>
        <cfset machineStatusNote = "Bakım kısmi tamamlandı; plan sonraki tarihi otomatik ileri alınmadı. Lütfen ayrı bir sonraki bakım tarihi seçin.">
        <cfset historyStatusNote = "Bakım kısmi tamamlandı">
    <cfelseif resultStatus eq "failed">
        <cfquery name="qOpenFaults" datasource="boyahane">
            SELECT COUNT(*) AS open_count
            FROM machine_faults
            WHERE machine_id = <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">
              AND fault_status IN ('open','in_progress')
        </cfquery>
        <cfset machineStatusCode = val(qOpenFaults.open_count) gt 0 ? STATUS_FAULT : STATUS_MAINTENANCE>
        <cfset machineStatusNote = machineStatusCode eq STATUS_FAULT ? "Bakım başarısız; aktif arıza mevcut" : "Bakım başarısız; makine bakımda bırakıldı">
        <cfset historyStatusNote = "Bakım başarısız">
    </cfif>

    <cfquery datasource="boyahane">
        UPDATE machine_machines
        SET current_status_code = <cfqueryparam value="#machineStatusCode#" cfsqltype="cf_sql_integer">,
            current_status_note = <cfqueryparam value="#machineStatusNote#" cfsqltype="cf_sql_varchar">,
            last_maintenance_date = CASE WHEN <cfqueryparam value="#isNull(endDate)?0:1#" cfsqltype="cf_sql_integer"> = 1 THEN CURRENT_TIMESTAMP ELSE last_maintenance_date END,
            update_date = CURRENT_TIMESTAMP
        WHERE machine_id = <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfquery datasource="boyahane">
        INSERT INTO machine_status_history (machine_id, status_code, status_note, source_type, source_id, record_emp)
        VALUES (
            <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#machineStatusCode#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#historyStatusNote#" cfsqltype="cf_sql_varchar">,
            'maintenance',
            NULL,
            <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
        )
    </cfquery>

    <cfif NOT isNull(planId) AND NOT isNull(endDate)>
        <cfquery datasource="boyahane">
            UPDATE machine_maintenance_plans
            SET last_done_date = CURRENT_TIMESTAMP,
                next_planned_date = CURRENT_TIMESTAMP + (period_days || ' day')::interval,
                update_date = CURRENT_TIMESTAMP,
                update_emp = <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer" null="#NOT isDefined('session.user.employee_id')#">
            WHERE plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
                AND machine_id = <cfqueryparam value="#machineId#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cfif>

    <cfset response = {"success":true}>
    <cfcatch type="any"><cfset response.message = "Bakım sonucu kaydedilirken bir hata oluştu."></cfcatch>
</cftry>
<cfoutput>#serializeJSON(response)#</cfoutput>
