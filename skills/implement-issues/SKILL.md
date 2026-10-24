---
name: implement-issues
description: "Implement several issues in parallel: one subagent per issue, or per group of issues sharing files, each implementing test-first on its own branch and opening a PR; then land them on request. Pass `afk` to ask everything up front and run unattended."
compatibility: Coding agents only (uses disable-model-invocation; not for claude.ai or the Skills API).
disable-model-invocation: true
---

You are the **orchestrator**. Each issue goes to one **worker** subagent, which implements it on its own branch in its own worktree and opens a pull request. You write no feature code yourself: you plan, dispatch, verify, and report.

The issue tracker workflow is in `docs/agents/issue-tracker.md`; read it before step 1.

## Mode

The run is **interactive** unless the invocation's arguments include the word `afk` (e.g. `/implement-issues afk 12 13`). Only that word turns on AFK mode: never infer it from anything else, such as the user saying they are stepping away, a handoff file, or an earlier run. In AFK mode, follow the steps below with the changes in [AFK mode](#afk-mode); everything else is the same.

## Before step 1: check commit signing

In both modes. A worker is a subagent with no terminal, so if its `git commit` needs a passphrase for the signing key, the commit blocks for good, with the work staged and nothing committed.

If `git config --get commit.gpgsign` prints `true` in the main checkout, make a probe signature:

```sh
git commit-tree -S -m probe $(git hash-object -t tree /dev/null) </dev/null
```

