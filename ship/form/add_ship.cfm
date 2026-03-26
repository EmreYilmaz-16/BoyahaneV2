<cfprocessingdirective pageEncoding="utf-8">

<!--- Edit mode --->
<cfset editMode   = isDefined("url.ship_id") AND isNumeric(url.ship_id) AND url.ship_id gt 0>
<cfset currentShipId = editMode ? val(url.ship_id) : 0>

<cfif editMode>
    <cfquery name="getShip" datasource="boyahane">
        SELECT s.*,
               COALESCE(c.nickname, c.fullname, '') AS company_name
        FROM ship s
        LEFT JOIN company c ON s.company_id = c.company_id
        WHERE s.ship_id = <cfqueryparam value="#currentShipId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getShip.recordCount>
        <cfset editMode = false>
        <cfset currentShipId = 0>
    </cfif>
    <cfquery name="getShipRows" datasource="boyahane">
        SELECT sr.*, p.product_code
        FROM ship_row sr
        LEFT JOIN product p ON sr.product_id = p.product_id
        WHERE sr.ship_id = <cfqueryparam value="#currentShipId#" cfsqltype="cf_sql_integer">
        ORDER BY sr.ship_row_id
    </cfquery>
</cfif>

<!--- Ödeme yöntemleri --->
<cfquery name="getPaymethods" datasource="boyahane">
    SELECT paymethod_id, paymethod FROM setup_paymethod ORDER BY paymethod
</cfquery>

<!--- Sevkiyat yöntemleri --->
<cfquery name="getShipMethods" datasource="boyahane">
    SELECT ship_method_id, ship_method FROM ship_method ORDER BY ship_method
</cfquery>

<!--- Stoklar (sepet arama için) --->
<cfquery name="getStocks" datasource="boyahane">
    SELECT s.stock_id, s.stock_code, s.barcod,
           s.property, s.product_unit_id,
           p.product_id, p.product_name, p.product_code
    FROM stocks s
    LEFT JOIN product p ON s.product_id = p.product_id
    WHERE s.stock_status = true
    ORDER BY p.product_name, s.stock_code
</cfquery>

<cfset stocksArray = []>
<cfloop query="getStocks">
    <cfset arrayAppend(stocksArray, {
        "stock_id"        = stock_id,
        "stock_code"      = stock_code ?: "",
        "barcod"          = barcod ?: "",
        "property"        = property ?: "",
        "product_id"      = product_id ?: 0,
        "product_unit_id" = product_unit_id ?: 0,
        "product_name"    = product_name ?: "",
        "product_code"    = product_code ?: "",
        "label"           = (product_name ?: "?") & " — " & (stock_code ?: "")
    })>
</cfloop>

<!--- Düzenleme modunda mevcut satırlar --->
<cfset rowsArray = []>
<cfif editMode AND isDefined("getShipRows") AND getShipRows.recordCount>
    <cfloop query="getShipRows">
        <cfset arrayAppend(rowsArray, {
            "ship_row_id":   ship_row_id,
            "stock_id":      0,
            "product_id":    product_id ?: 0,
            "name_product":  name_product ?: "",
            "product_code":  product_code ?: "",
            "price":         isNumeric(price)        ? price        : 0,
            "amount":        isNumeric(amount)       ? amount       : 0,
            "unit":          unit ?: "",
            "unit_id":       unit_id ?: 0,
            "tax":           isNumeric(tax)          ? tax          : 0,
            "discount":      isNumeric(discount)     ? discount     : 0,
            "discounttotal": isNumeric(discounttotal) ? discounttotal : 0,
            "grosstotal":    isNumeric(grosstotal)   ? grosstotal   : 0,
            "nettotal":      isNumeric(nettotal)     ? nettotal     : 0,
            "taxtotal":      isNumeric(taxtotal)     ? taxtotal     : 0,
            "lot_no":        lot_no ?: "",
            "giris_raf_id":  isNumeric(shelf_number) ? val(shelf_number) : 0,
            "giris_raf_code":"",
            "cikis_raf_id":  0,
            "cikis_raf_code":""
        })>
    </cfloop>
</cfif>

<!--- Depo lokasyonları --->
<cfquery name="getLocations" datasource="boyahane">
    SELECT sl.id, sl.department_id, sl.department_location,
           d.department_head
    FROM stocks_location sl
    JOIN department d ON sl.department_id = d.department_id
    WHERE sl.status = true
    ORDER BY d.department_head, sl.department_location
</cfquery>
<cfset locationsArray = []>
<cfloop query="getLocations">
    <cfset arrayAppend(locationsArray, {
        "id"                  = id,
        "department_id"       = department_id,
        "department_head"     = department_head ?: "",
        "department_location" = department_location ?: "",
        "label"               = (department_head ?: "") & " — " & (department_location ?: "")
    })>
</cfloop>

<!--- Seçili değerler --->
<cfset selPurchaseSales = editMode AND isDefined("getShip") AND getShip.recordCount ? getShip.purchase_sales : true>
<cfset selShipType      = editMode AND isDefined("getShip") AND getShip.recordCount ? val(getShip.ship_type ?: 1) : 1>
<cfset selPaymethod     = editMode AND isDefined("getShip") AND getShip.recordCount ? val(getShip.paymethod_id ?: 0) : 0>
<cfset selShipMethod    = editMode AND isDefined("getShip") AND getShip.recordCount ? val(getShip.ship_method ?: 0) : 0>
<cfset selShipStatus    = editMode AND isDefined("getShip") AND getShip.recordCount ? val(getShip.ship_status ?: 1) : 1>
<cfset selGirisDepo = editMode AND isDefined("getShip") AND getShip.recordCount ? val(getShip.location_in ?: 0) : 0>
<cfset selCikisDepo = editMode AND isDefined("getShip") AND getShip.recordCount ? val(getShip.deliver_store_id ?: 0) : 0>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-file-invoice"></i></div>
        <div class="page-header-title">
            <cfif editMode>
                <cfoutput><h1>İrsaliye Düzenle <small class="text-muted fs-6">###currentShipId#</small></h1></cfoutput>
                <p>İrsaliye bilgilerini ve kalemlerini düzenleyin</p>
            <cfelse>
                <h1>Yeni İrsaliye</h1>
                <p>Fiş bilgilerini doldurun, ürünleri sepete ekleyin</p>
            </cfif>
        </div>
    </div>
    <a href="index.cfm?fuseaction=ship.list_ship" class="btn-back">
        <i class="fas fa-arrow-left"></i>İrsaliye Listesi
    </a>
</div>

