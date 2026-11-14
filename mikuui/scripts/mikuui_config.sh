#!/bin/sh
. /koolshare/scripts/base.sh
case "${2:-}" in
1)
  if /koolshare/mikuui/scripts/mikuui-control.sh apply; then
    dbus set mikuui_enable=1
    dbus set mikuui_message='主题已应用，刷新网页即可查看。'
  else dbus set mikuui_message='应用失败，请恢复默认后重试，或检查是否有其他主题插件。'; fi
  ;;
2)
  if /koolshare/mikuui/scripts/mikuui-control.sh stop; then
    dbus set mikuui_enable=0
    dbus set mikuui_message='已恢复固件默认外观。'
  else dbus set mikuui_message='恢复未完成，请重试。'; fi
  ;;
3)
  dbus set "mikuui_runtime=$(/koolshare/mikuui/scripts/mikuui-control.sh status)"
  ;;
*) exit 2 ;;
esac
http_response "$1"
