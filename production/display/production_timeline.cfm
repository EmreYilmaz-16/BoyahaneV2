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
.timeline-page{height:calc(100vh - 82px);display:grid;grid-template-columns:330px 1fr;gap:14px;background:##f4f7fb;padding:14px;overflow:hidden}.tl-panel,.tl-main{background:##fff;border:1px solid ##d9e2ef;border-radius:14px;box-shadow:0 8px 24px rgba(15,23,42,.08);overflow:hidden}.tl-head{background:linear-gradient(135deg,##0f2a44,##1d4f7a);color:##fff;padding:14px 16px}.tl-head h2{font-size:1.05rem;margin:0}.tl-head small{opacity:.8}.tl-tools{display:flex;gap:8px;padding:10px;border-bottom:1px solid ##e5eaf2;align-items:center}.tl-tools input,.tl-tools select{border:1px solid ##cbd5e1;border-radius:9px;padding:8px 10px;font-size:.84rem}.tl-btn{border:0;border-radius:9px;background:##1d4f7a;color:##fff;padding:8px 11px;font-weight:700;cursor:pointer}.tl-list{height:calc(100% - 116px);overflow:auto;padding:10px}.order-card{border:1px solid ##d8e3ef;border-left:5px solid ##2563eb;border-radius:12px;padding:10px;margin-bottom:9px;background:##fff;cursor:grab}.order-card.urgent{border-left-color:##ef4444;background:##fff7f7}.order-card b{display:block;color:##0f172a}.order-meta{font-size:.75rem;color:##64748b;display:flex;flex-wrap:wrap;gap:6px;margin-top:5px}.tl-scroll{height:calc(100% - 95px);overflow:auto;position:relative}.tl-ruler{position:sticky;top:0;z-index:6;display:flex;margin-left:160px;background:##f8fafc;border-bottom:1px solid ##d9e2ef}.tl-day{min-width:720px;border-right:1px solid ##d9e2ef;color:##334155;text-align:center}.tl-day-title{padding:7px 10px;font-weight:800;border-bottom:1px solid ##e2e8f0}.tl-hours{display:grid;grid-template-columns:repeat(24,1fr)}.tl-hour{height:24px;border-right:1px solid ##e2e8f0;font-size:.68rem;color:##64748b;display:flex;align-items:center;justify-content:center}.tl-hour:last-child{border-right:0}.lane{display:grid;grid-template-columns:160px max-content;min-height:84px;border-bottom:1px solid ##e8eef6}.lane-label{position:sticky;left:0;z-index:5;background:##fff;padding:14px 12px;border-right:1px solid ##d9e2ef;font-weight:800;color:##1e293b}.lane-track{position:relative;height:84px;background-image:linear-gradient(to right,rgba(15,23,42,.12) 1px,transparent 1px),linear-gradient(to right,rgba(148,163,184,.28) 1px,transparent 1px);background-size:30px 100%,720px 100%}.job{position:absolute;top:13px;height:58px;border-radius:12px;padding:8px 10px;color:##fff;background:linear-gradient(135deg,##2563eb,##1d4ed8);box-shadow:0 8px 18px rgba(37,99,235,.22);overflow:hidden;font-size:.78rem;cursor:grab}.job:active{cursor:grabbing}.job.dragging{opacity:.55}.job.urgent{background:linear-gradient(135deg,##ef4444,##b91c1c)}.job small{display:block;opacity:.9;white-space:nowrap}.drop-hint{outline:3px dashed ##22c55e;outline-offset:-6px;background-color:rgba(34,197,94,.08)}.tl-toast{position:fixed;right:18px;bottom:18px;color:##fff;border-radius:10px;padding:11px 14px;z-index:9999;box-shadow:0 10px 28px rgba(0,0,0,.2)}.now-line{position:absolute;top:0;bottom:0;width:0;border-left:3px solid ##dc2626;z-index:4;pointer-events:none}.now-line:before{content:'Şimdi';position:absolute;top:2px;left:5px;background:##dc2626;color:##fff;border-radius:999px;padding:1px 6px;font-size:.65rem;font-weight:800;white-space:nowrap}.tl-now-marker{position:absolute;top:0;bottom:0;width:0;border-left:3px solid ##dc2626;z-index:8;pointer-events:none}

.tl-modebar{display:flex;gap:8px;align-items:center;flex-wrap:wrap}.tl-mode{border:1px solid ##cbd5e1;background:##fff;color:##334155;border-radius:999px;padding:7px 10px;font-weight:800;font-size:.78rem;cursor:pointer}.tl-mode.active{background:##1d4f7a;color:##fff;border-color:##1d4f7a;box-shadow:0 6px 16px rgba(29,79,122,.22)}.job{border:1px solid rgba(255,255,255,.25)}.job:hover{transform:translateY(-1px);box-shadow:0 12px 24px rgba(37,99,235,.30)}.job.swap-target{outline:3px solid ##f59e0b;outline-offset:2px}.job b{display:block;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}.job-actions{display:flex;gap:6px;margin-top:8px}.job-chip{display:inline-flex;align-items:center;gap:4px;background:rgba(255,255,255,.18);border-radius:999px;padding:1px 6px;font-size:.68rem}.tl-modal-backdrop{position:fixed;inset:0;background:rgba(15,23,42,.55);z-index:10000;display:none;align-items:center;justify-content:center;padding:20px}.tl-modal-backdrop.open{display:flex}.tl-modal{width:min(620px,96vw);background:##fff;border-radius:18px;box-shadow:0 24px 70px rgba(0,0,0,.32);overflow:hidden}.tl-modal-head{background:linear-gradient(135deg,##0f2a44,##2563eb);color:##fff;padding:16px 18px;display:flex;justify-content:space-between;gap:12px;align-items:flex-start}.tl-modal-head h3{margin:0;font-size:1.1rem}.tl-modal-close{border:0;background:rgba(255,255,255,.16);color:##fff;border-radius:10px;width:34px;height:34px;cursor:pointer;font-size:1.2rem}.tl-modal-body{padding:16px 18px}.detail-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.detail-item{border:1px solid ##e2e8f0;border-radius:12px;padding:10px;background:##f8fafc}.detail-item span{display:block;color:##64748b;font-size:.72rem;font-weight:800;text-transform:uppercase;letter-spacing:.03em}.detail-item b{display:block;color:##0f172a;margin-top:4px}.detail-wide{grid-column:1/-1}.tl-modal-foot{padding:12px 18px;border-top:1px solid ##e2e8f0;background:##f8fafc;color:##64748b;font-size:.82rem}
</style>
<div class="timeline-page">
  <aside class="tl-panel">
    <div class="tl-head"><h2>Planlanmamış Emirler</h2><small>Kartı makine satırına sürükleyin. Bırakılan noktadan sonraki işler otomatik ötelenir.</small></div>
    <div class="tl-tools"><input id="orderSearch" placeholder="Emir, renk, müşteri ara..." style="width:100%"></div>
    <div id="orderList" class="tl-list"></div>
  </aside>
  <main class="tl-main">
    <div class="tl-head"><h2>Üretim Timeline Planlama</h2><small>Planlanmamış veya planlı emri sürükleyerek makinesini ve saatini değiştirin</small></div>
    <div class="tl-tools">
      <select id="daySelect"><option value="3">3 gün</option><option value="7">7 gün</option><option value="14">14 gün</option><option value="30">30 gün</option></select>
      <button class="tl-btn" onclick="location.reload()">Yenile</button>
      <div class="tl-modebar" title="Bırakma davranışını seçin">
        <button type="button" class="tl-mode active" data-mode="insert">Ötele / araya koy</button>
        <button type="button" class="tl-mode" data-mode="move">Boşluğa taşı</button>
        <button type="button" class="tl-mode" data-mode="swap">Yer değiştir</button>
      </div>
      <span style="color:##64748b;font-size:.82rem">Saat hassasiyeti: 15 dakika · Planlı karta tıklayınca detay açılır</span>
    </div>
    <div class="tl-scroll" id="timelineScroll"><div class="tl-ruler" id="tlRuler"></div><div id="lanes"></div></div>
  </main>
</div>

<div class="tl-modal-backdrop" id="orderModal" onclick="closeOrderModal(event)">
  <div class="tl-modal" onclick="event.stopPropagation()">
    <div class="tl-modal-head"><div><h3 id="modalTitle">Emir Detayı</h3><small id="modalSub"></small></div><button class="tl-modal-close" type="button" onclick="closeOrderModal()">×</button></div>
    <div class="tl-modal-body" id="modalBody"></div>
    <div class="tl-modal-foot">İpucu: Planlı kartı sürükleyerek makine/saat değiştirebilir, mod seçimine göre öteleyebilir veya başka bir kartla yer değiştirebilirsiniz.</div>
  </div>
</div>
<script>
var UNPLANNED=#serializeJSON(unplannedArr)#, PLANNED=#serializeJSON(plannedArr)#, STATIONS=#serializeJSON(stationsArr)#;
var START=new Date('#dateFormat(timelineStart,"yyyy-mm-dd")#T00:00:00'), DAYS=#viewDays#, PX_PER_DAY=720, MINUTES_PER_PX=1440/PX_PER_DAY, DROP_MODE='insert', DRAGGED_ORDER_ID=null;
document.getElementById('daySelect').value=String(DAYS);
document.getElementById('daySelect').onchange=function(){ location.href='?fuseaction=production.production_timeline&days='+this.value; };
function enc(s){return String(s||'').replace(/[&<>]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;'}[c];});}
function pad(n){return n<10?'0'+n:n;} function serverDate(d){return d.getFullYear()+'-'+pad(d.getMonth()+1)+'-'+pad(d.getDate())+' '+pad(d.getHours())+':'+pad(d.getMinutes())+':00';}
function minsBetween(a,b){return (new Date(a)-new Date(b))/60000;} function pxFromDate(d){return minsBetween(d,START)/MINUTES_PER_PX;} function widthFromDates(s,e){return Math.max(26,minsBetween(e,s)/MINUTES_PER_PX);}
function snapDateFromX(x){var mins=Math.round((x*MINUTES_PER_PX)/15)*15;return new Date(START.getTime()+mins*60000);} 
function setDragData(ev,id,source){ev.dataTransfer.effectAllowed='move';ev.dataTransfer.setData('text/plain',id);ev.dataTransfer.setData('application/x-production-order',JSON.stringify({id:id,source:source}));}
function getDragOrderId(ev){var raw=ev.dataTransfer.getData('application/x-production-order');if(raw){try{return JSON.parse(raw).id;}catch(e){}}return ev.dataTransfer.getData('text/plain');}
function findOrder(id){id=String(id);return PLANNED.concat(UNPLANNED).filter(function(o){return String(o.p_order_id)===id;})[0];}
function fmtDate(v){return v?serverDate(new Date(v)).slice(0,16):'-';}
function detailItem(label,value,wide){return '<div class="detail-item '+(wide?'detail-wide':'')+'"><span>'+label+'</span><b>'+enc(value||'-')+'</b></div>'; }
function openOrderModal(order){if(!order)return;document.getElementById('modalTitle').textContent=order.p_order_no||('Emir ##'+order.p_order_id);document.getElementById('modalSub').textContent=(order.station_name||'Planlanmamış')+' · '+Math.round((order.total_op_minutes||0)/60*10)/10+' sa';document.getElementById('modalBody').innerHTML='<div class="detail-grid">'+detailItem('Müşteri',order.company_name)+detailItem('Renk',((order.color_code||'')+' '+(order.color_name||'')).trim())+detailItem('Parti No',order.lot_no)+detailItem('Stok Kodu',order.stock_code)+detailItem('Makine',order.station_name)+detailItem('Miktar',order.quantity)+detailItem('Başlangıç',fmtDate(order.startDate))+detailItem('Bitiş',fmtDate(order.endDate))+detailItem('Durum',order.status)+detailItem('Aciliyet',order.is_urgent?'Acil':'Normal')+'</div>';document.getElementById('orderModal').classList.add('open');}
function closeOrderModal(ev){if(ev&&ev.target&&ev.target.id!=='orderModal')return;document.getElementById('orderModal').classList.remove('open');}
function renderOrders(){var q=(document.getElementById('orderSearch').value||'').toLowerCase(), el=document.getElementById('orderList');el.innerHTML='';UNPLANNED.filter(function(o){return !q || JSON.stringify(o).toLowerCase().indexOf(q)>-1;}).forEach(function(o){var c=document.createElement('div');c.className='order-card '+(o.is_urgent?'urgent':'');c.draggable=true;c.dataset.id=o.p_order_id;c.innerHTML='<b>'+enc(o.p_order_no)+'</b><div class="order-meta"><span>'+enc(o.color_code)+' '+enc(o.color_name)+'</span><span>'+enc(o.company_name)+'</span><span>'+Math.round(o.total_op_minutes/60*10)/10+' sa</span></div>';c.ondragstart=function(ev){DRAGGED_ORDER_ID=o.p_order_id;setDragData(ev,o.p_order_id,'unplanned');};c.ondragend=function(){DRAGGED_ORDER_ID=null;};el.appendChild(c);});}
function renderTimeline(){var ruler=document.getElementById('tlRuler'), lanes=document.getElementById('lanes'), nowX=pxFromDate(new Date()), totalWidth=DAYS*PX_PER_DAY;ruler.innerHTML='';lanes.innerHTML='';ruler.style.position='sticky';for(var i=0;i<DAYS;i++){var d=new Date(START.getTime()+i*86400000), cell=document.createElement('div'), hours='';cell.className='tl-day';for(var h=0;h<24;h++){hours+='<div class="tl-hour">'+pad(h)+':00</div>';}cell.innerHTML='<div class="tl-day-title">'+pad(d.getDate())+'.'+pad(d.getMonth()+1)+'.'+d.getFullYear()+'</div><div class="tl-hours">'+hours+'</div>';ruler.appendChild(cell);}if(nowX>=0&&nowX<=totalWidth){var nowMarker=document.createElement('div');nowMarker.className='tl-now-marker';nowMarker.style.left=nowX+'px';ruler.appendChild(nowMarker);}STATIONS.forEach(function(st){var lane=document.createElement('div');lane.className='lane';lane.innerHTML='<div class="lane-label">'+enc(st.text)+'</div><div class="lane-track" data-station="'+st.id+'" style="width:'+(DAYS*PX_PER_DAY)+'px"></div>';var track=lane.querySelector('.lane-track');if(nowX>=0&&nowX<=totalWidth){var nowLine=document.createElement('div');nowLine.className='now-line';nowLine.style.left=nowX+'px';track.appendChild(nowLine);}track.ondragover=function(ev){ev.preventDefault();track.classList.add('drop-hint');};track.ondragleave=function(){track.classList.remove('drop-hint');};track.ondrop=function(ev){ev.preventDefault();track.classList.remove('drop-hint');var id=getDragOrderId(ev), r=track.getBoundingClientRect(), x=ev.clientX-r.left+track.scrollLeft;if(id) planOrder(id,st.id,snapDateFromX(x),DROP_MODE);};PLANNED.filter(function(j){return j.station_id==st.id;}).forEach(function(j){var job=document.createElement('div');job.className='job '+(j.is_urgent?'urgent':'');job.style.left=pxFromDate(j.startDate)+'px';job.style.width=widthFromDates(j.startDate,j.endDate)+'px';job.title='Sürükle: makine/saat değiştir · Çift tık: plandan kaldır';job.draggable=true;job.dataset.id=j.p_order_id;job.ondragstart=function(ev){DRAGGED_ORDER_ID=j.p_order_id;setDragData(ev,j.p_order_id,'planned');job.classList.add('dragging');};job.ondragend=function(){DRAGGED_ORDER_ID=null;job.classList.remove('dragging');};job.ondragover=function(ev){if(DROP_MODE==='swap'&&String(DRAGGED_ORDER_ID)!==String(j.p_order_id)){ev.preventDefault();job.classList.add('swap-target');}};job.ondragleave=function(){job.classList.remove('swap-target');};job.ondrop=function(ev){if(DROP_MODE!=='swap')return;ev.preventDefault();ev.stopPropagation();job.classList.remove('swap-target');var sourceId=getDragOrderId(ev);if(sourceId&&String(sourceId)!==String(j.p_order_id)) swapOrders(sourceId,j.p_order_id);};job.onclick=function(){openOrderModal(j);};job.ondblclick=function(){unplan(j.p_order_id);};job.innerHTML='<b>'+enc(j.p_order_no)+'</b><small>'+enc(j.color_code)+' '+enc(j.color_name)+'</small><small><span class="job-chip">'+serverDate(new Date(j.startDate)).slice(11,16)+'</span> <span class="job-chip">'+serverDate(new Date(j.endDate)).slice(11,16)+'</span></small>';track.appendChild(job);});lanes.appendChild(lane);});}
function planOrder(id,stationId,start,mode){if(mode==='swap'){toast('Yer değiştirmek için emri başka bir planlı kartın üzerine bırakın.',false);return;}var shift=mode==='move'?0:1;fetch('/production/form/save_plan.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({p_order_id:id,station_id:stationId,start_date:serverDate(start),cell_start_date:serverDate(start),status:1,shift_following:shift,interval_minutes:15,snap_back_minutes:15})}).then(function(r){return r.json();}).then(function(res){toast(res.message,res.success); if(res.success) location.reload();});}
function swapOrders(sourceId,targetId){fetch('/production/form/swap_plan.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({source_p_order_id:sourceId,target_p_order_id:targetId})}).then(function(r){return r.json();}).then(function(res){toast(res.message,res.success); if(res.success) location.reload();});}
document.querySelectorAll('.tl-mode').forEach(function(btn){btn.onclick=function(){DROP_MODE=this.dataset.mode;document.querySelectorAll('.tl-mode').forEach(function(b){b.classList.remove('active');});this.classList.add('active');};});
function unplan(id){if(!confirm('Emir plandan kaldırılsın mı?'))return;fetch('/production/form/unplan_order.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({p_order_id:id})}).then(function(r){return r.json();}).then(function(res){toast(res.message,res.success); if(res.success) location.reload();});}
function toast(m,ok){var t=document.createElement('div');t.className='tl-toast';t.style.background=ok?'##16a34a':'##dc2626';t.textContent=m||'';document.body.appendChild(t);setTimeout(function(){t.remove();},3200);}document.getElementById('orderSearch').oninput=renderOrders;renderOrders();renderTimeline();
</script>
</cfoutput>
