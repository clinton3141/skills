#!/usr/bin/env bash
# Validate skills against the Agent Skills spec (https://agentskills.io/specification).
# Usage: scripts/validate.sh [skill-dir ...]   (defaults to every skills/*/)
#
# skills-ref already rejects non-spec frontmatter keys and a name that doesn't
# match its folder, which is what keeps skills uploadable outside Claude Code.
set -uo pipefail

# Pinned so a spec change upstream can't silently change what CI accepts.
SKILLS_REF_COMMIT=69ef37e9424c0a7ea9dd2293b559e43ec8176379
SKILLS_REF_SOURCE="git+https://github.com/agentskills/agentskills@${SKILLS_REF_COMMIT}#subdirectory=skills-ref"
MAX_LINES=500

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

if [ "$#" -gt 0 ]; then
  dirs=("$@")
else
  dirs=("$repo_root"/skills/*/)
fi

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

frontmatter() {
  awk 'NR == 1 && $0 == "---" { inside = 1; next } inside && $0 == "---" { exit } inside' "$1"
}

manual_only() {
  frontmatter "$1" | grep -q '^disable-model-invocation:[[:space:]]*true'
}

# Every skill in the repo, and the manual-only ones among them, for the
# cross-skill checks below (which run on each validated skill's Markdown).
all_skills=()
manual_skills=()
for skill_md in "$repo_root"/skills/*/SKILL.md; do
  name="$(basename "$(dirname "$skill_md")")"
  all_skills+=("$name")
  if manual_only "$skill_md"; then manual_skills+=("$name"); fi
done

# A skill must reach another skill through the Skill tool, never by reading its
# file, and must never load a manual-only skill (see AGENTS.md).
check_cross_skill() {
  local dir="$1" own other md bad=0
  own="$(basename "$dir")"
  while IFS= read -r -d '' md; do
    for other in "${all_skills[@]}"; do
      [ "$other" = "$own" ] && continue
      if grep -nE "/${other}/SKILL\.md" "$md" >/dev/null; then
        grep -nE "/${other}/SKILL\.md" "$md" | sed "s|^|error: $md:|; s|\$| (reads skill '$other' by path; call the Skill tool instead)|" >&2
        bad=1
      fi
    done
    for other in "${manual_skills[@]}"; do
      [ "$other" = "$own" ] && continue
      if grep -nE "Skill tool.*\`${other}\`" "$md" >/dev/null; then
        grep -nE "Skill tool.*\`${other}\`" "$md" | sed "s|^|error: $md:|; s|\$| (loads manual-only skill '$other'; see AGENTS.md)|" >&2
        bad=1
      fi
    done
  done < <(find "$dir" -name '*.md' -print0)
  return "$bad"
}

failed=0
for dir in "${dirs[@]}"; do
  dir="${dir%/}"
  target="$dir"
  check_cross_skill "$dir" || failed=1
  # disable-model-invocation is the one vendor key allowed (see AGENTS.md). skills-ref
  # rejects it, so validate a copy without it; the copy keeps the folder name because
  # skills-ref checks it against `name`.
  if frontmatter "$dir/SKILL.md" | grep -q '^disable-model-invocation:'; then
    if ! frontmatter "$dir/SKILL.md" | grep -q '^compatibility:'; then
      echo "error: $dir uses disable-model-invocation without a compatibility field" >&2
      failed=1
      continue
    fi
    target="$tmp_root/$(basename "$dir")"
    cp -R "$dir" "$target"
    awk 'NR == 1 { inside = ($0 == "---") } inside && NR > 1 && $0 == "---" { inside = 0 }
         !(inside && /^disable-model-invocation:/)' "$dir/SKILL.md" > "$target/SKILL.md"
  fi
  if ! uvx -q --from "$SKILLS_REF_SOURCE" skills-ref validate "$target"; then
    failed=1
    continue
  fi
  lines=$(wc -l < "$dir/SKILL.md" | tr -d ' ')
  if [ "$lines" -gt "$MAX_LINES" ]; then
    echo "warning: $dir/SKILL.md is $lines lines; the spec recommends under $MAX_LINES (move detail to references/)"
  fi
done

exit "$failed"
