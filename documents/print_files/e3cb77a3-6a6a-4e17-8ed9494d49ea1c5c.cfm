<cfprocessingdirective pageEncoding="utf-8">
<cfparam name="url.doc_id" default="0">
<cfset docId = val(isDefined("request.docId") ? request.docId : url.doc_id)>

<!--- Ana fiş bilgileri --->
<cfquery name="getFis" datasource="boyahane">
    SELECT
        sf.*,
        lo_out.department_location   AS loc_out_name,
        d_out.department_head        AS dep_out_name,
        lo_in.department_location    AS loc_in_name,
        d_in.department_head         AS dep_in_name,
        TRIM(k.name || ' ' || k.surname) AS emp_fullname
    FROM stock_fis sf
    LEFT JOIN stocks_location lo_out ON lo_out.id = sf.location_out
    LEFT JOIN department      d_out  ON d_out.department_id = sf.department_out
    LEFT JOIN stocks_location lo_in  ON lo_in.id = sf.location_in
    LEFT JOIN department      d_in   ON d_in.department_id  = sf.department_in
    LEFT JOIN kullanicilar    k      ON k.id = sf.employee_id
    WHERE sf.fis_id = <cfqueryparam value="#docId#" cfsqltype="cf_sql_integer">
</cfquery>

<!--- Fiş satırları --->
<cfquery name="getFisRow" datasource="boyahane">
    SELECT
        sfr.stock_fis_row_id,
        sfr.amount,
        sfr.unit,
        sfr.amount2,
        sfr.unit2,
        sfr.lot_no,
        sfr.shelf_number,
        sfr.to_shelf_number,
        sfr.product_name2,
        sfr.product_manufact_code,
        sfr.detail_info_extra,
        s.stock_code,
        s.barcod,
        s.property,
        p.product_name,
        p.product_code
    FROM  stock_fis_row sfr
    LEFT JOIN stocks  s ON s.stock_id  = sfr.stock_id
    LEFT JOIN product p ON p.product_id = s.product_id
    WHERE sfr.fis_id = <cfqueryparam value="#docId#" cfsqltype="cf_sql_integer">
    ORDER BY sfr.stock_fis_row_id
</cfquery>

