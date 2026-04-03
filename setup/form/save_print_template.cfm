<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cfset response = { "success": false, "message": "" }>

<cftry>
    <cfparam name="form.form_id"      default="0">
    <cfparam name="form.name"         default="">
    <cfparam name="form.process_type" default="0">
    <cfparam name="form.detail"       default="">
    <cfparam name="form.active"       default="false">
    <cfparam name="form.is_default"   default="false">
    <cfparam name="form.is_standart"  default="true">

    <cfset formId      = val(form.form_id)>
    <cfset tplName     = trim(form.name)>
    <cfset processType = val(form.process_type)>
    <cfset tplDetail   = trim(form.detail)>
    <cfset isActive    = (form.active     eq "true")>
    <cfset isDefault   = (form.is_default eq "true")>
    <cfset isStandart  = (form.is_standart eq "true")>
    <cfset editMode    = (formId GT 0)>

    <cfif len(tplName) EQ 0>
        <cfset response.message = "Şablon adı zorunludur.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>
    <cfif processType EQ 0>
        <cfset response.message = "Belge kategorisi seçilmelidir.">
        <cfoutput>#serializeJSON(response)#</cfoutput>
        <cfabort>
    </cfif>

    <!--- CFM dosyası yükleme --->
    <cfset uploadedFileName = "">
    <cfset uploadDir = expandPath("/documents/print_files/")>

    <!--- Klasör yoksa oluştur --->
    <cfif NOT directoryExists(uploadDir)>
        <cfdirectory action="create" directory="#uploadDir#" recurse="true">
    </cfif>

    <cftry>
        <cffile action="upload"
                fileField="template_cfm_file"
                destination="#uploadDir#"
                nameConflict="makeunique">

        <!--- Sadece .cfm uzantısı --->
        <cfset uploadedExt = lcase(listLast(cffile.clientFile, "."))>
        <cfif uploadedExt NEQ "cfm">
            <cffile action="delete" file="#cffile.serverDirectory#/#cffile.serverFile#">
            <cfset response.message = "Yalnızca .cfm uzantılı dosya yüklenebilir.">
            <cfoutput>#serializeJSON(response)#</cfoutput>
            <cfabort>
        </cfif>

        <!--- GUID ile yeniden adlandır --->
        <cfset guidName = lcase(createUUID()) & ".cfm">
        <cfset destFile = uploadDir & guidName>
        <cffile action="rename"
                source="#cffile.serverDirectory#/#cffile.serverFile#"
                destination="#destFile#"
                nameConflict="overwrite">
        <cfset uploadedFileName = guidName>

        <cfcatch type="any">
            <!--- Dosya yüklenmemişse sessizce devam --->
            <cflog file="application" type="warning" text="save_print_template upload: #cfcatch.message#">
        </cfcatch>
    </cftry>

    <!--- Varsayılan yapılıyorsa aynı kategorideki diğerlerindeki is_default'u kaldır --->
    <cfif isDefault>
        <cfquery datasource="boyahane">
            UPDATE setup_print_files
            SET is_default = false
            WHERE process_type = <cfqueryparam value="#processType#" cfsqltype="cf_sql_integer">
            <cfif editMode>
                AND form_id <> <cfqueryparam value="#formId#" cfsqltype="cf_sql_integer">
            </cfif>
        </cfquery>
    </cfif>

    <cfif editMode>
        <cfif len(uploadedFileName)>
            <!--- Eski dosyayı sil --->
            <cfquery name="getOldFile" datasource="boyahane">
                SELECT template_file FROM setup_print_files
                WHERE form_id = <cfqueryparam value="#formId#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfif getOldFile.recordCount AND len(trim(getOldFile.template_file))>
                <cfset oldPath = uploadDir & getOldFile.template_file>
                <cfif fileExists(oldPath)><cffile action="delete" file="#oldPath#"></cfif>
            </cfif>
            <cfquery datasource="boyahane">
                UPDATE setup_print_files SET
                    name          = <cfqueryparam value="#tplName#"     cfsqltype="cf_sql_varchar">,
                    process_type  = <cfqueryparam value="#processType#" cfsqltype="cf_sql_integer">,
                    detail        = <cfqueryparam value="#tplDetail#"   cfsqltype="cf_sql_varchar">,
                    template_file = <cfqueryparam value="#uploadedFileName#" cfsqltype="cf_sql_varchar">,
                    active        = <cfqueryparam value="#isActive#"    cfsqltype="cf_sql_boolean">,
                    is_default    = <cfqueryparam value="#isDefault#"   cfsqltype="cf_sql_boolean">,
                    is_standart   = <cfqueryparam value="#isStandart#"  cfsqltype="cf_sql_boolean">,
                    update_date   = CURRENT_TIMESTAMP,
                    update_ip     = <cfqueryparam value="#cgi.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">,
                    update_emp    = <cfqueryparam value="#session.user.id#"  cfsqltype="cf_sql_integer">
                WHERE form_id = <cfqueryparam value="#formId#" cfsqltype="cf_sql_integer">
            </cfquery>
        <cfelse>
            <cfquery datasource="boyahane">
                UPDATE setup_print_files SET
                    name         = <cfqueryparam value="#tplName#"     cfsqltype="cf_sql_varchar">,
                    process_type = <cfqueryparam value="#processType#" cfsqltype="cf_sql_integer">,
                    detail       = <cfqueryparam value="#tplDetail#"   cfsqltype="cf_sql_varchar">,
                    active       = <cfqueryparam value="#isActive#"    cfsqltype="cf_sql_boolean">,
                    is_default   = <cfqueryparam value="#isDefault#"   cfsqltype="cf_sql_boolean">,
                    is_standart  = <cfqueryparam value="#isStandart#"  cfsqltype="cf_sql_boolean">,
                    update_date  = CURRENT_TIMESTAMP,
                    update_ip    = <cfqueryparam value="#cgi.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">,
                    update_emp   = <cfqueryparam value="#session.user.id#"  cfsqltype="cf_sql_integer">
                WHERE form_id = <cfqueryparam value="#formId#" cfsqltype="cf_sql_integer">
            </cfquery>
        </cfif>
        <cfset response.success = true>
        <cfset response.mode    = "updated">
        <cfset response.form_id = formId>
    <cfelse>
        <cfquery name="insRow" datasource="boyahane">
            INSERT INTO setup_print_files (
                name, process_type, detail,
                template_file,
                active, is_default, is_standart,
                record_date, record_ip, record_emp
            ) VALUES (
                <cfqueryparam value="#tplName#"          cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#processType#"      cfsqltype="cf_sql_integer">,
                <cfqueryparam value="#tplDetail#"        cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#uploadedFileName#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#isActive#"         cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#isDefault#"        cfsqltype="cf_sql_boolean">,
                <cfqueryparam value="#isStandart#"       cfsqltype="cf_sql_boolean">,
                CURRENT_TIMESTAMP,
                <cfqueryparam value="#cgi.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#session.user.id#" cfsqltype="cf_sql_integer">
            )
            RETURNING form_id
        </cfquery>
        <cfset response.success = true>
        <cfset response.mode    = "added">
        <cfset response.form_id = val(insRow.form_id)>
    </cfif>

    <cfcatch type="any">
        <cfset response.message = cfcatch.message & " " & cfcatch.detail>
        <cflog file="application" type="error" text="save_print_template hata: #cfcatch.message# | #cfcatch.detail#">
    </cfcatch>
</cftry>

<cfoutput>#serializeJSON(response)#</cfoutput>
<cfabort>