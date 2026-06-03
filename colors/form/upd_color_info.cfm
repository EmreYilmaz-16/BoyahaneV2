<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!--- Renk bilgilerini güncelle (sadece color_info + stocks) — product_tree'ye dokunmaz --->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.stock_id"       default="0">
    <cfparam name="form.color_code"     default="">
    <cfparam name="form.color_name"     default="">
    <cfparam name="form.kartela_no"     default="">
    <cfparam name="form.kartela_date"   default="">
    <cfparam name="form.renk_tonu"      default="">
    <cfparam name="form.boya_derecesi"  default="">
    <cfparam name="form.is_ready"       default="false">

    <cfset stockId     = isNumeric(form.stock_id) AND val(form.stock_id) gt 0 ? val(form.stock_id) : 0>
    <cfset colorCode   = trim(form.color_code)>
    <cfset colorName   = trim(form.color_name)>
    <cfset kartelaNo   = trim(form.kartela_no)>
    <cfset kartelaDate = (len(trim(form.kartela_date)) AND isDate(form.kartela_date))
                          ? createODBCDate(parseDateTime(form.kartela_date))
                          : javaCast("null","")>
    <cfset renkTonu    = isNumeric(form.renk_tonu) AND val(form.renk_tonu) gt 0 ? val(form.renk_tonu) : javaCast("null","")>
    <cfset boyaDer     = trim(form.boya_derecesi)>
    <cfset isReady     = (form.is_ready eq "true" OR form.is_ready eq "1")>

    <cfif stockId eq 0>
        <cfset response.message = "Geçersiz stok kaydı.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        UPDATE stocks SET
            property     = <cfqueryparam value="#colorCode#"  cfsqltype="cf_sql_varchar" null="#NOT len(colorCode)#">,
            stock_code_2 = <cfqueryparam value="#colorName#"  cfsqltype="cf_sql_varchar" null="#NOT len(colorName)#">,
            barcod       = <cfqueryparam value="#kartelaNo#"  cfsqltype="cf_sql_varchar" null="#NOT len(kartelaNo)#">,
            update_date  = CURRENT_TIMESTAMP
        WHERE stock_id = <cfqueryparam value="#stockId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfquery datasource="boyahane">
        UPDATE color_info SET
            color_code    = <cfqueryparam value="#colorCode#"                              cfsqltype="cf_sql_varchar"  null="#NOT len(colorCode)#">,
            color_name    = <cfqueryparam value="#colorName#"                              cfsqltype="cf_sql_varchar"  null="#NOT len(colorName)#">,
            kartela_no    = <cfqueryparam value="#kartelaNo#"                              cfsqltype="cf_sql_varchar"  null="#NOT len(kartelaNo)#">,
            kartela_date  = <cfqueryparam value="#isNull(kartelaDate)?'':kartelaDate#"     cfsqltype="cf_sql_date"     null="#isNull(kartelaDate)#">,
            renk_tonu     = <cfqueryparam value="#isNull(renkTonu)?'':renkTonu#"           cfsqltype="cf_sql_smallint" null="#isNull(renkTonu)#">,
            boya_derecesi = <cfqueryparam value="#boyaDer#"                               cfsqltype="cf_sql_varchar"  null="#NOT len(boyaDer)#">,
            is_ready      = <cfqueryparam value="#isReady#"                               cfsqltype="cf_sql_bit">,
            update_date   = CURRENT_TIMESTAMP
        WHERE stock_id = <cfqueryparam value="#stockId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset response.success = true>
    <cfset response.message = "Renk bilgileri güncellendi.">

    <cfcatch type="any">
        <cfset response.message = "Hata: " & cfcatch.message>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
