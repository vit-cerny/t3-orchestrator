#!/bin/sh
# t3-orchestrator installer (macOS / Linux)
# Copies the T3 orchestration agents + skill into the opencode config dir and
# appends the T3 section to AGENTS.md once. Idempotent. ASCII only.
#
#   sh install.sh
#   OPENCODE_CONFIG_DIR=/path/to/opencode sh install.sh
#   sh install.sh -n        # dry run

set -eu

DRY=0
case "${1:-}" in
  -n|--dry-run) DRY=1 ;;
  "") ;;
  *) echo "usage: sh install.sh [-n]" >&2; exit 2 ;;
esac

cfg=${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}
src=$(cd "$(dirname "$0")" && pwd)
marker='## T3 Code (global, opencode harness)'
stamp=$(date +%Y%m%d-%H%M%S)

echo "source      : $src"
echo "config dir  : $cfg"
[ "$DRY" -eq 1 ] && echo "mode        : DRY RUN (nothing is written)"
echo

copy_with_backup() {
  from=$1
  to=$2
  if [ -f "$to" ]; then
    echo "  backup  $to -> $to.bak.$stamp"
    [ "$DRY" -eq 0 ] && cp "$to" "$to.bak.$stamp"
  fi
  echo "  write   $to"
  if [ "$DRY" -eq 0 ]; then
    mkdir -p "$(dirname "$to")"
    cp "$from" "$to"
  fi
}

echo "agents:"
for a in t3-orchestrator.md t3-thread.md t3-subagent.md; do
  [ -f "$src/agents/$a" ] || { echo "missing source agent: $src/agents/$a" >&2; exit 1; }
  copy_with_backup "$src/agents/$a" "$cfg/agents/$a"
done

echo
echo "skill:"
copy_with_backup "$src/skills/t3-orchestration/SKILL.md" \
  "$cfg/skills/t3-orchestration/SKILL.md"
copy_with_backup "$src/skills/t3-orchestration/references/project-agents-template.md" \
  "$cfg/skills/t3-orchestration/references/project-agents-template.md"

echo
echo "AGENTS.md:"
agents_md="$cfg/AGENTS.md"
if [ -f "$agents_md" ] && grep -qF "$marker" "$agents_md"; then
  echo "  skip    T3 section already present in $agents_md"
else
  echo "  append  T3 section -> $agents_md"
  if [ "$DRY" -eq 0 ]; then
    if [ -f "$agents_md" ]; then cp "$agents_md" "$agents_md.bak.$stamp"; fi
    mkdir -p "$cfg"
    { echo; cat "$src/AGENTS.snippet.md"; } >> "$agents_md"
  fi
fi

echo
if [ "$DRY" -eq 1 ]; then
  echo "DRY RUN complete. Re-run without -n to apply."
  exit 0
fi

# --- self check ---
fail=""
for a in t3-orchestrator.md t3-thread.md t3-subagent.md; do
  [ -f "$cfg/agents/$a" ] || fail="$fail missing-agent-$a"
done
[ -f "$cfg/skills/t3-orchestration/SKILL.md" ] || fail="$fail missing-SKILL.md"
[ -f "$cfg/skills/t3-orchestration/references/project-agents-template.md" ] || fail="$fail missing-template"
if [ ! -f "$agents_md" ]; then
  fail="$fail missing-AGENTS.md"
elif ! grep -qF "$marker" "$agents_md"; then
  fail="$fail AGENTS.md-marker-missing"
fi

if [ -n "$fail" ]; then
  echo "CHECK: FAIL$fail"
  exit 1
fi

echo "CHECK: PASS (3 agents, 2 skill files, AGENTS.md section)"
echo
echo "Next:"
echo "  1. Restart opencode (config is not hot-reloaded)."
echo "  2. T3: Settings -> Providers -> enable the 'opencode' instance and sign in."
echo "  3. T3: select agent 't3-orchestrator' and describe a project-scale task."
