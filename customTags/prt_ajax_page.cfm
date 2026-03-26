<cfparam  name="attributes.action" default="mal_giris.emptypopup_ajaxpage_giris_listesi">
<cfparam  name="attributes.id" default="1">
<cfoutput><div id="res_#attributes.id#"></div></cfoutput>
<cfoutput>
<script>
    $(document).ready(function(){
        $.ajax({
            url:"index.cfm?fuseaction=#attributes.action#",
            
        }).done(function(ret_dat){
            //console.log(ret_dat)
            $("##res_#attributes.id#").html(ret_dat)
        })
    })
</script>
</cfoutput>