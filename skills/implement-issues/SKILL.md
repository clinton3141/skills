---
name: implement-issues
description: "Implement several issues in parallel: one subagent per issue, or per group of issues sharing files, each running /implement on its own branch and opening a PR; then land them on request."
compatibility: Coding agents only (uses disable-model-invocation; not for claude.ai or the Skills API).
disable-model-invocation: true
---

You are the **orchestrator**. Each issue goes to one **worker** subagent, which implements it on its own branch in its own worktree and opens a pull request. You write no feature code yourself: you plan, dispatch, verify, and report.

The issue tracker workflow is in `docs/agents/issue-tracker.md`; read it before step 1.

## 1. Resolve the issues

The user's description may be issue numbers, a label, a milestone, a map issue whose children are the work, or prose naming the work. Turn it into a list of issues and fetch each one in full (body, comments, labels, blockers).

Comments carry triage decisions that override the body; every decision found there goes into the brief.

Done when every piece of work the user named maps to a fetched issue. Work with no issue behind it is a gap: stop and ask the user whether to file one, rather than handing a worker a spec you invented.

## 2. Plan

First **group**: issues that edit the same files go to one worker, in a fixed order, one commit per issue. Parallel workers on overlapping files produce add/add and rebase conflicts. An issue that builds on another group's code waits for that group's PR to merge (a later **wave**), rather than running beside it.

For each worker, fix:

- **Branch**: `<type>/<number>-<slug>`, where `<type>` follows the repo's existing branches (`git branch -a`), e.g. `fix/114-how-to-play-daily-note`. A group takes its first issue's number or a slug naming the group.
- **Base**: the default branch, unless the issue is blocked by another issue in this batch. Then its base is the blocker's branch, the PR stacks on the blocker's PR, and the worker is dispatched only once the blocker's PR exists. An issue blocked by one outside the batch that is still open is left out and reported.

Check what parallel worktrees share: a test or dev server on a fixed port (look for `reuseExistingServer` or a hard-coded port in the e2e config), and the toolchain version pinned in `.nvmrc` / `.tool-versions` / `engines` against the shell's default. Each worker's brief says how to get its own port and the right version.

Show the user the plan as a table (wave, issues, branch, base, blocked by) and wait for a go-ahead: each worker will push and open a PR.

## 3. Dispatch

Spawn every unblocked worker in one message, each with the Agent tool, `isolation: "worktree"`, running in the background. Each worker starts cold, so its prompt carries everything it needs; fill in this brief. `<skills dir>` is the absolute path of the folder holding this skill's folder: the sibling skills live there, whichever installer put them in place.

> You are implementing issue #<number> in `<repo path>`, alone, in your own worktree. Other workers are implementing other issues in parallel; touch only what this issue needs, and note anything out of scope in the PR body instead of fixing it. The other workers share your temp and scratchpad directories, so write any scratch file (the PR body included) inside your worktree or under a name containing `<number>`, never at a fixed shared path.
>
> <the issue's full body and comments, pasted; for a group, each issue in order>
>
> <decisions the user made in planning; what has merged since the issue was written that moves or renames code it cites; the port and toolchain setup from step 2>
>
> For a group, make one commit per issue, each ending `Closes #<number>`.
>
> 1. Create your branch: `git fetch origin && git switch -c <branch> origin/<base>`.
> 2. Read `<skills dir>/implement/SKILL.md` and follow it for this issue. Each skill it names lives at `<skills dir>/<name>/SKILL.md`; read that file and follow it. For the code review, run both axes (Standards, then Spec) yourself, one after the other, against the fixed point `origin/<base>`.
> 3. You are done when: every item in the issue's acceptance criteria is met; the repo's definition of done passes (find it from `CLAUDE.md` / `AGENTS.md` and the docs they point to), run and seen passing, not assumed; and every review finding is fixed or answered in the PR body.
> 4. Push (`git push -u origin <branch>`) and open the PR with `gh pr create --base <base> --head <branch>`. Match the repo's recent PR titles and bodies (`gh pr list --state merged --limit 5 --json title,body`); the body opens with `Closes #<number>.` (one line per issue for a group)
> 5. If the issue is ambiguous in a way only a human can settle, stop before step 4 and report the question instead.
>
> Reply with: the PR URL (or the blocking question), the checks you ran and their results, and anything left unresolved. Under 200 words.

## 4. Verify each worker

A worker's report is a claim. As each one returns, check it against GitHub:

- `gh pr view <branch> --json url,state,baseRefName,body` shows an open PR on the planned base whose body's first line is `Closes #<this issue's number>.` Read the rest of the body too: a body written from the wrong file can carry the right-looking shape but another PR's content.
- `gh pr checks <branch> --watch` ends green, or the repo has no CI.
- If `gh` GraphQL commands fail with HTTP 504, use the REST API instead: `gh api repos/<owner>/<repo>/pulls/<n>` for the PR, and `.../commits/<sha>/check-runs` polled in the background for checks. Pass the same fallback to a worker whose `gh pr create` times out.
- The report names the checks it ran and they passed.

A worker that falls short (no PR, red checks, an unmet acceptance item, a skipped check) gets a follow-up through SendMessage, naming exactly what is missing, so it keeps its context. A worker with a human-only question: put the question to the user, then relay the answer the same way.

When a PR lands, dispatch any worker that was waiting on it (step 3).

## 5. Report

You are finished when every issue in the plan has an open PR with green checks, or has been reported to the user as blocked with the reason. Then say plainly that the work is complete, with a table: issue, PR link, checks, and anything a reviewer should know (stacked bases, out-of-scope notes, open questions). If anything is incomplete, the report says so first.

## 6. Land (only when the user asks to merge)

Merge in plan order with the repo's merge style (match `git log` on the default branch: rebase, squash or merge commits). Each merge can leave later PRs conflicting: dispatch one worker per conflicting PR to rebase it onto the default branch, keeping both sides' intent, rerun the definition of done, push with `--force-with-lease`, and merge once checks are green. A conflict where two PRs contradict goes to the user.

Once a worker's PR has merged, remove its worktree and local branch (`git worktree remove`, `git branch -D`), after checking the worktree has no uncommitted work. Leftover worktrees break test runners and branch deletion.

Done when every PR in the plan is merged, or reported to the user with the reason it isn't, and no worktree from this run remains.
