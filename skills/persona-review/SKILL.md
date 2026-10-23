---
name: persona-review
description: >
  Code review of a commit, a branch, a pull request or uncommitted changes through one
  or more personas: Chad (correctness, tests, types, linting, bugs), Clive (performance,
  concurrency, security, database), Jimmy (Clean Code, naming, code smells, refactoring)
  and Poindexter (architecture, design, SOLID, trade-offs), or a shallow sweep of all four.
  Use when the user asks for Chad's, Clive's, Jimmy's or Poindexter's review, a review
  of one of those concerns, a review from all reviewers ("review all"), or a code
  review of their change, a PR ("review PR 42") or a branch ("review the feature-x branch").
  Usage: /persona-review [personas or concerns] [commit-hash | PR number | branch [against base]]
---

A **persona review** looks at a change through one persona's lens, for a human reviewing their own code or someone else's. Each persona's criteria, voice and output format live in its own reference file, the single source of truth for that persona:

- **Chad**: [`references/chad.md`](references/chad.md)
- **Clive**: [`references/clive.md`](references/clive.md)
- **Jimmy**: [`references/jimmy.md`](references/jimmy.md)
- **Poindexter**: [`references/poindexter.md`](references/poindexter.md)

A **sweep** runs all four at reduced depth, to show which personas are worth running in full.

## 1. Resolve the target

Resolve the target to a **diff command** and a **revision**, the ref at which to read more of a file than the diff shows. Take the first that matches:

- **A commit hash**: diff `git show <hash>`; revision `<hash>`.
- **A PR or MR number** ("PR 42", "#42", "MR 42", "!42"): find the forge from the host of the `origin` URL in `git remote -v`.
  - GitHub (`github.com`), with `gh` installed and `gh auth status` passing: diff `gh pr diff <n>`. Fetch the head with `git fetch origin pull/<n>/head`; the revision is the SHA from `git rev-parse FETCH_HEAD`. The title from `gh pr view <n> --json title` may label the report heading.
  - GitLab (a host containing `gitlab`), with `glab` installed and `glab auth status` passing: diff `glab mr diff <n>`. Fetch the head with `git fetch origin merge-requests/<n>/head`; the revision as for GitHub. The title from `glab mr view <n>` may label the report heading.
  - Any other remote, or the forge's CLI missing or not signed in: ask the user for the PR's branch (and its base, if not the default branch), then resolve it as a branch below.

  The PR's description, linked issues and review threads are not input: the personas judge the code, and checking it against stated intent is a spec review's job.
- **A branch** ("the feature-x branch", optionally "against develop"):
  - Branch: refresh the remote copy with `git fetch origin +refs/heads/<branch>:refs/remotes/origin/<branch>` (the explicit refspec updates `origin/<branch>` even where the clone's configured refspecs would not). If that reports `couldn't find remote ref`, the branch is not on the remote: treat `origin/<branch>` as absent. Any other fetch failure (e.g. offline) carries on with the refs as they are, and the report heading says `origin` was not refreshed. Then, of `<branch>` and `origin/<branch>`, keep those that `git rev-parse --verify --quiet <ref>^{commit}` resolves:
    - Only one: review it. Both, at the same commit: review `<branch>`.
    - Both, at different commits: stop before any persona runs and ask the user which to review, stating how they differ from `git rev-list --left-right --count <branch>...origin/<branch>` (left: commits only the local copy has, so ahead; right: behind), e.g. "local `feature-x` is 3 behind and 1 ahead of `origin/feature-x`". Review the one chosen.
  - Base: the branch the user named, resolved the same way; otherwise the remote's default branch, `git symbolic-ref --short refs/remotes/origin/HEAD` (e.g. `origin/main`). If that ref is unset, take the name after `ref: refs/heads/` in `git ls-remote --symref origin HEAD` and use `origin/<name>`.
  - Diff `git diff <base>...<branch>` (three dots, so the comparison is against the merge-base), with `<branch>` and `<base>` the refs chosen; the revision is the chosen `<branch>`.
- **Nothing given**: diff `git diff --staged` and `git diff`; the revision is the working tree.

Every target leaves the working tree and current branch as they are: `git fetch` and read-only commands only, never a checkout, switch, stash or reset. Read files at the revision with `git show <revision>:<path>`, or from disk when the target is the uncommitted changes.

Done when the diff command and revision are fixed and the diff is non-empty. A ref or PR that doesn't resolve, or an empty diff, stops here with a message to the user, before any persona runs. Label the report heading with the target, naming the refs actually reviewed, e.g. `PR #42: <title>` or `origin/feature-x against origin/main`.

## 2. Route to personas

Take the first rule that matches:

1. **Personas named** ("Chad's review", "Clive and Jimmy"): run those.
2. **Concerns named**: run each persona that owns one. Several concerns can mean several personas.
   - Tests, types, linting, bugs, correctness → Chad
   - Performance, complexity, concurrency, security, database → Clive
   - Naming, code smells, refactoring, Clean Code → Jimmy
   - Design, architecture, SOLID, trade-offs → Poindexter
3. **Otherwise** (a bare "review this"): ask the user which personas to run, offering "all four (sweep)" first, then each persona with the concerns it owns from rule 2.

Whenever the set comes to all four ("review all", "all reviewers"), it is a sweep.

Done when the set of personas is fixed.

## 3. Run at the depth the set calls for

### One persona: full depth

Read that persona's reference file and review the diff in this context, as that persona, against every one of its criteria. Report in the persona's own output format.

### Two or three personas: full depth each

Where the agent can start sub-agents, start one per persona, in parallel, so each review has a context of its own; otherwise run them one after another in this context, each at full depth. Brief each sub-agent with the diff command and revision from step 1 and the absolute path of its reference file, telling it to read the file, review the diff as that persona against every criterion, read any more of a file only at the revision (leaving the working tree as it is), and return the report in the persona's output format.

Present each report under the persona's name, in the order Chad, Clive, Jimmy, Poindexter.

### All four: a sweep

A sweep is deliberately shallow: one context, a quick pass per persona, findings filtered hard. Depth comes from running a single persona afterwards, so the sweep's job is to point at where that depth is needed.

Read all four reference files. For each persona, take a pass over the diff in its voice and against its criteria, and give each finding a severity:

- **Critical**: must fix before merge
- **High**: should fix before merge
- **Medium**: address soon
- **Low**: nice to have

Then filter each persona's findings:

- every Critical and High finding, uncapped;
- at most 3 Medium findings, the most important;
- no Low findings, only a count of the Lows not shown.

Report in this layout:

1. **Executive summary**: what the change does and the overall assessment.
2. **One section per persona** (Chad, Clive, Jimmy, Poindexter): its filtered findings, each with severity, location (`path/to/file:line`) and a one-line fix; then "N Low findings not shown" (and "N more Medium" if the cap dropped any); then the persona's own verdict line from its output format.
3. **Priority list**: every reported finding, Critical first. A finding raised by several personas appears once, credited to each ("Chad, Clive").
4. **Final verdict**, one of:
   - ✅ **Approved**: all personas satisfied, ready to merge
   - ⚠️ **Approved with comments**: minor issues noted, acceptable to merge
   - 🔄 **Needs revision**: significant issues require changes
   - ❌ **Blocked**: critical issues must be addressed
5. **What's good**: the positives, across personas.
6. **Go deeper**: one line naming which personas are worth running in full and why (hidden findings, a dense area, a Critical that needs a closer look), or saying none are.
