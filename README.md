# skills

Portable [Agent Skills](https://agentskills.io): one `SKILL.md` per skill, usable by any agent that supports the open standard.

## Install

**Any agent** (Claude Code, Codex, Gemini CLI, Copilot, Cursor, OpenCode, Windsurf, …) via the [skills CLI](https://github.com/vercel-labs/skills):

```sh
npx skills add clinton3141/skills            # this project
npx skills add clinton3141/skills -g         # all projects
npx skills add clinton3141/skills -a codex -a claude-code
```

**Claude Code plugin**: skills are namespaced as `/clinton:<skill>`, and updates arrive through the plugin system.

```sh
claude plugin marketplace add clinton3141/skills
claude plugin install clinton@clinton3141
```

**From a local clone** (for editing): symlinks each skill into the global skills dir of every agent installed on this machine, so edits here take effect immediately.

```sh
scripts/link-skills.sh --dry-run
scripts/link-skills.sh
scripts/link-skills.sh --unlink
```

## Layout

```
skills/<name>/SKILL.md          the skill (+ optional scripts/, references/, assets/)
.claude-plugin/marketplace.json Claude Code marketplace; the repo root is the plugin
scripts/validate.sh             spec validation (needs uv)
scripts/link-skills.sh          local symlink installer
```

Authoring rules are in [AGENTS.md](AGENTS.md).
