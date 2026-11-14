#!/bin/sh
# Read-only radio telemetry. Counters stay in the response, never in flash/DBus.
set -eu
export PATH=/koolshare/bin:/bin:/sbin:/usr/bin:/usr/sbin
[ "$(nvram get productid)" = RT-AX86U_PRO ] || exit 1
[ "$(nvram get wl0_nband)" = 2 ] && [ "$(nvram get wl1_nband)" = 1 ] || exit 1
band() {
 unit="$1";iface="$(nvram get wl${unit}_ifname)"
 case "$iface" in eth[0-9]|eth[0-9][0-9]) ;; *) return 1;; esac
 if [ "$(wl -i "$iface" isup 2>/dev/null || true)" != 1 ];then
  printf '{"temp":null,"clients":null,"rx_bytes":null,"tx_bytes":null}';return
 fi
 temp="$(wl -i "$iface" phy_tempsense 2>/dev/null | awk 'NR==1&&$1~/^[0-9]+$/{printf "%.1f",$1/2+20}')"
 [ -n "$temp" ] || temp=null
 vifs="$(nvram get wl${unit}_vifs)"
 clients="$(
  { wl -i "$iface" assoclist 2>/dev/null || true
    for vif in $vifs;do
     case "$vif" in wl[01].[0-9]|wl[01].[0-9][0-9]) wl -i "$vif" assoclist 2>/dev/null || true;;esac
    done
  } | awk '$1=="assoclist"&&$2~/^[0-9a-fA-F:]+$/&&!seen[tolower($2)]++{n++} END{print n+0}'
 )"
 counters="$(wl -i "$iface" counters 2>/dev/null | awk '
 {for(i=1;i<NF;i++)if($(i+1)~/^[0-9]+$/){if($i=="rxbyte")rx=$(i+1);if($i=="txbyte")tx=$(i+1)}}
 END{printf "%s %s",rx==""?"null":rx,tx==""?"null":tx}')"
 set -- $counters
 printf '{"temp":%s,"clients":%s,"rx_bytes":%s,"tx_bytes":%s}' "$temp" "$clients" "${1:-null}" "${2:-null}"
}
printf '{"time":%s,"bands":{"24":' "$(awk '{print $1}' /proc/uptime)"
band 0
printf ',"5":'
band 1
printf '}}\n'
