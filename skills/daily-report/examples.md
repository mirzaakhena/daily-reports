# Reference reports (annotated)

These are **synthetic illustrative examples**, not real reports. Study the density, the verb choices, and the specificity of technical terms. They inform style only — never copy any content from them. Each bullet in your generated report must trace back to the actual context blob from `gather-context.sh` plus the user's free prompt.

All examples below follow the default counts: 5 bullets for `# Yesterday`, 3 bullets for `# Today`.

**Read example D first.** It demonstrates the preferred human voice (variable bullet length, multi-sentence narration where it earns its keep, casual hedges that carry meaning, no internal navigation tokens). Examples A–C are still valid for compact-mode reports but lean more uniform — when a day's activity has nuance, prefer D's voice.

---

## Example A — E-commerce backend

```
Hello, this is my daily report:

# Yesterday
- Implement Redis-backed session store behind the existing auth middleware
- Migrate user profile table from MySQL 5.7 to 8.0 with composite index
- Add idempotency key support to the order creation endpoint
- Debug intermittent 502s in checkout traced to gRPC client timeout
- Review and merge inventory reservation refactor PR

# Today
- Wire idempotency key into payment webhook handler
- Profile checkout endpoint under k6 load and capture p95 latency baseline
- Document new session store rotation procedure for the on-call runbook
```

**What to notice:**
- 5 yesterday, 3 today — matches default counts.
- Specific tokens grounded in (hypothetical) context: `Redis`, `MySQL 5.7 → 8.0`, `(tenant_id, email)` composite index, `gRPC client`, `k6`, `p95`.
- Action verbs: `Implement`, `Migrate`, `Add`, `Debug`, `Review`, `Wire`, `Profile`, `Document`.
- Non-coding work appears as a peer (PR review, runbook doc).
- No `continue`, no filler words, no internal jargon.
- A reader who has never touched the repo still understands what each bullet did.

---

## Example B — Data pipeline

```
Hello, this is my daily report:

# Yesterday
- Add dead-letter queue consumer to the events ingestion pipeline with exponential backoff
- Refactor schema validation step to fail fast on missing tenant_id rather than dropping silently
- Implement Parquet partition compaction job for the warehouse hourly bucket
- Investigate Kafka consumer lag spike on orders topic, traced to slow downstream sink
- Update Airflow DAG retry policy from 1 to 3 with 5-minute exponential backoff

# Today
- Validate compaction job end-to-end against staging warehouse with one day of replayed traffic
- Add OpenTelemetry spans around the schema validation step to expose per-record drop reasons
- Review pipeline observability dashboard with platform team
```

**What to notice:**
- Real file/module names you'd expect to see in this domain: `events ingestion pipeline`, `Parquet partition compaction job`, `orders topic`, `Airflow DAG`.
- Numeric specifics where they appear in context (`from 1 to 3`, `5-minute`, `one day`) — these are only acceptable when grounded in a commit, diff, or free-prompt mention.
- Mix of build / debug / investigate / review verbs.
- The investigation bullet is grounded enough to be useful (`traced to a slow downstream sink`) without inventing root-cause specifics.

---

## Example C — Mobile SDK

```
Hello, this is my daily report:

# Yesterday
- Implement retry-with-jitter wrapper around the SDK's network client for transient 5xx
- Add iOS background task handler so telemetry batches survive app suspension
- Fix cold-start crash when cached config is corrupt by falling back to bundled defaults
- Document public API surface for the new analytics module in the SDK README
- Review external integrator's reproduction repo for the reported memory leak

# Today
- Reproduce the reported memory leak in Instruments and capture allocation trace
- Add unit tests covering the corrupt-config fallback path
- Cut a 3.4.0-rc1 build for the integrator to validate the leak fix candidate
```

**What to notice:**
- Domain-specific specificity: `Instruments` (Apple profiler), `cold start`, `background task handler`, `3.4.0-rc1`.
- The investigation work (`Review external integrator's reproduction repo`) is reported as legitimate — it's not coding but it's grounded.
- `Today` directly continues `Yesterday`'s thread (review → reproduce → fix → ship rc), demonstrating rule 9's continuation pattern.

---

## Example D — ML inference service (preferred voice)

```
Hello, this is my daily report:

# Yesterday
- Stop the model warmup from blocking the readiness probe during deploys; the load balancer was killing pods before the model finished loading
- Patch the embedding service to fall back to the previous model version when the new one returns NaN, instead of returning a 500
- Switch feature-store reads from synchronous Redis calls to a small async batcher. Recommendation endpoint p95 dropped about 40 ms
- Document the on-call runbook for embedding service rollbacks
- Review the inference autoscaler PR and leave a couple of comments about cold-start ramp

# Today
- Ship the embedding fallback to staging, then watch the error rate for an hour or two before promoting
- Look at why the autoscaler's cold-start fix doesn't kick in for the largest model. Possibly related to startup probe timing — needs to be reproduced locally first
- Two flaky tests in the recommendation service kept failing on CI today. Either skip them or fix them properly tomorrow, depending on what the failure mode looks like in the morning
```

