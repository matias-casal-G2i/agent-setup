#!/bin/bash
# ============================================================
# update-team-knowledge.sh
# ============================================================
# Central script to incrementally update TEAM-KNOWLEDGE.md.
# Called by: git post-checkout hook (auto) or /team-knowledge skill (manual).
#
# Configuration (in priority order):
#   1. Environment variables
#   2. .team-knowledge.conf in repo root
#   3. Auto-detection from current working directory
#
# Environment variables:
#   KNOWLEDGE_FILE  — Path to TEAM-KNOWLEDGE.md
#   REPO_DIR        — Path to git repo
#   STATE_FILE      — Path to state file (default: next to KNOWLEDGE_FILE)
#   BASE_BRANCH     — Main branch name (default: auto-detect dev/main/master)
#   PROJECT_NAME    — Project name for logs (default: repo directory name)
#   AGENT_CLI       — Which agent CLI to use (default: auto-detect)
#                     Options: auto, claude, cursor, codex, gemini, opencode
#
# Usage:
#   bash update-team-knowledge.sh [--force] [--dry-run]
#
#   --force    Skip the "no changes" check, always run
#   --dry-run  Show summary but don't call the agent
# ============================================================

set -uo pipefail
# Note: -e intentionally omitted. Git commands return non-zero for valid cases
# (empty diff, no matches in grep). We handle errors explicitly.

SUMMARY_FILE="/tmp/team-knowledge-summary.txt"
LOG_FILE="/tmp/team-knowledge-update.log"

FORCE=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --force)   FORCE=true ;;
        --dry-run) DRY_RUN=true ;;
    esac
done

# --- Helpers ---
log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"; }
die() { log "ERROR: $*"; exit 1; }

# --- Auto-detect REPO_DIR ---
if [ -z "${REPO_DIR:-}" ]; then
    # Try to find repo root from cwd
    REPO_DIR=$(git rev-parse --show-toplevel 2>/dev/null || true)
    if [ -z "$REPO_DIR" ]; then
        die "Not inside a git repo and REPO_DIR not set. Run from inside a repo or set REPO_DIR."
    fi
fi

[ -d "$REPO_DIR/.git" ] || die "Repo not found at $REPO_DIR"

# --- Load config file if it exists ---
CONF_FILE="$REPO_DIR/.team-knowledge.conf"
if [ -f "$CONF_FILE" ]; then
    log "Loading config from $CONF_FILE"
    # shellcheck source=/dev/null
    source "$CONF_FILE"
fi

# --- Auto-detect remaining config ---

# PROJECT_NAME: default to repo directory name
PROJECT_NAME="${PROJECT_NAME:-$(basename "$REPO_DIR")}"

# KNOWLEDGE_FILE: search in parent dir first, then repo root
if [ -z "${KNOWLEDGE_FILE:-}" ]; then
    PARENT_DIR=$(dirname "$REPO_DIR")
    if [ -f "$PARENT_DIR/TEAM-KNOWLEDGE.md" ]; then
        KNOWLEDGE_FILE="$PARENT_DIR/TEAM-KNOWLEDGE.md"
    elif [ -f "$REPO_DIR/TEAM-KNOWLEDGE.md" ]; then
        KNOWLEDGE_FILE="$REPO_DIR/TEAM-KNOWLEDGE.md"
    else
        die "TEAM-KNOWLEDGE.md not found. Searched: $PARENT_DIR/ and $REPO_DIR/. Set KNOWLEDGE_FILE or run /team-knowledge init."
    fi
fi

[ -f "$KNOWLEDGE_FILE" ] || die "TEAM-KNOWLEDGE.md not found at $KNOWLEDGE_FILE"

# STATE_FILE: default to same directory as KNOWLEDGE_FILE
STATE_FILE="${STATE_FILE:-$(dirname "$KNOWLEDGE_FILE")/.team-knowledge-state}"

# BASE_BRANCH: auto-detect from remote refs
if [ -z "${BASE_BRANCH:-}" ]; then
    cd "$REPO_DIR"
    for candidate in dev main master; do
        if git rev-parse --verify "origin/$candidate" &>/dev/null; then
            BASE_BRANCH="$candidate"
            break
        fi
    done
    if [ -z "${BASE_BRANCH:-}" ]; then
        # Fallback: try local branches
        for candidate in dev main master; do
            if git rev-parse --verify "$candidate" &>/dev/null; then
                BASE_BRANCH="$candidate"
                break
            fi
        done
    fi
    BASE_BRANCH="${BASE_BRANCH:-main}"
