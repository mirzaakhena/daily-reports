#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
INSTALLER="$REPO_ROOT/install.sh"
SANDBOX="$HERE/../.test-sandbox"
FAILS=0

log_fail() { echo "  FAIL: $1"; FAILS=$((FAILS + 1)); }
log_pass() { echo "  PASS: $1"; }

setup_project_sandbox() {
  rm -rf "$SANDBOX"
  mkdir -p "$SANDBOX"
  cd "$SANDBOX"
  git init -q
}

setup_global_sandbox() {
  rm -rf "$SANDBOX"
  mkdir -p "$SANDBOX/fake-home"
  cd "$SANDBOX"
}

test_project_install_copies_files() {
  setup_project_sandbox
  bash "$INSTALLER" --source "$REPO_ROOT"

  if [[ ! -f "$SANDBOX/.claude/commands/daily-report.md" ]]; then
    log_fail "project install: commands/daily-report.md missing"; return
  fi
  if [[ ! -f "$SANDBOX/.claude/skills/daily-report/SKILL.md" ]]; then
    log_fail "project install: skills/daily-report/SKILL.md missing"; return
  fi
  if [[ ! -f "$SANDBOX/.claude/skills/daily-report/gather-context.sh" ]]; then
    log_fail "project install: gather-context.sh not co-located with skill"; return
  fi
  if [[ ! -x "$SANDBOX/.claude/skills/daily-report/gather-context.sh" ]]; then
    log_fail "project install: gather-context.sh not executable"; return
  fi
  log_pass "project install copies command, skill, and gather script"
}

test_project_install_creates_archive_dir() {
  setup_project_sandbox
  bash "$INSTALLER" --source "$REPO_ROOT"

  if [[ ! -d "$SANDBOX/.daily-reports" ]]; then
    log_fail "project install: .daily-reports/ not created"; return
  fi
  log_pass "project install creates .daily-reports/"
}

test_project_install_appends_gitignore() {
  setup_project_sandbox
  bash "$INSTALLER" --source "$REPO_ROOT"

  if ! grep -qE '^\.daily-reports/?$' "$SANDBOX/.gitignore"; then
    log_fail "project install: .daily-reports not in .gitignore"; return
  fi
  log_pass "project install appends .daily-reports/ to .gitignore"
}

test_project_install_gitignore_idempotent() {
  setup_project_sandbox
  echo ".daily-reports/" > "$SANDBOX/.gitignore"
  bash "$INSTALLER" --source "$REPO_ROOT"

  local count
  count="$(grep -cE '^\.daily-reports/?$' "$SANDBOX/.gitignore")"
  if [[ "$count" -ne 1 ]]; then
    log_fail ".daily-reports appears $count times in .gitignore (expected 1)"; return
  fi
  log_pass "project install does not duplicate gitignore entry"
}

test_global_install_copies_to_home() {
  setup_global_sandbox
  HOME="$SANDBOX/fake-home" bash "$INSTALLER" --global --source "$REPO_ROOT"

  if [[ ! -f "$SANDBOX/fake-home/.claude/commands/daily-report.md" ]]; then
    log_fail "global install: commands/daily-report.md missing"; return
  fi
  if [[ ! -f "$SANDBOX/fake-home/.claude/skills/daily-report/SKILL.md" ]]; then
    log_fail "global install: skills/daily-report/SKILL.md missing"; return
  fi
  if [[ ! -x "$SANDBOX/fake-home/.claude/skills/daily-report/gather-context.sh" ]]; then
    log_fail "global install: gather-context.sh missing or not executable"; return
  fi
  log_pass "global install populates ~/.claude/"
}

test_project_install_copies_files
test_project_install_creates_archive_dir
test_project_install_appends_gitignore
test_project_install_gitignore_idempotent
test_global_install_copies_to_home

echo
echo "Failures: $FAILS"
[[ $FAILS -eq 0 ]]
