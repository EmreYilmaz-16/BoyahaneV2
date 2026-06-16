<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Renk Kopyala (Yeni renk bilgileri + seçili rengin reçete ağacı)
    Adımlar (tek transaction):
      1. stocks tablosuna yeni renk stoğu INSERT (otomatik CLR-... kodu)
      2. color_info tablosuna yeni metadata INSERT
      3. Kaynak rengin (source_stock_id) product_tree satırlarını,
         eski→yeni product_tree_id eşlemesini koruyarak yeni stok altına kopyala
--->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.source_stock_id" default="0">
    <cfparam name="form.company_id"      default="0">
    <cfparam name="form.product_id"      default="0">
    <cfparam name="form.color_code"      default="">
    <cfparam name="form.color_name"      default="">
    <cfparam name="form.kartela_no"      default="">
    <cfparam name="form.kartela_date"    default="">
    <cfparam name="form.renk_no"         default="">
    <cfparam name="form.renk_tonu"       default="">
    <cfparam name="form.boya_derecesi"   default="">
    <cfparam name="form.flote"           default="0">
    <cfparam name="form.information"     default="">
    <cfparam name="form.is_ready"        default="false">

    <cfset sourceStockId = isNumeric(form.source_stock_id) AND val(form.source_stock_id) gt 0 ? val(form.source_stock_id) : 0>
    <cfset companyId  = isNumeric(form.company_id) AND val(form.company_id) gt 0 ? val(form.company_id) : 0>
    <cfset productId  = isNumeric(form.product_id) AND val(form.product_id) gt 0 ? val(form.product_id) : javaCast("null","")>
    <cfset colorCode  = trim(form.color_code)>
    <cfset colorName  = trim(form.color_name)>
    <cfset kartelaNo  = trim(form.kartela_no)>
    <cfset kartelaDate= (len(trim(form.kartela_date)) AND isDate(form.kartela_date))
                         ? createODBCDate(parseDateTime(form.kartela_date))
                         : javaCast("null","")>
    <cfset renkNo     = trim(form.renk_no)>
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
    <cfif sourceStockId eq 0>
        <cfset response.message = "Kopyalanacak kaynak renk seçimi zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput><cfabort>
    </cfif>

    <cftransaction>

        <!--- ─── 1. INSERT stocks ─── --->
        <cfset autoCode = "CLR-" & dateFormat(now(),"yyyymmdd") & "-" & right("000" & randRange(1,999),3)>

        <cfquery name="insStock" datasource="boyahane">
            INSERT INTO stocks
                (stock_code, stock_code_2, property, barcod, manufact_code,
                  product_id, is_main_stock, stock_status, record_date)
            VALUES (
                <cfqueryparam value="#autoCode#"     cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#colorName#"    cfsqltype="cf_sql_varchar" null="#NOT len(colorName)#">,
                <cfqueryparam value="#colorCode#"    cfsqltype="cf_sql_varchar" null="#NOT len(colorCode)#">,
                <cfqueryparam value="#kartelaNo#"    cfsqltype="cf_sql_varchar" null="#NOT len(kartelaNo)#">,
                <cfqueryparam value="#info#"         cfsqltype="cf_sql_varchar" null="#NOT len(info)#">,
                <cfqueryparam value="#isNull(productId)?'':productId#" cfsqltype="cf_sql_integer" null="#isNull(productId)#">,
                false,
                true,
                CURRENT_TIMESTAMP
            )
            RETURNING stock_id
        </cfquery>
        <cfset newStockId = val(insStock.stock_id)>

        <!--- ─── 2. INSERT color_info ─── --->
        <cfquery name="insColor" datasource="boyahane">
            INSERT INTO color_info
                (stock_id, company_id, product_id, color_code, color_name,
                 kartela_no, kartela_date, renk_no, renk_tonu, boya_derecesi, flote,
                 is_ready, information, record_date)
            VALUES (
                <cfqueryparam value="#newStockId#"                                         cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#companyId#"                                          cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#isNull(productId)?'':productId#"                     cfsqltype="cf_sql_integer" null="#isNull(productId)#">,
                <cfqueryparam value="#colorCode#"                                          cfsqltype="cf_sql_varchar" null="#NOT len(colorCode)#">,
                <cfqueryparam value="#colorName#"                                          cfsqltype="cf_sql_varchar" null="#NOT len(colorName)#">,
                <cfqueryparam value="#kartelaNo#"                                          cfsqltype="cf_sql_varchar" null="#NOT len(kartelaNo)#">,
                <cfqueryparam value="#isNull(kartelaDate)?'':kartelaDate#"                 cfsqltype="cf_sql_date"    null="#isNull(kartelaDate)#">,
                <cfqueryparam value="#renkNo#"                                             cfsqltype="cf_sql_varchar" null="#NOT len(renkNo)#">,
                <cfqueryparam value="#isNull(renkTonu)?'':renkTonu#"                       cfsqltype="cf_sql_smallint" null="#isNull(renkTonu)#">,
                <cfqueryparam value="#boyaDer#"                                            cfsqltype="cf_sql_varchar" null="#NOT len(boyaDer)#">,
                <cfqueryparam value="#flote#"                                              cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#isReady#"                                            cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#info#"                                               cfsqltype="cf_sql_varchar" null="#NOT len(info)#">,
                CURRENT_TIMESTAMP
            )
            RETURNING color_id
        </cfquery>
        <cfset newColorId = val(insColor.color_id)>

        <!--- ─── 3. Kaynak product_tree satırlarını oku ─── --->
        <cfquery name="srcTree" datasource="boyahane">
            SELECT
                product_tree_id,
                related_id,
                product_id,
                amount,
                unit_id,
                fire_amount,
                fire_rate,
                operation_type_id,
                station_id,
                line_number,
                process_stage,
                tree_type,
                detail,
                hierarchy,
                is_phantom,
                is_configure,
                is_sevk,
                is_tree,
                COALESCE(related_product_tree_id, 0) AS related_product_tree_id
            FROM product_tree
            WHERE stock_id = <cfqueryparam value="#sourceStockId#" cfsqltype="cf_sql_integer">
            ORDER BY product_tree_id
        </cfquery>

        <!--- Query → struct dizisi (eski id'lere göre kolay erişim ve yeniden sıralama için) --->
        <cfset srcRows = []>
        <cfloop query="srcTree">
            <cfset arrayAppend(srcRows, {
                "old_id"      : val(srcTree.product_tree_id),
                "related_id"  : (isNumeric(srcTree.related_id) AND val(srcTree.related_id) gt 0) ? val(srcTree.related_id) : javaCast("null",""),
                "product_id"  : (isNumeric(srcTree.product_id) AND val(srcTree.product_id) gt 0) ? val(srcTree.product_id) : javaCast("null",""),
                "amount"      : isNumeric(srcTree.amount) ? val(srcTree.amount) : 1,
                "unit_id"     : (isNumeric(srcTree.unit_id) AND val(srcTree.unit_id) gt 0) ? val(srcTree.unit_id) : javaCast("null",""),
                "fire_amount" : isNumeric(srcTree.fire_amount) ? val(srcTree.fire_amount) : 0,
                "fire_rate"   : isNumeric(srcTree.fire_rate) ? val(srcTree.fire_rate) : 0,
                "op_type_id"  : (isNumeric(srcTree.operation_type_id) AND val(srcTree.operation_type_id) gt 0) ? val(srcTree.operation_type_id) : javaCast("null",""),
                "station_id"  : (isNumeric(srcTree.station_id) AND val(srcTree.station_id) gt 0) ? val(srcTree.station_id) : javaCast("null",""),
                "line_number" : isNumeric(srcTree.line_number) ? val(srcTree.line_number) : 0,
                "proc_stage"  : isNumeric(srcTree.process_stage) ? val(srcTree.process_stage) : 0,
                "tree_type"   : isNumeric(srcTree.tree_type) ? val(srcTree.tree_type) : 0,
                "detail"      : len(srcTree.detail) ? srcTree.detail : javaCast("null",""),
                "hierarchy"   : srcTree.hierarchy ?: "",
                "is_phantom"  : srcTree.is_phantom,
                "is_configure": srcTree.is_configure,
                "is_sevk"     : srcTree.is_sevk,
                "is_tree"     : srcTree.is_tree,
                "parent_old"  : val(srcTree.related_product_tree_id)
            })>
        </cfloop>

        <!--- ─── Eski→yeni id eşlemesi: önce kökler, sonra çocuklar (çok seviyeli güvenli) ─── --->
        <cfset idMap     = {}>
        <cfset remaining = srcRows>
        <cfset copiedCnt = 0>
        <cfset safety    = 0>

        <cfloop condition="arrayLen(remaining) GT 0 AND safety LT 50">
            <cfset safety++>
            <cfset progressed = false>
            <cfset nextRound  = []>

            <cfloop array="#remaining#" index="row">
                <cfset parentOld = row.parent_old>
                <cfset parentReady = (parentOld eq 0) OR structKeyExists(idMap, parentOld)>

                <cfif parentReady>
                    <cfset newParentId = (parentOld eq 0) ? javaCast("null","") : idMap[parentOld]>

                    <cfquery name="insRow" datasource="boyahane">
                        INSERT INTO product_tree
                            (stock_id, related_id, product_id, amount, unit_id,
                             fire_amount, fire_rate, operation_type_id, station_id,
                             line_number, process_stage, tree_type, detail, hierarchy,
                             is_phantom, is_configure, is_sevk, is_tree,
                             related_product_tree_id, record_date)
                        VALUES (
                            <cfqueryparam value="#newStockId#"                                cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#isNull(row.related_id)?'':row.related_id#"   cfsqltype="cf_sql_integer" null="#isNull(row.related_id)#">,
                            <cfqueryparam value="#isNull(row.product_id)?'':row.product_id#"   cfsqltype="cf_sql_integer" null="#isNull(row.product_id)#">,
                            <cfqueryparam value="#row.amount#"                                cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#isNull(row.unit_id)?'':row.unit_id#"         cfsqltype="cf_sql_integer" null="#isNull(row.unit_id)#">,
                            <cfqueryparam value="#row.fire_amount#"                           cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#row.fire_rate#"                             cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#isNull(row.op_type_id)?'':row.op_type_id#"   cfsqltype="cf_sql_integer" null="#isNull(row.op_type_id)#">,
                            <cfqueryparam value="#isNull(row.station_id)?'':row.station_id#"   cfsqltype="cf_sql_integer" null="#isNull(row.station_id)#">,
                            <cfqueryparam value="#row.line_number#"                           cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#row.proc_stage#"                            cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#row.tree_type#"                             cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#isNull(row.detail)?'':row.detail#"           cfsqltype="cf_sql_varchar" null="#isNull(row.detail)#">,
                            <cfqueryparam value="#row.hierarchy#"                             cfsqltype="cf_sql_varchar" null="#NOT len(row.hierarchy)#">,
                            <cfqueryparam value="#row.is_phantom#"                            cfsqltype="cf_sql_bit">,
                            <cfqueryparam value="#row.is_configure#"                          cfsqltype="cf_sql_bit">,
                            <cfqueryparam value="#row.is_sevk#"                               cfsqltype="cf_sql_bit">,
                            <cfqueryparam value="#row.is_tree#"                               cfsqltype="cf_sql_bit">,
                            <cfqueryparam value="#isNull(newParentId)?'':newParentId#"        cfsqltype="cf_sql_integer" null="#isNull(newParentId)#">,
                            CURRENT_TIMESTAMP
                        )
                        RETURNING product_tree_id
                    </cfquery>

                    <cfset idMap[row.old_id] = val(insRow.product_tree_id)>
                    <cfset copiedCnt++>
                    <cfset progressed = true>
                <cfelse>
                    <cfset arrayAppend(nextRound, row)>
                </cfif>
            </cfloop>

            <cfset remaining = nextRound>
            <!--- İlerleme yoksa (parent zinciri kopuk) sonsuz döngüyü engelle --->
            <cfif NOT progressed><cfbreak></cfif>
        </cfloop>

    </cftransaction>

    <cfset response = {
        "success"  : true,
        "stock_id" : newStockId,
        "color_id" : newColorId,
        "copied_rows": copiedCnt,
        "mode"     : "copied"
    }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
