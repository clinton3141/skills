# Cross-vendor agent skills

Researched 2026-10-21. Primary sources are linked inline. Where only a secondary source was available, that's stated.

## The format: Agent Skills open standard
Spec: <https://agentskills.io/specification>. Anthropic published it as an open standard in December 2025.

- A skill is a directory containing `SKILL.md`: YAML frontmatter followed by Markdown instructions. Optional `scripts/`, `references/` and `assets/` folders.
- Frontmatter fields:
  - `name` (required): at most 64 characters, `[a-z0-9-]`, no leading, trailing or doubled hyphen, and must match the directory name.
  - `description` (required): 1–1024 characters, covering what the skill does and when to use it.
  - `license`, `compatibility` (at most 500 characters), `metadata` (string→string map) and `allowed-tools` (experimental, space-separated) are optional.
- Progressive disclosure: `name` and `description` (~100 tokens) are loaded at startup for every skill. The body (<5k tokens recommended, <500 lines) is loaded on activation. Resources are loaded on demand, and references should be one level deep.
- Validator: [`skills-ref`](https://github.com/agentskills/agentskills/tree/main/skills-ref). It isn't published to PyPI, so run it with `uvx --from 'git+https://github.com/agentskills/agentskills#subdirectory=skills-ref' skills-ref validate <dir>`. Tested at commit `69ef37e`: it rejects unknown frontmatter keys ("Unexpected fields in frontmatter: context") and a name/directory mismatch, exiting 1 in both cases.

## Vendor extensions break portability
[Claude Code skills docs](https://code.claude.com/docs/en/skills):
- Claude Code adds `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths` and `shell`.
- Inside Claude Code, unrecognised fields are ignored. **Outside Claude Code (claude.ai uploads, Skills API), any non-spec field is a hard error.**
- Conclusion: portable skills use spec fields only.

## Where each agent looks
The spec defines what goes in a skill, not where skills live. The [agentskills.io client guide](https://agentskills.io/client-implementation/adding-skills-support) recommends that clients scan `.agents/skills/`, at project level and in `~`, alongside their own directory.

Paths from [vercel-labs/skills docs/agents.md](https://raw.githubusercontent.com/vercel-labs/skills/main/docs/agents.md). This is secondary; check each vendor's docs before relying on it:

| Agent | Project | Global |
|---|---|---|
| Claude Code | `.claude/skills/` | `~/.claude/skills/` |
| Codex | `.agents/skills/` | `~/.agents/skills/` |
| Gemini CLI | `.agents/skills/` | `~/.gemini/skills/` |
| GitHub Copilot | `.agents/skills/` | `~/.copilot/skills/` |
| Cursor | `.agents/skills/` | `~/.cursor/skills/` |
| OpenCode | `.agents/skills/` | `~/.config/opencode/skills/` |
| Windsurf | `.windsurf/skills/` | `~/.codeium/windsurf/skills/` |
| Cline | `.agents/skills/` | `~/.agents/skills/` |

Claude Code's documented locations are `~/.claude/skills/`, `.claude/skills/` (from the start directory up to the repo root), nested `.claude/skills/`, `--add-dir`, and plugins. They don't include `.agents/skills/`. Symlinked skill directories are supported, and a target reached through several links is loaded once.

## Distribution options
1. **skills CLI** (`npx skills add owner/repo`, [vercel-labs/skills](https://github.com/vercel-labs/skills)).
   - Installs into roughly 70 agents and picks the right directory for each.
   - [Discovery](https://raw.githubusercontent.com/vercel-labs/skills/main/docs/creating-skills.md) covers a root `SKILL.md`; `skills/` walked up to 3 levels deep (also `.curated/`, `.experimental/` and `.system/`); agent dirs such as `.agents/skills/` and `.claude/skills/`; and skills declared in `.claude-plugin/marketplace.json` or `plugin.json`.
   - `npx skills check` and `npx skills update` handle updates. `metadata.internal: true` hides a skill unless `INSTALL_INTERNAL_SKILLS=1` is set.
2. **Claude Code plugin marketplace** (tried and dropped; see Decision) ([marketplace reference](https://code.claude.com/docs/en/plugins/marketplace-reference)).
   - `.claude-plugin/marketplace.json` needs `name`, `owner.name` and `plugins[]`. Each entry needs a `name` and a `source`.
   - `"source": "."` makes the repo root the plugin. With no `plugin.json`, the entry is the manifest, and skills are discovered from `<plugin>/skills/`.
   - Plugin skills are namespaced as `/<plugin>:<skill>`.
3. **Symlinks from a clone.** Best for authoring, because edits are live in every agent.

## Decision
Keep skills in `skills/<name>/` with spec-only frontmatter, enforced by `skills-ref` in CI. Publish through the skills CLI only. A Claude Code plugin was tried and dropped: plugin skills are namespaced, so a bare name such as `code-review` resolves to Claude Code's built-in rather than the plugin's skill, whereas personal and project skills replace the built-in (tested 2026-10-22). Use `scripts/link-skills.sh` on machines where skills are edited.
