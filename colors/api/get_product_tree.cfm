<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<!---
    Seçilen stok için BOM ağacını döndürür (renk ekleme/düzenleme sayfasında önizleme).
    Parametre: url.stock_id
    Geri döner: [{ product_tree_id, related_product_tree_id, ... }]
--->

<cfparam name="url.stock_id" default="0">
<cfset rootId = isNumeric(url.stock_id) AND val(url.stock_id) gt 0 ? val(url.stock_id) : 0>

<cfif rootId eq 0>
    <cfoutput>[]</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfquery name="getTree" datasource="boyahane">
        WITH RECURSIVE bom_tree AS (

            SELECT
                pt.product_tree_id,
                COALESCE(pt.related_product_tree_id, 0)  AS display_parent_id,
                pt.stock_id                              AS bom_owner_stock_id,
                pt.related_id,
                pt.product_id,
                pt.amount,      pt.unit_id,
                pt.fire_amount, pt.fire_rate,
                pt.operation_type_id,
                pt.station_id,
                pt.line_number, pt.process_stage, pt.tree_type,
                pt.detail,      pt.hierarchy,
                pt.is_phantom, pt.is_configure, pt.is_sevk,
                pt.record_date,
                false AS is_sub_bom,
                1     AS depth
            FROM product_tree pt
            WHERE pt.stock_id = <cfqueryparam value="#rootId#" cfsqltype="cf_sql_integer">

            UNION ALL

            SELECT
                sub.product_tree_id,
                CASE
                    WHEN COALESCE(sub.related_product_tree_id, 0) = 0
                    THEN parent.product_tree_id
                    ELSE sub.related_product_tree_id
                END AS display_parent_id,
                sub.stock_id                     AS bom_owner_stock_id,
                sub.related_id,
                sub.product_id,
                sub.amount,      sub.unit_id,
                sub.fire_amount, sub.fire_rate,
                sub.operation_type_id,
                sub.station_id,
                sub.line_number, sub.process_stage, sub.tree_type,
                sub.detail,      sub.hierarchy,
                sub.is_phantom, sub.is_configure, sub.is_sevk,
                sub.record_date,
                true            AS is_sub_bom,
                parent.depth + 1
            FROM bom_tree parent
            INNER JOIN product_tree sub ON sub.stock_id = parent.related_id
            WHERE parent.related_id IS NOT NULL
              AND parent.related_id > 0
              AND parent.depth < 10
        )

        SELECT DISTINCT ON (bom.product_tree_id)
            bom.product_tree_id,
            bom.display_parent_id                            AS related_product_tree_id,
            bom.bom_owner_stock_id,
            COALESCE(bom.related_id, 0)                     AS component_stock_id,
            COALESCE(bom.product_id, 0)                     AS component_product_id,
            COALESCE(cs.stock_code,'')                       AS component_stock_code,
            COALESCE(cp.product_name,'')                     AS component_name,
            COALESCE(bom.amount, 0)                         AS amount,
            COALESCE(bom.unit_id, 0)                        AS unit_id,
            COALESCE(u.unit,'')                             AS unit_name,
            COALESCE(u.unit_code,'')                        AS unit_code,
            COALESCE(bom.operation_type_id, 0)              AS operation_type_id,
            COALESCE(ot.operation_type,'')                  AS operation_type_name,
            COALESCE(bom.station_id, 0)                     AS station_id,
            COALESCE(ws.station_name,'')                    AS station_name,
            COALESCE(bom.is_phantom, false)                 AS is_phantom,
            COALESCE(bom.is_configure, false)               AS is_configure,
            COALESCE(bom.is_sevk, false)                    AS is_sevk,
            COALESCE(bom.line_number, 0)                    AS line_number,
            COALESCE(bom.process_stage, 0)                  AS process_stage,
            COALESCE(bom.tree_type, 0)                      AS tree_type,
            COALESCE(bom.detail,'')                         AS detail,
            COALESCE(bom.hierarchy,'')                      AS hierarchy,
            COALESCE(bom.fire_amount, 0)                    AS fire_amount,
            COALESCE(bom.fire_rate, 0)                      AS fire_rate,
            bom.is_sub_bom,
            COALESCE(bom.record_date, CURRENT_TIMESTAMP)    AS record_date
        FROM bom_tree bom
        LEFT JOIN stocks cs          ON bom.related_id        = cs.stock_id
        LEFT JOIN product cp         ON cs.product_id         = cp.product_id
        LEFT JOIN setup_unit u       ON bom.unit_id           = u.unit_id
        LEFT JOIN operation_types ot ON bom.operation_type_id = ot.operation_type_id
        LEFT JOIN workstations ws    ON bom.station_id        = ws.station_id
        ORDER BY bom.product_tree_id, bom.depth ASC
    </cfquery>

    <cfset arr = []>
    <cfloop query="getTree">
        <cfset arrayAppend(arr, {
            "product_tree_id"         : val(product_tree_id),
            "related_product_tree_id" : val(related_product_tree_id),
            "bom_owner_stock_id"      : val(bom_owner_stock_id),
            "component_stock_id"      : val(component_stock_id),
            "component_product_id"    : val(component_product_id),
            "component_stock_code"    : component_stock_code  ?: "",
            "component_name"          : component_name        ?: "",
            "amount"                  : isNumeric(amount) ? val(amount) : 0,
            "unit_id"                 : val(unit_id),
            "unit_name"               : unit_name             ?: "",
            "unit_code"               : unit_code             ?: "",
            "operation_type_id"       : val(operation_type_id),
            "operation_type_name"     : operation_type_name   ?: "",
            "station_id"              : val(station_id),
            "station_name"            : station_name          ?: "",
            "is_phantom"              : is_phantom,
            "is_configure"            : is_configure,
            "is_sevk"                 : is_sevk,
            "line_number"             : val(line_number),
            "process_stage"           : val(process_stage),
            "tree_type"               : val(tree_type),
            "detail"                  : detail                ?: "",
            "hierarchy"               : hierarchy             ?: "",
            "fire_amount"             : isNumeric(fire_amount) ? val(fire_amount) : 0,
            "fire_rate"               : isNumeric(fire_rate)   ? val(fire_rate)   : 0,
            "is_sub_bom"              : is_sub_bom
        })>
    </cfloop>

    <cfoutput>#serializeJSON(arr)#</cfoutput>

    <cfcatch type="any">
        <cfoutput>[]</cfoutput>
    </cfcatch>
</cftry>
