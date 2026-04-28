# Reference reports (annotated)

These are **synthetic illustrative examples**, not real reports. Study the density, the verb choices, and the specificity of technical terms. They inform style only — never copy any content from them. Each bullet in your generated report must trace back to the actual context blob from `gather-context.sh` plus the user's free prompt.

All examples below follow the default counts: 5 bullets for `# Yesterday`, 3 bullets for `# Today`.

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

## Anti-pattern — what NOT to write

```
# Yesterday
- Continue option A from yesterday
- Work on the v2 plan
- Some refactoring on the auth thing
- Just a quick fix to the spike branch
- Discussion with team about path 1 vs path 2
```

**Why this fails every rule:**
- `Continue option A` — internal process shorthand; no external reader knows what `option A` is.
- `the v2 plan` — assumes shared standup context.
- `the auth thing`, `a quick fix`, `some refactoring` — vague, generic, filler-laden.
- `spike branch` — internal codename for a process step; replace with what the spike was actually exploring (e.g., `Prototype OAuth device-flow login in the auth service`).
- `path 1 vs path 2` — pure internal jargon. Either drop the bullet or describe the substantive activity (`Compare cost of in-process vs sidecar telemetry collection`).
- Multiple bullets start with `Continue` or filler verbs.

A bullet should still make sense to a reader pulled in cold. If it doesn't, rewrite it as the concrete activity.

---

## Common patterns across the examples

- Technical names and version numbers are surfaced — but only when they appear in the actual context blob.
- Action verbs are explicit and varied: `Implement`, `Migrate`, `Add`, `Debug`, `Refactor`, `Investigate`, `Profile`, `Document`, `Validate`, `Review`, `Wire`, `Fix`, `Cut`.
- Non-coding work (reviews, investigations, docs, runbooks, meetings) is reported alongside coding work.
- Each bullet is one line and reads independently of any team-internal context.
- `Today` flows from `Yesterday` plus free-prompt hints, not invented from scratch.
