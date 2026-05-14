#!/usr/bin/env bash
# log-changes.sh — PostToolUse logger for Write/Edit tool calls.
#
# Appends one timestamped line per file Claude creates or edits to
# `changelog.txt` in the project root. Non-blocking (always exits 0).
#
# Line format:
#   <ISO-8601 timestamp> | <tool> | <file_path>
# Example:
#   2026-05-12T19:15:42Z | Write | /Users/me/proj/notes.md

set -uo pipefail

# Read stdin (hook payload as JSON).
payload="$(cat)"

# Extract tool_name and file_path with python3 (jq isn't guaranteed on macOS).
read -r tool_name file_path < <(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    tool = data.get("tool_name", "")
    fp = (data.get("tool_input") or {}).get("file_path", "")
    print(tool, fp)
except Exception:
    print("", "")
')

# Nothing to log if we can't resolve a tool or file path.
if [[ -z "${tool_name:-}" || -z "${file_path:-}" ]]; then
  exit 0
fi
if [[ -L "$file_path" ]]; then exit 0; fi

# Choose the changelog location:
#   1. $CLAUDE_PROJECT_DIR (set by Claude Code if available)
#   2. $PWD as fallback
project_dir="${CLAUDE_PROJECT_DIR:-$PWD}"
changelog="${project_dir%/}/changelog.txt"

# Timestamp in UTC, ISO-8601.
ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Append the entry (creates the file if missing).
printf '%s | %s | %s\n' "$ts" "$tool_name" "$file_path" >> "$changelog"

exit 0
