#!/bin/sh
. /koolshare/scripts/base.sh
CONTROL=/koolshare/mikuui/scripts/mikuui-wifi.sh
read_args() {
 A24="$(dbus get mikuui_wifi_on24)"; D24="$(dbus get mikuui_wifi_dbm24)"
 A5="$(dbus get mikuui_wifi_on5)"; D5="$(dbus get mikuui_wifi_dbm5)"
 "$CONTROL" validate "$A24" "$D24" "$A5" "$D5"
}
confirm_action() {
 c="$(dbus get mikuui_wifi_confirm)"; supplied="$(dbus get mikuui_wifi_confirm_token)"
 dbus remove mikuui_wifi_confirm;dbus remove mikuui_wifi_confirm_token
 [ "$c" = 1 ] && [ -r /tmp/mikuui-wifi/confirm ] || return 1
 read expected born < /tmp/mikuui-wifi/confirm
 rm -f /tmp/mikuui-wifi/confirm
 [ "$supplied" = "$expected" ] || return 1
 now="$(cut -d. -f1 /proc/uptime)";[ "$now" -ge "$born" ] && [ "$((now-born))" -le 600 ]
}

case "${2:-}" in
1)
 if ! "$CONTROL" status;then dbus set mikuui_wifi_ready=0;dbus set mikuui_wifi_message='当前固件或无线映射未通过兼容检查。';fi
 umask 077;mkdir -p /tmp/mikuui-wifi;chmod 700 /tmp/mikuui-wifi
 token="$(openssl rand -hex 16)"
 if ! printf '%s\n' "$token" | grep -Eq '^[0-9a-f]{32}$';then
  dbus remove mikuui_wifi_token;rm -f /tmp/mikuui-wifi/confirm
  dbus set mikuui_wifi_message='无法生成本次操作确认凭据，请稍后重试。';http_response "$1";exit 1
 fi
 printf '%s %s\n' "$token" "$(cut -d. -f1 /proc/uptime)" > /tmp/mikuui-wifi/confirm
 dbus set "mikuui_wifi_token=$token"
 http_response "$1"
 ;;
2)
 if read_args && msg="$("$CONTROL" preview "$A24" "$D24" "$A5" "$D5" 2>&1)";then dbus set "mikuui_wifi_message=$msg";else dbus set mikuui_wifi_message='请选择频段，并使用 5–28.5 dBm、步进 0.25 的数值。';fi
 http_response "$1"
 ;;
3|4)
 if ! confirm_action;then dbus set mikuui_wifi_message='请先确认本次修改会触发重启，再重新操作。';http_response "$1";exit 1;fi
 if [ "$2" = 3 ] && ! read_args;then dbus set mikuui_wifi_message='参数校验失败，未执行修改。';http_response "$1";exit 1;fi
 if [ -d /tmp/mikuui-wifi/lock ];then dbus set mikuui_wifi_message='另一项功率操作正在运行。';http_response "$1";exit 1;fi
 dbus set mikuui_wifi_message='正在检查本机备份与无线校准参数…'
 http_response "$1"
 if [ "$2" = 3 ];then
  "$CONTROL" apply "$A24" "$D24" "$A5" "$D5" > /tmp/upload/mikuui_wifi.log 2>&1
 else
  "$CONTROL" restore > /tmp/upload/mikuui_wifi.log 2>&1
 fi
 result=$?
 if [ "$result" != 0 ];then dbus set mikuui_wifi_message='操作停止，未完成应用；请查看操作日志。';else dbus set mikuui_wifi_message='操作完成。若数值相同则无需重启。';fi
 ;;
5)
 if [ -f /tmp/upload/mikuui_wifi.log ];then http_response "$(tail -c 8192 /tmp/upload/mikuui_wifi.log | openssl base64 -A)";else http_response "$(printf '%s' '尚无操作日志。' | openssl base64 -A)";fi
 ;;
6)
 if ! sample="$(/koolshare/mikuui/scripts/mikuui-wifi-live.sh)";then sample='{"error":"telemetry_unavailable"}';fi
 # Software-center wraps this value in JSON without escaping embedded quotes.
 http_response "$(printf '%s' "$sample" | openssl base64 -A)"
 ;;
*) exit 2 ;;
esac
