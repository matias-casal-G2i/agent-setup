# Team Knowledge Base

## Implicit: When to consult TEAM-KNOWLEDGE.md

When the user asks about **who built what**, **code ownership**, **PR history**,
**cross-domain dependencies**, **architectural decisions**, or **impact of changes**,
read the project's TEAM-KNOWLEDGE.md file and answer from it.

### How to find the file

Look for TEAM-KNOWLEDGE.md in this order:
1. Check `.team-knowledge.conf` in the repo root for a custom `KNOWLEDGE_FILE` path
2. Parent directory of the current repo (`../TEAM-KNOWLEDGE.md`)
3. Current repo root (`./TEAM-KNOWLEDGE.md`)

### Section guide

| Question type | Read section |
|---------------|-------------|
| "Who built/owns X?" | Domain Ownership Map |
| "What PRs touched X?" | Timeline / Evolution |
| "If I change X, what breaks?" | Cross-Domain Dependencies |
| "How is X structured?" | Architecture & Patterns |
| "What conventions?" | Coding Conventions |
| "What's the data model?" | Data Model |
| "What stack/version?" | Project Overview |

## Explicit: Update commands

To update the knowledge base with recent git changes:

```bash
bash update-team-knowledge.sh              # Incremental update
bash update-team-knowledge.sh --force      # Force full update
bash update-team-knowledge.sh --dry-run    # Preview without updating
```

The script auto-detects which AI agent CLI to use. Configure `AGENT_CLI` in
`.team-knowledge.conf` to override (options: auto, claude, cursor, codex, gemini, opencode).
