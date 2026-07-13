<cfprocessingdirective pageEncoding="utf-8">
<cfparam name="url.parti_no" default="">
<cfparam name="form.parti_no" default="#url.parti_no#">
<cfset partiNo = trim(form.parti_no)>
<cfset partiOrderId = isNumeric(partiNo) ? val(partiNo) : 0>
<cfset hasSearch = len(partiNo) gt 0>

<cfif hasSearch>
    <cfquery name="getParti" datasource="boyahane">
        SELECT o.order_id,
               o.order_number,
               o.order_head,
               o.order_detail,
               o.order_stage,
               o.order_date,
               o.deliverdate,
               o.ref_ship_id,
               o.ref_no,
               COALESCE(o.top_adedi, 0) AS top_adedi,
               COALESCE(o.main_color, '') AS main_color,
               COALESCE(o.kumas_tipi, '') AS order_kumas_tipi,
               COALESCE(ss.sarim_sekli_adi, '') AS sarim_sekli_adi,
               COALESCE(ab.ambalaj_adi, '') AS ambalaj_adi,
               COALESCE(c.nickname, c.fullname, '') AS company_name,
               COALESCE(c.member_code, '') AS member_code,
               COALESCE(s.ship_number, o.ref_no, '') AS ship_number,
               COALESCE(s.hk_metre, 0) AS ship_metre,
               COALESCE(s.hk_kg, 0) AS ship_kg,
               COALESCE(s.hk_top_adedi, 0) AS ship_top_adedi
        FROM orders o
        LEFT JOIN company c ON c.company_id = o.company_id
        LEFT JOIN ship s ON s.ship_id = o.ref_ship_id
        LEFT JOIN setup_sarim_sekli ss ON ss.sarim_sekli_id = o.sarim_sekli
        LEFT JOIN setup_ambalaj ab ON ab.ambalaj_id = o.ambalaj
        WHERE o.order_number = <cfqueryparam value="#partiNo#" cfsqltype="cf_sql_varchar">
           OR o.ref_no = <cfqueryparam value="#partiNo#" cfsqltype="cf_sql_varchar">
           OR (<cfqueryparam value="#partiOrderId#" cfsqltype="cf_sql_integer"> > 0 AND o.order_id = <cfqueryparam value="#partiOrderId#" cfsqltype="cf_sql_integer">)
        ORDER BY o.order_id DESC
        LIMIT 1
    </cfquery>

    <cfif getParti.recordCount>
        <cfquery name="getRows" datasource="boyahane">
            SELECT orw.order_row_id,
                   orw.product_name,
                   orw.product_name2,
                   orw.quantity,
                   orw.amount2,
                   orw.unit,
                   COALESCE(st.stock_code, '') AS stock_code,
                   COALESCE(st.stock_code_2, '') AS stock_code_2,
                   COALESCE(st.property, '') AS stock_property,
                   COALESCE(p.kumas_tipi, '') AS product_kumas_tipi,
                   COALESCE(ci.color_code, '') AS color_code,
                   COALESCE(ci.color_name, '') AS color_name,
                   COALESCE(ci.renk_no, '') AS renk_no
            FROM order_row orw
            LEFT JOIN stocks st ON st.stock_id = orw.stock_id
            LEFT JOIN product p ON p.product_id = st.product_id
            LEFT JOIN color_info ci ON ci.stock_id = orw.stock_id
            WHERE orw.order_id = <cfqueryparam value="#getParti.order_id#" cfsqltype="cf_sql_integer">
            ORDER BY orw.order_row_id
        </cfquery>

        <cfquery name="getRolls" datasource="boyahane">
            SELECT sr.roll_id,
                   sr.plan_id,
                   sr.roll_no,
                   sr.roll_barcode,
                   sr.metre,
                   sr.kg,
                   COALESCE(sr.paket_durumu, '') AS paket_durumu,
                   sr.etiket_print_count,
                   sr.record_date,
                   sr.dispatch_date,
                   COALESCE(ds.ship_number, '') AS dispatch_ship_number
            FROM ship_roll sr
            LEFT JOIN ship ds ON ds.ship_id = sr.dispatch_ship_id
            WHERE sr.order_id = <cfqueryparam value="#getParti.order_id#" cfsqltype="cf_sql_integer">
            ORDER BY COALESCE(sr.roll_no, 0), sr.roll_id
        </cfquery>

        <cfquery name="getRollTotals" datasource="boyahane">
            SELECT COUNT(*) AS roll_count,
                   COALESCE(SUM(COALESCE(metre, 0)), 0) AS total_metre,
                   COALESCE(SUM(COALESCE(kg, 0)), 0) AS total_kg,
                   COALESCE(SUM(CASE WHEN LOWER(COALESCE(paket_durumu, '')) = 'sevk edildi' THEN 1 ELSE 0 END), 0) AS dispatched_count
            FROM ship_roll
            WHERE order_id = <cfqueryparam value="#getParti.order_id#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cfif>
