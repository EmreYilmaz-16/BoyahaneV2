
<cfquery name="getAll" datasource="#dsn#">
    WITH RECURSIVE product_tree_cte AS (
        SELECT
             S.STOCK_ID
            ,P.PRODUCT_NAME
            ,P.PRODUCT_CODE
            ,PU.MAIN_UNIT
            ,PC.DETAIL
            ,PC.LIST_ORDER_NO
            ,CASE
                WHEN P.PRODUCT_CODE LIKE '150.01%' THEN '0'
                WHEN P.PRODUCT_CODE LIKE '150.02%' THEN '1'
                WHEN P.PRODUCT_CODE LIKE '150.03%' THEN '2'
             END AS tip
            ,S.PRODUCT_UNIT_ID
            ,NULL::INTEGER  AS PARENT_STOCK_ID
            ,1::NUMERIC      AS AMOUNT
            ,0               AS LINE_NUMBER
            ,0               AS tree_level
            ,NULL::INTEGER   AS OPERATION_TYPE_ID
            ,NULL::VARCHAR   AS OPERATION_TYPE_NAME
            ,NULL::VARCHAR   AS OPERATION_CODE
            ,0               AS IS_OPERATION
            ,NULL::INTEGER   AS PRODUCT_TREE_ID
            ,NULL::INTEGER   AS RELATED_PRODUCT_TREE_ID
        FROM STOCKS AS S
        LEFT JOIN PRODUCT      AS P  ON P.PRODUCT_ID      = S.PRODUCT_ID
        LEFT JOIN PRODUCT_UNIT AS PU ON PU.PRODUCT_UNIT_ID = S.PRODUCT_UNIT_ID
        LEFT JOIN PRODUCT_CAT  AS PC ON PC.PRODUCT_CATID   = P.PRODUCT_CATID
        WHERE P.PRODUCT_STATUS = TRUE
        <cfif len(arguments.keyword)>
            AND (P.PRODUCT_NAME ILIKE '%#arguments.keyword#%' OR P.PRODUCT_CODE ILIKE '%#arguments.keyword#%')
        </cfif>
        <cfif len(arguments.stock_id)>
            AND S.STOCK_ID = #arguments.stock_id#
        </cfif>

        UNION ALL

        SELECT
             cs.STOCK_ID
            ,cp.PRODUCT_NAME
            ,cp.PRODUCT_CODE
            ,cpu.MAIN_UNIT
            ,cpc.DETAIL
            ,cpc.LIST_ORDER_NO
            ,CASE
                WHEN cp.PRODUCT_CODE LIKE '150.01%' THEN '0'
                WHEN cp.PRODUCT_CODE LIKE '150.02%' THEN '1'
                WHEN cp.PRODUCT_CODE LIKE '150.03%' THEN '2'
             END AS tip
            ,cs.PRODUCT_UNIT_ID
            ,pt.STOCK_ID AS PARENT_STOCK_ID
            ,pt.AMOUNT
            ,pt.LINE_NUMBER
            ,parent.tree_level + 1
            ,pt.OPERATION_TYPE_ID
            
            
            ,ot.OPERATION_TYPE  AS OPERATION_TYPE_NAME
            ,ot.OPERATION_CODE
            ,CASE WHEN pt.OPERATION_TYPE_ID IS NOT NULL THEN 1 ELSE 0 END AS IS_OPERATION
            ,pt.PRODUCT_TREE_ID
            ,pt.RELATED_PRODUCT_TREE_ID
        FROM product_tree_cte AS parent
        JOIN PRODUCT_TREE       AS pt  ON pt.STOCK_ID           = parent.STOCK_ID
        LEFT JOIN STOCKS        AS cs  ON cs.STOCK_ID           = pt.RELATED_ID
        LEFT JOIN PRODUCT       AS cp  ON cp.PRODUCT_ID         = cs.PRODUCT_ID
        LEFT JOIN PRODUCT_UNIT  AS cpu ON cpu.PRODUCT_UNIT_ID   = cs.PRODUCT_UNIT_ID
        LEFT JOIN PRODUCT_CAT   AS cpc ON cpc.PRODUCT_CATID     = cp.PRODUCT_CATID
        LEFT JOIN OPERATION_TYPES AS ot ON ot.OPERATION_TYPE_ID = pt.OPERATION_TYPE_ID
        WHERE (cs.STOCK_ID IS NOT NULL OR pt.OPERATION_TYPE_ID IS NOT NULL)
          AND parent.tree_level < 3
    )
    SELECT * FROM product_tree_cte
    ORDER BY tree_level, PARENT_STOCK_ID NULLS FIRST, LINE_NUMBER
