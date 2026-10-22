<!--
Adapted from https://github.com/mattpocock/skills/blob/5beb35b/skills/engineering/setup-matt-pocock-skills/issue-tracker-local.md under the MIT License.
Original Copyright (c) 2026 Matt Pocock. See THIRD_PARTY_NOTICES.md for details.
-->

# Issue tracker: Local Markdown

Issues and specs for this repo live as markdown files in `.scratch/`.

## Conventions

- One feature per directory: `.scratch/<feature-slug>/`
- The spec is `.scratch/<feature-slug>/spec.md`
- Implementation issues are one file per ticket at `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01`, never a single combined tickets file
- Triage state is recorded as a `Status:` line near the top of each issue file (see `triage-labels.md` for the role strings)
- A blocked issue carries a `Blocked by: NN, NN` line near the top; it is unblocked when every issue it lists is done
- Comments and conversation history append to the bottom of the file under a `## Comments` heading

## When a skill says "publish to the issue tracker"

Create a new file under `.scratch/<feature-slug>/` (creating the directory if needed).

## When a skill says "fetch the relevant ticket"

Read the file at the referenced path. The user will normally pass the path or the issue number directly.
