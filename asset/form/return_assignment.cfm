<cfprocessingdirective pageEncoding="utf-8">
<cfsetting enablecfoutputonly="true" showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <!--- Zorunlu alanlar --->
    <cfif not (isDefined("form.assignment_id") and isNumeric(form.assignment_id) and val(form.assignment_id) gt 0)>
        <cfoutput>{"success":false,"message":"Zimmet ID zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif not (isDefined("form.returned_date") and isDate(form.returned_date) and len(trim(form.returned_date)))>
        <cfoutput>{"success":false,"message":"İade tarihi zorunludur."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Durum: RETURNED zorunlu, ancak return_condition kayıp/hasarlı ise durumu ona göre de set edebiliriz --->
    <cfset allowedConditions = "GOOD,DAMAGED,LOST">
    <cfset condVal = isDefined("form.return_condition") ? UCase(trim(form.return_condition)) : "GOOD">
    <cfif not listFind(allowedConditions, condVal)>
        <cfset condVal = "GOOD">
    </cfif>

    <!--- Kayıp ise assignment_status = LOST, hasarlı ise DAMAGED, iyi ise RETURNED --->
    <cfswitch expression="#condVal#">
        <cfcase value="LOST">    <cfset newStatus = "LOST"></cfcase>
        <cfcase value="DAMAGED"> <cfset newStatus = "DAMAGED"></cfcase>
        <cfdefaultcase>          <cfset newStatus = "RETURNED"></cfdefaultcase>
    </cfswitch>

    <cfset assignmentId = val(form.assignment_id)>
    <cfset returnNotes  = isDefined("form.return_notes") ? trim(form.return_notes) : "">

    <!--- Zimmeti kontrol et --->
    <cfquery name="qCheck" datasource="boyahane">
        SELECT assignment_id, assignment_status
        FROM asset_assignments
        WHERE assignment_id = <cfqueryparam value="#assignmentId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif qCheck.recordCount eq 0>
        <cfoutput>{"success":false,"message":"Zimmet kaydı bulunamadı."}</cfoutput>
        <cfabort>
    </cfif>

    <cfif qCheck.assignment_status eq "RETURNED">
        <cfoutput>{"success":false,"message":"Bu zimmet zaten iade edilmiş."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="qReturn" datasource="boyahane">
        UPDATE asset_assignments SET
            returned_date     = <cfqueryparam value="#form.returned_date#" cfsqltype="cf_sql_date">,
            assignment_status = <cfqueryparam value="#newStatus#" cfsqltype="cf_sql_varchar">,
            return_condition  = <cfqueryparam value="#condVal#" cfsqltype="cf_sql_varchar">,
            return_notes      = <cfqueryparam value="#returnNotes#" cfsqltype="cf_sql_longvarchar" null="#not len(returnNotes)#">
        WHERE assignment_id = <cfqueryparam value="#assignmentId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>{"success":true,"assignment_id":#assignmentId#,"new_status":"#newStatus#"}</cfoutput>

<cfcatch type="any">
    <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
</cfcatch>
</cftry>