fi

# --- Resolve agent CLI ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECT_SCRIPT="$SCRIPT_DIR/detect-agents.sh"

# Source agent detection
if [ -f "$DETECT_SCRIPT" ]; then
    eval "$("$DETECT_SCRIPT")"
else
    # Inline fallback: try each agent in priority order
    AVAILABLE_AGENTS=""
    DEFAULT_AGENT=""
    for _agent_name in claude codex gemini cursor opencode; do
        _cli_name="$_agent_name"
        [ "$_agent_name" = "cursor" ] && _cli_name="agent"
        if command -v "$_cli_name" &>/dev/null; then
            AVAILABLE_AGENTS="${AVAILABLE_AGENTS:+$AVAILABLE_AGENTS }$_agent_name"
            [ -z "$DEFAULT_AGENT" ] && DEFAULT_AGENT="$_agent_name"
        fi
    done
fi

resolve_agent() {
    local preference="${AGENT_CLI:-auto}"

    if [ "$preference" != "auto" ]; then
        # User explicitly chose an agent — verify it's available
        case "$preference" in
            claude)  command -v claude &>/dev/null || die "Requested agent 'claude' not found. Available: $AVAILABLE_AGENTS" ;;
            cursor)  command -v agent &>/dev/null  || die "Requested agent 'cursor' (agent CLI) not found. Available: $AVAILABLE_AGENTS" ;;
            codex)   command -v codex &>/dev/null  || die "Requested agent 'codex' not found. Available: $AVAILABLE_AGENTS" ;;
            gemini)  command -v gemini &>/dev/null || die "Requested agent 'gemini' not found. Available: $AVAILABLE_AGENTS" ;;
            opencode) command -v opencode &>/dev/null || die "Requested agent 'opencode' not found. Available: $AVAILABLE_AGENTS" ;;
            *)       die "Unknown agent: $preference. Options: auto, claude, cursor, codex, gemini, opencode" ;;
        esac
        RESOLVED_AGENT="$preference"
        return 0
    fi

    # Auto-detect: use first available in priority order
    if [ -n "${DEFAULT_AGENT:-}" ]; then
        RESOLVED_AGENT="$DEFAULT_AGENT"
        return 0
    fi

    die "No AI coding agent CLI found. Install one of: claude, cursor (agent CLI), codex, gemini, opencode"
}

resolve_agent

# --- Log resolved config ---
log "=== Configuration ==="
log "  PROJECT_NAME:   $PROJECT_NAME"
log "  REPO_DIR:       $REPO_DIR"
log "  KNOWLEDGE_FILE: $KNOWLEDGE_FILE"
log "  STATE_FILE:     $STATE_FILE"
log "  BASE_BRANCH:    $BASE_BRANCH"
log "  AGENT_CLI:      $RESOLVED_AGENT (available: $AVAILABLE_AGENTS)"

# --- Read state ---
LAST_COMMIT=""
LAST_PR=""
LAST_UPDATED=""

if [ -f "$STATE_FILE" ]; then
    # shellcheck source=/dev/null
    source "$STATE_FILE"
fi

# --- Gather current state ---
cd "$REPO_DIR"

# Fetch latest from remote (lightweight, only refs)
git fetch origin --quiet 2>/dev/null || true

# Use origin/BASE_BRANCH as source of truth (has merged PRs from all contributors)
# Falls back to local branch, then HEAD
if git rev-parse --verify "origin/$BASE_BRANCH" &>/dev/null; then
    CURRENT_COMMIT=$(git rev-parse "origin/$BASE_BRANCH")
elif git rev-parse --verify "$BASE_BRANCH" &>/dev/null; then
    CURRENT_COMMIT=$(git rev-parse "$BASE_BRANCH")
else
    CURRENT_COMMIT=$(git rev-parse HEAD)
fi

# Get latest PR number from merge commits
CURRENT_PR=$(git log --all --oneline --merges --format='%s' | grep -oE '#[0-9]+' | head -1 | tr -d '#' || true)
CURRENT_PR="${CURRENT_PR:-0}"

# --- Decide if update is needed ---
if [ "$FORCE" = false ]; then
    if [ "$LAST_COMMIT" = "$CURRENT_COMMIT" ] && [ "$LAST_PR" = "$CURRENT_PR" ]; then
        log "No changes since last update (commit: ${CURRENT_COMMIT:0:7}, PR: #$CURRENT_PR). Skipping."
        exit 0
    fi
