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
        <cfargument name="company_id" type="numeric" required="false" default="0">
        
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
                        company_id = <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_integer" null="#val(arguments.company_id) eq 0#">,
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
                        manufact_code, short_code, company_id, record_date, record_member
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
                        <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_integer" null="#val(arguments.company_id) eq 0#">,
                        CURRENT_TIMESTAMP,
                        1
                    )
                    RETURNING product_id
                </cfquery>
                
                <!--- Yeni ürünle bağlı otomatik stok kaydı oluştur --->
                <cfset newProductId = insertProduct.product_id>
                <cfset stockCode = len(trim(arguments.product_code)) gt 0 ? trim(arguments.product_code) : "STK-" & newProductId>
                
                <cfquery datasource="boyahane">
                    INSERT INTO stocks (
                        stock_code,
                        product_id,
                        barcod,
                        manufact_code,
                        stock_status,
                        is_main_stock,
                        record_emp,
                        record_date
                    ) VALUES (
                        <cfqueryparam value="#stockCode#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#newProductId#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#arguments.barcod#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.barcod)) eq 0#">,
                        <cfqueryparam value="#arguments.manufact_code#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.manufact_code)) eq 0#">,
                        <cfqueryparam value="true" cfsqltype="cf_sql_bit">,
                        <cfqueryparam value="true" cfsqltype="cf_sql_bit">,
                        1,
                        CURRENT_TIMESTAMP
                    )
                </cfquery>
                
                <cfset result = {
                    "success": true,
                    "message": "Ürün başarıyla eklendi",
                    "product_id": newProductId
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

    <!--- ==================== STOK FONKSİYONLARI ==================== --->

    <!--- Firmaya Bağlı Ana Stokları Getir --->
    <cffunction name="getStocksByCompany" access="remote" returnformat="plain" output="false">
        <cfargument name="company_id" type="numeric" required="true">

        <cfset var result = {}>
        <cfset var qStocks = "">

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif val(arguments.company_id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz firma ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfquery name="qStocks" datasource="boyahane">
                SELECT s.stock_id, s.stock_code, s.barcod, s.property, s.product_unit_id,
                       p.product_id, p.product_name, p.product_code
                FROM stocks s
                LEFT JOIN product p ON s.product_id = p.product_id
                WHERE s.stock_status  = true
                  AND s.is_main_stock = true
                  AND p.company_id    = <cfqueryparam value="#arguments.company_id#" cfsqltype="cf_sql_integer">
                ORDER BY p.product_name, s.stock_code
            </cfquery>

            <cfset var stocksArr = []>
            <cfloop query="qStocks">
                <cfset arrayAppend(stocksArr, {
                    "stock_id":        stock_id,
                    "stock_code":      stock_code ?: "",
                    "barcod":          barcod ?: "",
                    "property":        property ?: "",
                    "product_unit_id": product_unit_id ?: 0,
                    "product_id":      product_id ?: 0,
                    "product_name":    product_name ?: "",
                    "product_code":    product_code ?: "",
                    "label":           (product_name ?: "?") & " — " & (stock_code ?: "")
                })>
            </cfloop>

            <cfset result = {"success": true, "data": stocksArr}>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Stoklar getirilirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Ürüne Bağlı Stokları Getir --->
    <cffunction name="getStocksByProduct" access="remote" returnformat="plain" output="false">
        <cfargument name="product_id" type="numeric" required="true">

        <cfset var result = {}>
        <cfset var qStocks = "">

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif val(arguments.product_id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz ürün ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfquery name="qStocks" datasource="boyahane">
                SELECT stock_id, stock_code, stock_code_2, property, barcod,
                       manufact_code, stock_status, is_main_stock, record_date
                FROM stocks
                WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                ORDER BY is_main_stock DESC, stock_id ASC
            </cfquery>

            <cfset var stocksArr = []>
            <cfloop query="qStocks">
                <cfset arrayAppend(stocksArr, {
                    "stock_id": stock_id,
                    "stock_code": stock_code ?: "",
                    "stock_code_2": stock_code_2 ?: "",
                    "property": property ?: "",
                    "barcod": barcod ?: "",
                    "manufact_code": manufact_code ?: "",
                    "stock_status": stock_status,
                    "is_main_stock": is_main_stock,
                    "record_date": isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : ""
                })>
            </cfloop>

            <cfset result = {"success": true, "data": stocksArr}>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Stoklar getirilirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Stok Ekle / Güncelle --->
    <cffunction name="saveStock" access="remote" returnformat="plain" output="false">
        <cfargument name="stock_id"      type="numeric" required="false" default="0">
        <cfargument name="product_id"    type="numeric" required="true">
        <cfargument name="stock_code"    type="string"  required="true">
        <cfargument name="stock_code_2"  type="string"  required="false" default="">
        <cfargument name="property"      type="string"  required="false" default="">
        <cfargument name="barcod"        type="string"  required="false" default="">
        <cfargument name="manufact_code" type="string"  required="false" default="">
        <cfargument name="stock_status"  type="boolean" required="false" default="true">
        <cfargument name="is_main_stock" type="boolean" required="false" default="false">

        <cfset var result = {}>

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif len(trim(arguments.stock_code)) eq 0>
                <cfset result = {"success": false, "message": "Stok kodu boş olamaz"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfif val(arguments.product_id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz ürün ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfif val(arguments.stock_id) gt 0>
                <!--- Güncelle --->
                <cfquery datasource="boyahane">
                    UPDATE stocks SET
                        stock_code    = <cfqueryparam value="#arguments.stock_code#" cfsqltype="cf_sql_varchar">,
                        stock_code_2  = <cfqueryparam value="#arguments.stock_code_2#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.stock_code_2)) eq 0#">,
                        property      = <cfqueryparam value="#arguments.property#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.property)) eq 0#">,
                        barcod        = <cfqueryparam value="#arguments.barcod#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.barcod)) eq 0#">,
                        manufact_code = <cfqueryparam value="#arguments.manufact_code#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.manufact_code)) eq 0#">,
                        stock_status  = <cfqueryparam value="#arguments.stock_status#" cfsqltype="cf_sql_bit">,
                        is_main_stock = <cfqueryparam value="#arguments.is_main_stock#" cfsqltype="cf_sql_bit">,
                        update_emp    = 1,
                        update_date   = CURRENT_TIMESTAMP
                    WHERE stock_id = <cfqueryparam value="#arguments.stock_id#" cfsqltype="cf_sql_integer">
                      AND product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                </cfquery>
                <cfset result = {"success": true, "message": "Stok başarıyla güncellendi", "stock_id": arguments.stock_id}>
            <cfelse>
                <!--- Ekle --->
                <cfquery datasource="boyahane" name="qInsert">
                    INSERT INTO stocks (
                        product_id, stock_code, stock_code_2, property,
                        barcod, manufact_code, stock_status, is_main_stock,
                        record_emp, record_date
                    ) VALUES (
                        <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#arguments.stock_code#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#arguments.stock_code_2#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.stock_code_2)) eq 0#">,
                        <cfqueryparam value="#arguments.property#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.property)) eq 0#">,
                        <cfqueryparam value="#arguments.barcod#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.barcod)) eq 0#">,
                        <cfqueryparam value="#arguments.manufact_code#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.manufact_code)) eq 0#">,
                        <cfqueryparam value="#arguments.stock_status#" cfsqltype="cf_sql_bit">,
                        <cfqueryparam value="#arguments.is_main_stock#" cfsqltype="cf_sql_bit">,
                        1,
                        CURRENT_TIMESTAMP
                    )
                    RETURNING stock_id
                </cfquery>
                <cfset result = {"success": true, "message": "Stok başarıyla eklendi", "stock_id": qInsert.stock_id}>
            </cfif>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Stok kaydedilirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- ==================== BİRİM FONKSİYONLARI ==================== --->

    <!--- Ürüne Bağlı Birimleri Getir --->
    <cffunction name="getUnitsByProduct" access="remote" returnformat="plain" output="false">
        <cfargument name="product_id" type="numeric" required="true">

        <cfset var result = {}>
        <cfset var qUnits = "">

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif val(arguments.product_id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz ürün ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfquery name="qUnits" datasource="boyahane">
                SELECT product_unit_id, product_unit_status, main_unit, add_unit,
                       multiplier, quantity, weight, is_main, is_add_unit, record_date
                FROM product_unit
                WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                ORDER BY is_main DESC, product_unit_id ASC
            </cfquery>

            <cfset var unitsArr = []>
            <cfloop query="qUnits">
                <cfset arrayAppend(unitsArr, {
                    "product_unit_id":     product_unit_id,
                    "product_unit_status": product_unit_status,
                    "main_unit":           main_unit ?: "",
                    "add_unit":            add_unit ?: "",
                    "multiplier":          multiplier,
                    "quantity":            quantity,
                    "weight":              weight ?: "",
                    "is_main":             is_main,
                    "is_add_unit":         is_add_unit,
                    "record_date":         isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : ""
                })>
            </cfloop>

            <cfset result = {"success": true, "data": unitsArr}>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Birimler getirilirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Birim Ekle / Güncelle --->
    <cffunction name="saveUnit" access="remote" returnformat="plain" output="false">
        <cfargument name="unit_id"            type="numeric" required="false" default="0">
        <cfargument name="product_id"         type="numeric" required="true">
        <cfargument name="main_unit"          type="string"  required="true">
        <cfargument name="add_unit"           type="string"  required="false" default="">
        <cfargument name="multiplier"         type="numeric" required="false" default="1">
        <cfargument name="quantity"           type="numeric" required="false" default="1">
        <cfargument name="weight"             type="string"  required="false" default="">
        <cfargument name="is_main"            type="boolean" required="false" default="false">
        <cfargument name="is_add_unit"        type="boolean" required="false" default="false">
        <cfargument name="product_unit_status" type="boolean" required="false" default="true">

        <cfset var result = {}>

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif len(trim(arguments.main_unit)) eq 0>
                <cfset result = {"success": false, "message": "Ana birim boş olamaz"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfif val(arguments.product_id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz ürün ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfset var weightVal = len(trim(arguments.weight)) gt 0 ? val(arguments.weight) : "">
            <cfset var weightIsNull = len(trim(arguments.weight)) eq 0>

            <cfif val(arguments.unit_id) gt 0>
                <!--- Güncelle --->
                <cfquery datasource="boyahane">
                    UPDATE product_unit SET
                        main_unit           = <cfqueryparam value="#arguments.main_unit#" cfsqltype="cf_sql_varchar">,
                        add_unit            = <cfqueryparam value="#arguments.add_unit#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.add_unit)) eq 0#">,
                        multiplier          = <cfqueryparam value="#arguments.multiplier#" cfsqltype="cf_sql_double">,
                        quantity            = <cfqueryparam value="#arguments.quantity#" cfsqltype="cf_sql_double">,
                        weight              = <cfqueryparam value="#weightVal#" cfsqltype="cf_sql_decimal" null="#weightIsNull#">,
                        is_main             = <cfqueryparam value="#arguments.is_main#" cfsqltype="cf_sql_bit">,
                        is_add_unit         = <cfqueryparam value="#arguments.is_add_unit#" cfsqltype="cf_sql_bit">,
                        product_unit_status = <cfqueryparam value="#arguments.product_unit_status#" cfsqltype="cf_sql_bit">,
                        update_emp          = 1,
                        update_date         = CURRENT_TIMESTAMP
                    WHERE product_unit_id = <cfqueryparam value="#arguments.unit_id#" cfsqltype="cf_sql_integer">
                      AND product_id      = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                </cfquery>
                <cfset result = {"success": true, "message": "Birim başarıyla güncellendi", "unit_id": arguments.unit_id}>
            <cfelse>
                <!--- Ekle --->
                <cfquery datasource="boyahane" name="qInsertUnit">
                    INSERT INTO product_unit (
                        product_id, main_unit, add_unit, multiplier, quantity,
                        weight, is_main, is_add_unit, product_unit_status,
                        record_emp, record_date
                    ) VALUES (
                        <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">,
                        <cfqueryparam value="#arguments.main_unit#" cfsqltype="cf_sql_varchar">,
                        <cfqueryparam value="#arguments.add_unit#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.add_unit)) eq 0#">,
                        <cfqueryparam value="#arguments.multiplier#" cfsqltype="cf_sql_double">,
                        <cfqueryparam value="#arguments.quantity#" cfsqltype="cf_sql_double">,
                        <cfqueryparam value="#weightVal#" cfsqltype="cf_sql_decimal" null="#weightIsNull#">,
                        <cfqueryparam value="#arguments.is_main#" cfsqltype="cf_sql_bit">,
                        <cfqueryparam value="#arguments.is_add_unit#" cfsqltype="cf_sql_bit">,
                        <cfqueryparam value="#arguments.product_unit_status#" cfsqltype="cf_sql_bit">,
                        1,
                        CURRENT_TIMESTAMP
                    )
                    RETURNING product_unit_id
                </cfquery>
                <cfset result = {"success": true, "message": "Birim başarıyla eklendi", "unit_id": qInsertUnit.product_unit_id}>
            </cfif>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Birim kaydedilirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Birim Sil --->
    <cffunction name="deleteUnit" access="remote" returnformat="plain" output="false">
        <cfargument name="unit_id"    type="numeric" required="true">
        <cfargument name="product_id" type="numeric" required="true">

        <cfset var result = {}>

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif val(arguments.unit_id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz birim ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfquery datasource="boyahane">
                DELETE FROM product_unit
                WHERE product_unit_id = <cfqueryparam value="#arguments.unit_id#" cfsqltype="cf_sql_integer">
                  AND product_id       = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset result = {"success": true, "message": "Birim başarıyla silindi"}>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Birim silinirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Stok Sil --->
    <cffunction name="deleteStock" access="remote" returnformat="plain" output="false">
        <cfargument name="stock_id"   type="numeric" required="true">
        <cfargument name="product_id" type="numeric" required="true">

        <cfset var result = {}>

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif val(arguments.stock_id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz stok ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfquery datasource="boyahane">
                DELETE FROM stocks
                WHERE stock_id  = <cfqueryparam value="#arguments.stock_id#" cfsqltype="cf_sql_integer">
                  AND product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset result = {"success": true, "message": "Stok başarıyla silindi"}>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Stok silinirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Ürün Hareketleri Getir --->    
    <cffunction name="getProductMovements" access="remote" returnformat="plain" output="false">
        <cfargument name="product_id" type="numeric" required="true">

        <cfset var result = {}>
        <cfset var movements = "">
        <cfset var movArr = []>

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif val(arguments.product_id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz ürün ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfquery name="movements" datasource="boyahane">
                SELECT
                    sr.stocks_row_id,
                    sr.process_type,
                    sr.stock_in,
                    sr.stock_out,
                    sr.process_date,
                    sr.lot_no,
                    sr.shelf_number,
                    s.stock_code,
                    COALESCE(sf.fis_number, sh.ship_number, '') AS fis_number,
                    sf.fis_type,
                    COALESCE(sf.fis_date, sh.ship_date) AS fis_date,
                    sl.department_location,
                    d.department_head
                FROM stocks_row sr
                LEFT JOIN stocks s ON sr.stock_id = s.stock_id
                LEFT JOIN stock_fis sf ON sr.upd_id = sf.fis_id AND sr.process_type BETWEEN 1 AND 9
                LEFT JOIN ship sh ON sr.upd_id = sh.ship_id AND sr.process_type BETWEEN 10 AND 49
                LEFT JOIN stocks_location sl ON sr.store_location = sl.id
                LEFT JOIN department d ON sr.store = d.department_id
                WHERE sr.product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                ORDER BY sr.process_date DESC, sr.stocks_row_id DESC
            </cfquery>

            <cfloop query="movements">
                <cfset fisTypeLabel = "">
                <!--- Stok fişi (1-9) --->
                <cfif movements.process_type eq 1>      <cfset fisTypeLabel = "Giriş">
                <cfelseif movements.process_type eq 2>  <cfset fisTypeLabel = "Çıkış">
                <cfelseif movements.process_type eq 3>  <cfset fisTypeLabel = "Transfer">
                <cfelseif movements.process_type eq 4>  <cfset fisTypeLabel = "Sayım">
                <!--- İrsaliye (10-49) --->
                <cfelseif movements.process_type eq 10> <cfset fisTypeLabel = "Satış İrs.">
                <cfelseif movements.process_type eq 20> <cfset fisTypeLabel = "Alış İrs.">
                <cfelseif movements.process_type eq 30> <cfset fisTypeLabel = "İade İrs.">
                <cfelseif movements.process_type eq 40> <cfset fisTypeLabel = "Transfer İrs.">
                <cfelseif movements.process_type eq 50> <cfset fisTypeLabel = "Ham Kumaş Giriş">
                <cfelse>                                <cfset fisTypeLabel = "Tip: " & movements.process_type>
                </cfif>

                <cfset arrayAppend(movArr, {
                    "stocks_row_id":       movements.stocks_row_id,
                    "process_type":        movements.process_type ?: 0,
                    "stock_in":            movements.stock_in,
                    "stock_out":           movements.stock_out,
                    "process_date":        isDate(movements.process_date) ? dateFormat(movements.process_date, "dd/mm/yyyy") & " " & timeFormat(movements.process_date, "HH:mm") : "",
                    "lot_no":              movements.lot_no ?: "",
                    "shelf_number":        movements.shelf_number ?: "",
                    "stock_code":          movements.stock_code ?: "",
                    "fis_number":          movements.fis_number ?: "",
                    "fis_type":            movements.fis_type,
                    "fis_type_label":      fisTypeLabel,
                    "fis_date":            isDate(movements.fis_date) ? dateFormat(movements.fis_date, "dd/mm/yyyy") : "",
                    "department_location": movements.department_location ?: "",
                    "department_head":     movements.department_head ?: ""
                })>
            </cfloop>

            <cfset result = {"success": true, "data": movArr}>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Hareketler getirilirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- ==================== EXCEL IMPORT ==================== --->

    <!--- Toplu Ürün İçe Aktarma --->
    <cffunction name="importProducts" access="remote" returnformat="plain" output="false">
        <cfargument name="productsJSON" type="string" required="true">

        <cfset var result     = {}>
        <cfset var products   = []>
        <cfset var inserted   = 0>
        <cfset var errList    = []>
        <cfset var catMap     = {}>
        <cfset var qAllCats   = "">

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif len(trim(arguments.productsJSON)) eq 0>
                <cfset result = {"success": false, "message": "Veri boş olamaz"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfset products = deserializeJSON(arguments.productsJSON)>

            <cfif not isArray(products) or arrayLen(products) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz veri formatı"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfif arrayLen(products) gt 5000>
                <cfset result = {"success": false, "message": "Tek seferde en fazla 5000 ürün aktarabilirsiniz"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <!--- Kategori ID'lerini önbelleğe al (per-row sorgu yerine) --->
            <cfquery name="qAllCats" datasource="boyahane">
                SELECT product_catid FROM product_cat
            </cfquery>
            <cfloop query="qAllCats">
                <cfset catMap[product_catid] = true>
            </cfloop>

            <cfloop array="#products#" index="row">
                <cfset rowNum = structKeyExists(row, "row_num") ? row.row_num : 0>

                <!--- Zorunlu alan doğrulama --->
                <cfif not structKeyExists(row, "product_name") or len(trim(row.product_name)) eq 0>
                    <cfset arrayAppend(errList, "Satır #rowNum#: Ürün adı boş olamaz")>
                    <cfcontinue>
                </cfif>

                <cfif not structKeyExists(row, "product_catid") or val(row.product_catid) eq 0>
                    <cfset arrayAppend(errList, "Satır #rowNum# (#trim(row.product_name)#): Geçerli kategori ID girilmedi")>
                    <cfcontinue>
                </cfif>

                <cfif not structKeyExists(catMap, val(row.product_catid))>
                    <cfset arrayAppend(errList, "Satır #rowNum# (#trim(row.product_name)#): Kategori ID #val(row.product_catid)# bulunamadı")>
                    <cfcontinue>
                </cfif>

                <!--- Değerleri hazırla --->
                <cfset pCode      = structKeyExists(row, "product_code")    ? trim(row.product_code)    : "">
                <cfset pName      = trim(row.product_name)>
                <cfset pCatId     = val(row.product_catid)>
                <cfset pBarcod    = structKeyExists(row, "barcod")           ? trim(row.barcod)           : "">
                <cfset pBrandId   = structKeyExists(row, "brand_id")         ? val(row.brand_id)          : 0>
                <cfset pDetail    = structKeyExists(row, "product_detail")   ? trim(row.product_detail)   : "">
                <cfset pTax       = structKeyExists(row, "tax")              ? val(row.tax)               : 18>
                <cfset pManufact  = structKeyExists(row, "manufact_code")    ? trim(row.manufact_code)    : "">
                <cfset pShortCode = structKeyExists(row, "short_code")       ? trim(row.short_code)       : "">
                <cfset pShelfLife = structKeyExists(row, "shelf_life")       ? trim(row.shelf_life)       : "">

                <!--- Boolean dönüşümleri --->
                <cfset pStatus = true>
                <cfif structKeyExists(row, "product_status")>
                    <cfset pStatus = (row.product_status eq true or row.product_status eq 1)>
                </cfif>
                <cfset pIsSales = true>
                <cfif structKeyExists(row, "is_sales")>
                    <cfset pIsSales = (row.is_sales eq true or row.is_sales eq 1)>
                </cfif>
                <cfset pIsPurchase = true>
                <cfif structKeyExists(row, "is_purchase")>
                    <cfset pIsPurchase = (row.is_purchase eq true or row.is_purchase eq 1)>
                </cfif>

                <cfif pTax lt 0 or pTax gt 100>
                    <cfset pTax = 18>
                </cfif>

                <cftry>
                    <!--- Ürünü ekle --->
                    <cfquery datasource="boyahane" name="qInsert">
                        INSERT INTO product (
                            product_code, product_name, product_catid, barcod,
                            product_detail, product_status, tax,
                            is_sales, is_purchase, brand_id, shelf_life,
                            manufact_code, short_code, record_date, record_member
                        ) VALUES (
                            <cfqueryparam value="#pCode#"      cfsqltype="cf_sql_varchar" null="#len(pCode) eq 0#">,
                            <cfqueryparam value="#pName#"      cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#pCatId#"     cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#pBarcod#"    cfsqltype="cf_sql_varchar" null="#len(pBarcod) eq 0#">,
                            <cfqueryparam value="#pDetail#"    cfsqltype="cf_sql_varchar" null="#len(pDetail) eq 0#">,
                            <cfqueryparam value="#pStatus#"    cfsqltype="cf_sql_bit">,
                            <cfqueryparam value="#pTax#"       cfsqltype="cf_sql_double">,
                            <cfqueryparam value="#pIsSales#"   cfsqltype="cf_sql_bit">,
                            <cfqueryparam value="#pIsPurchase#" cfsqltype="cf_sql_bit">,
                            <cfqueryparam value="#pBrandId#"   cfsqltype="cf_sql_integer" null="#pBrandId eq 0#">,
                            <cfqueryparam value="#pShelfLife#" cfsqltype="cf_sql_varchar" null="#len(pShelfLife) eq 0#">,
                            <cfqueryparam value="#pManufact#"  cfsqltype="cf_sql_varchar" null="#len(pManufact) eq 0#">,
                            <cfqueryparam value="#pShortCode#" cfsqltype="cf_sql_varchar" null="#len(pShortCode) eq 0#">,
                            CURRENT_TIMESTAMP,
                            1
                        )
                        RETURNING product_id
                    </cfquery>

                    <!--- Stok kaydı oluştur --->
                    <cfset newProdId = qInsert.product_id>
                    <cfset stkCode   = len(pCode) gt 0 ? pCode : "STK-" & newProdId>

                    <cfquery datasource="boyahane">
                        INSERT INTO stocks (
                            stock_code, product_id, barcod, manufact_code,
                            stock_status, is_main_stock, record_emp, record_date
                        ) VALUES (
                            <cfqueryparam value="#stkCode#"   cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#newProdId#" cfsqltype="cf_sql_integer">,
                            <cfqueryparam value="#pBarcod#"   cfsqltype="cf_sql_varchar" null="#len(pBarcod) eq 0#">,
                            <cfqueryparam value="#pManufact#" cfsqltype="cf_sql_varchar" null="#len(pManufact) eq 0#">,
                            true, true, 1, CURRENT_TIMESTAMP
                        )
                    </cfquery>

                    <cfset inserted = inserted + 1>

                    <cfcatch type="any">
                        <cfset arrayAppend(errList, "Satır #rowNum# (#pName#): #cfcatch.message#")>
                    </cfcatch>
                </cftry>
            </cfloop>

            <cfset result = {
                "success":     true,
                "inserted":    inserted,
                "error_count": arrayLen(errList),
                "errors":      errList,
                "message":     inserted & " ürün başarıyla eklendi" & (arrayLen(errList) gt 0 ? ", " & arrayLen(errList) & " hata oluştu" : "")
            }>

            <cfcatch type="any">
                <cfset result = {
                    "success": false,
                    "message": "İçe aktarma sırasında hata oluştu: #cfcatch.message#"
                }>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Toplu Marka İçe Aktarma --->
    <cffunction name="importBrands" access="remote" returnformat="plain" output="false">
        <cfargument name="brandsJSON" type="string" required="true">

        <cfset var result   = {}>
        <cfset var brands   = []>
        <cfset var inserted = 0>
        <cfset var errList  = []>

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif len(trim(arguments.brandsJSON)) eq 0>
                <cfset result = {"success": false, "message": "Veri boş olamaz"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfset brands = deserializeJSON(arguments.brandsJSON)>

            <cfif not isArray(brands) or arrayLen(brands) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz veri formatı"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfif arrayLen(brands) gt 5000>
                <cfset result = {"success": false, "message": "En fazla 5000 kayıt aktarabilirsiniz"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfloop array="#brands#" index="row">
                <cfset rowNum = structKeyExists(row, "row_num") ? row.row_num : 0>

                <cfif not structKeyExists(row, "brand_name") or len(trim(row.brand_name)) eq 0>
                    <cfset arrayAppend(errList, "Satır #rowNum#: Marka adı boş olamaz")>
                    <cfcontinue>
                </cfif>

                <cfset bName      = trim(row.brand_name)>
                <cfset bCode      = structKeyExists(row, "brand_code")  ? trim(row.brand_code)  : "">
                <cfset bDetail    = structKeyExists(row, "detail")       ? trim(row.detail)       : "">
                <cfset bIsActive  = structKeyExists(row, "is_active")   ? (row.is_active eq true or row.is_active eq 1)   : true>
                <cfset bIsInternet = structKeyExists(row, "is_internet") ? (row.is_internet eq true or row.is_internet eq 1) : false>

                <cftry>
                    <cfquery datasource="boyahane">
                        INSERT INTO product_brands (
                            brand_name, brand_code, detail, is_active, is_internet,
                            record_date, record_emp
                        ) VALUES (
                            <cfqueryparam value="#bName#"       cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#bCode#"       cfsqltype="cf_sql_varchar" null="#len(bCode) eq 0#">,
                            <cfqueryparam value="#bDetail#"     cfsqltype="cf_sql_varchar" null="#len(bDetail) eq 0#">,
                            <cfqueryparam value="#bIsActive#"   cfsqltype="cf_sql_bit">,
                            <cfqueryparam value="#bIsInternet#" cfsqltype="cf_sql_bit">,
                            CURRENT_TIMESTAMP,
                            1
                        )
                    </cfquery>
                    <cfset inserted = inserted + 1>
                    <cfcatch type="any">
                        <cfset arrayAppend(errList, "Satır #rowNum# (#bName#): #cfcatch.message#")>
                    </cfcatch>
                </cftry>
            </cfloop>

            <cfset result = {
                "success":     true,
                "inserted":    inserted,
                "error_count": arrayLen(errList),
                "errors":      errList,
                "message":     inserted & " marka eklendi" & (arrayLen(errList) gt 0 ? ", " & arrayLen(errList) & " hata" : "")
            }>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "İçe aktarma hatası: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Toplu Kategori İçe Aktarma --->
    <cffunction name="importProductCats" access="remote" returnformat="plain" output="false">
        <cfargument name="catsJSON" type="string" required="true">

        <cfset var result   = {}>
        <cfset var cats     = []>
        <cfset var inserted = 0>
        <cfset var errList  = []>

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif len(trim(arguments.catsJSON)) eq 0>
                <cfset result = {"success": false, "message": "Veri boş olamaz"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfset cats = deserializeJSON(arguments.catsJSON)>

            <cfif not isArray(cats) or arrayLen(cats) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz veri formatı"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfif arrayLen(cats) gt 5000>
                <cfset result = {"success": false, "message": "En fazla 5000 kayıt aktarabilirsiniz"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfloop array="#cats#" index="row">
                <cfset rowNum = structKeyExists(row, "row_num") ? row.row_num : 0>

                <cfif not structKeyExists(row, "product_cat") or len(trim(row.product_cat)) eq 0>
                    <cfset arrayAppend(errList, "Satır #rowNum#: Kategori adı boş olamaz")>
                    <cfcontinue>
                </cfif>

                <cfset cName      = trim(row.product_cat)>
                <cfset cHierarchy = structKeyExists(row, "hierarchy") ? trim(row.hierarchy) : "">
                <cfset cDetail    = structKeyExists(row, "detail")     ? trim(row.detail)     : "">

                <cftry>
                    <cfquery datasource="boyahane">
                        INSERT INTO product_cat (
                            product_cat, hierarchy, detail, record_date, record_emp
                        ) VALUES (
                            <cfqueryparam value="#cName#"      cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#cHierarchy#" cfsqltype="cf_sql_varchar" null="#len(cHierarchy) eq 0#">,
                            <cfqueryparam value="#cDetail#"    cfsqltype="cf_sql_varchar" null="#len(cDetail) eq 0#">,
                            CURRENT_TIMESTAMP,
                            1
                        )
                    </cfquery>
                    <cfset inserted = inserted + 1>
                    <cfcatch type="any">
                        <cfset arrayAppend(errList, "Satır #rowNum# (#cName#): #cfcatch.message#")>
                    </cfcatch>
                </cftry>
            </cfloop>

            <cfset result = {
                "success":     true,
                "inserted":    inserted,
                "error_count": arrayLen(errList),
                "errors":      errList,
                "message":     inserted & " kategori eklendi" & (arrayLen(errList) gt 0 ? ", " & arrayLen(errList) & " hata" : "")
            }>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "İçe aktarma hatası: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- ==================== ÜRÜN RESİM FONKSİYONLARI ==================== --->

    <!--- Ürüne Ait Resimleri Getir --->
    <cffunction name="getProductImages" access="remote" returnformat="plain" output="false">
        <cfargument name="product_id" type="numeric" required="true">

        <cfset var result = {}>
        <cfset var qImages = "">

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif val(arguments.product_id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz ürün ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <cfquery name="qImages" datasource="boyahane">
                SELECT image_id, product_id, image_type, file_path, image_url,
                       title, is_main, sort_order, created_at
                FROM product_images
                WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                ORDER BY is_main DESC, sort_order ASC, image_id ASC
            </cfquery>

            <cfset var imgArr = []>
            <cfloop query="qImages">
                <cfset var src = "">
                <cfif image_type eq "url">
                    <cfset src = image_url ?: "">
                <cfelse>
                    <cfset src = len(trim(file_path)) gt 0 ? "/assets/uploads/products/" & file_path : "">
                </cfif>
                <cfset arrayAppend(imgArr, {
                    "image_id":   image_id,
                    "image_type": image_type ?: "file",
                    "file_path":  file_path ?: "",
                    "image_url":  image_url ?: "",
                    "src":        src,
                    "title":      title ?: "",
                    "is_main":    is_main,
                    "sort_order": sort_order,
                    "created_at": isDate(created_at) ? dateFormat(created_at,"dd/mm/yyyy") & " " & timeFormat(created_at,"HH:mm") : ""
                })>
            </cfloop>

            <cfset result = {"success": true, "data": imgArr}>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Resimler getirilirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- URL ile Resim Ekle --->
    <cffunction name="saveProductImageUrl" access="remote" returnformat="plain" output="false">
        <cfargument name="product_id" type="numeric" required="true">
        <cfargument name="image_url"  type="string"  required="true">
        <cfargument name="title"      type="string"  required="false" default="">

        <cfset var result = {}>

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfif val(arguments.product_id) eq 0>
                <cfset result = {"success": false, "message": "Geçersiz ürün ID"}>
                <cfreturn serializeJSON(result)>
            </cfif>
            <cfif NOT len(trim(arguments.image_url))>
                <cfset result = {"success": false, "message": "URL boş olamaz"}>
                <cfreturn serializeJSON(result)>
            </cfif>
            <!--- Basit URL format kontrolü --->
            <cfif NOT (left(lCase(trim(arguments.image_url)),7) eq "http://" OR left(lCase(trim(arguments.image_url)),8) eq "https://")>
                <cfset result = {"success": false, "message": "Geçerli bir URL giriniz (http:// veya https://)"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <!--- İlk resim ise ana resim yap --->
            <cfquery name="qCount" datasource="boyahane">
                SELECT COUNT(*) AS cnt FROM product_images
                WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfset var isFirst = (qCount.cnt eq 0)>

            <cfquery datasource="boyahane" name="qIns">
                INSERT INTO product_images (product_id, image_type, image_url, title, is_main, sort_order)
                VALUES (
                    <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">,
                    'url',
                    <cfqueryparam value="#trim(arguments.image_url)#" cfsqltype="cf_sql_varchar">,
                    <cfqueryparam value="#trim(arguments.title)#" cfsqltype="cf_sql_varchar" null="#len(trim(arguments.title)) eq 0#">,
                    <cfqueryparam value="#isFirst#" cfsqltype="cf_sql_bit">,
                    <cfqueryparam value="#qCount.cnt#" cfsqltype="cf_sql_integer">
                )
                RETURNING image_id
            </cfquery>

            <cfset result = {"success": true, "message": "Resim eklendi", "image_id": qIns.image_id, "is_main": isFirst}>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Resim eklenirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Resim Sil --->
    <cffunction name="deleteProductImage" access="remote" returnformat="plain" output="false">
        <cfargument name="image_id"   type="numeric" required="true">
        <cfargument name="product_id" type="numeric" required="true">

        <cfset var result = {}>

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <!--- Silinecek resmi bul --->
            <cfquery name="qImg" datasource="boyahane">
                SELECT image_id, image_type, file_path, is_main
                FROM product_images
                WHERE image_id  = <cfqueryparam value="#arguments.image_id#"   cfsqltype="cf_sql_integer">
                  AND product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                LIMIT 1
            </cfquery>

            <cfif qImg.recordCount eq 0>
                <cfset result = {"success": false, "message": "Resim bulunamadı"}>
                <cfreturn serializeJSON(result)>
            </cfif>

            <!--- Dosyayı diskten sil (file tipiyse) --->
            <cfif qImg.image_type eq "file" AND len(trim(qImg.file_path)) gt 0>
                <cftry>
                    <cfset var diskPath = expandPath("/assets/uploads/products/") & qImg.file_path>
                    <cfif fileExists(diskPath)>
                        <cffile action="delete" file="#diskPath#">
                    </cfif>
                    <cfcatch></cfcatch>
                </cftry>
            </cfif>

            <cfquery datasource="boyahane">
                DELETE FROM product_images
                WHERE image_id  = <cfqueryparam value="#arguments.image_id#"   cfsqltype="cf_sql_integer">
                  AND product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <!--- Silinen ana resimse başka birine ana yap --->
            <cfif qImg.is_main>
                <cfquery datasource="boyahane">
                    UPDATE product_images SET is_main = true
                    WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                      AND image_id = (
                          SELECT image_id FROM product_images
                          WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
                          ORDER BY sort_order ASC, image_id ASC
                          LIMIT 1
                      )
                </cfquery>
            </cfif>

            <cfset result = {"success": true, "message": "Resim silindi"}>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Resim silinirken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

    <!--- Ana Resim Yap --->
    <cffunction name="setMainProductImage" access="remote" returnformat="plain" output="false">
        <cfargument name="image_id"   type="numeric" required="true">
        <cfargument name="product_id" type="numeric" required="true">

        <cfset var result = {}>

        <cfheader name="Content-Type" value="application/json; charset=utf-8">

        <cftry>
            <cfquery datasource="boyahane">
                UPDATE product_images SET is_main = false
                WHERE product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>
            <cfquery datasource="boyahane">
                UPDATE product_images SET is_main = true
                WHERE image_id  = <cfqueryparam value="#arguments.image_id#"   cfsqltype="cf_sql_integer">
                  AND product_id = <cfqueryparam value="#arguments.product_id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset result = {"success": true, "message": "Ana resim güncellendi"}>

            <cfcatch type="any">
                <cfset result = {"success": false, "message": "Ana resim ayarlanırken hata: #cfcatch.message#"}>
            </cfcatch>
        </cftry>

        <cfreturn serializeJSON(result)>
    </cffunction>

</cfcomponent>