<div class="px-3 pb-5">
    <form id="shipForm">
        <input type="hidden" id="ship_id" name="ship_id" value="<cfoutput>#currentShipId#</cfoutput>">

        <div class="row g-3">

            <!--- ══════════════════════════════════════ --->
            <!--- SOL: FİŞ BİLGİLERİ                  --->
            <!--- ══════════════════════════════════════ --->
            <div class="col-lg-5">
                <div class="grid-card sticky-top-card">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-receipt"></i>Fiş Bilgileri
                        </div>
                        <span class="badge bg-primary" id="shipStatusBadge">
                            <cfif editMode>Düzenleniyor<cfelse>Yeni</cfif>
                        </span>
                    </div>
                    <div class="card-body p-3">

                        <!--- Alış / Satış --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fas fa-exchange-alt me-1 text-primary"></i>İşlem Türü</label>
                            <div class="btn-group w-100" role="group">
                                <input type="radio" class="btn-check" name="purchase_sales" id="ps_satis" value="true"  <cfif selPurchaseSales>checked</cfif>>
                                <label class="btn btn-outline-success btn-sm" for="ps_satis"><i class="fas fa-arrow-up me-1"></i>Satış</label>
                                <input type="radio" class="btn-check" name="purchase_sales" id="ps_alis"  value="false" <cfif NOT selPurchaseSales>checked</cfif>>
                                <label class="btn btn-outline-warning btn-sm" for="ps_alis"><i class="fas fa-arrow-down me-1"></i>Alış</label>
                            </div>
                        </div>

                        <!--- İrsaliye Tipi --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fas fa-tag me-1 text-primary"></i>İrsaliye Tipi</label>
                            <div class="btn-group w-100 flex-wrap gap-1" role="group" id="shipTypeGroup">
                                <input type="radio" class="btn-check" name="ship_type" id="st1" value="1" <cfif selShipType eq 1>checked</cfif>>
                                <label class="btn btn-outline-success btn-sm" for="st1">Satış İrs.</label>
                                <input type="radio" class="btn-check" name="ship_type" id="st2" value="2" <cfif selShipType eq 2>checked</cfif>>
                                <label class="btn btn-outline-primary btn-sm" for="st2">Alış İrs.</label>
                                <input type="radio" class="btn-check" name="ship_type" id="st5" value="5" <cfif selShipType eq 5>checked</cfif>>
                                <label class="btn btn-outline-info btn-sm" for="st5">Ham Kumaş Alış</label>
                                <input type="radio" class="btn-check" name="ship_type" id="st3" value="3" <cfif selShipType eq 3>checked</cfif>>
                                <label class="btn btn-outline-danger btn-sm" for="st3">İade</label>
                            </div>
                        </div>

                        <!--- İrsaliye No --->
                        <div class="mb-3">
                            <label for="ship_number" class="form-label fw-semibold"><i class="fas fa-hashtag me-1 text-primary"></i>İrsaliye No</label>
                            <input type="text" class="form-control" id="ship_number" name="ship_number"
                                   placeholder="Otomatik veya elle girin"
                                   value="<cfoutput><cfif editMode AND getShip.recordCount>#xmlFormat(getShip.ship_number)#</cfif></cfoutput>">
                        </div>

                        <!--- Seri No --->
                        <div class="mb-3">
                            <label for="serial_number" class="form-label fw-semibold"><i class="fas fa-barcode me-1 text-primary"></i>Seri No</label>
                            <input type="text" class="form-control" id="serial_number" name="serial_number"
                                   placeholder="Seri numarası"
                                   value="<cfoutput><cfif editMode AND getShip.recordCount>#xmlFormat(getShip.serial_number)#</cfif></cfoutput>">
                        </div>

                        <!--- İrsaliye Tarihi --->
                        <div class="mb-3">
                            <label for="ship_date" class="form-label fw-semibold"><i class="fas fa-calendar-alt me-1 text-primary"></i>İrsaliye Tarihi</label>
                            <input type="datetime-local" class="form-control" id="ship_date" name="ship_date"
                                   value="<cfoutput><cfif editMode AND getShip.recordCount AND isDate(getShip.ship_date)>#dateFormat(getShip.ship_date,'yyyy-mm-dd')#T#timeFormat(getShip.ship_date,'HH:mm')#<cfelse>#dateFormat(now(),'yyyy-mm-dd')#T#timeFormat(now(),'HH:mm')#</cfif></cfoutput>">
                        </div>

                        <!--- Sevk Tarihi --->
                        <div class="mb-3">
                            <label for="deliver_date" class="form-label fw-semibold"><i class="fas fa-truck me-1 text-primary"></i>Sevk Tarihi</label>
                            <input type="date" class="form-control" id="deliver_date" name="deliver_date"
                                   value="<cfoutput><cfif editMode AND getShip.recordCount AND isDate(getShip.deliver_date)>#dateFormat(getShip.deliver_date,'yyyy-mm-dd')#</cfif></cfoutput>">
                        </div>

                        <!--- Firma Arama --->
                        <div class="mb-3" style="position:relative">
                            <label class="form-label fw-semibold"><i class="fas fa-building me-1 text-primary"></i>Firma</label>
                            <input type="text" class="form-control" id="companySearch"
                                   placeholder="Firma adı ile arayın..."
                                   autocomplete="off"
                                   value="<cfoutput><cfif editMode AND getShip.recordCount>#xmlFormat(getShip.company_name)#</cfif></cfoutput>">
                            <input type="hidden" id="company_id"
                                   value="<cfoutput><cfif editMode AND getShip.recordCount>#getShip.company_id#</cfif></cfoutput>">
                            <div id="companyDropdown" class="search-dropdown d-none"></div>
                        </div>

                        <!--- Ödeme Yöntemi --->
                        <div class="mb-3">
                            <label for="paymethod_id" class="form-label fw-semibold"><i class="fas fa-credit-card me-1 text-primary"></i>Ödeme Yöntemi</label>
                            <select class="form-select" id="paymethod_id" name="paymethod_id">
                                <option value="0">-- Seçin --</option>
                                <cfloop query="getPaymethods">
                                    <option value="<cfoutput>#paymethod_id#</cfoutput>" <cfif selPaymethod eq paymethod_id>selected</cfif>>
                                        <cfoutput>#paymethod#</cfoutput>
                                    </option>
                                </cfloop>
                            </select>
                        </div>

                        <!--- Sevkiyat Yöntemi --->
                        <div class="mb-3">
                            <label for="ship_method_sel" class="form-label fw-semibold"><i class="fas fa-shipping-fast me-1 text-primary"></i>Sevkiyat Yöntemi</label>
                            <select class="form-select" id="ship_method_sel" name="ship_method">
                                <option value="0">-- Seçin --</option>
                                <cfloop query="getShipMethods">
                                    <option value="<cfoutput>#ship_method_id#</cfoutput>" <cfif selShipMethod eq ship_method_id>selected</cfif>>
                                        <cfoutput>#ship_method#</cfoutput>
                                    </option>
                                </cfloop>
                            </select>
                        </div>

                        <!--- Referans No --->
                        <div class="mb-3">
                            <label for="ref_no" class="form-label fw-semibold"><i class="fas fa-link me-1 text-primary"></i>Referans No</label>
                            <input type="text" class="form-control" id="ref_no" name="ref_no"
                                   placeholder="Sipariş/fatura no vb."
                                   value="<cfoutput><cfif editMode AND getShip.recordCount>#xmlFormat(getShip.ref_no)#</cfif></cfoutput>">
                        </div>

                        <!--- Açıklama --->
                        <div class="mb-3">
                            <label for="ship_detail" class="form-label fw-semibold"><i class="fas fa-sticky-note me-1 text-primary"></i>Açıklama</label>
                            <textarea class="form-control" id="ship_detail" name="ship_detail" rows="2"
                                      placeholder="İrsaliye açıklaması..."><cfoutput><cfif editMode AND getShip.recordCount>#xmlFormat(getShip.ship_detail)#</cfif></cfoutput></textarea>
                        </div>

                        <!--- Depo --->
                        <div class="mb-3" id="depoSection">
                            <label class="form-label fw-semibold"><i class="fas fa-warehouse me-1 text-primary"></i>Depo <span class="text-danger">*</span></label>
                            <div id="girisDepoWrap" class="mb-2">
                                <div class="text-muted small mb-1">Giriş Depo</div>
                                <select class="form-select form-select-sm" id="girisDepoId">
                                    <option value="0">-- Depo Seçin --</option>
                                </select>
                            </div>
                            <div id="cikisDepoWrap" class="mb-2">
                                <div class="text-muted small mb-1">Çıkış Depo</div>
                                <select class="form-select form-select-sm" id="cikisDepoId">
                                    <option value="0">-- Depo Seçin --</option>
                                </select>
                            </div>
                        </div>

                        <!--- Durum --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fas fa-toggle-on me-1 text-primary"></i>Durum</label>
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="ship_status" name="ship_status" value="1"
                                       <cfif selShipStatus eq 1>checked</cfif>>
                                <label class="form-check-label" for="ship_status">Aktif</label>
                            </div>
                        </div>

                        <!--- Toplamlar --->
                        <div class="totals-box mt-3">
                            <div class="totals-row">
                                <span>Brüt Toplam</span>
                                <strong id="totalGross">0,00</strong>
                            </div>
                            <div class="totals-row text-danger">
                                <span>İskonto</span>
                                <strong id="totalDiscount">0,00</strong>
                            </div>
                            <div class="totals-row">
                                <span>Net Tutar</span>
                                <strong id="totalNet">0,00</strong>
                            </div>
                            <div class="totals-row text-warning">
                                <span>KDV</span>
                                <strong id="totalTax">0,00</strong>
                            </div>
                            <div class="totals-row totals-grand">
                                <span>GENEL TOPLAM</span>
                                <strong id="totalGrand">0,00</strong>
                            </div>
                        </div>

                        <!--- Kaydet / Sil --->
                        <div class="d-grid gap-2 mt-4">
                            <button type="button" class="btn btn-primary btn-lg" onclick="saveShip()">
                                <i class="fas fa-save me-2"></i>
                                <span id="saveBtnLabel"><cfif editMode>Güncelle<cfelse>Kaydet</cfif></span>
                            </button>
                            <cfif editMode>
                            <button type="button" class="btn btn-outline-danger" onclick="deleteShipForm()">
                                <i class="fas fa-trash me-2"></i>Sil
                            </button>
                            </cfif>
                        </div>

                    </div>
                </div>
            </div>

            <!--- ══════════════════════════════════════ --->
            <!--- SAĞ: SEPET                           --->
            <!--- ══════════════════════════════════════ --->
            <div class="col-lg-7">
                <div class="grid-card">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-shopping-basket"></i>Sepet
                            <span class="badge bg-warning text-dark ms-2" id="sepetCount">0</span>
                        </div>
                        <button type="button" class="btn btn-sm btn-success" onclick="showAddItemModal()">
                            <i class="fas fa-plus me-1"></i>Ürün Ekle
                        </button>
                    </div>

                    <!--- Hızlı arama --->
                    <div class="px-3 pt-3 pb-2" style="position:relative">
                        <div class="input-group">
                            <span class="input-group-text bg-white"><i class="fas fa-barcode text-primary"></i></span>
                            <input type="text" class="form-control" id="quickSearch"
                                   placeholder="Ürün adı veya kodu ile arayın..."
                                   autocomplete="off">
                            <button class="btn btn-outline-primary" type="button" onclick="quickAdd()">
                                <i class="fas fa-plus"></i>
                            </button>
                        </div>
                        <div id="quickSearchDropdown" class="search-dropdown d-none"></div>
                    </div>

                    <!--- Sepet tablosu --->
                    <div class="card-body p-2">
                        <div class="table-responsive">
                            <table class="table table-hover table-sm align-middle mb-0">
                                <thead class="table-dark">
                                    <tr>
                                        <th style="width:36px">#</th>
                                        <th>Ürün</th>
                                        <th style="width:90px" class="text-end">Fiyat</th>
                                        <th style="width:75px" class="text-center">Miktar</th>
                                        <th style="width:55px" class="text-center">Birim</th>
                                        <th style="width:55px" class="text-center">KDV%</th>
                                        <th style="width:55px" class="text-center">İsk%</th>
                                        <th style="width:65px" class="text-center">Raf</th>
                                        <th style="width:95px" class="text-end">Net Tutar</th>
                                        <th style="width:50px"></th>
                                    </tr>
                                </thead>
                                <tbody id="sepetBody">
                                    <tr id="emptyRow">
                                        <td colspan="10" class="text-center text-muted py-5">
                                            <i class="fas fa-shopping-basket fa-3x mb-3 d-block opacity-25"></i>
                                            Sepet boş. Yukarıdan ürün ekleyin.
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <!--- Sepet özeti --->
                        <div id="sepetSummary" class="sepet-summary mt-2 d-none">
                            <div class="row g-2 justify-content-end px-2">
                                <div class="col-md-4">
                                    <div class="summary-box">
                                        <span>Toplam Kalem</span>
                                        <strong id="summaryKalem">0</strong>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="summary-box">
                                        <span>Toplam Miktar</span>
                                        <strong id="summaryMiktar">0</strong>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="summary-box summary-box-primary">
                                        <span>Genel Toplam</span>
                                        <strong id="summaryGrand">₺0,00</strong>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

        </div><!--- /row --->
    </form>
