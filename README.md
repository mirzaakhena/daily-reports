# daily-report

Slash command + skill for Claude Code that turns recent git activity and free-form notes into a KakaoTalk-ready daily work report.

## Install

Global (works in any repo):
```bash
./install.sh --global
```

Project (overrides global inside this repo only):
```bash
./install.sh
```

## Use

From inside a repo with git history:

```
/daily-report
/daily-report tomorrow plan: finish auth integration tests
/daily-report focus on commits abc123 def456
/daily-report also read ./notes.md
```

The free-form prompt is optional. It accepts:
- `Today` hints (e.g. "tomorrow plan: ...")
- Specific commit hashes to focus on
- File paths to fold into the context

Output is printed, copied to clipboard (`pbcopy`), and archived to `.daily-reports/YYYY-MM-DD.md`.

## Sample output

[`examples/2026-04-24.md`](examples/2026-04-24.md) is a real report produced by this tool — meta-flavoured, since it documents the day this tool was itself being built. It shows the on-disk archive format and the bullet style the skill aims for.

Note: the sample predates the current default counts (5 bullets for `# Yesterday`, 3 for `# Today`) and shows higher counts; defaults can be overridden anyway via the free prompt (e.g. `/daily-report make it 7 yesterday and 4 today`).

For style references the skill reads at generation time, see [`skills/daily-report/examples.md`](skills/daily-report/examples.md) — three synthetic illustrative reports plus an anti-pattern.

## Requirements

- macOS (uses `pbcopy`)
- git
- Claude Code

## Design & plan

- Spec: `docs/superpowers/specs/2026-04-24-daily-report-design.md`
- Plan: `docs/superpowers/plans/2026-04-24-daily-report.md`
