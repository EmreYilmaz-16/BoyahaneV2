<cfparam name="attributes.id" default="show_det">
<cfif thisTag.executionMode eq "start">
<div class="pos-relative">
    <div class="bg-red fg-white"
            data-role="dropdown"
            data-toggle-element="#<cfoutput>#attributes.id#</cfoutput>">
 <cfelse>   
    </div>
</div>
</cfif>