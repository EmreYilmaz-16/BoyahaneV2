<cfprocessingdirective pageEncoding="utf-8">
<!--- Session kontrolü --->
<cfif NOT (structKeyExists(session, "authenticated") AND session.authenticated)>
    <cflocation url="/login.cfm" addtoken="false">
    <cfabort>
</cfif>

<cfset rollId = (structKeyExists(url, "roll_id") AND isNumeric(url.roll_id)) ? val(url.roll_id) : 0>
<cfset planId = (structKeyExists(url, "plan_id") AND isNumeric(url.plan_id)) ? val(url.plan_id) : 0>

<cfif rollId lte 0 AND planId lte 0>
    <cfoutput><p style="color:red;padding:20px">roll_id veya plan_id gerekli.</p></cfoutput>
    <cfabort>
</cfif>

<!--- Top etiketi verileri: tek top (roll_id) veya planın tüm topları (plan_id) --->
<cfquery name="getRolls" datasource="boyahane">
    SELECT sr.roll_id,
           sr.plan_id,
           sr.order_id,
           sr.ship_id,
           sr.roll_no,
           sr.roll_barcode,
           sr.metre,
           sr.kg,
           sr.record_date,
           srp.refakat_barcode,
           o.order_number,
           COALESCE(c.nickname, c.fullname, '') AS company_name,
           COALESCE((
               SELECT orw.product_name
               FROM order_row orw
               LEFT JOIN stocks st ON orw.stock_id = st.stock_id
               WHERE orw.order_id = sr.order_id
                 AND COALESCE(st.is_main_stock, true) = true
               ORDER BY orw.order_row_id
               LIMIT 1
           ), '') AS product_name
    FROM ship_roll sr
    LEFT JOIN ship_roll_plan srp ON sr.plan_id = srp.plan_id
    LEFT JOIN orders o           ON sr.order_id = o.order_id
    LEFT JOIN company c          ON o.company_id = c.company_id
    WHERE 1 = 1
    <cfif rollId gt 0>
        AND sr.roll_id = <cfqueryparam value="#rollId#" cfsqltype="cf_sql_integer">
    <cfelse>
        AND sr.plan_id = <cfqueryparam value="#planId#" cfsqltype="cf_sql_integer">
    </cfif>
    ORDER BY sr.roll_no NULLS LAST, sr.roll_id
</cfquery>

<cfif NOT getRolls.recordCount>
    <cfoutput><p style="color:red;padding:20px">Top etiketi kaydı bulunamadı.</p></cfoutput>
    <cfabort>
</cfif>

