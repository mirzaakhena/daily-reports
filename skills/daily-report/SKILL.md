---
name: daily-report
description: Use when generating a daily work report for posting to KakaoTalk (or similar). Invoked by the /daily-report slash command. Produces a KakaoTalk-ready plain-text report with a `# Yesterday` and `# Today` section, following a locked template and strict anti-fabrication rules.
---

# Generating a daily work report

## When this skill runs

You were invoked by the `/daily-report` slash command. The command has already run `scripts/gather-context.sh` and placed its output in the conversation. Your job is to turn that context (plus any free-form prompt from the user) into a paste-ready report.

## Template (locked)

Output exactly this shape, plain text, no markdown rendering assumed:

```
Hello, this is my daily report:

# Yesterday
- <action verb> <object> <short qualifier>
- ... (default 5 bullets)

# Today
- <action verb> <object> <short qualifier>
- ... (default 3 bullets)
```

No sub-project headers. Flat bullets within each section.

Counts are defaults. If the user's free prompt asks for a different count (e.g. "buat 7 yesterday, 4 today"), follow the user. Never pad to hit the default — anti-fabrication wins.

## Style rules

1. **One line per bullet, target 10–15 words.** Hard ceiling is the line; the word band is a tightness target. If a bullet exceeds 15 words, either split it into two bullets or strip qualifiers until it fits. If it falls below 10, it is fine — terse is allowed when the activity is genuinely small. Never pad to reach 10.

2. **Strong action verb to start each bullet.** Prefer: `Integrate`, `Implement`, `Research`, `Refactor`, `Debug`, `Review`, `Validate`, `Document`, `Profile`, `Fix`, `Add`, `Remove`, `Wire`, `Swap`, `Migrate`. Ban: `continue` — replace with the specific verb for what is being continued.

3. **Breakdown is granular but grounded.** One commit may expand into 2–4 bullets if the diff shows distinct sub-activities, but each bullet must trace back to evidence in the context: commit subject, commit body, diff file paths, branch name, `git status` entry, TODO file line, previous archive entry, or explicit user free-prompt text. **Never invent activities.**

4. **Non-coding work counts** when the context supports it: reviewing AI output, debugging integrations, researching docs, preparing environments. Signals: branch name, stash, unstaged changes, TODO entries, or free-prompt hints.

5. **Do not mention Claude Code or AI-assistance in bullets.** If a commit was AI-generated, the bullet still reads "Implement X".

6. **Technical terminology must be specific, not generalized.**
   - ✅ Name exact libraries, frameworks, tools, services that appear in context: `Postgres`, `Redis`, `JWT middleware`, `gRPC client`, `S3 lifecycle policy`, `OpenTelemetry exporter`.
   - ✅ Make migrations and version swaps explicit when the diff shows them: `swap bcrypt for argon2 in password hasher`, `migrate user table from MySQL 5.7 to 8.0`.
   - ✅ Use real module references that appear in file paths or commit messages: `auth/middleware`, `billing/invoice-renderer`, `pipeline/dlq-consumer`.
   - ❌ Do not sanitize to generic phrasing: not *"update library to newer version"*.
   - ❌ Do not over-explain — the reader is technical.
   - **Anti-fabrication guard**: specific terminology is only allowed when the exact token appears in the context (commit messages, diffs, file paths, branch names, TODO file, previous archive, free prompt). Never invent.

7. **Write for an external technical reader.** The audience is someone outside your day-to-day team (e.g. your boss, a peer in another department, a future open-source reader) who is technically literate but does **not** share the team's internal shorthand.
   - ❌ Internal process jargon: `opsi A`, `approach B`, `path 1`, `spike branch`, `the v2 plan`, `TASK-1234` (issue tracker IDs without context).
   - ❌ Codenames that only the team knows what they mean. If the codename appears in commits/branches and is self-explanatory or stands for a real feature/module, keep it. If it is an internal alias for a process step, drop it.
   - ❌ Phrasing that assumes shared standup context: `as discussed`, `the thing from yesterday`, `like we talked about`.
   - ✅ Each bullet must stand alone — a reader who has never seen the codebase should still understand *what was done* (even if not *why*).
   - When in doubt, replace internal shorthand with the concrete activity it represents (e.g. instead of `Continue option A`, write `Implement Redis-backed session store`).

