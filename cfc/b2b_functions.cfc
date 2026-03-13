<cfcomponent>
<cfset dsn = application.systemParam.params().dsn>
    <cffunction  name="getCats"  access="remote" returntype="any" returnFormat="json" httpMethod="POST">
    <cfargument  name="catId" default="">
    <cfargument  name="hiearchy" default="">
    <cfargument  name="type" default="1">
            <cfquery name="getCat" datasource="#dsn#_product">               
            SELECT PRODUCT_CATID,HIERARCHY,PRODUCT_CAT,IMAGE_CAT FROM PRODUCT_CAT WHERE 1=1 <cfif len(arguments.catId)> and PRODUCT_CATID in(#arguments.catId#) </cfif>
            <cfif len(arguments.hiearchy)> and HIERARCHY LIKE '#arguments.hiearchy#%' </cfif> AND IS_PUBLIC=1
            ORDER BY HIERARCHY
        </cfquery>
        <cfset RetArr = arrayNew(1)>
        <cfloop query="getCat">
            <cfscript>
                item=structNew();
                item.PRODUCT_CATID=PRODUCT_CATID;
                item.HIERARCHY=HIERARCHY;
                item.PRODUCT_CAT=PRODUCT_CAT;
                item.IMAGE=IMAGE_CAT;
                arrayAppend(RetArr, item);
            </cfscript>
        </cfloop>
    <cfif arguments.type eq 1>
    <cfreturn Replace(SerializeJSON(RetArr),'//','')>
    <cfelse>
    <cfreturn Replace(SerializeJSON(getCat),'//','')>
    </cfif>
    </cffunction>
        <cffunction  name="getMainMenu"  access="remote" returntype="any" returnFormat="json" httpMethod="POST">
            <cfargument  name="type" default="1">
            <cfquery name="getCat" datasource="#dsn#_product">               
            SELECT PRODUCT_CATID,HIERARCHY,PRODUCT_CAT,IMAGE_CAT FROM PRODUCT_CAT WHERE 1=1  AND IS_PUBLIC=1 AND IS_SHOW_MAIN_PAGE =1
            ORDER BY HIERARCHY
        </cfquery>
        <cfset RetArr = arrayNew(1)>
        <cfloop query="getCat">
            <cfscript>
                item=structNew();
                item.PRODUCT_CATID=PRODUCT_CATID;
                item.HIERARCHY=HIERARCHY;
                item.PRODUCT_CAT=PRODUCT_CAT;
                item.IMAGE=IMAGE_CAT;
                arrayAppend(RetArr, item);
            </cfscript>
        </cfloop>
    <cfif arguments.type eq 1>
    <cfreturn Replace(SerializeJSON(RetArr),'//','')>
    <cfelse>
    <cfreturn Replace(SerializeJSON(getCat),'//','')>
    </cfif>
    </cffunction>
    <cffunction  name="loginControl"  access="remote" returntype="any" returnFormat="json" httpMethod="POST">
        <cfargument  name="username" required="true">
        <cfargument  name="password" required="true">
        <cfargument  name="companycode" required="true">
        <cfquery name="GET_LIST" datasource="#dsn#">
            SELECT
                C.NICKNAME,
                C.FULLNAME,
                C.COMPANY_ID,
                CP.PARTNER_ID, 
                MSP.TIME_ZONE,
                MSP.LANGUAGE_ID,
                MSP.LOGIN_TIME,
                MSP.MAXROWS,
                MSP.TIMEOUT_LIMIT,
                CP.COMPANY_PARTNER_NAME,
                CP.COMPANY_PARTNER_SURNAME,
                CP.COMPANY_PARTNER_USERNAME,
                CP.COMPANY_PARTNER_PASSWORD,
                SP.PERIOD_ID,
                SP.PERIOD_YEAR,
                SP.OUR_COMPANY_ID,
                SP.OTHER_MONEY,
                SP.STANDART_PROCESS_MONEY,
                OC.COMPANY_NAME,
                OC.EMAIL,
                OC.NICK_NAME,
                OCI.SPECT_TYPE,
                OCI.IS_USE_IFRS,
                OCI.RATE_ROUND_NUM,
                ISNULL((SELECT TOP 1 WRK_MESSAGE.RECEIVER_ID FROM WRK_MESSAGE WHERE WRK_MESSAGE.RECEIVER_ID = CP.PARTNER_ID AND WRK_MESSAGE.RECEIVER_TYPE = 1),0) AS CONTROL_MESSAGE,
                SM.MONEY,
                ISNULL(CP2.PERIOD_DATE,ISNULL(SP.PERIOD_DATE,SP.START_DATE)) AS PERIOD_DATE,
                CP.COMPANY_PARTNER_EMAIL,
                CC.MONEY AS CALISILAN_PARA              
            FROM 
                COMPANY_PARTNER AS CP
                LEFT JOIN COMPANY AS C ON C.COMPANY_ID = CP.COMPANY_ID
                LEFT JOIN COMPANY_PERIOD AS CP2 ON CP2.COMPANY_ID = C.COMPANY_ID
                LEFT JOIN MY_SETTINGS_P AS MSP ON MSP.PARTNER_ID = CP.PARTNER_ID
                LEFT JOIN SETUP_PERIOD AS SP ON SP.PERIOD_ID = CP2.PERIOD_ID
                LEFT JOIN SETUP_MONEY AS SM ON SM.PERIOD_ID = SP.PERIOD_ID
                LEFT JOIN OUR_COMPANY AS OC ON OC.COMP_ID = SP.OUR_COMPANY_ID
                LEFT JOIN OUR_COMPANY_INFO AS OCI ON OCI.COMP_ID = OC.COMP_ID
                LEFT JOIN COMPANY_CREDIT AS CC ON CC.COMPANY_ID=C.COMPANY_ID
            WHERE
                CP.COMPANY_PARTNER_USERNAME = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.username#"> AND
                CP.COMPANY_PARTNER_PASSWORD = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.password#"> AND
                CP.COMPANY_PARTNER_STATUS = 1 AND
                C.COMPANY_STATUS = 1 AND
                C.ISPOTANTIAL = 0 AND
                C.MEMBER_CODE = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.companycode#"> AND
                SP.OUR_COMPANY_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="1"> AND
                
                SM.RATE1 = SM.RATE2
                order by sp.PERIOD_YEAR desc
        </cfquery>
        <cfscript>
         employee=structNew();
        if(GET_LIST.recordcount){
           employee.LoginStatus=1;
            employee.NAME=GET_LIST.COMPANY_PARTNER_NAME;
            employee.SURNAME=GET_LIST.COMPANY_PARTNER_SURNAME;
            employee.COMPANY_ID=GET_LIST.COMPANY_ID;
            employee.PARTNER_ID=GET_LIST.PARTNER_ID;
            employee.EMAIL=GET_LIST.COMPANY_PARTNER_EMAIL;
            employee.COMPANY_NICKNAME=GET_LIST.NICKNAME;
            employee.COMPANY_FULLNAME=GET_LIST.FULLNAME;
            employee.CALISILAN_PARA=GET_LIST.CALISILAN_PARA;
            }else{
                employee.LoginStatus=0;
            }
        </cfscript>
        <cfreturn Replace(SerializeJSON(employee),'//','')>
    </cffunction>
    <cffunction  name="getProducts" access="remote" returntype="any" returnFormat="json" httpMethod="POST">
        <cfargument  name="catId" default="">
        <cfargument  name="hiearchy" default="">
        <cfargument  name="product_id" default="">
        <cfargument  name="company_id" default="">
        <cfargument  name="start_row" default="1">
        <cfargument  name="end_row" default="20">
        <cfquery name="getProducts" datasource="#dsn#_product">
           WITH CTE1 AS ( SELECT * FROM PRODUCT WHERE 1=1 <cfif len(arguments.catId)>AND PRODUCT_CATID=#arguments.catid#</cfif>
            <cfif len(arguments.hiearchy)> AND PRODUCT_CODE LIKE '#arguments.hiearchy#%'</cfif>
            <cfif len(arguments.product_id)>AND PRODUCT_ID=#arguments.product_id#</cfif> AND IS_INTERNET=1
              ),
           CTE2 AS (
				SELECT
					CTE1.*,
					ROW_NUMBER() OVER(ORDER BY		PRODUCT_ID					) AS RowNum,(SELECT COUNT(*) FROM CTE1) AS QUERY_COUNT
				FROM
					CTE1
			)
			SELECT
				CTE2.*
			FROM
				CTE2
			WHERE
				RowNum BETWEEN #arguments.start_row# and #arguments.end_row#
        </cfquery>
        <cfset returnValue=structNew()>
        <cfset returnValue.total_records=getProducts.QUERY_COUNT>
        <cfset returnValue.start_row=arguments.start_row>
        <cfset returnValue.end_row=arguments.end_row>
        <cfif len(arguments.company_id)>
        <cfquery name="isHvPriceList" datasource="#dsn#_1">
            SELECT PRICE_CATID FROM PRICE_CAT_EXCEPTIONS WHERE COMPANY_ID=#arguments.company_id# AND IS_DEFAULT=1 AND PURCHASE_SALES=1 
        </cfquery>
        <cfset priceLists=valueList(isHvPriceList.PRICE_CATID)>
        <cfelse>
         <cfset priceLists="0">
         </cfif>
         <cfset productArr=arrayNew(1)>
        <cfloop query="getProducts">
        <cfset product = structNew()>
            <cfquery name="getProduct_images" datasource="#dsn#_product">
                SELECT * FROM PRODUCT_IMAGES WHERE PRODUCT_ID=#getProducts.PRODUCT_ID# AND IS_INTERNET=1
            </cfquery>
            <cfset PRODUCT.IMAGE_COUNT =getProduct_images.RECORDCOUNT>
            <cfset imgArr=arrayNew(1)>
            <cfloop query="getProduct_images">
                <cfset img=structNew()>
                <cfset img.PATH=getProduct_images.PATH>
                <cfset img.NAME=getProduct_images.PRD_IMG_NAME>
                <cfset img.SIZE=getProduct_images.IMAGE_SIZE>
                <cfscript>
                arrayAppend(imgArr, img);
                </cfscript>
            </cfloop>
            <cfif priceLists neq 0 and listlen(priceLists)>
            <cfquery name="getproductPrice" datasource="#dsn#_1">
                SELECT PRICE,PRICE_KDV,IS_KDV,PRODUCT_ID,MONEY FROM catalystTest_1.PRICE WHERE PRICE_CATID IN(#priceLists#) and PRODUCT_ID =#getProducts.PRODUCT_ID#
            </cfquery>
            <cfelse>
            <cfquery name="getproductPrice" datasource="#dsn#_product">
                SELECT PRICE,PRICE_KDV,MONEY FROM PRICE_STANDART WHERE PURCHASESALES=1 and PRODUCT_ID =#getProducts.PRODUCT_ID#
            </cfquery>
            </cfif>           

            <cfscript>
                PR_PRODUCT=structNew();
                PR_PRODUCT.PRICE=getproductPrice.PRICE;
                PR_PRODUCT.PRICE_KDV=getproductPrice.PRICE_KDV;
                PR_PRODUCT.MONEY=getproductPrice.MONEY;
                PRODUCT.PRODUCT_PRICE=PR_PRODUCT;
                PRODUCT.PRODUCT_NAME=getProducts.PRODUCT_NAME;
                PRODUCT.PRODUCT_CODE=getProducts.PRODUCT_CODE;
                PRODUCT.PRODUCT_CODE_2=getProducts.PRODUCT_CODE_2;
                PRODUCT.PRODUCT_ID=getProducts.PRODUCT_ID;
                PRODUCT.PRODUCT_CATID=getProducts.PRODUCT_CATID;
                PRODUCT.IMAGES=imgArr;
                arrayAppend(productArr, PRODUCT);
            </cfscript>
        </cfloop>
        <cfset returnValue.PRODUCT_LIST=productArr>
        <cfreturn Replace(SerializeJSON(returnValue),'//','')>
    </cffunction>
    <cffunction  name="getOrders" access="remote" returntype="any" returnFormat="json" httpMethod="POST">
        <cfargument  name="company_id" >
        <cfargument  name="start_row" default="1">
        <cfargument  name="end_row" default="20">
        <cfquery name="getOrders" datasource="#dsn#_1">
            SELECT ORDER_HEAD,
                SHIP_ADDRESS,
                GROSSTOTAL,
                TAXTOTAL,
                OTHER_MONEY,
                OTHER_MONEY_VALUE,
                ORDER_DETAIL,
                ORDER_ID,
                ORDER_DATE,
                NETTOTAL,
                ORDER_CURRENCY,
                CITY.CITY_NAME,
                COUNTY.COUNTY_NAME,
                COUNTRY.COUNTRY_NAME ,
                CP.COMPANY_PARTNER_NAME,
                CP.COMPANY_PARTNER_SURNAME,
                PTR.STAGE
                FROM catalystTest_1.ORDERS AS O
                LEFT JOIN catalystTest.SETUP_CITY AS CITY ON CITY.CITY_ID=O.CITY_ID
                LEFT JOIN catalystTest.SETUP_COUNTY AS COUNTY ON COUNTY.COUNTY_ID=O.COUNTY_ID
                LEFT JOIN catalystTest.SETUP_COUNTRY AS COUNTRY ON COUNTRY.COUNTRY_ID=O.COUNTRY_ID
                LEFT JOIN catalystTest.COMPANY_PARTNER AS  CP ON CP.PARTNER_ID=O.PARTNER_ID
                LEFT JOIN catalystTest.PROCESS_TYPE_ROWS AS PTR ON PTR.PROCESS_ROW_ID=O.ORDER_STAGE
            WHERE O.COMPANY_ID =#arguments.company_id#
        </cfquery>
        <cfset orderArr=arrayNew(1)>
        <cfloop query="getOrders">
            <cfset item=structNew()>
            <cfset item.ORDER_HEAD=ORDER_HEAD><!----Ok---->
            <cfset item.SHIP_ADDRESS=SHIP_ADDRESS><!----Ok---->
            <cfset item.GROSSTOTAL=GROSSTOTAL><!----Ok---->
            <cfset item.TAXTOTAL=TAXTOTAL><!----Ok---->
            <cfset item.OTHER_MONEY=OTHER_MONEY><!----Ok---->
            <cfset item.OTHER_MONEY_VALUE=OTHER_MONEY_VALUE><!----Ok---->
            <cfset item.ORDER_DETAIL=ORDER_DETAIL><!----Ok---->
            <cfset item.ORDER_ID=ORDER_ID><!----Ok---->
            <cfset item.ORDER_DATE=ORDER_DATE>
            <cfset item.NETTOTAL=NETTOTAL>
            <cfset item.ORDER_CURRENCY=ORDER_CURRENCY>
            <cfset item.CITY_NAME=CITY_NAME>
            <cfset item.COUNTY_NAME=COUNTY_NAME>
            <cfset item.COUNTRY_NAME=COUNTRY_NAME>
            <cfset item.COMPANY_PARTNER_NAME=COMPANY_PARTNER_NAME>
            <cfset item.COMPANY_PARTNER_SURNAME=COMPANY_PARTNER_SURNAME>
            <cfset item.STAGE=STAGE>
           <cfscript>
           arrayAppend(orderArr, item);
           </cfscript>
        </cfloop>
        <cfreturn Replace(SerializeJSON(orderArr),'//','')>
    </cffunction>
    <cffunction  name="getOrderrows" access="remote" returntype="any" returnFormat="json" httpMethod="POST">
     <cfargument  name="order_id" >
     <cfquery name="getOrderRow" datasource="#dsn#_1">
        SELECT P.PRODUCT_NAME,
            ORDR.QUANTITY,
            ORDR.PRICE,
            ORDR.PRICE_OTHER,
            ORDR.UNIT,
            ORDR.TAX,
            ORDR.NETTOTAL,
            ORDR.OTHER_MONEY,
            ORDR.OTHER_MONEY_VALUE,
            CASE 
                WHEN ORDER_ROW_CURRENCY = - 1
                    THEN 'AÇIK'
                WHEN ORDER_ROW_CURRENCY = - 2
                    THEN 'TEDARİK'
                WHEN ORDER_ROW_CURRENCY = - 3
                    THEN 'KAPATILDI'
                WHEN ORDER_ROW_CURRENCY = - 4
                    THEN 'KISMİ ÜRETİM'
                WHEN ORDER_ROW_CURRENCY = - 5
                    THEN 'ÜRETİM'
                WHEN ORDER_ROW_CURRENCY = - 6
                    THEN 'SEVK'
                WHEN ORDER_ROW_CURRENCY = - 7
                    THEN 'EKSİK TESLİMAT'
                WHEN ORDER_ROW_CURRENCY = - 8
                    THEN 'FAZLA TESLİMAT'
                WHEN ORDER_ROW_CURRENCY = - 9
                    THEN 'İPTAL'
                WHEN ORDER_ROW_CURRENCY = - 10
                    THEN 'KAPATILDI (MANUEL)'
                END AS DURUM
        FROM catalystTest_1.ORDER_ROW ORDR
        LEFT JOIN catalystTest_product.PRODUCT AS P ON P.PRODUCT_ID = ORDR.PRODUCT_ID     
        WHERE ORDR.ORDER_ID=#arguments.ORDER_ID#       
     </cfquery>
      <cfset orderArr=arrayNew(1)>
        <cfloop query="getOrderRow">
             <cfset item=structNew()>
             <cfset item.PRODUCT_NAME=PRODUCT_NAME>
             <cfset item.QUANTITY=QUANTITY>
             <cfset item.PRICE=PRICE>
             <cfset item.PRICE_OTHER=PRICE_OTHER>
             <cfset item.UNIT=UNIT>
             <cfset item.TAX=TAX>
             <cfset item.NETTOTAL=NETTOTAL>
             <cfset item.OTHER_MONEY=OTHER_MONEY>
             <cfset item.OTHER_MONEY_VALUE=OTHER_MONEY_VALUE>
             <cfscript>
                arrayAppend(orderArr, item);
             </cfscript>
        </cfloop>
        <cfreturn Replace(SerializeJSON(orderArr),'//','')>
    </cffunction>
</cfcomponent>