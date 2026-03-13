<cfsetting enablecfoutputonly="true" showdebugoutput="false"><cfsilent>
<!--- Session kontrolü --->
<cfif not structKeyExists(session, "authenticated") or not session.authenticated>
    <cfcontent type="application/json" reset="true"><cfoutput>{"success": false, "message": "Oturum sonlanmış"}</cfoutput><cfabort>
</cfif>

<cfparam name="form.action" default="">

<!--- CFC'yi oluştur --->
<cfset menuService = createObject("component", "cfc.menuDesignerService")>

<!--- Parametreleri hazırla --->
<cfparam name="form.type" default="">
<cfparam name="form.id" default="0">
<cfparam name="form.itemType" default="">
<cfparam name="form.itemId" default="">
<cfparam name="form.itemName" default="">
<cfparam name="form.itemIcon" default="">
<cfparam name="form.orderNo" default="0">
<cfparam name="form.parentSelect" default="">
<cfparam name="form.showMenu" default="false">
<cfparam name="form.isActive" default="false">
<cfparam name="form.windowType" default="standart">
<cfparam name="form.fullFuseaction" default="">
<cfparam name="form.filePath" default="">
<cfparam name="form.orderData" default="[]">

<!--- Action'a göre CFC metodunu çağır --->
<cfswitch expression="#form.action#">
    <cfcase value="getMenu">
        <cfset result = menuService.getMenu()>
    </cfcase>
    <cfcase value="getItem">
        <cfset result = menuService.getItem(type=form.type, id=form.id)>
    </cfcase>
    <cfcase value="saveItem">
        <cfset result = menuService.saveItem(
            itemType=form.itemType,
            itemId=form.itemId,
            itemName=form.itemName,
            itemIcon=form.itemIcon,
            orderNo=form.orderNo,
            parentSelect=form.parentSelect,
            showMenu=form.showMenu,
            isActive=form.isActive,
            windowType=form.windowType,
            fullFuseaction=form.fullFuseaction,
            filePath=form.filePath
        )>
    </cfcase>
    <cfcase value="deleteItem">
        <cfset result = menuService.deleteItem(type=form.type, id=form.id)>
    </cfcase>
    <cfcase value="updateOrder">
        <cfset result = menuService.updateOrder(type=form.type, orderData=form.orderData)>
    </cfcase>
    <cfdefaultcase>
        <cfset result = {success=false, message="Geçersiz action parametresi"}>
    </cfdefaultcase>
</cfswitch>
</cfsilent><cfcontent type="application/json" reset="true"><cfoutput>#serializeJSON(result)#</cfoutput>
