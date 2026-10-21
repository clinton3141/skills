# Skills repo

Agent Skills that must work across vendors (Claude Code, Codex, Gemini CLI, Copilot, Cursor, OpenCode, …). Background and sources: `docs/research/cross-vendor-skills.md`.

## Adding or editing a skill
- One folder per skill: `skills/<name>/SKILL.md`, with optional `scripts/`, `references/`, `assets/`. Copy `skills/example-skill/` to start.
- `name` must equal the folder name: lowercase letters, digits and single hyphens, at most 64 characters.
- `description` (at most 1024 characters) says what the skill does **and** when to use it, using the words a user would type. It is the only text an agent sees before deciding to load the skill.
- Frontmatter may contain only `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Vendor-specific keys (e.g. Claude Code's `context`, `hooks`, `disable-model-invocation`) make the skill fail to load on claude.ai and the Skills API. Put vendor extras under `metadata`, or state the requirement in `compatibility`.
- Keep `SKILL.md` under 500 lines. Move detail into `references/` and link to it with a relative path one level deep.
- Scripts must state their dependencies and must not assume a particular agent's tools.

## Before committing
Run `scripts/validate.sh`. CI runs the same check.
