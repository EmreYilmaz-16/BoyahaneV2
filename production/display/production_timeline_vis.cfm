<cfprocessingdirective pageEncoding="utf-8">

<!--- Vis Timeline tabanlı üretim planlama prototipi. --->
<cfparam name="url.days" default="7">
<cfset viewDays = (isNumeric(url.days) AND val(url.days) gte 1 AND val(url.days) lte 30) ? val(url.days) : 7>
<cfset timelineStart = createDateTime(year(now()), month(now()), day(now()), 0, 0, 0)>
<cfset timelineEnd = dateAdd("d", viewDays, timelineStart)>

<cfquery name="qUnplanned" datasource="boyahane">
    SELECT po.p_order_id,
           po.p_order_no,
           COALESCE(po.quantity, 0) AS quantity,
           COALESCE(po.lot_no,'') AS lot_no,
           COALESCE(ci.color_code,'') AS color_code,
           COALESCE(ci.color_name,'') AS color_name,
           COALESCE(c.nickname, c.fullname,'') AS company_name,
           COALESCE(s.stock_code,'') AS stock_code,
           COALESCE(po.is_urgent, false) AS is_urgent,
           COALESCE((SELECT SUM(COALESCE(pop.o_minute, 0)) FROM production_operation pop WHERE pop.p_order_id = po.p_order_id), 0) AS total_op_minutes
    FROM production_orders po
    LEFT JOIN stocks s ON po.stock_id = s.stock_id
    LEFT JOIN color_info ci ON po.stock_id = ci.stock_id
    LEFT JOIN company c ON ci.company_id = c.company_id
    WHERE (po.station_id IS NULL OR po.start_date IS NULL)
      AND COALESCE(po.status, 1) NOT IN (2, 5, 9)
    ORDER BY po.is_urgent DESC, po.p_order_id DESC
</cfquery>

<cfquery name="qPlanned" datasource="boyahane">
    SELECT po.p_order_id,
           po.p_order_no,
           COALESCE(po.quantity, 0) AS quantity,
           COALESCE(po.lot_no,'') AS lot_no,
           COALESCE(ci.color_code,'') AS color_code,
           COALESCE(ci.color_name,'') AS color_name,
           COALESCE(c.nickname, c.fullname,'') AS company_name,
           COALESCE(s.stock_code,'') AS stock_code,
           po.start_date,
           po.finish_date,
           po.station_id,
           COALESCE(ws.station_name,'') AS station_name,
           COALESCE(po.status, 1) AS status,
           COALESCE(po.is_urgent, false) AS is_urgent,
           COALESCE((SELECT SUM(COALESCE(pop.o_minute, 0)) FROM production_operation pop WHERE pop.p_order_id = po.p_order_id), 0) AS total_op_minutes
    FROM production_orders po
    LEFT JOIN stocks s ON po.stock_id = s.stock_id
    LEFT JOIN color_info ci ON po.stock_id = ci.stock_id
    LEFT JOIN company c ON ci.company_id = c.company_id
    LEFT JOIN workstations ws ON po.station_id = ws.station_id
    WHERE po.station_id IS NOT NULL
      AND po.start_date IS NOT NULL
      AND po.finish_date IS NOT NULL
      AND po.status IN (1, 2, 5)
      AND po.start_date < <cfqueryparam value="#createODBCDateTime(timelineEnd)#" cfsqltype="cf_sql_timestamp">
      AND po.finish_date > <cfqueryparam value="#createODBCDateTime(timelineStart)#" cfsqltype="cf_sql_timestamp">
    ORDER BY ws.station_name, po.start_date
</cfquery>

<cfquery name="qStations" datasource="boyahane">
    SELECT station_id,
           station_name,
           COALESCE(up_station, 0) AS up_station,
           COALESCE(capacity, 0) AS capacity
    FROM workstations
    WHERE COALESCE(active, false) = true
      AND COALESCE(up_station, 0) > 0
    ORDER BY up_station, station_name, station_id
</cfquery>

<cfset unplannedArr = []>
<cfloop query="qUnplanned">
    <cfset arrayAppend(unplannedArr, {
        "p_order_id": val(p_order_id), "p_order_no": p_order_no ?: "", "quantity": val(quantity),
        "lot_no": lot_no ?: "", "color_code": color_code ?: "", "color_name": color_name ?: "",
        "company_name": company_name ?: "", "stock_code": stock_code ?: "", "is_urgent": is_urgent,
        "total_op_minutes": val(total_op_minutes) gt 0 ? val(total_op_minutes) : 480
    })>
</cfloop>

