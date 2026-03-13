<cfcomponent>
<cfset dsn = "catalyst_prod">
<cfset dsn3 = "catalyst_prod_#session.ep.COMPANY_ID#">
<cffunction name="checkLogin" access="remote" returntype="any" returnFormat="json">
<cfargument  name="ships_id" default="">
<cfquery name="getPeriods" datasource=#dsn#>
SELECT * FROM SETUP_PERIOD WHERE OUR_COMPANY_ID=1
</cfquery>

<cfquery name="getirs" datasource="#dsn#">
SELECT * FROM(
    <cfloop query="getPeriods">
    SELECT  SIP.PROPERTY1 AS UCRET_DUR, <!-----OK----->
SIP.PROPERTY2  AS KUMAS_DUR, <!-----OK----->
SIP.PROPERTY3  AS EVRAK_NO2, <!-----OK----->
PRTC.RETURN_CAT  AS IADE_NEDEN,<!-----OK----->
SIP.PROPERTY4  AS IADE_NEDEN_ID,<!-----OK----->
SIP.PROPERTY5  AS GR_MTUL, <!-----OK----->
SIP.PROPERTY6  AS TOP_ADET, <!-----OK----->
SIP.PROPERTY7  AS H_GRAM, <!-----OK----->
SIP.PROPERTY8  AS ORDER_NO, <!-----OK----->
S.SHIP_NUMBER,<!-----OK----->
S.LOCATION_IN,<!-----OK----->
S.DEPARTMENT_IN,<!-----OK----->
SR.AMOUNT AS AMOUNT,<!-----OK----->
SR.AMOUNT2 AS AMOUNT2,<!-----OK----->
ST.PRODUCT_NAME,<!-----OK----->
ST.PRODUCT_CODE_2,<!-----OK----->
C.MEMBER_CODE,<!-----OK----->
C.NICKNAME,<!-----OK----->
C.COMPANY_ID,
S.REF_NO AS SHIP_REF_NO,<!-----OK----->
S.SHIP_DETAIL,
ST.STOCK_ID,
S.SHIP_ID,
S.RECORD_DATE,
#getPeriods.PERIOD_ID# as PERIOD
FROM catalyst_prod_#getPeriods.PERIOD_YEAR#_1.SHIP_INFO_PLUS AS SIP
LEFT JOIN catalyst_prod_#getPeriods.PERIOD_YEAR#_1.SHIP AS S ON SIP.SHIP_ID=S.SHIP_ID
LEFT JOIN catalyst_prod_#getPeriods.PERIOD_YEAR#_1.SHIP_ROW AS SR ON  SR.SHIP_ID=S.SHIP_ID
LEFT JOIN #dsn3#.STOCKS AS ST ON SR.STOCK_ID=ST.STOCK_ID
LEFT JOIN catalyst_prod.COMPANY AS C ON C.COMPANY_ID=S.COMPANY_ID
LEFT JOIN #dsn3#.SETUP_PROD_RETURN_CATS AS PRTC ON PRTC.RETURN_CAT_ID=CONVERT(INT,SIP.PROPERTY4)
<cfif currentrow neq getPeriods.recordcount> UNION</cfif>
    </cfloop>
) AS TBL
WHERE TBL.LOCATION_IN=6 AND TBL.DEPARTMENT_IN=4
<cfif len(arguments.ships_id)>AND TBL.SHIP_ID=#arguments.ships_id#</cfif>
ORDER BY RECORD_DATE DESC
</cfquery>
    <cfset arr=arrayNew(1)>
    <cfloop query="getirs">
    <cfquery name="is_haveOrd" datasource="#dsn#_1">
        SELECT ISNULL(SUM(QUANTITY),0) AS PARTIED,
        count(*) AS  PARTI_SAYISI
        FROM #dsn3#.ORDER_ROW
        WHERE ORDER_ID IN (
                SELECT ORDER_ID
                FROM #dsn3#.ORDER_TO_SHIP_PRT
                WHERE SHIP_ID = #SHIP_ID#
                    AND PERIOD_ID = #PERIOD#
                )
            AND STOCK_ID IN (
                SELECT STOCK_ID
                FROM #dsn3#.STOCKS
                WHERE COMPANY_ID = #COMPANY_ID#
                    AND IS_PRODUCTION = 1
                )
    </cfquery>
    <cfscript>
        item=structNew();
        item.NICKNAME=NICKNAME;
        item.AMOUNT2=AMOUNT2;
        item.RECORD_DATE=dateformat(RECORD_DATE,"dd/mm/yyyy");
        item.NAME_PRODUCT=PRODUCT_NAME;
        item.SHIP_NUMBER=SHIP_NUMBER;
        item.AMOUNT=AMOUNT;
        item.SHIP_ID=SHIP_ID;
        item.GR_MTUL=GR_MTUL;
        item.UCRET_DUR=UCRET_DUR;
        item.KUMAS_DUR=KUMAS_DUR;
        item.EVRAK_NO2=EVRAK_NO2;
        item.IADE_NEDEN=IADE_NEDEN;
        item.IADE_NEDEN_ID=IADE_NEDEN_ID;
        item.TOP_ADET=TOP_ADET;
        item.PARTIED_AMOUNT=is_haveOrd.PARTIED;
        if(is_haveOrd.PARTIED eq 0){
            item.PARTY_STATUS="Partilenecek";
        }else if(is_haveOrd.PARTIED lt AMOUNT){
            item.PARTY_STATUS="Eksik Parti";
        }else if(is_haveOrd.PARTIED gte AMOUNT){
            item.PARTY_STATUS="Partilendi";
        }
        item.REMAINING_AMOUNT=AMOUNT-is_haveOrd.PARTIED;
        item.H_GRAM=H_GRAM;
        item.PARTI_SAYISI=is_haveOrd.PARTI_SAYISI;
        item.ORDER_NO=ORDER_NO;
        item.PRODUCT_CODE_2=PRODUCT_CODE_2;
        item.MEMBER_CODE=MEMBER_CODE;
        item.SHIP_REF_NO=SHIP_REF_NO;
        item.SHIP_DETAIL=SHIP_DETAIL;
        item.PERIOD_ID=PERIOD;
        arrayAppend(arr, item);
    </cfscript>
    </cfloop>

     <cfreturn Replace(SerializeJSON(arr),'//','')>

