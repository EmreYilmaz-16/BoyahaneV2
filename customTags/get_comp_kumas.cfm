<cfparam name="product_id" default="">
<cfparam name="product_name" default="">
<cfparam name="stock_id" default="">
<cfparam name="is_inventory" default="">
<cfoutput>
<div class="input-group">
    <input class="form-control form-control-sm" oninput="search(this)" type="text" name="product_name" id="kumas" value="#product_name#" <cfif isDefined("attributes.readonly") and attributes.readonly eq 1>readonly</cfif>>
  <cfif isDefined("attributes.readonly") and attributes.readonly eq 1><cfelse>  <span class="input-group-text"><i onclick="getKumas()" class="fas fa-chevron-down"></i></span></cfif>
    <input type="hidden" name="product_id" id="product_id"  value="#product_id#">
    <input type="hidden" name="stock_id" id="stock_id" value="#stock_id#">
    <input type="hidden" name="is_inventory" id="is_inventory" value="#is_inventory#">
    <div id="kumas_res" class="auto_complete">
        <div style="border-bottom:solid 1px ##dc3545;padding-left: 5px;padding-right: 5px;padding-bottom:2px;color:##dc3545">
            Kumaşlar <i style="float: right;font-size:14pt !important;margin-top: 2px;margin-bottom:1px"
                class="far fa-times-circle cls_close"></i>
        </div>
        <table class="table  table-hover table-sm" data-id="EmreEmre">
            <tbody  id="tbl_kumas"></tbody>
        </table>
    </div>
</div>
</cfoutput>
<script>
    function getKumas() {
        var comp_id=$("#company_id").val()
        console.log(comp_id)
        $("#kumas_res").show(100)
        $("#tbl_kumas").html("")
        $.ajax({
            url: "/cfc/boyahane.cfc?method=get_comp_kumas&company_id=" + comp_id,
            success: function (retData) {
                var arr = Array.isArray(retData) ? retData : JSON.parse(retData);
                var axxxx="";
                for(let i=0;i<arr.length;i++){
                    axxxx+="<tr><td>"+arr[i].PRODUCT_CODE+"</td><td><a onclick='selectKumas(this)' data-inv='"+arr[i].IS_INVENTORY+"' data-sid='"+arr[i].STOCK_ID+"' data-pid='"+arr[i].PRODUCT_ID+"'>"+arr[i].PRODUCT_NAME+"</a></td></tr>"
                }

                $("#tbl_kumas").html(axxxx)
                //$('#kumas_res').toggle(100)
            }

        });
    }

    function search(elem) {
        var kw = $(elem).val()
        
        $("#kumas_res").show(100)
        $("#tbl_kumas").children().hide()
        $("#tbl_kumas").children().filter(":icontains(" + kw + ")").show()
        
    }
    function selectKumas(elem){
        var sid = $(elem).data("sid");
        var pid = $(elem).data("pid");
        var inv = $(elem).data("inv");
        var pname = $(elem).text();
        console.log(elem)
        $("#stock_id").val(sid)
        $("#is_inventory").val(inv)
        $("#product_id").val(pid)
        $("#kumas").val(pname)
        $("#kumas_res").hide(100)        
    }
    jQuery.expr[':'].icontains = function (a, i, m) {
        return jQuery(a).text().toUpperCase()
            .indexOf(m[3].toUpperCase()) >= 0;
    };
</script>