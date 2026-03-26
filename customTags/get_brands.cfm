
<div class="input-group">
  <input type="text" name="brand" onkeydown="searchBrand(event,this)" id="brand" class="form-control" placeholder="Marka" aria-label="Marka">
  <input type="hidden" name="brand_id" id="brand_id">
  <button class="btn btn-outline-secondary" type="button" onclick="openModal_partner('index.cfm?fuseaction=emptypopup_get_brands_prt')"><i class="fas fa-ellipsis-v"></i></button>
</div>

<div class="modal fade" id="brand_modal_main" tabindex="-1" aria-labelledby="exampleModalLgLabel" aria-hidden="true">
  <div class="modal-dialog modal-dialog-scrollable modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title h4" id="exampleModalLgLabel">Large modal</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body" id="brand_modal">
        
      </div>
    </div>
  </div>
</div>
<script>
function searchBrand(ev,el){
  console.log(el)
  if(ev.keyCode==13){
    openModal_partner('index.cfm?fuseaction=emptypopup_get_brands_prt&keyword='+el.value)
  }
}

</script>