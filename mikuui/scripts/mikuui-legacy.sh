#!/bin/sh
# Move only this legacy plugin's files. Never invoke its broad uninstall script.
set -eu
export PATH=/koolshare/bin:/bin:/sbin:/usr/bin:/usr/sbin
BACKUP=/jffs/mikuui-backups/legacy-wifiboost
FILES='bin/wifiboost bin/wifiboost.sh scripts/wifiboost_config.sh scripts/wifiboost_status.sh scripts/uninstall_wifiboost.sh webs/Module_wifiboost.asp res/icon-wifiboost.png'
KEYS='install name title description version home_url'
case "${1:-}" in
migrate)
 found=0
 for file in $FILES;do [ ! -f "/koolshare/$file" ] || found=1;done
 [ "$found" = 1 ] || exit 0
 umask 077;mkdir -p "$BACKUP/files" "$BACKUP/meta";chmod 700 "$BACKUP"
 key="$(dbus get wifiboost_key)"
 if [ -n "$key" ];then
  legacy="$(printf '%s\n' "$key" | md5sum | awk '{print $1}')"
  dbus set "mikuui_wifi_legacy_backup=$legacy"
 fi
 unset key
 dbus list softcenter_module_wifiboost_ | cut -d= -f1 | while IFS= read -r key;do
  suffix="${key#softcenter_module_wifiboost_}"
  if printf '%s\n' "$suffix" | grep -Eq '^[a-zA-Z0-9_]+$';then dbus get "$key" > "$BACKUP/meta/$suffix";fi
 done
 for file in $FILES;do
  if [ -f "/koolshare/$file" ];then mkdir -p "$BACKUP/files/$(dirname "$file")";cp -p "/koolshare/$file" "$BACKUP/files/$file";fi
 done
 # Keep the private rollback copy, then remove only known per-plugin files.
 for file in $FILES;do
  if [ -f "$BACKUP/files/$file" ] && [ -f "/koolshare/$file" ];then
   cmp -s "$BACKUP/files/$file" "/koolshare/$file" || exit 1
   rm -f "/koolshare/$file"
  fi
 done
 dbus list softcenter_module_wifiboost_ | cut -d= -f1 | while IFS= read -r key;do
  case "$key" in softcenter_module_wifiboost_*) dbus remove "$key";;esac
 done
 ;;
restore)
 [ -d "$BACKUP/files" ] || exit 0
 for file in $FILES;do
  if [ -f "$BACKUP/files/$file" ] && [ -f "/koolshare/$file" ];then
   cmp -s "$BACKUP/files/$file" "/koolshare/$file" || { echo 'Legacy plugin files were changed; refusing to overwrite.';exit 1; }
  fi
 done
 for file in $FILES;do
  if [ -f "$BACKUP/files/$file" ] && [ ! -f "/koolshare/$file" ];then
   mkdir -p "/koolshare/$(dirname "$file")";cp -p "$BACKUP/files/$file" "/koolshare/$file"
  fi
 done
 for file in "$BACKUP/meta/"*;do
  [ -f "$file" ] || continue
  k="$(basename "$file")"
  if printf '%s\n' "$k" | grep -Eq '^[a-zA-Z0-9_]+$';then v="$(cat "$file")";[ -z "$v" ] || dbus set "softcenter_module_wifiboost_$k=$v";fi
 done
 ;;
*) exit 2;;
esac
