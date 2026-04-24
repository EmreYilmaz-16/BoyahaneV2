<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showdebugoutput="false">

<cfif NOT structKeyExists(session, "authenticated") OR NOT session.authenticated>
    <cfoutput>{"success":false,"message":"Oturum gerekli."}</cfoutput>
    <cfabort>
</cfif>

<cftry>
    <cfset productId = isDefined("form.product_id") ? val(form.product_id) : 0>
    <cfset imgTitle  = isDefined("form.title")      ? left(trim(form.title), 200) : "">

    <cfif productId lte 0>
        <cfoutput>{"success":false,"message":"Geçersiz ürün ID."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Dosya alanı kontrolü --->
    <cfif NOT isDefined("form.img_file") OR NOT len(trim(form.img_file))>
        <cfoutput>{"success":false,"message":"Lütfen bir dosya seçin."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Upload dizini --->
    <cfset uploadDir = expandPath("/assets/uploads/products/")>
    <cfif NOT directoryExists(uploadDir)>
        <cfdirectory action="create" directory="#uploadDir#" mode="755">
    </cfif>

    <!--- Dosyayı yükle --->
    <cffile action="upload"
            filefield="img_file"
            destination="#uploadDir#"
            nameconflict="makeunique"
            accept="image/jpeg,image/jpg,image/png,image/gif,image/webp">

    <!--- Güvenlik: yüklenen dosyanın gerçekten resim olduğunu doğrula --->
    <cfset allowedExts = "jpg,jpeg,png,gif,webp">
    <cfset fileExt = lCase(cffile.clientFileExt)>
    <cfif NOT listFind(allowedExts, fileExt)>
        <!--- İzin verilmeyen uzantı — yüklenen dosyayı sil --->
        <cfif fileExists(cffile.serverDirectory & "/" & cffile.serverFile)>
            <cffile action="delete" file="#cffile.serverDirectory#/#cffile.serverFile#">
        </cfif>
        <cfoutput>{"success":false,"message":"Sadece resim dosyaları yüklenebilir (jpg, png, gif, webp)."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Dosya boyutu kontrolü: max 5 MB --->
    <cfif cffile.fileSize gt 5242880>
        <cffile action="delete" file="#cffile.serverDirectory#/#cffile.serverFile#">
        <cfoutput>{"success":false,"message":"Dosya boyutu 5 MB'dan küçük olmalıdır."}</cfoutput>
        <cfabort>
    </cfif>

    <cfset savedFileName = cffile.serverFile>

    <!--- Dosya izinlerini nginx için düzelt (www-data okuyabilsin) --->
    <cftry>
        <cfexecute name="chmod" arguments="644 #uploadDir##savedFileName#" timeout="5"></cfexecute>
        <cfcatch></cfcatch>
    </cftry>

    <!--- İlk resim mi --->
    <cfquery name="qCount" datasource="boyahane">
        SELECT COUNT(*) AS cnt FROM product_images
        WHERE product_id = <cfqueryparam value="#productId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfset isFirst = (qCount.cnt eq 0)>

    <cfquery datasource="boyahane" name="qIns">
        INSERT INTO product_images (product_id, image_type, file_path, title, is_main, sort_order)
        VALUES (
            <cfqueryparam value="#productId#" cfsqltype="cf_sql_integer">,
            'file',
            <cfqueryparam value="#savedFileName#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#imgTitle#" cfsqltype="cf_sql_varchar" null="#len(imgTitle) eq 0#">,
            <cfqueryparam value="#isFirst#" cfsqltype="cf_sql_bit">,
            <cfqueryparam value="#qCount.cnt#" cfsqltype="cf_sql_integer">
        )
        RETURNING image_id
    </cfquery>

    <cfset imgSrc = "/assets/uploads/products/" & savedFileName>
    <cfoutput>{"success":true,"message":"Resim yüklendi","image_id":#qIns.image_id#,"src":"#imgSrc#","is_main":#isFirst#,"file_name":"#savedFileName#"}</cfoutput>

<cfcatch type="any">
    <cfoutput>{"success":false,"message":"Yükleme hatası: #jsStringFormat(cfcatch.message)#"}</cfoutput>
</cfcatch>
</cftry>