<cfprocessingdirective pageEncoding="utf-8">
<cfparam name="url.location_id" type="integer" default="4">

<!--- Edit mode --->
<cfset editMode      = isDefined("url.ship_id") AND isNumeric(url.ship_id) AND url.ship_id gt 0>
<cfset currentShipId = editMode ? val(url.ship_id) : 0>

<!--- Parametrik lokasyon bilgisi --->
<cfset locationLabel = "(Lokasyon belirtilmedi)">
<cfif url.location_id gt 0>
    <cfquery name="getLocation" datasource="boyahane">
        SELECT sl.id, sl.department_location, d.department_head
        FROM stocks_location sl
        JOIN department d ON sl.department_id = d.department_id
        WHERE sl.id      = <cfqueryparam value="#url.location_id#" cfsqltype="cf_sql_integer">
          AND sl.status  = true
    </cfquery>
    <cfif getLocation.recordCount>
        <cfset locationLabel = getLocation.department_head & " — " & getLocation.department_location>
    </cfif>
</cfif>

<!--- Edit modunda mevcut kayıt --->
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
    <cfelse>
        <cfquery name="getShipRow" datasource="boyahane">
            SELECT sr.*
            FROM ship_row sr
            WHERE sr.ship_id = <cfqueryparam value="#currentShipId#" cfsqltype="cf_sql_integer">
            ORDER BY sr.ship_row_id
            LIMIT 1
        </cfquery>
    </cfif>
</cfif>

<!--- Seçili değerler (stok bloğundan önce tanımlanmalı) --->
<cfif editMode AND isDefined("getShip") AND getShip.recordCount>
    <cfset s = getShip>
    <cfset selCompanyId   = val(s.company_id ?: 0)>
    <cfset selCompanyName = s.company_name ?: "">
    <cfset selShipNumber  = s.ship_number ?: "">
    <cfset selRefNo       = s.ref_no ?: "">
    <cfset selShipDetail  = s.ship_detail ?: "">
    <cfset selShipStatus  = val(s.ship_status ?: 1)>
    <cfset selPaymethod   = val(s.paymethod_id ?: 0)>
    <cfset selShipMethod  = val(s.ship_method ?: 0)>
    <cfset selLocationIn  = url.location_id gt 0 ? url.location_id : val(s.location_in ?: 0)>
    <cfset selHkMetre     = isNumeric(s.hk_metre)     ? s.hk_metre     : "">
    <cfset selHkKg        = isNumeric(s.hk_kg)        ? s.hk_kg        : "">
    <cfset selHkTopAdedi  = isNumeric(s.hk_top_adedi) ? s.hk_top_adedi : "">
    <cfset selHkHGramaj   = isNumeric(s.hk_h_gramaj)  ? s.hk_h_gramaj  : "">
    <cfset selHkGrMtul    = isNumeric(s.hk_gr_mtul)   ? s.hk_gr_mtul   : "">
    <cfset selHkUcretli   = s.hk_ucretli ?: true>
    <cfset selHkHamBoyali = s.hk_ham_boyali ?: true>
    <cfif isDefined("getShipRow") AND getShipRow.recordCount>
        <cfset r = getShipRow>
        <cfset selStockId   = val(r.stock_id ?: 0)>
        <cfset selStockName = r.name_product ?: "">
        <!--- metre = amount, kg = amount2 (ship_row kolonları) --->
        <cfif isNumeric(r.amount) AND r.amount gt 0><cfset selHkMetre = r.amount></cfif>
        <cfif isDefined("r.amount2") AND isNumeric(r.amount2) AND r.amount2 gt 0><cfset selHkKg = r.amount2></cfif>
        <cfset selUnit      = r.unit ?: "">
        <cfset selUnitId    = val(r.unit_id ?: 0)>
        <cfset selLotNo     = r.lot_no ?: "">
        <cfset selRafId     = val(r.shelf_number ?: 0)>
    <cfelse>
        <cfset selStockId = 0><cfset selStockName = "">
        <cfset selUnit = ""><cfset selUnitId = 0><cfset selLotNo = ""><cfset selRafId = 0>
    </cfif>
<cfelse>
    <cfset selCompanyId = 0><cfset selCompanyName = ""><cfset selShipNumber = "">
    <cfset selRefNo = ""><cfset selShipDetail = ""><cfset selShipStatus = 1>
    <cfset selPaymethod = 0><cfset selShipMethod = 0><cfset selLocationIn = url.location_id>
    <cfset selHkMetre = ""><cfset selHkKg = ""><cfset selHkTopAdedi = "">
    <cfset selHkHGramaj = ""><cfset selHkGrMtul = "">
    <cfset selHkUcretli = true><cfset selHkHamBoyali = true>
    <cfset selStockId = 0><cfset selStockName = "">
    <cfset selUnit = ""><cfset selUnitId = 0><cfset selLotNo = ""><cfset selRafId = 0>
