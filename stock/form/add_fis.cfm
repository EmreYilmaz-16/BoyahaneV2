<cfprocessingdirective pageEncoding="utf-8">

<!--- Düzenleme modu: URL'den fis_id geliyorsa mevcut fişi yükle --->
<cfset editMode = isDefined("url.fis_id") and isNumeric(url.fis_id) and url.fis_id gt 0>
<cfset currentFisId = editMode ? val(url.fis_id) : 0>

<!--- Yeni fiş modunda: belge numarası önizlemesi (kayıt sırasında atomik atanır) --->
<cfif NOT editMode>
    <cfquery name="getNextPaper" datasource="boyahane">
        SELECT COALESCE(stock_fis_no, 'SF') AS fis_prefix,
               COALESCE(stock_fis_number, 0) + 1 AS next_number
        FROM general_papers
        WHERE zone_type = 0
        ORDER BY general_papers_id
        LIMIT 1
    </cfquery>
    <cfif getNextPaper.recordCount>
        <cfset previewFisNo = getNextPaper.fis_prefix & '-' & numberFormat(getNextPaper.next_number, '00000')>
    <cfelse>
        <cfset previewFisNo = "SF-00001">
    </cfif>
</cfif>

<cfif editMode>
    <cfquery name="getFis" datasource="boyahane">
        SELECT * FROM stock_fis WHERE fis_id = <cfqueryparam value="#currentFisId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfquery name="getFisRows" datasource="boyahane">
        SELECT sfr.*, s.stock_code, s.barcod,
               p.product_name, p.product_code
        FROM stock_fis_row sfr
        LEFT JOIN stocks s ON sfr.stock_id = s.stock_id
        LEFT JOIN product p ON s.product_id = p.product_id
        WHERE sfr.fis_id = <cfqueryparam value="#currentFisId#" cfsqltype="cf_sql_integer">
        ORDER BY sfr.stock_fis_row_id
    </cfquery>
</cfif>

<!--- Aktif depo lokasyonlarını getir --->
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
        "id"                 = id,
        "department_id"      = department_id,
        "department_head"    = department_head ?: "",
        "department_location"= department_location ?: "",
        "label"              = (department_head ?: "") & " — " & (department_location ?: "")
    })>
</cfloop>
<cfset selGirisDepo = editMode and isDefined("getFis") and getFis.recordCount ? val(getFis.location_in  ?: 0) : 0>
<cfset selCikisDepo = editMode and isDefined("getFis") and getFis.recordCount ? val(getFis.location_out ?: 0) : 0>

<!--- Stokları getir (sepet arama için) --->
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
        "stock_id"       = stock_id,
        "stock_code"     = stock_code ?: "",
        "barcod"         = barcod ?: "",
        "property"       = property ?: "",
        "product_id"     = product_id ?: 0,
        "product_unit_id"= product_unit_id ?: 0,
        "product_name"   = product_name ?: "",
        "product_code"   = product_code ?: "",
        "label"          = (product_name ?: "?") & " — " & (stock_code ?: "")
    })>
</cfloop>

<cfset rowsArray = []>
<cfif editMode>
    <cfloop query="getFisRows">
        <cfset arrayAppend(rowsArray, {
            "stock_fis_row_id"   = stock_fis_row_id,
            "fis_id"             = fis_id,
            "stock_id"           = stock_id ?: 0,
            "stock_code"         = stock_code ?: "",
            "product_name"       = product_name ?: "",
            "product_code"       = product_code ?: "",
            "amount"             = amount ?: 0,
            "unit"               = unit ?: "",
            "unit_id"            = unit_id ?: 0,
            "lot_no"             = lot_no ?: "",
            "shelf_number"       = shelf_number ?: 0,
            "total"              = total ?: 0,
            "total_tax"          = total_tax ?: 0,
            "net_total"          = net_total ?: 0,
            "detail_info_extra"  = detail_info_extra ?: ""
        })>
    </cfloop>
</cfif>

