<cfprocessingdirective pageEncoding="utf-8">
<!--- Session kontrolü --->
<cfif NOT (structKeyExists(session, "authenticated") AND session.authenticated)>
    <cflocation url="/login.cfm" addtoken="false">
    <cfabort>
</cfif>
<cfset orderId = isDefined("url.order_id") AND isNumeric(url.order_id) ? val(url.order_id) : 0>
<cfif orderId lte 0>
    <cfoutput><p style="color:red;padding:20px">order_id gerekli.</p></cfoutput>
    <cfabort>
</cfif>

<!--- Parti (order) bilgisi --->
<cfquery name="getOrder" datasource="boyahane">
    SELECT o.order_id, o.order_number, o.order_head, o.order_detail,
           o.order_date, o.order_stage,
           o.ref_no, o.ref_ship_id,
           o.sarim_sekli, o.ambalaj,
           o.top_adedi, o.main_color,
           o.gramaj, o.en, o.kumas_tipi, o.tuse, o.isi, o.hiz, o.besleme_avans, o.cekme,
           COALESCE(c.nickname, c.fullname, '') AS company_name,
           COALESCE(ss.sarim_sekli_adi, '')     AS sarim_sekli_adi,
           COALESCE(ab.ambalaj_adi,     '')     AS ambalaj_adi
    FROM orders o
    LEFT JOIN company           c  ON o.company_id  = c.company_id
    LEFT JOIN setup_sarim_sekli ss ON o.sarim_sekli = ss.sarim_sekli_id
    LEFT JOIN setup_ambalaj     ab ON o.ambalaj     = ab.ambalaj_id
    WHERE o.order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getOrder.recordCount>
    <cfoutput><p style="color:red;padding:20px">Parti bulunamadı.</p></cfoutput>
    <cfabort>
</cfif>

<!--- İrsaliye bilgisi --->
<cfquery name="getShip" datasource="boyahane">
    SELECT s.ship_id, s.ship_number,
           s.hk_metre, s.hk_kg, s.hk_top_adedi
    FROM ship s
    WHERE s.ship_id = <cfqueryparam value="#val(getOrder.ref_ship_id)#" cfsqltype="cf_sql_integer">
</cfquery>

<!--- Ana ürün (kumaş cinsi + parti metre/kg) --->
<cfquery name="getMainRow" datasource="boyahane">
    SELECT orw.product_name, orw.quantity, orw.amount2, orw.unit2
    FROM order_row orw
    LEFT JOIN stocks st ON orw.stock_id = st.stock_id
    WHERE orw.order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
      AND COALESCE(st.is_main_stock, true) = true
    ORDER BY orw.order_row_id
    LIMIT 1
</cfquery>

<!--- Eski format: ayrı kg satırı (geriye dönük uyumluluk) --->
<cfquery name="getKgRow" datasource="boyahane">
    SELECT orw.quantity AS kg_qty
    FROM order_row orw
    JOIN stocks  st ON orw.stock_id  = st.stock_id
    JOIN product  p ON st.product_id = p.product_id
    WHERE orw.order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
      AND LOWER(TRIM(orw.unit)) = 'kg'
      AND COALESCE(p.is_ek_islem, false) = false
    ORDER BY orw.order_row_id
    LIMIT 1
</cfquery>

<!--- Ek işlemler (PROSES) --->
<cfquery name="getEkIslemRows" datasource="boyahane">
    SELECT DISTINCT orw.product_name
    FROM order_row orw
    JOIN stocks  st ON orw.stock_id  = st.stock_id
    JOIN product  p ON st.product_id = p.product_id
    WHERE orw.order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
      AND p.is_ek_islem = true
    ORDER BY orw.product_name
</cfquery>

