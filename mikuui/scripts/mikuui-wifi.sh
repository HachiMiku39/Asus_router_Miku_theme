#!/bin/sh
# Local-only calibration controller for RT-AX86U Pro. No license or payment code.
set -eu
umask 077
export PATH=/koolshare/bin:/bin:/sbin:/usr/bin:/usr/sbin
ROOT=/koolshare/mikuui
BACKUP=/jffs/mikuui-backups/wifi
KERNEL=/data/.kernel_nvram.setting
RUN=/tmp/mikuui-wifi
HELPER=/rom/etc/init.d/hndnvram.sh
mounted_here=0
say() { printf '%s\n' "$*"; }
fail() { say "错误：$*"; exit 1; }
valid_dbm() {
 printf '%s\n' "$1" | grep -Eq '^[0-9]+(\.[0-9]+)?$' || return 1
 awk -v n="$1" 'BEGIN {exit !(n>=5 && n<=28.5 && n*4==int(n*4))}'
}
validate() {
 [ "$#" = 4 ] || return 1
 case "$1:$3" in 0:1|1:0|1:1) ;; *) return 1;; esac
 valid_dbm "$2" && valid_dbm "$4"
}
# Pure validation entry is safe to run without a router, for packaging tests.
if [ "${1:-}" = validate ]; then shift; validate "$@"; exit; fi
model_check() { [ "$(nvram get productid)" = RT-AX86U_PRO ] || fail '当前版本只支持 RT-AX86U Pro'; }
identity() { { nvram get productid; cat /sys/class/net/br0/address; } | sha256sum | awk '{print $1}'; }
number() { printf '%s\n' "$1" | grep -Eq '^-?[0-9]+(\.[0-9]+)?$'; }
prefix_for() {
 local iface="$1" mac
 case "$iface" in eth[0-9]|eth[0-9][0-9]) ;; *) return 1;; esac
 [ -r "/sys/class/net/$iface/address" ] || return 1
 mac="$(cat "/sys/class/net/$iface/address")"
 awk -F= -v mac="$mac" 'tolower($2)==tolower(mac) && ($1~/^[0-5]:macaddr$/ || $1~/^sb\/[0-5]\/macaddr$/) {sub(/macaddr$/,"",$1);print $1;exit}' "$KERNEL"
}
load_radios() {
 [ -r "$KERNEL" ] || fail '无法读取当前无线校准信息'
 IF24="$(nvram get wl0_ifname)"; IF5="$(nvram get wl1_ifname)"
 [ "$(nvram get wl0_nband)" = 2 ] && [ "$(nvram get wl1_nband)" = 1 ] || fail '无线频段顺序不符合当前适配，已停止'
 P24="$(prefix_for "$IF24")"; P5="$(prefix_for "$IF5")"
 case "$P24:$P5" in *macaddr*) fail '无法识别无线校准前缀';; esac
 [ -n "$P24" ] && [ -n "$P5" ] && [ "$P24" != "$P5" ] || fail '无法唯一对应两个无线频段'
}
qvalue() {
 awk -F= -v p="$1" -v band="$2" '
 function dec(s, i,n,c){if(s!~/^0[xX]/)return s+0;n=0;for(i=3;i<=length(s);i++){c=index("0123456789abcdef",tolower(substr(s,i,1)))-1;if(c<0)return -1;n=n*16+c}return n}
 index($1,p)==1 && substr($1,length(p)+1)~("^maxp" band "[a-zA-Z0-9_]*$") {split($2,a,",");v=dec(a[1]);if(v>=0)printf "%.2f",(v-6)/4;exit}' "$KERNEL"
}
read_band() {
 local suffix="$1" iface="$2" prefix="$3" band="$4" raw temp power max
 temp=unknown;power=unknown;max="$(qvalue "$prefix" "$band")"
 if [ "$(wl -i "$iface" isup 2>/dev/null || true)" = 1 ]; then
  raw="$(wl -i "$iface" phy_tempsense 2>/dev/null | awk 'NR==1 {print $1}')"
  if number "$raw"; then temp="$(awk -v n="$raw" 'BEGIN {printf "%.1f",n/2+20}')"; fi
  raw="$(wl -i "$iface" txpwr_target_max 2>/dev/null | awk -F: 'NR==1 {n=split($3,a," ");for(i=1;i<=n;i++)if(a[i]~/^[0-9]+([.][0-9]+)?$/){print a[i];exit}}')"
  if number "$raw"; then power="$raw"; fi
 fi
 dbus set "mikuui_wifi_temp$suffix=$temp"
 dbus set "mikuui_wifi_power$suffix=$power"
 dbus set "mikuui_wifi_max$suffix=${max:-unknown}"
 dbus set "mikuui_wifi_iface$suffix=$iface"
}
status() {
 model_check;load_radios
 read_band 24 "$IF24" "$P24" 2g;read_band 5 "$IF5" "$P5" 5g
 dbus set "mikuui_wifi_region=$(nvram get location_code)"
 if [ -s "$BACKUP/nvram.nvm" ] && [ -s "$BACKUP/nvram.sha256" ]; then dbus set mikuui_wifi_backup=1;else dbus set mikuui_wifi_backup=0;fi
 dbus set mikuui_wifi_ready=1
}
find_profile() {
 PROFILE=''
 if [ -f /mnt/defaults/wl/nvram.nvm ];then PROFILE=/mnt/defaults/wl/nvram.nvm
 elif [ -f /tmp/mnt/nvram/nvram.nvm ];then PROFILE=/tmp/mnt/nvram/nvram.nvm;fi
}
mount_profile() {
 local access="${1:-read}" options target
 find_profile
 if [ "$access" = write ];then
  options=''
  if [ -n "$PROFILE" ];then
   target="$(dirname "$PROFILE")"
   [ "$(basename "$target")" != wl ] || target="$(dirname "$target")"
   target="$(readlink -f "$target")"
   options="$(awk -v p="$target" '$2==p {print $4;exit}' /proc/mounts)"
  fi
  case ",$options," in *,rw,*) ;; *)
   [ -x "$HELPER" ] || fail '缺少固件无线校准挂载工具'
   "$HELPER" mount_ubi || fail '固件校准分区无法切换为可写状态'
   mounted_here=1;find_profile
   ;;
  esac
 fi
 [ -n "$PROFILE" ] || fail '未找到可读取的校准文件；未写入配置'
 [ "$(wc -c < "$PROFILE")" -gt 100 ] || fail '校准文件大小异常'
 PROFILE_FORMAT="$("$ROOT/scripts/mikuui-wifi-format.sh" decode "$PROFILE" "$RUN/profile.txt")" || fail '校准格式或逐字节还原校验未通过，未写入配置'
}

