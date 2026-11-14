#!/bin/sh
# Read-only radio telemetry. Counters stay in the response, never in flash/DBus.
set -eu
export PATH=/koolshare/bin:/bin:/sbin:/usr/bin:/usr/sbin
. /koolshare/mikuui/scripts/mikuui-platform.sh
miku_armv8 || exit 1
band() {
 local unit="$1" iface="$2" temp vifs vif clients counters associations
 miku_iface_valid "$iface" || return 1
 if [ "$(wl -i "$iface" isup 2>/dev/null || true)" != 1 ];then
  printf '{"temp":null,"clients":null,"rx_bytes":null,"tx_bytes":null}';return
 fi
 temp="$(wl -i "$iface" phy_tempsense 2>/dev/null | awk 'NR==1&&$1~/^[0-9]+$/{printf "%.1f",$1/2+20}')"
 [ -n "$temp" ] || temp=null
 vifs="$(nvram get wl${unit}_vifs)"
 if associations="$(wl -i "$iface" assoclist 2>/dev/null)";then
 clients="$(
  { printf '%s\n' "$associations"
    for vif in $vifs;do
     if miku_iface_valid "$vif";then wl -i "$vif" assoclist 2>/dev/null || true;fi
    done
  } | awk '$1=="assoclist"&&$2~/^[0-9a-fA-F:]+$/&&!seen[tolower($2)]++{n++} END{print n+0}'
 )"
 else clients=null;fi
 counters="$(wl -i "$iface" counters 2>/dev/null | awk '
 {for(i=1;i<NF;i++)if($(i+1)~/^[0-9]+$/){if($i=="rxbyte")rx=$(i+1);if($i=="txbyte")tx=$(i+1)}}
 END{printf "%s %s",rx==""?"null":rx,tx==""?"null":tx}')"
 set -- $counters
 printf '{"temp":%s,"clients":%s,"rx_bytes":%s,"tx_bytes":%s}' "$temp" "$clients" "${1:-null}" "${2:-null}"
}
radios="$(miku_radios)"
[ -n "$radios" ] || exit 1
printf '{"time":%s,"radios":[' "$(awk '{print $1}' /proc/uptime)"
printf '%s\n' "$radios" | (
 first=1
 while IFS='|' read -r unit iface frequency;do
  [ "$first" = 1 ] || printf ',';first=0
  printf '{"unit":%s,"iface":"%s","frequency":%s,"data":' "$unit" "$iface" "$frequency"
  band "$unit" "$iface"
  printf '}'
 done
)
printf ']}\n'
