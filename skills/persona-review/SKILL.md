---
name: persona-review
description: >
  Code review of a commit or uncommitted changes through one or more personas:
  Chad (correctness, tests, types, linting, bugs), Clive (performance, concurrency,
  security, database), Jimmy (Clean Code, naming, code smells, refactoring) and
  Poindexter (architecture, design, SOLID, trade-offs), or a shallow sweep of all four.
  Use when the user asks for Chad's, Clive's, Jimmy's or Poindexter's review, a review
  of one of those concerns, a review from all reviewers ("review all"), or a code
  review of their change.
  Usage: /persona-review [personas or concerns] [commit-hash]
---

A **persona review** looks at a change through one persona's lens, for a human reviewing their own code or someone else's. Each persona's criteria, voice and output format live in its own reference file, the single source of truth for that persona:

- **Chad**: [`references/chad.md`](references/chad.md)
- **Clive**: [`references/clive.md`](references/clive.md)
- **Jimmy**: [`references/jimmy.md`](references/jimmy.md)
- **Poindexter**: [`references/poindexter.md`](references/poindexter.md)

A **sweep** runs all four at reduced depth, to show which personas are worth running in full.

## 1. Resolve the target

- A commit hash: review `git show <hash>`.
- Nothing given: review the uncommitted changes, `git diff --staged` and `git diff`.

Done when the diff command is fixed and its output is non-empty. An empty diff or a ref that doesn't resolve stops here with a message to the user.

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

Where the agent can start sub-agents, start one per persona, in parallel, so each review has a context of its own; otherwise run them one after another in this context, each at full depth. Brief each sub-agent with the diff command from step 1 and the absolute path of its reference file, telling it to read the file, review the diff as that persona against every criterion, and return the report in the persona's output format.

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
