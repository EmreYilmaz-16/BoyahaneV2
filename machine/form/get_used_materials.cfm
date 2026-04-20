<cfprocessingdirective pageEncoding="utf-8">
<cfheader name="Content-Type" value="application/json; charset=utf-8">
<cftry>
    <cfset sourceType = trim(url.source_type ?: "")>
    <cfset sourceId   = val(url.source_id   ?: 0)>

    <cfif NOT listFindNoCase("fault,maintenance", sourceType) OR sourceId LTE 0>
        <cfoutput>{"success":false,"message":"Geçersiz parametre."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery name="qMat" datasource="boyahane">
        SELECT material_id, product_id, product_name, product_code,
               quantity, unit, COALESCE(note,'') AS note,
               TO_CHAR(record_date, 'DD/MM/YYYY HH24:MI') AS record_date_fmt
        FROM machine_used_materials
        WHERE source_type = <cfqueryparam value="#sourceType#" cfsqltype="cf_sql_varchar">
          AND source_id   = <cfqueryparam value="#sourceId#"   cfsqltype="cf_sql_integer">
        ORDER BY record_date ASC
    </cfquery>

    <cfset arr = []>
    <cfloop query="qMat">
        <cfset arrayAppend(arr, {
            "material_id":   val(material_id),
            "product_id":    isNumeric(product_id) ? val(product_id) : 0,
            "product_name":  product_name ?: "",
            "product_code":  product_code ?: "",
            "quantity":      val(quantity),
            "unit":          unit ?: "",
            "note":          note ?: "",
            "record_date":   record_date_fmt ?: ""
        })>
    </cfloop>

    <cfoutput>{"success":true,"data":#serializeJSON(arr)#}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":"#JSStringFormat(cfcatch.message)#"}</cfoutput>
    </cfcatch>
</cftry>
