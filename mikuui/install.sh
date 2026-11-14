#!/bin/sh
set -eu
export PATH=/koolshare/bin:/bin:/sbin:/usr/bin:/usr/sbin
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/scripts/mikuui-platform.sh"
miku_web_check || exit 1
[ -d /koolshare/webs ] && [ -r /koolshare/scripts/base.sh ] && type dbus >/dev/null 2>&1 || { echo '需要兼容的软件中心及 DBus。';exit 1; }
[ "$HERE" != /koolshare/mikuui ] || exit 1
[ ! -f /tmp/mikuui-runtime/control.sh ] || /bin/sh /tmp/mikuui-runtime/control.sh stop
mkdir -p /koolshare/mikuui/assets /koolshare/mikuui/scripts
cp "$HERE/assets/"* /koolshare/mikuui/assets/
cp "$HERE/scripts/mikuui-control.sh" "$HERE/scripts/mikuui-guard.sh" "$HERE/scripts/mikuui-wifi.sh" "$HERE/scripts/mikuui-wifi-live.sh" "$HERE/scripts/mikuui-wifi-format.sh" "$HERE/scripts/mikuui-wifi-patch.awk" "$HERE/scripts/mikuui-legacy.sh" /koolshare/mikuui/scripts/
cp "$HERE/scripts/mikuui-platform.sh" /koolshare/mikuui/scripts/
cp "$HERE/scripts/mikuui_config.sh" "$HERE/scripts/mikuui_wifi_config.sh" "$HERE/scripts/uninstall_mikuui.sh" /koolshare/scripts/
cp "$HERE/webs/"*.asp /koolshare/webs/
cp "$HERE/res/icon-mikuui.png" /koolshare/res/
cp "$HERE/res/mikuui-wifi-live.js" /koolshare/res/mikuui-wifi-live-2.1.0.js
cp "$HERE/init.d/"* /koolshare/init.d/
ln -sf /koolshare/init.d/M99mikuui.sh /koolshare/init.d/S99mikuui.sh
chmod 755 /koolshare/mikuui/scripts/*.sh /koolshare/scripts/mikuui_config.sh /koolshare/scripts/mikuui_wifi_config.sh /koolshare/scripts/uninstall_mikuui.sh /koolshare/init.d/M99mikuui.sh /koolshare/init.d/U00mikuui.sh
chmod 644 /koolshare/mikuui/assets/* /koolshare/webs/Module_mikuui.asp /koolshare/webs/Module_mikuui_wifi.asp /koolshare/res/icon-mikuui.png /koolshare/res/mikuui-wifi-live-2.1.0.js
dbus set softcenter_module_mikuui_install=1
dbus set softcenter_module_mikuui_name=mikuui
dbus set softcenter_module_mikuui_title='初音未来主题 + Wi-Fi Boost'
dbus set softcenter_module_mikuui_description='完整初音主题与本地 Wi-Fi 功率调节，一个模块，无需激活。'
dbus set softcenter_module_mikuui_version=2.1.0
dbus set softcenter_module_mikuui_home_url=Module_mikuui.asp
dbus set mikuui_version=2.1.0
[ -n "$(dbus get mikuui_enable)" ] || dbus set mikuui_enable=0
dbus set mikuui_active=0
dbus set mikuui_message='点击应用主题，即可换上初音未来主题。'
if [ "$(dbus get mikuui_enable)" = 1 ]; then /koolshare/mikuui/scripts/mikuui-control.sh apply; dbus set mikuui_message='主题已应用，刷新网页即可查看。'; fi
/koolshare/mikuui/scripts/mikuui-wifi.sh status >/dev/null 2>&1 || dbus set mikuui_wifi_ready=0
for band in 24 5;do
 [ -n "$(dbus get mikuui_wifi_on$band)" ] || dbus set "mikuui_wifi_on$band=1"
 if [ -z "$(dbus get mikuui_wifi_dbm$band)" ];then
  value="$(dbus get mikuui_wifi_max$band)"
  if ! /koolshare/mikuui/scripts/mikuui-wifi.sh validate 1 "$value" 0 20 >/dev/null 2>&1;then value=20;fi
  dbus set "mikuui_wifi_dbm$band=$value"
 fi
done
[ "$(dbus get mikuui_wifi_ready)" != 1 ] || /koolshare/mikuui/scripts/mikuui-legacy.sh migrate
echo '初音未来主题 + Wi-Fi Boost 2.1.0 安装完成；现有无线功率保持原值。'

