<cfcomponent>
<!--- add_stock_rows--->

    <cffunction name="add_stock_rows" returntype="boolean" output="false">
        <cfargument name="sr_dsn_type" type="string" default="#dsn2#">
        <cfargument name="sr_process_type" type="boolean" default="">
		<cfargument name="sr_main_process_type" default=""><!--- faturanın kendi irsaliyesi stok hareketi olustururken bu argumana fatura process_type gonderılır, sr_process_type a ise faturanın olusturdgu irsaliyenin process_type ı gonderilir --->
		<cfargument name="sr_control_process_type" type="string" default=""><!---belgenin iade işlem tiplerini tutar. Alım iadelerde spec-ağaç çözümü YAPILMAZ, satıs iadelerde ise spec-ağaç çözümü YAPILIR --->
        <cfargument name="sr_stock_row_count" type="numeric"><!---toplu stok hareketi yapabilmk için kulanılabilir,irsaliye ekleme sayfalarndaki stok hareketi kısmında kullanılmaz--->
        <cfargument name="sr_max_id" type="numeric" default=""><!--- stocks_row daki UPD_ID yani stok hareketinin ilgili oldugu action_id--->
        <cfargument name="sr_department_id" type="numeric" default="">
        <cfargument name="sr_location_id" type="string" default="">
        <cfargument name="sr_process_date" type="string" default="">
        <cfargument name="sr_is_purchase_sales" type="boolean" default="1"><!--- 0 Alış 1 Satış --->
        <cfargument name="sr_product_id_list" type="string" default="">
        <cfargument name="sr_stock_id_list" type="string" default="">
        <cfargument name="sr_unit_list" type="string" default="">
        <cfargument name="sr_amount_list" type="string" default="">
        <cfargument name="sr_spec_id_list" type="string" default="">
        <cfargument name="sr_spec_main_id_list" type="string" default="">
        <cfargument name="sr_lot_no_list" type="string" default="">
        <cfargument name="sr_shelf_number_list" type="string" default="">
        <cfargument name="sr_manufact_code_list" type="string" default="">
        <cfargument name="sr_amount_other_list" type="string" default="">
        <cfargument name="sr_unit_other_list" type="string" default="">
        <cfargument name="sr_deliver_date_list" type="string" default="">
        <cfargument name="sr_paper_row_id_list" type="string" default="">
        <cfargument name="sr_width_list" type="string" default="">
        <cfargument name="sr_depth_list" type="string" default="">
        <cfargument name="sr_height_list" type="string" default="">
        <cfargument name="sr_wrk_row_id_list" type="string" default="">
        <cfargument name="sr_row_department_id" type="string" default=""><!--- satırdaki teslim depo bilgisi --->
        <cfargument name="sr_row_location_id" type="string" default=""><!--- satırdaki teslim deponun lokasyon bilgisi --->
         <!--- grup içi işlemden yeni spect oluşturmak için eklendi PY 102015 --->
        <cfargument name="is_company_related_action" default="0">
        <cfargument name="company_related_dsn" default="#dsn2#">
        <cfif arguments.is_company_related_action>
            <cfset new_dsn3 = arguments.company_related_dsn />
        <cfelse>
        	<cfset new_dsn3 = dsn3 />
        </cfif>
		<cfif not len(arguments.sr_main_process_type)>
			<cfset arguments.sr_main_process_type = arguments.sr_process_type />
		</cfif>
		<cfif arguments.sr_is_purchase_sales eq 1><!--- Satış ise  STOCK_ROW'DA STOCK_OUT tablosuna yazılacak alış ise STOCK_IN alanına yazılır!--->
			<cfset stock_in_out = 'STOCK_OUT' />
		<cfelseif arguments.sr_is_purchase_sales eq 0>
			<cfset stock_in_out = 'STOCK_IN' />
		</cfif>
        <cfset arguments.sr_process_date_time = arguments.sr_process_date>
        <cfset arguments.sr_process_date = createdate(year(arguments.sr_process_date),month(arguments.sr_process_date),day(arguments.sr_process_date))>
	<!---	<cfif (arguments.sr_is_purchase_sales eq 1 and not ListFind(arguments.sr_control_process_type,arguments.sr_main_process_type)) or (arguments.sr_is_purchase_sales eq 0 and ListFind(arguments.sr_control_process_type,arguments.sr_main_process_type))><!--- alım iadelerde spec-ağaç çözümü yapmasın --->--->
			<cfquery name="GET_KARMA_PRODUCTS" datasource="#arguments.sr_dsn_type#"><!--- karma koli olan ürünler --->
				SELECT PRODUCT_ID FROM #new_dsn3#.PRODUCT WHERE PRODUCT_ID IN (#arguments.sr_product_id_list#) AND IS_KARMA = 1
			</cfquery>
			<cfset karma_product_list = valuelist(GET_KARMA_PRODUCTS.PRODUCT_ID) />
			<cfquery name="GET_PROD_PRODUCTS" datasource="#arguments.sr_dsn_type#"><!--- üretilen ürünler --->
				SELECT STOCK_ID FROM #new_dsn3#.STOCKS WHERE STOCK_ID IN (#arguments.sr_stock_id_list#) AND IS_PRODUCTION=1
			</cfquery>
			<cfset prod_product_list = valuelist(GET_PROD_PRODUCTS.STOCK_ID) />
	<!---	</cfif>--->
		<cfloop from="1" to="#arguments.sr_stock_row_count#" index="src_ind">
			<cfif isdefined('arguments.sr_deliver_date_list') and ListGetAt(arguments.sr_deliver_date_list,src_ind,',') gt 0>
				<cfset row_deliver_date=ListGetAt(arguments.sr_deliver_date_list,src_ind,',') />
			<cfelse>
				<cfset row_deliver_date='NULL' />
			</cfif>
			<!--- varsa satırdaki teslim depo bilgisi yoksa belgenin depo bilgisi stok hareketine yazılıyor--->
			<cfset row_dept_id=arguments.sr_department_id />
			<cfset row_loc_id=arguments.sr_location_id />
			<!--- TESLIM DEPOYA GORE STOCK KONTROLU YAPILDIGINDA ACILACAK, SIMDILIK KAPATILDI OZDEN20091116
			<cfif isdefined('arguments.sr_row_department_id') and listlen(arguments.sr_row_department_id) gte  src_ind and ListGetAt(arguments.sr_row_department_id,src_ind,',') gt 0>
				<cfset row_dept_id=ListGetAt(arguments.sr_row_department_id,src_ind,',') />
			<cfelse>
				<cfset row_dept_id=arguments.sr_department_id />
			</cfif>
			<cfif isdefined('arguments.sr_row_location_id') and listlen(arguments.sr_row_location_id) gte  src_ind and ListGetAt(arguments.sr_row_location_id,src_ind,',') gt 0>
				<cfset row_loc_id=ListGetAt(arguments.sr_row_location_id,src_ind,',') />
			<cfelse>
				<cfset row_loc_id=arguments.sr_location_id />
			</cfif> --->
			<cfquery name="GET_UNIT" datasource="#arguments.sr_dsn_type#">
				SELECT 
					ADD_UNIT,
					MULTIPLIER,
					MAIN_UNIT,
					PRODUCT_UNIT_ID
				FROM
					#new_dsn3#.PRODUCT_UNIT 
				WHERE 
					PRODUCT_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ListGetAt(arguments.sr_product_id_list,src_ind,',')#"> AND
					ADD_UNIT = <cfqueryparam cfsqltype="cf_sql_varchar" value="#ListGetAt(arguments.sr_unit_list,src_ind,',')#"> AND
					PRODUCT_UNIT_STATUS = 1
			</cfquery>
			<cfif get_unit.recordcount and len(get_unit.multiplier) >
				<cfset multi=get_unit.multiplier*ListGetAt(arguments.sr_amount_list,src_ind,',') />
			<cfelse>
				<cfset multi=ListGetAt(arguments.sr_amount_list,src_ind,',') />
			</cfif>
			<cfif not (isdefined("karma_product_list") and ListFind(karma_product_list,ListGetAt(arguments.sr_product_id_list,src_ind,',')))>
				<!--- satırdaki ürün karma koli olmadığı sürece kendisine hareket yapar,
				bir ürün hem karma koli olup hem spect seçilme gibi durumlarda yanlış çalıştıgı düşünülmesin,business gereği olamaz,
				ürüne bağlı spec,karma koli,ürün ağacı tanımlamalarından sadece biri yapılmalıdır...AE20060621--->
				
				<!--- shelf number ve  PRODUCT_MANUFACT_CODE spect ve urun agacı için sadece ana ürüne eklenir,
				karmakoli ise karmakoliyi olusturan tum urunlere eklenir. OZDEN20060818--->
				<cfif isdefined('arguments.sr_spec_id_list') and ListGetAt(arguments.sr_spec_id_list,src_ind,',') gt 0>
					<cfquery name="GET_SPEC_MAIN" datasource="#arguments.sr_dsn_type#">
						SELECT SPECT_MAIN_ID FROM #new_dsn3#.SPECTS WHERE SPECT_VAR_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ListGetAt(arguments.sr_spec_id_list,src_ind,',')#">
					</cfquery>
				</cfif>
				<cfquery name="ADD_STOCK_ROW" datasource="#arguments.sr_dsn_type#"><!--- satırlardaki ana ürünler için stok hareketleri--->
					INSERT INTO 
						STOCKS_ROW
						(
							UPD_ID,
							PRODUCT_ID,
							STOCK_ID,
                            ROW_ID,
                            WRK_ROW_ID,
							PROCESS_TYPE,
							#stock_in_out#,
							STORE,
							STORE_LOCATION,
							PROCESS_DATE,
                            PROCESS_TIME,
							SPECT_VAR_ID,
							LOT_NO,
							DELIVER_DATE,
							SHELF_NUMBER,
							PRODUCT_MANUFACT_CODE,
							AMOUNT2,
							UNIT2,
							DEPTH_VALUE,
							WIDTH_VALUE,
							HEIGHT_VALUE
						)
						VALUES
						(
							#arguments.sr_max_id#,
							#ListGetAt(arguments.sr_product_id_list,src_ind,',')#,
							#ListGetAt(arguments.sr_stock_id_list,src_ind,',')#,
							<cfif isdefined('arguments.sr_paper_row_id_list') and len(arguments.sr_paper_row_id_list)>#ListGetAt(arguments.sr_paper_row_id_list,src_ind,',')#<cfelse>NULL</cfif>,
							<cfif isdefined('arguments.sr_wrk_row_id_list') and len(arguments.sr_wrk_row_id_list)>'#ListGetAt(arguments.sr_wrk_row_id_list,src_ind,',')#'<cfelse>NULL</cfif>,
							#arguments.sr_process_type#,
							#multi#,
							#row_dept_id#,
							#row_loc_id#,
							#arguments.sr_process_date#,
                            #arguments.sr_process_date_time#,
							<cfif isdefined('arguments.sr_spec_id_list') and len(ListGetAt(arguments.sr_spec_id_list,src_ind,',')) and  ListGetAt(arguments.sr_spec_id_list,src_ind,',') gt 0 and len(GET_SPEC_MAIN.SPECT_MAIN_ID)>#GET_SPEC_MAIN.SPECT_MAIN_ID#,<cfelse>NULL,</cfif>
							<cfif isdefined('arguments.sr_lot_no_list') and len(ListGetAt(arguments.sr_lot_no_list,src_ind,',')) and ListGetAt(arguments.sr_lot_no_list,src_ind,',') neq 0>'#ListGetAt(arguments.sr_lot_no_list,src_ind,',')#'<cfelse>NULL</cfif>,
							#row_deliver_date#,
							<cfif isdefined('arguments.sr_shelf_number_list') and len(ListGetAt(arguments.sr_shelf_number_list,src_ind,',')) and ListGetAt(arguments.sr_shelf_number_list,src_ind,',') neq 0>#ListGetAt(arguments.sr_shelf_number_list,src_ind,',')#<cfelse>NULL</cfif>,
							<cfif isdefined('arguments.sr_manufact_code_list') and len(ListGetAt(arguments.sr_manufact_code_list,src_ind,',')) and ListGetAt(arguments.sr_manufact_code_list,src_ind,',') neq 0>'#ListGetAt(arguments.sr_manufact_code_list,src_ind,',')#'<cfelse>NULL</cfif>,
							<cfif isdefined('arguments.sr_amount_other_list') and len(ListGetAt(arguments.sr_amount_other_list,src_ind,',')) and ListGetAt(arguments.sr_amount_other_list,src_ind,',') neq 0>#ListGetAt(arguments.sr_amount_other_list,src_ind,',')#<cfelse>NULL</cfif>,
							<cfif isdefined('arguments.sr_unit_other_list') and ListGetAt(arguments.sr_unit_other_list,src_ind,',') gt 0>'#ListGetAt(arguments.sr_unit_other_list,src_ind,',')#'<cfelse>NULL</cfif>,
							<cfif isdefined('arguments.sr_width_list') and (listlen(arguments.sr_width_list) gte src_ind) and len(ListGetAt(arguments.sr_width_list,src_ind,',')) and ListGetAt(arguments.sr_width_list,src_ind,',') neq 0>#ListGetAt(arguments.sr_width_list,src_ind,',')#<cfelse>NULL</cfif>,
							<cfif isdefined('arguments.sr_depth_list') and (listlen(arguments.sr_width_list) gte src_ind) and len(ListGetAt(arguments.sr_depth_list,src_ind,',')) and ListGetAt(arguments.sr_depth_list,src_ind,',') neq 0>#ListGetAt(arguments.sr_depth_list,src_ind,',')#<cfelse>NULL</cfif>,
							<cfif isdefined('arguments.sr_height_list') and (listlen(arguments.sr_width_list) gte src_ind) and len(ListGetAt(arguments.sr_height_list,src_ind,',')) and ListGetAt(arguments.sr_height_list,src_ind,',') neq 0>#ListGetAt(arguments.sr_height_list,src_ind,',')#<cfelse>NULL</cfif>
						)
				</cfquery>
			</cfif>
		<!---	<cfif (arguments.sr_is_purchase_sales eq 1 and not ListFind(arguments.sr_control_process_type,arguments.sr_main_process_type)) or (arguments.sr_is_purchase_sales eq 0 and ListFind(arguments.sr_control_process_type,arguments.sr_main_process_type))><!--- alım iadelerde spec-ağaç çözümü yapmasın --->--->
			<!--- satırdaki ürünlerin spec-ürünağacı-karmakoli çözümleri --->
				<cfif len(karma_product_list) and ListFind(karma_product_list,ListGetAt(arguments.sr_product_id_list,src_ind,','))><!--- karma koliyse --->
					<cfquery name="GET_KARMA_PRODUCT" datasource="#arguments.sr_dsn_type#">
						SELECT PRODUCT_ID,STOCK_ID,SPEC_MAIN_ID,PRODUCT_AMOUNT FROM #dsn1_alias#.KARMA_PRODUCTS WHERE KARMA_PRODUCT_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ListGetAt(arguments.sr_product_id_list,src_ind,',')#">
					</cfquery>
					<cfif GET_KARMA_PRODUCT.recordcount>
						<cfloop query="GET_KARMA_PRODUCT">
							<cfif len(GET_KARMA_PRODUCT.SPEC_MAIN_ID)><!--- karma koli satırındaki urun için spec seçilmisse, hem o ürün hem de sevkte birleştirilen urunleri için stok hareketi yazılır --->
								<cfquery name="GET_SPEC_PRODUCT" datasource="#arguments.sr_dsn_type#">
									SELECT 
										PRODUCT_ID,
										STOCK_ID,
										AMOUNT,
										RELATED_MAIN_SPECT_ID
									FROM
										#new_dsn3#.SPECT_MAIN_ROW
									WHERE
										IS_SEVK = 1 AND
										STOCK_ID IS NOT NULL AND
										PRODUCT_ID IS NOT NULL AND
										SPECT_MAIN_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#GET_KARMA_PRODUCT.SPEC_MAIN_ID#">
								</cfquery>
								<cfif GET_SPEC_PRODUCT.recordcount>
									<cfloop query="GET_SPEC_PRODUCT">
										<cfquery name="ADD_STOCK_ROW" datasource="#arguments.sr_dsn_type#">
											INSERT INTO
												STOCKS_ROW
											(
												UPD_ID,
												PRODUCT_ID,
												STOCK_ID,
												ROW_ID,
												WRK_ROW_ID,
												SPECT_VAR_ID,
												PROCESS_TYPE,
												#stock_in_out#,
												STORE,
												STORE_LOCATION,
												DELIVER_DATE,
												SHELF_NUMBER,
												PROCESS_DATE,
                                                PROCESS_TIME
											)
											VALUES
											(
												#arguments.sr_max_id#,
												#GET_SPEC_PRODUCT.product_id#,
												#GET_SPEC_PRODUCT.stock_id#,
												<cfif isdefined('arguments.sr_paper_row_id_list') and len(arguments.sr_paper_row_id_list)>#ListGetAt(arguments.sr_paper_row_id_list,src_ind,',')#<cfelse>NULL</cfif>,
												<cfif isdefined('arguments.sr_wrk_row_id_list') and len(arguments.sr_wrk_row_id_list)>'#ListGetAt(arguments.sr_wrk_row_id_list,src_ind,',')#'<cfelse>NULL</cfif>,
												<cfif len(GET_SPEC_PRODUCT.RELATED_MAIN_SPECT_ID) and GET_SPEC_PRODUCT.RELATED_MAIN_SPECT_ID gt 0>#GET_SPEC_PRODUCT.RELATED_MAIN_SPECT_ID#<cfelse>NULL</cfif>,
												#arguments.sr_process_type#,
												#multi*GET_SPEC_PRODUCT.AMOUNT#,
												#row_dept_id#,
												#row_loc_id#,                                
												#row_deliver_date#,
												<cfif isdefined('arguments.sr_shelf_number_list') and len(ListGetAt(arguments.sr_shelf_number_list,src_ind,','))and ListGetAt(arguments.sr_shelf_number_list,src_ind,',') neq 0>#ListGetAt(arguments.sr_shelf_number_list,src_ind,',')#<cfelse>NULL</cfif>,
												#arguments.sr_process_date#,
                                                #arguments.sr_process_date_time#
											)
										</cfquery>
									</cfloop>
								</cfif>
							</cfif>
							<cfquery name="ADD_STOCK_ROW" datasource="#arguments.sr_dsn_type#">
								INSERT INTO
									STOCKS_ROW
								(
									UPD_ID,
									PRODUCT_ID,
									STOCK_ID,
									SPECT_VAR_ID,
                                    ROW_ID,
                                    WRK_ROW_ID,
									PROCESS_TYPE,
									#stock_in_out#,
									STORE,
									STORE_LOCATION,
									PROCESS_DATE,
                                    PROCESS_TIME,
									DELIVER_DATE,
									SHELF_NUMBER,
									PRODUCT_MANUFACT_CODE
								)
								VALUES
								(
									#arguments.sr_max_id#,
									#GET_KARMA_PRODUCT.product_id#,
									#GET_KARMA_PRODUCT.stock_id#,
									<cfif len(GET_KARMA_PRODUCT.SPEC_MAIN_ID)>#GET_KARMA_PRODUCT.SPEC_MAIN_ID#<cfelse>NULL</cfif>,
									<cfif isdefined('arguments.sr_paper_row_id_list') and len(arguments.sr_paper_row_id_list)>#ListGetAt(arguments.sr_paper_row_id_list,src_ind,',')#<cfelse>NULL</cfif>,
                                    <cfif isdefined('arguments.sr_wrk_row_id_list') and len(arguments.sr_wrk_row_id_list)>'#ListGetAt(arguments.sr_wrk_row_id_list,src_ind,',')#'<cfelse>NULL</cfif>,
									#arguments.sr_process_type#,
									#multi*GET_KARMA_PRODUCT.product_amount#,
									#row_dept_id#,
									#row_loc_id#,
									#arguments.sr_process_date#,
                                    #arguments.sr_process_date_time#,
									#row_deliver_date#,
									<cfif isdefined('arguments.sr_shelf_number_list') and len(ListGetAt(arguments.sr_shelf_number_list,src_ind,',')) and ListGetAt(arguments.sr_shelf_number_list,src_ind,',') neq 0>#ListGetAt(arguments.sr_shelf_number_list,src_ind,',')#<cfelse>NULL</cfif>,						
									<cfif isdefined('arguments.sr_manufact_code_list') and len(ListGetAt(arguments.sr_manufact_code_list,src_ind,',')) and ListGetAt(arguments.sr_manufact_code_list,src_ind,',') neq 0>'#ListGetAt(arguments.sr_manufact_code_list,src_ind,',')#'<cfelse>NULL</cfif>
								)
							</cfquery>
						</cfloop>
					</cfif>
				<cfelseif isdefined('arguments.sr_spec_id_list') and ListGetAt(arguments.sr_spec_id_list,src_ind,',') gt 0><!--- spectse --->
					<cfquery name="GET_SPEC_PRODUCT" datasource="#arguments.sr_dsn_type#">
						SELECT 
							PRODUCT_ID,
							STOCK_ID,
							AMOUNT_VALUE,
							RELATED_SPECT_ID
						FROM
							#new_dsn3#.SPECTS_ROW
						WHERE
							IS_SEVK = 1 AND<!--- sevkte birleştir--->
							STOCK_ID IS NOT NULL AND
							PRODUCT_ID IS NOT NULL AND
							SPECT_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ListGetAt(arguments.sr_spec_id_list,src_ind,',')#">
					</cfquery>
					<cfif GET_SPEC_PRODUCT.recordcount>
						<cfloop query="GET_SPEC_PRODUCT">
							<cfquery name="ADD_STOCK_ROW" datasource="#arguments.sr_dsn_type#">
								INSERT INTO
									STOCKS_ROW
								(
									UPD_ID,
									PRODUCT_ID,
									STOCK_ID,
                                    ROW_ID,
                                    WRK_ROW_ID,
									SPECT_VAR_ID,
									PROCESS_TYPE,
									#stock_in_out#,
									STORE,
									STORE_LOCATION,
									DELIVER_DATE,
									SHELF_NUMBER,
									PROCESS_DATE,
                                    PROCESS_TIME
								)
								VALUES
								(
									#arguments.sr_max_id#,
									#GET_SPEC_PRODUCT.product_id#,
									#GET_SPEC_PRODUCT.stock_id#,
									<cfif isdefined('arguments.sr_paper_row_id_list') and len(arguments.sr_paper_row_id_list)>#ListGetAt(arguments.sr_paper_row_id_list,src_ind,',')#<cfelse>NULL</cfif>,
                                    <cfif isdefined('arguments.sr_wrk_row_id_list') and len(arguments.sr_wrk_row_id_list)>'#ListGetAt(arguments.sr_wrk_row_id_list,src_ind,',')#'<cfelse>NULL</cfif>,
									<cfif len(GET_SPEC_PRODUCT.RELATED_SPECT_ID) and GET_SPEC_PRODUCT.RELATED_SPECT_ID gt 0>#GET_SPEC_PRODUCT.RELATED_SPECT_ID#<cfelse>NULL</cfif>,
									#arguments.sr_process_type#,
									#multi*GET_SPEC_PRODUCT.AMOUNT_VALUE#,
									#row_dept_id#,
									#row_loc_id#,                                
									#row_deliver_date#,
									<cfif isdefined('arguments.sr_shelf_number_list') and len(ListGetAt(arguments.sr_shelf_number_list,src_ind,','))and ListGetAt(arguments.sr_shelf_number_list,src_ind,',') neq 0>#ListGetAt(arguments.sr_shelf_number_list,src_ind,',')#<cfelse>NULL</cfif>,
									#arguments.sr_process_date#,
                                    #arguments.sr_process_date_time#
								)
							</cfquery>
						</cfloop>
					</cfif>
				<cfelseif len(prod_product_list) and ListFind(prod_product_list,ListGetAt(arguments.sr_stock_id_list,src_ind,','))><!--- üretilen ürünse --->
					<cfquery name="GET_PROD_PRODUCT" datasource="#arguments.sr_dsn_type#">
						SELECT
							S.STOCK_ID,
							S.PRODUCT_ID,
							PT.AMOUNT
						FROM
							#new_dsn3#.PRODUCT_TREE PT,
							#new_dsn3#.STOCKS S
						WHERE
							PT.RELATED_ID = S.STOCK_ID AND
							PT.IS_SEVK = 1 AND<!--- sevkte birleştir--->
							PT.STOCK_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#ListGetAt(arguments.sr_stock_id_list,src_ind,',')#">
					</cfquery>
					<cfif GET_PROD_PRODUCT.recordcount>
						<cfloop query="GET_PROD_PRODUCT">
							<cfquery name="ADD_STOCK_ROW" datasource="#arguments.sr_dsn_type#">
								INSERT INTO
									STOCKS_ROW
								(
									UPD_ID,
									PRODUCT_ID,
									STOCK_ID,
                                    ROW_ID,
                                    WRK_ROW_ID,
									SPECT_VAR_ID,
									PROCESS_TYPE,
									#stock_in_out#,
									STORE,
									STORE_LOCATION,
									DELIVER_DATE,
									SHELF_NUMBER,
									PROCESS_DATE,
                                    PROCESS_TIME
								)
								VALUES
								(
									#arguments.sr_max_id#,
									#GET_PROD_PRODUCT.PRODUCT_ID#,
									#GET_PROD_PRODUCT.STOCK_ID#,
									<cfif len(GET_PROD_PRODUCT.SPECT_MAIN_ID) and GET_PROD_PRODUCT.SPECT_MAIN_ID gt 0>#GET_PROD_PRODUCT.SPECT_MAIN_ID#<cfelse>NULL</cfif>,
									#arguments.sr_process_type#,
									#multi*GET_PROD_PRODUCT.AMOUNT#,
									#row_dept_id#,
									#row_loc_id#,
									#row_deliver_date#,
									<cfif isdefined('arguments.sr_shelf_number_list') and len(ListGetAt(arguments.sr_shelf_number_list,src_ind,',')) and ListGetAt(arguments.sr_shelf_number_list,src_ind,',') neq 0 >#ListGetAt(arguments.sr_shelf_number_list,src_ind,',')#<cfelse>NULL</cfif>,
									#arguments.sr_process_date#,
                                    #arguments.sr_process_date_time#
								)
							</cfquery>
						</cfloop>
					</cfif>
				</cfif>
		<!---	</cfif>--->
		</cfloop>
        <cfreturn true>
    </cffunction>

<!--- get_specer--->
<cfscript>
	if(isdefined("session.pda") and isDefined("session.pda.userid"))
	{
		session_base.money = session.pda.money;
		session_base.money2 = session.pda.money2;
		session_base.userid = session.pda.userid;
		session_base.company_id = session.pda.our_company_id;
		session_base.our_company_id = session.pda.our_company_id;
		session_base.period_id = session.pda.period_id;
	}
	else if(isdefined("session.ep") and isDefined("session.ep.userid"))
	{
		session_base.money = session.ep.money;
		session_base.money2 = session.ep.money2;
		session_base.userid = session.ep.userid;
		session_base.company_id = session.ep.company_id;
		session_base.period_id = session.ep.period_id;
	}
</cfscript>
<cffunction name="specer" returntype="string" output="false">	
	<cfargument name="dsn_type" type="string" default="#new_dsn3#">
	<cfargument name="main_spec_id" type="numeric"><!--- eger main_spec_id biliniyorsa yollanir gelirse main_spec kaydetmez --->
	<cfargument name="only_main_spec" type="boolean" default="0"><!--- sadece main_spec kaydedilecekse 1 gider --->
	<cfargument name="insert_spec" type="boolean" default="1"><!--- spect kaydedilecekse 1 update ise 0 --->
	<cfargument name="is_purchasesales" type="boolean" required="no" default="1"><!--- spect alis tipinde spec alis fiyatindan ve maliyette sadece urun alis fiyati atilmali --->
	<cfargument name="spec_id" type="string"><!--- spec guncellenecekse guncellenecek spec id--->
	<cfargument name="action_date" type="numeric" default="#now()#"><!--- maliyet v.s. tarihi ( ODBC Formatta !!!)--->
	<cfargument name="add_to_main_spec" type="boolean"><!--- main_spec_id var ve eklenecek spec main_spec deki degerlerle eklenecekse 1 yollanmalı ( urun popuplari v.s. icin)--->
	<cfargument name="company_id" type="string" default="0">
	<cfargument name="consumer_id" type="string" default="0">
	<cfargument name="spec_type" type="numeric" default="1"><!--- spec type 1:alternatifli 2: --->
	<cfargument name="spec_is_tree" type="boolean" default="0"><!--- spect agacin aynisi ise 1 degilse 0 --->
	<cfargument name="main_stock_id" type="numeric"><!--- spec eklenecek urun stock_id si --->
	<cfargument name="main_product_id" type="numeric"><!--- spec eklenecek urun product_id si --->
	<cfargument name="spec_name" type="string">
	<cfargument name="spec_total_value" type="numeric"><!--- YTL cinsinden --->
	<cfargument name="main_prod_price" type="numeric"><!--- urun fiyati --->
	<cfargument name="main_product_money" type="string" default="#session_base.money#"><!--- spec eklenecek urunun fiyat para birimi --->
	<cfargument name="spec_other_total_value" type="string" default="0">
	<cfargument name="marj_total_value" type="string" default="0"><!--- Marjlı toplam fiyatı tutar. --->
	<cfargument name="marj_other_total_value" type="string"><!--- Marjlı olan toplam döviz fiyatını tutar. --->
	<cfargument name="marj_amount" type="string" default="0"><!--- Uygulanan marj miktarını ifade eder,yani toplam fiyatının üzerine eklenen değerdir. --->
	<cfargument name="marj_percent" type="string" default="0"><!--- Uygulanan marj miktarına eklenecek %'lik değeri ifade eder. --->			
	<cfargument name="calculate_type_list" type="string" default=""><!--- Fire ve sarf ürünlerinin hesaplanırken,ürün özelliklerindeki en*boy hesaplamasının hangisi ile hesaplandığını tutar,listeye ürün özelliğinin currentrow'ları gönderiliyor,ona göre hesaplama yapılıyor.Kullanılmayan yerlerde 0 gönderilmelidri. --->
	<cfargument name="other_money" type="string" default="#session_base.money2#">
	<cfargument name="money_list" type="string" default=""><!--- para birimleri--->
	<cfargument name="money_rate1_list" type="string" default="">
	<cfargument name="money_rate2_list" type="string" default="">
	<cfargument name="spec_money_select" type="string" default="#session_base.money2#"><!--- secili olan para birimi --->
	<cfargument name="spec_row_count" type="numeric"><!--- spec satir sayisi --->
	<cfargument name="stock_id_list" type="string" default=""><!--- satirlarin stock_id leri olmayanlar 0 olarak yollanmali --->
	<cfargument name="product_id_list" type="string" default=""><!--- satirlarin product_id leri olmayanlar 0 olarak yollanmali --->
	<cfargument name="product_space_list" type="string" default=""><!--- (Metrekare)Ürün özelliklerinin en ve boy çarpımında yani max ve min çarpımından bulunan alanı tutar.yok ise 0 gönderilmelidir. --->
	<cfargument name="product_display_list" type="string" default=""><!--- (Metre)Ürün özelliklerinin en ve boy çarpımında yani max ve min çarpımından bulunan çevresini tutar.yok ise 0 gönderilmelidir. --->
	<cfargument name="product_rate_list" type="string" default=""><!--- ( % ) Maliyeti bulurken alan ile çarpılan yüzdelik dilimi ifade eder. Boş ise 0 gönderilmelidir.--->
	<cfargument name="product_name_list" type="string" default=""><!--- satirlarin urun isimleri olmayanlar - olarak yollanmali --->
	<cfargument name="amount_list" type="string" default=""><!--- satirlarin urun miktarlari --->
	<cfargument name="is_sevk_list" type="string" default=""><!--- satirlar sevkte birlestirse 1 degilse 0 --->
    <cfargument name="detail_list" type="string" default="">
	<cfargument name="is_configure_list" type="string" default=""><!--- satirlar configure edilebiliyorsa birlestirse 1 degilse 0 --->
	<cfargument name="is_property_list" type="string" default=""><!--- satirlar ozellik satiri ise 1 sarf ise 0 fire ürünü ise 2 ve operasyon ise 3 set edilmelidir. --->
	<cfargument name="property_id_list" type="string" default=""><!--- satirlar ozellikli ise ozellik idsi --->
	<cfargument name="variation_id_list" type="string" default=""><!--- satirlar ozellikli ise varyasyon idsi --->
	<cfargument name="total_min_list" type="string" default=""><!--- satirlar ozellikli ise total_minler olmayanlarda - yollanmali --->
	<cfargument name="total_max_list" type="string" default=""><!--- satirlar ozellikli ise total_maxlar olmayanlarda - yollanmali--->
	
    <cfargument name="configurator_variation_id_list" type="string" default=""><!--- özellik uniq id (SETUP_PRODUCT_CONFIGURATOR_VARIATION tablosundaki CONFIGURATOR_VARIATION_ID)--->
	<!--- <cfargument name="chapter_id_list" type="string" default=""><!--- ürün konfigüratöründeki bölüm id---> --->
	<cfargument name="dimension_list" type="string" default=""><!---Ölçek varsa gönderili yoksa - gönderilir.. --->
	<!--- <cfargument name="rel_variation_id_list" type="string" default=""><!--- İlişkili varyasyon id varsa gönderlir yoksa 0 atılmalı...---> --->
	<cfargument name="fire_amount_list" type="string" default="">
	<cfargument name="fire_rate_list" type="string" default="">
	<cfargument name="is_free_amount_list" type="string" default="">
	<cfargument name="is_phantom_list" type="string" default="">

	<cfargument name="diff_price_list" type="string" default=""><!--- satirlarda oluşan alternatif urunle ana urun arasındaki fiyat farki--->
	<cfargument name="product_price_list" type="string" default=""><!--- satirlarda oluşan urunlerin fiyatlari--->
	<cfargument name="list_price_list" type="string" default=""><!--- Satırlardaki ürünlerin o anki liste fiyatları yoksa 0 gönderilmelidir. --->
	<cfargument name="product_money_list" type="string" default=""><!--- satirlarda oluşan urun fiyatlarin para birimi--->
	<cfargument name="tolerance_list" type="string" default=""><!--- satirların tolerans yoksa - yollanmali--->
	<cfargument name="spect_file_name" type="string" default=""><!--- Specte dosya eklenirse objects altında tutuyor. --->
	<cfargument name="spect_server_file_name" type="string" default="">
	<cfargument name="old_files" type="string" default="">
	<cfargument name="old_server_id" type="string" default="">
	<cfargument name="del_attach" type="string" default="">
	<cfargument name="spect_status" type="numeric" default="1"><!--- Spect_main tablosundaki spect_status alanını kaydederken 1 olarak atar --->
	<cfargument name="related_spect_id_list" type="string" default=""><!--- satirlardaki üretilen ürünlerin ilişkili [MAIN_SPECT_ID]'si yoksa 0 gönderilmelidir. --->
	<cfargument name="related_spect_name_list" type="string" default=""><!--- satirlardaki üretilen ürünlerin ilişkili [MAIN_SPECT_ID]'lere ait spect isimleri --->
	<cfargument name="spect_detail" type="string" default=""><!--- Spect'in detayları --->
    <cfargument name="line_number_list" type="string"><!--- Ürünün ağaç ve spectdeki kullanım sırası,her yerde kullanılmıyor bu sebeble parametreye bağlı olarak gelicek. --->
    <cfargument name="question_id_list" type="string"><!---Alternatif ürünler seçilirken kullanılacak... --->
    <cfargument name="station_id_list" type="string"><!--- Ürün Ağacında seçilen Default İstasyon... --->
    <cfargument name="upd_spec_main_row" type="string" default=""><!--- Spec Kullanmayan Yerlerde Ürün Ağacı Güncellediği Zaman SpecMain'in Satırlarıda Güncellensin Diye Eklendi!Sadece ÜrünAğacını Kaydederken Gönderiyorum,Başka Yerlerde Kullanması Sıkıntıya Sebebiyet verir.. --->
    <cfargument name="is_limited_stock" type="numeric" default="0"><!--- seri sonu specmi  --->
    <cfargument name="special_code_1" type="string" default=""><!--- özel kod 1 uniq  --->
    <cfargument name="special_code_2" type="string" default=""><!--- özel kod 2 uniq  --->
    <cfargument name="special_code_3" type="string" default=""><!--- özel kod 3  --->
    <cfargument name="special_code_4" type="string" default=""><!--- özel kod 4  --->
	<cfargument name="related_tree_id_list" type="string" default=""><!--- satirlar operasyon  ise operasyonun bağlı bulunduğu ürün ağacının satırının id'si.. idsi yoksa 0 gönderilmelidir. --->
	<cfargument name="operation_type_id_list" type="string" default=""><!--- Satırlar operasyon ise operasyon id'si.. --->
    <cfargument name="is_product_tree_import" type="string" default=""><!--- Sadece Ürün ağacından import yapılıyor ise gönderilir... --->
	<cfargument name="is_control_spect_name" type="string" default="0">
	<cfargument name="is_control_tree" type="string" default="1">
	<cfargument name="is_add_same_name_spect" type="string" default="0"><!--- Aynı isimli spect oluşamasın seçili ise xml de 1 gelir. --->
