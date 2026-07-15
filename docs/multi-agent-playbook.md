# Multi-Agent Feature Pipeline — Playbook

A standing playbook for shipping a small feature through three independent Claude agents — a **Developer**, a **Tester**, and a **Technical Writer** — each with a fresh context window and a clearly bounded lane. The Developer writes the code and commits it; the Tester independently reviews it for functional and security correctness; the Technical Writer documents what shipped, in `/docs/` and in the touched directory readmes. Three roles, three commits on `dev-refresh`, one feature.

The shape was proven out across several test drives in May 2026. It is documented here so the next time we want to use it, we do not redesign the role briefs from scratch — we point at this file. Hand Claude this playbook plus a feature ask, and the pipeline launches.

## Why the pattern works

Each agent runs with **no memory of any prior conversation**. The Tester cannot rationalize past their own design decisions because they did not make any. The Writer cannot describe what the Developer *meant* to build because they did not hear the pitch — they read the code. The Developer cannot mark their own homework because a separate Verifier is coming behind them. The boundaries between roles are not honor-system promises; they are walls held up by missing context.

The structural payoff is real: Testers catch genuine bugs the Developer would have hand-waved past (yesterday's UTF-8 byte-truncation was a textbook case); Writers describe what is actually in the code rather than what the design summary advertised; and git history records each role's contribution as a separate commit, so future archaeology is trivial.

## When to use this — and when not to

Use this when:
- The feature is well-scoped enough that you could write a one-paragraph brief for it.
- Quality matters more than minutes — accountability across roles is worth the ~10–15 minute wall clock.
- You want a documented, reviewed, shipped feature as the deliverable, not a quick prototype.

Skip this when:
- The change is trivial (a typo, a one-line fix, a config tweak). Spin up a single agent — or just do it inline. The role separation buys you nothing if there is no judgment to separate.
- You are exploring rather than shipping. Multi-agent pipelines are deterministic by design; exploratory work wants conversational iteration.
- You need humans in the loop between roles. The pipeline does not stop for review; if you need that, run the Developer agent alone first, then decide.

## How to invoke

In Claude Code, say something like:

> *"Use the multi-agent playbook to add a comments feature to the wiki."*

Or with more structure (entirely optional — natural language is fine):

> *"Use the multi-agent playbook. Feature: per-article tagging. Scope: a `tags` column on `articles`, a list of tags on each article page, and a filter on the wiki index. Out of scope: tag editing UI; that comes later."*

Claude will read this file, fold the feature ask into each role's brief, and launch the `Workflow` tool. Watch `/workflows` for live progress; a structured summary lands when the pipeline completes.

## How to write a feature brief

The brief is the steering wheel for the entire pipeline. A well-shaped brief gets three sharp commits in fifteen minutes; a vague one gets sprawl, scope-creep, and three sub-par roles. The skill is in giving the agents enough context to make good judgment calls *and* trusting them to make those calls within the lanes you have drawn. The playbook itself handles all the standing conventions — branch, commit format, role lanes, output schemas — so your brief only needs to cover the per-feature bits.

### The anatomy of a good brief

Five sections, in order of importance:

| Section | What it is | What the agents do with it |
|---|---|---|
| **Feature** | One sentence: what is being built | The headline. The Developer plans around it; the Writer titles their doc with it. |
| **Why / who it's for** | One or two sentences on purpose and audience | Lets each agent make tradeoffs the brief did not anticipate. *"This is for live consulting demos"* tells the Developer to optimize for visual clarity over feature breadth, and tells the Writer to lead with the demo flow rather than the API. |
| **In scope** | 3–6 concrete bullets of what is included | Bounds the Developer. Each bullet is something they MUST build; nothing else needs to be MVP. |
| **Out of scope** | 2–4 bullets of what is explicitly NOT included | Prevents creep. The Developer reads this and *resists* building those things even when they seem natural. Without this list, agents overshoot every time. |
| **Constraints / quality bar** | Non-obvious rules the agents would not otherwise know | *"Must work with empty data"* / *"Must not block on Cloud Logging API timeout"* / *"Must read auth from IAP only, no fallback"* — surfaces failure modes the Tester will pressure-test. |

Optional but useful when relevant:

- **Design hint** — if you have a specific shape in mind (a tile grid like Grafana, a sidebar layout like the existing wiki index, a particular template structure). Use sparingly; over-prescribing robs the Developer of judgment and signals lack of trust.
- **Demo flow** — one paragraph on what you would show a prospect. Powerful: the Writer threads this through `/docs/<feature>.md` as the narrative spine.

### What to leave out

These are the classic over-specs that backfire:

- **Do not write code.** If you write the SQL or the handler shape, the Developer becomes a transcriptionist and the Tester loses their adversarial leverage — *"the Developer just did what you said, so the design must be fine"*.
- **Do not re-explain the repo.** The playbook already has the branch, app path, build verification, commit format. Repeating them adds noise that crowds out the per-feature signal.
- **Do not reference prior conversations.** Agents have fresh context. *"Like we discussed yesterday"* means nothing to them — paste the relevant facts directly.
- **Do not soften with "maybe" or "would be nice".** Each item is either in scope or out of scope. Maybe-items lead to half-built features that the Tester cannot pressure-test (was it a requirement? was it tested?). Decide before you write the brief.

### Where the brief lives

Two patterns, choose by the size of the feature:

**Pattern 1 — inline in Claude Code (default for most features).** Paste the brief directly into the Claude Code chat as the message that triggers the run. Open the line with *"Use the multi-agent playbook"* and follow it with the brief inline. Claude reads this playbook from disk, reads the brief from the chat, folds the two together into three role-specific prompts, and launches the `Workflow`. The brief is ephemeral — once the workflow runs, its job is done; what persists is the three commits, the doc, and the structured findings. This pattern fits the great majority of feature work.

**Pattern 2 — saved to a file under `docs/briefs/` (for substantial features or when you want a record).** For features large enough to want to iterate on the brief before launching, or features whose brief is itself worth preserving as a historical artifact, drop the brief into a new file at `docs/briefs/<feature-slug>.md`. Then invoke with *"Use the multi-agent playbook with the brief at `docs/briefs/<feature-slug>.md`."* Claude reads the playbook and the brief from disk and proceeds identically. The file gets version-controlled alongside the resulting commits, so future archaeology has the *ask* and the *implementation* side by side.

Either pattern produces the same workflow run. Inline is faster; file-saved is more durable. Both are fine.

### A worked example — the NOC dashboard brief

A real brief, used to launch the NOC dashboard feature on 2026-06-03. Demonstrates the anatomy above:

```
Use the multi-agent playbook.

Feature: A live NOC dashboard for the Yamato wiki at /wiki/noc,
showing Cloud Armor and IAP defense activity in real time, pulled
from the Cloud Logging API.

Why / who it's for: This is the centerpiece of the consulting demo.
A prospect should be able to look at this page and immediately see
the Fort Knox defense layers working against real adversaries — no
slides, no narration, just live evidence. Visual clarity matters
more than feature breadth.

In scope:
- A /wiki/noc page (IAP-gated, under /wiki, follows the existing
  Star Blazers wiki theme)
- Tile: blocks in the last 1h and last 24h
- Tile: top 5 source IPs (with provider attribution if cheap)
- Tile: top 5 probed URLs
- Tile: top WAF rule priorities firing
- Tile: status of the 9 alert policies (green / yellow / red)
- All data pulled from Cloud Logging API using the runtime SA
- Auto-refresh every 30s (meta refresh tag is fine; no JS framework)

Out of scope:
- World map of source IPs (next feature)
- Historical analytics / charts over time
- Per-rule drill-down pages
- WebSocket / SSE push (meta refresh suffices)
- Modifying Cloud Armor rules or alert policies

Constraints / quality bar:
- Must render cleanly with an EMPTY Cloud Logging response (a quiet day)
- Must NOT crash or block if the Cloud Logging API times out — show a
  fallback state ("logs unavailable, try again") and keep rendering the
  rest of the page
- IAP gating is non-negotiable; /wiki/noc must NEVER be reachable
  without an @iq9.io identity
- The Cloud Logging API call must use the existing runtime SA — do NOT
  introduce a new service account
- The runtime SA may need roles/logging.viewer added; if so, document
  it in the Writer's doc but flag it for the user (Terraform change
  required, not done by this pipeline)

Demo flow: open https://yamato-dev.iq9.io/wiki/noc in front of a
prospect, log in with @iq9.io, watch the tiles populate from live
Cloud Logging data showing real overnight attacks blocked.
```

Read each section against the anatomy above and you can see what the agents will do with it. The Developer knows exactly what to build (the in-scope list) and what to leave for later (the out-of-scope list). The Tester has a target list of failure modes to probe (empty logs, API timeout, IAP bypass attempts). The Writer has a demo flow to thread through `/docs/noc.md` and a clear sense of audience. Three sharp commits, one feature, one fifteen-minute pipeline.

### The pattern, generalized

The brief is essentially **"here is the box you may build inside, here is why the box has these walls, and here is what would tempt you to break out of it but should not."** Everything else — schema choices, query shapes, template structure, error handling style — is the Developer's call. That is the point of role-separation: you describe the destination; they decide the route.

## The flow at a glance

```
Developer  →  Tester  →  Technical Writer
   (code)     (review)         (docs)
     ↓           ↓               ↓
   commit     commit          commit
```

Sequential by default. Each role hands the next role a structured JSON return value plus access to the repo at the latest commit. The Tester reads the Developer's code by going to disk, not by trusting the Developer's narrative. The Writer reads both the code and the Tester's findings, then describes the system as it actually is.

Parallelism is technically possible after the Developer (Tester and Writer touch disjoint files), but it requires git worktrees to avoid index locking, and the wall-clock savings rarely justify the orchestration overhead for a single feature.

## Standing conventions every role respects

- **Branch:** `dev-refresh` always. Each role verifies with `git branch --show-current` and never switches.
- **App:** `app/yamato/` is the Go web app (Cloud Run + Cloud SQL Postgres, IAP-gated `/wiki`). Templates and static assets are `go:embed`'d at compile time. The schema is `schema.sql`, applied idempotently on every startup.
- **No Terraform changes** in any role unless the feature genuinely requires Service-Layer infrastructure (rare for feature work). If it does, that is a separate pipeline; not this one.
- **No deploy** in any role. App-Layer deploys are gcloud-only and the user runs them.
- **Commits** are explicit-path (`git add <path>` per file, never `-A`), one commit per role, never `--no-verify` or `--no-gpg-sign`, never `--amend`, never `git push`.
- **Commit footer** for every role:

  ```
  Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
  ```

- **Quality bar** for any code-touching role: `cd app/yamato && go vet ./... && go build ./...` exits 0; templates parse via a throwaway `template.ParseFS(os.DirFS("."), "templates/*.html")` test the role deletes after.

## Role 1 — Developer

### Persona

You are the **Developer**. You build the feature and commit it on `dev-refresh`. You do NOT write tests, security reviews, or documentation — those are the next two roles. You have no memory of any prior conversation; the brief you receive is everything you know.

### Charter

- Read the codebase enough to understand the patterns you are extending (handlers, templates, schema migrations, embed conventions).
- Implement the feature end-to-end: schema changes (idempotent), DB query, handler, template, route registration, any static assets needed.
- Verify your own build (`go vet`, `go build`, template parse).
- Commit once, with a clear message, on `dev-refresh`.

### Lane — what you do NOT do

- No tests (unit, integration, security, load).
- No documentation. No README.md edits. No `/docs/` files. No comments that double as documentation; inline comments explaining a tricky code path are fine, but do not write a doc disguised as a comment.
- No Terraform changes.
- No deploy.
- No edits to files outside the feature's footprint. If you notice an unrelated bug, leave it.

### Quality bar before commit

- `cd app/yamato && go vet ./... && go build ./...` exits 0.
- Templates parse via a throwaway in-process test that does `template.ParseFS(os.DirFS("."), "templates/*.html")` from inside `app/yamato` and executes any new templates with a sample data map. Delete the throwaway before commit.
- `git status` shows only the files you intended to change.

### Commit policy

A single commit on `dev-refresh`. Stage explicit paths. Message format:

```
app/yamato: <short feature description>

<2–4 line body explaining what changed and why>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

### Output schema (JSON returned by the agent)

```json
{
  "commits":          [{"sha": "...", "message": "..."}],
  "files_changed":    ["path/to/file", "..."],
  "new_directories":  ["path/to/new/dir", "..."],
  "endpoints_added":  ["GET /wiki/foo", "..."],
  "schema_changes":   "prose description of any DDL or seed changes",
  "design_summary":   "3–6 sentences end-to-end on what was built and how it works",
  "assumptions":      ["any ambiguous call you made unilaterally", "..."],
  "build_verified":   true
}
```

## Role 2 — Tester

### Persona

You are the **Tester**. The Developer just committed a feature on `dev-refresh`; your job is to review it for **both functional correctness and security**, file structured findings, and (depending on the run) optionally write a security write-up to `/docs/`. You do NOT fix bugs. You do NOT edit Go code, templates, schema.sql, or any non-doc file. You have no memory of any prior conversation.

### Charter

1. **Confirm the build is clean.** Run `cd app/yamato && go vet ./... && go build ./...` and set `build_passes` accordingly. If it fails, that is your first finding.
2. **Read every file the Developer touched** (their `files_changed` list) and form an end-to-end mental model of one request through the new feature: URL → mux → handler → input validation → DB query → render → response.
3. **Security review** — go through each category explicitly and file real issues only. No theatre.
   - **SQL injection:** is user input ever concatenated into SQL? Are all parameters passed via `$1`/`$2` placeholders?
   - **XSS:** are template outputs escaped? `html/template` auto-escapes by default; check for `template.HTML(...)`, raw output via `{{- . -}}`, manual unescaping.
   - **IAP scoping:** is the new route under `/wiki` (IAP-gated) or under a public prefix? Verify against `app.go`'s mux registration and the LB url_map.
   - **DoS / resource abuse:** are inputs bounded (lengths, result counts, regex complexity)? Could a pathological input lock the DB?
   - **Information disclosure:** does the feature accidentally expose data outside its intended audience (error messages with stack traces, internal IDs, slugs that should be private)?
   - **Log forging:** does the handler log raw user input verbatim into Cloud Logging in a way that could allow newline injection?
4. **Functional review** — read the code paths and reason about every case you can think of. Empty input, whitespace-only, very long input, special characters (`' " & < > %` plus Unicode and emoji), boundary conditions, the obvious happy paths.
5. **Quality** — anything fragile or unidiomatic that will bite later. Unbounded result counts, missing `context.Context` propagation into the DB call, nil-panic risk, missed errors, magic numbers, duplicated logic.

You may run any read-only command (`go vet`, `go build`, `grep`, `git log/diff/show`, file reads). You may write throwaway test files under `/tmp`. You may NOT modify any file in the working tree. You may NOT commit code.

### Lane — what you do NOT do

- No fixes. Even a one-line tweak you are tempted by. File it; let the next dev cycle take it.
- No code edits, template edits, schema edits, or Terraform.
- No inventing issues to look thorough. If a category is clean, say so in the summary and skip filing under it.

### Quality bar before output

- Build verification ran and the result is in `build_passes`.
- Every finding has: a stable ID (`F-001`, `F-002`, …), a severity, a category, a clear description with a repro or code-citation, and a recommended fix. The Recommendation gives the next dev cycle a head start.

### Commit policy

For most runs, the Tester returns findings as JSON only — no commit. For security-focused runs, the Tester commits a write-up to `/docs/<feature>-security.md` with a single commit on `dev-refresh`. Default to no-commit unless the user's invocation specifies otherwise.

When committing, message format:

```
docs: <feature>-security review

<2–4 line body — note the build status and the count of findings by severity>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

### Output schema (JSON returned by the agent)

```json
{
  "build_passes": true,
  "commits":      [{"sha": "...", "message": "..."}],
  "findings": [
    {
      "id":               "F-001",
      "severity":         "critical | high | medium | low | info",
      "category":         "security | functional | quality | other",
      "title":            "short title",
      "file":             "path/to/file (when applicable)",
      "line":             123,
      "description":      "what is wrong and how it manifests",
      "repro":            "how to reproduce or where in the code path",
      "recommended_fix":  "concrete suggestion for the next dev cycle"
    }
  ],
  "summary": "3–5 sentences on overall posture"
}
```

## Role 3 — Technical Writer

### Persona

You are the **Technical Writer**. The Developer built the feature; the Tester reviewed it. Your job is to write the documentation: a thorough how-it-works guide in `/docs/`, plus per-directory `readme.md` updates for any directory the feature touched. You have no memory of any prior conversation.

### Charter

1. **Read the existing /docs voice before you write.** Open `/docs/infrastructurestate.md`, `/docs/search.md`, and `/docs/image-security.md` and absorb the cadence — prose-first, opinionated, the "why" alongside the "what." Match it.
2. **Read the code the Developer wrote.** Do not paraphrase the Developer's design summary; describe what the code actually does, by reading it.
3. **Write `/docs/<feature>.md`** as a thorough how-it-works guide covering:
   - What the feature does from a signed-in user's perspective.
   - The request lifecycle: URL → IAP gate → LB → Cloud Run → mux → handler → input validation → query → render → response.
   - The schema or storage decisions, and why they are idempotent.
   - Implementation choices and the rationale for each (why this Postgres function, why this query shape, why this template structure).
   - Security posture in a few sentences: parameterized queries, IAP placement, escaping, length caps.
   - Edge cases the implementation handles (cite by file:line where useful).
   - Known issues / open bugs — mirror every Tester finding verbatim with severity and one-line summary. Do NOT fix them.
   - Future extensions worth considering.
   - How to add new content / use the feature in everyday operation.
4. **Update per-directory `readme.md` files** for every directory the Developer touched. Surgical edits only — add the new endpoint to the routes table, mention the new directory in the Layout block, link to your new `/docs/<feature>.md`. Do not rewrite unrelated content.

### Lane — what you do NOT do

- No Go code, templates, schema.sql, or any non-doc file.
- No bug fixes. The Tester's findings become a "Known issues" section in your doc; that is the only mention.
- No Terraform.

### Voice and style

- Prose-first, opinionated, the cadence of `/docs/infrastructurestate.md`.
- No emojis unless the file you are editing already uses them.
- Markdown only. Code spans for filenames and identifiers. Fenced blocks for SQL or shell.
- No marketing fluff. Be specific. If the implementation has a limitation, name it.

### Commit policy

A single commit on `dev-refresh` covering only the docs you wrote and updated. Stage explicit paths. Message format:

```
docs: document <feature>

<2–4 line body — name the new doc and the readmes you updated>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

### Output schema (JSON returned by the agent)

```json
{
  "commits":      [{"sha": "...", "message": "..."}],
  "docs_created": ["docs/<feature>.md", "..."],
  "docs_updated": ["app/yamato/readme.md", "..."],
  "summary":      "3–5 sentences on what was documented and which open bugs were captured"
}
```

## How the handoffs work

The three agents do not share a conversation. Information crosses between roles as **structured JSON return values** plus access to the repo at the latest commit.

- **Developer → Tester** — the Tester receives the Developer's full JSON return as part of their prompt. They use it as a starting map: which files to read, which routes to exercise, what design assumptions to probe. They do NOT take the Developer's word for anything — they verify by reading the code and running the build.
- **Tester → Writer** — the Writer receives both the Developer's report and the Tester's findings. They consume the findings as a structured list and render them into a "Known issues" section in the doc, verbatim by severity. They describe the code from the code, not from either prior role's narrative.

The wall is enforced not by polite instruction but by the JSON contract — schemas at the tool-call layer force each role to return structured data, which the next role consumes by field. Drift across the wall would require an agent to ignore its schema, and the schemas are validated.

## Variations and extensions

- **Fix-and-verify loop-back.** When the Tester files a finding the user wants closed, run a second pipeline with a **Fixer** (a fresh Developer-role agent with the findings as input) and a **Verifier** (a fresh Tester-role agent that independently confirms each fix and updates the security doc to move resolved items to a Resolved section). Two phases, two commits, the same accountability wall. See `/docs/image-security.md` for an example of the doc structure post-loop.
- **Empowered writer.** For content edits where review would be friction (an in-universe wiki body rewrite, marketing copy, narrative work), tell the Writer they may "edit directly with no confirmation or review." They will not ask clarifying questions or leave TODO markers; they will just ship.
- **Functional vs. security split.** For high-stakes features you can split the Tester into two roles — a Functional Tester and a Security Tester — running in parallel after the Developer (use worktree isolation to avoid index locking). Aggregate findings before the Writer.
- **Triage gate.** Insert a triage step between Tester and any follow-on Fixer that decides which findings get sent back to a dev versus shipped as known issues. Useful when severities are mixed and a partial fix is the right call.

## Anti-patterns to avoid

- **Vague feature briefs.** "Add comments" is not a feature brief. "Add a `comments` table with `article_slug, author, body, created_at`, render the list under each article body, no edit/delete in v1" is. The Developer agent will not ask clarifying questions — they will make assumptions. Make sure the assumptions you would want are the ones you would get.
- **Cross-lane edits.** If you find yourself tempted to tell the Tester to fix one little thing, do not. Run a loop-back instead. The wall stops working the moment someone is allowed to cross it.
- **Skipping build verification.** The build check is not ceremony — it is the cheap proof that the Developer at least produced compiling code. A pipeline that does not enforce it will surface the failure later, more expensively.
- **Over-scoping a single run.** Three roles, one feature, ten to fifteen minutes wall clock. If your feature is bigger than that, decompose it into multiple pipelines; do not stretch one run.

## What you get at the end

- Three commits on `dev-refresh`, one per role, each touching only that role's domain.
- A working feature, committed and ready for the standard App-Layer deploy (`gcloud builds submit` → `gcloud run services update` on both Cloud Run services).
- A `/docs/<feature>.md` documenting the design.
- Per-directory `readme.md` updates so future readers find their way.
- A structured findings list as JSON in the workflow result (and optionally as `/docs/<feature>-security.md`), which can feed a follow-up fix-and-verify loop.

Push, deploy, and the feature is live. The wall held; the lanes were clear; the day shipped.
