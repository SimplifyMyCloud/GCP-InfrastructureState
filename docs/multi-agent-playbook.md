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
