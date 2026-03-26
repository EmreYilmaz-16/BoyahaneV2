<cfdump  var="#attributes#">
<cfset dsn3="#dsn#_1">
<cfquery name="getTree" datasource="#dsn3#">
    select PT.LINE_NUMBER,S.PRODUCT_NAME,S.STOCK_ID,PT.DETAIL,PT.AMOUNT from PRODUCT_TREE as PT 
    LEFT JOIN STOCKS AS S ON S.STOCK_ID=PT.RELATED_ID
    WHERE  PT.STOCK_ID =#attributes.stock_id#
    ORDER BY LINE_NUMBER
</cfquery>
<cfquery name="getStokInfo" datasource="#dsn3#">
    SELECT * FROM STOCKS AS S 
    LEFT JOIN #dsn#.COMPANY AS C ON S.COMPANY_ID=C.COMPANY_ID
    LEFT JOIN PRTOTM_STOCK_INFO_PLUS AS SIP ON SIP.STOCK_ID=S.STOCK_ID
    where S.STOCK_ID =#ATTRIBUTES.STOCK_ID#
</cfquery>
<cfdump  var="#getStokInfo#">
<cfscript>
    TREEQ=queryNew("AMOUNT,MAIN_STOCK,MAIN_ORDER,LINE_ORDER,PRODUCT_NAME,STOCK_ID","Decimal,INTEGER,INTEGER,INTEGER,VARCHAR,INTEGER");
</cfscript>

<CFLOOP query="getTree">
    <cfscript >
        ITEM=structNew();
        ITEM.AMOUNT=AMOUNT;
        ITEM.MAIN_STOCK=listGetAt(DETAIL, 2,"-");
        ITEM.MAIN_ORDER=listGetAt(DETAIL, 1,"-");
        ITEM.LINE_ORDER=LINE_NUMBER;
        ITEM.PRODUCT_NAME=PRODUCT_NAME;
        ITEM.STOCK_ID=STOCK_ID;
        queryAddRow(TREEQ,ITEM);
    </cfscript>
</CFLOOP>

<cfloop query="TREEQ" group="MAIN_STOCK">
    <cfdump  var="#MAIN_STOCK#">
    <cfquery name="getStok" datasource="#dsn3#">
        select * from STOCKS where STOCK_ID=#MAIN_STOCK#
    </cfquery>
    <cfdump  var="#getStok.PRODUCT_NAME#"><br>
    <cfloop>
        <cfdump  var="#PRODUCT_NAME#"><br>
    </cfloop>
</cfloop>

<cfdump  var="#TREEQ#">
<cfoutput>
<div class="row">
<div  class="col" id="dv1">
<div class="row">
  <div class="col">
    <button class="btn btn-primary" onclick="OpenOperationPopup()">Operasyon</button>
    <button class="btn btn-success" onclick="SaveTree()">Renk Kaydet</button>
  </div>
</div>
<div class="row">
  <div class="col">
  <table class="table table-sm table-borderless">
  <tr>
  <td>K.Tarihi</td>
  <td><input type="date" name="cart_date" class="form-control form-control-sm" id="cart_date" value="#getStokInfo.PROPERTY5#"></td>
  <td><div style="display:flex">Kartela
  
  <input type="text" name="cartlea" class="form-control form-control-sm" id="cartlea" value="#getStokInfo.PROPERTY4#">
  <div class="form-check form-switch">
  <input class="form-check-input" type="checkbox" id="flexSwitchCheckDefault" <cfif getStokInfo.PROPERTY6  eq 1>checked</cfif> value="1" >
  <label class="form-check-label" for="flexSwitchCheckDefault">Hazır</label>
</div></div></td>
  </tr>
  <tr>
  <td colspan="2">
  <table class="table table-sm table-borderless">
  <tr>
  <td>R.Tonu<input type="text" style="width:60px" id="Rtone" class="form-control form-control-sm" value="#getStokInfo.PROPERTY1#"></td>
  <td>Boya C<input type="text" style="width:60px" class="form-control form-control-sm" id="paint_degree" value="#getStokInfo.PROPERTY2#"></td>
  <td>Flote<input type="text" style="width:60px" class="form-control form-control-sm" id="flote" value="#getStokInfo.PROPERTY3#"></td>
  </tr>
  </table>
  </td>
  </tr>
  </table>
  
  </div>
