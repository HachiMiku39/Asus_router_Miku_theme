#!/bin/sh
# Reversible web-only overlays. Never change NVRAM, radios, routes or firewall.
set -u
export PATH=/koolshare/bin:/bin:/sbin:/usr/bin:/usr/sbin
ROOT=/koolshare/mikuui
RUN=/tmp/mikuui-runtime
PUBLIC=/tmp/var/wwwext/mikuui
TARGETS='state.js Main_Login.asp error_page.htm message.htm blocking.asp updateSubnet.htm'
owned() { awk -v p="/www/$1" '$5==p && $4 ~ /^\/mikuui-runtime\/overlay\// {ok=1} END {exit !ok}' /proc/self/mountinfo; }
mounted() { awk -v p="/www/$1" '$5==p {ok=1} END {exit !ok}' /proc/self/mountinfo; }
restore() {
  result=0
  for name in $TARGETS; do
    if owned "$name"; then umount "/www/$name" || result=1; fi
  done
  [ "$result" = 0 ] || return 1
  rm -f "$RUN/active"
  # Keep cached-page asset URLs harmless while browsers refresh.
  if [ -d "$PUBLIC" ]; then
    for css in "$PUBLIC"/theme-*.css; do
      [ ! -f "$css" ] || printf '/* theme disabled */\n' > "$css"
    done
  fi
  dbus set mikuui_active=0 2>/dev/null || true
}
apply() {
  . "$ROOT/scripts/mikuui-platform.sh"
  miku_web_check || return 1
  [ -r "$ROOT/assets/theme.css" ] || return 1
  for name in $TARGETS; do
    if mounted "$name" && ! owned "$name"; then echo "Web resource is managed by another plugin: $name"; return 1; fi
  done
  restore || return 1
  mkdir -p "$RUN/overlay" "$PUBLIC" || return 1
  chmod 755 "$RUN" "$RUN/overlay" "$PUBLIC"
  cp "$ROOT/assets/"*.png "$ROOT/assets/theme.css" "$ROOT/assets/loader.js" "$PUBLIC/" || return 1
  cp "$ROOT/assets/theme.css" "$PUBLIC/theme-2.1.0.css" || return 1
  cp "$ROOT/assets/login_bg_title.png" "$PUBLIC/login-bg-2.1.0.png" || return 1
  chmod 644 "$PUBLIC/"*
  : > "$RUN/baseline.sha256"
  for name in $TARGETS; do
    [ -f "/www/$name" ] || continue
    sha256sum "/www/$name" >> "$RUN/baseline.sha256"
    if [ "$name" = state.js ]; then
      cp "/www/$name" "$RUN/overlay/$name" || return 1
      printf '\n' >> "$RUN/overlay/$name"
      cat "$ROOT/assets/loader.js" >> "$RUN/overlay/$name"
    elif [ "$name" = Main_Login.asp ]; then
      awk -v css="$ROOT/assets/login.css" '
        BEGIN {done=0}
        /<\/head>/ && !done {
          print "<!-- MIKUUI_STYLELOADER_V1: public inline login appearance -->"
          print "<style id=\"mikuui-login-style\">"
          while ((getline line < css) > 0) print line
          close(css)
          print "</style>"
          done=1
        }
        /<body / {sub(/<body /, "<body id=\"mikuui-login-page\" ")}
        {print}
      ' "/www/$name" > "$RUN/overlay/$name" || return 1
      grep -q MIKUUI_STYLELOADER_V1 "$RUN/overlay/$name" || return 1
    else
      awk 'BEGIN {done=0} /<\/head>/ && !done {print "<!-- MIKUUI_STYLELOADER_V1 --><script src=\"/user/mikuui/loader.js?v=2.1.0\"></script>";done=1} {print}' "/www/$name" > "$RUN/overlay/$name" || return 1
      grep -q MIKUUI_STYLELOADER_V1 "$RUN/overlay/$name" || continue
    fi
    chmod 644 "$RUN/overlay/$name"
    mount -o bind "$RUN/overlay/$name" "/www/$name" || { restore; return 1; }
  done
  owned state.js || { restore; return 1; }
  cp "$ROOT/scripts/mikuui-control.sh" "$RUN/control.sh"
  cp "$ROOT/scripts/mikuui-guard.sh" "$RUN/guard.sh"
  chmod 700 "$RUN/control.sh" "$RUN/guard.sh"
  printf '%s\n' "$(readlink -f "$ROOT")" > "$RUN/source"
  touch "$RUN/active"
  dbus set mikuui_active=1
  echo 'Theme applied'
}
case "${1:-}" in
apply)
  mkdir -p "$RUN"
  mkdir "$RUN/lock" 2>/dev/null || { echo 'Theme operation already in progress'; exit 1; }
  trap 'rmdir "$RUN/lock" 2>/dev/null' 0 1 2 15
  if apply; then
    if [ ! -s "$RUN/guard.pid" ] || ! kill -0 "$(cat "$RUN/guard.pid")" 2>/dev/null; then
      (trap '' 1; exec /bin/sh "$RUN/guard.sh") >/dev/null 2>&1 </dev/null & echo $! > "$RUN/guard.pid"
    fi
  else restore; dbus set mikuui_active=0; exit 1; fi
  ;;
stop) restore ;;
status) if owned state.js; then echo active; else echo default; fi ;;
*) echo 'Usage: apply|stop|status'; exit 2 ;;
esac