<!--- <cfdump var="#arguments#">
 <cfabort> --->
 <cfset dsn="catalyst_prod">
 <cfset dsn3="#dsn#_1">
 <cfif isDefined('session.ep.userid')>
	<cfif isdefined("fusebox.use_spect_company") and len(fusebox.use_spect_company) and isdefined("fusebox.spect_company_list") and listfind(fusebox.spect_company_list,session_base.company_id)>
		<cfset new_dsn3 = "#dsn#_#fusebox.use_spect_company#" />
	<cfelse>
		<cfset new_dsn3 = dsn3 />
	</cfif>
<cfelseif isDefined('session.pp.userid')>
	<cfif isdefined("fusebox.use_spect_company") and len(fusebox.use_spect_company) and isdefined("fusebox.spect_company_list") and listfind(fusebox.spect_company_list,session.pp.our_company_id)>
		<cfset new_dsn3 = "#dsn#_#fusebox.use_spect_company#" />
	<cfelse>
		<cfset new_dsn3 = dsn3 />
	</cfif>
<cfelseif isDefined('session.ww.userid')>
	<cfif isdefined("fusebox.use_spect_company") and len(fusebox.use_spect_company) and isdefined("fusebox.spect_company_list") and listfind(fusebox.spect_company_list,session.ww.our_company_id)>
		<cfset new_dsn3 = "#dsn#_#fusebox.use_spect_company#" />
	<cfelse>
		<cfset new_dsn3 = dsn3 />
	</cfif>
<cfelseif isdefined("dsn3")>
	<cfset new_dsn3 = dsn3 />
