---
name: handoff
description: "Compact the current conversation into a handoff document for another agent to pick up. Use when the user asks for a handoff, to hand over or pass on the work, or to continue in a fresh session."
compatibility: Coding agents only (uses disable-model-invocation; not for claude.ai or the Skills API).
metadata:
  argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

<!--
Adapted from https://github.com/mattpocock/skills/tree/5beb35b/skills/productivity/handoff under the MIT License.
Original Copyright (c) 2026 Matt Pocock. See THIRD_PARTY_NOTICES.md for details.
-->

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to the temporary directory of the user's OS (`$TMPDIR`, else `/tmp`; `%TEMP%` on Windows) - not the current workspace.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
