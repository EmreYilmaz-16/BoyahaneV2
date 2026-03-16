<cfcomponent output="false">
    
    <!--- Kategori Silme Fonksiyonu --->
    <cffunction name="deleteCategory" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        
        <cfset var result = {}>
        <cfset var checkProducts = "">
        
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        
        <cftry>
            <!--- ID kontrolü --->
            <cfif val(arguments.id) eq 0>
                <cfset result = {
                    "success": false,
                    "message": "Geçersiz kategori ID"
                }>
                <cfreturn result>
            </cfif>
            
            <!--- Kategoriye bağlı ürün var mı kontrol et --->
            <cfquery name="checkProducts" datasource="boyahane">
                SELECT COUNT(*) as product_count
                FROM product
                WHERE product_catid = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            
            <cfif checkProducts.product_count gt 0>
                <cfset result = {
                    "success": false,
                    "message": "Bu kategoriye bağlı #checkProducts.product_count# adet ürün bulunmaktadır. Önce ürünleri silmelisiniz."
                }>
                <cfreturn result>
            </cfif>
            
            <!--- Kategoriyi sil --->
            <cfquery datasource="boyahane">
                DELETE FROM product_cat
                WHERE product_catid = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            
            <cfset result = {
                "success": true,
                "message": "Kategori başarıyla silindi"
            }>
            
            <cfcatch type="any">
                <cfset result = {
                    "success": false,
                    "message": "Kategori silinirken bir hata oluştu: #cfcatch.message#"
                }>
            </cfcatch>
        </cftry>
        
        <cfreturn serializeJSON(result)>
    </cffunction>
    
    <!--- Ürün Getir Fonksiyonu --->
    <cffunction name="getProduct" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        
        <cfset var result = {}>
        <cfset var getProduct = "">
        
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        
        <cftry>
            <cfquery name="getProduct" datasource="boyahane">
                SELECT 
                    p.*,
                    pc.product_cat,
                    pc.hierarchy,
                    pb.brand_name
                FROM 
                    product p
                    LEFT JOIN product_cat pc ON p.product_catid = pc.product_catid
                    LEFT JOIN product_brands pb ON p.brand_id = pb.brand_id
                WHERE 
                    p.product_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            
            <cfif getProduct.recordCount eq 0>
                <cfset result = {
                    "success": false,
                    "message": "Ürün bulunamadı"
                }>
            <cfelse>
                <cfset result = {
                    "success": true,
                    "data": {
                        "product_id": getProduct.product_id,
                        "product_code": getProduct.product_code ?: "",
                        "product_name": getProduct.product_name ?: "",
                        "product_catid": getProduct.product_catid,
                        "product_cat": getProduct.product_cat ?: "",
                        "hierarchy": getProduct.hierarchy ?: "",
                        "brand_id": getProduct.brand_id ?: 0,
                        "brand_name": getProduct.brand_name ?: "",
                        "barcod": getProduct.barcod ?: "",
                        "product_detail": getProduct.product_detail ?: "",
                        "product_detail2": getProduct.product_detail2 ?: "",
                        "product_status": getProduct.product_status,
                        "tax": getProduct.tax,
                        "is_sales": getProduct.is_sales,
                        "is_purchase": getProduct.is_purchase,
                        "brand_id": getProduct.brand_id ?: "",
                        "shelf_life": getProduct.shelf_life ?: "",
                        "manufact_code": getProduct.manufact_code ?: "",
                        "short_code": getProduct.short_code ?: "",
                        "record_date": isDate(getProduct.record_date) ? dateFormat(getProduct.record_date, "dd/mm/yyyy") & " " & timeFormat(getProduct.record_date, "HH:mm") : "",
                        "update_date": isDate(getProduct.update_date) ? dateFormat(getProduct.update_date, "dd/mm/yyyy") & " " & timeFormat(getProduct.update_date, "HH:mm") : ""
                    }
                }>
            </cfif>
            
            <cfcatch type="any">
                <cfset result = {
                    "success": false,
                    "message": "Ürün getirilirken bir hata oluştu: #cfcatch.message#"
                }>
            </cfcatch>
        </cftry>
        
        <cfreturn serializeJSON(result)>
    </cffunction>
    
    <!--- Ürün Silme Fonksiyonu --->
    <cffunction name="deleteProduct" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        
        <cfset var result = {}>
        
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        
        <cftry>
            <!--- ID kontrolü --->
            <cfif val(arguments.id) eq 0>
                <cfset result = {
                    "success": false,
                    "message": "Geçersiz ürün ID"
                }>
                <cfreturn serializeJSON(result)>
            </cfif>
            
            <!--- Ürünü sil --->
            <cfquery datasource="boyahane">
                DELETE FROM product
                WHERE product_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            
            <cfset result = {
                "success": true,
                "message": "Ürün başarıyla silindi"
            }>
            
            <cfcatch type="any">
                <cfset result = {
                    "success": false,
                    "message": "Ürün silinirken bir hata oluştu: #cfcatch.message#"
                }>
            </cfcatch>
        </cftry>
        
        <cfreturn serializeJSON(result)>
    </cffunction>
    
    <!--- Ürün Kaydet/Güncelle Fonksiyonu --->
    <cffunction name="saveProduct" access="remote" returnformat="plain" output="false">
        <cfargument name="product_id" type="numeric" required="false" default="0">
        <cfargument name="product_code" type="string" required="false" default="">
        <cfargument name="product_name" type="string" required="true">
        <cfargument name="product_catid" type="numeric" required="true">
        <cfargument name="barcod" type="string" required="false" default="">
        <cfargument name="product_detail" type="string" required="false" default="">
        <cfargument name="product_detail2" type="string" required="false" default="">
        <cfargument name="product_status" type="boolean" required="false" default="false">
        <cfargument name="tax" type="numeric" required="false" default="0">
        <cfargument name="is_sales" type="boolean" required="false" default="false">
        <cfargument name="is_purchase" type="boolean" required="false" default="false">
        <cfargument name="brand_id" type="numeric" required="false" default="0">
        <cfargument name="shelf_life" type="string" required="false" default="">
        <cfargument name="manufact_code" type="string" required="false" default="">
        <cfargument name="short_code" type="string" required="false" default="">
        
        <cfset var result = {}>
        
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        
        <cftry>
            <!--- Validation --->
            <cfif len(trim(arguments.product_name)) eq 0>
                <cfset result = {
                    "success": false,
                    "message": "Ürün adı boş olamaz"
                }>
                <cfreturn serializeJSON(result)>
            </cfif>
            
            <cfif val(arguments.product_catid) eq 0>
                <cfset result = {
                    "success": false,
                    "message": "Kategori seçmelisiniz"
                }>
                <cfreturn serializeJSON(result)>
            </cfif>
            
            <!--- Güncelleme mi yoksa yeni kayıt mı? --->
            <cfif val(arguments.product_id) gt 0>
                <!--- Güncelleme --->
                <cfquery datasource="boyahane">
                    UPDATE product SET
                        product_code = <cfqueryparam value="#arguments.product_code#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.product_code)) eq 0#">,
                        product_name = <cfqueryparam value="#arguments.product_name#" cfsqltype="cf_sql_varchar">,
                        product_catid = <cfqueryparam value="#arguments.product_catid#" cfsqltype="cf_sql_integer">,
                        barcod = <cfqueryparam value="#arguments.barcod#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.barcod)) eq 0#">,
                        product_detail = <cfqueryparam value="#arguments.product_detail#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.product_detail)) eq 0#">,
                        product_detail2 = <cfqueryparam value="#arguments.product_detail2#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.product_detail2)) eq 0#">,
                        product_status = <cfqueryparam value="#arguments.product_status#" cfsqltype="cf_sql_bit">,
                        tax = <cfqueryparam value="#arguments.tax#" cfsqltype="cf_sql_double">,
                        is_sales = <cfqueryparam value="#arguments.is_sales#" cfsqltype="cf_sql_bit">,
                        is_purchase = <cfqueryparam value="#arguments.is_purchase#" cfsqltype="cf_sql_bit">,
                        brand_id = <cfqueryparam value="#arguments.brand_id#" cfsqltype="cf_sql_integer" null="#val(arguments.brand_id) eq 0#">,
                        shelf_life = <cfqueryparam value="#arguments.shelf_life#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.shelf_life)) eq 0#">,
                        manufact_code = <cfqueryparam value="#arguments.manufact_code#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.manufact_code)) eq 0#">,
                        short_code = <cfqueryparam value="#arguments.short_code#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.short_code)) eq 0#">,
                        update_date = CURRENT_TIMESTAMP,
                        update_emp = 1
                    WHERE 
                        product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                </cfquery>
                
                <cfset result = {
                    "success": true,
                    "message": "Ürün başarıyla güncellendi",
                    "product_id": arguments.product_id
                }>
            <cfelse>
                <!--- Yeni kayıt --->
                <cfquery datasource="boyahane" name="insertProduct">
                    INSERT INTO product (
                        product_code, product_name, product_catid, barcod,
                        product_detail, product_detail2, product_status, tax,
                        is_sales, is_purchase, brand_id, shelf_life,
                        manufact_code, short_code, record_date, record_member
                    ) VALUES (
                        <cfqueryparam value="#arguments.product_code#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.product_code)) eq 0#">,
                        <cfqueryparam value="#arguments.product_name#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#arguments.product_catid#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#arguments.barcod#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.barcod)) eq 0#">,
                        <cfqueryparam value="#arguments.product_detail#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.product_detail)) eq 0#">,
                        <cfqueryparam value="#arguments.product_detail2#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.product_detail2)) eq 0#">,
                        <cfqueryparam value="#arguments.product_status#" cfsqltype="cf_sql_bit">,
                        <cfqueryparam value="#arguments.tax#" cfsqltype="cf_sql_double">,
                        <cfqueryparam value="#arguments.is_sales#" cfsqltype="cf_sql_bit">,
                        <cfqueryparam value="#arguments.is_purchase#" cfsqltype="cf_sql_bit">,
                        <cfqueryparam value="#arguments.brand_id#" cfsqltype="cf_sql_integer" null="#val(arguments.brand_id) eq 0#">,
                        <cfqueryparam value="#arguments.shelf_life#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.shelf_life)) eq 0#">,
                        <cfqueryparam value="#arguments.manufact_code#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.manufact_code)) eq 0#">,
                        <cfqueryparam value="#arguments.short_code#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.short_code)) eq 0#">,
                        CURRENT_TIMESTAMP,
                        1
                    )
                    RETURNING product_id
                </cfquery>
                
                <cfset result = {
                    "success": true,
                    "message": "Ürün başarıyla eklendi",
                    "product_id": insertProduct.product_id
                }>
            </cfif>
            
            <cfcatch type="any">
                <cfset result = {
                    "success": false,
                    "message": "Ürün kaydedilirken bir hata oluştu: #cfcatch.message#"
                }>
            </cfcatch>
        </cftry>
        
        <cfreturn serializeJSON(result)>
    </cffunction>
    
    <!--- ==================== MARKA FONKSİYONLARI ==================== --->
    
    <!--- Marka Getir Fonksiyonu --->
    <cffunction name="getBrand" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        
        <cfset var result = {}>
        <cfset var getBrand = "">
        
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        
        <cftry>
            <cfquery name="getBrand" datasource="boyahane">
                SELECT *
                FROM product_brands
                WHERE brand_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            
            <cfif getBrand.recordCount eq 0>
                <cfset result = {
                    "success": false,
                    "message": "Marka bulunamadı"
                }>
            <cfelse>
                <cfset result = {
                    "success": true,
                    "data": {
                        "brand_id": getBrand.brand_id,
                        "brand_name": getBrand.brand_name ?: "",
                        "brand_code": getBrand.brand_code ?: "",
                        "detail": getBrand.detail ?: "",
                        "is_active": getBrand.is_active,
                        "is_internet": getBrand.is_internet,
                        "record_date": isDate(getBrand.record_date) ? dateFormat(getBrand.record_date, "dd/mm/yyyy") & " " & timeFormat(getBrand.record_date, "HH:mm") : "",
                        "update_date": isDate(getBrand.update_date) ? dateFormat(getBrand.update_date, "dd/mm/yyyy") & " " & timeFormat(getBrand.update_date, "HH:mm") : ""
                    }
                }>
            </cfif>
            
            <cfcatch type="any">
                <cfset result = {
                    "success": false,
                    "message": "Marka getirilirken bir hata oluştu: #cfcatch.message#"
                }>
            </cfcatch>
        </cftry>
        
        <cfreturn serializeJSON(result)>
    </cffunction>
    
    <!--- Marka Silme Fonksiyonu --->
    <cffunction name="deleteBrand" access="remote" returnformat="plain" output="false">
        <cfargument name="id" type="numeric" required="true">
        
        <cfset var result = {}>
        <cfset var checkProducts = "">
        
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        
        <cftry>
            <!--- ID kontrolü --->
            <cfif val(arguments.id) eq 0>
                <cfset result = {
                    "success": false,
                    "message": "Geçersiz marka ID"
                }>
                <cfreturn serializeJSON(result)>
            </cfif>
            
            <!--- Markaya bağlı ürün var mı kontrol et --->
            <cfquery name="checkProducts" datasource="boyahane">
                SELECT COUNT(*) as product_count
                FROM product
                WHERE brand_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            
            <cfif checkProducts.product_count gt 0>
                <cfset result = {
                    "success": false,
                    "message": "Bu markaya bağlı #checkProducts.product_count# adet ürün bulunmaktadır. Önce ürünleri silmelisiniz."
                }>
                <cfreturn serializeJSON(result)>
            </cfif>
            
            <!--- Markayı sil --->
            <cfquery datasource="boyahane">
                DELETE FROM product_brands
                WHERE brand_id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>
            
            <cfset result = {
                "success": true,
                "message": "Marka başarıyla silindi"
            }>
            
            <cfcatch type="any">
                <cfset result = {
                    "success": false,
                    "message": "Marka silinirken bir hata oluştu: #cfcatch.message#"
                }>
            </cfcatch>
        </cftry>
        
        <cfreturn serializeJSON(result)>
    </cffunction>
    
    <!--- Marka Kaydet/Güncelle Fonksiyonu --->
    <cffunction name="saveBrand" access="remote" returnformat="plain" output="false">
        <cfargument name="brand_id" type="numeric" required="false" default="0">
        <cfargument name="brand_name" type="string" required="true">
        <cfargument name="brand_code" type="string" required="false" default="">
        <cfargument name="detail" type="string" required="false" default="">
        <cfargument name="is_active" type="boolean" required="false" default="true">
        <cfargument name="is_internet" type="boolean" required="false" default="false">
        
        <cfset var result = {}>
        
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        
        <cftry>
            <!--- Validation --->
            <cfif len(trim(arguments.brand_name)) eq 0>
                <cfset result = {
                    "success": false,
                    "message": "Marka adı boş olamaz"
                }>
                <cfreturn serializeJSON(result)>
            </cfif>
            
            <!--- Güncelleme mi yoksa yeni kayıt mı? --->
            <cfif val(arguments.brand_id) gt 0>
                <!--- Güncelleme --->
                <cfquery datasource="boyahane">
                    UPDATE product_brands SET
                        brand_name = <cfqueryparam value="#arguments.brand_name#" cfsqltype="cf_sql_varchar">,
                        brand_code = <cfqueryparam value="#arguments.brand_code#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.brand_code)) eq 0#">,
                        detail = <cfqueryparam value="#arguments.detail#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.detail)) eq 0#">,
                        is_active = <cfqueryparam value="#arguments.is_active#" cfsqltype="cf_sql_bit">,
                        is_internet = <cfqueryparam value="#arguments.is_internet#" cfsqltype="cf_sql_bit">,
                        update_date = CURRENT_TIMESTAMP,
                        update_emp = 1
                    WHERE 
                        brand_id = <cfqueryparam value="#arguments.brand_id#" cfsqltype="cf_sql_integer">
                </cfquery>
                
                <cfset result = {
                    "success": true,
                    "message": "Marka başarıyla güncellendi",
                    "brand_id": arguments.brand_id
                }>
            <cfelse>
                <!--- Yeni kayıt --->
                <cfquery datasource="boyahane" name="insertBrand">
                    INSERT INTO product_brands (
                        brand_name, brand_code, detail, is_active, is_internet,
                        record_date, record_emp
                    ) VALUES (
                        <cfqueryparam value="#arguments.brand_name#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#arguments.brand_code#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.brand_code)) eq 0#">,
                        <cfqueryparam value="#arguments.detail#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.detail)) eq 0#">,
                        <cfqueryparam value="#arguments.is_active#" cfsqltype="cf_sql_bit">,
                        <cfqueryparam value="#arguments.is_internet#" cfsqltype="cf_sql_bit">,
                        CURRENT_TIMESTAMP,
                        1
                    )
                    RETURNING brand_id
                </cfquery>
                
                <cfset result = {
                    "success": true,
                    "message": "Marka başarıyla eklendi",
                    "brand_id": insertBrand.brand_id
                }>
            </cfif>
            
            <cfcatch type="any">
                <cfset result = {
                    "success": false,
                    "message": "Marka kaydedilirken bir hata oluştu: #cfcatch.message#"
                }>
            </cfcatch>
        </cftry>
        
        <cfreturn serializeJSON(result)>
    </cffunction>
    
    <!--- Tüm Markaları Getir --->
    <cffunction name="getBrands" access="remote" returnformat="plain" output="false">
        <cfset var result = []>
        <cfset var getBrands = "">
        
        <cfheader name="Content-Type" value="application/json; charset=utf-8">
        
        <cftry>
            <cfquery name="getBrands" datasource="boyahane">
                SELECT brand_id, brand_name, brand_code
                FROM product_brands
                WHERE is_active = true
                ORDER BY brand_name
            </cfquery>
            
            <cfloop query="getBrands">
                <cfset arrayAppend(result, {
                    "BRAND_ID": brand_id,
                    "BRAND_NAME": brand_name,
                    "BRAND_CODE": brand_code ?: ""
                })>
            </cfloop>
            
            <cfcatch type="any">
                <cfset result = []>
            </cfcatch>
        </cftry>
        
        <cfreturn serializeJSON(result)>
    </cffunction>
    
</cfcomponent>