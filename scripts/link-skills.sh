#!/usr/bin/env bash
# Symlink every skill in this repo into each installed agent's global skills dir,
# so edits here are live everywhere without reinstalling.
# Usage: scripts/link-skills.sh [--dry-run] [--unlink]
#
# Never touches anything that isn't a symlink back into this repo; conflicts are
# reported and the script exits 1 so they aren't missed.
set -uo pipefail

# "<agent config dir>:<skills dir>" pairs, from vercel-labs/skills docs/agents.md.
# A skills dir is only used when its agent's config dir already exists.
TARGETS=(
  "$HOME/.agents:$HOME/.agents/skills"                     # Codex, Cline, shared convention
  "$HOME/.claude:$HOME/.claude/skills"                     # Claude Code
  "$HOME/.gemini:$HOME/.gemini/skills"                     # Gemini CLI
  "$HOME/.copilot:$HOME/.copilot/skills"                   # GitHub Copilot
  "$HOME/.cursor:$HOME/.cursor/skills"                     # Cursor
  "$HOME/.config/opencode:$HOME/.config/opencode/skills"   # OpenCode
  "$HOME/.codeium/windsurf:$HOME/.codeium/windsurf/skills" # Windsurf
)

dry_run=0
unlink=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=1 ;;
    --unlink) unlink=1 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

run() {
  if [ "$dry_run" -eq 1 ]; then
    echo "would run: $*"
  else
    "$@"
  fi
}

conflicts=0
for target in "${TARGETS[@]}"; do
  config_dir="${target%%:*}"
  skills_dir="${target#*:}"
  [ -d "$config_dir" ] || continue

  for src in "$repo_root"/skills/*/; do
    src="${src%/}"
    dest="$skills_dir/$(basename "$src")"

    if [ "$unlink" -eq 1 ]; then
      if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        run rm "$dest"
      fi
      continue
    fi

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      continue
    elif [ -e "$dest" ] || [ -L "$dest" ]; then
      echo "conflict: $dest already exists and isn't a link to $src; skipped" >&2
      conflicts=1
    else
      [ -d "$skills_dir" ] || run mkdir -p "$skills_dir"
      run ln -s "$src" "$dest"
      [ "$dry_run" -eq 1 ] || echo "linked $dest"
    fi
  done
done

exit "$conflicts"