<!--- Tekstil: partiye özel varsa onları kullan, yoksa ürün kartından --->
<cfset hasPartiTekstil = (
    (isNumeric(getOrder.gramaj)        AND val(getOrder.gramaj)        gt 0) OR
    (isNumeric(getOrder.en)            AND val(getOrder.en)            gt 0) OR
    len(trim(getOrder.kumas_tipi       ?: "")) OR
    len(trim(getOrder.tuse             ?: "")) OR
    (isNumeric(getOrder.isi)           AND val(getOrder.isi)           gt 0) OR
    (isNumeric(getOrder.hiz)           AND val(getOrder.hiz)           gt 0) OR
    (isNumeric(getOrder.besleme_avans) AND val(getOrder.besleme_avans) gt 0) OR
    len(trim(getOrder.cekme            ?: ""))
)>

<cfif NOT hasPartiTekstil>
    <cfquery name="getTekstil" datasource="boyahane">
        SELECT p.gramaj, p.en, p.kumas_tipi, p.tuse, p.isi, p.hiz, p.besleme_avans, p.cekme
        FROM order_row orw
        JOIN stocks  st ON orw.stock_id  = st.stock_id
        JOIN product  p ON st.product_id = p.product_id
        WHERE orw.order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
        ORDER BY orw.order_row_id
        LIMIT 1
    </cfquery>
    <cfset tGramaj       = (getTekstil.recordCount AND isNumeric(getTekstil.gramaj)        AND val(getTekstil.gramaj)        gt 0) ? val(getTekstil.gramaj)        : "">
    <cfset tEn           = (getTekstil.recordCount AND isNumeric(getTekstil.en)            AND val(getTekstil.en)            gt 0) ? val(getTekstil.en)            : "">
    <cfset tKumasTipi    = getTekstil.recordCount ? trim(getTekstil.kumas_tipi   ?: "") : "">
    <cfset tTuse         = getTekstil.recordCount ? trim(getTekstil.tuse         ?: "") : "">
    <cfset tIsi          = (getTekstil.recordCount AND isNumeric(getTekstil.isi)           AND val(getTekstil.isi)           gt 0) ? val(getTekstil.isi)           : "">
    <cfset tHiz          = (getTekstil.recordCount AND isNumeric(getTekstil.hiz)           AND val(getTekstil.hiz)           gt 0) ? val(getTekstil.hiz)           : "">
    <cfset tBesleme      = (getTekstil.recordCount AND isNumeric(getTekstil.besleme_avans) AND val(getTekstil.besleme_avans) gt 0) ? val(getTekstil.besleme_avans) : "">
    <cfset tCekme        = getTekstil.recordCount ? trim(getTekstil.cekme        ?: "") : "">
<cfelse>
    <cfset tGramaj       = (isNumeric(getOrder.gramaj)        AND val(getOrder.gramaj)        gt 0) ? val(getOrder.gramaj)        : "">
    <cfset tEn           = (isNumeric(getOrder.en)            AND val(getOrder.en)            gt 0) ? val(getOrder.en)            : "">
    <cfset tKumasTipi    = trim(getOrder.kumas_tipi   ?: "")>
    <cfset tTuse         = trim(getOrder.tuse         ?: "")>
    <cfset tIsi          = (isNumeric(getOrder.isi)           AND val(getOrder.isi)           gt 0) ? val(getOrder.isi)           : "">
    <cfset tHiz          = (isNumeric(getOrder.hiz)           AND val(getOrder.hiz)           gt 0) ? val(getOrder.hiz)           : "">
    <cfset tBesleme      = (isNumeric(getOrder.besleme_avans) AND val(getOrder.besleme_avans) gt 0) ? val(getOrder.besleme_avans) : "">
    <cfset tCekme        = trim(getOrder.cekme        ?: "")>
</cfif>

<!--- Değişkenler --->
<cfset vPartKodu  = getOrder.order_number ?: "">
<cfset vMusteri   = getOrder.company_name ?: "">
<cfset vRenk      = getOrder.main_color   ?: "">
<cfset vKumasCins = getMainRow.recordCount ? (getMainRow.product_name ?: "") : "">
<!--- Parti metre: ana satır quantity --->
<cfset vMetre = (getMainRow.recordCount AND isNumeric(getMainRow.quantity) AND val(getMainRow.quantity) gt 0)
              ? numberFormat(val(getMainRow.quantity), '0.000') : "">
