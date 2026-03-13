<cfcomponent output="false">
    
    <!--- Get complete menu hierarchy --->
    <cffunction name="getMenu" access="remote" returntype="struct" returnformat="json">
        <cfset var result = {}>
        <cfset var menuData = {}>
        <cfset var getSolutions = "">
        <cfset var getFamilies = "">
        <cfset var getModules = "">
        <cfset var getObjects = "">
        
        <cftry>
            <cfquery name="getSolutions" datasource="boyahane">
                SELECT * FROM pbs_solution
                WHERE is_active = true
                ORDER BY order_no, solution_id
            </cfquery>

            <cfset menuData.solutions = []>

            <cfloop query="getSolutions">
                <cfset var solution = {}>
                <cfset solution.solution_id = getSolutions.solution_id>
                <cfset solution.solution_name = getSolutions.solution_name>
                <cfset solution.icon = getSolutions.icon>
                <cfset solution.show_menu = getSolutions.show_menu>
                <cfset solution.is_active = getSolutions.is_active>
                <cfset solution.order_no = getSolutions.order_no>
                <cfset solution.families = []>

                <!--- Get Families for this Solution --->
                <cfquery name="getFamilies" datasource="boyahane">
                    SELECT * FROM pbs_family
                    WHERE solution_id = <cfqueryparam value="#getSolutions.solution_id#" cfsqltype="cf_sql_integer">
                    AND is_active = true
                    ORDER BY order_no, family_id
                </cfquery>

                <cfloop query="getFamilies">
                    <cfset var family = {}>
                    <cfset family.family_id = getFamilies.family_id>
                    <cfset family.family_name = getFamilies.family_name>
                    <cfset family.icon = getFamilies.icon>
                    <cfset family.show_menu = getFamilies.show_menu>
                    <cfset family.is_active = getFamilies.is_active>
                    <cfset family.order_no = getFamilies.order_no>
                    <cfset family.modules = []>

                    <!--- Get Modules for this Family --->
                    <cfquery name="getModules" datasource="boyahane">
                        SELECT * FROM pbs_module
                        WHERE family_id = <cfqueryparam value="#getFamilies.family_id#" cfsqltype="cf_sql_integer">
                        AND is_active = true
                        ORDER BY order_no, module_id
                    </cfquery>

                    <cfloop query="getModules">
                        <cfset var module = {}>
                        <cfset module.module_id = getModules.module_id>
                        <cfset module.module_name = getModules.module_name>
                        <cfset module.icon = getModules.icon>
                        <cfset module.show_menu = getModules.show_menu>
                        <cfset module.is_active = getModules.is_active>
                        <cfset module.order_no = getModules.order_no>
                        <cfset module.objects = []>

                        <!--- Get Objects for this Module --->
                        <cfquery name="getObjects" datasource="boyahane">
                            SELECT * FROM pbs_objects
                            WHERE module_id = <cfqueryparam value="#getModules.module_id#" cfsqltype="cf_sql_integer">
                            AND is_active = true
                            ORDER BY order_no, object_id
                        </cfquery>

                        <cfloop query="getObjects">
                            <cfset var obj = {}>
                            <cfset obj.object_id = getObjects.object_id>
                            <cfset obj.object_name = getObjects.object_name>
                            <cfset obj.icon = ""><!--- Objects don't have icons --->
                            <cfset obj.show_menu = getObjects.show_menu>
                            <cfset obj.is_active = getObjects.is_active>
                            <cfset obj.window_type = getObjects.window_type>
                            <cfset obj.full_fuseaction = getObjects.full_fuseaction>
                            <cfset obj.file_path = getObjects.file_path>
                            <cfset obj.order_no = getObjects.order_no>
                            <cfset arrayAppend(module.objects, obj)>
                        </cfloop>

                        <cfset arrayAppend(family.modules, module)>
                    </cfloop>

                    <cfset arrayAppend(solution.families, family)>
                </cfloop>

                <cfset arrayAppend(menuData.solutions, solution)>
            </cfloop>

            <cfset result.success = true>
            <cfset result.data = menuData>
            
            <cfcatch type="any">
                <cfset result.success = false>
                <cfset result.message = cfcatch.message>
                <cfset result.detail = cfcatch.detail>
            </cfcatch>
        </cftry>
        
        <cfreturn result>
    </cffunction>

    <!--- Get single item --->
    <cffunction name="getItem" access="remote" returntype="struct" returnformat="json">
        <cfargument name="type" type="string" required="true">
        <cfargument name="id" type="numeric" required="true">
        
        <cfset var result = {}>
        <cfset var getItem = "">
        
        <cftry>
            <cfswitch expression="#arguments.type#">
                <cfcase value="solution">
                    <cfquery name="getItem" datasource="boyahane">
                        SELECT solution_name as name, icon, show_menu, is_active, order_no
                        FROM pbs_solution
                        WHERE solution_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
                    </cfquery>
                </cfcase>
                <cfcase value="family">
                    <cfquery name="getItem" datasource="boyahane">
                        SELECT family_name as name, icon, show_menu, is_active, order_no, solution_id as parent_id
                        FROM pbs_family
                        WHERE family_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
                    </cfquery>
                </cfcase>
                <cfcase value="module">
                    <cfquery name="getItem" datasource="boyahane">
                        SELECT module_name as name, icon, show_menu, is_active, order_no, family_id as parent_id
                        FROM pbs_module
                        WHERE module_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
                    </cfquery>
                </cfcase>
                <cfcase value="object">
                    <cfquery name="getItem" datasource="boyahane">
                        SELECT object_name as name, show_menu, is_active, order_no, 
                               module_id as parent_id, window_type, full_fuseaction, file_path
                        FROM pbs_objects
                        WHERE object_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
                    </cfquery>
                </cfcase>
            </cfswitch>

            <cfif getItem.recordCount>
                <cfset var itemData = {}>
                <cfset itemData.name = getItem.name>
                <!--- Objects don't have icon column --->
                <cfif arguments.type neq "object">
                    <cfset itemData.icon = getItem.icon>
                <cfelse>
                    <cfset itemData.icon = "">
                </cfif>
                <cfset itemData.show_menu = getItem.show_menu>
                <cfset itemData.is_active = getItem.is_active>
                <cfset itemData.order_no = getItem.order_no>
                
                <cfif structKeyExists(getItem, "parent_id")>
                    <cfset itemData.parent_id = getItem.parent_id>
                </cfif>
                
                <cfif arguments.type eq "object">
                    <cfset itemData.window_type = getItem.window_type>
                    <cfset itemData.full_fuseaction = getItem.full_fuseaction>
                    <cfset itemData.file_path = getItem.file_path>
                </cfif>

                <cfset result.success = true>
                <cfset result.data = itemData>
            <cfelse>
                <cfset result.success = false>
                <cfset result.message = "Öğe bulunamadı">
            </cfif>
            
            <cfcatch type="any">
                <cfset result.success = false>
                <cfset result.message = cfcatch.message>
            </cfcatch>
        </cftry>
        
        <cfreturn result>
    </cffunction>

    <!--- Save item (insert or update) --->
    <cffunction name="saveItem" access="remote" returntype="struct" returnformat="json">
        <cfargument name="itemType" type="string" required="true">
        <cfargument name="itemId" type="string" required="false" default="">
        <cfargument name="itemName" type="string" required="true">
        <cfargument name="itemIcon" type="string" required="false" default="">
        <cfargument name="orderNo" type="numeric" required="false" default="0">
        <cfargument name="parentSelect" type="string" required="false" default="">
        <cfargument name="showMenu" type="string" required="false" default="false">
        <cfargument name="isActive" type="string" required="false" default="false">
        <cfargument name="windowType" type="string" required="false" default="standart">
        <cfargument name="fullFuseaction" type="string" required="false" default="">
        <cfargument name="filePath" type="string" required="false" default="">
        
        <cfset var result = {}>
        <cfset var message = "">
        <cfset var showMenuBool = (arguments.showMenu eq "on" or arguments.showMenu eq "true")>
        <cfset var isActiveBool = (arguments.isActive eq "on" or arguments.isActive eq "true")>
        
        <cftry>
            <cfswitch expression="#arguments.itemType#">
                <cfcase value="solution">
                    <cfif len(trim(arguments.itemId))>
                        <!--- Update --->
                        <cfquery datasource="boyahane">
                            UPDATE pbs_solution SET
                                solution_name = <cfqueryparam value="#trim(arguments.itemName)#" cfsqltype="cf_sql_varchar">,
                                icon = <cfqueryparam value="#trim(arguments.itemIcon)#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.itemIcon)) eq 0#">,
                                show_menu = <cfqueryparam value="#showMenuBool#" cfsqltype="cf_sql_bit">,
                                is_active = <cfqueryparam value="#isActiveBool#" cfsqltype="cf_sql_bit">,
                                order_no = <cfqueryparam value="#arguments.orderNo#" cfsqltype="cf_sql_integer">
                            WHERE solution_id = <cfqueryparam value="#arguments.itemId#" cfsqltype="cf_sql_integer">
                        </cfquery>
                        <cfset message = "Solution güncellendi">
                    <cfelse>
                        <!--- Insert --->
                        <cfquery datasource="boyahane">
                            INSERT INTO pbs_solution (solution_name, icon, show_menu, is_active, order_no)
                            VALUES (
                                <cfqueryparam value="#trim(arguments.itemName)#" cfsqltype="cf_sql_varchar">,
                                <cfqueryparam value="#trim(arguments.itemIcon)#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.itemIcon)) eq 0#">,
                                <cfqueryparam value="#showMenuBool#" cfsqltype="cf_sql_bit">,
                                <cfqueryparam value="#isActiveBool#" cfsqltype="cf_sql_bit">,
                                <cfqueryparam value="#arguments.orderNo#" cfsqltype="cf_sql_integer">
                            )
                        </cfquery>
                        <cfset message = "Solution eklendi">
                    </cfif>
                </cfcase>

                <cfcase value="family">
                    <cfif len(trim(arguments.itemId))>
                        <!--- Update --->
                        <cfquery datasource="boyahane">
                            UPDATE pbs_family SET
                                family_name = <cfqueryparam value="#trim(arguments.itemName)#" cfsqltype="cf_sql_varchar">,
                                icon = <cfqueryparam value="#trim(arguments.itemIcon)#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.itemIcon)) eq 0#">,
                                show_menu = <cfqueryparam value="#showMenuBool#" cfsqltype="cf_sql_bit">,
                                is_active = <cfqueryparam value="#isActiveBool#" cfsqltype="cf_sql_bit">,
                                order_no = <cfqueryparam value="#arguments.orderNo#" cfsqltype="cf_sql_integer">
                            WHERE family_id = <cfqueryparam value="#arguments.itemId#" cfsqltype="cf_sql_integer">
                        </cfquery>
                        <cfset message = "Family güncellendi">
                    <cfelse>
                        <!--- Insert --->
                        <cfquery datasource="boyahane">
                            INSERT INTO pbs_family (family_name, solution_id, icon, show_menu, is_active, order_no)
                            VALUES (
                                <cfqueryparam value="#trim(arguments.itemName)#" cfsqltype="cf_sql_varchar">,
                                <cfqueryparam value="#arguments.parentSelect#" cfsqltype="cf_sql_integer">,
                                <cfqueryparam value="#trim(arguments.itemIcon)#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.itemIcon)) eq 0#">,
                                <cfqueryparam value="#showMenuBool#" cfsqltype="cf_sql_bit">,
                                <cfqueryparam value="#isActiveBool#" cfsqltype="cf_sql_bit">,
                                <cfqueryparam value="#arguments.orderNo#" cfsqltype="cf_sql_integer">
                            )
                        </cfquery>
                        <cfset message = "Family eklendi">
                    </cfif>
                </cfcase>

                <cfcase value="module">
                    <cfif len(trim(arguments.itemId))>
                        <!--- Update --->
                        <cfquery datasource="boyahane">
                            UPDATE pbs_module SET
                                module_name = <cfqueryparam value="#trim(arguments.itemName)#" cfsqltype="cf_sql_varchar">,
                                icon = <cfqueryparam value="#trim(arguments.itemIcon)#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.itemIcon)) eq 0#">,
                                show_menu = <cfqueryparam value="#showMenuBool#" cfsqltype="cf_sql_bit">,
                                is_active = <cfqueryparam value="#isActiveBool#" cfsqltype="cf_sql_bit">,
                                order_no = <cfqueryparam value="#arguments.orderNo#" cfsqltype="cf_sql_integer">
                            WHERE module_id = <cfqueryparam value="#arguments.itemId#" cfsqltype="cf_sql_integer">
                        </cfquery>
                        <cfset message = "Module güncellendi">
                    <cfelse>
                        <!--- Insert --->
                        <cfquery datasource="boyahane">
                            INSERT INTO pbs_module (module_name, family_id, icon, show_menu, is_active, order_no)
                            VALUES (
                                <cfqueryparam value="#trim(arguments.itemName)#" cfsqltype="cf_sql_varchar">,
                                <cfqueryparam value="#arguments.parentSelect#" cfsqltype="cf_sql_integer">,
                                <cfqueryparam value="#trim(arguments.itemIcon)#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.itemIcon)) eq 0#">,
                                <cfqueryparam value="#showMenuBool#" cfsqltype="cf_sql_bit">,
                                <cfqueryparam value="#isActiveBool#" cfsqltype="cf_sql_bit">,
                                <cfqueryparam value="#arguments.orderNo#" cfsqltype="cf_sql_integer">
                            )
                        </cfquery>
                        <cfset message = "Module eklendi">
                    </cfif>
                </cfcase>

                <cfcase value="object">
                    <cfif len(trim(arguments.itemId))>
                        <!--- Update --->
                        <cfquery datasource="boyahane">
                            UPDATE pbs_objects SET
                                object_name = <cfqueryparam value="#trim(arguments.itemName)#" cfsqltype="cf_sql_varchar">,
                                show_menu = <cfqueryparam value="#showMenuBool#" cfsqltype="cf_sql_bit">,
                                is_active = <cfqueryparam value="#isActiveBool#" cfsqltype="cf_sql_bit">,
                                window_type = <cfqueryparam value="#arguments.windowType#" cfsqltype="cf_sql_varchar">,
                                full_fuseaction = <cfqueryparam value="#trim(arguments.fullFuseaction)#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.fullFuseaction)) eq 0#">,
                                file_path = <cfqueryparam value="#trim(arguments.filePath)#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.filePath)) eq 0#">,
                                order_no = <cfqueryparam value="#arguments.orderNo#" cfsqltype="cf_sql_integer">
                            WHERE object_id = <cfqueryparam value="#arguments.itemId#" cfsqltype="cf_sql_integer">
                        </cfquery>
                        <cfset message = "Object güncellendi">
                    <cfelse>
                        <!--- Insert --->
                        <cfquery datasource="boyahane">
                            INSERT INTO pbs_objects (object_name, module_id, show_menu, is_active, window_type, full_fuseaction, file_path, order_no)
                            VALUES (
                                <cfqueryparam value="#trim(arguments.itemName)#" cfsqltype="cf_sql_varchar">,
                                <cfqueryparam value="#arguments.parentSelect#" cfsqltype="cf_sql_integer">,
                                <cfqueryparam value="#showMenuBool#" cfsqltype="cf_sql_bit">,
                                <cfqueryparam value="#isActiveBool#" cfsqltype="cf_sql_bit">,
                                <cfqueryparam value="#arguments.windowType#" cfsqltype="cf_sql_varchar">,
                                <cfqueryparam value="#trim(arguments.fullFuseaction)#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.fullFuseaction)) eq 0#">,
                                <cfqueryparam value="#trim(arguments.filePath)#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.filePath)) eq 0#">,
                                <cfqueryparam value="#arguments.orderNo#" cfsqltype="cf_sql_integer">
                            )
                        </cfquery>
                        <cfset message = "Object eklendi">
                    </cfif>
                </cfcase>
            </cfswitch>

            <cfset result.success = true>
            <cfset result.message = message>
            
            <cfcatch type="any">
                <cfset result.success = false>
                <cfset result.message = cfcatch.message>
            </cfcatch>
        </cftry>
        
        <cfreturn result>
    </cffunction>

    <!--- Delete item --->
    <cffunction name="deleteItem" access="remote" returntype="struct" returnformat="json">
        <cfargument name="type" type="string" required="true">
        <cfargument name="id" type="numeric" required="true">
        
        <cfset var result = {}>
        <cfset var message = "">
        
        <cftry>
            <cfswitch expression="#arguments.type#">
                <cfcase value="solution">
                    <cfquery datasource="boyahane">
                        DELETE FROM pbs_solution
                        WHERE solution_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
                    </cfquery>
                    <cfset message = "Solution silindi">
                </cfcase>
                <cfcase value="family">
                    <cfquery datasource="boyahane">
                        DELETE FROM pbs_family
                        WHERE family_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
                    </cfquery>
                    <cfset message = "Family silindi">
                </cfcase>
                <cfcase value="module">
                    <cfquery datasource="boyahane">
                        DELETE FROM pbs_module
                        WHERE module_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
                    </cfquery>
                    <cfset message = "Module silindi">
                </cfcase>
                <cfcase value="object">
                    <cfquery datasource="boyahane">
                        DELETE FROM pbs_objects
                        WHERE object_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
                    </cfquery>
                    <cfset message = "Object silindi">
                </cfcase>
            </cfswitch>

            <cfset result.success = true>
            <cfset result.message = message>
            
            <cfcatch type="any">
                <cfset result.success = false>
                <cfset result.message = cfcatch.message>
            </cfcatch>
        </cftry>
        
        <cfreturn result>
    </cffunction>

    <!--- Update order --->
    <cffunction name="updateOrder" access="remote" returntype="struct" returnformat="json">
        <cfargument name="type" type="string" required="true">
        <cfargument name="orderData" type="string" required="true">
        
        <cfset var result = {}>
        <cfset var orderArray = deserializeJSON(arguments.orderData)>
        
        <cftry>
            <cfswitch expression="#arguments.type#">
                <cfcase value="solution">
                    <cfloop array="#orderArray#" index="item">
                        <cfquery datasource="boyahane">
                            UPDATE pbs_solution
                            SET order_no = <cfqueryparam value="#item.order_no#" cfsqltype="cf_sql_integer">
                            WHERE solution_id = <cfqueryparam value="#item.id#" cfsqltype="cf_sql_integer">
                        </cfquery>
                    </cfloop>
                </cfcase>
                <cfcase value="family">
                    <cfloop array="#orderArray#" index="item">
                        <cfquery datasource="boyahane">
                            UPDATE pbs_family
                            SET order_no = <cfqueryparam value="#item.order_no#" cfsqltype="cf_sql_integer">
                            WHERE family_id = <cfqueryparam value="#item.id#" cfsqltype="cf_sql_integer">
                        </cfquery>
                    </cfloop>
                </cfcase>
                <cfcase value="module">
                    <cfloop array="#orderArray#" index="item">
                        <cfquery datasource="boyahane">
                            UPDATE pbs_module
                            SET order_no = <cfqueryparam value="#item.order_no#" cfsqltype="cf_sql_integer">
                            WHERE module_id = <cfqueryparam value="#item.id#" cfsqltype="cf_sql_integer">
                        </cfquery>
                    </cfloop>
                </cfcase>
                <cfcase value="object">
                    <cfloop array="#orderArray#" index="item">
                        <cfquery datasource="boyahane">
                            UPDATE pbs_objects
                            SET order_no = <cfqueryparam value="#item.order_no#" cfsqltype="cf_sql_integer">
                            WHERE object_id = <cfqueryparam value="#item.id#" cfsqltype="cf_sql_integer">
                        </cfquery>
                    </cfloop>
                </cfcase>
            </cfswitch>

            <cfset result.success = true>
            <cfset result.message = "Sıralama güncellendi">
            
            <cfcatch type="any">
                <cfset result.success = false>
                <cfset result.message = cfcatch.message>
            </cfcatch>
        </cftry>
        
        <cfreturn result>
    </cffunction>

</cfcomponent>
