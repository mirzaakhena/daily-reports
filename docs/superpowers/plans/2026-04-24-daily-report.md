# `/daily-report` Build History

**Status:** Implemented
**Spec:** `docs/superpowers/specs/2026-04-24-daily-report-design.md`

This document is a record of how the tool was built. It is not a live plan — for current behaviour, read the spec and the source files directly.

## Architecture

A thin slash command (`commands/daily-report.md`) orchestrates:

1. A pure-bash context gatherer (`scripts/gather-context.sh`) that emits delimited sections (commits, status, branch, TODO, prev archive, metadata).
2. A skill (`skills/daily-report/SKILL.md`) that holds the style rules, template, and anti-fabrication guard.
3. A runtime step that prints + `pbcopy`s + archives the report to `.daily-reports/YYYY-MM-DD.md`.

`install.sh` copies the command + skill into `~/.claude/` (global) or `<repo>/.claude/` (project).

**Tech stack:** Bash (POSIX-leaning, macOS target), Markdown (skill/command bodies), git CLI, `pbcopy`.

## File responsibilities

- `scripts/gather-context.sh` — deterministic git + file context collector, emits plain-text delimited sections
- `scripts/test_gather_context.sh` — bash test harness for the gatherer
- `commands/daily-report.md` — slash command: frontmatter + prompt body that drives the model
- `skills/daily-report/SKILL.md` — style rules, template, anti-fabrication guard, generation procedure
- `skills/daily-report/examples.md` — synthetic illustrative reports
- `install.sh` — installer for global or project scope, manages `.daily-reports/` + `.gitignore`
- `scripts/test_install.sh` — bash test harness for the installer
- `README.md` — human-facing usage docs
- `.gitignore` — ignore sandbox/tmp dirs and per-project archives

## Build sequence

1. **Repo scaffolding** — directory layout, README, `.gitignore`.
2. **`gather-context.sh`** — built test-first, one section at a time:
   - Repo / date / branch metadata.
   - Commit selection with three-tier fallback (since-archive-mtime → last 24h → last 10 commits).
   - `git status`, TODO file, previous-archive, extra-files-from-args.
3. **`SKILL.md`** — locked template, style rules, anti-fabrication guard, generation procedure.
4. **`examples.md`** — synthetic reports illustrating density, verb choice, technical specificity, and the external-reader rule.
5. **`commands/daily-report.md`** — slash command body that invokes the skill, runs the gatherer, persists the archive, and pipes to `pbcopy`.
6. **`install.sh`** — built test-first, supports `--global` and project modes, manages `.daily-reports/` creation and idempotent `.gitignore` updates. Co-locates `gather-context.sh` with the skill at install targets so the command can find it at a predictable path regardless of scope.
7. **End-to-end smoke test** — manual verification in a scratch repo: install, run the gatherer standalone, run the slash command, confirm archive + clipboard + grounded bullets.

## Output template

See `skills/daily-report/SKILL.md` for the locked template and full style rules. Default counts are 5 bullets for `# Yesterday` and 3 bullets for `# Today`, overridable via the user's free prompt.

## Anti-fabrication

Every bullet must trace back to evidence in the context blob (commit, diff, file path, branch, status, TODO, previous archive) or the user's free prompt. The skill is instructed to produce a short honest report and flag thin context to the user rather than padding.

## Test coverage

- `scripts/test_gather_context.sh` — six tests covering each section emitted by the gatherer.
- `scripts/test_install.sh` — five tests covering project install, archive-dir creation, idempotent gitignore, and global install into a fake `$HOME`.
