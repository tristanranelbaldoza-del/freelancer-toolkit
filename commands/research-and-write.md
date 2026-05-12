---
description: End-to-end content workflow — research a topic with the research-agent, draft an 800–1,200 word blog post with proper H2/H3 structure and source citations, then audit it with the review-agent. Returns the final post plus prioritized review notes.
argument-hint: "<topic> [primary-keyword]"
---

# /research-and-write — Researched blog post workflow

Run the full research → draft → review pipeline for a single blog post. Coordinates the **research-agent** and **review-agent** subagents and produces a polished draft ready for the writer's last pass.

## Workflow

### 0 · Parse arguments

`$ARGUMENTS` is `<topic> [primary-keyword]`:
- Everything before the last quoted-or-flag fragment is the **topic** (free text).
- The optional last segment after `--keyword=` or in `[brackets]` is the **primary keyword** for SEO. If omitted, derive one from the topic.

If `$ARGUMENTS` is empty, ask the user for the topic and primary keyword via `AskUserQuestion`.

Compute a slug from the topic (lowercase, spaces → hyphens, strip punctuation). This drives all file paths in this run.

### 1 · Research phase — invoke `research-agent`

Dispatch the **research-agent** subagent with a self-contained prompt:

> Research the topic "<topic>" for a freelance blog post targeting <audience inferred from project context or 'general professional readers'>.
> Primary keyword for SEO: "<primary-keyword>".
> Return 3–5 credible sources from the last 12 months and 8–15 bulleted key takeaways with `[^N]` source markers.
> Follow the exact "Research Digest" output format from your skill definition.

Save its output to:

```
research/<slug>-digest.md
```

(Create `research/` if missing.)

If the agent surfaces an ambiguity in the topic, pause and surface it to the user via `AskUserQuestion` before proceeding to step 2.

### 2 · Draft phase — write the post yourself

Read `research/<slug>-digest.md`. Then draft the blog post following this spec.

**Targets:**
- **Length**: 800–1,200 words (write `wc -w` final count into a comment at the very end of the file as `<!-- word_count: N -->`)
- **Primary keyword**: appears in the title, H1, first 100 words, and at least one H2
- **Heading structure**: exactly one H1 (the title); 3–6 H2 sections; optional H3s nested under H2s; never skip levels

**Required document structure:**

```markdown
---
title: "<Post title — 50–60 chars, primary keyword near front>"
description: "<140–160 char meta description with primary keyword and a reason to click>"
slug: <slug>
author: "<from project context, or 'Freelancer'>"
date: <YYYY-MM-DD>
primary_keyword: "<primary-keyword>"
secondary_keywords: ["<term-1>", "<term-2>", "<term-3>"]
sources:
  - { id: 1, title: "<source title>", url: "<url>" }
  - { id: 2, ... }
---

# <H1 title>

<Opening hook — 2–3 sentences earning the read. Use a specific number or sharp claim from the digest, not a vague generality.>

<Brief framing paragraph laying out what the reader will get.>

## <H2 section 1>

<2–4 short paragraphs. Cite digest claims inline as [^1], [^2].>

### <H3 sub-section, optional>

<Drill-down or example.>

## <H2 section 2>

<...>

## <H2 section 3>

<...>

## <H2: Takeaways>

<3–5 bullet takeaways summarizing what the reader should do next.>

## Sources

[^1]: <source title> — <publication>, <date>. <url>
[^2]: ...
```

**Style rules**:
- Paragraphs ≤ 3 sentences
- Bold for genuinely key terms (≤ 5 per post)
- Tables/bullets where a comparison or list is natural
- Every numerical or named claim has a `[^N]` marker that points to a real source in the digest
- No "in this blog post we will" filler — get to the point

Save the draft to:

```
drafts/<slug>.md
```

(Create `drafts/` if missing.)

### 3 · Review phase — invoke `review-agent`

Dispatch the **review-agent** subagent with this prompt:

> Review the blog draft at `drafts/<slug>.md` against the research digest at `research/<slug>-digest.md`.
> Return the audit in the exact "Review" output format from your skill definition: scores, factual accuracy table, SEO findings, editorial notes, and a P0/P1/P2 fix list.

Save its output to:

```
reviews/<slug>-review.md
```

(Create `reviews/` if missing.)

### 4 · Auto-correct P0 issues (optional but recommended)

If the review-agent surfaces any **P0 (must fix)** items:
- Apply them to `drafts/<slug>.md` directly using `Edit`
- Update the meta description, fix unsupported claims, repair heading structure, etc.
- Re-run the review-agent **once** to confirm P0s are cleared
- Don't loop forever — if P0s remain after one auto-fix pass, surface them to the user and let them decide

P1/P2 fixes are surfaced to the user but not auto-applied.

### 5 · Report back

End the command with:

```markdown
## /research-and-write — complete

- **Topic**: <topic>
- **Primary keyword**: <primary-keyword>
- **Word count**: <N> (target 800–1,200)
- **Overall score**: <X/10>

### Artifacts
- 📚 Research digest: [research/<slug>-digest.md]
- 📝 Draft: [drafts/<slug>.md]
- 🔍 Review: [reviews/<slug>-review.md]

### P0 issues
- <auto-fixed | none>

### Outstanding P1/P2
- <count + one-line summary, or 'none'>

### Suggested next step
- Final human read-through → publish
```

## Constraints

- **Never skip the research phase.** Drafting without the digest leads to hallucinated claims — exactly what the review-agent is designed to catch. Save tokens by writing tightly, not by skipping research.
- **One subagent per phase.** Don't fan out — research-agent does the gathering, you do the writing, review-agent does the audit. The hand-offs are the workflow.
- **Honor the word count.** 800–1,200 is the target. If the topic genuinely needs more, surface it to the user before exceeding; don't silently balloon to 2,000+.
- **Don't fabricate citations.** Every `[^N]` must trace to a real source in the digest. The review-agent will catch this anyway, but it's faster to do it right the first time.
- **Auto-fix budget is one pass.** If P0s remain after a single auto-correction loop, stop and ask — endless loops waste tokens and erode the user's trust.