fi

log "Changes detected. Last: ${LAST_COMMIT:0:7}/#${LAST_PR:-?} → Current: ${CURRENT_COMMIT:0:7}/#$CURRENT_PR"

# --- Build compact summary ---
{
    echo "=== TEAM KNOWLEDGE UPDATE SUMMARY ==="
    echo "Project: $PROJECT_NAME"
    echo "Period: ${LAST_UPDATED:-never} → $(date '+%Y-%m-%d')"
    echo "Repo: $REPO_DIR"
    echo ""

    # Determine the ref to log from
    LOG_REF="origin/$BASE_BRANCH"
    if ! git rev-parse --verify "$LOG_REF" &>/dev/null; then
        LOG_REF="$BASE_BRANCH"
        if ! git rev-parse --verify "$LOG_REF" &>/dev/null; then
            LOG_REF="HEAD"
        fi
    fi

    # New commits since last known state
    if [ -n "$LAST_COMMIT" ] && git cat-file -t "$LAST_COMMIT" &>/dev/null; then
        COMMIT_RANGE="${LAST_COMMIT}..${CURRENT_COMMIT}"

        NEW_COMMIT_COUNT=$(git log --oneline "$COMMIT_RANGE" 2>/dev/null | wc -l | tr -d ' ')
        echo "New commits: $NEW_COMMIT_COUNT"
        echo ""

        # Commit messages (one-liners, max 30)
        echo "--- COMMITS ---"
        git log --oneline "$COMMIT_RANGE" 2>/dev/null | head -30
        echo ""

        # PRs merged (extracted from merge commits)
        MERGED_PRS=$(git log --merges --format='%s' "$COMMIT_RANGE" 2>/dev/null | grep -oE 'Merge pull request #[0-9]+|#[0-9]+' | grep -oE '#[0-9]+' | sort -u || true)
        if [ -n "$MERGED_PRS" ]; then
            echo "--- PRs MERGED ---"
            echo "$MERGED_PRS"
            echo ""
        fi

        # Files changed (compact: directory-level summary)
        echo "--- FILES CHANGED (by directory) ---"
        git diff --name-only "$COMMIT_RANGE" 2>/dev/null \
            | sed 's|/[^/]*$||' \
            | sort | uniq -c | sort -rn \
            | head -20
        echo ""

        # Schema changes?
        if git diff --name-only "$COMMIT_RANGE" 2>/dev/null | grep -q "prisma/schema.prisma"; then
            echo "--- SCHEMA CHANGES DETECTED ---"
            git diff "$COMMIT_RANGE" -- prisma/schema.prisma 2>/dev/null \
                | grep '^[+-]' | grep -v '^[+-][+-][+-]' | head -30
            echo ""
        fi

        # New routers or major files
        NEW_FILES=$(git diff --name-only --diff-filter=A "$COMMIT_RANGE" 2>/dev/null | head -15)
        if [ -n "$NEW_FILES" ]; then
            echo "--- NEW FILES ---"
            echo "$NEW_FILES"
            echo ""
        fi

        # New contributors
        echo "--- CONTRIBUTORS IN PERIOD ---"
        git log --format='%an' "$COMMIT_RANGE" 2>/dev/null | sort | uniq -c | sort -rn
        echo ""
    else
        # No previous state — full scan (first run or state lost)
        echo "First run or state reset. Scanning last 20 commits on $LOG_REF."
        echo ""
        echo "--- RECENT COMMITS ---"
        git log "$LOG_REF" --oneline -20 2>/dev/null || git log --oneline -20
        echo ""
        echo "--- RECENT CONTRIBUTORS ---"
        git log "$LOG_REF" --format='%an' -50 2>/dev/null | sort | uniq -c | sort -rn
        echo ""
        echo "--- RECENT FILES ---"
        git log "$LOG_REF" --name-only --format="" -20 2>/dev/null | sort | uniq -c | sort -rn | head -20
        echo ""
    fi

    echo "=== END SUMMARY ==="
} > "$SUMMARY_FILE"

SUMMARY_SIZE=$(wc -c < "$SUMMARY_FILE" | tr -d ' ')
log "Summary generated: $SUMMARY_SIZE bytes"

# --- Dry run: show summary and exit ---
if [ "$DRY_RUN" = true ]; then
    log "DRY RUN — showing summary, not calling agent."
    cat "$SUMMARY_FILE"
    exit 0
