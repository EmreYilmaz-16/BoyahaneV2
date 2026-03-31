<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.station_id"        default="0">
    <cfparam name="form.station_name"      default="">
    <cfparam name="form.department"        default="0">
    <cfparam name="form.active"            default="false">
    <cfparam name="form.capacity"          default="0">
    <cfparam name="form.cost"              default="0">
    <cfparam name="form.cost_money"        default="">
    <cfparam name="form.outsource_partner" default="0">
    <cfparam name="form.employee_number"   default="0">
    <cfparam name="form.up_station"        default="0">
    <cfparam name="form.comment"           default="">

    <cfset stId    = isNumeric(form.station_id) ? val(form.station_id) : 0>
    <cfset stName  = trim(form.station_name)>
    <cfset isActive= (form.active eq "true" OR form.active eq "1")>
    <cfset deptId  = isNumeric(form.department) AND val(form.department) gt 0 ? val(form.department) : javaCast("null","")>
    <cfset outId   = isNumeric(form.outsource_partner) AND val(form.outsource_partner) gt 0 ? val(form.outsource_partner) : javaCast("null","")>
    <cfset cap     = isNumeric(form.capacity) ? val(form.capacity) : 0>
    <cfset cost    = isNumeric(form.cost)     ? val(form.cost)     : 0>
    <cfset empNum  = isNumeric(form.employee_number) ? val(form.employee_number) : 0>
    <cfset upSt    = isNumeric(form.up_station) AND val(form.up_station) gt 0 ? val(form.up_station) : javaCast("null","")>

    <cfif NOT len(stName)>
        <cfset response.message = "İstasyon adı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <cfif stId gt 0>
        <!--- UPDATE --->
        <cfquery datasource="boyahane">
            UPDATE workstations SET
                station_name      = <cfqueryparam value="#stName#"                   cfsqltype="cf_sql_varchar">,
                department        = <cfqueryparam value="#isNull(deptId)?'':deptId#" cfsqltype="cf_sql_integer" null="#isNull(deptId)#">,
                active            = <cfqueryparam value="#isActive#"                 cfsqltype="cf_sql_bit">,
                capacity          = <cfqueryparam value="#cap#"                      cfsqltype="cf_sql_integer">,
                cost              = <cfqueryparam value="#cost#"                     cfsqltype="cf_sql_numeric">,
                cost_money        = <cfqueryparam value="#trim(form.cost_money)#"    cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.cost_money))#">,
                outsource_partner = <cfqueryparam value="#isNull(outId)?'':outId#"   cfsqltype="cf_sql_integer" null="#isNull(outId)#">,
                employee_number   = <cfqueryparam value="#empNum#"                   cfsqltype="cf_sql_integer">,
                up_station        = <cfqueryparam value="#isNull(upSt)?'':upSt#"     cfsqltype="cf_sql_integer" null="#isNull(upSt)#">,
                comment           = <cfqueryparam value="#trim(form.comment)#"       cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.comment))#">
            WHERE station_id = <cfqueryparam value="#stId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset response = { "success": true, "station_id": stId, "mode": "updated" }>
    <cfelse>
        <!--- INSERT --->
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO workstations
                (station_name, department, active, capacity, cost, cost_money,
                 outsource_partner, employee_number, up_station, comment, record_date)
            VALUES (
                <cfqueryparam value="#stName#"                   cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#isNull(deptId)?'':deptId#" cfsqltype="cf_sql_integer" null="#isNull(deptId)#">,
                <cfqueryparam value="#isActive#"                 cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#cap#"                      cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#cost#"                     cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#trim(form.cost_money)#"    cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.cost_money))#">,
                <cfqueryparam value="#isNull(outId)?'':outId#"   cfsqltype="cf_sql_integer" null="#isNull(outId)#">,
                <cfqueryparam value="#empNum#"                   cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#isNull(upSt)?'':upSt#"     cfsqltype="cf_sql_integer" null="#isNull(upSt)#">,
                <cfqueryparam value="#trim(form.comment)#"       cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.comment))#">,
                CURRENT_TIMESTAMP
            )
            RETURNING station_id
        </cfquery>
        <cfset response = { "success": true, "station_id": val(ins.station_id), "mode": "added" }>
    </cfif>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>