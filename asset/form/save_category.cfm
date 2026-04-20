<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
    <cfset catId    = isDefined("form.category_id") and isNumeric(form.category_id) ? val(form.category_id) : 0>
    <cfset catName  = isDefined("form.category_name") ? left(trim(form.category_name), 150) : "">
    <cfset catCode  = isDefined("form.category_code") ? left(trim(form.category_code), 50) : "">
    <cfset assetType= isDefined("form.asset_type") ? uCase(trim(form.asset_type)) : "">
    <cfset isActive = isDefined("form.is_active") and form.is_active eq "true">

    <cfif not len(catName)>
        <cfoutput>{"success":false,"message":"Kategori adı zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif not listFindNoCase("PHYSICAL,IT,VEHICLE", assetType)>
        <cfoutput>{"success":false,"message":"Geçerli bir varlık tipi seçin."}</cfoutput>
        <cfabort>
    </cfif>

    <cfset parentIdNull = not (isDefined("form.parent_id") and isNumeric(form.parent_id) and val(form.parent_id) gt 0)>
    <cfset parentId     = parentIdNull ? 0 : val(form.parent_id)>

    <!--- Prevent a category from being its own parent --->
    <cfif not parentIdNull and parentId eq catId and catId gt 0>
        <cfoutput>{"success":false,"message":"Kategori kendisinin üst kategorisi olamaz."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Auto-generate code if blank and this is an INSERT --->
    <cfif not len(catCode) and catId eq 0>
        <cfset catCode = ""><!--- let DB default null --->
    </cfif>
    <cfset catCodeNull = not len(catCode)>

    <cfif catId gt 0>
        <!--- UPDATE --->
        <cfquery datasource="boyahane">
            UPDATE asset_categories SET
                category_name = <cfqueryparam value="#catName#"    cfsqltype="cf_sql_varchar">,
                category_code = <cfqueryparam value="#catCode#"    cfsqltype="cf_sql_varchar" null="#catCodeNull#">,
                asset_type    = <cfqueryparam value="#assetType#"  cfsqltype="cf_sql_varchar">,
                parent_id     = <cfqueryparam value="#parentId#"   cfsqltype="cf_sql_integer" null="#parentIdNull#">,
                is_active     = <cfqueryparam value="#isActive#"   cfsqltype="cf_sql_bit">
            WHERE category_id = <cfqueryparam value="#catId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfoutput>{"success":true,"category_id":#catId#}</cfoutput>
    <cfelse>
        <!--- INSERT --->
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO asset_categories (category_name, category_code, asset_type, parent_id, is_active, record_emp, record_date)
            VALUES (
                <cfqueryparam value="#catName#"  cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#catCode#"  cfsqltype="cf_sql_varchar" null="#catCodeNull#">,
                <cfqueryparam value="#assetType#"cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#parentId#" cfsqltype="cf_sql_integer" null="#parentIdNull#">,
                <cfqueryparam value="#isActive#" cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
            ) RETURNING category_id
        </cfquery>
        <cfoutput>{"success":true,"category_id":#ins.category_id#}</cfoutput>
    </cfif>

    <cfcatch type="any">
        <!--- Unique constraint violation on category_code --->
        <cfif findNoCase("unique", cfcatch.message) or findNoCase("duplicate", cfcatch.message)>
            <cfoutput>{"success":false,"message":"Bu kategori kodu zaten kullanılıyor."}</cfoutput>
        <cfelse>
            <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
        </cfif>
    </cfcatch>
</cftry>
