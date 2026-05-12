<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <!--- tablo tipi: 'sarim' veya 'ambalaj' --->
    <cfparam name="form.table_type"  default="">
    <cfparam name="form.row_id"      default="0">
    <cfparam name="form.adi"         default="">
    <cfparam name="form.sort_order"  default="0">
    <cfparam name="form.is_active"   default="1">
    <cfparam name="form.is_default"  default="0">

    <cfset tableType = lCase(trim(form.table_type))>
    <cfset rowId     = isNumeric(form.row_id) AND val(form.row_id) gt 0 ? val(form.row_id) : 0>
    <cfset adi       = trim(form.adi)>
    <cfset sortOrder = isNumeric(form.sort_order) ? val(form.sort_order) : 0>
    <cfset isActive  = (form.is_active  eq "1" OR form.is_active  eq "true") ? true : false>
    <cfset isDefault = (form.is_default eq "1" OR form.is_default eq "true") ? true : false>

    <cfif NOT listFind("sarim,ambalaj", tableType)>
        <cfset response.message = "Geçersiz tablo tipi.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif NOT len(adi)>
        <cfset response.message = "Ad alanı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Tablo ve kolon adlarını belirle --->
    <cfif tableType eq "sarim">
        <cfset tableName  = "setup_sarim_sekli">
        <cfset idColumn   = "sarim_sekli_id">
        <cfset nameColumn = "sarim_sekli_adi">
    <cfelse>
        <cfset tableName  = "setup_ambalaj">
        <cfset idColumn   = "ambalaj_id">
        <cfset nameColumn = "ambalaj_adi">
    </cfif>

    <!--- Varsayılan seçildiyse diğerlerini sıfırla (aynı tablo içinde) --->
    <cfif isDefault>
        <cfquery datasource="boyahane">
            UPDATE #tableName# SET is_default = false
            <cfif rowId gt 0>
                WHERE #idColumn# <> <cfqueryparam value="#rowId#" cfsqltype="cf_sql_integer">
            </cfif>
        </cfquery>
    </cfif>

    <cfif rowId gt 0>
        <!--- UPDATE --->
        <cfquery datasource="boyahane">
            UPDATE #tableName# SET
                #nameColumn# = <cfqueryparam value="#adi#" cfsqltype="cf_sql_varchar">,
                sort_order   = <cfqueryparam value="#sortOrder#" cfsqltype="cf_sql_smallint">,
                is_active    = <cfqueryparam value="#isActive#"  cfsqltype="cf_sql_boolean">,
                is_default   = <cfqueryparam value="#isDefault#" cfsqltype="cf_sql_boolean">
            WHERE #idColumn# = <cfqueryparam value="#rowId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset response = { "success": true, "row_id": rowId, "mode": "updated" }>
    <cfelse>
        <!--- INSERT --->
        <cfquery name="ins" datasource="boyahane">
            INSERT INTO #tableName# (#nameColumn#, sort_order, is_active, is_default)
            VALUES (
                <cfqueryparam value="#adi#"       cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#sortOrder#" cfsqltype="cf_sql_smallint">,
                <cfqueryparam value="#isActive#"  cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#isDefault#" cfsqltype="cf_sql_boolean">
            )
            RETURNING #idColumn# AS new_id
        </cfquery>
        <cfset response = { "success": true, "row_id": val(ins.new_id), "mode": "added" }>
    </cfif>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
