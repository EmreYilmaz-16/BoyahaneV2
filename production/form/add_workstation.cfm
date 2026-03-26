<cfprocessingdirective pageEncoding="utf-8">

<cfset editMode = isDefined("url.station_id") AND isNumeric(url.station_id) AND val(url.station_id) gt 0>
<cfset currentId  = editMode ? val(url.station_id) : 0>

<cfif editMode>
    <cfquery name="getRec" datasource="boyahane">
        SELECT * FROM workstations
        WHERE station_id = <cfqueryparam value="#currentId#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfif NOT getRec.recordCount>
        <cfset editMode = false>
        <cfset currentId  = 0>
    </cfif>
</cfif>

<!--- İstasyon-ürün ilişkileri --->
<cfif editMode>
    <cfquery name="getWsProducts" datasource="boyahane">
        SELECT wp.ws_p_id, wp.ws_id, wp.stock_id, wp.capacity,
               wp.production_time, wp.setup_time, wp.operation_type_id,
               COALESCE(s.stock_code,'')        AS stock_code,
               COALESCE(p.product_name,'')      AS product_name,
               COALESCE(ot.operation_type,'')   AS operation_type_name
        FROM workstations_products wp
        LEFT JOIN stocks s       ON wp.stock_id          = s.stock_id
        LEFT JOIN product p      ON s.product_id         = p.product_id
        LEFT JOIN operation_types ot ON wp.operation_type_id = ot.operation_type_id
        WHERE wp.ws_id = <cfqueryparam value="#currentId#" cfsqltype="cf_sql_integer">
        ORDER BY wp.ws_p_id
    </cfquery>
</cfif>

<!--- Üst istasyon listesi --->
<cfquery name="getParentStations" datasource="boyahane">
    SELECT station_id, station_name
    FROM workstations
    <cfif editMode>WHERE station_id <> <cfqueryparam value="#currentId#" cfsqltype="cf_sql_integer"></cfif>
    ORDER BY station_name
</cfquery>
<cfset parentStArr = []>
<cfloop query="getParentStations">
    <cfset arrayAppend(parentStArr, { "station_id": val(station_id), "station_name": station_name ?: "" })>
</cfloop>

<!--- Departman listesi --->
<cfquery name="getDepts" datasource="boyahane">
    SELECT department_id, department_head
    FROM department
    ORDER BY department_head
</cfquery>
<cfset deptsArr = []>
<cfloop query="getDepts">
    <cfset arrayAppend(deptsArr, { "department_id": val(department_id), "department_head": department_head ?: "" })>
</cfloop>

<!--- Şirket (dış kaynak) listesi --->
<cfquery name="getCompanies" datasource="boyahane">
    SELECT company_id, COALESCE(nickname, fullname, member_code, CAST(company_id AS VARCHAR)) AS company_name
    FROM company
    WHERE company_status = true
    ORDER BY company_name
</cfquery>
<cfset compArr = []>
<cfloop query="getCompanies">
    <cfset arrayAppend(compArr, { "company_id": val(company_id), "company_name": company_name ?: "" })>
</cfloop>

<!--- Stok listesi --->
<cfquery name="getStocks" datasource="boyahane">
    SELECT s.stock_id, s.stock_code,
           COALESCE(p.product_name,'') AS product_name
    FROM stocks s
    LEFT JOIN product p ON s.product_id = p.product_id
    WHERE s.stock_status = true
    ORDER BY s.stock_code
</cfquery>
<cfset stocksArr = []>
<cfloop query="getStocks">
    <cfset arrayAppend(stocksArr, {
        "stock_id"    : val(stock_id),
        "stock_code"  : stock_code   ?: "",
        "product_name": product_name ?: "",
        "label"       : stock_code & (len(product_name) ? " — " & product_name : "")
    })>
</cfloop>

<!--- Operasyon tipleri listesi --->
<cfquery name="getOpTypes" datasource="boyahane">
    SELECT operation_type_id, operation_type
    FROM operation_types
    WHERE COALESCE(operation_status, true) = true
    ORDER BY operation_type
