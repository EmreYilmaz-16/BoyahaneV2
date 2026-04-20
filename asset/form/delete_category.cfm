<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cftry>
    <cfset catId = isDefined("form.category_id") and isNumeric(form.category_id) ? val(form.category_id) : 0>

    <cfif catId lte 0>
        <cfoutput>{"success":false,"message":"Geçersiz kategori."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Check if any assets use this category --->
    <cfquery name="chkAssets" datasource="boyahane">
        SELECT COUNT(*) AS cnt FROM asset_master
        WHERE category_id = <cfqueryparam value="#catId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif chkAssets.cnt gt 0>
        <cfoutput>{"success":false,"message":"Bu kategoriye bağlı #chkAssets.cnt# varlık var. Silinemez; önce varlıkları başka kategoriye taşıyın."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Check if any sub-categories reference this as parent --->
    <cfquery name="chkChildren" datasource="boyahane">
        SELECT COUNT(*) AS cnt FROM asset_categories
        WHERE parent_id = <cfqueryparam value="#catId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfif chkChildren.cnt gt 0>
        <cfoutput>{"success":false,"message":"Bu kategorinin #chkChildren.cnt# alt kategorisi var. Önce alt kategorileri silin veya taşıyın."}</cfoutput>
        <cfabort>
    </cfif>

    <cfquery datasource="boyahane">
        DELETE FROM asset_categories
        WHERE category_id = <cfqueryparam value="#catId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>{"success":true}</cfoutput>

    <cfcatch type="any">
        <cfoutput>{"success":false,"message":#serializeJSON(cfcatch.message)#}</cfoutput>
    </cfcatch>
</cftry>
