#!/bin/sh
export PATH=/koolshare/bin:/bin:/sbin:/usr/bin:/usr/sbin
[ ! -f /tmp/mikuui-runtime/control.sh ] || /bin/sh /tmp/mikuui-runtime/control.sh stop || exit 1
/koolshare/mikuui/scripts/mikuui-legacy.sh restore || exit 1
rm -f /koolshare/init.d/M99mikuui.sh /koolshare/init.d/U00mikuui.sh /koolshare/init.d/S99mikuui.sh
rm -f /koolshare/webs/Module_mikuui.asp /koolshare/webs/Module_mikuui_wifi.asp /koolshare/res/icon-mikuui.png /koolshare/scripts/mikuui_config.sh /koolshare/scripts/mikuui_wifi_config.sh
rm -f /koolshare/res/mikuui-wifi-live.js /koolshare/res/mikuui-wifi-live-2.1.0.js
rm -rf /koolshare/mikuui /tmp/var/wwwext/mikuui /tmp/mikuui-runtime
dbus list mikuui_ | cut -d= -f1 | while IFS= read -r key;do
 case "$key" in mikuui_*) dbus remove "$key";;esac
done
for key in install name title description version home_url; do dbus remove "softcenter_module_mikuui_$key"; done
rm -f /koolshare/scripts/uninstall_mikuui.sh
