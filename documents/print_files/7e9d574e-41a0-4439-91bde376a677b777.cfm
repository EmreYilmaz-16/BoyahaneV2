<cfprocessingdirective pageEncoding="utf-8">
<cfparam name="url.doc_id" default="0">
<cfset docId = val(isDefined("request.docId") ? request.docId : url.doc_id)>

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
    <div style="font-family:monospace;padding:8px;">Fiş bulunamadı.</div>
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

<cfset fisTarih   = isDate(getFis.fis_date)    ? dateFormat(getFis.fis_date,    "dd.mm.yyyy") & " " & timeFormat(getFis.fis_date,    "HH:mm") : "">
<cfset deliverTarih = isDate(getFis.deliver_date) ? dateFormat(getFis.deliver_date, "dd.mm.yyyy") : "">

<cfset toplamMiktar = 0>
<cfloop query="getFisRow">
    <cfset toplamMiktar = toplamMiktar + val(getFisRow.amount)>
</cfloop>

<cfoutput>
<style>
/* ===== FİŞ YAZICI ŞABLONU — 80 mm termal -===== */
* { box-sizing: border-box; margin: 0; padding: 0; }
body { background: ##fff; }
.tr-wrap {
    font-family: "Courier New", Courier, monospace;
    font-size: 12px;
    color: ##000;
    width: 302px;           /* 80mm @ 96dpi ≈ 302px */
    margin: 0 auto;
    padding: 4px 0;
    background: ##fff;
}
.tr-center  { text-align: center; }
.tr-right   { text-align: right; }
.tr-bold    { font-weight: bold; }
.tr-big     { font-size: 14px; font-weight: bold; }
.tr-small   { font-size: 10px; }
.tr-sep     { border-top: 1px dashed ##000; margin: 4px 0; }
.tr-sep-solid { border-top: 2px solid ##000; margin: 4px 0; }
.tr-row {
    display: flex;
    justify-content: space-between;
    gap: 4px;
    padding: 1px 0;
}
.tr-row .tr-lbl { color: ##333; white-space: nowrap; }
.tr-row .tr-val { text-align: right; overflow-wrap: break-word; word-break: break-all; }
.tr-product-line {
    padding: 3px 0;
    border-bottom: 1px dotted ##bbb;
}
.tr-product-name {
    font-weight: bold;
    font-size: 12px;
    word-break: break-word;
}
.tr-product-sub {
    font-size: 10px;
    color: ##333;
}
.tr-product-qty {
    display: flex;
    justify-content: space-between;
    font-size: 12px;
    margin-top: 1px;
}
.tr-footer {
    font-size: 10px;
    text-align: center;
    color: ##555;
    margin-top: 4px;
}
@@media print {
    body { margin: 0; }
    .tr-wrap { width: 100%; }
}
</style>

<div class="tr-wrap">

    <!--- FIRMA BAŞLIĞI --->
    <div class="tr-center tr-bold" style="font-size:13px; letter-spacing:1px;">RASİH ÇELİK</div>
    <div class="tr-center tr-small">BOYAHANE</div>

    <div class="tr-sep-solid"></div>

    <!--- FİŞ TÜRÜ --->
    <div class="tr-center tr-big">#fisTypeLabel#</div>

    <div class="tr-sep"></div>

    <!--- TEMEL BİLGİLER --->
    <div class="tr-row">
        <span class="tr-lbl">Fiş No :</span>
        <span class="tr-val tr-bold">#htmlEditFormat(getFis.fis_number ?: "---")#</span>
    </div>
    <div class="tr-row">
        <span class="tr-lbl">Tarih  :</span>
        <span class="tr-val">#fisTarih#</span>
    </div>
    <cfif deliverTarih neq "">
    <div class="tr-row">
        <span class="tr-lbl">Teslim :</span>
        <span class="tr-val">#deliverTarih#</span>
    </div>
    </cfif>
    <cfif len(trim(getFis.emp_fullname ?: ""))>
    <div class="tr-row">
        <span class="tr-lbl">Soruml.:</span>
        <span class="tr-val">#htmlEditFormat(getFis.emp_fullname)#</span>
    </div>
    </cfif>

    <!--- DEPO BİLGİSİ --->
    <cfif getFis.fis_type eq 1>
    <div class="tr-row">
        <span class="tr-lbl">Giriş D:</span>
        <span class="tr-val">
            #htmlEditFormat(getFis.dep_in_name ?: "")#
            <cfif len(trim(getFis.loc_in_name ?: ""))>/#htmlEditFormat(getFis.loc_in_name)#</cfif>
        </span>
    </div>
    <cfelseif getFis.fis_type eq 2>
    <div class="tr-row">
        <span class="tr-lbl">Çıkış D:</span>
        <span class="tr-val">
            #htmlEditFormat(getFis.dep_out_name ?: "")#
            <cfif len(trim(getFis.loc_out_name ?: ""))>/#htmlEditFormat(getFis.loc_out_name)#</cfif>
        </span>
    </div>
    <cfelseif getFis.fis_type eq 3>
    <div class="tr-row">
        <span class="tr-lbl">Çıkış D:</span>
        <span class="tr-val">
            #htmlEditFormat(getFis.dep_out_name ?: "")#
            <cfif len(trim(getFis.loc_out_name ?: ""))>/#htmlEditFormat(getFis.loc_out_name)#</cfif>
        </span>
    </div>
    <div class="tr-row">
        <span class="tr-lbl">Giriş D:</span>
        <span class="tr-val">
            #htmlEditFormat(getFis.dep_in_name ?: "")#
            <cfif len(trim(getFis.loc_in_name ?: ""))>/#htmlEditFormat(getFis.loc_in_name)#</cfif>
        </span>
    </div>
    </cfif>

    <cfif len(trim(getFis.ref_no ?: ""))>
    <div class="tr-row">
        <span class="tr-lbl">Ref    :</span>
        <span class="tr-val">#htmlEditFormat(getFis.ref_no)#</span>
    </div>
    </cfif>

    <div class="tr-sep"></div>

    <!--- ÜRÜN SATIRLARI --->
    <cfif getFisRow.recordCount>
        <cfloop query="getFisRow">
            <cfset pName = len(trim(getFisRow.product_name ?: "")) ? getFisRow.product_name : getFisRow.product_name2>
            <div class="tr-product-line">
                <div class="tr-product-name">#getFisRow.currentRow#. #htmlEditFormat(pName ?: "—")#</div>
                <cfif len(trim(getFisRow.stock_code ?: "")) OR len(trim(getFisRow.property ?: ""))>
                <div class="tr-product-sub">
                    <cfif len(trim(getFisRow.stock_code ?: ""))>#htmlEditFormat(getFisRow.stock_code)# </cfif>
                    <cfif len(trim(getFisRow.property ?: ""))>#htmlEditFormat(getFisRow.property)#</cfif>
                </div>
                </cfif>
                <cfif len(trim(getFisRow.lot_no ?: ""))>
                <div class="tr-product-sub">Lot: #htmlEditFormat(getFisRow.lot_no)#</div>
                </cfif>
                <cfif val(getFisRow.shelf_number ?: 0) gt 0>
                <div class="tr-product-sub">
                    Raf: #getFisRow.shelf_number#
                    <cfif getFis.fis_type eq 3 AND val(getFisRow.to_shelf_number ?: 0) gt 0>
                        &rarr; #getFisRow.to_shelf_number#
                    </cfif>
                </div>
                </cfif>
                <div class="tr-product-qty">
                    <span></span>
                    <span class="tr-bold">#numberFormat(val(getFisRow.amount), "__.___,__")# #htmlEditFormat(getFisRow.unit ?: "")#</span>
                </div>
                <cfif len(trim(getFisRow.detail_info_extra ?: ""))>
                <div class="tr-product-sub" style="margin-top:1px;">&gt; #htmlEditFormat(getFisRow.detail_info_extra)#</div>
                </cfif>
            </div>
        </cfloop>
    <cfelse>
        <div class="tr-center tr-small" style="padding:6px 0;">Satır bulunamadı.</div>
    </cfif>

    <div class="tr-sep-solid"></div>

    <!--- TOPLAM --->
    <div class="tr-row">
        <span class="tr-lbl">Toplam Kalem :</span>
        <span class="tr-val tr-bold">#getFisRow.recordCount#</span>
    </div>
    <div class="tr-row">
        <span class="tr-lbl">Toplam Miktar:</span>
        <span class="tr-val tr-bold">#numberFormat(toplamMiktar, "__.___,__")#</span>
    </div>

    <cfif len(trim(getFis.fis_detail ?: ""))>
    <div class="tr-sep"></div>
    <div style="font-size:10px; word-break:break-word;">Not: #htmlEditFormat(getFis.fis_detail)#</div>
    </cfif>

    <div class="tr-sep"></div>

    <!--- İMZA --->
    <div style="display:flex; justify-content:space-between; margin-top:14px; font-size:10px;">
        <div style="text-align:center; width:45%;">
            <div style="border-top:1px solid ##000; padding-top:2px;">Teslim Eden</div>
        </div>
        <div style="text-align:center; width:45%;">
            <div style="border-top:1px solid ##000; padding-top:2px;">Teslim Alan</div>
        </div>
    </div>

    <!--- FOOTER --->
    <div class="tr-sep"></div>
    <div class="tr-footer">#dateFormat(now(),"dd.mm.yyyy")# #timeFormat(now(),"HH:mm")#</div>

</div>
</cfoutput>
