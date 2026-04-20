<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getInspections" datasource="boyahane">
    SELECT qi.qc_inspection_id, qi.inspection_no, qi.inspection_type,
           qi.lot_no, qi.quantity, qi.sample_quantity,
           qi.inspection_date, qi.inspector_name,
           qi.result, qi.record_date,
           COALESCE(p.product_name,'') AS product_name,
           COALESCE(p.product_code,'') AS product_code,
           -- İrsaliye bağlantısı
           COALESCE(sh.ship_number,'') AS ship_number,
           -- Üretim emri bağlantısı
           COALESCE(po.p_order_no,'')  AS p_order_no,
           -- Şirket adı (irsaliyeden ya da üretim emrinden)
           COALESCE(sc.nickname, sc.fullname, poc.nickname, poc.fullname, '') AS company_name
    FROM qc_inspections qi
    LEFT JOIN product        p   ON qi.product_id  = p.product_id
    LEFT JOIN ship           sh  ON qi.ship_id      = sh.ship_id
    LEFT JOIN company        sc  ON sh.company_id   = sc.company_id
    LEFT JOIN production_orders po ON qi.p_order_id = po.p_order_id
    LEFT JOIN stocks         st  ON po.stock_id     = st.stock_id
    LEFT JOIN color_info     ci  ON st.stock_id     = ci.stock_id
    LEFT JOIN company        poc ON ci.company_id   = poc.company_id
    WHERE qi.is_active = true
    ORDER BY qi.qc_inspection_id DESC
</cfquery>

<cfset inspArr = []>
<cfloop query="getInspections">
    <cfset itLabel = ""><cfset itClass = ""
    ><cfset resLabel = ""><cfset resClass = "">
    <cfswitch expression="#inspection_type#">
        <cfcase value="1"><cfset itLabel="Giriş Kontrol">   <cfset itClass="bg-primary"></cfcase>
        <cfcase value="2"><cfset itLabel="Operasyon Kontrol"><cfset itClass="bg-warning text-dark"></cfcase>
        <cfcase value="3"><cfset itLabel="Final Kontrol">   <cfset itClass="bg-info"></cfcase>
        <cfdefaultcase><cfset itLabel="Diğer"><cfset itClass="bg-secondary"></cfdefaultcase>
    </cfswitch>
    <cfswitch expression="#result#">
        <cfcase value="1"><cfset resLabel="Kabul">           <cfset resClass="bg-success"></cfcase>
        <cfcase value="2"><cfset resLabel="Koşullu Kabul">   <cfset resClass="bg-warning text-dark"></cfcase>
        <cfcase value="3"><cfset resLabel="Ret">             <cfset resClass="bg-danger"></cfcase>
        <cfdefaultcase><cfset resLabel="Bekliyor"><cfset resClass="bg-secondary"></cfdefaultcase>
    </cfswitch>
    <cfset arrayAppend(inspArr, {
        "qc_inspection_id" : val(qc_inspection_id),
        "inspection_no"    : inspection_no    ?: "",
        "inspection_type"  : val(inspection_type),
        "it_label"         : itLabel,
        "it_class"         : itClass,
        "lot_no"           : lot_no           ?: "",
        "quantity"         : isNumeric(quantity) ? val(quantity) : 0,
        "sample_quantity"  : isNumeric(sample_quantity) ? val(sample_quantity) : 0,
        "inspection_date"  : isDate(inspection_date) ? dateFormat(inspection_date,"dd/mm/yyyy") & " " & timeFormat(inspection_date,"HH:mm") : "",
        "inspector_name"   : inspector_name   ?: "",
        "result"           : val(result),
        "res_label"        : resLabel,
        "res_class"        : resClass,
        "product_name"     : product_name     ?: "",
        "product_code"     : product_code     ?: "",
        "ship_number"      : ship_number      ?: "",
        "p_order_no"       : p_order_no       ?: "",
        "company_name"     : company_name     ?: "",
        "record_date"      : isDate(record_date) ? dateFormat(record_date,"dd/mm/yyyy") & " " & timeFormat(record_date,"HH:mm") : ""
    })>
</cfloop>

<!--- Özet istatistikler --->
<cfset totalInsp    = arrayLen(inspArr)>
<cfset totalKabul   = 0><cfset totalKos = 0><cfset totalRet = 0>
<cfloop array="#inspArr#" index="i">
    <cfif i.result eq 1><cfset totalKabul = totalKabul + 1>
    <cfelseif i.result eq 2><cfset totalKos = totalKos + 1>
    <cfelse><cfset totalRet = totalRet + 1>
    </cfif>
</cfloop>