<!--- Parti kg: önce amount2 (yeni format), yoksa ayrı kg satırı (eski format) --->
<cfif getMainRow.recordCount AND isNumeric(getMainRow.amount2) AND val(getMainRow.amount2) gt 0>
    <cfset vKg = numberFormat(val(getMainRow.amount2), '0.000')>
<cfelseif getKgRow.recordCount AND isNumeric(getKgRow.kg_qty) AND val(getKgRow.kg_qty) gt 0>
    <cfset vKg = numberFormat(val(getKgRow.kg_qty), '0.000')>
<cfelse>
    <cfset vKg = "">
</cfif>
<!--- Parti top adedi: orders.top_adedi --->
<cfset vTop = (isNumeric(getOrder.top_adedi) AND val(getOrder.top_adedi) gt 0) ? val(getOrder.top_adedi) : "">
<cfset vAmbalaj   = getOrder.ambalaj_adi   ?: "">
<cfset vSarim     = getOrder.sarim_sekli_adi ?: "">
<cfset vAciklama  = trim(getOrder.order_detail ?: "")>
<cfset vTarih     = now()>
<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Refakat Kartı — <cfoutput>#xmlFormat(vPartKodu)#</cfoutput></title>
<script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.6/dist/JsBarcode.all.min.js"></script>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: Arial, Helvetica, sans-serif;
    font-size: 11px;
    background: #888;
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 20px;
    gap: 12px;
  }
  .btn-bar {
    display: flex;
    gap: 8px;
  }
  .btn-bar button {
    padding: 8px 18px;
    font-size: 13px;
    border: none;
    border-radius: 5px;
    cursor: pointer;
  }
  .btn-print  { background: #1d4ed8; color: #fff; }
  .btn-close  { background: #6b7280; color: #fff; }
  .kart {
    width: 148mm;            /* A5 genişliği */
    min-height: 210mm;       /* A5 yüksekliği */
    background: #fff;
    padding: 7mm;
    box-shadow: 0 4px 24px rgba(0,0,0,.35);
    display: flex;
    flex-direction: column;
  }

  /* ── HEADER ── */
  .kart-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    border-bottom: 2px solid #000;
    padding-bottom: 5px;
    margin-bottom: 5px;
  }
  .kart-logo { line-height: 1.3; }
  .kart-logo .firma-adi-italic { font-style: italic; font-size: 13px; font-weight: 600; }
  .kart-logo .refakat-baslik {
    font-size: 22px;
    font-weight: 900;
    letter-spacing: 2px;
  }
  .kart-logo .parti-rn {
    font-size: 12px;
    font-weight: 700;
  }
  .kart-header-right { text-align: right; }
  .kart-header-right .tarih-satir { font-size: 11px; margin-bottom: 3px; }
  svg.barcode { display: block; }

  /* ── INFO TABLE ── */
  .info-table {
    width: 100%;
    border-collapse: collapse;
    border: 1.5px solid #000;
    margin-bottom: 5px;
  }
  .info-table td {
    border: 1px solid #000;
    padding: 3px 7px;
    vertical-align: top;
  }
  .info-table .lbl { font-weight: bold; width: 100px; white-space: nowrap; }
  .info-table .val { font-size: 15px; font-weight: 600; }
  .info-table .num-lbl { font-weight: bold; white-space: nowrap; }
  .info-table .num-val { font-weight: bold; font-size: 15px; }

  /* ── SECTION HEADER ── */
  .section-header {
    background: #000;
    color: #fff;
    text-align: center;
    font-weight: 900;
    letter-spacing: 2px;
    font-size: 13px;
    padding: 4px 0;
    margin-top: 4px;
  }

  /* ── APRE TABLE ── */
  .apre-table {
    width: 100%;
    border-collapse: collapse;
    border: 1.5px solid #000;
  }
  .apre-table td {
    border: 1px solid #000;
    padding: 3px 7px;
    vertical-align: top;
  }
  .apre-table .lbl { font-weight: bold; width: 110px; white-space: nowrap; }
  .apre-table .val { font-size: 15px; font-weight: 600; }

  /* ── PROSES + KKT split ── */
  .split-row {
    display: flex;
    border: 1.5px solid #000;
    margin-bottom: 4px;
    min-height: 80px;
    flex: 0 0 auto;
  }
  .split-col {
    flex: 1;
    padding: 4px 6px;
  }
  .split-col-divider {
    border-left: 1.5px solid #000;
    flex: 1.5;
    padding: 4px 6px;
  }
  .split-header {
    font-weight: 900;
    letter-spacing: 1px;
    font-size: 10px;
    border-bottom: 1px solid #000;
    margin-bottom: 3px;
    padding-bottom: 2px;
    text-align: center;
  }
  .proses-item { padding: 1px 0; font-weight: 700; font-size: 14px; }
  .kkt-row { display: flex; gap: 4px; margin-bottom: 2px; }
  .kkt-row .lbl { font-weight: bold; width: 80px; }
  .kkt-row .val { font-size: 14px; font-weight: 600; }
  .kkt-aciklama { margin-top: 4px; font-weight: 700; font-size: 14px; line-height: 1.5; }

  /* ── AÇIKLAMA ── */
  .aciklama-box {
    border: 1.5px solid #000;
    min-height: 50px;
    padding: 6px 8px;
    font-size: 14px;
    line-height: 1.6;
    white-space: pre-wrap;
    flex: 1 1 auto;          /* kalan dikey alanı doldur */
  }

  @media print {
    body { background: none; padding: 0; }
    .btn-bar { display: none; }
    .kart {
      width: 100%;
      min-height: 196mm;
      box-shadow: none;
      padding: 4mm;
    }
    @page { size: A5 portrait; margin: 6mm; }
  }
</style>
</head>
<body>
<div class="btn-bar">
  <button class="btn-print" onclick="window.print()">&#128438; Yazdır</button>
  <button class="btn-close" onclick="window.close()">✕ Kapat</button>
</div>

<div class="kart">
  <cfoutput>
  <!--- HEADER --->
  <div class="kart-header">
    <div class="kart-logo">
      <div class="firma-adi-italic">Rasih Çelik</div>
      <div class="refakat-baslik">R E F A K A T</div>
      <div class="parti-rn">Parti RN: <span class="num-val">#orderId#</span></div>
    </div>
    <div class="kart-header-right">
      <div class="tarih-satir">Tarih : #dateFormat(vTarih,'dd/mm/yyyy')# #timeFormat(vTarih,'HH:mm:ss')#</div>
      <svg id="barcode" class="barcode"></svg>
    </div>
  </div>

  <!--- BİLGİ TABLOSU --->
  <table class="info-table">
    <tr>
      <td class="lbl">Parti Kodu</td>
      <td class="val"><strong>#xmlFormat(vPartKodu)#</strong></td>
      <td class="num-lbl">Metre</td>
      <td class="num-val">: #xmlFormat(vMetre)#</td>
    </tr>
    <tr>
      <td class="lbl">Müşteri</td>
      <td class="val"><strong>#xmlFormat(vMusteri)#</strong></td>
      <td class="num-lbl">Kg</td>
      <td class="num-val">: #xmlFormat(vKg)#</td>
    </tr>
    <tr>
      <td class="lbl">Renk</td>
      <td class="val">#xmlFormat(vRenk)#</td>
      <td class="num-lbl">Top Adedi</td>
      <td class="num-val">: #xmlFormat(vTop)#</td>
    </tr>
    <tr>
      <td class="lbl">Kumaş Cinsi</td>
      <td class="val" colspan="3">#xmlFormat(vKumasCins)#</td>
    </tr>
    <tr>
      <td class="lbl">Kartela</td>
      <td class="val">&nbsp;</td>
      <td class="num-lbl">Kartela Trh</td>
      <td class="num-val">:&nbsp;</td>
    </tr>
    <tr>
      <td class="lbl">İnditex PO1</td>
      <td class="val" colspan="3">&nbsp;</td>
    </tr>
    <tr>
      <td class="lbl">İnditex PO2</td>
      <td class="num-lbl">Standart</td>
      <td class="num-val" colspan="2">:&nbsp;</td>
    </tr>
  </table>

  <!--- APRE TALİMATI --->
  <div class="section-header">A P R E &nbsp; T A L İ M A T I</div>
  <table class="apre-table" style="margin-bottom:4px">
    <tr>
      <td class="lbl">Elyaf İçeriği</td>
      <td class="val">&nbsp;</td>
      <td class="lbl">Kull.Kimyasal</td>
      <td class="val">:&nbsp;</td>
    </tr>
    <tr>
      <td class="lbl">Gramaj</td>
      <td class="val"><cfif len(tGramaj)>: #xmlFormat(tGramaj)#</cfif></td>
      <td class="lbl">Isı</td>
      <td class="val">:<cfif len(tIsi)> #xmlFormat(tIsi)#</cfif></td>
    </tr>
    <tr>
      <td class="lbl">En</td>
      <td class="val"><cfif len(tEn)>: #xmlFormat(tEn)#</cfif></td>
      <td class="lbl">Hız</td>
      <td class="val">:<cfif len(tHiz)> #xmlFormat(tHiz)#</cfif></td>
    </tr>
    <tr>
      <td class="lbl">Tuşe</td>
      <td class="val"><cfif len(tTuse)>: #xmlFormat(tTuse)#</cfif></td>
      <td class="lbl">Besleme/Avans</td>
      <td class="val">:<cfif len(tBesleme)> #xmlFormat(tBesleme)#</cfif></td>
    </tr>
    <tr>
      <td class="lbl">Çekme</td>
      <td class="val"><cfif len(tCekme)>: #xmlFormat(tCekme)#</cfif></td>
      <td class="lbl">Su Geçmez</td>
      <td class="val">:&nbsp;</td>
    </tr>
    <tr>
      <td class="lbl">Apre</td>
      <td class="val">:&nbsp;</td>
      <td class="lbl">Yanmaz</td>
      <td class="val">:&nbsp;</td>
    </tr>
    <tr>
      <td class="lbl">Ön Fikse</td>
      <td class="val" colspan="3">:&nbsp;</td>
    </tr>
  </table>

  <!--- PROSES + KALİTE KONTROL --->
  <div class="split-row">
    <div class="split-col">
      <div class="split-header">P R O S E S</div>
      <cfif getEkIslemRows.recordCount>
        <cfloop query="getEkIslemRows">
          <div class="proses-item">#xmlFormat(Listgetat(product_name,1,"-"))#</div>
        </cfloop>
      <cfelse>
        <div style="color:##aaa;font-style:italic;font-size:10px">—</div>
      </cfif>
    </div>
    <div class="split-col-divider">
      <div class="split-header">K A L İ T E &nbsp; K O N T R O L &nbsp; T A L İ M A T I</div>
      <div class="kkt-row">
        <span class="lbl">Ambalaj</span>
        <span>: #xmlFormat(vAmbalaj)#</span>
      </div>
      <div class="kkt-row">
        <span class="lbl">Sarım Şekli</span>
        <span>: #xmlFormat(vSarim)#</span>
      </div>
    </div>
  </div>

  <!--- APRE AÇIKLAMA --->
  <div class="section-header">A P R E &nbsp; A Ç I K L A M A</div>
  <div class="aciklama-box">#xmlFormat(vAciklama)#</div>
  </cfoutput>
</div>

<script>
(function() {
  var barcodeVal = '<cfoutput>#jsStringFormat(orderId)#</cfoutput>';
  if (barcodeVal && typeof JsBarcode !== 'undefined') {
    try {
      JsBarcode('#barcode', barcodeVal, {
        format:      'CODE128',
        width:       1.5,
        height:      40,
        displayValue: false,
        margin:       0
      });
    } catch(e) {}
  }
})();
</script>
</body>
</html>
