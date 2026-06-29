<cfprocessingdirective pageEncoding="utf-8">
<cfsetting showdebugoutput="false">

<cfparam name="url.p_order_id" default="0">
<cfset pOrderId = isNumeric(url.p_order_id) AND val(url.p_order_id) gt 0 ? val(url.p_order_id) : 0>

<cfif pOrderId eq 0>
    <cflocation url="index.cfm?fuseaction=production.list_production_orders" addtoken="false">
</cfif>

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
           COALESCE(ws.station_name, '') AS station_name,
           COALESCE(ws.min_water_amount, 0) AS min_water_amount,
           COALESCE(ws.max_water_amount, 0) AS max_water_amount,
           COALESCE(o.order_number, '') AS order_number,
           COALESCE(oc.nickname, oc.fullname, cc.nickname, cc.fullname, '') AS company_name,
           COALESCE(o.detail, '') AS order_detail
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
            <cfset isDye = findNoCase("BOYA", rowText) OR findNoCase("DYE", rowText) OR findNoCase("REAKTIF", rowText) OR findNoCase("REACTIVE", rowText)>
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
.recipe-page{width:210mm;min-height:297mm;margin:0 auto;background:##fff;color:##111;font-family:Arial,Helvetica,sans-serif;font-size:11px;padding:8mm;box-sizing:border-box}.recipe-box{border:2px solid ##111}.recipe-head{display:grid;grid-template-columns:1fr 235px 210px;border-bottom:2px solid ##111}.recipe-title{font-size:32px;font-weight:900;letter-spacing:16px;padding:8px 10px}.brand{font-family:Georgia,serif;font-style:italic;font-size:22px;letter-spacing:0;margin-left:12px}.head-mid{padding:6px 8px;font-size:14px;font-weight:700;line-height:1.7}.barcode{padding:5px 10px;text-align:center}.barcode-bars{height:44px;background:repeating-linear-gradient(90deg,##111 0 2px,transparent 2px 4px,##111 4px 5px,transparent 5px 8px)}.info-grid{display:grid;grid-template-columns:1.45fr .95fr;border-bottom:2px solid ##111}.info-left,.info-right{padding:7px 10px}.field{display:grid;grid-template-columns:120px 1fr;line-height:1.75;font-size:15px}.field .lbl{font-weight:700}.field .val{font-weight:800}.party-table,.program-table{width:100%;border-collapse:collapse}.party-table th,.party-table td,.program-table th,.program-table td{border:1px solid ##111;padding:3px 5px}.party-table th,.program-table th{font-weight:800;background:##eee}.program-wrap{display:grid;grid-template-columns:1.05fr 1fr;min-height:175mm}.program-left{border-right:2px solid ##111}.program-block{border-bottom:2px solid ##111}.program-head{display:grid;grid-template-columns:90px 1fr 115px;border-bottom:1px solid ##111;font-size:14px;font-weight:800;padding:5px}.num{text-align:right}.bold{font-weight:900}.lot-box{border-bottom:1px solid ##111;padding:8px;font-size:12px}.empty-space{min-height:120mm}.notes{display:grid;grid-template-columns:1fr 1fr;border-top:2px solid ##111}.note{min-height:28mm;border-right:2px solid ##111}.note:last-child{border-right:0}.note-title{font-weight:900;border-bottom:2px solid ##111;padding:4px 7px;background:##eee}.note-body{padding:7px;font-size:13px}@media print{body{margin:0;background:##fff}.page-header,.navbar,.sidebar,.btn-back{display:none!important}.recipe-page{width:210mm;min-height:297mm;padding:6mm;margin:0}.recipe-box{page-break-inside:avoid}@page{size:A4;margin:5mm}}
</style>

<cfoutput>
<div class="recipe-page">
    <div class="recipe-box">
        <div class="recipe-head">
            <div class="recipe-title">REÇETE <span class="brand">Boyahane</span></div>
            <div class="head-mid">
                Tarih : #dateFormat(printDate,"dd/mm/yyyy")#<br>
                Plan/Şarj No : #htmlEditFormat(planNo)#
            </div>
            <div class="barcode"><div class="barcode-bars"></div><div>#htmlEditFormat(planNo)#</div></div>
        </div>
        <div class="info-grid">
            <div class="info-left">
                <div class="field"><span class="lbl">Müşteri</span><span class="val">: #htmlEditFormat(getOrder.company_name ?: "—")#</span></div>
                <div class="field"><span class="lbl">Parti Kodu</span><span class="val">: #htmlEditFormat(partiCode ?: "—")#</span></div>
                <div class="field"><span class="lbl">Kumaş Cinsi</span><span class="val">: #htmlEditFormat(getOrder.product_name ?: getOrder.product_cat ?: "—")#</span></div>
                <div class="field"><span class="lbl">Renk Kodu</span><span class="val">: #htmlEditFormat(getOrder.color_code ?: "—")#</span></div>
                <div class="field"><span class="lbl">Renk No/Adı</span><span class="val">: #htmlEditFormat((len(trim(getOrder.renk_no)) ? getOrder.renk_no & " / " : "") & (getOrder.color_name ?: "—"))#</span></div>
                <div class="field"><span class="lbl">Kartela</span><span class="val">: #htmlEditFormat(getOrder.kartela_no ?: "NUMUNE YOK")#</span></div>
                <div class="field"><span class="lbl">Kartela Tarihi</span><span class="val">: #isDate(getOrder.kartela_date) ? dateFormat(getOrder.kartela_date,"dd/mm/yyyy") : ""#</span></div>
            </div>
            <div class="info-right">
                <div class="field"><span class="lbl">Makine No</span><span class="val">: #htmlEditFormat(getOrder.station_name ?: "—")#</span></div>
                <div class="field"><span class="lbl">Metre</span><span class="val">: #val(getOrder.quantity_2) gt 0 ? numberFormat(getOrder.quantity_2,"_.___") : "—"#</span></div>
                <div class="field"><span class="lbl">Kg</span><span class="val">: #numberFormat(val(getOrder.quantity),"_.___")#</span></div>
                <div class="field"><span class="lbl">Top Adedi</span><span class="val">: #len(trim(getOrder.unit_2 ?: "")) ? htmlEditFormat(getOrder.unit_2) : "—"#</span></div>
                <br>
                <div class="field"><span class="lbl">Kazan Su Mik.</span><span class="val">: #numberFormat(planWater,"_.___")#</span></div>
                <div class="field"><span class="lbl">Renk Tonu</span><span class="val">: #val(getOrder.renk_tonu) gt 0 ? val(getOrder.renk_tonu) : "—"#</span></div>
            </div>
        </div>
        <table class="party-table">
            <thead><tr><th>PartiRN</th><th>Müşteri</th><th>Parti Kodu</th><th>Metre</th><th>Kg</th></tr></thead>
            <tbody><tr><td>#htmlEditFormat(getOrder.p_order_id)#</td><td>#htmlEditFormat(getOrder.company_name ?: "")#</td><td>#htmlEditFormat(partiCode ?: "")#</td><td class="num">#val(getOrder.quantity_2) gt 0 ? numberFormat(getOrder.quantity_2,"_.___") : ""#</td><td class="num">#numberFormat(val(getOrder.quantity),"_.___")#</td></tr></tbody>
        </table>
        <div class="program-wrap">
            <div class="program-left">
                <cfset programSeq = 0>
                <cfloop array="#opOrder#" index="opKey">
                    <cfset programSeq = programSeq + 1>
                    <cfset op = opMap[opKey]>
                    <div class="program-block">
                        <div class="program-head"><div>Program No<br>#htmlEditFormat(op.code ?: op.product_tree_id)#</div><div>Program Adı<br>#htmlEditFormat(op.name)#</div><div>Program Sıra<br><span class="bold">#programSeq#</span></div></div>
                        <table class="program-table">
                            <thead><tr><th>Grup</th><th>Sıra</th><th>Ad</th><th>%-Gr/Lt</th><th>MiktarGr.</th></tr></thead>
                            <tbody>
                            <cfif arrayLen(op.rows)>
                                <cfset rowSeq = 0>
                                <cfloop array="#op.rows#" index="r"><cfset rowSeq = rowSeq + 1><tr><td>#htmlEditFormat(r.group)#</td><td class="num">#rowSeq#</td><td>#htmlEditFormat(r.name)#</td><td class="num">#numberFormat(r.ratio,"_.___")#</td><td class="num bold">#numberFormat(r.amount,"_.___")#</td></tr></cfloop>
                            <cfelse>
                                <tr><td colspan="5">Program satırı bulunamadı.</td></tr>
                            </cfif>
                            </tbody>
                        </table>
                    </div>
                </cfloop>
                <cfif NOT arrayLen(opOrder)><div class="program-block p-2">Ürün ağacında reçete/program satırı bulunamadı.</div></cfif>
            </div>
            <div>
                <div class="lot-box"><strong>Kimyevi</strong><br><em>Lot:</em> Plan reçetesi — gerçekleşen tüketim basılmaz.</div>
                <div class="empty-space"></div>
            </div>
        </div>
        <div class="notes">
            <div class="note"><div class="note-title">PARTİ AÇIKLAMA</div><div class="note-body">#htmlEditFormat(getOrder.detail ?: getOrder.order_detail ?: "")#</div></div>
            <div class="note"><div class="note-title">RENK AÇIKLAMA</div><div class="note-body">#htmlEditFormat(getOrder.color_information ?: "")#</div></div>
        </div>
    </div>
</div>
<script>window.addEventListener('load', function(){ setTimeout(function(){ window.print(); }, 350); });</script>
</cfoutput>