</cfquery>
<cfset opTypesArr = []>
<cfloop query="getOpTypes">
    <cfset arrayAppend(opTypesArr, { "operation_type_id": val(operation_type_id), "operation_type": operation_type ?: "" })>
</cfloop>

<!--- Mevcut değerler --->
<cfset fName     = editMode ? (getRec.station_name     ?: "") : "">
<cfset fDept     = editMode ? (isNumeric(getRec.department) ? val(getRec.department) : 0) : 0>
<cfset fActive   = editMode ? (getRec.active eq true OR getRec.active eq "true") : true>
<cfset fCapacity = editMode ? (isNumeric(getRec.capacity) ? val(getRec.capacity) : 0) : 0>
<cfset fCost     = editMode ? (isNumeric(getRec.cost) ? val(getRec.cost) : 0) : 0>
<cfset fCostMon  = editMode ? (getRec.cost_money ?: "") : "">
<cfset fOutsrc   = editMode ? (isNumeric(getRec.outsource_partner) ? val(getRec.outsource_partner) : 0) : 0>
<cfset fEmpNum   = editMode ? (isNumeric(getRec.employee_number) ? val(getRec.employee_number) : 0) : 0>
<cfset fComment   = editMode ? (getRec.comment ?: "") : "">
<cfset fUpStation = editMode ? (isNumeric(getRec.up_station) ? val(getRec.up_station) : 0) : 0>

<!--- wp array --->
<cfset wpArr = []>
<cfif editMode AND isDefined("getWsProducts") AND getWsProducts.recordCount>
    <cfloop query="getWsProducts">
        <cfset arrayAppend(wpArr, {
            "ws_p_id"           : val(ws_p_id),
            "ws_id"             : val(ws_id),
            "stock_id"          : val(stock_id),
            "stock_code"        : stock_code          ?: "",
            "product_name"      : product_name        ?: "",
            "capacity"          : isNumeric(capacity) ? val(capacity) : 0,
            "production_time"   : isNumeric(production_time) ? val(production_time) : 0,
            "setup_time"        : isNumeric(setup_time) ? val(setup_time) : 0,
            "operation_type_id" : isNumeric(operation_type_id) ? val(operation_type_id) : 0,
            "operation_type_name": operation_type_name ?: ""
        })>
    </cfloop>
</cfif>

<cfif NOT structKeyExists(request,"jQueryLoaded")>
    <script src="https://code.jquery.com/jquery-3.7.1.min.js" integrity="sha256-/JqT3SQfawRcv/BIHPThkBvs0OEvtFFmqPF/lYI/Cxo=" crossorigin="anonymous"></script>
    <cfset request.jQueryLoaded = true>
</cfif>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-industry"></i></div>
        <div class="page-header-title">
            <h1><cfoutput>#editMode ? "İstasyon Düzenle" : "Yeni İş İstasyonu"#</cfoutput></h1>
            <p>İş istasyonu bilgileri ve bağlı ürünler</p>
        </div>
    </div>
    <button class="btn-back" onclick="window.location.href='index.cfm?fuseaction=production.list_workstations'">
        <i class="fas fa-arrow-left"></i>Listeye Dön
    </button>
</div>