<cfif NOT getFis.recordCount>
    <div class="alert alert-warning">Fiş bulunamadı. (ID: <cfoutput>#docId#</cfoutput>)</div>
    <cfabort>
</cfif>

<!--- Fiş tipi etiketi --->
<cfset fisTypeLabel = "">
<cfswitch expression="#getFis.fis_type#">
    <cfcase value="1"><cfset fisTypeLabel = "STOK GİRİŞ FİŞİ"></cfcase>
    <cfcase value="2"><cfset fisTypeLabel = "STOK ÇIKIŞ FİŞİ"></cfcase>
    <cfcase value="3"><cfset fisTypeLabel = "STOK TRANSFER FİŞİ"></cfcase>
    <cfcase value="4"><cfset fisTypeLabel = "STOK SAYIM FİŞİ"></cfcase>
    <cfdefaultcase><cfset fisTypeLabel = "STOK FİŞİ"></cfdefaultcase>
</cfswitch>

<!--- Tarih biçimlendirme --->
<cfset fisTarih      = isDate(getFis.fis_date)     ? dateFormat(getFis.fis_date,     "dd.mm.yyyy") & " " & timeFormat(getFis.fis_date,     "HH:mm") : "">
<cfset deliverTarih  = isDate(getFis.deliver_date)  ? dateFormat(getFis.deliver_date,  "dd.mm.yyyy") : "">
<cfset kayitTarih    = isDate(getFis.record_date)   ? dateFormat(getFis.record_date,   "dd.mm.yyyy") & " " & timeFormat(getFis.record_date,   "HH:mm") : "">

<!--- Toplam miktar --->
<cfset toplamMiktar = 0>
<cfloop query="getFisRow">
    <cfset toplamMiktar = toplamMiktar + val(getFisRow.amount)>
</cfloop>

<cfoutput>
<style>
/* ===== STOK FİŞİ PRINT ŞABLONU ===== */
.sf-wrap {
    font-family: Arial, Helvetica, sans-serif;
    font-size: 12px;
    color: ##1a1a1a;
    max-width: 800px;
    margin: 0 auto;
    padding: 12px;
}
/* Başlık kutusu */
.sf-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border: 2px solid ##2c3e50;
    border-radius: 4px;
    margin-bottom: 10px;
    overflow: hidden;
}
.sf-header-left {
    padding: 10px 14px;
    flex: 1;
}
.sf-header-left .sf-company {
    font-size: 16px;
    font-weight: bold;
    color: ##2c3e50;
}
.sf-header-left .sf-company-sub {
    font-size: 11px;
    color: ##555;
    margin-top: 2px;
}
.sf-header-right {
    background: ##2c3e50;
    color: ##fff;
    padding: 10px 18px;
    text-align: center;
    min-width: 180px;
}
.sf-header-right .sf-doc-type {
    font-size: 13px;
    font-weight: bold;
    letter-spacing: 0.5px;
}
.sf-header-right .sf-doc-no {
    font-size: 19px;
    font-weight: bold;
    margin-top: 4px;
    letter-spacing: 1px;
}
.sf-header-right .sf-doc-date {
    font-size: 11px;
    margin-top: 4px;
    opacity: 0.85;
}
/* Bilgi satırları */
.sf-info-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 6px;
    margin-bottom: 10px;
}
.sf-info-box {
    border: 1px solid ##bdc3cb;
    border-radius: 3px;
    padding: 5px 8px;
}
.sf-info-box .label {
    font-size: 10px;
    color: ##777;
    text-transform: uppercase;
    font-weight: bold;
    margin-bottom: 2px;
}
.sf-info-box .value {
    font-size: 12px;
    font-weight: 600;
    color: ##1a1a1a;
    min-height: 16px;
}
/* Detay notu */
.sf-detail-box {
    border: 1px solid ##bdc3cb;
    border-radius: 3px;
    padding: 5px 8px;
    margin-bottom: 10px;
}
.sf-detail-box .label {
    font-size: 10px;
    color: ##777;
    text-transform: uppercase;
    font-weight: bold;
    margin-bottom: 2px;
}
/* Tablo */
.sf-table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 10px;
    font-size: 11.5px;
}
.sf-table thead tr {
    background: ##2c3e50;
    color: ##fff;
}
.sf-table thead th {
    padding: 6px 7px;
    text-align: left;
    font-weight: 600;
    font-size: 11px;
}
.sf-table thead th.text-right { text-align: right; }
.sf-table thead th.text-center { text-align: center; }
.sf-table tbody tr:nth-child(even) { background: ##f5f7f9; }
.sf-table tbody tr:hover { background: ##eaf0f8; }
.sf-table tbody td {
    padding: 5px 7px;
    border-bottom: 1px solid ##e2e6ea;
    vertical-align: middle;
}
.sf-table tbody td.text-right { text-align: right; }
.sf-table tbody td.text-center { text-align: center; }
.sf-table tfoot tr {
    background: ##ecf0f1;
    font-weight: bold;
}
.sf-table tfoot td {
    padding: 6px 7px;
    border-top: 2px solid ##2c3e50;
}
/* İmza satırı */
.sf-sign-row {
    display: flex;
    gap: 12px;
    margin-top: 18px;
}
.sf-sign-box {
    flex: 1;
    border-top: 1px solid ##1a1a1a;
    padding-top: 4px;
    text-align: center;
    font-size: 11px;
    color: ##444;
}
/* Footer */
.sf-footer {
    text-align: center;
    font-size: 10px;
    color: ##aaa;
    margin-top: 14px;
    border-top: 1px solid ##dee2e6;
    padding-top: 5px;
}
/* Yazdırma */
@@media print {
    .sf-wrap { padding: 0; }
    .sf-table tbody tr:hover { background: inherit; }
}
</style>

<div class="sf-wrap">

    <!--- BAŞLIK --->
    <div class="sf-header">
        <div class="sf-header-left">
            <div class="sf-company">RASİH ÇELİK BOYAHANE</div>
            <div class="sf-company-sub">Stok Yönetim Sistemi</div>
        </div>
        <div class="sf-header-right">
            <div class="sf-doc-type">#fisTypeLabel#</div>
            <div class="sf-doc-no">#htmlEditFormat(getFis.fis_number ?: "---")#</div>
            <div class="sf-doc-date">#fisTarih#</div>
        </div>
    </div>

    <!--- BİLGİ ALANLARI --->
    <div class="sf-info-grid">

        <div class="sf-info-box">
            <div class="label">Fiş No</div>
            <div class="value">#htmlEditFormat(getFis.fis_number ?: "—")#</div>
        </div>
        <div class="sf-info-box">
            <div class="label">Fiş Tarihi</div>
            <div class="value">#fisTarih#</div>
        </div>
        <div class="sf-info-box">
            <div class="label">Teslim Tarihi</div>
            <div class="value">#deliverTarih != "" ? deliverTarih : "—"#</div>
        </div>

        <cfif getFis.fis_type eq 2 OR getFis.fis_type eq 3>
        <div class="sf-info-box">
            <div class="label">Çıkış Deposu</div>
            <div class="value">
                #htmlEditFormat(getFis.dep_out_name ?: "")#
                <cfif len(trim(getFis.loc_out_name ?: ""))> — #htmlEditFormat(getFis.loc_out_name)#</cfif>
            </div>
        </div>
        </cfif>

        <cfif getFis.fis_type eq 1 OR getFis.fis_type eq 3>
        <div class="sf-info-box">
            <div class="label">Giriş Deposu</div>
            <div class="value">
                #htmlEditFormat(getFis.dep_in_name ?: "")#
                <cfif len(trim(getFis.loc_in_name ?: ""))> — #htmlEditFormat(getFis.loc_in_name)#</cfif>
            </div>
        </div>
        </cfif>

        <cfif getFis.fis_type eq 4>
        <div class="sf-info-box">
            <div class="label">Sayım Deposu</div>
            <div class="value">
                <cfset sayimDep = len(trim(getFis.dep_out_name ?: "")) ? getFis.dep_out_name : getFis.dep_in_name>
                <cfset sayimLoc = len(trim(getFis.loc_out_name ?: "")) ? getFis.loc_out_name : getFis.loc_in_name>
                #htmlEditFormat(sayimDep ?: "—")#
                <cfif len(trim(sayimLoc ?: ""))> — #htmlEditFormat(sayimLoc)#</cfif>
            </div>
        </div>
        </cfif>

        <div class="sf-info-box">
            <div class="label">Sorumlu</div>
            <div class="value">#htmlEditFormat(getFis.emp_fullname ?: "—")#</div>
        </div>
        <div class="sf-info-box">
            <div class="label">Referans No</div>
            <div class="value">#len(trim(getFis.ref_no ?: "")) ? htmlEditFormat(getFis.ref_no) : "—"#</div>
        </div>

        <cfif val(getFis.prod_order_number ?: 0) gt 0>
        <div class="sf-info-box">
            <div class="label">Üretim Emri</div>
            <div class="value">#getFis.prod_order_number#</div>
        </div>
        </cfif>

        <div class="sf-info-box">
            <div class="label">Kayıt Tarihi</div>
            <div class="value">#kayitTarih#</div>
        </div>

    </div>

    <!--- AÇIKLAMA --->
    <cfif len(trim(getFis.fis_detail ?: ""))>
    <div class="sf-detail-box">
        <div class="label">Açıklama / Not</div>
        <div style="margin-top:3px; font-size:12px;">#htmlEditFormat(getFis.fis_detail)#</div>
    </div>
    </cfif>

    <!--- SATIRLAR TABLOSU --->
    <table class="sf-table">
        <thead>
            <tr>
                <th style="width:30px;" class="text-center">##</th>
                <th>Ürün Kodu</th>
                <th>Ürün Adı</th>
                <th>Özellik</th>
                <th>Stok Kodu</th>
                <th>Lot No</th>
                <th class="text-right" style="width:70px;">Miktar</th>
                <th style="width:45px;">Birim</th>
                <cfif getFis.fis_type eq 3>
                <th class="text-center" style="width:55px;">Çıkış Raf</th>
                <th class="text-center" style="width:55px;">Giriş Raf</th>
                <cfelse>
                <th class="text-center" style="width:55px;">Raf</th>
                </cfif>
            </tr>
        </thead>
        <tbody>
            <cfif getFisRow.recordCount>
                <cfloop query="getFisRow">
                    <cfset pName = len(trim(getFisRow.product_name ?: "")) ? getFisRow.product_name : getFisRow.product_name2>
                    <tr>
                        <td class="text-center">#getFisRow.currentRow#</td>
                        <td>#htmlEditFormat(getFisRow.product_code ?: "—")#</td>
                        <td><strong>#htmlEditFormat(pName ?: "—")#</strong></td>
                        <td>#htmlEditFormat(getFisRow.property ?: "")#</td>
                        <td>#htmlEditFormat(getFisRow.stock_code ?: "")#</td>
                        <td>#htmlEditFormat(getFisRow.lot_no ?: "")#</td>
                        <td class="text-right">#numberFormat(val(getFisRow.amount), "__.___,__")#</td>
                        <td>#htmlEditFormat(getFisRow.unit ?: "")#</td>
                        <cfif getFis.fis_type eq 3>
                        <td class="text-center">#val(getFisRow.shelf_number ?: 0) gt 0 ? getFisRow.shelf_number : "—"#</td>
                        <td class="text-center">#val(getFisRow.to_shelf_number ?: 0) gt 0 ? getFisRow.to_shelf_number : "—"#</td>
                        <cfelse>
                        <td class="text-center">#val(getFisRow.shelf_number ?: 0) gt 0 ? getFisRow.shelf_number : "—"#</td>
                        </cfif>
                    </tr>
                    <cfif len(trim(getFisRow.detail_info_extra ?: ""))>
                    <tr>
                        <td></td>
                        <td colspan="<cfif getFis.fis_type eq 3>9<cfelse>8</cfif>" style="font-size:10.5px; color:##555; padding-top:0; border-bottom:1px dashed ##ddd;">
                            &nbsp;&nbsp;&rarr; #htmlEditFormat(getFisRow.detail_info_extra)#
                        </td>
                    </tr>
                    </cfif>
                </cfloop>
            <cfelse>
                <tr>
                    <td colspan="<cfif getFis.fis_type eq 3>10<cfelse>9</cfif>" class="text-center" style="padding:14px; color:##888;">
                        Fiş satırı bulunamadı.
                    </td>
                </tr>
            </cfif>
        </tbody>
        <tfoot>
            <tr>
                <td colspan="<cfif getFis.fis_type eq 3>6<cfelse>6</cfif>">Toplam: <strong>#getFisRow.recordCount#</strong> kalem</td>
                <td class="text-right"><strong>#numberFormat(toplamMiktar, "__.___,__")#</strong></td>
                <td colspan="<cfif getFis.fis_type eq 3>3<cfelse>2</cfif>"></td>
            </tr>
        </tfoot>
    </table>

    <!--- İMZA ALANLARI --->
    <div class="sf-sign-row">
        <div class="sf-sign-box">Hazırlayan</div>
        <div class="sf-sign-box">Teslim Eden</div>
        <div class="sf-sign-box">Teslim Alan</div>
        <div class="sf-sign-box">Onaylayan</div>
    </div>

    <!--- FOOTER --->
    <div class="sf-footer">
        #fisTypeLabel# &bull; #getFis.fis_number ?: ""# &bull; Yazdırma: #dateFormat(now(), "dd.mm.yyyy")# #timeFormat(now(), "HH:mm")#
    </div>

</div>
</cfoutput>
