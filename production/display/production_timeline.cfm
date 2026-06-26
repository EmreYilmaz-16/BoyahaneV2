<cfprocessingdirective pageEncoding="utf-8">

<!--- Timeline tabanlı üretim planlama: scheduler/gantt bağımlılığı olmadan arka arkaya ve araya planlama. --->
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
    <cfset arrayAppend(stationsArr, {"id": val(station_id), "text": station_name ?: ("Makina " & station_id), "capacity": val(capacity)})>
</cfloop>

<cfoutput>
<style>
.timeline-page{height:calc(100vh - 82px);display:grid;grid-template-columns:330px 1fr;gap:14px;background:##f4f7fb;padding:14px;overflow:hidden}.tl-panel,.tl-main{background:##fff;border:1px solid ##d9e2ef;border-radius:14px;box-shadow:0 8px 24px rgba(15,23,42,.08);overflow:hidden}.tl-head{background:linear-gradient(135deg,##0f2a44,##1d4f7a);color:##fff;padding:14px 16px}.tl-head h2{font-size:1.05rem;margin:0}.tl-head small{opacity:.8}.tl-tools{display:flex;gap:8px;padding:10px;border-bottom:1px solid ##e5eaf2;align-items:center}.tl-tools input,.tl-tools select{border:1px solid ##cbd5e1;border-radius:9px;padding:8px 10px;font-size:.84rem}.tl-btn{border:0;border-radius:9px;background:##1d4f7a;color:##fff;padding:8px 11px;font-weight:700;cursor:pointer}.tl-list{height:calc(100% - 116px);overflow:auto;padding:10px}.order-card{border:1px solid ##d8e3ef;border-left:5px solid ##2563eb;border-radius:12px;padding:10px;margin-bottom:9px;background:##fff;cursor:grab}.order-card.urgent{border-left-color:##ef4444;background:##fff7f7}.order-card b{display:block;color:##0f172a}.order-meta{font-size:.75rem;color:##64748b;display:flex;flex-wrap:wrap;gap:6px;margin-top:5px}.tl-scroll{height:calc(100% - 95px);overflow:auto;position:relative}.tl-ruler{position:sticky;top:0;z-index:6;display:flex;margin-left:160px;background:##f8fafc;border-bottom:1px solid ##d9e2ef}.tl-day{min-width:240px;border-right:1px solid ##d9e2ef;padding:8px 10px;font-weight:700;color:##334155;text-align:center}.lane{display:grid;grid-template-columns:160px max-content;min-height:84px;border-bottom:1px solid ##e8eef6}.lane-label{position:sticky;left:0;z-index:5;background:##fff;padding:14px 12px;border-right:1px solid ##d9e2ef;font-weight:800;color:##1e293b}.lane-track{position:relative;height:84px;background-image:linear-gradient(to right,rgba(148,163,184,.22) 1px,transparent 1px);background-size:10px 100%}.job{position:absolute;top:13px;height:58px;border-radius:12px;padding:8px 10px;color:##fff;background:linear-gradient(135deg,##2563eb,##1d4ed8);box-shadow:0 8px 18px rgba(37,99,235,.22);overflow:hidden;font-size:.78rem}.job.urgent{background:linear-gradient(135deg,##ef4444,##b91c1c)}.job small{display:block;opacity:.9;white-space:nowrap}.drop-hint{outline:3px dashed ##22c55e;outline-offset:-6px;background-color:rgba(34,197,94,.08)}.tl-toast{position:fixed;right:18px;bottom:18px;color:##fff;border-radius:10px;padding:11px 14px;z-index:9999;box-shadow:0 10px 28px rgba(0,0,0,.2)}
</style>
<div class="timeline-page">
  <aside class="tl-panel">
    <div class="tl-head"><h2>Planlanmamış Emirler</h2><small>Kartı makine satırına sürükleyin. Bırakılan noktadan sonraki işler otomatik ötelenir.</small></div>
    <div class="tl-tools"><input id="orderSearch" placeholder="Emir, renk, müşteri ara..." style="width:100%"></div>
    <div id="orderList" class="tl-list"></div>
  </aside>
  <main class="tl-main">
    <div class="tl-head"><h2>Üretim Timeline Planlama</h2><small>Arka arkaya planlama ve araya üretim emri ekleme ekranı</small></div>
    <div class="tl-tools">
      <select id="daySelect"><option value="3">3 gün</option><option value="7">7 gün</option><option value="14">14 gün</option><option value="30">30 gün</option></select>
      <button class="tl-btn" onclick="location.reload()">Yenile</button>
      <span style="color:##64748b;font-size:.82rem">Saat hassasiyeti: 15 dakika</span>
    </div>
    <div class="tl-scroll" id="timelineScroll"><div class="tl-ruler" id="tlRuler"></div><div id="lanes"></div></div>
  </main>
</div>
<script>
var UNPLANNED=#serializeJSON(unplannedArr)#, PLANNED=#serializeJSON(plannedArr)#, STATIONS=#serializeJSON(stationsArr)#;
var START=new Date('#dateFormat(timelineStart,"yyyy-mm-dd")#T00:00:00'), DAYS=#viewDays#, PX_PER_DAY=240, MINUTES_PER_PX=1440/PX_PER_DAY;
document.getElementById('daySelect').value=String(DAYS);
document.getElementById('daySelect').onchange=function(){ location.href='?fuseaction=production.production_timeline&days='+this.value; };
function enc(s){return String(s||'').replace(/[&<>]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;'}[c];});}
function pad(n){return n<10?'0'+n:n;} function serverDate(d){return d.getFullYear()+'-'+pad(d.getMonth()+1)+'-'+pad(d.getDate())+' '+pad(d.getHours())+':'+pad(d.getMinutes())+':00';}
function minsBetween(a,b){return (new Date(a)-new Date(b))/60000;} function pxFromDate(d){return minsBetween(d,START)/MINUTES_PER_PX;} function widthFromDates(s,e){return Math.max(26,minsBetween(e,s)/MINUTES_PER_PX);}
function snapDateFromX(x){var mins=Math.round((x*MINUTES_PER_PX)/15)*15;return new Date(START.getTime()+mins*60000);} 
function renderOrders(){var q=(document.getElementById('orderSearch').value||'').toLowerCase(), el=document.getElementById('orderList');el.innerHTML='';UNPLANNED.filter(function(o){return !q || JSON.stringify(o).toLowerCase().indexOf(q)>-1;}).forEach(function(o){var c=document.createElement('div');c.className='order-card '+(o.is_urgent?'urgent':'');c.draggable=true;c.dataset.id=o.p_order_id;c.innerHTML='<b>'+enc(o.p_order_no)+'</b><div class="order-meta"><span>'+enc(o.color_code)+' '+enc(o.color_name)+'</span><span>'+enc(o.company_name)+'</span><span>'+Math.round(o.total_op_minutes/60*10)/10+' sa</span></div>';c.ondragstart=function(ev){ev.dataTransfer.setData('text/plain',o.p_order_id);};el.appendChild(c);});}
function renderTimeline(){var ruler=document.getElementById('tlRuler'), lanes=document.getElementById('lanes');ruler.innerHTML='';lanes.innerHTML='';for(var i=0;i<DAYS;i++){var d=new Date(START.getTime()+i*86400000), cell=document.createElement('div');cell.className='tl-day';cell.textContent=pad(d.getDate())+'.'+pad(d.getMonth()+1)+'.'+d.getFullYear();ruler.appendChild(cell);}STATIONS.forEach(function(st){var lane=document.createElement('div');lane.className='lane';lane.innerHTML='<div class="lane-label">'+enc(st.text)+'</div><div class="lane-track" data-station="'+st.id+'" style="width:'+(DAYS*PX_PER_DAY)+'px"></div>';var track=lane.querySelector('.lane-track');track.ondragover=function(ev){ev.preventDefault();track.classList.add('drop-hint');};track.ondragleave=function(){track.classList.remove('drop-hint');};track.ondrop=function(ev){ev.preventDefault();track.classList.remove('drop-hint');var id=ev.dataTransfer.getData('text/plain'), r=track.getBoundingClientRect(), x=ev.clientX-r.left+track.scrollLeft;planOrder(id,st.id,snapDateFromX(x));};PLANNED.filter(function(j){return j.station_id==st.id;}).forEach(function(j){var job=document.createElement('div');job.className='job '+(j.is_urgent?'urgent':'');job.style.left=pxFromDate(j.startDate)+'px';job.style.width=widthFromDates(j.startDate,j.endDate)+'px';job.title='Çift tık: plandan kaldır';job.ondblclick=function(){unplan(j.p_order_id);};job.innerHTML='<b>'+enc(j.p_order_no)+'</b><small>'+enc(j.color_code)+' '+enc(j.color_name)+'</small><small>'+serverDate(new Date(j.startDate)).slice(11,16)+' - '+serverDate(new Date(j.endDate)).slice(11,16)+'</small>';track.appendChild(job);});lanes.appendChild(lane);});}
function planOrder(id,stationId,start){fetch('/production/form/save_plan.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({p_order_id:id,station_id:stationId,start_date:serverDate(start),cell_start_date:serverDate(start),status:1,shift_following:1,interval_minutes:15,snap_back_minutes:15})}).then(function(r){return r.json();}).then(function(res){toast(res.message,res.success); if(res.success) location.reload();});}
function unplan(id){if(!confirm('Emir plandan kaldırılsın mı?'))return;fetch('/production/form/unplan_order.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({p_order_id:id})}).then(function(r){return r.json();}).then(function(res){toast(res.message,res.success); if(res.success) location.reload();});}
function toast(m,ok){var t=document.createElement('div');t.className='tl-toast';t.style.background=ok?'##16a34a':'##dc2626';t.textContent=m||'';document.body.appendChild(t);setTimeout(function(){t.remove();},3200);}document.getElementById('orderSearch').oninput=renderOrders;renderOrders();renderTimeline();
</script>
</cfoutput>