8. **No filler words.** Skip `just`, `simply`, `a bit of`, `some`, `various`.

9. **`Today` must be grounded.** Populate it, in priority order, from:
   - Free-prompt hints ("besok mau X", "today X", "next X").
   - Unfinished items carried from the previous archive's `Today`.
   - TODO file entries.
   - Reasonable continuations of `Yesterday` — e.g., if `Yesterday` has `Add schema` and there is a visible integration task, `Today` may list `Wire schema into endpoint X`.
   - If all of the above are empty, ask the user rather than invent.

## Language and tone

- Default output language: **English**. If the free prompt is in another language (e.g., Indonesian), translate the output to English.
- Tone: professional and flat. No emoji. No markdown-fancy formatting (bold, italics, tables, code fences). KakaoTalk does not render rich markdown.
- Default length: **5 bullets** for `# Yesterday`, **3 bullets** for `# Today`. Soft target — if the user's free prompt requests different counts, follow the user. If commits are few and honest breakdown can't reach the default, produce fewer bullets rather than padding (anti-fabrication wins). If commits are many, group related tiny commits into one concise bullet.

## Generation procedure

Follow this procedure step by step:

1. **Parse the context blob.** Locate each `===SECTION===` header from `gather-context.sh`. Hold each section in mind:
   - `REPO`, `DATE`, `BRANCH`: framing
   - `COMMITS`: primary source for `Yesterday`
   - `STATUS`: work-in-progress hint, often relevant for `Today`
   - `TODO`: explicit plan hints for `Today`
   - `PREV_ARCHIVE`: continuity — what the user said yesterday they would do today
   - `EXTRA_FILES`: user-supplied notes

2. **Parse the user's free prompt.** Extract:
   - Commit hashes (merge into analysis).
   - File paths (read via the Read tool if not already in `EXTRA_FILES`).
   - `Today` hints.
   - Any project-name override.

3. **Draft `Yesterday`.** For each commit or coherent cluster of commits:
   - Identify the user-visible outcome (not the internal refactor detail).
   - Expand into 2–4 grounded sub-bullets if the diff supports distinct activities.
   - Rewrite with a strong action verb and specific terminology drawn from the commit.

4. **Draft `Today`.** Apply the priority ladder in rule 9.

5. **Self-check before emitting.**
   - Every bullet: does it trace to at least one piece of context? If not, remove it.
   - Every technical term: does the exact token appear in the context? If not, either remove the term or rephrase without it.
   - Counts: `Yesterday` at default 5, `Today` at default 3 (or the count the user requested). If below the target, expand via legitimate breakdown only. If above, consolidate small items. Never invent to hit the count.
   - Word count per bullet: 10–15 words target. Anything above 15 must be split or tightened. Below 10 is fine if honest.
   - External-reader check: would a reader outside your team understand each bullet in isolation? Strip internal process jargon (`opsi A`, `path 1`, `spike`) and replace with the concrete activity.
   - Verbs: any `continue`? Replace with a specific verb.
   - Fillers: any `just`, `simply`, `some`, `various`? Remove.

6. **Emit the final report** in the exact template shape. No preamble, no trailing commentary.

7. **Persist.** After printing the report:
   - Write it to `.daily-reports/YYYY-MM-DD.md` (using the `DATE` from the context blob; overwrite if the file exists).
   - Pipe it to `pbcopy` so it lands on the clipboard.

## When context is thin

If commits are fewer than 2, no TODO, no free prompt, no prev archive — do not pad. Produce a short honest report and explicitly flag to the user: *"Context was thin today — only N commits, no TODO, no free prompt. Consider passing hints via the free prompt."*

## Reference examples

See `examples.md` in this skill directory for annotated reference reports.
