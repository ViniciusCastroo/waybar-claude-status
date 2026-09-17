#!/usr/bin/env bash
set -euo pipefail

cache_base="${XDG_CACHE_HOME:-$HOME/.cache}"
status_dir="$cache_base/ai-status.d"
legacy_file="$cache_base/ai-status"
now=$(date +%s)
ttl_busy=7200
ttl_done=15

busy=0
done=0
tools=()

add_status() {
  local raw="$1" state tool updated age ttl

  IFS=: read -r state tool updated _ <<< "$raw"
  [ -n "${tool:-}" ] || tool="ai"
  [ -n "${updated:-}" ] || updated="$now"

  case "$updated" in
    *[!0-9]*|"") updated="$now" ;;
  esac

  age=$((now - updated))
  [ "$state" = "busy" ] && ttl="$ttl_busy" || ttl="$ttl_done"
  [ "$age" -le "$ttl" ] || return 0

  case "$state" in
    busy) busy=$((busy + 1)) ;;
    done) done=$((done + 1)) ;;
    *) return 0 ;;
  esac

  tools+=("$tool")
}

if [ -d "$status_dir" ]; then
  while IFS= read -r -d '' file; do
    raw=$(head -n 1 "$file" 2>/dev/null || true)
    [ -n "$raw" ] && add_status "$raw"
  done < <(find "$status_dir" -type f -name '*.status' -print0 2>/dev/null)
fi

if [ "$busy" -eq 0 ] && [ "$done" -eq 0 ] && [ -f "$legacy_file" ]; then
  raw=$(head -n 1 "$legacy_file" 2>/dev/null || true)
  updated=$(stat -c %Y "$legacy_file" 2>/dev/null || printf "%s" "$now")
  [ -n "$raw" ] && add_status "$raw:$updated"
fi

label_for_tool() {
  case "$1" in
    claude) printf "Claude" ;;
    codex) printf "Codex" ;;
    *) printf "AI" ;;
  esac
}

primary_tool="${tools[0]:-ai}"
label=$(label_for_tool "$primary_tool")

slot="${1:-}"
if [ -n "$slot" ]; then
  case "$slot" in
    *[!0-9]*|"") slot=1 ;;
  esac

  if [ "$busy" -ge "$slot" ]; then
    text="."
    class="busy"
    tooltip="$label: $busy working"
  elif [ "$done" -ge "$slot" ] && [ "$busy" -eq 0 ]; then
    text="."
    class="done"
    tooltip="$label: done"
  elif [ "$slot" -eq 1 ] && [ "$busy" -eq 0 ]; then
    text="."
    class="idle"
    tooltip="AI: idle"
  else
    text=""
    class="hidden"
    tooltip=""
  fi

  printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tooltip"
  exit 0
fi

if [ "$busy" -gt 0 ]; then
  text="."
  class="busy"
  tooltip="$label: $busy working"
elif [ "$done" -gt 0 ]; then
  text="."
  class="done"
  tooltip="$label: done"
else
  text="."
  class="idle"
  tooltip="AI: idle"
fi

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tooltip"
