<cfprocessingdirective pageEncoding="utf-8">

<!--- Filtre parametreleri --->
<cfparam name="url.dept_id"      default="0">
<cfparam name="url.loc_id"       default="0">
<cfparam name="url.search"       default="">
<cfparam name="url.only_positive" default="1">

<cfset fDeptId       = isNumeric(url.dept_id)       ? val(url.dept_id)       : 0>
<cfset fLocId        = isNumeric(url.loc_id)         ? val(url.loc_id)         : 0>
<cfset fSearch       = left(trim(url.search), 100)>
<cfset fOnlyPositive = val(url.only_positive) EQ 1>

<!--- Filtre selectbox verileri --->
<cfquery name="qDepts" datasource="boyahane">
    SELECT DISTINCT d.department_id, COALESCE(d.department_head,'') AS department_head
    FROM department d
    INNER JOIN stocks_row sr ON sr.store = d.department_id
    WHERE COALESCE(d.department_status, true) = true
    ORDER BY d.department_head
</cfquery>

<cfquery name="qLocs" datasource="boyahane">
    SELECT sl.id, sl.location_id,
           COALESCE(sl.department_location,'') AS department_location,
           COALESCE(d.department_head,'')       AS department_head
    FROM stocks_location sl
    INNER JOIN department d ON d.department_id = sl.department_id
    <cfif fDeptId GT 0>
    WHERE sl.department_id = <cfqueryparam value="#fDeptId#" cfsqltype="cf_sql_integer">
    </cfif>
    ORDER BY d.department_head, sl.department_location
</cfquery>

<!--- Ana stok miktarları sorgusu --->
<cfquery name="getAmounts" datasource="boyahane">
    SELECT
        sr.stock_id,
        sr.product_id,
        COALESCE(p.product_name,  '')   AS product_name,
        COALESCE(s.stock_code,    '')   AS stock_code,
        COALESCE(s.stock_code_2,  '')   AS stock_code_2,
        COALESCE(s.property,      '')   AS stock_property,
        sr.store                        AS dept_id,
        COALESCE(d.department_head,'')  AS dept_name,
        sr.store_location               AS loc_id,
        COALESCE(sl.department_location,'') AS loc_name,
        SUM(COALESCE(sr.stock_in,0) - COALESCE(sr.stock_out,0)) AS net_amount
    FROM stocks_row sr
    LEFT JOIN stocks          s  ON s.stock_id   = sr.stock_id
    LEFT JOIN product         p  ON p.product_id = s.product_id
    LEFT JOIN stocks_location sl ON sl.location_id = sr.store_location
                                 AND sl.department_id = sr.store
    LEFT JOIN department      d  ON d.department_id = sr.store
    WHERE 1=1
    <cfif fDeptId GT 0>
        AND sr.store = <cfqueryparam value="#fDeptId#" cfsqltype="cf_sql_integer">
    </cfif>
    <cfif fLocId GT 0>
        AND sl.id = <cfqueryparam value="#fLocId#" cfsqltype="cf_sql_integer">
    </cfif>
    <cfif len(fSearch)>
        AND (
            p.product_name  ILIKE <cfqueryparam value="%#fSearch#%" cfsqltype="cf_sql_varchar">
         OR s.stock_code     ILIKE <cfqueryparam value="%#fSearch#%" cfsqltype="cf_sql_varchar">
         OR s.stock_code_2   ILIKE <cfqueryparam value="%#fSearch#%" cfsqltype="cf_sql_varchar">
         OR s.property       ILIKE <cfqueryparam value="%#fSearch#%" cfsqltype="cf_sql_varchar">
        )
    </cfif>
    GROUP BY
        sr.stock_id, sr.product_id, p.product_name,
        s.stock_code, s.stock_code_2, s.property,
        sr.store, d.department_head,
        sr.store_location, sl.department_location
    <cfif fOnlyPositive>
        HAVING SUM(COALESCE(sr.stock_in,0) - COALESCE(sr.stock_out,0)) > 0
    </cfif>
    ORDER BY d.department_head, sl.department_location, p.product_name
</cfquery>

<!--- Özet toplamlar --->
<cfset totalRows     = getAmounts.recordCount>
<cfset totalNetQty   = 0>
<cfset totalPositive = 0>
<cfset totalZeroNeg  = 0>
<cfloop query="getAmounts">
    <cfset totalNetQty += val(net_amount)>
    <cfif val(net_amount) GT 0>
        <cfset totalPositive++>
    <cfelse>
        <cfset totalZeroNeg++>
    </cfif>
</cfloop>

<cfoutput>
<style>
/* ===== STOK MİKTARLARI ===== */
.sa-page { padding: 0 4px 32px; }