<cfoutput>
<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-microscope"></i></div>
        <div class="page-header-title">
            <h1>Kalite Kontrol İşlemleri</h1>
            <p>Giriş, operasyon ve final kontrol muayeneleri</p>
        </div>
    </div>
    <button class="btn-add" onclick="addInspection()">
        <i class="fas fa-plus"></i>Yeni Muayene
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Muayene kaydedildi.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Muayene güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Muayene silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    </cfif>

    <!--- Özet Kartlar --->
    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="summary-card summary-card-blue">
                <div class="summary-icon"><i class="fas fa-microscope"></i></div>
                <div class="summary-info">
                    <div class="summary-value">#totalInsp#</div>
                    <div class="summary-label">Toplam Muayene</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-check-circle"></i></div>
                <div class="summary-info">
                    <div class="summary-value">#totalKabul#</div>
                    <div class="summary-label">Kabul</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-yellow">
                <div class="summary-icon"><i class="fas fa-exclamation-circle"></i></div>
                <div class="summary-info">
                    <div class="summary-value">#totalKos#</div>
                    <div class="summary-label">Koşullu Kabul</div>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-red">
                <div class="summary-icon"><i class="fas fa-times-circle"></i></div>
                <div class="summary-info">
                    <div class="summary-value">#totalRet#</div>
                    <div class="summary-label">Ret</div>
                </div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-body p-0">
            <div id="inspGrid"></div>
        </div>
    </div>
</div>

<div class="modal fade" id="deleteModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><i class="fas fa-exclamation-triangle text-warning me-2"></i>Muayeneyi Sil</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <p><strong id="deleteInspNo"></strong> numaralı muayeneyi silmek istediğinize emin misiniz?</p>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">İptal</button>
                <button type="button" class="btn btn-danger" id="confirmDeleteBtn">Sil</button>
            </div>
        </div>
    </div>
</div>

<script>
var inspData   = #serializeJSON(inspArr)#;
var deleteModal = null;
var deleteTargetId = 0;

$(function(){
    deleteModal = new bootstrap.Modal(document.getElementById('deleteModal'));

    new DevExpress.ui.dxDataGrid(document.getElementById('inspGrid'), {
        dataSource: inspData,
        keyExpr: 'qc_inspection_id',
        showBorders: true,
        showRowLines: true,
        rowAlternationEnabled: true,
        filterRow: { visible: true },
        headerFilter: { visible: true },
        searchPanel: { visible: true, width: 240 },
        paging: { pageSize: 25 },
        pager: { showPageSizeSelector: true, allowedPageSizes: [25,50,100] },
        columns: [
            { dataField: 'inspection_no',  caption: 'Muayene No', width: 150 },
            {
                dataField: 'it_label', caption: 'Tip', width: 160,
                cellTemplate: function(c,o){
                    $('<span>').addClass('badge ' + o.data.it_class).text(o.value).appendTo(c);
                }
            },
            { dataField: 'company_name',   caption: 'Cari',          minWidth: 150 },
            { dataField: 'product_name',   caption: 'Ürün',           minWidth: 150 },
            { dataField: 'lot_no',         caption: 'Lot No',         width: 120 },
            { dataField: 'quantity',       caption: 'Miktar',         width: 100, dataType: 'number' },
            { dataField: 'sample_quantity',caption: 'Numune',         width: 100, dataType: 'number' },
            { dataField: 'ship_number',    caption: 'İrsaliye',       width: 130 },
            { dataField: 'p_order_no',     caption: 'Ürt. Emri',      width: 130 },
            {
                dataField: 'res_label', caption: 'Sonuç', width: 140,
                cellTemplate: function(c,o){
                    $('<span>').addClass('badge ' + o.data.res_class).text(o.value).appendTo(c);
                }
            },
            { dataField: 'inspector_name', caption: 'Kontrolör',      width: 140 },
            { dataField: 'inspection_date',caption: 'Tarih',          width: 150 },
            {
                caption: 'İşlemler', width: 120, allowFiltering: false, allowSorting: false,
                cellTemplate: function(container, options) {
                    var d = options.data;
                    $('<button>').addClass('btn btn-sm btn-outline-primary me-1')
                        .html('<i class="fas fa-eye"></i>').attr('title','Detay')
                        .on('click', function(){ viewInspection(d.qc_inspection_id); })
                        .appendTo(container);
                    $('<button>').addClass('btn btn-sm btn-outline-danger')
                        .html('<i class="fas fa-trash"></i>').attr('title','Sil')
                        .on('click', function(){ confirmDelete(d.qc_inspection_id, d.inspection_no); })
                        .appendTo(container);
                }
            }
        ]
    });
});

function addInspection()  { window.location.href = 'index.cfm?fuseaction=quality.add_qc_inspection'; }
function viewInspection(id) { window.location.href = 'index.cfm?fuseaction=quality.view_qc_inspection&qc_inspection_id=' + id; }

function confirmDelete(id, no) {
    deleteTargetId = id;
    document.getElementById('deleteInspNo').textContent = no;
    deleteModal.show();
}

document.getElementById('confirmDeleteBtn').addEventListener('click', function(){
    if (!deleteTargetId) return;
    $.post('index.cfm?fuseaction=quality.delete_qc_inspection', { qc_inspection_id: deleteTargetId }, function(res){
        var r = typeof res === 'string' ? JSON.parse(res) : res;
        deleteModal.hide();
        if (r.success) {
            window.location.href = 'index.cfm?fuseaction=quality.list_qc_inspections&success=deleted';
        } else {
            alert('Hata: ' + (r.message || 'Silinemedi'));
        }
    });
});
</script>
</cfoutput>
