<cfprocessingdirective pageEncoding="utf-8">
<cfsetting requestTimeout="60">

<!--- TCMB'den güncel döviz kurlarını çek ve sisteme kaydet --->
<cfparam name="url.ajax" default="0">

<cfset result = {
    "success": false,
    "message": "",
    "updated": []
}>

<cftry>
    <!--- TCMB XML URL --->
    <cfset tcmbURL = "https://www.tcmb.gov.tr/kurlar/today.xml">
    
    <!--- XML'i çek --->
    <cfhttp url="#tcmbURL#" method="GET" timeout="30" result="httpResult">
    </cfhttp>
    
    <cfif httpResult.statusCode eq "200 OK">
        <!--- XML'i parse et --->
        <cfset xmlData = xmlParse(httpResult.fileContent)>
        <cfset tarihDate = xmlData.Tarih_Date.XmlAttributes.Tarih>
        
        <!--- Sistemdeki para birimlerini al --->
        <cfquery name="getMoneys" datasource="boyahane">
            SELECT money_id, money, currency_code 
            FROM setup_money 
            WHERE money_status = true 
            AND money != 'TRY'
            ORDER BY money
        </cfquery>
        
        <!--- Her para birimi için kur güncelle --->
        <cfloop query="getMoneys">
            <cfset currentMoney = money>
            <cfset currentCode = currency_code ?: money>
            <cfset kurFound = false>
            
            <!--- XML'deki Currency node'larını tara --->
            <cfloop array="#xmlData.Tarih_Date.Currency#" index="currency">
                <cfset kod = currency.XmlAttributes.CurrencyCode>
                
                <cfif kod eq currentCode>
                    <cfset kurFound = true>
                    
                    <!--- Kurları al --->
                    <cfset forexBuying = 0>
                    <cfset forexSelling = 0>
                    <cfset banknoteBuying = 0>
                    <cfset banknoteSelling = 0>
                    
                    <cfif structKeyExists(currency, "ForexBuying") AND len(currency.ForexBuying.XmlText)>
                        <cfset forexBuying = val(replace(currency.ForexBuying.XmlText, ",", ".", "all"))>
                    </cfif>
                    <cfif structKeyExists(currency, "ForexSelling") AND len(currency.ForexSelling.XmlText)>
                        <cfset forexSelling = val(replace(currency.ForexSelling.XmlText, ",", ".", "all"))>
                    </cfif>
                    <cfif structKeyExists(currency, "BanknoteBuying") AND len(currency.BanknoteBuying.XmlText)>
                        <cfset banknoteBuying = val(replace(currency.BanknoteBuying.XmlText, ",", ".", "all"))>
                    </cfif>
                    <cfif structKeyExists(currency, "BanknoteSelling") AND len(currency.BanknoteSelling.XmlText)>
                        <cfset banknoteSelling = val(replace(currency.BanknoteSelling.XmlText, ",", ".", "all"))>
                    </cfif>
                    
                    <!--- Ortalama hesapla --->
                    <cfset avgRate = (forexBuying + forexSelling) / 2>
                    
                    <!--- setup_money'yi güncelle --->
                    <cfquery datasource="boyahane">
                        UPDATE setup_money SET
                            rate1 = <cfqueryparam value="#forexBuying#" cfsqltype="cf_sql_numeric">,
                            rate2 = <cfqueryparam value="#forexSelling#" cfsqltype="cf_sql_numeric">,
                            rate3 = <cfqueryparam value="#avgRate#" cfsqltype="cf_sql_numeric">,
                            effective_pur = <cfqueryparam value="#banknoteBuying#" cfsqltype="cf_sql_numeric">,
                            effective_sale = <cfqueryparam value="#banknoteSelling#" cfsqltype="cf_sql_numeric">,
                            dsp_rate_sale = <cfqueryparam value="#forexSelling#" cfsqltype="cf_sql_numeric">,
                            dsp_rate_pur = <cfqueryparam value="#forexBuying#" cfsqltype="cf_sql_numeric">,
                            dsp_effective_sale = <cfqueryparam value="#banknoteSelling#" cfsqltype="cf_sql_numeric">,
                            dsp_effective_pur = <cfqueryparam value="#banknoteBuying#" cfsqltype="cf_sql_numeric">,
                            dsp_update_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                            update_date = <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                            update_emp = <cfqueryparam value="#structKeyExists(session,'user') ? session.user.id : 0#" cfsqltype="cf_sql_integer">
                        WHERE money_id = <cfqueryparam value="#money_id#" cfsqltype="cf_sql_integer">
                    </cfquery>
                    
                    <!--- money_history'ye kaydet --->
                    <cfquery datasource="boyahane">
                        INSERT INTO money_history (
                            money, rate1, rate2, rate3, 
                            effective_pur, effective_sale,
                            validate_date, validate_hour,
                            ratepp2, ratepp3,
                            record_date, record_emp
                        ) VALUES (
                            <cfqueryparam value="#currentMoney#" cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#forexBuying#" cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#forexSelling#" cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#avgRate#" cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#banknoteBuying#" cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#banknoteSelling#" cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#tarihDate#" cfsqltype="cf_sql_timestamp">,
                            <cfqueryparam value="#timeFormat(now(), 'HH:mm')#" cfsqltype="cf_sql_varchar">,
                            <cfqueryparam value="#banknoteBuying#" cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#banknoteSelling#" cfsqltype="cf_sql_numeric">,
                            <cfqueryparam value="#now()#" cfsqltype="cf_sql_timestamp">,
                            <cfqueryparam value="#structKeyExists(session,'user') ? session.user.id : 0#" cfsqltype="cf_sql_integer">
                        )
                    </cfquery>
                    
                    <cfset arrayAppend(result.updated, {
                        "money": currentMoney,
                        "code": currentCode,
                        "forexBuying": forexBuying,
                        "forexSelling": forexSelling,
                        "banknoteBuying": banknoteBuying,
                        "banknoteSelling": banknoteSelling
                    })>
                    
                    <cfbreak>
                </cfif>
            </cfloop>
        </cfloop>
        
        <cfset result.success = true>
        <cfset result.message = "#arrayLen(result.updated)# para birimi güncellendi (Tarih: #dateFormat(tarihDate, 'dd/mm/yyyy')#)">
        
    <cfelse>
        <cfset result.message = "TCMB'ye bağlanılamadı. HTTP Status: #httpResult.statusCode#">
    </cfif>
    
    <cfcatch type="any">
        <cfset result.message = "Hata: #cfcatch.message# - #cfcatch.detail#">
    </cfcatch>
