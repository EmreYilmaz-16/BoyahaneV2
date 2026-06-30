<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">

<cfparam name="url.p_order_id" default="0">
<cfset pOrderId = isNumeric(url.p_order_id) AND val(url.p_order_id) gt 0 ? val(url.p_order_id) : 0>

<cfif pOrderId eq 0>
    <cflocation url="index.cfm?fuseaction=production.list_production_orders" addtoken="false">
</cfif>
<cfquery name="getParams" datasource="boyahane">
    SELECT parametre_adi,deger
    FROM boyahane_params
</cfquery>
<cfloop query="getParams">
    <cfset paramName = trim(parametre_adi)>
    <cfset paramValue = trim(deger)>
    <cfif len(paramName) AND NOT structKeyExists(application, paramName)>
        <cfset application[paramName] = paramValue>
    </cfif>
</cfloop>


<cfquery name="getOrder" datasource="boyahane">
    SELECT po.*,
           COALESCE(po.plan_water_amount, 0) AS plan_water_amount,
           COALESCE(ci.color_code, s.stock_code, '') AS color_code,
           COALESCE(ci.color_name, s.property, '') AS color_name,
           COALESCE(ci.renk_no, '') AS renk_no,
           COALESCE(ci.kartela_no, '') AS kartela_no,
           ci.kartela_date,
           COALESCE(ci.renk_tonu, 0) AS renk_tonu,
           COALESCE(ci.boya_derecesi, '') AS boya_derecesi,
           COALESCE(ci.information, '') AS color_information,
           COALESCE(ci.flote, 0) AS flote,
           COALESCE(s.stock_code, '') AS stock_code,
           COALESCE(s.property, '') AS stock_property,
           COALESCE(p.product_name, po.product_name2, '') AS product_name,
           COALESCE(pc.product_cat, '') AS product_cat,
           COALESCE(pc.product_catid, 0) AS product_catid,
           COALESCE(ws.station_name, '') AS station_name,
           COALESCE(ws.min_water_amount, 0) AS min_water_amount,
           COALESCE(ws.max_water_amount, 0) AS max_water_amount,
           COALESCE(o.order_number, '') AS order_number,
           COALESCE(oc.nickname, oc.fullname, cc.nickname, cc.fullname, '') AS company_name,
           COALESCE(o.order_detail, '') AS order_detail
    FROM production_orders po
    LEFT JOIN stocks s       ON po.stock_id = s.stock_id
    LEFT JOIN product p      ON s.product_id = p.product_id
    LEFT JOIN product_cat pc ON p.product_catid = pc.product_catid
    LEFT JOIN color_info ci  ON po.stock_id = ci.stock_id
    LEFT JOIN company cc     ON ci.company_id = cc.company_id
    LEFT JOIN orders o       ON po.order_id = o.order_id
    LEFT JOIN company oc     ON o.company_id = oc.company_id
    LEFT JOIN workstations ws ON po.station_id = ws.station_id
    WHERE po.p_order_id = <cfqueryparam value="#pOrderId#" cfsqltype="cf_sql_integer">
</cfquery>

<cfif NOT getOrder.recordCount>
    <cflocation url="index.cfm?fuseaction=production.list_production_orders" addtoken="false">
</cfif>

<cfset planWater = val(getOrder.plan_water_amount)>
<cfif planWater lte 0 AND val(getOrder.flote) gt 0 AND val(getOrder.quantity) gt 0>
    <cfset planWater = val(getOrder.flote) * val(getOrder.quantity)>
</cfif>
<cfif planWater lte 0 AND val(getOrder.max_water_amount) gt 0>
    <cfset planWater = val(getOrder.max_water_amount)>
</cfif>