<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Top Barkod Etiketi</title>
<script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.6/dist/JsBarcode.all.min.js"></script>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: Arial, Helvetica, sans-serif;
    font-size: 10px;
    color: #111;
    background: #777;
    padding: 14px;
  }
  .btn-bar {
    display: flex;
    justify-content: center;
    gap: 8px;
    margin-bottom: 12px;
  }
  .btn-bar button {
    border: 0;
    border-radius: 5px;
    cursor: pointer;
    font-size: 13px;
    font-weight: 700;
    padding: 8px 16px;
  }
  .btn-print { background: #1d4ed8; color: #fff; }
  .btn-close { background: #6b7280; color: #fff; }
  .labels {
    display: flex;
    flex-wrap: wrap;
    align-items: flex-start;
    justify-content: center;
    gap: 8px;
  }
  .label {
    width: 100mm;
    min-height: 75mm;
    background: #fff;
    border: 1px solid #000;
    border-radius: 2px;
    box-shadow: 0 4px 16px rgba(0,0,0,.28);
    display: flex;
    flex-direction: column;
    padding: 4mm;
    break-inside: avoid;
    page-break-inside: avoid;
  }
  .label-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    border-bottom: 2px solid #000;
    padding-bottom: 2mm;
    margin-bottom: 2mm;
    gap: 4mm;
  }
  .brand { line-height: 1.15; min-width: 0; }
  .brand-name { font-family: Georgia, serif; font-style: italic; font-size: 12px; font-weight: 700; }
  .label-title { font-size: 15px; font-weight: 900; letter-spacing: 1.2px; white-space: nowrap; }
  .label-subtitle { font-size: 8px; font-weight: 700; color: #333; margin-top: 1px; }
  .header-code { text-align: right; font-size: 8px; line-height: 1.25; white-space: nowrap; }
  .header-code strong { display: block; font-size: 12px; }
  .info-grid {
    display: grid;
    grid-template-columns: 21mm 1fr 15mm 21mm;
    border: 1px solid #000;
    border-bottom: 0;
  }
  .cell {
    min-height: 8.2mm;
    border-right: 1px solid #000;
    border-bottom: 1px solid #000;
    padding: 1.4mm 1.8mm;
    overflow: hidden;
  }
  .cell:nth-child(4n) { border-right: 0; }
  .lbl { font-size: 7px; font-weight: 800; letter-spacing: .3px; text-transform: uppercase; color: #444; }
  .val { font-size: 10.5px; font-weight: 800; line-height: 1.15; overflow-wrap: anywhere; }
  .val.big { font-size: 16px; line-height: 1; }
  .wide-val { grid-column: span 3; }
  .barcode-wrap {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: flex-end;
    padding-top: 2mm;
    min-height: 22mm;
  }
  svg.barcode { display: block; width: 100%; max-width: 86mm; height: 18mm; }
  .barcode-value { font-size: 11px; font-weight: 900; letter-spacing: 1.4px; margin-top: 1mm; text-align: center; overflow-wrap: anywhere; }
  @media print {
    body { background: none; padding: 0; }
    .btn-bar { display: none; }
    .labels { display: block; }
    .label {
      width: 100mm;
      min-height: 75mm;
      box-shadow: none;
      border-radius: 0;
      margin: 0;
      page-break-after: always;
    }
    .label:last-child { page-break-after: auto; }
    @page { size: 100mm 75mm; margin: 0; }
  }
</style>
</head>
<body>
<div class="btn-bar">
  <button class="btn-print" onclick="window.print()">&#128438; Yazdır</button>
  <button class="btn-close" onclick="window.close()">✕ Kapat</button>
</div>

<div class="labels">
<cfoutput query="getRolls">
  <cfset vPartiNo = order_number ?: "">
  <cfset vMusteri = company_name ?: "">
  <cfset vUrun = product_name ?: "">
  <cfset vTopNo = isNumeric(roll_no) ? roll_no : "">
  <cfset vMetre = (isNumeric(metre) AND val(metre) gt 0) ? numberFormat(val(metre), "0.00") : "">
  <cfset vKg = (isNumeric(kg) AND val(kg) gt 0) ? numberFormat(val(kg), "0.00") : "">
  <cfset vBarcode = len(trim(roll_barcode ?: "")) ? trim(roll_barcode) : "ROLL-#roll_id#">
  <cfset vTarih = isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : "">
  <div class="label">
    <div class="label-header">
      <div class="brand">
        <div class="brand-name">Rasih Çelik</div>
        <div class="label-title">TOP ETİKETİ</div>
        <div class="label-subtitle">Boyahane Sarım / Barkod</div>
      </div>
      <div class="header-code">
        Parti RN
        <strong>#val(order_id)#</strong>
        Plan: #val(plan_id)#
      </div>
    </div>

    <div class="info-grid">
      <div class="cell"><div class="lbl">Parti No</div></div>
      <div class="cell wide-val"><div class="val">#htmlEditFormat(vPartiNo)#</div></div>

      <div class="cell"><div class="lbl">Müşteri</div></div>
      <div class="cell wide-val"><div class="val">#htmlEditFormat(vMusteri)#</div></div>

      <div class="cell"><div class="lbl">Ürün / Kumaş</div></div>
      <div class="cell wide-val"><div class="val">#htmlEditFormat(vUrun)#</div></div>

      <div class="cell"><div class="lbl">Top No</div><div class="val big">#htmlEditFormat(vTopNo)#</div></div>
      <div class="cell"><div class="lbl">Metre</div><div class="val big">#htmlEditFormat(vMetre)#</div></div>
      <div class="cell"><div class="lbl">Kg</div><div class="val big">#htmlEditFormat(vKg)#</div></div>
      <div class="cell"><div class="lbl">Kayıt</div><div class="val">#htmlEditFormat(vTarih)#</div></div>
    </div>

    <div class="barcode-wrap">
      <svg class="barcode" data-barcode="#htmlEditFormat(vBarcode)#"></svg>
      <div class="barcode-value">#htmlEditFormat(vBarcode)#</div>
    </div>
  </div>
</cfoutput>
</div>

<script>
(function() {
  if (typeof JsBarcode === 'undefined') { return; }
  var barcodes = document.querySelectorAll('svg.barcode[data-barcode]');
  barcodes.forEach(function(el) {
    var value = el.getAttribute('data-barcode') || '';
    if (!value) { return; }
    try {
      JsBarcode(el, value, {
        format: 'CODE128',
        width: 1.35,
        height: 48,
        displayValue: false,
        margin: 0
      });
    } catch(e) {}
  });
})();
</script>
</body>
</html>
