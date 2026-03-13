
<cfquery name="getstok" datasource="#dsn#_1">
    SELECT DISTINCT S.PRODUCT_NAME
    ,S.STOCK_ID
    ,PRODUCT_CODE                   
    ,PU.MAIN_UNIT
    ,PC.DETAIL
    ,PC.LIST_ORDER_NO 
                        ,CASE WHEN PRODUCT_CODE LIKE '150.01%' THEN '0'
 WHEN PRODUCT_CODE LIKE '150.02%' THEN '1'
 WHEN PRODUCT_CODE LIKE '150.03%' THEN '2'
 end as tip
    ,S.PRODUCT_UNIT_ID FROM STOCKS AS S 
    LEFT JOIN catalyst_prod_product.PRODUCT_UNIT AS PU ON PU.PRODUCT_UNIT_ID = S.PRODUCT_UNIT_ID 
    LEFT JOIN PRODUCT_CAT AS PC ON PC.PRODUCT_CATID=S.PRODUCT_CATID
    WHERE 1=1 <cfif len(arguments.keyword)> and( PRODUCT_NAME like '%#arguments.keyword#%' or PRODUCT_CODE like '%#arguments.keyword#%' )</cfif>
    <cfif len(arguments.stock_id)>and S.STOCK_ID =#arguments.stock_id#</cfif>
    AND PRODUCT_STATUS=1
</cfquery>

