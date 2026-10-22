---
name: implement-issues-afk
description: "Run implement-issues while the user is away: ask everything up front, then dispatch, verify and land without waiting."
compatibility: Coding agents only (uses disable-model-invocation; not for claude.ai or the Skills API).
disable-model-invocation: true
---

Run `~/.claude/skills/implement-issues/SKILL.md` as the orchestrator, with the changes below. The user is **AFK**: every question they would otherwise answer mid-run is asked once, at the start, and the run then carries on alone until it is done or blocked.

The repo's own docs (its `CLAUDE.md` and the docs it links) say how its checks, merges and deploys work. Where they name something below, such as the definition of done, the merge style or what a merge deploys, follow them.

## Before step 1: settle the questions

Ask in one `AskUserQuestion` call, leaving out anything the invocation already answers:

- **Model** for the workers. A handoff from an earlier run may name one; still confirm it.
- **Landing**: merge each PR once it is verified, or open PRs and stop.

Done when both are answered. From here the only questions that go to the user are ones only a human can settle (a worker's spec question, two PRs that contradict each other); everything else is decided by the skill, the repo's docs or a stated assumption.

## Step 2: plan without waiting

Show the plan table, then dispatch straight away. The go-ahead was given at the start.

## Step 3: what the brief adds

Add to every worker's brief:

- Install dependencies fresh from the lockfile in the new worktree before anything else.
- Run the repo's whole definition of done **after the last change**, review fixes included, and see it pass. The PR body records the results under `## Checks, all after the last change`.
- Run both review axes, Standards then Spec, and record them in the PR body under `## Review (against origin/<base>)` with `### Standards` and `### Spec`, each finding marked fixed or answered.
- Other workers' suites run at the same time, so a timing failure is rerun before it is called real. A timeout is never raised to make a real failure pass.
- Leave merging to the orchestrator.

Workers otherwise cut these corners, so state each one plainly.

## Step 4: what verification adds

A PR is verified only when its body has both sections above, with every check listed as run after the last change and passing. If the repo's CI runs less than its definition of done, a green check is supporting evidence only; the Checks section is the proof. A PR short of this goes back to its worker through `SendMessage`, naming what is missing.

## Step 6: landing without asking

If the user chose to merge, land each PR as soon as it is verified, in plan order, without asking again. After each merge:

- Every open PR from this run that touches any of the same files goes back to its worker, even when it still merges cleanly: two PRs can merge as text and still fail the typecheck. The worker merges the default branch, reruns the whole definition of done, pushes, and updates the Checks section. Merge it once its new CI run is green and the section is updated.
- If a merge deploys, watch the deploy run to its end. A failed deploy stops further merges and goes in the report.
- Clean up as the skill says, and also delete the `worktree-agent-*` branch the harness creates for each worktree.

If the user chose PRs only, stop after step 5.

## Interruptions

After a rate limit, a long wait or a scheduled wakeup, re-read the state (`gh pr list`, `git worktree list`, each PR's checks) before acting; a wakeup can fire after the work it was guarding has moved on. Resume workers with `SendMessage`, which keeps their context.

## Finishing

The run is done when every issue is merged (or has a verified PR, if the user chose PRs only) or is reported as blocked with the reason, and no worktree from this run remains.

### File the loose ends

The user may never read the final report, so nothing that needs doing or deciding lives only there. Gather every **loose end** from the run:

- each PR body's out-of-scope notes, unresolved items and interpretations of the spec;
- the workers' reports;
- your own next steps and calls for the user, including what would unblock a blocked issue.

For each, either file it in the repo's issue tracker or drop it as not worth anyone's time. A loose end is worth filing when it is a follow-up someone should do, a risk someone should weigh, or a question only the user can answer.

- **Find a home first.** Search the open issues. If one already covers it, comment there instead of filing a duplicate.
- **One issue per loose end.** Its body says what was found, where (link the PR, file and line), and why it matters. A question states the options and the run's recommendation.
- **Label it** with the repo's triage vocabulary: a follow-up as one awaiting triage, and a question for the user as one awaiting a human.

Done when every loose end is filed, commented on an existing issue, or dropped, and none is left only in a PR body or the report.

### Report

Lead with anything incomplete. Then the table from `implement-issues` step 5, and a list of the issues filed or commented on, each with its number and one line on why. The report holds no next step without an issue number beside it.

If work remains for a later run, write a handoff file with the current state only: open issues, blockers, PRs in flight. Lessons about how to run the work belong in the repo's docs or in this skill instead.