</div>
</div>
<div class="col">
<form name="forum1">
<cf_select_customer frm_name="forum1" on_company_select="getKumas()" readonly="0">
<cf_get_comp_kumas frm_name="forum1" on_company_select="bos()" readonly="0">
<div style="display:flex"><input style="width:17%" type="text" name="renk_code" id="color_code" placeholder="R.Kodu" class="form-control form-control-sm"><input type="text" name="renk_name" id="color_name" placeholder="Renk Adı" class="form-control form-control-sm"></div>
<input type="text" class="form-control form-control-sm" placeholder="Açıklama" id="information">
</cfoutput>
</form>
</div>
</div>
<div class="row">
<div style="height:100vh" class="col" id="CurrentTree">
<cfset Row=0>
<cfoutput>
<cfloop query="TREEQ" group="MAIN_STOCK">
    <ul class="list-group">
    <li data-id="#MAIN_STOCK#" data-parent="#Row#" class="list-group-item"> 
    <input type="text" id="line_order_#row#_#MAIN_STOCK#" value="#Row#">        
    <cfquery name="getStok" datasource="#dsn3#">
        select * from STOCKS where STOCK_ID=#MAIN_STOCK#
    </cfquery>
    #getStok.PRODUCT_NAME#
    <button style="float:right" class="btn btn-sm btn-warning" onclick="remProd(this,#MAIN_STOCK#,#Row#)">-</button>
    <button style="float:right" class="btn btn-sm btn-primary" onclick="OpenProductpopup(#MAIN_STOCK#,#Row#)">+</button>
    <cfdump  var="#getStok.PRODUCT_NAME#"><br>
    <ul class="urun_agac_liste" style="margin-top:15px" id="urun_#Row#_#MAIN_STOCK#">
    <cfloop>
    <li style="margin-top:5px" data-id="#STOCK_ID#" data-parent="#MAIN_STOCK#">
       <div style="display:flex">
            <input type="text" style="width:25px" id="line_order_#Row#_#MAIN_STOCK#" value="#LINE_ORDER#">#PRODUCT_NAME#
            <button style="float:right; margin-inline-start: auto" class="btn btn-sm btn-danger" onclick="reminner(this,#MAIN_STOCK#,#row#)">-</button>
            <input type="number" class="form-control form-control-sm RT_" onchange="RenkHesapla()" style="width:70px" id="amount_#row#_#STOCK_ID#" value="#AMOUNT#">
       </div>
    </li>
    </cfloop>
    <cfset Row=Row+1>
</cfloop>
</cfoutput>
</div>
</div>

<div class="modal fade" id="exampleModalScrollable" tabindex="-1" aria-labelledby="exampleModalScrollableTitle" style="display: none;" aria-hidden="true">
  <div class="modal-dialog modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="exampleModalScrollableTitle">Modal title</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <table class="table">
        <tr>
            <td>
                <input type="text" class="form-control form-control-sm" id="Modkeyword" placeholder="Keyword">
            </td>
            <td>
            <button class="btn btn-succes btn-sm" onclick="SearchProd()">Ara</button>
            </td>
        </tr>
        </table>
        <div id="Div_1">        
        </div>
      </div>

    </div>
  </div>
</div>

<div class="modal fade" id="exampleModalScrollable_1" tabindex="-1" aria-labelledby="exampleModalScrollableTitle" style="display: none;" aria-hidden="true">
  <div class="modal-dialog modal-dialog-scrollable">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="exampleModalScrollableTitle">Renk Ekle</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">
        <table class="table">
        <tr>
            <td>
                <input type="text" class="form-control form-control-sm" id="Prokeyword" placeholder="Keyword">
                <input type="hidden" id="tx_1">
                <input type="hidden" id="rowx_1">
            </td>
            <td>
            <button class="btn btn-succes btn-sm" onclick="SearchProd_2()">Ara</button>
            </td>
        </tr>
        </table>
        <div id="Div_1_PROD"></div>
      </div>

    </div>
  </div>
</div>

<script>
    <cfinclude  template="agac_func.js">
</script>