<cfset RETURN_ARRAY = arrayNew(1)>
<cfloop query="getstok">
    <cfquery name="getTree" datasource="#dsn#_1">
        SELECT S.PRODUCT_NAME
        ,S.STOCK_ID
        ,PT.AMOUNT
        ,PT.LINE_NUMBER
        ,PRODUCT_CODE
        ,PU.MAIN_UNIT
         ,PC.DETAIL
    ,PC.LIST_ORDER_NO
                            ,CASE WHEN PRODUCT_CODE LIKE '150.01%' THEN '0'
 WHEN PRODUCT_CODE LIKE '150.02%' THEN '1'
 WHEN PRODUCT_CODE LIKE '150.03%' THEN '2'
 end as tip
        ,S.PRODUCT_NAME
        ,S.PRODUCT_UNIT_ID
        FROM catalyst_prod_1.PRODUCT_TREE AS PT
        LEFT JOIN catalyst_prod_1.STOCKS AS S ON S.STOCK_ID = PT.RELATED_ID
        LEFT JOIN catalyst_prod_product.PRODUCT_UNIT AS PU ON PU.PRODUCT_UNIT_ID = S.PRODUCT_UNIT_ID
        LEFT JOIN PRODUCT_CAT AS PC ON PC.PRODUCT_CATID=S.PRODUCT_CATID
        WHERE PT.STOCK_ID = #getstok.STOCK_ID# AND S.STOCK_ID IS NOT NULL
        ORDER BY LINE_NUMBER
    </cfquery>  
    <CFSET TREE_LEVEL_1=arrayNew(1)>          
    <cfif getTree.recordcount>
        <cfloop query="getTree">                    
            <cfquery name="getTreelvl2" datasource="#dsn#_1">
                SELECT S.PRODUCT_NAME
                ,S.STOCK_ID
                ,PT.AMOUNT
                ,PT.LINE_NUMBER
                ,PRODUCT_CODE
                ,PU.MAIN_UNIT
                            ,PC.DETAIL
    ,PC.LIST_ORDER_NO
                     ,CASE WHEN PRODUCT_CODE LIKE '150.01%' THEN '0'
 WHEN PRODUCT_CODE LIKE '150.02%' THEN '1'
 WHEN PRODUCT_CODE LIKE '150.03%' THEN '2'
 end as tip
                ,S.PRODUCT_NAME
                ,S.PRODUCT_UNIT_ID
                FROM catalyst_prod_1.PRODUCT_TREE AS PT
                LEFT JOIN catalyst_prod_1.STOCKS AS S ON S.STOCK_ID = PT.RELATED_ID
                LEFT JOIN catalyst_prod_product.PRODUCT_UNIT AS PU ON PU.PRODUCT_UNIT_ID = S.PRODUCT_UNIT_ID
                LEFT JOIN PRODUCT_CAT AS PC ON PC.PRODUCT_CATID=S.PRODUCT_CATID
                WHERE PT.STOCK_ID = #getTree.STOCK_ID#
                ORDER BY LINE_NUMBER
            </cfquery>
            <CFSET TREE_LEVEL_2=arrayNew(1)>  
            <cfif getTreelvl2.recordcount>
                <cfloop query="getTreelvl2">
                    <cfquery name="getTreelvl3" datasource="#dsn#_1">
                        SELECT S.PRODUCT_NAME
                        ,S.STOCK_ID
                        ,PT.AMOUNT
                        ,PT.LINE_NUMBER
                        ,PRODUCT_CODE
                          ,PC.DETAIL
    ,PC.LIST_ORDER_NO                                            
                                            ,CASE WHEN PRODUCT_CODE LIKE '150.01%' THEN '0'
 WHEN PRODUCT_CODE LIKE '150.02%' THEN '1'
 WHEN PRODUCT_CODE LIKE '150.03%' THEN '2'
 end as tip
                        ,PU.MAIN_UNIT                                
                        ,S.PRODUCT_UNIT_ID
                        FROM catalyst_prod_1.PRODUCT_TREE AS PT
                        LEFT JOIN catalyst_prod_1.STOCKS AS S ON S.STOCK_ID = PT.RELATED_ID
                        LEFT JOIN catalyst_prod_product.PRODUCT_UNIT AS PU ON PU.PRODUCT_UNIT_ID = S.PRODUCT_UNIT_ID
                         LEFT JOIN PRODUCT_CAT AS PC ON PC.PRODUCT_CATID=S.PRODUCT_CATID
                        WHERE PT.STOCK_ID = #getTreelvl2.STOCK_ID#
                        ORDER BY LINE_NUMBER
                    </cfquery>
                    <CFSET TREE_LEVEL_3=arrayNew(1)>  
                    <cfif getTreelvl3.recordcount>                        
                        <cfloop query="getTreelvl3">
                            <cfscript>
                                item=structNew();
                                item.PRODUCT_NAME=getTreelvl3.PRODUCT_NAME;
                                item.STOCK_ID=getTreelvl3.STOCK_ID;
                                item.PRODUCT_UNIT_ID=getTreelvl3.PRODUCT_UNIT_ID;
                                item.PRODUCT_CODE=getTreelvl3.PRODUCT_CODE;
                                item.MAIN_UNIT=getTreelvl3.MAIN_UNIT;
                                item.DETAIL =DETAIL;
                                item.LIST_ORDER_NO=LIST_ORDER_NO;
                                item.LINE_NUMBER=getTreelvl3.LINE_NUMBER;
                                  item.tip=getTreelvl3.tip;
                                item.AMOUNT=getTreelvl3.AMOUNT;
                                item.PARENT_ID=getTreelvl2.STOCK_ID;
                                item.TREE=arrayNew(1);
                                 item2.IS_DIRECTORY=0;
                                arrayAppend(TREE_LEVEL_3, item);                                                                                
                            </cfscript>
                        </cfloop>
                    </cfif>
                    <cfscript>
                        item2=structNew();
                        item2.PRODUCT_NAME=getTreelvl2.PRODUCT_NAME;
                        item2.STOCK_ID=getTreelvl2.STOCK_ID;
                        item2.PRODUCT_UNIT_ID=getTreelvl2.PRODUCT_UNIT_ID;
                        item2.PRODUCT_CODE=getTreelvl2.PRODUCT_CODE;
                        item2.MAIN_UNIT=getTreelvl2.MAIN_UNIT;
                        item2.DETAIL =DETAIL;
                        item2.LIST_ORDER_NO=LIST_ORDER_NO;                        
                        item2.AMOUNT=getTreelvl2.AMOUNT;
                        item2.tip=getTreelvl2.tip;
                        item2.LINE_NUMBER=getTreelvl2.LINE_NUMBER;
                        item2.PARENT_ID=getTree.STOCK_ID;
                        item2.TREE=TREE_LEVEL_3
                        IF(arrayLen(TREE_LEVEL_3)){
                            item2.IS_DIRECTORY=1;
                        }ELSE{
                            item2.IS_DIRECTORY=0;
                        }                           
                        arrayAppend(TREE_LEVEL_2, item2)                                                                                
                    </cfscript>                               
                </cfloop>
            </cfif> 
            <cfscript>
                item3=structNew();
                item3.PRODUCT_NAME=getTree.PRODUCT_NAME;
                item3.STOCK_ID=getTree.STOCK_ID;
                item3.PRODUCT_UNIT_ID=getTree.PRODUCT_UNIT_ID;
                item3.PRODUCT_CODE=getTree.PRODUCT_CODE;
                item3.MAIN_UNIT=getTree.MAIN_UNIT;
                item3.DETAIL =DETAIL;
                item3.LIST_ORDER_NO=LIST_ORDER_NO; 
                item3.tip=getTree.tip;
                item3.LINE_NUMBER=getTree.LINE_NUMBER;
                item3.AMOUNT=getTree.AMOUNT;
                item3.PARENT_ID=getTree.STOCK_ID;
                IF(arrayLen(TREE_LEVEL_2)){
                    item3.IS_DIRECTORY=1;
                }ELSE{
                    item3.IS_DIRECTORY=0;
                }                
                item3.TREE=TREE_LEVEL_2
                arrayAppend(TREE_LEVEL_1, item3)                                                                                
            </cfscript>  
        </cfloop>
    </cfif>
    <cfscript>
        item4=structNew();
        item4.PRODUCT_NAME=PRODUCT_NAME;
        item4.STOCK_ID=getstok.STOCK_ID;
        item4.PRODUCT_UNIT_ID=PRODUCT_UNIT_ID;
        item4.PRODUCT_CODE=PRODUCT_CODE;
        item4.MAIN_UNIT=MAIN_UNIT;
        item4.DETAIL =DETAIL;
        item4.LIST_ORDER_NO=LIST_ORDER_NO; 
        item4.tip=tip;
        item4.LINE_NUMBER=0;
        item4.AMOUNT=1;
        item4.PARENT_ID="";
        IF(arrayLen(TREE_LEVEL_1)){
            item4.IS_DIRECTORY=1;
        }ELSE{
             item4.IS_DIRECTORY=0;
        }
        item4.TREE=TREE_LEVEL_1
        arrayAppend(RETURN_ARRAY, item4)                                                                                
    </cfscript>  
</cfloop>   