</cfif>

<cfscript>
function stageText(stageValue) {
    switch (val(stageValue)) {
        case 1: return "Beklemede";
        case 2: return "Onaylandı";
        case 3: return "Üretimde";
        case 4: return "Hazır";
        case 5: return "Sevk Edildi";
        case 6: return "Tamamlandı";
        case 7: return "Renkli";
        default: return "Bilinmiyor";
    }
}
</cfscript>

<div class="page-header">
    <div class="page-header-left">
        <div class="page-header-icon"><i class="fas fa-boxes-stacked"></i></div>
        <div class="page-header-title">
            <h1>Parti Paket Topları</h1>
            <p>Parti numarası girerek parti bilgilerini ve paketlenen top listesini görüntüleyin.</p>
        </div>
    </div>
</div>

<div class="px-3 pb-5 parti-package-page">
    <div class="grid-card mb-3">
        <div class="grid-card-header">
            <div class="grid-card-header-title"><i class="fas fa-search"></i>Parti Sorgula</div>
        </div>
        <div class="card-body p-3">
            <form method="get" action="index.cfm" class="row g-2 align-items-end">
                <input type="hidden" name="fuseaction" value="ship.parti_paket_toplari">
                <div class="col-md-8 col-lg-6">
                    <label class="form-label fw-semibold" for="parti_no">Parti Numarası</label>
                    <input type="text" class="form-control form-control-lg" id="parti_no" name="parti_no" value="<cfoutput>#htmlEditFormat(partiNo)#</cfoutput>" placeholder="Parti no / ref no / order id" autofocus autocomplete="off">
                </div>
                <div class="col-auto">
                    <button type="submit" class="btn btn-primary btn-lg"><i class="fas fa-magnifying-glass me-1"></i>Sorgula</button>
                </div>
            </form>
        </div>
    </div>

<cfif NOT hasSearch>
    <div class="alert alert-info"><i class="fas fa-info-circle me-2"></i>Başlamak için parti numarasını girip sorgulayın.</div>
<cfelseif NOT getParti.recordCount>
    <div class="alert alert-warning"><i class="fas fa-triangle-exclamation me-2"></i><cfoutput>#htmlEditFormat(partiNo)#</cfoutput> için parti bulunamadı.</div>