<div class="px-3 pb-5">
    <div class="grid-card mb-3">
        <div class="grid-card-header">
            <div class="grid-card-header-title">
                <i class="fas fa-<cfoutput>#editMode ? "edit" : "plus-circle"#</cfoutput>"></i>
                <cfoutput>#editMode ? "İstasyon Güncelle" : "Yeni İstasyon Ekle"#</cfoutput>
            </div>
        </div>
        <div class="card-body p-3">
            <form id="stationForm" autocomplete="off">
                <cfoutput><input type="hidden" id="station_id" value="#currentId#"></cfoutput>

                <div class="row g-3">
                    <div class="col-md-5">
                        <label class="form-label">İstasyon Adı <span class="text-danger">*</span></label>
                        <cfoutput><input type="text" class="form-control" id="f_station_name" value="#htmlEditFormat(fName)#" placeholder="İstasyon adı..." required></cfoutput>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label">Departman</label>
                        <select class="form-select" id="f_department">
                            <option value="0">Seçiniz...</option>
                            <cfoutput>
                            <cfloop array="#deptsArr#" index="d">
                                <option value="#d.department_id#" <cfif fDept eq d.department_id>selected</cfif>>#htmlEditFormat(d.department_head)#</option>
                            </cfloop>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-3 d-flex align-items-end">
                        <div class="form-check form-switch ms-1">
                            <cfoutput><input class="form-check-input" type="checkbox" id="f_active" #fActive ? "checked" : ""#></cfoutput>
                            <label class="form-check-label" for="f_active">Aktif</label>
                        </div>
                    </div>
                </div>

                <div class="row g-3 mt-1">
                    <div class="col-md-3">
                        <label class="form-label">Kapasite</label>
                        <cfoutput><input type="number" min="0" class="form-control" id="f_capacity" value="#fCapacity#"></cfoutput>
                    </div>
                    <div class="col-md-3">
                        <label class="form-label">Maliyet</label>
                        <cfoutput><input type="number" step="0.01" class="form-control" id="f_cost" value="#fCost#"></cfoutput>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Para Birimi</label>
                        <select class="form-select" id="f_cost_money">
                            <option value="">-</option>
                            <cfoutput>
                            <option value="TL"  #fCostMon eq "TL"  ? "selected" : ""#>TL</option>
                            <option value="USD" #fCostMon eq "USD" ? "selected" : ""#>USD</option>
                            <option value="EUR" #fCostMon eq "EUR" ? "selected" : ""#>EUR</option>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Çalışan Sayısı</label>
                        <cfoutput><input type="number" min="0" class="form-control" id="f_employee_number" value="#fEmpNum#"></cfoutput>
                    </div>
                </div>

                <div class="row g-3 mt-1">
                    <div class="col-md-6">
                        <label class="form-label">Üst İstasyon</label>
                        <select class="form-select" id="f_up_station">
                            <option value="0">Yok (Ana İstasyon)</option>
                            <cfoutput>
                            <cfloop array="#parentStArr#" index="ps">
                                <option value="#ps.station_id#" <cfif fUpStation eq ps.station_id>selected</cfif>>#htmlEditFormat(ps.station_name)#</option>
                            </cfloop>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Dış Kaynak (Firma)</label>
                        <select class="form-select" id="f_outsource_partner">
                            <option value="0">-</option>
                            <cfoutput>
                            <cfloop array="#compArr#" index="co">
                                <option value="#co.company_id#" <cfif fOutsrc eq co.company_id>selected</cfif>>#htmlEditFormat(co.company_name)#</option>
                            </cfloop>
                            </cfoutput>
                        </select>
                    </div>
                    <div class="col-md-6">
                        <label class="form-label">Açıklama</label>
                        <cfoutput><input type="text" class="form-control" id="f_comment" value="#htmlEditFormat(fComment)#"></cfoutput>
                    </div>
                </div>

                <div class="row g-3 mt-1">

                <div class="row mt-3">
                    <div class="col-12 d-flex gap-2">
                        <button type="submit" class="btn-save" id="btnSave">
                            <i class="fas fa-save me-1"></i>Kaydet
                        </button>
                        <button type="button" class="btn-back" onclick="window.location.href='index.cfm?fuseaction=production.list_workstations'">
                            <i class="fas fa-times me-1"></i>İptal
                        </button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <!--- ─── Ürün Tanımlamaları Alt Bölümü ─── --->
    <cfif editMode>
    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-boxes"></i>Bu İstasyonda Üretilen Ürünler</div>
            <button class="btn btn-sm btn-success" onclick="showAddWpRow()">
                <i class="fas fa-plus me-1"></i>Ürün Ekle
            </button>
        </div>

        <!--- Ürün ekleme satırı --->
        <div id="addWpRow" class="card-body border-bottom px-3 py-2" style="display:none;">
            <div class="row g-2 align-items-end">
                <div class="col-md-4">
                    <label class="form-label small mb-1">Stok</label>
                    <select class="form-select form-select-sm" id="wp_stock_id">
                        <option value="0">Seçiniz...</option>
                        <cfoutput>
                        <cfloop array="#stocksArr#" index="s">
                            <option value="#s.stock_id#">#htmlEditFormat(s.label)#</option>
                        </cfloop>
                        </cfoutput>
                    </select>
                </div>
                <div class="col-md-3">
                    <label class="form-label small mb-1">Operasyon Tipi</label>
                    <select class="form-select form-select-sm" id="wp_operation_type_id">
                        <option value="0">-</option>
                        <cfoutput>
                        <cfloop array="#opTypesArr#" index="ot">
                            <option value="#ot.operation_type_id#">#htmlEditFormat(ot.operation_type)#</option>
                        </cfloop>
                        </cfoutput>
                    </select>
                </div>
                <div class="col-md-1">
                    <label class="form-label small mb-1">Kapasite</label>
                    <input type="number" step="0.01" class="form-control form-control-sm" id="wp_capacity" placeholder="0">
                </div>
                <div class="col-md-1">
                    <label class="form-label small mb-1">Üretim S.</label>
                    <input type="number" step="0.01" class="form-control form-control-sm" id="wp_production_time" placeholder="0">
                </div>
                <div class="col-md-1">
                    <label class="form-label small mb-1">Hazırlık S.</label>
                    <input type="number" step="0.01" class="form-control form-control-sm" id="wp_setup_time" placeholder="0">
                </div>
                <div class="col-md-2 d-flex gap-1">
                    <button class="btn btn-sm btn-primary flex-fill" onclick="saveWpRow()"><i class="fas fa-save"></i> Kaydet</button>
                    <button class="btn btn-sm btn-secondary" onclick="hideAddWpRow()"><i class="fas fa-times"></i></button>
                </div>
            </div>
        </div>

        <div class="card-body p-2">
            <div id="wpGrid"></div>
        </div>
    </div>
    </cfif>
