---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
compatibility: Coding agents only (uses disable-model-invocation; not for claude.ai or the Skills API).
disable-model-invocation: true
---

<!--
Adapted from https://github.com/mattpocock/skills/tree/5beb35b/skills/engineering/implement under the MIT License.
Original Copyright (c) 2026 Matt Pocock. See THIRD_PARTY_NOTICES.md for details.
-->

Implement the work described by the user in the spec or tickets.

If the user passes a ticket reference, fetch it from the issue tracker and state its title before starting. If the reference is ambiguous, ask.

Where possible, read `../tdd/SKILL.md` (relative to this skill's folder) and follow it at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end.

Once done, read `../spec-review/SKILL.md` and follow it to review the work.

Commit your work to the current branch.
