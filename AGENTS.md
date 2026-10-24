# Skills repo

Agent Skills that must work across vendors (Claude Code, Codex, Gemini CLI, Copilot, Cursor, OpenCode, …). Background and sources: `docs/research/cross-vendor-skills.md`.

## Adding or editing a skill
- One folder per skill: `skills/<name>/SKILL.md`, with optional `scripts/`, `references/`, `assets/`. Copy `skills/example-skill/` to start.
- `name` must equal the folder name: lowercase letters, digits and single hyphens, at most 64 characters.
- `description` (at most 1024 characters) says what the skill does **and** when to use it, using the words a user would type. It is the only text an agent sees before deciding to load the skill.
- Frontmatter may contain only `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Vendor-specific keys (e.g. Claude Code's `context`, `hooks`, `disable-model-invocation`) make the skill fail to load on claude.ai and the Skills API. Put vendor extras under `metadata`, or state the requirement in `compatibility`.
- One exception: `disable-model-invocation: true` is allowed on coding-agent workflows that must only run when the user asks (it also keeps the description out of context). Such a skill must say so in `compatibility`, e.g. `Coding agents only (uses disable-model-invocation; not for claude.ai or the Skills API).` `scripts/validate.sh` enforces this.
- A skill copied from a third-party MIT project carries the header in `docs/templates/third-party-mit-header.md` in every copied file, with `{{SOURCE}}` a permalink to the upstream commit and path: after the frontmatter in `SKILL.md`, at the top of other Markdown files, and as `#` comments below the shebang in scripts. The project's licence goes in `THIRD_PARTY_NOTICES.md`.
- To use another skill, write "Call the Skill tool with `<name>`." Never point at another skill's file (`../<name>/SKILL.md`, `<skills dir>/<name>/SKILL.md`): the agent reads it as a raw file, which shows in the transcript as a `cat` instead of a quiet skill load.
- A skill never loads a manual-only skill (`disable-model-invocation`), since the Skill tool can't. Shared logic belongs in a model-invocable skill, often a reference skill such as `code-smells` or `codebase-design`. If that logic isn't safe to trigger on its own (it pushes, merges or opens PRs), merge the callers into one manual-only skill with an argument instead, as `implement-issues afk` does. `scripts/validate.sh` enforces both rules.
- Keep `SKILL.md` under 500 lines. Move detail into `references/` and link to it with a relative path one level deep.
- Scripts must state their dependencies and must not assume a particular agent's tools.

## Before committing
Run `scripts/validate.sh`. CI runs the same check.

## Agent skills

### Issue tracker

Issues are tracked in this repo's GitHub Issues, via `gh`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default label names for all triage roles. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one root `GLOSSARY.md` and `docs/adr/`. See `docs/agents/domain.md`.
