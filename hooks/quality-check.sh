#!/usr/bin/env bash
# quality-check.sh — PostToolUse content-quality scan for Write/Edit tool calls.
#
# Receives the tool-call payload as JSON on stdin (Claude Code hook contract).
# Reads the file_path, runs a handful of cheap sanity checks, and prints a
# concise warning summary to stderr. Never blocks (exits 0 even on findings).
#
# Checks performed:
#   1. File exists and is non-empty
#   2. No trailing whitespace on any line
#   3. No stray TODO / FIXME / XXX markers introduced
#   4. Markdown files: code-fences balanced (even count of ```)
#   5. Shell scripts: pass `bash -n` syntax check
#   6. JSON files: pass `python3 -m json.tool` parse

set -uo pipefail

# Read stdin into a variable (hook payload as JSON).
payload="$(cat)"

# Extract file_path using python3 (jq isn't guaranteed on macOS).
file_path="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print((data.get("tool_input") or {}).get("file_path", ""))
except Exception:
    pass
')"

# Nothing to check if we can't resolve a path.
if [[ -z "$file_path" ]]; then
  exit 0
fi

# Skip files outside the workspace or under common ignore paths.
case "$file_path" in
  */node_modules/*|*/.git/*|*/dist/*|*/build/*|/tmp/*)
    exit 0 ;;
esac

warnings=()

# 1. File exists and is non-empty.
if [[ ! -f "$file_path" ]]; then
  # The tool might have just deleted/moved — not our concern.
  exit 0
fi
if [[ ! -s "$file_path" ]]; then
  warnings+=("file is empty")
fi

# 2. Trailing whitespace.
if grep -nE ' +$' "$file_path" >/dev/null 2>&1; then
  count=$(grep -cE ' +$' "$file_path" 2>/dev/null || echo 0)
  warnings+=("$count line(s) with trailing whitespace")
fi

# 3. Stray TODO/FIXME/XXX markers.
if grep -nE '\b(TODO|FIXME|XXX)\b' "$file_path" >/dev/null 2>&1; then
  count=$(grep -cE '\b(TODO|FIXME|XXX)\b' "$file_path" 2>/dev/null || echo 0)
  warnings+=("$count TODO/FIXME/XXX marker(s) present")
fi

# 4. Markdown: balanced code fences.
if [[ "$file_path" == *.md || "$file_path" == *.markdown ]]; then
  fence_count=$(grep -cE '^```' "$file_path" 2>/dev/null || echo 0)
  if (( fence_count % 2 != 0 )); then
    warnings+=("markdown: unbalanced \`\`\` fences (count=$fence_count)")
  fi
fi

# 5. Shell scripts: syntax check.
if [[ "$file_path" == *.sh || "$file_path" == *.bash ]]; then
  if ! bash -n "$file_path" 2>/dev/null; then
    warnings+=("shell: bash -n syntax check failed")
  fi
fi

# 6. JSON: parse check.
if [[ "$file_path" == *.json ]]; then
  if ! python3 -m json.tool "$file_path" >/dev/null 2>&1; then
    warnings+=("json: parse failed")
  fi
fi

# Emit summary (stderr is shown to Claude/user via hook output).
if (( ${#warnings[@]} > 0 )); then
  echo "[quality-check] $file_path" >&2
  for w in "${warnings[@]}"; do
    echo "  ⚠ $w" >&2
  done
fi

exit 0