</cfif>

<!--- Stoklar — edit modunda firma seçiliyse CF'de ön yükle; add modunda JS AJAX ile yüklenir --->
<cfset stocksArray = []>
<cfif selCompanyId gt 0>
    <cfquery name="getStocks" datasource="boyahane">
        SELECT s.stock_id, s.stock_code, s.barcod,
               s.property, s.product_unit_id,
               p.product_id, p.product_name, p.product_code
        FROM stocks s
        LEFT JOIN product p ON s.product_id = p.product_id
        WHERE s.stock_status  = true
          AND s.is_main_stock = true
          AND p.company_id    = <cfqueryparam value="#selCompanyId#" cfsqltype="cf_sql_integer">
        ORDER BY p.product_name, s.stock_code
    </cfquery>
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
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-dolly"></i></div>
        <div class="page-header-title">
            <cfif editMode>
                <cfoutput><h1>Ham Kumaş Girişi Düzenle <small class="text-muted fs-6">###currentShipId#</small></h1></cfoutput>
                <p>Ham kumaş giriş irsaliyesini düzenleyin</p>
            <cfelse>
                <h1>Ham Kumaş Girişi</h1>
                <p>Alış / Ham Kumaş irsaliyesi oluşturun</p>
            </cfif>
        </div>
    </div>
    <a href="index.cfm?fuseaction=ship.list_giris_fis" class="btn-back">
        <i class="fas fa-arrow-left"></i>Girişi Fişleri
    </a>
</div>

