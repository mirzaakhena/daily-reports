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

## What "Yesterday" and "Today" actually mean

**The report is typically written at end-of-day and posted the following morning.** Anchor `Yesterday` and `Today` to the **posting moment**, not the writing moment. From the morning reader's perspective:

- **`Yesterday`** = the work session being reported. In practice this is **the session you just finished** when generating the report. The bullets describe what was actually done — completed work, fixes shipped, decisions made, items deferred.
- **`Today`** = the next session, the upcoming day's plan. The bullets describe what you intend to do next — usually drawn from the just-finished session's open backlog, the latest handoff's "next session goal", TODO entries, or explicit free-prompt hints.

Common mistakes to avoid:

- ❌ Writing `Yesterday` from the *writing* moment so it captures the previous calendar day's session and `Today` ends up describing the session you just finished. That report is one day stale by the time it's posted.
- ❌ Treating `Today` as a continuation of writing-time activity ("what I'm doing right now"). It is forward-looking.
- ✅ When in doubt: ask "if the reader opens this tomorrow morning, will the bullets make sense as 'what happened yesterday' and 'what's planned for today'?" — if not, shift the content one slot.

If the user explicitly says they will post the report at a different time (e.g., immediately, or after a multi-day gap), follow that — but the default convention is next-morning posting and the anchoring rule above applies.

## Style rules

1. **Vary bullet length on purpose.** A short 6-word bullet next to a longer 25-word multi-sentence bullet reads like a person. A column of identical 12-word bullets reads like a template. Aim for a mix: some terse, some narrative, occasionally one with a parenthetical aside or a follow-up sentence ("...; the second attempt got set aside" / "Hermes passed first time. The other four each broke for a different reason — ..."). Never pad to a target.

2. **Strong action verb is the default opener, not a rule.** Most bullets do start with one (`Implement`, `Migrate`, `Debug`, `Refactor`, `Profile`, `Fix`, `Wire`, `Swap`). But not every bullet has to — when it reads more naturally, start with the subject ("Two agents still fail because..."), a hedge ("Held off on..."), or a state-of-the-world fact ("The remaining flaky tests..."). Ban only `continue` — replace with the specific verb for what is being continued.

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

7. **Write for an external technical reader (think: your boss).** Technically literate, follows the architecture in broad strokes, but does **not** share the team's day-to-day shorthand and does not need to debug from the report. Keep what's meaningful at architecture/feature level; strip what's only useful for navigating the repo.
   - ❌ Strip from bullets even when the context contains them:
     - Commit hashes / SHAs (`6591a0c`, `267b43e`)
     - Branch names (`feat/phase4-swe-bench-agent`, `feature/foo`)
     - Merge request / PR / issue numbers (`MR #3`, `PR #142`, `JIRA-1234`)
     - File paths and function names with internal shape (`app/services/swe_bench_agent.py:152`, `_resolve_env`, `_load_benchmarks`, `_lib/swe_bench_react.py`)
     - Internal endpoint URLs, IPs, container names (`a100gemma.acciox.dev`, `192.168.1.73`, `alif-benchmach-orchestrator`)
   - ❌ Internal process jargon: `opsi A`, `approach B`, `path 1`, `spike branch`, `the v2 plan`, `TASK-1234`.
   - ❌ Phrasing that assumes shared standup context: `as discussed`, `the thing from yesterday`, `like we talked about`.
   - ✅ Keep meaningful concept names that describe *what* a feature is, even if internal: `the SWE-bench wrapper`, `the embedding fallback`, `the dead-letter queue consumer`. Names of agents, services, benchmarks (`Hermes`, `Django 11087`, `claw-code`, `sonnet`) usually belong — they're identifiers, not jargon.
   - ✅ Each bullet must stand alone — a reader who has never seen the repo still understands *what was done* (even if not the line-by-line *how*).
   - When in doubt, replace internal navigation detail with the activity it represents: instead of "fix `_resolve_env` priority in `swe_bench_main.py`", write "fix the model-name override being silently ignored".

8. **Cut empty filler. Keep meaningful casual phrasing.**
   - ❌ Cut: `just`, `simply`, `a bit of`, `some`, `various`, `kind of`, `sort of`. These add no information.
   - ✅ Keep: hedges and texture words that carry meaning — `for now`, `first time`, `got set aside`, `still`, `for two days`, `parked for the next session`, `or two`. These signal time, status, or uncertainty a real person would name.