<cfelse>
    <cfoutput>
    <div class="row g-3 mb-3">
        <div class="col-lg-8">
            <div class="grid-card h-100">
                <div class="grid-card-header"><div class="grid-card-header-title"><i class="fas fa-clipboard-list"></i>Parti Bilgileri</div></div>
                <div class="card-body p-0">
                    <div class="detail-grid">
                        <div><span>Parti No</span><strong>#htmlEditFormat(getParti.order_number ?: '')#</strong></div>
                        <div><span>Firma</span><strong>#htmlEditFormat(getParti.company_name ?: '—')#</strong></div>
                        <div><span>Üye Kodu</span><strong>#htmlEditFormat(getParti.member_code ?: '—')#</strong></div>
                        <div><span>Durum</span><strong>#stageText(getParti.order_stage)#</strong></div>
                        <div><span>İrsaliye</span><strong>#htmlEditFormat(getParti.ship_number ?: '—')#</strong></div>
                        <div><span>Renk</span><strong>#htmlEditFormat(getParti.main_color ?: '—')#</strong></div>
                        <div><span>Kumaş Tipi</span><strong>#htmlEditFormat(len(getParti.order_kumas_tipi) ? getParti.order_kumas_tipi : '—')#</strong></div>
                        <div><span>Sarım / Ambalaj</span><strong>#htmlEditFormat((len(getParti.sarim_sekli_adi) ? getParti.sarim_sekli_adi : '—') & ' / ' & (len(getParti.ambalaj_adi) ? getParti.ambalaj_adi : '—'))#</strong></div>
                        <div><span>Parti Top</span><strong>#numberFormat(val(getParti.top_adedi), '_,')#</strong></div>
                        <div><span>İrsaliye Metre / Kg</span><strong>#numberFormat(val(getParti.ship_metre), '_,.00')# m / #numberFormat(val(getParti.ship_kg), '_,.00')# kg</strong></div>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-lg-4">
            <div class="summary-card h-100">
                <div class="summary-item"><span>Paketlenen Top</span><strong>#numberFormat(val(getRollTotals.roll_count), '_,')#</strong></div>
                <div class="summary-item"><span>Toplam Metre</span><strong>#numberFormat(val(getRollTotals.total_metre), '_,.00')#</strong></div>
                <div class="summary-item"><span>Toplam Kg</span><strong>#numberFormat(val(getRollTotals.total_kg), '_,.00')#</strong></div>
                <div class="summary-item"><span>Sevk Edilen</span><strong>#numberFormat(val(getRollTotals.dispatched_count), '_,')#</strong></div>
            </div>
        </div>
    </div>
    </cfoutput>

    <div class="grid-card mb-3">
        <div class="grid-card-header"><div class="grid-card-header-title"><i class="fas fa-layer-group"></i>Parti Kalemleri</div></div>
        <div class="table-responsive">
            <table class="table table-sm table-hover align-middle mb-0">
                <thead><tr><th>Ürün</th><th>Stok</th><th>Renk</th><th class="text-end">Miktar</th><th>Birim</th><th>Kumaş Tipi</th></tr></thead>
                <tbody>
                <cfoutput query="getRows">
                    <tr>
                        <td>#htmlEditFormat(product_name ?: '')#<cfif len(product_name2 ?: '')><div class="text-muted small">#htmlEditFormat(product_name2)#</div></cfif></td>
                        <td>#htmlEditFormat(stock_code ?: '')#<cfif len(stock_code_2 ?: '')><div class="text-muted small">#htmlEditFormat(stock_code_2)#</div></cfif></td>
                        <td>#htmlEditFormat(trim((color_code ?: '') & ' ' & (color_name ?: '') & ' ' & (renk_no ?: '')))#</td>
                        <td class="text-end">#numberFormat(val(quantity), '_,.00')#</td>
                        <td>#htmlEditFormat(unit ?: '')#</td>
                        <td>#htmlEditFormat(product_kumas_tipi ?: '')#</td>
                    </tr>
                </cfoutput>
                <cfif getRows.recordCount eq 0><tr><td colspan="6" class="text-center text-muted py-4">Parti kalemi bulunamadı.</td></tr></cfif>
                </tbody>
            </table>
        </div>
    </div>

    <div class="grid-card">
        <div class="grid-card-header"><div class="grid-card-header-title"><i class="fas fa-box"></i>Paketlenen Toplar</div></div>
        <div class="table-responsive">
            <table class="table table-sm table-hover align-middle mb-0">
                <thead><tr><th>Top No</th><th>Barkod</th><th class="text-end">Metre</th><th class="text-end">Kg</th><th>Paket Durumu</th><th>Etiket</th><th>Kayıt Tarihi</th><th>Sevk</th></tr></thead>
                <tbody>
                <cfoutput query="getRolls">
                    <tr>
                        <td><strong>#isNumeric(roll_no) ? val(roll_no) : ''#</strong></td>
                        <td><code>#htmlEditFormat(roll_barcode ?: '')#</code></td>
                        <td class="text-end">#numberFormat(val(metre), '_,.00')#</td>
                        <td class="text-end">#numberFormat(val(kg), '_,.00')#</td>
                        <td><span class="badge bg-#lCase(paket_durumu ?: '') eq 'sevk edildi' ? 'success' : 'secondary'#">#htmlEditFormat(len(paket_durumu) ? paket_durumu : 'Paketlendi')#</span></td>
                        <td>#numberFormat(val(etiket_print_count), '_,')#</td>
                        <td>#isDate(record_date) ? dateFormat(record_date, 'dd/mm/yyyy') & ' ' & timeFormat(record_date, 'HH:mm') : ''#</td>
                        <td>#htmlEditFormat(dispatch_ship_number ?: '')#<cfif isDate(dispatch_date)><div class="text-muted small">#dateFormat(dispatch_date, 'dd/mm/yyyy')# #timeFormat(dispatch_date, 'HH:mm')#</div></cfif></td>
                    </tr>
                </cfoutput>
                <cfif getRolls.recordCount eq 0><tr><td colspan="8" class="text-center text-muted py-4">Bu parti için paketlenen top kaydı bulunamadı.</td></tr></cfif>
                </tbody>
            </table>
        </div>
    </div>
</cfif>
</div>

<style>
.parti-package-page .detail-grid { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:0; }
.parti-package-page .detail-grid > div { padding:12px 14px; border-bottom:1px solid #eef2f7; border-right:1px solid #eef2f7; }
.parti-package-page .detail-grid span { display:block; font-size:.74rem; color:#64748b; margin-bottom:3px; }
.parti-package-page .detail-grid strong { color:#0f172a; font-size:.92rem; }
.parti-package-page .summary-card { background:linear-gradient(135deg,#0f766e,#2563eb); color:white; border-radius:14px; padding:18px; box-shadow:0 12px 30px rgba(37,99,235,.18); }
.parti-package-page .summary-item { display:flex; justify-content:space-between; align-items:center; padding:12px 0; border-bottom:1px solid rgba(255,255,255,.22); }
.parti-package-page .summary-item:last-child { border-bottom:0; }
.parti-package-page .summary-item span { opacity:.86; }
.parti-package-page .summary-item strong { font-size:1.35rem; }
@media (max-width: 768px) { .parti-package-page .detail-grid { grid-template-columns:1fr; } }
</style>
