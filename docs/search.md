# Wiki Search

The full-text search behind `/wiki/search` on the Yamato wiki. This document is the *why* and the *how* — the user-visible behavior, the request lifecycle, the schema, the security posture, and the open issues. The route lives in the **Application Layer** (Go on Cloud Run); no Terraform was touched to add it.

## What it does, from the user's chair

A signed-in `@iq9.io` operator lands on the wiki index at `/wiki`. Under the lede is a search form; there is also a dedicated search page at `/wiki/search` with the same form and a results panel. Submitting either form GETs `/wiki/search?q=<term>` and renders a list of matching articles — title, category, and a short snippet from the body with the matched terms wrapped in `<mark>` tags. Each hit is a link straight to the article. An empty `q` renders the form with a prompt; a non-matching `q` renders "No records matched." Nothing about the search surface is reachable to a public visitor — the entire `/wiki` prefix is IAP-gated, and `/wiki/search` is just another sub-path of that gate.

The search is forgiving on input. The query is run through `plainto_tsquery`, which tokenizes raw user text and ANDs the terms; it does not surface tsquery operator syntax, so `&`, `|`, `!`, and `:` in the box are treated as literal characters and never trigger a SQL parse error. Whitespace is trimmed, the cap is 200 characters (silently truncated, not 400'd), and result pages are capped at 50 rows.

## Request lifecycle

```
GET https://yamato.<domain>/wiki/search?q=wave+gun
        |
        v
External HTTPS LB    (service/yamato/dev/frontdoor)
        |  url_map path_matcher "main"
        |  path_rule paths = ["/wiki", "/wiki/*"]  -> wiki backend
        v
Cloud Armor policy   (8 OWASP WAF rules + per-IP rate limit, ENFORCE)
        |
        v
IAP                  (domain:iq9.io on the wiki backend service)
        |  injects X-Goog-Authenticated-User-Email
        v
Cloud Run service    iq9-run-dev-yamato-wiki   (Direct VPC egress)
        |
        v
stdlib ServeMux      app/yamato/app.go
        |  mux.HandleFunc("GET /wiki/search", a.handleSearch)
        v
handleSearch         app/yamato/handlers.go
        |  trim, length-cap, empty-state short-circuit
        v
store.search         app/yamato/db.go
        |  parameterized plainto_tsquery + ts_rank + ts_headline
        v
Cloud SQL Postgres   (private IP, dialed via cloudsqlconn WithPrivateIP)
        |
        v
renderSnippet        html.EscapeString -> swap sentinels for <mark>
        v
templates/search.html  rendered via html/template (auto-escape)
        |
        v
HTML response back through Cloud Run -> IAP -> LB -> browser
```

A couple of notes on that picture. `/wiki/search` is registered on **the same `http.ServeMux`** that serves `/wiki` and `/wiki/{slug}` (see `app/yamato/app.go`); the stdlib mux resolves the static path before the wildcard `/wiki/{slug}`, so the search route is reached without a precedence trick. IAP scoping is enforced at the LB by path-rule, not in the app — the url_map sends `/wiki` and `/wiki/*` to the IAP-gated backend, so `/wiki/search` inherits that gate by virtue of its prefix (see `service/yamato/modules/frontdoor/frontdoor.tf` around line 274). The app does not consult `X-Goog-Authenticated-User-Email` for authorization; it reads it only to greet the user in the topbar.

## The schema

The full-text index lives in `app/yamato/schema.sql`, alongside the table it indexes. The schema file is embedded into the binary and applied idempotently on every app startup (see `app/yamato/db.go`, `newStore`), so the table, the column, the index, the function, and the trigger all come into existence the first time a new revision boots, and every subsequent boot is a no-op.

```sql
ALTER TABLE articles ADD COLUMN IF NOT EXISTS tsv tsvector;

CREATE INDEX IF NOT EXISTS articles_tsv_idx ON articles USING GIN (tsv);

CREATE OR REPLACE FUNCTION articles_tsv_refresh() RETURNS trigger AS $$
BEGIN
    NEW.tsv :=
        setweight(to_tsvector('english', coalesce(NEW.title, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(NEW.body,  '')), 'B');
    RETURN NEW;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS articles_tsv_trg ON articles;
CREATE TRIGGER articles_tsv_trg
    BEFORE INSERT OR UPDATE OF title, body ON articles
    FOR EACH ROW EXECUTE FUNCTION articles_tsv_refresh();
```

Four things are worth calling out.

**`tsv` is a regular column, kept in sync by a trigger.** It is not a `GENERATED ALWAYS` column. The trigger fires `BEFORE INSERT OR UPDATE OF title, body`, which means any path that writes a row — the embedded seed, a future admin page, a one-off `INSERT` — populates the vector automatically. There is no separate backfill step. The existing seed at the bottom of `schema.sql` ends with `ON CONFLICT (slug) DO UPDATE SET title = EXCLUDED.title, body = EXCLUDED.body, ...`; that UPDATE fires the trigger, so every redeploy refreshes `tsv` for every seeded article, even rows that pre-date the column.

**Title is weighted higher than body.** `setweight(..., 'A')` for the title and `'B'` for the body biases ranking so an article whose title matches the query sorts above one where the term only appears deep in the body. The four-tier weight system (A/B/C/D) is fixed in Postgres; only A and B are used here because there is no third or fourth field to index.

**The GIN index on `tsv` is what makes the search fast.** Without it, `tsv @@ plainto_tsquery(...)` would sequence-scan the table; with it, lookups are near-constant relative to the number of articles. The seed is currently 16 rows so this is academic, but the index is correct regardless of size.

**The whole block is re-runnable.** `ADD COLUMN IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`, `CREATE OR REPLACE FUNCTION`, and `DROP TRIGGER IF EXISTS` + `CREATE TRIGGER` together guarantee that re-applying the schema is a no-op. This matters because the app *is* the migrator — there is no out-of-band psql path to the private-IP instance — so the schema runs on every cold start of every revision.

## Postgres full-text search choices

The query in `app/yamato/db.go` is:

```sql
SELECT slug,
       title,
       category,
       ts_headline(
           'english',
           body,
           plainto_tsquery('english', $1),
           'StartSel=' || $3 || ', StopSel=' || $4 || ', MaxFragments=2, MaxWords=18, MinWords=6, ShortWord=3, HighlightAll=FALSE'
       ) AS snippet
FROM articles
WHERE tsv @@ plainto_tsquery('english', $1)
ORDER BY ts_rank(tsv, plainto_tsquery('english', $1)) DESC,
         title ASC
LIMIT $2
```

A few deliberate choices.

**`plainto_tsquery`, not `to_tsquery` or `websearch_to_tsquery`.** `plainto_tsquery` accepts arbitrary user text, tokenizes it, drops stop words, applies the configured stemmer, and ANDs the surviving terms. It ignores any operator syntax the user might type, which is exactly the behavior wanted for a public-ish search box: the user types whatever they think, the database does its best, and there is no failure mode where a stray `:` or `&` produces a SQL-level error visible to the caller. `websearch_to_tsquery` would support `OR` and quoted phrases, which is a real upgrade if and when that's wanted; for now the simpler tokenizer is the right default.

**The `english` text-search configuration.** Both `to_tsvector` and `plainto_tsquery` are invoked with the `'english'` config. That selects the English stemmer (so `gun`, `guns`, `gunning` collapse to a common stem) and the English stop-word list (so `the`, `of`, `and` and friends are dropped before ranking). The seed is entirely English. If a future article ships in another language, the obvious upgrade is a per-row `language` column with a `regconfig` cast, or `simple` for content where stemming would do more harm than good — but that's a future change, not a today change.

**`ts_rank` for ordering, title for tiebreak.** `ts_rank` scores how densely the query terms appear in the indexed vector, weighted by the A/B/C/D buckets the vector was built with. Because the title is in bucket A and the body is in bucket B, an article whose title matches wins over one whose body matches at the same density. Equal-rank rows tie-break by `title ASC` so the order is deterministic across runs (no surprise reshuffles between page loads).

**`ts_headline` for snippets.** `ts_headline` runs across the *body* (not the vector — `ts_headline` does its own tokenization) and returns a fragment of text with the matched terms wrapped in the start/end markers you give it. The options string asks for at most two fragments, 18 words each minimum 6, with no full-document highlight. Importantly, the markers are **not** literal `<mark>` HTML. They're sentinel strings — `{{HL_START}}` and `{{HL_END}}` — chosen so they cannot appear in real article text and so `html.EscapeString` leaves them untouched. The Go side escapes the whole snippet first and *then* swaps the sentinels for `<mark>` tags, which is what keeps body content from ever injecting markup. See "Security posture" below.

**Result cap and column choice.** `LIMIT 50` is enforced by the constant `maxSearchResults` in `app/yamato/handlers.go`. The select list is intentionally narrow — slug, title, category, snippet — so that even a very-broad query (`"the"`, which would match every English article) returns at most 50 short rows rather than 50 full bodies.

## Security posture

Four layers protect the search surface.

**Parameterized queries.** The user's `q` enters SQL as `$1` in `app/yamato/db.go`; the result limit is `$2`; the snippet sentinels are `$3` and `$4`. Nothing from the request is ever interpolated into the SQL string. Even if `q` is `"; DROP TABLE articles; --`, Postgres will see it as a single text literal and hand it to `plainto_tsquery`, which will tokenize it into harmless words.

**IAP at the front door.** The url_map routes `/wiki` and `/wiki/*` to the IAP-protected backend service (`service/yamato/modules/frontdoor/frontdoor.tf`, the `path_rule` around line 274), and IAP is bound to `domain:iq9.io`. `/wiki/search` is a child of that prefix, so it inherits the gate without a separate IAP backend configuration. A request from an unauthenticated browser is intercepted before it reaches Cloud Run; the app's handler is only ever invoked for a verified identity.

**HTML auto-escaping at render.** `templates/search.html` is parsed via Go's `html/template`. Every `{{.Query}}` and `{{.Title}}` interpolation is auto-escaped — a query of `<script>` round-trips back to the input box as `&lt;script&gt;`. The only field that is allowed to carry markup is the snippet, and it does so as `template.HTML`, which Go specifically refuses to auto-escape; the safety of that channel is enforced upstream in `renderSnippet` (see below).

**Snippet hardening.** `renderSnippet` in `app/yamato/handlers.go` takes the raw `ts_headline` output, runs the whole string through `html.EscapeString` (so any `<`, `>`, `&`, `'`, `"` in the body becomes its HTML entity), and *then* swaps the sentinel pairs `{{HL_START}}` and `{{HL_END}}` for `<mark>` and `</mark>`. The order matters: escape first, swap second. Because the sentinels contain only characters that `html.EscapeString` passes through unchanged (`{`, `}`, `_`, ASCII letters), they survive the escape step intact and can be replaced with real tags. The result is `template.HTML` — already-safe markup — that the template emits verbatim.

**Length cap.** The 200-character ceiling in `maxSearchQueryLen` prevents a pathological request from constructing a multi-megabyte `tsquery`. It is not a security guarantee — `plainto_tsquery` is bounded internally — but it costs nothing and keeps logs readable.

## Edge cases the handler covers

- **Empty `q` or whitespace-only `q`.** `strings.TrimSpace` reduces both to `""`; the handler short-circuits before touching the database and renders the empty-state copy.
- **`q` longer than 200 characters.** Truncated to 200 (see "Known issues" — the truncation is byte-wise, which is a bug).
- **`q` with no matches.** `tsv @@ plainto_tsquery(...)` returns no rows; the template renders "No records matched."
- **`q` containing tsquery operator syntax.** `plainto_tsquery` ignores it; the term reaches the index as a plain word.
- **`q` containing HTML.** Auto-escaped on echo-back into the input box, and the body it searches is also escaped on snippet rendering. No markup escapes the safe channel.
- **Article body containing the sentinel literals.** Extremely unlikely (the sentinels are `{{HL_START}}` / `{{HL_END}}`), but if it ever did, the worst case is spurious `<mark>` tags around unrelated text — never an injection.

## Known issues

These were flagged in review. They are documented here so they don't get lost; the fixes have not been applied.

- **F-001 (medium, functional)** — The query-length truncation in `app/yamato/handlers.go` is byte-wise (`q = q[:200]`), not rune-wise. A pasted string of 198 ASCII characters followed by a 4-byte emoji is valid UTF-8 at 202 bytes but invalid at 200 bytes after the slice, and Postgres rejects it with `invalid byte sequence for encoding "UTF8"` — surfacing as an HTTP 500 instead of the silent truncation the design promised. Fix: truncate over `[]rune(q)` or walk with `for i, r := range q` to find the byte index of the cap-th rune.
- **F-002 (low, quality)** — The `ts_headline` options string in `app/yamato/db.go` is assembled at SQL evaluation time via `||` concatenation with the sentinel constants. The options grammar uses `,` and `=` as delimiters; today's sentinels happen to contain neither, but the dependency between the Go-side constants and the SQL-side grammar is not enforced anywhere. A future rename that introduces `,` or `=` into the sentinels would silently mis-parse. Fix: build the options string in Go and pass it as a single parameter, or add a package-`init` assertion that the constants contain neither character.
- **F-003 (low, quality)** — The 200-character cap is duplicated three times: the `maxSearchQueryLen` constant in `app/yamato/handlers.go`, and `maxlength="200"` on the search inputs in `app/yamato/templates/search.html` and `app/yamato/templates/wiki_index.html`. The HTML attribute is only a client-side hint, but the values can drift. Fix: pass `MaxLen: maxSearchQueryLen` into the template data and template the attribute, or add a comment on the constant naming the two templates.

## Adding a new article (and having it become searchable)

There is no "rebuild the index" step. To add a new article, append a row to the `INSERT INTO articles ... VALUES ...` block at the bottom of `app/yamato/schema.sql`. On the next redeploy, the schema runs on app startup, the `INSERT` fires the `articles_tsv_trg` trigger, `articles_tsv_refresh()` computes the new row's `tsv` from its title and body, and the row drops into the GIN index. The next query against `/wiki/search` finds it.

The same is true for edits to existing articles: the seed uses `ON CONFLICT (slug) DO UPDATE SET title = EXCLUDED.title, body = EXCLUDED.body, ...`, the UPDATE fires the trigger, and the vector is refreshed in place.

## Future extensions

A few things this implementation has intentionally not done, with notes on how to layer them on later.

- **Phrase / boolean search.** Swap `plainto_tsquery` for `websearch_to_tsquery`, which adds quoted phrases and the `OR` keyword without changing the index. The ranking and snippet code are unaffected.
- **Multi-language content.** Add a `language regconfig` column on `articles`, defaulting to `'english'`, and use it in both the trigger (`to_tsvector(NEW.language, ...)`) and the query (`to_tsvector(language, body)` joined against `to_tsquery(<query-language>, ...)`). The index can remain a single GIN on `tsv` so long as the trigger writes a consistent vector.
- **Suggest-as-you-type.** Either a debounced fetch against `/wiki/search?q=...` rendering a small dropdown, or a separate `/wiki/suggest` route that returns titles via `ILIKE` or `pg_trgm`. The latter wants its own GIN/GiST `pg_trgm` index on `title`.
- **Fuzzy / typo-tolerant match.** `pg_trgm`'s `<%>` or `%` operators against `title` give you "close" matches; combined into a `UNION ALL` with the current `tsv @@` query, you get FTS where it's available and trigram similarity as a fallback. Worth the complexity only if title typos become a real complaint.
- **Per-category facets.** Group results in the template by `category` (which is already in the result row) and render section headings; no schema change needed.
- **Search analytics.** Log `q`, hit count, and IAP identity from the handler for trend analysis. Be deliberate about the retention and the PII surface of logged identity before turning this on.

## Files at a glance

| File | Role |
| --- | --- |
| `app/yamato/schema.sql` | Adds `tsv` column, GIN index, trigger function, and trigger; seed naturally backfills. |
| `app/yamato/db.go` | `store.search()` — parameterized FTS query with `ts_rank` ordering and `ts_headline` snippets. |
| `app/yamato/handlers.go` | `handleSearch`, `renderSnippet`, `maxSearchQueryLen`, `maxSearchResults`. |
| `app/yamato/app.go` | Route registration: `mux.HandleFunc("GET /wiki/search", a.handleSearch)`. |
| `app/yamato/templates/search.html` | Dedicated search page (form + results panel). |
| `app/yamato/templates/wiki_index.html` | Adds a second search form under the lede. |
| `app/yamato/static/style.css` | `.search-form`, `.search-results`, `.hit`, `.hit-cat`, `.hit-snippet`, and `mark` styling. |
| `service/yamato/modules/frontdoor/frontdoor.tf` | url_map `path_rule` for `/wiki` + `/wiki/*` — gates `/wiki/search` via IAP by prefix. |
