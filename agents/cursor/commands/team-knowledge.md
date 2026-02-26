---
description: >
  Team knowledge base — who built what, project history, cross-domain dependencies,
  architecture, coding conventions. Consult when asked about contributors, code ownership,
  PR history, architectural decisions, or impact of changes across domains.
---

# TEAM-KNOWLEDGE Task

## What is TEAM-KNOWLEDGE.md?

A comprehensive reference document optimized for LLM consumption. It exists because
multi-contributor projects need a single source of truth about:
- **Who built what** — domain ownership, contributor map
- **How things connect** — cross-domain dependencies, shared resources
- **What happened when** — timeline, PR history, project evolution
- **How to write code** — real conventions from the codebase
- **What breaks if I change X** — impact matrix

## Implicit Triggers (when to consult automatically)

When the user asks ANY of these types of questions, read the project's
TEAM-KNOWLEDGE.md and answer from it:

| User asks about... | Read section... |
|---------------------|-----------------|
| "Who built/wrote/created X?" | Domain Ownership Map |
| "Who owns X domain?" | Domain Ownership Map |
| "What PRs touched X?" | Timeline / Evolution |
| "When was X added/changed?" | Timeline / Evolution |
| "If I change X, what breaks?" | Cross-Domain Dependencies |
| "What are the shared resources?" | Cross-Domain Dependencies |
| "How is X structured?" | Architecture & Patterns |
| "What conventions does the team follow?" | Coding Conventions |
| "What's the data model for X?" | Data Model |
| "What stack/version does this use?" | Project Overview |
| "What happened in sprint/week X?" | Timeline / Evolution |
| "Which domains depend on X?" | Cross-Domain Dependencies |

### How to find the file

Look for TEAM-KNOWLEDGE.md in this order:
1. Check `.team-knowledge.conf` in the current repo root for a custom `KNOWLEDGE_FILE` path
2. Parent directory of the current repo (`../TEAM-KNOWLEDGE.md`)
3. Current repo root (`./TEAM-KNOWLEDGE.md`)

If the file doesn't exist, inform the user they can create one with
the `/team-knowledge init` command.

### How to answer

1. Read the TEAM-KNOWLEDGE.md file
2. Find the relevant section(s)
3. Answer the user's question using the data
4. If the data is stale or doesn't cover the question, say so and suggest running
   `/team-knowledge update` first

## Explicit Commands

### `/team-knowledge update [--force] [--dry-run]`

Run the update script to incorporate recent git changes into TEAM-KNOWLEDGE.md.

**Steps:**
1. Locate the update script (see Script Location below)
2. Run it with any flags the user passed:
   ```bash
   bash <script-path>/update-team-knowledge.sh [--force] [--dry-run]
   ```
3. Report results: whether changes were detected, what sections were updated, current state

### `/team-knowledge init`

Bootstrap a new TEAM-KNOWLEDGE.md for the current project:

1. Detect the repo root from cwd
2. Determine where to place the file (parent dir or repo root)
3. Copy the template or generate the standard 7-section structure
4. Replace `{PROJECT_NAME}` with the repo directory name
5. Replace `{DATE}` with today's date
6. Suggest running `/team-knowledge update --force` to populate it

### `/team-knowledge status`

Show current state: last commit processed, last PR, last update date.

## Script Location

The update script is searched in this order:
1. Path specified in `.team-knowledge.conf` (`SCRIPT_PATH` variable)
2. Same directory as the TEAM-KNOWLEDGE.md file
3. `~/.cursor/scripts/update-team-knowledge.sh` (Cursor global install)
4. `~/.claude/scripts/update-team-knowledge.sh` (Claude global install)

## Configuration File (.team-knowledge.conf)

Optional file in the repo root. Bash-sourceable key=value pairs:

```bash
# .team-knowledge.conf
KNOWLEDGE_FILE="../TEAM-KNOWLEDGE.md"
BASE_BRANCH="dev"
PROJECT_NAME="my-project"
AGENT_CLI="auto"    # auto | claude | cursor | codex | gemini | opencode
```

## Troubleshooting

- **Log:** `/tmp/team-knowledge-update.log`
- **Summary:** `/tmp/team-knowledge-summary.txt`
- **State:** `.team-knowledge-state` (next to TEAM-KNOWLEDGE.md)
- Delete state file to force full scan on next run
