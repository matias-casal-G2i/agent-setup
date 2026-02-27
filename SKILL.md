---
name: team-knowledge
description: >
  Team knowledge base — who built what, project history, cross-domain dependencies,
  architecture, coding conventions. Consult when asked about contributors, code ownership,
  PR history, architectural decisions, or impact of changes across domains.
  Create or update with /team-knowledge.
---

# TEAM-KNOWLEDGE

A single, comprehensive reference file (`TEAM-KNOWLEDGE.md`) optimized for LLM consumption.
It gives any AI agent working on the project instant context about:

- **Who built what** — domain ownership, contributor map
- **How things connect** — cross-domain dependencies, shared resources
- **What happened when** — timeline, PR history, project evolution
- **How to write code here** — real conventions extracted from the codebase
- **What breaks if I change X** — impact matrix

---

## Implicit Triggers

When the user asks ANY of these types of questions, find and read the project's
TEAM-KNOWLEDGE.md, then answer from it:

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

Search in this order:
1. Parent directory of the current repo (`../TEAM-KNOWLEDGE.md`)
2. Current repo root (`./TEAM-KNOWLEDGE.md`)
3. Ask the user where it is

If not found, offer to create it with `/team-knowledge create`.

### How to answer

1. Read the TEAM-KNOWLEDGE.md file
2. Find the relevant section(s)
3. Answer using the data
4. If the data is stale or doesn't cover the question, say so and suggest
   running `/team-knowledge update`

---

## Explicit Commands

### `/team-knowledge` (no args)

Show a brief status: whether the file exists, when it was last updated,
and suggest `create` or `update` as appropriate.

### `/team-knowledge create`

