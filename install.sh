#!/usr/bin/env bash
# install.sh — installs /daily-report command + daily-report skill.
#
# Usage:
#   ./install.sh                  # project install (into $PWD/.claude/)
#   ./install.sh --global         # global install (into $HOME/.claude/)
#   ./install.sh --source <dir>   # override source dir (for tests)
#
# Project install also:
#   - creates $PWD/.daily-reports/
#   - appends '.daily-reports/' to $PWD/.gitignore (idempotent)

set -euo pipefail

MODE="project"
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --global) MODE="global"; shift ;;
    --source) SOURCE_DIR="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ "$MODE" == "global" ]]; then
  TARGET_DIR="$HOME/.claude"
else
  TARGET_DIR="$PWD/.claude"
fi

mkdir -p "$TARGET_DIR/commands" "$TARGET_DIR/skills/daily-report"

cp "$SOURCE_DIR/commands/daily-report.md" "$TARGET_DIR/commands/daily-report.md"
cp "$SOURCE_DIR/skills/daily-report/SKILL.md" "$TARGET_DIR/skills/daily-report/SKILL.md"
cp "$SOURCE_DIR/skills/daily-report/examples.md" "$TARGET_DIR/skills/daily-report/examples.md"

# Co-locate gather-context.sh with the skill so the command can find it at a
# predictable path regardless of install scope.
cp "$SOURCE_DIR/scripts/gather-context.sh" "$TARGET_DIR/skills/daily-report/gather-context.sh"
chmod +x "$TARGET_DIR/skills/daily-report/gather-context.sh"

if [[ "$MODE" == "project" ]]; then
  mkdir -p "$PWD/.daily-reports"
  touch "$PWD/.gitignore"
  if ! grep -qE '^\.daily-reports/?$' "$PWD/.gitignore"; then
    printf '\n.daily-reports/\n' >> "$PWD/.gitignore"
  fi
fi

echo "Installed $MODE -> $TARGET_DIR"
