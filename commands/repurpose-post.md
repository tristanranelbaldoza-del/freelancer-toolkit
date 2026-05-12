---
description: Repurpose a finished blog post into platform-native social posts for LinkedIn, Twitter/X (as a thread), and Instagram. Reads the source post, invokes the social-repurpose-agent, and writes three ready-to-paste drafts into social/.
argument-hint: "<path-to-post.md> [--url=<live-url>]"
---

# /repurpose-post — Blog → LinkedIn + Twitter/X + Instagram

Coordinates the **social-repurpose-agent** to convert a finished blog post into three platform-native social drafts. Each draft is saved as its own file so it can be copy-pasted directly into the platform.

## Workflow

### 0 · Parse arguments

`$ARGUMENTS` is:
- **First positional** — path to the source post (markdown). If omitted, default to the most recently modified file under `drafts/` or `posts/`. If neither exists or both are empty, ask the user.
- **`--url=<live-url>`** (optional) — the URL where the post will live (used in Twitter's final tweet + Instagram's link reference). If omitted, use the placeholder `<post-url>` so the user can substitute later.

Compute the post **slug** from the filename (strip directory + `.md` extension). All output files derive from it.

### 1 · Read the post

Use `Read` to load the source post. Pull these from the frontmatter (or infer if missing):
- `title`
- `slug`
- `primary_keyword`
- `description`
- `sources` (list)

If the post has no YAML frontmatter at all, that's fine — proceed with what's there and tell the agent the frontmatter is absent.

### 2 · Dispatch the social-repurpose-agent

Invoke the **social-repurpose-agent** subagent. Pass it a self-contained prompt containing:

> Repurpose the following blog post into three platform-native social drafts (LinkedIn, Twitter/X thread, Instagram), following your skill's output format exactly.
>
> **Source URL**: `<live-url or '<post-url>'>`
> **Slug**: `<slug>`
> **Primary keyword (if known)**: `<primary_keyword or 'n/a'>`
>
> --- BEGIN SOURCE POST ---
> <the full markdown content of the post>
> --- END SOURCE POST ---
>
> Return the three drafts with the `### === LINKEDIN ===` / `### === TWITTER ===` / `### === INSTAGRAM ===` delimiters and `---POST---` / `---END---` body markers exactly as your skill defines them.

### 3 · Parse the agent's response and write three files

The agent's response contains three drafts separated by `### === <PLATFORM> ===` headers, each with the post body bracketed by `---POST---` and `---END---`.

For each platform, extract the body between those markers and write to:

```
social/<slug>-linkedin.md
social/<slug>-twitter.md
social/<slug>-instagram.md
```

(Create `social/` if missing.)

Each output file should be **just the post body**, no metadata header — so the user can `cat | pbcopy` it straight into the platform. The agent's metadata (character counts, hook notes) is preserved in the consolidated digest file below.

Also save the agent's **full response** (with metadata, reuse map, and notes) to:

```
social/<slug>-digest.md
```

This is for the freelancer's records and to capture the agent's notes about weak hooks, missing stats, etc.

### 4 · Sanity-check the outputs

After writing the files, programmatically verify:

| Platform | Check | If fails |
|---|---|---|
| LinkedIn | Character count between 1,000 and 3,000 | Warn the user; do not auto-retry |
| Twitter | Each tweet ≤ 280 chars (split on blank lines or `\d+/` numbering) | List the over-length tweets in the report |
| Instagram | Total ≤ 2,200 chars; ends with a hashtag block (≥ 5 hashtags) | Warn if hashtags are missing |

Use `wc -c` / `wc -m` and shell parsing — don't dispatch another agent for this; the agent should have respected limits already.

### 5 · Report back

End the command with:

```markdown
## /repurpose-post — complete

- **Source**: `<path>`
- **Slug**: `<slug>`
- **Live URL**: `<live-url or 'not provided'>`

### Drafts ready to copy-paste
- 💼 LinkedIn (~<N> chars): [social/<slug>-linkedin.md]
- 🐦 Twitter thread (<N> tweets): [social/<slug>-twitter.md]
- 📷 Instagram (~<N> chars): [social/<slug>-instagram.md]
- 📋 Full digest (with agent's notes): [social/<slug>-digest.md]

### Sanity checks
- LinkedIn length: <✓ within range | ✗ over/under>
- Twitter per-tweet limit: <✓ all under 280 | ✗ N tweets over>
- Instagram hashtag block: <✓ present | ✗ missing>

### Agent notes
- <quote the 1–3 bullets from the agent's "Notes for the caller" section>

### Suggested next steps
1. Review the LinkedIn hook — does it stop a scroll?
2. If `<post-url>` is still a placeholder, substitute the real URL across all three drafts
3. Drop into the platform composer; the files are plain text and need no further formatting
```

## Edge cases

- **Missing source post**: if the provided path doesn't exist or is empty, exit cleanly with a one-line error pointing to `/research-and-write` or asking for a valid path. Don't invent content.
- **Over-length agent output**: if the agent ignores limits and produces a 3,500-char LinkedIn post or 320-char tweets, do not silently trim. Surface it in the sanity-check report and let the user decide whether to ask for a regenerate.
- **Existing social/ files**: if `social/<slug>-*.md` already exists, ask before overwriting. Default to (a) overwrite, (b) append `-2`, or (c) cancel.
- **No frontmatter on the source post**: still works — the agent gets raw content. Note in the report that frontmatter was missing in case the user wants to add it for future repurposes.
- **Truly short source post**: if the source is < 300 words, warn the user — the agent will repurpose, but a thin post produces thin social drafts. Suggest expanding the source first.

## Constraints

- **One agent dispatch per run.** Don't fan out per platform — the agent handles all three in a single response, preserving voice consistency across versions.
- **Don't auto-fix the drafts.** Unlike `/research-and-write`'s P0 auto-correct loop, this command surfaces issues to the user rather than rewriting the agent's output. Voice and hook choices are too taste-driven for automatic editing.
- **Don't add hashtags the agent didn't suggest.** The agent has the source-post context for relevance; appending generic tags after-the-fact dilutes results.
- **Don't modify the source post.** This command is read-only against the source — never edit the blog draft as a side effect of repurposing.
