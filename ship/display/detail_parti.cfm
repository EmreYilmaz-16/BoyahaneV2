<cfprocessingdirective pageEncoding="utf-8">
<cfset orderId = isDefined("url.order_id") AND isNumeric(url.order_id) ? val(url.order_id) : 0>

<cfif orderId lte 0>
    <div class="alert alert-warning m-3"><i class="fas fa-exclamation-triangle me-2"></i>Lütfen bir parti seçin (order_id gerekli).</div>
    <cfabort>
</cfif>

<!--- Parti (order) bilgisi --->
<cfquery name="getOrder" datasource="boyahane">
    SELECT o.order_id, o.order_number, o.order_head, o.order_detail,
           o.order_date, o.deliverdate, o.order_stage, o.order_status,
           o.ref_no, o.ref_ship_id,
           o.grosstotal, o.discounttotal, o.taxtotal, o.nettotal,
           o.sarim_sekli, o.ambalaj,
           o.record_date, o.company_id,
           COALESCE(c.nickname, c.fullname, '') AS company_name,
           COALESCE(ss.sarim_sekli_adi, '') AS sarim_sekli_adi,
           COALESCE(ab.ambalaj_adi, '')     AS ambalaj_adi
    FROM orders o
    LEFT JOIN company               c  ON o.company_id    = c.company_id
    LEFT JOIN setup_sarim_sekli     ss ON o.sarim_sekli   = ss.sarim_sekli_id
    LEFT JOIN setup_ambalaj         ab ON o.ambalaj        = ab.ambalaj_id
    WHERE o.order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getOrder.recordCount>
    <div class="alert alert-danger m-3">Parti bulunamadı (order_id: #orderId#).</div>
    <cfabort>
</cfif>

<!--- İrsaliye bilgisi (ref_ship_id FK ile bağlı) --->
<cfquery name="getShip" datasource="boyahane">
    SELECT s.ship_id, s.ship_number, s.ship_detail,
           s.hk_metre, s.hk_kg, s.hk_top_adedi,
           COALESCE(c.nickname, c.fullname, '') AS company_name
    FROM ship s
    LEFT JOIN company c ON s.company_id = c.company_id
    WHERE s.ship_id = <cfqueryparam value="#val(getOrder.ref_ship_id)#" cfsqltype="cf_sql_integer">
</cfquery>

<!--- Parti kalemleri --->
<cfquery name="getRows" datasource="boyahane">
    SELECT orw.order_row_id, orw.stock_id,
           orw.product_name, orw.product_name2,
           orw.quantity, orw.unit, orw.price, orw.tax, orw.discount_1, orw.nettotal,
           COALESCE(st.property,     '') AS stock_property,
           COALESCE(st.stock_code,   '') AS stock_code,
           COALESCE(st.stock_code_2, '') AS stock_code_2,
           COALESCE(st.is_main_stock, true) AS is_main_stock,
           COALESCE(st.product_id, 0)       AS product_id
    FROM order_row orw
    LEFT JOIN stocks st ON orw.stock_id = st.stock_id
    WHERE orw.order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
    ORDER BY orw.order_row_id
</cfquery>

<!--- Tekstil bilgileri (ilk ana stok satırından ürün üzerinden) --->
<cfquery name="getTekstil" datasource="boyahane">
    SELECT p.en, p.tuse, p.cekme, p.isi, p.hiz, p.gramaj, p.besleme_avans, p.kumas_tipi
    FROM order_row orw
    JOIN stocks  st ON orw.stock_id  = st.stock_id
    JOIN product  p ON st.product_id = p.product_id
    WHERE orw.order_id = <cfqueryparam value="#orderId#" cfsqltype="cf_sql_integer">
    ORDER BY orw.order_row_id
    LIMIT 1
</cfquery>

<!--- Aşama etiketi --->
<cfset stageLabel = "">
<cfswitch expression="#val(getOrder.order_stage)#">
    <cfcase value="1"><cfset stageLabel = "Beklemede"><cfset stageCls = "bg-secondary"></cfcase>
    <cfcase value="2"><cfset stageLabel = "Onaylandı"><cfset stageCls = "bg-primary"></cfcase>
    <cfcase value="3"><cfset stageLabel = "Üretimde"><cfset stageCls = "bg-warning text-dark"></cfcase>
    <cfcase value="4"><cfset stageLabel = "Hazır"><cfset stageCls = "bg-info text-dark"></cfcase>
    <cfcase value="5"><cfset stageLabel = "Sevk Edildi"><cfset stageCls = "bg-success"></cfcase>
    <cfcase value="6"><cfset stageLabel = "Tamamlandı"><cfset stageCls = "bg-dark"></cfcase>
    <cfdefaultcase><cfset stageLabel = "Bilinmiyor"><cfset stageCls = "bg-secondary"></cfdefaultcase>
</cfswitch>

<!--- JS dizisi --->
<cfset rowsArr = []>
<cfloop query="getRows">
    <cfset arrayAppend(rowsArr, {
        "order_row_id":  order_row_id,
        "stock_id":      isNumeric(stock_id) ? val(stock_id) : 0,
        "product_id":    isNumeric(product_id) ? val(product_id) : 0,
        "product_name":  product_name ?: "",
        "is_main_stock": isBoolean(is_main_stock) ? is_main_stock : true,
        "stock_property":stock_property ?: "",
        "stock_code":    stock_code ?: "",
        "stock_code_2":  stock_code_2 ?: "",
        "quantity":      isNumeric(quantity)  ? val(quantity)  : 0,
        "unit":          unit ?: "",
        "price":         isNumeric(price)     ? val(price)     : 0,
        "tax":           isNumeric(tax)       ? val(tax)       : 0,
        "discount_1":    isNumeric(discount_1)? val(discount_1): 0,
        "nettotal":      isNumeric(nettotal)  ? val(nettotal)  : 0
    })>
</cfloop>

<!--- ================================================ HTML ================================================ --->
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-layer-group"></i></div>
        <div class="page-header-title">
            <cfoutput>
            <h1>Parti Detay <small class="text-muted fs-6">#xmlFormat(getOrder.order_number)#</small></h1>
            <p><strong>#xmlFormat(getOrder.company_name)#</strong><cfif getShip.recordCount> — İrsaliye: #xmlFormat(getShip.ship_number)#</cfif></p>
            </cfoutput>
        </div>
    </div>
    <div class="d-flex gap-2">
        <cfoutput>
        <a href="index.cfm?fuseaction=ship.add_parti&ship_id=#getShip.recordCount ? getShip.ship_id : 0#"
           class="btn btn-sm btn-outline-primary">
            <i class="fas fa-edit me-1"></i>Partiyi Düzenle
        </a>
        <cfif getShip.recordCount>
        <a href="index.cfm?fuseaction=ship.list_partiler&ship_id=#getShip.ship_id#" class="btn-back">
            <i class="fas fa-arrow-left"></i>Parti Listesi
        </a>
        <cfelse>
        <a href="index.cfm?fuseaction=ship.list_giris_fis" class="btn-back">
            <i class="fas fa-arrow-left"></i>Giriş Fişleri
        </a>
        </cfif>
        </cfoutput>
    </div>
</div>

<div class="px-3 pb-5">

    <!--- Özet kartlar --->
    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="summary-card" style="background:linear-gradient(135deg,#1a3a5c,#2563ab);">
                <div class="summary-icon"><i class="fas fa-list-ol"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Kalem Sayısı</span>
                    <span class="summary-value"><cfoutput>#getRows.recordCount#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card" style="background:linear-gradient(135deg,#15803d,#22c55e);">
                <div class="summary-icon"><i class="fas fa-ruler-horizontal"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Miktar</span>
                    <cfset totalQty = 0>
                    <cfloop query="getRows">
                        <cfset totalQty += isNumeric(quantity) ? val(quantity) : 0>
                    </cfloop>
                    <span class="summary-value"><cfoutput>#numberFormat(totalQty,'0.00')#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card" style="background:linear-gradient(135deg,#92400e,#f59e0b);">
                <div class="summary-icon"><i class="fas fa-file-invoice-dollar"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Brüt Tutar</span>
                    <span class="summary-value"><cfoutput>#numberFormat(getOrder.grosstotal,'0.00')#</cfoutput></span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card" style="background:linear-gradient(135deg,#166534,#4ade80);">
                <div class="summary-icon"><i class="fas fa-coins"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Net Tutar</span>
                    <span class="summary-value"><cfoutput>#numberFormat(getOrder.nettotal,'0.00')#</cfoutput></span>
                </div>
            </div>
        </div>
    </div>

    <div class="row g-3 mb-3">

        <!--- Parti bilgileri --->
        <div class="col-md-6">
            <div class="grid-card h-100">
                <div class="grid-card-header">
                    <div class="grid-card-header-title"><i class="fas fa-info-circle"></i>Parti Bilgileri</div>
                    <cfoutput><span class="badge #stageCls#">#stageLabel#</span></cfoutput>
                </div>
                <div class="card-body p-3">
                    <table class="table table-sm table-borderless mb-0">
                        <tbody>
                            <cfoutput>
                            <tr>
                                <td class="text-muted" style="width:40%">Parti Kodu</td>
                                <td><strong>#xmlFormat(getOrder.order_number)#</strong></td>
                            </tr>
                            <cfif len(trim(getOrder.order_head ?: ""))>
                            <tr>
                                <td class="text-muted">Başlık</td>
                                <td>#xmlFormat(getOrder.order_head)#</td>
                            </tr>
                            </cfif>
                            <tr>
                                <td class="text-muted">Firma</td>
                                <td>#xmlFormat(getOrder.company_name)#</td>
                            </tr>
                            <tr>
                                <td class="text-muted">İrsaliye No</td>
                                <td>
                                    <cfif getShip.recordCount>
                                    <a href="index.cfm?fuseaction=ship.list_partiler&ship_id=#getShip.ship_id#"
                                       class="text-decoration-none fw-semibold">
                                        #xmlFormat(getShip.ship_number)#
                                    </a>
                                    <cfelse>
                                    #xmlFormat(getOrder.ref_no)#
                                    </cfif>
                                </td>
                            </tr>
                            <tr>
                                <td class="text-muted">Sipariş Tarihi</td>
                                <td>#isDate(getOrder.order_date) ? dateFormat(getOrder.order_date, 'dd/mm/yyyy') : '-'#</td>
                            </tr>
                            <tr>
                                <td class="text-muted">Teslim Tarihi</td>
                                <td>#isDate(getOrder.deliverdate) ? dateFormat(getOrder.deliverdate, 'dd/mm/yyyy') : '-'#</td>
                            </tr>
                            <cfif len(trim(getOrder.sarim_sekli_adi ?: ""))>
                            <tr>
                                <td class="text-muted">Sarım Şekli</td>
                                <td><span class="badge bg-light text-dark border">#xmlFormat(getOrder.sarim_sekli_adi)#</span></td>
                            </tr>
                            </cfif>
                            <cfif len(trim(getOrder.ambalaj_adi ?: ""))>
                            <tr>
                                <td class="text-muted">Ambalaj</td>
                                <td><span class="badge bg-light text-dark border">#xmlFormat(getOrder.ambalaj_adi)#</span></td>
                            </tr>
                            </cfif>
                            <cfif len(trim(getOrder.order_detail ?: ""))>
                            <tr>
                                <td class="text-muted">Açıklama</td>
                                <td>#xmlFormat(getOrder.order_detail)#</td>
                            </tr>
                            </cfif>
                            <tr>
                                <td class="text-muted">Kayıt Tarihi</td>
                                <td class="text-muted small">#isDate(getOrder.record_date) ? dateFormat(getOrder.record_date,'dd/mm/yyyy') & ' ' & timeFormat(getOrder.record_date,'HH:mm') : '-'#</td>
                            </tr>
                            </cfoutput>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <!--- İrsaliye + Finans --->
        <div class="col-md-6">
            <div class="d-flex flex-column gap-3 h-100">

                <!--- İrsaliye Özet --->
                <cfif getShip.recordCount>
                <div class="grid-card">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-truck"></i>İrsaliye Bilgisi</div>
                    </div>
                    <div class="card-body p-3">
                        <table class="table table-sm table-borderless mb-0">
                            <tbody>
                                <cfoutput>
                                <tr>
                                    <td class="text-muted" style="width:45%">İrsaliye No</td>
                                    <td><strong>#xmlFormat(getShip.ship_number)#</strong></td>
                                </tr>
                                <cfif isNumeric(getShip.hk_metre) AND getShip.hk_metre gt 0>
                                <tr>
                                    <td class="text-muted">İrsaliye Metre</td>
                                    <td>#numberFormat(getShip.hk_metre,'0.00')# mt</td>
                                </tr>
                                </cfif>
                                <cfif isNumeric(getShip.hk_kg) AND getShip.hk_kg gt 0>
                                <tr>
                                    <td class="text-muted">İrsaliye Kg</td>
                                    <td>#numberFormat(getShip.hk_kg,'0.000')# kg</td>
                                </tr>
                                </cfif>
                                <cfif isNumeric(getShip.hk_top_adedi) AND getShip.hk_top_adedi gt 0>
                                <tr>
                                    <td class="text-muted">Top Adedi</td>
                                    <td>#val(getShip.hk_top_adedi)# adet</td>
                                </tr>
                                </cfif>
                                </cfoutput>
                            </tbody>
                        </table>
                    </div>
                </div>
                </cfif>

                <!--- Finans Özet --->
                <div class="grid-card">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title"><i class="fas fa-calculator"></i>Tutar Özeti</div>
                    </div>
                    <div class="card-body p-3">
                        <table class="table table-sm table-borderless mb-0">
                            <tbody>
                                <cfoutput>
                                <tr>
                                    <td class="text-muted" style="width:50%">Brüt Toplam</td>
                                    <td class="text-end">#numberFormat(getOrder.grosstotal,'0.00')#</td>
                                </tr>
                                <cfif isNumeric(getOrder.discounttotal) AND getOrder.discounttotal neq 0>
                                <tr>
                                    <td class="text-muted">İskonto</td>
                                    <td class="text-end text-danger">-#numberFormat(getOrder.discounttotal,'0.00')#</td>
                                </tr>
                                </cfif>
                                <tr>
                                    <td class="text-muted">KDV</td>
                                    <td class="text-end">#numberFormat(getOrder.taxtotal,'0.00')#</td>
                                </tr>
                                <tr class="fw-bold border-top">
                                    <td>Net Toplam</td>
                                    <td class="text-end text-success">#numberFormat(getOrder.nettotal,'0.00')#</td>
                                </tr>
                                </cfoutput>
                            </tbody>
                        </table>
                    </div>
                </div>

            </div>
        </div>
    </div>

    <!--- Tekstil Bilgileri --->
    <cfif getTekstil.recordCount AND (
        (isNumeric(getTekstil.en) AND getTekstil.en gt 0) OR
        len(trim(getTekstil.kumas_tipi ?: "")) OR
        (isNumeric(getTekstil.gramaj) AND getTekstil.gramaj gt 0) OR
        (isNumeric(getTekstil.isi) AND getTekstil.isi gt 0) OR
        len(trim(getTekstil.tuse ?: "")) OR
        len(trim(getTekstil.cekme ?: ""))
    )>
    <cfoutput>
    <div class="grid-card mb-3">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-tshirt"></i>Tekstil / Kumaş Özellikleri</div>
        </div>
        <div class="card-body px-3 py-3">
            <div class="d-flex flex-wrap gap-4">
                <cfif len(trim(getTekstil.kumas_tipi ?: ""))>
                <div class="tekstil-item">
                    <small class="text-muted d-block mb-1"><i class="fas fa-tag me-1"></i>Kumaş Tipi</small>
                    <strong>#xmlFormat(getTekstil.kumas_tipi)#</strong>
                </div>
                </cfif>
                <cfif isNumeric(getTekstil.en) AND getTekstil.en gt 0>
                <div class="tekstil-item">
                    <small class="text-muted d-block mb-1"><i class="fas fa-arrows-alt-h me-1"></i>En</small>
                    <strong>#getTekstil.en# cm</strong>
                </div>
                </cfif>
                <cfif isNumeric(getTekstil.gramaj) AND getTekstil.gramaj gt 0>
                <div class="tekstil-item">
                    <small class="text-muted d-block mb-1"><i class="fas fa-weight me-1"></i>Gramaj</small>
                    <strong>#getTekstil.gramaj# g/m²</strong>
                </div>
                </cfif>
                <cfif isNumeric(getTekstil.isi) AND getTekstil.isi gt 0>
                <div class="tekstil-item">
                    <small class="text-muted d-block mb-1"><i class="fas fa-thermometer-half me-1"></i>Isı</small>
                    <strong>#getTekstil.isi# °C</strong>
                </div>
                </cfif>
                <cfif isNumeric(getTekstil.hiz) AND getTekstil.hiz gt 0>
                <div class="tekstil-item">
                    <small class="text-muted d-block mb-1"><i class="fas fa-tachometer-alt me-1"></i>Hız</small>
                    <strong>#getTekstil.hiz# m/dak</strong>
                </div>
                </cfif>
                <cfif isNumeric(getTekstil.besleme_avans) AND getTekstil.besleme_avans gt 0>
                <div class="tekstil-item">
                    <small class="text-muted d-block mb-1"><i class="fas fa-sliders-h me-1"></i>Besleme Avans</small>
                    <strong>#getTekstil.besleme_avans#</strong>
                </div>
                </cfif>
                <cfif len(trim(getTekstil.tuse ?: ""))>
                <div class="tekstil-item">
                    <small class="text-muted d-block mb-1"><i class="fas fa-hand-paper me-1"></i>Tuşe</small>
                    <strong>#xmlFormat(getTekstil.tuse)#</strong>
                </div>
                </cfif>
                <cfif len(trim(getTekstil.cekme ?: ""))>
                <div class="tekstil-item">
                    <small class="text-muted d-block mb-1"><i class="fas fa-compress-arrows-alt me-1"></i>Çekme</small>
                    <strong>#xmlFormat(getTekstil.cekme)#</strong>
                </div>
                </cfif>
            </div>
        </div>
    </div>
    </cfoutput>
    </cfif>

    <!--- Parti Kalemleri --->
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-th-list"></i>Parti Kalemleri</div>
            <span class="record-count"><cfoutput>#getRows.recordCount#</cfoutput> kalem</span>
        </div>
        <div class="card-body p-2">
            <div id="rowGrid"></div>
        </div>
    </div>

</div>

<cfoutput>
<style>
.summary-card  { display:flex; align-items:center; gap:14px; padding:16px 20px; border-radius:10px; color:##fff; box-shadow:0 2px 10px rgba(0,0,0,.12); }
.summary-icon  { font-size:1.8rem; opacity:.85; }
.summary-label { font-size:.75rem; opacity:.85; display:block; }
.summary-value { font-size:1.6rem; font-weight:700; display:block; }
.tekstil-item  { min-width:120px; padding:8px 14px; background:##f8fafc; border:1px solid ##e2e8f0; border-radius:8px; }
</style>

<script>
var rowsData = #serializeJSON(rowsArr)#;

var paletteBg = ['##6366f1','##2563ab','##15803d','##b45309','##be123c','##0e7490','##7c3aed','##c2410c','##166534','##1e40af'];
function getBg(i) { return paletteBg[i % paletteBg.length]; }

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $('##rowGrid').dxDataGrid({
            dataSource: rowsData,
            showBorders: true,
            showRowLines: true,
            showColumnLines: true,
            rowAlternationEnabled: true,
            columnAutoWidth: true,
            allowColumnResizing: true,
            columnResizingMode: 'widget',
            paging: { pageSize: 100 },
            filterRow: { visible: true },
            sorting: { mode: 'multiple' },
            export: { enabled: true, fileName: 'parti_kalemleri_#orderId#' },
            columns: [
                {
                    dataField: 'product_name',
                    caption: 'Ürün / İşlem',
                    minWidth: 220,
                    cellTemplate: function(container, options) {
                        var d        = options.data;
                        var isMain   = d.IS_MAIN_STOCK !== undefined ? d.IS_MAIN_STOCK : d.is_main_stock;
                        var propVal  = d.STOCK_PROPERTY || d.stock_property || '';
                        var name     = options.value || '-';
                        var wrap     = $('<div>').addClass('d-flex align-items-center gap-2');

                        $('<span>').text(name).appendTo(wrap);

                        if ((isMain === false || isMain === 'false' || isMain === 0) && propVal) {
                            var allProps = rowsData
                                .filter(function(r) {
                                    return (r.PRODUCT_ID||r.product_id) === (d.PRODUCT_ID||d.product_id)
                                        && !(r.IS_MAIN_STOCK !== undefined ? r.IS_MAIN_STOCK : r.is_main_stock);
                                });
                            var idx = allProps.findIndex(function(r) {
                                return (r.ORDER_ROW_ID||r.order_row_id) === (d.ORDER_ROW_ID||d.order_row_id);
                            });
                            var bg = getBg(idx >= 0 ? idx : 0);
                            $('<span>')
                                .css({ background: bg, color:'##fff', borderRadius:'12px', padding:'2px 8px', fontSize:'.78rem', fontWeight:600 })
                                .html('<i class="fas fa-circle me-1" style="font-size:.55rem"></i>' + $('<span>').text(propVal).html())
                                .appendTo(wrap);
                        }
                        wrap.appendTo(container);
                    }
                },
                { dataField: 'quantity',   caption: 'Miktar',  width: 110, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'unit',       caption: 'Birim',   width:  70 },
                { dataField: 'price',      caption: 'Fiyat',   width: 110, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 4 } },
                { dataField: 'tax',        caption: 'KDV %',   width:  80, alignment: 'right', dataType: 'number' },
                { dataField: 'discount_1', caption: 'İskonto', width:  90, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 2 } },
                { dataField: 'nettotal',   caption: 'Net',     width: 120, alignment: 'right', dataType: 'number', format: { type: 'fixedPoint', precision: 2 } }
            ],
            summary: {
                totalItems: [
                    { column: 'quantity', summaryType: 'sum', displayFormat: 'Top.: {0}', valueFormat: { type: 'fixedPoint', precision: 4 } },
                    { column: 'nettotal', summaryType: 'sum', displayFormat: 'Top.: {0}', valueFormat: { type: 'fixedPoint', precision: 2 } }
                ]
            }
        });
    }
});
</script>
</cfoutput>
