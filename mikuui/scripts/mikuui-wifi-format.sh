#!/bin/sh
# Lossless conversion of ASCII line or NUL-separated manufacturing profiles.
set -eu
umask 077
export LC_ALL=C
case "${1:-}" in
decode)
 [ "$#" = 3 ] || exit 2
 source_file="$2";text_file="$3"
 [ "$source_file" != "$text_file" ] || exit 2
 bytes="$(wc -c < "$source_file")"
 [ "$bytes" -gt 0 ] && [ "$bytes" -le 2097152 ] || exit 1
 without_nul="$(tr -d '\000' < "$source_file" | wc -c)"
 format=lines
 if [ "$bytes" != "$without_nul" ];then
  format=nul
  [ "$(tail -c 1 "$source_file" | hexdump -v -e '1/1 "%02x"')" = 00 ] || exit 1
  # Mixed separators could change record boundaries; reject them.
  [ "$(tr -d '\r\n' < "$source_file" | wc -c)" = "$bytes" ] || exit 1
  tr '\000' '\n' < "$source_file" > "$text_file"
 else
  [ "$(tail -c 1 "$source_file" | hexdump -v -e '1/1 "%02x"')" = 0a ] || exit 1
  cp "$source_file" "$text_file"
 fi
 [ "$(tr -cd '\t\n\r -~' < "$text_file" | wc -c)" = "$(wc -c < "$text_file")" ] || exit 1
 trap 'rm -f "$text_file.roundtrip"' 0 1 2 15
 if [ "$format" = nul ];then tr '\n' '\000' < "$text_file" > "$text_file.roundtrip";else cp "$text_file" "$text_file.roundtrip";fi
 cmp -s "$source_file" "$text_file.roundtrip" || exit 1
 printf '%s\n' "$format"
 ;;
encode)
 [ "$#" = 4 ] && [ "$3" != "$4" ] || exit 2
 case "$2" in
 nul) tr '\n' '\000' < "$3" > "$4" ;;
 lines) cp "$3" "$4" ;;
 *) exit 2 ;;
 esac
 ;;
*) exit 2 ;;
esac
