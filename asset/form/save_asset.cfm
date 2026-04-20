<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
    <cfset assetId = isDefined("form.asset_id") and isNumeric(form.asset_id) ? val(form.asset_id) : 0>
    <cfset assetName = isDefined("form.asset_name") ? left(trim(form.asset_name), 250) : "">
    <cfset assetType = isDefined("form.asset_type") ? uCase(trim(form.asset_type)) : "PHYSICAL">

    <cfif not len(assetName)>
        <cfoutput>{"success":false,"message":"Varlık adı zorunludur."}</cfoutput>
        <cfabort>
    </cfif>

    <cfif not listFindNoCase("PHYSICAL,IT,VEHICLE", assetType)>
        <cfoutput>{"success":false,"message":"Varlık tipi geçersiz."}</cfoutput>
        <cfabort>
    </cfif>

    <cfset categoryIdNull  = not (isDefined("form.category_id") and isNumeric(form.category_id) and val(form.category_id) gt 0)>
    <cfset categoryId      = categoryIdNull  ? 0 : val(form.category_id)>
    <cfset locationIdNull  = not (isDefined("form.location_id") and isNumeric(form.location_id) and val(form.location_id) gt 0)>
    <cfset locationId      = locationIdNull  ? 0 : val(form.location_id)>
    <cfset purchaseDateNull = not (isDefined("form.purchase_date") and isDate(form.purchase_date))>
    <cfset purchaseDate    = purchaseDateNull ? "" : createODBCDate(form.purchase_date)>
    <cfset acqCost = isDefined("form.acquisition_cost") and isNumeric(form.acquisition_cost) ? val(form.acquisition_cost) : 0>

    <cfif assetId gt 0>
        <cfquery datasource="boyahane">
            UPDATE asset_master SET
                asset_no = <cfqueryparam value="#left(trim(form.asset_no ?: ''), 50)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.asset_no ?: ''))#">,
                asset_name = <cfqueryparam value="#assetName#" cfsqltype="cf_sql_varchar">,
                asset_type = <cfqueryparam value="#assetType#" cfsqltype="cf_sql_varchar">,
                category_id = <cfqueryparam value="#categoryId#" cfsqltype="cf_sql_integer" null="#categoryIdNull#">,
                brand = <cfqueryparam value="#left(trim(form.brand ?: ''),100)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.brand ?: ''))#">,
                model = <cfqueryparam value="#left(trim(form.model ?: ''),100)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.model ?: ''))#">,
                serial_no = <cfqueryparam value="#left(trim(form.serial_no ?: ''),100)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.serial_no ?: ''))#">,
                purchase_date = <cfqueryparam value="#purchaseDate#" cfsqltype="cf_sql_date" null="#purchaseDateNull#">,
                acquisition_cost = <cfqueryparam value="#acqCost#" cfsqltype="cf_sql_numeric">,
                currency = <cfqueryparam value="#left(trim(form.currency ?: 'TRY'),10)#" cfsqltype="cf_sql_varchar">,
                location_id = <cfqueryparam value="#locationId#" cfsqltype="cf_sql_integer" null="#locationIdNull#">,
                asset_status = <cfqueryparam value="#left(trim(form.asset_status ?: 'ACTIVE'),20)#" cfsqltype="cf_sql_varchar">,
                detail = <cfqueryparam value="#trim(form.detail ?: '')#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.detail ?: ''))#">,
                update_emp = <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
                update_ip = <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">,
                update_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
            WHERE asset_id = <cfqueryparam value="#assetId#" cfsqltype="cf_sql_integer">
        </cfquery>
    <cfelse>
        <cfquery name="insAsset" datasource="boyahane">
            INSERT INTO asset_master (
                asset_no, asset_name, asset_type, category_id, brand, model, serial_no,
                purchase_date, acquisition_cost, currency, location_id, asset_status, detail,
                record_emp, record_ip, record_date
            ) VALUES (
                <cfqueryparam value="#left(trim(form.asset_no ?: ''), 50)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.asset_no ?: ''))#">,
                <cfqueryparam value="#assetName#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#assetType#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#categoryId#" cfsqltype="cf_sql_integer" null="#categoryIdNull#">,
                <cfqueryparam value="#left(trim(form.brand ?: ''),100)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.brand ?: ''))#">,
                <cfqueryparam value="#left(trim(form.model ?: ''),100)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.model ?: ''))#">,
                <cfqueryparam value="#left(trim(form.serial_no ?: ''),100)#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.serial_no ?: ''))#">,
                <cfqueryparam value="#purchaseDate#" cfsqltype="cf_sql_date" null="#purchaseDateNull#">,
                <cfqueryparam value="#acqCost#" cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#left(trim(form.currency ?: 'TRY'),10)#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#locationId#" cfsqltype="cf_sql_integer" null="#locationIdNull#">,
                <cfqueryparam value="#left(trim(form.asset_status ?: 'ACTIVE'),20)#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#trim(form.detail ?: '')#" cfsqltype="cf_sql_varchar" null="#not len(trim(form.detail ?: ''))#">,
                <cfqueryparam value="#session.user.employee_id ?: 0#" cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#cgi.remote_addr#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">
            ) RETURNING asset_id
        </cfquery>
        <cfset assetId = insAsset.asset_id>
    </cfif>

    <cfoutput>{"success":true,"asset_id":#assetId#,"redirect":"index.cfm?fuseaction=asset.add_asset&asset_id=#assetId#"}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
