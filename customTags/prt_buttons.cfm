
<cfparam  name="attributes.Update_Action" default="">
<cfparam  name="attributes.Update_Message" default="">
<cfparam  name="attributes.Add_Action" default="">
<cfparam  name="attributes.Add_Message" default="">
<cfparam  name="attributes.Delete_Action" default="">
<cfparam  name="attributes.Delete_Message" default="">
<cfquery name="isPerm" datasource="#caller.dsn#">
   SELECT * FROM catalyst_prod.USER_GROUP_OBJECT WHERE OBJECT_NAME='#caller.attributes.fuseaction#' AND USER_GROUP_ID=#session.ep.POWER_USER# 
</cfquery>

<cfoutput>

<div>
<cfif isPerm.recordcount>
    <cfif isPerm.ADD_OBJECT eq 0>
    <button type="button" onclick="btnAdd()"  class="btn btn-success btn-sm">Kaydet</button>
    </cfif>
    <cfif isPerm.UPDATE_OBJECT eq 0>
    <button type="button" onclick="btnUpdate()" class="btn btn-warning btn-sm">Güncelle</button>
    </cfif>
    <cfif isPerm.DELETE_OBJECT eq 0>
    <button type="button" onclick="btnDelete()" class="btn btn-danger btn-sm">Sil</button>
    </cfif>
    <cfelse>
    <button type="button" onclick="btnAdd()"  class="btn btn-success btn-sm">Kaydet</button>
    <button type="button" onclick="btnUpdate()" class="btn btn-warning btn-sm">Güncelle</button>
    <button type="button" onclick="btnDelete()" class="btn btn-danger btn-sm">Sil</button>
    </cfif>
</div>
<script>
function btnAdd(){
    var st=true;
    <cfif len(attributes.Add_Action)>
        <cfif len(attributes.Add_Message)>
            st=confirm('#attributes.Add_Message#');
        </cfif>
        if(st){
            #attributes.Add_Action#
        }
    </cfif>
}
function btnUpdate(){
    var st=true;
    <cfif len(attributes.Update_Action)>
        <cfif len(attributes.Update_Message)>
            st=confirm('#attributes.Update_Message#');
        </cfif>
        if(st){
            #attributes.Update_Action#
        }
    </cfif>
}
function btnDelete(){
    var st=true;
    <cfif len(attributes.Delete_Action)>
        <cfif len(attributes.Delete_Message)>
            st=confirm('#attributes.Delete_Message#');
        </cfif>
        if(st){
            #attributes.Delete_Action#
        }
    </cfif>
}
</script>

</cfoutput>
