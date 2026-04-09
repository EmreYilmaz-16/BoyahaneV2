<cfset kurlar = []>
<cftry>
    <cfhttp url="https://www.tcmb.gov.tr/kurlar/today.xml" method="get" timeout="5" result="tcmbRes">
    <cfif tcmbRes.statusCode eq "200 OK">
        <cfset xmlDoc = xmlParse(tcmbRes.fileContent)>
        <cfset currencies = ["USD","EUR","GBP","CHF","SAR","JPY"]>
        <cfloop array="#currencies#" index="cur">
            <cfset nodes = xmlSearch(xmlDoc, "//Currency[@CurrencyCode='#cur#']")>
            <cfif arrayLen(nodes)>
                <cfset n = nodes[1]>
                <cfset forexBuying  = isDefined("n.ForexBuying.xmlText")  AND len(trim(n.ForexBuying.xmlText))  ? val(n.ForexBuying.xmlText)  : 0>
                <cfset forexSelling = isDefined("n.ForexSelling.xmlText") AND len(trim(n.ForexSelling.xmlText)) ? val(n.ForexSelling.xmlText) : 0>
                <cfset curName = isDefined("n.xmlAttributes.CurrencyName") ? n.xmlAttributes.CurrencyName : cur>
                <cfif forexSelling gt 0>
                    <cfset arrayAppend(kurlar, {
                        code    : cur,
                        name    : curName,
                        buying  : forexBuying,
                        selling : forexSelling
                    })>
                </cfif>
            </cfif>
        </cfloop>
    </cfif>
    <cfcatch></cfcatch>
</cftry>
<cfoutput>
<div class="grid-card h-100">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-chart-line"></i>Güncel Kurlar</div>
                <span class="text-muted" style="font-size:.7rem">TCMB</span>
            </div>
            <div class="card-body p-0">
                <cfif arrayLen(kurlar)>
                <table class="table table-sm mb-0 welcome-kur-table">
                    <thead>
                        <tr>
                            <th></th>
                            <th class="text-end">Alış</th>
                            <th class="text-end">Satış</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop array="#kurlar#" index="k">
                        <tr>
                            <td><span class="welcome-kur-code">#k.code#</span></td>
                            <td class="text-end">#numberFormat(k.buying,  "_.___,__")#</td>
                            <td class="text-end fw-semibold">#numberFormat(k.selling, "_.___,__")#</td>
                        </tr>
                        </cfloop>
                    </tbody>
                </table>
                <cfelse>
                <div class="p-3 text-muted text-center small">Kur bilgisi alınamadı.</div>
                </cfif>
            </div>
        </div>
        </cfoutput>