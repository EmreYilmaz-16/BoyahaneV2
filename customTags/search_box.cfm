<cfparam  name="attributes.is_detail" default="0">
<cfparam  name="attributes.is_collapsible" default="0">
<cfparam  name="attributes.title" default="">
<cfparam name="attributes.id" default="show_det">
<cfparam name="attributes.header" default="">
<style>
.panel {
    position: relative;
    width: 100%;
}
</style>
<cfif thisTag.executionMode eq "start">
<cfoutput>
  
  <div class="card">
  <div class="card-header">
    <h3 class="card-title" id="headingOne">  
      Müşteri Seç
    </h3>
  </div>
    <div id="collapseOne" class="card-body" aria-labelledby="headingOne" data-bs-parent="##accordionExample">     
 </cfoutput>
 <cfelse>
 <cfif attributes.is_detail eq 1>
<button class="button primary small" id="<cfoutput>#attributes.id#</cfoutput>">Daha Fazlası</button>
</cfif>
      
    </div>
  </div>
</cfif>
