<cfprocessingdirective pageEncoding="utf-8">

<cfquery name="getGirisFisler" datasource="boyahane">
    SELECT
        s.ship_id,
        s.ship_number,
        s.ref_no,
        s.ship_detail,
        s.ship_status,
        s.is_ship_iptal,
        s.record_date,
        s.hk_metre,
        s.hk_kg,
        s.hk_top_adedi,
        s.hk_h_gramaj,
        s.hk_gr_mtul,
        s.hk_ucretli,
        s.hk_ham_boyali,
        COALESCE(c.nickname, c.fullname, '') AS company_name,
        c.company_id,
        COALESCE((
            SELECT p.product_name || ' — ' || st.stock_code
            FROM ship_row sr
            LEFT JOIN stocks st ON sr.stock_id = st.stock_id
            LEFT JOIN product p ON st.product_id = p.product_id
            WHERE sr.ship_id = s.ship_id
            ORDER BY sr.ship_row_id
            LIMIT 1
        ), '') AS urun_adi,
        COALESCE((
            SELECT COUNT(*) FROM orders o
            WHERE o.ref_no = s.ship_number
              AND s.ship_number <> ''
        ), 0) AS parti_count,
        COALESCE((
            SELECT SUM(orw.quantity)
            FROM orders o
            JOIN order_row orw ON o.order_id = orw.order_id
            WHERE o.ref_no = s.ship_number
              AND s.ship_number <> ''
              AND orw.product_id = (
                  SELECT sr2.product_id FROM ship_row sr2
                  WHERE sr2.ship_id = s.ship_id
                  ORDER BY sr2.ship_row_id LIMIT 1
              )
        ), 0) AS parti_metre
    FROM ship s
    LEFT JOIN company c ON s.company_id = c.company_id
    WHERE s.ship_type = 5
    ORDER BY s.ship_id DESC
</cfquery>


<cfset fisArr = []>
<cfloop query="getGirisFisler">
    <cfset arrayAppend(fisArr, {
        "ship_id":       ship_id,
        "ship_number":   ship_number ?: "",
        "company_name":  company_name ?: "",
        "company_id":    company_id ?: 0,
        "urun_adi":      urun_adi ?: "",
        "hk_metre":      isNumeric(hk_metre)     ? val(hk_metre)     : "",
        "hk_kg":         isNumeric(hk_kg)        ? val(hk_kg)        : "",
        "hk_top_adedi":  isNumeric(hk_top_adedi) ? val(hk_top_adedi) : "",
        "hk_h_gramaj":   isNumeric(hk_h_gramaj)  ? val(hk_h_gramaj)  : "",
        "hk_gr_mtul":    isNumeric(hk_gr_mtul)   ? val(hk_gr_mtul)   : "",
        "hk_ucretli":    hk_ucretli,
        "hk_ham_boyali": hk_ham_boyali,
        "ref_no":        ref_no ?: "",
        "ship_detail":   ship_detail ?: "",
        "ship_status":   ship_status ?: 1,
        "is_ship_iptal": is_ship_iptal,
        "record_date":   isDate(record_date) ? dateFormat(record_date, "dd/mm/yyyy") & " " & timeFormat(record_date, "HH:mm") : "",
        "parti_count":   val(parti_count),
        "parti_metre":   isNumeric(parti_metre) ? val(parti_metre) : 0,
        "kalan_metre":   (isNumeric(hk_metre) ? val(hk_metre) : 0) - (isNumeric(parti_metre) ? val(parti_metre) : 0)
    })>
</cfloop>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-dolly"></i></div>
        <div class="page-header-title">
            <h1>Ham Kumaş Girişleri</h1>
            <p>Tüm ham kumaş giriş fişleri</p>
        </div>
    </div>
    <button class="btn-add" onclick="addGirisFis()">
        <i class="fas fa-plus"></i>Yeni Giriş Fişi
    </button>
</div>

