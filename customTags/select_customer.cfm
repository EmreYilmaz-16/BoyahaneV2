<cfparam name="on_company_select" default="">
<cfparam name="readonly" default="0">
<cfparam name="frm_name" default="">
<cfparam name="company_id" default="">
<cfparam name="partner_id" default="">
<cfparam name="company_code" default="">
<cfparam name="company_name" default="">
<div class="input-group">
    <cfoutput><input style="flex: 0 0 auto;width: 15%;" class="form-control form-control-sm" type="text" id="company_code" name="company_code" value="#company_code#" <cfif isDefined("attributes.readonly") and attributes.readonly eq 1>readonly</cfif>>
    <input oninput="getComp(this)" style="flex: 0 0 auto;width:75%" class="form-control form-control-sm" type="text" id="company_name" name="company_name" value="#company_name#" autocomplete="off" <cfif isDefined("attributes.readonly") and attributes.readonly eq 1>readonly</cfif>>
    <input type="hidden" id="company_id" name="company_id" value="#company_id#">
    <input type="hidden" id="partner_id" name="partner_id" value="#partner_id#"></cfoutput>
    <button type="button" style="width: 10%;font-size: 14pt;padding: 0" onclick="SelectCustomer()"
        class="btn btn-sm btn-outline-success" <cfif isDefined("attributes.readonly") and attributes.readonly eq 1>disabled</cfif>><i class="fas fa-users"></i></button>
    <div class="auto_complete" id="res_area"
        style="">
        <div style="border-bottom:solid 1px #dc3545;padding-left: 5px;padding-right: 5px;">
            Müşteriler <i style="float: right;font-size:14pt !important;margin-top: 2px;"
                class="far fa-times-circle cls_close"></i>
        </div>
        <table class="table table-sm table-bordered" id="tbl11">

        </table>
<script>
    function getComp(elem) {
        
        var kw = $(elem).val();
        $("#res_area").show(100)
        if (kw.length < 3) {
            $("#tbl11").html("")
        }
        if (kw.length > 3) {
            $.ajax({
                url: "/cfc/boyahane.cfc?method=getCompany&company_name=" + kw,
                success: function (retDat) {

                    var arr = Array.isArray(retDat) ? retDat : JSON.parse(retDat)
                    var arq = "";
                    console.log(retDat)
                    for (let i = 0; i < arr.length; i++) {


                        var as = "<a onclick='setComp(this)' data-pid='"+arr[i].PARTNER_ID+"' data-code='" + arr[i]
                            .COMPANY_CODE +
                            "' data-id='" + arr[i].COMPANY_ID + "' data-name='" +
                            arr[i].FULLNAME +"-"+arr[i].COMPANY_PARTNER+
                            "'>" + arr[i].FULLNAME +"-"+arr[i].COMPANY_PARTNER + "</a>"


                        arq += "<tr><td>" + arr[i].COMPANY_CODE + "</td><td>" + as +
                            "</td></tr>"
                    }
                    $("#tbl11").html(arq)
                }

            });
        }
    }
            function SelectCustomer(){
                <cfoutput>windowopen("index.cfm?fuseaction=objects.emptypopup_list_customer&frm_name=#attributes.frm_name#&id_area=company_id&name_area=company_name&code_area=company_code&onselect=#attributes.on_company_select#",'page')</cfoutput>
            }

            function setComp(elem) {
                console.log(elem)
                var cn = $(elem).data("name");
                var cc = $(elem).data("code");
                var cid = $(elem).data("id");
                var pid = $(elem).data("pid");
                $("#company_code").val(cc)
                $("#company_name").val(cn)
                $("#company_id").val(cid)
                $("#partner_id").val(pid)
                $("#res_area").hide(100)
            <cfif isDefined("attributes.on_company_select") and len(attributes.on_company_select)>
            <cfoutput>
            <cfloop list="#attributes.on_company_select#" item="i">
                #i#
            </cfloop>
            </cfoutput>
            </cfif>
            }
            
        </script>
    </div>
</div>