</div>

<!--- MODAL: Ürün Ekle / Düzenle --->
<div class="modal fade" id="addItemModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-success text-white">
                <h5 class="modal-title" id="addItemModalTitle">
                    <i class="fas fa-plus-circle me-2"></i><span id="modalTitleText">Ürün Ekle</span>
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <!--- Stok arama --->
                <div class="mb-3" style="position:relative">
                    <label class="form-label fw-semibold">Stok Seçin <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" id="modalStockSearch"
                           placeholder="Ürün adı, stok kodu veya barkod ile arayın..." autocomplete="off">
                    <div id="modalSearchResults" class="search-dropdown d-none"></div>
                    <input type="hidden" id="selectedStockId">
                    <div id="selectedStockInfo" class="mt-1 d-none">
                        <div class="alert alert-info py-2 mb-0">
                            <i class="fas fa-check-circle me-1"></i>
                            <span id="selectedStockLabel"></span>
                        </div>
                    </div>
                </div>

                <div class="row g-3">
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Birim Fiyat <span class="text-danger">*</span></label>
                        <input type="number" class="form-control" id="modalPrice"
                               value="0" min="0" step="0.01" placeholder="0.00">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Miktar <span class="text-danger">*</span></label>
                        <input type="number" class="form-control" id="modalAmount"
                               value="1" min="0.001" step="0.001" placeholder="0.000">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">Birim</label>
                        <select class="form-select" id="modalUnit">
                            <option value="">-- Birim Seçin --</option>
                        </select>
                        <input type="hidden" id="modalUnitId" value="0">
                    </div>
                    <div class="col-md-3">
                        <label class="form-label fw-semibold">KDV %</label>
                        <select class="form-select" id="modalTax">
                            <option value="0">%0</option>
                            <option value="1">%1</option>
                            <option value="8">%8</option>
                            <option value="10" selected>%10</option>
                            <option value="18">%18</option>
                            <option value="20">%20</option>
                        </select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">İskonto %</label>
                        <input type="number" class="form-control" id="modalDiscount"
                               value="0" min="0" max="100" step="0.01" placeholder="0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Lot No</label>
                        <input type="text" class="form-control" id="modalLotNo" placeholder="Lot / parti no">
                    </div>
                    <div id="girisRafWrap" class="col-md-4">
                        <label class="form-label fw-semibold" id="girisRafLabel">Giriş Raf</label>
                        <select class="form-select" id="modalGirisRaf">
                            <option value="0">-- Raf Seçin --</option>
                        </select>
                        <input type="hidden" id="modalGirisRafId" value="0">
                    </div>
                    <div id="cikisRafWrap" class="col-md-4" style="display:none">
                        <label class="form-label fw-semibold">Çıkış Raf</label>
                        <select class="form-select" id="modalCikisRaf">
                            <option value="0">-- Raf Seçin --</option>
                        </select>
                        <input type="hidden" id="modalCikisRafId" value="0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Tutar (Hesaplanan)</label>
                        <input type="text" class="form-control" id="modalCalcNet" readonly
                               placeholder="0.00" style="background:#f8f9fa">
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-success" id="modalSaveBtn" onclick="addOrUpdateBasketItem()">
                    <i class="fas fa-cart-plus me-1"></i>Sepete Ekle
                </button>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<style>