</div>

<cfoutput>
<script>
var wpData      = #serializeJSON(wpArr)#;
var stocksData  = #serializeJSON(stocksArr)#;
var opTypesData = #serializeJSON(opTypesArr)#;
var stationId   = #currentId#;

window.addEventListener('load', function(){
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');
    <cfif editMode>
    initWpGrid();
    </cfif>
});

<cfif editMode>
function initWpGrid() {
    if (!$ || !$.fn.dxDataGrid) return;
    var $g = $('##wpGrid');
    if ($g.data('dxDataGrid')) {
        $g.dxDataGrid('instance').option('dataSource', wpData);
        return;
    }
    $g.dxDataGrid({
        dataSource: wpData,
        showBorders: true, showRowLines: true, showColumnLines: true,
        rowAlternationEnabled: true, columnAutoWidth: true,
        paging: { enabled: false },
        noDataText: 'Bu istasyon için ürün tanımlanmamış.',
        columns: [
            { dataField:'stock_code',          caption:'Stok Kodu',     width:170,
                cellTemplate: function(c,o){ $('<span>').addClass('badge bg-light text-dark border').text(o.value||'-').appendTo(c); }
            },
            { dataField:'product_name',        caption:'Ürün Adı',      minWidth:200 },
            { dataField:'operation_type_name', caption:'Operasyon',     width:180 },
            { dataField:'capacity',            caption:'Kapasite',      width:90,  alignment:'right', dataType:'number' },
            { dataField:'production_time',     caption:'Üretim Süresi', width:110, alignment:'right', dataType:'number' },
            { dataField:'setup_time',          caption:'Hazırlık',      width:90,  alignment:'right', dataType:'number' },
            {
                caption:'Sil', width:65, alignment:'center', allowSorting:false, allowFiltering:false,
                cellTemplate: function(c,o){
                    $('<button>').addClass('btn btn-sm btn-outline-danger').html('<i class="fas fa-trash"></i>')
                        .on('click', function(){ deleteWpRow(o.data.ws_p_id); }).appendTo(c);
                }
            }
        ]
    });
}

function showAddWpRow(){ document.getElementById('addWpRow').style.display=''; $('##wp_stock_id').val('0'); }
function hideAddWpRow(){ document.getElementById('addWpRow').style.display='none'; }

