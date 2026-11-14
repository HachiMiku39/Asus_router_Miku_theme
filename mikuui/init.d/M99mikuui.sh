#!/bin/sh
export PATH=/koolshare/bin:/bin:/sbin:/usr/bin:/usr/sbin
[ "$(dbus get mikuui_enable)" = 1 ] && /koolshare/mikuui/scripts/mikuui-control.sh apply
exit 0
