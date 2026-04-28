# Design — `/daily-report` slash command

**Status:** Implemented
**Date:** 2026-04-24

## 1. Problem

Many engineers are required to post a daily work report to a team channel (KakaoTalk, Slack, email) summarising what was done yesterday and planned for today. Common failure modes:

1. **Granularity gap.** A single git commit often represents several distinct sub-activities (research → design → implement → debug → review). When the report collapses each commit into one bullet, the day looks artificially thin.
2. **Verb erosion.** `Continue`, `work on`, and `some refactoring` creep in over time, hiding the substance of the work.
3. **Internal jargon leaks.** Phrases like `option A`, `the v2 plan`, or `path 1` are meaningful inside the team but opaque to a reader outside it (a manager, a peer in another department, an open-source onlooker).

The goal of this tool is **not** to fabricate work — it is to **surface the granularity of work already done**, in language a technical reader outside the immediate team can follow, while strictly enforcing that every bullet trace back to real evidence (commits, diffs, branch, status, TODO, previous archive, or explicit user prompt).

## 2. Non-goals

- Cross-repo aggregation. The tool runs once per repo. Multi-repo days are merged manually.
- Auto-posting / scheduling. Output ends at terminal preview + system clipboard + on-disk archive.
- Cross-platform clipboard. macOS only for v1 (`pbcopy`).
- Morning/evening/weekend auto-detection. The tool reports "what was done" against "what is planned next" regardless of wall clock.

## 3. User flow

Typical scenario — engineer wraps up a coding day, runs the command from inside the project repo:

```
$ /daily-report tomorrow plan: validate end-to-end and ship rc1
```

