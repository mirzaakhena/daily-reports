#!/usr/bin/env bash
# Test harness for gather-context.sh.
# Creates a sandboxed git repo per test, runs the script, asserts on output.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/gather-context.sh"
SANDBOX="$HERE/../.test-sandbox"
FAILS=0

log_fail() { echo "  FAIL: $1"; FAILS=$((FAILS + 1)); }
log_pass() { echo "  PASS: $1"; }

# Recreate a fresh sandbox repo. Each test calls this before setting up its scenario.
setup_sandbox() {
  rm -rf "$SANDBOX"
  mkdir -p "$SANDBOX"
  cd "$SANDBOX"
  git init -q
  git config user.email "test@test"
  git config user.name "Test"
}

make_commit() {
  local file="$1"
  local content="$2"
  local msg="$3"
  echo "$content" > "$file"
  git add "$file"
  git commit -q -m "$msg"
}

test_commits_last_10_fallback() {
  setup_sandbox
  # Create 3 commits. No archive → fallback 1 (24h) catches them.
  make_commit a.txt "hello" "feat: add a"
  make_commit b.txt "world" "feat: add b"
  make_commit c.txt "!"     "fix: tweak c"

  local out
  out="$("$SCRIPT")"

  if ! grep -q "===COMMITS===" <<< "$out"; then
    log_fail "COMMITS section missing"; return
  fi
  if ! grep -q "feat: add a" <<< "$out"; then
    log_fail "expected commit subject 'feat: add a' in output"; return
  fi
  if ! grep -q "feat: add b" <<< "$out"; then
    log_fail "expected commit subject 'feat: add b' in output"; return
  fi
  if ! grep -q "fix: tweak c" <<< "$out"; then
    log_fail "expected commit subject 'fix: tweak c' in output"; return
  fi
  log_pass "commits in last 24h are captured"
}

test_commits_last_10_fallback
test_status_section() {
  setup_sandbox
  make_commit a.txt "a" "init"
  echo "wip" > new.txt            # untracked
  echo "modified" >> a.txt        # unstaged mod

  local out
  out="$("$SCRIPT")"

  if ! grep -q "===STATUS===" <<< "$out"; then
    log_fail "STATUS section missing"; return
  fi
  if ! grep -q "new.txt" <<< "$out"; then
    log_fail "untracked file new.txt should appear in STATUS"; return
  fi
  log_pass "status section includes untracked/modified files"
}

test_todo_section_when_present() {
  setup_sandbox
  make_commit a.txt "a" "init"
  echo "- plan item one" > .daily-report.todo.md

  local out
  out="$("$SCRIPT")"

  if ! grep -q "===TODO===" <<< "$out"; then
    log_fail "TODO section missing"; return
  fi
  if ! grep -q "plan item one" <<< "$out"; then
    log_fail "TODO content not echoed"; return
  fi
  log_pass "todo section reads .daily-report.todo.md when present"
}

test_todo_section_absent_is_blank() {
  setup_sandbox
  make_commit a.txt "a" "init"

  local out
  out="$("$SCRIPT")"

  # TODO header present but empty (no crash, no content)
  if ! grep -q "===TODO===" <<< "$out"; then
    log_fail "TODO header missing when file absent"; return
  fi
  log_pass "todo section header present even when file absent"
}

test_prev_archive_section() {
  setup_sandbox
  make_commit a.txt "a" "init"
  mkdir -p .daily-reports
  echo "# Yesterday\n- old item" > ".daily-reports/2026-04-22.md"

  local out
  out="$("$SCRIPT")"

  if ! grep -q "===PREV_ARCHIVE===" <<< "$out"; then
    log_fail "PREV_ARCHIVE section missing"; return
  fi
  if ! grep -q "old item" <<< "$out"; then
    log_fail "prev archive content not echoed"; return
  fi
  log_pass "prev archive section reads latest .daily-reports/*.md"
}

test_extra_files_arg() {
  setup_sandbox
  make_commit a.txt "a" "init"
  echo "extra note body" > /tmp/extra-note.txt

  local out
  out="$("$SCRIPT" /tmp/extra-note.txt)"

  if ! grep -q "===EXTRA_FILES===" <<< "$out"; then
    log_fail "EXTRA_FILES section missing"; return
  fi
  if ! grep -q "extra note body" <<< "$out"; then
    log_fail "extra file content not echoed"; return
  fi
  log_pass "extra files from args included"

  rm -f /tmp/extra-note.txt
}

test_status_section
test_todo_section_when_present
test_todo_section_absent_is_blank
test_prev_archive_section
test_extra_files_arg
echo
echo "Failures: $FAILS"
[[ $FAILS -eq 0 ]]
