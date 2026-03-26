
<cfquery name="getGeneralInfo" datasource="#dsn3#">
select OTSP.SHIP_ID,
O.ORDER_ID,
ORR.ORDER_ROW_ID,
S.STOCK_CODE,
S.STOCK_ID,
S.IS_INVENTORY,
S.PRODUCT_ID,
CP.PERIOD_YEAR,
CP.OUR_COMPANY_ID,
O.COMPANY_ID,
C.NICKNAME,
C.MEMBER_CODE,
S.PRODUCT_NAME,o.PARTNER_ID,CPP.COMPANY_PARTNER_NAME,CPP.COMPANY_PARTNER_SURNAME from catalyst_prod_1.ORDER_TO_SHIP_PRT as OTSP
LEFT JOIN catalyst_prod_1.ORDERS AS O ON O.ORDER_ID=OTSP.ORDER_ID
LEFT JOIN catalyst_prod.SETUP_PERIOD AS CP ON CP.PERIOD_ID=OTSP.PERIOD_ID
LEFT JOIN catalyst_prod_1.ORDER_ROW AS ORR ON ORR.ORDER_ID=O.ORDER_ID AND ORR.ORDER_ROW_ID=#attributes.order_row_id#
LEFT JOIN catalyst_prod_1.STOCKS AS S ON S.STOCK_ID=ORR.STOCK_ID
LEFT JOIN catalyst_prod.COMPANY AS C ON C.COMPANY_ID=O.COMPANY_ID
LEFT JOIN catalyst_prod.COMPANY_PARTNER AS CPP ON CPP.PARTNER_ID=O.PARTNER_ID
WHERE OTSP.ORDER_ID=(SELECT ORDER_ID FROM catalyst_prod_1.ORDER_ROW WHERE ORDER_ROW_ID=#attributes.order_row_id#)
</cfquery>

<div class="row">
<div  class="col" id="dv1">
<div class="row">
  <div class="col">
    <button class="btn btn-primary" onclick="OpenOperationPopup()">Operasyon</button>
    <button class="btn btn-success" onclick="Renk_Kaydet()">Renk Kaydet</button>
  </div>
</div>
<div class="row">
  <div class="col">
  <table class="table table-sm table-borderless">
  <tr>
  <td>K.Tarihi</td>
  <td><input type="date" name="cart_date" class="form-control form-control-sm" id="cart_date"></td>
  <td><div style="display:flex">Kartela
  
  <input type="text" name="cartlea" class="form-control form-control-sm" id="cartlea">
  <div class="form-check form-switch">
  <input class="form-check-input" type="checkbox" id="flexSwitchCheckDefault" value="1" >
  <label class="form-check-label" for="flexSwitchCheckDefault">Hazır</label>
</div></div></td>
  </tr>
  <tr>
  <td colspan="2">
  <table class="table table-sm table-borderless">
  <tr>
  <td>R.Tonu<input type="text" style="width:60px" id="Rtone" class="form-control form-control-sm"></td>
  <td>Boya C<input type="text" style="width:60px" class="form-control form-control-sm" id="paint_degree"></td>
  <td>Flote<input type="text" style="width:60px" class="form-control form-control-sm" id="flote"></td>
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
<cfoutput>
<input class="form-control" type="text" readonly name="company_code" id="company_code" value="#getGeneralInfo.MEMBER_CODE#">
<input class="form-control" type="text" readonly name="company_name" id="company_name" value="#getGeneralInfo.NICKNAME#">
<input type="hidden" readonly name="company_id" id="company_id" value="#getGeneralInfo.COMPANY_ID#">
<input type="hidden" readonly name="partner_id" id="partner_id" value="#getGeneralInfo.PARTNER_ID#">
<input class="form-control" type="text" readonly name="product_name" id="product_name" value="#getGeneralInfo.PRODUCT_NAME#">
<input type="hidden" readonly name="product_id" id="product_id" value="#getGeneralInfo.PRODUCT_ID#">
<input type="hidden" readonly name="stock_id" id="stock_id" value="#getGeneralInfo.STOCK_ID#">
<input type="hidden" readonly name="is_inventory" id="is_inventory" value="#getGeneralInfo.IS_INVENTORY#">
</cfoutput>

<div style="display:flex">
    <input style="width:17%" type="text" name="renk_code" id="color_code" placeholder="R.Kodu" class="form-control form-control-sm">
    <input type="text" name="renk_name" id="color_name" placeholder="Renk Adı" class="form-control form-control-sm">
</div>
<input type="text" class="form-control form-control-sm" placeholder="Açıklama" id="information">
</form>
</div>
</div>
<div class="row">
<div style="height:100vh" class="col" id="CurrentTree"></div>
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