It works with every signing format and creates only a commit that nothing points to. Let it run for about 10 seconds at most (use your tool's timeout, or run it in the background and kill it). A non-zero exit or running out of time is a failure.

When the probe fails, tell the user to load the signing key in a separate terminal (e.g. `ssh-add`, or their GPG agent), not through the agent's `!` shell: that has no terminal, and the passphrase prompt fails there with "incorrect passphrase". Then run the probe again. Don't go on until it passes, and don't offer to commit unsigned.

Done when the probe passes, or `commit.gpgsign` isn't `true`.

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

Spawn every unblocked worker in one message, each with the Agent tool, `isolation: "worktree"`, running in the background. Each worker starts cold, so its prompt carries everything it needs; fill in this brief.

> You are implementing issue #<number> in `<repo path>`, alone, in your own worktree. Other workers are implementing other issues in parallel; touch only what this issue needs, and note anything out of scope in the PR body instead of fixing it. The other workers share your temp and scratchpad directories, so write any scratch file (the PR body included) inside your worktree or under a name containing `<number>`, never at a fixed shared path.
>
> <the issue's full body and comments, pasted; for a group, each issue in order>
>
> <decisions the user made in planning; what has merged since the issue was written that moves or renames code it cites; the port and toolchain setup from step 2>
>
> For a group, make one commit per issue, each ending `Closes #<number>`.
>
> If a `git commit` is still running after about 30 seconds, check with `ps` what it is waiting on. If it's the signing program (`ssh-keygen -Y sign`, `gpg`, or whatever `gpg.<format>.program` names), kill the commit with a plain `kill` (not `-9`, so git removes its `index.lock`), leave the work staged, and report a signing stall. Never disable signing. If something else is running, it's a hook: keep waiting.
>
> 1. Create your branch: `git fetch origin && git switch -c <branch> origin/<base>`.
> 2. Implement the issue test-first: call the Skill tool with `tdd` and work at the seams the issue names. Run typechecking and single test files as you go, and the full test suite at the end. Commit to your branch.
> 3. Review: call the Skill tool with `spec-review`, but run both axes (Standards, then Spec) yourself, one after the other, against the fixed point `origin/<base>`, rather than spawning sub-agents.
> 4. You are done when: every item in the issue's acceptance criteria is met; the repo's definition of done passes (find it from `CLAUDE.md` / `AGENTS.md` and the docs they point to), run and seen passing, not assumed; and every review finding is fixed or answered in the PR body.
> 5. Push (`git push -u origin <branch>`) and open the PR with `gh pr create --base <base> --head <branch>`. Match the repo's recent PR titles and bodies (`gh pr list --state merged --limit 5 --json title,body`); the body opens with `Closes #<number>.` (one line per issue for a group)
> 6. If the issue is ambiguous in a way only a human can settle, stop before step 5 and report the question instead.
>
> Reply with: the PR URL (or the blocking question, or the signing stall), the checks you ran and their results, and anything left unresolved. Under 200 words.

## 4. Verify each worker

A worker's report is a claim. As each one returns, check it against GitHub:

- `gh pr view <branch> --json url,state,baseRefName,body` shows an open PR on the planned base whose body's first line is `Closes #<this issue's number>.` Read the rest of the body too: a body written from the wrong file can carry the right-looking shape but another PR's content.
- `gh pr checks <branch> --watch` ends green, or the repo has no CI.
- If `gh` GraphQL commands fail with HTTP 504, use the REST API instead: `gh api repos/<owner>/<repo>/pulls/<n>` for the PR, and `.../commits/<sha>/check-runs` polled in the background for checks. Pass the same fallback to a worker whose `gh pr create` times out.
- The report names the checks it ran and they passed.

A worker that falls short (no PR, red checks, an unmet acceptance item, a skipped check) gets a follow-up through SendMessage, naming exactly what is missing, so it keeps its context. A worker with a human-only question: put the question to the user, then relay the answer the same way.

A worker that reports a signing stall: tell the user to load the signing key in a separate terminal, as in [check commit signing](#before-step-1-check-commit-signing). Keep the other workers going, and once the user confirms the key is loaded, resume the stalled worker with `SendMessage` to commit and carry on.

When a PR lands, dispatch any worker that was waiting on it (step 3).

## 5. Report

You are finished when every issue in the plan has an open PR with green checks, or has been reported to the user as blocked with the reason. Then say plainly that the work is complete, with a table: issue, PR link, checks, and anything a reviewer should know (stacked bases, out-of-scope notes, open questions). If anything is incomplete, the report says so first.

## 6. Land (only when the user asks to merge)

Merge in plan order with the repo's merge style (match `git log` on the default branch: rebase, squash or merge commits). Each merge can leave later PRs conflicting: dispatch one worker per conflicting PR to rebase it onto the default branch, keeping both sides' intent, rerun the definition of done, push with `--force-with-lease`, and merge once checks are green. A conflict where two PRs contradict goes to the user.

Once a worker's PR has merged, remove its worktree and local branch (`git worktree remove`, `git branch -D`), after checking the worktree has no uncommitted work. Leftover worktrees break test runners and branch deletion.

Done when every PR in the plan is merged, or reported to the user with the reason it isn't, and no worktree from this run remains.

## AFK mode

Only when the invocation includes `afk` (see [Mode](#mode)). The user is **AFK**: every question they would otherwise answer mid-run is asked once, at the start, and the run then carries on alone until it is done or blocked.

The repo's own docs (its `CLAUDE.md` and the docs it links) say how its checks, merges and deploys work. Where they name something below, such as the definition of done, the merge style or what a merge deploys, follow them.

### Before step 1: settle the questions

Once the [signing check](#before-step-1-check-commit-signing) passes, ask in one `AskUserQuestion` call, leaving out anything the invocation already answers:

- **Model** for the workers. A handoff from an earlier run may name one; still confirm it.
- **Landing**: merge each PR once it is verified, or open PRs and stop.

Done when both are answered. From here the only questions that go to the user are ones only a human can settle (a worker's spec question or signing stall, two PRs that contradict each other); everything else is decided by the skill, the repo's docs or a stated assumption.

### Step 2: plan without waiting

Show the plan table, then dispatch straight away. The go-ahead was given at the start.

### Step 3: what the brief adds

Add to every worker's brief:

- Install dependencies fresh from the lockfile in the new worktree before anything else.
- Run the repo's whole definition of done **after the last change**, review fixes included, and see it pass. The PR body records the results under `## Checks, all after the last change`.
- Run both review axes, Standards then Spec, and record them in the PR body under `## Review (against origin/<base>)` with `### Standards` and `### Spec`, each finding marked fixed or answered.
- Other workers' suites run at the same time, so a timing failure is rerun before it is called real. A timeout is never raised to make a real failure pass.
- Leave merging to the orchestrator.

Workers otherwise cut these corners, so state each one plainly.

### Step 4: what verification adds

A PR is verified only when its body has both sections above, with every check listed as run after the last change and passing. If the repo's CI runs less than its definition of done, a green check is supporting evidence only; the Checks section is the proof. A PR short of this goes back to its worker through `SendMessage`, naming what is missing.

### Step 6: landing without asking

If the user chose to merge, land each PR as soon as it is verified, in plan order, without asking again. After each merge:

- Every open PR from this run that touches any of the same files goes back to its worker, even when it still merges cleanly: two PRs can merge as text and still fail the typecheck. The worker merges the default branch, reruns the whole definition of done, pushes, and updates the Checks section. Merge it once its new CI run is green and the section is updated.
- If a merge deploys, watch the deploy run to its end. A failed deploy stops further merges and goes in the report.
- Clean up as step 6 says, and also delete the `worktree-agent-*` branch the harness creates for each worktree.

If the user chose PRs only, stop after step 5.

### Interruptions

After a rate limit, a long wait or a scheduled wakeup, re-read the state (`gh pr list`, `git worktree list`, each PR's checks) before acting; a wakeup can fire after the work it was guarding has moved on. Resume workers with `SendMessage`, which keeps their context.

### Finishing

The run is done when every issue is merged (or has a verified PR, if the user chose PRs only) or is reported as blocked with the reason, and no worktree from this run remains.

#### File the loose ends

The user may never read the final report, so nothing that needs doing or deciding lives only there. Gather every **loose end** from the run:

- each PR body's out-of-scope notes, unresolved items and interpretations of the spec;
- the workers' reports;
- your own next steps and calls for the user, including what would unblock a blocked issue.

For each, either file it in the repo's issue tracker or drop it as not worth anyone's time. A loose end is worth filing when it is a follow-up someone should do, a risk someone should weigh, or a question only the user can answer.

- **Find a home first.** Search the open issues. If one already covers it, comment there instead of filing a duplicate.
- **One issue per loose end.** Its body says what was found, where (link the PR, file and line), and why it matters. A question states the options and the run's recommendation.
- **Label it** with the repo's triage vocabulary: a follow-up as one awaiting triage, and a question for the user as one awaiting a human.

Done when every loose end is filed, commented on an existing issue, or dropped, and none is left only in a PR body or the report.

#### Report

Lead with anything incomplete. Then the table from step 5, and a list of the issues filed or commented on, each with its number and one line on why. The report holds no next step without an issue number beside it.

If work remains for a later run, write a handoff file with the current state only: open issues, blockers, PRs in flight. Lessons about how to run the work belong in the repo's docs or in this skill instead.
