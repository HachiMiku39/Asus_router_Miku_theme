#!/bin/sh
# RAM copy can restore the GUI even after external JFFS is removed.
RUN=/tmp/mikuui-runtime
while [ -f "$RUN/active" ]; do
  sleep 5
  [ -f "$RUN/active" ] || break
  expected="$(cat "$RUN/source" 2>/dev/null)"
  actual="$(readlink -f /koolshare/mikuui 2>/dev/null)"
  if [ ! -r /koolshare/mikuui/assets/theme.css ] || [ "$expected" != "$actual" ]; then
    /bin/sh "$RUN/control.sh" stop
    break
  fi
done
rm -f "$RUN/guard.pid"