9. **`Today` is forward-looking and must be grounded.** Remember `Today` describes the next session, not what was just finished (see "What 'Yesterday' and 'Today' actually mean"). Populate it, in priority order, from:
   - Free-prompt hints ("besok mau X", "today X", "next X").
   - The latest handoff's `Section 6` ("Apa yang Akan Dikerjakan di Sesi Berikutnya"), if a `.handoff/` file was generated this session.
   - Unfinished items carried from the previous archive's `Today`.
   - TODO file entries.
   - Reasonable continuations of `Yesterday` — e.g., if `Yesterday` has `Add schema` and there is a visible integration task, `Today` may list `Wire schema into endpoint X`.
   - If all of the above are empty, ask the user rather than invent.

10. **Voice: a developer giving a quick standup, not a press release.**
    - Mix sentence lengths within and across bullets.
    - A bullet may be one sentence, a fragment, or two short sentences — pick what matches the activity. Multi-sentence bullets are fine when one fact deserves an aside ("Hermes passed first time. The other four each broke for a different reason...").
    - Use contractions if you'd say it that way out loud (`don't`, `didn't`, `we'd`).
    - Don't end every bullet on the same beat. If three in a row close on a quantitative outcome, break the pattern with a status line, a parenthetical, or a hedged claim.
    - Things going wrong, decisions being made, items deferred — those are part of an honest day. Surface them. A report that's all green outcomes reads like marketing copy.

## Language and tone

- Default output language: **English**. If the free prompt is in another language (e.g., Indonesian), translate the output to English.
- Voice: technically-literate human writing a quick end-of-day update, not a polished announcement. Plain text, no emoji, no markdown-fancy formatting (bold, italics, tables, code fences). KakaoTalk does not render rich markdown.
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

3. **Draft `Yesterday`** (the just-finished session — what actually happened). For each commit or coherent cluster of commits:
   - Identify the user-visible outcome (not the internal refactor detail).
   - Expand into 2–4 grounded sub-bullets if the diff supports distinct activities.
   - Rewrite with a strong action verb and specific terminology drawn from the commit. Surface deferrals and items that didn't work too — those are part of an honest day.

4. **Draft `Today`** (the upcoming session — what's planned next, anchored to next-morning posting). Apply the priority ladder in rule 9. If a `.handoff/` markdown was generated this session, its Section 6 ("Apa yang Akan Dikerjakan di Sesi Berikutnya") is the strongest source.

5. **Self-check before emitting.**
   - Every bullet: does it trace to at least one piece of context? If not, remove it.
   - Every technical term: does the exact token appear in the context? If not, either remove the term or rephrase without it.
   - Counts: `Yesterday` at default 5, `Today` at default 3 (or the count the user requested). If below the target, expand via legitimate breakdown only. If above, consolidate small items. Never invent to hit the count.
   - Bullet length variation: scan the column. Are most bullets within ±3 words of each other? If yes, the report reads templated — break the rhythm by splitting one into two short bullets, merging two into a multi-sentence bullet, or trimming a long one to a fragment.
   - Boss-readable strip: any commit hash, branch name, MR/PR number, internal file path, function/variable name with underscores, or internal endpoint URL inside a bullet? Strip and rephrase as the activity that name represents.
   - External-reader check: would a reader outside your team understand each bullet without opening the repo? Replace internal process jargon (`opsi A`, `path 1`, `spike`) with the concrete activity.
   - Verbs: any `continue`? Replace with a specific verb.
   - Fillers vs texture: any `just`, `simply`, `some`, `various`, `kind of`? Remove. Hedges that carry meaning (`for now`, `first time`, `got set aside`, `still`) stay.
   - Voice check: read the report aloud. Does it sound like a developer giving a 5-minute update, or like a press release? If everything is in the same sentence shape and same beat, break the pattern.
   - Anchoring check: imagine the reader opens this tomorrow morning. Does `Yesterday` describe what was actually done in the just-finished session, and does `Today` describe what's planned next? If `Today` accidentally captures activity the writer just finished, shift everything one slot.

6. **Emit the final report** in the exact template shape. No preamble, no trailing commentary.

7. **Persist.** After printing the report:
   - Write it to `.daily-reports/YYYY-MM-DD.md` (using the `DATE` from the context blob; overwrite if the file exists).
   - Pipe it to `pbcopy` so it lands on the clipboard.

## When context is thin

If commits are fewer than 2, no TODO, no free prompt, no prev archive — do not pad. Produce a short honest report and explicitly flag to the user: *"Context was thin today — only N commits, no TODO, no free prompt. Consider passing hints via the free prompt."*

## Reference examples

See `examples.md` in this skill directory for annotated reference reports.