<div class="px-3">
    <cfif isDefined("url.success")>
        <cfoutput>
        <div class="alert alert-success alert-dismissible fade show mb-3">
            <i class="fas fa-check-circle me-2"></i>
            <cfif url.success eq "added"><strong>Başarılı!</strong> Giriş fişi oluşturuldu.
            <cfelseif url.success eq "updated"><strong>Başarılı!</strong> Giriş fişi güncellendi.
            <cfelseif url.success eq "deleted"><strong>Başarılı!</strong> Giriş fişi silindi.
            </cfif>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        </cfoutput>
    </cfif>

    <!--- Özet Kartlar --->
    <div class="row g-3 mb-3">
        <div class="col-md-3">
            <div class="summary-card summary-card-blue">
                <div class="summary-icon"><i class="fas fa-file-alt"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Fiş</span>
                    <span class="summary-value" id="sumTotal">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-green">
                <div class="summary-icon"><i class="fas fa-ruler-horizontal"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Metre</span>
                    <span class="summary-value" id="sumMetre">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-orange">
                <div class="summary-icon"><i class="fas fa-weight-hanging"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Kg</span>
                    <span class="summary-value" id="sumKg">-</span>
                </div>
            </div>
        </div>
        <div class="col-md-3">
            <div class="summary-card summary-card-red">
                <div class="summary-icon"><i class="fas fa-boxes"></i></div>
                <div class="summary-info">
                    <span class="summary-label">Toplam Top</span>
                    <span class="summary-value" id="sumTop">-</span>
                </div>
            </div>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-list"></i>Giriş Fişi Listesi</div>
            <span class="record-count" id="recordCount">Yükleniyor...</span>
        </div>
        <div class="card-body p-2">
            <div id="girisFisGrid"></div>
        </div>
    </div>
</div>

