
<cfquery name="getOrderRow" datasource="#dsn3#">
    SELECT PRODUCT_NAME,ORDER_ID,QUANTITY,ORDER_ROW_ID 
    FROM ORDER_ROW WHERE ORDER_ID =(select ORDER_ID from ORDER_ROW where ORDER_ROW_ID=#attributes.key#)
</cfquery>

<cfquery name="getInfoPlus" datasource="#dsn3#">
SELECT * FROM ORDER_INFO_PLUS where  ORDER_ID=#getOrderRow.ORDER_ID#
</cfquery>
<cfquery name="getPer" datasource="#dsn#">
    SELECT * FROM SETUP_PERIOD WHERE PERIOD_ID=#attributes.att_period_id#
</cfquery>
<cfquery name="getShiprow" datasource="#dsn#">
    SELECT * FROM #DSN#_#getPer.PERIOD_YEAR#_#getPer.OUR_COMPANY_ID#.SHIP_ROW WHERE SHIP_ID=#attributes.att_ship_id#
</cfquery>
<cfquery name="getColors"datasource="#dsn3#">
    SELECT * FROM STOCKS 
    WHERE PRODUCT_ID=#getShiprow.PRODUCT_ID# and (IS_MAIN_STOCK=0 or IS_MAIN_STOCK IS NULL)
</cfquery>

<table class="table">
<tr>
<td><b>Renk :</b> <cfoutput>#getInfoPlus.PROPERTY15#</cfoutput></td>
<td><b>Kartela T :</b> <cfoutput>#dateformat(getInfoPlus.PROPERTY1,"dd/mm/yyyy")#</cfoutput></td>
<td><b>Kartela :</b> <cfoutput>#getInfoPlus.PROPERTY2#</cfoutput></td>
</tr>
<tr><td colspan="3">
<select class="form-select" id="sl1" onchange="changecolorRow(this)"> 
<option value="">Seçiniz</option>
<cfoutput query="getColors">
<option value="#STOCK_ID#">#STOCK_CODE_2#- #PROPERTY#</option>
</cfoutput>
</select>
</td>
</tr>
</table>
<cfoutput>

<script>
    function changecolorRow(el){
        var e=el.value;
        
        if(e.length){
        windowopen("index.cfm?fuseaction=mal_giris.emptypopup_ajaxpage_upd_party_query&kayit_area=#DSN#_#getPer.PERIOD_YEAR#_#getPer.OUR_COMPANY_ID#&QUANTITY=#getOrderRow.QUANTITY#&order_id=#getOrderRow.ORDER_ID#&order_row_id=#attributes.key#&ekstoka="+e)}
    }
</script>
</cfoutput>


<!-----









----->