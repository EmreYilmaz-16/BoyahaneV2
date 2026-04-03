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
    <cfparam name="form.exit_dep_id"       default="0">
    <cfparam name="form.exit_loc_id"       default="0">
    <cfparam name="form.enter_dep_id"      default="0">
    <cfparam name="form.enter_loc_id"      default="0">
    <cfparam name="form.production_dep_id" default="0">
    <cfparam name="form.production_loc_id" default="0">

    <cfset stId    = isNumeric(form.station_id) ? val(form.station_id) : 0>
    <cfset stName  = trim(form.station_name)>
    <cfset isActive= (form.active eq "true" OR form.active eq "1")>
    <cfset deptId  = isNumeric(form.department) AND val(form.department) gt 0 ? val(form.department) : javaCast("null","")>
    
    <cfset cap     = isNumeric(form.capacity) ? val(form.capacity) : 0>
    <cfset cost    = isNumeric(form.cost)     ? val(form.cost)     : 0>
    <cfset empNum  = isNumeric(form.employee_number) ? val(form.employee_number) : 0>
    <cfset upSt    = isNumeric(form.up_station) AND val(form.up_station) gt 0 ? val(form.up_station) : javaCast("null","")>
    <cfset exitDepId  = isNumeric(form.exit_dep_id)       AND val(form.exit_dep_id)       gt 0 ? val(form.exit_dep_id)       : javaCast("null","")>
    <cfset exitLocId  = isNumeric(form.exit_loc_id)       AND val(form.exit_loc_id)       gt 0 ? val(form.exit_loc_id)       : javaCast("null","")>
    <cfset enterDepId = isNumeric(form.enter_dep_id)      AND val(form.enter_dep_id)      gt 0 ? val(form.enter_dep_id)      : javaCast("null","")>
    <cfset enterLocId = isNumeric(form.enter_loc_id)      AND val(form.enter_loc_id)      gt 0 ? val(form.enter_loc_id)      : javaCast("null","")>
    <cfset prodDepId  = isNumeric(form.production_dep_id) AND val(form.production_dep_id) gt 0 ? val(form.production_dep_id) : javaCast("null","")>
    <cfset prodLocId  = isNumeric(form.production_loc_id) AND val(form.production_loc_id) gt 0 ? val(form.production_loc_id) : javaCast("null","")>
<cfoutput>
   <!--- Debug output --->
   <!----
    debug: 
   <table border="1" cellpadding="5" cellspacing="0">
    <tr>
        <td></td>
        <td>station_id</td><td>station_name</td><td>active</td><td>department</td><td>capacity</td><td>cost</td><td>cost_money</td><td>employee_number</td><td>up_station</td><td>comment</td><td>exit_dep_id</td><td>exit_loc_id</td><td>enter_dep_id</td><td>enter_loc_id</td><td>production_dep_id</td><td>production_loc_id</td>
        
    </tr>
    <tr>
        <td>values:</td>
        <td>#stId#</td><td>#stName#</td><td>#isActive#</td><td>#deptId#</td><td>#cap#</td><td>#cost#</td><td>#trim(form.cost_money)#</td><td>#empNum#</td><td>#upSt#</td><td>#trim(form.comment)#</td><td>#exitDepId#</td><td>#exitLocId#</td><td>#enterDepId#</td><td>#enterLocId#</td><td>#prodDepId#</td><td>#prodLocId#</td>
    </tr>
   </table>
    station_id: #stId#,
    station_name: #stName#,
    active: #isActive#,
    department: #deptId#,
    capacity: #cap#,
    cost: #cost#,
    cost_money: #trim(form.cost_money)#,
    employee_number: #empNum#,
    up_station: #upSt#,
    comment: #trim(form.comment)#,
    exit_dep_id: #exitDepId#,
    exit_loc_id: #exitLocId#,
    enter_dep_id: #enterDepId#,
    enter_loc_id: #enterLocId#,
    production_dep_id: #prodDepId#,
    production_loc_id: #prodLocId#

</cfoutput>

---->

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
                
                employee_number   = <cfqueryparam value="#empNum#"                   cfsqltype="cf_sql_integer">,
                up_station        = <cfqueryparam value="#isNull(upSt)?'':upSt#"     cfsqltype="cf_sql_integer" null="#isNull(upSt)#">,
                comment           = <cfqueryparam value="#trim(form.comment)#"       cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.comment))#">,
                exit_dep_id       = <cfqueryparam value="#isNull(exitDepId)?'':exitDepId#"   cfsqltype="cf_sql_integer" null="#isNull(exitDepId)#">,
                exit_loc_id       = <cfqueryparam value="#isNull(exitLocId)?'':exitLocId#"   cfsqltype="cf_sql_integer" null="#isNull(exitLocId)#">,
                enter_dep_id      = <cfqueryparam value="#isNull(enterDepId)?'':enterDepId#" cfsqltype="cf_sql_integer" null="#isNull(enterDepId)#">,
                enter_loc_id      = <cfqueryparam value="#isNull(enterLocId)?'':enterLocId#" cfsqltype="cf_sql_integer" null="#isNull(enterLocId)#">,
                production_dep_id = <cfqueryparam value="#isNull(prodDepId)?'':prodDepId#"   cfsqltype="cf_sql_integer" null="#isNull(prodDepId)#">,
                production_loc_id = <cfqueryparam value="#isNull(prodLocId)?'':prodLocId#"   cfsqltype="cf_sql_integer" null="#isNull(prodLocId)#">
            WHERE station_id = <cfqueryparam value="#stId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset response = { "success": true, "station_id": stId, "mode": "updated" }>
    <cfelse>
        <!--- INSERT --->
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO workstations
                (station_name, department, active, capacity, cost, cost_money,
                  employee_number, up_station, comment,
                 exit_dep_id, exit_loc_id, enter_dep_id, enter_loc_id,
                 production_dep_id, production_loc_id, record_date)
            VALUES (
                <cfqueryparam value="#stName#"                   cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#isNull(deptId)?'':deptId#" cfsqltype="cf_sql_integer" null="#isNull(deptId)#">,
                <cfqueryparam value="#isActive#"                 cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#cap#"                      cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#cost#"                     cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#trim(form.cost_money)#"    cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.cost_money))#">,
                <cfqueryparam value="#empNum#"                   cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#isNull(upSt)?'':upSt#"     cfsqltype="cf_sql_integer" null="#isNull(upSt)#">,
                <cfqueryparam value="#trim(form.comment)#"       cfsqltype="cf_sql_varchar" null="#NOT len(trim(form.comment))#">,
                <cfqueryparam value="#isNull(exitDepId)?'':exitDepId#"   cfsqltype="cf_sql_integer" null="#isNull(exitDepId)#">,
                <cfqueryparam value="#isNull(exitLocId)?'':exitLocId#"   cfsqltype="cf_sql_integer" null="#isNull(exitLocId)#">,
                <cfqueryparam value="#isNull(enterDepId)?'':enterDepId#" cfsqltype="cf_sql_integer" null="#isNull(enterDepId)#">,
                <cfqueryparam value="#isNull(enterLocId)?'':enterLocId#" cfsqltype="cf_sql_integer" null="#isNull(enterLocId)#">,
                <cfqueryparam value="#isNull(prodDepId)?'':prodDepId#"   cfsqltype="cf_sql_integer" null="#isNull(prodDepId)#">,
                <cfqueryparam value="#isNull(prodLocId)?'':prodLocId#"   cfsqltype="cf_sql_integer" null="#isNull(prodLocId)#">,
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