</cffunction>
<cffunction name="getRelatedParties" access="remote" returntype="any" returnFormat="json">3
<cfargument  name="SHIP_ID" default="">
<cfargument  name="PERIOD_ID" default="">
<cfquery name="getRelorders" datasource="#dsn#_1">
    SELECT ORDER_ID FROM #dsn3#.ORDER_TO_SHIP_PRT WHERE 1=1 <cfif len(arguments.SHIP_ID)>AND SHIP_ID=#arguments.SHIP_ID# AND PERIOD_ID=#arguments.PERIOD_ID#</cfif>
</cfquery>
<cfif getRelorders.recordcount>
<cfset ORDER_ID_LIST = valueList(getRelorders.ORDER_ID)>
<cfelse>
<cfset ORDER_ID_LIST=0>
</cfif>
<cfquery name="getRelRows" datasource="#dsn#_1">
    SELECT ORR.QUANTITY,ORR.AMOUNT2,ORDER_NUMBER,ORR.PRODUCT_NAME2,PTR.STAGE,S.STOCK_CODE_2,ORR.ORDER_ROW_CURRENCY,ORR.ORDER_ROW_ID,O.RECORD_DATE 
    FROM #dsn3#.ORDERS AS O 
    LEFT JOIN #dsn3#.ORDER_ROW AS ORR ON ORR.ORDER_ID=O.ORDER_ID 
    LEFT JOIN #dsn3#.STOCKS AS S ON S.STOCK_ID=ORR.STOCK_ID
    LEFT JOIN catalyst_prod.PROCESS_TYPE_ROWS as PTR ON PTR.PROCESS_ROW_ID=O.ORDER_STAGE
    WHERE 1=1  
    AND ORR.ORDER_ROW_CURRENCY IN(-5,-1)
    AND ORR.ORDER_ID IN(#ORDER_ID_LIST#)
   -- AND S.IS_PRODUCTION=1
</cfquery>
<cfset retArr=arrayNew(1)>
<cfif getRelRows.recordcount>
<cfloop query="getRelRows">
    <cfscript>
        item=structNew();
        item.AMOUNT=QUANTITY;
        item.AMOUNT2=AMOUNT2;
        item.ORDER_NUMBER=ORDER_NUMBER;
        item.PRODUCT_NAME2=PRODUCT_NAME2;
        item.STAGE=STAGE;
        item.STOCK_CODE_2=STOCK_CODE_2;
        item.RECORD_DATE=RECORD_DATE;
        item.ORDER_ROW_ID=ORDER_ROW_ID;
        arrayAppend(retArr, item)
    </cfscript>
</cfloop>
<cfelse>
    <cfscript>
        item=structNew();
        item.AMOUNT="";
        item.AMOUNT2="";
        item.ORDER_NUMBER="";
        item.PRODUCT_NAME2="";
        item.STAGE="";
        item.STOCK_CODE_2="";
        item.RECORD_DATE="";
        item.ORDER_ROW_ID=0;
      //  arrayAppend(retArr, item)
    </cfscript>
</cfif>
<cfreturn Replace(SerializeJSON(retArr),'//','')>
</cffunction>

<cffunction name="getShipinfa" access="remote" returntype="any" returnFormat="json">
<cfargument  name="ship_id" default="0">
<cfargument  name="period_id" default="0">
<cfquery name="getOrd" datasource="#dsn#">
SELECT S.SHIP_NUMBER,ORR.AMOUNT FROM #dsn3#.ORDER_TO_SHIP_PRT AS OSP
LEFT JOIN catalyst_prod_2021_1.SHIP AS S ON OSP.SHIP_ID=S.SHIP_ID
LEFT JOIN #dsn3#.ORDERS AS O ON OSP.ORDER_ID=O.ORDER_ID
LEFT JOIN #dsn3#.ORDER_ROW AS ORR ON O.ORDER_ID=ORR.ORDER_ID
WHERE OSP.SHIP_ID=#arguments.ship_id# AND OSP.PERIOD_ID=#arguments.period_id#
</cfquery>
<cfset arr=arrayNew(1)>
<cfloop query="getOrd">
<cfscript>
item=structNew();
item.kazan=currentrow;
item.parti_kod=SHIP_NUMBER;
item.metre=0;
</cfscript>
</cfloop>

</cffunction>
<cffunction name="getShipinf" access="remote" returntype="any" returnFormat="json">
<cfquery name="getSh" datasource="#dsn#">
</cfquery>
</cffunction>
<cffunction  name="getCompany" access="remote" returntype="any" returnFormat="json">
<cfargument  name="company_name">

<cfquery name="getComp" datasource="catalyst_prod">
    SELECT FULLNAME,C.MEMBER_CODE,C.COMPANY_ID,CP.COMPANY_PARTNER_NAME+' '+CP.COMPANY_PARTNER_SURNAME AS COMPANY_PARTNER,CP.PARTNER_ID FROM catalyst_prod.COMPANY AS C 
    LEFT JOIN catalyst_prod.COMPANY_PARTNER AS CP ON C.COMPANY_ID=CP.COMPANY_ID WHERE 1=1 <cfif len(arguments.company_name)>and C.FULLNAME LIKE  '%#arguments.company_name#%'</cfif>
</cfquery>
<cfset arr=arrayNew(1)>

<cfloop query="getComp">
  <cfscript>
    item=structNew();
    item.FULLNAME=FULLNAME;
    item.COMPANY_CODE=MEMBER_CODE;
    item.COMPANY_ID=COMPANY_ID;
    item.PARTNER_ID=PARTNER_ID;
    item.COMPANY_PARTNER=COMPANY_PARTNER;
    arrayAppend(arr, item)
    </cfscript>
</cfloop>
 <cfreturn Replace(SerializeJSON(arr),'//','')>
</cffunction>
<cffunction  name="saveTree" access="remote" returntype="any" returnFormat="json">
  <!---<cfset deneme = deserializeJSON(arguments)>----->
    <cfdump  var="#arguments#">
    <cfset aaa=StructKeyList(arguments)>
    <cfdump  var="#aaa#">
    <cfset bbb=deserializeJSON(aaa)>
    <cfdump  var="#bbb#">
     <cfreturn Replace(SerializeJSON(aaa),'//','')>
</cffunction>
<cffunction  name="save_bookmark" access="remote" returntype="any" returnFormat="json">
  <!---<cfset deneme = deserializeJSON(arguments)>----->
    <cfdump  var="#arguments#">
   <cfquery name="insB" datasource="#dsn#">
        INSERT INTO BOYAHANE_SHORTCUTS_EMPLOYEE (SHORCUT_NAME,SHORTCUT_URL,IS_BLANK,EMPLOYEE_ID) 
        VALUES ('#arguments.bookmark#','#mid(arguments.bookmark_url,2,len(arguments.bookmark_url))#',<cfif isDefined("arguments.is_new_page")>1<cfelse>0</cfif>,#session.ep.userid#)
   </cfquery>
     <cfreturn Replace(SerializeJSON(arguments),'//','')>
</cffunction>
<cffunction name="getProdTreeWithName" access="remote" returntype="any" returnFormat="json">
    <cfargument  name="keyword" default="">
    <cfset retArr=arrayNew(1)>
    <cfif len(arguments.keyword)>
        <cfquery name="getstok" datasource="#dsn#_1">
            SELECT DISTINCT S.PRODUCT_NAME
                    ,S.STOCK_ID
                    ,PRODUCT_CODE                   
                    ,PU.MAIN_UNIT
                    ,S.PRODUCT_UNIT_ID FROM STOCKS AS S 
            LEFT JOIN catalyst_prod_product.PRODUCT_UNIT AS PU ON PU.PRODUCT_UNIT_ID = S.PRODUCT_UNIT_ID 
            WHERE 1=1 and( PRODUCT_NAME like '%#arguments.keyword#%' or PRODUCT_CODE like '%#arguments.keyword#%' )
        </cfquery>
        <cfloop query="getstok">
            <cfquery name="getTree" datasource="#dsn#_1">
                SELECT S.PRODUCT_NAME
                    ,S.STOCK_ID
                    ,PT.AMOUNT
                    ,PRODUCT_CODE
                    ,PU.MAIN_UNIT
                    ,S.PRODUCT_NAME
                    ,S.PRODUCT_UNIT_ID
                FROM #dsn3#.PRODUCT_TREE AS PT
                LEFT JOIN #dsn3#.STOCKS AS S ON S.STOCK_ID = PT.RELATED_ID
                LEFT JOIN catalyst_prod_product.PRODUCT_UNIT AS PU ON PU.PRODUCT_UNIT_ID = S.PRODUCT_UNIT_ID
                WHERE PT.STOCK_ID = #STOCK_ID#
            </cfquery>
            <cfscript>
                item=structNew();
               //item.STOCK_ID=STOCK_ID;
                 item.PRODUCT_CODE=PRODUCT_CODE;
                 item.AMOUNT=1;
               // item.PRODUCT_NAME=PRODUCT_NAME;
                 item.MAIN_UNIT=MAIN_UNIT;
                    
                    item.id=STOCK_ID;
                    item.name=PRODUCT_NAME;
                    if(getTree.recordcount){
                     item.icon='activefolder';
                     item.isDirectory=true;
                     }else{
                         item.icon='file';
                          item.isDirectory=false;
                     }
                    item.expanded=true;
                item.PRODUCT_UNIT_ID=PRODUCT_UNIT_ID;
                 arrayAppend(retArr, item);
            </cfscript>
            
            <CFSET TREEARR=arrayNew(1)>
            <cfloop query="getTree">
            <cfscript>
                 Bitem=structNew();
                // Bitem.STOCK_ID=STOCK_ID;
                 Bitem.PRODUCT_CODE=PRODUCT_CODE;
                // Bitem.PRODUCT_NAME=PRODUCT_NAME;
                 Bitem.MAIN_UNIT=MAIN_UNIT;
                 bitem.AMOUNT=getTree.AMOUNT;
                 Bitem.parentId=getstok.STOCK_ID;
                Bitem.isDirectory=false;
                Bitem.id=getTree.STOCK_ID;
                Bitem.name=getTree.PRODUCT_NAME;
                Bitem.icon='file';
               Bitem.expanded=true;
                 Bitem.PRODUCT_UNIT_ID=PRODUCT_UNIT_ID;
           
             arrayAppend(retArr, Bitem);
            </cfscript>
         
            </cfloop>
              
            <cfscript>
           

            </cfscript>
        </cfloop>
        <cfreturn Replace(SerializeJSON(retArr),'//','')>
    </cfif>
</cffunction>
<cffunction name="getProdTreeWithName_arr" access="remote" returntype="any" returnFormat="json">
    <cfargument  name="keyword" default="">
    <cfargument  name="stock_id" default="">
    <cfquery name="getstok" datasource="#dsn#_1">
        SELECT DISTINCT S.PRODUCT_NAME
        ,S.STOCK_ID
        ,PRODUCT_CODE                   
        ,PU.MAIN_UNIT
                            ,CASE WHEN PRODUCT_CODE LIKE '150.01%' THEN '0'
 WHEN PRODUCT_CODE LIKE '150.02%' THEN '1'
 WHEN PRODUCT_CODE LIKE '150.03%' THEN '2'
 end as tip
        ,S.PRODUCT_UNIT_ID FROM STOCKS AS S 
        LEFT JOIN catalyst_prod_product.PRODUCT_UNIT AS PU ON PU.PRODUCT_UNIT_ID = S.PRODUCT_UNIT_ID 
        WHERE 1=1 <cfif len(arguments.keyword)>and( PRODUCT_NAME like '%#arguments.keyword#%' or PRODUCT_CODE like '%#arguments.keyword#%' )</cfif>
        <cfif len(arguments.stock_id)>and S.STOCK_ID=#arguments.stock_id#</cfif>
    </cfquery>
    <cfset RETURN_ARRAY = arrayNew(1)>
    <cfloop query="getstok">
        <cfquery name="getTree" datasource="#dsn#_1">
            SELECT S.PRODUCT_NAME
            ,S.STOCK_ID
            ,PT.AMOUNT
            ,PRODUCT_CODE
            ,PU.MAIN_UNIT
            ,S.PRODUCT_NAME
            ,S.PRODUCT_UNIT_ID
                                ,CASE WHEN PRODUCT_CODE LIKE '150.01%' THEN '0'
 WHEN PRODUCT_CODE LIKE '150.02%' THEN '1'
 WHEN PRODUCT_CODE LIKE '150.03%' THEN '2'
 end as tip
            FROM #dsn3#.PRODUCT_TREE AS PT
            LEFT JOIN #dsn3#.STOCKS AS S ON S.STOCK_ID = PT.RELATED_ID
            LEFT JOIN catalyst_prod_product.PRODUCT_UNIT AS PU ON PU.PRODUCT_UNIT_ID = S.PRODUCT_UNIT_ID
            WHERE PT.STOCK_ID = #STOCK_ID#
        </cfquery>  
        <CFSET TREE_LEVEL_1=arrayNew(1)>          
        <cfif getTree.recordcount>
            <cfloop query="getTree">                    
                <cfquery name="getTreelvl2" datasource="#dsn#_1">
                    SELECT S.PRODUCT_NAME
                    ,S.STOCK_ID
                    ,PT.AMOUNT
                    ,PRODUCT_CODE
                    ,PU.MAIN_UNIT
                    ,S.PRODUCT_NAME
                    ,S.PRODUCT_UNIT_ID
                    ,CASE WHEN PRODUCT_CODE LIKE '150.01%' THEN '0'
 WHEN PRODUCT_CODE LIKE '150.02%' THEN '1'
 WHEN PRODUCT_CODE LIKE '150.03%' THEN '2'
 end as tip
                    FROM #dsn3#.PRODUCT_TREE AS PT
                    LEFT JOIN #dsn3#.STOCKS AS S ON S.STOCK_ID = PT.RELATED_ID
                    LEFT JOIN catalyst_prod_product.PRODUCT_UNIT AS PU ON PU.PRODUCT_UNIT_ID = S.PRODUCT_UNIT_ID
                    WHERE PT.STOCK_ID = #getTree.STOCK_ID#
                </cfquery>
                <CFSET TREE_LEVEL_2=arrayNew(1)>  
                <cfif getTreelvl2.recordcount>
                    <cfloop query="getTreelvl2">
                        <cfquery name="getTreelvl3" datasource="#dsn#_1">
                            SELECT S.PRODUCT_NAME
                            ,S.STOCK_ID
                            ,PT.AMOUNT
                            ,PRODUCT_CODE
                            ,PU.MAIN_UNIT                                
                            ,S.PRODUCT_UNIT_ID
                                                ,CASE WHEN PRODUCT_CODE LIKE '150.01%' THEN '0'
 WHEN PRODUCT_CODE LIKE '150.02%' THEN '1'
 WHEN PRODUCT_CODE LIKE '150.03%' THEN '2'
 end as tip
                            FROM #dsn3#.PRODUCT_TREE AS PT
                            LEFT JOIN #dsn3#.STOCKS AS S ON S.STOCK_ID = PT.RELATED_ID
                            LEFT JOIN catalyst_prod_product.PRODUCT_UNIT AS PU ON PU.PRODUCT_UNIT_ID = S.PRODUCT_UNIT_ID
                            WHERE PT.STOCK_ID = #getTreelvl2.STOCK_ID#
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
                                    item.AMOUNT=getTreelvl3.AMOUNT;
                                    item.tip=getTreelvl3.tip;
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
                            item2.tip=getTreelvl2.tip;
                            item2.AMOUNT=getTreelvl2.AMOUNT;
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
                    item3.tip=getTree.tip;
                    item3.MAIN_UNIT=getTree.MAIN_UNIT;
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
            item4.STOCK_ID=STOCK_ID;
            item4.PRODUCT_UNIT_ID=PRODUCT_UNIT_ID;
            item4.PRODUCT_CODE=PRODUCT_CODE;
            item4.MAIN_UNIT=MAIN_UNIT;
            item4.tip=tip;
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
<!----<cfdump  var="#retArr#">----->
<cfreturn Replace(SerializeJSON(RETURN_ARRAY),'//','')>

</cffunction>
<cffunction  name="get_comp_kumas" access="remote" returntype="any" returnFormat="json">
<cfargument  name="company_id">
<cfquery name="company_products" datasource="catalyst_prod">
    select STOCK_CODE AS PRODUCT_CODE,ISNULL(STOCK_CODE_2,'')+' '+PRODUCT_NAME AS PRODUCT_NAME,PRODUCT_ID,STOCK_ID,IS_INVENTORY from #dsn3#.STOCKS where COMPANY_ID =#arguments.company_id# AND IS_MAIN_STOCK=1
</cfquery>
<cfset arr=arrayNew(1)>

<cfloop query="company_products">
  <cfscript>
    item=structNew();
    item.PRODUCT_CODE=PRODUCT_CODE;
    item.PRODUCT_NAME=PRODUCT_NAME;
    item.PRODUCT_ID=PRODUCT_ID;
    item.STOCK_ID=STOCK_ID;
    item.IS_INVENTORY=IS_INVENTORY;
    arrayAppend(arr, item)
    </cfscript>
</cfloop>
<cfreturn Replace(SerializeJSON(arr),'//','')>
</cffunction>
<cffunction name="getProdTreeWithName_yeni" access="remote" returntype="any" returnFormat="json">
    <cfargument  name="keyword" default="">
    <cfargument  name="stock_id" default="">
    <cfinclude  template="aga_ret.cfm">
    <cfreturn Replace(SerializeJSON(RETURN_ARRAY),'//','')>
</cffunction>
<cffunction  name="AgacKayitEt"  access="remote" returntype="any" returnFormat="json">
     
     
<cfset aaa=StructKeyList(arguments)>

<cfset Agac=deserializeJSON(aaa)>
<cfset q=queryNew("STOCK_ID,ORDER,AMOUNT","varchar,varchar,varchar")>
<cfloop array="#Agac#" item="agacitem">
<cfscript>
    item=structNew();
    item.STOCK_ID="";
</cfscript>

<cfdump  var="#Seviye_1#">
</cfloop>
</cffunction>
<cffunction  name="getKumaslarIrs"  access="remote" returntype="any" returnFormat="json">
<cfargument  name="att_ship_id">
<cfargument  name="att_period_id">
<cfquery name="getCompPeriod" datasource="#dsn#">
   SELECT PERIOD_YEAR,OUR_COMPANY_ID FROM catalyst_prod.SETUP_PERIOD WHERE PERIOD_ID=#arguments.att_period_id#
</cfquery>
<cfquery name="getShip" datasource="#dsn#_#getCompPeriod.PERIOD_YEAR#_#getCompPeriod.OUR_COMPANY_ID#">
    SELECT * FROM #dsn#_#getCompPeriod.PERIOD_YEAR#_#getCompPeriod.OUR_COMPANY_ID#.SHIP_ROW where SHIP_ID =#arguments.att_ship_id#
</cfquery>
<cfquery name="getRenks" datasource="#dsn#_#getCompPeriod.OUR_COMPANY_ID#">
    SELECT STOCK_CODE_2,STOCK_ID,PROPERTY FROM STOCKS WHERE PRODUCT_ID=#getShip.PRODUCT_ID# AND (IS_MAIN_STOCK IS NULL  OR IS_MAIN_STOCK=0)
</cfquery>


<cfset arr=arrayNew(1)>
<cfloop query="getRenks">
<cfscript>
    item=structNew();
    item.STOCK_CODE_2=STOCK_CODE_2;
    item.STOCK_ID=STOCK_ID;
    item.PROPERTY=PROPERTY;
    arrayAppend(arr, item)
</cfscript>
</cfloop>
<cfreturn Replace(SerializeJSON(arr),'//','')>
</cffunction>
<cffunction  name="get_product_Cat" access="remote" returntype="any" returnFormat="json">
<cfargument  name="keyword">

<cfquery name="getComp" datasource="catalyst_prod">
    SELECT PRODUCT_CATID,HIERARCHY,PRODUCT_CAT 
    FROM #dsn3#.PRODUCT_CAT WHERE 1 = 1 AND (HIERARCHY LIKE '%#arguments.keyword#%' OR PRODUCT_CAT LIKE '%#arguments.keyword#%')
</cfquery>
<cfset arr=arrayNew(1)>

<cfloop query="getComp">
  <cfscript>
    item=structNew();
    item.PRODUCT_CAT=PRODUCT_CAT;
    item.HIERARCHY=HIERARCHY;
    item.PRODUCT_CATID=PRODUCT_CATID;
  //  item.PARTNER_ID=PARTNER_ID;
    //item.COMPANY_PARTNER=COMPANY_PARTNER;
    arrayAppend(arr, item)
    </cfscript>
</cfloop>
 <cfreturn Replace(SerializeJSON(arr),'//','')>
</cffunction>
<cffunction  name="wrk_query" access="remote" returntype="any" returnFormat="json">

<cfquery name="getT" datasource="#evaluate(arguments.datas)#" result="res">
    #PreserveSingleQuotes(arguments.query_)#
</cfquery>
<cfset jsquery=structNew()>
<cfset jsquery.recordcount=res.recordcount>

<cfset jsquery.COLUMNLIST=res.COLUMNLIST>
<cfloop list="#res.COLUMNLIST#" item="li">
<cfset mya = arrayNew(1)>
<cfloop query="getT">
    <cfscript>
        arrayAppend(mya, evaluate("getT.#li#"));
    </cfscript>
</cfloop>
<cfset "jsquery.#li#"=mya>
</cfloop>

<cfreturn Replace(SerializeJSON(jsquery),'//','')>
</cffunction>
<cffunction   name="saveProduct"  access="remote" returntype="any" returnFormat="json">
<cfdump  var="#arguments#">
<cfset JSONDATA=structKeyList(arguments)>
<cfset KayitVeri=deserializeJSON(JSONDATA)>
<cfset attributes.hierarchy=KayitVeri.Hiearchy>
<cfset uye_kodu=KayitVeri.CompanyCode>
<cfset urun_adi="#KayitVeri.Product_Cat# #KayitVeri.BrandName#">
<cfset detail="">
<cfset detail_2="">
<cfset satis_kdv=18>
<cfset alis_kdv=18>
<cfset is_inventory=1>
<cfset is_production=1>
<cfset is_sales=1>
<cfset is_sales=1>
<cfset is_purchase="">
<cfset is_internet="">
<cfset is_extranet="">
<cfset surec_id="65">
<cfset birim="KG">
<cfset is_zero_stock="">
<cfset fiyat_yetkisi="">
<cfset uretici_urun_kodu="">
<cfset brand_id="#KayitVeri.BrandId#">
<cfset short_code_id="">
<cfset product_code_2="">
<cfset is_limited_stock="">
<cfset is_quality="">
<cfset min_margin="">
<cfset max_margin="">
<cfset shelf_life="">
<cfset segment_id="">
<cfset bsmv="">
<cfset dimention="">
<cfset volume="">
<cfset weight="">
<cfset alis_fiyat_kdvsiz="">
<cfset alis_fiyat_kdvli="">
<cfset purchase_money="">
<cfset satis_fiyat_kdvli="">
<cfset satis_fiyat_kdvsiz="">
<cfset sales_money="">
<cfset kategori_id="#KayitVeri.CatId#">
<cfset oiv="">
<cfset En=KayitVeri.En>
<cfset Tuse=KayitVeri.Tuse>
<cfset Cekme=KayitVeri.Cekme>
<cfset Gramaj=KayitVeri.Gramaj>
<cfset Isi=KayitVeri.Isi>
<cfset Hiz=KayitVeri.Hiz>
<cfset Besleme=KayitVeri.Besleme>
<cfset Kimyasal=KayitVeri.Kimyasal>
<cfset BirimCarpan=KayitVeri.BirimCarpan>
<cfset MuhStockCode=KayitVeri.MuhStockCode>

<cfinclude  template="/Modules/kumas/query/add_import_product.cfm">
<cfinclude  template="/Modules/kumas/query/insertProductInfoPlus.cfm">

<cfreturn Replace(SerializeJSON(arguments),'//','')>
</cffunction>
<cffunction  name="getKumasLAR" access="remote" returntype="any" returnFormat="json">
<cfquery name="getList" datasource="#dsn#">
    SELECT S.PRODUCT_CODE,C.FULLNAME,S.STOCK_ID,S.PRODUCT_ID,PRODUCT_NAME,PB.BRAND_NAME,PC.PRODUCT_CAT FROM #dsn3#.STOCKS AS S 
    LEFT JOIN catalyst_prod.COMPANY AS C ON S.COMPANY_ID=C.COMPANY_ID
    LEFT JOIN catalyst_prod_product.PRODUCT_BRANDS as PB ON PB.BRAND_ID=S.BRAND_ID
    LEFT JOIN catalyst_prod_product.PRODUCT_CAT AS PC ON PC.PRODUCT_CATID=S.PRODUCT_CATID
    WHERE IS_MAIN_STOCK =1
</cfquery>
<cfset ReturnArray=arrayNew(1)>
<cfloop query="getList">
<cfscript>
    item=structNew();
    item.PRODUCT_CODE=PRODUCT_CODE;
    item.PRODUCT_NAME=PRODUCT_NAME;
    item.BRAND_NAME=BRAND_NAME;
    item.PRODUCT_ID=PRODUCT_ID;
    item.PRODUCT_CAT=PRODUCT_CAT;
    arrayAppend(ReturnArray, item);
</cfscript>
</cfloop>

<cfreturn Replace(SerializeJSON(ReturnArray),'//','')>
</cffunction>

<cffunction  name="getWorkList" access="remote" returntype="any" returnFormat="json">
<cfargument  name="work_type">
<cfquery name="getList" datasource="#dsn#">
  SELECT O.ORDER_HEAD,O.ORDER_ID,SPC.STAGE,ORR.STOCK_ID,ORR.ORDER_ROW_CURRENCY,S.STOCK_CODE,S.PRODUCT_NAME,s.STOCK_CODE_2,s.PROPERTY,ORR.ORDER_ROW_ID,ORR.QUANTITY FROM #dsn3#.ORDERS as O
LEFT JOIN catalyst_prod.PROCESS_TYPE_ROWS AS SPC ON SPC.PROCESS_ROW_ID=O.ORDER_STAGE
LEFT JOIN #dsn3#.ORDER_ROW AS ORR ON ORR.ORDER_ID=O.ORDER_ID
LEFT JOIN #dsn3#.STOCKS AS S ON S.STOCK_ID=ORR.STOCK_ID
WHERE 1=1 <cfif argumentS.work_type neq 0>AND ORDER_STAGE=#arguments.work_type#</cfif>
AND S.IS_PRODUCTION=1
</cfquery>
<cfset ReturnArray=arrayNew(1)>
<cfloop query="getList">
<cfscript>
    item=structNew();
    item.PARTI_KODU=ORDER_HEAD;
    item.AMOUNT=QUANTITY;
    item.ORDER_ROW_ID="#ORDER_ROW_ID#";
    item.PRODUCT_NAME="#STOCK_CODE_2# #PROPERTY#";
    item.ORDER_ID=ORDER_ID;
    item.STAGE=STAGE;    
    arrayAppend(ReturnArray, item);
</cfscript>
</cfloop>

<cfreturn Replace(SerializeJSON(ReturnArray),'//','')>
</cffunction>
<cffunction  name="getWorkStations"  access="remote" returntype="any" returnFormat="json">
<cfargument  name="UpStationId" default="1">
<cfquery name="getWs" datasource="#dsn#">
    SELECT STATION_ID,STATION_NAME FROM #dsn3#.WORKSTATIONS WHERE UP_STATION=#arguments.UpStationId#
</cfquery> 
<cfset ReturnArray=arrayNew(1)>
<cfloop query="getWs">
<cfscript>
    item=structNew();
    item.STATION_ID=STATION_ID;    
    item.STATION_NAME=STATION_NAME;
     
    arrayAppend(ReturnArray, item);
</cfscript>
</cfloop>

<cfreturn Replace(SerializeJSON(ReturnArray),'//','')>
</cffunction>
<cffunction  name="getMessages"  access="remote" returntype="any" returnFormat="json">
<cfargument  name="user_id" default="1">
<cfquery name="getM" datasource="#dsn#">
select top 1 BOYAHANE_MESSAGES.*,E.EMPLOYEE_NAME,E.EMPLOYEE_SURNAME,E.PHOTO
from catalyst_prod.BOYAHANE_MESSAGES 
LEFT JOIN catalyst_prod.EMPLOYEES AS E ON E.EMPLOYEE_ID=FROM_USER_ID
WHERE IS_READ=0 AND TO_USER_ID=177 order by MESSAGE_DATE desc
</cfquery>

<cfset ReturnArray=arrayNew(1)>
<cfloop query="getM">

<cfscript>
    a_message={
        _message_date=MESSAGE_DATE,
        _message_text=MESSAGE_TEXT,
        _message_from="#EMPLOYEE_NAME# #EMPLOYEE_SURNAME#",
        _photo=PHOTO
    };
    arrayAppend(ReturnArray, a_message);
</cfscript>
</cfloop>
<cfset returnValues.message_count=arrayLen(ReturnArray)>
<cfset returnValues.messages=ReturnArray>
<!----<cfquery name="getWs" datasource="#dsn#">
    SELECT STATION_ID,STATION_NAME FROM #dsn3#.WORKSTATIONS WHERE UP_STATION=#arguments.UpStationId#
</cfquery> 
<cfset ReturnArray=arrayNew(1)>
<cfloop query="getWs">
<cfscript>
    item=structNew();
    item.STATION_ID=STATION_ID;    
    item.STATION_NAME=STATION_NAME;
     
    arrayAppend(ReturnArray, item);
</cfscript>
</cfloop>
----->
<cfreturn Replace(SerializeJSON(returnValues),'//','')>
</cffunction>
<cffunction  name="getWorks"  access="remote" returntype="any" returnFormat="json">
<cfargument  name="work_start_date" >
<cfargument  name="work_end_date" >
<cfargument  name="up_station_id">
<cfif not len(arguments.work_start_date)><cfset arguments.work_start_date=dateAdd("d", -30, now())></cfif>
<cfif not len(arguments.work_end_date)><cfset arguments.work_end_date=dateAdd("d", 1, now())></cfif>

<cfset current_start_date=createODBCDateTime(arguments.work_start_date)>
<cfset current_end_date=createODBCDateTime(arguments.work_end_date)>

<cfquery name="getWs" datasource="#dsn#">
 SELECT  PO.STATION_ID,PO.SPECT_VAR_NAME,PO.P_ORDER_ID,PO.P_ORDER_NO,PO.START_DATE,FINISH_DATE,PO.PARTNER_WORK_STAGE,C.NICKNAME ,S.PROPERTY,S.STOCK_CODE_2,PO.IS_COLLECTED
FROM #dsn3#.PRODUCTION_ORDERS AS PO
LEFT JOIN #dsn3#.PRODUCTION_ORDERS_ROW AS POR ON PO.P_ORDER_ID=POR.PRODUCTION_ORDER_ID
LEFT JOIN #dsn3#.ORDERS AS O ON O.ORDER_ID=POR.ORDER_ID
LEFT JOIN catalyst_prod.COMPANY AS C ON C.COMPANY_ID=O.COMPANY_ID
LEFT JOIN #dsn3#.STOCKS AS S ON S.STOCK_ID=PO.STOCK_ID
    WHERE PO.START_DATE >=#current_start_date # and  PO.FINISH_DATE<=#current_end_date#  and po.STATION_ID IN(SELECT STATION_ID FROM #dsn3#.WORKSTATIONS WHERE UP_STATION=#arguments.up_station_id#)
</cfquery> 

<cfset ReturnArray=arrayNew(1)>
<cfloop query="getWs">
<cfscript>
    item=structNew();
    item.STATION_ID=STATION_ID;    
    item.SPECT_VAR_NAME=SPECT_VAR_NAME;
    item.P_ORDER_ID=P_ORDER_ID;
    item.P_ORDER_NO=P_ORDER_NO;
    item.START_DATE=START_DATE;
    item.FINISH_DATE=FINISH_DATE;
    item.PARTNER_WORK_STAGE=PARTNER_WORK_STAGE;
    item.NICKNAME=NICKNAME;
    item.PROPERTY=PROPERTY;
    item.IS_COLLECTED=IS_COLLECTED;
    arrayAppend(ReturnArray, item);
</cfscript>
</cfloop>

<cfreturn Replace(SerializeJSON(ReturnArray),'//','')>
</cffunction>
<cffunction name="UpdateProductionOrders" access="remote" returntype="any" returnFormat="json">
<cfset station_id_fi=listGetAt(arguments.station_id, 1)>
<cfset arguments.station_id_fi=station_id_fi>
<cfquery name="getWs" datasource="#dsn3#">
    SELECT COMMENT FROM WORKSTATIONS WHERE STATION_ID=#station_id_fi#
</cfquery>
<cfif listlen(getWs.COMMENT) gt 1 and listgetat(getWs.COMMENT,1,"-") eq "H">
<CFSET STG=59>
<CFELSE>
<CFSET STG=91>
</CFIF>
<cfquery name="getPOrder" datasource="#dsn3#">
    SELECT * FROM PRODUCTION_ORDERS WHERE P_ORDER_ID=#ARGUMENTS.p_order_id#
</cfquery>

<CFSET CALISMA_ZAMAN=dateDiff("n", getPOrder.START_DATE, getPOrder.FINISH_DATE)>
<cfset arguments.CALISMA_ZAMAN=CALISMA_ZAMAN>

<cfset WorkStart=createDateTime(year(now()), month(now()), day(now()), arguments.start_HOUR, arguments.start_MINUTE, 0)>
<cfset WorkEnd=dateAdd("n", CALISMA_ZAMAN, WorkStart)>
<cfset arguments.WorkStart=WorkStart>
<cfset arguments.WorkEnd=WorkEnd>
<cfquery name="updOrder" datasource="#dsn3#">
    UPDATE PRODUCTION_ORDERS SET PROD_ORDER_STAGE=#STG#, START_DATE=#WorkStart#,FINISH_DATE=#WorkEnd#,IS_URGENT=#ARGUMENTS.acil#,STATION_ID=#listGetAt(arguments.station_id, 1)#
    WHERE P_ORDER_ID=#ARGUMENTS.p_order_id#
</cfquery>
<cfquery NAME="GETSARFS" DATASOURCE="#DSN3#">
SELECT POS.AMOUNT AS AM1
	,POS.POR_STOCK_ID
	,POS.STOCK_ID
	,POS.PRTOTM_DETAIL
	,PO.STOCK_ID
	,SMR.AMOUNT
	,S.PRODUCT_CODE
FROM catalyst_prod_1.PRODUCTION_ORDERS_STOCKS AS POS
LEFT JOIN catalyst_prod_1.PRODUCTION_ORDERS AS PO ON PO.P_ORDER_ID = POS.P_ORDER_ID
LEFT JOIN catalyst_prod_1.STOCKS AS S ON S.STOCK_ID = POS.STOCK_ID
LEFT JOIN catalyst_prod_1.SPECT_MAIN_ROW AS SMR ON SMR.SPECT_MAIN_ROW_ID=POS.SPECT_MAIN_ROW_ID
--LEFT JOIN catalyst_prod_1.PRODUCT_TREE AS PT ON PT.STOCK_ID = PO.STOCK_ID
	--AND PT.DETAIL = POS.PRTOTM_DETAIL
	--AND PT.RELATED_ID = S.STOCK_ID
WHERE POS.P_ORDER_ID = #ARGUMENTS.p_order_id#
<!-----
select POS.AMOUNT AS AM1,POS.POR_STOCK_ID,POS.STOCK_ID,POS.PRTOTM_DETAIL,PO.STOCK_ID,PT.AMOUNT,S.PRODUCT_CODE from #dsn3#.PRODUCTION_ORDERS_STOCKS AS POS
LEFT JOIN #dsn3#.PRODUCTION_ORDERS AS PO ON PO.P_ORDER_ID=POS.P_ORDER_ID
LEFT JOIN #dsn3#.STOCKS AS S ON S.STOCK_ID=POS.STOCK_ID
LEFT JOIN #dsn3#.PRODUCT_TREE AS PT ON PT.STOCK_ID=PO.STOCK_ID AND PT.DETAIL=POS.PRTOTM_DETAIL AND PT.RELATED_ID=S.STOCK_ID
WHERE POS.P_ORDER_ID=#ARGUMENTS.p_order_id#------>
</cfquery>
    
<cfscript>
    obj={
        type:{
            pos="before",
            tip=0
        },
        ev:{
            P_ORDER_ID=arguments.p_order_id,
            endDate="#DATEADD('h',-2,arguments.WorkStart)#",
            startDate="#DATEADD('h',-2,arguments.WorkStart)#",
            STATION_ID=listGetAt(arguments.station_id, 1)
        }
    }
</cfscript>


<cfloop query="GETSARFS">
    <cfif findNoCase("150.02", PRODUCT_CODE)>
    <cfset NewSarf=AMOUNT*ARGUMENTS.plan_su>
    <CFSET "ARGUMENTS.S#listgetat(product_code,listlen(product_code,"."),".")#"=NewSarf>
   <cfquery NAME="UP" datasource="#dsn3#">
        UPDATE PRODUCTION_ORDERS_STOCKS SET AMOUNT=#NewSarf# WHERE POR_STOCK_ID=#POR_STOCK_ID#
    </cfquery>
    </cfif>
</cfloop>
    <cfif arguments.yikama eq 1>
<cfset attributes.data=Replace(SerializeJSON(obj),'//','')>
        <cfinclude  template="/Modules/objects/tests/test4.cfm">

    </cfif>

<cfreturn Replace(SerializeJSON(arguments),'//','')>
</cffunction>
<cffunction  name="getWorksWithStationGroup" access="remote" returntype="any" returnFormat="json">
<cfargument  name="up_station_id">
<cfquery name="getOrders" datasource="#dsn3#">
    SELECT O.ORDER_HEAD
        ,PO.P_ORDER_ID
        ,C.NICKNAME
        ,PO.QUANTITY
        ,POR.ORDER_ROW_ID
        ,S.PROPERTY
        ,O.ORDER_ID
        ,S.STOCK_ID
        ,S.PRODUCT_NAME
        ,POP.P_OPERATION_ID
        ,POP.OPERATION_TYPE_ID
        ,WS.STATION_NAME
        ,OT.OPERATION_TYPE
        ,PO.PROD_ORDER_STAGE
        ,PTR.STAGE
        ,PO.IS_COLLECTED
    FROM #dsn3#.PRODUCTION_ORDERS AS PO
    LEFT JOIN #dsn3#.PRODUCTION_ORDERS_ROW AS POR   ON PO.P_ORDER_ID = POR.PRODUCTION_ORDER_ID
    LEFT JOIN #dsn3#.ORDERS AS O ON O.ORDER_ID = POR.ORDER_ID
    LEFT JOIN #dsn3#.ORDER_ROW AS ORR ON ORR.ORDER_ROW_ID = POR.ORDER_ROW_ID
    LEFT JOIN catalyst_prod.COMPANY AS C ON C.COMPANY_ID = O.COMPANY_ID
    LEFT JOIN #dsn3#.PRODUCTION_OPERATION AS POP ON POP.P_ORDER_ID = PO.P_ORDER_ID
    LEFT JOIN #dsn3#.STOCKS AS S ON S.STOCK_ID = PO.STOCK_ID
    LEFT JOIN #dsn3#.WORKSTATIONS AS WS ON WS.STATION_ID = PO.STATION_ID
    LEFT JOIN #dsn3#.OPERATION_TYPES AS OT ON OT.OPERATION_TYPE_ID = POP.OPERATION_TYPE_ID
    LEFT JOIN catalyst_prod.PROCESS_TYPE_ROWS AS PTR ON PTR.PROCESS_ROW_ID = PO.PROD_ORDER_STAGE
	where PO.STATION_ID IN(SELECT STATION_ID FROM #dsn3#.WORKSTATIONS WHERE UP_STATION=#arguments.up_station_id#)
  --  AND PO.STATUS=1
</cfquery>
<cfset arr=arrayNew(1)>
<cfloop  query="getOrders" group="P_ORDER_ID">
<cfquery name="getB" datasource="#dsn3#">
    SELECT  o.ORDER_HEAD FROM #dsn3#.BOYAHANE_BIRLESEN  AS BB 
INNER JOIN #dsn3#.ORDERS AS O ON O.ORDER_ID =BB.ORDER_ID AND P_ORDER_ID=#P_ORDER_ID#
</cfquery>
<cfif getB.recordcount>
<cfset order_head_list=valueList(getB.ORDER_HEAD)>
<cfelse>
<cfset order_head_list=ORDER_HEAD>
</cfif>
<cfscript>
item=structNew();
item.ORDER_ID=ORDER_ID;
item.ORDER_ROW_ID=ORDER_ROW_ID;
item.P_ORDER_ID=P_ORDER_ID;
item.ORDER_HEAD=order_head_list;
item.NICKNAME=NICKNAME;
item.QUANTITY=QUANTITY;
item.STAGE=STAGE;
item.COLOR=PROPERTY;
item.PRODUCT_NAME=PRODUCT_NAME;
item.STOCK_ID=STOCK_ID;
item.IS_COLLECTED=IS_COLLECTED;
</cfscript>
<cfset tt=arrayNew(1)>
<cfloop>
    <cfscript>
    item2=structNew();
    item2.P_ORDER_ID=P_ORDER_ID;
    item2.OPERATION_TYPE=OPERATION_TYPE;
    item2.OPERATION_TYPE_ID=OPERATION_TYPE_ID;
    item2.P_OPERATION_ID=P_OPERATION_ID;
    item2.P_AMOUNT=QUANTITY;
    item2.ORDER_ID=ORDER_ID;
    item2.STOCK_ID=STOCK_ID;
    arrayAppend(tt, item2);    
    </cfscript>
</cfloop>
<cfscript>
item.Operations=tt;
arrayAppend(arr, item);
</cfscript>


</cfloop>

<cfreturn replace(serializeJSON(arr), "//", "")>
</cffunction>

</cfcomponent>

