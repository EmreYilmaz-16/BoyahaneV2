
<cfprocessingdirective pageEncoding="utf-8">
<cfset shipId = isDefined("attributes.ship_id") AND isNumeric(attributes.ship_id) ? val(attributes.ship_id) : (isDefined("url.ship_id") AND isNumeric(url.ship_id) ? val(url.ship_id) : 0)>

<cfif shipId lte 0>
    <div class="alert alert-warning m-3"><i class="fas fa-exclamation-triangle me-2"></i>Lütfen bir irsaliye seçin (ship_id gerekli).</div>
    <cfabort>
</cfif>

<!--- İrsaliye bilgisi --->
<cfquery name="getShip" datasource="boyahane">
    SELECT s.ship_id, s.ship_number, s.company_id,
           s.hk_metre, s.hk_kg,
           COALESCE(c.nickname, c.fullname, '') AS company_name
    FROM ship s
    LEFT JOIN company c ON s.company_id = c.company_id
    WHERE s.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getShip.recordCount>
    <div class="alert alert-danger m-3">İrsaliye bulunamadı (#shipId#).</div>
    <cfabort>
</cfif>

<!--- Sarım şekli ve ambalaj tipleri --->
<cfquery name="getSarimSekli" datasource="boyahane">
    SELECT sarim_sekli_id, sarim_sekli_adi, COALESCE(is_default, false) AS is_default
    FROM setup_sarim_sekli
    WHERE is_active = true
    ORDER BY sort_order, sarim_sekli_adi
</cfquery>

<cfquery name="getAmbalajTipleri" datasource="boyahane">
    SELECT ambalaj_id, ambalaj_adi, COALESCE(is_default, false) AS is_default
    FROM setup_ambalaj
    WHERE is_active = true
    ORDER BY sort_order, ambalaj_adi
</cfquery>

<!--- Ana ürün satırı (irsaliyenin ilk ship_row'u) --->
<cfquery name="getShipRow" datasource="boyahane">
    SELECT sr.ship_row_id, sr.stock_id, sr.product_id,
           sr.name_product, sr.amount, sr.amount2, sr.unit, sr.unit_id
    FROM ship_row sr
    WHERE sr.ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
    ORDER BY sr.ship_row_id
    LIMIT 1
</cfquery>

<!--- Mevcut parti sayısı (ref_ship_id ile bağlı siparışler) --->
<cfquery name="countParts" datasource="boyahane">
    SELECT COUNT(*) AS c FROM orders
    WHERE ref_ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
       OR (ref_ship_id IS NULL AND ref_no IS NOT NULL AND ref_no <> '' AND ref_no = <cfqueryparam value="#getShip.ship_number#" cfsqltype="cf_sql_varchar">)
</cfquery>
<cfset partiNo   = countParts.c + 1>
<cfset partiKodu = getShip.ship_number & "-P" & partiNo>



<!--- Son parti verileri (miktar/kg/açıklama/tekstil ön doldurma) --->
<cfquery name="getSonPartiRec" datasource="boyahane">
    SELECT o.order_id, COALESCE(o.order_head, '') AS order_head,
           o.en, o.gramaj, o.kumas_tipi, o.tuse, o.isi, o.hiz, o.besleme_avans, o.cekme,
           COALESCE(o.top_adedi, 0) AS top_adedi
    FROM orders o
    WHERE o.ref_ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
    ORDER BY o.order_id DESC
    LIMIT 1
</cfquery>
<cfset sonPartiMiktar   = "">
<cfset sonPartiKg       = "">
<cfset sonPartiAciklama = "">
<cfset sonPartiTop      = "">
<!--- Tekstil: önce ürün tanımından al, sonra son parti varsa üzerine yaz --->
<cfset sonPartiTekstil = {
    "kumas_tipi":    tekstilBilgi.kumas_tipi    ?: "",
    "en":            tekstilBilgi.en            ?: "",
    "gramaj":        tekstilBilgi.gramaj        ?: "",
    "isi":           tekstilBilgi.isi           ?: "",
    "hiz":           tekstilBilgi.hiz           ?: "",
    "besleme_avans": tekstilBilgi.besleme_avans ?: "",
    "tuse":          tekstilBilgi.tuse          ?: "",
    "cekme":         tekstilBilgi.cekme         ?: ""
}>
<cfif getSonPartiRec.recordCount AND val(getSonPartiRec.order_id) gt 0>
    <cfquery name="getSonPartiMiktar" datasource="boyahane">
        SELECT orw.quantity
        FROM order_row orw
        JOIN stocks st ON orw.stock_id = st.stock_id
        WHERE orw.order_id = <cfqueryparam value="#getSonPartiRec.order_id#" cfsqltype="cf_sql_integer">
          AND COALESCE(st.is_main_stock, true) = true
          AND LOWER(TRIM(orw.unit)) IN ('mt','mtr','m','metre')
        ORDER BY orw.order_row_id
        LIMIT 1
    </cfquery>
    <cfquery name="getSonPartiKg" datasource="boyahane">
        SELECT orw.quantity
        FROM order_row orw
        WHERE orw.order_id = <cfqueryparam value="#getSonPartiRec.order_id#" cfsqltype="cf_sql_integer">
          AND LOWER(TRIM(orw.unit)) = 'kg'
        ORDER BY orw.order_row_id
        LIMIT 1
    </cfquery>
    <cfif getSonPartiMiktar.recordCount AND isNumeric(getSonPartiMiktar.quantity) AND val(getSonPartiMiktar.quantity) gt 0>
        <cfset sonPartiMiktar = val(getSonPartiMiktar.quantity)>
    </cfif>
    <cfif getSonPartiKg.recordCount AND isNumeric(getSonPartiKg.quantity) AND val(getSonPartiKg.quantity) gt 0>
        <cfset sonPartiKg = val(getSonPartiKg.quantity)>
    </cfif>
    <cfif len(trim(getSonPartiRec.order_head ?: ""))>
        <cfset sonPartiAciklama = trim(getSonPartiRec.order_head)>
    </cfif>
    <cfif isNumeric(getSonPartiRec.top_adedi) AND val(getSonPartiRec.top_adedi) gt 0>
        <cfset sonPartiTop = val(getSonPartiRec.top_adedi)>
    </cfif>
    <!--- Tekstil alanları son partizde dolu ise üzerine yaz --->
    <cfif isNumeric(getSonPartiRec.en) AND val(getSonPartiRec.en) gt 0>
        <cfset sonPartiTekstil.en = val(getSonPartiRec.en)>
    </cfif>
    <cfif isNumeric(getSonPartiRec.gramaj) AND val(getSonPartiRec.gramaj) gt 0>
        <cfset sonPartiTekstil.gramaj = val(getSonPartiRec.gramaj)>
    </cfif>
    <cfif isNumeric(getSonPartiRec.isi) AND val(getSonPartiRec.isi) gt 0>
        <cfset sonPartiTekstil.isi = val(getSonPartiRec.isi)>
    </cfif>
    <cfif isNumeric(getSonPartiRec.hiz) AND val(getSonPartiRec.hiz) gt 0>
        <cfset sonPartiTekstil.hiz = val(getSonPartiRec.hiz)>
    </cfif>
    <cfif isNumeric(getSonPartiRec.besleme_avans) AND val(getSonPartiRec.besleme_avans) gt 0>
        <cfset sonPartiTekstil.besleme_avans = val(getSonPartiRec.besleme_avans)>
    </cfif>
    <cfif len(trim(getSonPartiRec.kumas_tipi ?: ""))>
        <cfset sonPartiTekstil.kumas_tipi = trim(getSonPartiRec.kumas_tipi)>
    </cfif>
    <cfif len(trim(getSonPartiRec.tuse ?: ""))>
        <cfset sonPartiTekstil.tuse = trim(getSonPartiRec.tuse)>
    </cfif>
    <cfif len(trim(getSonPartiRec.cekme ?: ""))>
        <cfset sonPartiTekstil.cekme = trim(getSonPartiRec.cekme)>
    </cfif>
</cfif>
<cfset params = structNew()>
<cfquery name="getParams" datasource="boyahane">
    SELECT parametre_adi, deger FROM boyahane_params
</cfquery>
<cfloop query="getParams">
    <cfset params[parametre_adi] = deger>
</cfloop>

<!--- Ek işlem ürünleri (bu firmaya ait) --->
<cfquery name="getEkIslem" datasource="boyahane">
    SELECT s.stock_id, s.stock_code, p.product_id, p.product_name, p.product_code
    FROM stocks s
    JOIN product p ON s.product_id = p.product_id
    WHERE p.company_id      = <cfqueryparam value="#getShip.company_id#" cfsqltype="cf_sql_integer">
      AND p.is_ek_islem = true
      AND s.stock_status    = true
    ORDER BY p.product_name
</cfquery>

<!--- Ek işlem ürünleri için kategori listesi (hızlı ekleme modalı) --->
<cfquery name="getProductCats" datasource="boyahane">
    SELECT product_catid, product_cat, hierarchy
    FROM product_cat
    <cfif structKeyExists(params, "ek_islem_kategori_ids") AND len(trim(params.ek_islem_kategori_ids))>
        where product_catid IN (
            <cfqueryparam value="#params.ek_islem_kategori_ids#" cfsqltype="cf_sql_integer" list="true">
        )
    </cfif>
    ORDER BY hierarchy, product_cat
</cfquery>

<!--- Ek işlemleri JSON dizisine çevir (JS için) --->
<cfset ekIslemArray = []>
<cfloop query="getEkIslem">
    <cfset arrayAppend(ekIslemArray, {
        "stock_id":     stock_id,
        "product_id":   product_id,
        "product_name": product_name ?: "",
        "product_code": product_code ?: "",
        "stock_code":   stock_code   ?: ""
    })>
</cfloop>

<!--- Ana ürün değerleri --->
<cfset mainStockId   = getShipRow.recordCount ? val(getShipRow.stock_id   ?: 0) : 0>
<cfset mainProductId = getShipRow.recordCount ? val(getShipRow.product_id ?: 0) : 0>
<cfset mainName      = getShipRow.recordCount ? (getShipRow.name_product  ?: "") : "">
<cfset mainMetre     = getShipRow.recordCount AND isNumeric(getShipRow.amount)  ? getShipRow.amount  : "">
<cfset mainKg        = getShipRow.recordCount AND isNumeric(getShipRow.amount2) ? getShipRow.amount2 : "">
<cfset mainUnit      = getShipRow.recordCount ? (getShipRow.unit   ?: "mt") : "mt">
<cfset mainUnitId    = getShipRow.recordCount ? val(getShipRow.unit_id ?: 0) : 0>

<!--- Ana ürünün tekstil bilgileri --->
<cfset tekstilBilgi = {}>
<cfif mainProductId gt 0>
    <cfquery name="getTekstilBilgi" datasource="boyahane">
        SELECT en, tuse, cekme, isi, hiz, gramaj, besleme_avans, kumas_tipi
        FROM product
        WHERE product_id = <cfqueryparam value="#mainProductId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif getTekstilBilgi.recordCount>
        <cfset tekstilBilgi = {
            "en":            isNumeric(getTekstilBilgi.en) ? getTekstilBilgi.en : "",
            "tuse":          len(getTekstilBilgi.tuse ?: "") ? getTekstilBilgi.tuse : "",
            "cekme":         len(getTekstilBilgi.cekme ?: "") ? getTekstilBilgi.cekme : "",
            "isi":           isNumeric(getTekstilBilgi.isi) ? getTekstilBilgi.isi : "",
            "hiz":           isNumeric(getTekstilBilgi.hiz) ? getTekstilBilgi.hiz : "",
            "gramaj":        isNumeric(getTekstilBilgi.gramaj) ? getTekstilBilgi.gramaj : "",
            "besleme_avans": isNumeric(getTekstilBilgi.besleme_avans) ? getTekstilBilgi.besleme_avans : "",
            "kumas_tipi":    len(getTekstilBilgi.kumas_tipi ?: "") ? getTekstilBilgi.kumas_tipi : ""
        }>
    </cfif>
</cfif>

<!--- Müşteri satış fiyat listesi ---> 
<cfset companyPriceCat = 0>
<cfquery name="getCompanyCat" datasource="boyahane">
    SELECT price_cat FROM company_credit
    WHERE company_id = <cfqueryparam value="#getShip.company_id#" cfsqltype="cf_sql_integer">
    LIMIT 1
</cfquery>
<cfif getCompanyCat.recordCount AND isNumeric(getCompanyCat.price_cat) AND val(getCompanyCat.price_cat) gt 0>
    <cfset companyPriceCat = val(getCompanyCat.price_cat)>
</cfif>

<cfset priceList = []>
<cfif companyPriceCat gt 0>
    <cfquery name="getCompanyPrices" datasource="boyahane">
        SELECT pr.stock_id, pr.price,
               COALESCE(p.tax, 0) AS tax
        FROM price pr
        LEFT JOIN product p ON pr.product_id = p.product_id
        WHERE pr.price_catid = <cfqueryparam value="#companyPriceCat#" cfsqltype="cf_sql_integer">
          AND pr.stock_id IS NOT NULL
    </cfquery>
    <cfloop query="getCompanyPrices">
        <cfif val(stock_id) gt 0>
            <cfset arrayAppend(priceList, {
                "stock_id": val(stock_id),
                "price":    isNumeric(price) ? price : 0,
                "tax":      isNumeric(tax)   ? tax   : 0
            })>
        </cfif>
    </cfloop>
</cfif>

<!--- Tamamen partilendi kontrolü --->
<cfset shipHkMetre = isNumeric(getShip.hk_metre) ? val(getShip.hk_metre) : 0>
<cfif shipHkMetre gt 0 AND mainProductId gt 0 AND len(trim(getShip.ship_number))>
    <cfquery name="getPartiToplamMiktar" datasource="boyahane">
        SELECT COALESCE(SUM(orw.quantity), 0) AS toplam
        FROM orders o
        JOIN order_row orw ON o.order_id = orw.order_id
        WHERE (o.ref_ship_id = <cfqueryparam value="#shipId#" cfsqltype="cf_sql_integer">
           OR (o.ref_ship_id IS NULL AND o.ref_no IS NOT NULL AND o.ref_no <> '' AND o.ref_no = <cfqueryparam value="#getShip.ship_number#" cfsqltype="cf_sql_varchar">))
          AND orw.product_id = <cfqueryparam value="#mainProductId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif val(getPartiToplamMiktar.toplam) gte shipHkMetre>
        <cfoutput>
        <div class="alert alert-warning m-4 d-flex align-items-start gap-3">
            <i class="fas fa-lock fs-3 mt-1 text-warning"></i>
            <div>
                <h5 class="mb-1">Bu giriş fişi tamamen partilendi!</h5>
                <p class="mb-2">Toplam <strong>#numberFormat(shipHkMetre,'0.00')# mt</strong> girişin tamamı (<strong>#numberFormat(val(getPartiToplamMiktar.toplam),'0.00')# mt</strong>) sipariş/parti olarak işlenmiştir.</p>
                <a href="index.cfm?fuseaction=ship.list_giris_fis" class="btn btn-sm btn-secondary">
                    <i class="fas fa-arrow-left me-1"></i>Giriş Fişleri Listesi
                </a>
                <a href="index.cfm?fuseaction=ship.list_partiler&ship_id=#shipId#" class="btn btn-sm btn-outline-primary ms-2">
                    <i class="fas fa-list-ol me-1"></i>Parti Listesi
                </a>
            </div>
        </div>
        </cfoutput>
        <cfabort>
    </cfif>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-cut"></i></div>
        <div class="page-header-title">
            <cfoutput>
            <h1>Parti Oluştur <small class="text-muted fs-6">#partiKodu#</small></h1>
            <p>İrsaliye <strong>#getShip.ship_number#</strong> — <strong>#xmlFormat(getShip.company_name)#</strong></p>
            </cfoutput>
        </div>
    </div>
    <a href="index.cfm?fuseaction=ship.list_ship" class="btn-back">
        <i class="fas fa-arrow-left"></i>İrsaliye Listesi
    </a>
</div>

<div class="px-3 pb-5">
    <div class="row g-3">

        <!--- ═══════ SOL: PARTİ BİLGİLERİ ═══════ --->
        <div class="col-lg-5">
            <div class="grid-card sticky-top-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title">
                        <i class="fas fa-tag"></i>Parti Bilgileri
                    </div>
                </div>
                <div class="card-body p-3">

                    <!--- Sipariş No (Parti Kodu) --->
                    <div class="mb-3">
                        <label class="form-label fw-semibold">
                            <i class="fas fa-hashtag me-1 text-primary"></i>Parti Kodu
                        </label>
                        <input type="text" class="form-control" id="parti_kodu"
                               value="<cfoutput>#xmlFormat(partiKodu)#</cfoutput>">
                        <small class="text-muted">Varsayılan otomatik oluşturuldu, değiştirilebilir.</small>
                    </div>

                    <!--- Aşama --->
                    <div class="mb-3">
                        <label class="form-label fw-semibold">
                            <i class="fas fa-tasks me-1 text-primary"></i>Aşama
                        </label>
                        <cfoutput><select class="form-select" id="order_stage">
                            <option value="1" selected>Beklemede</option>
                            <option value="2">Onaylandı</option>
                            <option value="3">Üretimde</option>
                            <option value="4">Hazır</option>
                            <option value="5">Sevk Edildi</option>
                            <option value="6">Tamamlandı</option>
                        </select></cfoutput>
                    </div>

                    <!--- Teslim Tarihi --->
                    <div class="mb-3">
                        <label class="form-label fw-semibold">
                            <i class="fas fa-calendar-alt me-1 text-primary"></i>Teslim Tarihi
                        </label>
                        <input type="date" class="form-control" id="deliverdate" value="">
                    </div>

                    <!--- Açıklama --->
                    <div class="mb-3">
                        <label class="form-label fw-semibold">
                            <i class="fas fa-sticky-note me-1 text-primary"></i>Açıklama
                        </label>
                        <textarea class="form-control" id="order_detail" rows="3"
                                  placeholder="Parti açıklaması..."><cfoutput>#xmlFormat(sonPartiAciklama)#</cfoutput></textarea>
                    </div>

                    <!--- Sarım ve Ambalaj --->
                    <div class="row g-2 mb-3">
                        <div class="col-6">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-redo me-1 text-primary"></i>Sarım Şekli
                            </label>
                            <select class="form-select" id="sarim_sekli">
                                <option value="0">-- Seçiniz --</option>
                                <cfoutput query="getSarimSekli">
                                <option value="#sarim_sekli_id#"<cfif is_default> selected</cfif>>#xmlFormat(sarim_sekli_adi)#</option>
                                </cfoutput>
                            </select>
                        </div>
                        <div class="col-6">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-box me-1 text-primary"></i>Ambalaj
                            </label>
                            <select class="form-select" id="ambalaj">
                                <option value="0">-- Seçiniz --</option>
                                <cfoutput query="getAmbalajTipleri">
                                <option value="#ambalaj_id#"<cfif is_default> selected</cfif>>#xmlFormat(ambalaj_adi)#</option>
                                </cfoutput>
                            </select>
                        </div>
                    </div>

                    <!--- Kaydet --->
                    <div class="d-grid mt-3">
                        <button type="button" class="btn btn-primary" id="saveBtn" onclick="saveParti()">
                            <i class="fas fa-save me-2"></i>Parti Oluştur
                        </button>
                    </div>

                </div>
            </div>
        </div>

        <!--- ═══════ SAĞ: ANA ÜRÜN + EK İŞLEMLER ═══════ --->
        <div class="col-lg-7">

            <!--- Ana ürün kartı --->
            <div class="grid-card mb-3">
                <div class="grid-card-header">
                    <div class="grid-card-header-title">
                        <i class="fas fa-tshirt"></i>Ana Ürün
                        <small class="text-muted ms-2">(irsaliyeden)</small>
                    </div>
                </div>
                <div class="card-body p-3">

                    <div class="p-3 rounded mb-3" style="background:#f0f7ff;border:1px solid #b3d4ff;">
                        <div class="fw-semibold text-primary mb-1">
                            <i class="fas fa-box me-1"></i>
                            <cfoutput>#xmlFormat(mainName)#</cfoutput>
                        </div>
                        <cfif mainUnit neq "">
                        <small class="text-muted">Birim: <cfoutput>#xmlFormat(mainUnit)#</cfoutput></small>
                        </cfif>
                    </div>

                    <div class="row g-2">
                        <div class="col-sm-4">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-ruler me-1 text-primary"></i>Metre
                            </label>
                            <input type="number" step="0.0001" class="form-control" id="main_metre"
                                   value="<cfoutput>#len(sonPartiMiktar) ? sonPartiMiktar : mainMetre#</cfoutput>"
                                   placeholder="0.0000">
                        </div>
                        <div class="col-sm-4">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-weight me-1 text-primary"></i>Kg
                            </label>
                            <input type="number" step="0.0001" class="form-control" id="main_kg"
                                   value="<cfoutput>#len(sonPartiKg) ? sonPartiKg : mainKg#</cfoutput>"
                                   placeholder="0.0000">
                        </div>
                        <div class="col-sm-4">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-boxes me-1 text-primary"></i>Top Adedi
                            </label>
                            <input type="number" step="1" class="form-control" id="main_top"
                                   value="<cfoutput>#len(sonPartiTop) ? sonPartiTop : ''#</cfoutput>"
                                   placeholder="0">
                        </div>
                    </div>

                    <div class="row g-2 mt-1">
                        <div class="col-sm-6">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-palette me-1 text-primary"></i>Müşteri Renk / Açıklama
                            </label>
                            <input type="text" class="form-control" id="main_color"
                                   placeholder="Renk kodu, açıklama...">
                        </div>
                        <div class="col-sm-6">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-barcode me-1 text-primary"></i>Lot No
                            </label>
                            <input type="text" class="form-control" id="main_lot_no"
                                   value=""
                                   placeholder="Lot / Parti no">
                        </div>
                    </div>

                </div>
            </div>
            <!--- Tekstil Bilgileri Kartı — her zaman göster, editable --->
            <div class="grid-card mb-3">
                <div class="grid-card-header">
                    <div class="grid-card-header-title">
                        <i class="fas fa-tshirt"></i>Tekstil Özellikleri
                        <small class="text-muted ms-2">(önceki partiden / değiştirilebilir)</small>
                    </div>
                </div>
                <div class="card-body p-3">
                    <cfoutput>
                    <div class="row g-2">
                        <div class="col-6 col-sm-4">
                            <label class="form-label fw-semibold small mb-1">Kumaş Tipi</label>
                            <input type="text" class="form-control form-control-sm" id="txt_kumas_tipi"
                                   value="#xmlFormat(sonPartiTekstil.kumas_tipi)#" placeholder="Kumaş tipi...">
                        </div>
                        <div class="col-6 col-sm-4">
                            <label class="form-label fw-semibold small mb-1">En (cm)</label>
                            <input type="number" step="0.01" class="form-control form-control-sm" id="txt_en"
                                   value="#xmlFormat(sonPartiTekstil.en)#" placeholder="0">
                        </div>
                        <div class="col-6 col-sm-4">
                            <label class="form-label fw-semibold small mb-1">Gramaj (g/m²)</label>
                            <input type="number" step="0.01" class="form-control form-control-sm" id="txt_gramaj"
                                   value="#xmlFormat(sonPartiTekstil.gramaj)#" placeholder="0">
                        </div>
                        <div class="col-6 col-sm-4">
                            <label class="form-label fw-semibold small mb-1">Isı (°C)</label>
                            <input type="number" step="0.1" class="form-control form-control-sm" id="txt_isi"
                                   value="#xmlFormat(sonPartiTekstil.isi)#" placeholder="0">
                        </div>
                        <div class="col-6 col-sm-4">
                            <label class="form-label fw-semibold small mb-1">Hız (m/dak)</label>
                            <input type="number" step="0.1" class="form-control form-control-sm" id="txt_hiz"
                                   value="#xmlFormat(sonPartiTekstil.hiz)#" placeholder="0">
                        </div>
                        <div class="col-6 col-sm-4">
                            <label class="form-label fw-semibold small mb-1">Besleme Avans</label>
                            <input type="number" step="0.01" class="form-control form-control-sm" id="txt_besleme_avans"
                                   value="#xmlFormat(sonPartiTekstil.besleme_avans)#" placeholder="0">
                        </div>
                        <div class="col-6 col-sm-4">
                            <label class="form-label fw-semibold small mb-1">Tuşe</label>
                            <input type="text" class="form-control form-control-sm" id="txt_tuse"
                                   value="#xmlFormat(sonPartiTekstil.tuse)#" placeholder="Tuşe...">
                        </div>
                        <div class="col-6 col-sm-4">
                            <label class="form-label fw-semibold small mb-1">Çekme</label>
                            <input type="text" class="form-control form-control-sm" id="txt_cekme"
                                   value="#xmlFormat(sonPartiTekstil.cekme)#" placeholder="Çekme...">
                        </div>
                    </div>
                    </cfoutput>
                </div>
            </div>
            <!--- Ek İşlemler kartı --->
            <div class="grid-card">
                <div class="grid-card-header">
                    <div class="grid-card-header-title">
                        <i class="fas fa-cogs"></i>Ek İşlemler
                        <small class="text-muted ms-2">(sipariş satırı olarak eklenir)</small>
                    </div>
                    <div class="d-flex align-items-center gap-2">
                        <span class="badge bg-secondary" id="ekIslemCount">
                            <cfoutput>#getEkIslem.recordCount#</cfoutput> adet
                        </span>
                        <button type="button" class="btn btn-sm btn-outline-primary py-0 px-2"
                                onclick="openQuickEkIslemModal()"
                                title="Hızlı Ek İşlem Ekle">
                            <i class="fas fa-plus"></i>
                        </button>
                    </div>
                </div>
                <div class="card-body p-3">

                    <cfif NOT getEkIslem.recordCount>
                        <div class="text-center text-muted py-4">
                            <i class="fas fa-info-circle fs-4 mb-2 d-block"></i>
                            Bu firmaya ait "Ek İşlem" ürünü tanımlı değil.
                        </div>
                    <cfelse>
                        <div class="mb-2">
                            <small class="text-muted">İşaretlenen her ek işlem, ana ürünün miktarıyla sipariş satırı olarak eklenir.</small>
                        </div>
                        <div id="ekIslemList">
                            <cfoutput query="getEkIslem">
                            <div class="ek-islem-row p-2 mb-2 rounded" style="border:1px solid ##e9ecef;background:##fafafa;" id="ek_row_#stock_id#">
                                <div class="d-flex align-items-center gap-3">
                                    <div class="form-check mb-0">
                                        <input class="form-check-input ek-chk" type="checkbox"
                                               id="ek_chk_#stock_id#"
                                               data-stock-id="#stock_id#"
                                               data-product-id="#product_id#"
                                               data-product-name="#xmlFormat(product_name)#"
                                               data-product-code="#xmlFormat(product_code ?: '')#"
                                               data-stock-code="#xmlFormat(stock_code ?: '')#">
                                        <label class="form-check-label fw-semibold" for="ek_chk_#stock_id#">
                                            #xmlFormat(product_name)#
                                            <cfif len(trim(stock_code))>
                                            <small class="text-muted">(#xmlFormat(stock_code)#)</small>
                                            </cfif>
                                        </label>
                                    </div>

                                </div>
                            </div>
                            </cfoutput>
                        </div>
                    </cfif>

                </div>
            </div>

        </div><!--- /col-lg-7 --->

    </div><!--- /row --->
</div>

<!--- Hızlı Ek İşlem Ekleme Modalı --->
<cfoutput>
<div class="modal fade" id="quickEkIslemModal" tabindex="-1" aria-labelledby="quickEkIslemModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title" id="quickEkIslemModalLabel">
                    <i class="fas fa-plus-circle me-2 text-primary"></i>Hızlı Ek İşlem Ekle
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <!--- Bilgi satırı: şirket ve birim ---> 
                <div class="alert alert-info py-2 mb-3">
                    <small>
                        <i class="fas fa-building me-1"></i><strong>Şirket:</strong> #xmlFormat(getShip.company_name)#
                        &nbsp;&nbsp;
                        <i class="fas fa-ruler me-1"></i><strong>Birim:</strong> #xmlFormat(mainUnit)#
                    </small>
                </div>

                <!--- Ek İşlem Adı --->
                <div class="mb-3">
                    <label for="qei_product_name" class="form-label fw-semibold">
                        Ek İşlem Adı <span class="text-danger">*</span>
                    </label>
                    <input type="text" class="form-control" id="qei_product_name"
                           placeholder="Örn: Boyama, Apre, Kasarlama...">
                </div>

                <!--- Kategori --->
                <div class="mb-3">
                    <label for="qei_product_catid" class="form-label fw-semibold">
                        Kategori <span class="text-danger">*</span>
                    </label>
                    <select class="form-select" id="qei_product_catid">
                        <option value="0">-- Kategori Seçin --</option>
                        <cfloop query="getProductCats">
                        <option value="#product_catid#" data-cat-name="#xmlFormat(product_cat)#">#xmlFormat(hierarchy & ' - ' & product_cat)#</option>
                        </cfloop>
                    </select>
                </div>

                <div id="qei_error" class="text-danger small d-none"></div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-primary" id="qei_saveBtn" onclick="quickAddEkIslem()">
                    <i class="fas fa-save me-2"></i>Kaydet
                </button>
            </div>
        </div>
    </div>
</div>
</cfoutput>

<cfoutput>
<style>
.ek-islem-row { transition: background .15s; }
.ek-islem-row.selected { background: ##e8f5e9 !important; border-color: ##a5d6a7 !important; }
@media(min-width:992px){ .sticky-top-card { position:sticky; top:70px; z-index:1; } }
##quickEkIslemModal { z-index: 99999 !important; }
.modal-backdrop    { z-index: 99998 !important; }
</style>

<script>
/* ─── Fiyat haritası (firma satış fiyat listesi) ─── */
var priceListData = #serializeJSON(priceList)#;
var companyPriceMap = {};
priceListData.forEach(function(r) {
    if (r.STOCK_ID > 0) companyPriceMap[r.STOCK_ID] = { price: r.PRICE || 0, tax: r.TAX || 0 };
});

/* ─── Hızlı Ek İşlem Modal ─── */
var QUICK_COMPANY_ID   = #getShip.company_id#;
var QUICK_COMPANY_NAME = '#jsStringFormat(getShip.company_name)#';
var QUICK_UNIT         = '#jsStringFormat(mainUnit)#';
var QUICK_UNIT_ID      = #mainUnitId#;
var EDIT_ORDER_ID      = 0;

function openQuickEkIslemModal() {
    var modalEl = document.getElementById('quickEkIslemModal');
    /* content-wrapper'ın overflow:hidden içinden kaçmak için body'e taşı */
    if (modalEl.parentElement !== document.body) {
        document.body.appendChild(modalEl);
    }
    document.getElementById('qei_product_name').value = '';
    document.getElementById('qei_product_catid').value = '0';
    var errEl = document.getElementById('qei_error');
    errEl.textContent = '';
    errEl.classList.add('d-none');
    new bootstrap.Modal(modalEl).show();
}

function quickAddEkIslem() {
    var name   = document.getElementById('qei_product_name').value.trim();
    var catid  = parseInt(document.getElementById('qei_product_catid').value) || 0;
    var errEl  = document.getElementById('qei_error');
    var btn    = document.getElementById('qei_saveBtn');

    errEl.classList.add('d-none');

    if (!name) {
        errEl.textContent = 'Ek işlem adı boş olamaz.';
        errEl.classList.remove('d-none');
        document.getElementById('qei_product_name').focus();
        return;
    }
    if (!catid) {
        errEl.textContent = 'Kategori seçmelisiniz.';
        errEl.classList.remove('d-none');
        return;
    }

    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url: '/product/cfc/product.cfc?method=saveProduct',
        method: 'POST',
        data: {
            product_name:   name,
            product_catid:  catid,
            company_id:     QUICK_COMPANY_ID,
            is_ek_islem:    true,
            is_purchase:    true,
            product_status: true
        },
        dataType: 'json',
        success: function(res) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet';
            if (res.success) {
                bootstrap.Modal.getInstance(document.getElementById('quickEkIslemModal')).hide();
                /* Yeni ürünü listeye ekle + checkbox ile seç */
                var newStockId  = res.stock_id  || 0;
                var newProdId   = res.product_id || 0;
                var listEl = document.getElementById('ekIslemList');
                if (!listEl) {
                    /* Liste elementi yoksa (firma için ilk ek işlem) sayfa yenile */
                    location.reload();
                    return;
                }
                var rowId = 'ek_row_' + newStockId;
                var html  = '<div class="ek-islem-row p-2 mb-2 rounded selected" id="' + rowId + '" style="border:1px solid ##a5d6a7;background:##e8f5e9;">'
                          + '<div class="d-flex align-items-center gap-3">'
                          + '<div class="form-check mb-0">'
                          + '<input class="form-check-input ek-chk" type="checkbox" id="ek_chk_' + newStockId + '" checked'
                          + ' data-stock-id="' + newStockId + '"'
                          + ' data-product-id="' + newProdId + '"'
                          + ' data-product-name="' + name.replace(/"/g, '&quot;') + '"'
                          + ' data-product-code=""'
                          + ' data-stock-code="">'
                          + '<label class="form-check-label fw-semibold" for="ek_chk_' + newStockId + '">'
                          + name
                          + ' <small class="badge bg-success ms-1">Yeni</small>'
                          + '</label></div></div></div>';
                listEl.insertAdjacentHTML('beforeend', html);
                /* Checkbox toggle event'ını da bağla */
                var newChk = document.getElementById('ek_chk_' + newStockId);
                if (newChk) {
                    newChk.addEventListener('change', function() {
                        var r = document.getElementById('ek_row_' + this.dataset.stockId);
                        if (this.checked) r.classList.add('selected');
                        else              r.classList.remove('selected');
                    });
                }
                /* Sayacı güncelle */
                var cntEl = document.getElementById('ekIslemCount');
                if (cntEl) cntEl.textContent = (parseInt(cntEl.textContent) || 0) + 1 + ' adet';
            } else {
                errEl.textContent = res.message || 'Kayıt hatası.';
                errEl.classList.remove('d-none');
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Kaydet';
            errEl.textContent = 'Sunucu hatası! Lütfen tekrar deneyin.';
            errEl.classList.remove('d-none');
        }
    });
}

/* ─── Kategori seçilince ürün adını otomatik doldur ─── */
document.getElementById('qei_product_catid').addEventListener('change', function() {
    var sel = this.options[this.selectedIndex];
    var catName = (sel && this.value !== '0') ? sel.getAttribute('data-cat-name') : '';
    if (catName) {
        document.getElementById('qei_product_name').value = catName + '-' + QUICK_COMPANY_NAME;
    }
});

/* ─── Ek işlem checkbox toggle ─── */
document.querySelectorAll('.ek-chk').forEach(function(chk) {
    chk.addEventListener('change', function() {
        var row = document.getElementById('ek_row_' + this.dataset.stockId);
        if (this.checked) row.classList.add('selected');
        else              row.classList.remove('selected');
    });
});

/* ─── Kaydet ─── */
function saveParti() {
    var mainMetre = parseFloat(document.getElementById('main_metre').value) || 0;
    var mainKg    = parseFloat(document.getElementById('main_kg').value)    || 0;
    var mainTop   = parseFloat(document.getElementById('main_top').value)   || 0;

    if (mainMetre <= 0 && mainKg <= 0) {
        alert('Lütfen ana ürün için en az Metre veya Kg girin.');
        document.getElementById('main_metre').focus();
        return;
    }

    /* Ana ürün satırı — miktar olarak metre kullanılır (>0 ise), yoksa kg */
    var mainQty = mainMetre > 0 ? mainMetre : mainKg;
    var mainUnit = '#jsStringFormat(mainUnit)#';

    var mainPriceInfo = companyPriceMap[#mainStockId#] || { price: 0, tax: 0 };
    var mainRowUnit = mainQty === mainMetre ? (mainUnit || 'mt') : 'kg';

    var rows = [{
        stock_id:     #mainStockId#,
        product_id:   #mainProductId#,
        product_name: '#jsStringFormat(mainName)#',
        product_code: '',
        quantity:     mainQty,
        price:        mainPriceInfo.price,
        unit:         mainRowUnit,
        unit_id:      #mainUnitId#,
        tax:          mainPriceInfo.tax,
        discount_1:   0,
        lot_no:       document.getElementById('main_lot_no').value || ''
    }];

    /* Ek işlem satırları — ana ürünün miktarı ve birimi, firma fiyat listesinden fiyat */
    document.querySelectorAll('.ek-chk:checked').forEach(function(chk) {
        var ekSid       = parseInt(chk.dataset.stockId);
        var ekPriceInfo = companyPriceMap[ekSid] || { price: 0, tax: 0 };
        rows.push({
            stock_id:     ekSid,
            product_id:   parseInt(chk.dataset.productId),
            product_name: chk.dataset.productName || '',
            product_code: chk.dataset.productCode || '',
            quantity:     mainQty,
            price:        ekPriceInfo.price,
            unit:         mainRowUnit,
            unit_id:      0,
            tax:          ekPriceInfo.tax,
            discount_1:   0,
            lot_no:       ''
        });
    });

    var today = new Date();
    var todayStr = today.toISOString().slice(0, 10) + 'T' + today.toTimeString().slice(0, 5);

    var data = {
        order_id:       EDIT_ORDER_ID,
        purchase_sales: 'true',
        order_stage:    document.getElementById('order_stage').value,
        order_number:   document.getElementById('parti_kodu').value,
        order_head:     '#jsStringFormat(getShip.company_name)# — ' + document.getElementById('parti_kodu').value,
        ref_no:         '#jsStringFormat(getShip.ship_number)#',
        ref_ship_id:    #shipId#,
        order_detail:   document.getElementById('order_detail').value,
        order_date:     todayStr,
        deliverdate:    document.getElementById('deliverdate').value || '',
        company_id:     #getShip.company_id#,
        member_type:    3,
        ref_company_id: #getShip.company_id#,
        paymethod:      0,
        ship_method:    0,
        order_currency: 0,
        order_status:   '1',
        sarim_sekli:    parseInt(document.getElementById('sarim_sekli').value) || 0,
        ambalaj:        parseInt(document.getElementById('ambalaj').value) || 0,
        top_adedi:      parseInt(document.getElementById('main_top').value) || 0,
        main_color:     document.getElementById('main_color').value || '',
        kumas_tipi:     document.getElementById('txt_kumas_tipi').value || '',
        en:             parseFloat(document.getElementById('txt_en').value) || 0,
        gramaj:         parseFloat(document.getElementById('txt_gramaj').value) || 0,
        isi:            parseFloat(document.getElementById('txt_isi').value) || 0,
        hiz:            parseFloat(document.getElementById('txt_hiz').value) || 0,
        besleme_avans:  parseFloat(document.getElementById('txt_besleme_avans').value) || 0,
        tuse:           document.getElementById('txt_tuse').value || '',
        cekme:          document.getElementById('txt_cekme').value || '',
        rows:           JSON.stringify(rows)
    };

    var btn = document.getElementById('saveBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url:      '/order/form/save_order.cfm',
        method:   'POST',
        data:     data,
        dataType: 'json',
        success: function(res) {
            if (res.success) {
                window.location.href = 'index.cfm?fuseaction=ship.list_partiler&ship_id=#getShip.ship_id#';
            } else {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-save me-2"></i>Sipariş Olarak Kaydet';
                alert('Hata: ' + (res.message || 'Bilinmeyen hata'));
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>Sipariş Olarak Kaydet';
            alert('Sunucu hatası! Lütfen tekrar deneyin.');
        }
    });
}
</script>
</cfoutput>