1. Command runs the context gatherer (git log, git status, branch, optional TODO file, previous day's archive).
2. The free-form prompt is folded in as `Today` hints and optional commit/file references.
3. The skill produces a report following the locked template and style rules.
4. Output is printed to the terminal, copied to the system clipboard, and archived to `.daily-reports/YYYY-MM-DD.md`.
5. The engineer pastes the result into their team channel.

## 4. File layout

```
daily-report-slash-commands/
├── commands/
│   └── daily-report.md          # slash command frontmatter + prompt body
├── skills/
│   └── daily-report/
│       ├── SKILL.md             # style rules, template, generation procedure
│       └── examples.md          # synthetic illustrative reports
├── scripts/
│   └── gather-context.sh        # invoked by the command to collect git context
├── install.sh                   # copies into ~/.claude/ or <repo>/.claude/
├── README.md
└── docs/superpowers/
    ├── specs/2026-04-24-daily-report-design.md   # this file
    └── plans/2026-04-24-daily-report.md          # build history
```

### 4.1 Install targets

`install.sh` supports two modes, matching Claude Code conventions:

- **Global**: `./install.sh --global` → copies command + skill to `~/.claude/commands/` and `~/.claude/skills/daily-report/`. Works in any repo.
- **Project**: `./install.sh` run from inside a target repo → copies to `<repo>/.claude/commands/` and `<repo>/.claude/skills/daily-report/`. Overrides global when both exist.

The installer also (project mode only):

- Creates `<repo>/.daily-reports/` if it does not exist.
- Appends `.daily-reports/` to `<repo>/.gitignore` if not already present.

`gather-context.sh` is co-located with the skill at install targets so the command can find it at a predictable path regardless of install scope.

## 5. Command contract

### 5.1 Invocation

```
/daily-report [free-form prompt]
```

The free-form prompt is parsed by the skill as natural language. There are no required flags. Valid examples:

- `/daily-report`
- `/daily-report tomorrow plan: finish auth integration tests`
- `/daily-report focus on commits abc123 def456`
- `/daily-report also read ./notes.md`
- `/daily-report make it 7 yesterday and 4 today`

The skill extracts the following from the free prompt when present:

- **Commit hashes** — added to the set of commits under analysis.
- **File paths** — read as additional context.
- **Today-section hints** — phrases like "tomorrow plan", "today", "next" are treated as plan items.
- **Project-name override** — `project=<name>` overrides the inferred project name.
- **Count override** — phrases like "make it 7 and 4" override the default counts.

### 5.2 Auto-gathered context (no flags needed)

The command always scans:

1. **Git commits** — selection strategy, in order:
   - Primary: commits since the file modification time of the most recent file in `.daily-reports/`.
   - Fallback 1: commits in the last 24 hours (used when no archive exists).
   - Fallback 2: the 10 most recent commits (used when both primary and fallback 1 yield fewer than 2 commits).
2. **`git status`** — unstaged and untracked files, as a signal for work in progress.
3. **Current branch name** — as a soft hint for what the engineer is actively working on.
4. **`.daily-report.todo.md`** at the repo root, if it exists — manual notes.
5. **Previous archive** at `.daily-reports/<latest>.md`, if it exists — used for narrative continuity (today's "Yesterday" may echo yesterday's "Today").

### 5.3 Output

Three sinks, all fired on every successful run:

1. **Terminal** — full report printed verbatim, as a preview.
2. **Clipboard** — piped through `pbcopy` (macOS). Cross-platform support is out of scope for v1.
3. **Archive** — written to `<repo>/.daily-reports/YYYY-MM-DD.md`. Filename uses the local date at the time of invocation. If the file already exists, it is overwritten (each day's report is authoritative; re-runs are idempotent-ish).

## 6. Report template

Locked output shape (plain text, no markdown rendering assumed):

```
Hello, this is my daily report:

# Yesterday
- <action verb> <object> <short qualifier>
- ... (default 5 bullets)

# Today
- <action verb> <object> <short qualifier>
- ... (default 3 bullets)
```

Flat bullets. No sub-project headers — the design favours simplicity within a single repo.

Counts are defaults. The user's free prompt can override both.

## 7. Style rules (encoded in SKILL.md)

1. **One line per bullet, target 10–15 words.** Bullets above 15 words must be split or tightened. Below 10 is fine when honest; never pad.
2. **Start with a strong action verb.** `Integrate`, `Implement`, `Research`, `Refactor`, `Debug`, `Review`, `Validate`, `Document`, `Profile`, `Fix`, `Add`, `Remove`, `Wire`, `Swap`, `Migrate`. Avoid `continue` — replace with the specific verb for what is being continued.
3. **Breakdown is granular but grounded.** One commit may expand to 2–4 bullets, but each bullet must have a basis in the commit diff, message, file paths, branch name, status output, TODO file, or user-supplied free prompt. No invented activities.
4. **Non-coding work counts.** Reviewing PRs, debugging integrations, researching docs, preparing environments, onboarding — all are legitimate bullets when the context supports them (branch name, stash, unstaged changes, free prompt).
5. **Do not mention AI assistance in bullets.** If the commit was AI-generated, the bullet still reads "Implement X" — the engineer supervised and shipped.
6. **Technical terminology must be specific, not generalized**, but only when the exact token appears in the context (commit messages, diffs, file paths, branch names, TODO file, previous archive, free prompt). Never invented.
7. **Write for an external technical reader.** The audience is someone outside the day-to-day team — technically literate but not sharing the team's internal shorthand. Drop process jargon (`option A`, `the v2 plan`, `path 1`, `spike`) and replace with the concrete activity. Each bullet must stand alone.
8. **No filler words.** Skip `just`, `simply`, `a bit of`, `some`, `various`.
9. **`Today` must be grounded.** Populated, in priority order, from:
   - Free-prompt hints.
   - Unfinished items carried over from the previous archive's `Today`.
   - TODO file entries.
   - Reasonable continuations of `Yesterday`.
   - If all of the above are empty, the skill asks the user explicitly rather than inventing plans.

**Language:** English by default. If the free prompt is in another language, the skill translates content to English.

**Tone:** Professional, flat, no emoji, no markdown-fancy formatting. The target channel does not render rich markdown.

**Default length:** 5 bullets for `# Yesterday`, 3 bullets for `# Today`. Soft target — if commits are few and honest breakdown can't reach the default, produce fewer bullets rather than padding.

## 8. Anti-fabrication safeguards

The tool's legitimacy depends on "surfacing granularity of real work", not inventing work. Safeguards:

- Every bullet must trace back to at least one of: commit message, diff, file path, branch name, `git status` entry, TODO file line, previous-archive entry, or explicit user free-prompt text.
- The skill is explicitly instructed that fabricating activities or technical terms not in the context is prohibited.
- When context is thin (few commits, no TODO, no prompt), the skill produces a short report and flags it to the user rather than padding.

## 9. Open questions / deferred

- **Cross-platform clipboard.** macOS only for v1 (`pbcopy`). Linux (`xclip`/`wl-copy`) and Windows (`clip`) deferred.
- **Weekly / monthly rollup.** The archive folder makes this trivial to add later but it's out of scope for v1.
- **Report editing UX.** V1 writes the archive directly. A future iteration could open the archive in `$EDITOR` before copying to clipboard.

## 10. Success criteria

- Running `/daily-report` in a repo with a day's worth of commits produces a report at the default 5/3 counts within ~10 seconds.
- The clipboard contains a paste-ready report immediately after the command completes.
- Across repeated usage, no bullet in any archived report references a tool, model, or module that did not exist in the commit context.
- Output is comprehensible to a technical reader who has never seen the codebase.
