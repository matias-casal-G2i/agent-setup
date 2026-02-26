#!/bin/bash
# ============================================================
# detect-agents.sh — Detect installed AI coding agent CLIs
# ============================================================
# Outputs bash-sourceable variables describing available agents.
#
# Usage:
#   eval "$(bash detect-agents.sh)"     # Source into current shell
#   bash detect-agents.sh               # Print variables
#   bash detect-agents.sh --json        # JSON output
#
# Output variables (per agent):
#   AGENT_<NAME>       — Full path to CLI binary
#   AGENT_<NAME>_CMD   — Headless invocation command (without the prompt)
#   AVAILABLE_AGENTS   — Space-separated list of detected agent names
#   DEFAULT_AGENT      — First agent in priority order
#
# Priority order: claude > codex > gemini > cursor > opencode
# (Cursor lower because its headless mode has documented stability issues)
# ============================================================

JSON_MODE=false
[ "${1:-}" = "--json" ] && JSON_MODE=true

DETECTED=""
VARS=""

# --- Detection in priority order ---

# Claude Code
_path=$(command -v claude 2>/dev/null || true)
if [ -n "$_path" ]; then
    VARS+="AGENT_CLAUDE=\"$_path\""$'\n'
    VARS+="AGENT_CLAUDE_CMD=\"env -u CLAUDECODE \\\"$_path\\\" -p --dangerously-skip-permissions\""$'\n'
    DETECTED="${DETECTED:+$DETECTED }claude"
fi

# Codex
_path=$(command -v codex 2>/dev/null || true)
if [ -n "$_path" ]; then
    VARS+="AGENT_CODEX=\"$_path\""$'\n'
    VARS+="AGENT_CODEX_CMD=\"\\\"$_path\\\" exec --full-auto\""$'\n'
    DETECTED="${DETECTED:+$DETECTED }codex"
fi

# Gemini CLI
_path=$(command -v gemini 2>/dev/null || true)
if [ -n "$_path" ]; then
    VARS+="AGENT_GEMINI=\"$_path\""$'\n'
    VARS+="AGENT_GEMINI_CMD=\"\\\"$_path\\\" -p --yolo\""$'\n'
    DETECTED="${DETECTED:+$DETECTED }gemini"
fi

# Cursor (headless CLI is 'agent' command)
_path=$(command -v agent 2>/dev/null || true)
if [ -n "$_path" ]; then
    VARS+="AGENT_CURSOR=\"$_path\""$'\n'
    VARS+="AGENT_CURSOR_CMD=\"timeout 1200 \\\"$_path\\\" -p --force\""$'\n'
    DETECTED="${DETECTED:+$DETECTED }cursor"
fi

# OpenCode
_path=$(command -v opencode 2>/dev/null || true)
if [ -n "$_path" ]; then
    VARS+="AGENT_OPENCODE=\"$_path\""$'\n'
    VARS+="AGENT_OPENCODE_CMD=\"\\\"$_path\\\"\""$'\n'
    DETECTED="${DETECTED:+$DETECTED }opencode"
fi

# --- Derive default agent (first in list) ---
DEFAULT="${DETECTED%% *}"

# --- Output ---
if [ "$JSON_MODE" = true ]; then
    echo "{"
    # Available list
    printf '  "available": ['
    first=true
    for name in $DETECTED; do
        [ "$first" = true ] || printf ','
        printf '"%s"' "$name"
        first=false
    done
    echo "],"
    echo "  \"default\": \"${DEFAULT:-none}\","
    echo "  \"agents\": {"
    first=true
    for name in $DETECTED; do
        upper=$(echo "$name" | tr '[:lower:]' '[:upper:]')
        path_val=$(echo "$VARS" | grep "^AGENT_${upper}=" | head -1 | cut -d'"' -f2)
        cmd_val=$(echo "$VARS" | grep "^AGENT_${upper}_CMD=" | head -1 | sed "s/^AGENT_${upper}_CMD=//" | tr -d '"')
        [ "$first" = true ] || echo ","
        printf '    "%s": {"path": "%s", "cmd": "%s"}' "$name" "$path_val" "$cmd_val"
        first=false
    done
    echo ""
    echo "  }"
    echo "}"
else
    # Bash-sourceable output
    [ -n "$VARS" ] && printf '%s' "$VARS"
    echo "AVAILABLE_AGENTS=\"$DETECTED\""
    echo "DEFAULT_AGENT=\"$DEFAULT\""
fi
