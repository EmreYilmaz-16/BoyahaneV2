<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    product_tree kaydet (INSERT / UPDATE)

    Sütun anlamları:
        stock_id           = kök stok (BOM sahibi)  ← form.root_stock_id
        related_id         = bileşenin stock_id'si   (malzeme satırı)
        product_id         = bileşenin product_id'si (malzeme satırı, stocks'tan otomatik)
        operation_type_id  = operasyon satırı için (malzeme satırlarında NULL)
--->

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.product_tree_id"    default="0">
    <cfparam name="form.root_stock_id"      default="0">
    <cfparam name="form.row_type"           default="malzeme">
    <cfparam name="form.parent_tree_id"     default="0">
    <cfparam name="form.component_stock_id" default="0">
    <cfparam name="form.operation_type_id"  default="0">
    <cfparam name="form.amount"             default="1">
    <cfparam name="form.unit_id"            default="0">
    <cfparam name="form.fire_amount"        default="0">
    <cfparam name="form.fire_rate"          default="0">
    <cfparam name="form.station_id"         default="0">
    <cfparam name="form.line_number"        default="0">
    <cfparam name="form.process_stage"      default="0">
    <cfparam name="form.tree_type"          default="0">
    <cfparam name="form.detail"             default="">
    <cfparam name="form.is_phantom"         default="false">
    <cfparam name="form.is_configure"       default="false">
    <cfparam name="form.is_sevk"            default="false">

    <cfset treeId      = isNumeric(form.product_tree_id) ? val(form.product_tree_id) : 0>
    <cfset rootStockId = isNumeric(form.root_stock_id) AND val(form.root_stock_id) gt 0 ? val(form.root_stock_id) : 0>
    <cfset rowType     = lCase(trim(form.row_type))>
    <cfset parentId    = isNumeric(form.parent_tree_id) AND val(form.parent_tree_id) gt 0 ? val(form.parent_tree_id) : javaCast("null","")>
    <cfset compStockId = isNumeric(form.component_stock_id) AND val(form.component_stock_id) gt 0 ? val(form.component_stock_id) : javaCast("null","")>
    <cfset opTypeId    = isNumeric(form.operation_type_id) AND val(form.operation_type_id) gt 0 ? val(form.operation_type_id) : javaCast("null","")>
    <cfset amount      = isNumeric(form.amount) AND val(form.amount) gt 0 ? val(form.amount) : 1>
    <cfset unitId      = isNumeric(form.unit_id) AND val(form.unit_id) gt 0 ? val(form.unit_id) : javaCast("null","")>
    <cfset fireAmt     = isNumeric(form.fire_amount) ? val(form.fire_amount) : 0>
    <cfset fireRate    = isNumeric(form.fire_rate) ? val(form.fire_rate) : 0>
    <cfset stationId   = isNumeric(form.station_id) AND val(form.station_id) gt 0 ? val(form.station_id) : javaCast("null","")>
    <cfset lineNum     = isNumeric(form.line_number) ? val(form.line_number) : 0>
    <cfset procStage   = isNumeric(form.process_stage) ? val(form.process_stage) : 0>
    <cfset treeType    = isNumeric(form.tree_type) ? val(form.tree_type) : 0>
    <cfset detail      = trim(form.detail)>
    <cfset isPhantom   = (form.is_phantom   eq "true" OR form.is_phantom   eq "1")>
    <cfset isConfig    = (form.is_configure eq "true" OR form.is_configure eq "1")>
    <cfset isSevk      = (form.is_sevk      eq "true" OR form.is_sevk      eq "1")>

    <!--- Validasyon --->
    <cfif rootStockId eq 0>
        <cfset response.message = "Kök stok ID gereklidir.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>
    <cfif rowType eq "malzeme" AND isNull(compStockId)>
        <cfset response.message = "Malzeme satırı için bileşen stok seçimi zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>
    <cfif rowType eq "operasyon" AND isNull(opTypeId)>
        <cfset response.message = "Operasyon satırı için operasyon tipi seçimi zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Malzeme satırı: bileşenin product_id'sini stocks tablosundan çek --->
    <cfset compProdId = javaCast("null","")>
    <cfif rowType eq "malzeme" AND NOT isNull(compStockId)>
        <cfquery name="getCompProd" datasource="boyahane">
            SELECT product_id FROM stocks
            WHERE stock_id = <cfqueryparam value="#compStockId#" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif getCompProd.recordCount AND isNumeric(getCompProd.product_id) AND val(getCompProd.product_id) gt 0>
            <cfset compProdId = val(getCompProd.product_id)>
        </cfif>
    </cfif>

    <!--- Operasyon satırında bileşen yok --->
    <cfif rowType eq "operasyon">
        <cfset compStockId = javaCast("null","")>
        <cfset compProdId  = javaCast("null","")>
        <cfset unitId      = javaCast("null","")>
        <cfset fireAmt     = 0>
        <cfset fireRate    = 0>
    </cfif>

    <cfif treeId gt 0>
        <!--- ─── UPDATE ─── --->
        <cfquery datasource="boyahane">
            UPDATE product_tree SET
                related_id        = <cfqueryparam value="#isNull(compStockId)?'':compStockId#" cfsqltype="cf_sql_integer" null="#isNull(compStockId)#">,
                product_id        = <cfqueryparam value="#isNull(compProdId)?'':compProdId#"   cfsqltype="cf_sql_integer" null="#isNull(compProdId)#">,
                amount            = <cfqueryparam value="#amount#"                             cfsqltype="cf_sql_numeric">,
                unit_id           = <cfqueryparam value="#isNull(unitId)?'':unitId#"            cfsqltype="cf_sql_integer" null="#isNull(unitId)#">,
                fire_amount       = <cfqueryparam value="#fireAmt#"                            cfsqltype="cf_sql_numeric">,
                fire_rate         = <cfqueryparam value="#fireRate#"                           cfsqltype="cf_sql_numeric">,
                operation_type_id = <cfqueryparam value="#isNull(opTypeId)?'':opTypeId#"       cfsqltype="cf_sql_integer" null="#isNull(opTypeId)#">,
                station_id        = <cfqueryparam value="#isNull(stationId)?'':stationId#"     cfsqltype="cf_sql_integer" null="#isNull(stationId)#">,
                line_number       = <cfqueryparam value="#lineNum#"                            cfsqltype="cf_sql_integer">,
                process_stage     = <cfqueryparam value="#procStage#"                          cfsqltype="cf_sql_integer">,
                tree_type         = <cfqueryparam value="#treeType#"                           cfsqltype="cf_sql_integer">,
                detail            = <cfqueryparam value="#detail#"                             cfsqltype="cf_sql_varchar" null="#NOT len(detail)#">,
                is_phantom        = <cfqueryparam value="#isPhantom#"                          cfsqltype="cf_sql_bit">,
                is_configure      = <cfqueryparam value="#isConfig#"                           cfsqltype="cf_sql_bit">,
                is_sevk           = <cfqueryparam value="#isSevk#"                             cfsqltype="cf_sql_bit">,
                update_date       = CURRENT_TIMESTAMP
            WHERE product_tree_id = <cfqueryparam value="#treeId#"        cfsqltype="cf_sql_integer">
              AND stock_id         = <cfqueryparam value="#rootStockId#"   cfsqltype="cf_sql_integer">
        </cfquery>
        <cfset savedId = treeId>
        <cfset mode    = "updated">
    <cfelse>
        <!--- ─── INSERT ─── --->

        <!--- Otomatik satır numarası --->
        <cfif lineNum eq 0>
            <cfquery name="getMaxLine" datasource="boyahane">
                SELECT COALESCE(MAX(line_number), 0) + 1 AS next_line
                FROM product_tree
                WHERE stock_id = <cfqueryparam value="#rootStockId#" cfsqltype="cf_sql_integer">
                  AND <cfif isNull(parentId)>related_product_tree_id IS NULL<cfelse>related_product_tree_id = <cfqueryparam value="#parentId#" cfsqltype="cf_sql_integer"></cfif>
            </cfquery>
            <cfset lineNum = val(getMaxLine.next_line)>
        </cfif>

        <!--- Üst satırın hierarchy --->
        <cfset parentHierarchy = "">
        <cfif NOT isNull(parentId)>
            <cfquery name="getParentRow" datasource="boyahane">
                SELECT COALESCE(hierarchy,'') AS hierarchy
                FROM product_tree
                WHERE product_tree_id = <cfqueryparam value="#parentId#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfif getParentRow.recordCount AND len(trim(getParentRow.hierarchy))>
                <cfset parentHierarchy = getParentRow.hierarchy & ".">
            </cfif>
        </cfif>
        <cfset newHierarchy = parentHierarchy & lineNum>

        <cfquery name="ins" datasource="boyahane">
            INSERT INTO product_tree
                (stock_id, related_id, product_id, related_product_tree_id,
                 amount, unit_id, fire_amount, fire_rate,
                 operation_type_id, station_id,
                 line_number, hierarchy, process_stage, tree_type, detail,
                 is_phantom, is_configure, is_sevk, is_tree, record_date)
            VALUES (
                <cfqueryparam value="#rootStockId#"                              cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#isNull(compStockId)?'':compStockId#"       cfsqltype="cf_sql_integer" null="#isNull(compStockId)#">,
                <cfqueryparam value="#isNull(compProdId)?'':compProdId#"         cfsqltype="cf_sql_integer" null="#isNull(compProdId)#">,
                <cfqueryparam value="#isNull(parentId)?'':parentId#"             cfsqltype="cf_sql_integer" null="#isNull(parentId)#">,
                <cfqueryparam value="#amount#"                                   cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#isNull(unitId)?'':unitId#"                  cfsqltype="cf_sql_integer" null="#isNull(unitId)#">,
                <cfqueryparam value="#fireAmt#"                                  cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#fireRate#"                                 cfsqltype="cf_sql_numeric">,
                <cfqueryparam value="#isNull(opTypeId)?'':opTypeId#"             cfsqltype="cf_sql_integer" null="#isNull(opTypeId)#">,
                <cfqueryparam value="#isNull(stationId)?'':stationId#"           cfsqltype="cf_sql_integer" null="#isNull(stationId)#">,
                <cfqueryparam value="#lineNum#"                                  cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#newHierarchy#"                             cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#procStage#"                                cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#treeType#"                                 cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#detail#"                                   cfsqltype="cf_sql_varchar" null="#NOT len(detail)#">,
                <cfqueryparam value="#isPhantom#"                                cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#isConfig#"                                 cfsqltype="cf_sql_bit">,
                <cfqueryparam value="#isSevk#"                                   cfsqltype="cf_sql_bit">,
                true,
                CURRENT_TIMESTAMP
            )
            RETURNING product_tree_id
        </cfquery>
        <cfset savedId = val(ins.product_tree_id)>
        <cfset mode    = "added">
    </cfif>

    <!--- Kaydedilen satırı zenginleştirilmiş döndür --->
    <cfquery name="getRow" datasource="boyahane">
        SELECT
            pt.product_tree_id,
            COALESCE(pt.related_product_tree_id, 0)  AS related_product_tree_id,
            pt.stock_id                               AS root_stock_id,
            COALESCE(pt.related_id, 0)               AS component_stock_id,
            COALESCE(pt.product_id, 0)               AS component_product_id,
            COALESCE(cs.stock_code,'')               AS component_stock_code,
            COALESCE(cp.product_name,'')             AS component_name,
            COALESCE(pt.amount, 0)                   AS amount,
            COALESCE(pt.unit_id, 0)                  AS unit_id,
            COALESCE(u.unit,'')                      AS unit_name,
            COALESCE(u.unit_code,'')                 AS unit_code,
            COALESCE(pt.operation_type_id, 0)        AS operation_type_id,
            COALESCE(ot.operation_type,'')           AS operation_type_name,
            COALESCE(pt.station_id, 0)               AS station_id,
            COALESCE(ws.station_name,'')             AS station_name,
            COALESCE(pt.is_phantom, false)           AS is_phantom,
            COALESCE(pt.is_configure, false)         AS is_configure,
            COALESCE(pt.is_sevk, false)              AS is_sevk,
            COALESCE(pt.line_number, 0)              AS line_number,
            COALESCE(pt.process_stage, 0)            AS process_stage,
            COALESCE(pt.tree_type, 0)                AS tree_type,
            COALESCE(pt.detail,'')                   AS detail,
            COALESCE(pt.hierarchy,'')                AS hierarchy,
            COALESCE(pt.fire_amount, 0)              AS fire_amount,
            COALESCE(pt.fire_rate, 0)                AS fire_rate,
            COALESCE(pt.record_date, CURRENT_TIMESTAMP) AS record_date
        FROM product_tree pt
        LEFT JOIN stocks cs          ON pt.related_id        = cs.stock_id
        LEFT JOIN product cp         ON cs.product_id        = cp.product_id
        LEFT JOIN setup_unit u       ON pt.unit_id           = u.unit_id
        LEFT JOIN operation_types ot ON pt.operation_type_id = ot.operation_type_id
        LEFT JOIN workstations ws    ON pt.station_id        = ws.station_id
        WHERE pt.product_tree_id = <cfqueryparam value="#savedId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset rowData = {
        "product_tree_id"         : val(getRow.product_tree_id),
        "related_product_tree_id" : val(getRow.related_product_tree_id),
        "root_stock_id"           : val(getRow.root_stock_id),
        "component_stock_id"      : val(getRow.component_stock_id),
        "component_product_id"    : val(getRow.component_product_id),
        "component_stock_code"    : getRow.component_stock_code  ?: "",
        "component_name"          : getRow.component_name        ?: "",
        "amount"                  : isNumeric(getRow.amount) ? val(getRow.amount) : 0,
        "unit_id"                 : val(getRow.unit_id),
        "unit_name"               : getRow.unit_name             ?: "",
        "unit_code"               : getRow.unit_code             ?: "",
        "operation_type_id"       : val(getRow.operation_type_id),
        "operation_type_name"     : getRow.operation_type_name   ?: "",
        "station_id"              : val(getRow.station_id),
        "station_name"            : getRow.station_name          ?: "",
        "is_phantom"              : getRow.is_phantom,
        "is_configure"            : getRow.is_configure,
        "is_sevk"                 : getRow.is_sevk,
        "line_number"             : val(getRow.line_number),
        "process_stage"           : val(getRow.process_stage),
        "tree_type"               : val(getRow.tree_type),
        "detail"                  : getRow.detail                ?: "",
        "hierarchy"               : getRow.hierarchy             ?: "",
        "fire_amount"             : isNumeric(getRow.fire_amount) ? val(getRow.fire_amount) : 0,
        "fire_rate"               : isNumeric(getRow.fire_rate)   ? val(getRow.fire_rate)   : 0,
        "record_date"             : isDate(getRow.record_date) ? dateFormat(getRow.record_date,"dd/mm/yyyy") : ""
    }>

    <cfset response = { "success": true, "product_tree_id": savedId, "mode": mode, "row": rowData }>

    <cfcatch type="any">
        <cfset response = { "success": false, "message": "Hata: " & cfcatch.message }>
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