<cfquery name="getRecipe" datasource="boyahane">
    SELECT pt.product_tree_id,
           COALESCE(pt.related_product_tree_id, 0) AS parent_tree_id,
           COALESCE(pt.operation_type_id, 0) AS operation_type_id,
           COALESCE(ot.operation_code, '') AS operation_code,
           COALESCE(ot.operation_type, ot.product_name, 'PROGRAM') AS operation_name,
           COALESCE(pt.related_id, pt.stock_id, 0) AS material_stock_id,
           COALESCE(rs.stock_code, '') AS material_code,
           COALESCE(rp.product_name, '') AS material_name,
           COALESCE(rpc.product_cat, '') AS material_cat,
           COALESCE(rpc.product_catid, 0) AS product_catid,
           COALESCE(pt.amount, 0) AS ratio_amount,
           COALESCE(pt.line_number, 0) AS line_number,
           COALESCE(pt.detail, '') AS detail
    FROM product_tree pt
    LEFT JOIN operation_types ot ON pt.operation_type_id = ot.operation_type_id
    LEFT JOIN stocks rs         ON pt.related_id = rs.stock_id
    LEFT JOIN product rp        ON rs.product_id = rp.product_id
    LEFT JOIN product_cat rpc   ON rp.product_catid = rpc.product_catid
    WHERE pt.stock_id = <cfqueryparam value="#val(getOrder.stock_id)#" cfsqltype="cf_sql_integer">
    ORDER BY COALESCE(pt.related_product_tree_id, pt.product_tree_id), COALESCE(pt.line_number, 0), pt.product_tree_id
</cfquery>

<cfset opOrder = []>
<cfset opMap = {}>
<cfloop query="getRecipe">
    <cfif val(operation_type_id) gt 0>
        <cfset opKey = "op_" & val(product_tree_id)>
        <cfset opMap[opKey] = {"product_tree_id": val(product_tree_id), "code": operation_code ?: "", "name": operation_name ?: "PROGRAM", "rows": []}>
        <cfset arrayAppend(opOrder, opKey)>
    </cfif>
</cfloop>
<cfloop query="getRecipe">
    <cfif val(operation_type_id) eq 0 AND val(parent_tree_id) gt 0>
        <cfset opKey = "op_" & val(parent_tree_id)>
        <cfif structKeyExists(opMap, opKey)>
            <cfset rowText = ucase((material_code ?: "") & " " & (material_name ?: "") & " " & (material_cat ?: "") & " " & (detail ?: ""))>
            <cfif structKeyExists(application, "boya_kategori_ids")>
            <cfif listFindNoCase(application.boya_kategori_ids, val(product_catid))>
                <cfset isDye = true>
                <cfelse>
                <cfset isDye = false>
            </cfif>
            <cfelse>
                <cfset isDye = findNoCase("BOYA", rowText) OR findNoCase("DYE", rowText) OR findNoCase("REAKTIF", rowText) OR findNoCase("REACTIVE", rowText)>
            </cfif>
            
            <cfset calcBase = isDye ? val(getOrder.quantity) : planWater>
            <cfset calcAmount = calcBase * val(ratio_amount)>
            <cfset arrayAppend(opMap[opKey].rows, {
                "group": isDye ? "Boya" : "Kimyevi",
                "name": len(trim(material_name)) ? material_name : material_code,
                "ratio": val(ratio_amount),
                "amount": calcAmount
            })>
        </cfif>
    </cfif>
</cfloop>

<cfset printDate = isDate(getOrder.start_date) ? getOrder.start_date : now()>
<cfset planNo = len(trim(getOrder.p_order_no)) ? getOrder.p_order_no : pOrderId>
<cfset partiCode = len(trim(getOrder.lot_no)) ? getOrder.lot_no : (len(trim(getOrder.group_lot_no)) ? getOrder.group_lot_no : getOrder.order_number)>