cleanup() {
 if [ "$mounted_here" = 1 ];then sync;"$HELPER" umount_ubi >/dev/null 2>&1 || true;fi
 rm -f "$RUN/candidate.nvm" "$RUN/candidate.txt" "$RUN/profile.txt";rmdir "$RUN/lock" 2>/dev/null || true
}
backup_profile() {
 mkdir -p "$BACKUP";chmod 700 "$BACKUP"
 if [ -f "$BACKUP/nvram.nvm" ]; then
  [ "$(cat "$BACKUP/device.sha256")" = "$(identity)" ] || fail '备份不属于本机，已停止'
  (cd "$BACKUP" && sha256sum -c nvram.sha256) || fail '备份校验失败'
 else
  local source="$PROFILE" legacy
  legacy="$(dbus get mikuui_wifi_legacy_backup)"
  if printf '%s\n' "$legacy" | grep -Eq '^[0-9a-f]{32}$' && [ -f "$(dirname "$PROFILE")/$legacy" ] && [ "$(wc -c < "$(dirname "$PROFILE")/$legacy")" -gt 100 ];then source="$(dirname "$PROFILE")/$legacy";fi
  cp "$source" "$BACKUP/nvram.nvm"
  chmod 600 "$BACKUP/nvram.nvm";identity > "$BACKUP/device.sha256"
  (cd "$BACKUP" && sha256sum nvram.nvm > nvram.sha256)
  chmod 600 "$BACKUP/device.sha256" "$BACKUP/nvram.sha256"
 fi
}
preview() {
 validate "$@" || fail '请选择频段并输入 5–28.5 dBm、步进 0.25 的数值'
 model_check;load_radios
 say '预览模式：未写入校准分区，不会重启。'
 [ "$1" = 0 ] || say "2.4 GHz：$2 dBm；字段前缀 $P24"
 [ "$3" = 0 ] || say "5 GHz：$4 dBm；字段前缀 $P5"
}
commit_profile() {
 if cmp -s "$RUN/candidate.nvm" "$PROFILE";then say '当前设置与目标相同，无需重启。';return;fi
 local original_mode
 original_mode="$(stat -c '%a' "$PROFILE")"
 cp "$RUN/candidate.nvm" "$PROFILE.mikuui-new"
 chmod "$original_mode" "$PROFILE.mikuui-new"
 mv "$PROFILE.mikuui-new" "$PROFILE"
 sync
 say '设置已保存，5 秒后正常重启。'
 dbus set mikuui_wifi_message='设置已保存，路由器即将重启。'
 if [ "$mounted_here" = 1 ];then sync;"$HELPER" umount_ubi >/dev/null 2>&1 || fail '校准分区未能正常卸载，请手动检查后重启';mounted_here=0;fi
 sleep 5
 /sbin/reboot
}
case "${1:-}" in
status) status ;;
preview) shift;preview "$@" ;;
probe)
 model_check;load_radios;mkdir -p "$RUN";chmod 700 "$RUN";mkdir "$RUN/lock" || fail '另一项操作正在运行'
 trap cleanup 0 1 2 15
 mount_profile
 say 'PASS：无线频段、校准前缀和校准文件可读；未挂载或写入校准分区。'
 ;;
