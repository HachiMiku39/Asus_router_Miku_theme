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
.miku-page-heading{display:flex;justify-content:space-between;align-items:center;gap:16px;flex-wrap:wrap}.miku-back{display:inline-block;padding:9px 16px;border:1px solid #39c5bb;border-radius:6px;color:#b6fff1!important;text-decoration:none!important;font-size:13px;white-space:nowrap}
</style>
<script>
function menu_hook(){tabtitle[tabtitle.length-1]=['','主题外观','Wi-Fi Boost'];tablink[tablink.length-1]=['','Module_mikuui.asp','Module_mikuui_wifi.asp'];}
function loadStatus(){
 $.ajax({url:'/_api/mikuui_',dataType:'json',cache:false,success:function(r){
  var s=r.result[0]||{},active=s.mikuui_active==='1';
  document.getElementById('themeStatus').textContent=active?'初音未来主题已应用':'当前使用固件默认外观';
  document.getElementById('themeDot').className='miku-dot'+(active?' on':'');
  document.getElementById('themeMessage').textContent=s.mikuui_message||'';
 },error:function(){document.getElementById('themeMessage').textContent='无法读取状态，请刷新页面或重新登录。';}});
}
function setTheme(action){
 $('button.theme-action').prop('disabled',true);
 document.getElementById('themeMessage').textContent=action===1?'正在应用主题…':'正在恢复默认外观…';
 $.ajax({url:'/_api/',type:'POST',dataType:'json',contentType:'application/json',timeout:30000,
  data:JSON.stringify({id:Math.floor(Math.random()*90000000)+1000000,method:'mikuui_config.sh',params:[action],fields:{}}),
  success:function(){window.location.reload();},error:function(){
   $('button.theme-action').prop('disabled',false);loadStatus();
   document.getElementById('themeMessage').textContent='操作结果待确认，请刷新页面查看当前状态。';
  }});
}
function init(){show_menu(menu_hook);loadStatus();}
</script></head>
<body onload="init();">
<div id="TopBanner"></div><div id="Loading" class="popup_bg"></div>
<table class="content" align="center" cellpadding="0" cellspacing="0"><tr>
<td width="17">&nbsp;</td><td valign="top" width="202"><div id="mainMenu"></div><div id="subMenu"></div></td>
<td valign="top"><div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0"><tr><td>
<table width="760" border="0" cellpadding="5" cellspacing="0" class="FormTitle" id="FormTitle"><tr><td bgcolor="#4D595D" valign="top">
<div style="padding:16px 12px">
<div class="miku-page-heading"><div class="formfonttitle">初音未来主题 + Wi-Fi Boost <span style="font-size:12px;font-weight:normal;opacity:.65">2.1.0</span></div><a class="miku-back" href="/Module_Softcenter.asp">← 返回软件中心</a></div>
<div class="miku-card"><img src="/res/icon-mikuui.png" alt="初音未来原包主题素材"><div class="miku-eyebrow">HATSUNE MIKU · MERLIN</div><h2>让初音绿，点亮后台。</h2><p>原包角色素材，搭配初音绿与粉红点缀。保留熟悉的 Merlin 布局，所有设置照常使用。</p><span class="miku-chip">#39C5BB</span><span class="miku-chip pink">Pink accent</span></div>
<div class="miku-status" role="status"><span id="themeDot" class="miku-dot"></span><span id="themeStatus">正在读取主题状态…</span></div>
<div class="miku-actions"><button type="button" class="theme-action" onclick="setTheme(1)">应用初音未来主题</button><button type="button" class="theme-action secondary" onclick="setTheme(2)">恢复默认外观</button></div>
<div id="themeMessage" class="miku-message" aria-live="polite"></div>
<table class="FormTable" width="100%" cellspacing="0" cellpadding="8" border="1"><thead><tr><td colspan="2">主题内容</td></tr></thead><tbody>
<tr><th>管理后台</th><td>初音主题页眉、薄荷绿菜单与按钮、深色表格和粉红细节。</td></tr>
<tr><th>登录与提示页面</th><td>完整联名标题、边框与署名；竖屏时原图显示在表单上方。</td></tr>
<tr><th>开机自动应用</th><td>应用后记住选择；恢复默认后停止自动应用。</td></tr>
<tr><th>恢复与卸载</th><td>可随时恢复固件默认外观，或从软件中心卸载。</td></tr>
</tbody></table>
<p class="miku-caption">应用后刷新网页即可查看。原包插画保留作者署名。<br>插画：Art by Hanasa © CFM；本插件为个人外观适配。</p>
<a href="/Module_mikuui_wifi.asp">打开 Wi-Fi Boost</a> · <a href="/Module_Softcenter.asp">返回软件中心</a>
</div></td></tr></table></td></tr></table></td></tr></table>
<div id="footer"></div>
</body></html>