<style>
:root{--ink:#172033;--muted:#637083;--line:#d8dee8;--soft:#f3f6fa;--accent:#173f70;--accent-soft:#eaf1f8}
*{box-sizing:border-box}.recipe-screen{background:#edf1f5;margin:-15px;padding:22px;min-height:100vh;color:var(--ink);font-family:Arial,Helvetica,sans-serif}.print-toolbar{width:210mm;max-width:100%;margin:0 auto 12px;display:flex;align-items:center;justify-content:space-between}.toolbar-note{color:var(--muted);font-size:12px}.toolbar-actions{display:flex;gap:8px}.recipe-btn{border:0;border-radius:7px;padding:9px 14px;font-weight:700;cursor:pointer;background:#fff;color:var(--ink);box-shadow:0 1px 3px rgba(23,32,51,.14)}.recipe-btn.primary{background:var(--accent);color:#fff}.recipe-page{width:210mm;min-height:297mm;margin:0 auto;background:#fff;padding:10mm;box-shadow:0 8px 30px rgba(23,32,51,.12);font-size:10px}.recipe-box{min-height:277mm;border:1px solid var(--line);border-radius:10px;overflow:hidden;display:flex;flex-direction:column}.recipe-head{display:grid;grid-template-columns:1fr 180px 178px;align-items:stretch;background:var(--ink);color:#fff}.title-wrap{padding:16px 18px}.recipe-kicker{font-size:9px;font-weight:700;letter-spacing:2.3px;text-transform:uppercase;color:#b8c7da;margin-bottom:4px}.recipe-title{font-size:29px;line-height:1;font-weight:900;letter-spacing:8px}.brand{font-family:Georgia,serif;font-style:italic;font-size:16px;font-weight:400;letter-spacing:0;margin-left:5px;color:#dce7f3}.head-meta{display:grid;align-content:center;padding:10px 14px;border-left:1px solid rgba(255,255,255,.18)}.meta-line{display:flex;justify-content:space-between;gap:10px;padding:3px 0;font-size:10px;color:#dce7f3}.meta-line strong{font-size:12px;color:#fff}.barcode{padding:11px 14px;text-align:center;border-left:1px solid rgba(255,255,255,.18);display:flex;flex-direction:column;justify-content:center}.barcode-bars{height:34px;background:repeating-linear-gradient(90deg,#fff 0 2px,transparent 2px 4px,#fff 4px 5px,transparent 5px 8px,#fff 8px 11px,transparent 11px 13px);opacity:.94}.barcode-code{font-size:9px;letter-spacing:3px;margin-top:5px;color:#dce7f3}.recipe-content{display:flex;min-height:228mm;flex:1;flex-direction:column}.section{padding:12px 14px;border-bottom:1px solid var(--line)}.section-title{font-size:9px;line-height:1;font-weight:800;letter-spacing:1.5px;text-transform:uppercase;color:var(--accent);margin-bottom:10px}.info-grid{display:grid;grid-template-columns:1.35fr .85fr;gap:22px}.field-grid{display:grid;grid-template-columns:1fr 1fr;gap:8px 18px}.field{min-width:0}.field.wide,.stat.wide{grid-column:1/-1}.field .lbl{display:block;color:var(--muted);font-size:8px;font-weight:700;letter-spacing:.45px;text-transform:uppercase;margin-bottom:2px}.field .val{display:block;font-weight:800;font-size:11px;line-height:1.25;overflow-wrap:anywhere}.stats{display:grid;grid-template-columns:1fr 1fr;gap:7px}.stat{background:var(--soft);border-radius:6px;padding:7px 9px}.stat .lbl{display:block;color:var(--muted);font-size:8px;font-weight:700;text-transform:uppercase;letter-spacing:.4px}.stat .val{display:block;font-size:15px;font-weight:900;margin-top:2px}.stat.accent{background:var(--accent-soft);color:var(--accent)}.party-strip{display:grid;grid-template-columns:.6fr 1.45fr 1fr .55fr .55fr;background:var(--soft);border-bottom:1px solid var(--line)}.party-cell{padding:7px 10px;border-right:1px solid var(--line);min-width:0}.party-cell:last-child{border-right:0}.party-cell .lbl{display:block;color:var(--muted);font-size:7px;font-weight:700;text-transform:uppercase;letter-spacing:.45px;margin-bottom:2px}.party-cell .val{display:block;font-size:9px;font-weight:800;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.programs{padding:12px 14px 4px}.program-block{border:1px solid var(--line);border-radius:7px;overflow:hidden;margin-bottom:8px;break-inside:avoid}.program-head{display:grid;grid-template-columns:78px 1fr 70px;align-items:center;background:var(--accent-soft);color:var(--accent);min-height:32px}.program-head>div{padding:6px 9px;border-right:1px solid #d0ddea}.program-head>div:last-child{border-right:0;text-align:center}.program-label{display:block;font-size:7px;text-transform:uppercase;letter-spacing:.55px;color:var(--muted);margin-bottom:1px}.program-value{display:block;font-size:10px;font-weight:900}.program-table{width:100%;border-collapse:collapse}.program-table th{padding:4px 7px;background:#f9fafc;color:var(--muted);font-size:7px;letter-spacing:.35px;text-transform:uppercase;text-align:left;border-bottom:1px solid var(--line)}.program-table td{padding:4px 7px;border-bottom:1px solid #edf0f4;font-size:8.5px}.program-table tbody tr:last-child td{border-bottom:0}.program-table .group-pill{display:inline-block;border-radius:10px;background:var(--soft);padding:2px 6px;font-size:7px;font-weight:700;color:var(--muted)}.program-table .dye{background:var(--accent-soft);color:var(--accent)}.num{text-align:right!important;font-variant-numeric:tabular-nums}.bold{font-weight:900}.empty-recipe{padding:16px;color:var(--muted);text-align:center}.plan-note{margin:0 14px 10px;padding:7px 9px;border-left:3px solid var(--accent);background:var(--soft);color:var(--muted);font-size:8px}.notes{display:grid;grid-template-columns:1fr 1fr;gap:10px;padding:10px 14px 14px;margin-top:auto}.note{min-height:22mm;border:1px solid var(--line);border-radius:7px;overflow:hidden}.note-title{font-size:8px;font-weight:800;letter-spacing:.8px;color:var(--accent);background:var(--accent-soft);padding:6px 8px;text-transform:uppercase}.note-body{padding:8px;font-size:9px;line-height:1.35}.footer{display:flex;justify-content:space-between;align-items:center;padding:7px 14px;background:var(--ink);color:#b8c7da;font-size:7px;letter-spacing:.5px}.footer strong{color:#fff}
/* Beyaz, yazıcı dostu başlık ve alt bilgi */
.recipe-head{grid-template-columns:minmax(0,1fr) 170px 145px;background:#fff;color:var(--ink);border-bottom:2px solid var(--ink)}
.recipe-head>*,.title-wrap,.head-meta,.barcode{min-width:0}
.recipe-kicker,.meta-line,.barcode-code{color:var(--muted)}
.meta-line strong,.recipe-title,.brand{color:var(--ink)}
.head-meta,.barcode{border-left:1px solid var(--line)}
.barcode-bars{background:repeating-linear-gradient(90deg,var(--ink) 0 2px,transparent 2px 4px,var(--ink) 4px 5px,transparent 5px 8px,var(--ink) 8px 11px,transparent 11px 13px)}
.barcode-code{font-size:7px;letter-spacing:2px;white-space:nowrap;overflow:hidden}
.program-table{table-layout:fixed}
.program-table th,.program-table td{overflow-wrap:anywhere}
.program-table th:nth-child(1){width:12%}.program-table th:nth-child(2){width:7%}.program-table th:nth-child(3){width:48%}.program-table th:nth-child(4){width:16%}.program-table th:nth-child(5){width:17%}
.notes{margin-top:0}
.recipe-footer{display:flex;justify-content:space-between;align-items:center;padding:7px 14px;background:#fff;color:var(--muted);border-top:1px solid var(--line);font-size:7px;letter-spacing:.5px}
.recipe-footer strong{color:var(--ink)}
body>footer.footer{display:none!important}
/* Uzun reçeteler için yoğun bilgi düzeni */
.title-wrap{padding:10px 14px}.recipe-kicker{font-size:7px;margin-bottom:3px}.recipe-title{font-size:23px;letter-spacing:6px}.brand{font-size:13px}.head-meta{padding:7px 10px}.meta-line{padding:2px 0;font-size:8px}.meta-line strong{font-size:9px}.barcode{padding:7px 10px}.barcode-bars{height:27px}.section{padding:8px 11px}.section-title{font-size:7px;margin-bottom:6px}.info-grid{gap:14px}.field-grid{gap:5px 13px}.field .lbl,.stat .lbl{font-size:6.5px}.field .val{font-size:9px}.stats{gap:4px}.stat{padding:4px 6px;border-radius:4px}.stat .val{font-size:11px;margin-top:1px}.party-cell{padding:4px 7px}.party-cell .lbl{font-size:6px}.party-cell .val{font-size:7.5px}.programs{padding:8px 10px 2px}.program-block{margin-bottom:5px;border-radius:4px}.program-head{grid-template-columns:65px 1fr 52px;min-height:25px}.program-head>div{padding:3px 6px}.program-label{font-size:6px}.program-value{font-size:8px}.program-table th{padding:2px 5px;font-size:6px}.program-table td{padding:2px 5px;font-size:7px;line-height:1.15}.program-table .group-pill{padding:1px 4px;font-size:6px}.plan-note{margin:0 10px 5px;padding:4px 6px;font-size:6.5px}.notes{gap:6px;padding:5px 10px 8px}.note{min-height:14mm;border-radius:4px}.note-title{padding:3px 6px;font-size:6.5px}.note-body{padding:5px 6px;font-size:7px}.recipe-footer{padding:4px 10px;font-size:6px}
/* Üst bilgiler tek satır: Etiket : Değer */
.section{padding-top:6px;padding-bottom:6px}.info-grid{grid-template-columns:1.45fr .75fr;gap:10px}.field-grid{gap:3px 12px}.field{display:grid;grid-template-columns:68px minmax(0,1fr);align-items:baseline;column-gap:4px;min-height:15px}.field .lbl{margin:0;white-space:nowrap}.field .lbl:after,.stat .lbl:after{content:":";margin-left:1px}.field .val{font-size:8px;line-height:1.1;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.stats{gap:3px}.stat{display:flex;align-items:baseline;justify-content:space-between;gap:5px;padding:3px 5px;min-height:20px}.stat .lbl{white-space:nowrap}.stat .val{font-size:9px;line-height:1;white-space:nowrap;margin:0}.stat.wide{min-height:22px}.stat.wide .val{font-size:10px}
@media (max-width:850px){.recipe-screen{padding:0;overflow-x:auto}.print-toolbar{padding:10px;margin:0}.recipe-page{box-shadow:none}.toolbar-note{display:none}}
@media print{*{-webkit-print-color-adjust:exact;print-color-adjust:exact}html,body{width:100%!important;height:auto!important;margin:0!important;padding:0!important;background:#fff!important}.page-header,.navbar,.sidebar,.btn-back,.print-toolbar,body>footer.footer{display:none!important}.content-wrapper,.container-fluid.main-content{width:100%!important;max-width:none!important;margin:0!important;padding:0!important}.recipe-screen{width:100%!important;margin:0!important;padding:0!important;background:#fff;min-height:0}.recipe-page{width:100%!important;max-width:100%!important;min-height:0;padding:0;margin:0;box-shadow:none}.recipe-box{display:block;width:100%!important;min-height:273mm;border-radius:0;overflow:visible}.recipe-content{display:block;min-height:0}.program-block{break-inside:auto;overflow:visible}.program-head{break-after:avoid}.program-table thead{display:table-header-group}.program-table tr{break-inside:avoid}.section,.notes,.plan-note{break-inside:avoid}@page{size:A4 portrait;margin:12mm}}
</style>

<cfoutput>
<div class="recipe-screen">
<div class="print-toolbar">
    <div class="toolbar-note">A4 baskı önizlemesi</div>
    <div class="toolbar-actions">
        <button type="button" class="recipe-btn" onclick="history.back()">Geri Dön</button>
        <button type="button" class="recipe-btn primary" onclick="window.print()">Yazdır</button>
    </div>
</div>
<div class="recipe-page">
    <div class="recipe-box">
        <div class="recipe-head">
            <div class="title-wrap">
                <div class="recipe-kicker">Üretim ve Boya Takip Formu</div>
                <div class="recipe-title">REÇETE <span class="brand">Rasih Çelik</span></div>
            </div>
            <div class="head-meta">
                <div class="meta-line"><span>Tarih</span><strong>#dateFormat(printDate,"dd/mm/yyyy")#</strong></div>
                <div class="meta-line"><span>Plan / Şarj No</span><strong>#htmlEditFormat(planNo)#</strong></div>
            </div>
            <div class="barcode"><div class="barcode-bars"></div><div class="barcode-code">#htmlEditFormat(planNo)#</div></div>
        </div>
        <div class="recipe-content">
        <div class="section">
            <div class="section-title">Parti ve renk bilgileri</div>
            <div class="info-grid">
                <div class="field-grid">
                    <div class="field wide"><span class="lbl">Müşteri</span><span class="val">#htmlEditFormat(getOrder.company_name ?: "—")#</span></div>
                    <div class="field"><span class="lbl">Parti Kodu</span><span class="val">#htmlEditFormat(partiCode ?: "—")#</span></div>
                    <div class="field"><span class="lbl">Kumaş Cinsi</span><span class="val">#htmlEditFormat(getOrder.product_name ?: getOrder.product_cat ?: "—")#</span></div>
                    <div class="field"><span class="lbl">Renk Kodu</span><span class="val">#htmlEditFormat(getOrder.color_code ?: "—")#</span></div>
                    <div class="field"><span class="lbl">Renk No / Adı</span><span class="val">#htmlEditFormat((len(trim(getOrder.renk_no)) ? getOrder.renk_no & " / " : "") & (getOrder.color_name ?: "—"))#</span></div>
                    <div class="field"><span class="lbl">Kartela</span><span class="val">#htmlEditFormat(getOrder.kartela_no ?: "NUMUNE YOK")#</span></div>
                    <div class="field"><span class="lbl">Kartela Tarihi</span><span class="val">#isDate(getOrder.kartela_date) ? dateFormat(getOrder.kartela_date,"dd/mm/yyyy") : "—"#</span></div>
                </div>
                <div class="stats">
                    <div class="stat wide"><span class="lbl">Makine No</span><span class="val">#htmlEditFormat(getOrder.station_name ?: "—")#</span></div>
                    <div class="stat"><span class="lbl">Metre</span><span class="val">#val(getOrder.quantity_2) gt 0 ? numberFormat(getOrder.quantity_2,"_.___") : "—"#</span></div>
                    <div class="stat"><span class="lbl">Kilogram</span><span class="val">#numberFormat(val(getOrder.quantity),"_.___")#</span></div>
                    <div class="stat"><span class="lbl">Top Adedi</span><span class="val">#len(trim(getOrder.unit_2 ?: "")) ? htmlEditFormat(getOrder.unit_2) : "—"#</span></div>
                    <div class="stat accent"><span class="lbl">Kazan Suyu</span><span class="val">#numberFormat(planWater,"_.___")#</span></div>
                    <div class="stat"><span class="lbl">Renk Tonu</span><span class="val">#val(getOrder.renk_tonu) gt 0 ? val(getOrder.renk_tonu) : "—"#</span></div>
                </div>
            </div>
        </div>
        <div class="party-strip">
            <div class="party-cell"><span class="lbl">Parti RN</span><span class="val">#htmlEditFormat(getOrder.p_order_id)#</span></div>
            <div class="party-cell"><span class="lbl">Müşteri</span><span class="val">#htmlEditFormat(getOrder.company_name ?: "")#</span></div>
            <div class="party-cell"><span class="lbl">Parti Kodu</span><span class="val">#htmlEditFormat(partiCode ?: "")#</span></div>
            <div class="party-cell"><span class="lbl">Metre</span><span class="val num">#val(getOrder.quantity_2) gt 0 ? numberFormat(getOrder.quantity_2,"_.___") : "—"#</span></div>
            <div class="party-cell"><span class="lbl">Kg</span><span class="val num">#numberFormat(val(getOrder.quantity),"_.___")#</span></div>
        </div>
        <div class="programs">
            <div class="section-title">Reçete programı</div>
                <cfset programSeq = 0>
                <cfloop array="#opOrder#" index="opKey">
                    <cfset programSeq = programSeq + 1>
                    <cfset op = opMap[opKey]>
                    <div class="program-block">
                        <div class="program-head"><div><span class="program-label">Program No</span><span class="program-value">#htmlEditFormat(op.code ?: op.product_tree_id)#</span></div><div><span class="program-label">Program Adı</span><span class="program-value">#htmlEditFormat(op.name)#</span></div><div><span class="program-label">Sıra</span><span class="program-value">#programSeq#</span></div></div>
                        <table class="program-table">
                            <thead><tr><th>Grup</th><th class="num">Sıra</th><th>Malzeme Adı</th><th class="num">% - Gr/Lt</th><th class="num">Miktar (Gr)</th></tr></thead>
                            <tbody>
                            <cfif arrayLen(op.rows)>
                                <cfset rowSeq = 0>
                                <cfloop array="#op.rows#" index="r">
                                    <cfset rowSeq = rowSeq + 1>
                                    <cfset groupClass = r.group eq "Boya" ? " dye" : "">
                                    <tr><td><span class="group-pill#groupClass#">#htmlEditFormat(r.group)#</span></td><td class="num">#rowSeq#</td><td class="bold">#htmlEditFormat(r.name)#</td><td class="num">#numberFormat(r.ratio,"_.___")#</td><td class="num bold">#numberFormat(r.amount,"_.___")#</td></tr>
                                </cfloop>
                            <cfelse>
                                <tr><td colspan="5">Program satırı bulunamadı.</td></tr>
                            </cfif>
                            </tbody>
                        </table>
                    </div>
                </cfloop>
                <cfif NOT arrayLen(opOrder)><div class="program-block empty-recipe">Ürün ağacında reçete / program satırı bulunamadı.</div></cfif>
        </div>
        <div class="plan-note"><strong>Plan reçetesi:</strong> Bu form planlanan sarfiyatı gösterir; gerçekleşen tüketim ayrıca kaydedilir.</div>
        <div class="notes">
            <div class="note"><div class="note-title">PARTİ AÇIKLAMA</div><div class="note-body">#htmlEditFormat(getOrder.detail ?: getOrder.order_detail ?: "")#</div></div>
            <div class="note"><div class="note-title">RENK AÇIKLAMA</div><div class="note-body">#htmlEditFormat(getOrder.color_information ?: "")#</div></div>
        </div>
        </div>
        <div class="recipe-footer"><span><strong>RASİH ÇELİK</strong> &nbsp; Boyahane Üretim Sistemi</span><span>Reçete No: #htmlEditFormat(planNo)#</span></div>
    </div>
</div>
</div>
<script>window.addEventListener('load', function(){ setTimeout(function(){ window.print(); }, 350); });</script>
</cfoutput>
