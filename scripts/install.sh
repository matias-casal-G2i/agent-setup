#!/bin/bash
# ============================================================
# install.sh — Install team-knowledge for detected AI coding agents
# ============================================================
# Detects installed agent CLIs and installs the appropriate
# skill/command definitions and update script.
#
# Usage:
#   bash install.sh                    # Interactive install
#   bash install.sh --agent claude     # Install for specific agent only
#   bash install.sh --global           # Install script globally
# ============================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

SPECIFIC_AGENT=""
GLOBAL_INSTALL=false

for arg in "$@"; do
    case "$arg" in
        --global) GLOBAL_INSTALL=true ;;
        --agent)  shift; SPECIFIC_AGENT="${1:-}" ;;
        --agent=*) SPECIFIC_AGENT="${arg#--agent=}" ;;
    esac
done

echo "=== Team Knowledge Installer ==="
echo ""

# --- Detect agents ---
eval "$("$SCRIPT_DIR/detect-agents.sh")"

if [ -z "${AVAILABLE_AGENTS:-}" ]; then
    echo "No AI coding agent CLIs detected."
    echo "Install one of: claude, cursor (agent CLI), codex, gemini, opencode"
    exit 1
fi

echo "Detected agents: $AVAILABLE_AGENTS"
echo "Default agent:   $DEFAULT_AGENT"
echo ""

# --- Determine which agents to install for ---
if [ -n "$SPECIFIC_AGENT" ]; then
    INSTALL_AGENTS="$SPECIFIC_AGENT"
else
    INSTALL_AGENTS="$AVAILABLE_AGENTS"
fi

# --- Install per-agent config ---
for agent in $INSTALL_AGENTS; do
    case "$agent" in
        claude)
            echo "[claude] Installing skill..."
            mkdir -p ~/.claude/skills/team-knowledge
            cp "$REPO_DIR/agents/claude/skills/team-knowledge/SKILL.md" \
               ~/.claude/skills/team-knowledge/SKILL.md
            echo "[claude] Skill installed at ~/.claude/skills/team-knowledge/SKILL.md"
            ;;
        cursor)
            echo "[cursor] Cursor commands are project-level, not global."
            echo "[cursor] To install in a project, copy:"
            echo "         cp $REPO_DIR/agents/cursor/commands/team-knowledge.md .cursor/commands/"
            ;;
        codex)
            echo "[codex] Codex uses AGENTS.md for instructions."
            echo "[codex] Append the fragment to your project's AGENTS.md:"
            echo "         cat $REPO_DIR/agents/codex/instructions-fragment.md >> AGENTS.md"
            ;;
        gemini)
            echo "[gemini] Gemini uses GEMINI.md for instructions."
            echo "[gemini] Append the fragment to your project's GEMINI.md:"
            echo "         cat $REPO_DIR/agents/gemini/instructions-fragment.md >> GEMINI.md"
            ;;
        opencode)
            echo "[opencode] OpenCode support is experimental."
            echo "[opencode] See: $REPO_DIR/agents/opencode/instructions-fragment.md"
            ;;
        *)
            echo "[warn] Unknown agent: $agent — skipping"
            ;;
    esac
    echo ""
done

# --- Install update script ---
if [ "$GLOBAL_INSTALL" = true ]; then
    # Find the first agent's scripts directory
    INSTALL_DIR=""
    for agent in $AVAILABLE_AGENTS; do
        case "$agent" in
            claude)   INSTALL_DIR="$HOME/.claude/scripts" ;;
            cursor)   INSTALL_DIR="$HOME/.cursor/scripts" ;;
            codex)    INSTALL_DIR="$HOME/.codex/scripts" ;;
            gemini)   INSTALL_DIR="$HOME/.gemini/scripts" ;;
            opencode) INSTALL_DIR="$HOME/.opencode/scripts" ;;
        esac
        [ -n "$INSTALL_DIR" ] && break
    done

    if [ -n "$INSTALL_DIR" ]; then
        echo "Installing scripts globally to $INSTALL_DIR/"
        mkdir -p "$INSTALL_DIR"
        cp "$REPO_DIR/scripts/update-team-knowledge.sh" "$INSTALL_DIR/"
        cp "$REPO_DIR/scripts/detect-agents.sh" "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/update-team-knowledge.sh" "$INSTALL_DIR/detect-agents.sh"
        echo "Scripts installed."
    fi
fi

echo ""
echo "=== Installation complete ==="
echo ""
echo "Next steps:"
echo "  1. Place update-team-knowledge.sh next to your TEAM-KNOWLEDGE.md"
echo "  2. (Optional) Create .team-knowledge.conf in your repo root"
echo "  3. Run: bash update-team-knowledge.sh --dry-run"
echo "  4. (Optional) Install git hook: cp $REPO_DIR/hooks/post-checkout .git/hooks/"
