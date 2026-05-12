---
name: client-brief-generator
description: Use when the user mentions creating, writing, drafting, or starting a client brief — gathers ten standard intake fields and saves a clean markdown brief to client-briefs/<client-name>-brief.md. Triggers on phrases like "client brief", "new client brief", "draft a brief", "intake for [client]", "onboarding doc for [client]".
---

# Client Brief Generator

Use this skill when the user wants to create or draft a client brief for a new engagement. It gathers ten standard intake fields, then writes a clean markdown brief to disk for the freelancer's records.

## When to use

Trigger on phrases like:
- "Create a client brief for [name]"
- "New client brief"
- "Draft a brief for [client]"
- "Start the intake for [client]"
- "Onboarding doc for [client]"

Do **not** use this for: existing-client status updates, project recaps, or proposal documents (those are separate workflows).

## The ten intake fields

Collect all ten before writing the file. Use `AskUserQuestion` to gather them in batches of up to 4 questions per call. Don't ask one at a time — group sensibly.

| # | Field | What it captures |
|---|-------|------------------|
| 1 | **Client / Brand Name** | The legal or brand-facing name (used for the filename and brief title) |
| 2 | **Industry** | The sector / vertical (e.g., DTC apparel, B2B SaaS, healthtech) |
| 3 | **Services Needed** | What the freelancer is delivering (e.g., content strategy, social posts, brand identity) |
| 4 | **Target Audience** | Primary customer/persona the client is trying to reach |
| 5 | **Brand Voice** | Tone descriptors (e.g., warm + irreverent, premium minimal, technical authority) |
| 6 | **Platforms** | Where the work lives (Instagram, LinkedIn, X, TikTok, web, email, podcast, etc.) |
| 7 | **Budget Range** | Engagement size (hourly rate, project fee, monthly retainer, or a $ range) |
| 8 | **Timeline** | Start date, key milestones, end date, or "ongoing retainer" |
| 9 | **Competitors (2–3)** | Brands the client benchmarks against or wants to differentiate from |
| 10 | **Success Metrics** | How the engagement will be judged (KPIs, deliverables, growth targets) |

## How to gather

1. Confirm the **client name** first — it determines the filename and brief title.
2. Group the remaining nine fields across **2–3 AskUserQuestion calls** (max 4 questions per call). Suggested grouping:
   - **Call A** (positioning): Industry, Services Needed, Target Audience, Brand Voice
   - **Call B** (logistics): Platforms, Budget Range, Timeline
   - **Call C** (context): Competitors, Success Metrics
3. For free-form fields (Services Needed, Target Audience, Competitors, Success Metrics), offer a multi-select where possible AND let the user override via "Other" to provide a custom value.
4. **Never invent answers.** If the user skips a field, write "_(not specified)_" rather than guessing.

## Output format

After all ten fields are collected, write the brief to:

```
client-briefs/<client-name-slug>-brief.md
```

Where `<client-name-slug>` is the client name lowercased, spaces and special characters replaced with hyphens (e.g., "Acme Health Co." → `acme-health-co`).

Use this exact template:

````markdown
# Client Brief — <Client/Brand Name>

> Engagement brief · Generated <YYYY-MM-DD>

| Field | Detail |
|-------|--------|
| **Client / Brand Name** | <value> |
| **Industry** | <value> |
| **Services Needed** | <value> |
| **Target Audience** | <value> |
| **Brand Voice** | <value> |
| **Platforms** | <value> |
| **Budget Range** | <value> |
| **Timeline** | <value> |
| **Competitors** | <value> (2–3 entries) |
| **Success Metrics** | <value> |

---

## Notes

_Free-form notes and follow-ups go here._
````

## Workflow checklist

- [ ] Confirm client name
- [ ] Gather 9 remaining fields via 2–3 grouped `AskUserQuestion` calls
- [ ] Create `client-briefs/` directory if it doesn't exist (`mkdir -p client-briefs`)
- [ ] Slug the client name for the filename
- [ ] Write the brief using the template above
- [ ] Report the file path back to the user with a clickable markdown link
- [ ] If the file already exists, ask before overwriting

## Edge cases

- **Duplicate brief**: If `client-briefs/<slug>-brief.md` already exists, surface that and ask whether to overwrite, append a date suffix, or cancel.
- **Partial input**: If the user explicitly says "skip" or "I don't know yet" for a field, write `_(not specified)_` in that row — do not infer or invent.
- **Multiple competitors**: List 2–3 competitors comma-separated on a single row, or as a nested bullet list inside the cell if the user provides extra context per competitor.
