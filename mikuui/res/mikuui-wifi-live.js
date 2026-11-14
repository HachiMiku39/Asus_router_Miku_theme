(function () {
 'use strict';
 var timer=null,pending=false,stopped=false,previous=null,history=[];
 function put(id,value){var e=document.getElementById(id);if(e)e.textContent=value;}
 function numeric(value){return typeof value==='number'&&isFinite(value);}
 function rate(now,before,seconds){
  if(!numeric(now)||!numeric(before)||seconds<=0||seconds>10)return null;
  var delta=now-before;
  // Broadcom's legacy byte counters wrap at 32 bits; counter resets are gaps.
  if(delta<0&&before>4026531840&&before<=4294967295&&now<268435456)delta+=4294967296;
  return delta<0?null:delta/seconds;
 }
 function speed(bytes){if(!numeric(bytes))return '等待采样';var bits=bytes*8;return bits>=1000000?(bits/1000000).toFixed(2)+' Mbit/s':(bits/1000).toFixed(1)+' kbit/s';}
 function draw(){
  var canvas=document.getElementById('wifiTemperatureChart');if(!canvas)return;
  var width=canvas.clientWidth||680,height=190,dpr=window.devicePixelRatio||1;
  canvas.width=width*dpr;canvas.height=height*dpr;
  var c=canvas.getContext('2d');c.scale(dpr,dpr);c.clearRect(0,0,width,height);
  var left=42,right=width-12,top=16,bottom=height-28,min=30,max=80,end=history.length?history[history.length-1].time:0;
  history.forEach(function(p){['24','5'].forEach(function(b){if(numeric(p[b])){min=Math.min(min,Math.floor((p[b]-5)/10)*10);max=Math.max(max,Math.ceil((p[b]+5)/10)*10);}});});
  c.font='11px sans-serif';c.lineWidth=1;
  for(var i=0;i<5;i++){var y=top+(bottom-top)*i/4;c.strokeStyle='rgba(180,221,217,.14)';c.beginPath();c.moveTo(left,y);c.lineTo(right,y);c.stroke();c.fillStyle='#b8cecc';c.fillText(Math.round(max-(max-min)*i/4)+'°',4,y+4);}
  c.fillStyle='#b8cecc';c.fillText('−120 秒',left,height-7);c.fillText('−60 秒',(left+right)/2-18,height-7);c.fillText('现在',right-24,height-7);
  ['24','5'].forEach(function(b,index){var connected=false;c.strokeStyle=index?'#ef8db5':'#39c5bb';c.lineWidth=2;c.beginPath();history.forEach(function(p){if(!numeric(p[b])){connected=false;return;}var x=left+(p.time-end+120)/120*(right-left),y=bottom-(p[b]-min)/(max-min)*(bottom-top);if(connected)c.lineTo(x,y);else c.moveTo(x,y);connected=true;});c.stroke();
   var last=history[history.length-1];if(last&&numeric(last[b])){c.beginPath();c.arc(right,bottom-(last[b]-min)/(max-min)*(bottom-top),3,0,Math.PI*2);c.fillStyle=c.strokeStyle;c.fill();}
  });
 }
 function accept(sample){
  if(!sample||!numeric(sample.time)||!sample.bands)throw new Error('invalid telemetry');
  if(previous&&sample.time<=previous.time){previous=null;history=[];}
  var point={time:sample.time},totalClients=0,totalUp=0,totalDown=0,allClients=true,allRates=true;
  ['24','5'].forEach(function(b){
   var now=sample.bands[b]||{},old=previous&&previous.bands[b],dt=previous?sample.time-previous.time:0;
   var up=old?rate(now.rx_bytes,old.rx_bytes,dt):null,down=old?rate(now.tx_bytes,old.tx_bytes,dt):null;
   point[b]=numeric(now.temp)?now.temp:null;
   put('liveTemp'+b,numeric(now.temp)?now.temp.toFixed(1)+' °C':'暂不可读');
   put('temp'+b,numeric(now.temp)?now.temp.toFixed(1)+' °C':'暂不可读');
   put('liveClients'+b,numeric(now.clients)?now.clients+' 台':'暂不可读');
   put('liveUp'+b,speed(up));put('liveDown'+b,speed(down));
   if(numeric(now.clients))totalClients+=now.clients;else allClients=false;
   if(numeric(up)&&numeric(down)){totalUp+=up;totalDown+=down;}else allRates=false;
  });
  put('liveTotalClients',allClients?totalClients+' 台':'暂不可读');
  put('liveTotalUp',speed(allRates?totalUp:null));put('liveTotalDown',speed(allRates?totalDown:null));
  history.push(point);history=history.filter(function(p){return p.time>=sample.time-120;});
  previous=sample;draw();put('liveStatus','每秒更新 · '+new Date().toLocaleTimeString());
 }
 function poll(){
  if(stopped||document.hidden||pending)return;pending=true;var started=Date.now();
  $.ajax({url:'/_api/',type:'POST',contentType:'application/json',dataType:'json',timeout:5000,
   data:JSON.stringify({id:Math.floor(Math.random()*90000000)+1000000,method:'mikuui_wifi_config.sh',params:[6],fields:{}}),
   success:function(r){try{accept(typeof r.result==='string'?JSON.parse(atob(r.result)):r.result);}catch(e){put('liveStatus','读数暂不可用，正在重试');previous=null;}},
   error:function(){put('liveStatus','连接中断，正在重试');previous=null;},
   complete:function(){pending=false;if(!stopped&&!document.hidden)timer=setTimeout(poll,Math.max(0,1000-(Date.now()-started)));}
  });
 }
 window.startWifiLive=function(){stopped=false;draw();poll();};
 document.addEventListener('visibilitychange',function(){clearTimeout(timer);if(!document.hidden)poll();});
 window.addEventListener('resize',draw);
 window.addEventListener('beforeunload',function(){stopped=true;clearTimeout(timer);});
 // Pure helpers are exposed for fixture tests; no router writes are available here.
 window.mikuWifiTelemetry={rate:rate,speed:speed};
}());
