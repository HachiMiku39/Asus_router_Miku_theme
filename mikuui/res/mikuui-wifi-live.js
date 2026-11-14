(function () {
 'use strict';
 var timer=null,pending=false,stopped=false,previous=null,history=[],series=[],signature='';
 var colors=['#39c5bb','#ef8db5','#80b8ff','#e7cd70','#bda3ff','#8cdf9b','#ffa97c','#dadada'];
 function put(id,value){var e=document.getElementById(id);if(e)e.textContent=value;}
 function numeric(value){return typeof value==='number'&&isFinite(value);}
 function rate(now,before,seconds){
  if(!numeric(now)||!numeric(before)||seconds<=0||seconds>10)return null;
  var delta=now-before;
  if(delta<0&&before>4026531840&&before<=4294967295&&now<268435456)delta+=4294967296;
  return delta<0?null:delta/seconds;
 }
 function speed(bytes){if(!numeric(bytes))return '等待采样';var bits=bytes*8;return bits>=1000000?(bits/1000000).toFixed(2)+' Mbit/s':(bits/1000).toFixed(1)+' kbit/s';}
 function normalize(sample){
  if(!sample||!numeric(sample.time))throw new Error('invalid time');
  var rows=sample.radios;
  if(!Array.isArray(rows)&&sample.bands)rows=[{unit:0,iface:'legacy24',frequency:2,data:sample.bands['24']},{unit:1,iface:'legacy5',frequency:1,data:sample.bands['5']}];
  if(!Array.isArray(rows)||!rows.length||rows.length>8)throw new Error('invalid radios');
  var seen={};rows.forEach(function(r){if(!Number.isInteger(r.unit)||r.unit<0||r.unit>7||seen[r.unit]||typeof r.iface!=='string'||!/^[a-zA-Z0-9_.-]{1,32}$/.test(r.iface)||!r.data)throw new Error('invalid radio');seen[r.unit]=true;});
  return rows;
 }
 function configure(rows){
  var next=rows.map(function(r){return r.unit+':'+r.iface+':'+r.frequency;}).join('|');
  if(next===signature)return;signature=next;previous=null;history=[];
  var cards=document.getElementById('liveRadioCards'),legend=document.getElementById('liveRadioLegend');
  cards.textContent='';legend.textContent='';var counts={};
  rows.forEach(function(r){counts[r.frequency]=(counts[r.frequency]||0)+1;});
  series=rows.map(function(r,index){
   var id='r'+r.unit,label=r.frequency===2?'2.4 GHz':r.frequency===1?'5 GHz':r.frequency===4?'6 GHz':'未知频段';
   if(counts[r.frequency]>1||r.frequency===0)label+=' · wl'+r.unit;
   var card=document.createElement('div');card.className='miku-radio';card.style.borderColor=colors[index]+'88';
   var title=document.createElement('h4');title.textContent=label;title.style.color=colors[index];card.appendChild(title);
   var readings=document.createElement('div');readings.className='miku-readings';
   [['温度','Temp'],['连接设备','Clients'],['上传 ↑','Up'],['下载 ↓','Down']].forEach(function(pair){var name=document.createElement('span'),value=document.createElement('strong');name.textContent=pair[0];value.id='live'+pair[1]+'_'+id;value.textContent='读取中';readings.appendChild(name);readings.appendChild(value);});
   card.appendChild(readings);cards.appendChild(card);
   var item=document.createElement('span');item.style.color=colors[index];item.textContent='● '+label+' 温度';legend.appendChild(item);
   return {id:id,label:label,color:colors[index],frequency:r.frequency};
  });
 }
 function draw(){
  var canvas=document.getElementById('wifiTemperatureChart');if(!canvas)return;
  var width=canvas.clientWidth||680,height=190,dpr=window.devicePixelRatio||1;
  canvas.width=width*dpr;canvas.height=height*dpr;
  var c=canvas.getContext('2d');c.scale(dpr,dpr);c.clearRect(0,0,width,height);
  var left=42,right=width-12,top=16,bottom=height-28,min=30,max=80,end=history.length?history[history.length-1].time:0;
  history.forEach(function(p){series.forEach(function(s){if(numeric(p[s.id])){min=Math.min(min,Math.floor((p[s.id]-5)/10)*10);max=Math.max(max,Math.ceil((p[s.id]+5)/10)*10);}});});
  c.font='11px sans-serif';c.lineWidth=1;
  for(var i=0;i<5;i++){var y=top+(bottom-top)*i/4;c.strokeStyle='rgba(180,221,217,.14)';c.beginPath();c.moveTo(left,y);c.lineTo(right,y);c.stroke();c.fillStyle='#b8cecc';c.fillText(Math.round(max-(max-min)*i/4)+'°',4,y+4);}
  c.fillStyle='#b8cecc';c.fillText('−120 秒',left,height-7);c.fillText('−60 秒',(left+right)/2-18,height-7);c.fillText('现在',right-24,height-7);
  series.forEach(function(s){var connected=false;c.strokeStyle=s.color;c.lineWidth=2;c.beginPath();history.forEach(function(p){if(!numeric(p[s.id])){connected=false;return;}var x=left+(p.time-end+120)/120*(right-left),y=bottom-(p[s.id]-min)/(max-min)*(bottom-top);if(connected)c.lineTo(x,y);else c.moveTo(x,y);connected=true;});c.stroke();var last=history[history.length-1];if(last&&numeric(last[s.id])){c.beginPath();c.arc(right,bottom-(last[s.id]-min)/(max-min)*(bottom-top),3,0,Math.PI*2);c.fillStyle=s.color;c.fill();}});
 }
 function accept(sample){
  var rows=normalize(sample);configure(rows);
  if(previous&&sample.time<=previous.time){previous=null;history=[];}
  var point={time:sample.time},totalClients=0,totalUp=0,totalDown=0,allClients=true,allRates=true,oldRadios=previous?previous.radios:{};
  var snapshot={time:sample.time,radios:{}};
  rows.forEach(function(r){
   var id='r'+r.unit,now=r.data,old=oldRadios[id],dt=previous?sample.time-previous.time:0;
   var up=old?rate(now.rx_bytes,old.rx_bytes,dt):null,down=old?rate(now.tx_bytes,old.tx_bytes,dt):null;
   point[id]=numeric(now.temp)?now.temp:null;snapshot.radios[id]=now;
   put('liveTemp_'+id,numeric(now.temp)?now.temp.toFixed(1)+' °C':'暂不可读');
   var same=rows.filter(function(x){return x.frequency===r.frequency;}).length;
   if(same===1&&(r.frequency===2||r.frequency===1))put('temp'+(r.frequency===2?'24':'5'),numeric(now.temp)?now.temp.toFixed(1)+' °C':'暂不可读');
   put('liveClients_'+id,numeric(now.clients)?now.clients+' 台':'暂不可读');put('liveUp_'+id,speed(up));put('liveDown_'+id,speed(down));
   if(numeric(now.clients))totalClients+=now.clients;else allClients=false;
   if(numeric(up)&&numeric(down)){totalUp+=up;totalDown+=down;}else allRates=false;
  });
  put('liveTotalClients',allClients?totalClients+' 台':'部分不可读');put('liveTotalUp',speed(allRates?totalUp:null));put('liveTotalDown',speed(allRates?totalDown:null));
  history.push(point);history=history.filter(function(p){return p.time>=sample.time-120;});previous=snapshot;draw();put('liveStatus','每秒更新 · '+rows.length+' 组射频 · '+new Date().toLocaleTimeString());
 }
 function poll(){
  if(stopped||document.hidden||pending)return;pending=true;var started=Date.now();
  $.ajax({url:'/_api/',type:'POST',contentType:'application/json',dataType:'json',timeout:5000,
   data:JSON.stringify({id:Math.floor(Math.random()*90000000)+1000000,method:'mikuui_wifi_config.sh',params:[6],fields:{}}),
   success:function(r){try{accept(typeof r.result==='string'?JSON.parse(atob(r.result)):r.result);}catch(e){put('liveStatus','当前驱动未提供可用读数，正在重试');previous=null;}},
   error:function(){put('liveStatus','连接中断，正在重试');previous=null;},
   complete:function(){pending=false;if(!stopped&&!document.hidden)timer=setTimeout(poll,Math.max(0,1000-(Date.now()-started)));}
  });
 }
 window.startWifiLive=function(){stopped=false;draw();poll();};
 document.addEventListener('visibilitychange',function(){clearTimeout(timer);if(!document.hidden)poll();});
 window.addEventListener('resize',draw);window.addEventListener('beforeunload',function(){stopped=true;clearTimeout(timer);});
 window.mikuWifiTelemetry={rate:rate,speed:speed,accept:accept};
}());
