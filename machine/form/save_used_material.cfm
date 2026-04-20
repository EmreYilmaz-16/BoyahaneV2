<cfprocessingdirective pageEncoding="utf-8">
<cfheader name="Content-Type" value="application/json; charset=utf-8">
<cftry>
    <cfset sourceType  = trim(form.source_type  ?: "")>
    <cfset sourceId    = val(form.source_id     ?: 0)>
    <cfset productId   = val(form.product_id    ?: 0)>
    <cfset productName = trim(form.product_name ?: "")>
    <cfset productCode = trim(form.product_code ?: "")>
    <cfset quantity    = val(form.quantity       ?: 1)>
    <cfset unit        = trim(form.unit          ?: "adet")>
    <cfset note        = trim(form.note          ?: "")>

    <!--- Validasyonlar --->
    <cfif NOT listFindNoCase("fault,maintenance", sourceType)>
        <cfoutput>{"success":false,"message":"Geçersiz kaynak tipi."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif sourceId LTE 0>
        <cfoutput>{"success":false,"message":"Geçersiz kayıt ID."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif NOT len(productName)>
        <cfoutput>{"success":false,"message":"Ürün adı zorunludur."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif quantity LTE 0>
        <cfoutput>{"success":false,"message":"Miktar sıfırdan büyük olmalıdır."}</cfoutput>
        <cfabort>
    </cfif>
    <cfif NOT listFindNoCase("adet,litre,kg,metre,kutu,paket,rulo,lt,gr,cm,mm", unit)>
        <cfset unit = "adet">
    </cfif>

    <cfquery name="qIns" datasource="boyahane">
        INSERT INTO machine_used_materials
            (source_type, source_id, product_id, product_name, product_code, quantity, unit, note, record_date)
        VALUES (
            <cfqueryparam value="#sourceType#"  cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#sourceId#"    cfsqltype="cf_sql_integer">,
            <cfif productId GT 0>
                <cfqueryparam value="#productId#" cfsqltype="cf_sql_integer">
            <cfelse>
                NULL
            </cfif>,
            <cfqueryparam value="#productName#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#productCode#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#quantity#"    cfsqltype="cf_sql_decimal">,
            <cfqueryparam value="#unit#"        cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#note#"        cfsqltype="cf_sql_varchar">,
            NOW()
        )
        RETURNING material_id
    </cfquery>
    <cfoutput>{"success":true,"message":"Malzeme eklendi.","material_id":#qIns.material_id#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":"#JSStringFormat(cfcatch.message)#"}</cfoutput>
    </cfcatch>
</cftry>
