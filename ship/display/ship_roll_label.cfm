<cfprocessingdirective pageEncoding="utf-8">
<cfset rollId = isDefined("url.roll_id") AND isNumeric(url.roll_id) ? val(url.roll_id) : 0>

<cfif rollId lte 0>
    <div style="padding:20px;color:#b91c1c;font-family:Arial">Geçerli bir top seçilmedi (roll_id gerekli).</div>
    <cfabort>
</cfif>

<cfquery name="getRoll" datasource="boyahane">
    SELECT sr.roll_id, sr.roll_no, sr.roll_barcode, sr.metre, sr.kg, sr.paket_durumu,
           sr.etiket_print_count, sr.record_date,
           o.order_number,
           s.ship_number,
           COALESCE(c.nickname, c.fullname, '') AS company_name
    FROM ship_roll sr
    LEFT JOIN orders o  ON sr.order_id = o.order_id
    LEFT JOIN ship s    ON sr.ship_id  = s.ship_id
    LEFT JOIN company c ON o.company_id = c.company_id
    WHERE sr.roll_id = <cfqueryparam value="#rollId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getRoll.recordCount>
    <div style="padding:20px;color:#b91c1c;font-family:Arial">Top kaydı bulunamadı (roll_id: <cfoutput>#rollId#</cfoutput>).</div>
    <cfabort>
</cfif>

<cfoutput>
<!doctype html>
<html lang="tr">
<head>
<meta charset="utf-8">
<title>Top Etiketi - #xmlFormat(getRoll.roll_barcode)#</title>
<style>
@page { size: 100mm 70mm; margin: 5mm; }
* { box-sizing: border-box; }
body { margin:0; font-family: Arial, Helvetica, sans-serif; color:##111827; background:##fff; }
.label { width:90mm; min-height:60mm; border:2px solid ##111827; border-radius:8px; padding:8px; }
.header { display:flex; justify-content:space-between; align-items:flex-start; border-bottom:1px solid ##111827; padding-bottom:5px; margin-bottom:6px; }
.title { font-size:16px; font-weight:800; letter-spacing:.03em; }
.roll-no { font-size:20px; font-weight:800; }
.row { display:flex; justify-content:space-between; gap:8px; margin:4px 0; font-size:12px; }
.row span:first-child { color:##6b7280; font-weight:700; }
.row strong { text-align:right; }
.barcode-box { margin-top:8px; border:1px dashed ##6b7280; padding:8px; text-align:center; font-family:'Courier New', monospace; font-size:15px; font-weight:700; letter-spacing:.08em; overflow-wrap:anywhere; }
.footer { margin-top:6px; font-size:10px; color:##6b7280; display:flex; justify-content:space-between; }
.no-print { margin:12px; }
@media print { .no-print { display:none; } body { background:##fff; } }
</style>
</head>
<body>
<div class="no-print"><button onclick="window.print()">Yazdır</button></div>
<div class="label">
    <div class="header">
        <div>
            <div class="title">SEVKİYAT TOP ETİKETİ</div>
            <div style="font-size:11px;color:##6b7280">#xmlFormat(getRoll.company_name ?: '')#</div>
        </div>
        <div class="roll-no">## #xmlFormat(getRoll.roll_no ?: '')#</div>
    </div>
    <div class="row"><span>Parti</span><strong>#xmlFormat(getRoll.order_number ?: '—')#</strong></div>
    <div class="row"><span>İrsaliye</span><strong>#xmlFormat(getRoll.ship_number ?: '—')#</strong></div>
    <div class="row"><span>Metre</span><strong>#numberFormat(isNumeric(getRoll.metre) ? val(getRoll.metre) : 0, '0.00')# mt</strong></div>
    <div class="row"><span>Kg</span><strong>#numberFormat(isNumeric(getRoll.kg) ? val(getRoll.kg) : 0, '0.000')# kg</strong></div>
    <div class="row"><span>Paket Durumu</span><strong>#xmlFormat(len(trim(getRoll.paket_durumu ?: '')) ? getRoll.paket_durumu : '—')#</strong></div>
    <div class="barcode-box">#xmlFormat(getRoll.roll_barcode ?: '')#</div>
    <div class="footer">
        <span>Kayıt: #isDate(getRoll.record_date) ? dateFormat(getRoll.record_date,'dd/mm/yyyy') & ' ' & timeFormat(getRoll.record_date,'HH:mm') : '—'#</span>
        <span>Yazdırma: #val(getRoll.etiket_print_count)#</span>
    </div>
</div>
<script>window.addEventListener('load', function(){ setTimeout(function(){ window.print(); }, 300); });</script>
</body>
</html>
</cfoutput>