/* ── Ürün arama dropdown ── */
.search-dropdown {
    position: absolute; z-index: 1060;
    background: ##fff; border: 1px solid ##dee2e6;
    border-radius: 8px; max-height: 220px; overflow-y: auto;
    box-shadow: 0 4px 16px rgba(0,0,0,.15); width: 100%; left: 0; top: 100%;
}
.search-dropdown .search-item {
    padding: 8px 14px; cursor: pointer; border-bottom: 1px solid ##f0f0f0; font-size:.875rem;
}
.search-dropdown .search-item:hover { background:##f0f6ff; }
.search-dropdown .search-item .item-code { color:##6c757d; font-size:.8rem; }
/* ── Toplamlar kutusu ── */
.totals-box { background:##f8f9fa; border-radius:10px; padding:12px 16px; border:1px solid ##e9ecef; }
.totals-row { display:flex; justify-content:space-between; padding:4px 0; border-bottom:1px solid ##e9ecef; font-size:.875rem; }
.totals-row:last-child { border-bottom:none; }
.totals-grand { font-size:1rem; font-weight:700; color:##1a3a5c; padding-top:8px; border-top:2px solid ##1a3a5c; }
/* ── Sepet __ */
.sepet-summary { border-top:1px solid ##e9ecef; padding-top:12px; }
.summary-box { display:flex; justify-content:space-between; align-items:center; background:##f8f9fa; border-radius:8px; padding:10px 14px; border:1px solid ##e9ecef; }
.summary-box span { color:##6c757d; font-size:.8rem; }
.summary-box-primary { background:linear-gradient(135deg,##1a3a5c,##2563ab); color:##fff; border-color:##1a3a5c; }
.summary-box-primary span, .summary-box-primary strong { color:##fff; }
@media(min-width:992px){ .sticky-top-card { position:sticky; top:70px; } }
</style>

<script>
var allStocks    = #serializeJSON(stocksArray)#;
var allLocations = #serializeJSON(locationsArray)#;
var basketItems  = #serializeJSON(rowsArray)#;
var editShipId   = #currentShipId#;
var editingIdx   = -1;
var editGirisDepo = #val(selGirisDepo)#;
var editCikisDepo = #val(selCikisDepo)#;

/* ─── Firma arama ─── */
var allCompanies  = [];
var companyLoaded = false;

function loadCompanies() {
    if (companyLoaded) return;
    $.ajax({
        url: '/company/cfc/company.cfc?method=getCompaniesForDropdown',
        method: 'GET', dataType: 'json',
        success: function(data) {
            allCompanies  = Array.isArray(data) ? data : [];
            companyLoaded = true;
        }
    });
}

/* ─── Hızlı ürün arama (sepet üstü) ─── */
function quickAdd() {
    var term = document.getElementById('quickSearch').value.trim();
    document.getElementById('quickSearchDropdown').classList.add('d-none');
    if (!term) return;
    term = term.toLowerCase();
    var found = allStocks.find(function(s){
        return s.barcod && s.barcod.toLowerCase() === term;
    }) || allStocks.find(function(s){
        return s.stock_code && s.stock_code.toLowerCase() === term;
    });
    if (found) {
        document.getElementById('quickSearch').value = '';
        openAddModalFor(found);
    } else {
        document.getElementById('quickSearch').dispatchEvent(new Event('input'));
    }
}

/* ─── İrsaliye tipi yardımcısı ─── */
function getShipType() {
    var checked = document.querySelector('input[name="ship_type"]:checked');
    return checked ? parseInt(checked.value) : 1;
}

/* ─── İşlem türü + İrsaliye tipi → hareket yönü ─── */
function getDepoDirection() {
    var type    = getShipType();
    var psSel   = document.querySelector('input[name="purchase_sales"]:checked');
    var isSatis = psSel ? psSel.value === 'true' : true;
    var showGiris, showCikis;
    if (type === 3) {             // İade: yön tersine döner
        showGiris = isSatis;      // Satış İadesi → giriş (stok geri gelir)
        showCikis = !isSatis;     // Alış İadesi  → çıkış (stok geri gönderilir)
    } else if (type === 1) {      // Satış → sadece çıkış depo
        showGiris = false; showCikis = true;
    } else {                      // Alış (2, 5) ve diğerleri → sadece giriş depo
        showGiris = true;  showCikis = false;
    }
    return { showGiris: showGiris, showCikis: showCikis };
}

/* ─── İşlem türüne göre irsaliye tipini filtrele ─── */
function updateShipTypeVisibility() {
    var psSel   = document.querySelector('input[name="purchase_sales"]:checked');
    var isSatis = psSel ? psSel.value === 'true' : true;
    var st1 = document.getElementById('st1'), lbl1 = st1.nextElementSibling;
    var st2 = document.getElementById('st2'), lbl2 = st2.nextElementSibling;
    var st5 = document.getElementById('st5'), lbl5 = st5.nextElementSibling;
    if (isSatis) {
        st1.style.display = ''; lbl1.style.display = '';
        st2.style.display = 'none'; lbl2.style.display = 'none';
        st5.style.display = 'none'; lbl5.style.display = 'none';
        if (getShipType() === 2 || getShipType() === 5) { st1.checked = true; }
    } else {
        st2.style.display = ''; lbl2.style.display = '';
        st5.style.display = ''; lbl5.style.display = '';
        st1.style.display = 'none'; lbl1.style.display = 'none';
        if (getShipType() === 1) { st2.checked = true; }
    }
    updateDepoUI();
}

/* ─── Depo UI: hareket yönüne göre giriş/çıkış göster/gizle ─── */
function updateDepoUI() {
    var dir = getDepoDirection();
    document.getElementById('girisDepoWrap').style.display = dir.showGiris ? '' : 'none';
    document.getElementById('cikisDepoWrap').style.display = dir.showCikis ? '' : 'none';
}

/* ─── Depo seçimi doğrulama ─── */
function validateDepoSelection() {
    var dir = getDepoDirection();
    if (dir.showGiris && !(parseInt(document.getElementById('girisDepoId').value) > 0)) {
        alert('Lütfen önce giriş deponu seçin.');
        document.getElementById('girisDepoId').focus();
        return false;
    }
    if (dir.showCikis && !(parseInt(document.getElementById('cikisDepoId').value) > 0)) {
        alert('Lütfen önce çıkış deponu seçin.');
        document.getElementById('cikisDepoId').focus();
        return false;
    }
    return true;
}

/* ─── Modal raf görünürlüğü ─── */
function updateModalRafVisibility() {
    var dir = getDepoDirection();
    document.getElementById('girisRafWrap').style.display = dir.showGiris ? '' : 'none';
    document.getElementById('cikisRafWrap').style.display = dir.showCikis ? '' : 'none';
}

/* ─── Raf dropdown AJAX ile doldur ─── */
function loadShelvesIntoSelect(selEl, hiddenEl, stockId, locationId) {
    selEl.innerHTML = '<option value="0">Yükleniyor...</option>';
    hiddenEl.value  = '0';
    $.ajax({
        url:      '/department/form/get_shelves_for_product.cfm',
        method:   'GET',
        data:     { stock_id: stockId, location_id: locationId },
        dataType: 'json',
        success:  function(res) {
            selEl.innerHTML = '<option value="0">-- Raf Seçin --</option>';
            if (res.success && res.data && res.data.length) {
                res.data.forEach(function(sh) {
                    var opt = document.createElement('option');
                    opt.value             = sh.product_place_id;
                    opt.textContent       = sh.label || sh.shelf_code;
                    opt.dataset.shelfCode = sh.shelf_code;
                    selEl.appendChild(opt);
                });
                if (res.data.length === 1) {
                    selEl.selectedIndex = 1;
                    hiddenEl.value = res.data[0].product_place_id;
                }
            } else {
                selEl.innerHTML = '<option value="0">-- Raf tanımlı yok --</option>';
            }
        },
        error: function() {
            selEl.innerHTML = '<option value="0">-- Raf yüklenemedi --</option>';
        }
    });
    selEl.onchange = function() { hiddenEl.value = selEl.value || '0'; };
}

/* ─── Stok arama dropdown ─── */
function showDropdown(term, containerId, onSelect) {
    var container = document.getElementById(containerId);
    if (!term || term.length < 2) { container.classList.add('d-none'); return; }
    term = term.toLowerCase();
    var results = allStocks.filter(function(s) {
        return (s.product_name && s.product_name.toLowerCase().includes(term)) ||
               (s.stock_code   && s.stock_code.toLowerCase().includes(term))   ||
               (s.barcod       && s.barcod.toLowerCase().includes(term))        ||
               (s.product_code && s.product_code.toLowerCase().includes(term));
    }).slice(0, 20);
    container.innerHTML = '';
    if (!results.length) {
        container.innerHTML = '<div class="search-item text-muted">Sonuç bulunamadı</div>';
        container.classList.remove('d-none');
        return;
    }
    results.forEach(function(s) {
        var div = document.createElement('div');
        div.className = 'search-item';
        div.innerHTML = '<div>' + escHtml(s.product_name) + '</div>' +
                        '<div class="item-code">' + escHtml(s.stock_code) +
                        (s.barcod ? ' · Barkod: ' + escHtml(s.barcod) : '') + '</div>';
        div.addEventListener('click', function() {
            container.classList.add('d-none');
            onSelect(s);
        });
        container.appendChild(div);
    });
    container.classList.remove('d-none');
}

/* ─── Modal: stok seç, birim ve rafları yükle ─── */
function selectStockInModal(stock) {
    document.getElementById('selectedStockId').value = stock.stock_id;
    document.getElementById('selectedStockLabel').textContent =
        stock.product_name + ' — ' + stock.stock_code +
        (stock.property ? ' (' + stock.property + ')' : '');
    document.getElementById('selectedStockInfo').classList.remove('d-none');
    $('##modalStockSearch').val(stock.product_name);
    $('##modalSearchResults').addClass('d-none');

    // Birimleri AJAX ile yükle
    var sel = document.getElementById('modalUnit');
    sel.innerHTML = '<option value="">Yükleniyor...</option>';
    $.ajax({
        url:      '/product/cfc/product.cfc?method=getUnitsByProduct',
        method:   'GET',
        data:     { product_id: stock.product_id },
        dataType: 'json',
        success: function(res) {
            sel.innerHTML = '<option value="">-- Birim Seçin --</option>';
            if (res.success && res.data && res.data.length) {
                res.data.forEach(function(u) {
                    var label = u.main_unit;
                    if (u.add_unit) label += ' / ' + u.add_unit;
                    var opt = document.createElement('option');
                    opt.value            = u.product_unit_id;
                    opt.textContent      = label;
                    opt.dataset.unitName = u.main_unit;
                    if (u.product_unit_id == stock.product_unit_id || u.is_main) {
                        opt.selected = true;
                        document.getElementById('modalUnitId').value = u.product_unit_id;
                    }
                    sel.appendChild(opt);
                });
            } else {
                sel.innerHTML = '<option value="">Birim tanımlı değil</option>';
            }
        },
        error: function() { sel.innerHTML = '<option value="">Birim yüklenemedi</option>'; }
    });
    sel.onchange = function() {
        var chosen = sel.options[sel.selectedIndex];
        document.getElementById('modalUnitId').value = chosen ? chosen.value : '0';
    };

    // Rafları hareket yönüne göre yükle
    var dir = getDepoDirection();
    if (dir.showGiris) {
        var girisLocId = parseInt(document.getElementById('girisDepoId').value) || 0;
        loadShelvesIntoSelect(
            document.getElementById('modalGirisRaf'),
            document.getElementById('modalGirisRafId'),
            stock.stock_id, girisLocId
        );
    }
    if (dir.showCikis) {
        var cikisLocId = parseInt(document.getElementById('cikisDepoId').value) || 0;
        loadShelvesIntoSelect(
            document.getElementById('modalCikisRaf'),
            document.getElementById('modalCikisRafId'),
            stock.stock_id, cikisLocId
        );
    }
}

/* ─── Modal: sepet üstü hızlı açma ─── */
function openAddModalFor(stock) {
    if (!validateDepoSelection()) return;
    updateModalRafVisibility();
    resetModal();
    selectStockInModal(stock);
    bootstrap.Modal.getOrCreateInstance(document.getElementById('addItemModal')).show();
    setTimeout(function(){ document.getElementById('modalAmount').focus(); }, 400);
}

/* ─── Modal aç / başlat ─── */
function showAddItemModal(prefill) {
    if (!validateDepoSelection()) return;
    updateModalRafVisibility();
    editingIdx = -1;
    resetModal();
    document.getElementById('modalTitleText').textContent = 'Ürün Ekle';
    document.getElementById('modalSaveBtn').innerHTML = '<i class="fas fa-cart-plus me-1"></i>Sepete Ekle';
    bootstrap.Modal.getOrCreateInstance(document.getElementById('addItemModal')).show();
    if (prefill) {
        setTimeout(function(){
            var el = document.getElementById('modalStockSearch');
            el.value = prefill;
            el.dispatchEvent(new Event('input'));
            el.focus();
        }, 300);
    } else {
        setTimeout(function(){ document.getElementById('modalStockSearch').focus(); }, 400);
    }
}

/* ─── Modal sıfırla ─── */
function resetModal() {
    $('##modalStockSearch').val('');
    $('##modalSearchResults').addClass('d-none');
    $('##selectedStockId').val('');
    $('##selectedStockInfo').addClass('d-none');
    $('##modalPrice').val('0');
    $('##modalAmount').val('1');
    $('##modalUnitId').val('0');
    $('##modalTax').val('10');
    $('##modalDiscount').val('0');
    $('##modalLotNo').val('');
    $('##modalCalcNet').val('');
    document.getElementById('modalUnit').innerHTML = '<option value="">-- Birim Seçin --</option>';
    document.getElementById('modalGirisRaf').innerHTML = '<option value="0">-- Raf Seçin --</option>';
    $('##modalGirisRafId').val('0');
    document.getElementById('modalCikisRaf').innerHTML = '<option value="0">-- Raf Seçin --</option>';
    $('##modalCikisRafId').val('0');
}

/* ─── Modal güncelle hesap ─── */
function calcModal() {
    var price    = parseFloat($('##modalPrice').val())    || 0;
    var amount   = parseFloat($('##modalAmount').val())   || 0;
    var discount = parseFloat($('##modalDiscount').val()) || 0;
    var gross    = price * amount;
    var disc     = gross * discount / 100;
    var net      = gross - disc;
    $('##modalCalcNet').val(net.toLocaleString('tr-TR', {minimumFractionDigits:2, maximumFractionDigits:2}));
}

/* ─── Sepete ekle veya güncelle ─── */
function addOrUpdateBasketItem() {
    var stockId = parseInt($('##selectedStockId').val()) || 0;
    if (!stockId) { alert('Lütfen bir stok/ürün seçin.'); return; }

    var stock       = allStocks.find(function(s){ return s.stock_id == stockId; });
    var productName = stock ? stock.product_name : ($('##modalStockSearch').val().trim());

    var price    = parseFloat($('##modalPrice').val())    || 0;
    var amount   = parseFloat($('##modalAmount').val())   || 1;
    var tax      = parseFloat($('##modalTax').val())      || 0;
    var discount = parseFloat($('##modalDiscount').val()) || 0;
    var gross    = price * amount;
    var discTot  = gross * discount / 100;
    var net      = gross - discTot;
    var taxTot   = net * tax / 100;

    var unitSel  = document.getElementById('modalUnit');
    var unitId   = parseInt($('##modalUnitId').val()) || 0;
    var unitName = unitSel && unitSel.selectedIndex > 0
        ? (unitSel.options[unitSel.selectedIndex].dataset.unitName || unitSel.options[unitSel.selectedIndex].textContent)
        : '';

    var girisRafSel  = document.getElementById('modalGirisRaf');
    var girisRafId   = parseInt($('##modalGirisRafId').val()) || 0;
    var girisRafCode = girisRafId > 0 && girisRafSel.selectedIndex > 0
        ? (girisRafSel.options[girisRafSel.selectedIndex].dataset.shelfCode || girisRafSel.options[girisRafSel.selectedIndex].textContent) : '';

    var cikisRafSel  = document.getElementById('modalCikisRaf');
    var cikisRafId   = parseInt($('##modalCikisRafId').val()) || 0;
    var cikisRafCode = cikisRafId > 0 && cikisRafSel.selectedIndex > 0
        ? (cikisRafSel.options[cikisRafSel.selectedIndex].dataset.shelfCode || cikisRafSel.options[cikisRafSel.selectedIndex].textContent) : '';

    var lotNo = $('##modalLotNo').val().trim();

    var item = {
        stock_id:       stockId,
        product_id:     stock ? stock.product_id : 0,
        name_product:   productName,
        price:          price,
        amount:         amount,
        unit:           unitName,
        unit_id:        unitId,
        tax:            tax,
        discount:       discount,
        discounttotal:  discTot,
        grosstotal:     gross,
        nettotal:       net,
        taxtotal:       taxTot,
        lot_no:         lotNo,
        giris_raf_id:   girisRafId,
        giris_raf_code: girisRafCode,
        cikis_raf_id:   cikisRafId,
        cikis_raf_code: cikisRafCode
    };

    if (editingIdx >= 0 && editingIdx < basketItems.length) {
        basketItems[editingIdx] = item;
    } else {
        basketItems.push(item);
    }

    var _m = bootstrap.Modal.getInstance(document.getElementById('addItemModal'));
    if (_m) _m.hide();
    renderBasket();
}

/* ─── Sepet render ─── */
function renderBasket() {
    var tbody    = document.getElementById('sepetBody');
    var emptyRow = document.getElementById('emptyRow');

    while (tbody.firstChild) tbody.removeChild(tbody.firstChild);

    if (!basketItems.length) {
        tbody.appendChild(emptyRow);
        document.getElementById('sepetCount').textContent = '0';
        document.getElementById('sepetSummary').classList.add('d-none');
        calcTotals();
        return;
    }

    basketItems.forEach(function(item, idx){
        var rafHtml = '';
        if (item.giris_raf_code) rafHtml += '<div class="text-success" style="font-size:.75rem"><i class="fas fa-arrow-down me-1"></i>' + escHtml(item.giris_raf_code) + '</div>';
        if (item.cikis_raf_code) rafHtml += '<div class="text-danger"  style="font-size:.75rem"><i class="fas fa-arrow-up me-1"></i>'   + escHtml(item.cikis_raf_code) + '</div>';
        if (!rafHtml) rafHtml = '<span class="text-muted">-</span>';

        var tr = document.createElement('tr');
        tr.innerHTML =
            '<td class="text-muted small">' + (idx+1) + '</td>' +
            '<td><strong class="small">' + escHtml(item.name_product) + '</strong>' +
                (item.lot_no ? '<br><span class="text-muted" style="font-size:.75rem">Lot: ' + escHtml(item.lot_no) + '</span>' : '') +
            '</td>' +
            '<td class="text-end small">' + fmtNum(item.price) + '</td>' +
            '<td class="text-center">' +
                '<input type="number" class="form-control form-control-sm text-center qty-inp" ' +
                    'value="' + item.amount + '" min="0.001" step="0.001" ' +
                    'style="width:64px;margin:auto" ' +
                    'onchange="updateQty(' + idx + ', this.value)">' +
            '</td>' +
            '<td class="text-center small">' + escHtml(item.unit||'-') + '</td>' +
            '<td class="text-center small">%' + item.tax + '</td>' +
            '<td class="text-center small">%' + item.discount + '</td>' +
            '<td class="text-center" style="min-width:70px">' + rafHtml + '</td>' +
            '<td class="text-end"><strong class="small">' + fmtNum(item.nettotal) + '</strong></td>' +
            '<td class="text-center">' +
                '<div class="d-flex gap-1 justify-content-center">' +
                    '<button class="btn btn-xs btn-outline-secondary" title="Düzenle" onclick="editItem(' + idx + ')"><i class="fas fa-pen"></i></button>' +
                    '<button class="btn btn-xs btn-outline-danger"    title="Sil"     onclick="removeItem(' + idx + ')"><i class="fas fa-times"></i></button>' +
                '</div>' +
            '</td>';
        tbody.appendChild(tr);
    });

    document.getElementById('sepetCount').textContent = basketItems.length;
    document.getElementById('sepetSummary').classList.remove('d-none');
    calcTotals();
}

function updateQty(idx, val) {
    var q = parseFloat(val) || 0;
    if (q <= 0) q = 1;
    var item = basketItems[idx];
    item.amount        = q;
    item.grosstotal    = item.price * q;
    item.discounttotal = item.grosstotal * item.discount / 100;
    item.nettotal      = item.grosstotal - item.discounttotal;
    item.taxtotal      = item.nettotal * item.tax / 100;
    renderBasket();
}

function editItem(idx) {
    editingIdx = idx;
    var item   = basketItems[idx];
    if (!validateDepoSelection()) return;
    updateModalRafVisibility();
    document.getElementById('modalTitleText').textContent = 'Ürün Düzenle';
    document.getElementById('modalSaveBtn').innerHTML = '<i class="fas fa-save me-1"></i>Güncelle';
    resetModal();
    var stock = allStocks.find(function(s){ return s.stock_id == item.stock_id; });
    if (stock) {
        selectStockInModal(stock);
    } else {
        $('##selectedStockId').val(item.stock_id || 0);
        $('##selectedStockLabel').text(item.name_product || '');
        $('##selectedStockInfo').removeClass('d-none');
        $('##modalStockSearch').val(item.name_product || '');
    }
    $('##modalPrice').val(item.price || 0);
    $('##modalAmount').val(item.amount || 1);
    $('##modalTax').val(item.tax || 0);
    $('##modalDiscount').val(item.discount || 0);
    $('##modalLotNo').val(item.lot_no || '');
    calcModal();
    bootstrap.Modal.getOrCreateInstance(document.getElementById('addItemModal')).show();
}

function removeItem(idx) {
    basketItems.splice(idx, 1);
    renderBasket();
}

/* ─── Toplamları hesapla ─── */
function calcTotals() {
    var gross = 0, disc = 0, net = 0, tax = 0, totalMiktar = 0;
    basketItems.forEach(function(item){
        gross         += item.grosstotal    || 0;
        disc          += item.discounttotal || 0;
        net           += item.nettotal      || 0;
        tax           += item.taxtotal      || 0;
        totalMiktar   += item.amount        || 0;
    });
    var grand = net + tax;
    document.getElementById('totalGross').textContent    = fmtNum(gross);
    document.getElementById('totalDiscount').textContent = fmtNum(disc);
    document.getElementById('totalNet').textContent      = fmtNum(net);
    document.getElementById('totalTax').textContent      = fmtNum(tax);
    document.getElementById('totalGrand').textContent    = fmtNum(grand);
    document.getElementById('summaryKalem').textContent  = basketItems.length;
    document.getElementById('summaryMiktar').textContent = totalMiktar.toLocaleString('tr-TR', {maximumFractionDigits:3});
    document.getElementById('summaryGrand').textContent  = '₺' + fmtNum(grand);
}

/* ─── Kaydet ─── */
function saveShip() {
    if (!basketItems.length) { DevExpress.ui.notify('Sepet boş!', 'warning', 2500); return; }

    var ship_id     = parseInt(document.getElementById('ship_id').value) || 0;
    var ps_checked  = document.querySelector('input[name="purchase_sales"]:checked');
    var st_checked  = document.querySelector('input[name="ship_type"]:checked');
    var status_cb   = document.getElementById('ship_status');

    var gross = 0, disc = 0, net = 0, tax = 0;
    basketItems.forEach(function(item){
        gross += item.grosstotal    || 0;
        disc  += item.discounttotal || 0;
        net   += item.nettotal      || 0;
        tax   += item.taxtotal      || 0;
    });

    var data = {
        ship_id:        ship_id,
        purchase_sales: ps_checked  ? ps_checked.value  : 'true',
        ship_type:      st_checked  ? st_checked.value  : '1',
        ship_number:    $('##ship_number').val(),
        serial_number:  $('##serial_number').val(),
        ship_date:      $('##ship_date').val(),
        deliver_date:   $('##deliver_date').val(),
        company_id:     $('##company_id').val() || '0',
        paymethod_id:   $('##paymethod_id').val() || '0',
        ship_method:    $('##ship_method_sel').val() || '0',
        location_in:    parseInt(document.getElementById('girisDepoId').value) || 0,
        location_out:   parseInt(document.getElementById('cikisDepoId').value) || 0,
        ship_status:    status_cb && status_cb.checked ? '1' : '0',
        ref_no:         $('##ref_no').val(),
        ship_detail:    $('##ship_detail').val(),
        grosstotal:     gross,
        discounttotal:  disc,
        nettotal:       net,
        taxtotal:       tax,
        rows:           JSON.stringify(basketItems)
    };

    var btn = document.getElementById('saveBtnLabel').parentElement;
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url:      '/ship/form/save_ship.cfm',
        method:   'POST',
        data:     data,
        dataType: 'json',
        success: function(res) {
            if (res.success) {
                DevExpress.ui.notify('İrsaliye kaydedildi!', 'success', 2000);
                setTimeout(function(){
                    window.location.href = '/index.cfm?fuseaction=ship.add_ship&ship_id=' + res.ship_id;
                }, 1000);
            } else {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-save me-2"></i><span id="saveBtnLabel">' + (ship_id ? 'Güncelle' : 'Kaydet') + '</span>';
                DevExpress.ui.notify(res.message || 'Hata!', 'error', 4000);
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i><span id="saveBtnLabel">' + (ship_id ? 'Güncelle' : 'Kaydet') + '</span>';
            DevExpress.ui.notify('Kayıt başarısız!', 'error', 3000);
        }
    });
}

/* ─── Sil ─── */
function deleteShipForm() {
    var ship_id = parseInt(document.getElementById('ship_id').value) || 0;
    if (!ship_id) return;
    DevExpress.ui.dialog.confirm('Bu irsaliyeyi silmek istediğinizden emin misiniz?', 'Silme Onayı')
        .then(function(ok){
            if (!ok) return;
            $.ajax({
                url: '/ship/form/delete_ship.cfm', method:'POST', data:{ship_id: ship_id}, dataType:'json',
                success: function(r){
                    if (r.success) {
                        DevExpress.ui.notify('İrsaliye silindi.','success',1500);
                        setTimeout(function(){ window.location.href='/index.cfm?fuseaction=ship.list_ship'; },1500);
                    } else DevExpress.ui.notify(r.message||'Hata!','error',3000);
                },
                error: function(){ DevExpress.ui.notify('Silme başarısız!','error',3000); }
            });
        });
}

/* ─── Yardımcılar ─── */
function fmtNum(n) {
    return parseFloat(n||0).toLocaleString('tr-TR', {minimumFractionDigits:2, maximumFractionDigits:2});
}
function escHtml(str) {
    return String(str||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

/* ─── Sayfa yüklenince (jQuery burada hazır) ─── */
window.addEventListener('load', function(){
    // Modal'ı body'e taşı (content-wrapper stacking context'ten kaçınmak için)
    var m = document.getElementById('addItemModal');
    if (m && m.parentNode !== document.body) document.body.appendChild(m);

    // Depo seçeneklerini her iki select'e doldur
    ['girisDepoId','cikisDepoId'].forEach(function(selId) {
        var selEl = document.getElementById(selId);
        if (!selEl) return;
        allLocations.forEach(function(loc) {
            var opt = document.createElement('option');
            opt.value       = loc.id;
            opt.textContent = loc.label || (loc.department_head + ' — ' + loc.department_location);
            selEl.appendChild(opt);
        });
    });
    if (editGirisDepo > 0) document.getElementById('girisDepoId').value = editGirisDepo;
    if (editCikisDepo > 0) document.getElementById('cikisDepoId').value = editCikisDepo;

    // İşlem türü değişince irsaliye tipini + depoyu güncelle
    document.querySelectorAll('input[name="purchase_sales"]').forEach(function(radio) {
        radio.addEventListener('change', updateShipTypeVisibility);
    });
    // İrsaliye tipi değişince depo görünürlüğünü güncelle
    document.querySelectorAll('input[name="ship_type"]').forEach(function(radio) {
        radio.addEventListener('change', updateDepoUI);
    });
    updateShipTypeVisibility();

    // ─── Firma arama ───
    $('##companySearch').on('focus', function(){ loadCompanies(); })
        .on('input', function(){
            var q = $(this).val().toLowerCase().trim();
            var dd = $('##companyDropdown');
            if (!q) { dd.addClass('d-none'); return; }
            var matches = allCompanies.filter(function(c){
                return (c.display_name||'').toLowerCase().includes(q);
            }).slice(0,10);
            dd.empty();
            if (!matches.length) { dd.addClass('d-none'); return; }
            matches.forEach(function(c){
                $('<div>').addClass('search-item').text(c.display_name)
                    .on('click', function(){
                        $('##companySearch').val(c.display_name);
                        $('##company_id').val(c.company_id);
                        dd.addClass('d-none');
                    }).appendTo(dd);
            });
            dd.removeClass('d-none');
        });

    // ─── Hızlı stok arama (sepet üstü) ───
    $('##quickSearch').on('input', function(){
        showDropdown(this.value, 'quickSearchDropdown', function(stock){
            $('##quickSearch').val('');
            openAddModalFor(stock);
        });
    });

    // ─── Modal stok arama ───
    $('##modalStockSearch').on('input', function(){
        showDropdown(this.value, 'modalSearchResults', function(stock){
            selectStockInModal(stock);
        });
    });

    // ─── Modal fiyat hesaplama ───
    $('##modalPrice, ##modalAmount, ##modalDiscount, ##modalTax').on('input change', function(){ calcModal(); });

    // ─── Tüm dropdown'ları dışarı tıklayınca kapat ───
    $(document).on('click', function(e){
        if (!$(e.target).closest('##companySearch, ##companyDropdown').length)
            $('##companyDropdown').addClass('d-none');
        if (!$(e.target).closest('##quickSearch, ##quickSearchDropdown').length)
            $('##quickSearchDropdown').addClass('d-none');
        if (!$(e.target).closest('##modalStockSearch, ##modalSearchResults').length)
            $('##modalSearchResults').addClass('d-none');
    });

    // Firma listesini arka planda yükle
    loadCompanies();

    // Edit modunda mevcut sepeti göster
    if (basketItems.length) renderBasket();

    // Modal hesap tetikle
    calcModal();
});


</script>
</cfoutput>
