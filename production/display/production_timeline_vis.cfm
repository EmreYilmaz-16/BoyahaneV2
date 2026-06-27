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
           COALESCE((SELECT SUM(COALESCE(pop.o_minute, 0)) FROM production_operation pop WHERE pop.p_order_id = po.p_order_id), 0) AS total_op_minutes,
           COALESCE((SELECT COUNT(*) FROM setup_prod_pause sp WHERE sp.p_order_id = po.p_order_id AND sp.duration_finish_date IS NULL), 0) AS active_pause_count
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
        "active_pause_count": val(active_pause_count),
        "total_op_minutes": val(total_op_minutes) gt 0 ? val(total_op_minutes) : 480,
        "startDate": dateFormat(start_date,"yyyy-mm-dd") & "T" & timeFormat(start_date,"HH:mm:ss"),
        "endDate": dateFormat(finish_date,"yyyy-mm-dd") & "T" & timeFormat(finish_date,"HH:mm:ss")
    })>
</cfloop>

<cfset groupsArr = []>
<cfset stationsArr = []>
<cfloop query="qStations">
    <cfif val(up_station) eq 0>
        <cfset arrayAppend(groupsArr, {
            "id": val(station_id),
            "text": station_name ?: ("Grup " & val(station_id))
        })>
    <cfelse>
        <cfset arrayAppend(stationsArr, {
            "id": val(station_id),
            "content": station_name ?: ("Makina " & station_id),
            "capacity": val(capacity),
            "group_id": val(up_station)
        })>
    </cfif>
</cfloop>

