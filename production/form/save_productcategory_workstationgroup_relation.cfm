<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.id" default="0">
    <cfparam name="form.product_catid" default="0">
    <cfparam name="form.workstation_id" default="0">

    <cfset relId = isNumeric(form.id) ? val(form.id) : 0>
    <cfset productCatId = isNumeric(form.product_catid) AND val(form.product_catid) gt 0 ? val(form.product_catid) : 0>
    <cfset workstationId = isNumeric(form.workstation_id) AND val(form.workstation_id) gt 0 ? val(form.workstation_id) : 0>

    <cfif productCatId eq 0>
        <cfset response.message = "Ürün kategorisi zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>
    <cfif workstationId eq 0>
        <cfset response.message = "İş istasyonu zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery name="chkDuplicate" datasource="boyahane">
        SELECT id
        FROM productcategory_workstationgroup_relation
        WHERE product_catid = <cfqueryparam value="#productCatId#" cfsqltype="cf_sql_integer">
          AND workstation_id = <cfqueryparam value="#workstationId#" cfsqltype="cf_sql_integer">
          AND id <> <cfqueryparam value="#relId#" cfsqltype="cf_sql_integer">
        LIMIT 1
    </cfquery>
    <cfif chkDuplicate.recordCount gt 0>
        <cfset response.message = "Bu kategori ve iş istasyonu eşleştirmesi zaten mevcut.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif relId gt 0>
        <cfquery datasource="boyahane">
            UPDATE productcategory_workstationgroup_relation
            SET product_catid = <cfqueryparam value="#productCatId#" cfsqltype="cf_sql_integer">,
                workstation_id = <cfqueryparam value="#workstationId#" cfsqltype="cf_sql_integer">
            WHERE id = <cfqueryparam value="#relId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset response = { "success": true, "id": relId, "mode": "updated" }>
    <cfelse>
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO productcategory_workstationgroup_relation
                (product_catid, workstation_id, record_date)
            VALUES (
                <cfqueryparam value="#productCatId#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#workstationId#" cfsqltype="cf_sql_integer">,
                CURRENT_TIMESTAMP
            )
            RETURNING id
        </cfquery>
        <cfset response = { "success": true, "id": val(ins.id), "mode": "added" }>
    </cfif>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