function saveWpRow(){
    var sid = parseInt($('##wp_stock_id').val());
    if (!sid || sid <= 0){ DevExpress.ui.notify('Stok seçiniz.','error',2500); return; }
    $.post('/production/form/save_ws_product.cfm', {
        ws_p_id           : 0,
        ws_id             : stationId,
        stock_id          : sid,
        operation_type_id : $('##wp_operation_type_id').val() || 0,
        capacity          : $('##wp_capacity').val() || 0,
        production_time   : $('##wp_production_time').val() || 0,
        setup_time        : $('##wp_setup_time').val() || 0
    }, function(res){
        if (res && res.success) {
            var s = stocksData.find(function(x){ return x.stock_id == sid; });
            var o = opTypesData.find(function(x){ return x.operation_type_id == parseInt($('##wp_operation_type_id').val()); });
            wpData.push({
                ws_p_id: res.ws_p_id, ws_id: stationId,
                stock_id: sid,
                stock_code:  s ? s.stock_code  : '',
                product_name: s ? s.product_name : '',
                operation_type_id: o ? o.operation_type_id : 0,
                operation_type_name: o ? o.operation_type : '',
                capacity:         parseFloat($('##wp_capacity').val()) || 0,
                production_time:  parseFloat($('##wp_production_time').val()) || 0,
                setup_time:       parseFloat($('##wp_setup_time').val()) || 0
            });
            DevExpress.ui.notify('Ürün eklendi.','success',2000);
            hideAddWpRow();
            initWpGrid();
        } else {
            DevExpress.ui.notify((res && res.message)||'Kayıt başarısız.','error',3000);
        }
    },'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.','error',3000); });
}

function deleteWpRow(wpId){
    DevExpress.ui.dialog.confirm('Bu ürün tanımlamasını silmek istiyor musunuz?','Silme Onayı').then(function(ok){
        if (!ok) return;
        $.post('/production/form/delete_ws_product.cfm',{ws_p_id:wpId},function(res){
            if (res && res.success) {
                wpData = wpData.filter(function(x){ return x.ws_p_id != wpId; });
                DevExpress.ui.notify('Silindi.','success',2000);
                initWpGrid();
            } else {
                DevExpress.ui.notify((res && res.message)||'Silme başarısız.','error',3000);
            }
        },'json').fail(function(){ DevExpress.ui.notify('Sunucu hatası.','error',3000); });
    });
}
</cfif>

$(document).ready(function(){
    $('##stationForm').on('submit', function(e){
        e.preventDefault();
        var name = $('##f_station_name').val().trim();
        if (!name){ DevExpress.ui.notify('İstasyon adı zorunludur.','error',3000); return; }

        var btn = $('##btnSave').prop('disabled',true).html('<i class="fas fa-spinner fa-spin me-1"></i>Kaydediliyor...');

        $.ajax({
            url: '/production/form/save_workstation.cfm',
            method: 'POST',
            data: {
                station_id        : $('##station_id').val(),
                station_name      : name,
                department        : $('##f_department').val() || 0,
                active            : $('##f_active').is(':checked'),
                capacity          : $('##f_capacity').val() || 0,
                cost              : $('##f_cost').val() || 0,
                cost_money        : $('##f_cost_money').val(),
                outsource_partner : $('##f_outsource_partner').val() || 0,
                employee_number   : $('##f_employee_number').val() || 0,
                up_station        : $('##f_up_station').val() || 0,
                comment           : $('##f_comment').val()
            },
            dataType: 'json',
            success: function(res){
                if (res && res.success) {
                    DevExpress.ui.notify('İstasyon kaydedildi.','success',2500);
                    setTimeout(function(){
                        window.location.href = 'index.cfm?fuseaction=production.list_workstations&success=' + (res.mode||'added');
                    }, 900);
                } else {
                    DevExpress.ui.notify((res && res.message)||'Kayıt başarısız.','error',4000);
                    btn.prop('disabled',false).html('<i class="fas fa-save me-1"></i>Kaydet');
                }
            },
            error: function(){
                DevExpress.ui.notify('Sunucu hatası.','error',3000);
                btn.prop('disabled',false).html('<i class="fas fa-save me-1"></i>Kaydet');
            }
        });
    });
});
</script>
</cfoutput>
