<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">

<cftry>
    <cfparam name="form.price_catid" default="0">
    <cfparam name="form.rate"        default="0">
    <cfparam name="form.type"        default="increase">
    <cfparam name="form.rounding"    default="0">

    <cfset catId    = val(form.price_catid)>
    <cfset rate     = val(form.rate)>
    <cfset rounding = val(form.rounding)>
    <cfset changeType = trim(form.type)>

    <cfif catId lte 0>
        <cfoutput>#serializeJSON({"success": false, "message": "Geçersiz fiyat listesi."})#</cfoutput>
        <cfabort>
    </cfif>

    <cfif rate lte 0>
        <cfoutput>#serializeJSON({"success": false, "message": "Geçerli bir oran girilmedi."})#</cfoutput>
        <cfabort>
    </cfif>

    <!--- İzin verilen type değerleri --->
    <cfif changeType neq "increase" AND changeType neq "decrease">
        <cfset changeType = "increase">
    </cfif>

    <!--- Çarpan hesapla: artış = 1 + rate/100, indirim = 1 - rate/100 --->
    <cfset multiplier = (changeType eq "increase") ? (1 + rate / 100) : (1 - rate / 100)>

    <cfif changeType eq "decrease" AND rate gte 100>
        <cfoutput>#serializeJSON({"success": false, "message": "İndirim oranı 100'den küçük olmalıdır."})#</cfoutput>
        <cfabort>
    </cfif>

    <!--- Mevcut fiyatları çek --->
    <cfquery name="getCurrentPrices" datasource="boyahane">
        SELECT price_id, price, price_kdv, tax
        FROM price
        WHERE price_catid = <cfqueryparam value="#catId#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfset updatedCount = 0>

    <cfloop query="getCurrentPrices">
        <cfset oldPrice    = val(price)>
        <cfset oldPriceKdv = val(price_kdv)>
        <cfset taxRate     = val(tax)>

        <!--- Yeni fiyat --->
        <cfset newPrice = oldPrice * multiplier>

        <!--- Yuvarlama uygula (kuruş cinsinden) --->
        <cfif rounding gt 0>
            <!--- Kuruş = rounding / 100 --->
            <cfset roundUnit = rounding / 100>
            <cfset newPrice  = ceiling(newPrice / roundUnit) * roundUnit>
        </cfif>

        <cfset newPriceKdv = newPrice * (1 + taxRate / 100)>

        <cfquery datasource="boyahane">
            UPDATE price SET
                price     = <cfqueryparam value="#newPrice#"    cfsqltype="cf_sql_numeric">,
                price_kdv = <cfqueryparam value="#newPriceKdv#" cfsqltype="cf_sql_numeric">
            WHERE price_id = <cfqueryparam value="#price_id#" cfsqltype="cf_sql_integer">
        </cfquery>

        <cfset updatedCount++>
    </cfloop>

    <cfoutput>#serializeJSON({"success": true, "updated": updatedCount, "multiplier": multiplier})#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success": false, "message": cfcatch.message & " " & cfcatch.detail})#</cfoutput>
    </cfcatch>
</cftry>