fi

# --- Build the agent prompt ---
SUMMARY_CONTENT=$(cat "$SUMMARY_FILE")
KNOWLEDGE_BASENAME=$(basename "$KNOWLEDGE_FILE")

AGENT_PROMPT="You are updating a team knowledge base file used by LLMs assisting developers on a multi-contributor project.

FILE: $KNOWLEDGE_FILE

PURPOSE:
This file is a comprehensive reference document optimized for LLM consumption. It exists because
the $PROJECT_NAME project has multiple contributors working on parallel features across different
domains. Every LLM session assisting a contributor needs to quickly understand:
- Who built what, when, and how their work connects to others' work
- The data model and architectural decisions so changes don't break other domains
- Where changes in one domain could impact another's work (cross-domain dependencies)
- Real coding conventions extracted from the codebase (not theoretical guidelines)

STRUCTURE (7 sections — each serves a specific purpose):
1. Project Overview & Stack — Tech stack with exact versions, so LLMs generate compatible code
2. Data Model — Entity hierarchy, JSON columns, cascade rules, permission model.
   Critical for any DB-touching change.
3. Domain Ownership Map — Table of contributors, their domains, files, and PR counts.
   Tells the LLM 'ask this person' or 'check this person's code for patterns'.
4. Timeline / Evolution — Chronological phases and merged PRs. Shows how the codebase grew
   and what landed when, so LLMs understand the project's maturity per area.
5. Cross-Domain Dependencies — Impact matrix of shared resources. The most critical section
   for preventing merge conflicts and breaking changes across contributors.
6. Architecture & Patterns — Routers, component patterns, routing/URL structure,
   middleware, providers. Helps LLMs write code that fits the existing architecture.
7. Coding Conventions — Real patterns with real examples from the codebase. Not guidelines
   but actual conventions the team follows.

INSTRUCTIONS:
1. Read the current $KNOWLEDGE_BASENAME file FIRST
2. Use the Edit tool for surgical, targeted updates — do NOT rewrite the file
3. Only update sections where the change summary below shows actual, meaningful changes
4. If the summary shows no meaningful changes (just config tweaks, minor refactors), only
   update the 'Last updated' date
5. Keep the same structure, formatting, and tone — concise reference style, not narrative
6. When adding PRs to the timeline, include PR number, title, author, and which domain it affects
7. When updating Domain Ownership, reflect actual commit activity — don't inflate or deflate
8. When updating Cross-Domain Dependencies, think about what shared resources were touched
   and what other domains could be affected

CHANGE SUMMARY:
$SUMMARY_CONTENT

UPDATE THE 'Last updated' DATE TO: $(date '+%Y-%m-%d')"

# --- Call agent with multi-agent dispatch ---
call_agent() {
    local prompt="$1"

    case "$RESOLVED_AGENT" in
        claude)
            env -u CLAUDECODE claude -p --dangerously-skip-permissions "$prompt"
            ;;
        cursor)
            timeout 1200 agent -p --force --workspace "$REPO_DIR" "$prompt"
            ;;
        codex)
            cd "$REPO_DIR"
            codex exec --full-auto --cd "$REPO_DIR" "$prompt"
            ;;
        gemini)
            cd "$REPO_DIR"
            gemini -p --yolo "$prompt"
            ;;
        opencode)
            log "WARNING: OpenCode headless mode is experimental."
            cd "$REPO_DIR"
            opencode "$prompt"
            ;;
        *)
            die "Unknown agent: $RESOLVED_AGENT"
            ;;
    esac
}

log "Calling $RESOLVED_AGENT CLI to update TEAM-KNOWLEDGE.md..."

call_agent "$AGENT_PROMPT" >> "$LOG_FILE" 2>&1

AGENT_EXIT=$?

if [ $AGENT_EXIT -eq 0 ]; then
    log "Agent completed successfully."

    # --- Update state file ---
    cat > "$STATE_FILE" <<EOF
LAST_COMMIT="$CURRENT_COMMIT"
LAST_PR="$CURRENT_PR"
LAST_UPDATED="$(date '+%Y-%m-%d')"
EOF
    log "State file updated: commit=${CURRENT_COMMIT:0:7}, PR=#$CURRENT_PR"
else
    log "Agent failed (exit code: $AGENT_EXIT). State NOT updated — will retry next time."
fi

exit $AGENT_EXIT
