# agent-setup

AI agent skill for maintaining a **Team Knowledge Base** — a living document that gives any AI coding agent instant context about your project: who built what, how things connect, what conventions the team follows, and what breaks if you change X.

## What is this?

A single skill file (`SKILL.md`) that teaches any AI coding agent how to:

1. **Create** a `TEAM-KNOWLEDGE.md` file by analyzing your git history, codebase structure, and conventions
2. **Update** it incrementally as the project evolves
3. **Answer questions** about ownership, history, architecture, and dependencies by reading the file

No scripts, no CLI tools, no dependencies. The agent does everything directly.

## Install

Copy `SKILL.md` to your agent's skill/instruction directory:

**Claude Code:**
```bash
mkdir -p ~/.claude/skills/team-knowledge
cp SKILL.md ~/.claude/skills/team-knowledge/SKILL.md
```

**Cursor:** copy to `.cursor/commands/team-knowledge.md` in your project

**Codex:** append contents to your `AGENTS.md`

**Gemini CLI:** append contents to your `GEMINI.md`

**Any other agent:** include the contents in your system instructions or project rules

## Usage

### Natural queries (implicit)

Just ask your AI agent questions — it will read TEAM-KNOWLEDGE.md automatically:

- "Who built the sidebar?"
- "What PRs touched the auth module?"
- "If I change the Task model, what breaks?"
- "What conventions does the team follow?"

### Commands (explicit)

```
/team-knowledge              # Status: does the file exist? Is it current?
/team-knowledge create       # Build from scratch by analyzing the repo
/team-knowledge update       # Incremental update with recent changes
```

## What goes in TEAM-KNOWLEDGE.md?

Seven sections, each serving a specific purpose:

| Section | Purpose | LLM uses it to... |
|---------|---------|-------------------|
| Project Overview & Stack | Tech stack with exact versions | Generate compatible code |
| Data Model | Entity hierarchy, relationships, rules | Write correct queries |
| Domain Ownership Map | Who works on what (from git) | Know who to reference |
| Timeline & Evolution | Chronological PRs and phases | Understand project maturity |
| Cross-Domain Dependencies | Impact matrix of shared resources | Avoid breaking changes |
| Architecture & Patterns | How the codebase is organized | Write code that fits |
| Coding Conventions | Real patterns with real examples | Match the team's style |

## License

MIT