Create a new TEAM-KNOWLEDGE.md from scratch. See [Create Flow](#create-flow).

### `/team-knowledge update`

Incrementally update an existing TEAM-KNOWLEDGE.md. See [Update Flow](#update-flow).

---

## Before You Start: Gather Context

Before creating or updating, you need to know the answers to these questions.
Some can be inferred automatically, others may need to be asked.

### 1. Which repository?

- **If the user is working inside a git repo** → use that repo. No need to ask.
- **If the user mentions a specific repo** → use that one.
- **If ambiguous** → ask: "Which repository should I analyze?"

### 2. Where should the file live?

- **Default:** Parent directory of the repo (`../TEAM-KNOWLEDGE.md`).
  This is useful when there are multiple clones of the same repo in sibling
  directories — all clones share the same knowledge file.
- **Alternative:** Inside the repo root (`./TEAM-KNOWLEDGE.md`).
- **If the file already exists** → use its current location. Don't move it.
- **If creating new** → ask the user which location they prefer, explaining
  the trade-off (shared vs per-clone).

### 3. What branch is the source of truth?

- Run `git branch -r` and look for `origin/dev`, `origin/main`, or `origin/master`.
- If multiple candidates exist, prefer `dev` > `main` > `master`.
- If unclear → ask: "Which branch should I treat as the source of truth?"

### 4. Is this a multi-contributor project?

- Check `git shortlog -sn --all | head -20` to see contributors.
- If there's only 1 contributor, the Domain Ownership section will be simpler
  (but still useful for tracking which areas that person focused on).

---

## Create Flow

When creating a new TEAM-KNOWLEDGE.md from scratch:

### Step 1: Gather data from git

Run these commands (adapt to the shell available) and analyze the output:

```
# Branch to analyze
git fetch origin --quiet

# Contributors and their commit counts
git shortlog -sn --all

# Recent commit history (last 100)
git log origin/<branch> --oneline -100

# Merged PRs (from merge commit messages)
git log --all --merges --format='%s' | head -50

# Files and directories (structure overview)
find . -type f -not -path './.git/*' -not -path './node_modules/*' | head -200

# File change frequency (most active areas)
git log --all --name-only --format="" | sort | uniq -c | sort -rn | head -30

# Per-author file activity (who works where)
git log --all --format='%an' --name-only | head -500

# Schema or data model files
find . -name "schema.prisma" -o -name "*.schema.ts" -o -name "models" -type d 2>/dev/null

# Package/dependency info
cat package.json 2>/dev/null | head -50
cat requirements.txt 2>/dev/null | head -30
```

### Step 2: Analyze the codebase

Read key files to understand architecture:
- Entry points (index files, main files, app files)
- Router/API definitions
- Database schema
- Config files (tsconfig, next.config, vite.config, etc.)
- Existing documentation (README, CONTRIBUTING, etc.)

### Step 3: Write the file

Create the TEAM-KNOWLEDGE.md with this structure. Every section is mandatory,
but sections can be brief if there's limited data. Use the data you gathered —
don't invent or speculate.

```markdown
# {PROJECT_NAME} — Team Knowledge Base

> Reference document for LLMs assisting contributors on the {PROJECT_NAME} project.
> Covers architecture, data model, domain ownership, conventions, and cross-domain dependencies.
> Last updated: {DATE}

---

## Table of Contents

1. [Project Overview & Stack](#1-project-overview--stack)
2. [Data Model](#2-data-model)
3. [Domain Ownership Map](#3-domain-ownership-map)
4. [Timeline & Evolution](#4-timeline--evolution)
5. [Cross-Domain Dependencies](#5-cross-domain-dependencies)
6. [Architecture & Patterns](#6-architecture--patterns)
7. [Coding Conventions](#7-coding-conventions)

---

## 1. Project Overview & Stack

{Brief description of what the project does — 2-3 sentences.}

### Core Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| ... | ... | ... |

{Extract from package.json, requirements.txt, or equivalent.
Include exact versions — LLMs use these to generate compatible code.}

---

## 2. Data Model

{Entity hierarchy, relationships, key fields. Focus on what an LLM needs to
know to write correct queries/mutations. Include cascade rules, JSON columns,
permission model if applicable.}

---

## 3. Domain Ownership Map

{Who works on what. Based on git log analysis.}

| Contributor | Domain(s) | Key Files/Dirs | Approx PRs |
|------------|-----------|----------------|------------|
| ... | ... | ... | ... |

{Note: This is based on git history, not formal ownership.
"Domain" = area of the codebase they've committed to most.}

---

## 4. Timeline & Evolution

{Chronological phases of the project. Major PRs merged. When key features
were added. This helps LLMs understand which areas are mature vs new.}

### Recent PRs

| PR | Title | Author | Domain | Date |
|----|-------|--------|--------|------|
| ... | ... | ... | ... | ... |

---

## 5. Cross-Domain Dependencies

{The most critical section. What shared resources exist? If someone changes
module X, what else might break?}

### Shared Resources

| Resource | Used By | Impact If Changed |
|----------|---------|-------------------|
| ... | ... | ... |

---

## 6. Architecture & Patterns

{How the codebase is organized. API layer, routing, state management,
component patterns, middleware, providers. Include actual directory paths.}

---

## 7. Coding Conventions

{Real patterns from the codebase, not theoretical guidelines.
Include actual code snippets from the repo as examples. Cover naming,
file structure, error handling, testing patterns, imports.}
```

### Step 4: Confirm with the user

Before writing the file, show a brief summary of what you found:
- Project name and stack
- Number of contributors found
- Number of PRs/phases identified
- Key domains identified

Ask if anything looks wrong or missing before proceeding.

---

## Update Flow

When updating an existing TEAM-KNOWLEDGE.md:

### Step 1: Read the current file

Read the entire TEAM-KNOWLEDGE.md to understand its current state.
Note the "Last updated" date.

### Step 2: Find what changed since last update

```
# Get the date from "Last updated" in the file, then find commits since then
git log origin/<branch> --oneline --since="<last-updated-date>"

# Files changed since that date
git log origin/<branch> --name-only --format="" --since="<last-updated-date>" | sort | uniq -c | sort -rn | head -20

# PRs merged since that date
git log --all --merges --format='%s' --since="<last-updated-date>"

# Contributors active since that date
git log origin/<branch> --format='%an' --since="<last-updated-date>" | sort | uniq -c | sort -rn

# Schema changes since that date
git log origin/<branch> --format="" --name-only --since="<last-updated-date>" | grep -i "schema\|model\|migration" || true
```

### Step 3: Evaluate what needs updating

Based on the changes found:

| Change type | Action |
|-------------|--------|
| New PRs merged | Add to Timeline section |
| New contributor or existing contributor in new area | Update Domain Ownership |
| Schema/model changes | Update Data Model |
| New shared resources touched | Update Cross-Domain Dependencies |
| New files/directories/patterns | Update Architecture |
| Nothing meaningful (just minor fixes) | Only update the "Last updated" date |

### Step 4: Apply surgical edits

- Use the Edit tool for targeted updates — do NOT rewrite the entire file.
- Keep the same structure, formatting, and tone.
- When adding PRs to the timeline, include: PR number, title, author, domain.
- When updating Domain Ownership, reflect actual commit activity.
- Always update the "Last updated" date.

### Step 5: Report what changed

Tell the user:
- Which sections were updated and why
- How many new PRs/commits were incorporated
- If any new contributors or domains were found

---

## Edge Cases

### The repo has no remote

Use local branches instead of `origin/<branch>`. Skip `git fetch`.

### The repo has thousands of commits

Limit analysis to the last 200 commits or the last 6 months.
The knowledge file should reflect the current state, not full history.

### Single-contributor project

Still useful. The Domain Ownership becomes a "Focus Areas" map.
Cross-Domain Dependencies still matter for understanding impact.

### Monorepo with multiple packages

Create one TEAM-KNOWLEDGE.md for the entire monorepo, but organize
sections 3-6 by package/workspace.

### The user wants to track a repo they don't have locally

Ask them to clone it first, or provide the GitHub URL so you can
use `gh` CLI to gather data (if available).

### The file exists but is empty or malformed

Treat it as a create — rebuild from scratch using the template above.

---

## Style Guide

- **Concise reference style** — not narrative prose. Tables over paragraphs.
- **Real data only** — never invent contributors, PRs, or conventions.
- **Exact versions** — `React 19.2.3`, not `React 19`.
- **Actual code snippets** — for conventions, show real examples from the repo.
- **Paths are relative** — to the repo root.
- **Dates in ISO format** — `2026-02-27`.
