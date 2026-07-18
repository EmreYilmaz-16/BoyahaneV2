<cfprocessingdirective pageEncoding="utf-8">
<cfset shipId = isDefined("url.ship_id") AND isNumeric(url.ship_id) ? val(url.ship_id) : 0>

<cfif shipId lte 0>
    <div class="alert alert-warning m-3"><i class="fas fa-exclamation-triangle me-2"></i>Lütfen bir irsaliye seçin (ship_id gerekli).</div>
    <cfabort>
</cfif>

<!--- İrsaliye bilgisi --->
<cfquery name="getShip" datasource="boyahane">
    SELECT s.ship_id, s.ship_number, s.ship_detail, s.hk_metre, s.hk_kg, s.hk_top_adedi,
           COALESCE(c.nickname, c.fullname, '') AS company_name,
           COALESCE((
               SELECT p.product_name || ' — ' || st.stock_code
               FROM ship_row sr
               LEFT JOIN stocks st ON sr.stock_id = st.stock_id
               LEFT JOIN product p ON st.product_id = p.product_id
               WHERE sr.ship_id = s.ship_id
               ORDER BY sr.ship_row_id
               LIMIT 1
           ), '') AS urun_adi
    FROM ship s
    LEFT JOIN company c ON s.company_id = c.company_id
    WHERE s.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getShip.recordCount>
    <div class="alert alert-danger m-3">İrsaliye bulunamadı (#shipId#).</div>
    <cfabort>
</cfif>

<!--- Bu irsaliyeye ait partiler (orders where ref_no = ship_number) --->
<cfquery name="getPartiler" datasource="boyahane">
    SELECT o.order_id, o.order_number, o.order_stage, o.order_date, o.deliverdate,
           o.nettotal, o.grosstotal, o.taxtotal, o.record_date,
           o.sarim_sekli, o.ambalaj,
           ss.sarim_sekli_adi, ab.ambalaj_adi,
           po.p_order_id
    FROM orders o
    LEFT JOIN LATERAL (
        SELECT p_order_id
        FROM production_orders
        WHERE order_id = o.order_id
          AND station_id IS NOT NULL
          AND start_date IS NOT NULL
          AND COALESCE(status, 1) IN (1, 2)
        ORDER BY p_order_id DESC
        LIMIT 1
    ) po ON true
    LEFT JOIN setup_sarim_sekli ss ON o.sarim_sekli = ss.sarim_sekli_id
    LEFT JOIN setup_ambalaj ab ON o.ambalaj = ab.ambalaj_id
    WHERE o.ref_ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
       OR (o.ref_ship_id IS NULL AND o.ref_no IS NOT NULL AND o.ref_no <> '' AND o.ref_no = <cfqueryparam value="#getShip.ship_number#" cfsqltype="cf_sql_varchar">)
    ORDER BY o.order_id
</cfquery>


<!--- Sevkiyat topları: yeni ship_roll tablosundan irsaliyeye bağlı tüm top detayları --->
<cfquery name="getShipRolls" datasource="boyahane">
    SELECT sr.roll_id, sr.order_id, sr.roll_no, sr.roll_barcode, sr.metre, sr.kg,
           sr.paket_durumu, sr.etiket_print_count, sr.record_date,
           COALESCE(o.order_number, '') AS order_number
    FROM ship_roll sr
    LEFT JOIN orders o ON sr.order_id = o.order_id
    WHERE sr.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
       OR sr.order_id IN (
           SELECT o2.order_id
           FROM orders o2
           WHERE o2.ref_ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
              OR (o2.ref_ship_id IS NULL AND o2.ref_no IS NOT NULL AND o2.ref_no <> '' AND o2.ref_no = <cfqueryparam value="#getShip.ship_number#" cfsqltype="cf_sql_varchar">)
       )
    ORDER BY COALESCE(o.order_number, ''), COALESCE(sr.roll_no, 0), sr.roll_id
</cfquery>

<!--- Ana ürünün tekstil bilgileri --->
<cfquery name="getShipTekstil" datasource="boyahane">
    SELECT p.en, p.tuse, p.cekme, p.isi, p.hiz, p.gramaj, p.besleme_avans, p.kumas_tipi
    FROM ship_row sr
    JOIN stocks st ON sr.stock_id = st.stock_id
    JOIN product p ON st.product_id = p.product_id
    WHERE sr.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
    ORDER BY sr.ship_row_id
    LIMIT 1
</cfquery>

<!--- Her partinin satırları (stok renk/varyant bilgisiyle) --->
<cfquery name="getPartiRows" datasource="boyahane">
    SELECT orw.order_id, orw.order_row_id,
           orw.product_name, orw.product_name2, orw.stock_id,
           orw.quantity, orw.unit, orw.price, orw.tax, orw.discount_1, orw.nettotal,
           o.order_number,
           COALESCE(st.is_main_stock, true)  AS is_main_stock,
           COALESCE(st.property, '')          AS stock_property,
           COALESCE(st.stock_code_2, '')      AS stock_code_2,
           COALESCE(st.product_id, 0)         AS product_id
    FROM order_row orw
    JOIN orders o ON orw.order_id = o.order_id
    LEFT JOIN stocks st ON orw.stock_id = st.stock_id
    WHERE o.ref_ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
       OR (o.ref_ship_id IS NULL AND o.ref_no IS NOT NULL AND o.ref_no <> '' AND o.ref_no = <cfqueryparam value="#getShip.ship_number#" cfsqltype="cf_sql_varchar">)
    ORDER BY orw.order_id, orw.order_row_id
</cfquery>

<!--- Renk varyantları: parti satırlarındaki ürünlerin IS_MAIN_STOCK=false olan stok kartları --->
<cfset partiProductIds = []>
<cfloop query="getPartiRows">
    <cfif NOT arrayContains(partiProductIds, val(product_id))>
        <cfset arrayAppend(partiProductIds, val(product_id))>
    </cfif>
</cfloop>

<cfset colorVariantsArr = []>
<cfif arrayLen(partiProductIds) gt 0>
    <cfquery name="getColorVariants" datasource="boyahane">
        SELECT st.stock_id, st.stock_code, COALESCE(st.stock_code_2,'') AS stock_code_2,
               COALESCE(st.property,'') AS property, st.product_id
        FROM stocks st
        WHERE st.product_id IN (<cfqueryparam value="#arrayToList(partiProductIds)#" cfsqltype="cf_sql_integer" list="true">)
          AND (st.is_main_stock IS NULL OR st.is_main_stock = false)
        ORDER BY st.product_id, st.stock_id
    </cfquery>
    <cfloop query="getColorVariants">
        <cfset arrayAppend(colorVariantsArr, {
            "stock_id":     val(stock_id),
            "stock_code":   stock_code ?: "",
            "stock_code_2": stock_code_2 ?: "",
            "property":     property ?: "",
            "product_id":   val(product_id)
        })>
    </cfloop>
</cfif>

<!--- JS dizilerine dönüştür --->
<cfset partilerArr = []>
<cfloop query="getPartiler">
    <cfset stageLabel = "">
    <cfswitch expression="#val(order_stage)#">
        <cfcase value="1"><cfset stageLabel = "Beklemede"></cfcase>
        <cfcase value="2"><cfset stageLabel = "Onaylandı"></cfcase>
        <cfcase value="3"><cfset stageLabel = "Üretimde"></cfcase>
        <cfcase value="4"><cfset stageLabel = "Hazır"></cfcase>
        <cfcase value="5"><cfset stageLabel = "Sevk Edildi"></cfcase>
        <cfcase value="6"><cfset stageLabel = "Tamamlandı"></cfcase>
        <cfdefaultcase><cfset stageLabel = "Bilinmiyor"></cfdefaultcase>
    </cfswitch>
    <cfset arrayAppend(partilerArr, {
        "order_id":     order_id,
        "order_number": order_number ?: "",
        "order_stage":  val(order_stage),
        "stage_label":  stageLabel,
        "p_order_id":   isNumeric(p_order_id) ? val(p_order_id) : 0,
        "order_date":   isDate(order_date)  ? dateFormat(order_date,  "dd/mm/yyyy") : "",
        "deliverdate":  isDate(deliverdate) ? dateFormat(deliverdate, "dd/mm/yyyy") : "",
        "nettotal":     isNumeric(nettotal)   ? val(nettotal)   : 0,
        "grosstotal":   isNumeric(grosstotal) ? val(grosstotal) : 0,
        "taxtotal":     isNumeric(taxtotal)   ? val(taxtotal)   : 0,
        "record_date":  isDate(record_date)  ? dateFormat(record_date,  "dd/mm/yyyy") & " " & timeFormat(record_date,  "HH:mm") : "",
        "sarim_sekli":     isNumeric(sarim_sekli) ? val(sarim_sekli) : 0,
        "sarim_sekli_adi": len(sarim_sekli_adi ?: "") ? sarim_sekli_adi : "",
        "ambalaj":         isNumeric(ambalaj) ? val(ambalaj) : 0,
        "ambalaj_adi":     len(ambalaj_adi ?: "") ? ambalaj_adi : ""
    })>
</cfloop>

<cfset hkMetre = isNumeric(getShip.hk_metre) ? val(getShip.hk_metre) : 0>
<cfset shipRollsArr = []>
<cfset rollTotalMetre = 0>
<cfset rollTotalKg = 0>
<cfloop query="getShipRolls">
    <cfset rMetre = isNumeric(metre) ? val(metre) : 0>
    <cfset rKg = isNumeric(kg) ? val(kg) : 0>
    <cfset rollTotalMetre += rMetre>
    <cfset rollTotalKg += rKg>
    <cfset arrayAppend(shipRollsArr, {
        "roll_id": roll_id,
        "order_id": isNumeric(order_id) ? val(order_id) : 0,
        "order_number": order_number ?: "",
        "roll_no": isNumeric(roll_no) ? val(roll_no) : 0,
        "roll_barcode": roll_barcode ?: "",
        "metre": rMetre,
        "kg": rKg,
        "paket_durumu": paket_durumu ?: "",
        "etiket_print_count": isNumeric(etiket_print_count) ? val(etiket_print_count) : 0,
        "record_date": isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : ""
    })>
</cfloop>
<cfset hkKg = isNumeric(getShip.hk_kg) ? val(getShip.hk_kg) : 0>
<cfset rollDiffMetre = hkMetre - rollTotalMetre>
<cfset rollDiffKg = hkKg - rollTotalKg>

<cfset partiRowsArr = []>
<cfloop query="getPartiRows">
    <cfset arrayAppend(partiRowsArr, {
        "order_id":      order_id,
        "order_number":  order_number ?: "",
        "order_row_id":  order_row_id,
        "stock_id":      isNumeric(stock_id) ? val(stock_id) : 0,
        "product_id":    isNumeric(product_id) ? val(product_id) : 0,
        "product_name":  product_name ?: "",
        "is_main_stock": isBoolean(is_main_stock) ? is_main_stock : true,
        "stock_property":stock_property ?: "",
        "stock_code_2":  stock_code_2 ?: "",
        "quantity":      isNumeric(quantity) ? val(quantity) : 0,
        "unit":          unit ?: "",
        "price":         isNumeric(price)    ? val(price)    : 0,
        "tax":           isNumeric(tax)      ? val(tax)      : 0,
        "nettotal":      isNumeric(nettotal) ? val(nettotal) : 0
    })>
</cfloop>

<!--- Partilenen toplam metre (ana ürün satırı = ilk satır her partide) --->
<cfset partiMetre = 0>
<cfset prevOrderId = 0>
<cfloop query="getPartiRows">
    <cfif order_id neq prevOrderId>
        <cfset partiMetre += isNumeric(quantity) ? val(quantity) : 0>
        <cfset prevOrderId = order_id>
    </cfif>
</cfloop>
<cfif hkMetre gt 0 AND partiMetre gte hkMetre>
    <cfset partiDurum = "tamam">
    <cfset partiDurumLabel = "Tamamen Partilendi">
<cfelseif partiMetre gt 0>
    <cfset partiDurum = "eksik">
    <cfset partiDurumLabel = "Eksik Partilendi">
<cfelse>
    <cfset partiDurum = "yok">
    <cfset partiDurumLabel = "Partilenmedi">
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-list-ol"></i></div>
        <div class="page-header-title">
            <cfoutput>
            <h1>Parti Listesi <small class="text-muted fs-6">#xmlFormat(getShip.ship_number)#</small></h1>
            <p><strong>#xmlFormat(getShip.company_name)#</strong> — #xmlFormat(getShip.urun_adi)#</p>
            </cfoutput>
        </div>
    </div>
    <div class="d-flex gap-2">
        <cfoutput>
        <a href="index.cfm?fuseaction=ship.add_parti&ship_id=#shipId#" class="btn btn-success btn-sm">
            <i class="fas fa-cut me-1"></i>Yeni Parti
        </a>
        <a href="/ship/display/sevkiyat_cikis_fisi.cfm?ship_id=#shipId#" target="_blank" class="btn btn-dark btn-sm">
            <i class="fas fa-print me-1"></i>Sevkiyat Çıkış Fişi
        </a>
        </cfoutput>
        <a href="index.cfm?fuseaction=ship.list_giris_fis" class="btn-back">
            <i class="fas fa-arrow-left"></i>Giriş Fişi Listesi
        </a>
    </div>
</div>

<div class="px-3 pb-5">

    <!--- İrsaliye Özet --->
    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="summary-card" style="background:linear-gradient(135deg,#1a3a5c,#2563ab);">
                <div class="summary-icon"><i class="fas fa-ruler-horizontal"></i></div>
                <div class="summary-info">
                    <span class="summary-label">İrsaliye Metre</span>
                    <span class="summary-value"><cfoutput>#numberFormat(hkMetre,'0.00')#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card" style="background:linear-gradient(135deg,#15803d,#22c55e);">
                <div class="summary-icon"><i class="fas fa-cut"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Partilenen Metre</span>
                    <span class="summary-value"><cfoutput>#numberFormat(partiMetre,'0.00')#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card" style="background:linear-gradient(135deg,#92400e,#f59e0b);">
                <div class="summary-icon"><i class="fas fa-chart-pie"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Kalan Metre</span>
                    <span class="summary-value"><cfoutput>#numberFormat(max(hkMetre - partiMetre, 0),'0.00')#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card"
                 style="background:<cfoutput>#partiDurum eq 'tamam' ? 'linear-gradient(135deg,##15803d,##22c55e)' : (partiDurum eq 'eksik' ? 'linear-gradient(135deg,##92400e,##f59e0b)' : 'linear-gradient(135deg,##374151,##6b7280)')#</cfoutput>;">
                <div class="summary-icon"><i class="fas fa-flag"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Parti Durumu</span>
                    <span class="summary-value" style="font-size:1rem;"><cfoutput>#partiDurumLabel#</cfoutput></span>
                </div>
            </div>
        </div>
    </div>

    <!--- Tekstil Bilgileri --->
    <cfif getShipTekstil.recordCount AND (
        isNumeric(getShipTekstil.en) OR len(getShipTekstil.kumas_tipi ?: "") OR
        isNumeric(getShipTekstil.gramaj) OR isNumeric(getShipTekstil.isi))>
    <cfoutput>
    <div class="grid-card mb-3">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-tshirt"></i>Ürün Tekstil Özellikleri</div>
        </div>
        <div class="card-body px-3 py-2">
            <div class="d-flex flex-wrap gap-4">
                <cfif len(getShipTekstil.kumas_tipi ?: "")>
                <div><small class="text-muted d-block">Kumaş Tipi</small><strong>#xmlFormat(getShipTekstil.kumas_tipi)#</strong></div>
                </cfif>
                <cfif isNumeric(getShipTekstil.en)>
                <div><small class="text-muted d-block">En</small><strong>#getShipTekstil.en# cm</strong></div>
                </cfif>
                <cfif isNumeric(getShipTekstil.gramaj)>
                <div><small class="text-muted d-block">Gramaj</small><strong>#getShipTekstil.gramaj# g/m²</strong></div>
                </cfif>
                <cfif isNumeric(getShipTekstil.isi)>
                <div><small class="text-muted d-block">Isı</small><strong>#getShipTekstil.isi# °C</strong></div>
                </cfif>
                <cfif isNumeric(getShipTekstil.hiz)>
                <div><small class="text-muted d-block">Hız</small><strong>#getShipTekstil.hiz# m/dak</strong></div>
                </cfif>
                <cfif isNumeric(getShipTekstil.besleme_avans)>
                <div><small class="text-muted d-block">Besleme Avans</small><strong>#getShipTekstil.besleme_avans#</strong></div>
                </cfif>
                <cfif len(getShipTekstil.tuse ?: "")>
                <div><small class="text-muted d-block">Tuşe</small><strong>#xmlFormat(getShipTekstil.tuse)#</strong></div>
                </cfif>
                <cfif len(getShipTekstil.cekme ?: "")>
                <div><small class="text-muted d-block">Çekme</small><strong>#xmlFormat(getShipTekstil.cekme)#</strong></div>
                </cfif>
            </div>
        </div>
    </div>
    </cfoutput>
    </cfif>


    <!--- Sevkiyat Topları --->
    <div class="grid-card mb-3">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-boxes-stacked"></i>Sevkiyat Topları</div>
            <span class="record-count"><cfoutput>#getShipRolls.recordCount#</cfoutput> top</span>
        </div>
        <div class="card-body p-2">
            <div id="shipRollGrid"></div>
        </div>
        <div class="px-3 pb-3">
            <div class="roll-summary-row">
                <cfoutput>
                <div><span>Toplam metre</span><strong>#numberFormat(rollTotalMetre,'0.00')# mt</strong></div>
                <div><span>Toplam kg</span><strong>#numberFormat(rollTotalKg,'0.000')# kg</strong></div>
                <div><span>Top adedi</span><strong>#getShipRolls.recordCount# adet</strong></div>
                <div><span>Partiyle fark</span><strong>#numberFormat(rollDiffMetre,'0.00')# mt / #numberFormat(rollDiffKg,'0.000')# kg</strong></div>
                </cfoutput>
            </div>
        </div>
    </div>

    <!--- Parti Listesi --->
    <div class="grid-card mb-3">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-layer-group"></i>Partiler</div>
            <span class="record-count" id="partiCount"><cfoutput>#getPartiler.recordCount#</cfoutput> parti</span>
        </div>
        <div class="card-body p-2">
            <div id="partiGrid"></div>
        </div>
    </div>

    <!--- Parti Satır Detayları --->
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-th-list"></i>Tüm Parti Kalemleri</div>
        </div>
        <div class="card-body p-2">
            <div class="parti-row-header mb-2">
                <div id="rowFilterInfo" class="text-muted small">Tüm partiler gösteriliyor — partiye tıklayarak filtreleyin</div>
            </div>
            <div id="partiRowGrid"></div>
        </div>
    </div>

</div>

<cfoutput>
<style>
.summary-card { display:flex; align-items:center; gap:14px; padding:16px 20px; border-radius:10px; color:##fff; box-shadow:0 2px 10px rgba(0,0,0,.12); }
.summary-icon { font-size:1.8rem; opacity:.85; }
.summary-label { font-size:.75rem; opacity:.85; display:block; }
.summary-value { font-size:1.6rem; font-weight:700; display:block; }
.roll-summary-row { display:grid; grid-template-columns:repeat(4,minmax(140px,1fr)); gap:10px; }
.roll-summary-row > div { background:##f8fafc; border:1px solid ##e2e8f0; border-radius:8px; padding:10px 12px; }
.roll-summary-row span { display:block; color:##64748b; font-size:.75rem; font-weight:600; text-transform:uppercase; }
.roll-summary-row strong { display:block; color:##0f172a; font-size:1rem; margin-top:2px; }
@media (max-width: 768px) { .roll-summary-row { grid-template-columns:1fr; } }
.parti-row-header { display:flex; align-items:center; justify-content:space-between; padding:6px 12px; background:##f1f5f9; border-radius:6px; margin-bottom:6px; }
.parti-filter-badge { display:inline-flex; align-items:center; gap:6px; background:##2563ab; color:##fff; border-radius:20px; padding:3px 10px; font-size:.8rem; }
.color-badge { display:inline-flex; align-items:center; gap:5px; padding:2px 8px; border-radius:12px; font-size:.78rem; font-weight:600; color:##fff; background:##6366f1; }
.color-select-btn { border:none; background:transparent; cursor:pointer; color:##6366f1; padding:2px 6px; border-radius:4px; font-size:.78rem; }
.color-select-btn:hover { background:##ede9fe; }
/* Renk popup */
##colorPickerModal { z-index: 99999 !important; }
.modal-backdrop { z-index: 99998 !important; }
##colorPickerModal .color-option { cursor:pointer; border:2px solid ##e5e7eb; border-radius:8px; padding:8px 12px; transition:.15s; display:flex; align-items:center; gap:8px; }
##colorPickerModal .color-option:hover { border-color:##6366f1; background:##f5f3ff; }
##colorPickerModal .color-option.active { border-color:##6366f1; background:##ede9fe; }
##colorPickerModal .color-dot { width:14px; height:14px; border-radius:50%; background:##6366f1; flex-shrink:0; }
</style>

<!-- Renk Seçim Modal -->
<div class="modal fade" id="colorPickerModal" tabindex="-1" aria-labelledby="colorPickerLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="colorPickerLabel"><i class="fas fa-palette me-2"></i>Renk Seçimi</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <p class="text-muted small mb-3" id="colorPickerProductName"></p>
                <div id="colorOptionsList" class="d-flex flex-wrap gap-2"></div>
                <div class="mt-3" id="noColorMsg" style="display:none;">
                    <div class="alert alert-info py-2 mb-0">Bu ürün için tanımlı renk varyantı bulunmuyor.</div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-primary btn-sm" id="colorPickerSaveBtn" disabled>
                    <i class="fas fa-check me-1"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>

<script>
var partilerData    = #serializeJSON(partilerArr)#;
var partiRowsData   = #serializeJSON(partiRowsArr)#;
var shipRollsData   = #serializeJSON(shipRollsArr)#;
var colorVariants   = #serializeJSON(colorVariantsArr)#;
var shipId          = #shipId#;

/* Renk haritası: product_id -> [{stock_id, stock_code, stock_code_2, property}] */
var colorMap = {};
colorVariants.forEach(function(v) {
    var pid = v.PRODUCT_ID || v.product_id;
    if (!colorMap[pid]) colorMap[pid] = [];
    colorMap[pid].push({
        stock_id:     v.STOCK_ID     || v.stock_id,
        stock_code:   v.STOCK_CODE   || v.stock_code   || '',
        stock_code_2: v.STOCK_CODE_2 || v.stock_code_2 || '',
        property:     v.PROPERTY     || v.property     || ''
    });
});

/* Seçili parti filtresi */
var activeOrderId = null;

/* Renk popup durumu */
var colorPickerRowId    = null;
var colorPickerStockId  = null;
var colorPickerSelected = null;

/* Paletten renk renkleri (sıralı) */
var paletteBg = ['##6366f1','##2563ab','##15803d','##b45309','##be123c','##0e7490','##7c3aed','##c2410c','##166534','##1e40af'];
function getBg(i) { return paletteBg[i % paletteBg.length]; }

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {

        /* ─── Yardımcı: gridy yenile -──────────────────────────────── */
        function refreshRowGrid() {
            var filtered = activeOrderId
                ? partiRowsData.filter(function(r){ return (r.ORDER_ID||r.order_id) == activeOrderId; })
                : partiRowsData;

            var _el = document.getElementById('partiRowGrid');
            var g = _el ? DevExpress.ui.dxDataGrid.getInstance(_el) : null;
            if (g) g.option('dataSource', filtered);

            /* Filtre başlık güncelle */
            if (activeOrderId) {
                var parti = partilerData.find(function(p){ return (p.ORDER_ID||p.order_id)==activeOrderId; });
                var lbl   = parti ? (parti.ORDER_NUMBER||parti.order_number||('##'+activeOrderId)) : ('##'+activeOrderId);
                $('##rowFilterInfo').html(
                    '<span class="parti-filter-badge">' +
                    '<i class="fas fa-filter"></i>' + lbl +
                    '</span>' +
                    '<button class="btn btn-sm btn-outline-secondary ms-2 py-0" onclick="clearPartiFilter()"><i class="fas fa-times"></i> Tümü</button>'
                );
            } else {
                $('##rowFilterInfo').html('<span class="text-muted small">Tüm partiler gösteriliyor — partiye tıklayarak filtreleyin</span>');
            }
        }


        /* ─── Sevkiyat topları grid ─── */
        $('##shipRollGrid').dxDataGrid({
            dataSource: shipRollsData,
            showBorders: true, showRowLines: true, showColumnLines: true,
            rowAlternationEnabled: true, columnAutoWidth: true,
            allowColumnResizing: true, columnResizingMode: 'widget',
            paging: { pageSize: 50 },
            filterRow: { visible: true },
            sorting: { mode:'multiple' },
            noDataText: 'Bu irsaliyeye ait sevkiyat topu bulunamadı',
            export: { enabled: true, fileName: 'sevkiyat_toplari_' + shipId },
            columns: [
                { dataField:'order_number', caption:'Parti', width:150 },
                { dataField:'roll_no', caption:'Top No', width:90, alignment:'center', dataType:'number' },
                { dataField:'roll_barcode', caption:'Barkod', minWidth:160 },
                { dataField:'metre', caption:'Metre', width:110, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'kg', caption:'Kg', width:110, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:3} },
                { dataField:'paket_durumu', caption:'Paket Durumu', width:140, cellTemplate: function(c,o){ $('<span>').addClass('badge bg-light text-dark border').text(o.value || '—').appendTo(c); } },
                { caption:'Etiket', width:95, alignment:'center', allowSorting:false, allowFiltering:false, cellTemplate: function(c,o){
                    $('<button>').addClass('btn btn-sm btn-outline-dark').attr('title','Etiket Yazdır').html('<i class="fas fa-print"></i>').on('click', function(e){
                        e.preventDefault(); e.stopPropagation();
                        window.open('/ship/display/ship_roll_label.cfm?roll_id=' + (o.data.ROLL_ID || o.data.roll_id), '_blank', 'width=520,height=720,scrollbars=yes');
                    }).appendTo(c);
                } },
                { dataField:'record_date', caption:'Kayıt Tarihi', width:150 }
            ],
            summary: { totalItems: [
                { column:'metre', summaryType:'sum', displayFormat:'Toplam: {0}', valueFormat:{type:'fixedPoint',precision:2} },
                { column:'kg', summaryType:'sum', displayFormat:'Toplam: {0}', valueFormat:{type:'fixedPoint',precision:3} },
                { column:'roll_no', summaryType:'count', displayFormat:'{0} top' }
            ] }
        });

        /* ─── Partiler grid ─── */
        $('##partiGrid').dxDataGrid({
            dataSource: partilerData,
            showBorders: true, showRowLines: true, showColumnLines: true,
            rowAlternationEnabled: true, columnAutoWidth: true,
            allowColumnResizing: true, columnResizingMode: 'widget',
            paging: { pageSize: 50 },
            filterRow: { visible: true },
            sorting: { mode:'multiple' },
            export: { enabled: true, fileName: 'partiler_' + shipId },
            onRowClick: function(e) {
                var clickedId = e.data.ORDER_ID || e.data.order_id;
                if (activeOrderId === clickedId) {
                    activeOrderId = null;
                } else {
                    activeOrderId = clickedId;
                }
                refreshRowGrid();
                /* Seçili satır vurgusu */
                $('##partiGrid .dx-row-focused').removeClass('dx-row-focused');
                if (activeOrderId) {
                    var inst = $('##partiGrid').dxDataGrid('instance');
                    var idx  = partilerData.findIndex(function(p){ return (p.ORDER_ID||p.order_id)==activeOrderId; });
                    if (idx >= 0) inst.selectRowsByIndexes([idx]);
                } else {
                    $('##partiGrid').dxDataGrid('instance').clearSelection();
                }
            },
            selection: { mode: 'single' },
            columns: [
                { dataField:'order_id',     caption:'Sipariş ID', width:90,  alignment:'center', dataType:'number' },
                { dataField:'order_number', caption:'Parti Kodu', width:160,
                    cellTemplate: function(c,o){ $('<strong>').text(o.value||'-').appendTo(c); }
                },
                { dataField:'stage_label',  caption:'Aşama', width:130,
                    cellTemplate: function(c,o){
                        var cls = {
                            'Beklemede':'badge bg-secondary', 'Onaylandı':'badge bg-primary',
                            'Üretimde':'badge bg-warning text-dark', 'Hazır':'badge bg-info text-dark',
                            'Sevk Edildi':'badge bg-success', 'Tamamlandı':'badge bg-dark'
                        }[o.value] || 'badge bg-secondary';
                        $('<span>').addClass(cls).text(o.value||'-').appendTo(c);
                    }
                },
                { dataField:'order_date',   caption:'Sipariş Tarihi', width:130 },
                { dataField:'deliverdate',  caption:'Teslim Tarihi',  width:130 },
                { dataField:'grosstotal',   caption:'Brüt',    width:110, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'taxtotal',     caption:'KDV',     width:100, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'nettotal',     caption:'Net',     width:110, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'record_date',  caption:'Kayıt Tarihi', width:140 },
                { dataField:'sarim_sekli_adi', caption:'Sarım Şekli', width:120 },
                { dataField:'ambalaj_adi',     caption:'Ambalaj',      width:120 },
                {
                    caption:'İşlemler', width:165, alignment:'center', allowSorting:false, allowFiltering:false,
                    cellTemplate: function(c,o){
                        var oid = o.data.ORDER_ID || o.data.order_id;
                        var pOrderId = o.data.P_ORDER_ID || o.data.p_order_id || 0;
                        var g   = $('<div>').addClass('d-flex gap-1 justify-content-center');
                        $('<button>').addClass('btn btn-sm btn-outline-info').attr('title','Parti Detay')
                            .html('<i class="fas fa-eye"></i>')
                            .on('click', function(e2){
                                e2.stopPropagation();
                                window.location.href='index.cfm?fuseaction=ship.detail_parti&order_id='+oid;
                            })
                            .appendTo(g);
                        if (pOrderId > 0) {
                            $('<button>').addClass('btn btn-sm btn-outline-dark').attr('title','Reçete Yazdır')
                                .html('<i class="fas fa-print"></i>')
                                .on('click', function(e2){
                                    e2.stopPropagation();
                                    window.open('index.cfm?fuseaction=production.print_recipe&p_order_id=' + pOrderId, '_blank');
                                })
                                .appendTo(g);
                        }
                        $('<button>').addClass('btn btn-sm btn-outline-primary').attr('title','Partiyi Düzenle')
                            .html('<i class="fas fa-edit"></i>')
                            .on('click', function(e2){
                                e2.stopPropagation();
                                window.location.href='index.cfm?fuseaction=ship.edit_parti&order_id='+oid;
                            })
                            .appendTo(g);
                        g.appendTo(c);
                    }
                }
            ],
            summary: {
                totalItems: [
                    { column:'order_id',   summaryType:'count', displayFormat:'{0} parti' },
                    { column:'grosstotal', summaryType:'sum',   displayFormat:'Brüt: {0}',  valueFormat:{type:'fixedPoint',precision:2} },
                    { column:'nettotal',   summaryType:'sum',   displayFormat:'Net: {0}',   valueFormat:{type:'fixedPoint',precision:2} }
                ]
            }
        });

        /* ─── Parti kalemleri grid ─── */
        $('##partiRowGrid').dxDataGrid({
            dataSource: partiRowsData,
            showBorders: true, showRowLines: true, showColumnLines: true,
            rowAlternationEnabled: true, columnAutoWidth: true,
            allowColumnResizing: true, columnResizingMode: 'widget',
            paging: { pageSize: 100 },
            filterRow: { visible: true },
            sorting: { mode:'multiple' },
            columns: [
                { dataField:'order_number', caption:'Parti', width:160,
                    cellTemplate: function(c,o){ $('<span>').addClass('fw-semibold text-primary').text(o.value||'-').appendTo(c); }
                },
                {
                    dataField:'product_name', caption:'Ürün / İşlem', minWidth:200,
                    cellTemplate: function(c,o) {
                        var d        = o.data;
                        var isMain   = d.IS_MAIN_STOCK !== undefined ? d.IS_MAIN_STOCK : d.is_main_stock;
                        var propVal  = d.STOCK_PROPERTY || d.stock_property || '';
                        var name     = o.value || '-';
                        var wrap     = $('<div>').addClass('d-flex align-items-center gap-2');

                        if (isMain === false || isMain === 'false' || isMain === 0) {
                            /* Renk varyantı — renkli badge ile göster */
                            $('<span>').text(name).appendTo(wrap);
                            if (propVal) {
                                var pidKey = d.PRODUCT_ID || d.product_id;
                                var idx    = (colorMap[pidKey]||[]).findIndex(function(v){ return v.stock_id==(d.STOCK_ID||d.stock_id); });
                                var bg     = getBg(idx >= 0 ? idx : 0);
                                $('<span>').addClass('color-badge').css('background', bg).html('<i class="fas fa-circle me-1" style="font-size:.6rem"></i>' + $('<span>').text(propVal).html()).appendTo(wrap);
                            }
                        } else {
                            /* Ana stok — renksiz + renk seç butonu */
                            $('<span>').text(name).appendTo(wrap);
                            var pidKey2 = d.PRODUCT_ID || d.product_id;
                            if (pidKey2 && colorMap[pidKey2] && colorMap[pidKey2].length > 0) {
                                $('<button>').addClass('color-select-btn').attr('title','Renk Ata')
                                    .html('<i class="fas fa-palette"></i> Renk Seç')
                                    .on('click', function(e2){
                                        e2.stopPropagation();
                                        openColorPicker(d, pidKey2);
                                    })
                                    .appendTo(wrap);
                            }
                        }
                        wrap.appendTo(c);
                    }
                },
                { dataField:'quantity',  caption:'Miktar', width:100, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:4} },
                { dataField:'unit',      caption:'Birim',  width:70 },
                { dataField:'price',     caption:'Fiyat',  width:100, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:4} },
                { dataField:'tax',       caption:'KDV %', width:75,  alignment:'right', dataType:'number' },
                { dataField:'nettotal',  caption:'Net',    width:110, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} }
            ],
            summary: {
                groupItems: [
                    { column:'quantity', summaryType:'sum', displayFormat:'Toplam: {0}', valueFormat:{type:'fixedPoint',precision:4} }
                ],
                totalItems: [
                    { column:'nettotal', summaryType:'sum', displayFormat:'Toplam: {0}', valueFormat:{type:'fixedPoint',precision:2} }
                ]
            }
        });

        /* İlk açılışta filtre ipucu göster */
        refreshRowGrid();
    }

    /* ─── Renk seçici ─────────────────────────────────────────── */
    $('##colorPickerSaveBtn').on('click', function() {
        if (!colorPickerSelected || !colorPickerRowId) return;
        var $btn = $(this).prop('disabled', true).html('<i class="fas fa-spinner fa-spin me-1"></i>Kaydediliyor...');
        $.post('/ship/form/update_order_row_stock.cfm', {
            order_row_id: colorPickerRowId,
            stock_id:     colorPickerSelected.stock_id
        }, function(res) {
            if (res && res.success) {
                /* partiRowsData güncelle */
                for (var i=0; i<partiRowsData.length; i++) {
                    var r = partiRowsData[i];
                    if ((r.ORDER_ROW_ID||r.order_row_id) == colorPickerRowId) {
                        r.STOCK_ID      = r.stock_id      = res.stock_id;
                        r.PRODUCT_NAME  = r.product_name  = res.product_name;
                        r.IS_MAIN_STOCK = r.is_main_stock = false;
                        r.STOCK_PROPERTY= r.stock_property= res.property;
                        r.STOCK_CODE_2  = r.stock_code_2  = res.stock_code_2;
                        break;
                    }
                }
                try { refreshRowGrid(); } catch(e) { console.warn('refreshRowGrid:', e); }
                var modal = bootstrap.Modal.getInstance(document.getElementById('colorPickerModal'));
                if (modal) modal.hide();
            } else {
                alert('Hata: ' + (res.message || 'Bilinmeyen hata'));
                $btn.prop('disabled',false).html('<i class="fas fa-check me-1"></i>Kaydet');
            }
        }, 'json').fail(function(){
            alert('Sunucu hatası oluştu.');
            $btn.prop('disabled',false).html('<i class="fas fa-check me-1"></i>Kaydet');
        });
    });
});

function clearPartiFilter() {
    activeOrderId = null;
    $('##partiGrid').dxDataGrid('instance').clearSelection();
    refreshRowGrid();
}

function openColorPicker(rowData, productId) {
    var rowId       = rowData.ORDER_ROW_ID || rowData.order_row_id;
    var productName = rowData.PRODUCT_NAME || rowData.product_name || '';
    var variants    = colorMap[productId] || [];

    colorPickerRowId    = rowId;
    colorPickerStockId  = rowData.STOCK_ID || rowData.stock_id;
    colorPickerSelected = null;

    $('##colorPickerProductName').text(productName);
    $('##colorPickerSaveBtn').prop('disabled', true).html('<i class="fas fa-check me-1"></i>Kaydet');

    var $list = $('##colorOptionsList').empty();
    $('##noColorMsg').hide();

    if (variants.length === 0) {
        $('##noColorMsg').show();
    } else {
        variants.forEach(function(v, idx) {
            var label  = v.property || v.stock_code_2 || v.stock_code;
            var bg     = getBg(idx);
            var $opt = $('<div>').addClass('color-option').attr('data-stock-id', v.stock_id)
                .html('<span class="color-dot" style="background:'+bg+'"></span>' +
                      '<span>' + $('<span>').text(label).html() +
                      (v.stock_code_2 ? ' <small class="text-muted">(' + $('<span>').text(v.stock_code_2).html() + ')</small>' : '') +
                      '</span>');
            $opt.on('click', function() {
                $list.find('.color-option').removeClass('active');
                $(this).addClass('active');
                colorPickerSelected = v;
                $('##colorPickerSaveBtn').prop('disabled', false);
            });
            $list.append($opt);
        });
    }

    var modalEl = document.getElementById('colorPickerModal');
    /* DevExtreme stacking context'inden çıkar, body'e taşı */
    if (modalEl.parentNode !== document.body) document.body.appendChild(modalEl);
    var modal = bootstrap.Modal.getOrCreateInstance(modalEl);
    modal.show();
}
</script>
</cfoutput>