</cfquery>


<cfscript>
    RETURN_ARRAY = [];
    byParent     = {};

    // Flat sonuçları level-0 (root) ve parent map'ine ayır
    cfloop(query="getAll") {
        row = {
            STOCK_ID        : getAll.STOCK_ID,
            PRODUCT_NAME    : getAll.PRODUCT_NAME,
            PRODUCT_CODE    : getAll.PRODUCT_CODE,
            MAIN_UNIT       : getAll.MAIN_UNIT,
            DETAIL          : getAll.DETAIL,
            LIST_ORDER_NO   : getAll.LIST_ORDER_NO,
            tip             : getAll.tip,
            PRODUCT_UNIT_ID : getAll.PRODUCT_UNIT_ID,
            AMOUNT             : getAll.AMOUNT,
            LINE_NUMBER        : getAll.LINE_NUMBER,
            PARENT_STOCK_ID    : getAll.PARENT_STOCK_ID,
            tree_level         : getAll.tree_level,
            // --- operasyon alanları ---
            IS_OPERATION       : getAll.IS_OPERATION,
            OPERATION_TYPE_ID  : getAll.OPERATION_TYPE_ID,
            OPERATION_TYPE_NAME: getAll.OPERATION_TYPE_NAME,
            OPERATION_CODE     : getAll.OPERATION_CODE,
            PRODUCT_TREE_ID    : getAll.PRODUCT_TREE_ID,
            RELATED_PRODUCT_TREE_ID    : getAll.RELATED_PRODUCT_TREE_ID
        };
        if (getAll.tree_level == 0) {
            arrayAppend(RETURN_ARRAY, row);
        } else {
            parentKey = toString(getAll.PARENT_STOCK_ID);
            if (!structKeyExists(byParent, parentKey)) {
                byParent[parentKey] = [];
            }
            arrayAppend(byParent[parentKey], row);
        }
    }

    // Her root için tree yapısını kur
    for (root in RETURN_ARRAY) {
        lvl1Children = structKeyExists(byParent, root.STOCK_ID) ? byParent[toString(root.STOCK_ID)] : [];
        TREE_LEVEL_1 = [];

        for (child1 in lvl1Children) {
            lvl2Children = structKeyExists(byParent, toString(child1.STOCK_ID)) ? byParent[toString(child1.STOCK_ID)] : [];
            TREE_LEVEL_2 = [];

            for (child2 in lvl2Children) {
                lvl3Children = structKeyExists(byParent, toString(child2.STOCK_ID)) ? byParent[toString(child2.STOCK_ID)] : [];
                TREE_LEVEL_3 = [];

                for (child3 in lvl3Children) {
                    item = duplicate(child3);
                    item.PARENT_ID    = child2.STOCK_ID;
                    item.IS_DIRECTORY = 0;
                    item.TREE         = [];
                    arrayAppend(TREE_LEVEL_3, item);
                }

                item2 = duplicate(child2);
                item2.PARENT_ID    = child1.STOCK_ID;
                item2.IS_DIRECTORY = arrayLen(TREE_LEVEL_3) ? 1 : 0;
                item2.TREE         = TREE_LEVEL_3;
                arrayAppend(TREE_LEVEL_2, item2);
            }

            item3 = duplicate(child1);
            item3.PARENT_ID    = root.STOCK_ID;
            item3.IS_DIRECTORY = arrayLen(TREE_LEVEL_2) ? 1 : 0;
            item3.TREE         = TREE_LEVEL_2;
            arrayAppend(TREE_LEVEL_1, item3);
        }

        root.LINE_NUMBER  = 0;
        root.AMOUNT       = 1;
        root.PARENT_ID    = "";
        root.IS_DIRECTORY = arrayLen(TREE_LEVEL_1) ? 1 : 0;
        root.TREE         = TREE_LEVEL_1;
    }
</cfscript>

