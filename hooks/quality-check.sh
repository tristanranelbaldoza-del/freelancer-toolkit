#!/usr/bin/env bash
# quality-check.sh — PostToolUse content-quality scan for Write/Edit tool calls.
set -uo pipefail

payload="$(cat)"

file_path="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print((data.get("tool_input") or {}).get("file_path", ""))
except Exception:
    pass
')"

if [[ -z "$file_path" ]]; then
  exit 0
fi

case "$file_path" in
  */node_modules/*|*/.git/*|*/dist/*|*/build/*|/tmp/*)
    exit 0 ;;
esac

if [[ -L "$file_path" ]]; then
  exit 0
fi

if [[ ! -f "$file_path" ]]; then
  exit 0
fi

file_path_lower="${file_path,,}"

warnings=()

if [[ ! -s "$file_path" ]]; then
  warnings+=("file is empty")
fi

if grep -nE ' +$' "$file_path" >/dev/null 2>&1; then
  count=$(grep -cE ' +$' "$file_path" 2>/dev/null || echo 0)
  warnings+=("$count line(s) with trailing whitespace")
fi

if grep -nE '\b(TODO|FIXME|XXX)\b' "$file_path" >/dev/null 2>&1; then
  count=$(grep -cE '\b(TODO|FIXME|XXX)\b' "$file_path" 2>/dev/null || echo 0)
  warnings+=("$count TODO/FIXME/XXX marker(s) present")
fi

if [[ "$file_path_lower" == *.md || "$file_path_lower" == *.markdown ]]; then
  fence_count=$(grep -cE '^```' "$file_path" 2>/dev/null || echo 0)
  if (( fence_count % 2 != 0 )); then
    warnings+=("markdown: unbalanced \`\`\` fences (count=$fence_count)")
  fi
fi

if [[ "$file_path_lower" == *.sh || "$file_path_lower" == *.bash ]]; then
  if ! bash -n "$file_path" 2>/dev/null; then
    warnings+=("shell: bash -n syntax check failed")
  fi
fi

if [[ "$file_path_lower" == *.json ]]; then
  if ! python3 -m json.tool "$file_path" >/dev/null 2>&1; then
    warnings+=("json: parse failed")
  fi
fi

if (( ${#warnings[@]} > 0 )); then
  echo "[quality-check] $file_path" >&2
  for w in "${warnings[@]}"; do
    echo "  ⚠ $w" >&2
  done
fi

exit 0
