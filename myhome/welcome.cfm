<cfprocessingdirective pageEncoding="utf-8">

<!--- Döviz kurları (TCMB XML) --->
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


<div class="px-3 pb-5">
<div class="row g-3">

    <!--- SOL: Güncel Kurlar --->
    <div class="col-12 col-sm-6 col-lg-3">
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
    </div>

    <!--- ORTA: Kısayollar --->
    <div class="col-12 col-sm-12 col-lg-6">
        <div class="grid-card h-100">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-bookmark"></i>Kısayollarım</div>
            </div>
            <div class="card-body p-3">
                <cfif getUserFavorites.recordCount gt 0>
                    <cfset favColors = ["##6366f1","##0ea5e9","##10b981","##f59e0b","##ef4444","##8b5cf6","##ec4899","##14b8a6","##f97316","##84cc16"]>
                    <div class="row g-2">
                        <cfloop query="getUserFavorites">
                        <cfset ci = ((currentRow - 1) mod arrayLen(favColors)) + 1>
                        <cfset cc = favColors[ci]>
                        <div class="col-6 col-sm-3 col-md-2 col-lg-1">
                            <a href="index.cfm?fuseaction=#fuseaction#" class="text-decoration-none">
                                <div class="grid-card welcome-fav-card" style="--fav-color:#cc#">
                                    <i class="#htmlEditFormat(page_icon)# welcome-fav-icon"></i>
                                    <div class="welcome-fav-title fw-semibold">#htmlEditFormat(page_title)#</div>
                                </div>
                            </a>
                        </div>
                        </cfloop>
                    </div>
                <cfelse>
                    <div class="p-4 text-center text-muted">
                        <i class="fas fa-star fa-2x mb-3 d-block" style="opacity:.3"></i>
                        <div>Henüz kısayol eklenmemiş.</div>
                        <div class="small mt-1">Sayfa başlığındaki <i class="fas fa-star"></i> simgesine basarak kısayol ekleyin.</div>
                    </div>
                </cfif>
            </div>
        </div>
    </div>

    <!--- SAĞ: (ileride doldurulur) --->
    <div class="col-12 col-sm-6 col-lg-3">
        <div class="grid-card h-100">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-bell"></i>Bildirimler</div>
            </div>
            <div class="card-body p-3 text-muted text-center small">
                <i class="fas fa-inbox fa-2x mb-2 d-block" style="opacity:.25"></i>
                Yeni bildirim yok.
            </div>
        </div>
    </div>

</div><!--- row --->
</div><!--- px-3 --->

<style>
.welcome-fav-card {
    aspect-ratio: 1 / 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: .15rem;
    padding: .35rem;
    text-align: center;
    transition: transform .15s, box-shadow .15s;
    cursor: pointer;
}
.welcome-fav-card:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0,0,0,.1);
}
.welcome-fav-icon { color: var(--fav-color, ##4f46e5); font-size: .9rem; }
.welcome-fav-title { color: ##374151; line-height: 1.2; font-size: .6rem; }
.welcome-fav-card { border-top: 3px solid var(--fav-color, ##4f46e5); }
.welcome-kur-table th { font-size: .7rem; color: ##6b7280; font-weight: 600; border-bottom: 1px solid ##e5e7eb; padding: .4rem .75rem; }
.welcome-kur-table td { font-size: .8rem; padding: .35rem .75rem; border-bottom: 1px solid ##f3f4f6; }
.welcome-kur-code { font-weight: 700; color: var(--color-primary, ##4f46e5); }
</style>
</cfoutput>