<div class="px-3 pb-5">
    <form id="shipForm">
        <input type="hidden" id="ship_id"       value="<cfoutput>#currentShipId#</cfoutput>">
        <input type="hidden" id="purchase_sales" value="false">
        <input type="hidden" id="ship_type_val"  value="5">
        <input type="hidden" id="location_in"    value="<cfoutput>#selLocationIn#</cfoutput>">
        <input type="hidden" id="paymethod_id"   value="<cfoutput>#selPaymethod#</cfoutput>">
        <input type="hidden" id="ship_method"    value="<cfoutput>#selShipMethod#</cfoutput>">

        <div class="row g-3">

            <!--- ═══════ SOL: FİŞ + HAM KUMAŞ ═══════ --->
            <div class="col-lg-5">

                <!--- Fiş Bilgileri --->
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-receipt"></i>Fiş Bilgileri
                            <span class="badge bg-info ms-2">Alış · Ham Kumaş</span>
                        </div>
                        <cfif url.location_id gt 0>
                            <span class="badge bg-success" title="Giriş Deposu">
                                <i class="fas fa-warehouse me-1"></i><cfoutput>#locationLabel#</cfoutput>
                            </span>
                        <cfelse>
                            <span class="badge bg-danger" title="Lokasyon belirtilmedi">
                                <i class="fas fa-exclamation-triangle me-1"></i>Depo Yok
                            </span>
                        </cfif>
                    </div>
                    <div class="card-body p-3">

                        <!--- Firma (zorunlu) --->
                        <div class="mb-3" style="position:relative">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-building me-1 text-primary"></i>Firma <span class="text-danger">*</span>
                            </label>
                            <input type="text" class="form-control" id="companySearch"
                                   placeholder="Firma adı ile arayın..." autocomplete="off" required
                                   value="<cfoutput>#xmlFormat(selCompanyName)#</cfoutput>">
                            <input type="hidden" id="company_id" value="<cfoutput>#selCompanyId#</cfoutput>">
                            <div id="companyDropdown" class="search-dropdown d-none"></div>
                            <div id="companyInfo" class="mt-1 <cfif selCompanyId eq 0>d-none</cfif>">
                                <small class="text-muted">
                                    <i class="fas fa-check-circle text-success me-1"></i>
                                    <span id="companyRiskInfo"></span>
                                </small>
                            </div>
                        </div>

                        <!--- İrsaliye No --->
                        <div class="mb-3">
                            <label for="ship_number" class="form-label fw-semibold">
                                <i class="fas fa-hashtag me-1 text-primary"></i>İrsaliye No
                            </label>
                            <input type="text" class="form-control" id="ship_number"
                                   placeholder="Otomatik veya elle girin"
                                   value="<cfoutput>#xmlFormat(selShipNumber)#</cfoutput>">
                        </div>

                        <!--- Referans No --->
                        <div class="mb-3">
                            <label for="ref_no" class="form-label fw-semibold">
                                <i class="fas fa-link me-1 text-primary"></i>Referans No
                            </label>
                            <input type="text" class="form-control" id="ref_no"
                                   placeholder="Sipariş/fatura no vb."
                                   value="<cfoutput>#xmlFormat(selRefNo)#</cfoutput>">
                        </div>

                        <!--- Açıklama --->
                        <div class="mb-3">
                            <label for="ship_detail" class="form-label fw-semibold">
                                <i class="fas fa-sticky-note me-1 text-primary"></i>Açıklama
                            </label>
                            <textarea class="form-control" id="ship_detail" rows="2"
                                      placeholder="İrsaliye açıklaması..."><cfoutput>#xmlFormat(selShipDetail)#</cfoutput></textarea>
                        </div>

                        <!--- Giriş Rafı --->
                        <div class="mb-3">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-layer-group me-1 text-primary"></i>Giriş Rafı
                            </label>
                            <select class="form-select" id="stock_raf">
                                <option value="0">-- Raf Seçin --</option>
                            </select>
                            <input type="hidden" id="stock_raf_id"   value="<cfoutput>#selRafId#</cfoutput>">
                            <input type="hidden" id="stock_raf_code" value="">
                        </div>

                        <!--- Durum --->
                        <div class="mb-3">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" id="ship_status"
                                       <cfif selShipStatus eq 1>checked</cfif>>
                                <label class="form-check-label fw-semibold" for="ship_status">
                                    <i class="fas fa-toggle-on me-1 text-primary"></i>Aktif
                                </label>
                            </div>
                        </div>

                        <!--- Kaydet / Sil --->
                        <div class="d-grid gap-2 mt-3">
                            <button type="button" class="btn btn-primary btn-lg" id="saveBtn" onclick="saveShip()"
                                    <cfif NOT editMode AND selStockId eq 0>disabled title="Önce stok seçin"</cfif>>
                                <i class="fas fa-save me-2"></i>
                                <cfif editMode>Güncelle<cfelse>Kaydet</cfif>
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

            <!--- ═══════ SAĞ: STOK SEÇİMİ ═══════ --->
            <div class="col-lg-7">
                <div class="grid-card mb-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-box-open"></i>Stok Seçimi
                        </div>
                        <cfif url.location_id gt 0>
                            <span class="text-muted small">
                                <i class="fas fa-warehouse me-1"></i><cfoutput>#locationLabel#</cfoutput>
                            </span>
                        </cfif>
                    </div>
                    <div class="card-body p-3">

                        <!--- Stok arama --->
                        <div class="mb-3" style="position:relative">
                            <label class="form-label fw-semibold">
                                <i class="fas fa-search me-1 text-primary"></i>Stok Ara <span class="text-danger">*</span>
                            </label>
                            <div class="input-group">
                                <span class="input-group-text bg-white"><i class="fas fa-barcode text-primary"></i></span>
                                <input type="text" class="form-control" id="stockSearch"
                                       placeholder="Önce firma seçin..." autocomplete="off"
                                       value="<cfoutput>#xmlFormat(selStockName)#</cfoutput>"
                                       <cfif selCompanyId eq 0>disabled</cfif>>
                                <button class="btn btn-outline-secondary" type="button" onclick="clearStockSelection()" title="Temizle">
                                    <i class="fas fa-times"></i>
                                </button>
                            </div>
                            <div id="stockSearchDropdown" class="search-dropdown d-none"></div>
                            <div id="stockLoadingInfo" class="mt-1 d-none">
                                <small class="text-muted"><i class="fas fa-spinner fa-spin me-1"></i>Stoklar yükleniyor...</small>
                            </div>
                            <input type="hidden" id="selected_stock_id"  value="<cfoutput>#selStockId#</cfoutput>">
                            <input type="hidden" id="selected_product_id" value="0">
                        </div>

                        <!--- Seçili stok kartı --->
                        <div id="selectedStockCard" class="<cfif selStockId eq 0>d-none</cfif> mb-3">
                            <div class="alert alert-info py-2 mb-3">
                                <i class="fas fa-check-circle me-1"></i>
                                <strong id="selectedStockLabel"><cfoutput>#xmlFormat(selStockName)#</cfoutput></strong>
                            </div>

                            <div class="row g-3">
                                <div class="col-sm-6">
                                    <label class="form-label fw-semibold small">Birim</label>
                                    <select class="form-select" id="stock_unit">
                                        <option value="">-- Birim --</option>
                                    </select>
                                    <input type="hidden" id="stock_unit_id" value="<cfoutput>#selUnitId#</cfoutput>">
                                    <input type="hidden" id="stock_unit_name" value="<cfoutput>#xmlFormat(selUnit)#</cfoutput>">
                                </div>
                                <div class="col-sm-6 d-flex align-items-end">
                                    <div class="alert alert-warning py-2 w-100 mb-0" style="font-size:.82rem">
                                        <i class="fas fa-info-circle me-1"></i>
                                        Fiyat: <strong>0,00</strong> (ham giriş)
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!--- Boş durum --->
                        <div id="stockEmptyState" class="<cfif selStockId gt 0>d-none</cfif> text-center text-muted py-5">
                            <i class="fas fa-box fa-3x mb-3 d-block opacity-25"></i>
                            Yukarıdan stok arayın ve seçin
                        </div>

                    </div>
                </div>

                <!--- Ham Kumaş Bilgileri --->
                <div class="grid-card mt-3">
                    <div class="grid-card-header">
                        <div class="grid-card-header-title">
                            <i class="fas fa-tshirt"></i>Ham Kumaş Bilgileri
                        </div>
                    </div>
                    <div class="card-body p-3">

                        <div class="row g-2 mb-2">
                            <div class="col-4">
                                <label class="form-label fw-semibold small">Metre</label>
                                <input type="number" class="form-control form-control-sm" id="hk_metre"
                                       step="0.001" min="0" placeholder="0.000"
                                       value="<cfoutput>#selHkMetre#</cfoutput>"
                                       oninput="calcGrMtul()">
                            </div>
                            <div class="col-4">
                                <label class="form-label fw-semibold small">Kg</label>
                                <input type="number" class="form-control form-control-sm" id="hk_kg"
                                       step="0.001" min="0" placeholder="0.000"
                                       value="<cfoutput>#selHkKg#</cfoutput>"
                                       oninput="calcGrMtul()">
                            </div>
                            <div class="col-4">
                                <label class="form-label fw-semibold small">Top Adedi</label>
                                <input type="number" class="form-control form-control-sm" id="hk_top_adedi"
                                       step="1" min="0" placeholder="0"
                                       value="<cfoutput>#selHkTopAdedi#</cfoutput>">
                            </div>
                        </div>

                        <div class="row g-2 mb-3">
                            <div class="col-6">
                                <label class="form-label fw-semibold small">Ham Gramaj</label>
                                <input type="number" class="form-control form-control-sm" id="hk_h_gramaj"
                                       step="0.01" min="0" placeholder="0.00"
                                       value="<cfoutput>#selHkHGramaj#</cfoutput>">
                            </div>
                            <div class="col-6">
                                <label class="form-label fw-semibold small">Gr/Mtül <span class="text-muted">(oto)</span></label>
                                <input type="number" class="form-control form-control-sm" id="hk_gr_mtul"
                                       step="0.0001" placeholder="0.0000" readonly
                                       style="background:#f8f9fa"
                                       value="<cfoutput>#selHkGrMtul#</cfoutput>">
                            </div>
                        </div>

                        <div class="row g-2">
                            <div class="col-6">
                                <label class="form-label fw-semibold small d-block">Ücret Durumu</label>
                                <div class="btn-group w-100" role="group">
                                    <input type="radio" class="btn-check" name="hk_ucretli" id="hk_ucretli_e" value="true"  <cfif selHkUcretli>checked</cfif>>
                                    <label class="btn btn-outline-success btn-sm" for="hk_ucretli_e">Ücretli</label>
                                    <input type="radio" class="btn-check" name="hk_ucretli" id="hk_ucretli_h" value="false" <cfif NOT selHkUcretli>checked</cfif>>
                                    <label class="btn btn-outline-secondary btn-sm" for="hk_ucretli_h">Ücretsiz</label>
                                </div>
                            </div>
                            <div class="col-6">
                                <label class="form-label fw-semibold small d-block">Kumaş Durumu</label>
                                <div class="btn-group w-100" role="group">
                                    <input type="radio" class="btn-check" name="hk_ham_boyali" id="hk_ham"    value="true"  <cfif selHkHamBoyali>checked</cfif>>
                                    <label class="btn btn-outline-warning btn-sm" for="hk_ham">Ham</label>
                                    <input type="radio" class="btn-check" name="hk_ham_boyali" id="hk_boyali" value="false" <cfif NOT selHkHamBoyali>checked</cfif>>
                                    <label class="btn btn-outline-info btn-sm" for="hk_boyali">Boyalı</label>
                                </div>
                            </div>
                        </div>

                    </div>
                </div>
            </div>

        </div><!--- /row --->
    </form>