<cfoutput>
<link rel="stylesheet" href="https://unpkg.com/vis-timeline@7.7.3/styles/vis-timeline-graph2d.min.css">
<style>
.ptv-page{height:calc(100vh - 122px);display:grid;grid-template-columns:minmax(300px,330px) minmax(620px,1fr);gap:14px;background:##f4f7fb;padding:14px;overflow:hidden;box-sizing:border-box}.ptv-sidebar,.ptv-main{min-width:0;background:##fff;border:1px solid ##d9e2ef;border-radius:14px;box-shadow:0 8px 24px rgba(15,23,42,.08);overflow:hidden}.ptv-head{background:linear-gradient(135deg,##0f2a44,##1d4f7a);color:##fff;padding:14px 16px}.ptv-head h2{font-size:1.05rem;margin:0;line-height:1.25}.ptv-head small{display:block;opacity:.82;margin-top:4px;line-height:1.35}.ptv-tools{display:flex;gap:8px;padding:10px;border-bottom:1px solid ##e5eaf2;align-items:center;flex-wrap:wrap}.ptv-tools input,.ptv-tools select{border:1px solid ##cbd5e1;border-radius:9px;padding:8px 10px;font-size:.84rem}.ptv-group-filter{display:flex;align-items:center;gap:6px;background:##f8fafc;border:1px solid ##e2e8f0;border-radius:10px;padding:6px 8px}.ptv-group-filter label{font-size:.78rem;font-weight:800;color:##475569}.ptv-group-filter select{min-width:150px;background:##fff}.ptv-btn{border:0;border-radius:9px;background:##1d4f7a;color:##fff;padding:8px 11px;font-weight:700;cursor:pointer}.ptv-order-list{height:calc(100% - 116px);overflow:auto;padding:10px}.ptv-order-card{border:1px solid ##d8e3ef;border-left:5px solid ##2563eb;border-radius:12px;padding:10px;margin-bottom:9px;background:##fff;cursor:grab}.ptv-order-card.urgent{border-left-color:##ef4444;background:##fff7f7}.ptv-order-card b{display:block;color:##0f172a}.ptv-order-meta{font-size:.75rem;color:##64748b;display:flex;flex-wrap:wrap;gap:6px;margin-top:5px}.ptv-timeline-wrap{height:calc(100% - 112px);padding:10px;box-sizing:border-box}.ptv-timeline{height:100%;min-height:420px;border:1px solid ##d9e2ef;border-radius:12px}.vis-item.production-job{border:0;border-radius:10px;background:linear-gradient(135deg,##64748b,##475569);color:##fff;box-shadow:0 8px 18px rgba(100,116,139,.2);cursor:pointer}.vis-item.production-job.active{background:linear-gradient(135deg,##2563eb,##1d4ed8);box-shadow:0 8px 18px rgba(37,99,235,.22)}.vis-item.production-job.completed{background:linear-gradient(135deg,##16a34a,##15803d);box-shadow:0 8px 18px rgba(22,163,74,.2)}.vis-item.production-job.paused{background:linear-gradient(135deg,##f59e0b,##d97706);color:##1f2937;box-shadow:0 8px 18px rgba(245,158,11,.22)}.vis-item.production-job.urgent:not(.completed):not(.paused){box-shadow:0 0 0 2px rgba(239,68,68,.35),0 8px 18px rgba(37,99,235,.2)}.vis-item.vis-selected{box-shadow:0 0 0 3px rgba(245,158,11,.35)}.job-title{font-weight:800}.job-sub{font-size:.74rem;opacity:.92}.ptv-toast{position:fixed;right:18px;bottom:18px;color:##fff;border-radius:10px;padding:11px 14px;z-index:9999;box-shadow:0 10px 28px rgba(0,0,0,.2)}.ptv-modal-backdrop{position:fixed;inset:0;background:rgba(15,23,42,.55);z-index:10000;display:none;align-items:center;justify-content:center;padding:20px}.ptv-modal-backdrop.open{display:flex}.ptv-modal{width:min(640px,96vw);background:##fff;border-radius:18px;box-shadow:0 24px 70px rgba(0,0,0,.32);overflow:hidden}.ptv-modal-head{background:linear-gradient(135deg,##0f2a44,##2563eb);color:##fff;padding:16px 18px;display:flex;justify-content:space-between;gap:12px;align-items:flex-start}.ptv-modal-head h3{margin:0;font-size:1.1rem}.ptv-modal-close{border:0;background:rgba(255,255,255,.16);color:##fff;border-radius:10px;width:34px;height:34px;cursor:pointer;font-size:1.2rem}.ptv-modal-body{padding:16px 18px}.detail-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}.detail-item{border:1px solid ##e2e8f0;border-radius:12px;padding:10px;background:##f8fafc}.detail-item span{display:block;color:##64748b;font-size:.72rem;font-weight:800;text-transform:uppercase;letter-spacing:.03em}.detail-item b{display:block;color:##0f172a;margin-top:4px}.detail-wide{grid-column:1/-1}.ptv-modal-foot{padding:12px 18px;border-top:1px solid ##e2e8f0;background:##f8fafc;color:##64748b;font-size:.82rem}
</style>
<div class="ptv-page">
  <aside class="ptv-sidebar">
    <div class="ptv-head"><h2>Planlanmamış Emirler</h2><small>Kartı Vis Timeline üzerindeki makine satırına sürükleyin.</small></div>
    <div class="ptv-tools"><input id="visOrderSearch" placeholder="Emir, renk, müşteri ara..." style="width:100%"></div>
    <div id="visOrderList" class="ptv-order-list"></div>
  </aside>
  <main class="ptv-main">
    <div class="ptv-head"><h2>Vis Timeline Planlama Prototipi</h2><small>vis-timeline: zoom, pan, gruplu satırlar, sürükle-bırak ve düzenlenebilir aralık kartları.</small></div>
    <div class="ptv-tools">
      <input id="visStartDate" type="date" title="Başlangıç tarihi">
      <select id="visDaySelect"><option value="3">3 gün</option><option value="7">7 gün</option><option value="14">14 gün</option><option value="30">30 gün</option></select>
      <div class="ptv-group-filter">
        <label for="visGroupFilter">Grup:</label>
        <select id="visGroupFilter" onchange="applyGroupFilter(this.value)"><option value="0">Tüm Gruplar</option></select>
      </div>
      <button class="ptv-btn" type="button" onclick="reloadPlannedForCurrentWindow(true)">Yenile</button>
      <span style="color:##64748b;font-size:.82rem">Kartları taşıyınca mevcut save_plan.cfm servisi ile 5 dakikaya yuvarlanarak kaydedilir.</span>
    </div>
    <div class="ptv-timeline-wrap"><div id="visProductionTimeline" class="ptv-timeline"></div></div>
  </main>
</div>
<div class="ptv-modal-backdrop" id="visOrderModal" onclick="closeOrderModal(event)">
  <div class="ptv-modal" onclick="event.stopPropagation()">
    <div class="ptv-modal-head"><div><h3 id="visModalTitle">Emir Detayı</h3><small id="visModalSub"></small></div><button class="ptv-modal-close" type="button" onclick="closeOrderModal()">×</button></div>
    <div class="ptv-modal-body" id="visModalBody"></div>
    <div class="ptv-modal-foot">İpucu: Timeline üzerindeki kartı sürükleyerek makine veya saat bilgisini değiştirebilirsiniz.</div>
  </div>
</div>
<script src="https://unpkg.com/vis-timeline@7.7.3/standalone/umd/vis-timeline-graph2d.min.js"></script>
<script>
var UNPLANNED=#serializeJSON(unplannedArr)#, PLANNED=#serializeJSON(plannedArr)#, ALL_STATIONS=#serializeJSON(stationsArr)#, GROUPS=#serializeJSON(groupsArr)#, STATIONS=ALL_STATIONS.slice();
var activeGroupId=0;
var START=new Date('#dateFormat(timelineStart,"yyyy-mm-dd")#T00:00:00'), END=new Date('#dateFormat(timelineEnd,"yyyy-mm-dd")#T00:00:00'), INITIAL_END=addMins(new Date('#dateFormat(timelineStart,"yyyy-mm-dd")#T00:00:00'),480), timeline, items, groups, draggedOrder=null, plannedLoadTimer=null, plannedLoadSeq=0;
var VisTimeline=window.vis||{};
var PTV_DEBUG=false;
document.getElementById('visDaySelect').value=String(#viewDays#);
document.getElementById('visStartDate').value='#dateFormat(timelineStart,"yyyy-mm-dd")#';
document.getElementById('visDaySelect').onchange=function(){setWindowFromControls();};
document.getElementById('visStartDate').onchange=function(){setWindowFromControls();};
function ptvLog(){if(PTV_DEBUG&&window.console&&console.debug)console.debug.apply(console,arguments);}
function enc(s){return String(s||'').replace(/[&<>]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;'}[c];});}
function pad(n){return n<10?'0'+n:n;} function serverDate(d){return d.getFullYear()+'-'+pad(d.getMonth()+1)+'-'+pad(d.getDate())+' '+pad(d.getHours())+':'+pad(d.getMinutes())+':00';}
function snapDate(d){var ms=5*60000;return new Date(Math.round(d.getTime()/ms)*ms);} function addMins(d,m){return new Date(d.getTime()+m*60000);}
function toast(m,ok){var t=document.createElement('div');t.className='ptv-toast';t.style.background=ok?'##16a34a':'##dc2626';t.textContent=m||'';document.body.appendChild(t);setTimeout(function(){t.remove();},3200);}
function itemContent(o){return '<div class="job-title">'+enc(o.p_order_no)+'</div><div class="job-sub">'+enc(o.color_code)+' '+enc(o.color_name)+' · '+Math.round((o.total_op_minutes||480)/60*10)/10+' sa</div>';}
function statusLabel(status){status=Number(status||1);return status===1?'Planlandı':(status===2?'Devam Ediyor':(status===5?'Tamamlandı':(status===9?'İptal':'Bilinmiyor')));}function itemClass(o){var cls='production-job';if(Number(o.active_pause_count||0)>0)cls+=' paused';else if(Number(o.status)===2)cls+=' active';else if(Number(o.status)===5)cls+=' completed';if(o.is_urgent)cls+=' urgent';return cls;}
function rangeDate(d){return d.getFullYear()+'-'+pad(d.getMonth()+1)+'-'+pad(d.getDate())+'T'+pad(d.getHours())+':'+pad(d.getMinutes())+':00';}
function fmtDate(v){return v?serverDate(new Date(v)).slice(0,16):'-';}
function detailItem(label,value,wide){return '<div class="detail-item '+(wide?'detail-wide':'')+'"><span>'+enc(label)+'</span><b>'+enc(value||'-')+'</b></div>';}
function findOrder(id){id=String(id);var item=items&&items.get(id);if(item&&item.order)return item.order;return PLANNED.concat(UNPLANNED).filter(function(o){return String(o.p_order_id)===id;})[0];}
function openOrderModal(order){if(!order)return;document.getElementById('visModalTitle').textContent=order.p_order_no||('Emir ##'+order.p_order_id);document.getElementById('visModalSub').textContent=(order.station_name||'Planlanmamış')+' · '+statusLabel(order.status)+' · '+Math.round((order.total_op_minutes||480)/60*10)/10+' sa';document.getElementById('visModalBody').innerHTML='<div class="detail-grid">'+detailItem('Müşteri',order.company_name)+detailItem('Renk',((order.color_code||'')+' '+(order.color_name||'')).trim())+detailItem('Parti No',order.lot_no)+detailItem('Stok Kodu',order.stock_code)+detailItem('Makine',order.station_name)+detailItem('Miktar',order.quantity)+detailItem('Başlangıç',fmtDate(order.startDate))+detailItem('Bitiş',fmtDate(order.endDate))+detailItem('Durum',statusLabel(order.status))+detailItem('Aciliyet',order.is_urgent?'Acil':'Normal')+'</div>';document.getElementById('visOrderModal').classList.add('open');}
function closeOrderModal(ev){if(ev&&ev.target&&ev.target.id!=='visOrderModal')return;document.getElementById('visOrderModal').classList.remove('open');}
function setWindowFromControls(){var days=parseInt(document.getElementById('visDaySelect').value,10)||7, raw=document.getElementById('visStartDate').value, nextStart=raw?new Date(raw+'T00:00:00'):new Date(START), nextEnd=new Date(nextStart.getTime()+days*86400000);START=nextStart;END=nextEnd;INITIAL_END=addMins(new Date(START),480);if(timeline){timeline.setOptions({min:START,max:END});timeline.setWindow(START,INITIAL_END,{animation:false});reloadPlannedForCurrentWindow(true);}}
function getActiveStations(){if(!activeGroupId)return ALL_STATIONS;return ALL_STATIONS.filter(function(s){return Number(s.group_id)===activeGroupId;});}
function activeStationMap(){var map={};getActiveStations().forEach(function(s){map[String(s.id)]=true;});return map;}
function refreshTimelineFilter(){STATIONS=getActiveStations();if(groups){groups.clear();groups.add(STATIONS);}if(items){var visible=activeStationMap(), nextIds={};PLANNED.forEach(function(o){if(visible[String(o.station_id)]){nextIds[o.p_order_id]=true;items.update({id:o.p_order_id,group:o.station_id,start:o.startDate,end:o.endDate,content:itemContent(o),className:itemClass(o),order:o});}});items.getIds().forEach(function(id){if(!nextIds[id])items.remove(id);});}}
function populateGroupFilter(){var sel=document.getElementById('visGroupFilter');if(!sel)return;GROUPS.forEach(function(g){var opt=document.createElement('option');opt.value=g.id;opt.textContent=g.text;sel.appendChild(opt);});if(!GROUPS.length){var wrap=document.querySelector('.ptv-group-filter');if(wrap)wrap.style.display='none';}}
function applyGroupFilter(val){activeGroupId=parseInt(val,10)||0;refreshTimelineFilter();}
function mergePlannedOrders(data){PLANNED=data||[];refreshTimelineFilter();}
function reloadPlannedRange(startDate,endDate,showToast){if(!items)return;var seq=++plannedLoadSeq, qs=new URLSearchParams({start_date:rangeDate(startDate),end_date:rangeDate(endDate)});fetch('/production/form/get_planned_orders.cfm?'+qs.toString(),{headers:{'Accept':'application/json'}}).then(function(r){return r.json();}).then(function(res){if(seq!==plannedLoadSeq)return;if(res&&res.success){mergePlannedOrders(res.data||[]);if(showToast)toast('Planlı emirler güncellendi.',true);}else if(showToast)toast((res&&res.message)||'Planlı emirler alınamadı.',false);}).catch(function(){if(showToast)toast('Planlı emirler alınamadı.',false);});}
function reloadPlannedForCurrentWindow(showToast){reloadPlannedRange(START,END,showToast);}
function groupFromDrop(ev,props){if(props&&props.group!==undefined&&props.group!==null&&props.group!=='')return props.group;var rows=document.querySelectorAll('##visProductionTimeline .vis-foreground .vis-group');if(!rows.length)rows=document.querySelectorAll('##visProductionTimeline .vis-labelset .vis-label');for(var i=0;i<rows.length;i++){var r=rows[i].getBoundingClientRect();if(ev.clientY>=r.top&&ev.clientY<=r.bottom&&STATIONS[i])return STATIONS[i].id;}return null;}
function removeUnplanned(id){UNPLANNED=UNPLANNED.filter(function(o){return String(o.p_order_id)!==String(id);});renderOrders();}
function updateShiftedItems(res){(res.shifted_orders||[]).forEach(function(s){PLANNED.forEach(function(o){if(String(o.p_order_id)===String(s.p_order_id)){o.startDate=s.start_date;o.endDate=s.finish_date;}});var item=items.get(s.p_order_id);if(item){if(item.order){item.order.startDate=s.start_date;item.order.endDate=s.finish_date;}items.update({id:s.p_order_id,start:s.start_date,end:s.finish_date,order:item.order});}});}
function applyPlanResult(order,stationId,res){var start=res.start_date||serverDate(new Date(order.startDate||new Date())).replace(' ','T'), finish=res.finish_date||serverDate(addMins(new Date(start),order.total_op_minutes||480)).replace(' ','T');order.station_id=stationId;order.startDate=start;order.endDate=finish;order.total_op_minutes=res.total_op_minutes||order.total_op_minutes||480;var idx=-1;PLANNED.some(function(o,i){if(String(o.p_order_id)===String(order.p_order_id)){idx=i;return true;}return false;});if(idx>-1)PLANNED[idx]=order;else PLANNED.push(order);var visible=activeStationMap()[String(stationId)], existing=items.get(order.p_order_id), item={id:order.p_order_id,group:stationId,start:start,end:finish,content:itemContent(order),className:itemClass(order),order:order};if(visible){if(existing)items.update(item);else items.add(item);}else if(existing){items.remove(order.p_order_id);}removeUnplanned(order.p_order_id);updateShiftedItems(res);}
function renderOrders(){var q=(document.getElementById('visOrderSearch').value||'').toLowerCase(), el=document.getElementById('visOrderList');el.innerHTML='';UNPLANNED.filter(function(o){return !q || JSON.stringify(o).toLowerCase().indexOf(q)>-1;}).forEach(function(o){var c=document.createElement('div');c.className='ptv-order-card '+(o.is_urgent?'urgent':'');c.draggable=true;c.dataset.id=o.p_order_id;c.innerHTML='<b>'+enc(o.p_order_no)+'</b><div class="ptv-order-meta"><span>'+enc(o.color_code)+' '+enc(o.color_name)+'</span><span>'+enc(o.company_name)+'</span><span>'+Math.round(o.total_op_minutes/60*10)/10+' sa</span></div>';c.addEventListener('mousedown',function(ev){ptvLog('[PTV] card mousedown',{id:o.p_order_id,target:ev.target});});c.addEventListener('dragstart',function(ev){draggedOrder=o;ev.dataTransfer.effectAllowed='move';ev.dataTransfer.setData('text/plain',JSON.stringify(o));ev.dataTransfer.setData('application/x-production-order',String(o.p_order_id));ptvLog('[PTV] card dragstart',{id:o.p_order_id,types:Array.prototype.slice.call(ev.dataTransfer.types||[])});});c.addEventListener('dragend',function(ev){ptvLog('[PTV] card dragend',{id:o.p_order_id,dropEffect:ev.dataTransfer&&ev.dataTransfer.dropEffect});draggedOrder=null;});el.appendChild(c);});ptvLog('[PTV] renderOrders',{count:el.children.length});}
function buildTimeline(){if(!VisTimeline.Timeline||!VisTimeline.DataSet){toast('Vis Timeline kütüphanesi yüklenemedi.',false);return;}STATIONS=getActiveStations();var visible=activeStationMap();groups=new VisTimeline.DataSet(STATIONS);items=new VisTimeline.DataSet(PLANNED.filter(function(o){return visible[String(o.station_id)];}).map(function(o){return {id:o.p_order_id, group:o.station_id, start:o.startDate, end:o.endDate, content:itemContent(o), className:itemClass(o), order:o};}));timeline=new VisTimeline.Timeline(document.getElementById('visProductionTimeline'),items,groups,{start:START,end:INITIAL_END,min:START,max:END,zoomMin:10*60*1000,stack:false,editable:{updateTime:true,updateGroup:true,add:false,remove:false,overrideItems:false},orientation:'top',margin:{item:10,axis:8},snap:function(date){return snapDate(date);},onMove:function(item,callback){var start=snapDate(new Date(item.start)), order=(items.get(item.id)||{}).order||{p_order_id:item.id,total_op_minutes:480};ptvLog('[PTV] internal onMove',{id:item.id,group:item.group,start:start});savePlan(item.id,item.group,start,1,function(ok,res){if(ok){applyPlanResult(order,item.group,res);item.start=res.start_date;item.end=res.finish_date;callback(item);}else callback(null);});}});timeline.on('rangechanged',function(props){clearTimeout(plannedLoadTimer);plannedLoadTimer=setTimeout(function(){reloadPlannedRange(new Date(props.start),new Date(props.end),false);},450);});timeline.on('select',function(props){if(props.items&&props.items.length){openOrderModal(findOrder(props.items[0]));}});timeline.on('doubleClick',function(props){if(props.item){openOrderModal(findOrder(props.item));}});var container=document.getElementById('visProductionTimeline');ptvLog('[PTV] buildTimeline ready',{stations:STATIONS.length,planned:PLANNED.length,container:!!container});function onTimelineDrop(ev){if(!draggedOrder)return;ev.preventDefault();ev.stopPropagation();var props=timeline.getEventProperties(ev), raw=ev.dataTransfer.getData('text/plain'), stationId=groupFromDrop(ev,props);ptvLog('[PTV] timeline drop',{rawLength:raw&&raw.length,types:Array.prototype.slice.call(ev.dataTransfer.types||[]),group:props.group,stationId:stationId,time:props.time,draggedOrder:draggedOrder&&draggedOrder.p_order_id,target:ev.target&&ev.target.className});if(!stationId){toast('Emri bir makine satırının üzerine bırakın.',false);return;}if(!props.time){toast('Emri zaman çizelgesi alanına bırakın.',false);return;}if(!raw&&!draggedOrder){toast('Sürüklenen emir okunamadı.',false);return;}try{var o=draggedOrder||JSON.parse(raw), start=snapDate(props.time);ptvLog('[PTV] savePlan start',{id:o.p_order_id,stationId:stationId,start:start});savePlan(o.p_order_id,stationId,start,1,function(ok,res){ptvLog('[PTV] savePlan done',{id:o.p_order_id,ok:ok});if(ok)applyPlanResult(o,stationId,res);},props.time);}catch(e){ptvLog('[PTV] drop parse error',e);toast('Sürüklenen emir okunamadı.',false);}finally{draggedOrder=null;}}container.addEventListener('dragenter',function(ev){ptvLog('[PTV] timeline dragenter',{target:ev.target&&ev.target.className,draggedOrder:draggedOrder&&draggedOrder.p_order_id});},true);container.addEventListener('dragover',function(ev){if(!draggedOrder)return;ev.preventDefault();ev.stopPropagation();ev.dataTransfer.dropEffect='move';var props=timeline.getEventProperties(ev);ptvLog('[PTV] timeline dragover',{x:ev.clientX,y:ev.clientY,group:props.group,time:props.time,draggedOrder:draggedOrder&&draggedOrder.p_order_id});},true);container.addEventListener('drop',onTimelineDrop,true);}
function savePlan(id,stationId,start,shiftFollowing,done,cellStart){var data={p_order_id:id,station_id:stationId,start_date:serverDate(start),cell_start_date:serverDate(cellStart||start),status:1,shift_following:shiftFollowing?1:0,interval_minutes:5,snap_back_minutes:5};function ok(res){toast(res.message,res.success);if(done)done(!!res.success,res||{});}function fail(){toast('Plan kaydedilemedi.',false);if(done)done(false,{});}if(window.jQuery){$.ajax({url:'/production/form/save_plan.cfm',method:'POST',data:data,dataType:'json'}).done(ok).fail(fail);}else{fetch('/production/form/save_plan.cfm',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams(data)}).then(function(r){return r.json();}).then(ok).catch(fail);}}
document.getElementById('visOrderSearch').oninput=renderOrders;populateGroupFilter();renderOrders();buildTimeline();
</script>
</cfoutput>
