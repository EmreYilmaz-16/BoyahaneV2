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

<cfquery name="companyShipStats" datasource="boyahane">
    SELECT
        sum(hk_metre)     AS hk_metre,
        sum(hk_kg)        AS hk_kg,
        sum(hk_top_adedi) AS hk_top_adedi,
        sum(parti_metre)  AS parti_metre,
        company_id,
        company_name
    FROM (
        SELECT
            s.ship_id,
            s.hk_metre,
            s.hk_kg,
            s.hk_top_adedi,
            COALESCE(c.nickname, c.fullname, '') AS company_name,
            c.company_id,
            COALESCE((
                SELECT SUM(orw.quantity)
                FROM orders o
                JOIN order_row orw ON o.order_id = orw.order_id
                WHERE o.ref_no = s.ship_number
                  AND s.ship_number <> ''
                  AND orw.product_id = (
                      SELECT sr2.product_id FROM ship_row sr2
                      WHERE sr2.ship_id = s.ship_id
                      ORDER BY sr2.ship_row_id LIMIT 1
                  )
            ), 0) AS parti_metre
        FROM ship s
        LEFT JOIN company c ON s.company_id = c.company_id
        WHERE s.ship_type = 5
    ) sk
    GROUP BY company_id, company_name
    ORDER BY company_name
</cfquery>

<cfoutput>


<div class="px-3 pb-5">
<div class="row g-3">

    <!--- SOL: Güncel Kurlar --->
    <div class="col-12 col-sm-6 col-lg-4" id="solcol">
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

     <!--- SAĞ: (ileride doldurulur) --->
    <div class="col-12 col-sm-6 col-lg-5">
        <div class="grid-card h-100">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-bell"></i>Bildirimler</div>
            </div>
            <div class="card-body p-3 text-muted text-center small">
                <i class="fas fa-inbox fa-2x mb-2 d-block" style="opacity:.25"></i>
                Yeni bildirim yok.
            </div>
        </div>
    <!---   <cf_box title="Bildirimler" add_href="index.cfm?fuseaction=product.add_product"></cf_box>---->
    </div>

    <!--- ORTA: Kısayollar --->
    <div class="col-12 col-sm-12 col-lg-3">
        <div class="grid-card h-100">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-bookmark"></i>Kısayollarım</div>
            </div>
            <div class="card-body p-3">
                <cfif getUserFavorites.recordCount gt 0>
                    <cfset favColors = ["##6366f1","##0ea5e9","##10b981","##f59e0b","##ef4444","##8b5cf6","##ec4899","##14b8a6","##f97316","##84cc16"]>
                    <div class="row g-2" <!----style="overflow: scroll;max-height: 15rem;"---->>
                        <cfloop query="getUserFavorites">
                        <cfset ci = ((currentRow - 1) mod arrayLen(favColors)) + 1>
                        <cfset cc = favColors[ci]>
                        <div class="col-4">
                            <a href="index.cfm?fuseaction=#fuseaction#" class="text-decoration-none">
                                <div class="welcome-fav-card" style="--fav-color:#cc#">
                                    <div class="welcome-fav-icon-wrap">
                                        <i class="far fa-star"></i>
                                    </div>
                                    <div class="welcome-fav-title">#htmlEditFormat(page_title)#</div>
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

   

</div><!--- row --->

