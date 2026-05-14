# freelancer-toolkit

> A Claude Code plugin that turns Claude into your freelance operations assistant — onboarding clients, drafting briefs, researching and writing blog posts, repurposing them for social, and publishing to WordPress. All without leaving the terminal.

---

## What this plugin gives you

When this plugin is installed in Claude Code, you get:

- **4 slash commands** for end-to-end client work — onboarding, weekly reports, research-driven writing, and social repurposing
- **1 auto-triggered skill** that captures new client briefs in a clean, repeatable format
- **3 specialized subagents** the slash commands invoke under the hood (you don't need to call them directly)
- **2 hooks** that run silently after every file write — content quality checks and a file-change log
- **1 MCP server** that connects Claude to your WordPress site so it can read, draft, and publish posts directly

A typical workflow looks like:

```
/onboard-client "Acme Co"
    → brief saved, project workspace scaffolded under clients/acme-co/

/research-and-write "Why Acme should adopt X"  --keyword="acme x adoption"
    → research gathered from the web with citations
    → 800–1,200 word draft written with proper H2/H3 structure
    → automatic editorial review against the sources + SEO checklist

/repurpose-post drafts/why-acme-should-adopt-x.md  --url=https://acme.com/blog/...
    → LinkedIn post, Twitter thread, and Instagram caption — all platform-native

/weekly-report all
    → status across every client in one report

WordPress MCP can publish the draft when you're ready
```

---

## Installation

This plugin is distributed as a Claude Code marketplace. Once you've pushed it to GitHub, anyone (including you on another machine) installs it in two commands.

### From GitHub

```bash
# 1. Register the marketplace (one-time, per machine)
claude plugin marketplace add tristanranelbaldoza-del/freelancer-toolkit

# 2. Install the plugin
claude plugin install freelancer-toolkit@freelancer-marketplace
```

### From a local folder (development / before publishing)

```bash
# 1. Add your local clone as a marketplace
claude plugin marketplace add /path/to/my-freelancer-plugin

# 2. Install
claude plugin install freelancer-toolkit@freelancer-marketplace
```

### After installation

**Restart Claude Code fully** (quit and reopen). Plugin slash commands, hooks, and the MCP server are loaded at startup — they won't appear in an already-running session.

Verify it worked:

```bash
claude plugin list
```

You should see `freelancer-toolkit@freelancer-marketplace · ✔ enabled` in the output.

---

## Slash commands

Type these inside Claude Code. All four take optional arguments — Claude will prompt you for anything missing.

### `/onboard-client [client-name]`

Walks through new-client onboarding from scratch. Invokes the client-brief skill to capture the ten-field intake, then scaffolds a full project workspace.

**What it produces:**
- `client-briefs/<slug>-brief.md` — the intake brief
- `clients/<slug>/00-brief/` through `05-communications/` — six standard project folders
- `clients/<slug>/README.md` — quick-jump index linking everything

**Example:**

```
/onboard-client "Acme Health Co."
```

Claude will ask for the ten intake fields (industry, services, audience, brand voice, platforms, budget, timeline, competitors, success metrics), save the brief, and scaffold `clients/acme-health-co/` with the standard subdirectories.

---

### `/weekly-report [client-slug | all]`

Generates a weekly status report. Walks every `clients/<slug>/` folder, looks at files touched in the last 7 days, and produces a wins / in-progress / blockers / next-week summary per client.

**What it produces:**
- `reports/weekly-<YYYY-MM-DD>.md`

**Examples:**

```
/weekly-report all
```

Report covering every client in `clients/`.

```
/weekly-report acme-health-co
```

Report scoped to one client.

If a client has had zero activity in 7 days, it's flagged at the top of the report under "needs attention."

---

### `/research-and-write <topic> [primary-keyword]`

The flagship content-creation pipeline. Researches a topic, drafts an 800–1,200 word blog post with proper H2/H3 structure and citations, then audits the draft against the research and SEO best practices.

**Three subagents run in sequence:**
1. `research-agent` — searches the web, vets 3–5 credible sources, returns 8–15 footnoted takeaways
2. *(Claude itself)* writes the draft
3. `review-agent` — audits factual accuracy, SEO, and editorial quality; rates the post on 4 dimensions

**What it produces:**
- `research/<slug>-digest.md` — research sources and key takeaways
- `drafts/<slug>.md` — the blog post with frontmatter (title, meta description, keywords, sources)
- `reviews/<slug>-review.md` — scores out of 10 plus a P0/P1/P2 fix list

**Examples:**

```
/research-and-write "Why teams are switching from BrowserStack to Playwright"
```

Claude infers the primary keyword.

```
/research-and-write "AI-native testing platforms" --keyword="ai testing tools"
```

You set the keyword explicitly.

Any P0 (must-fix) issues the reviewer finds get auto-corrected in a single pass before the command returns.

---

### `/repurpose-post <path-to-post.md> [--url=<live-url>]`

Takes a finished blog post and produces platform-native social drafts for LinkedIn, Twitter/X (as a thread), and Instagram. Each version respects that platform's length limits, hook conventions, and hashtag norms — not just truncated copies of the post.

**What it produces:**
- `social/<slug>-linkedin.md` — ready to copy-paste
- `social/<slug>-twitter.md` — numbered thread, each tweet ≤ 280 chars
- `social/<slug>-instagram.md` — caption with hashtag block
- `social/<slug>-digest.md` — full agent output (metadata, reuse map, notes)

**Examples:**

```
/repurpose-post drafts/why-teams-switch-to-playwright.md
```

URL is left as a placeholder you fill in before posting.

```
/repurpose-post drafts/why-teams-switch-to-playwright.md --url=https://blog.example.com/playwright
```

Real URL inserted into the Twitter and Instagram drafts.

After the drafts are written, the command sanity-checks them (LinkedIn 1,000–3,000 chars; every tweet ≤ 280; Instagram has hashtag block) and surfaces any issues — but never silently trims, so you stay in control.

---

## The skill

### `client-brief-generator`

This skill **triggers automatically** when you mention creating a client brief in conversation. You don't invoke it explicitly — it activates when Claude sees phrases like:

- "Create a client brief for Acme"
- "Draft a brief for the new project"
- "Start the intake for Coastal Co."
- "Onboarding doc for Northwind"

The skill captures ten standard intake fields via grouped questions:

| # | Field | Example |
|---|-------|---------|
| 1 | Client / Brand Name | "Acme Health Co." |
| 2 | Industry | "B2B health-SaaS" |
| 3 | Services Needed | "Content strategy + monthly posts" |
| 4 | Target Audience | "Hospital procurement leads" |
| 5 | Brand Voice | "Authoritative but warm; never jargon-heavy" |
| 6 | Platforms | "LinkedIn, blog, email newsletter" |
| 7 | Budget Range | "$5K/mo retainer" |
| 8 | Timeline | "Start June 1, 6-month engagement" |
| 9 | Competitors (2–3) | "Epic, Cerner, Veradigm" |
| 10 | Success Metrics | "200 SQL/mo by month 4, 15% open rate" |

Output saved to `client-briefs/<client-slug>-brief.md` as a clean markdown table.

The skill is **also** invoked under the hood by `/onboard-client` — you don't have to choose between the slash command and the skill.

---

## Subagents

These are specialized helpers the slash commands invoke. You generally don't call them yourself, but knowing they exist helps when reviewing logs or customizing the workflow.

| Agent | Model | Used by | What it does |
|-------|-------|---------|--------------|
| `research-agent` | `sonnet` | `/research-and-write` | Searches the web, vets 3–5 credible sources against a 5-signal rubric, returns 8–15 footnoted takeaways |
| `review-agent` | `sonnet` | `/research-and-write` | Audits a draft against its research digest (factual accuracy), SEO checklist (title, meta, keywords, headings, links), and editorial quality (hook, flow, voice). Rates 1–10 on 4 dimensions. Returns P0/P1/P2 fix list |
| `social-repurpose-agent` | `sonnet` | `/repurpose-post` | Mines a finished post for its sharpest claim, supporting data, and voice — then drafts LinkedIn / Twitter / Instagram versions in each platform's conventions |

---

## Hooks (run automatically)

Hooks fire silently after Claude uses certain tools. The plugin registers two on `PostToolUse` for `Write` and `Edit` calls, with a 10-second timeout each. Both are non-blocking — they emit information and always exit cleanly.

### `quality-check.sh`

Scans every file Claude writes or edits for six common quality issues:

| Check | What it catches |
|-------|-----------------|
| Empty file | Zero-byte writes |
| Trailing whitespace | Lines ending in spaces |
| Stray markers | `TODO`, `FIXME`, `XXX` left in the file |
| Markdown fences | Unbalanced ``` blocks |
| Shell syntax | `.sh` files that fail `bash -n` |
| JSON parse | `.json` files that don't parse |

When a check fails, you'll see a warning in your terminal — but the write succeeds. Nothing gets blocked.

### `log-changes.sh`

Appends one line per Write/Edit to `changelog.txt` in your project root. Format:

```
2026-05-12T13:03:50Z | Write | /Users/me/project/drafts/post.md
2026-05-12T13:04:12Z | Edit  | /Users/me/project/clients/acme/00-brief/brief.md
```

Useful for: auditing what Claude actually touched, generating retrospectives, debugging "wait, when did I write that?" moments.
**Note for plugin users:** `changelog.txt` is excluded from git in this repository, but if you install this plugin into another project you should add `changelog.txt` to that project's `.gitignore` to avoid accidentally committing your activity log.
---

## MCP server — WordPress

The plugin ships with a Model Context Protocol server config that connects Claude to a WordPress site via the WP REST API. Once configured, Claude can list posts, create drafts, publish, update metadata, etc. — all from chat.

### Step 1 · Get your WordPress credentials

WordPress has built-in **Application Passwords** (since WP 5.6) — these are scoped, revocable credentials separate from your normal login password. **Always use an Application Password — never your login password.**

1. Log in to your WP admin: `https://your-site.com/wp-admin`
2. Go to **Users → Profile** (or **Users → All Users → Edit** for someone else's profile if you're admin)
3. Scroll to the **Application Passwords** section near the bottom
4. Enter a name like `claude-code-mcp` and click **Add New Application Password**
5. WordPress shows a one-time password like `abcd 1234 efgh 5678 ijkl 9012` — **copy it now**, you can't retrieve it again
6. Note your WP username (the one you log in with, e.g. `admin`)

If your managed WP host has disabled Application Passwords, install the [Application Passwords plugin](https://wordpress.org/plugins/application-passwords/) or contact your host.

### Step 2 · Encode the auth token

The auth token is `username:application-password` base64-encoded. Generate it once on your terminal:

```bash
echo -n "admin:abcd 1234 efgh 5678 ijkl 9012" | base64
```

Output looks like `YWRtaW46YWJjZCAxMjM0IGVmZ2gg...` — that's your `WORDPRESS_AUTH_TOKEN`.

### Step 3 · Set environment variables

Add these to your shell startup file. For **zsh** (macOS default), edit `~/.zshrc`:

```bash
# WordPress MCP — freelancer-toolkit plugin
export WORDPRESS_URL="https://your-blog.com"
export WORDPRESS_AUTH_TOKEN="YWRtaW46YWJjZCAxMjM0IGVmZ2gg..."
```

For **bash**, use `~/.bashrc` or `~/.bash_profile`. Reload your shell:

```bash
source ~/.zshrc       # or ~/.bashrc
```

Verify they're set:

```bash
echo $WORDPRESS_URL
echo $WORDPRESS_AUTH_TOKEN
```

### Step 4 · Restart Claude Code

Environment variables in `.mcp.json` are resolved when Claude Code starts. After editing your shell config, **fully quit and restart Claude Code** so it picks up the new values.

### Step 5 · Verify the connection

In Claude Code, ask:

> "List the 5 most recent posts on my WordPress site."

If the MCP is connected, Claude will use the WordPress tools to fetch them.

### Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| Connection refused / DNS error | `WORDPRESS_URL` wrong | Check the URL in a browser; no trailing slash |
| `401 Unauthorized` | Bad auth token | Re-generate the app password and re-encode |
| `404 Not Found` on `/wp-json/mcp/v1` | WP site doesn't have a WordPress MCP server installed | Install the WordPress MCP companion plugin on your WP site |
| Tools never appear in Claude Code | Env vars weren't loaded — Claude was started before `source ~/.zshrc` | Quit, open a fresh terminal, restart Claude Code from there |

### Security notes

- **Never commit your `WORDPRESS_AUTH_TOKEN`** to git or share it in screenshots. It's equivalent to your WP credentials.
- Application Passwords can be **revoked individually** from WP admin → Users → Profile. Rotate them like SSH keys.
- The `.mcp.json` in this plugin only contains `${VAR}` placeholders — real credentials live in your shell environment, not in the repo.
- Scope app passwords narrowly: one per integration (Claude Code, automations, etc.) so you can revoke surgically.

---

## File structure

```
my-freelancer-plugin/
├── .claude-plugin/
│   ├── plugin.json                   ← plugin manifest (name, version, author)
│   └── marketplace.json              ← marketplace manifest (so it can be installed)
├── .mcp.json                         ← WordPress MCP server config
├── README.md                         ← this file
├── agents/
│   ├── research-agent.md             ← web research with credibility vetting
│   ├── review-agent.md               ← draft + SEO + editorial audit
│   └── social-repurpose-agent.md     ← blog → 3 platform-native social drafts
├── commands/
│   ├── onboard-client.md             ← /onboard-client
│   ├── weekly-report.md              ← /weekly-report
│   ├── research-and-write.md         ← /research-and-write
│   └── repurpose-post.md             ← /repurpose-post
├── hooks/
│   ├── hooks.json                    ← registers both hooks on Write|Edit
│   ├── quality-check.sh              ← content quality scanner
│   └── log-changes.sh                ← appends to changelog.txt
└── skills/
    └── client-brief-generator/
        └── SKILL.md                  ← auto-triggers on "client brief"
```

### Files the plugin creates in your project

When you use the plugin, Claude writes into your **working directory**, not the plugin folder. Expect these to appear:

| Path | Created by | Purpose |
|------|------------|---------|
| `client-briefs/<slug>-brief.md` | client-brief-generator skill, `/onboard-client` | Single-file intake brief per client |
| `clients/<slug>/` (6 subdirs + README) | `/onboard-client` | Full project workspace |
| `research/<slug>-digest.md` | `/research-and-write` | Vetted sources and key takeaways |
| `drafts/<slug>.md` | `/research-and-write` | The blog post itself |
| `reviews/<slug>-review.md` | `/research-and-write` | Editorial audit and fix list |
| `social/<slug>-{linkedin,twitter,instagram,digest}.md` | `/repurpose-post` | Platform-specific social drafts |
| `reports/weekly-<YYYY-MM-DD>.md` | `/weekly-report` | Weekly cross-client status |
| `changelog.txt` | `log-changes.sh` hook | Append-only log of every Write/Edit |

---

## Local development

If you're working on this plugin:

```bash
# Validate before pushing
claude plugin validate /path/to/my-freelancer-plugin/

# Install your local copy
claude plugin marketplace add /path/to/my-freelancer-plugin
claude plugin install freelancer-toolkit@freelancer-marketplace

# Restart Claude Code

# Update after changes
claude plugin update freelancer-toolkit
```

Both the plugin manifest (`plugin.json`) and the marketplace manifest (`marketplace.json`) live under `.claude-plugin/`. When you change one, run `claude plugin validate` to catch schema errors early.

---

## FAQ

**"My slash commands aren't appearing in Claude Code."**
Did you restart Claude Code after installing? Slash commands are registered at startup. Also check `claude plugin list` to confirm the plugin is enabled.

**"The skill triggered when I didn't want it to."**
The skill activates on phrases like "client brief", "draft a brief". If you want to discuss the *concept* of briefs without triggering it, just be specific: "tell me about the client-brief workflow" tends not to trigger.

**"Can I customize the intake fields in the brief?"**
Yes — edit `skills/client-brief-generator/SKILL.md` and update the ten-field list. The skill's output template uses whatever fields you define.

**"Can I disable a hook temporarily?"**
Yes — `claude plugin disable freelancer-toolkit` turns off everything. To disable just one hook, edit `hooks/hooks.json` and remove that entry, then update the plugin.

**"Where does `changelog.txt` get written when the project root isn't obvious?"**
The hook resolves `$CLAUDE_PROJECT_DIR` first, falling back to `$PWD`. In most setups this is the directory you launched Claude Code from.

**"Do I need the WordPress MCP to use the rest of the plugin?"**
No. The MCP is optional. Skip the WordPress setup section if you don't publish to WP — every command and hook works without it.