</div>

<cfoutput>
<style>
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
.hk-section { background:##fff8e1; border:1px solid ##ffe082; border-radius:10px; padding:14px 16px; }
@media(min-width:992px){ .sticky-top-card { position:sticky; top:70px; } }
</style>

<script>
var allStocks     = <cfoutput><cfif selCompanyId gt 0>#serializeJSON(stocksArray)#<cfelse>[]</cfif></cfoutput>;
var editShipId    = #currentShipId#;
var paramLocId    = #val(url.location_id)#;
var selStockId    = #selStockId#;
var selRafId      = #selRafId#;

/* ─── Gr/Mtül oto hesap ─── */
function calcGrMtul() {
    var m  = parseFloat(document.getElementById('hk_metre').value) || 0;
    var kg = parseFloat(document.getElementById('hk_kg').value)    || 0;
    document.getElementById('hk_gr_mtul').value = (m > 0 && kg > 0) ? ((kg / m) * 1000).toFixed(4) : '';
}

/* ─── Firma arama + risk bilgisi ─── */
var allCompanies = [], companyLoaded = false;
function loadCompanies() {
    if (companyLoaded) return;
    $.ajax({
        url: '/company/cfc/company.cfc?method=getCompaniesForDropdown',
        method: 'GET', dataType: 'json',
        success: function(data) { allCompanies = Array.isArray(data) ? data : []; companyLoaded = true; }
    });
}

function selectCompany(c) {
    $('##companySearch').val(c.display_name || c.nickname || c.fullname || '');
    $('##company_id').val(c.company_id);
    $('##companyDropdown').addClass('d-none');
    $('##companyInfo').removeClass('d-none');
    /* Stok seçimini sıfırla */
    clearStockSelection();
    /* Risk bilgilerini çek */
    $.ajax({
        url:    '/company/cfc/company.cfc',
        method: 'GET',
        data:   { method: 'getCompanyRisk', company_id: c.company_id },
        dataType: 'json',
        success: function(res) {
            var d = res.data || res;
            if (d.paymethod_id) {
                $('##paymethod_id').val(d.paymethod_id);
                $('##ship_method').val(d.ship_method || 0);
                var label = [];
                if (d.paymethod_name)  label.push('Ödeme: ' + escHtml(d.paymethod_name));
                if (d.ship_method_name) label.push('Sevk: ' + escHtml(d.ship_method_name));
                $('##companyRiskInfo').html(label.join(' &nbsp;|&nbsp; '));
            } else {
                $('##companyRiskInfo').text('Risk bilgisi alınamadı');
            }
        },
        error: function() { $('##companyRiskInfo').text('Risk bilgisi yüklenemedi'); }
    });
    /* Firmaya bağlı stokları yükle */
    loadStocksByCompany(c.company_id);
}

function loadStocksByCompany(companyId) {
    var searchInput = document.getElementById('stockSearch');
    var infoEl      = document.getElementById('stockLoadingInfo');
    searchInput.disabled = true;
    searchInput.placeholder = 'Stoklar yükleniyor...';
    infoEl.classList.remove('d-none');
    $.ajax({
        url:      '/product/cfc/product.cfc?method=getStocksByCompany',
        method:   'GET',
        data:     { company_id: companyId },
        dataType: 'json',
        success: function(res) {
            infoEl.classList.add('d-none');
            if (res.success && res.data) {
                allStocks = res.data;
                searchInput.disabled = false;
                searchInput.placeholder = 'Stok adı, kodu veya barkod...';
                if (!allStocks.length) {
                    searchInput.placeholder = 'Bu firmaya bağlı stok bulunamadı';
                }
            } else {
                allStocks = [];
                searchInput.placeholder = 'Stok yüklenemedi';
            }
        },
        error: function() {
            infoEl.classList.add('d-none');
            allStocks = [];
            searchInput.disabled = false;
            searchInput.placeholder = 'Stok yüklenemedi';
        }
    });
}

/* ─── Stok arama ─── */
function showStockDropdown(term) {
    var container = document.getElementById('stockSearchDropdown');
    if (!term || term.length < 2) { container.classList.add('d-none'); return; }
    term = term.toLowerCase();
    var results = allStocks.filter(function(s) {
        return (s.product_name && s.product_name.toLowerCase().includes(term)) ||
               (s.stock_code   && s.stock_code.toLowerCase().includes(term))   ||
               (s.barcod       && s.barcod.toLowerCase().includes(term))        ||
               (s.product_code && s.product_code.toLowerCase().includes(term));
    }).slice(0, 25);
    container.innerHTML = '';
    if (!results.length) {
        container.innerHTML = '<div class="search-item text-muted">Sonuç bulunamadı</div>';
        container.classList.remove('d-none'); return;
    }
    results.forEach(function(s) {
        var div = document.createElement('div');
        div.className = 'search-item';
        div.innerHTML = '<div>' + escHtml(s.product_name) + '</div>' +
                        '<div class="item-code">' + escHtml(s.stock_code) +
                        (s.barcod ? ' · Barkod: ' + escHtml(s.barcod) : '') +
                        (s.property ? ' · ' + escHtml(s.property) : '') + '</div>';
        div.addEventListener('click', function() {
            container.classList.add('d-none');
            selectStock(s);
        });
        container.appendChild(div);
    });
    container.classList.remove('d-none');
}

function selectStock(stock) {
    selStockId = stock.stock_id;
    document.getElementById('selected_stock_id').value  = stock.stock_id;
    document.getElementById('selected_product_id').value = stock.product_id || 0;
    document.getElementById('stockSearch').value         = stock.product_name +
        (stock.stock_code ? ' — ' + stock.stock_code : '');
    document.getElementById('selectedStockLabel').textContent = stock.product_name +
        (stock.stock_code  ? ' — ' + stock.stock_code  : '') +
        (stock.property    ? ' (' + stock.property + ')' : '');
    document.getElementById('selectedStockCard').classList.remove('d-none');
    document.getElementById('stockEmptyState').classList.add('d-none');
    /* Kaydet butonunu aktif et */
    var btn = document.getElementById('saveBtn');
    btn.disabled = false;
    btn.removeAttribute('title');

    /* Birimleri yükle */
    loadUnits(stock.product_id, stock.product_unit_id);

    /* Rafları yükle */
    if (paramLocId > 0) {
        loadRaf(stock.stock_id, paramLocId);
    }
}

function clearStockSelection() {
    selStockId = 0;
    document.getElementById('selected_stock_id').value  = '0';
    document.getElementById('selected_product_id').value = '0';
    document.getElementById('stockSearch').value         = '';
    document.getElementById('selectedStockCard').classList.add('d-none');
    document.getElementById('stockEmptyState').classList.remove('d-none');
    document.getElementById('stock_unit').innerHTML  = '<option value="">-- Birim --</option>';
    document.getElementById('stock_raf').innerHTML   = '<option value="0">-- Raf Seçin --</option>';
    document.getElementById('stock_raf_id').value    = '0';
    document.getElementById('stock_raf_code').value  = '';    /* Kaydet butonunu devre dışı bırak */
    var btn = document.getElementById('saveBtn');
    btn.disabled = true;
    btn.title = 'Önce stok seçin';}

function loadUnits(productId, defaultUnitId) {
    var sel = document.getElementById('stock_unit');
    sel.innerHTML = '<option value="">Yükleniyor...</option>';
    $.ajax({
        url:      '/product/cfc/product.cfc?method=getUnitsByProduct',
        method:   'GET',
        data:     { product_id: productId },
        dataType: 'json',
        success: function(res) {
            sel.innerHTML = '<option value="">-- Birim Seçin --</option>';
            if (res.success && res.data && res.data.length) {
                res.data.forEach(function(u) {
                    var label = u.main_unit + (u.add_unit ? ' / ' + u.add_unit : '');
                    var opt   = document.createElement('option');
                    opt.value = u.product_unit_id;
                    opt.textContent = label;
                    opt.dataset.unitName = u.main_unit;
                    if (u.product_unit_id == defaultUnitId || (!defaultUnitId && u.is_main)) {
                        opt.selected = true;
                        document.getElementById('stock_unit_id').value   = u.product_unit_id;
                        document.getElementById('stock_unit_name').value = u.main_unit;
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
        var o = sel.options[sel.selectedIndex];
        document.getElementById('stock_unit_id').value   = o ? o.value         : '0';
        document.getElementById('stock_unit_name').value = o ? (o.dataset.unitName || o.textContent) : '';
    };
}

function loadRaf(stockId, locationId) {
    var sel = document.getElementById('stock_raf');
    sel.innerHTML = '<option value="0">Yükleniyor...</option>';
    document.getElementById('stock_raf_id').value   = '0';
    document.getElementById('stock_raf_code').value = '';
    $.ajax({
        url:      '/department/form/get_shelves_for_product.cfm',
        method:   'GET',
        data:     { stock_id: stockId, location_id: locationId },
        dataType: 'json',
        success: function(res) {
            sel.innerHTML = '<option value="0">-- Raf Seçin --</option>';
            if (res.success && res.data && res.data.length) {
                res.data.forEach(function(sh) {
                    var opt = document.createElement('option');
                    opt.value = sh.product_place_id;
                    opt.textContent = sh.label || sh.shelf_code;
                    opt.dataset.shelfCode = sh.shelf_code;
                    sel.appendChild(opt);
                });
                if (res.data.length === 1) {
                    sel.selectedIndex = 1;
                    document.getElementById('stock_raf_id').value   = res.data[0].product_place_id;
                    document.getElementById('stock_raf_code').value = res.data[0].shelf_code || '';
                }
            } else {
                sel.innerHTML = '<option value="0">-- Raf tanımlı yok --</option>';
            }
        },
        error: function() { sel.innerHTML = '<option value="0">-- Raf yüklenemedi --</option>'; }
    });
    sel.onchange = function() {
        var o = sel.options[sel.selectedIndex];
        document.getElementById('stock_raf_id').value   = o ? o.value : '0';
        document.getElementById('stock_raf_code').value = o ? (o.dataset.shelfCode || '') : '';
    };
}

/* ─── Kaydet ─── */
function saveShip() {
    var companyId = parseInt(document.getElementById('company_id').value) || 0;
    if (!companyId) {
        alert('Lütfen firma seçin.');
        document.getElementById('companySearch').focus();
        return;
    }
    var stockId = parseInt(document.getElementById('selected_stock_id').value) || 0;
    if (!stockId) {
        alert('Lütfen stok seçin.');
        document.getElementById('stockSearch').focus();
        return;
    }
    var today     = new Date();
    var todayDate = today.toISOString().slice(0, 10);
    var todayDT   = todayDate + 'T' + today.toTimeString().slice(0, 5);

    var unitSel   = document.getElementById('stock_unit');
    var unitId    = parseInt(document.getElementById('stock_unit_id').value)  || 0;
    var unitName  = document.getElementById('stock_unit_name').value || (unitSel.options[unitSel.selectedIndex] ? unitSel.options[unitSel.selectedIndex].dataset.unitName || unitSel.options[unitSel.selectedIndex].textContent : '');
    var rafId     = parseInt(document.getElementById('stock_raf_id').value)   || 0;
    var rafCode   = document.getElementById('stock_raf_code').value || '';

    var stockLabel = document.getElementById('selectedStockLabel').textContent;
    var productId  = parseInt(document.getElementById('selected_product_id').value) || 0;

    var ucretliSel   = document.querySelector('input[name="hk_ucretli"]:checked');
    var hamBoyaliSel = document.querySelector('input[name="hk_ham_boyali"]:checked');

    var row = {
        stock_id:     stockId,
        product_id:   productId,
        name_product: stockLabel,
        price:        0,
        amount:       parseFloat(document.getElementById('hk_metre').value) || 0,
        amount2:      parseFloat(document.getElementById('hk_kg').value)    || 0,
        unit:         unitName,
        unit_id:      unitId,
        tax:          0,
        discount:     0,
        discounttotal:0,
        grosstotal:   0,
        nettotal:     0,
        taxtotal:     0,
        lot_no:       '',
        giris_raf_id: rafId,
        giris_raf_code: rafCode,
        cikis_raf_id: 0,
        cikis_raf_code: ''
    };

    var data = {
        ship_id:       parseInt(document.getElementById('ship_id').value) || 0,
        purchase_sales: 'false',
        ship_type:      '5',
        ship_number:    document.getElementById('ship_number').value,
        serial_number:  '',
        ship_date:      todayDT,
        deliver_date:   todayDate,
        company_id:     companyId,
        paymethod_id:   parseInt(document.getElementById('paymethod_id').value) || 0,
        ship_method:    parseInt(document.getElementById('ship_method').value)  || 0,
        location_in:    parseInt(document.getElementById('location_in').value)  || 0,
        location_out:   0,
        ship_status:    document.getElementById('ship_status').checked ? '1' : '0',
        ref_no:         document.getElementById('ref_no').value,
        ship_detail:    document.getElementById('ship_detail').value,
        grosstotal:     0,
        discounttotal:  0,
        nettotal:       0,
        taxtotal:       0,
        hk_metre:       document.getElementById('hk_metre').value     || '',
        hk_kg:          document.getElementById('hk_kg').value        || '',
        hk_top_adedi:   document.getElementById('hk_top_adedi').value || '',
        hk_h_gramaj:    document.getElementById('hk_h_gramaj').value  || '',
        hk_gr_mtul:     document.getElementById('hk_gr_mtul').value   || '',
        hk_ucretli:     ucretliSel   ? ucretliSel.value   : 'true',
        hk_ham_boyali:  hamBoyaliSel ? hamBoyaliSel.value : 'true',
        rows:           JSON.stringify([row])
    };

    var btn = document.getElementById('saveBtn');
    btn.disabled = true;
    btn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Kaydediliyor...';

    $.ajax({
        url:      '/ship/form/save_ship.cfm',
        method:   'POST',
        data:     data,
        dataType: 'json',
        success: function(res) {
            if (res.success) {
                var newId = res.ship_id || parseInt(document.getElementById('ship_id').value) || 0;
                if (!editShipId && newId) {
                    window.location.href = 'index.cfm?fuseaction=ship.add_giris_fis&ship_id=' + newId + '&location_id=' + paramLocId;
                } else {
                    btn.disabled = false;
                    btn.innerHTML = '<i class="fas fa-save me-2"></i>Güncelle';
                    alert('Kaydedildi!');
                }
            } else {
                btn.disabled = false;
                btn.innerHTML = '<i class="fas fa-save me-2"></i>#(editMode ? "Güncelle" : "Kaydet")#';
                alert('Hata: ' + (res.message || 'Bilinmeyen hata'));
            }
        },
        error: function() {
            btn.disabled = false;
            btn.innerHTML = '<i class="fas fa-save me-2"></i>#(editMode ? "Güncelle" : "Kaydet")#';
            alert('Sunucu hatası!');
        }
    });
}

function deleteShipForm() {
    var ship_id = parseInt(document.getElementById('ship_id').value) || 0;
    if (!ship_id || !confirm('Bu irsaliyeyi silmek istediğinizden emin misiniz?')) return;
    $.ajax({
        url: '/ship/form/save_ship.cfm', method: 'POST',
        data: { ship_id: ship_id, action: 'delete' }, dataType: 'json',
        success: function(res) {
            if (res.success) window.location.href = 'index.cfm?fuseaction=ship.list_ship';
            else alert('Silme hatası: ' + (res.message || ''));
        }
    });
}

function escHtml(str) {
    return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

window.addEventListener('load', function(){

    /* Firma arama */
    var companySearch = document.getElementById('companySearch');
    var companyDd     = document.getElementById('companyDropdown');
    companySearch.addEventListener('focus',  function(){ loadCompanies(); });
    companySearch.addEventListener('input',  function(){
        var q = this.value.toLowerCase().trim();
        companyDd.innerHTML = '';
        if (!q) { companyDd.classList.add('d-none'); return; }
        var matches = allCompanies.filter(function(c){
            return (c.display_name||'').toLowerCase().includes(q);
        }).slice(0, 10);
        if (!matches.length) { companyDd.classList.add('d-none'); return; }
        matches.forEach(function(c){
            var div = document.createElement('div');
            div.className = 'search-item';
            div.textContent = c.display_name || '';
            div.addEventListener('click', function(){ selectCompany(c); });
            companyDd.appendChild(div);
        });
        companyDd.classList.remove('d-none');
    });
    loadCompanies();

    /* Stok arama */
    var stockSearch = document.getElementById('stockSearch');
    stockSearch.addEventListener('input', function(){ showStockDropdown(this.value); });

    /* Dropdown dışına tıklama */
    document.addEventListener('click', function(e){
        if (!companySearch.contains(e.target) && !companyDd.contains(e.target))
            companyDd.classList.add('d-none');
        var sDd = document.getElementById('stockSearchDropdown');
        if (!stockSearch.contains(e.target) && !sDd.contains(e.target))
            sDd.classList.add('d-none');
    });

    /* Edit modunda stok/birim/raf yükle */
    if (selStockId > 0) {
        var existingStock = allStocks.find(function(s){ return s.stock_id == selStockId; });
        if (existingStock) {
            loadUnits(existingStock.product_id, #selUnitId#);
            if (paramLocId > 0) {
                loadRaf(selStockId, paramLocId);
            }
        }
    }
});
</script>
</cfoutput>