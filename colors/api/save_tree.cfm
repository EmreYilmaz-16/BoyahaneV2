<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8">

<cfset JsonData = deserializeJSON(getHTTPRequestData().content)>


<cfquery name="getColorStok" datasource="boyahane">
    select stock_id from color_info WHERE color_id=<cfqueryparam value="#JsonData.color_id#" cfsqltype="cf_sql_integer">
</cfquery>
<cfquery name="delOldTree" datasource="boyahane">
    DELETE FROM product_tree WHERE stock_id=<cfqueryparam value="#getColorStok.stock_id#" cfsqltype="cf_sql_integer">
</cfquery>
<cfquery name="updColorInfo" datasource="boyahane">
    UPDATE color_info SET renk_tonu=<cfqueryparam value="#JsonData.renk_tonu#" cfsqltype="cf_sql_integer"> WHERE color_id=<cfqueryparam value="#JsonData.color_id#" cfsqltype="cf_sql_integer">
</cfquery>

<cftry>
    <cftransaction>
        <cfset op_ln = 1>
        <cfloop array="#JsonData.tree#" index="element">
            <cfquery name="saveTree" datasource="boyahane" result="res">
                INSERT INTO product_tree (stock_id, operation_type_id, operation_line_number, amount) VALUES (
                    <cfqueryparam value="#getColorStok.stock_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#element.operation_type_id#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="#op_ln#" cfsqltype="cf_sql_integer">,
                    <cfqueryparam value="1" cfsqltype="cf_sql_decimal">
                )
            </cfquery>
            <cfset op_ln = op_ln + 1>
            <cfloop array="#element.items#" index="subElement">
                <cfquery name="saveSubTree" datasource="boyahane">
                    INSERT INTO product_tree (stock_id, related_id, line_number, amount, related_product_tree_id) VALUES (
                        <cfqueryparam value="#getColorStok.stock_id#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#subElement.related_id#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#subElement.line_number#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#subElement.amount#" cfsqltype="cf_sql_decimal">,
                        <cfqueryparam value="#val(listFirst(res.generatedKey))#" cfsqltype="cf_sql_integer">
                    )
                </cfquery>
            </cfloop>
        </cfloop>
    </cftransaction>
    <cfoutput>#serializeJSON({"success": true})#</cfoutput>

    <cfcatch type="any">
        <cftransaction action="rollback" />
        <cfoutput>#serializeJSON({"success": false, "message": cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>

