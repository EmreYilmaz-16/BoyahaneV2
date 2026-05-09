<cfprocessingdirective pageEncoding="utf-8">
<cfcontent type="application/json; charset=utf-8">
<cfsetting showDebugOutput="false">

<cftry>
    <!--- Giriş kontrolü --->
    <cfif not structKeyExists(form, "recordsJSON") or not len(trim(form.recordsJSON))>
        <cfoutput>#serializeJSON({"success":false,"message":"recordsJSON parametresi eksik."})#</cfoutput>
        <cfabort>
    </cfif>

    <cfset records = deserializeJSON(form.recordsJSON)>

    <cfif not isArray(records) or arrayLen(records) eq 0>
        <cfoutput>#serializeJSON({"success":false,"message":"Geçerli kayıt bulunamadı."})#</cfoutput>
        <cfabort>
    </cfif>

    <cfif arrayLen(records) gt 5000>
        <cfoutput>#serializeJSON({"success":false,"message":"Tek seferde en fazla 5.000 kayıt gönderilebilir."})#</cfoutput>
        <cfabort>
    </cfif>

    <cfset updatedCount  = 0>
    <cfset notFoundCount = 0>
    <cfset errorCount    = 0>
    <cfset errors        = []>

    <cfloop array="#records#" index="rec">
        <cftry>
            <!--- Üretici kodu zorunlu --->
            <cfif not structKeyExists(rec, "manufact_code") or not len(trim(rec.manufact_code))>
                <cfset errorCount++>
                <cfset arrayAppend(errors, "Satır " & (structKeyExists(rec,"row_num") ? rec.row_num : "?") & ": Üretici kodu boş.")>
                <cfcontinue>
            </cfif>

            <cfset mCode = trim(rec.manufact_code)>

            <!--- Alan boş/yok flag'leri --->
            <cfset hasEn          = structKeyExists(rec,"en")          and isNumeric(rec.en)>
            <cfset hasTuse        = structKeyExists(rec,"tuse")        and len(trim(rec.tuse))>
            <cfset hasCekme       = structKeyExists(rec,"cekme")       and len(trim(rec.cekme))>
            <cfset hasIsi         = structKeyExists(rec,"isi")         and isNumeric(rec.isi)>
            <cfset hasHiz         = structKeyExists(rec,"hiz")         and isNumeric(rec.hiz)>
            <cfset hasGramaj      = structKeyExists(rec,"gramaj")      and isNumeric(rec.gramaj)>
            <cfset hasBesAvans    = structKeyExists(rec,"besleme_avans") and isNumeric(rec.besleme_avans)>
            <cfset hasKumasTipi   = structKeyExists(rec,"kumas_tipi")  and len(trim(rec.kumas_tipi))>
            <cfset hasKimyassal   = structKeyExists(rec,"kullanilan_kimyassal") and isNumeric(rec.kullanilan_kimyassal)>

            <!--- Herhangi bir güncelleme alanı var mı? --->
            <cfif not (hasEn or hasTuse or hasCekme or hasIsi or hasHiz or hasGramaj or hasBesAvans or hasKumasTipi or hasKimyassal)>
                <cfcontinue>
            </cfif>

            <!--- Ürün var mı? --->
            <cfquery name="qCheck" datasource="boyahane">
                SELECT product_id FROM product
                WHERE manufact_code = <cfqueryparam value="#mCode#" cfsqltype="cf_sql_varchar">
                LIMIT 1
            </cfquery>

            <cfif qCheck.recordCount eq 0>
                <cfset notFoundCount++>
                <cfset arrayAppend(errors, "Satır " & (structKeyExists(rec,"row_num") ? rec.row_num : "?") & ": Üretici kodu bulunamadı — '" & mCode & "'")>
                <cfcontinue>
            </cfif>

            <!--- UPDATE — sadece gönderilen alanlar güncellenir --->
            <cfquery datasource="boyahane">
                UPDATE product SET
                <cfset sep = "">
                <cfif hasEn>
                    #sep#en = <cfqueryparam value="#rec.en#" cfsqltype="cf_sql_double">
                    <cfset sep = ",">
                </cfif>
                <cfif hasTuse>
                    #sep#tuse = <cfqueryparam value="#trim(rec.tuse)#" cfsqltype="cf_sql_varchar">
                    <cfset sep = ",">
                </cfif>
                <cfif hasCekme>
                    #sep#cekme = <cfqueryparam value="#trim(rec.cekme)#" cfsqltype="cf_sql_varchar">
                    <cfset sep = ",">
                </cfif>
                <cfif hasIsi>
                    #sep#isi = <cfqueryparam value="#rec.isi#" cfsqltype="cf_sql_double">
                    <cfset sep = ",">
                </cfif>
                <cfif hasHiz>
                    #sep#hiz = <cfqueryparam value="#rec.hiz#" cfsqltype="cf_sql_double">
                    <cfset sep = ",">
                </cfif>
                <cfif hasGramaj>
                    #sep#gramaj = <cfqueryparam value="#rec.gramaj#" cfsqltype="cf_sql_double">
                    <cfset sep = ",">
                </cfif>
                <cfif hasBesAvans>
                    #sep#besleme_avans = <cfqueryparam value="#rec.besleme_avans#" cfsqltype="cf_sql_double">
                    <cfset sep = ",">
                </cfif>
                <cfif hasKumasTipi>
                    #sep#kumas_tipi = <cfqueryparam value="#trim(rec.kumas_tipi)#" cfsqltype="cf_sql_varchar">
                    <cfset sep = ",">
                </cfif>
                <cfif hasKimyassal>
                    #sep#kullanilan_kimyassal = <cfqueryparam value="#int(rec.kullanilan_kimyassal)#" cfsqltype="cf_sql_integer">
                </cfif>
                WHERE manufact_code = <cfqueryparam value="#mCode#" cfsqltype="cf_sql_varchar">
            </cfquery>

            <cfset updatedCount++>

            <cfcatch type="any">
                <cfset errorCount++>
                <cfset arrayAppend(errors, "Satır " & (structKeyExists(rec,"row_num") ? rec.row_num : "?") & " (" & mCode & "): " & cfcatch.message)>
            </cfcatch>
        </cftry>
    </cfloop>

    <cfoutput>#serializeJSON({
        "success":     true,
        "updated":     updatedCount,
        "not_found":   notFoundCount,
        "error_count": errorCount,
        "errors":      errors
    })#</cfoutput>

    <cfcatch type="any">
        <cfoutput>#serializeJSON({"success":false,"message":cfcatch.message})#</cfoutput>
    </cfcatch>
</cftry>
