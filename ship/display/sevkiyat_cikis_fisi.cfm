<cfprocessingdirective pageEncoding="utf-8">
<cfset shipId = isDefined("url.ship_id") AND isNumeric(url.ship_id) ? val(url.ship_id) : 0>

<cfif shipId lte 0>
    <div style="padding:20px;color:#b91c1c;font-family:Arial">Geçerli bir sevkiyat seçilmedi (ship_id gerekli).</div>
    <cfabort>
</cfif>

<cfquery name="getSlip" datasource="boyahane">
    SELECT s.ship_id, s.ship_number, s.ship_date, s.record_date, s.hk_metre, s.hk_kg, s.hk_top_adedi,
           COALESCE(c.nickname, c.fullname, '') AS company_name,
           COALESCE(c.member_code, '') AS member_code,
           o.order_id, COALESCE(o.order_number, '') AS order_number, COALESCE(o.ref_no, '') AS ref_no,
           COALESCE(o.order_head, '') AS order_head, o.order_date,
           COALESCE(o.main_color, '') AS main_color,
           '' AS plan_sarj_no,
           '' AS inditex_po1,
           '' AS inditex_po2,
           '' AS inditex_rn,
           COALESCE((
               SELECT ci.renk_no
               FROM order_row orw
               LEFT JOIN color_info ci ON ci.stock_id = orw.stock_id
               WHERE orw.order_id = o.order_id AND COALESCE(ci.renk_no, '') <> ''
               ORDER BY orw.order_row_id
               LIMIT 1
           ), '') AS order_renk_no,
           COALESCE(o.kumas_tipi, '') AS order_kumas_tipi,
           COALESCE((
               SELECT p.product_name
               FROM ship_row sr
               LEFT JOIN product p ON p.product_id = sr.product_id
               WHERE sr.ship_id = s.ship_id
               ORDER BY sr.ship_row_id
               LIMIT 1
           ), '') AS product_name,
           COALESCE((
               SELECT p.kumas_tipi
               FROM ship_row sr
               LEFT JOIN product p ON p.product_id = sr.product_id
               WHERE sr.ship_id = s.ship_id
               ORDER BY sr.ship_row_id
               LIMIT 1
           ), '') AS product_kumas_tipi
    FROM ship s
    LEFT JOIN company c ON c.company_id = s.company_id
    LEFT JOIN LATERAL (
        SELECT o1.*
        FROM orders o1
        WHERE o1.ref_ship_id = s.ship_id
           OR (o1.ref_ship_id IS NULL AND o1.ref_no IS NOT NULL AND o1.ref_no <> '' AND o1.ref_no = s.ship_number)
        ORDER BY o1.order_id
        LIMIT 1
    ) o ON true
    WHERE s.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getSlip.recordCount>
    <div style="padding:20px;color:#b91c1c;font-family:Arial">Sevkiyat bulunamadı (#shipId#).</div>
    <cfabort>
</cfif>

<cfquery name="getRolls" datasource="boyahane">
    SELECT sr.roll_no, sr.metre, sr.kg, COALESCE(sr.paket_durumu, '') AS hata
    FROM ship_roll sr
    LEFT JOIN orders o ON o.order_id = sr.order_id
    WHERE sr.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
       OR sr.order_id IN (
           SELECT o2.order_id
           FROM orders o2
           WHERE o2.ref_ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
              OR (o2.ref_ship_id IS NULL AND o2.ref_no IS NOT NULL AND o2.ref_no <> '' AND o2.ref_no = <cfqueryparam value="#getSlip.ship_number#" cfsqltype="cf_sql_varchar">)
       )
    ORDER BY COALESCE(sr.roll_no, 0), sr.roll_id
</cfquery>

<cfset totalMetre = 0>
<cfset totalKg = 0>
<cfloop query="getRolls">
    <cfset totalMetre += isNumeric(metre) ? val(metre) : 0>
    <cfset totalKg += isNumeric(kg) ? val(kg) : 0>
</cfloop>
<cfset hamMetre = isNumeric(getSlip.hk_metre) ? val(getSlip.hk_metre) : 0>
<cfset hamKg = isNumeric(getSlip.hk_kg) ? val(getSlip.hk_kg) : 0>
<cfset cekmeMt = hamMetre gt 0 ? ((hamMetre - totalMetre) / hamMetre) * 100 : 0>
<cfset cekmeKg = hamKg gt 0 ? ((hamKg - totalKg) / hamKg) * 100 : 0>
<cfset grMtul = totalMetre gt 0 ? (totalKg * 1000 / totalMetre) : 0>

<cfoutput>
<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Sevkiyat Çıkış Fişi - #xmlFormat(getSlip.ship_number)#</title>
<style>
@page { size:A4 portrait; margin:10mm; }
* { box-sizing:border-box; }
body { margin:0; background:##f3f4f6; color:##111827; font-family:Arial, Helvetica, sans-serif; }
.no-print { margin:12px auto; width:190mm; display:flex; gap:8px; }
.no-print button { padding:8px 14px; font-weight:700; cursor:pointer; }
.sheet { width:190mm; min-height:270mm; margin:0 auto 16px; background:##fff; padding:8mm; }
.slip { border:2px solid ##111827; }
.header { display:grid; grid-template-columns:44mm 1fr 48mm; align-items:center; border-bottom:2px solid ##111827; min-height:16mm; }
.brand { font-family:Georgia,serif; font-style:italic; font-weight:700; font-size:24px; padding-left:5mm; text-decoration:underline; }
.title { text-align:center; font-size:29px; font-weight:900; letter-spacing:.04em; }
.head-info { font-size:13px; font-weight:700; line-height:1.7; padding:2mm 4mm; }
.info { display:grid; grid-template-columns:1fr 1fr; border-bottom:2px solid ##111827; min-height:42mm; }
.info-col { padding:2mm 3mm; font-size:13px; }
.info-row { display:grid; grid-template-columns:28mm 4mm 1fr; min-height:6mm; align-items:center; }
.info-row .value { font-weight:800; font-size:16px; }
.info-row.big .value { font-size:18px; }
.ham-row { display:grid; grid-template-columns:1fr 1fr 1fr; gap:4mm; padding:1mm 3mm 2mm; font-size:20px; font-weight:900; }
.content { display:grid; grid-template-columns:112mm 1fr; gap:4mm; padding:1mm 3mm 2mm; }
table { border-collapse:collapse; width:100%; }
.roll-table th, .roll-table td { border:1.5px solid ##111827; height:7mm; font-size:13px; padding:1mm; }
.roll-table th { text-align:center; font-weight:900; }
.roll-table td:nth-child(1), .roll-table td:nth-child(5) { text-align:center; width:8mm; }
.roll-table td:nth-child(2), .roll-table td:nth-child(3), .roll-table td:nth-child(6), .roll-table td:nth-child(7) { text-align:right; }
.side-title { border:1.5px solid ##111827; text-align:center; font-weight:900; padding:1mm; font-size:15px; }
.ops td { border:1.5px solid ##111827; height:7mm; font-size:15px; font-weight:800; padding:1mm 2mm; }
.ops td:last-child { width:22mm; text-align:center; }
.totals-title { margin-top:7mm; font-weight:900; font-size:16px; }
.totals th, .totals td { border:1.5px solid ##111827; height:7mm; font-size:13px; padding:1mm 2mm; }
.totals th { text-align:center; font-size:16px; }
.totals td:first-child { font-weight:900; }
.totals td:last-child { text-align:right; font-weight:800; }
.note { font-size:11px; font-weight:800; padding:1mm 3mm 0; }
.sign { display:grid; grid-template-columns:1fr 1fr; text-align:center; margin-top:3mm; font-size:12px; font-weight:900; text-decoration:underline; }
@media print { body { background:##fff; } .no-print { display:none; } .sheet { margin:0; padding:0; width:auto; min-height:auto; } }
</style>
</head>
<body>
<div class="no-print"><button onclick="window.print()">Yazdır</button><button onclick="window.close()">Kapat</button></div>
<div class="sheet">
    <div class="slip">
        <div class="header">
            <div class="brand">Rasih Çelik</div>
            <div class="title">SEVKİYAT ÇIKIŞ FİŞİ</div>
            <div class="head-info">
                <div>Tarih : #isDate(getSlip.ship_date) ? dateFormat(getSlip.ship_date,'dd.mm.yyyy') : dateFormat(now(),'dd.mm.yyyy')#</div>
                <div>Sevk No : #xmlFormat(getSlip.ship_number ?: getSlip.ship_id)#</div>
            </div>
        </div>
        <div class="info">
            <div class="info-col">
                <div class="info-row big"><span>Firma İsmi</span><span>:</span><span class="value">#xmlFormat(getSlip.company_name ?: '')#</span></div>
                <div class="info-row"><span>Giriş EvrakNo</span><span>:</span><span class="value">#xmlFormat(getSlip.ref_no ?: '')#</span></div>
                <div class="info-row"><span>Giriş EvrakNo2</span><span>:</span><span class="value"></span></div>
                <div class="info-row"><span>İnditexPO1</span><span>:</span><span class="value">#xmlFormat(getSlip.inditex_po1 ?: '')#</span></div>
                <div class="info-row big"><span>Kumaş</span><span>:</span><span class="value">#xmlFormat(len(getSlip.product_kumas_tipi ?: '') ? getSlip.product_kumas_tipi : (len(getSlip.order_kumas_tipi ?: '') ? getSlip.order_kumas_tipi : getSlip.product_name))#</span></div>
                <div class="info-row big"><span>RenkNo/Adı</span><span>:</span><span class="value">#xmlFormat(trim((getSlip.order_renk_no ?: '') & ' / ' & (getSlip.main_color ?: '')))#</span></div>
            </div>
            <div class="info-col">
                <div class="info-row big"><span>Parti Kodu</span><span>:</span><span class="value">#xmlFormat(getSlip.order_number ?: '')#</span></div>
                <div class="info-row big"><span>Parti RN</span><span>:</span><span class="value">#xmlFormat(getSlip.inditex_rn ?: '')#</span></div>
                <div class="info-row big"><span>PlanŞarj No</span><span>:</span><span class="value">#xmlFormat(getSlip.plan_sarj_no ?: '')#</span></div>
                <div class="info-row big"><span>Giriş Tarihi</span><span>:</span><span class="value">#isDate(getSlip.order_date) ? dateFormat(getSlip.order_date,'dd.mm.yyyy') : ''#</span></div>
                <div class="info-row"><span>İnditexPO2</span><span>:</span><span class="value">#xmlFormat(getSlip.inditex_po2 ?: '')#</span></div>
                <div class="info-row big" style="justify-content:end;display:flex;padding-top:4mm;"><span class="value">R - #numberFormat(grMtul,'0.00')#</span></div>
            </div>
        </div>
        <div class="ham-row">
            <div>Ham Mt : #numberFormat(hamMetre,'0.00')#</div>
            <div>Ham Kg: #numberFormat(hamKg,'0.00')#</div>
            <div></div>
        </div>
        <div class="content">
            <table class="roll-table">
                <thead><tr><th>Top</th><th>Metre</th><th>Kg</th><th>Hata</th><th>Top</th><th>Metre</th><th>Kg</th><th>Hata</th></tr></thead>
                <tbody>
                <cfloop from="1" to="25" index="i">
                    <tr>
                        <cfset leftRow = i>
                        <cfset rightRow = i + 25>
                        <td>#leftRow#</td>
                        <cfif getRolls.recordCount gte leftRow>
                            <td>#numberFormat(val(getRolls.metre[leftRow]),'0.00')#</td><td>#numberFormat(val(getRolls.kg[leftRow]),'0.00')#</td><td>#xmlFormat(getRolls.hata[leftRow] ?: '')#</td>
                        <cfelse><td></td><td></td><td></td></cfif>
                        <td>#rightRow#</td>
                        <cfif getRolls.recordCount gte rightRow>
                            <td>#numberFormat(val(getRolls.metre[rightRow]),'0.00')#</td><td>#numberFormat(val(getRolls.kg[rightRow]),'0.00')#</td><td>#xmlFormat(getRolls.hata[rightRow] ?: '')#</td>
                        <cfelse><td></td><td></td><td></td></cfif>
                    </tr>
                </cfloop>
                </tbody>
            </table>
            <div>
                <div class="side-title">İLAVE İŞLEMLER</div>
                <table class="ops">
                    <cfset ops = ['ÖN FİKSE','GAZE','SANFOR','KALENDER','K.D.','ŞARDON','MAKAS','ŞARDON APRE','SU GEÇMEZ','İNCELTME','TÜY DÖKME','YANMAZ']>
                    <cfloop array="#ops#" index="op"><tr><td>#op#</td><td></td></tr></cfloop>
                    <tr><td colspan="2"></td></tr><tr><td colspan="2"></td></tr><tr><td colspan="2"></td></tr>
                </table>
                <div class="totals-title">BOYALI ÇIKIŞ</div>
                <table class="totals">
                    <tr><th colspan="2">TOPLAM</th></tr>
                    <tr><td>Çıkış MT</td><td>#numberFormat(totalMetre,'0.00')#</td></tr>
                    <tr><td>Çıkış KG</td><td>#numberFormat(totalKg,'0.00')#</td></tr>
                    <tr><td>Top Adedi</td><td>#getRolls.recordCount#</td></tr>
                    <tr><td>Çekme/Fire Mt</td><td>%#numberFormat(cekmeMt,'0.00')#</td></tr>
                    <tr><td>Çekme/Fire Kg</td><td>%#numberFormat(cekmeKg,'0.00')#</td></tr>
                    <tr><td>Çıkış Gr/Mtül</td><td>#numberFormat(grMtul,'0.00')#</td></tr>
                </table>
            </div>
        </div>
        <div class="note">DİKKAT : İş bu belge muhteviyatı 7 (Yedi) gün içinde itiraz edilmediği takdirde kabul edilmiş sayılır.</div>
    </div>
    <div class="sign"><div>TESLİM EDEN</div><div>TESLİM ALAN</div></div>
</div>
<script>window.addEventListener('load', function(){ setTimeout(function(){ window.print(); }, 300); });</script>
</body>
</html>
</cfoutput>
