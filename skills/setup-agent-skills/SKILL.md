---
name: setup-agent-skills
description: "Configure this repo for the engineering skills: its issue tracker (GitHub, local markdown, or another tool), triage labels, and domain-doc layout. Run once per repo before to-spec, to-tickets, triage, spec-review or implement-issues, or to switch trackers."
compatibility: Coding agents only (uses disable-model-invocation; not for claude.ai or the Skills API).
disable-model-invocation: true
---

<!--
Adapted from https://github.com/mattpocock/skills/tree/5beb35b/skills/engineering/setup-matt-pocock-skills under the MIT License.
Original Copyright (c) 2026 Matt Pocock. See THIRD_PARTY_NOTICES.md for details.
-->

# Setup agent skills

Write the per-repo config the engineering skills read: where issues live, which label strings fill the triage roles, and where the domain docs live. Infer everything you can, confirm once, then write.

## 1. Infer

Read the repo's starting state:

- `git remote -v`: a GitHub remote means **GitHub**.
- `.scratch/` with feature folders means **local markdown** is already in use.
- `docs/agents/`: earlier output of this skill. Treat a re-run as an update: keep what the user wrote unless they are switching trackers.
- `AGENTS.md` and `CLAUDE.md` at the repo root, and any `## Agent skills` block in either.
- Whether `triage` is installed: a `triage` folder next to this skill's folder, or `triage` among your available skills. Labels are configured only when it is.
- On GitHub with `triage` installed: `gh label list --json name` shows labels that may already fill the triage roles under other names (e.g. `bug:triage` for `needs-triage`).
- The domain-doc layout. **Single-context** (one `GLOSSARY.md` and `docs/adr/` at the root) fits almost every repo. **Multi-context** (a root `GLOSSARY-MAP.md` pointing at one `GLOSSARY.md` per context) is a candidate only with monorepo signals: an existing `GLOSSARY-MAP.md` or `src/*/docs/adr/`, `pnpm-workspace.yaml`, a `workspaces` field in `package.json`, or a populated `packages/*`.

The trackers:

- **GitHub**: issues in the repo's GitHub Issues, via `gh`. Template: [issue-tracker-github.md](references/issue-tracker-github.md).
- **Local markdown**: issues as files under `.scratch/<feature>/`, for solo repos or repos without a remote. Template: [issue-tracker-local.md](references/issue-tracker-local.md).
- **Other** (Jira, Linear, …): the user describes the workflow in a paragraph, and you write `docs/agents/issue-tracker.md` from it, covering the same operations as the GitHub template.

## 2. Confirm once

Show the user, in one message:

- The tracker you inferred, and why.
- The label mapping: the five defaults from [triage-labels.md](references/triage-labels.md), with any existing labels you matched to a role. Omit this when `triage` isn't installed.
- The domain-doc layout, and the signals behind it when it is multi-context.
- The file you will edit: `AGENTS.md` if it exists, else `CLAUDE.md`. If neither exists, ask which to create. When `CLAUDE.md` only imports `AGENTS.md` (`@AGENTS.md`), edit `AGENTS.md`.
- The `## Agent skills` block from step 3.

Ask only where inference left a real choice: no remote and no `.scratch/`, a non-GitHub remote, or monorepo signals. Wait for a go-ahead or corrections.

## 3. Write

- `docs/agents/issue-tracker.md` from the tracker's template.
- `docs/agents/triage-labels.md` from its template with the confirmed label strings, when `triage` is installed.
- `docs/agents/domain.md` from [domain.md](references/domain.md). Keep only the confirmed layout's file tree.
- Drop each template's attribution comment.
- On GitHub, `gh label create` for each confirmed label the repo lacks.
- The `## Agent skills` block in the chosen file. Replace an existing block in place, and leave the rest of the file as it is:

```markdown
## Agent skills

### Issue tracker

[One line: where issues are tracked.] See `docs/agents/issue-tracker.md`.

### Triage labels

[One line: default labels, or which roles are renamed.] See `docs/agents/triage-labels.md`.

### Domain docs

[One line: single-context or multi-context.] See `docs/agents/domain.md`.
```

Include `### Triage labels` only when `triage-labels.md` was written. Leave `GLOSSARY.md` and ADRs uncreated: `domain-modeling` writes them when a term or decision is first settled.

You are done when every `docs/agents/` file above exists with the confirmed content, the block is in place, and on GitHub `gh label list` shows every configured label. Tell the user which files you wrote and that later changes can go straight into `docs/agents/*.md`.
