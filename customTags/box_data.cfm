<!---
    box_data.cfm — CFC metot çağrısı ile veri yükleme yardımcısı
    boyahanev2.rasihcelik.com sistemine uyarlanmış ve hataları düzeltilmiş versiyon.

    Nitelikler (Attributes):
        asname     - Sonuç değişkeninin çağrıcı sayfadaki adı (zorunlu)
        function   - "component.path:methodName" veya "localVar:methodName" formatı (zorunlu)
                     Örnekler:
                       "company.cfc.company:getCompany"  → CFC yolundan oluşturulan nesne
                       "companyObj:getCompany"           → caller sayfasındaki mevcut nesne
        columns    - Şu an kullanılmıyor, gelecek kullanım için ayrıldı (varsayılan: "")
        conditions - "&" ile ayrılmış "paramAdi=deger" çiftleri (varsayılan: "")
                     Değer önce caller'da aranır, yoksa literal string olarak kullanılır.

    Kullanım:
        <!--- company_id URL parametresini kullanarak şirket bilgisini yükle --->
        <cf_box_data
            asname="myCompany"
            function="company.cfc.company:getCompanyById"
            conditions="company_id=company_id">

        <!--- Yüklenmiş veriyi kullan --->
        <cf_box title="#myCompany.company_name#">
            ...
        </cf_box>

    Hata Düzeltmeleri (orijinal box_data.cfm'e göre):
        1. `evalueate` yazım hatası düzeltildi → `evaluate` (artık structKeyExists kullanılıyor)
        2. else dalında `funct_name` tanımsız değişken hatası düzeltildi
        3. `evaluate()` güvenlik riski — modern `invoke()` ile değiştirildi
--->

<cfparam name="attributes.asname">
<cfparam name="attributes.function">
<cfparam name="attributes.columns"    default="">
<cfparam name="attributes.conditions" default="">

<cfif thisTag.executionMode eq "start">

    <!--- Koşul parametrelerini struct'a çevir --->
    <cfset conditions_struct = structNew()>
    <cfif len(trim(attributes.conditions))>
        <cfset conditions_array = listToArray(attributes.conditions, "&")>
        <cfloop array="#conditions_array#" item="e">
            <cftry>
                <cfset paramKey = trim(listFirst(e, "="))>
                <cfset paramVal = trim(listLast(e, "="))>

                <cfif structKeyExists(caller, paramVal)>
                    <!--- Caller sayfasındaki değişkeni kullan --->
                    <cfset conditions_struct[paramKey] = caller[paramVal]>
                <cfelse>
                    <!--- Literal string olarak kullan --->
                    <cfset conditions_struct[paramKey] = paramVal>
                </cfif>

                <cfcatch>
                    <!--- Hata durumunda yine de literal değeri kullan --->
                    <cfset conditions_struct[paramKey] = paramVal>
                </cfcatch>
            </cftry>
        </cfloop>
    </cfif>

    <!--- Fonksiyon çağrısı: "nesne:metod" formatı gerektirir --->
    <cfif find(":", attributes.function)>
        <cfset funct_object = listFirst(attributes.function, ":")>
        <cfset funct_name   = listLast(attributes.function, ":")>

        <cfif find(".", funct_object)>
            <!--- Nokta içeriyorsa CFC dosya yoludur — yeni nesne oluştur --->
            <cftry>
                <cfset funct_instance = createObject("component", funct_object)>
                <cfset caller[attributes.asname] = invoke(funct_instance, funct_name, conditions_struct)>
                <cfcatch>
                    <cfset caller[attributes.asname] = "">
                    <cflog file="application" type="error"
                           text="box_data.cfm CFC hata: #funct_object#.#funct_name# - #cfcatch.message#">
                </cfcatch>
            </cftry>
        <cfelse>
            <!--- Nokta içermiyorsa caller sayfasındaki mevcut CFC nesnesidir --->
            <cfif structKeyExists(caller, funct_object)>
                <cftry>
                    <cfset caller[attributes.asname] = invoke(caller[funct_object], funct_name, conditions_struct)>
                    <cfcatch>
                        <cfset caller[attributes.asname] = "">
                        <cflog file="application" type="error"
                               text="box_data.cfm local invoke hata: #funct_object#.#funct_name# - #cfcatch.message#">
                    </cfcatch>
                </cftry>
            <cfelse>
                <cfset caller[attributes.asname] = "">
                <cflog file="application" type="warning"
                       text="box_data.cfm: '#funct_object#' caller sayfasında tanımlı değil.">
            </cfif>
        </cfif>
    </cfif>

</cfif>