</cfif>
 	<cfif not isdefined("new_dsn3")><cfset new_dsn3 = arguments.dsn_type /></cfif>
	<cfset is_new_spec = 0 />
	<cfif isdefined('del_attach') and del_attach eq 1>
		<cf_del_server_file output_file="objects/#old_files#" output_server="#old_server_id#">
		<cfquery name="UPD_DEL_ATTACH" datasource="#arguments.dsn_type#">
			UPDATE
				#new_dsn3#.SPECTS
			SET
				FILE_NAME = NULL,
				FILE_SERVER_ID = NULL
			WHERE
				SPECT_VAR_ID=#arguments.spec_id#
		</cfquery>
	</cfif>
	<cfif isdefined('arguments.spect_file_name') and len(arguments.spect_file_name)>
		<cf_del_server_file output_file="objects/#old_files#" output_server="#old_server_id#">
		<cffile action="UPLOAD"
					nameconflict="OVERWRITE" 
					filefield="spect_file_name" 
					destination="#upload_folder#objects#dir_seperator#">
		<cfset file_name_ = "#createUUID()#.#cffile.serverfileext#" />
		<cffile action="rename" source="#upload_folder#objects#dir_seperator##cffile.serverfile#" destination="#upload_folder#objects#dir_seperator##file_name_#">
		<!---Script dosyalarını engelle  02092010 FA-ND --->
		<cfset assetTypeName = listlast(cffile.serverfile,'.') />
		<cfset blackList = 'php,php2,php3,php4,php5,phtml,pwml,inc,asp,aspx,ascx,jsp,cfm,cfml,cfc,pl,bat,exe,com,dll,vbs,reg,cgi,htaccess,asis' />
		<cfif listfind(blackList,assetTypeName,',')>
			<cffile action="delete" file="#upload_folder#objects#dir_seperator##file_name_#">
			<script type="text/javascript">
				alert("\'php\',\'jsp\',\'asp\',\'cfm\',\'cfml\' Formatlarında Dosya Girmeyiniz!!");
				history.back();
			</script>
			<cfabort>
		</cfif>
		<cfset arguments.spect_file_name=file_name_ />
		<cfset arguments.spect_server_file_name = cffile.serverfile />
	</cfif>
	<cfset ayirac='|@|' /><!--- AYIRAC FONSIYONUN CAGRIDILDIGI YERDE DUZELTILINCE BU bolum QUERY VS KALDIRILACAK --->
    <cfif isdefined('arguments.spec_name')>
        <cfset arguments.spec_name=replace(arguments.spec_name,',',' ','all') />
    </cfif>
    <cfif listlen(product_name_list,'#ayirac#') neq listlen(stock_id_list,',')><!--- özellikli olan speclerde aciklama alani kaydediliyor o yuzden o sayfada ayirac duzenlendi diger sayfalarda duznlenmeli --->
        <cfif listlen(arguments.stock_id_list,',')>
            <cfset arguments.product_name_list="" />
            <cfloop list="#arguments.stock_id_list#" delimiters="," index="stk_id">
            <cfif stk_id neq 0>
                <cfquery name="GET_PRODUCT_NAME" datasource="#arguments.dsn_type#">
                    SELECT
                        STOCK_ID,
                        PRODUCT_DETAIL,
                        PRODUCT_NAME,
                        PROPERTY,
						PRODUCT_ID
                    FROM 
                        #new_dsn3#.STOCKS 
                    WHERE 
                        STOCK_ID IN (#stk_id#)
                </cfquery>
                <cfif isdefined('session.ep.userid') or isDefined("session.pda.userid")>
                    <cfif GET_PRODUCT_NAME.recordcount>
                        <cfset pro_name='#GET_PRODUCT_NAME.PRODUCT_NAME# #GET_PRODUCT_NAME.PROPERTY#' />
                        <cfif len(pro_name) gt 150><cfset pro_name=left(pro_name,150) /></cfif>
                        <cfset arguments.product_name_list=listappend(arguments.product_name_list,pro_name,ayirac) />
                    <cfelse>
                        <cfset arguments.product_name_list=listappend(arguments.product_name_list,'-',ayirac) />
                    </cfif>
                <cfelse><!--- partnersa --->
                    <cfif GET_PRODUCT_NAME.recordcount and len(GET_PRODUCT_NAME.PRODUCT_DETAIL)>
                        <cfset pro_name=GET_PRODUCT_NAME.PRODUCT_DETAIL />
                        <cfif len(pro_name) gt 150><cfset pro_name=left(pro_name,150) /></cfif>
                        <cfset arguments.product_name_list=listappend(arguments.product_name_list,pro_name,ayirac) />
                    <cfelse>
                        <cfset pro_name='#GET_PRODUCT_NAME.PRODUCT_NAME# #GET_PRODUCT_NAME.PROPERTY#' />
                        <cfif len(pro_name) gt 150><cfset pro_name=left(pro_name,150) /></cfif>
                        <cfset arguments.product_name_list=listappend(arguments.product_name_list,pro_name,ayirac) />
                    </cfif>
                </cfif>
            <cfelse>
                <cfset arguments.product_name_list=listappend(arguments.product_name_list,'-',ayirac) />
            </cfif>
            </cfloop>
        </cfif>
    </cfif>
	<!--- main_spec ekliyor --->
	<cfif not isdefined("arguments.main_stock_id")>
		<cfset wrk_id = dateformat(now(),'YYYYMMDD')&timeformat(now(),'HHmmss')&'_#session_base.userid#_'&round(rand()*100) />
	<cfelseif isdefined("arguments.spec_row_count")>		
		<cfset wrk_id = dateformat(now(),'YYYYMMDD')&timeformat(now(),'HHmmss')&'_#session_base.userid#_#arguments.main_stock_id#_#arguments.spec_row_count#_'&round(rand()*100) />
	<cfelse>
		<cfset wrk_id = dateformat(now(),'YYYYMMDD')&timeformat(now(),'HHmmss')&'_#session_base.userid#_#arguments.main_stock_id#_'&round(rand()*100) />
	</cfif>
	<cfif not isdefined('arguments.main_spec_id') or not len(arguments.main_spec_id)>
		<cfif arguments.spec_row_count eq 0><!--- Main Spec Oluşturmak İçin Üründe hiçbir sarf olmadığı durumlarda. --->
			<script type="text/javascript">
                alert('Birleşeni Olmayan Ürünler İçin Spec Oluşturamazsınız!');
            </script>
			<cfexit method="exittemplate">
			<cfabort>
		</cfif>
		<!--- 
            Eğer Ana Ürünümüz Özelleştirilebiliyor ise Yeni Main Specler Oluşur,
            Özelleştirilmiyorsa yeni spec oluşmaz,olası bir güncellemede spec_main_row satırları silinerek yeni satırlar eklenir.
            M.ER 27 01 2008 
        --->
        <cfquery name="get_product_info_spec"  datasource="#arguments.dsn_type#">
        	SELECT 
				<cfif arguments.is_add_same_name_spect eq 1><!--- eğer aynı isimle spect eklenemesin denmişse sadece isme göre kontrol yapsın diye özelleştirilebilir değeri 0 yapılıyor --->
					0 IS_PROTOTYPE
				<cfelse>
					ISNULL(IS_PROTOTYPE,0) AS IS_PROTOTYPE
				</cfif>,
				ISNULL(IS_PROTOTYPE,0) AS IS_PROTOTYPE_OLD,
				PRODUCT_ID 
			FROM 
				#new_dsn3#.STOCKS 
			WHERE 
				STOCK_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.main_stock_id#">
        </cfquery>
		<cfif isdefined("arguments.main_product_id") and (arguments.main_product_id eq 0 or not len(arguments.main_product_id))><cfset arguments.main_product_id = get_product_info_spec.PRODUCT_ID></cfif>
        <cfquery name="GET_SPECT" datasource="#arguments.dsn_type#">
	        <cfif get_product_info_spec.IS_PROTOTYPE eq 1 and not len(arguments.is_product_tree_import)>
				SELECT 
					COUNT(SPECT_MAIN_ROW.SPECT_MAIN_ROW_ID),
					SPECT_MAIN.SPECT_MAIN_ID,
					SPECT_MAIN.SPECT_MAIN_NAME
				FROM 
					#new_dsn3#.SPECT_MAIN_ROW SPECT_MAIN_ROW,
					#new_dsn3#.SPECT_MAIN SPECT_MAIN
				WHERE
					SPECT_MAIN.SPECT_STATUS=1 AND 
					SPECT_MAIN.STOCK_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.main_stock_id#"> AND
					SPECT_MAIN_ROW.SPECT_MAIN_ID=SPECT_MAIN.SPECT_MAIN_ID AND
					(
						<cfloop from="1" to="#arguments.spec_row_count#" index="ii">
							(
								IS_SEVK = <cfqueryparam cfsqltype="cf_sql_smallint" value="#listgetat(arguments.is_sevk_list,ii,',')#">
								AND SPECT_MAIN_ROW.AMOUNT = <cfqueryparam cfsqltype="cf_sql_float" value="#listgetat(arguments.amount_list,ii,',')#">
								AND SPECT_MAIN_ROW.IS_PROPERTY = <cfqueryparam cfsqltype="cf_sql_integer" value="#listgetat(arguments.is_property_list,ii,',')#">
								<cfif listgetat(arguments.stock_id_list,ii,',') gt 0>
									AND	SPECT_MAIN_ROW.STOCK_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#listgetat(arguments.stock_id_list,ii,',')#">
								</cfif>
								<cfif isdefined('arguments.related_spect_id_list') and listlen(arguments.related_spect_id_list,',')>
									<cfif listgetat(arguments.related_spect_id_list,ii,',') neq 0>
										AND	SPECT_MAIN_ROW.RELATED_MAIN_SPECT_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#listgetat(arguments.related_spect_id_list,ii,',')#">
									</cfif>
								<cfelse>
									AND	SPECT_MAIN_ROW.RELATED_MAIN_SPECT_ID IS NULL
								</cfif>
								<cfif isdefined('arguments.property_id_list') and listgetat(arguments.property_id_list,ii,',') gt 0>
									AND SPECT_MAIN_ROW.PROPERTY_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#listgetat(property_id_list,ii,',')#">
								</cfif>
								<cfif isdefined('arguments.operation_type_id_list') and listlen(arguments.operation_type_id_list) and listgetat(arguments.operation_type_id_list,ii,',') gt 0>
									AND SPECT_MAIN_ROW.OPERATION_TYPE_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#listgetat(operation_type_id_list,ii,',')#">
								</cfif>
								
								<cfif isdefined('arguments.variation_id_list') and listgetat(arguments.variation_id_list,ii,',') gt 0>
									AND SPECT_MAIN_ROW.VARIATION_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#listgetat(variation_id_list,ii,',')#">
								</cfif>
								<cfif isdefined('arguments.total_min_list') and listgetat(arguments.total_min_list,ii,',') gt 0>
									AND SPECT_MAIN_ROW.TOTAL_MIN = <cfqueryparam cfsqltype="cf_sql_float" value="#listgetat(arguments.total_min_list,ii,',')#">
								</cfif>
								<cfif isdefined('arguments.total_max_list') and listgetat(arguments.total_max_list,ii,',') gt 0>
									AND SPECT_MAIN_ROW.TOTAL_MAX = <cfqueryparam cfsqltype="cf_sql_float" value="#listgetat(arguments.total_max_list,ii,',')#">
								</cfif>
								<cfif isdefined('arguments.tolerance_list') and listgetat(arguments.tolerance_list,ii,',') neq '-'>
									AND SPECT_MAIN_ROW.TOLERANCE = <cfqueryparam cfsqltype="cf_sql_integer" value="#listgetat(arguments.tolerance_list,ii,',')#">
								</cfif>
								<cfif isdefined('arguments.product_space_list') and len(arguments.product_space_list) and listgetat(arguments.product_space_list,ii,',') gt 0>
									AND SPECT_MAIN_ROW.PRODUCT_SPACE = <cfqueryparam cfsqltype="cf_sql_float" value="#listgetat(arguments.product_space_list,ii,',')#">
								</cfif>
								<cfif isdefined('arguments.product_display_list') and len(arguments.product_display_list) and listgetat(arguments.product_display_list,ii,',') gt 0>
									AND SPECT_MAIN_ROW.PRODUCT_DISPLAY = <cfqueryparam cfsqltype="cf_sql_float" value="#listgetat(arguments.product_display_list,ii,',')#">
								</cfif>
								<cfif isdefined('arguments.product_rate_list') and len(arguments.product_rate_list) and listgetat(arguments.product_rate_list,ii,',') gt 0>
									AND SPECT_MAIN_ROW.PRODUCT_RATE = <cfqueryparam cfsqltype="cf_sql_float" value="#listgetat(arguments.product_rate_list,ii,',')#">
								</cfif>
								<cfif isdefined('arguments.question_id_list') and len(arguments.question_id_list) and listgetat(arguments.question_id_list,ii,',') gt 0>
									AND SPECT_MAIN_ROW.QUESTION_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#listgetat(arguments.question_id_list,ii,',')#">
								</cfif>
								<!--- <cfif isdefined('arguments.calculate_type_list') and len(arguments.calculate_type_list) and listgetat(arguments.calculate_type_list,ii,',') gt 0 >
									AND SPECT_MAIN_ROW.CALCULATE_TYPE = <cfqueryparam cfsqltype="cf_sql_integer" value="#listgetat(arguments.calculate_type_list,ii,',')#">
								</cfif> --->
							) 
							<cfif listlen(arguments.stock_id_list,',') gt ii>OR</cfif>
						</cfloop>
					)
					AND (SELECT COUNT(SMR.SPECT_MAIN_ROW_ID) FROM #new_dsn3#.SPECT_MAIN_ROW SMR WHERE SMR.SPECT_MAIN_ID=SPECT_MAIN.SPECT_MAIN_ID) = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.spec_row_count#">
				GROUP BY SPECT_MAIN.SPECT_MAIN_ID,SPECT_MAIN.SPECT_MAIN_NAME
				HAVING COUNT(SPECT_MAIN_ROW.SPECT_MAIN_ROW_ID) = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.spec_row_count#">
            <cfelse>
            	SELECT TOP 1 SPECT_MAIN_ID,SPECT_MAIN_NAME FROM #new_dsn3#.SPECT_MAIN SM WHERE SM.SPECT_STATUS=1 AND SM.STOCK_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.main_stock_id#"> <cfif arguments.is_control_tree eq 1 and not(arguments.is_control_spect_name eq 1 and get_product_info_spec.is_prototype_old eq 1)>AND SM.IS_TREE = 1</cfif> <cfif arguments.is_control_spect_name eq 1 and get_product_info_spec.is_prototype_old eq 1>AND SM.SPECT_MAIN_NAME = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.spec_name#"></cfif> ORDER BY SM.RECORD_DATE DESC,SM.UPDATE_DATE DESC
            </cfif>
		</cfquery>
        <!--- <cfdump var="#GET_SPECT#"><cfoutput>[#get_product_info_spec.IS_PROTOTYPE#]--#arguments.is_product_tree_import#</cfoutput><cfabort> ---->
		<cfif GET_SPECT.RECORDCOUNT eq 0>
		<cfif not len(arguments.main_product_id)>
				<cfquery name="get_prod_id" datasource="#arguments.dsn_type#">
					SELECT PRODUCT_ID FROM #new_dsn3#.STOCKS WHERE STOCK_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.main_stock_id#">
				</cfquery>
				<cfset arguments.main_product_id = get_prod_id.product_id />
			</cfif>
			<cfquery name="ADD_VAR_SPECT" datasource="#arguments.dsn_type#">
				INSERT INTO
					#new_dsn3#.SPECT_MAIN
					(
						SPECT_MAIN_NAME,
						SPECT_TYPE,
						PRODUCT_ID,
						STOCK_ID,
						IS_TREE,
						SPECT_STATUS,
						RECORD_IP,
						<cfif isDefined("session.pp")>
                            RECORD_PAR,
                        <cfelseif isDefined("session.ww")>
                            RECORD_CON,
                        <cfelse>
                            RECORD_EMP,
                        </cfif>
						RECORD_DATE,
                        FUSEACTION,
                        IS_LIMITED_STOCK,
                        SPECIAL_CODE_1,
                        SPECIAL_CODE_2,
                        SPECIAL_CODE_3,
                        SPECIAL_CODE_4,
                        WRK_ID
					)
					VALUES
					(
						'#left(arguments.spec_name,500)#',
						#arguments.spec_type#,
						#arguments.main_product_id#,
						#arguments.main_stock_id#,
						#arguments.spec_is_tree#,
						#arguments.spect_status#,
						'#cgi.remote_addr#',
						<cfif isdefined('session_base.userid')>
							#session_base.userid#,
						<cfelse>
							NULL,
						</cfif>
						#now()#,
                        '',
                        <cfif isdefined('arguments.is_limited_stock') and len(arguments.is_limited_stock)>#arguments.is_limited_stock#<cfelse>NULL</cfif>,
                        <cfif isdefined('arguments.special_code_1') and len(arguments.special_code_1)>'#arguments.special_code_1#'<cfelse>NULL</cfif>,
                        <cfif isdefined('arguments.special_code_2') and len(arguments.special_code_2)>'#arguments.special_code_2#'<cfelse>NULL</cfif>,
                        <cfif isdefined('arguments.special_code_3') and len(arguments.special_code_3)>'#arguments.special_code_3#'<cfelse>NULL</cfif>,
                        <cfif isdefined('arguments.special_code_4') and len(arguments.special_code_4)>'#arguments.special_code_4#'<cfelse>NULL</cfif>,
						'#wrk_id#'
					)
			</cfquery>
			<cfquery name="GET_MAX_ID" datasource="#arguments.dsn_type#">
				SELECT MAX(SPECT_MAIN_ID) AS MAX_ID FROM #new_dsn3#.SPECT_MAIN WHERE WRK_ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#wrk_id#">
			</cfquery>
			<cfset main_spec_id=get_max_id.max_id />
			<cfset is_new_spec = 1 />
            <cfset DSN2_ALIAS ="#dsn#_#year(now())#_1">
			<cfquery name="INSRT_STK_ROW" datasource="#arguments.dsn_type#">
				INSERT INTO #dsn2_alias#.STOCKS_ROW 
					(
						STOCK_ID,
						PRODUCT_ID,
						SPECT_VAR_ID
					)
				VALUES 
					(
						#arguments.main_stock_id#,
						#arguments.main_product_id#,
						#main_spec_id#
					)
			</cfquery>
            <!--- Main Spec Satırlarının Oluşturuyor.. --->
            <cfinclude template="/Modules/objects/query/add_main_spec_row.cfm" />
		<cfelse>
			<cfif arguments.is_control_spect_name eq 1 and isdefined("GET_SPECT")>
				<cfquery name="GET_SPECT_NEW" dbtype="query">
					SELECT * FROM GET_SPECT WHERE SPECT_MAIN_NAME = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.spec_name#">
				</cfquery>
				<cfif GET_SPECT_NEW.recordcount>
					<cfset main_spec_id=GET_SPECT_NEW.SPECT_MAIN_ID />
				<cfelse>
					<cfset main_spec_id=GET_SPECT.SPECT_MAIN_ID />
				</cfif>
			<cfelse>
				<cfset main_spec_id=GET_SPECT.SPECT_MAIN_ID />
			</cfif>
        	<cfif arguments.spec_is_tree eq 1><!--- Eğerki ürün ağacından ağaç varyasyonlanıyorsa,ağaçta oluşturulan main_spec daha önceden oluşturulmuş ise ağaçın şu andaki    varyasyonu is_tree = 1 olmalıdır o sebeble burda is_tree'yi 1 olarak set edicez. --->
                <cfquery name="upd_main_spec_is_tree" datasource="#arguments.dsn_type#"><!--- İlk önce diğer main_speclerin hepsinin is_tree'sini boşaltıyoruz. --->
                    UPDATE #new_dsn3#.SPECT_MAIN SET IS_TREE = 0 WHERE STOCK_ID = #arguments.MAIN_STOCK_ID#
                </cfquery>
                <cfquery name="upd_main_spec_is_tree" datasource="#arguments.dsn_type#"><!--- daha sonra is_tree'yi 1 olarak set ediyoruz. --->
                    UPDATE #new_dsn3#.SPECT_MAIN SET IS_TREE = 1 WHERE SPECT_MAIN_ID = #main_spec_id#
                </cfquery>
			</cfif>
            <!--- Özelliştirilmiyor ve ÜrünAğacından Güncelleme Yapılıyor İse SpecMain Satırları Güncelleniyor... --->
			<cfif get_product_info_spec.IS_PROTOTYPE eq 0 and isdefined('arguments.upd_spec_main_row') and arguments.upd_spec_main_row eq 1><!--- Eğerki ürün özelleştirilmiyor ise ve main spec'e ait kayıt bulunmuş ise önce main_spec'in satırlarını silicez,daha sonra fonksiyondan gelen değerlerle yeniden set ediyoruz,bu şekilde yeni bir spec oluşmadan ürünün son spec'ini ağacınının son hali ile oluşturmuş oluyoruz..Bir nevi güncelleme! --->
                <!--- Ürün  Konfig. Edilmediği İçin Ürün Ağacındaki En Son Halini Varolan MainSpec'inin satırları yapıyoruz,önce satırları sildik,daha sonra fonksiyona gelen değerlere göre yeniden satırları yazıcaz. --->
                <cfquery name="DELETE_MAIN_SPEC_ROW" datasource="#arguments.dsn_type#">
                    DELETE #new_dsn3#.SPECT_MAIN_ROW WHERE SPECT_MAIN_ID = #GET_SPECT.SPECT_MAIN_ID# 
                </cfquery>
                <!--- Main Spec Satırlarının Oluşturuyor.. --->
                <cfinclude template="../V16/objects/query/add_main_spec_row.cfm" />
            </cfif>
		</cfif>
	<cfelse>
		<cfset main_spec_id=arguments.main_spec_id />
	</cfif>
	<cfif arguments.only_main_spec eq 0>
		<!--- fiyatlar : main_specden eklenecekse veya fiyat listeleri yollanmadi ise fiyatlar alinir--->
		<cfif len(main_spec_id) and (isdefined('arguments.add_to_main_spec') and arguments.add_to_main_spec) or (listlen(arguments.product_price_list,',') eq 0 and listlen(arguments.product_money_list,',') eq 0)>
			<cfset product_id_list_2="" />
			<cfset stock_id_list_2="" />
			<cfif isdefined('arguments.add_to_main_spec') and arguments.add_to_main_spec eq 1><!--- main_specden ekleniyorsa urunler aliniyor listeye atiliyor--->
				<cfquery name="GET_MAIN_SPEC" datasource="#arguments.dsn_type#">
					SELECT 
                    	SPECT_MAIN.SPECIAL_CODE_1,
                        SPECT_MAIN.IS_LIMITED_STOCK,
                        SPECT_MAIN.SPECIAL_CODE_2,
                        SPECT_MAIN.SPECIAL_CODE_3,
                        SPECT_MAIN.SPECIAL_CODE_4,
						SPECT_MAIN.SPECT_MAIN_NAME,
						SPECT_MAIN.SPECT_TYPE,
						SPECT_MAIN.STOCK_ID MAIN_STOCK_ID,
						SPECT_MAIN.PRODUCT_ID MAIN_PRODUCT_ID,
						SPECT_MAIN.IS_TREE,
						SPECT_MAIN_ROW.* 
					FROM 
						#new_dsn3#.SPECT_MAIN SPECT_MAIN,
						#new_dsn3#.SPECT_MAIN_ROW SPECT_MAIN_ROW
					WHERE
						SPECT_MAIN.SPECT_MAIN_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#main_spec_id#">
						AND SPECT_MAIN.SPECT_MAIN_ID=SPECT_MAIN_ROW.SPECT_MAIN_ID
				</cfquery>
				<cfif not GET_MAIN_SPEC.RECORDCOUNT>
					<script type="text/javascript">
						alert('<cfoutput>#arguments.main_spec_id#</cfoutput> ID Numarasına Sahip Spec"in Satirlari yok! Ağacı Kontrol ediniz');
						//history.go(-1);
					</script>
                    <cfexit method="exittemplate">
					<cfabort>
				<cfelse>
					<cfset main_product=GET_MAIN_SPEC.MAIN_PRODUCT_ID />
					<cfset arguments.product_id_list = valuelist(GET_MAIN_SPEC.PRODUCT_ID,',') />
					<cfset arguments.stock_id_list = valuelist(GET_MAIN_SPEC.STOCK_ID,',') />
					<cfset product_id_list_2 = ListAppend(arguments.product_id_list,GET_MAIN_SPEC.MAIN_PRODUCT_ID,',') />
					<cfset stock_id_list_2 = ListAppend(arguments.stock_id_list,GET_MAIN_SPEC.MAIN_STOCK_ID,',') />
				</cfif>
			<cfelseif listlen(arguments.product_id_list,',') and listlen(arguments.stock_id_list,',')><!--- urun listeleri geldi ise --->
				<cfset product_id_list_2=arguments.product_id_list />
				<cfset stock_id_list_2=arguments.stock_id_list />
				<cfset product_id_list_2=listappend(product_id_list_2,arguments.main_product_id,',') />
				<cfset stock_id_list_2=listappend(stock_id_list_2,arguments.main_stock_id,',') />
				<cfset main_product=arguments.main_product_id />
			</cfif>
			<cfset arguments.product_id_list=Replace(arguments.product_id_list,',,',',','all') />
			<cfset arguments.product_id_list=Replace(arguments.product_id_list,', ,',',','all') />
			<cfset arguments.stock_id_list=Replace(arguments.stock_id_list,',,','','all') />
			<cfset arguments.stock_id_list=Replace(arguments.stock_id_list,', ,','','all') />
			<cfset product_id_list_2=Replace(product_id_list_2,',,',',','all') />
			<cfset product_id_list_2=Replace(product_id_list_2,', ,','','all') />
			<cfset stock_id_list_2=Replace(stock_id_list_2,',,','','all') />
			<cfset stock_id_list_2=Replace(stock_id_list_2,', ,','','all') />
			<!--- uyenin fiyat listesini bulmak icin--->
			<cfif arguments.is_purchasesales eq 1><!--- satissa sadece buraya girer alis ise sadece standart alis fiyatini almali --->
				<cfif arguments.company_id gt 0>
					<cfquery name="GET_PRICE_CAT_CREDIT" datasource="#arguments.dsn_type#">
						SELECT PRICE_CAT FROM #dsn_alias#.COMPANY_CREDIT WHERE COMPANY_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.company_id#"> AND OUR_COMPANY_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#session_base.company_id#">
					</cfquery>
					<cfif GET_PRICE_CAT_CREDIT.RECORDCOUNT and len(GET_PRICE_CAT_CREDIT.PRICE_CAT)>
						<cfset attributes.price_catid=GET_PRICE_CAT_CREDIT.PRICE_CAT />
					<cfelse>
						<cfquery name="GET_COMP_CAT" datasource="#arguments.dsn_type#">
							SELECT COMPANYCAT_ID FROM #dsn_alias#.COMPANY WHERE COMPANY_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.company_id#">
						</cfquery>
						<cfquery name="GET_PRICE_CAT_COMP" datasource="#arguments.dsn_type#">
							SELECT PRICE_CATID FROM #dsn3_alias#.PRICE_CAT PRICE_CAT WHERE COMPANY_CAT LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%,#GET_COMP_CAT.COMPANYCAT_ID#,%">
						</cfquery>
						<cfset attributes.price_catid=GET_PRICE_CAT_COMP.PRICE_CATID />
					</cfif>
				</cfif>
				<cfif arguments.consumer_id gt 0>
					<cfquery name="GET_COMP_CAT" datasource="#arguments.dsn_type#">
						SELECT CONSUMER_CAT_ID FROM #dsn_alias#.CONSUMER WHERE CONSUMER_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.consumer_id#">
					</cfquery>
					<cfquery name="GET_PRICE_CAT" datasource="#arguments.dsn_type#">
						SELECT PRICE_CATID FROM #dsn3_alias#.PRICE_CAT WHERE CONSUMER_CAT LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%,#get_comp_cat.consumer_cat_id#,%">
					</cfquery>
					<cfset attributes.price_catid=get_price_cat.PRICE_CATID />
				</cfif>
				<!--- //uyenin fiyat listesini bulmak icin--->
				<cfif isdefined("attributes.price_catid") and len(attributes.price_catid)>
					<cfquery name="GET_PRICE" datasource="#arguments.dsn_type#">
						SELECT
							PRICE_STANDART.PRODUCT_ID,
							PRICE_STANDART.MONEY,
							PRICE_STANDART.PRICE
						FROM
							#dsn3_alias#.PRICE PRICE_STANDART,	
							#dsn3_alias#.PRODUCT_UNIT PRODUCT_UNIT
						WHERE
							PRICE_STANDART.PRICE_CATID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.price_catid#"> AND
							PRICE_STANDART.STARTDATE < <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.action_date#"> AND 
							(PRICE_STANDART.FINISHDATE >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.action_date#"> OR PRICE_STANDART.FINISHDATE IS NULL) AND
							PRODUCT_UNIT.PRODUCT_ID = PRICE_STANDART.PRODUCT_ID AND 
							ISNULL(PRICE_STANDART.STOCK_ID,0)=0 AND
							ISNULL(PRICE_STANDART.SPECT_VAR_ID,0)=0 AND
							PRICE_STANDART.PRODUCT_ID IN (#listsort(product_id_list_2,"numeric","ASC",",")#) AND 
							PRODUCT_UNIT.IS_MAIN = 1
					</cfquery>
				</cfif>
			</cfif>
            <cfset DSN3_ALIAS ="#dsn#_1">
            <cfset DSN1_ALIAS ="#dsn#_product">
			<cfquery name="GET_PRICE_STANDART" datasource="#arguments.dsn_type#">
				SELECT
					PRICE_STANDART.PRODUCT_ID,
					PRICE_STANDART.MONEY,
					PRICE_STANDART.PRICE
				FROM
					#dsn3_alias#.PRODUCT PRODUCT,
					#dsn3_alias#.PRICE_STANDART PRICE_STANDART
				WHERE
					PRODUCT.PRODUCT_ID = PRICE_STANDART.PRODUCT_ID AND
					PURCHASESALES = <cfif arguments.is_purchasesales eq 1>1<cfelse>0</cfif> AND
					PRICESTANDART_STATUS = 1 AND
					PRODUCT.PRODUCT_ID IN (#listsort(product_id_list_2,"numeric","ASC",",")#)
			</cfquery>
			<cfif isdefined("attributes.price_catid") and len(attributes.price_catid)>
				<cfquery name="GET_PRICE_MAIN_PROD" dbtype="query">
					SELECT * FROM GET_PRICE WHERE PRODUCT_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#main_product#">
				  </cfquery>
			</cfif>
			<cfif not isdefined("GET_PRICE_MAIN_PROD") or GET_PRICE_MAIN_PROD.RECORDCOUNT eq 0>
				<cfquery name="GET_PRICE_MAIN_PROD" dbtype="query">
					SELECT * FROM GET_PRICE_STANDART WHERE PRODUCT_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#main_product#">
				</cfquery>
			</cfif>
			<cfscript>
			if(listlen(arguments.product_id_list,',') and listlen(arguments.stock_id_list,','))
			{
				if(not isdefined('arguments.spec_total_value') or not len(arguments.spec_total_value))
				{
					if(GET_PRICE_MAIN_PROD.MONEY eq session_base.money)
					{
						arguments.spec_total_value=GET_PRICE_MAIN_PROD.PRICE;
					}
					else
					{
						//urun fiyati sistem para biriminden farkli ise once sisteme ceviriyoz
						money_pos=listfind(arguments.money_list,GET_PRICE_MAIN_PROD.MONEY,',');
						if(money_pos)
							arguments.spec_total_value=GET_PRICE_MAIN_PROD.PRICE*(listgetat(arguments.money_rate2_list,money_pos,','));
						else
							arguments.spec_total_value=GET_PRICE_MAIN_PROD.PRICE;//para birimi yoksa setup_moneyde direk fiyatı atıyoruz
					}
				}
				arguments.main_prod_price=GET_PRICE_MAIN_PROD.PRICE;
				arguments.main_product_money=GET_PRICE_MAIN_PROD.MONEY;
				if(not isdefined('arguments.spec_other_total_value') or not len(arguments.spec_other_total_value) or not arguments.spec_other_total_value gt 0)arguments.spec_other_total_value=GET_PRICE_MAIN_PROD.PRICE;
				if(not isdefined('arguments.other_money') or not len(arguments.other_money))arguments.other_money=GET_PRICE_MAIN_PROD.MONEY;
				arguments.spec_row_count=listlen(arguments.product_id_list,',');
				for(s=1;s lte arguments.spec_row_count;s=s+1)
				{//product_id 0 dan fakli ise fiyati alinir degilse 0 atiyoz
					if(listgetat(arguments.product_id_list,s,',') gt 0 and isdefined("attributes.price_catid") and len(attributes.price_catid))
						GET_PRICE_PROD = cfquery(SQLString:"SELECT * FROM GET_PRICE WHERE PRODUCT_ID=#listgetat(arguments.product_id_list,s,',')#",Datasource:dsn3,dbtype:1,is_select:1);	
					if(listgetat(arguments.product_id_list,s,',') gt 0 and (not isdefined("GET_PRICE_PROD") or GET_PRICE_PROD.RECORDCOUNT eq 0) and isdefined("cfquery"))
						GET_PRICE_PROD = cfquery(SQLString:"SELECT * FROM GET_PRICE_STANDART WHERE PRODUCT_ID=#listgetat(arguments.product_id_list,s,',')#",Datasource:dsn3,dbtype:1,is_select:1);	
					if(isdefined('GET_PRICE_PROD') and len(GET_PRICE_PROD.PRICE))
					{
						arguments.product_price_list=listappend(arguments.product_price_list,GET_PRICE_PROD.PRICE,',');
						arguments.product_money_list=listappend(arguments.product_money_list,GET_PRICE_PROD.MONEY,',');
					}
					else
					{
						arguments.product_price_list=listappend(arguments.product_price_list,0,',');
						arguments.product_money_list=listappend(arguments.product_money_list,session_base.money,',');
					}
				}
			}
			</cfscript>
		</cfif>
		<cfif len(main_spec_id) and isdefined('arguments.add_to_main_spec') and arguments.add_to_main_spec><!--- spec main spec den eklenecekse listeler oluşturulacak --->		
			<cfscript>
				arguments.stock_id_list='';
				arguments.product_id_list='';
				arguments.line_number_list='';
				arguments.question_id_list='';
				arguments.spec_is_tree=GET_MAIN_SPEC.IS_TREE;
				arguments.spec_type=GET_MAIN_SPEC.SPECT_TYPE;
				arguments.main_stock_id=GET_MAIN_SPEC.MAIN_STOCK_ID;
				arguments.main_product_id=GET_MAIN_SPEC.MAIN_PRODUCT_ID;
				arguments.spec_name=GET_MAIN_SPEC.SPECT_MAIN_NAME;
				
				arguments.special_code_1=GET_MAIN_SPEC.SPECIAL_CODE_1;
				arguments.special_code_2=GET_MAIN_SPEC.SPECIAL_CODE_2;
				arguments.special_code_3=GET_MAIN_SPEC.SPECIAL_CODE_3;
				arguments.special_code_4=GET_MAIN_SPEC.SPECIAL_CODE_4;
				arguments.is_limited_stock=GET_MAIN_SPEC.IS_LIMITED_STOCK;
				//para birimi listelerinden eksik bir deger varsa listeler olusturulacak
				if(listlen(arguments.money_list,',') eq 0 or listlen(arguments.money_rate1_list,',') or listlen(arguments.money_rate2_list,',') eq 0)
				{
					if(isdefined("session.ep.company_id"))
						GET_MONEY_SPEC = cfquery(SQLString:'SELECT MONEY AS MONEY_TYPE,RATE2,RATE1 FROM #dsn_alias#.SETUP_MONEY SETUP_MONEY WHERE COMPANY_ID=#session.ep.company_id# AND PERIOD_ID=#session_base.period_id# AND MONEY_STATUS=1',Datasource:arguments.dsn_type,is_select:1);	
					else
						GET_MONEY_SPEC = cfquery(SQLString:'SELECT MONEY AS MONEY_TYPE,RATE2,RATE1 FROM #dsn_alias#.SETUP_MONEY SETUP_MONEY WHERE COMPANY_ID=#session_base.our_company_id# AND PERIOD_ID=#session_base.period_id# AND MONEY_STATUS=1',Datasource:arguments.dsn_type,is_select:1);	
					
					for(a=1;a lte GET_MONEY_SPEC.RECORDCOUNT;a=a+1)
					{
						arguments.money_list=listappend(arguments.money_list,GET_MONEY_SPEC.MONEY_TYPE[a],',');
						arguments.money_rate1_list=listappend(arguments.money_rate1_list,GET_MONEY_SPEC.RATE1[a],',');
						arguments.money_rate2_list=listappend(arguments.money_rate2_list,GET_MONEY_SPEC.RATE2[a],',');
					}
				}
				if(GET_PRICE_MAIN_PROD.MONEY eq session_base.money)
				{
					arguments.spec_total_value=GET_PRICE_MAIN_PROD.PRICE;
				}
				else
				{
					//urun fiyati sistem para biriminden farkli ise once sisteme ceviriyoz
					money_pos=listfind(arguments.money_list,GET_PRICE_MAIN_PROD.MONEY,',');
					if(money_pos)
						arguments.spec_total_value=GET_PRICE_MAIN_PROD.PRICE*(listgetat(arguments.money_rate2_list,money_pos,','));
					else
							arguments.spec_total_value=GET_PRICE_MAIN_PROD.PRICE;//para birimi yoksa setup_moneyde direk fiyatı atıyoruz
				}
				arguments.main_prod_price=GET_PRICE_MAIN_PROD.PRICE;
				arguments.main_product_money=GET_PRICE_MAIN_PROD.MONEY;
				arguments.spec_other_total_value=GET_PRICE_MAIN_PROD.PRICE;
				arguments.other_money=GET_PRICE_MAIN_PROD.MONEY;

				arguments.spec_row_count=GET_MAIN_SPEC.RECORDCOUNT;
				for(s=1;s lte GET_MAIN_SPEC.RECORDCOUNT;s=s+1)
				{
					if(GET_MAIN_SPEC.STOCK_ID[s] gt 0)
						arguments.stock_id_list=listappend(arguments.stock_id_list,GET_MAIN_SPEC.STOCK_ID[s],',');
					else
						arguments.stock_id_list=listappend(arguments.stock_id_list,0,',');
						
					if(GET_MAIN_SPEC.PRODUCT_ID[s] gt 0)
						arguments.product_id_list=listappend(arguments.product_id_list,GET_MAIN_SPEC.PRODUCT_ID[s],',');
					else
						arguments.product_id_list=listappend(arguments.product_id_list,0,',');
					
					if(len(GET_MAIN_SPEC.PRODUCT_NAME[s]))
						arguments.product_name_list=listappend(arguments.product_name_list,GET_MAIN_SPEC.PRODUCT_NAME[s],ayirac);
					else
						arguments.product_name_list=listappend(arguments.product_name_list,'-',ayirac);
					
					/*if(len(GET_MAIN_SPEC.RELATED_MAIN_SPECT_ID[s]))
						arguments.related_spect_id_list=listappend(arguments.related_spect_id_list,GET_MAIN_SPEC.RELATED_MAIN_SPECT_ID[s],',');
					else
						arguments.related_spect_id_list=listappend(arguments.related_spect_id_list,0,',');
					*/
					if(len(GET_MAIN_SPEC.PRODUCT_NAME[s]))
						arguments.amount_list=listappend(arguments.amount_list,GET_MAIN_SPEC.AMOUNT[s],',');
					else
						arguments.amount_list=listappend(arguments.amount_list,0,',');
	
					if(len(GET_MAIN_SPEC.IS_SEVK[s]))
						arguments.is_sevk_list=listappend(arguments.is_sevk_list,GET_MAIN_SPEC.IS_SEVK[s],',');
					else
						arguments.is_sevk_list=listappend(arguments.is_sevk_list,0,',');
					
					
					if(len(GET_MAIN_SPEC.IS_CONFIGURE[s]))
						arguments.is_configure_list=listappend(arguments.is_configure_list,GET_MAIN_SPEC.IS_CONFIGURE[s],',');
					else
						arguments.is_configure_list=listappend(arguments.is_configure_list,0,',');
					
					if(len(GET_MAIN_SPEC.IS_PROPERTY[s]))
						arguments.is_property_list=listappend(arguments.is_property_list,GET_MAIN_SPEC.IS_PROPERTY[s],',');
					else
						arguments.is_property_list=listappend(arguments.is_property_list,0,',');
	
					if(len(GET_MAIN_SPEC.PROPERTY_ID[s]))
						arguments.property_id_list=listappend(arguments.property_id_list,GET_MAIN_SPEC.PROPERTY_ID[s],',');
					else
						arguments.property_id_list=listappend(arguments.property_id_list,0,',');
					
					//operasyon yada ürünlerin ilişkili product_tree_id'si..
					if(len(GET_MAIN_SPEC.RELATED_TREE_ID[s]))
						arguments.related_tree_id_list=listappend(arguments.related_tree_id_list,GET_MAIN_SPEC.RELATED_TREE_ID[s],',');
					else
						arguments.related_tree_id_list=listappend(arguments.related_tree_id_list,0,',');
					//operasyon_id'si..
					if(len(GET_MAIN_SPEC.OPERATION_TYPE_ID[s]))
						arguments.operation_type_id_list=listappend(arguments.operation_type_id_list,GET_MAIN_SPEC.OPERATION_TYPE_ID[s],',');
					else
						arguments.operation_type_id_list=listappend(arguments.operation_type_id_list,0,',');
					
					
					
					if(len(GET_MAIN_SPEC.VARIATION_ID[s]))
						arguments.variation_id_list=listappend(arguments.variation_id_list,GET_MAIN_SPEC.VARIATION_ID[s],',');
					else
						arguments.variation_id_list=listappend(arguments.variation_id_list,0,',');
					
					if(len(GET_MAIN_SPEC.TOTAL_MIN[s]))
						arguments.total_min_list=listappend(arguments.total_min_list,GET_MAIN_SPEC.TOTAL_MIN[s],',');
					else
						arguments.total_min_list=listappend(arguments.total_min_list,'-',',');
					
					if(len(GET_MAIN_SPEC.TOTAL_MAX[s]))
						arguments.total_max_list=listappend(arguments.total_max_list,GET_MAIN_SPEC.TOTAL_MAX[s],',');
					else
						arguments.total_max_list=listappend(arguments.total_max_list,'-',',');
				
					if(len(GET_MAIN_SPEC.CONFIGURATOR_VARIATION_ID[s]))
						arguments.configurator_variation_id_list=listappend(arguments.configurator_variation_id_list,GET_MAIN_SPEC.CONFIGURATOR_VARIATION_ID[s],',');
					else
						arguments.configurator_variation_id_list=listappend(arguments.configurator_variation_id_list,0,',');
					/*
					if(len(GET_MAIN_SPEC.CHAPTER_ID[s]))
						arguments.chapter_id_list=listappend(arguments.chapter_id_list,GET_MAIN_SPEC.CHAPTER_ID[s],',');
					else
						arguments.chapter_id_list=listappend(arguments.chapter_id_list,0,',');
					*/	
					if(len(GET_MAIN_SPEC.DIMENSION[s]))
						arguments.dimension_list=listappend(arguments.dimension_list,GET_MAIN_SPEC.DIMENSION[s],',');
					else
						arguments.dimension_list=listappend(arguments.dimension_list,'-',',');
						
					/*if(len(GET_MAIN_SPEC.REL_VARIATION_ID[s]))
						arguments.rel_variation_id_list=listappend(arguments.rel_variation_id_list,GET_MAIN_SPEC.REL_VARIATION_ID[s],',');
					else
						arguments.rel_variation_id_list=listappend(arguments.rel_variation_id_list,0,',');
					*/	
					arguments.diff_price_list=listappend(arguments.diff_price_list,0,',');
	
					if(len(GET_MAIN_SPEC.PRODUCT_ID[s]) and isdefined("attributes.price_catid") and len(attributes.price_catid))
						GET_PRICE_PROD = cfquery(SQLString:'SELECT * FROM GET_PRICE WHERE PRODUCT_ID=#GET_MAIN_SPEC.PRODUCT_ID[s]#',Datasource:dsn3,dbtype:1,is_select:1);	
					if(len(GET_MAIN_SPEC.PRODUCT_ID[s]) and (not isdefined("GET_PRICE_PROD") or GET_PRICE_PROD.RECORDCOUNT eq 0))
						GET_PRICE_PROD = cfquery(SQLString:'SELECT * FROM GET_PRICE_STANDART WHERE PRODUCT_ID=#GET_MAIN_SPEC.PRODUCT_ID[s]#',Datasource:dsn3,dbtype:1,is_select:1);	
					if(isdefined('GET_PRICE_PROD') and len(GET_PRICE_PROD.PRICE))
					{
						arguments.product_price_list=listappend(arguments.product_price_list,GET_PRICE_PROD.PRICE,',');
						arguments.product_money_list=listappend(arguments.product_money_list,GET_PRICE_PROD.MONEY,',');
					}
					else
					{
						arguments.product_price_list=listappend(arguments.product_price_list,0,',');
						arguments.product_money_list=listappend(arguments.product_money_list,session_base.money,',');
					}
					
					if(len(GET_MAIN_SPEC.TOLERANCE[s]))
						arguments.tolerance_list=listappend(arguments.tolerance_list,GET_MAIN_SPEC.TOLERANCE[s],',');
					else
						arguments.tolerance_list=listappend(arguments.tolerance_list,'-',',');
					/*if(len(GET_MAIN_SPEC.PRODUCT_SPACE[s]))
						arguments.product_space_list=listappend(arguments.product_space_list,GET_MAIN_SPEC.PRODUCT_SPACE[s],',');
					else
						arguments.product_space_list=listappend(arguments.product_space_list,'-',',');
					if(len(GET_MAIN_SPEC.CALCULATE_TYPE[s]))
						arguments.calculate_type_list=listappend(arguments.calculate_type_list,GET_MAIN_SPEC.CALCULATE_TYPE[s],',');
					else
						arguments.calculate_type_list=listappend(arguments.calculate_type_list,0,',');
					
					if(len(GET_MAIN_SPEC.PRODUCT_DISPLAY[s]))
						arguments.product_display_list=listappend(arguments.product_display_list,GET_MAIN_SPEC.PRODUCT_DISPLAY[s],',');
					else
						arguments.product_display_list=listappend(arguments.product_display_list,'-',',');	
					if(len(GET_MAIN_SPEC.PRODUCT_RATE[s]))
						arguments.product_rate_list=listappend(arguments.product_rate_list,GET_MAIN_SPEC.PRODUCT_RATE[s],',');
					else
						arguments.product_rate_list=listappend(arguments.product_rate_list,'-',',');
					*/	
					if(len(GET_MAIN_SPEC.PRODUCT_LIST_PRICE[s]))
						arguments.list_price_list=listappend(arguments.list_price_list,GET_MAIN_SPEC.PRODUCT_LIST_PRICE[s],',');
					else
						arguments.list_price_list=listappend(arguments.list_price_list,'-',',');
					if(len(GET_MAIN_SPEC.LINE_NUMBER[s]))
						arguments.line_number_list = listappend(arguments.line_number_list,GET_MAIN_SPEC.LINE_NUMBER[s],',');
					else
						arguments.line_number_list  =listappend(arguments.line_number_list,'-',',');
					
					if(len(GET_MAIN_SPEC.QUESTION_ID[s]))
						arguments.question_id_list = listappend(arguments.question_id_list,GET_MAIN_SPEC.QUESTION_ID[s],',');
					else
						arguments.question_id_list  =listappend(arguments.question_id_list,'-',',');	
				}
			</cfscript>
		</cfif>
	</cfif>
	<!--- <cfdump var="#ayirac#">
	<cfabort> --->
	<!--- spec ekleme --->
	<cfif len(main_spec_id) and arguments.only_main_spec eq 0>
		<cfif arguments.insert_spec or is_new_spec eq 1 or arguments.is_control_spect_name eq 1>
			<cfquery name="ADD_VAR_SPECT" datasource="#arguments.dsn_type#">
				INSERT
				INTO
					#new_dsn3#.SPECTS
					(
						SPECT_MAIN_ID,
						SPECT_VAR_NAME,
						SPECT_TYPE,
						PRODUCT_ID,
						STOCK_ID,
						TOTAL_AMOUNT,
						OTHER_MONEY_CURRENCY,
						OTHER_TOTAL_AMOUNT,
						PRODUCT_AMOUNT,
						PRODUCT_AMOUNT_CURRENCY,
						IS_TREE,
						FILE_NAME,
						FILE_SERVER_ID,
						MARJ_TOTAL_AMOUNT,
						MARJ_OTHER_TOTAL_AMOUNT,
						MARJ_AMOUNT,
						MARJ_PERCENT,
						DETAIL,
						RECORD_IP,
						<cfif isDefined("session.pp")>
                            RECORD_PAR,
                        <cfelseif isDefined("session.ww")>
                            RECORD_CONS,
                        <cfelse>
                            RECORD_EMP,
                        </cfif>
						RECORD_DATE,
                        IS_LIMITED_STOCK,
                        SPECIAL_CODE_1,
                        SPECIAL_CODE_2,
                        SPECIAL_CODE_3,
                        SPECIAL_CODE_4,
                        WRK_ID
					)
					VALUES
					(
						#main_spec_id#,
						'#left(arguments.spec_name,500)#',
						#arguments.spec_type#,
						<cfif isdefined("arguments.main_product_id") and len(arguments.main_product_id)>#arguments.main_product_id#<cfelse>NULL</cfif>,
						<cfif isdefined("arguments.main_stock_id") and len(arguments.main_stock_id)>#arguments.main_stock_id#<cfelse>NULL</cfif>,
						<cfif isdefined('arguments.spec_total_value') and len(arguments.spec_total_value)>#arguments.spec_total_value#<cfelse>0</cfif>,
						'#arguments.other_money#',
						<cfif len(arguments.spec_other_total_value)>#arguments.spec_other_total_value#<cfelse>0</cfif>,
						<cfif isdefined("arguments.main_prod_price") and len(arguments.main_prod_price)>#arguments.main_prod_price#<cfelse>0</cfif>,
						<cfif len(arguments.main_product_money)>'#arguments.main_product_money#'<cfelse>'#session_base.money#'</cfif>,
						#arguments.spec_is_tree#,
						<cfif len(arguments.spect_file_name)>'#arguments.spect_file_name#'<cfelse>NULL</cfif>,
						<cfif len(arguments.spect_file_name)>#fusebox.server_machine#<cfelse>NULL</cfif>,
						<cfif isdefined('arguments.marj_total_value') and len(arguments.marj_total_value)>#arguments.marj_total_value#<cfelse>0</cfif>,
						<cfif isdefined('arguments.marj_other_total_value') and len(arguments.marj_other_total_value)>#arguments.marj_other_total_value#<cfelse>0</cfif>,
						<cfif isdefined('arguments.marj_amount') and len(arguments.marj_amount)>#arguments.marj_amount#<cfelse>0</cfif>,
						<cfif isdefined('arguments.marj_percent') and len(arguments.marj_percent)>#arguments.marj_percent#<cfelse>0</cfif>,
						<cfif isdefined('arguments.spect_detail') and len(arguments.spect_detail)>'#arguments.spect_detail#'<cfelse>NULL</cfif>,
						'#cgi.remote_addr#',
						<cfif isdefined('session_base.userid')>
							#session_base.userid#,
						<cfelse>
							NULL,
						</cfif>
						#now()#,
                        <cfif isdefined('arguments.is_limited_stock') and len(arguments.is_limited_stock)>#arguments.is_limited_stock#<cfelse>NULL</cfif>,
                        <cfif isdefined('arguments.special_code_1') and len(arguments.special_code_1)>'#arguments.special_code_1#'<cfelse>NULL</cfif>,
                        <cfif isdefined('arguments.special_code_2') and len(arguments.special_code_2)>'#arguments.special_code_2#'<cfelse>NULL</cfif>,
                        <cfif isdefined('arguments.special_code_3') and len(arguments.special_code_3)>'#arguments.special_code_3#'<cfelse>NULL</cfif>,
                        <cfif isdefined('arguments.special_code_4') and len(arguments.special_code_4)>'#arguments.special_code_4#'<cfelse>NULL</cfif>,
						'#wrk_id#'                        
					)
			</cfquery>
			<cfquery name="GET_MAX" datasource="#arguments.dsn_type#">
				SELECT MAX(SPECT_VAR_ID) AS MAX_ID FROM #new_dsn3#.SPECTS WHERE WRK_ID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#wrk_id#">
			</cfquery>
		<cfelseif isdefined('arguments.spec_id') and len(arguments.spec_id)>
			<cfquery name="UPD_VAR_SPECT" datasource="#arguments.dsn_type#">
				UPDATE
					#new_dsn3#.SPECTS
				SET
					SPECT_MAIN_ID=#main_spec_id#,
					SPECT_VAR_NAME='#arguments.spec_name#',
					SPECT_TYPE=#arguments.spec_type#,
					PRODUCT_ID=<cfif isdefined("arguments.main_product_id") and len(arguments.main_product_id)>#arguments.main_product_id#<cfelse>NULL</cfif>,
					STOCK_ID=<cfif isdefined("arguments.main_stock_id") and len(arguments.main_stock_id)>#arguments.main_stock_id#<cfelse>NULL</cfif>,
					TOTAL_AMOUNT=<cfif len(arguments.spec_total_value)>#arguments.spec_total_value#<cfelse>0</cfif>,
					OTHER_MONEY_CURRENCY='#arguments.main_product_money#',
					OTHER_TOTAL_AMOUNT=<cfif len(arguments.spec_other_total_value)>#arguments.spec_other_total_value#<cfelse>0</cfif>,
					PRODUCT_AMOUNT=<cfif isdefined("arguments.main_prod_price") and len(arguments.main_prod_price)>#arguments.main_prod_price#<cfelse>0</cfif>,
					PRODUCT_AMOUNT_CURRENCY=<cfif len(arguments.main_product_money)>'#arguments.main_product_money#'<cfelse>'#session_base.money#'</cfif>,
					IS_TREE=#arguments.spec_is_tree#,
					<cfif len(arguments.spect_file_name)>
					FILE_NAME='#arguments.spect_file_name#',
					FILE_SERVER_ID=#fusebox.server_machine#,
					</cfif>
					MARJ_TOTAL_AMOUNT=<cfif len(arguments.marj_total_value)>#arguments.marj_total_value#<cfelse>0</cfif>,
					MARJ_OTHER_TOTAL_AMOUNT=<cfif isdefined('arguments.marj_other_total_value') and len(arguments.marj_other_total_value)>#arguments.marj_other_total_value#<cfelse>0</cfif>,
					MARJ_AMOUNT=<cfif len(arguments.marj_amount)>#arguments.marj_amount#<cfelse>0</cfif>,
					MARJ_PERCENT=<cfif len(arguments.marj_percent)>#arguments.marj_percent#<cfelse>0</cfif>,
					DETAIL =<cfif isdefined('arguments.spect_detail') and len(arguments.spect_detail)>'#arguments.spect_detail#'<cfelse>NULL</cfif>,
					UPDATE_IP='#cgi.remote_addr#',
                    <cfif isDefined("session.pp")>
                        UPDATE_PAR=#session_base.userid#,
                    <cfelseif isDefined("session.ww")>
                        UPDATE_CONS=#session_base.userid#,
                    <cfelse>
                        UPDATE_EMP=#session_base.userid#,
                    </cfif>
					UPDATE_DATE=#now()#,
                    SPECIAL_CODE_1 = <cfif isdefined('arguments.special_code_1') and len(arguments.special_code_1)>'#arguments.special_code_1#'<cfelse>NULL</cfif>,
                    SPECIAL_CODE_2 = <cfif isdefined('arguments.special_code_2') and len(arguments.special_code_2)>'#arguments.special_code_2#'<cfelse>NULL</cfif>,
                    SPECIAL_CODE_3 = <cfif isdefined('arguments.special_code_3') and len(arguments.special_code_3)>'#arguments.special_code_3#'<cfelse>NULL</cfif>,
                    SPECIAL_CODE_4 = <cfif isdefined('arguments.special_code_4') and len(arguments.special_code_4)>'#arguments.special_code_4#'<cfelse>NULL</cfif>
				WHERE
					SPECT_VAR_ID=#arguments.spec_id#
			</cfquery>		
			<!--- eger guncelleniyorsa money ve satirlar siliniyor --->
			<cfquery name="DEL_ROW" datasource="#arguments.dsn_type#">
				DELETE FROM #new_dsn3#.SPECTS_ROW WHERE SPECT_ID = #arguments.spec_id#
			</cfquery>
			<cfif listlen(arguments.money_list,',') and listlen(arguments.money_rate1_list,',') and listlen(arguments.money_rate2_list,',')>
			<!--- guncelleme islemi sirasinda para birimi ve kur listeleri gelmezse kur degerleri silinmiyor ve eski degerleri ile kaliyor --->
				<cfquery name="DEL_MONEY_ROW" datasource="#arguments.dsn_type#">
					DELETE FROM #new_dsn3#.SPECT_MONEY WHERE ACTION_ID =#arguments.spec_id#
				</cfquery>
			</cfif>
			<cfset get_max.max_id=arguments.spec_id />
		</cfif>
		<cfif arguments.insert_spec or is_new_spec eq 1 or (listlen(arguments.money_list,',') and listlen(arguments.money_rate1_list,',') and listlen(arguments.money_rate2_list,','))>
		<!---*** yeni spec ekleme ise mutlaka girmeli (money listeleri yollanmalı) ancak guncelleme ve main specden ekleme ise degerler gelmedi ise girmesin --->
			<cfloop from="1" to="#listlen(arguments.money_list,',')#" index="xx">
				<cfscript>
					spec_money_type=listgetat(arguments.money_list,xx,',');
					spec_txt_rate1=listgetat(arguments.money_rate1_list,xx,',');
					spec_txt_rate2=listgetat(arguments.money_rate2_list,xx,',');
					if(spec_money_type eq spec_money_select)spec_money_check=1; else spec_money_check=0;
				</cfscript>
				<cfquery name="add_spec_money" datasource="#arguments.dsn_type#">
					INSERT INTO
						#new_dsn3#.SPECT_MONEY
						(
							MONEY_TYPE,
							ACTION_ID,
							RATE2,
							RATE1,
							IS_SELECTED
						)
					VALUES
						(
							'#spec_money_type#',
							#get_max.max_id#,
							#spec_txt_rate2#,
							#spec_txt_rate1#,
							#spec_money_check#
						)
				</cfquery>
			</cfloop>
		</cfif>
		<cfloop from="1" to="#arguments.spec_row_count#" index="zz">
			<cfscript>
				form_product_name = listgetat(arguments.product_name_list,zz,ayirac);
				form_product_id = listgetat(arguments.product_id_list,zz,',');
				form_stock_id = listgetat(arguments.stock_id_list,zz,',');
				if(len(amount_list))
					form_amount = listgetat(arguments.amount_list,zz,',');
				else
					form_amount = '';	
				if(len(diff_price_list))
					form_diff_price = listgetat(arguments.diff_price_list,zz,',');
				else
					form_diff_price = '';	
				form_total_amount = listgetat(arguments.product_price_list,zz,',');
				form_value_money_type =  listgetat(arguments.product_money_list,zz,',');
				form_is_property = listgetat(arguments.is_property_list,zz,',');
				form_is_configure = listgetat(arguments.is_configure_list,zz,',');
				form_property_id = listgetat(arguments.property_id_list,zz,',');
				form_variation_id = listgetat(arguments.variation_id_list,zz,',');
				form_total_min = listgetat(arguments.total_min_list,zz,',');
				form_total_max = listgetat(arguments.total_max_list,zz,',');
				
				if(isdefined('arguments.related_tree_id_list') and len(arguments.related_tree_id_list))
					form_related_tree_id = listgetat(arguments.related_tree_id_list,zz,',');
				if(isdefined('arguments.operation_type_id_list') and len(arguments.operation_type_id_list))
					form_operation_type_id = listgetat(arguments.operation_type_id_list,zz,',');
				
				if(isdefined('arguments.configurator_variation_id_list') and len(arguments.configurator_variation_id_list) and listlen(arguments.configurator_variation_id_list) gte zz) form_configurator_variation_id=listgetat(arguments.configurator_variation_id_list,zz,',');
				//if(isdefined('arguments.chapter_id_list') and len(arguments.chapter_id_list)) form_chapter_id=listgetat(arguments.chapter_id_list,zz,',');
				if(isdefined('arguments.dimension_list') and len(arguments.dimension_list)) form_dimention=listgetat(arguments.dimension_list,zz,',');
				//if(isdefined('arguments.rel_variation_id_list') and len(arguments.rel_variation_id_list)) form_rel_variation_id=listgetat(arguments.rel_variation_id_list,zz,',');
				if(isdefined('arguments.tolerance_list') and len(arguments.tolerance_list)) form_tolerance = listgetat(arguments.tolerance_list,zz,',');
				if(isdefined('arguments.is_sevk_list') and len(arguments.is_sevk_list)) form_is_sevk = listgetat(arguments.is_sevk_list,zz,',');
				
				if (len(arguments.product_space_list)){form_product_space = listgetat(arguments.product_space_list,zz,',');}
				if (len(arguments.product_display_list)){form_product_display = listgetat(arguments.product_display_list,zz,',');}
				if (len(arguments.product_rate_list)){form_product_rate = listgetat(arguments.product_rate_list,zz,',');}
				if (len(arguments.list_price_list)){form_list_price = listgetat(arguments.list_price_list,zz,',');}
				//if (len(arguments.calculate_type_list)){form_calculate_type = listgetat(arguments.calculate_type_list,zz,',');}
				if (len(arguments.related_spect_id_list)){form_related_spect_id = listgetat(arguments.related_spect_id_list,zz,',');}
				if (isDefined("arguments.question_id_list") and len(arguments.question_id_list)){form_question_id= listgetat(arguments.question_id_list,zz,',');}
				
				if (isdefined('arguments.line_number_list') and len(arguments.line_number_list) and listlen(arguments.line_number_list) gte zz )
					form_line_number = listgetat(arguments.line_number_list,zz,',');
			
			</cfscript>

			<cfquery name="ADD_ROW" datasource="#arguments.dsn_type#">
				INSERT
				INTO
					#new_dsn3#.SPECTS_ROW
					(
						SPECT_ID,
						PRODUCT_ID,
						STOCK_ID,
						AMOUNT_VALUE,
						TOTAL_VALUE,
						MONEY_CURRENCY,
						PRODUCT_NAME,
						IS_PROPERTY,
						IS_CONFIGURE,
						DIFF_PRICE,

						PROPERTY_ID,
						VARIATION_ID,
						TOTAL_MIN,
						TOTAL_MAX,
						TOLERANCE,
						IS_SEVK,
						PRODUCT_SPACE,
						PRODUCT_DISPLAY,
						PRODUCT_RATE,
						PRODUCT_LIST_PRICE,
                        LINE_NUMBER,
                        CONFIGURATOR_VARIATION_ID,
                        DIMENSION,
                        RELATED_TREE_ID,
                        OPERATION_TYPE_ID,
						RELATED_SPECT_ID						
					<!--- CALCULATE_TYPE,
                        <!--- CHAPTER_ID,	,
                        <!--- ,REL_VARIATION_ID --->
                        ,
                        ,
                        QUESTION_ID ---> --->
                        

					)
					VALUES
					(
						#get_max.max_id#,
						<cfif form_product_id gt 0>#form_product_id#<cfelse>NULL</cfif>,
						<cfif form_stock_id gt 0>#form_stock_id#<cfelse>NULL</cfif>,
						<cfif isdefined('form_amount') and len(form_amount)>#form_amount#<cfelse>NULL</cfif>,
						<cfif len(form_total_amount)>#form_total_amount#<cfelse>0</cfif>,
						'#form_value_money_type#',
						<cfif len(form_product_name)>'#form_product_name#'<cfelse>NULL</cfif>,
						#form_is_property#,
						#form_is_configure#,
						<cfif len(form_diff_price)>#form_diff_price#<cfelse>0</cfif>,

						<cfif form_property_id gt 0>#form_property_id#<cfelse>NULL</cfif>,
						<cfif form_variation_id gt 0>#form_variation_id#<cfelse>NULL</cfif>,
						<cfif form_total_min neq '-'>#form_total_min#<cfelse>NULL</cfif>,
						<cfif form_total_max neq '-'>#form_total_max#<cfelse>NULL</cfif>,
						<cfif form_tolerance neq '-'>#form_tolerance#<cfelse>NULL</cfif>,
						#form_is_sevk#,
						<cfif isdefined('form_product_space') and form_product_space gt 0>#form_product_space#<cfelse>NULL</cfif>,
						<cfif isdefined('form_product_display') and form_product_display gt 0>#form_product_display#<cfelse>NULL</cfif>,
						<cfif isdefined('form_product_rate') and form_product_rate gt 0>#form_product_rate#<cfelse>NULL</cfif>,
						<cfif isdefined('form_list_price') and form_list_price gt 0>#form_list_price#<cfelse>NULL</cfif>,
						<cfif isdefined('form_line_number') and form_line_number GT 0>#form_line_number#<cfelse>NULL</cfif>,
                        <cfif isdefined('form_configurator_variation_id') and form_configurator_variation_id gt 0>#form_configurator_variation_id#<cfelse>NULL</cfif>,
                        <cfif isdefined('form_dimention') and form_dimention neq '-'>#form_dimention#<cfelse>NULL</cfif>,
                        <cfif isdefined('form_related_tree_id') and form_related_tree_id gt 0>#form_related_tree_id#<cfelse>NULL</cfif>,
                        <cfif isdefined('form_operation_type_id') and  form_operation_type_id gt 0>#form_operation_type_id#<cfelse>NULL</cfif>,
					<cfif isdefined('form_related_spect_id') and form_related_spect_id GT 0>#form_related_spect_id#<cfelse>NULL</cfif>						
					<!--- ,
						<!--- <cfif isdefined('form_calculate_type') and len(form_calculate_type)>#form_calculate_type#<cfelse>NULL</cfif>, --->
						,
						<!--- <cfif isdefined('form_chapter_id') and form_chapter_id gt 0>#form_chapter_id#<cfelse>NULL</cfif>, --->
                        ,<!--- ,
						<cfif isdefined('form_rel_variation_id') and form_rel_variation_id gt 0>#form_rel_variation_id#<cfelse>NULL</cfif> --->
                        <cfif isdefined('form_related_tree_id') and form_related_tree_id gt 0>#form_related_tree_id#<cfelse>NULL</cfif>,
                        ,
                        <cfif isdefined('form_question_id') and  form_question_id gt 0>#form_question_id#<cfelse>NULL</cfif> --->
					)
			</cfquery>
		</cfloop>
	</cfif>
	<cfquery name="get_spect_cost_f" datasource="#arguments.dsn_type#" maxrows="1"><!--- Ürünün geçerli maliyetini getiriyor.--->
		SELECT 
			PRODUCT_COST,
			PURCHASE_NET_SYSTEM,
			PURCHASE_EXTRA_COST_SYSTEM 
		FROM 
			#dsn1_alias#.PRODUCT_COST AS PRODUCT_COST 
		WHERE 
			SPECT_MAIN_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#main_spec_id#"> AND
			START_DATE <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.action_date#">
		ORDER BY 
			RECORD_DATE DESC,START_DATE DESC
	</cfquery>
	<cfif get_spect_cost_f.recordcount and len(get_spect_cost_f.PRODUCT_COST)>
		<cfset toplam_spec_maliyet = get_spect_cost_f.PRODUCT_COST />
		<cfset toplam_spec_maliyet_system = get_spect_cost_f.PURCHASE_NET_SYSTEM />
		<cfset toplam_spec_maliyet_extra_system = get_spect_cost_f.PURCHASE_EXTRA_COST_SYSTEM />
	<cfelse>
		<cfset toplam_spec_maliyet = 0 />
		<cfset toplam_spec_maliyet_system = 0 />
		<cfset toplam_spec_maliyet_extra_system = 0 />
	</cfif>
	<cfif not len(arguments.spec_other_total_value)><cfset arguments.spec_other_total_value = 0 /></cfif>
	<cfif not len(arguments.main_product_money)><cfset arguments.main_product_money = 0 /></cfif>
	<cfif arguments.only_main_spec>
		<cfset spec_return='#main_spec_id#,0,#replace(arguments.spec_name,',','','all')#,0,0,#session_base.money#,0,#session_base.money#,0,0,#is_new_spec#' />
	<cfelse>
		<cfset spec_return='#main_spec_id#,#get_max.max_id#,#replace(arguments.spec_name,',','','all')#,#arguments.spec_total_value#,#arguments.spec_other_total_value#,#arguments.other_money#,#toplam_spec_maliyet#,#arguments.main_product_money#,#toplam_spec_maliyet_system#,#toplam_spec_maliyet_extra_system#,#is_new_spec#' />
	</cfif>
	<cfreturn spec_return>
</cffunction>

<!--- add_serial_no--->
   

	<cffunction name="add_serial_no" output="false">
            <cfargument name="wrk_row_id" type="string">
            <cfargument name="session_row" type="numeric" required="true">
            <cfargument name="is_insert" type="boolean"><!--- true : ekleme, false guncelleme (sadece depolararasi sevk de kullaniliyor)--->
            <cfargument name="process_type" type="numeric" required="true">
            <cfargument name="process_number" type="string" required="true">
            <cfargument name="process_id" type="numeric" required="true">
            <cfargument name="is_sale" type="boolean" default="false">
            <cfargument name="is_purchase" type="boolean" default="false">
            <cfargument name="dpt_id" type="string" required="true" default=""> <!--- depo id --->
            <cfargument name="loc_id" type="string" default=""> <!--- location_id --->
            <cfargument name="par_id" type="string" default="">
            <cfargument name="promotion_id" type="string" default="">
            <cfargument name="con_id" type="string" default="">
            <cfargument name="main_stock_id" type="string" default="">
            <cfargument name="spect_id" type="string" default="">
            <cfargument name="comp_id" type="string" default="">
            <cfargument name="main_process_id" type="string" default="">
            <cfargument name="main_process_no" type="string" default="">
            <cfargument name="main_process_cat" type="string" default="">
            <cfargument name="main_serial_no" type="string" default="">
            <cfargument name="unit" type="numeric" default="0">
            <cfargument name="unit_row_quantity" default="">
            <cfargument name="is_in_out" type="boolean" required="no" default="0">
           <cfset letters = "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,r,s,t,u,v,y,z,1,2,3,4,5,6,7,8,9,0" />
            <cfif listfindnocase('0,1',arguments.process_type,',')>
                <cfset record_place = 0 /> <!--- service_guaranty_temp tablosuna yazar --->
            <cfelse>
                <cfset record_place = 1 /> <!--- service_guaranty_new tablosuna yazar --->
            </cfif>
            <!--- 
                my_in_out = 1 ( giriş) 
                my_in_out = 0 (çıkış)
                my_is_purchase = 1 (alış)
                my_is_sale = 1 (satış)
            --->
            <cfif listfindnocase('59,73,74,75,76,77,80,82,84,86,87,110,115,140',arguments.process_type,',')><!--- Alış ve giriş --->
                <cfset my_is_purchase = 1 />
                <cfset my_is_sale = 0 />
                <cfset my_in_out = 1 />
                <cfset my_seri_sonu = 0 />
            <cfelseif listfindnocase('70,71,72,78,79,88,83,141',arguments.process_type,',')><!--- Satış ve çıkış --->
                <cfset my_is_purchase = 0 />
                <cfset my_is_sale = 1 />
                <cfset my_in_out = 0 />
                <cfset my_seri_sonu = 0 />
            <cfelseif listfindnocase('118,116',arguments.process_type,',')><!--- satış alış yok giriş (116-stok virman giriş) --->
                <cfset my_is_purchase = 0 />
                <cfset my_is_sale = 0 />
                <cfif isdefined("arguments.is_in_out") and arguments.is_in_out eq 0>
                    <cfset my_in_out = 0 />
                <cfelse>
                    <cfset my_in_out = 1 />
                </cfif>
                <cfset my_seri_sonu = 0 />
            <cfelseif listfindnocase('85,111,112,1182',arguments.process_type,',')>
                <cfset my_is_purchase = 0 />
                <cfset my_is_sale = 0 />
                <cfset my_in_out = 0 />
                <cfset my_seri_sonu = 0 />
            <cfelseif listfindnocase('171,114',arguments.process_type,',')><!--- TolgaS 20060428 üretim sonucunda üretilen ürünler satılabilir ve in_out 1 set edildi--->
                <cfset my_is_purchase = 0 />
                <cfset my_is_sale = 0 />
                <cfset my_in_out = 1 />
                <cfset my_seri_sonu = 0 />
            <cfelseif listfindnocase('1131',arguments.process_type,',')><!--- seri sonu ürünler satılabilir ve in_out 1 set edildi ayrica seri sonu ibaresi de 1 oldu--->
                <cfset my_is_purchase = 0 />
                <cfset my_is_sale = 0 />
                <cfset my_in_out = 1 />
                <cfset my_seri_sonu = 1 />
            <cfelseif listfindnocase('81,811,113',arguments.process_type,',')> <!--- depolararası sevk,İTHAL MAL GİRİŞ,ambar fişi giriş ve çıkış kayıtları atılıyor --->
                 <cfif isdefined("arguments.is_in_out") and arguments.is_in_out eq 0>
                    <cfset my_in_out = 0 />
                    <cfset my_is_purchase = 0 />
                    <cfset my_is_sale = 1 />
                <cfelse>
                    <cfset my_in_out = 1 />
                    <cfset my_is_purchase = 1 />
                    <cfset my_is_sale = 0 />
                </cfif>
                <cfset my_seri_sonu = 0 />
            <cfelse>
                <cfset my_is_purchase = 0 />
                <cfset my_is_sale = 0 />
                <cfset my_in_out = 0 />
                <cfset my_seri_sonu = 0 />
            </cfif>
        
            <cfset is_insert = 1 />
            <cfif listfindnocase('73,74,75,86',arguments.process_type,',')>
                <cfset control_sale_purchase = 1 />
            <cfelseif listfindnocase('78,79,85',arguments.process_type,',')>
                <cfset control_sale_purchase = 0 />
            </cfif>
            <cfif listfindnocase('73,74,75,78,79',arguments.process_type,',')>
                <cfset my_is_return = 1 />
            <cfelse>
                <cfset my_is_return = 0 />
            </cfif>
            <cfif listfindnocase('85',arguments.process_type,',')>
                <cfset my_is_rma = 1 />
            <cfelse>
                <cfset my_is_rma = 0 />
            </cfif>
            <cfif listfindnocase('112',arguments.process_type,',')>
                <cfset my_is_trash = 1 />
            <cfelse>
                <cfset my_is_trash = 0 />
            </cfif>
            <cfif listfindnocase('111',arguments.process_type,',') or listfindnocase('1719',arguments.process_type,',') or (len(arguments.main_stock_id) and listfindnocase('171',arguments.process_type,','))>
                <cfset my_is_sarf = 1 />
            <cfelse>
                <cfset my_is_sarf = 0 />
            </cfif>
            <cfif not isdefined("temp_date")>
                <cfif isdefined("attributes.guaranty_cat#session_row#") and len(evaluate('attributes.guaranty_cat#session_row#'))>
                    <cfquery name="get_guaranty_time_" datasource="#dsn3#">
                        SELECT (SELECT GUARANTYCAT_TIME FROM #dsn_alias#.SETUP_GUARANTYCAT_TIME WHERE GUARANTYCAT_TIME_ID = SETUP_GUARANTY.GUARANTYCAT_TIME) GUARANTYCAT_TIME_ FROM  #dsn_alias#.SETUP_GUARANTY WHERE GUARANTYCAT_ID = #evaluate('attributes.guaranty_cat#session_row#')#
                    </cfquery>
                </cfif>
                <cfif isdefined("attributes.guaranty_startdate#arguments.session_row#") and len(evaluate('attributes.guaranty_startdate#arguments.session_row#'))>
                    <cfset temp_start_date = evaluate('attributes.guaranty_startdate#arguments.session_row#') />
                </cfif>
                <cfif isdefined("temp_start_date") and isdate(temp_start_date) and isdefined("get_guaranty_time_.GUARANTYCAT_TIME_") and Len(get_guaranty_time_.GUARANTYCAT_TIME_)>
                    <cf_date tarih="temp_start_date">
                    <cfset temp_date = date_add("m",get_guaranty_time_.GUARANTYCAT_TIME_,temp_start_date) />
                </cfif>
            </cfif>
            
            <cfif isDefined("temp_start_date") and isdate(temp_start_date)><cf_date tarih="temp_start_date"></cfif>
            <cfif isDefined("temp_date") and isdate(temp_date)><cf_date tarih="temp_date"></cfif>
            
            <cfset subscription_id_ = "" />
            <cfif listfindnocase('70,71,72,73,74,75,76,77,78,79,80,81,811,82,83,84,88,761,85,86,140,141',arguments.process_type,',') and len(arguments.process_id)><!--- irs --->
                <cfquery name="get_subscription" datasource="#dsn2#">
                    SELECT SUBSCRIPTION_ID FROM SHIP WHERE SHIP_ID = #arguments.process_id#
                </cfquery>
                <cfif get_subscription.recordcount>
                    <cfset subscription_id_ = get_subscription.SUBSCRIPTION_ID />
                </cfif>
            <cfelseif listfindnocase('110,111,112,113,114,115,119,1131,118,1182 ',arguments.process_type,',') and len(arguments.process_id)>
                <cfquery name="get_subscription" datasource="#dsn2#">
                    SELECT SUBSCRIPTION_ID FROM STOCK_FIS WHERE FIS_ID = #arguments.process_id#
                </cfquery>
                <cfif get_subscription.recordcount>
                    <cfset subscription_id_ = get_subscription.SUBSCRIPTION_ID />
                </cfif>
            </cfif>
                
            <cfset aktif_satir = 0 />
            <cfif is_insert>
                <cfset baslangic_degeri = 1 />
                <cfset blok_sayisi = 400 />
                <cfif listlen(evaluate('attributes.serial_no_start_number#arguments.session_row#')) gt 400>
                    <cfset ilk_deger = listfirst(listlen(evaluate('attributes.serial_no_start_number#arguments.session_row#'))/400,'.') />
                    <cfif listlen(evaluate('attributes.serial_no_start_number#arguments.session_row#')) mod 400 neq 0>
                        <cfset ilk_deger = ilk_deger + 1 />
                    </cfif>
                    <cfset list_uzunluk = ilk_deger />
                <cfelse>
                    <cfset list_uzunluk = 1 />
                </cfif>
            	<cfloop from="1" to="#list_uzunluk#" index="aaa">
                <cfif blok_sayisi gt listlen(evaluate('attributes.serial_no_start_number#arguments.session_row#'))>
                    <cfset blok_sayisi = listlen(evaluate('attributes.serial_no_start_number#arguments.session_row#')) />
                </cfif>
                    <cfquery name="add_guaranty" datasource="#dsn3#" result="xxx"> 
                        INSERT INTO
                            SERVICE_GUARANTY_NEW
                        (
                            WRK_ID,
                            WRK_ROW_ID,
                            STOCK_ID,
                            MAIN_STOCK_ID,
                            LOT_NO,
                            RMA_NO,
                            REFERENCE_NO,
                            PROMOTION_ID,
                            <cfif evaluate('attributes.guaranty_purchasesales#arguments.session_row#') eq 0>
                                PURCHASE_GUARANTY_CATID,
                                PURCHASE_START_DATE,
                                PURCHASE_FINISH_DATE,
                                <cfif len(arguments.comp_id)>PURCHASE_COMPANY_ID,
                                <cfelseif len(arguments.con_id)>PURCHASE_CONSUMER_ID,</cfif>
                                <cfif len(arguments.par_id)>PURCHASE_PARTNER_ID,</cfif>
                            <cfelse>
                                SALE_GUARANTY_CATID,
                                SALE_START_DATE,
                                SALE_FINISH_DATE,
                                <cfif len(arguments.comp_id)>SALE_COMPANY_ID,
                                <cfelseif len(arguments.con_id)>SALE_CONSUMER_ID,</cfif>
                                <cfif len(arguments.par_id)>SALE_PARTNER_ID,</cfif>
                            </cfif>	
                            IN_OUT,
                            IS_SALE,
                            IS_PURCHASE,
                            IS_SERVICE,
                            IS_SARF,
                            IS_RMA,
                            IS_SERI_SONU,
                            IS_RETURN,
                            PROCESS_ID,
                            PROCESS_NO,
                            PROCESS_CAT,
                            PERIOD_ID,
                            DEPARTMENT_ID,
                            LOCATION_ID,
                            SERIAL_NO,
                            SPECT_ID,
                            MAIN_PROCESS_ID,
                            MAIN_PROCESS_NO,
                            MAIN_PROCESS_TYPE,
                            MAIN_SERIAL_NO,
                            SUBSCRIPTION_ID,
                            UNIT_TYPE,
                            UNIT_ROW_QUANTITY,
                            <cfif isDefined('session.ep.userid')>
                                RECORD_EMP,
                            </cfif>
                            RECORD_IP,
                            RECORD_DATE
                        )
                        <cfloop from="#baslangic_degeri#" to="#blok_sayisi#" index="j">
                            <cfif isdefined("attributes.is_dynamic_lot_no")>
                                <cfset password = '' />
                                <cfloop from="1" to="6" index="ind">				     
                                    <cfset random = RandRange(1,33) />
                                    <cfset password = "#password##ListGetAt(letters,random,',')#" />
                                </cfloop>
                                <cfset password = "#ucase(password)#" />
                            </cfif>
                            <cfif arguments.process_type eq 141 and isdefined("attributes.out_stock_id")>
                                <cfif attributes.stock_id1 eq attributes.out_stock_id>
                                    <cfquery name="check_stock_serial" datasource="#dsn3#" maxrows="1">
                                        SELECT GUARANTY_ID FROM SERVICE_GUARANTY_NEW WHERE STOCK_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.out_stock_id#"> AND SERIAL_NO = <cfqueryparam cfsqltype="cf_sql_varchar" value="#listgetat(evaluate('attributes.serial_no_start_number#arguments.session_row#'),j)#"> AND PROCESS_CAT = 140 AND PROCESS_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.out_ship_id#"> AND PERIOD_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#session_base.period_id#"> AND RETURN_SERIAL_NO IS NULL ORDER BY GUARANTY_ID DESC
                                    </cfquery>
                                    <cfif check_stock_serial.recordcount>
                                        <cfset is_insert = 1 />
                                        <cfset servis_degisim = 0 />
                                        <cfset GET_MAX.MAX_ID = check_stock_serial.guaranty_id />
                                    <cfelse>
                                        <cfset servis_degisim = 1 /> <!--- en altta kullandim --->
                                        <cfset is_insert = 1 />
                                    </cfif>
                                <cfelse>
                                    <cfset servis_degisim = 1 /><!--- en altta kullandim --->
                                    <cfset is_insert = 1 />
                                </cfif>
                            </cfif>
                        
                            <cfif arguments.process_type eq 86>
                                <cfset is_insert = 1 />
                            </cfif>
                        
                            <cfset aktif_satir = aktif_satir + 1 />
                            <cfset servis_degisim = 0 />
                            <cfif isDefined('session.ep.userid')>
                                <cfset wrk_id = '#listgetat(evaluate("attributes.serial_no_start_number#arguments.session_row#"),j)#' & dateformat(now(),'YYYYMMDD')&timeformat(now(),'HHmmssL')&'_#session.ep.userid#_'&round(rand()*100) />
                            <cfelse>
                                <cfset wrk_id = '#listgetat(evaluate("attributes.serial_no_start_number#arguments.session_row#"),j)#' & dateformat(now(),'YYYYMMDD')&timeformat(now(),'HHmmssL')&'_'&round(rand()*100) />
                            </cfif>
                            
                            <!--- Burasi Bir Onceki Stok ve Seriye Ait Satis Tipli Islemin Satis Garanti Bilgilerini Kopyalamak Icin Eklendi, Checkbox ile Gelir FBS 20130129 --->
                            <cfif my_is_sale eq 1 and isdefined("attributes.stock_id#arguments.session_row#") and isDefined("attributes.is_last_guaranty_control")>
                                <cfquery name="get_sale_serial_guaranty" datasource="#dsn3#">
                                    SELECT TOP 1 SALE_GUARANTY_CATID, SALE_START_DATE, SALE_FINISH_DATE FROM SERVICE_GUARANTY_NEW WHERE STOCK_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#evaluate('attributes.stock_id#arguments.session_row#')#"> AND SERIAL_NO = <cfqueryparam cfsqltype="cf_sql_varchar" value="#listgetat(evaluate('attributes.serial_no_start_number#arguments.session_row#'),j)#"> AND IS_SALE = 1 ORDER BY GUARANTY_ID DESC
                                </cfquery>
                                <cfif get_sale_serial_guaranty.recordcount>
                                    <cfif Len(get_sale_serial_guaranty.sale_guaranty_catid)><cfset "attributes.guaranty_cat#arguments.session_row#" = get_sale_serial_guaranty.sale_guaranty_catid /></cfif>
                                    <cfif Len(get_sale_serial_guaranty.sale_guaranty_catid)><cfset "temp_start_date" = CreateOdbcDateTime(get_sale_serial_guaranty.sale_start_date) /></cfif>
                                    <cfif Len(get_sale_serial_guaranty.sale_guaranty_catid)><cfset "temp_date" = CreateOdbcDateTime(get_sale_serial_guaranty.sale_finish_date) /></cfif>
                                </cfif>
                            </cfif>
                            <!--- //Burasi Bir Onceki Stok ve Seriye Ait Satis Tipli Islemin Satis Garanti Bilgilerini Kopyalamak Icin Eklendi, Checkbox ile Gelir FBS 20130129 --->
                            <!--- // Eğer seri aktarım ile içeri alınmışsa garanti bilgilerini taşımak için eklendi PY 0515 --->
                            <cfquery name="get_old_rec" datasource="#dsn3#">
                                SELECT top 1 PURCHASE_START_DATE,PURCHASE_FINISH_DATE,PURCHASE_GUARANTY_CATID FROM SERVICE_GUARANTY_NEW WHERE SERIAL_NO = '#trim(listgetat(evaluate('attributes.serial_no_start_number#arguments.session_row#'),j))#' AND STOCK_ID = #evaluate('attributes.stock_id#arguments.session_row#')# AND PROCESS_CAT = 1190 ORDER BY GUARANTY_ID DESC
                            </cfquery>
                            <cfif get_old_rec.recordcount>
                                <cfif Len(get_old_rec.PURCHASE_GUARANTY_CATID)><cfset "attributes.guaranty_cat#arguments.session_row#" = get_old_rec.PURCHASE_GUARANTY_CATID /></cfif>
                                <cfif Len(get_old_rec.PURCHASE_GUARANTY_CATID)><cfset "temp_start_date" = CreateOdbcDateTime(get_old_rec.PURCHASE_START_DATE) /></cfif>
                                <cfif Len(get_old_rec.PURCHASE_GUARANTY_CATID)><cfset "temp_date" = CreateOdbcDateTime(get_old_rec.PURCHASE_FINISH_DATE) /></cfif>
                            </cfif>
                            SELECT 
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#wrk_id#">,
                                <cfif isdefined("arguments.wrk_row_id") and len(arguments.wrk_row_id)>'#arguments.wrk_row_id#',<cfelse>NULL,</cfif>
                                #evaluate('attributes.stock_id#arguments.session_row#')#,
                                <cfif len(arguments.main_stock_id)>#arguments.main_stock_id#,<cfelse>NULL,</cfif>
                                <cfif isdefined("attributes.is_dynamic_lot_no")>
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#password#">,
                                <cfelseif isdefined("attributes.row_lot_no#arguments.session_row#") and listgetat(evaluate('attributes.row_lot_no#arguments.session_row#'),aktif_satir,',') is not '*_*'>
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#listgetat(evaluate('attributes.row_lot_no#arguments.session_row#'),aktif_satir,',')#">,
                                <cfelse>
                                    '',
                                </cfif>
                                <cfif isdefined("attributes.row_rma_no#arguments.session_row#") and listgetat(evaluate('attributes.row_rma_no#arguments.session_row#'),aktif_satir,',') is not '*_*'>
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#listgetat(evaluate('attributes.row_rma_no#arguments.session_row#'),aktif_satir,',')#">,
                                <cfelse>
                                    '',
                                </cfif>
                                <cfif isdefined("attributes.ref_no#arguments.session_row#") and listgetat(evaluate('attributes.ref_no#arguments.session_row#'),aktif_satir,',') is not '*_*'>
                                    <cfqueryparam cfsqltype="cf_sql_varchar" value="#listgetat(evaluate('attributes.ref_no#arguments.session_row#'),aktif_satir,',')#">,
                                <cfelse>
                                    '',
                                </cfif>
                                <cfif len(arguments.promotion_id)>#arguments.promotion_id#,<cfelse>NULL,</cfif>
                                <cfif evaluate('attributes.guaranty_purchasesales#arguments.session_row#') eq 0>
                                    <cfif isdefined('attributes.guaranty_cat#arguments.session_row#') and len(evaluate('attributes.guaranty_cat#arguments.session_row#'))>#evaluate('attributes.guaranty_cat#arguments.session_row#')#<cfelse>NULL</cfif>,
                                    <cfif isdefined("temp_start_date") and len(temp_start_date)>#temp_start_date#,<cfelse>NULL,</cfif>
                                    <cfif isdefined("temp_date") and len(temp_date)>#temp_date#,<cfelse>NULL,</cfif>
                                    <cfif len(arguments.comp_id)>#arguments.comp_id#,<cfelseif len(arguments.con_id)>#arguments.con_id#,</cfif>
                                    <cfif len(arguments.par_id)>#arguments.par_id#,</cfif>
                                <cfelse>
                                    <cfif isdefined('attributes.guaranty_cat#arguments.session_row#') and len(evaluate('attributes.guaranty_cat#arguments.session_row#'))>#evaluate('attributes.guaranty_cat#arguments.session_row#')#<cfelse>NULL</cfif>,
                                    <cfif isdefined("temp_start_date") and len(temp_start_date)>#temp_start_date#,<cfelse>NULL,</cfif>
                                    <cfif isdefined("temp_date") and len(temp_date)>#temp_date#,<cfelse>NULL,</cfif>
                                    <cfif len(arguments.comp_id)>#arguments.comp_id#,<cfelseif len(arguments.con_id)>#arguments.con_id#,</cfif>
                                    <cfif len(arguments.par_id)>#arguments.par_id#,</cfif>
                                </cfif>
                                #my_in_out#,
                                #my_is_sale#,
                                #my_is_purchase#,
                                <cfif arguments.process_type eq 140>1,<cfelse>0,</cfif>
                                #my_is_sarf#,
                                #my_is_rma#,
                                #my_seri_sonu#,
                                #my_is_return#,
                                #arguments.process_id#,
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.process_number#">,
                                #arguments.process_type#,
                                #session_base.period_id#,
                                <cfif len(arguments.dpt_id)>#arguments.dpt_id#<cfelse>NULL</cfif>,
                                <cfif len(arguments.loc_id)>#arguments.loc_id#<cfelse>NULL</cfif>,
                                <cfif trim(listgetat(evaluate('attributes.serial_no_start_number#arguments.session_row#'),j)) is not '---'><cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(listgetat(evaluate('attributes.serial_no_start_number#arguments.session_row#'),j))#"><cfelse>NULL</cfif>,
                                <cfif len(arguments.spect_id)>#arguments.spect_id#,<cfelse>NULL,</cfif>
                                <cfif len(arguments.main_process_id)><cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.main_process_id#">,<cfelse>NULL,</cfif>
                                <cfif len(arguments.main_process_no)><cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.main_process_no#">,<cfelse>NULL,</cfif>
                                <cfif len(arguments.main_process_cat)><cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.main_process_cat#">,<cfelse>NULL,</cfif>
                                <cfif len(arguments.main_serial_no)><cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.main_serial_no#">,<cfelse>NULL,</cfif>
                                <cfif len(subscription_id_)><cfqueryparam cfsqltype="cf_sql_varchar" value="#subscription_id_#">,<cfelse>NULL,</cfif>
                                #unit#,
                                <cfif isdefined('attributes.unit_row_quantity#arguments.session_row#')>
                                    <cfif listgetat(evaluate('attributes.unit_row_quantity#arguments.session_row#'),j) is not '*_*'>
                                        <cfqueryparam cfsqltype="cf_sql_float" value="#trim(listgetat(evaluate('attributes.unit_row_quantity#arguments.session_row#'),j))#">
                                    <cfelse>
                                        NULL
                                    </cfif>
                                <cfelseif len(arguments.unit_row_quantity)>
                                    <cfqueryparam cfsqltype="cf_sql_float" value="#arguments.unit_row_quantity#">
                                <cfelse>
                                    NULL
                                </cfif>,
                                <cfif isDefined('session.ep.userid')>
                                    #session.ep.userid#,
                                </cfif>
                                <cfqueryparam cfsqltype="cf_sql_varchar" value="#CGI.REMOTE_ADDR#">,
                                #NOW()#
                                <cfif j neq blok_sayisi>
                                    UNION ALL
                                </cfif>
                        </cfloop>
                    </cfquery>
                    <cfset baslangic_degeri = baslangic_degeri+400 />
                    <cfset blok_sayisi = blok_sayisi + 400 />
            </cfloop>
            </cfif>
            <cfreturn true>
        </cffunction>

<!--- get_product_no--->

	<cffunction name="get_product_no" returntype="any" output="false">
        <!---
        by :  20040110
        notes : 
    
        usage :
        get_product_no
            (
            action_type : product_no,stock_no
            );
        <cfset product_no = get_product_no(action_type:'product_no') />
        revisions : 
        --->
        <cfargument name="action_type" required="true" type="any">
        <cftransaction>
            <cfquery name="GET_PRODUCT_NO_" datasource="#dsn1#">
                SELECT 
                    <cfif arguments.action_type is 'product_no'>PRODUCT_NO</cfif>
                    <cfif arguments.action_type is 'stock_no'>STOCK_NO</cfif>
                    AS URUN_NUMBER
                FROM
                    PRODUCT_NO
            </cfquery>
            <cfif GET_PRODUCT_NO_.recordcount>
                <cfset urun_no_=GET_PRODUCT_NO_.URUN_NUMBER />
                <cfquery name="UPDATE_PRODUCT_NO_" datasource="#dsn1#">
                    UPDATE PRODUCT_NO
                        SET <cfif arguments.action_type is 'product_no'>PRODUCT_NO</cfif><cfif arguments.action_type is 'stock_no'>STOCK_NO</cfif>=#urun_no_+1#
                </cfquery>
                <cfreturn urun_no_>
            <cfelse>
                <cfreturn ''>
            </cfif>
        </cftransaction>
    </cffunction>
    
<!--- get_barcode_no--->

	<cffunction name="get_barcode_no" returntype="any" output="false">
	<cfargument name="barcode_for_ean8" default="">
     
    <cfif arguments.barcode_for_ean8 neq 1>
        <cflock name="#CreateUUID()#" timeout="20">
            <cftransaction>
                <cfquery name="GET_BARCODE_NO_" datasource="#DSN1#">
                    SELECT BARCODE FROM PRODUCT_NO
                </cfquery>
                <cfif GET_BARCODE_NO_.recordcount>
                    <cfset wrk_barcode = left(trim(GET_BARCODE_NO_.BARCODE),12) />
                    <cfquery name="UPDATE_BARCODE_NO_" datasource="#DSN1#">
                        UPDATE PRODUCT_NO SET BARCODE = '#wrk_barcode+1#X'<!--- 20050107 buradaki X in onemi yok kontorl karakteri yerine temporary bir deger --->
                    </cfquery>
                <cfelse>
                    <cfset wrk_barcode = '' />
                </cfif>
            </cftransaction>
        </cflock>
        <cfscript>
			function UPCEANCheck(s)
			{
				flag = true; i = 0; j = 0; k = 0;
				for( l = Len(s); l gte 1; l = l - 1)
					{
					if(flag) i = i + Mid(trim(s),l,1);
					else j = j + Mid(s,l,1);
					flag = not flag;
					}
				j = i * 3 + j;
				/*k = mode(j, 10);*/
				k = j mod 10;
				if(k neq 0)
					k = 10 - k;
				return k;
			}
			if(len(wrk_barcode)){
				wrk_barcode = wrk_barcode+1;
				if(len(wrk_barcode) eq 12)
					return wrk_barcode & UPCEANCheck(wrk_barcode);
				if(Len(wrk_barcode) lt 13)
					return '';
				}
			else
				return '';
				
        </cfscript>
    <cfelse>
        <cflock name="#CreateUUID()#" timeout="20">
            <cftransaction>
                <cfquery name="GET_BARCODE_NO_" datasource="#DSN1#">
                    SELECT BARCODE_EAN8 FROM PRODUCT_NO
                </cfquery>
                <cfif GET_BARCODE_NO_.recordcount>
                    <cfset wrk_barcode = left(trim(GET_BARCODE_NO_.BARCODE_EAN8),7) />
                    <cfset wrk_barcode = Int(wrk_barcode) />
                	<cfset len1= len(wrk_barcode) />
					<cfset deger = 7 - (len1) />
                    <cfset wrk_barcode = wrk_barcode+1 />
                    <cfloop from = "1" to = "#deger#" index = "xxx">
                    <cfset wrk_barcode = 0 & wrk_barcode />
                    </cfloop> 
                             
                    <cfquery name="UPDATE_BARCODE_NO_" datasource="#DSN1#">
                        UPDATE PRODUCT_NO SET BARCODE_EAN8 = '#wrk_barcode#X'<!--- 20050107 buradaki X in onemi yok kontorl karakteri yerine temporary bir deger --->
                    </cfquery>
                <cfelse>
                    <cfset wrk_barcode = '' />
                </cfif>
            </cftransaction>
        </cflock>
        <cfscript>
			function UPCEANCheck_EAN8(s,number)
			{
				barcode_no = s;
				tek_karakterler = 0;
				cift_karakterler = 0;
				toplam = 0;
				ilk_hane = 0;
				check_digit = 0;
				hedef_sayi = 0;
				for(i=1; i<=7; i++)
				{
					if(i % 2 == 1)
					{
						tek_karakterler = tek_karakterler + (3 * Mid(trim(s),i,1));
					}
					else
					{
						cift_karakterler = cift_karakterler + Mid(trim(s),i,1);
					}
				}
				toplam = tek_karakterler + cift_karakterler;
				son_hane = toplam%10;
				if(son_hane == 0)
					check_digit = 0;
				else
					check_digit = 10 - son_hane;
				
				yeni_barkod = check_digit;
				s = yeni_barkod;
				return s;
			}

            if(len(wrk_barcode)){
               	wrk_barcode = Int(wrk_barcode);
				 wrk_barcode = wrk_barcode;
				 len1 = len(wrk_barcode);
				 deger = 7 - (len1);
				for(index=1; index LTE deger; index = index + 1) 
				    wrk_barcode = 0 & wrk_barcode;
               
                if(len(wrk_barcode) eq 7)
                    return wrk_barcode & UPCEANCheck_EAN8(wrk_barcode,7);
                if(Len(wrk_barcode) lt 8)
                    return '';
                }
            else
                return '';
        </cfscript>
    </cfif>   
</cffunction>

    
<!--- del_serial_no --->

	<cffunction name="del_serial_no" output="false">
        <cfargument name="process_id" type="numeric" required="true">
        <cfargument name="process_cat" type="numeric" required="true">
        <cfargument name="period_id" type="numeric" required="true">
        <cfargument name="is_dsn3" type="numeric" required="no" default="0">
    
        <cfif arguments.is_dsn3 eq 0>
            <cfset serial_dsn = '#DSN2#' />
            <cfset dsn_add_ = '#dsn3_alias#' />
        <cfelse>
            <cfset serial_dsn = '#DSN3#' />
            <cfset dsn_add_ = '' />
        </cfif>
    
        <cfquery name="del_serial_numbers" datasource="#serial_dsn#">
            DELETE FROM 
                <cfif len(dsn_add_)>#dsn_add_#.</cfif>SERVICE_GUARANTY_NEW 
            WHERE
                PROCESS_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.process_id#"> AND
                PROCESS_CAT = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.process_cat#"> AND
                PERIOD_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.period_id#">
        </cfquery>
        <!--- BK kaldirdi 6 aya kaldirilmali. 20130529
        <cfquery name="del_serial_numbers_history" datasource="#serial_dsn#">
            DELETE FROM 
                <cfif len(dsn_add_)>#dsn_add_#.</cfif>SERVICE_GUARANTY_NEW_HISTORY 
            WHERE
                PROCESS_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.process_id#"> AND
                PROCESS_CAT = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.process_cat#"> AND
                PERIOD_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.period_id#">
        </cfquery> --->
        <cfreturn true>
    </cffunction>
    
<!--- get_production_times--->

	 <cffunction name="get_production_times" returntype="string" output="no">
        <cfargument name="station_id" type="boolean" default="1">
        <cfargument name="shift_id" type="boolean" default="1">
        <cfargument name="stock_id" type="boolean" default="1">
        <cfargument name="amount" type="boolean" default="1">
        <cfargument name="min_date" type="numeric" default="0">
        <cfargument name="setup_time_min" type="numeric" default="0">
        <cfargument name="production_type" type="boolean" default="0">
        <cfargument name="_now_" type="string" default="">
        <cfquery name="GET_STATION_CAPACITY" datasource="#DSN3#"><!--- Seçilen istasyona ve ürüne bağlı olarak istasyonumuzun o ürünü ne kadar zamanda ürettiği bilgileri --->
            SELECT 
                *
            FROM
                WORKSTATIONS_PRODUCTS WSP,
                WORKSTATIONS W
            WHERE
                W.STATION_ID=WSP.WS_ID AND 
                WSP.STOCK_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.stock_id#"> AND
                WS_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.station_id#">
        </cfquery>
        <cfif GET_STATION_CAPACITY.RECORDCOUNT>
            <cfset capacity = GET_STATION_CAPACITY.CAPACITY />
        <cfelse>
            <cfset capacity = 1 />
        </cfif>    
        <cfset amount = arguments.amount />
        <!--- İstasyon zamanlarında bazen hata oluyordu,onu engellemek için eklendi...Üretim zamanı 0,000001 gibi bi değer inifty oluyor ve 0 geldiği için çakıyordu --->
        <cfif capacity eq 0><cfset capacity =1 /></cfif>
        <cfset gerekli_uretim_zamani_dak = wrk_round((amount/capacity)*60,6) />
        <cfif arguments.setup_time_min gt 0><cfset gerekli_uretim_zamani_dak = arguments.setup_time_min + gerekli_uretim_zamani_dak /></cfif>
        <!--- <cfoutput><font color="FF0000">**********#arguments.min_date#************************ </font> </cfoutput> --->
        <cfif len(arguments._now_) and isdate(arguments._now_)>
            <cfset _now_ = arguments._now_ />
        <cfelse>
            <cfset _now_ = date_add('h',session.ep.TIME_ZONE,now()) />
        </cfif>
        <cfquery name="get_station_times" datasource="#dsn#">
            SELECT * FROM SETUP_SHIFTS WHERE IS_PRODUCTION = 1 AND FINISHDATE > <cfqueryparam cfsqltype="cf_sql_timestamp" value="#_now_#"> AND SHIFT_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.shift_id#">
        </cfquery>
        <cfif get_station_times.recordcount>
            <cfset calisma_start = (get_station_times.START_HOUR*60)+get_station_times.START_MIN />
            <cfset calisma_finish = (get_station_times.END_HOUR*60)+get_station_times.END_MIN />
        <cfelse>
            <cfset calisma_start = 01 />
            <cfset calisma_finish = 1439 />
        </cfif>
        <cfquery name="get_station_select" datasource="#dsn3#">
            SELECT DISTINCT
                DATEPART(hh,START_DATE)*60+DATEPART(n,START_DATE) AS START_TIME,
                DATEPART(M,START_DATE) AS START_MONT,
                DATEPART(D,START_DATE) AS START_DAY,
                DATEPART(hh,FINISH_DATE)*60+DATEPART(n,FINISH_DATE) AS FINISH_TIME,
                DATEPART(M,FINISH_DATE) AS FINISH_MONT,
                DATEPART(D,FINISH_DATE) AS FINISH_DAY,
                datediff(d,START_DATE,FINISH_DATE) AS FARK,
                START_DATE,FINISH_DATE	
            FROM 
                PRODUCTION_ORDERS 
            WHERE 
                STATION_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.station_id#"> AND 
                (START_DATE > <cfqueryparam cfsqltype="cf_sql_timestamp" value="#_now_#"> OR FINISH_DATE > <cfqueryparam cfsqltype="cf_sql_timestamp" value="#_now_#">)
        UNION ALL
            SELECT
                DISTINCT
                DATEPART(hh,START_DATE)*60+DATEPART(n,START_DATE) AS START_TIME,
                DATEPART(M,START_DATE) AS START_MONT,
                DATEPART(D,START_DATE) AS START_DAY,
                DATEPART(hh,FINISH_DATE)*60+DATEPART(n,FINISH_DATE) AS FINISH_TIME,
                DATEPART(M,FINISH_DATE) AS FINISH_MONT,
                DATEPART(D,FINISH_DATE) AS FINISH_DAY,
                datediff(d,START_DATE,FINISH_DATE) AS FARK,
                START_DATE,FINISH_DATE	
            FROM 
                PRODUCTION_ORDERS_CASH
            WHERE 
                STATION_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.station_id#"> AND 
                (START_DATE > <cfqueryparam cfsqltype="cf_sql_timestamp" value="#_now_#"> OR FINISH_DATE > <cfqueryparam cfsqltype="cf_sql_timestamp" value="#_now_#">)
            ORDER BY 
                START_DATE ASC,FINISH_DATE ASC
        </cfquery>
        <cfset full_days ='' />	<!---dolu olan günleri yani iş yüklemesi yapamıyacağım günleri belirliyoruz. --->
        <cfset production_type = arguments.production_type /><!--- 0 ise sürekli üretim 1 ise parçalı üretim yapacak  --->
        <!--- Üretimlerimizin içinden başlangıç ve bitiş saatlerini hesaplayarak çalışma saatlerimizi şekillendiriyoruz. --->
        <table cellpadding="1" cellspacing="1" border="1" width="100%" class="">
        <cfoutput query="get_station_select">
            <cfset p_start_day = DateFormat(START_DATE,'YYYYMMDD') />
            <cfset p_finish_day = DateFormat(FINISH_DATE,'YYYYMMDD') />
           <tr>
            <cfif FARK gt 0><!--- Başlangıç ve bitiş tarihleri aynı olmayan üretim emirleri gelsin sadece. --->
                <cfloop from="0" to="#FARK#" index="_days_">
                    <cfset new_days = DateFormat(date_add('D',_days_,START_DATE),'YYYYMMDD') />
                    <cfif not ListFind(full_days,new_days,',') and new_days gte DateFormat(_NOW_,'YYYYMMDD')><!--- DOLU GÜNLER İÇİNDE OLMAYAN GÜNLER GELSİN SADECE --->
                        <cfif not isdefined('empty_days#new_days#') OR(isdefined('empty_days#new_days#') and not len(Evaluate('empty_days#new_days#')))><cfset 'empty_days#new_days#' = '#calisma_start#-#calisma_finish#' /><!--- ----#new_days# ---></cfif>
                            <td>
                                <cfif new_days eq p_start_day><!--- Üretimin Başladığı Gün ise --->
                               <font color="33CC33">#new_days#[#START_TIME#]</font>
                                    <cfif START_TIME lte ListGetAt(Evaluate('empty_days#new_days#'),2,'-') and START_TIME gte ListGetAt(Evaluate('empty_days#new_days#'),1,'-')><!--- Üretim zamanımız çalışma saatleri arasında ise --->
                                       <cfset 'empty_days#new_days#' = '#ListGetAt(Evaluate('empty_days#new_days#'),1,'-')#-#START_TIME-1#' />
                                    </cfif>
                                <cfelseif new_days eq p_finish_day><!--- Üretimin Bittiği Gün ise --->
                                <font color="FF0000">bitiş=>#new_days#[#FINISH_TIME#]</font>
                                    <!--- <cfif ListLen(Evaluate('empty_days#new_days#'),'-') lt 2>#new_days#cccc#Evaluate('empty_days#new_days#')#aaaa<cfabort></cfif> --->
                                    <cfif FINISH_TIME lte ListGetAt(Evaluate('empty_days#new_days#'),2,'-') and FINISH_TIME gte ListGetAt(Evaluate('empty_days#new_days#'),1,'-')>
                                        <cfset 'empty_days#new_days#' = '#FINISH_TIME+1#-#ListGetAt(Evaluate('empty_days#new_days#'),2,'-')#' />
                                    <cfelseif  FINISH_TIME gte ListGetAt(Evaluate('empty_days#new_days#'),2,'-')><!--- eğer bitiş zamanı çalışma saatlerinin üzerinde ise,o zamanda o günüde dolu günler arasına alıyoruz. --->
                                        <cfset full_days =ListAppend(full_days,new_days,',') />#new_days#
                                    </cfif>
                                <cfelse><!--- Üretimin başlagıç ve bitiş tarihi arasında kalan günler ise bu günler zaten üretim ile dolu günler olduğu için direkt olarak kapatıyoruz. --->
                                    <cfset full_days =ListAppend(full_days,new_days,',') />#new_days#XX
                                </cfif>
                               <!--- ///[#Evaluate('empty_days#new_days#')#]// --->
                           </td>
                      </cfif>
                </cfloop>
            </cfif>
            </tr>
        </cfoutput>
        </table>
        <!--- bURDA İSE BAŞLANGIÇ VE BİTİŞ GÜNLERİ AYNI OLAN ÜRETİMLERİ ŞEKİLLENDİRİCEZ. --->
        <cfoutput query="get_station_select">
            <cfset p_start_day = DateFormat(START_DATE,'YYYYMMDD') />
            <cfif FARK eq 0 and not listfind(full_days,p_start_day,',') and p_start_day gte DateFormat(_NOW_,'YYYYMMDD')><!--- Başlama ve bitiş tarihi aynı olan günler yani 1 gün içinde başlayıp biten üretimlere bakıyoruz. --->
                    <cfif not isdefined('empty_days#p_start_day#') OR (isdefined('empty_days#p_start_day#') and not len(Evaluate('empty_days#p_start_day#')))><cfset 'empty_days#p_start_day#' = '#calisma_start#-#calisma_finish#'></cfif>
                    <!--- <cfset days_list = listdeleteduplicates(ListAppend(days_list,p_start_day,',')) /> --->
                    <cfif START_TIME lt calisma_start><cfset START_TIME = calisma_start /></cfif>
                    <cfif FINISH_TIME lt calisma_finish><cfset FINISH_TIME = calisma_finish /></cfif>
                    <cfloop list="#Evaluate('empty_days#p_start_day#')#" index="list_d">
                         <cfif ListLen(list_d,'-') neq 2>
                            <cfset saat_basi=list_d /><!--- Sadece hata vermesin diye eklendi daha sonra silinecek! --->
                            <cfset saat_sonu=list_d+60 />
                            <cfset list_d = '#saat_basi#-#saat_sonu#' />
                        <cfelse>
                            <cfset saat_basi=ListGetAt(list_d,1,'-') />
                            <cfset saat_sonu=ListGetAt(list_d,2,'-') /><!--- 11:00-13:00 --->
                        </cfif>
                        <cfif START_TIME gt saat_basi and START_TIME lt saat_sonu and FINISH_TIME lt saat_sonu><!--- ortadaysa 11:30-12--->
                            <cfset aaa='#ListGetAt(list_d,1,'-')#-#START_TIME-1#' />
                            <cfset bb='#FINISH_TIME+1#-#ListGetAt(list_d,2,'-')#' />
                            <cfset 'empty_days#p_start_day#' = ListDeleteAt(Evaluate('empty_days#p_start_day#'),listfind(Evaluate('empty_days#p_start_day#'),list_d)) />
                            <cfset 'empty_days#p_start_day#' = ListAppend(Evaluate('empty_days#p_start_day#'),aaa) />
                            <cfset 'empty_days#p_start_day#' = ListAppend(Evaluate('empty_days#p_start_day#'),bb) />
                          <!--- ##=>111111 : #aaa#--<!--- #bb# ---><br/> <!---  ---> --->
                         <cfelseif START_TIME lte saat_basi and FINISH_TIME gt saat_basi and FINISH_TIME lt saat_sonu><!--- 9-12 --->
                            <cfset ccc = '#FINISH_TIME+1#-#ListGetAt(list_d,2,'-')#' />
                           <cfif listlen(Evaluate('empty_days#p_start_day#')) and list_d gt 0 and listfind(Evaluate('empty_days#p_start_day#'),list_d) gt 0>
                                <cfset 'empty_days#p_start_day#' = ListDeleteAt(Evaluate('empty_days#p_start_day#'),listfind(Evaluate('empty_days#p_start_day#'),list_d)) />
                                <cfset 'empty_days#p_start_day#' = ListAppend(Evaluate('empty_days#p_start_day#'),ccc) />
                            </cfif>
                          <!---  2222222 :#START_TIME#---#FINISH_TIME#--*#ccc#<br/><!---  ---> --->
                         <cfelseif START_TIME lte saat_basi and FINISH_TIME gt saat_basi and FINISH_TIME gte saat_sonu> <!--- 9-14 --->
                            <cfif listlen(Evaluate('empty_days#p_start_day#')) and list_d gt 0 and listfind(Evaluate('empty_days#p_start_day#'),list_d) gt 0>
                                <cfset 'empty_days#p_start_day#' = ListDeleteAt(Evaluate('empty_days#p_start_day#'),listfind(Evaluate('empty_days#p_start_day#'),list_d)) />
                            </cfif>
                         <cfelseif START_TIME lte saat_basi and  FINISH_TIME gt saat_basi and FINISH_TIME lt saat_sonu><!--- 11-12 --->
                            <cfset ffff = '#FINISH_TIME+1#-#ListGetAt(list_d,2,'-')#' />
                            <cfset 'empty_days#p_start_day#' = ListDeleteAt(Evaluate('empty_days#p_start_day#'),listfind(Evaluate('empty_days#p_start_day#'),list_d)) />
                            <cfset 'empty_days#p_start_day#' = ListAppend(Evaluate('empty_days#p_start_day#'),ffff) />
                           <!--- 33333333 :#START_TIME#---#FINISH_TIME#--*#ffff#<br/><!---  ---> --->
                         <cfelseif START_TIME gt saat_basi and  START_TIME lt saat_sonu and FINISH_TIME gte saat_sonu><!--- 12-13,12-14 --->
                            <cfset dddd = '#saat_basi#-#START_TIME-1#' />
                            <cfset 'empty_days#p_start_day#' = ListDeleteAt(Evaluate('empty_days#p_start_day#'),listfind(Evaluate('empty_days#p_start_day#'),list_d)) />
                            <cfset 'empty_days#p_start_day#' = ListAppend(Evaluate('empty_days#p_start_day#'),dddd) />
                         <!---  44444444 :#START_TIME#---#FINISH_TIME#--*#dddd#<br/><!---   ---> --->
                        <cfelseif START_TIME gt saat_basi and START_TIME lte saat_sonu and FINISH_TIME gte saat_sonu>
                            <cfset eeee = '#ListGetAt(list_d,1,'-')#-#START_TIME-1#' />
                            <cfset 'empty_days#p_start_day#' = ListDeleteAt(Evaluate('empty_days#p_start_day#'),listfind(Evaluate('empty_days#p_start_day#'),list_d)) />
                            <cfset 'empty_days#p_start_day#' = ListAppend(Evaluate('empty_days#p_start_day#'),eeee) />
                          <!---  555555 : ******#list_d#********-------#eeee#<br/> --->
                        <cfelseif (START_TIME lte calisma_start and FINISH_TIME gte calisma_finish)><!--- 9-14 --->
                            <!--- kapandı: --->
                            <cfset full_days = ListAppend(full_days,p_start_day,',') />
                        </cfif>
                    </cfloop>
               <!---     #p_start_day#==>#Evaluate('empty_days#p_start_day#')#</font> <br/>
                  #p_start_day#==>[[#Evaluate('empty_days#p_start_day#')#]]<br/>
                    #Evaluate('empty_days#p_start_day#')#***#START_TIME#-#FINISH_TIME#<br/> --->
            </cfif>
        </cfoutput>
        <cfset uretim_birlesim_dakika = 0 />
        <cfoutput>
            <cfset songun = 365 /><!--- üretim verildikten sonra 1 yıl boyunca boş zamana bakıyoruz. --->
            <cfloop from="0" to="#songun#" index="_i_n_d_">
                <cfset crate_days = DateFormat(date_add('d',_i_n_d_,_NOW_),'YYYYMMDD') /><!--- ilk gün olarak bugünü alıyoruz. --->
                <cfif not listfind(full_days,crate_days,',')><!--- Yukarda belirlediğimiz dolu günlerin içinde değil ise --->           
                    <cfif not isdefined('empty_days#crate_days#') OR(isdefined('empty_days#crate_days#') and not len(Evaluate('empty_days#crate_days#')))><cfset 'empty_days#crate_days#' = '#calisma_start#-#calisma_finish#'><!--- tanımlanmamış boş kalmış günleri çalışma saatlerinin zamanlarını atıyoruz. ---></cfif>
                    <cfset last_empty_time = listlast(Evaluate('empty_days#crate_days#'),',') /><!---sonzaman=>günün son boş saatinin aralığı mesela [15:15-16:20],[17:00-19:30] saatleri boş zamanlar olsun,sondan ekleme yapmak için burda[17:00-19:30] luk kısmı getiriyor.  --->
                    <cfset next_day = DateFormat(date_add('d',_i_n_d_+1,now()),'YYYYMMDD') /><!--- bir sonraki günü belirliyoruz. --->
                    <cfif DateFormat(_NOW_,'YYYYMMDD') eq crate_days><!--- eğer bugüne bakılıyorsa  --->
                        <cfset now_minute = (ListGetAt(TimeFormat(_now_,'HH:MM'),1,':') * 60) + ListGetAt(TimeFormat(_now_,'HH:MM'),2,':') /><!--- şu anı dk olarak set ediyoruz. --->
                        <cfloop list="#Evaluate('empty_days#crate_days#')#" index="now_edit">
                            <!--- #now_minute#___#ListGetAt(now_edit,1,'-')#___#ListGetAt(now_edit,2,'-')# --->
                            <cfif now_minute gt ListGetAt(now_edit,1,'-') and now_minute lt ListGetAt(now_edit,2,'-')><!--- bugünün boş saatlerini şu andan sonra olacak şekilde düzenliyoruz. mesela şu anda saat 14:00 olsun,boş zaman [12:00-16:00] bu durumda bu boş zaman [14:00-16:00] arası oluyor. --->
                                 <cfset 'empty_days#crate_days#' = ListSetAt(Evaluate('empty_days#crate_days#'),ListFind(Evaluate('empty_days#crate_days#'),now_edit,','),"#now_minute#-#ListGetAt(now_edit,2,'-')#",',') />
                            <cfelseif now_minute gt ListGetAt(now_edit,1,'-') and now_minute gt ListGetAt(now_edit,2,'-')>
                                 <cfset full_days =ListAppend(full_days,crate_days,',') />
                            <cfelseif now_minute gt ListGetAt(now_edit,1,'-') and now_minute lt ListGetAt(now_edit,2,'-')>
                                 <cfif ListFind(full_days,crate_days,',') gt 0>
                                     <cfset full_days =ListDeleteAt(full_days,ListFind(full_days,crate_days,','),',') />
                                </cfif>
                                 <cfif ListFind(evaluate('empty_days#crate_days#'),now_edit,',')-1 gt 0>
                                     <cfset 'empty_days#crate_days#' =ListDeleteAt(evaluate('empty_days#crate_days#'),ListFind(evaluate('empty_days#crate_days#'),now_edit,',')-1,',') />
                                 </cfif>
                            <cfelseif now_minute lt ListGetAt(now_edit,1,'-') and now_minute lt ListGetAt(now_edit,2,'-')>
                                <cfif ListFind(full_days,crate_days,',') gt 0>
                                     <cfset full_days =ListDeleteAt(full_days,ListFind(full_days,crate_days,','),',') />
                                </cfif>
                                 <cfif ListFind(evaluate('empty_days#crate_days#'),now_edit,',')-1 gt 0>
                                     <cfset 'empty_days#crate_days#' =ListDeleteAt(evaluate('empty_days#crate_days#'),ListFind(evaluate('empty_days#crate_days#'),now_edit,',')-1,',') />
                                 </cfif>
                            </cfif>
                        </cfloop>
                    </cfif>#crate_days#==>#Evaluate('empty_days#crate_days#')#</font> <br/>
                    <cfif not listfind(full_days,crate_days,',')>
                    <cfif production_type eq 0><!--- continue üretim yapılıyor ise --->
                        <!--- #Evaluate('empty_days#crate_days#')#-- --->
                        <!--- #crate_days# #next_day#==> #Evaluate('empty_days#crate_days#')#==>sonzaman==> #last_empty_time# ==>birsonkgünbaş==>#next_first_empty_time# --->
                        <!--- <cfif ListLast(last_empty_time,'-') eq calisma_finish><!--- son boş zamanın bitiş saati istasyonun çalışma bitiş saatine eşitmi --->
                            <cfset last_time_diff = ListLast(last_empty_time,'-')-ListFirst(last_empty_time,'-')>
                        <cfelse>    
                            <cfset last_time_diff = -1>
                        </cfif>bugünFarkı=>#last_time_diff# --->
                       <!---  <cfif ListFirst(next_first_empty_time,'-') eq calisma_start>
                            <cfset firs_time_diff =  ListLast(next_first_empty_time,'-')-ListFirst(next_first_empty_time,'-')>
                        <cfelse>    
                            <cfset firs_time_diff = -1>
                        </cfif>=>sonrakiGFark=>#firs_time_diff# --->
                        <!--- günler bazında --->
                        <!--- birgün boşluğuna girecek bir üretim ise boş olan zamanlar dönsün --->
                        <cfif gerekli_uretim_zamani_dak lte (calisma_finish-calisma_start)><!--- 1 gün içinde bitebilecek bir üretim ise günün içindeki boş zamanlara bakıyoruz. --->
                             <cfloop list="#Evaluate('empty_days#crate_days#')#" index="l_list">
                                <cfif ListGetAt(l_list,2,'-')-ListGetAt(l_list,1,'-') gte gerekli_uretim_zamani_dak>
                                    <cfset finded_production_start_day = crate_days />
                                    <cfset finded_production_finish_day = crate_days />
                                    <cfset finded_production_start_time = "#Int(ListGetAt(l_list,1,'-')/60)# : #ListGetAt(l_list,1,'-') mod 60#" />
                                    <cfset finded_production_finish_time = "#Int((ListGetAt(l_list,1,'-')+gerekli_uretim_zamani_dak)/60)# : #(ListGetAt(l_list,1,'-')+gerekli_uretim_zamani_dak) mod 60#" />
                                   <!---  bulundu!**#finded_production_start_day# -- #finded_production_start_time#-#finded_production_finish_time#<br/> --->
                                    <cfset finded_production_start_finish_times = "#finded_production_start_day#,#finded_production_start_time#,#finded_production_finish_day#,#finded_production_finish_time#" />
                                <cfreturn finded_production_start_finish_times>
                                    <cfexit method="exittemplate"><!--- uygun aralığı bulursa çıksın --->
                                </cfif>
                            </cfloop>
                        </cfif>
                        <!--- birbirni takip eden günlerde üretim. --->
                        <cfif not listfind(full_days,next_day,',')><!--- bir sonraki gün dolu günler arasında değilse  --->
                            <cfif not isdefined('empty_days#next_day#')><!--- bir sonraki günün başlagınç zamanını alıcaz mesela 09:15-12:20 --->
                                <cfset next_first_empty_time = '#calisma_start#-#calisma_finish#' />
                            <cfelse>
                                <cfset next_first_empty_time = ListFirst(Evaluate('empty_days#DateFormat(date_add('d',_i_n_d_+1,now()),'YYYYMMDD')#'),',') />
                            </cfif>
                        <cfelse> 
                            <cfset next_first_empty_time = -1 />
                        </cfif>
                        <cfif (not listfind(full_days,next_day,',')) and<!--- bulduğumuz bir sonraki gün dolu günler arasında değil ise --->
                               (ListLast(last_empty_time,'-') eq calisma_finish) and<!--- bugünün son boş zamanının bitiş saati calisma programının bitiş saati ile eşitmi --->
                               (ListFirst(next_first_empty_time,'-') eq calisma_start)<!--- bir sonraki gündeki boş zamanın başlangıç saati calisma programının başlamgıç saati ile eşitmi --->
                               >
                               <!--- <font color="0000FF">#Evaluate('empty_days#crate_days#')# uz:#ListLen(Evaluate('empty_days#crate_days#'),',')#</font> --->
                                <cfif ListLen(Evaluate('empty_days#crate_days#'),',') neq 1><!--- bir taneden fazla boş çalışma anı varsa eğer günümüzde yani =>[10:05-12:30],[13:13-15:00] böyle ise --->
                                    <cfset finded_production_start_time = "#Int(ListGetAt(last_empty_time,1,'-')/60)# : #ListGetAt(last_empty_time,1,'-') mod 60#" />
                                    <cfset finded_production_start_day = crate_days />
                                    <cfset uretim_birlesim_dakika = ListLast(last_empty_time,'-')-ListFirst(last_empty_time,'-')+ListLast(next_first_empty_time,'-')-ListFirst(next_first_empty_time,'-') />
                                <cfelseif ListFirst(next_first_empty_time,'-') eq calisma_start and ListLast(next_first_empty_time,'-') eq calisma_finish><!--- bir sonraki gündeki boş zamanın başlangıç saati calisma programının başlamgıç saati ile eşitmi --->
                                    <cfset uretim_birlesim_dakika = uretim_birlesim_dakika + (ListLast(last_empty_time,'-')-ListFirst(last_empty_time,'-')) />
                                <cfelse>
                                    <cfset uretim_birlesim_dakika = uretim_birlesim_dakika + (ListLast(last_empty_time,'-')-ListFirst(last_empty_time,'-')) + ListLast(next_first_empty_time,'-')-ListFirst(next_first_empty_time,'-') />
                                </cfif>	  
                        <cfelse>
                                <cfset uretim_birlesim_dakika = 0 />
                        </cfif>
                        <!---bulunan zamanı karşılaştırıyoruz. --->
                        <cfif uretim_birlesim_dakika gte gerekli_uretim_zamani_dak>
                            <!--- <font color="66666"> --->
                                <cfif not isdefined('finded_production_start_day')>
                                    <cfset finded_production_start_day = crate_days />
                                    <cfset finded_production_start_time = "#Int(ListGetAt(last_empty_time,1,'-')/60)# : #ListGetAt(last_empty_time,1,'-') mod 60#" />
                                </cfif>
                                <cfset _fark_ = uretim_birlesim_dakika-gerekli_uretim_zamani_dak />
                                <cfset finded_production_finish_day = next_day />
                                <cfset finded_production_finish_time =" #Int((ListGetAt(next_first_empty_time,2,'-') - _fark_)/60)# : #(ListGetAt(next_first_empty_time,2,'-') - _fark_) mod 60#" />
                           <!---  #finded_production_start_day#__#finded_production_start_time#-----#finded_production_finish_day# : #finded_production_finish_time#
                            BULUNDU!!!!!!!!!!!!!!!!!!</font> --->
                            <cfset finded_production_start_finish_times = "#finded_production_start_day#,#finded_production_start_time#,#finded_production_finish_day#,#finded_production_finish_time#" />
                            <cfreturn finded_production_start_finish_times>
                            <cfexit method="exittemplate">
                        </cfif>
                    <cfelse><!--- Parçalı Üretim yapılıyorsa --->
                          <cfif uretim_birlesim_dakika eq 0><!--- ilk günümüz belli oluyor.--->
                                <cfset finded_production_start_day = crate_days /><cfif listlen(Evaluate('empty_days#finded_production_start_day#'),'-') lt 2>DOLU GÜNLER =>#full_days#---#finded_production_start_day#=>#Evaluate('empty_days#finded_production_start_day#')#--</cfif>
                                <cfset finded_production_start_time = "#Int(ListFirst(Evaluate('empty_days#finded_production_start_day#'),'-')/60)# : #ListFirst(Evaluate('empty_days#finded_production_start_day#'),'-') mod 60#" />
                          </cfif>
                           <font color="FF0000">#Evaluate('empty_days#crate_days#')#</font><br/>
                          <cfloop list="#Evaluate('empty_days#crate_days#')#" index="new_indx">
                                <cfset uretim_birlesim_dakika = uretim_birlesim_dakika + (ListGetAt(new_indx,2,'-')-ListGetAt(new_indx,1,'-')) />
                                <cfif uretim_birlesim_dakika gte gerekli_uretim_zamani_dak>
                                    <cfset finded_production_finish_day = crate_days /><!--- üretimin dolduğu anı buluyoruz. --->
                                    <cfset onceki_uretim_birlesim_dakika = uretim_birlesim_dakika-(ListGetAt(new_indx,2,'-')-ListGetAt(new_indx,1,'-')) />
                                    <cfset fark = gerekli_uretim_zamani_dak-onceki_uretim_birlesim_dakika />
                                    <cfset finded_production_finish_time =" #Int(((ListGetAt(new_indx,1,'-')+fark))/60)# : #((ListGetAt(new_indx,1,'-')+fark)) mod 60#" />
                                    <cfset finded_production_start_finish_times = "#finded_production_start_day#,#finded_production_start_time#,#finded_production_finish_day#,#finded_production_finish_time#" />
                               <cfreturn finded_production_start_finish_times>
                                    <cfexit method="exittemplate">
                                </cfif>
                          </cfloop>
                    </cfif>
                    </cfif>
                    <!--- bu satırlar silinmesin bunlar test yaparken gerekli oluyor. 
                   <font color="red">#ListLast(last_empty_time,'-')-ListFirst(last_empty_time,'-')#<!--- +#ListLast(next_first_empty_time,'-')-ListFirst(next_first_empty_time,'-')# --->==>[[[#uretim_birlesim_dakika#]]]</font>--->
                </cfif>
            </cfloop>
        </cfoutput>
    </cffunction>
    
<!---get_product_stock_cost--->

	<cffunction name="get_product_stock_cost" returntype="string" output="true">
	<!--- Oluşturma geçmiş zaman ve yapan belli değil ancak nerde ise tamamen değişti
    TolgaS 20061205
        notes : İstenen ürün veya stoğun istenen yönteme göre maliyetini hesaplar
        Arguments:
            -is_product_stock:		1:product_id veya 2:stock_id
            -product_stock_id:		product_id veya stock_id
            -tax_inc:		KDV Dahil(1), KDV Hariç(0)
            -cost_method:	
                Yöntemler
                ---------
                1: fifo:	İlk Giren İlk Çıkar
                2: lifo:	Son Giren İlk Çıkar
                3: gpa:		Ağırlıklı Ortalama
                4: lpp:		Son Alış Fiyatı
                5: fpp:		İlk Alış Fiyatı
                6: st:		Standart Alış
                7: st:		Standart Satış
            -cost_money : maliyetin hesaplanacagi parabrimi (standart satış genelde)
            -action_id : belge idsi (maliyetti eklenecek belge)
            -action_row_id : belge satır idsi
            -action_type : 1 fatura, 2 israliye,3 stok fisi,4 üretim, 5 stok virman,-1 Excelden aktarım ile...
            -spec_id:
            -spec_main_id :	maliyet eklenecek urun main spec idsi
            -period_dsn_type : donemlerde sorun olmaması icin calistirilacak donem yollanmalı
            -pur_sale : alış satış mı
            -cost_date :
            -cost_money_system : sistem parabirimi maliyeti hesaplanırken kullanılır
            -cost_money_system_2 : 2 sistem para brimi
            -action_comp_period_list : agirlikli ortalama icin sirket donem id listesi
            -action_cost_id : guncellenen maliyetin ilerki tarihli maliyetleri guncellenirken elle eklenenler için cost_id yollanıyor
            -is_cost_zero_row : 0 tutarlı satırlar maliyet oluştursunmu 1 oluşturur 0 oluşturmaz
            -is_cost_zero_row : 0 tutarlar net maliyetdenmi fiyatdanmı alınsın
        usage :
            get_product_stock_cost(is_product_stock:1,product_stock_id:11,tax_inc:1,cost_method:1,cost_money:'USD',action_id:1,action_type:1,spec_main_id:50)
            get_product_stock_cost(is_product_stock:2,product_stock_id:22,tax_inc:0,cost_method:6,cost_money:'EURO')
    --->
        <cfargument name="is_product_stock" type="boolean" required="yes">
        <cfargument name="product_stock_id" type="numeric" required="yes">
        <cfargument name="tax_inc" type="boolean" required="yes">
        <cfargument name="cost_method" required="yes">
        <cfargument name="pur_sale" type="boolean" required="no">
        <cfargument name="cost_date" type="date" default="#now()#" required="no">
        <cfargument name="cost_money" type="string" required="yes"><!--- maliyetin hesaplanacagi parabrimi (standart satış genelde) --->
        <cfargument name="cost_money_system" type="string" required="no" default="#session.ep.money#">
        <cfargument name="cost_money_system_2" type="string" required="no" default="USD"><!--- sistem 2. para birimi --->
        <cfargument name="action_id" type="numeric" required="no" default="0">
        <cfargument name="action_row_id" type="string" required="no" default="0">
        <cfargument name="action_type" type="numeric" required="no" default="1">
        <cfargument name="spec_id" type="numeric" required="no">
        <cfargument name="spec_main_id" type="numeric" required="no">
        <cfargument name="period_dsn_type" type="string" required="no" default="#dsn2#">
        <cfargument name="action_comp_period_list" type="string" required="no" default="0"><!--- agirlikli ortalama icin sirket donem id listesi --->
        <cfargument name="action_cost_id" type="numeric" required="no" default="0"><!--- guncellenen maliyetin ilerki tarihli maliyetleri guncellenirken elle eklenenler için cost_id yollanıyor --->
        <cfargument name="is_cost_zero_row" type="numeric" required="no">
        <cfargument name="is_cost_field" type="numeric" required="no">
        <cfargument name="control_type" type="numeric" required="no" default="0">
        <cfargument name="is_cost_calc_type" type="numeric" required="no" default="1">
    <!--- <CFDUMP var="#arguments#"> --->
        <cfswitch expression="#arguments.cost_method#">
            <cfcase value="1">
                <cfinclude template="../V16/objects/display/price_fifo.cfm" />
            </cfcase>
            <cfcase value="2">
                <cfinclude template="../V16/objects/display/price_lifo.cfm" />
            </cfcase>
            <cfcase value="3">
                <cfinclude template="../V16/objects/display/price_gpa.cfm" />
            </cfcase>
            <cfcase value="4">
                <cfinclude template="../V16/objects/display/price_lpp.cfm" />
            </cfcase>
            <cfcase value="5">
                <cfinclude template="../V16/objects/display/price_fpp.cfm" />
            </cfcase>
            <cfcase value="6,7">
                <cfinclude template="../V16/objects/display/price_st.cfm" />
            </cfcase>
            <cfcase value="8">
                <cfinclude template="../V16/objects/display/price_production.cfm" />
            </cfcase>
        </cfswitch>
        <cfreturn stock_cost>
    </cffunction>

	<cffunction name="get_cost_rate" returntype="string">
	<!--- vereilen belge degerleri ile maliyetin eklendigi kur bulunur historyden almak icin once setup money alınıyor o donerken hıstory varmı diye bakıyor cunku yeni kur eklenmis olabilir yada historyde olmaya bilir--->
        <cfargument name="action_id" type="numeric" required="yes">
        <cfargument name="action_type" type="numeric" required="yes">
        <cfargument name="action_date" type="string" required="yes">
        <cfargument name="dsn_period_money" type="string" required="yes" default="#form.dsn3#">
        <cfargument name="dsn_money" type="string" required="yes" default="#form.dsn#">
        <cfargument name="session_period_id" type="numeric" required="no">
        <cfset  GET_MONEY_FK.RECORDCOUNT=0 /><!--- fonskiyon 2.3. olarak çağrılıyor olabilir o yüzden 0 set ettik --->
        <cfif arguments.action_type eq 1>
            <cfquery name="GET_MONEY_FK" datasource="#arguments.dsn_period_money#">
                SELECT (RATE2/RATE1) RATE,MONEY_TYPE FROM INVOICE_MONEY WHERE ACTION_ID = <cfqueryparam value="#arguments.action_id#" cfsqltype="cf_sql_integer">
            </cfquery>
        <cfelseif arguments.action_type eq 8>
            <cfquery name="GET_MONEY_FK" datasource="#arguments.dsn_period_money#">
                SELECT (RATE2/RATE1) RATE,MONEY_TYPE FROM INVOICE_MONEY WHERE ACTION_ID = <cfqueryparam value="#arguments.action_id#" cfsqltype="cf_sql_integer">
            </cfquery>
        <cfelseif arguments.action_type eq 2>
            
            <cfstoredproc procedure="GET_SHIP_TYPE" datasource="#arguments.dsn_period_money#">
                <cfprocparam cfsqltype="cf_sql_integer" value="#arguments.action_id#">
                <cfprocresult name="GET_SHIP_TYPE">
            </cfstoredproc>
            
            <cfquery name="GET_MONEY_FK" datasource="#arguments.dsn_period_money#">
                SELECT (RATE2/RATE1) RATE, MONEY_TYPE FROM SHIP_MONEY WHERE	ACTION_ID = <cfqueryparam value="#arguments.action_id#" cfsqltype="cf_sql_integer">
            </cfquery>	
            <cfif not(isdefined("GET_MONEY_FK") and GET_MONEY_FK.recordcount)>
                <cfquery name="GET_MONEY_FK" datasource="#arguments.dsn_period_money#">
                    SELECT (RATE2/RATE1) RATE, MONEY_TYPE FROM SHIP_MONEY WHERE	ACTION_ID = <cfqueryparam value="#arguments.action_id#" cfsqltype="cf_sql_integer">
                </cfquery>
            </cfif>
        <cfelseif arguments.action_type eq 3>
            <cfquery name="GET_MONEY_FK" datasource="#arguments.dsn_period_money#">
                SELECT (RATE2/RATE1) RATE, MONEY_TYPE FROM STOCK_FIS_MONEY WHERE ACTION_ID = <cfqueryparam value="#arguments.action_id#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>
        <cfset  cost_money_rate_='' />
        <cfif isdefined('GET_MONEY_FK') and GET_MONEY_FK.RECORDCOUNT and arguments.action_type neq 4>
            <cfoutput query="GET_MONEY_FK">
                <cfset  cost_money_rate_='#cost_money_rate_##RATE#;#MONEY_TYPE#;' />
            </cfoutput>
        <cfelse>
            <cfquery name="GET_MONEY_FK" datasource="#arguments.dsn_period_money#">
                SELECT (RATE2/RATE1) RATE, MONEY MONEY_TYPE,PERIOD_ID FROM SETUP_MONEY
            </cfquery>
            <cfoutput query="GET_MONEY_FK">
                <cfstoredproc procedure="GET_MONEY_HISTORY" datasource="#dsn_money#">
                    <cfprocparam cfsqltype="cf_sql_timestamp" value="#CREATEODBCDATETIME(arguments.action_date)#">
                    <cfprocparam cfsqltype="cf_sql_varchar" value="#MONEY_TYPE#">
                    <cfprocparam cfsqltype="cf_sql_varchar" value="#PERIOD_ID#">
                    <cfprocresult name="GET_MONEY_HISTORY">
                </cfstoredproc>
                <cfif GET_MONEY_HISTORY.RECORDCOUNT>
                    <cfset  cost_money_rate_='#cost_money_rate_##GET_MONEY_HISTORY.RATE#;#GET_MONEY_HISTORY.MONEY_TYPE#;' />
                <cfelse>
                    <cfset  cost_money_rate_='#cost_money_rate_##RATE#;#MONEY_TYPE#;' />
                </cfif>
            </cfoutput>
        </cfif>
        <cfreturn cost_money_rate_>
    </cffunction>

	<cffunction name="duedate_action" output="false" returntype="numeric">
	<!--- finansal yas hesaplar--->
        <cfargument name="duedate" type="date" required="yes"><!--- stokdaki ürünlerin vade tarihi (maliyet tablosundaki due_date)--->
        <cfargument name="stock_amount" type="numeric" required="yes"><!--- stok miktarı--->
        <cfargument name="stock_value" type="numeric" required="yes"><!--- birim stok tutarı--->
        <cfargument name="action_date" type="date" required="yes"><!--- belge işlem tarihi ınvoice_date--->
        <cfargument name="action_duedate" type="numeric" required="yes"><!--- belgedeki vade gün sayısı --->
        <cfargument name="action_amount" type="numeric" required="yes"><!--- belge miktarı --->
        <cfargument name="action_value" type="numeric" required="yes"><!--- belgedeki birim ürün tutarı --->
            <cfif arguments.stock_amount lt 0><cfset arguments.stock_amount=0 /></cfif>
            <cfif arguments.action_duedate gt 0>
                <cfset action_due_date_ = dateformat(date_add('d',arguments.action_duedate,dateformat(arguments.action_date,'dd/mm/yyyy')),'dd/mm/yyyy') />
            <cfelse>
                <cfset action_due_date_ = arguments.action_date />
            </cfif>
            <cfset duedate_day = datediff('d',dateformat(action_due_date_,'dd/mm/yyyy'),dateformat(arguments.duedate,'dd/mm/yyyy')) />
            <cfset due_day_arg=arguments.stock_amount*arguments.stock_value+arguments.action_amount*arguments.action_value />
            <cfif due_day_arg gt 0>
                <cfset duedate_value = INT((arguments.stock_amount*arguments.stock_value*duedate_day)/due_day_arg) />
            <cfelse>
                <cfset duedate_value = 0 />
            </cfif>
            <cfset duedate_value = date_add('d',duedate_value,dateformat(action_due_date_,'dd/mm/yyyy')) />
        <cfreturn duedate_value>
    </cffunction>

	<cffunction name="physical_action" output="false" returntype="numeric">
	<!--- fiziksel yas hesaplar--->
        <cfargument name="physicaldate" type="date" required="yes"><!--- stokdaki ürünlerin fiziksel yaşı--->
        <cfargument name="stock_amount" type="numeric" required="yes"><!--- stok miktarı--->
        <cfargument name="action_date" type="date" required="yes"><!--- ürünün stoğa giriş tarihi--->
        <cfargument name="action_amount" type="numeric" required="yes"><!--- belge miktarı --->
            <cfif arguments.stock_amount lt 0><cfset arguments.stock_amount=0 /></cfif>
            <cfset physical_day = datediff('d',dateformat(arguments.physicaldate,'dd/mm/yyyy'),dateformat(arguments.action_date,'dd/mm/yyyy')) />
            <cfset physical_value_arg = arguments.stock_amount+arguments.action_amount />
            <cfif physical_value_arg gt 0>
                <cfset physical_value = INT((arguments.stock_amount*physical_day)/physical_value_arg) />
            <cfelse>
                <cfset physical_value_arg = 0 />
            </cfif>
            <cfset physical_value = date_add('d',-1*physical_value,dateformat(arguments.action_date,'dd/mm/yyyy')) />
        <cfreturn physical_value>
    </cffunction>

	<cffunction name="del_cost" output="false">
	<!--- maliyet idsi yollanır ve maliyet silinir--->
        <cfargument name="del_product_cost_id" type="numeric" required="no" default="0">
        <cfargument name="del_dsn1" type="string" required="yes">
        <cfargument name="del_period_dsn" type="string" required="yes">
        <cfargument name="del_ship_id_list" type="string" required="no" default="0">
        <cfargument name="del_cost_period_id" type="string" required="no" default="0">
        <cfargument name="paper_product_id_" type="string" required="no" default="0">
        
        <cfif arguments.del_product_cost_id gt 0>
            <!---Stored Procedure Çevirdim 6 aya silinsin E.A 20130125 ---->
            <!---<cfquery name="DEL_PROD_COST" datasource="#arguments.del_dsn1#">
                DELETE FROM PRODUCT_COST WHERE PRODUCT_COST_ID = <cfqueryparam value="#arguments.del_product_cost_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            
            <cfquery name="DEL_PROD_COST_REF" datasource="#arguments.del_period_dsn#">
                DELETE FROM PRODUCT_COST_REFERENCE WHERE PRODUCT_COST_ID = <cfqueryparam value="c" cfsqltype="cf_sql_integer">
            </cfquery>--->
            <cfstoredproc procedure="DEL_COST_PRODUCT" datasource="#arguments.del_period_dsn#">
                <cfprocparam cfsqltype="cf_sql_integer" value="#arguments.del_product_cost_id#">
            </cfstoredproc>
            
        <cfelseif arguments.del_ship_id_list gt 0>
            <!---E.A storedprocedure çevrildi 6 aya silinsin! 20130125 --->
            <!---<cfquery name="DEL_PROD_COST" datasource="#arguments.del_dsn1#">
                DELETE FROM PRODUCT_COST WHERE ACTION_ID IN (#arguments.del_ship_id_list#) AND ACTION_TYPE = 2 AND ACTION_PERIOD_ID = <cfqueryparam value="#del_cost_period_id#" cfsqltype="cf_sql_integer">
                <cfif len(arguments.paper_product_id_) and arguments.paper_product_id_ neq 0>
                    AND PRODUCT_ID = #arguments.paper_product_id_#
                </cfif>
            </cfquery>
            
            <cfquery name="DEL_PROD_COST_REF" datasource="#arguments.del_period_dsn#">
                DELETE FROM PRODUCT_COST_REFERENCE WHERE ACTION_ID IN (#arguments.del_ship_id_list#) AND ACTION_TYPE = 2
            </cfquery>--->
            <cfstoredproc procedure="DEL_COST_SHIP" datasource="#arguments.del_period_dsn#">
                <cfprocparam cfsqltype="cf_sql_varchar" value="#arguments.del_ship_id_list#">
                <cfprocparam cfsqltype="cf_sql_integer" value="#del_cost_period_id#">
                <cfif len(arguments.paper_product_id_) and arguments.paper_product_id_ neq 0>
                    <cfprocparam cfsqltype="cf_sql_integer" value="#arguments.paper_product_id_#">
                <cfelse>
                    <cfprocparam cfsqltype="cf_sql_integer" value="0">
                </cfif>
            </cfstoredproc>
        </cfif>
    </cffunction>

    <cffunction name="upd_newer_cost" output="true">
    <!--- eklenen veya silinen maliyetlerden sonra tarihli m aliyetler guncelleniyor --->
        <cfargument name="newer_action_id" type="numeric" required="yes">
        <cfargument name="newer_action_row_id" type="numeric" required="yes">
        <cfargument name="newer_product_cost_id" type="numeric" required="no">
        <cfargument name="newer_spec_main_id" type="string">
        <cfargument name="newer_product_id" type="numeric" required="yes">
        <cfargument name="newer_stock_id" type="string" required="no">
        <cfargument name="newer_action_date" type="string" required="yes">
        <cfargument name="newer_record_date" type="string" required="yes">
        <cfargument name="newer_comp_period_list" type="string" required="yes">
        <cfargument name="newer_comp_period_year_list" type="string" required="yes">
        <cfargument name="newer_dsn" type="string" required="yes">
        <cfargument name="newer_dsn3" type="string" required="yes">
        <cfargument name="newer_period_dsn_type" type="string" required="yes">
        <cfargument name="newer_our_company_id" type="numeric" required="yes">
        <cfargument name="newer_action_process_type" type="numeric" default="0" required="no">
        <cfargument name="newer_action_finish_date" type="string" default="" required="no">
        <cfif not isdefined('comp_cost_calc_type')>
            <cfif len(arguments.newer_our_company_id)>
                <cfquery name="GET_COST_CALC_TYPE" datasource="#dsn#">
                    SELECT COST_CALC_TYPE FROM OUR_COMPANY_INFO WHERE COMP_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.newer_our_company_id#">
                </cfquery>
                <cfif GET_COST_CALC_TYPE.RECORDCOUNT and len(GET_COST_CALC_TYPE.COST_CALC_TYPE)>
                    <cfset comp_cost_calc_type=GET_COST_CALC_TYPE.COST_CALC_TYPE />
                <cfelse>
                    <cfset comp_cost_calc_type =1 />
                </cfif>
            <cfelse>
                <cfset comp_cost_calc_type =1 />
            </cfif>
        </cfif>
        <cfquery name="GET_NEWER_P_COSTS" datasource="#arguments.newer_dsn3#">
            <!--- --eklenen yada silinen maliyetten sonra ki maliyetleri çekiyoruz... --->
            SELECT
                PRODUCT_COST_ID,
                INVENTORY_CALC_TYPE,
                PRODUCT_ID,
                START_DATE,
                SPECT_MAIN_ID,	
                <cfif isdefined("arguments.newer_stock_id") and len(arguments.newer_stock_id)>	
                    STOCK_ID,
                <cfelse>
                    '' STOCK_ID,
                </cfif>	
                ISNULL(PURCHASE_NET,0) PURCHASE_NET,
                ISNULL(PURCHASE_EXTRA_COST,0) PURCHASE_EXTRA_COST,
                ISNULL(PURCHASE_NET_MONEY,0) PURCHASE_NET_MONEY,
                ISNULL(PURCHASE_NET_SYSTEM_MONEY,0) PURCHASE_NET_SYSTEM_MONEY,
                ISNULL(PURCHASE_NET_SYSTEM_MONEY_2,0) PURCHASE_NET_SYSTEM_MONEY_2,
                MONEY,
                PRICE_PROTECTION_MONEY,
                PRICE_PROTECTION,
                PRICE_PROTECTION_TYPE,
                STANDARD_COST,
                STANDARD_COST_RATE,
                STANDARD_COST_MONEY,
                ISNULL(MONEY_LOCATION,0) MONEY_LOCATION,
                ISNULL(PRICE_PROTECTION_MONEY_LOCATION,0) PRICE_PROTECTION_MONEY_LOCATION,
                ISNULL(PRICE_PROTECTION_LOCATION,0) PRICE_PROTECTION_LOCATION,
                ISNULL(STANDARD_COST_LOCATION,0) STANDARD_COST_LOCATION,
                ISNULL(STANDARD_COST_RATE_LOCATION,0) STANDARD_COST_RATE_LOCATION,
                ISNULL(STANDARD_COST_MONEY_LOCATION,0) STANDARD_COST_MONEY_LOCATION,
                 ISNULL(MONEY_DEPARTMENT,0) MONEY_DEPARTMENT,
                ISNULL(PRICE_PROTECTION_MONEY_DEPARTMENT,0) PRICE_PROTECTION_MONEY_DEPARTMENT,
                ISNULL(PRICE_PROTECTION_DEPARTMENT,0) PRICE_PROTECTION_DEPARTMENT,
                ISNULL(STANDARD_COST_DEPARTMENT,0) STANDARD_COST_DEPARTMENT,
                ISNULL(STANDARD_COST_RATE_DEPARTMENT,0) STANDARD_COST_RATE_DEPARTMENT,
                ISNULL(STANDARD_COST_MONEY_DEPARTMENT,0) STANDARD_COST_MONEY_DEPARTMENT,
                ISNULL(ACTION_ID,0) ACTION_ID,
                ISNULL(ACTION_TYPE,0) ACTION_TYPE,
                ISNULL(ACTION_ROW_ID,0) ACTION_ROW_ID,
                ACTION_PERIOD_ID,
                DUE_DATE,
                PHYSICAL_DATE,
                ISNULL(DUE_DATE_LOCATION,0) DUE_DATE_LOCATION,
                ISNULL(PHYSICAL_DATE_LOCATION,0) PHYSICAL_DATE_LOCATION,
                ISNULL(DUE_DATE_DEPARTMENT,0) DUE_DATE_DEPARTMENT,
                ISNULL(PHYSICAL_DATE_DEPARTMENT,0) PHYSICAL_DATE_DEPARTMENT,
                RECORD_DATE,
                ACTION_AMOUNT,
                ACTION_DATE,
                ACTION_DUE_DATE,
                DEPARTMENT_ID,
                LOCATION_ID,
                ISNULL(PURCHASE_NET_SYSTEM_MONEY_2_LOCATION,0) PURCHASE_NET_SYSTEM_MONEY_2_LOCATION,
                 ISNULL(PURCHASE_NET_SYSTEM_MONEY_2_DEPARTMENT,0) PURCHASE_NET_SYSTEM_MONEY_2_DEPARTMENT,
                ACTION_PROCESS_CAT_ID,
                ACTION_PROCESS_TYPE
            FROM
                PRODUCT_COST 
            WHERE
                PRODUCT_ID = #arguments.newer_product_id# <!--- <cfqueryparam value="#arguments.newer_product_id#" cfsqltype="cf_sql_integer"> --->
                <cfif len(arguments.newer_spec_main_id)>
                    AND SPECT_MAIN_ID = #arguments.newer_spec_main_id# <!--- <cfqueryparam value="#arguments.newer_spec_main_id#" cfsqltype="cf_sql_integer"> --->
                <cfelse>
                    AND ISNULL(IS_SPEC,0)=0
                </cfif>
                <cfif isdefined("arguments.newer_stock_id") and len(arguments.newer_stock_id)>
                    AND STOCK_ID = #arguments.newer_stock_id# <!--- <cfqueryparam value="#arguments.newer_spec_main_id#" cfsqltype="cf_sql_integer"> --->
                <cfelse>
                    AND STOCK_ID IS NULL
                </cfif>
                <cfif isdefined('arguments.newer_action_row_id') and arguments.newer_action_row_id gt 0>
                    AND ISNULL(ACTION_ROW_ID,0) <> #arguments.newer_action_row_id# <!--- <cfqueryparam value="#arguments.newer_action_row_id#" cfsqltype="cf_sql_integer"> --->
                <cfelseif isdefined('arguments.newer_product_cost_id') and arguments.newer_product_cost_id gt 0>
                    AND PRODUCT_COST_ID <> #arguments.newer_product_cost_id# <!--- <cfqueryparam value="#arguments.newer_product_cost_id#" cfsqltype="cf_sql_integer"> --->
                <cfelse>
                    AND ISNULL(ACTION_ID,0) <> #arguments.newer_action_id# <!--- <cfqueryparam value="#arguments.newer_action_id#" cfsqltype="cf_sql_integer"> --->
                </cfif>
                <cfif arguments.newer_action_process_type neq 0>
                    AND ACTION_PROCESS_TYPE = #arguments.newer_action_process_type#
                </cfif>
                AND ISNULL(ACTION_TYPE,0) <> -1 <!--- Excelden oluştulan maliyetler güncellenmesin! --->
                <cfif newer_action_process_type neq 0>
                     AND (
                          (  START_DATE >= #dateadd('d',1,CreateODBCDate(arguments.newer_action_date))# AND 
                            START_DATE < #dateadd('d',1,arguments.newer_action_finish_date)#
                            )
                        OR
                            (
                               ( START_DATE > #dateadd('d',-1,CreateODBCDate(arguments.newer_action_date))# AND
                                START_DATE < #dateadd('d',1,CreateODBCDate(arguments.newer_action_date))# 
                               )
                                 AND
                                RECORD_DATE > #CreateODBCDateTime(arguments.newer_record_date)#
                                <cfif arguments.newer_action_id gt 0>AND ACTION_ID <> #arguments.newer_action_id# </cfif>
                                <cfif isdefined('arguments.newer_product_cost_id') and arguments.newer_product_cost_id gt 0>AND PRODUCT_COST_ID <> #arguments.newer_product_cost_id#</cfif>
                            )
                        )
                <cfelse>
                    AND (
                            START_DATE > #CreateODBCDate(arguments.newer_action_date)# <!--- <cfqueryparam value="#CreateODBCDate(arguments.newer_action_date)#" cfsqltype="cf_sql_date"> --->
                        OR
                            (START_DATE = #CreateODBCDate(arguments.newer_action_date)# AND<!--- <cfqueryparam value="#CreateODBCDate(arguments.newer_action_date)#" cfsqltype="cf_sql_date"> ---> 
                            RECORD_DATE > #CreateODBCDateTime(arguments.newer_record_date)#
                            <!--- RECORD_DATE >#CreateODBCDate(arguments.newer_record_date)# --->
                            <cfif arguments.newer_action_id gt 0>AND ACTION_ID <> #arguments.newer_action_id# <!--- <cfqueryparam value="#arguments.newer_action_id#" cfsqltype="cf_sql_integer"> ---></cfif>
                            <cfif isdefined('arguments.newer_product_cost_id') and arguments.newer_product_cost_id gt 0>AND PRODUCT_COST_ID <> #arguments.newer_product_cost_id#<!--- <cfqueryparam value="#arguments.newer_product_cost_id#" cfsqltype="cf_sql_integer"> ---></cfif>
                            )
                        )
                </cfif>
                AND ACTION_PERIOD_ID IN (#arguments.newer_comp_period_list#)
            ORDER BY 
                START_DATE,RECORD_DATE,PRODUCT_COST_ID
        </cfquery>
	
        <cfif GET_NEWER_P_COSTS.RECORDCOUNT>
            <cfloop query="GET_NEWER_P_COSTS">
                <cfif len(GET_NEWER_P_COSTS.ACTION_PROCESS_CAT_ID)>
                    <cfquery name="GET_PROCESS_NEWER_COST" datasource="#DSN3#"><!--- Kategoriye göre maliyetin oluşturma özellikleri çekiliyor. --->
                        SELECT 
                            PROCESS_TYPE,
                            IS_COST,
                            IS_COST_ZERO_ROW,
                            IS_COST_FIELD
                        FROM
                            SETUP_PROCESS_CAT 
                        WHERE 
                            PROCESS_CAT_ID = <cfqueryparam value="#GET_NEWER_P_COSTS.ACTION_PROCESS_CAT_ID#" cfsqltype="cf_sql_integer">
                    </cfquery>
                <cfelse>
                    <cfset GET_PROCESS_NEWER_COST.RECORDCOUNT=0 />
                </cfif>
                <cfif GET_PROCESS_NEWER_COST.RECORDCOUNT>
                    <cfset is_cost_field_newer = GET_PROCESS_NEWER_COST.IS_COST_FIELD />
                    <cfset is_cost_zero_row_newer = GET_PROCESS_NEWER_COST.IS_COST_ZERO_ROW />
                <cfelse>
                    <cfset is_cost_field_newer = 0 />
                    <cfset is_cost_zero_row_newer = 1 />
                </cfif>
                <cfset "cost_date_#PRODUCT_COST_ID#" = dateformat(GET_NEWER_P_COSTS.START_DATE,'dd/mm/yyyy') />
                <cf_date tarih = 'cost_date_#PRODUCT_COST_ID#'>	
                <cfscript>
                    if(len(GET_NEWER_P_COSTS.ACTION_PERIOD_ID))
                    {
                        period_year_=listgetat(arguments.newer_comp_period_year_list,listfind(arguments.newer_comp_period_list,GET_NEWER_P_COSTS.ACTION_PERIOD_ID,','));
                        newer_period_dsn='#arguments.newer_dsn#_#period_year_#_#arguments.newer_our_company_id#';
                    }else{
                        newer_period_dsn=arguments.newer_period_dsn_type;
                    }
                    if(len(GET_NEWER_P_COSTS.SPECT_MAIN_ID))
                        {
                            "maliyet_#PRODUCT_COST_ID#" = get_product_stock_cost(
                                                                is_product_stock:1,
                                                                product_stock_id:GET_NEWER_P_COSTS.PRODUCT_ID,
                                                                tax_inc:0,
                                                                cost_method:GET_NEWER_P_COSTS.INVENTORY_CALC_TYPE,
                                                                cost_date:evaluate('cost_date_#PRODUCT_COST_ID#'),
                                                                cost_money:GET_NEWER_P_COSTS.MONEY,
                                                                action_id=GET_NEWER_P_COSTS.ACTION_ID,
                                                                action_row_id=GET_NEWER_P_COSTS.ACTION_ROW_ID,
                                                                action_type=GET_NEWER_P_COSTS.ACTION_TYPE,
                                                                spec_main_id=GET_NEWER_P_COSTS.SPECT_MAIN_ID,
                                                                stock_id=GET_NEWER_P_COSTS.STOCK_ID,
                                                                period_dsn_type=newer_period_dsn,
                                                                action_comp_period_list='#comp_period_list#',
                                                                action_cost_id=GET_NEWER_P_COSTS.PRODUCT_COST_ID,
                                                                cost_money_system : GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY,
                                                                cost_money_system_2 : GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY_2,
                                                                is_cost_zero_row :  is_cost_zero_row_newer,
                                                                is_cost_field : is_cost_field_newer,
                                                                is_cost_calc_type : comp_cost_calc_type
                                                        );
                        }else{
                            "maliyet_#PRODUCT_COST_ID#" = get_product_stock_cost(
                                                                is_product_stock : 1,
                                                                product_stock_id : GET_NEWER_P_COSTS.PRODUCT_ID,
                                                                tax_inc : 0,
                                                                cost_method : GET_NEWER_P_COSTS.INVENTORY_CALC_TYPE,
                                                                cost_date : evaluate('cost_date_#PRODUCT_COST_ID#'),
                                                                cost_money : GET_NEWER_P_COSTS.MONEY,
                                                                action_id : GET_NEWER_P_COSTS.ACTION_ID,
                                                                stock_id=GET_NEWER_P_COSTS.STOCK_ID,
                                                                action_row_id : GET_NEWER_P_COSTS.ACTION_ROW_ID,
                                                                action_type : GET_NEWER_P_COSTS.ACTION_TYPE,
                                                                period_dsn_type : newer_period_dsn,
                                                                action_comp_period_list : '#comp_period_list#',
                                                                action_cost_id : GET_NEWER_P_COSTS.PRODUCT_COST_ID,
                                                                cost_money_system : GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY,
                                                                cost_money_system_2 : GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY_2,
                                                                is_cost_zero_row :  is_cost_zero_row_newer,
                                                                is_cost_field : is_cost_field_newer,
                                                                is_cost_calc_type : comp_cost_calc_type
                                                                );
                        }
                        "alis_net_fiyat_#PRODUCT_COST_ID#" = "#listfirst(evaluate('maliyet_#PRODUCT_COST_ID#'),';')#";
                        "alis_ek_maliyet_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),2,';')#";
                        "alis_net_fiyat_system_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),4,';')#";
                        "alis_ek_maliyet_system_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),5,';')#";
                        "alis_net_fiyat_system_2_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),6,';')#";
                        "alis_ek_maliyet_system_2_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),7,';')#";
                        "mevcut_son_alislar_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),3,';')#";
                        
                        "mevcut_son_alislar_lokasyon_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),8,';')#";
                        "alis_net_fiyat_lokasyon_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),9,';')#";
                        "alis_ek_maliyet_lokasyon_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),10,';')#";
                        "alis_net_fiyat_system_lokasyon_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),11,';')#";
                        "alis_ek_maliyet_system_lokasyon_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),12,';')#";
                        "alis_net_fiyat_system_2_lokasyon_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),13,';')#";
                        "alis_ek_maliyet_system_2_lokasyon_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),14,';')#";
                        
                        if(listlen(evaluate('maliyet_#PRODUCT_COST_ID#'),';') gt 14) "satir_fiyat_tutar_#PRODUCT_COST_ID#"="#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),15,';')#";

                        //depo
                        "mevcut_son_alislar_department_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),17,';')#";
                        "alis_net_fiyat_department_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),18,';')#";
                        "alis_ek_maliyet_department_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),19,';')#";
                        "alis_net_fiyat_system_department_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),20,';')#";
                        "alis_ek_maliyet_system_department_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),21,';')#";
                        "alis_net_fiyat_system_2_department_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),22,';')#";
                        "alis_ek_maliyet_system_2_department_#PRODUCT_COST_ID#" = "#listgetat(evaluate('maliyet_#PRODUCT_COST_ID#'),23,';')#";
                        
                        if(not len(GET_NEWER_P_COSTS.STANDARD_COST))GET_NEWER_P_COSTS.STANDARD_COST=0;
                        if(not len(GET_NEWER_P_COSTS.PRICE_PROTECTION))GET_NEWER_P_COSTS.PRICE_PROTECTION=0;
                        if(not len(GET_NEWER_P_COSTS.STANDARD_COST_RATE))GET_NEWER_P_COSTS.STANDARD_COST_RATE=0;
                        if(not len(GET_NEWER_P_COSTS.PRICE_PROTECTION_TYPE))GET_NEWER_P_COSTS.PRICE_PROTECTION_TYPE=1;//tip gelmiyorsa malyiet düşürmek içindir düzenleme tutarı
                        ////writeoutput('Ürünün Maliyeti Oluşturuluyor..#evaluate("alis_net_fiyat_system_#PRODUCT_COST_ID#")# <br/>');
                </cfscript>
                <!--- burda işlem kategoresine göre 0 sa maliyet kaydedecekmi etmeyecekmi belirlenmelii --->
                <cfif evaluate('maliyet_#PRODUCT_COST_ID#') neq 'YOK'><!--- and listfirst(evaluate('maliyet_#PRODUCT_COST_ID#'),';') gt 0 --->
                    <!--- stok miktarlarida guncellenmeli --->
                    <cfquery name="GET_SEVK" datasource="#newer_period_dsn#">
                        SELECT 
                            SUM(STOCK_OUT-STOCK_IN) AS MIKTAR 
                        FROM 
                            STOCKS_ROW 
                        WHERE
                            PRODUCT_ID = #arguments.newer_product_id# AND
                            <cfif isdefined('arguments.newer_spec_main_id') and len(arguments.newer_spec_main_id)>
                                SPECT_VAR_ID=#arguments.newer_spec_main_id# AND
                            <cfelse>
                                (SPECT_VAR_ID IS NULL OR SPECT_VAR_ID = 0) AND
                            </cfif>
                            PROCESS_TYPE = 81 AND
                            PROCESS_DATE <= #evaluate('cost_date_#PRODUCT_COST_ID#')#
                            <cfif GET_NOT_DEP_COST.RECORDCOUNT>
                            AND
                                ( 
                                <cfset rw_count=0 />
                                <cfloop query="GET_NOT_DEP_COST">
                                    <cfset rw_count=rw_count+1 />
                                    NOT (STORE_LOCATION = <cfqueryparam value="#GET_NOT_DEP_COST.LOCATION_ID#" cfsqltype="cf_sql_integer"> AND STORE = <cfqueryparam value="#GET_NOT_DEP_COST.DEPARTMENT_ID#" cfsqltype="cf_sql_integer">)
                                    <cfif rw_count lt GET_NOT_DEP_COST.RECORDCOUNT>AND</cfif>
                                </cfloop>
                                )
                            </cfif>
                    </cfquery>
                    <cfif GET_SEVK.RECORDCOUNT and len(GET_SEVK.MIKTAR)>
                        <cfset yoldaki_stoklar = GET_SEVK.MIKTAR />
                    <cfelse>
                        <cfset yoldaki_stoklar = '' />
                    </cfif>
                    <!--- fiyat koruma degerleri ve sabit maliyet girilmiş ise degerleri kaybetmemesi için çünkü yeni hesaplanan degerlere göre --->
                    <cfscript>
                        upd_func_rate_list=get_cost_rate(action_id:GET_NEWER_P_COSTS.ACTION_ID,session_period_id:GET_NEWER_P_COSTS.ACTION_PERIOD_ID,action_type:GET_NEWER_P_COSTS.ACTION_TYPE,action_date:createodbcdate(GET_NEWER_P_COSTS.START_DATE) ,dsn_period_money:newer_period_dsn ,dsn_money:#arguments.newer_dsn#);
                        if(GET_NEWER_P_COSTS.PRICE_PROTECTION gt 0 and listfind(upd_func_rate_list,GET_NEWER_P_COSTS.PRICE_PROTECTION_MONEY,';'))	
                        {
                            prc_protec_sys = (GET_NEWER_P_COSTS.PRICE_PROTECTION*listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.PRICE_PROTECTION_MONEY,';')-1,';'))*GET_NEWER_P_COSTS.PRICE_PROTECTION_TYPE;
                            prc_protec = prc_protec_sys/listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.MONEY,';')-1,';');
                            prc_protec_sys_2 = prc_protec_sys/listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY_2,';')-1,';');
                        }else
                        {
                            prc_protec_sys = 0;
                            prc_protec = 0;
                            prc_protec_sys_2 = 0;
                        }
                        if(GET_NEWER_P_COSTS.STANDARD_COST gt 0 and listfind(upd_func_rate_list,GET_NEWER_P_COSTS.STANDARD_COST_MONEY,';'))	
                        {
                            std_cost_sys=GET_NEWER_P_COSTS.STANDARD_COST*listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.STANDARD_COST_MONEY,';')-1,';');
                            std_cost=std_cost_sys/listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.MONEY,';')-1,';');
                            std_cost_sys_2=std_cost_sys/listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY_2,';')-1,';');
                        }else
                        {
                            std_cost_sys = 0;
                            std_cost = 0;
                            std_cost_sys_2 = 0;
                        }
                        
                        //lokasyon
                        if(GET_NEWER_P_COSTS.PRICE_PROTECTION_LOCATION gt 0 and listfind(upd_func_rate_list,GET_NEWER_P_COSTS.PRICE_PROTECTION_MONEY_LOCATION,';'))	
                        {
                            prc_protec_sys_loc = (GET_NEWER_P_COSTS.PRICE_PROTECTION_LOCATION*listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.PRICE_PROTECTION_MONEY_LOCATION,';')-1,';'))*GET_NEWER_P_COSTS.PRICE_PROTECTION_TYPE;
                            prc_protec_loc = prc_protec_sys_loc/listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.MONEY_LOCATION,';')-1,';');
                            prc_protec_sys_2 = prc_protec_sys_loc/listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY_2_LOCATION,';')-1,';');
                        }else
                        {
                            prc_protec_sys_loc = 0;
                            prc_protec_loc = 0;
                            prc_protec_sys_2_loc = 0;
                        }
                        if(GET_NEWER_P_COSTS.STANDARD_COST_LOCATION gt 0 and listfind(upd_func_rate_list,GET_NEWER_P_COSTS.STANDARD_COST_MONEY_LOCATION,';'))	
                        {
    
                            std_cost_sys_loc = GET_NEWER_P_COSTS.STANDARD_COST_LOCATION*listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.STANDARD_COST_MONEY_LOCATION,';')-1,';');
                            std_cost_loc = std_cost_sys_loc/listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.MONEY_LOCATION,';')-1,';');
                            std_cost_sys_2_loc = std_cost_sys_loc/listgetat(upd_func_rate_list,listfind(upd_func_rate_list,GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY_2_LOCATION,';')-1,';');
                        }else
                        {
                            std_cost_sys_loc = 0;
                            std_cost_loc = 0;
                            std_cost_sys_2_loc = 0;
                        }
                        //writeoutput('Fiyat Koruma ve Sabit Maliyetler Sonrasında ki Ürünün Maliyeti :#evaluate("alis_net_fiyat_system_#PRODUCT_COST_ID#")# <br/>');
                    </cfscript>
                    <cfquery name="GET_COST_FOR_ALL" datasource="#FORM.DSN1#">
                        SELECT 
                            DUE_DATE,
                            DUE_DATE_LOCATION,
                            PURCHASE_NET_SYSTEM+PURCHASE_EXTRA_COST_SYSTEM PROD_COST,
                            PHYSICAL_DATE,
                            PHYSICAL_DATE_LOCATION,
                            START_DATE,
                            RECORD_DATE,
                            DEPARTMENT_ID,
                            LOCATION_ID,
                            PRODUCT_COST_ID
                        FROM
                            PRODUCT_COST
                        WHERE
                            PRODUCT_ID = <cfqueryparam value="#GET_NEWER_P_COSTS.PRODUCT_ID#" cfsqltype="cf_sql_integer">
                            <cfif isdefined('GET_NEWER_P_COSTS.SPEC_MAIN_ID') and len(GET_NEWER_P_COSTS.SPEC_MAIN_ID)>
                                AND SPECT_MAIN_ID = <cfqueryparam value="#GET_NEWER_P_COSTS.SPEC_MAIN_ID#" cfsqltype="cf_sql_integer">
                            <cfelse>
                                AND IS_SPEC=0
                            </cfif>
                            <cfif isdefined('GET_NEWER_P_COSTS.STOCK_ID') and len(GET_NEWER_P_COSTS.STOCK_ID)>
                                AND STOCK_ID = <cfqueryparam value="#GET_NEWER_P_COSTS.STOCK_ID#" cfsqltype="cf_sql_integer">
                            <cfelse>
                                AND STOCK_ID IS NULL
                            </cfif>
                            AND ACTION_PERIOD_ID IN (#arguments.newer_comp_period_list#)	
                            AND 
    
                            (
                            <!--- aynı gune eklenmis bir belge olabilir ancak kayit tarihi farkli olabilir --->
                                (
                                    START_DATE < <cfqueryparam value="#createodbcdatetime(GET_NEWER_P_COSTS.START_DATE)#" cfsqltype="cf_sql_timestamp">
                                )
                                OR
                                (
                                    START_DATE = <cfqueryparam value="#createodbcdatetime(GET_NEWER_P_COSTS.START_DATE)#" cfsqltype="cf_sql_timestamp">
                                    AND RECORD_DATE < <cfqueryparam value="#createodbcdatetime(GET_NEWER_P_COSTS.RECORD_DATE)#" cfsqltype="cf_sql_timestamp">
                                )
                            )
                    </cfquery>
                    <cfif GET_NEWER_P_COSTS.ACTION_ID gt 0> <!--- elle eklenen maliyetlerde finansal ve fiziksel yaşı taşımalı--->
                        <cfif len(GET_NEWER_P_COSTS.DUE_DATE)><!--- finansal yaş sadece alım faturalarında ve açılış stok fişlerinde çalışacak burdada işlem tipini bilmediğimdan güncellenen maliyetde due_date varsa zaten bunlardan biridir--->
                            <cfquery name="GET_COST_FOR_DUE" dbtype="query">
                                SELECT 
                                    DUE_DATE COST_DUE_DATE,
                                    PROD_COST
                                FROM
                                    GET_COST_FOR_ALL
                                WHERE
                                    DUE_DATE IS NOT NULL
                                ORDER BY
                                    START_DATE DESC,
                                    RECORD_DATE DESC,
                                    PRODUCT_COST_ID DESC
                            </cfquery>
                            <cfquery name="GET_COST_FOR_DUE_LOCATION" dbtype="query">
                                SELECT 
                                    DUE_DATE_LOCATION COST_DUE_DATE,
                                    PROD_COST
                                FROM
                                    GET_COST_FOR_ALL
                                WHERE
                                    DEPARTMENT_ID <cfif len(GET_NEWER_P_COSTS.DEPARTMENT_ID)>= #GET_NEWER_P_COSTS.DEPARTMENT_ID#<cfelse>IS NULL</cfif> AND
                                    LOCATION_ID <cfif len(GET_NEWER_P_COSTS.LOCATION_ID)>= #GET_NEWER_P_COSTS.LOCATION_ID#<cfelse>IS NULL</cfif> AND
                                    DUE_DATE IS NOT NULL
                                ORDER BY
                                    START_DATE DESC,
                                    RECORD_DATE DESC,
                                    PRODUCT_COST_ID DESC
                            </cfquery>
                        <cfelse>
                            <cfset GET_COST_FOR_DUE.RECORDCOUNT=0 />
                            <cfset GET_COST_FOR_DUE_LOCATION.RECORDCOUNT=0 />
                        </cfif>
                        
                        <cfquery name="GET_COST_FOR_PHYSICAL" dbtype="query">
                            SELECT 
                                PHYSICAL_DATE COST_PHYSICAL_DATE,
                                PROD_COST
                            FROM
                                GET_COST_FOR_ALL
                            WHERE
                                PHYSICAL_DATE IS NOT NULL
                            ORDER BY
                                START_DATE DESC,
                                RECORD_DATE DESC,
                                PRODUCT_COST_ID DESC
                        </cfquery>
                        <cfquery name="GET_COST_FOR_PHYSICAL_LOCATION" dbtype="query">
                            SELECT 
                                PHYSICAL_DATE_LOCATION COST_PHYSICAL_DATE,
                                PROD_COST
                            FROM
                                GET_COST_FOR_ALL
                            WHERE
                                DEPARTMENT_ID <cfif len(GET_NEWER_P_COSTS.DEPARTMENT_ID)>= #GET_NEWER_P_COSTS.DEPARTMENT_ID#<cfelse>IS NULL</cfif> AND
                                LOCATION_ID <cfif len(GET_NEWER_P_COSTS.LOCATION_ID)>= #GET_NEWER_P_COSTS.LOCATION_ID#<cfelse>IS NULL</cfif> AND
                                PHYSICAL_DATE IS NOT NULL
                            ORDER BY
                                START_DATE DESC,
                                RECORD_DATE DESC,
                                PRODUCT_COST_ID DESC
                        </cfquery>
                        <cfscript>
                            if(GET_COST_FOR_DUE.RECORDCOUNT gt 0 and len(GET_NEWER_P_COSTS.DUE_DATE) and isdefined('GET_NEWER_P_COSTS.DUE_DATE') and isdefined('GET_NEWER_P_COSTS.ACTION_DATE'))// sadece bu alanlar geliyorsa girsin değerler fatura tipinde geliyor
                            {
                                if(GET_COST_FOR_DUE.RECORDCOUNT and isdate(GET_COST_FOR_DUE.COST_DUE_DATE))
                                    due=dateformat(GET_COST_FOR_DUE.COST_DUE_DATE,'dd/mm/yyyy');
                                else
                                    due=dateformat(GET_NEWER_P_COSTS.ACTION_DATE,'dd/mm/yyyy');
                                    
                                'due_date_#PRODUCT_COST_ID#'=
                                    duedate_action(
                                        duedate: due,
                                        stock_amount:evaluate('mevcut_son_alislar_#PRODUCT_COST_ID#')-GET_NEWER_P_COSTS.ACTION_AMOUNT,
                                        stock_value:iif(GET_COST_FOR_DUE.RECORDCOUNT,GET_COST_FOR_DUE.PROD_COST,0),
                                        action_date:dateformat(GET_NEWER_P_COSTS.ACTION_DATE,'dd/mm/yyyy'),
                                        action_duedate:GET_NEWER_P_COSTS.ACTION_DUE_DATE,
                                        action_amount:GET_NEWER_P_COSTS.ACTION_AMOUNT,
                                        action_value:evaluate('satir_fiyat_tutar_#PRODUCT_COST_ID#')
                                    );
                                
                                if(GET_COST_FOR_DUE_LOCATION.RECORDCOUNT and isdate(GET_COST_FOR_DUE_LOCATION.COST_DUE_DATE))
                                    due_lokasyon=dateformat(GET_COST_FOR_DUE_LOCATION.COST_DUE_DATE,'dd/mm/yyyy');
                                else
                                    due_lokasyon=dateformat(GET_NEWER_P_COSTS.ACTION_DATE,'dd/mm/yyyy');
                                'due_date_location_#PRODUCT_COST_ID#'=
                                    duedate_action(
                                        duedate: due_lokasyon,
                                        stock_amount:evaluate('mevcut_son_alislar_lokasyon_#PRODUCT_COST_ID#')-GET_NEWER_P_COSTS.ACTION_AMOUNT,
                                        stock_value:iif(GET_COST_FOR_DUE_LOCATION.RECORDCOUNT,GET_COST_FOR_DUE_LOCATION.PROD_COST,0),
                                        action_date:dateformat(GET_NEWER_P_COSTS.ACTION_DATE,'dd/mm/yyyy'),
                                        action_duedate:GET_NEWER_P_COSTS.ACTION_DUE_DATE,
                                        action_amount:GET_NEWER_P_COSTS.ACTION_AMOUNT,
                                        action_value:evaluate('satir_fiyat_tutar_#PRODUCT_COST_ID#')
                                    );
                            }
                            if(GET_COST_FOR_PHYSICAL.RECORDCOUNT gt 0)
                            {
                                if(GET_COST_FOR_PHYSICAL.RECORDCOUNT and isdate(GET_COST_FOR_PHYSICAL.COST_PHYSICAL_DATE))
                                    physical_=dateformat(GET_COST_FOR_PHYSICAL.COST_PHYSICAL_DATE,'dd/mm/yyyy');
                                else
                                    physical_=dateformat(GET_NEWER_P_COSTS.START_DATE,'dd/mm/yyyy');
                                if(not listfind('81,113',GET_NEWER_P_COSTS.ACTION_PROCESS_TYPE))
                                {
                                    'physical_date_#PRODUCT_COST_ID#' =
                                                physical_action(
                                                    physicaldate: physical_,
                                                    stock_amount:evaluate('mevcut_son_alislar_#PRODUCT_COST_ID#')-GET_NEWER_P_COSTS.ACTION_AMOUNT,
                                                    action_date:dateformat(GET_NEWER_P_COSTS.START_DATE,'dd/mm/yyyy'),
                                                    action_amount:GET_NEWER_P_COSTS.ACTION_AMOUNT
                                                );
                                }else{
                                    if(GET_COST_FOR_PHYSICAL.RECORDCOUNT and isdate(GET_COST_FOR_PHYSICAL.COST_PHYSICAL_DATE))
                                        'physical_date_#PRODUCT_COST_ID#'=CreateODBCDateTime(GET_COST_FOR_PHYSICAL.COST_PHYSICAL_DATE);
                                    else
                                        'physical_date_#PRODUCT_COST_ID#'=CreateODBCDateTime(GET_NEWER_P_COSTS.START_DATE);
                                }
                                if(GET_COST_FOR_PHYSICAL_LOCATION.RECORDCOUNT and isdate(GET_COST_FOR_PHYSICAL_LOCATION.COST_PHYSICAL_DATE))
                                    physical_lokasyon=dateformat(GET_COST_FOR_PHYSICAL_LOCATION.COST_PHYSICAL_DATE,'dd/mm/yyyy');
                                else
                                    physical_lokasyon=dateformat(GET_NEWER_P_COSTS.START_DATE,'dd/mm/yyyy');
                                'physical_date_location_#PRODUCT_COST_ID#' =
                                            physical_action(
                                                physicaldate: physical_lokasyon,
                                                stock_amount:evaluate('mevcut_son_alislar_lokasyon_#PRODUCT_COST_ID#')-GET_NEWER_P_COSTS.ACTION_AMOUNT,
                                                action_date:dateformat(GET_NEWER_P_COSTS.START_DATE,'dd/mm/yyyy'),
                                                action_amount:GET_NEWER_P_COSTS.ACTION_AMOUNT
                                            );
                            }
                        </cfscript>
                    <cfelse>
                        <cfset GET_COST_FOR_DUE.RECORDCOUNT=0 />
                        <cfset GET_COST_FOR_DUE_LOCATION.RECORDCOUNT=0 />
                        <cfset GET_COST_FOR_PHYSICAL.RECORDCOUNT=0 />
                        <cfset GET_COST_FOR_PHYSICAL_LOCATION.RECORDCOUNT=0 />
                        <cfif len(GET_NEWER_P_COSTS.DUE_DATE)>
                            <cfset 'due_date_#PRODUCT_COST_ID#'= createodbcdatetime(GET_NEWER_P_COSTS.DUE_DATE) />
                        </cfif>
                        <cfif len(GET_NEWER_P_COSTS.DUE_DATE_LOCATION)>
                            <cfset 'due_date_location_#PRODUCT_COST_ID#'=createodbcdatetime(GET_NEWER_P_COSTS.DUE_DATE_LOCATION) />
                        </cfif>
                        <cfif len(GET_NEWER_P_COSTS.PHYSICAL_DATE)>
                            <cfset 'physical_date_#PRODUCT_COST_ID#'=createodbcdatetime(GET_NEWER_P_COSTS.PHYSICAL_DATE) />
                        </cfif>
                        <cfif len(GET_NEWER_P_COSTS.PHYSICAL_DATE_LOCATION)>
                            <cfset 'physical_date_location_#PRODUCT_COST_ID#' =createodbcdatetime(GET_NEWER_P_COSTS.PHYSICAL_DATE_LOCATION) />
                        </cfif>
                    </cfif>
                    <!--- //fiyat koruma degerleri ve sabit maliyet girilmiş ise degerleri kaybetmemesi için --->
                    <cfif GET_NEWER_P_COSTS.ACTION_TYPE gt 0><!--- elle eklenen maliyetler güncellenmesin... --->
                    <cfquery name="UPD_COST" datasource="#FORM.DSN1#">
                        UPDATE
                            PRODUCT_COST
                        SET
                            <cfif GET_NEWER_P_COSTS.ACTION_TYPE gt 0><!--- elle eklenmisse maliyet miktarı guncellemeyelim --->
                                ACTIVE_STOCK = <cfif len(yoldaki_stoklar)>#yoldaki_stoklar#<cfelse>0</cfif>,
                                AVAILABLE_STOCK = <cfif len(evaluate('mevcut_son_alislar_#PRODUCT_COST_ID#'))>#evaluate('mevcut_son_alislar_#PRODUCT_COST_ID#')#<cfelse>0</cfif>,
                            </cfif>
                            PRODUCT_COST = #(evaluate("alis_net_fiyat_#PRODUCT_COST_ID#")+evaluate("alis_ek_maliyet_#PRODUCT_COST_ID#")+std_cost+((evaluate("alis_net_fiyat_#PRODUCT_COST_ID#")*GET_NEWER_P_COSTS.STANDARD_COST_RATE)/100)-prc_protec)#,
                            PURCHASE_NET = #evaluate("alis_net_fiyat_#PRODUCT_COST_ID#")#,
                            PURCHASE_EXTRA_COST = #evaluate("alis_ek_maliyet_#PRODUCT_COST_ID#")#,
                            PURCHASE_NET_SYSTEM = #(evaluate("alis_net_fiyat_system_#PRODUCT_COST_ID#")-prc_protec_sys)#,
                            PURCHASE_EXTRA_COST_SYSTEM = #evaluate("alis_ek_maliyet_system_#PRODUCT_COST_ID#")+std_cost_sys+((evaluate("alis_net_fiyat_system_#PRODUCT_COST_ID#")*GET_NEWER_P_COSTS.STANDARD_COST_RATE)/100)#,
                            PURCHASE_NET_SYSTEM_2 = #(evaluate("alis_net_fiyat_system_2_#PRODUCT_COST_ID#")-prc_protec_sys_2)#,
                            PURCHASE_EXTRA_COST_SYSTEM_2 = #evaluate("alis_ek_maliyet_system_2_#PRODUCT_COST_ID#")+std_cost_sys_2+((evaluate("alis_net_fiyat_system_2_#PRODUCT_COST_ID#")*GET_NEWER_P_COSTS.STANDARD_COST_RATE)/100)#,
    
                            ACTIVE_STOCK_LOCATION = 0,
                            AVAILABLE_STOCK_LOCATION = <cfif len(evaluate('mevcut_son_alislar_lokasyon_#PRODUCT_COST_ID#'))>#evaluate('mevcut_son_alislar_lokasyon_#PRODUCT_COST_ID#')#<cfelse>0</cfif>,
                            PRODUCT_COST_LOCATION = #(evaluate("alis_net_fiyat_lokasyon_#PRODUCT_COST_ID#")+evaluate("alis_ek_maliyet_lokasyon_#PRODUCT_COST_ID#")+std_cost_loc+((evaluate("alis_net_fiyat_lokasyon_#PRODUCT_COST_ID#")*GET_NEWER_P_COSTS.STANDARD_COST_RATE_LOCATION)/100)-prc_protec_loc)#,
                            PURCHASE_NET_LOCATION = #evaluate("alis_net_fiyat_lokasyon_#PRODUCT_COST_ID#")#,
                            PURCHASE_EXTRA_COST_LOCATION = #evaluate("alis_ek_maliyet_lokasyon_#PRODUCT_COST_ID#")#,
                            PURCHASE_NET_MONEY_LOCATION = '#GET_NEWER_P_COSTS.PURCHASE_NET_MONEY#', 
                            PURCHASE_NET_SYSTEM_LOCATION = #(evaluate("alis_net_fiyat_system_lokasyon_#PRODUCT_COST_ID#")-prc_protec_sys)#,
                            PURCHASE_EXTRA_COST_SYSTEM_LOCATION = #evaluate("alis_ek_maliyet_system_lokasyon_#PRODUCT_COST_ID#")+std_cost_sys+((evaluate("alis_net_fiyat_system_lokasyon_#PRODUCT_COST_ID#")*GET_NEWER_P_COSTS.STANDARD_COST_RATE_LOCATION)/100)#,
                            <!--- PURCHASE_NET_SYSTEM_MONEY_LOCATION = <cfif len(GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY)>'#GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY#'<cfelse>'#form.cost_money_system#'</cfif>, --->
                            PURCHASE_NET_SYSTEM_2_LOCATION = #(evaluate("alis_net_fiyat_system_2_lokasyon_#PRODUCT_COST_ID#")-prc_protec_sys_2)#,
                            PURCHASE_EXTRA_COST_SYSTEM_2_LOCATION = #evaluate("alis_ek_maliyet_system_2_lokasyon_#PRODUCT_COST_ID#")+std_cost_sys_2+((evaluate("alis_net_fiyat_system_2_lokasyon_#PRODUCT_COST_ID#")*GET_NEWER_P_COSTS.STANDARD_COST_RATE_LOCATION)/100)#,
                            <!--- PURCHASE_NET_SYSTEM_MONEY_2_LOCATION = <cfif len(GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY_2)>'#GET_NEWER_P_COSTS.PURCHASE_NET_SYSTEM_MONEY_2#'<cfelse>'#form.cost_money_system_2#'</cfif>, --->
                            
                            ACTIVE_STOCK_DEPARTMENT = 0,
                            AVAILABLE_STOCK_DEPARTMENT = <cfif len(evaluate('mevcut_son_alislar_department_#PRODUCT_COST_ID#'))>#evaluate('mevcut_son_alislar_department_#PRODUCT_COST_ID#')#<cfelse>0</cfif>,
                            PRODUCT_COST_DEPARTMENT = #(evaluate("alis_net_fiyat_department_#PRODUCT_COST_ID#")+evaluate("alis_ek_maliyet_department_#PRODUCT_COST_ID#")+std_cost_loc+((evaluate("alis_net_fiyat_department_#PRODUCT_COST_ID#")*GET_NEWER_P_COSTS.STANDARD_COST_RATE_DEPARTMENT)/100)-prc_protec_loc)#,
                            PURCHASE_NET_DEPARTMENT = #evaluate("alis_net_fiyat_department_#PRODUCT_COST_ID#")#,
                            PURCHASE_EXTRA_COST_DEPARTMENT = #evaluate("alis_ek_maliyet_department_#PRODUCT_COST_ID#")#,
                            PURCHASE_NET_MONEY_DEPARTMENT = '#GET_NEWER_P_COSTS.PURCHASE_NET_MONEY#', 
                            PURCHASE_NET_SYSTEM_DEPARTMENT = #(evaluate("alis_net_fiyat_system_department_#PRODUCT_COST_ID#")-prc_protec_sys)#,
                            PURCHASE_EXTRA_COST_SYSTEM_DEPARTMENT = #evaluate("alis_ek_maliyet_system_department_#PRODUCT_COST_ID#")+std_cost_sys+((evaluate("alis_net_fiyat_system_department_#PRODUCT_COST_ID#")*GET_NEWER_P_COSTS.STANDARD_COST_RATE_DEPARTMENT)/100)#,
                            PURCHASE_NET_SYSTEM_2_DEPARTMENT = #(evaluate("alis_net_fiyat_system_2_department_#PRODUCT_COST_ID#")-prc_protec_sys_2)#,
                            PURCHASE_EXTRA_COST_SYSTEM_2_DEPARTMENT = #evaluate("alis_ek_maliyet_system_2_department_#PRODUCT_COST_ID#")+std_cost_sys_2+((evaluate("alis_net_fiyat_system_2_department_#PRODUCT_COST_ID#")*GET_NEWER_P_COSTS.STANDARD_COST_RATE_DEPARTMENT)/100)#,
                         

                            <cfif GET_COST_FOR_DUE.RECORDCOUNT>DUE_DATE=<cfif isdefined('due_date_#PRODUCT_COST_ID#') and isdate(evaluate('due_date_#PRODUCT_COST_ID#'))>#evaluate('due_date_#PRODUCT_COST_ID#')#<cfelse>NULL</cfif>,</cfif>
                            <cfif GET_COST_FOR_DUE_LOCATION.RECORDCOUNT>DUE_DATE_LOCATION=<cfif isdefined('due_date_location_#PRODUCT_COST_ID#') and isdate(evaluate('due_date_location_#PRODUCT_COST_ID#'))>#evaluate('due_date_location_#PRODUCT_COST_ID#')#<cfelse>NULL</cfif>,</cfif>
                            <cfif GET_COST_FOR_PHYSICAL.RECORDCOUNT>PHYSICAL_DATE=<cfif isdefined('physical_date_#PRODUCT_COST_ID#') and isdate(evaluate('physical_date_#PRODUCT_COST_ID#'))>#evaluate('physical_date_#PRODUCT_COST_ID#')#<cfelse>NULL</cfif>,</cfif>
                            <cfif GET_COST_FOR_PHYSICAL_LOCATION.RECORDCOUNT>PHYSICAL_DATE_LOCATION=<cfif isdefined('physical_date_location_#PRODUCT_COST_ID#') and isdate(evaluate('physical_date_location_#PRODUCT_COST_ID#'))>#evaluate('physical_date_location_#PRODUCT_COST_ID#')#<cfelse>NULL</cfif>,</cfif>
                            
                            PRODUCT_COST_STATUS=<cfif GET_NEWER_P_COSTS.RECORDCOUNT eq GET_NEWER_P_COSTS.CURRENTROW>1<cfelse>0</cfif>,
                            UPDATE_DATE = #now()#,
                            UPDATE_EMP = 0,
                            UPDATE_IP = '#cgi.REMOTE_ADDR#'
                        WHERE
                            PRODUCT_COST_ID = #PRODUCT_COST_ID#
                    </cfquery>
                    <cfif arguments.newer_action_process_type neq 0>
                        <cfquery name="upd_cost" datasource="#dsn1#">
                            UPDATE
                                PRODUCT_COST
                            SET
                                PURCHASE_NET_ALL = PURCHASE_NET,
                                PURCHASE_NET_SYSTEM_ALL = PURCHASE_NET,
                                PURCHASE_NET_SYSTEM_2_ALL = PURCHASE_NET,
                                PURCHASE_NET_LOCATION_ALL = PURCHASE_NET_LOCATION,
                                PURCHASE_NET_SYSTEM_LOCATION_ALL = PURCHASE_NET_LOCATION,
                                PURCHASE_NET_SYSTEM_2_LOCATION_ALL = PURCHASE_NET_LOCATION,
                                PURCHASE_NET_DEPARTMENT_ALL = PURCHASE_NET_DEPARTMENT,
                                PURCHASE_NET_SYSTEM_DEPARTMENT_ALL = PURCHASE_NET_DEPARTMENT,
                                PURCHASE_NET_SYSTEM_2_DEPARTMENT_ALL = PURCHASE_NET_DEPARTMENT
                            WHERE
                                PRODUCT_COST_ID = #PRODUCT_COST_ID#
                        </cfquery>
                    </cfif>
                    </cfif>
                </cfif>
            </cfloop> 
        </cfif>
    </cffunction>
    
<!---get_prod_order_funcs---> 
    
    <cffunction name="GET_STATION_PROD">
        <cfargument name="get_station_id" type="numeric" required="true">
        <cfargument name="get_other" type="string"  default=""  required="false">
        <cfquery name="GET_STATION_OF_ORDER" datasource="#DSN#">
            SELECT
                W.*,
                B.BRANCH_ID,
                B.BRANCH_NAME
            FROM
                #dsn3_alias#.WORKSTATIONS W,
                BRANCH B
            WHERE
                W.BRANCH = B.BRANCH_ID AND
                W.STATION_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#get_station_id#">
        </cfquery>
        <cfif  get_other eq "uye">
            <cfif LEN(GET_STATION_OF_ORDER.OUTSOURCE_PARTNER) AND ISNUMERIC(GET_STATION_OF_ORDER.OUTSOURCE_PARTNER)>
                <cfreturn #get_par_info(GET_STATION_OF_ORDER.OUTSOURCE_PARTNER,0,-1,1)#> 
            <cfelse>
                <cfreturn ''>	
            </cfif>
        <cfelseif  get_other eq "yetkili">	
            <cfif GET_STATION_OF_ORDER.RECORDCOUNT>
                <cfset DEGER= "<a href=""javascript://""  onclick=""windowopen('#request.self#?fuseaction=objects.popup_emp_det&emp_id=" &  #GET_STATION_OF_ORDER.employee_id# & "','medium');"" class=""tableyazi"">" & #GET_STATION_OF_ORDER.FULLNAME2# & "</a>" />
                <cfreturn DEGER>	
            <cfelse>
                <cfreturn ''>
            </cfif> 
        <cfelse>
            <cfif GET_STATION_OF_ORDER.RECORDCOUNT>
                <cfreturn GET_STATION_OF_ORDER.STATION_NAME>
            <cfelse>
                <cfreturn ''>
            </cfif> 
        </cfif>
    </cffunction>
    
    <cffunction name="GET_ROUTE_PROD">
        <cfargument name="get_route_id" type="numeric" required="true">
        <cfquery name="GET_ROUTE_OF_ORDER" datasource="#DSN3#">
            SELECT ROUTE FROM ROUTE WHERE ROUTE_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#get_route_id#">
        </cfquery>
        <cfif GET_ROUTE_OF_ORDER.RECORDCOUNT>
            <cfreturn GET_ROUTE_OF_ORDER.ROUTE>
        <cfelse>
            <cfreturn ''>
        </cfif> 
    </cffunction>
    
    <cffunction name="GET_PROSPECTUS_PROD">
        <cfargument name="get_prospectus_id" type="numeric" required="true">
        <cfquery name="GET_PROSPECTUS_OF_ORDER" datasource="#DSN3#">
            SELECT PROSPECTUS_NAME FROM PROSPECTUS WHERE PROSPECTUS_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#get_prospectus_id#">
        </cfquery>
        <cfif GET_PROSPECTUS_OF_ORDER.RECORDCOUNT>
            <cfreturn GET_PROSPECTUS_OF_ORDER.PROSPECTUS_NAME>
        <cfelse>
            <cfreturn ''>
        </cfif> 
    </cffunction>
    
    <cffunction name="GET_STATUS_PROD_ORDER">
        <cfargument name="status_id" type="numeric" required="true">
        <cfquery name="GET_STATUS_OF_PROD" datasource="#DSN#">
            SELECT STATUS_NAME FROM PRODUCTION_STATUS WHERE STATUS_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#status_id#">
        </cfquery>
        <cfif GET_STATUS_OF_PROD.RECORDCOUNT>
            <cfreturn GET_STATUS_OF_PROD.STATUS_NAME>
        <cfelse>
            <cfreturn ''>
        </cfif> 
    </cffunction>
    
    <cffunction name="GET_PRODUCT_PROPERTY_PROD">
        <cfargument name="stock_id" type="numeric" required="true">
        <cfargument name="be_wanted" type="string" required="false" default="pro_name">
        <cfquery name="GET_PRODUCT_NAMES" datasource="#DSN3#">
            SELECT
                S.PRODUCT_NAME,
                S.PROPERTY,
                PU.MAIN_UNIT,
                S.PRODUCT_ID
            FROM
                STOCKS AS S,
                PRODUCT_UNIT AS PU
            WHERE
                PU.PRODUCT_ID = S.PRODUCT_ID AND
                STOCK_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#stock_id#">
        </cfquery>
        <cfif GET_PRODUCT_NAMES.RECORDCOUNT>
            <cfif len(be_wanted)>
                <cfset 	deger = "#be_wanted#" />
                <cfswitch expression="#deger#">
                    <cfcase value="unit">
                        <cfset deger = GET_PRODUCT_NAMES.MAIN_UNIT />
                    </cfcase>
                    <cfcase value="pro">
                        <cfset deger = GET_PRODUCT_NAMES.PRODUCT_ID & " " & GET_PRODUCT_NAMES.PRODUCT_ID />
                    </cfcase>
                    <cfdefaultcase>
                        <cfset deger = GET_PRODUCT_NAMES.PRODUCT_NAME />
                    </cfdefaultcase>
                </cfswitch>
                <cfreturn deger>
            <cfelse>
                <cfreturn GET_PRODUCT_NAMES.PRODUCT_NAME & " " &  GET_PRODUCT_NAMES.PROPERTY />
            </cfif>
        <cfelse>
            <cfreturn ''>
        </cfif> 
    </cffunction>
    
    <cffunction name="GET_PRODUCT_UNIT_PROD">
        <cfargument name="get_product_id" type="numeric" required="true">
        <cfquery name="GET_PRODUCT_UNIT_OF_ORDER" datasource="#DSN3#">
            SELECT MAIN_UNIT FROM PRODUCT_UNIT WHERE PRODUCT_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#get_product_id#">
        </cfquery>
        <cfif GET_PRODUCT_UNIT_OF_ORDER.RECORDCOUNT>
            <cfreturn GET_PRODUCT_UNIT_OF_ORDER.MAIN_UNIT>
        <cfelse>
            <cfreturn ''>
        </cfif> 
    </cffunction>
    
<!---add_product_price--->     

    <cffunction name="add_price" returntype="any" output="false">
        <!---
        by :20040119
        notes : Bir ürüne o ürünün bir birimine ait ve belli bir fiyat listesi icin fiyat ekler.
        Önemli : Kullanılırken mutlaka bir transaction icinde calisiyor olmalı.
        usage :
        add_price
            (
            product_id : fiyat yapilan urun (int),
            product_unit_id : fiyat yapilan urun birimi (int),
            price_cat : ilgili fiyat listesi (int),
            start_date : fiyat baslangic tarihi (date),
            price : kdv siz fiyat (float),
            price_money : fiyat para birimi (TL,USD),
            price_with_kdv : kdv li fiyat ////// ESKİDEN YANDAKİ GEÇERLİYDİ ARTIK DİİL: AK20051003(eger bu arguman gelmisse IS_KDV de 1 olarak set edilecek),
            catalog_id : Fiyat bir Aksiyon'dan set ediliyorsa o Aksiyonun ID si
            is_kdv : formdan gelen değer kdv li fiyat içinmi yoksa kdv siz fiyat içinmi AK20051003
            );
        revisions : 
        --->
        <cfargument name="product_id" required="true" type="numeric">
        <cfargument name="product_unit_id" required="true" type="numeric">
        <cfargument name="price_cat" required="true" type="numeric">
        <cfargument name="start_date" required="true" type="date">
        <cfargument name="price" required="true" type="numeric">
        <cfargument name="price_money" required="true" type="string">
        <cfargument name="price_with_kdv" required="true" type="numeric">
        <cfargument name="catalog_id" type="numeric" required="false">
        <cfargument name="is_kdv" type="numeric" required="yes">
        <cfargument name="price_discount" required="no" type="numeric">
        <cfargument name="stock_id" type="string" required="no">
        <cfargument name="spect_var_id" type="string" required="no">
        <cfif len(arguments.product_id) and len(arguments.price_cat) and isdate(arguments.start_date) and len(arguments.product_unit_id) and len(arguments.price) and len(arguments.price_money)>
            <cfif database_type is 'MSSQL'>
                <cfquery name="ADD_PRODUCT_PRICE" datasource="#dsn3#" timeout="180">
                    add_price 
                            #arguments.product_id#,
                            #arguments.product_unit_id#,
                            #arguments.price_cat#,
                            #arguments.start_date#,
                            #arguments.price#,
                            '#arguments.price_money#',
                            #arguments.is_kdv#,
                            #arguments.price_with_kdv#,
                        <cfif isDefined('arguments.catalog_id')>
                            #arguments.catalog_id#,
                        <cfelse>
                            -1,
                        </cfif>
                            #session.ep.userid#,
                            '#cgi.remote_addr#',
                        <cfif isDefined('arguments.price_discount')>
                            #arguments.price_discount#
                        <cfelse>
                            0
                        </cfif>
                        <cfif isDefined('arguments.stock_id') and len(arguments.stock_id)>
                            ,#arguments.stock_id#
                        <cfelse>
                            ,0
                        </cfif>
                        <cfif isDefined('arguments.spect_var_id') and len(arguments.spect_var_id)>
                            ,#arguments.spect_var_id#
                        <cfelse>
                            ,0
                        </cfif>
                </cfquery>
            <cfelse>
                <cfquery name="DELETE_PRICE_THIS_PRODUCT" datasource="#dsn3#">
                    DELETE FROM 
                        PRICE
                    WHERE
                        PRICE_CATID = #arguments.price_cat# 
                        AND STARTDATE=#arguments.start_date#
                        AND PRODUCT_ID=#arguments.product_id#
                        AND UNIT=#arguments.product_unit_id#
                        <cfif isDefined('arguments.stock_id') and len(arguments.stock_id)>
                            AND STOCK_ID=#arguments.stock_id#
                        <cfelse>
                            AND STOCK_ID IS NULL
                        </cfif>
                        <cfif isDefined('arguments.spect_var_id') and len(arguments.spect_var_id)>
                            AND SPECT_VAR_ID=#arguments.spect_var_id#
                        <cfelse>
                            AND SPECT_VAR_ID IS NULL
                        </cfif>
                </cfquery>
                <cfquery name="DELETE_PRICE_HISTORY_THIS_PRODUCT" datasource="#dsn3#">
                    DELETE FROM 
                        PRICE_HISTORY 
                    WHERE
                        PRICE_CATID = #arguments.price_cat#
                        AND STARTDATE=#arguments.start_date# 
                        AND PRODUCT_ID=#arguments.product_id# 
                        AND UNIT=#arguments.product_unit_id#
                        <cfif isDefined('arguments.stock_id') and len(arguments.stock_id)>
                            AND STOCK_ID=#arguments.stock_id#
                        <cfelse>
                            AND STOCK_ID IS NULL
                        </cfif>
                        <cfif isDefined('arguments.spect_var_id') and len(arguments.spect_var_id)>
                            AND SPECT_VAR_ID=#arguments.spect_var_id#
                        <cfelse>
                            AND SPECT_VAR_ID IS NULL
                        </cfif>
                </cfquery>
                <cfquery name="DELETE_ALL_OLD_PRODUCT_PRICE" datasource="#dsn3#">
                    DELETE FROM PRICE WHERE FINISHDATE < #DATEADD('d',-1,now())#
                </cfquery>
                <cfquery name="UPDATE_PREVIOUS_PRODUCT_PRICE" datasource="#dsn3#" maxrows="1">
                    UPDATE 
                        PRICE 
                    SET 
                        FINISHDATE=#DATEADD('s',-1,arguments.start_date)#
                    WHERE
                        PRODUCT_ID=#arguments.product_id#
                        AND UNIT=#arguments.product_unit_id#
                        AND PRICE_CATID=#arguments.price_cat#
                        AND STARTDATE < #arguments.start_date#
                        AND (FINISHDATE IS NULL OR FINISHDATE > #arguments.start_date#)
                        <cfif isDefined('arguments.stock_id') and len(arguments.stock_id)>
                            AND STOCK_ID=#arguments.stock_id#
                        <cfelse>
                            AND STOCK_ID IS NULL
                        </cfif>
                        <cfif isDefined('arguments.spect_var_id') and len(arguments.spect_var_id)>
                            AND SPECT_VAR_ID=#arguments.spect_var_id#
                        <cfelse>
                            AND SPECT_VAR_ID IS NULL
                        </cfif>
                </cfquery>
                <cfquery name="UPDATE_PREVIOUS_PRODUCT_PRICE_HISTORY" datasource="#dsn3#" maxrows="1">
                    UPDATE 
                        PRICE_HISTORY
                    SET
                        FINISHDATE=#DATEADD('s',-1,arguments.start_date)#
                    WHERE
                        PRODUCT_ID=#arguments.product_id#
                        AND UNIT=#arguments.product_unit_id#
                        AND PRICE_CATID=#arguments.price_cat#
                        AND STARTDATE < #arguments.start_date# 
                        AND (FINISHDATE IS NULL OR FINISHDATE > #arguments.start_date#)
                        <cfif isDefined('arguments.stock_id') and len(arguments.stock_id)>
                            AND STOCK_ID=#arguments.stock_id#
                        <cfelse>
                            AND STOCK_ID IS NULL
                        </cfif>
                        <cfif isDefined('arguments.spect_var_id') and len(arguments.spect_var_id)>
                            AND SPECT_VAR_ID=#arguments.spect_var_id#
                        <cfelse>
                            AND SPECT_VAR_ID IS NULL
                        </cfif>
                </cfquery>
                <cfquery name="SELECT_NEXT_PRODUCT_STARTDATE" datasource="#dsn3#" maxrows="1">
                    SELECT 
                        STARTDATE 
                    FROM
                        PRICE
                    WHERE
                        PRODUCT_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.product_id#">
                        AND UNIT = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.product_unit_id#">
                        AND PRICE_CATID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.price_cat#">
                        AND STARTDATE > <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.start_date#">
                        <cfif isDefined('arguments.stock_id') and len(arguments.stock_id)>
                            AND STOCK_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.stock_id#">
                        <cfelse>
                            AND STOCK_ID IS NULL
                        </cfif>
                        <cfif isDefined('arguments.spect_var_id') and len(arguments.spect_var_id)>
                            AND SPECT_VAR_ID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.spect_var_id#">
                        <cfelse>
                            AND SPECT_VAR_ID IS NULL
                        </cfif>
                    ORDER BY STARTDATE
                </cfquery>
                <cfquery name="ADD_PRODUCT_PRICE" datasource="#dsn3#">
                    INSERT INTO
                        PRICE
                    (
                        PRICE_CATID,
                        PRODUCT_ID,
                        STOCK_ID,
                        SPECT_VAR_ID,
                        STARTDATE,
                    <cfif len(SELECT_NEXT_PRODUCT_STARTDATE.STARTDATE)>
                        FINISHDATE,
                    </cfif>
                        PRICE,
                        IS_KDV,
                        PRICE_KDV,
                        PRICE_DISCOUNT,
                        MONEY,
                        UNIT,
                    <cfif isDefined('arguments.catalog_id')>
                        CATALOG_ID,
                    </cfif>
                        RECORD_DATE,
                        RECORD_EMP,
                        RECORD_IP
                    )
                    VALUES
                    (
                        #arguments.price_cat#,
                        #arguments.product_id#,
                    <cfif isDefined('arguments.stock_id') and len(arguments.stock_id)>#arguments.stock_id#<cfelse>NULL</cfif>,
                    <cfif isDefined('arguments.spect_var_id') and len(arguments.spect_var_id)>#arguments.spect_var_id#<cfelse>NULL</cfif>,
                        #arguments.start_date#,
                    <cfif len(SELECT_NEXT_PRODUCT_STARTDATE.STARTDATE)>
                        #date_add('s',-1,SELECT_NEXT_PRODUCT_STARTDATE.STARTDATE)#,
                    </cfif>
                        #arguments.price#,
                        #arguments.is_kdv#,
                        #arguments.price_with_kdv#,
                    <cfif isDefined('arguments.price_discount')>
                        #arguments.price_discount#,
                    <cfelse>
                        0,
                    </cfif>
                        '#arguments.price_money#',
                        #arguments.product_unit_id#,
                    <cfif isDefined('arguments.catalog_id')>
                        #arguments.catalog_id#,
                    </cfif>
                        #now()#,
                        #session.ep.userid#,
                        '#cgi.remote_addr#'
                    )
                </cfquery>
                <cfquery name="ADD_PRODUCT_PRICE_HISTORY" datasource="#dsn3#">
                    INSERT INTO	
                        PRICE_HISTORY
                    (
                        PRICE_CATID,
                        PRODUCT_ID,
                        STOCK_ID,
                        SPECT_VAR_ID,
                        STARTDATE,
                    <cfif len(SELECT_NEXT_PRODUCT_STARTDATE.STARTDATE)>
                        FINISHDATE,
                    </cfif>
                        PRICE,
                        IS_KDV,
                        PRICE_KDV,
                        PRICE_DISCOUNT,
                        MONEY,
                        UNIT,
                    <cfif isDefined('arguments.catalog_id')>
                        CATALOG_ID,
                    </cfif>
                        RECORD_DATE,
                        RECORD_EMP,
                        RECORD_IP
                    )					 
                    VALUES
                    (
                        #arguments.price_cat#,
                        #arguments.product_id#,
                    <cfif isDefined('arguments.stock_id') and len(arguments.stock_id)>#arguments.stock_id#<cfelse>NULL</cfif>,
                    <cfif isDefined('arguments.spect_var_id') and len(arguments.spect_var_id)>#arguments.spect_var_id#<cfelse>NULL</cfif>,
                        #arguments.start_date#,
                    <cfif len(SELECT_NEXT_PRODUCT_STARTDATE.STARTDATE)>
                        #date_add('s',-1,SELECT_NEXT_PRODUCT_STARTDATE.STARTDATE)#,
                    </cfif>
                        #arguments.price#,
                        #arguments.is_kdv#,
                        #arguments.price_with_kdv#,
                    <cfif isDefined('arguments.price_discount')>
                        #arguments.price_discount#,
                    <cfelse>
                        0,
                    </cfif>
                        '#arguments.price_money#',
                        #arguments.product_unit_id#,
                    <cfif isDefined('arguments.catalog_id')>
                        #arguments.catalog_id#,
                    </cfif>
                        #now()#,
                        #session.ep.userid#,
                        '#cgi.remote_addr#'
                    )
                </cfquery>
            </cfif>
            <cfreturn true>
        <cfelse>
            <cfreturn false>
        </cfif>
    </cffunction>  

<!--- add_one --->

	<cffunction name="add_one" returntype="boolean" output="false">
	<cfargument name="gelen" required="yes" type="any">
		<cfscript>
            elde = 0;
            uz = len(gelen);
            for (i=uz; i gt 0;i=i-1)
                {
                eleman = mid(gelen,i,1);
        
                if ( (i eq uz) or (elde) )
                    eleman = eleman + 1;
        
                if (eleman gt 9)
                    elde = 1;
                else
                    elde = 0;
        
                if (i eq 1)
                    {
                    if (elde)
                        bas = '1';
                    else
                        bas = '';
                    }
                else
                    bas = left(gelen,i-1);
                
                if (i neq uz)
                    son = right(gelen,uz-i);
                else
                    son = '';
                    
                gelen = '#bas##right(eleman,1)##son#';
                if (not elde)
                    return gelen;
                }
            return gelen;
		</cfscript>
	</cffunction> 
    
	
    
    <cffunction name="GET_PRO_ORD">
          <cfargument name="ORDER_ID" type="numeric" required="true">
          <cfargument name="STOCK_ID" type="numeric" required="true">
          <cfquery name="GET_STATUS_OF_PROD" datasource="#DSN3#">
              SELECT 
                  STATUS_ID 
              FROM 
                  PRODUCTION_ORDERS 
              WHERE 
                ORDER_ID=#ORDER_ID# 
              AND 
                STOCK_ID=#STOCK_ID#
          </cfquery>
          <cfif GET_STATUS_OF_PROD.RECORDCOUNT >
                <cfif  GET_STATUS_OF_PROD.STATUS_ID gt 0>
                   <cfset deger=GET_STATUS_PROD_ORDER(GET_STATUS_OF_PROD.STATUS_ID) />
                 <cfelse>
                   <cfset deger=GET_STATUS_OF_PROD.STATUS_ID />
                </cfif>
                <cfreturn deger>
           <cfelse>
                <cfreturn ''>
          </cfif>
        </cffunction>
        
        <cffunction  name="get_name" >
            <cfargument name="prop_id" >
            <cfargument name="our_type" >
            <cfswitch expression="#our_type#">
                <cfcase value="ws">
                    <cfset table_name= "WORKSTATIONS" />
                    <cfset field_name= "STATION_NAME" />
                    <cfset look_id="STATION_ID" />
                </cfcase>
            </cfswitch>
            <CFQUERY name="GET_OUR_NAME" datasource="#DSN3#">
                SELECT 
                    #PreserveSingleQuotes(field_name)#  AS MY_FIELD
                FROM 
                    #PreserveSingleQuotes(table_name)# 
                WHERE 
                    #PreserveSingleQuotes(look_id)#=#prop_id#
            </CFQUERY>
            <cfif GET_OUR_NAME.RECORDCOUNT>
                <cfreturn GET_OUR_NAME.MY_FIELD>
            <cfelse>
                <cfreturn "">
            </cfif>
        </cffunction>
        
        <cffunction  name="get_price" >
            <cfargument name="stock_id" >
            <cfargument name="our_type" >
            <cfargument name="wanted" >
            <cfif our_type  eq "pur">
                <cfset val=0 />
            <cfelse>
                <cfset val=1 />
            </cfif>
            <CFQUERY name="GET_PRO_PRICE" datasource="#DSN3#">
                SELECT	
                    PRICE,MONEY,ADD_UNIT 
                FROM 
                    PRICE_STANDART,STOCKS,PRODUCT_UNIT
                WHERE 
                    PRICE_STANDART.PRODUCT_ID = STOCKS.PRODUCT_ID 
                    AND PRICE_STANDART.PURCHASESALES = #val# 
                    AND	PRICE_STANDART.PRICESTANDART_STATUS = 1 
                    AND	STOCKS.STOCK_ID = #stock_id#
                    AND	PRODUCT_UNIT.UNIT_ID = STOCKS.PRODUCT_UNIT_ID
                    AND	PRODUCT_UNIT.PRODUCT_ID = PRICE_STANDART.PRODUCT_ID
                    AND	PRICE_STANDART.UNIT_ID = PRODUCT_UNIT.PRODUCT_UNIT_ID				
            </CFQUERY>
            <cfif GET_PRO_PRICE.RECORDCOUNT and wanted eq "price_tl">
                <cfreturn #numberformat(GET_PRO_PRICE.PRICE)# & " " & #GET_PRO_PRICE.MONEY# >
            <cfelseif GET_PRO_PRICE.RECORDCOUNT and wanted eq "price">		
                <cfreturn GET_PRO_PRICE.PRICE >
            <cfelseif GET_PRO_PRICE.RECORDCOUNT>
                <cfreturn GET_PRO_PRICE.ADD_UNIT>
            <cfelse>
                <cfreturn 0>
            </cfif>
        </cffunction>
        
        <cffunction name="get_stock">
            <cfargument name="s_date">
            <cfargument name="stock_id">
            <cfset s_date=dateformat(s_date,'dd/mm/yyyy') />
            <cf_date  tarih='s_date'>
            
            <cfquery name="get_in"  datasource="#DSN2#">
                SELECT
                    SUM(STOCK_IN) AS STOCK_IN 
                FROM
                    STOCKS_ROW
                WHERE
                    PROCESS_DATE <=#s_date#
                AND
                    STOCK_ID=#stock_id#		
            </cfquery>
                <cfquery name="get_out"  datasource="#DSN2#">
                SELECT
                    SUM(STOCK_OUT) AS STOCK_OUT
                FROM
                    STOCKS_ROW
                WHERE
                    PROCESS_DATE <=#s_date#
                AND
                    STOCK_ID=#stock_id#		
            </cfquery>
            <cfif len(get_in.STOCK_IN) ><cfset ge_in=get_in.STOCK_IN /><cfelse><cfset ge_in=0 /></cfif>
            <cfif len(get_out.STOCK_OUT) ><cfset ge_out=get_out.STOCK_OUT /><cfelse><cfset ge_out=0 /></cfif>
        
            <cfreturn #evaluate(ge_in-ge_out)#>
        </cffunction>
    
    <!--- get_phantom_product_list ---->
    	<cffunction name="get_subs_order" returntype="any" >
            <cfargument name="spect_id">
            <cfscript>
                SQLStr = "
                        SELECT
                            AMOUNT,
                            ISNULL(RELATED_MAIN_SPECT_ID,0) RELATED_MAIN_SPECT_ID,
                            ISNULL(STOCK_ID,0) STOCK_ID,
                            ISNULL(LINE_NUMBER, 0) LINE_NUMBER
                        FROM 
                            SPECT_MAIN_ROW SM
                        WHERE
                            SPECT_MAIN_ID = #arguments.spect_id#
                            AND IS_PHANTOM = 1
                    ";
                query1 = cfquery(SQLString : SQLStr, Datasource : dsn3);
                stock_id_ary='';
                for (str_i=1; str_i lte query1.recordcount; str_i = str_i+1)
                {
                    stock_id_ary=listappend(stock_id_ary,query1.AMOUNT[str_i],'█');
                    stock_id_ary=listappend(stock_id_ary,query1.RELATED_MAIN_SPECT_ID[str_i],'§');
                    stock_id_ary=listappend(stock_id_ary,query1.STOCK_ID[str_i],'§');
                    stock_id_ary=listappend(stock_id_ary,query1.LINE_NUMBER[str_i],'§');
                }
            </cfscript>
            <cfreturn stock_id_ary>
        </cffunction>
        
        <cffunction name="writeTree_order" returntype="void">
            <cfargument name="spect_main_id">
            <cfargument name="old_amount">
            <cfscript>
                var i = 1;
				var sub_products = get_subs_order(spect_main_id);
				for (i=1; i lte listlen(sub_products,'█'); i = i+1)
				{
					_next_amount_ = ListGetAt(ListGetAt(sub_products,i,'█'),1,'§');//alt+987 = █ --//alt+789 = §
					_next_spect_id_ = ListGetAt(ListGetAt(sub_products,i,'█'),2,'§');
					_next_stock_id_ = ListGetAt(ListGetAt(sub_products,i,'█'),3,'§');
					_next_line_number_ = ListGetAt(ListGetAt(sub_products,i,'█'),4,'§');
					phantom_spec_main_id_list = listappend(phantom_spec_main_id_list,_next_spect_id_,',');
					phantom_stock_id_list = listappend(phantom_stock_id_list,_next_stock_id_,',');
					phantom_line_number_list = listappend(phantom_line_number_list,_next_line_number_,',');
					if(_next_spect_id_ gt 0)
					{
						'multipler_#_next_spect_id_#' = _next_amount_*old_amount;
						writeTree_order(_next_spect_id_,_next_amount_*old_amount);
					}
				 }
            </cfscript>
        </cffunction>
        
        <cffunction name="get_subs_operation" returntype="any">
            <cfargument name="next_stock_id">
            <cfargument name="next_spec_id">
            <cfargument name="next_product_tree_id">
            <cfargument name="type">
     		<cfscript>
				if(type eq 0) where_parameter = 'PT.STOCK_ID = #next_stock_id#'; else where_parameter = 'RELATED_PRODUCT_TREE_ID = #next_product_tree_id#';							
				SQLStr = "
						SELECT
							PRODUCT_TREE_ID,
							AMOUNT,
							ISNULL(SPECT_MAIN_ID,0) SPECT_MAIN_ID,
							ISNULL(RELATED_ID,0) STOCK_ID,
							ISNULL(PT.OPERATION_TYPE_ID,0) OPERATION_TYPE_ID
						FROM
							PRODUCT_TREE PT
						WHERE
							#where_parameter#
						ORDER BY LINE_NUMBER ASC
					";
				query1 = cfquery(SQLString : SQLStr, Datasource : dsn3);
				stock_id_ary='';
				'type_#attributes.deep_level_op#' = type;
				for (str_i=1; str_i lte query1.recordcount; str_i = str_i+1)
				{
					stock_id_ary=listappend(stock_id_ary,query1.PRODUCT_TREE_ID[str_i],'█');
					stock_id_ary=listappend(stock_id_ary,query1.SPECT_MAIN_ID[str_i],'§');
					stock_id_ary=listappend(stock_id_ary,query1.STOCK_ID[str_i],'§');
					stock_id_ary=listappend(stock_id_ary,query1.AMOUNT[str_i],'§');
					stock_id_ary=listappend(stock_id_ary,query1.OPERATION_TYPE_ID[str_i],'§');
					stock_id_ary=listappend(stock_id_ary,attributes.deep_level_op,'§');
				}
			 </cfscript>
             <cfreturn stock_id_ary>
        </cffunction>
        
        <cffunction name="writeTree_operation" returntype="void">
            <cfargument name="next_stock_id">
            <cfargument name="next_spec_id">
            <cfargument name="next_product_tree_id">
            <cfargument name="type">
     		<cfscript>
				var i = 1;
				var sub_products = get_subs_operation(next_stock_id,next_spec_id,next_product_tree_id,type);
				attributes.deep_level_op = attributes.deep_level_op + 1;
				for (i=1; i lte listlen(sub_products,'█'); i = i+1)
				{
					_next_product_tree_id_ = ListGetAt(ListGetAt(sub_products,i,'█'),1,'§');//alt+987 = █ --//alt+789 = §
					_next_spect_id_ = ListGetAt(ListGetAt(sub_products,i,'█'),2,'§');
					_next_stock_id_ = ListGetAt(ListGetAt(sub_products,i,'█'),3,'§');
					_next_amount_ = ListGetAt(ListGetAt(sub_products,i,'█'),4,'§');
					_next_operation_id_ = ListGetAt(ListGetAt(sub_products,i,'█'),5,'§');
					_next_deep_level_ = ListGetAt(ListGetAt(sub_products,i,'█'),6,'§');
					product_tree_id_list = listappend(product_tree_id_list,_next_product_tree_id_,',');
					operation_type_id_list = listappend(operation_type_id_list,_next_operation_id_,',');
					amount_list = listappend(amount_list,_next_amount_,',');
					"deep_level_#_next_operation_id_#" = _next_deep_level_;
					deep_level_list = listappend(deep_level_list,_next_deep_level_,',');
					if(_next_operation_id_ gt 0) type_=3;else type_=0;
		
					if(attributes.deep_level_op lt 40)
					{
						writeTree_operation(_next_stock_id_,_next_spect_id_,_next_product_tree_id_,type_);
					}
				 }
			 </cfscript>
        </cffunction>
        
        <cffunction name="WriteRelatedProduction2" returntype="void">
            <cfargument name="P_ORDER_ID">
     		<cfscript>
				var i = 1;
				QueryText = '
						SELECT 
							P_ORDER_ID
						FROM 
							PRODUCTION_ORDERS
						WHERE 
							PO_RELATED_ID = #P_ORDER_ID#';
				'GET_RELATED_PRODUCTION#P_ORDER_ID#' = cfquery(SQLString : QueryText, Datasource : dsn3);
				if(Evaluate('GET_RELATED_PRODUCTION#P_ORDER_ID#').recordcount) 
				{
					for(i=1;i lte Evaluate("GET_RELATED_PRODUCTION#P_ORDER_ID#").recordcount;i=i+1)
					{
						related_production_list = ListAppend(related_production_list,Evaluate("GET_RELATED_PRODUCTION#P_ORDER_ID#").P_ORDER_ID[i],',');
						WriteRelatedProduction2(Evaluate("GET_RELATED_PRODUCTION#P_ORDER_ID#").P_ORDER_ID[i]);
					}
				}
			 </cfscript>
        </cffunction>
        
        <cffunction name="Relation_IDs" returntype="void">
            <cfargument name="x_id">
     		<cfscript>
				SQLStr_Relation = 'SELECT PRODUCT_TREE_ID FROM PRODUCT_TREE WHERE RELATED_PRODUCT_TREE_ID ='&x_id;
				query_Relation = cfquery(SQLString : SQLStr_Relation, Datasource : dsn3);
				for(i=1;i lte query_Relation.recordcount; i=i+1)
				{
					stock_id_ary=listappend(stock_id_ary,query_Relation.PRODUCT_TREE_ID[i],',');
					Relation_IDs(query_Relation.PRODUCT_TREE_ID[i]);
				}
			 </cfscript>
        </cffunction>
        
        <cffunction name="_get_subs_" returntype="any">
        <cfargument name="spect_main_id">
        	<cfscript>
					_SubSqlStr_ = '
							SELECT
								ISNULL(S.IS_PRODUCTION,0)IS_PRODUCTION,
								ISNULL(SMR.RELATED_MAIN_SPECT_ID,0)AS RELATED_ID,
								SMR.STOCK_ID,
								SMR.IS_CONFIGURE,
								S.PRODUCT_NAME 
							FROM 
								SPECT_MAIN_ROW SMR,
								STOCKS S
							WHERE 
								S.STOCK_ID = SMR.STOCK_ID AND
								SPECT_MAIN_ID = #spect_main_id# AND 
								IS_PROPERTY = 0 --SADECE SARF ÜRÜNLER GELSİN
							ORDER BY
								SMR.LINE_NUMBER,
								S.PRODUCT_NAME			
						';
					_SubSqlQuery_ = cfquery(SQLString : _SubSqlStr_, Datasource : dsn3);
					_stock_id_arry_= '';
					for (_str_i_=1; _str_i_ lte _SubSqlQuery_.recordcount; _str_i_ = _str_i_+1)
					{
						_stock_id_arry_=listappend(_stock_id_arry_,_SubSqlQuery_.RELATED_ID[_str_i_],'█');
						_stock_id_arry_=listappend(_stock_id_arry_,_SubSqlQuery_.STOCK_ID[_str_i_],'§');
						_stock_id_arry_=listappend(_stock_id_arry_,_SubSqlQuery_.PRODUCT_NAME[_str_i_],'§');
						_stock_id_arry_=listappend(_stock_id_arry_,_SubSqlQuery_.IS_PRODUCTION[_str_i_],'§');
						_stock_id_arry_=listappend(_stock_id_arry_,_SubSqlQuery_.IS_CONFIGURE[_str_i_],'§');
					}
			</cfscript>
            <cfreturn _stock_id_arry_>
        </cffunction>
       
        <cfscript>
			if(not isdefined('configure_spec_name')) configure_spec_name ='';
			function GetProductConf(c_spect_main_id)
			{
				var i = 1;
				var _sub_products_ = _get_subs_(c_spect_main_id);
				for (i=1; i lte listlen(_sub_products_,'█'); i = i+1)
				{
					_c_spect_main_id_ = ListGetAt(ListGetAt(_sub_products_,i,'█'),1,'§');//alt+987 = █ --//alt+789 = §
					_c_stock_id_ = ListGetAt(ListGetAt(_sub_products_,i,'█'),2,'§');
					_c_product_name_ = ListGetAt(ListGetAt(_sub_products_,i,'█'),3,'§');
					_c_is_production_ = ListGetAt(ListGetAt(_sub_products_,i,'█'),4,'§');
					_c_is_configure_= ListGetAt(ListGetAt(_sub_products_,i,'█'),5,'§');
					if(_c_is_configure_ eq 1){
						//Ürün konfigüre ediliyorsa alternatifi varmı diye bakmamız lazım..
						Conf_SqlStr = 'SELECT TOP 1 AP.PRODUCT_ID FROM ALTERNATIVE_PRODUCTS AP,STOCKS S WHERE (S.PRODUCT_ID = AP.PRODUCT_ID OR S.PRODUCT_ID = AP.ALTERNATIVE_PRODUCT_ID) AND S.STOCK_ID =#_c_stock_id_#';
						Conf_SqlQuery = cfquery(SQLString : Conf_SqlStr, Datasource : dsn3);
						if(Conf_SqlQuery.recordcount)
							configure_spec_name = '#configure_spec_name#,#_c_product_name_#';
					}	
					if(_c_spect_main_id_ gt 0 and _c_is_production_ eq 1)
						GetProductConf(_c_spect_main_id_);
				 }
				 return  configure_spec_name;
			}
		</cfscript>
</cfcomponent>