.sa-header {
    background: linear-gradient(135deg, ##1a3a5c 0%, ##0d2137 100%);
    border-radius: 14px;
    padding: 20px 24px;
    margin-bottom: 20px;
    display: flex; align-items: center; justify-content: space-between;
    flex-wrap: wrap; gap: 12px;
    box-shadow: 0 4px 18px rgba(13,33,55,.25);
}
.sa-header-left   { display: flex; align-items: center; gap: 16px; }
.sa-header-icon   {
    width: 48px; height: 48px; background: ##e67e22; border-radius: 12px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.35rem; color: ##fff; box-shadow: 0 4px 14px rgba(230,126,34,.4); flex-shrink: 0;
}
.sa-header-title  { font-size: 1.25rem; font-weight: 800; color: ##fff; margin: 0 0 3px; }
.sa-header-sub    { font-size: 0.78rem; color: rgba(255,255,255,.55); margin: 0; }

/* Özet kartlar */
.sa-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 12px; margin-bottom: 20px;
}
.sa-stat {
    background: ##fff; border-radius: 12px; padding: 16px;
    display: flex; align-items: center; gap: 14px;
    box-shadow: 0 2px 10px rgba(0,0,0,.06); border: 1px solid ##f1f5f9;
}
.sa-stat-icon {
    width: 44px; height: 44px; border-radius: 11px;
    display: flex; align-items: center; justify-content: center;
    font-size: 1.2rem; flex-shrink: 0;
}
.sa-stat-icon.total   { background: ##eff6ff; color: ##3b82f6; }
.sa-stat-icon.pos     { background: ##f0fdf4; color: ##16a34a; }
.sa-stat-icon.zero    { background: ##fef2f2; color: ##dc2626; }
.sa-stat-icon.sum     { background: ##f5f3ff; color: ##7c3aed; }
.sa-stat-label { font-size: 0.7rem; font-weight: 600; color: ##94a3b8; text-transform: uppercase; letter-spacing:.04em; margin-bottom: 2px; }
.sa-stat-val   { font-size: 1.55rem; font-weight: 800; line-height: 1.1; color: ##0f172a; }

/* Filtre çubuğu */
.sa-filter-bar {
    background: ##fff;
    border-radius: 12px;
    padding: 16px 18px;
    margin-bottom: 18px;
    border: 1px solid ##e5e7eb;
    box-shadow: 0 2px 8px rgba(0,0,0,.04);
    display: flex; flex-wrap: wrap; gap: 10px; align-items: flex-end;
}
.sa-filter-bar .form-label { font-size: 0.72rem; font-weight: 600; color: ##64748b; text-transform: uppercase; letter-spacing: .04em; margin-bottom: 4px; }
.sa-filter-bar .form-control,
.sa-filter-bar .form-select { font-size: 0.82rem; border-color: ##e5e7eb; }
.sa-filter-bar .form-control:focus,
.sa-filter-bar .form-select:focus { border-color: ##1a3a5c; box-shadow: 0 0 0 2px rgba(26,58,92,.12); }

/* Filtre aktif ipucu */
.sa-filter-active {
    display: inline-flex; align-items: center; gap: 5px;
    font-size: 0.72rem; background: ##eff6ff; color: ##3b82f6;
    border: 1px solid ##bfdbfe; border-radius: 99px; padding: 3px 10px;
}

/* Tablo kartı */
.sa-table-card {
    background: ##fff; border-radius: 14px; overflow: hidden;
    box-shadow: 0 2px 10px rgba(0,0,0,.06); border: 1px solid ##e5e7eb;
}
.sa-table-card thead th {
    background: var(--primary, ##1a3a5c); color: ##fff;
    font-size: 0.73rem; font-weight: 600; text-transform: uppercase; letter-spacing:.04em;
    border: none; padding: 10px 12px; white-space: nowrap;
}
.sa-table-card tbody td { font-size: 0.82rem; padding: 9px 12px; vertical-align: middle; border-color: ##f1f5f9; }
.sa-table-card tbody tr:last-child td { border-bottom: none; }
.sa-table-card tbody tr:hover td { background: ##f8fafc; }
.sa-table-footer {
    padding: 10px 14px; font-size: 0.78rem; color: ##64748b;
    border-top: 1px solid ##f1f5f9; background: ##fafbfc;
    display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px;
}

/* Dept bölücü satırı */
.sa-dept-row td {
    background: linear-gradient(90deg, ##1a3a5c, ##1e4570) !important;
    color: ##fff !important; font-weight: 700; font-size: 0.78rem;
    letter-spacing: .04em; padding: 7px 12px !important;
}

/* Miktar badge */
.sa-qty-pos  { color: ##16a34a; font-weight: 700; }
.sa-qty-zero { color: ##94a3b8; font-weight: 600; }
.sa-qty-neg  { color: ##dc2626; font-weight: 700; }

/* Boş durum */
.sa-empty { text-align: center; padding: 40px 16px; color: ##94a3b8; }
.sa-empty i { font-size: 2rem; display: block; margin-bottom: 8px; color: ##cbd5e1; }
</style>

<div class="sa-page">

    <!--- HEADER --->
    <div class="sa-header">
        <div class="sa-header-left">
            <div class="sa-header-icon"><i class="bi bi-boxes"></i></div>
            <div>
                <p class="sa-header-title">Stok Miktarları</p>
                <p class="sa-header-sub">Depo ve lokasyon bazlı anlık stok durumu</p>
            </div>
        </div>
        <div class="d-flex gap-2 flex-wrap align-items-center">
            <!--- Aktif filtre rozeti --->
            <cfif fDeptId GT 0 OR fLocId GT 0 OR len(fSearch) OR NOT fOnlyPositive>
                <span class="sa-filter-active">
                    <i class="bi bi-funnel-fill"></i> Filtre aktif
                    <a href="index.cfm?fuseaction=stock.list_stock_amounts" class="ms-1 text-decoration-none" style="color:##dc2626;" title="Filtreleri temizle">&##x2715;</a>
                </span>
            </cfif>
            <a href="index.cfm?fuseaction=stock.list_fis" style="background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.2);color:##fff;font-size:0.82rem;font-weight:600;padding:7px 16px;border-radius:8px;text-decoration:none;display:inline-flex;align-items:center;gap:6px;">
                <i class="bi bi-file-earmark-text"></i> Stok Fişleri
            </a>
        </div>
    </div>

    <!--- ÖZET KARTLAR --->
    <div class="sa-stats">
        <div class="sa-stat">
            <div class="sa-stat-icon total"><i class="bi bi-list-ul"></i></div>
            <div>
                <div class="sa-stat-label">Toplam Satır</div>
                <div class="sa-stat-val">#totalRows#</div>
            </div>
        </div>
        <div class="sa-stat">
            <div class="sa-stat-icon pos"><i class="bi bi-graph-up-arrow"></i></div>
            <div>
                <div class="sa-stat-label">Pozitif Stok</div>
                <div class="sa-stat-val">#totalPositive#</div>
            </div>
        </div>
        <cfif NOT fOnlyPositive>
        <div class="sa-stat">
            <div class="sa-stat-icon zero"><i class="bi bi-dash-circle"></i></div>
            <div>
                <div class="sa-stat-label">Sıfır / Negatif</div>
                <div class="sa-stat-val">#totalZeroNeg#</div>
            </div>
        </div>
        </cfif>
        <div class="sa-stat">
            <div class="sa-stat-icon sum"><i class="bi bi-sigma"></i></div>
            <div>
                <div class="sa-stat-label">Net Toplam</div>
                <div class="sa-stat-val">#numberFormat(totalNetQty, "_.___")#</div>
            </div>
        </div>
    </div>

    <!--- FİLTRE ÇUBUĞU --->
    <form method="get" action="index.cfm" class="sa-filter-bar">
        <input type="hidden" name="fuseaction" value="stock.list_stock_amounts">

        <div>
            <label class="form-label">Departman</label>
            <select name="dept_id" class="form-select" style="min-width:180px;" onchange="this.form.submit()">
                <option value="0">Tümü</option>
                <cfloop query="qDepts">
                    <option value="#val(department_id)#" <cfif fDeptId EQ val(department_id)>selected</cfif>>
                        #htmlEditFormat(department_head)#
                    </option>
                </cfloop>
            </select>
        </div>

        <div>
            <label class="form-label">Lokasyon</label>
            <select name="loc_id" class="form-select" style="min-width:200px;">
                <option value="0">Tümü</option>
                <cfloop query="qLocs">
                    <option value="#val(id)#" <cfif fLocId EQ val(id)>selected</cfif>>
                        <cfif NOT fDeptId>#htmlEditFormat(department_head)# — </cfif>#htmlEditFormat(department_location)#
                    </option>
                </cfloop>
            </select>
        </div>

        <div style="flex:1;min-width:200px;">
            <label class="form-label">Ürün / Stok Kodu</label>
            <input type="text" name="search" class="form-control" placeholder="Ürün adı veya stok kodu..." value="#htmlEditFormat(fSearch)#" style="min-width:200px;">
        </div>

        <div>
            <label class="form-label d-block">Sadece Pozitif</label>
            <div class="form-check form-switch mt-1">
                <input class="form-check-input" type="checkbox" name="only_positive" value="1" id="cbPositive"
                       <cfif fOnlyPositive>checked</cfif>
                       style="width:2.5em;height:1.3em;cursor:pointer;">
                <label class="form-check-label small text-muted" for="cbPositive">Evet</label>
            </div>
        </div>

        <div class="d-flex gap-2">
            <button type="submit" class="btn btn-sm btn-primary px-3">
                <i class="bi bi-funnel me-1"></i>Filtrele
            </button>
            <a href="index.cfm?fuseaction=stock.list_stock_amounts" class="btn btn-sm btn-outline-secondary px-3">
                <i class="bi bi-x-lg me-1"></i>Temizle
            </a>
        </div>
    </form>

    <!--- TABLO --->
    <div class="sa-table-card">
        <cfif totalRows GT 0>
            <div class="table-responsive">
                <table class="table table-hover table-sm align-middle mb-0">
                    <thead>
                        <tr>
                            <th style="width:40px;">##</th>
                            <th>Ürün Adı</th>
                            <th>Stok Kodu</th>
                            <th>Özellik / Renk</th>
                            <th>Departman</th>
                            <th>Lokasyon</th>
                            <th class="text-end">Net Miktar</th>
                        </tr>
                    </thead>
                    <tbody>
                        <cfset rowNum      = 0>
                        <cfset lastDept    = "">
                        <cfloop query="getAmounts">
                            <cfset rowNum++>

                            <!--- Departman bölücü --->
                            <cfif dept_name NEQ lastDept>
                                <cfset lastDept = dept_name>
                                <tr class="sa-dept-row">
                                    <td colspan="7">
                                        <i class="bi bi-building me-2"></i>
                                        #htmlEditFormat(len(dept_name) ? dept_name : "Depo Belirtilmemiş")#
                                    </td>
                                </tr>
                            </cfif>

                            <cfset qty = val(net_amount)>
                            <cfset qtyClass = qty GT 0 ? "sa-qty-pos" : (qty LT 0 ? "sa-qty-neg" : "sa-qty-zero")>

                            <tr>
                                <td class="text-muted" style="font-size:0.72rem;">#rowNum#</td>
                                <td>
                                    <span class="fw-semibold">#htmlEditFormat(product_name)#</span>
                                </td>
                                <td>
                                    <code style="font-size:0.78rem;background:##f1f5f9;padding:2px 7px;border-radius:5px;">#htmlEditFormat(stock_code)#</code>
                                    <cfif len(trim(stock_code_2))>
                                        <span class="text-muted ms-1" style="font-size:0.72rem;">#htmlEditFormat(stock_code_2)#</span>
                                    </cfif>
                                </td>
                                <td style="font-size:0.78rem;color:##64748b;">
                                    #len(trim(stock_property)) ? htmlEditFormat(stock_property) : "—"#
                                </td>
                                <td style="font-size:0.78rem;color:##64748b;">
                                    #len(trim(dept_name)) ? htmlEditFormat(dept_name) : "—"#
                                </td>
                                <td style="font-size:0.78rem;">
                                    <cfif len(trim(loc_name))>
                                        <span class="badge" style="background:##f1f5f9;color:##475569;font-weight:600;">
                                            <i class="bi bi-geo-alt me-1"></i>#htmlEditFormat(loc_name)#
                                        </span>
                                    <cfelse>
                                        <span class="text-muted">—</span>
                                    </cfif>
                                </td>
                                <td class="text-end">
                                    <span class="#qtyClass#" style="font-size:0.9rem;">
                                        #numberFormat(qty, "_.___.__")#
                                    </span>
                                </td>
                            </tr>
                        </cfloop>
                    </tbody>
                </table>
            </div>
            <div class="sa-table-footer">
                <span>
                    <strong>#totalRows#</strong> satır listeleniyor
                    <cfif fDeptId GT 0 OR fLocId GT 0 OR len(fSearch)>
                        — filtre uygulandı
                    </cfif>
                </span>
                <span class="#totalNetQty GT 0 ? 'sa-qty-pos' : (totalNetQty LT 0 ? 'sa-qty-neg' : 'sa-qty-zero')#">
                    Toplam Net: <strong>#numberFormat(totalNetQty, "_.___.__")#</strong>
                </span>
            </div>
        <cfelse>
            <div class="sa-empty">
                <i class="bi bi-inbox"></i>
                <p>
                    <cfif fDeptId GT 0 OR fLocId GT 0 OR len(fSearch)>
                        Filtreye uygun stok kaydı bulunamadı.
                        <a href="index.cfm?fuseaction=stock.list_stock_amounts" class="d-block mt-1 text-muted" style="font-size:0.8rem;">Filtreleri temizle</a>
                    <cfelse>
                        Henüz stok hareketi kaydı bulunmuyor.
                    </cfif>
                </p>
            </div>
        </cfif>
    </div>

</div>
</cfoutput>
