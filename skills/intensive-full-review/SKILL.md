---
name: intensive-full-review
description: Review a whole codebase across many dimensions (correctness, complexity, smells, architecture, idiom and more), verify each finding, and open one issue per finding on the project's issue tracker.
compatibility: Coding agents only (uses disable-model-invocation; not for claude.ai or the Skills API).
disable-model-invocation: true
---

# Intensive full review

A full audit of the codebase as it stands at `HEAD`, not a diff. Every **finding** becomes an issue, so the bar is a public bug report: each one is a single **root cause**, backed by evidence a stranger can check, and survives an attempt to refute it.

The user may pass a scope (a path, a subsystem) or a subset of dimensions. Without one, the scope is the whole repo and every dimension in [`dimensions.md`](references/dimensions.md) runs.

## Process

### 1. Load the project's rules

Read, where they exist:

- `docs/agents/issue-tracker.md` and `docs/agents/triage-labels.md`: how to file an issue and which label string means `needs-triage`. If they are missing, infer the tracker from `git remote -v` (GitHub → `gh`, GitLab → `glab`) and tell the user `/setup-agent-skills` would pin it down; if there is no remote, ask where issues go.
- `CLAUDE.md` / `AGENTS.md`, `CONTRIBUTING.md`, any coding-standards doc, the linter and formatter configs: the **house rules**. A house rule overrides any general heuristic in `references/dimensions.md`.
- `GLOSSARY.md` and `docs/adr/`: the domain language findings must use, and decisions a finding must not re-litigate. Contradict an ADR only when the friction is real enough to reopen it, and say so in the issue.
- `.out-of-scope/*.md`, if present: prior rejections.

Then snapshot the existing issues, open and closed (`gh issue list --state all --limit 500 --json number,title,state,labels`), so step 5 can drop duplicates.

Done when you can state the filing command, the label string, and the house rules in a few lines each.

### 2. Map the codebase

Pin the commit: `git rev-parse HEAD`. Every finding cites this SHA, so evidence links stay valid as the code moves.

Build a map: languages and frameworks with versions (from the manifest and lockfile), top-level modules and what each owns, entry points, test layout, and the commands that build, lint, type-check and test. Run those commands once and keep the output: a failing check or a warning is evidence the sub-agents can use.

Split the scope into **slices** of roughly 5–15k lines along module boundaries, so each sub-agent can read its slice in full rather than skim.

Done when every source file in scope belongs to exactly one slice.

### 3. Review in parallel sub-agents

Dispatch one sub-agent per dimension per slice, in parallel. A dimension that is cross-cutting by nature (architecture, consistency, dependencies) gets the whole scope and the map instead of a slice. Each brief carries:

- The pinned SHA, the slice's file list, and the map from step 2.
- That dimension's section of `references/dimensions.md`, pasted in full (the sub-agent has no other access to it).
- The house rules and relevant ADRs from step 1.
- The brief: "Read every file in your slice. Report every finding in this dimension as: **title** (imperative, under 70 chars); **severity** (critical / high / medium / low, per the rubric); **locations** (`path:line` for each, all occurrences of the same root cause in one finding); **evidence** (the quoted code, and for correctness a concrete input or sequence that triggers the fault); **why it matters**; **suggested direction** (the behaviour to reach, not a patch). Report nothing you have not read in the source. A house rule overrides the dimension's heuristics. Return an empty list if the slice is clean."

Done when every dimension × slice pair has reported.

### 4. Verify

Each finding is a claim, so a **verifier** sub-agent tries to refute it before it can be filed. Batch findings by slice; each verifier gets the findings, the SHA and the house rules, and the brief: "For each finding, read the cited code and its callers and tests. Mark it CONFIRMED only if the evidence holds and nothing elsewhere (a guard upstream, a test, a house rule, an ADR, a framework guarantee) defeats it. Otherwise mark it REFUTED with the reason. For correctness, run the triggering input where you can."

Keep only CONFIRMED findings.

### 5. Consolidate

- **Merge** findings that share a root cause across slices or dimensions: one issue, every location listed.
- **Group** repeats of the same low-severity pattern (one smell in twelve files) into one finding.
- **Drop** a finding that an existing issue, an `.out-of-scope` entry or an ADR already covers. Where an open issue covers it only in part, note the issue number to cross-link instead.
- **Rank** by severity, then by blast radius.

Done when no two remaining findings would be fixed by the same change.

### 6. Approve

Present the findings to the user as a numbered table: severity, dimension, title, locations (count), plus the dropped duplicates and their matching issues. Wait for the user to say which to file; they may cut, merge or reword. Filing publishes, so nothing goes to the tracker before this answer.

### 7. File

Open one issue per approved finding, through the tracker's create command, with the `needs-triage` label string from step 1 plus `bug` or `enhancement` where those labels exist (`gh label list`). Create no new labels.

Issue body:

```markdown
> *This was generated by AI during a codebase review.*

**Dimension:** <dimension> · **Severity:** <severity> · **Reviewed at:** <short SHA>

## Problem

<What is wrong and why it matters, in the domain language of GLOSSARY.md.>

## Evidence

- <permalink to the line range at the pinned SHA>, with the quoted code
- <for correctness: the triggering input and the observed vs expected result>

## Suggested direction

<The behaviour or shape to reach, not a patch. Note any ADR it touches.>

## Acceptance criteria

- [ ] <independently checkable condition>
```

Permalinks take the form `https://github.com/<owner>/<repo>/blob/<sha>/<path>#L<a>-L<b>`; on another tracker, use `path:line @ <sha>`.

Done when every approved finding has an issue number.

### 8. Report

List the filed issues as `#<n> <title>` grouped by severity, then the counts per dimension: raised, refuted, merged, dropped as duplicate, filed.
