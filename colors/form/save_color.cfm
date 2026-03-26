<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Renk kaydet (INSERT / UPDATE)
    Adımlar:
      1. stocks tablosuna INSERT/UPDATE (color stock)
      2. color_info tablosuna INSERT/UPDATE (metadata)
      3. product_tree satırlarını sil + yeniden ekle (reçete)
--->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.stock_id"       default="0">
    <cfparam name="form.company_id"     default="0">
    <cfparam name="form.product_id"     default="0">
    <cfparam name="form.color_code"     default="">
    <cfparam name="form.color_name"     default="">
    <cfparam name="form.kartela_no"     default="">
    <cfparam name="form.kartela_date"   default="">
    <cfparam name="form.renk_tonu"      default="">
    <cfparam name="form.boya_derecesi"  default="">
    <cfparam name="form.flote"          default="0">
    <cfparam name="form.information"    default="">
    <cfparam name="form.is_ready"       default="false">
    <cfparam name="form.recipe_json"    default="[]">

    <cfset stockId    = isNumeric(form.stock_id)   AND val(form.stock_id)   gt 0 ? val(form.stock_id)   : 0>
    <cfset companyId  = isNumeric(form.company_id) AND val(form.company_id) gt 0 ? val(form.company_id) : 0>
    <cfset productId  = isNumeric(form.product_id) AND val(form.product_id) gt 0 ? val(form.product_id) : javaCast("null","")>
    <cfset colorCode  = trim(form.color_code)>
    <cfset colorName  = trim(form.color_name)>
    <cfset kartelaNo  = trim(form.kartela_no)>
    <cfset kartelaDate= (len(trim(form.kartela_date)) AND isDate(form.kartela_date))
                         ? createODBCDate(parseDateTime(form.kartela_date))
                         : javaCast("null","")>
    <cfset renkTonu   = isNumeric(form.renk_tonu) AND val(form.renk_tonu) gt 0 ? val(form.renk_tonu) : javaCast("null","")>
    <cfset boyaDer    = trim(form.boya_derecesi)>
    <cfset flote      = isNumeric(form.flote) ? val(form.flote) : 0>
    <cfset info       = trim(form.information)>
    <cfset isReady    = (form.is_ready eq "true" OR form.is_ready eq "1")>

    <!--- Validasyon --->
    <cfif companyId eq 0>
        <cfset response.message = "Müşteri seçimi zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <!--- Reçete JSON parse --->
    <cftry>
        <cfset recipeData = deserializeJSON(form.recipe_json)>
        <cfcatch><cfset recipeData = []></cfcatch>
    </cftry>

    <cfif NOT isArray(recipeData) OR NOT arrayLen(recipeData)>
        <cfset response.message = "Reçete boş olamaz.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cfif stockId gt 0>
        <!--- ─── UPDATE stocks ─── --->
        <cfquery datasource="boyahane">
            UPDATE stocks SET
                
                product_id    = <cfqueryparam value="#isNull(productId)?'':productId#"          cfsqltype="cf_sql_integer" null="#isNull(productId)#">,
                property      = <cfqueryparam value="#colorCode#"                              cfsqltype="cf_sql_varchar" null="#NOT len(colorCode)#">,
                stock_code_2  = <cfqueryparam value="#colorName#"                              cfsqltype="cf_sql_varchar" null="#NOT len(colorName)#">,
                barcod        = <cfqueryparam value="#kartelaNo#"                              cfsqltype="cf_sql_varchar" null="#NOT len(kartelaNo)#">,
                manufact_code = <cfqueryparam value="#info#"                                   cfsqltype="cf_sql_varchar" null="#NOT len(info)#">,
                update_date   = CURRENT_TIMESTAMP
            WHERE stock_id = <cfqueryparam value="#stockId#" cfsqltype="cf_sql_integer">
        </cfquery>

        <!--- UPDATE color_info --->
        <cfquery datasource="boyahane">
            UPDATE color_info SET
                company_id    = <cfqueryparam value="#companyId#"                              cfsqltype="cf_sql_integer">,
                product_id    = <cfqueryparam value="#isNull(productId)?'':productId#"          cfsqltype="cf_sql_integer" null="#isNull(productId)#">,
                color_code    = <cfqueryparam value="#colorCode#"                              cfsqltype="cf_sql_varchar" null="#NOT len(colorCode)#">,
                color_name    = <cfqueryparam value="#colorName#"                              cfsqltype="cf_sql_varchar" null="#NOT len(colorName)#">,
                kartela_no    = <cfqueryparam value="#kartelaNo#"                              cfsqltype="cf_sql_varchar" null="#NOT len(kartelaNo)#">,
                kartela_date  = <cfqueryparam value="#isNull(kartelaDate)?'':kartelaDate#"      cfsqltype="cf_sql_date"    null="#isNull(kartelaDate)#">,
                renk_tonu     = <cfqueryparam value="#isNull(renkTonu)?'':renkTonu#"            cfsqltype="cf_sql_smallint" null="#isNull(renkTonu)#">,
                boya_derecesi = <cfqueryparam value="#boyaDer#"                                cfsqltype="cf_sql_varchar" null="#NOT len(boyaDer)#">,
                flote         = <cfqueryparam value="#flote#"                                  cfsqltype="cf_sql_numeric">,
                is_ready      = <cfqueryparam value="#isReady#"                                cfsqltype="cf_sql_bit">,
                information   = <cfqueryparam value="#info#"                                   cfsqltype="cf_sql_varchar" null="#NOT len(info)#">,
                update_date   = CURRENT_TIMESTAMP
            WHERE stock_id = <cfqueryparam value="#stockId#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfset savedStockId = stockId>
        <cfset mode         = "updated">
    <cfelse>
        <!--- ─── INSERT stocks ─── --->
        <!--- Otomatik renk stok kodu oluştur --->
        <cfset autoCode = "CLR-" & dateFormat(now(),"yyyymmdd") & "-" & right("000" & randRange(1,999),3)>

        <cfquery name="insStock" datasource="boyahane">
            INSERT INTO stocks
                (stock_code, stock_code_2, property, barcod, manufact_code,
                 company_id, product_id, is_main_stock, stock_status, record_date)
            VALUES (
                <cfqueryparam value="#autoCode#"     cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#colorName#"    cfsqltype="cf_sql_varchar" null="#NOT len(colorName)#">,
                <cfqueryparam value="#colorCode#"    cfsqltype="cf_sql_varchar" null="#NOT len(colorCode)#">,
                <cfqueryparam value="#kartelaNo#"    cfsqltype="cf_sql_varchar" null="#NOT len(kartelaNo)#">,
                <cfqueryparam value="#info#"         cfsqltype="cf_sql_varchar" null="#NOT len(info)#">,
                <cfqueryparam value="#companyId#"    cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#isNull(productId)?'':productId#" cfsqltype="cf_sql_integer" null="#isNull(productId)#">,
                false,
                true,
                CURRENT_TIMESTAMP
            )
            RETURNING stock_id
        </cfquery>
        <cfset savedStockId = val(insStock.stock_id)>

        <!--- INSERT color_info --->
        <cfquery datasource="boyahane">
            INSERT INTO color_info
                (stock_id, company_id, product_id, color_code, color_name,
                 kartela_no, kartela_date, renk_tonu, boya_derecesi, flote,
                 is_ready, information, record_date)
            VALUES (
                <cfqueryparam value="#savedStockId#"                                       cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#companyId#"                                          cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#isNull(productId)?'':productId#"                     cfsqltype="cf_sql_integer" null="#isNull(productId)#">,
                <cfqueryparam value="#colorCode#"                                          cfsqltype="cf_sql_varchar" null="#NOT len(colorCode)#">,
                <cfqueryparam value="#colorName#"                                          cfsqltype="cf_sql_varchar" null="#NOT len(colorName)#">,
                <cfqueryparam value="#kartelaNo#"                                          cfsqltype="cf_sql_varchar" null="#NOT len(kartelaNo)#">,
                <cfqueryparam value="#isNull(kartelaDate)?'':kartelaDate#"                 cfsqltype="cf_sql_date"    null="#isNull(kartelaDate)#">,
                <cfqueryparam value="#isNull(renkTonu)?'':renkTonu#"                       cfsqltype="cf_sql_smallint" null="#isNull(renkTonu)#">,
                <cfqueryparam value="#boyaDer#"                                            cfsqltype="cf_sql_varchar" null="#NOT len(boyaDer)#">,
                <cfqueryparam value="#flote#"                                              cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#isReady#"                                            cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#info#"                                               cfsqltype="cf_sql_varchar" null="#NOT len(info)#">,
                CURRENT_TIMESTAMP
            )
        </cfquery>

        <cfset mode = "added">
    </cfif>

    <!--- ─── Reçete: mevcut product_tree satırlarını temizle + yeniden ekle ─── --->
    <cfquery datasource="boyahane">
        DELETE FROM product_tree
        WHERE stock_id = <cfqueryparam value="#savedStockId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <!--- parent_id'ye göre grupla --->
    <cfset groups = {}>
    <cfloop array="#recipeData#" index="item">
        <cfset pid = (isStruct(item) AND structKeyExists(item,"parent_id") AND len(trim(item.parent_id))) ? trim(item.parent_id) : "default">
        <cfif NOT structKeyExists(groups, pid)>
            <cfset groups[pid] = []>
        </cfif>
        <cfset arrayAppend(groups[pid], item)>
    </cfloop>

    <!--- Her grup: önce operasyonu ekle, sonra ürünleri operasyona bağla --->
    <cfset opLineNum = 0>
    <cfloop collection="#groups#" item="gKey">
        <cfset grpItems = groups[gKey]>
        <cfset opTreeId = javaCast("null","")>

        <!--- 1. Operasyonu bul ve ekle --->
        <cfloop array="#grpItems#" index="item">
            <cfif isStruct(item) AND structKeyExists(item,"is_operation") AND val(item.is_operation) eq 1>
                <cfset opLineNum  = opLineNum + 1>
                <cfset opTypeId   = structKeyExists(item,"operation_type_id") AND isNumeric(item.operation_type_id) ? val(item.operation_type_id) : javaCast("null","")>
                <cfset opAmount   = structKeyExists(item,"amount") AND isNumeric(item.amount) ? val(item.amount) : 1>
                <cfquery name="insOp" datasource="boyahane">
                    INSERT INTO product_tree
                        (stock_id, operation_type_id, amount, line_number, hierarchy, is_tree, record_date)
                    VALUES (
                        <cfqueryparam value="#savedStockId#"                          cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#isNull(opTypeId)?'':opTypeId#"          cfsqltype="cf_sql_integer" null="#isNull(opTypeId)#">,
                        <cfqueryparam value="#opAmount#"                              cfsqltype="cf_sql_numeric">,
                        <cfqueryparam value="#opLineNum#"                             cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#opLineNum#"                             cfsqltype="cf_sql_varchar">,
                        true,
                        CURRENT_TIMESTAMP
                    )
                    RETURNING product_tree_id
                </cfquery>
                <cfset opTreeId = val(insOp.product_tree_id)>
                <cfbreak>
            </cfif>
        </cfloop>

        <!--- 2. Ürünleri ekle, operasyona bağla --->
        <cfloop array="#grpItems#" index="item">
            <cfif isStruct(item) AND NOT (structKeyExists(item,"is_operation") AND val(item.is_operation) eq 1)>
                <cfset compStockId = structKeyExists(item,"stock_id") AND isNumeric(item.stock_id) ? val(item.stock_id) : 0>
                <cfset itemAmount  = structKeyExists(item,"amount")   AND isNumeric(item.amount)   ? val(item.amount) : 1>
                <cfset itemUnitId  = structKeyExists(item,"unit_id")  AND isNumeric(item.unit_id) AND val(item.unit_id) gt 0 ? val(item.unit_id) : javaCast("null","")>
                <cfset lineOrder   = structKeyExists(item,"line_order") AND isNumeric(item.line_order) ? val(item.line_order) : 0>

                <cfif compStockId gt 0>
                    <cfquery name="getCompProd" datasource="boyahane">
                        SELECT product_id FROM stocks WHERE stock_id = <cfqueryparam value="#compStockId#" cfsqltype="cf_sql_integer">
                    </cfquery>
                    <cfset compProdId = getCompProd.recordCount AND isNumeric(getCompProd.product_id) AND val(getCompProd.product_id) gt 0
                                         ? val(getCompProd.product_id) : javaCast("null","")>

                    <cfquery datasource="boyahane">
                        INSERT INTO product_tree
                            (stock_id, related_id, product_id, amount, unit_id,
                             line_number, hierarchy, is_tree,
                             related_product_tree_id, record_date)
                        VALUES (
                            <cfqueryparam value="#savedStockId#"                               cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#compStockId#"                                cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#isNull(compProdId)?'':compProdId#"           cfsqltype="cf_sql_integer" null="#isNull(compProdId)#">,
                            <cfqueryparam value="#itemAmount#"                                 cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#isNull(itemUnitId)?'':itemUnitId#"           cfsqltype="cf_sql_integer" null="#isNull(itemUnitId)#">,
                            <cfqueryparam value="#lineOrder#"                                  cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#lineOrder#"                                  cfsqltype="cf_sql_varchar">,
                            true,
                            <cfqueryparam value="#isNull(opTreeId)?'':opTreeId#"               cfsqltype="cf_sql_integer" null="#isNull(opTreeId)#">,
                            CURRENT_TIMESTAMP
                        )
                    </cfquery>
                </cfif>
            </cfif>
        </cfloop>
    </cfloop>

    <cfset response = { "success": true, "stock_id": savedStockId, "mode": mode }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
