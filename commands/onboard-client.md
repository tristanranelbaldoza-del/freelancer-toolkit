---
description: Walk through new client onboarding — gather info, generate a brief, and scaffold project folders.
argument-hint: "[client name]"
---

# /onboard-client — New client onboarding workflow

Run the full onboarding sequence for a new freelance client. Produces a brief, scaffolds working directories, and leaves the project ready for the first deliverable.

## Workflow

### 1 · Confirm the client name

If `$ARGUMENTS` is non-empty, use it as the client name. Otherwise ask the user.

Compute the slug: lowercase, spaces → hyphens, strip non-alphanumeric characters except hyphens. Example: "Acme Health Co." → `acme-health-co`.

### 2 · Generate the client brief

Invoke the **client-brief-generator** skill to gather the ten standard intake fields and produce `client-briefs/<slug>-brief.md`. Do not duplicate that flow here — defer to the skill.

If the brief already exists, ask whether to (a) reuse it as-is, (b) regenerate from scratch, or (c) append today's date suffix.

### 3 · Scaffold project folders

After the brief is saved, create this directory tree at the project root:

```
clients/<slug>/
├── 00-brief/              ← symlink or copy of client-briefs/<slug>-brief.md
├── 01-research/           ← competitor + audience research
├── 02-strategy/           ← positioning, content pillars, calendars
├── 03-deliverables/       ← actual work product (drafts, finals)
├── 04-assets/             ← logos, photos, brand references
├── 05-communications/     ← meeting notes, email threads, decisions
└── README.md              ← quick-jump index, links to brief + key dates
```

Use a single `mkdir -p` to create the tree in one call. After mkdir, write the `README.md` with:
- H1 title: `<Client Name> — Project Workspace`
- A short blockquote with the engagement summary pulled from the brief
- A table linking to each subdirectory and the brief
- A "Status" section seeded with: `Stage: Onboarding · Last update: <today>`

Copy (don't symlink, for portability) the brief from `client-briefs/<slug>-brief.md` into `clients/<slug>/00-brief/brief.md`.

### 4 · Report back

End the command by listing:
- Path to the generated brief
- Path to the new project workspace
- The 6 subdirectories created
- Suggested next step (e.g., "Run `/weekly-report` after the first work session")

## Edge cases

- **Existing workspace**: if `clients/<slug>/` already exists, ask before touching it. Default to a non-destructive merge (only create missing subdirectories; leave existing files alone).
- **No `client-briefs/` directory yet**: create it as part of step 2; the skill should handle this, but verify after.
- **Slug collision**: if two clients would slug to the same value (e.g., "Acme Co" and "Acme Co."), suffix with `-2`, `-3`, etc., and warn the user.