<cfset plannedArr = []>
<cfloop query="qPlanned">
    <cfset arrayAppend(plannedArr, {
        "p_order_id": val(p_order_id), "p_order_no": p_order_no ?: "", "quantity": val(quantity),
        "lot_no": lot_no ?: "", "color_code": color_code ?: "", "color_name": color_name ?: "",
        "company_name": company_name ?: "", "stock_code": stock_code ?: "", "station_id": val(station_id),
        "station_name": station_name ?: "", "status": val(status), "is_urgent": is_urgent,
        "total_op_minutes": val(total_op_minutes) gt 0 ? val(total_op_minutes) : 480,
        "startDate": dateFormat(start_date,"yyyy-mm-dd") & "T" & timeFormat(start_date,"HH:mm:ss"),
        "endDate": dateFormat(finish_date,"yyyy-mm-dd") & "T" & timeFormat(finish_date,"HH:mm:ss")
    })>
</cfloop>

<cfset stationsArr = []>
<cfloop query="qStations">
    <cfset arrayAppend(stationsArr, {"id": val(station_id), "content": station_name ?: ("Makina " & station_id), "capacity": val(capacity)})>
</cfloop>

<cfoutput>
<link rel="stylesheet" href="https://unpkg.com/vis-timeline@7.7.3/styles/vis-timeline-graph2d.min.css">
<style>
.vis-production-page{height:calc(100vh - 82px);display:grid;grid-template-columns:330px 1fr;gap:14px;background:##f4f7fb;padding:14px;overflow:hidden}.vis-panel,.vis-main{background:##fff;border:1px solid ##d9e2ef;border-radius:14px;box-shadow:0 8px 24px rgba(15,23,42,.08);overflow:hidden}.vis-head{background:linear-gradient(135deg,##0f2a44,##1d4f7a);color:##fff;padding:14px 16px}.vis-head h2{font-size:1.05rem;margin:0}.vis-head small{opacity:.82}.vis-tools{display:flex;gap:8px;padding:10px;border-bottom:1px solid ##e5eaf2;align-items:center;flex-wrap:wrap}.vis-tools input,.vis-tools select{border:1px solid ##cbd5e1;border-radius:9px;padding:8px 10px;font-size:.84rem}.vis-btn{border:0;border-radius:9px;background:##1d4f7a;color:##fff;padding:8px 11px;font-weight:700;cursor:pointer}.vis-order-list{height:calc(100% - 116px);overflow:auto;padding:10px}.vis-order-card{border:1px solid ##d8e3ef;border-left:5px solid ##2563eb;border-radius:12px;padding:10px;margin-bottom:9px;background:##fff;cursor:grab}.vis-order-card.urgent{border-left-color:##ef4444;background:##fff7f7}.vis-order-card b{display:block;color:##0f172a}.vis-order-meta{font-size:.75rem;color:##64748b;display:flex;flex-wrap:wrap;gap:6px;margin-top:5px}.vis-timeline-wrap{height:calc(100% - 112px);padding:10px}.vis-timeline{height:100%;border:1px solid ##d9e2ef;border-radius:12px}.vis-item.production-job{border:0;border-radius:10px;background:linear-gradient(135deg,##2563eb,##1d4ed8);color:##fff;box-shadow:0 8px 18px rgba(37,99,235,.2)}.vis-item.production-job.urgent{background:linear-gradient(135deg,##ef4444,##b91c1c)}.vis-item.vis-selected{box-shadow:0 0 0 3px rgba(245,158,11,.35)}.job-title{font-weight:800}.job-sub{font-size:.74rem;opacity:.92}.vis-toast{position:fixed;right:18px;bottom:18px;color:##fff;border-radius:10px;padding:11px 14px;z-index:9999;box-shadow:0 10px 28px rgba(0,0,0,.2)}
</style>
<div class="vis-production-page">
  <aside class="vis-panel">
    <div class="vis-head"><h2>Planlanmamış Emirler</h2><small>Kartı Vis Timeline üzerindeki makine satırına sürükleyin.</small></div>
    <div class="vis-tools"><input id="visOrderSearch" placeholder="Emir, renk, müşteri ara..." style="width:100%"></div>
    <div id="visOrderList" class="vis-order-list"></div>
  </aside>
  <main class="vis-main">
    <div class="vis-head"><h2>Vis Timeline Planlama Prototipi</h2><small>vis-timeline: zoom, pan, gruplu satırlar, sürükle-bırak ve düzenlenebilir aralık kartları.</small></div>
    <div class="vis-tools">
      <select id="visDaySelect"><option value="3">3 gün</option><option value="7">7 gün</option><option value="14">14 gün</option><option value="30">30 gün</option></select>
      <button class="vis-btn" type="button" onclick="location.reload()">Yenile</button>
      <span style="color:##64748b;font-size:.82rem">Kartları taşıyınca mevcut save_plan.cfm servisi ile 15 dakikaya yuvarlanarak kaydedilir.</span>
    </div>
    <div class="vis-timeline-wrap"><div id="visProductionTimeline" class="vis-timeline"></div></div>
  </main>
</div>
<script src="https://unpkg.com/vis-data@7.1.9/peer/umd/vis-data.min.js"></script>
<script src="https://unpkg.com/vis-timeline@7.7.3/peer/umd/vis-timeline-graph2d.min.js"></script>
<script>
var UNPLANNED=#serializeJSON(unplannedArr)#, PLANNED=#serializeJSON(plannedArr)#, STATIONS=#serializeJSON(stationsArr)#;
var START=new Date('#dateFormat(timelineStart,"yyyy-mm-dd")#T00:00:00'), END=new Date('#dateFormat(timelineEnd,"yyyy-mm-dd")#T00:00:00'), timeline, items, groups;
document.getElementById('visDaySelect').value=String(#viewDays#);
document.getElementById('visDaySelect').onchange=function(){ location.href='?fuseaction=production.production_timeline_vis&days='+this.value; };
function enc(s){return String(s||'').replace(/[&<>]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;'}[c];});}
function pad(n){return n<10?'0'+n:n;} function serverDate(d){return d.getFullYear()+'-'+pad(d.getMonth()+1)+'-'+pad(d.getDate())+' '+pad(d.getHours())+':'+pad(d.getMinutes())+':00';}
function snapDate(d){var ms=15*60000;return new Date(Math.round(d.getTime()/ms)*ms);} function addMins(d,m){return new Date(d.getTime()+m*60000);}
function toast(m,ok){var t=document.createElement('div');t.className='vis-toast';t.style.background=ok?'##16a34a':'##dc2626';t.textContent=m||'';document.body.appendChild(t);setTimeout(function(){t.remove();},3200);}
function itemContent(o){return '<div class="job-title">'+enc(o.p_order_no)+'</div><div class="job-sub">'+enc(o.color_code)+' '+enc(o.color_name)+' · '+Math.round((o.total_op_minutes||480)/60*10)/10+' sa</div>';}
function renderOrders(){var q=(document.getElementById('visOrderSearch').value||'').toLowerCase(), el=document.getElementById('visOrderList');el.innerHTML='';UNPLANNED.filter(function(o){return !q || JSON.stringify(o).toLowerCase().indexOf(q)>-1;}).forEach(function(o){var c=document.createElement('div');c.className='vis-order-card '+(o.is_urgent?'urgent':'');c.draggable=true;c.dataset.id=o.p_order_id;c.innerHTML='<b>'+enc(o.p_order_no)+'</b><div class="vis-order-meta"><span>'+enc(o.color_code)+' '+enc(o.color_name)+'</span><span>'+enc(o.company_name)+'</span><span>'+Math.round(o.total_op_minutes/60*10)/10+' sa</span></div>';c.ondragstart=function(ev){ev.dataTransfer.effectAllowed='move';ev.dataTransfer.setData('text/plain',JSON.stringify(o));};el.appendChild(c);});}
function buildTimeline(){groups=new vis.DataSet(STATIONS);items=new vis.DataSet(PLANNED.map(function(o){return {id:o.p_order_id, group:o.station_id, start:o.startDate, end:o.endDate, content:itemContent(o), className:'production-job '+(o.is_urgent?'urgent':''), order:o};}));timeline=new vis.Timeline(document.getElementById('visProductionTimeline'),items,groups,{start:START,end:END,min:START,max:END,stack:false,editable:{updateTime:true,updateGroup:true,add:false,remove:false,overrideItems:false},orientation:'top',margin:{item:10,axis:8},snap:function(date){return snapDate(date);},onMove:function(item,callback){var start=snapDate(new Date(item.start));savePlan(item.id,item.group,start,1,function(ok){callback(ok?item:null);});}});var container=document.getElementById('visProductionTimeline');container.addEventListener('dragover',function(ev){ev.preventDefault();});container.addEventListener('drop',function(ev){ev.preventDefault();var props=timeline.getEventProperties(ev), raw=ev.dataTransfer.getData('text/plain');if(!props.group||!raw)return;try{var o=JSON.parse(raw), start=snapDate(props.time), end=addMins(start,o.total_op_minutes||480);savePlan(o.p_order_id,props.group,start,1,function(ok){if(ok){items.add({id:o.p_order_id,group:props.group,start:start,end:end,content:itemContent(o),className:'production-job '+(o.is_urgent?'urgent':''),order:o});}});}catch(e){toast('Sürüklenen emir okunamadı.',false);}});}
function savePlan(id,stationId,start,shiftFollowing,done){fetch('/production/form/save_plan.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({p_order_id:id,station_id:stationId,start_date:serverDate(start),cell_start_date:serverDate(start),status:1,shift_following:shiftFollowing?1:0,interval_minutes:15,snap_back_minutes:15})}).then(function(r){return r.json();}).then(function(res){toast(res.message,res.success); if(res.success){setTimeout(function(){location.reload();},450);} if(done)done(!!res.success);}).catch(function(){toast('Plan kaydedilemedi.',false); if(done)done(false);});}
document.getElementById('visOrderSearch').oninput=renderOrders;renderOrders();buildTimeline();
</script>
</cfoutput>
