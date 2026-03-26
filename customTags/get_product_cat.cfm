<div class="input-group">
<span class="input-group-text">Kumaş Tipi</span>
    <input class="form-control form-control-sm" oninput="getCat(this)" type="text" name="product_cat" id="cat" <cfif isDefined("attributes.readonly") and attributes.readonly eq 1>readonly</cfif>>
  <cfif isDefined("attributes.readonly") and attributes.readonly eq 1><cfelse>  <span class="input-group-text"><i onclick="$('#cats_res').toggle(100)" class="fas fa-chevron-down"></i></span></cfif>
    <input type="hidden" name="HIERARCHY" id="HIERARCHY">
    <input type="hidden" name="PRODUCT_CAT" id="PRODUCT_CAT">
    <input type="hidden" name="PRODUCT_CATID" id="PRODUCT_CATID">
    <input type="hidden" name="is_inventory" id="is_inventory">
    <div id="cats_res" class="auto_complete">
        <div style="border-bottom:solid 1px #dc3545;padding-left: 5px;padding-right: 5px;padding-bottom:2px">
            Kumaş Tipi <i style="float: right;font-size:14pt !important;margin-top: 2px;margin-bottom:1px"
                class="far fa-times-circle cls_close"></i>
        </div>
        <table class="table table-sm table-bordered" id="tbl_cat">

        </table>
    </div>
</div>
<script>
    function getCat(el) {

        $("#cats_res").show(100)
        $("#tbl_cat").html("")
        $.ajax({
            url: "/cfc/boyahane.cfc?method=get_product_Cat&keyword=" + el.value,
            success: function (retData) {
                var arr = JSON.parse(retData);
                var axxxx="";
                for(let i=0;i<arr.length;i++){
                    axxxx+="<tr><td>"+arr[i].HIERARCHY+"</td><td><a onclick='selectKumas(this)' data-inv='"+arr[i].HIERARCHY+"' data-sid='"+arr[i].PRODUCT_CATID+"' >"+arr[i].PRODUCT_CAT+"</a></td></tr>"
                }

                $("#tbl_cat").html(axxxx)
            }

        });
    }

    function selectKumas(elem){      
      var hiearchy=$(elem).data("inv");
      var cat_id=$(elem).data("sid");
      var cat =$(elem).text()     
      $("#HIERARCHY").val(hiearchy)
      $("#PRODUCT_CAT").val(cat)
      $("#PRODUCT_CATID").val(cat_id)
      $("#cat").val(cat)
        $("#cats_res").hide(100)        
        
        <cfif isDefined("attributes.on_select") and len(attributes.on_select)>
        <cfoutput>
            #attributes.on_select#
        </cfoutput>
        </cfif>

    }
   


    jQuery.expr[':'].icontains = function (a, i, m) {
        return jQuery(a).text().toUpperCase()
            .indexOf(m[3].toUpperCase()) >= 0;
    };
</script>