<!--- jQuery yükleme kontrolü --->
<cfif not structKeyExists(request, "jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon">
            <i class="fas fa-file-invoice"></i>
        </div>
        <div class="page-header-title">
            <cfif editMode>
                <h1>Fiş Düzenle <cfoutput><small class="text-muted fs-6">#currentFisId#</small></cfoutput></h1>
                <p>Stok fişini ve kalemlerini düzenleyin</p>
            <cfelse>
                <h1>Yeni Stok Fişi</h1>
                <p>Fiş bilgilerini doldurun, sepete ürün ekleyin</p>
            </cfif>
        </div>
    </div>
    <a href="index.cfm?fuseaction=stock.list_fis" class="btn-back">
        <i class="fas fa-arrow-left"></i>Fiş Listesi
    </a>
</div>

<div class="px-3 pb-5">
    <form id="fisForm">
        <input type="hidden" id="fis_id" name="fis_id" value="<cfoutput>#currentFisId#</cfoutput>">

        <div class="row g-3">

            <!--- ═══════════════════════════════════════════════ --->
            <!--- SOL: FİŞ BİLGİLERİ                            --->
            <!--- ═══════════════════════════════════════════════ --->
            <div class="col-lg-4">
                <div class="grid-card h-100">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-receipt"></i>Fiş Bilgileri
                        </div>
                        <span class="badge bg-primary" id="fisStatusBadge">
                            <cfif editMode>Düzenleniyor<cfelse>Yeni</cfif>
                        </span>
                    </div>
                    <div class="card-body p-3">

                        <!--- Fiş Tipi --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fas fa-tag me-1 text-primary"></i>Fiş Tipi <span class="text-danger">*</span></label>
                            <div class="btn-group w-100 fis-type-group" role="group">
                                <cfset selType = editMode and getFis.recordCount ? getFis.fis_type : 1>
                                <input type="radio" class="btn-check" name="fis_type" id="ft1" value="1" <cfif selType eq 1>checked</cfif>>
                                <label class="btn btn-outline-success btn-sm" for="ft1"><i class="fas fa-arrow-down me-1"></i>Giriş</label>

                                <input type="radio" class="btn-check" name="fis_type" id="ft2" value="2" <cfif selType eq 2>checked</cfif>>
                                <label class="btn btn-outline-danger btn-sm" for="ft2"><i class="fas fa-arrow-up me-1"></i>Çıkış</label>

                                <input type="radio" class="btn-check" name="fis_type" id="ft3" value="3" <cfif selType eq 3>checked</cfif>>
                                <label class="btn btn-outline-warning btn-sm" for="ft3"><i class="fas fa-exchange-alt me-1"></i>Transfer</label>

                                <input type="radio" class="btn-check" name="fis_type" id="ft4" value="4" <cfif selType eq 4>checked</cfif>>
                                <label class="btn btn-outline-info btn-sm" for="ft4"><i class="fas fa-clipboard-check me-1"></i>Sayım</label>
                            </div>
                        </div>

                        <!--- Depo Seçimi --->
                        <div class="mb-3" id="depoSection">
                            <label class="form-label fw-semibold"><i class="fas fa-warehouse me-1 text-primary"></i>Depo <span class="text-danger">*</span></label>
                            <div id="girisDepoWrap" class="mb-2">
                                <div class="text-muted small mb-1" id="girisDepoLabel">Giriş Depo</div>
                                <select class="form-select form-select-sm" id="girisDepoId">
                                    <option value="0">-- Depo Seçin --</option>
                                </select>
                            </div>
                            <div id="cikisDepoWrap" style="display:none">
                                <div class="text-muted small mb-1">Çıkış Depo</div>
                                <select class="form-select form-select-sm" id="cikisDepoId">
                                    <option value="0">-- Depo Seçin --</option>
                                </select>
                            </div>
                        </div>

                        <!--- Fiş Numarası --->
                        <div class="mb-3">
                            <label for="fis_number" class="form-label fw-semibold"><i class="fas fa-hashtag me-1 text-primary"></i>Fiş Numarası</label>
                            <cfif editMode>
                                <input type="text" class="form-control" id="fis_number" name="fis_number"
                                       placeholder="Otomatik veya manuel girin"
                                       value="<cfoutput><cfif getFis.recordCount>#xmlFormat(getFis.fis_number)#</cfif></cfoutput>">
                            <cfelse>
                                <div class="input-group">
                                    <input type="text" class="form-control" id="fis_number" name="fis_number"
                                           placeholder="Otomatik atanacak"
                                           value="<cfoutput>#xmlFormat(previewFisNo)#</cfoutput>"
                                           readonly style="background:#f8f9fa;font-family:monospace;">
                                    <span class="input-group-text text-muted" style="font-size:.75rem;"
                                          title="Numara kayıt anında benzersiz olarak atanır">
                                        <i class="fas fa-lock me-1"></i>Otomatik
                                    </span>
                                </div>
                                <div class="form-text text-muted"><i class="fas fa-info-circle me-1"></i>Numara kayıt sırasında kesinleşir. Eşzamanlı kullanımda çakışma olmaz.</div>
                            </cfif>
                        </div>

                        <!--- Fiş Tarihi --->
                        <div class="mb-3">
                            <label for="fis_date" class="form-label fw-semibold"><i class="fas fa-calendar-alt me-1 text-primary"></i>Fiş Tarihi</label>
                            <input type="datetime-local" class="form-control" id="fis_date" name="fis_date"
                                   value="<cfoutput><cfif editMode and getFis.recordCount and isDate(getFis.fis_date)>#dateFormat(getFis.fis_date,'yyyy-mm-dd')#T#timeFormat(getFis.fis_date,'HH:mm')#<cfelse>#dateFormat(now(),'yyyy-mm-dd')#T#timeFormat(now(),'HH:mm')#</cfif></cfoutput>">
                        </div>

                        <!--- Teslim Tarihi --->
                        <div class="mb-3">
                            <label for="deliver_date" class="form-label fw-semibold"><i class="fas fa-truck me-1 text-primary"></i>Teslim Tarihi</label>
                            <input type="date" class="form-control" id="deliver_date" name="deliver_date"
                                   value="<cfoutput><cfif editMode and getFis.recordCount and isDate(getFis.deliver_date)>#dateFormat(getFis.deliver_date,'yyyy-mm-dd')#</cfif></cfoutput>">
                        </div>

                        <!--- Referans No --->
                        <div class="mb-3">
                            <label for="ref_no" class="form-label fw-semibold"><i class="fas fa-link me-1 text-primary"></i>Referans No</label>
                            <input type="text" class="form-control" id="ref_no" name="ref_no"
                                   placeholder="İrsaliye / sipariş no vb."
                                   value="<cfoutput><cfif editMode and getFis.recordCount>#xmlFormat(getFis.ref_no)#</cfif></cfoutput>">
                        </div>

                        <!--- Açıklama --->
                        <div class="mb-3">
                            <label for="fis_detail" class="form-label fw-semibold"><i class="fas fa-sticky-note me-1 text-primary"></i>Açıklama</label>
                            <textarea class="form-control" id="fis_detail" name="fis_detail" rows="3"
                                      placeholder="Fiş açıklaması..."><cfoutput><cfif editMode and getFis.recordCount>#xmlFormat(getFis.fis_detail)#</cfif></cfoutput></textarea>
                        </div>

                        <!--- Seçenekler --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold"><i class="fas fa-cog me-1 text-primary"></i>Seçenekler</label>
                            <div class="d-flex flex-column gap-2">
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="is_production" name="is_production" value="1"
                                           <cfoutput><cfif editMode and getFis.recordCount and getFis.is_production>checked</cfif></cfoutput>>
                                    <label class="form-check-label" for="is_production">Üretim Fişi</label>
                                </div>
                                <div class="form-check form-switch">
                                    <input class="form-check-input" type="checkbox" id="is_stock_transfer" name="is_stock_transfer" value="1"
                                           <cfoutput><cfif editMode and getFis.recordCount and getFis.is_stock_transfer eq 1>checked</cfif></cfoutput>>
                                    <label class="form-check-label" for="is_stock_transfer">Stok Transferi</label>
                                </div>
                            </div>
                        </div>

                        <!--- Kaydet butonu --->
                        <div class="d-grid gap-2 mt-4">
                            <button type="button" class="btn btn-primary btn-lg" onclick="saveFis()">
                                <i class="fas fa-save me-2"></i>
                                <cfif editMode>Fişi Güncelle<cfelse>Fişi Kaydet</cfif>
                            </button>
                            <cfif editMode>
                            <button type="button" class="btn btn-outline-danger" onclick="deleteFis()">
                                <i class="fas fa-trash me-2"></i>Fişi Sil
                            </button>
                            </cfif>
                        </div>

                    </div>
                </div>
            </div>

            <!--- ═══════════════════════════════════════════════ --->
            <!--- SAĞ: SEPET                                     --->
            <!--- ═══════════════════════════════════════════════ --->
            <div class="col-lg-8">
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

                    <!--- Hızlı barkod/arama çubuğu --->
                    <div class="px-3 pt-3 pb-2" style="position:relative">
                        <div class="input-group">
                            <span class="input-group-text bg-white"><i class="fas fa-barcode text-primary"></i></span>
                            <input type="text" class="form-control" id="quickSearch"
                                   placeholder="Barkod okutun veya ürün adı arayın..."
                                   autocomplete="off">
                            <button class="btn btn-outline-primary" type="button" onclick="quickAdd()">
                                <i class="fas fa-plus"></i>
                            </button>
                        </div>
                        <div id="searchResults" class="search-dropdown d-none"></div>
                    </div>

                    <!--- Sepet tablosu --->
                    <div class="card-body p-2">
                        <div class="table-responsive">
                            <table class="table table-hover table-sm align-middle mb-0" id="sepetTable">
                                <thead class="table-dark">
                                    <tr>
                                        <th style="width:40px">#</th>
                                        <th>Ürün / Stok</th>
                                        <th style="width:100px">Miktar</th>
                                        <th style="width:80px">Birim</th>
                                        <th style="width:110px">Lot No</th>
                                        <th style="width:80px">Raf</th>
                                        <th style="width:80px" class="text-end">Toplam</th>
                                        <th style="width:50px"></th>
                                    </tr>
                                </thead>
                                <tbody id="sepetBody">
                                    <tr id="emptyRow">
                                        <td colspan="8" class="text-center text-muted py-5">
                                            <i class="fas fa-shopping-basket fa-3x mb-3 d-block opacity-25"></i>
                                            Sepet boş. Yukarıdan ürün ekleyin.
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>

                        <!--- Sepet özeti --->
                        <div class="sepet-summary mt-2" id="sepetSummary" style="display:none">
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
                                        <strong id="summaryMiktar">0.00</strong>
                                    </div>
                                </div>
                                <div class="col-md-4">
                                    <div class="summary-box summary-box-primary">
                                        <span>Genel Toplam</span>
                                        <strong id="summaryTotal">₺0.00</strong>
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

<!--- ═══════════════════════════════════════════════ --->
<!--- MODAL: Ürün Ekleme                             --->
<!--- ═══════════════════════════════════════════════ --->
<div class="modal fade" id="addItemModal" tabindex="-1" aria-labelledby="addItemModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-success text-white">
                <h5 class="modal-title" id="addItemModalLabel">
                    <i class="fas fa-plus-circle me-2"></i>Sepete Ürün Ekle
                </h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <div class="mb-3" style="position:relative">
                    <label class="form-label fw-semibold">Ürün / Stok Seçin</label>
                    <input type="text" class="form-control" id="modalStockSearch"
                           placeholder="Ürün adı veya stok kodu ile arayın..." autocomplete="off">
                    <div id="modalSearchResults" class="search-dropdown d-none"></div>
                    <input type="hidden" id="selectedStockId">
                    <div id="selectedStockInfo" class="mt-2 d-none">
                        <div class="alert alert-info py-2 mb-0">
                            <i class="fas fa-check-circle me-1"></i>
                            <span id="selectedStockLabel"></span>
                        </div>
                    </div>
                </div>

                <div class="row g-3">
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Miktar <span class="text-danger">*</span></label>
                        <input type="number" class="form-control" id="modalAmount"
                               value="1" min="0.001" step="0.001" placeholder="0.000">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Birim</label>
                        <select class="form-select" id="modalUnit">
                            <option value="">-- Birim Seçin --</option>
                        </select>
                        <input type="hidden" id="modalUnitId" value="0">
                    </div>
                    <div class="col-md-4">
                        <label class="form-label fw-semibold">Birim Fiyat (₺)</label>
                        <input type="number" class="form-control" id="modalUnitPrice"
                               value="0" min="0" step="0.01" placeholder="0.00">
                    </div>
                    <div class="col-md-6">
                        <label class="form-label fw-semibold">Lot No</label>
                        <input type="text" class="form-control" id="modalLotNo" placeholder="Lot/parti numarası">
                    </div>
                    <div id="girisRafWrap" class="col-md-3">
                        <label class="form-label fw-semibold" id="girisRafLabel">Giriş Raf</label>
                        <select class="form-select" id="modalGirisRaf">
                            <option value="0">-- Raf Seçin --</option>
                        </select>
                        <input type="hidden" id="modalGirisRafId" value="0">
                    </div>
                    <div id="cikisRafWrap" class="col-md-3" style="display:none">
                        <label class="form-label fw-semibold">Çıkış Raf</label>
                        <select class="form-select" id="modalCikisRaf">
                            <option value="0">-- Raf Seçin --</option>
                        </select>
                        <input type="hidden" id="modalCikisRafId" value="0">
                    </div>
                    <div class="col-12">
                        <label class="form-label fw-semibold">Detay Bilgi</label>
                        <input type="text" class="form-control" id="modalDetailInfo" placeholder="Ek notlar...">
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-success" onclick="addToBasket()">
                    <i class="fas fa-cart-plus me-1"></i>Sepete Ekle
                </button>
            </div>
        </div>
    </div>
</div>

<cfoutput>
<style>
/* ── Fiş tip butonları ── */
.fis-type-group .btn { flex: 1; font-size:.8rem; padding:.35rem .5rem; }

/* ── Arama dropdown ── */
.search-dropdown {
    position: absolute;
    z-index: 1060;
    background: ##fff;
    border: 1px solid ##dee2e6;
    border-radius: 8px;
    max-height: 240px;
    overflow-y: auto;
    box-shadow: 0 4px 16px rgba(0,0,0,.15);
    width: 100%;
    left: 0;
    top: 100%;
}
.search-dropdown .search-item {
    padding: 8px 14px;
    cursor: pointer;
    border-bottom: 1px solid ##f0f0f0;
    font-size:.875rem;
}
.search-dropdown .search-item:hover { background:##f0f6ff; }
.search-dropdown .search-item .item-code { color:##6c757d; font-size:.8rem; }

/* ── Sepet tablosu ── */
##sepetTable thead th { font-size: .8rem; white-space: nowrap; }
##sepetTable tbody td { font-size: .875rem; }
.qty-input { width: 80px; }

/* ── Özet kutuları ── */
.sepet-summary { border-top: 1px solid ##e9ecef; padding-top: 12px; }
.summary-box {
    display: flex;
    justify-content: space-between;
    align-items: center;
    background: ##f8f9fa;
    border-radius: 8px;
    padding: 10px 14px;
    border: 1px solid ##e9ecef;
}
.summary-box span { color:##6c757d; font-size:.8rem; }
.summary-box strong { font-size:1rem; }
.summary-box-primary { background:linear-gradient(135deg,##1a3a5c,##2563ab); color:##fff; border-color:##1a3a5c; }
.summary-box-primary span, .summary-box-primary strong { color:##fff; }
.summary-box-primary strong { font-size:1.1rem; }

/* ── Fiş bilgileri card sabit yükseklik için ── */
@media(min-width:992px){
    .col-lg-4 .grid-card { position: sticky; top: 70px; }
}
</style>

<script>
var allStocks   = #serializeJSON(stocksArray)#;
var allLocations = #serializeJSON(locationsArray)#;
var sepetRows   = #serializeJSON(rowsArray)#;  // Düzenleme modunda mevcut satırlar
var rowCounter  = 0;
var editGirisDepo = #val(selGirisDepo)#;
var editCikisDepo = #val(selCikisDepo)#;

/* ══════════════════════════════════════════
   Yardımcı ─ Fiş Tipi
══════════════════════════════════════════ */
function getFisType() {
    var checked = document.querySelector('input[name="fis_type"]:checked');
    return checked ? parseInt(checked.value) : 1;
}

// Depo seçimlerini fiş tipine göre göster/gizle
function updateDepoUI() {
    var type = getFisType();
    var girisWrap  = document.getElementById('girisDepoWrap');
    var cikisWrap  = document.getElementById('cikisDepoWrap');
    var girisLabel = document.getElementById('girisDepoLabel');
    if (type === 2) {                   // Sadece çıkış
        girisWrap.style.display = 'none';
        cikisWrap.style.display = '';
    } else if (type === 3) {            // Transfer: ikisi birden
        girisWrap.style.display = '';
        cikisWrap.style.display = '';
        if (girisLabel) girisLabel.textContent = 'Giriş Depo';
    } else {                            // Giriş (1) veya Sayım (4)
        girisWrap.style.display = '';
        cikisWrap.style.display = 'none';
        if (girisLabel) girisLabel.textContent = type === 4 ? 'Sayım Depo' : 'Giriş Depo';
    }
}

// Raf seçeneklerini fiş tipine göre göster/gizle
function updateModalRafVisibility() {
    var type = getFisType();
    var girisRafWrap = document.getElementById('girisRafWrap');
    var cikisRafWrap = document.getElementById('cikisRafWrap');
    var girisLabel   = document.getElementById('girisRafLabel');
    if (type === 2) {                   // Sadece çıkış raf
        girisRafWrap.style.display = 'none';
        cikisRafWrap.style.display = '';
    } else if (type === 3) {            // Transfer: ikisi birden
        girisRafWrap.style.display = '';
        cikisRafWrap.style.display = '';
        if (girisLabel) girisLabel.textContent = 'Giriş Raf';
    } else {                            // Giriş / Sayım
        girisRafWrap.style.display = '';
        cikisRafWrap.style.display = 'none';
        if (girisLabel) girisLabel.textContent = type === 4 ? 'Sayım Raf' : 'Giriş Raf';
    }
}

// Depo seçimi doğrulaması
function validateDepoSelection() {
    var type = getFisType();
    if (type !== 2) {   // Giriş, Transfer, Sayım: giriş depo zorunlu
        if (!(parseInt(document.getElementById('girisDepoId').value) > 0)) {
            alert('Lütfen önce giriş deponu seçin.');
            document.getElementById('girisDepoId').focus();
            return false;
        }
    }
    if (type === 2 || type === 3) {   // Çıkış veya Transfer: çıkış depo zorunlu
        if (!(parseInt(document.getElementById('cikisDepoId').value) > 0)) {
            alert('Lütfen önce çıkış deponu seçin.');
            document.getElementById('cikisDepoId').focus();
            return false;
        }
    }
    return true;
}

// Raf dropdown'ı AJAX ile doldur
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
                    opt.value            = sh.product_place_id;
                    opt.textContent      = sh.label || sh.shelf_code;
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

/* ══════════════════════════════════════════
   Sayfa Yüklenince
══════════════════════════════════════════ */
window.addEventListener('load', function() {
    // Modal'ı body'e taşı — content-wrapper'ın overflow stacking context'inden kurtulmak için
    var modalEl = document.getElementById('addItemModal');
    if (modalEl && modalEl.parentNode !== document.body) {
        document.body.appendChild(modalEl);
    }

    // Depo seçeneklerini JS ile doldur
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
    // Edit modunda kaydetli depoları seç
    if (editGirisDepo > 0) document.getElementById('girisDepoId').value = editGirisDepo;
    if (editCikisDepo > 0) document.getElementById('cikisDepoId').value = editCikisDepo;

    // Fiş tipi değişince depo görünürlüğünü güncelle
    document.querySelectorAll('input[name="fis_type"]').forEach(function(radio) {
        radio.addEventListener('change', updateDepoUI);
    });
    updateDepoUI();

    // Mevcut satırları sepete yükle (edit modu)
    sepetRows.forEach(function(row) {
        addRowToTable({
            rowId:      row.stock_fis_row_id,
            stockId:    row.stock_id,
            stockCode:  row.stock_code,
            productName:row.product_name,
            amount:     row.amount,
            unit:       row.unit,
            lotNo:      row.lot_no,
            shelfNumber:row.shelf_number,
            unitPrice:  row.total && row.amount ? (row.total / row.amount) : 0,
            total:      row.total,
            detailInfo: row.detail_info_extra
        });
    });

    // Hızlı arama
    document.getElementById('quickSearch').addEventListener('input', function() {
        showDropdown(this.value, 'searchResults', function(stock) {
            document.getElementById('quickSearch').value = '';
            document.getElementById('searchResults').classList.add('d-none');
            openAddModalFor(stock);
        });
    });

    // Modal arama
    document.getElementById('modalStockSearch').addEventListener('input', function() {
        showDropdown(this.value, 'modalSearchResults', function(stock) {
            selectStockInModal(stock);
        });
    });

    document.getElementById('modalAmount').addEventListener('input', calcModalTotal);
    document.getElementById('modalUnitPrice').addEventListener('input', calcModalTotal);
});

/* ══════════════════════════════════════════
   Arama / Dropdown
══════════════════════════════════════════ */
function showDropdown(term, containerId, onSelect) {
    var container = document.getElementById(containerId);
    if (!term || term.length < 2) {
        container.classList.add('d-none');
        return;
    }
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

/* ══════════════════════════════════════════
   Modal İşlemleri
══════════════════════════════════════════ */
function showAddItemModal() {
    if (!validateDepoSelection()) return;
    updateModalRafVisibility();
    resetModal();
    var modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('addItemModal'));
    modal.show();
    setTimeout(function(){ document.getElementById('modalStockSearch').focus(); }, 400);
}

function openAddModalFor(stock) {
    if (!validateDepoSelection()) return;
    updateModalRafVisibility();
    resetModal();
    selectStockInModal(stock);
    var modal = bootstrap.Modal.getOrCreateInstance(document.getElementById('addItemModal'));
    modal.show();
    setTimeout(function(){ document.getElementById('modalAmount').focus(); }, 400);
}

function resetModal() {
    document.getElementById('modalStockSearch').value = '';
    document.getElementById('modalSearchResults').classList.add('d-none');
    document.getElementById('selectedStockId').value = '';
    document.getElementById('selectedStockInfo').classList.add('d-none');
    document.getElementById('modalAmount').value = '1';
    document.getElementById('modalUnitPrice').value = '0';
    document.getElementById('modalUnitId').value = '0';
    document.getElementById('modalLotNo').value = '';
    document.getElementById('modalDetailInfo').value = '';
    // Birim dropdown'ı sıfırla
    document.getElementById('modalUnit').innerHTML = '<option value="">-- Birim Seçin --</option>';
    // Giriş/çıkış raf dropdown'ı sıfırla
    document.getElementById('modalGirisRaf').innerHTML = '<option value="0">-- Raf Seçin --</option>';
    document.getElementById('modalGirisRafId').value = '0';
    document.getElementById('modalCikisRaf').innerHTML = '<option value="0">-- Raf Seçin --</option>';
    document.getElementById('modalCikisRafId').value = '0';
}

function selectStockInModal(stock) {
    document.getElementById('selectedStockId').value = stock.stock_id;
    document.getElementById('selectedStockLabel').textContent =
        stock.product_name + ' — ' + stock.stock_code +
        (stock.property ? ' (' + stock.property + ')' : '');
    document.getElementById('selectedStockInfo').classList.remove('d-none');
    document.getElementById('modalStockSearch').value = stock.product_name;
    document.getElementById('modalSearchResults').classList.add('d-none');

    // Ürünün birimlerini getir
    var sel = document.getElementById('modalUnit');
    sel.innerHTML = '<option value="">Yükleniyor...</option>';
    $.ajax({
        url: '/product/cfc/product.cfc?method=getUnitsByProduct',
        method: 'GET',
        data: { product_id: stock.product_id },
        dataType: 'json',
        success: function(res) {
            sel.innerHTML = '<option value="">-- Birim Seçin --</option>';
            if (res.success && res.data.length) {
                res.data.forEach(function(u) {
                    var label = u.main_unit;
                    if (u.add_unit) label += ' / ' + u.add_unit;
                    if (u.multiplier && u.multiplier != 1) label += ' (x' + u.multiplier + ')';
                    var opt = document.createElement('option');
                    opt.value = u.product_unit_id;
                    opt.textContent = label;
                    opt.dataset.unitName = u.main_unit;
                    // Stokun ana birimiyle eşleşeni seç
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
        error: function() {
            sel.innerHTML = '<option value="">Birim yüklenemedi</option>';
        }
    });

    // Birim seçimi değişince unit_id güncelle
    sel.onchange = function() {
        var chosen = sel.options[sel.selectedIndex];
        document.getElementById('modalUnitId').value = chosen ? chosen.value : '0';
    };

    // Raf yükle: fiş tipine göre giriş/çıkış lokasyona göre filtrele
    var type = getFisType();
    if (type !== 2) {   // Giriş / Sayım / Transfer: giriş raf yükle
        var girisLocId = parseInt(document.getElementById('girisDepoId').value) || 0;
        loadShelvesIntoSelect(
            document.getElementById('modalGirisRaf'),
            document.getElementById('modalGirisRafId'),
            stock.stock_id, girisLocId
        );
    }
    if (type === 2 || type === 3) {   // Çıkış / Transfer: çıkış raf yükle
        var cikisLocId = parseInt(document.getElementById('cikisDepoId').value) || 0;
        loadShelvesIntoSelect(
            document.getElementById('modalCikisRaf'),
            document.getElementById('modalCikisRafId'),
            stock.stock_id, cikisLocId
        );
    }

    document.getElementById('modalAmount').focus();
}

function quickAdd() {
    var term = document.getElementById('quickSearch').value.trim();
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

function calcModalTotal() {
    var qty   = parseFloat(document.getElementById('modalAmount').value) || 0;
    var price = parseFloat(document.getElementById('modalUnitPrice').value) || 0;
    // Sadece görsel olarak gösterebiliriz; gerçek hesap addToBasket'te
    return qty * price;
}

/* ══════════════════════════════════════════
   Sepete Ekle
══════════════════════════════════════════ */
function addToBasket() {
    var stockId = document.getElementById('selectedStockId').value;
    if (!stockId) {
        alert('Lütfen bir ürün/stok seçin.');
        return;
    }
    var qty = parseFloat(document.getElementById('modalAmount').value) || 0;
    if (qty <= 0) {
        alert('Miktar sıfırdan büyük olmalıdır.');
        return;
    }

    var stock = allStocks.find(function(s){ return s.stock_id == stockId; });
    var unitPrice = parseFloat(document.getElementById('modalUnitPrice').value) || 0;
    var sel = document.getElementById('modalUnit');
    var unitName = sel.options[sel.selectedIndex] ? sel.options[sel.selectedIndex].dataset.unitName || sel.options[sel.selectedIndex].textContent : '';
    var unitId   = document.getElementById('modalUnitId').value || 0;

    // Giriş raf
    var girisRafSel  = document.getElementById('modalGirisRaf');
    var girisRafId   = parseInt(girisRafSel.value) || 0;
    var girisRafCode = girisRafId > 0 && girisRafSel.options[girisRafSel.selectedIndex]
                       ? (girisRafSel.options[girisRafSel.selectedIndex].dataset.shelfCode || girisRafSel.options[girisRafSel.selectedIndex].textContent)
                       : '';
    // Çıkış raf
    var cikisRafSel  = document.getElementById('modalCikisRaf');
    var cikisRafId   = parseInt(cikisRafSel.value) || 0;
    var cikisRafCode = cikisRafId > 0 && cikisRafSel.options[cikisRafSel.selectedIndex]
                       ? (cikisRafSel.options[cikisRafSel.selectedIndex].dataset.shelfCode || cikisRafSel.options[cikisRafSel.selectedIndex].textContent)
                       : '';

    addRowToTable({
        rowId:        0,
        stockId:      stockId,
        stockCode:    stock ? stock.stock_code : '',
        productName:  stock ? stock.product_name : '',
        amount:       qty,
        unit:         unitName,
        unitId:       unitId,
        lotNo:        document.getElementById('modalLotNo').value,
        girisRafId:   girisRafId,
        girisRafCode: girisRafCode,
        cikisRafId:   cikisRafId,
        cikisRafCode: cikisRafCode,
        unitPrice:    unitPrice,
        total:        qty * unitPrice,
        detailInfo:   document.getElementById('modalDetailInfo').value
    });

    var modalEl = document.getElementById('addItemModal');
    var instance = bootstrap.Modal.getInstance(modalEl) || bootstrap.Modal.getOrCreateInstance(modalEl);
    instance.hide();
}

function addRowToTable(item) {
    rowCounter++;
    var idx = rowCounter;

    document.getElementById('emptyRow').style.display = 'none';

    var tr = document.createElement('tr');
    tr.id = 'row_' + idx;
    tr.dataset.stockId   = item.stockId;
    tr.dataset.rowId     = item.rowId;
    tr.dataset.unitPrice = item.unitPrice;
    tr.dataset.unitId      = item.unitId || 0;
    tr.dataset.girisRafId  = item.girisRafId  || 0;
    tr.dataset.cikisRafId  = item.cikisRafId  || 0;

    // Raf hücresi görünümü
    var rafCellHtml = '';
    if (item.girisRafCode) rafCellHtml += '<div class="text-success" style="font-size:.75rem"><i class="fas fa-arrow-down me-1"></i>' + escHtml(item.girisRafCode) + '</div>';
    if (item.cikisRafCode) rafCellHtml += '<div class="text-danger" style="font-size:.75rem"><i class="fas fa-arrow-up me-1"></i>' + escHtml(item.cikisRafCode) + '</div>';
    rafCellHtml += '<input type="hidden" data-field="shelf_number" value="' + (item.girisRafId || 0) + '">';
    rafCellHtml += '<input type="hidden" data-field="to_shelf_number" value="' + (item.cikisRafId || 0) + '">';

    tr.innerHTML =
        '<td class="text-muted">' + idx + '</td>' +
        '<td>' +
            '<div class="fw-semibold" style="font-size:.875rem">' + escHtml(item.productName) + '</div>' +
            '<div class="text-muted" style="font-size:.78rem">' + escHtml(item.stockCode) + '</div>' +
        '</td>' +
        '<td>' +
            '<input type="number" class="form-control form-control-sm qty-input" ' +
                   'value="' + item.amount + '" min="0.001" step="0.001" ' +
                   'onchange="updateRow(' + idx + ')" data-field="amount">' +
        '</td>' +
        '<td>' +
            '<input type="text" class="form-control form-control-sm" ' +
                   'value="' + escHtml(item.unit) + '" style="width:70px" ' +
                   'onchange="updateRow(' + idx + ')" data-field="unit" placeholder="biri.">' +
        '</td>' +
        '<td>' +
            '<input type="text" class="form-control form-control-sm" ' +
                   'value="' + escHtml(item.lotNo) + '" style="width:90px" ' +
                   'data-field="lot_no" placeholder="Lot">' +
        '</td>' +
        '<td>' +
            rafCellHtml +
        '</td>' +
        '<td class="text-end fw-semibold row-total" id="total_' + idx + '">' +
            formatMoney(item.total) +
        '</td>' +
        '<td class="text-center">' +
            '<button type="button" class="btn btn-sm btn-outline-danger" onclick="removeRow(' + idx + ')">' +
                '<i class="fas fa-times"></i>' +
            '</button>' +
        '</td>';

    document.getElementById('sepetBody').appendChild(tr);
    updateSummary();
}

function updateRow(idx) {
    var tr = document.getElementById('row_' + idx);
    if (!tr) return;
    var qty   = parseFloat(tr.querySelector('[data-field="amount"]').value) || 0;
    var price = parseFloat(tr.dataset.unitPrice) || 0;
    var total = qty * price;
    document.getElementById('total_' + idx).textContent = formatMoney(total);
    updateSummary();
}

function removeRow(idx) {
    var tr = document.getElementById('row_' + idx);
    if (tr) tr.remove();
    var rows = document.querySelectorAll('##sepetBody tr[id^="row_"]');
    if (!rows.length) {
        document.getElementById('emptyRow').style.display = '';
    }
    updateSummary();
}

function updateSummary() {
    var rows    = document.querySelectorAll('##sepetBody tr[id^="row_"]');
    var kalem   = rows.length;
    var miktar  = 0;
    var total   = 0;
    rows.forEach(function(tr){
        var qtyInput = tr.querySelector('[data-field="amount"]');
        var qty = qtyInput ? parseFloat(qtyInput.value) || 0 : 0;
        var price = parseFloat(tr.dataset.unitPrice) || 0;
        miktar += qty;
        total  += qty * price;
    });
    document.getElementById('sepetCount').textContent = kalem;
    document.getElementById('summaryKalem').textContent = kalem;
    document.getElementById('summaryMiktar').textContent = miktar.toFixed(2);
    document.getElementById('summaryTotal').textContent = '₺' + total.toFixed(2);
    document.getElementById('sepetSummary').style.display = kalem > 0 ? '' : 'none';
}

/* ══════════════════════════════════════════
   Fibinisleri Kaydetme
══════════════════════════════════════════ */
function collectSepetData() {
    var rows = document.querySelectorAll('##sepetBody tr[id^="row_"]');
    var data = [];
    rows.forEach(function(tr) {
        data.push({
            stock_fis_row_id: tr.dataset.rowId,
            stock_id:         tr.dataset.stockId,
            amount:           parseFloat(tr.querySelector('[data-field="amount"]').value) || 0,
            unit:             tr.querySelector('[data-field="unit"]').value,
            unit_id:          tr.dataset.unitId || 0,
            lot_no:           tr.querySelector('[data-field="lot_no"]').value,
            shelf_number:     parseInt((tr.querySelector('[data-field="shelf_number"]') || {}).value) || parseInt(tr.dataset.girisRafId) || 0,
            to_shelf_number:  parseInt((tr.querySelector('[data-field="to_shelf_number"]') || {}).value) || parseInt(tr.dataset.cikisRafId) || 0,
            unit_price:       parseFloat(tr.dataset.unitPrice) || 0,
            total:            parseFloat(tr.querySelector('[data-field="amount"]').value || 0) *
                              parseFloat(tr.dataset.unitPrice || 0)
        });
    });
    return data;
}

function saveFis() {
    var rows = document.querySelectorAll('##sepetBody tr[id^="row_"]');
    if (!rows.length) {
        if (!confirm('Sepet boş. Yine de fişi kaydetmek istiyor musunuz?')) return;
    }

    var fisDate = document.getElementById('fis_date').value;
    if (!fisDate) {
        alert('Lütfen fiş tarihini giriniz.');
        document.getElementById('fis_date').focus();
        return;
    }

    var payload = {
        fis_id:           document.getElementById('fis_id').value,
        fis_type:         document.querySelector('input[name="fis_type"]:checked').value,
        fis_number:       document.getElementById('fis_number').value,
        fis_date:         fisDate,
        deliver_date:     document.getElementById('deliver_date').value,
        ref_no:           document.getElementById('ref_no').value,
        fis_detail:       document.getElementById('fis_detail').value,
        is_production:    document.getElementById('is_production').checked ? 1 : 0,
        is_stock_transfer:document.getElementById('is_stock_transfer').checked ? 1 : 0,
        location_in_id:   parseInt(document.getElementById('girisDepoId').value) || 0,
        location_out_id:  parseInt(document.getElementById('cikisDepoId').value) || 0,
        rows:             JSON.stringify(collectSepetData())
    };

    $.ajax({
        url:  'stock/form/save_fis.cfm',
        type: 'POST',
        data: payload,
        dataType: 'json',
        success: function(resp) {
            if (resp.success) {
                window.location.href = 'index.cfm?fuseaction=stock.list_fis&success=' +
                    (payload.fis_id > 0 ? 'updated' : 'added');
            } else {
                alert('Hata: ' + (resp.message || 'Kaydetme başarısız.'));
            }
        },
        error: function() {
            alert('Sunucu hatası. Lütfen tekrar deneyin.');
        }
    });
}

function deleteFis() {
    var fisId = document.getElementById('fis_id').value;
    if (!fisId || fisId == 0) return;
    if (!confirm('Bu fişi ve tüm kalemlerini silmek istediğinizden emin misiniz?')) return;
    $.post('stock/form/delete_fis.cfm', { fis_id: fisId }, function(resp){
        try {
            var r = JSON.parse(resp);
            if (r.success) {
                window.location.href = 'index.cfm?fuseaction=stock.list_fis&success=deleted';
            } else {
                alert('Hata: ' + (r.message || 'Silme başarısız.'));
            }
        } catch(e) {
            alert('Sunucu hatası.');
        }
    });
}

/* ══════════════════════════════════════════
   Yardımcılar
══════════════════════════════════════════ */
function escHtml(str) {
    if (!str) return '';
    return String(str)
        .replace(/&/g,'&amp;')
        .replace(/</g,'&lt;')
        .replace(/>/g,'&gt;')
        .replace(/"/g,'&quot;');
}
function formatMoney(n) {
    if (!n) return '₺0.00';
    return '₺' + parseFloat(n).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g,',');
}
</script>
</cfoutput>
