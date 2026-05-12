---
description: Generate a weekly status report across active client projects under clients/ — wins, blockers, next steps.
argument-hint: "[client-slug | all]"
---

# /weekly-report — Weekly client status report

Generate a concise weekly status report for active client engagements. The report is intended for the freelancer's own records and for forwarding (lightly edited) to clients.

## Workflow

### 1 · Determine scope

- If `$ARGUMENTS` is a client slug (e.g., `acme-health-co`), scope the report to that one client.
- If `$ARGUMENTS` is `all` or empty, scope to **every** subdirectory under `clients/`.
- If `clients/` does not exist, report that and exit cleanly.

### 2 · Collect signals per client

For each in-scope client, gather (read-only, no shell side effects):

| Signal | How |
|--------|-----|
| **Engagement summary** | First blockquote in `clients/<slug>/README.md` or `clients/<slug>/00-brief/brief.md` |
| **Files touched this week** | `find clients/<slug> -type f -mtime -7` |
| **Latest deliverables** | Newest files under `03-deliverables/` |
| **Open notes / decisions** | Tail of `05-communications/` markdown files |
| **Brief reminders** | Timeline + Success Metrics rows from the brief |

If any signal is missing, write `_(no activity)_` for that client section — never fabricate progress.

### 3 · Write the report

Save the report to:

```
reports/weekly-<YYYY-MM-DD>.md
```

(Use today's date. If that file already exists, append `-2`, `-3`, etc.)

Use this template:

````markdown
# Weekly Status Report — Week of <YYYY-MM-DD>

> Across <N> active client engagement(s).

## Executive summary

- <2-4 bullets summarizing the week across all clients>

---

## <Client Name> — `<slug>`

**Engagement:** <one-line summary from brief>

### ✓ Wins this week
- <bullet>

### ⏳ In progress
- <bullet>

### 🚧 Blockers
- <bullet, or "_(none)_">

### → Next week
- <bullet>

### Files touched (last 7 days)
- `path/to/file.md` — <one-line note>

---

<repeat per client>

---

## Footer

- Report generated: <YYYY-MM-DD HH:MM>
- Clients covered: <comma-separated slugs>
- Brief sources: `clients/<slug>/00-brief/brief.md`
````

### 4 · Report back

End the command by:
- Linking the generated report file
- Listing which clients were covered
- Surfacing any client with **zero activity in 7 days** as a "needs attention" callout

## Edge cases

- **Stale brief**: if a brief is older than 90 days, note "Brief is over 90 days old — consider re-onboarding" in that client's section.
- **No `clients/` yet**: emit a clear message: "No client workspaces found at `clients/`. Run `/onboard-client <name>` first."
- **Empty subdirectory**: if `clients/<slug>/` exists but is empty, still include the client with a "_(no activity)_" section.
- **Single-client run**: when scoped to one slug, skip the "Executive summary" section header but keep the per-client structure intact.
