# agent-setup

Shared tools for AI-assisted development workflows. Currently includes the **Team Knowledge** system — a living knowledge base for multi-contributor projects, optimized for LLM consumption.

## Team Knowledge

Maintains a `TEAM-KNOWLEDGE.md` file that tracks who built what, how domains connect, what changed when, and what conventions the team follows. LLM agents can query it naturally ("who owns the sidebar?") or update it explicitly.

### What's included

| Path | Purpose |
|------|---------|
| `skills/team-knowledge/SKILL.md` | Claude Code skill definition |
| `scripts/update-team-knowledge.sh` | Incremental update script |
| `hooks/post-checkout` | Git hook template for auto-updates |
| `templates/TEAM-KNOWLEDGE-TEMPLATE.md` | Starter template for new projects |

### Quick install

```bash
# 1. Install the skill
mkdir -p ~/.claude/skills/team-knowledge
cp skills/team-knowledge/SKILL.md ~/.claude/skills/team-knowledge/SKILL.md

# 2. Place the update script (choose one location)
# Option A: Next to your TEAM-KNOWLEDGE.md
cp scripts/update-team-knowledge.sh /path/to/project-root/
# Option B: Global install
mkdir -p ~/.claude/scripts
cp scripts/update-team-knowledge.sh ~/.claude/scripts/

# 3. Bootstrap knowledge file for a new project
cp templates/TEAM-KNOWLEDGE-TEMPLATE.md /path/to/project-root/TEAM-KNOWLEDGE.md
# Edit: replace {PROJECT_NAME} and {DATE}

# 4. (Optional) Install git hook for auto-updates on branch switch
cp hooks/post-checkout /path/to/repo/.git/hooks/post-checkout
chmod +x /path/to/repo/.git/hooks/post-checkout
```

### Configuration

The script auto-detects everything from the current working directory:
- **Repo** — from `git rev-parse --show-toplevel`
- **Branch** — first of `dev`, `main`, `master` found in remote refs
- **Knowledge file** — `../TEAM-KNOWLEDGE.md` or `./TEAM-KNOWLEDGE.md`

For custom setups, create `.team-knowledge.conf` in the repo root:

```bash
# .team-knowledge.conf
KNOWLEDGE_FILE="../TEAM-KNOWLEDGE.md"
BASE_BRANCH="dev"
PROJECT_NAME="my-project"
SCRIPT_PATH="../update-team-knowledge.sh"
```

Or use environment variables:

```bash
REPO_DIR=/path/to/repo KNOWLEDGE_FILE=/path/to/TEAM-KNOWLEDGE.md bash update-team-knowledge.sh
```

### Usage

#### Natural queries (implicit)

Just ask your AI assistant questions — the skill triggers automatically:

- "Who built the sidebar?"
- "What PRs touched the auth module?"
- "If I change the Task model, what breaks?"
- "What conventions does the team follow for API routes?"

#### Explicit commands

```
/team-knowledge update              # Incremental update from git history
/team-knowledge update --force      # Force full update
/team-knowledge update --dry-run    # Preview changes without updating
/team-knowledge init                # Bootstrap for a new project
/team-knowledge status              # Show last processed state
```

### How it works

1. **State tracking** — `.team-knowledge-state` records the last processed commit and PR number
2. **Change detection** — Compares current `origin/<base-branch>` HEAD against stored state
3. **Summary generation** — Builds a compact diff summary (commits, PRs, files, contributors)
4. **Agent update** — Calls `claude --print` with the summary to surgically edit TEAM-KNOWLEDGE.md
5. **State update** — On success, records the new state to skip next time

### Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (`claude` in PATH)
- Git
- Bash 4+

### Troubleshooting

| File | Purpose |
|------|---------|
| `/tmp/team-knowledge-update.log` | Full execution log |
| `/tmp/team-knowledge-summary.txt` | Last generated change summary |
| `.team-knowledge-state` | State file (delete to force full scan) |

## License

MIT