**What to notice:**
- Bullet length varies: short (10 words), medium (20), long-with-aside (25+, including a follow-up sentence). Reads like a real person reflecting, not a template.
- Casual hedges that carry meaning: `for an hour or two`, `Possibly related to`, `kept failing`, `depending on what... looks like in the morning`. None are filler — each tells you something about timing, certainty, or status.
- Multi-sentence bullets used where one fact deserves an aside (`Recommendation endpoint p95 dropped about 40 ms` after a setup sentence; the autoscaler bullet pairs a hypothesis with a planned next step).
- Non-uniform openers: most are action verbs, but `Two flaky tests in the recommendation service` opens with the subject because that reads more naturally than forcing a verb.
- Real outcomes named: `40 ms`, `p95`, `NaN`, `readiness probe`, `embedding service` — the same kind of specifics A–C use, but woven into sentences rather than tacked on as qualifiers.
- A bullet admits uncertainty (`Either skip them or fix them properly tomorrow`). Honest > polished.
- No commit hashes, no branch names, no MR numbers, no internal file paths or function names. The reader gets architecture + decisions, not navigation.

---

## Anti-pattern A — internal process jargon

```
# Yesterday
- Continue option A from yesterday
- Work on the v2 plan
- Some refactoring on the auth thing
- Just a quick fix to the spike branch
- Discussion with team about path 1 vs path 2
```

**Why this fails:**
- `Continue option A` — internal process shorthand; no external reader knows what `option A` is.
- `the v2 plan` — assumes shared standup context.
- `the auth thing`, `a quick fix`, `some refactoring` — vague, generic, filler-laden.
- `spike branch` — internal codename for a process step; replace with what the spike was actually exploring (e.g., `Prototype OAuth device-flow login in the auth service`).
- `path 1 vs path 2` — pure internal jargon. Either drop the bullet or describe the substantive activity (`Compare cost of in-process vs sidecar telemetry collection`).
- Multiple bullets start with `Continue` or filler verbs.

A bullet should still make sense to a reader pulled in cold. If it doesn't, rewrite it as the concrete activity.

---

## Anti-pattern B — AI-uniform voice

```
# Yesterday
- Implement Redis-backed caching layer for session lookups
- Refactor authentication middleware to support OAuth flows
- Add comprehensive test coverage for the payment processing module
- Migrate database schema from version 5 to version 8
- Document API endpoints for the new analytics dashboard

# Today
- Continue work on Redis caching layer integration
- Begin OAuth flow testing across all environments
- Schedule code review for the database migration
```

**Why this fails the voice check** — even though every individual rule on technical specificity passes:

- Every bullet starts with a strong action verb followed by a technical noun phrase. Same shape, ten times in a row.
- Every bullet lands in the 9–13 word range. Same beat, same rhythm.
- No multi-sentence bullets, no parentheticals, no hedges, no admissions of uncertainty.
- `Today` opens two of three bullets with `Continue` and `Begin` — both AI tells; the actual activity is hidden.
- Reads like a feature-list press release, not a person reporting their day.

The fix is not to drop technical specificity. It's to break the rhythm: vary length, allow the occasional fragment or two-sentence bullet, surface what didn't go well, name the moments where a decision was deferred. See Example D for what that looks like.

---

## Anti-pattern C — internal navigation leaking into bullets

```
# Yesterday
- Land commit 6591a0c fixing _resolve_env in agents/free-code/swe_bench_main.py
- Open MR #142 on feat/refactor-billing branch with 8 commits
- Update app/services/swe_bench_agent.py:152 to use absolute host path
```

**Why this fails:** the reader is your boss, not someone navigating your repo. Strip:
- `commit 6591a0c` → just describe the fix
- `MR #142 on feat/refactor-billing` → "open the billing-refactor merge request"
- `app/services/swe_bench_agent.py:152`, `_resolve_env` → name the activity, not the line

Rewritten:

```
- Fix the model-name override being silently ignored by the free-code wrapper
- Open the billing-refactor merge request for review
- Switch the agent workspace path resolution to an absolute host path so disk-backed mounts can replace the in-memory tmpfs
```

The internal token belongs in the commit message and the merge request description. The daily report is a different document for a different reader.

---

## Common patterns across the examples

- Technical names and version numbers are surfaced — but only when they appear in the actual context blob.
- Action verbs are explicit and varied: `Implement`, `Migrate`, `Add`, `Debug`, `Refactor`, `Investigate`, `Profile`, `Document`, `Validate`, `Review`, `Wire`, `Fix`, `Cut`. Not every bullet has to lead with one — Example D opens a bullet with the subject when that reads more naturally.
- Non-coding work (reviews, investigations, docs, runbooks, meetings) is reported alongside coding work.
- Each bullet reads independently of any team-internal context — and stripped of internal navigation tokens (commit hashes, branch names, MR numbers, function names, file paths).
- Bullet length varies on purpose. A column of identical 12-word bullets reads templated; a mix of short, medium, and occasionally multi-sentence bullets reads human.
- `Today` flows from `Yesterday` plus free-prompt hints, not invented from scratch. Honest deferrals and uncertainties belong here as much as confirmed plans.