apply)
 shift;validate "$@" || fail '参数不合法';model_check;load_radios
 mkdir -p "$RUN";chmod 700 "$RUN";mkdir "$RUN/lock" || fail '另一项操作正在运行';trap cleanup 0 1 2 15
 mount_profile write;backup_profile
 q24="$(awk -v n="$2" 'BEGIN{printf "%d",n*4+6}')";q5="$(awk -v n="$4" 'BEGIN{printf "%d",n*4+6}')"
 awk -v on24="$1" -v on5="$3" -v prefix24="$P24" -v prefix5="$P5" -v q24="$q24" -v q5="$q5" -f "$ROOT/scripts/mikuui-wifi-patch.awk" "$RUN/profile.txt" > "$RUN/candidate.txt" || fail '字段格式不受支持，未写入'
 "$ROOT/scripts/mikuui-wifi-format.sh" encode "$PROFILE_FORMAT" "$RUN/candidate.txt" "$RUN/candidate.nvm" || fail '校准格式转换失败，未写入'
 commit_profile
 ;;
restore)
 model_check;load_radios;mkdir -p "$RUN";chmod 700 "$RUN";mkdir "$RUN/lock" || fail '另一项操作正在运行';trap cleanup 0 1 2 15
 [ -s "$BACKUP/nvram.nvm" ] || fail '尚无备份'
 [ "$(cat "$BACKUP/device.sha256")" = "$(identity)" ] || fail '备份不属于本机'
 (cd "$BACKUP" && sha256sum -c nvram.sha256) || fail '备份校验失败'
 mount_profile write;cp "$BACKUP/nvram.nvm" "$RUN/candidate.nvm";commit_profile
 ;;
*) fail '用法：status / preview / probe / apply / restore';;
esac
