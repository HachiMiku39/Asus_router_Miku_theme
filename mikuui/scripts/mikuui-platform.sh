#!/bin/sh
# Shared capability discovery; no model-name whitelist or device writes.
miku_arch_from() {
 case "$1" in aarch64|arm64|armv8*) return 0;; esac
 case "$1" in arm*) ;; *) return 1;; esac
 printf '%s\n' "$2" | grep -Eiq 'CPU architecture[[:space:]]*:[[:space:]]*(8|9)([[:space:]]|$)|ARMv8|AArch64' && return 0
 # Some 32-bit kernels report v7 even on the ARMv8 Cortex-A53/A72 SoCs.
 printf '%s\n' "$3" | grep -Eq 'arm,(armv8|cortex-a53|cortex-a72)([^a-zA-Z0-9]|$)'
}
miku_armv8() {
 local cpu='' dt='' f
 [ ! -r /proc/cpuinfo ] || cpu="$(cat /proc/cpuinfo)"
 for f in /proc/device-tree/cpus/cpu@*/compatible;do
  [ ! -r "$f" ] || dt="$dt $(tr '\000' ' ' < "$f")"
 done
 miku_arch_from "$(uname -m)" "$cpu" "$dt"
}
miku_iface_valid() { printf '%s\n' "$1" | grep -Eq '^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,31}$'; }
miku_iface_present() { [ -d "/sys/class/net/$1" ]; }
miku_radios() {
 local unit iface band declared hint list
 list="$(nvram get wlnband_list)"
 for unit in 0 1 2 3 4 5 6 7;do
  iface="$(nvram get wl${unit}_ifname)"
  [ -n "$iface" ] || continue
  miku_iface_valid "$iface" || continue
  miku_iface_present "$iface" || continue
  band="$(nvram get wl${unit}_nband)"
  case "$band" in 1|2|4) ;; *) band=0;;esac
  declared="$(printf '%s\n' "$list" | awk -F '<' -v n="$unit" '{print $(n+1)}')"
  hint=0
  case "$declared" in 2g[0-9]) hint=2;;5g[0-9]) hint=1;;6g[0-9]) hint=4;;esac
  if [ "$hint" != 0 ];then
   if [ "$band" != 0 ] && [ "$band" != "$hint" ];then band=0;else band="$hint";fi
  fi
  printf '%s|%s|%s\n' "$unit" "$iface" "$band"
 done | awk -F '|' '!seen[$2]++'
}
miku_dual_mapping() {
 # A two-slider writer cannot safely represent multiple 5 GHz / 6 GHz radios.
 awk -F '|' '{n++;if($3==2){u24=$1;i24=$2;c24++}else if($3==1){u5=$1;i5=$2;c5++}}
 END{if(n!=2||c24!=1||c5!=1)exit 1;printf "%s %s %s %s\n",u24,i24,u5,i5}'
}
miku_web_check() {
 miku_armv8 || { echo '需要可识别的 ARMv8 设备；不支持本机架构。';return 1; }
 [ -r /www/state.js ] && [ -r /www/Main_Login.asp ] && [ -r /www/index_style.css ] || { echo '当前固件缺少所需的 Merlin 网页接口。';return 1; }
 grep -q 'show_menu' /www/state.js && grep -q '</head>' /www/Main_Login.asp || { echo '当前网页结构不符合已有 Merlin 适配。';return 1; }
}