</cftry>

<!--- AJAX isteği ise JSON dön --->
<cfif val(url.ajax) eq 1>
    <cfcontent type="application/json" reset="true">
    <cfoutput>#serializeJSON(result)#</cfoutput>
    <cfabort>
</cfif>

<!--- Normal sayfa --->
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-sync-alt"></i></div>
        <div class="page-header-title">
            <h1>TCMB Kur Güncelleme</h1>
            <p>Merkez Bankası güncel döviz kurlarını çek</p>
        </div>
    </div>
    <a href="/index.cfm?fuseaction=setup.list_money" class="btn-back">
        <i class="fas fa-arrow-left"></i>Para Birimleri
    </a>
</div>

<div class="px-3 pb-4">
    <cfoutput>
    <div class="alert alert-#result.success ? 'success' : 'danger'# alert-dismissible fade show" role="alert">
        <i class="fas fa-#result.success ? 'check-circle' : 'exclamation-circle'# me-2"></i>
        <strong>#result.message#</strong>
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    
    <cfif result.success AND arrayLen(result.updated) gt 0>
        <div class="grid-card">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-money-bill-wave me-2"></i>Güncellenen Kurlar</div>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover table-sm mb-0">
                        <thead class="table-light">
                            <tr>
                                <th>Para Birimi</th>
                                <th>Kod</th>
                                <th class="text-end">Döviz Alış</th>
                                <th class="text-end">Döviz Satış</th>
                                <th class="text-end">Efektif Alış</th>
                                <th class="text-end">Efektif Satış</th>
                            </tr>
                        </thead>
                        <tbody>
                            <cfloop array="#result.updated#" index="item">
                            <tr>
                                <td><strong>#item.money#</strong></td>
                                <td><span class="badge bg-secondary">#item.code#</span></td>
                                <td class="text-end">#numberFormat(item.forexBuying, '9.9999')#</td>
                                <td class="text-end">#numberFormat(item.forexSelling, '9.9999')#</td>
                                <td class="text-end">#numberFormat(item.banknoteBuying, '9.9999')#</td>
                                <td class="text-end">#numberFormat(item.banknoteSelling, '9.9999')#</td>
                            </tr>
                            </cfloop>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        
        <div class="text-center mt-3">
            <a href="/index.cfm?fuseaction=setup.list_money" class="btn btn-primary">
                <i class="fas fa-list me-2"></i>Para Birimleri Listesine Dön
            </a>
            <button type="button" class="btn btn-success" onclick="location.reload()">
                <i class="fas fa-sync-alt me-2"></i>Tekrar Güncelle
            </button>
        </div>
    </cfif>
    </cfoutput>
</div>
