<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cfoutput>{"success":false,"message":"Yetkisiz erişim."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset locId       = isDefined("form.loc_id")            and isNumeric(form.loc_id)       ? val(form.loc_id)       : 0>
    <cfset deptId      = isDefined("form.department_id")     and isNumeric(form.department_id) ? val(form.department_id) : 0>
    <cfset locationId  = isDefined("form.location_id")       and isNumeric(form.location_id)   ? val(form.location_id)  : 0>
    <cfset locName     = isDefined("form.department_location")? left(trim(form.department_location), 500) : "">
    <cfset comment     = isDefined("form.comment")            ? left(trim(form.comment), 75)   : "">
    <cfset width       = isDefined("form.width")     and isNumeric(form.width)     ? val(form.width)     : 0>
    <cfset height      = isDefined("form.height")    and isNumeric(form.height)    ? val(form.height)    : 0>
    <cfset depth       = isDefined("form.depth")     and isNumeric(form.depth)     ? val(form.depth)     : 0>
    <cfset temperature = isDefined("form.temperature") and isNumeric(form.temperature) ? val(form.temperature) : 0>
    <cfset pressure    = isDefined("form.pressure")  and isNumeric(form.pressure)  ? val(form.pressure)  : 0>
    <cfset locType     = isDefined("form.location_type") and isNumeric(form.location_type) ? val(form.location_type) : 0>
    <cfset status      = isDefined("form.status")         and val(form.status)         eq 1>
    <cfset noSale      = isDefined("form.no_sale")        and val(form.no_sale)        eq 1>
    <cfset priority    = isDefined("form.priority")       and val(form.priority)       eq 1>
    <cfset delivery    = isDefined("form.delivery")       and val(form.delivery)       eq 1>
    <cfset isQuality   = isDefined("form.is_quality")     and val(form.is_quality)     eq 1>
    <cfset isScrap     = isDefined("form.is_scrap")       and val(form.is_scrap)       eq 1>
    <cfset isCostAction   = isDefined("form.is_cost_action")   and val(form.is_cost_action)   eq 1>
    <cfset isEndOfSeries  = isDefined("form.is_end_of_series") and val(form.is_end_of_series) eq 1>

    <cfif not len(locName)>
        <cfoutput>{"success":false,"message":"Lokasyon adı zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif deptId lte 0>
        <cfoutput>{"success":false,"message":"Departman seçilmemiş."}</cfoutput>
        <cfabort>
    </cfif>

    <cfif locId gt 0>
        <!--- Güncelle --->
        <cfquery datasource="boyahane">
            UPDATE stocks_location SET
                location_id          = <cfqueryparam value="#locationId#"  cfsqltype="cf_sql_integer">,
                department_location  = <cfqueryparam value="#locName#"     cfsqltype="cf_sql_varchar">,
                comment              = <cfqueryparam value="#comment#"     cfsqltype="cf_sql_varchar" null="#not len(comment)#">,
                width                = <cfqueryparam value="#width#"       cfsqltype="cf_sql_numeric">,
                height               = <cfqueryparam value="#height#"      cfsqltype="cf_sql_numeric">,
                depth                = <cfqueryparam value="#depth#"       cfsqltype="cf_sql_numeric">,
                temperature          = <cfqueryparam value="#temperature#" cfsqltype="cf_sql_numeric">,
                pressure             = <cfqueryparam value="#pressure#"    cfsqltype="cf_sql_numeric">,
                location_type        = <cfqueryparam value="#locType#"     cfsqltype="cf_sql_integer" null="#locType eq 0#">,
                status               = <cfqueryparam value="#status#"      cfsqltype="cf_sql_bit">,
                no_sale              = <cfqueryparam value="#noSale#"      cfsqltype="cf_sql_bit">,
                priority             = <cfqueryparam value="#priority#"    cfsqltype="cf_sql_bit">,
                delivery             = <cfqueryparam value="#delivery#"    cfsqltype="cf_sql_bit">,
                is_quality           = <cfqueryparam value="#isQuality#"   cfsqltype="cf_sql_bit">,
                is_scrap             = <cfqueryparam value="#isScrap#"     cfsqltype="cf_sql_bit">,
                is_cost_action       = <cfqueryparam value="#isCostAction#"   cfsqltype="cf_sql_bit">,
                is_end_of_series     = <cfqueryparam value="#isEndOfSeries#"  cfsqltype="cf_sql_bit">
            WHERE id = <cfqueryparam value="#locId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfoutput>{"success":true,"id":#locId#}</cfoutput>
    <cfelse>
        <!--- Yeni ekle --->
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO stocks_location (
                location_id, department_id, department_location, comment,
                width, height, depth, temperature, pressure, location_type,
                status, no_sale, priority, delivery,
                is_quality, is_scrap, is_cost_action, is_end_of_series
            ) VALUES (
                <cfqueryparam value="#locationId#"  cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#deptId#"      cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#locName#"     cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#comment#"     cfsqltype="cf_sql_varchar" null="#not len(comment)#">,
                <cfqueryparam value="#width#"       cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#height#"      cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#depth#"       cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#temperature#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#pressure#"    cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#locType#"     cfsqltype="cf_sql_integer" null="#locType eq 0#">,
                <cfqueryparam value="#status#"      cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#noSale#"      cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#priority#"    cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#delivery#"    cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#isQuality#"   cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#isScrap#"     cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#isCostAction#"   cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#isEndOfSeries#"  cfsqltype="cf_sql_bit">
            ) RETURNING id
        </cfquery>
        <cfoutput>{"success":true,"id":#ins.id#}</cfoutput>
    </cfif>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