<cfoutput>
<style>
.summary-card { display:flex; align-items:center; gap:14px; padding:16px 20px; border-radius:10px; color:##fff; box-shadow:0 2px 10px rgba(0,0,0,.12); }
.summary-card-blue   { background:linear-gradient(135deg,##1a3a5c,##2563ab); }
.summary-card-green  { background:linear-gradient(135deg,##15803d,##22c55e); }
.summary-card-orange { background:linear-gradient(135deg,##92400e,##f59e0b); }
.summary-card-red    { background:linear-gradient(135deg,##991b1b,##ef4444); }
.summary-icon { font-size:1.8rem; opacity:.85; }
.summary-label { font-size:.75rem; opacity:.85; display:block; }
.summary-value { font-size:1.6rem; font-weight:700; display:block; }
</style>

<script>
var fisData = #serializeJSON(fisArr)#;

window.addEventListener('load', function() {
    if (typeof DevExpress !== 'undefined') DevExpress.localization.locale('tr');

    var totalMetre = fisData.reduce(function(a,r){ return a + (parseFloat(r.hk_metre)||0); }, 0);
    var totalKg    = fisData.reduce(function(a,r){ return a + (parseFloat(r.hk_kg)||0); }, 0);
    var totalTop   = fisData.reduce(function(a,r){ return a + (parseFloat(r.hk_top_adedi)||0); }, 0);
    document.getElementById('sumTotal').textContent = fisData.length;
    document.getElementById('sumMetre').textContent = totalMetre.toLocaleString('tr-TR', {minimumFractionDigits:2, maximumFractionDigits:2});
    document.getElementById('sumKg').textContent    = totalKg.toLocaleString('tr-TR',    {minimumFractionDigits:2, maximumFractionDigits:2});
    document.getElementById('sumTop').textContent   = totalTop.toLocaleString('tr-TR',   {minimumFractionDigits:0, maximumFractionDigits:0});

    if (typeof $ !== 'undefined' && $.fn.dxDataGrid) {
        $('##girisFisGrid').dxDataGrid({
            dataSource: fisData,
            showBorders: true, showRowLines: true, showColumnLines: true,
            rowAlternationEnabled: true, columnAutoWidth: true,
            allowColumnReordering: true, allowColumnResizing: true, columnResizingMode: 'widget',
            paging: { pageSize: 25 },
            pager: { visible:true, allowedPageSizes:[10,25,50,100], showPageSizeSelector:true, showNavigationButtons:true, showInfo:true, infoText:'Sayfa {0}/{1} ({2} kayıt)' },
            filterRow: { visible:true }, headerFilter: { visible:true },
            searchPanel: { visible:true, width:240, placeholder:'Ara...' },
            sorting: { mode:'multiple' },
            columnChooser: { enabled:true, mode:'select', title:'Sütun Seçimi' },
            export: { enabled:true, fileName:'giris_fisleri_' + new Date().toISOString().slice(0,10) },
            onRowDblClick: function(e) { openGirisFis(e.data.ship_id); },
            onContentReady: function(e) { document.getElementById('recordCount').textContent = e.component.totalCount() + ' kayıt'; },
            columns: [
                { dataField:'ship_id', caption:'ID', width:70, alignment:'center', dataType:'number', sortOrder:'desc' },
                { dataField:'ship_number', caption:'Fiş No', width:130,
                    cellTemplate: function(c,o) { $('<strong>').text(o.value||'-').appendTo(c); }
                },
                { dataField:'company_name', caption:'Firma', minWidth:160 },
                { dataField:'urun_adi', caption:'Ürün', minWidth:180,
                    cellTemplate: function(c,o) { $('<span>').addClass('small').text(o.value||'-').appendTo(c); }
                },
                { dataField:'hk_metre', caption:'Metre', width:100, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'hk_kg', caption:'Kg', width:100, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'hk_top_adedi', caption:'Top Adedi', width:95, alignment:'center', dataType:'number' },
                { dataField:'parti_metre', caption:'Partilenen (mt)', width:120, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2},
                    cellTemplate: function(c,o) {
                        var pm  = parseFloat(o.value) || 0;
                        var hkm = parseFloat(o.data.hk_metre) || 0;
                        var txt = pm.toLocaleString('tr-TR',{minimumFractionDigits:2,maximumFractionDigits:2});
                        $('<span>').text(txt)
                            .addClass(hkm > 0 && pm >= hkm ? 'text-success fw-semibold' : (pm > 0 ? 'text-warning fw-semibold' : 'text-muted'))
                            .appendTo(c);
                    }
                },
                { dataField:'kalan_metre', caption:'Kalan (mt)', width:110, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2},
                    cellTemplate: function(c,o) {
                        var km  = parseFloat(o.value) || 0;
                        var hkm = parseFloat(o.data.hk_metre) || 0;
                        var txt = (km > 0 ? km : 0).toLocaleString('tr-TR',{minimumFractionDigits:2,maximumFractionDigits:2});
                        $('<span>').text(txt)
                            .addClass(km > 0 ? 'text-danger fw-semibold' : 'text-muted')
                            .appendTo(c);
                    }
                },
                { caption:'Parti Durumu', width:150, alignment:'center', allowSorting:false, allowFiltering:false,
                    calculateCellValue: function(r) {
                        var pm = parseFloat(r.parti_metre) || 0;
                        var hm = parseFloat(r.hk_metre) || 0;
                        if (pm <= 0) return 'Partilenmedi';
                        if (hm > 0 && pm >= hm) return 'Tamamen Partilendi';
                        return 'Eksik Partilendi';
                    },
                    cellTemplate: function(c,o) {
                        var pm = parseFloat(o.data.parti_metre) || 0;
                        var hm = parseFloat(o.data.hk_metre) || 0;
                        var label, cls;
                        if (pm <= 0)                  { label = 'Partilenmedi';       cls = 'badge bg-secondary'; }
                        else if (hm > 0 && pm >= hm)  { label = 'Tamamen Partilendi'; cls = 'badge bg-success'; }
                        else                           { label = 'Eksik Partilendi';   cls = 'badge bg-warning text-dark'; }
                        $('<span>').addClass(cls).text(label).appendTo(c);
                    }
                },
                { dataField:'parti_count', caption:'Parti Adedi', width:100, alignment:'center', dataType:'number' },
                { dataField:'hk_h_gramaj', caption:'H.Gramaj', width:95, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'hk_gr_mtul', caption:'Gr/Mtul', width:90, alignment:'right', dataType:'number', format:{type:'fixedPoint',precision:2} },
                { dataField:'hk_ucretli', caption:'Ücretli', width:80, alignment:'center', dataType:'boolean',
                    cellTemplate: function(c,o) {
                        $('<span>').addClass(o.value ? 'badge bg-success' : 'badge bg-secondary')
                            .text(o.value ? 'Evet' : 'Hayır').appendTo(c);
                    }
                },
                { dataField:'hk_ham_boyali', caption:'Ham/Boyalı', width:95, alignment:'center', dataType:'boolean',
                    cellTemplate: function(c,o) {
                        $('<span>').addClass(o.value ? 'badge bg-info text-dark' : 'badge bg-warning text-dark')
                            .text(o.value ? 'Ham' : 'Boyalı').appendTo(c);
                    }
                },
                { dataField:'ref_no', caption:'Ref No', width:120,
                    cellTemplate: function(c,o) { $('<span>').addClass('text-muted small').text(o.value||'-').appendTo(c); }
                },
                { dataField:'is_ship_iptal', caption:'Durum', width:90, alignment:'center',
                    cellTemplate: function(c,o) {
                        $('<span>').addClass(o.value ? 'badge bg-danger' : 'badge bg-success')
                            .text(o.value ? 'İptal' : 'Aktif').appendTo(c);
                    }
                },
                { dataField:'record_date', caption:'Kayıt Tarihi', width:130 },
                {
                    caption:'İşlemler', width:130, alignment:'center', allowSorting:false, allowFiltering:false,
                    cellTemplate: function(c, o) {
                        var g = $('<div>').addClass('d-flex gap-1 justify-content-center');
                        $('<button>').addClass('btn btn-sm btn-outline-primary').attr('title','Düzenle').html('<i class="fas fa-edit"></i>')
                            .on('click', function(){ openGirisFis(o.data.ship_id); }).appendTo(g);
                        $('<button>').addClass('btn btn-sm btn-outline-info').attr('title','Parti Listesi').html('<i class="fas fa-list-ol"></i>')
                            .on('click', function(){ listPartiler(o.data.ship_id); }).appendTo(g);
                        $('<button>').addClass('btn btn-sm btn-outline-success').attr('title','Parti Ekle').html('<i class="fas fa-cut"></i>')
                            .on('click', function(){ addParti(o.data.ship_id); }).appendTo(g);
                        $('<button>').addClass('btn btn-sm btn-outline-danger').attr('title','Sil').html('<i class="fas fa-trash"></i>')
                            .on('click', function(){ deleteGirisFis(o.data.ship_id, o.data.ship_number); }).appendTo(g);
                        g.appendTo(c);
                    },
                    width: 160
                }
            ]
        });
    }
});

function addGirisFis()      { window.location.href = 'index.cfm?fuseaction=ship.add_giris_fis'; }
function openGirisFis(id)   { window.location.href = 'index.cfm?fuseaction=ship.add_giris_fis&ship_id=' + id; }
function addParti(id)       { window.location.href = 'index.cfm?fuseaction=ship.add_parti&ship_id=' + id; }
function listPartiler(id)   { window.location.href = 'index.cfm?fuseaction=ship.list_partiler&ship_id=' + id; }

function deleteGirisFis(id, no) {
    var label = no ? no : ('##' + id);
    DevExpress.ui.dialog.confirm('"' + label + '" giriş fişini silmek istediğinizden emin misiniz?', 'Silme Onayı')
        .then(function(ok) {
            if (!ok) return;
            $.ajax({
                url: '/ship/form/delete_ship.cfm', method:'POST', data:{ ship_id: id }, dataType:'json',
                success: function(r) {
                    if (r.success) {
                        DevExpress.ui.notify('Giriş fişi silindi','success',2000);
                        fisData = fisData.filter(function(x){ return x.ship_id != id; });
                        $('##girisFisGrid').dxDataGrid('instance').option('dataSource', fisData);
                        document.getElementById('sumTotal').textContent = fisData.length;
                    } else DevExpress.ui.notify(r.message||'Hata!','error',3000);
                },
                error: function() { DevExpress.ui.notify('Silme başarısız!','error',3000); }
            });
        });
}
</script>
</cfoutput>