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

failed=0
for dir in "${dirs[@]}"; do
  dir="${dir%/}"
  if ! uvx -q --from "$SKILLS_REF_SOURCE" skills-ref validate "$dir"; then
    failed=1
    continue
  fi
  lines=$(wc -l < "$dir/SKILL.md" | tr -d ' ')
  if [ "$lines" -gt "$MAX_LINES" ]; then
    echo "warning: $dir/SKILL.md is $lines lines; the spec recommends under $MAX_LINES (move detail to references/)"
  fi
done

exit "$failed"