<!--- Boyahane İş Özeti (ship_type=5) --->
<div class="row g-3 mt-3">
    <div class="col-12 col-sm-6 col-lg-4">
        <div class="grid-card">
            <div class="grid-card-header">
                <div class="grid-card-header-title"><i class="fas fa-industry"></i>Boyahane İş Özeti (Firmaya Göre)</div>
            </div>
            <div class="card-body p-0">
                <cfif companyShipStats.recordCount gt 0>
                <cfset tot_metre = 0><cfset tot_kg = 0><cfset tot_top = 0><cfset tot_parti = 0><cfset tot_kalan = 0><cfset max_kalan = 0>
                <cfloop query="companyShipStats">
                    <cfset tot_metre  = tot_metre  + val(hk_metre)>
                    <cfset tot_kg     = tot_kg     + val(hk_kg)>
                    <cfset tot_top    = tot_top    + val(hk_top_adedi)>
                    <cfset tot_parti  = tot_parti  + val(parti_metre)>
                    <cfset _k = val(hk_metre) - val(parti_metre)>
                    <cfset tot_kalan  = tot_kalan  + _k>
                    <cfif _k gt max_kalan><cfset max_kalan = _k></cfif>
                </cfloop>
                <div class="table-responsive">
                <table class="table table-sm table-hover mb-0 welcome-ship-stats-table">
                    <thead>
                        <tr>
                            <th>Firma</th>
                            <th class="text-end">Ham Kumaş Metre</th>
                            <th class="text-end">Ham Kumaş Kg</th>
                            <th class="text-end">Ham Kumaş Top Adedi</th>
                            <th class="text-end">Partilenen Metre</th>
                            <th class="text-end">Kalan Metre</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfloop query="companyShipStats">
                        <cfset row_kalan = val(hk_metre) - val(parti_metre)>
                        <cfset kalan_pct = (max_kalan gt 0) ? (row_kalan / max_kalan * 100) : 0>
                        <cfif kalan_pct lte 25>
                            <cfset kalan_cls = "kalan-green">
                        <cfelseif kalan_pct lte 50>
                            <cfset kalan_cls = "kalan-yellow">
                        <cfelseif kalan_pct lte 75>
                            <cfset kalan_cls = "kalan-orange">
                        <cfelse>
                            <cfset kalan_cls = "kalan-red">
                        </cfif>
                        <tr>
                            <td>#htmlEditFormat(company_name)#</td>
                            <td class="text-end">#numberFormat(hk_metre,  "_.,00")#</td>
                            <td class="text-end">#numberFormat(hk_kg,     "_.,00")#</td>
                            <td class="text-end">#numberFormat(hk_top_adedi, "_,")#</td>
                            <td class="text-end">#numberFormat(parti_metre,  "_.,00")#</td>
                            <td class="text-end #kalan_cls#">#numberFormat(row_kalan, "_.,00")#</td>
                        </tr>
                        </cfloop>
                    </tbody>
                    <tfoot>
                        <tr class="fw-bold table-light">
                            <td>TOPLAM</td>
                            <td class="text-end">#numberFormat(tot_metre,  "_.,00")#</td>
                            <td class="text-end">#numberFormat(tot_kg,     "_.,00")#</td>
                            <td class="text-end">#numberFormat(tot_top,    "_,")#</td>
                            <td class="text-end">#numberFormat(tot_parti,  "_.,00")#</td>
                            <td class="text-end">#numberFormat(tot_kalan,  "_.,00")#</td>
                        </tr>
                    </tfoot>
                </table>
                </div>
                <cfelse>
                <div class="p-3 text-muted text-center small">Kayıt bulunamadı.</div>
                </cfif>
            </div>
        </div>
    </div>
    <div class="col-12 col-sm-12 col-lg-5"></div>
    <div class="col-12 col-sm-6 col-lg-3"></div>
        <!--- İleride buraya boyahane ile ilgili grafikler konulabilir --->
</div><!--- ship stats row --->


</div><!--- px-3 --->

<style>
.welcome-fav-card {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: .35rem;
    padding: .5rem .25rem;
    border-radius: .6rem;
    text-align: center;
    cursor: pointer;
    transition: background .15s, transform .15s, box-shadow .15s;
}
.welcome-fav-card:hover {
    background: rgba(0,0,0,.04);
    transform: translateY(-3px);
    box-shadow: 0 6px 16px rgba(0,0,0,.08);
}
.welcome-fav-icon-wrap {
    width: 2.4rem;
    height: 2.4rem;
    border-radius: 50%;
    background: color-mix(in srgb, var(--fav-color, ##4f46e5) 15%, white);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 1rem;
    color: var(--fav-color, ##4f46e5);
    transition: background .15s, transform .15s;
}
.welcome-fav-card:hover .welcome-fav-icon-wrap {
    background: color-mix(in srgb, var(--fav-color, ##4f46e5) 28%, white);
    transform: scale(1.1);
}
.welcome-fav-title { color: ##374151; line-height: 1.2; font-size: .62rem; font-weight: 600; }
.welcome-kur-table th { font-size: .7rem; color: ##6b7280; font-weight: 600; border-bottom: 1px solid ##e5e7eb; padding: .4rem .75rem; }
.welcome-kur-table td { font-size: .8rem; padding: .35rem .75rem; border-bottom: 1px solid ##f3f4f6; }
.welcome-kur-code { font-weight: 700; color: var(--color-primary, ##4f46e5); }
.welcome-ship-stats-table th { font-size: .75rem; color: ##6b7280; font-weight: 600; border-bottom: 1px solid ##e5e7eb; padding: .4rem .75rem; }
.welcome-ship-stats-table td { font-size: .8rem; padding: .35rem .75rem; border-bottom: 1px solid ##f3f4f6; }
.welcome-ship-stats-table tfoot td { border-top: 2px solid ##e5e7eb; border-bottom: none; font-size: .8rem; padding: .4rem .75rem; }
/* Kalan Metre koşullu renklendirme */
.kalan-green  { background-color: ##dcfce7 !important; color: ##166534 !important; font-weight: 600; }
.kalan-yellow { background-color: ##fef9c3 !important; color: ##854d0e !important; font-weight: 600; }
.kalan-orange { background-color: ##ffedd5 !important; color: ##9a3412 !important; font-weight: 600; }
.kalan-red    { background-color: ##fee2e2 !important; color: ##991b1b !important; font-weight: 600; }
</style>
</cfoutput>
