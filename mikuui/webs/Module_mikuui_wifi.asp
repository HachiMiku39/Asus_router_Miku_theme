<!DOCTYPE html>
<html><head>
<meta http-equiv="X-UA-Compatible" content="IE=edge"><meta charset="utf-8">
<meta http-equiv="Pragma" content="no-cache"><meta http-equiv="Expires" content="-1">
<title>初音未来主题 + Wi-Fi Boost</title>
<link rel="icon" href="/res/icon-mikuui.png">
<link rel="stylesheet" href="/index_style.css"><link rel="stylesheet" href="/form_style.css"><link rel="stylesheet" href="/res/softcenter.css">
<script src="/js/jquery.js"></script><script src="/state.js"></script><script src="/general.js"></script><script src="/popup.js"></script><script src="/help.js"></script><script src="/res/softcenter.js"></script>
<style>
.miku-card{padding:24px;border:1px solid #39c5bb66;border-radius:12px;background:linear-gradient(135deg,#143d40,#10212c 70%);color:#efffff;margin:12px 0 18px;overflow:hidden;min-height:170px;box-sizing:border-box}
.miku-card img{float:right;width:178px;height:178px;object-fit:contain;margin:-10px 0 -10px 8px}
.miku-eyebrow{font-size:11px;letter-spacing:3px;color:#88e8de}.miku-card h2{font-size:28px;line-height:1.3;letter-spacing:1px;margin:12px 0;color:#f5ffff}.miku-card p{line-height:1.8;max-width:460px;color:#c1dcd9}
.miku-chip{display:inline-block;padding:4px 10px;border:1px solid #39c5bb77;border-radius:20px;color:#92ebe1;font-size:12px}.miku-chip.pink{border-color:#ed559b88;color:#f69ac5;margin-left:6px}
.miku-status{padding:12px 0;font-size:14px;line-height:1.8}.miku-dot{display:inline-block;width:8px;height:8px;border-radius:50%;background:#829597;margin-right:8px}.miku-dot.on{background:#39c5bb;box-shadow:0 0 10px #39c5bb88}
.miku-actions{display:flex;gap:12px;flex-wrap:wrap;margin:16px 0}.miku-actions button{font:inherit;padding:10px 20px;border-radius:6px;border:1px solid #39c5bb;cursor:pointer;background:#39c5bb;color:#0d2527;font-weight:bold}.miku-actions .secondary{background:transparent;color:inherit;border-color:#658887}.miku-actions button:disabled{opacity:.45;cursor:wait}.miku-caption{line-height:1.8;font-size:12px;color:#bad0cf}.miku-message{min-height:24px;line-height:1.7;color:#ace8de}
.miku-page-heading{display:flex;justify-content:space-between;align-items:center;gap:16px;flex-wrap:wrap}.miku-back{display:inline-block;padding:9px 16px;border:1px solid #39c5bb;border-radius:6px;color:#b6fff1!important;text-decoration:none!important;font-size:13px;white-space:nowrap}.miku-disclaimer{border:1px solid #ef8db577;border-left:3px solid #ef8db5;border-radius:6px;padding:14px 16px;margin:8px 0 18px;line-height:1.8;color:#e2eceb;font-size:13px}.miku-disclaimer h3{margin:0 0 6px;font-size:14px;color:#ffbad7}.miku-disclaimer p{margin:0}.miku-unit{min-width:190px;text-align:right;font-variant-numeric:tabular-nums}
.miku-live{margin:18px 0;padding:18px;border:1px solid #39c5bb66;border-radius:8px;background:#10262c}.miku-live h3{margin:0 0 8px;color:#ecfffc}.miku-live-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}.miku-radio{padding:12px;border:1px solid #39c5bb44;border-radius:6px;background:#122c31}.miku-radio.five{border-color:#ef8db566}.miku-radio h4{margin:0 0 8px;color:#6de4d7}.miku-radio.five h4{color:#ffafd2}.miku-readings{display:grid;grid-template-columns:1fr auto;gap:7px 12px;font-size:13px}.miku-readings strong{font-variant-numeric:tabular-nums}.miku-total{display:flex;flex-wrap:wrap;gap:10px 22px;margin:14px 0;font-size:13px}.miku-legend{font-size:12px;margin:12px 0 2px}.miku-legend span{margin-right:18px}.miku-chart{display:block;width:100%;height:190px}.miku-live-status{font-size:12px;color:#b4d3cf}
</style>
<script src="/res/mikuui-wifi-live.js"></script>
<script>
function menu_hook(){tabtitle[tabtitle.length-1]=['','主题外观','Wi-Fi Boost'];tablink[tablink.length-1]=['','Module_mikuui.asp','Module_mikuui_wifi.asp'];}
var wifiToken='', loaded=false;
function field(id,value){document.getElementById(id).textContent=value;}
function formatPower(value){var n=Number(value);return value!==''&&value!=null&&isFinite(n)?n.toFixed(2)+' dBm / '+Math.pow(10,n/10).toFixed(2)+' mW':'暂不可读';}
function loadWifi(){
 $.ajax({url:'/_api/mikuui_wifi_',cache:false,dataType:'json',success:function(r){
  var s=r.result[0]||{};wifiToken=s.mikuui_wifi_token||'';
  ['24','5'].forEach(function(b){
   var temp=s['mikuui_wifi_temp'+b],power=s['mikuui_wifi_power'+b],max=s['mikuui_wifi_max'+b];
   field('temp'+b, temp&&temp!=='unknown'?temp+' °C':'暂不可读');
   field('power'+b,formatPower(power));
   field('max'+b,formatPower(max));
   if(!loaded){document.getElementById('dbm'+b).value=s['mikuui_wifi_dbm'+b]||'20';document.getElementById('on'+b).checked=s['mikuui_wifi_on'+b]!=='0';updateValue(b);}
  });
  field('wifiMessage',s.mikuui_wifi_message||'选择频段并预览，然后应用设置。');
  field('backupStatus',s.mikuui_wifi_backup==='1'?'已保留本机备份':'首次应用前自动备份');
  document.getElementById('wifiApply').disabled=s.mikuui_wifi_ready!=='1';
  document.getElementById('wifiRestore').disabled=s.mikuui_wifi_backup!=='1';loaded=true;
 },error:function(){field('wifiMessage','无法读取状态，请重新登录后刷新。');}});
}
function updateValue(b){field('value'+b,formatPower(document.getElementById('dbm'+b).value));}
function wifiAction(action){
 var fields={};if(action===2||action===3){['24','5'].forEach(function(b){fields['mikuui_wifi_on'+b]=document.getElementById('on'+b).checked?'1':'0';fields['mikuui_wifi_dbm'+b]=document.getElementById('dbm'+b).value;});}
 if(action===3||action===4){
  var message=action===3?'应用所选功率上限后，路由器会在 5 秒后重启。Wi-Fi 和经过本路由器的连接将暂时断开。地区、代理和防火墙保持当前设置。继续吗？':'恢复本机备份后将重启路由器，连接会暂时断开。继续吗？';
  if(!window.confirm(message))return;
  fields.mikuui_wifi_confirm='1';fields.mikuui_wifi_confirm_token=wifiToken;
 }
 field('wifiMessage',action===1?'正在读取无线状态…':'正在处理…');
 $.ajax({url:'/_api/',type:'POST',contentType:'application/json',dataType:'json',timeout:20000,
 data:JSON.stringify({id:Math.floor(Math.random()*90000000)+1000000,method:'mikuui_wifi_config.sh',params:[action],fields:fields}),
 success:function(){if(action===3||action===4){field('wifiMessage','操作已提交。如设置有变化，路由器即将重启；请稍后刷新。');}else{setTimeout(loadWifi,300);}},
 error:function(){field('wifiMessage','无法确认结果。若路由器正在重启，请恢复连接后刷新。');}});
}
function readLog(){
 $.ajax({url:'/_api/',type:'POST',contentType:'application/json',dataType:'json',data:JSON.stringify({id:Math.floor(Math.random()*90000000)+1000000,method:'mikuui_wifi_config.sh',params:[5],fields:{}}),success:function(r){try{var bytes=Uint8Array.from(atob(r.result||''),function(c){return c.charCodeAt(0);});field('wifiLog',new TextDecoder('utf-8').decode(bytes)||'尚无日志');}catch(e){field('wifiLog','无法读取日志，请刷新重试。');}}});
}
function init(){show_menu(menu_hook);wifiAction(1);startWifiLive();}
</script></head>
<body onload="init();">
<div id="TopBanner"></div><div id="Loading" class="popup_bg"></div>
<table class="content" align="center" cellpadding="0" cellspacing="0"><tr>
<td width="17">&nbsp;</td><td valign="top" width="202"><div id="mainMenu"></div><div id="subMenu"></div></td>
<td valign="top"><div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0"><tr><td>
<table width="760" border="0" cellpadding="5" cellspacing="0" class="FormTitle" id="FormTitle"><tr><td bgcolor="#4D595D" valign="top">
<div style="padding:16px 12px">
<div class="miku-page-heading"><div class="formfonttitle">Wi-Fi Boost <span style="font-size:12px;font-weight:normal;opacity:.65">2.0.0 · 本地版</span></div><a class="miku-back" href="/Module_Softcenter.asp">← 返回软件中心</a></div>
<p class="miku-caption">安装即可使用，无需机器码、激活码或支付服务。这里调整的是校准功率上限；实际发射功率取决于地区和驱动。</p>
<section class="miku-live" aria-labelledby="liveTitle"><h3 id="liveTitle">无线实时状态</h3><div id="liveStatus" class="miku-live-status" role="status">正在等待首次采样…</div>
<div class="miku-total"><span>总连接数 <strong id="liveTotalClients">读取中</strong></span><span>总上传 ↑ <strong id="liveTotalUp">等待采样</strong></span><span>总下载 ↓ <strong id="liveTotalDown">等待采样</strong></span></div>
<div class="miku-live-grid"><div class="miku-radio"><h4>2.4 GHz</h4><div class="miku-readings"><span>温度</span><strong id="liveTemp24">读取中</strong><span>连接设备</span><strong id="liveClients24">读取中</strong><span>上传 ↑</span><strong id="liveUp24">等待采样</strong><span>下载 ↓</span><strong id="liveDown24">等待采样</strong></div></div>
<div class="miku-radio five"><h4>5 GHz</h4><div class="miku-readings"><span>温度</span><strong id="liveTemp5">读取中</strong><span>连接设备</span><strong id="liveClients5">读取中</strong><span>上传 ↑</span><strong id="liveUp5">等待采样</strong><span>下载 ↓</span><strong id="liveDown5">等待采样</strong></div></div></div>
<div class="miku-legend"><span style="color:#39c5bb">● 2.4 GHz 温度</span><span style="color:#ef8db5">● 5 GHz 温度</span></div><canvas id="wifiTemperatureChart" class="miku-chart" role="img" aria-label="最近两分钟的 2.4 GHz 和 5 GHz 温度曲线，当前温度见上方读数"></canvas>
<p class="miku-caption" style="margin-bottom:0">每秒采样，保留最近两分钟曲线；页面切到后台时暂停。上传/下载以无线终端为视角，统计各频段流量（包含内网流量），总计为两个频段相加。驱动统计可能受硬件加速影响，首次采样与计数重置时等待下一次有效读数。</p></section>
<table class="FormTable" width="100%" cellpadding="10" cellspacing="0" border="1"><thead><tr><td>频段</td><td>温度</td><td>驱动目标功率</td><td>当前校准上限</td></tr></thead><tbody>
<tr><th>2.4 GHz</th><td id="temp24">读取中</td><td id="power24">读取中</td><td id="max24">读取中</td></tr>
<tr><th>5 GHz</th><td id="temp5">读取中</td><td id="power5">读取中</td><td id="max5">读取中</td></tr></tbody></table>
<div style="padding:24px 0"><label><input type="checkbox" id="on24" checked> 调整 2.4 GHz</label><div style="display:flex;gap:16px;align-items:center;margin-top:12px"><input id="dbm24" type="range" min="5" max="28.5" step="0.25" value="20" style="flex:1;accent-color:#39c5bb" oninput="updateValue('24')"><span id="value24" class="miku-unit">20.00 dBm / 100.00 mW</span></div></div>
<div style="padding:8px 0 24px"><label><input type="checkbox" id="on5" checked> 调整 5 GHz</label><div style="display:flex;gap:16px;align-items:center;margin-top:12px"><input id="dbm5" type="range" min="5" max="28.5" step="0.25" value="20" style="flex:1;accent-color:#39c5bb" oninput="updateValue('5')"><span id="value5" class="miku-unit">20.00 dBm / 100.00 mW</span></div></div>
<p class="miku-caption">mW 按 10^(dBm / 10) 换算，与对应 dBm 读数表示同一功率值，不是独立的射频实测结果。</p>
<section id="wifiDisclaimer" class="miku-disclaimer" aria-labelledby="wifiDisclaimerTitle"><h3 id="wifiDisclaimerTitle">使用说明与免责声明</h3><p>本项目为个人开发的非官方工具，与 ASUS、Merlin 及原插件作者无隶属关系。提高功率可能增加温度、干扰或连接不稳定，也不保证覆盖和速率提升。请遵守所在地无线电规定，并根据散热和使用环境设置数值。校准上限与实际发射功率不同，实际输出受地区和驱动限制。应用或恢复发生变化的配置会重启路由器，请先保存正在进行的工作；备份仅用于恢复本机保存过的校准配置。</p></section>
<div class="miku-actions"><button type="button" onclick="wifiAction(1)">刷新状态</button><button type="button" class="secondary" onclick="wifiAction(2)">预览更改</button><button id="wifiApply" type="button" onclick="wifiAction(3)" disabled>应用并重启</button><button id="wifiRestore" type="button" class="secondary" onclick="wifiAction(4)" disabled>恢复备份并重启</button></div>
<div id="wifiMessage" class="miku-message" role="status" style="white-space:pre-line">正在读取…</div>
<p class="miku-caption">备份：<span id="backupStatus">读取中</span>。备份留在路由器本地，卸载后保留。</p>
<details><summary onclick="readLog()" style="cursor:pointer">查看操作日志</summary><pre id="wifiLog" style="white-space:pre-wrap;max-height:220px;overflow:auto">尚无日志</pre></details>
<p><a href="/Module_mikuui.asp">返回主题外观</a> · <a href="/Module_Softcenter.asp">返回软件中心</a></p>
</div></td></tr></table></td></tr></table></td></tr></table>
<div id="footer"></div>
</body></html>
