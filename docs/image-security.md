# Image Security — per-article portraits

A focused security review of the image-handling model on the Yamato wiki, written against commit `80e47d2` on `dev-refresh`. That commit added a per-article profile portrait slot to `/wiki/<slug>` and seeded `app/yamato/static/img/articles/` with seven JPEGs (six copied from `crew/`, plus a `sips`-derived JPG of the existing hero PNG). This document is the *why* alongside the *what* — the threat model, the findings, what is genuinely safe, and what would need to change if a "real" upload feature ever shipped.

## What this app does with images

Yamato never accepts user-uploaded images. The supply chain is **maintainer-driven**:

1. A maintainer drops a `.jpg` named after an article slug into `app/yamato/static/img/articles/<slug>.jpg` and commits it to the repo.
2. The next container build runs `go build`; the binary embeds the entire `static/` tree via `//go:embed static` (see `app/yamato/app.go` line 14).
3. At runtime, `http.FileServerFS` serves anything under that embedded sub-FS at the public URL `/static/...` (see the `staticRoot` block in `routes()`, `app/yamato/app.go` lines 55–56).
4. The article template requests `/static/img/articles/{{.Article.Slug}}.jpg`. When the file exists the browser renders the portrait; when it 404s the inline `onerror="this.parentElement.remove()"` quietly drops the entire `<figure>` so the body still leads (see `app/yamato/templates/article.html` lines 8–10).

There is **no schema column, no DB query, no server-side existence check, and no resize/transcode step**. The slug-to-file lookup is the whole mechanism. The slug rendered into the `src` attribute is the value read back from the `articles` table (`store.get`, `app/yamato/db.go` line 200), which means the slug rendered into HTML is always a value the DB has already accepted as a primary key — never raw URL input. The `html/template` engine attribute-escapes the slug on its way into the `src` so even a hypothetical hostile slug could not break out of the attribute.

`/static/*` is **public** — it is registered on the un-gated mux path that the load balancer routes outside the IAP backend. Only `/wiki`, `/wiki/*`, and `/noc/*` sit behind IAP. So any file dropped into `static/` is reachable to the open internet, IAP or not.

## Threat surface today

Because the only path into the served filesystem is a maintainer commit, today's threat model is essentially **supply-chain**: what could a contributor (or a compromised contributor laptop, a stale Slack DM that lands in someone's downloads folder, an AI tool generating "helpful" art) drop into the tree that the next deploy would happily serve?

The categories that matter for a static-bytes pipeline are:

- **Format risk** — a hostile file that decodes to executable behavior in some browser context. SVG is the headline; polyglot files (PNG-that-is-also-HTML) are the long tail.
- **Serving risk** — the way the bytes leave the server: content-type sniffing, content-disposition, the path namespace, whether IAP is or is not in front.
- **Supply-chain hygiene** — whether the file shipped is what the maintainer thinks shipped (byte-identity), and whether the maintainer had the rights to ship it at all.
- **Metadata** — what the file carries inside it (EXIF GPS, camera serial, source software) and whether that constitutes accidental disclosure.
- **DoS / resource** — files large enough to bloat the container image, cold start, or per-request bandwidth.

Browser-side script execution from a raw `<img src=*.jpg>` is **not** a realistic vector — the image decode happens in a sandboxed pipeline and a JPEG cannot run code at decode time absent a libjpeg CVE in the user's browser, which is out of scope for this app.

## Findings from this review

### F-1 — `/static/*` is missing `X-Content-Type-Options: nosniff` (medium)

`http.FileServerFS` infers `Content-Type` from the file extension and serves the bytes raw. No middleware in `app/yamato/app.go` or the LB module (`service/yamato/modules/frontdoor/`) sets `X-Content-Type-Options: nosniff` on the response. Older browsers — and a handful of edge cases in modern ones — will run MIME sniffing on the body and can promote a file whose extension is `.jpg` but whose bytes look like HTML/JS to `text/html`, turning a static asset into a stored-XSS vector on the `simplifymy.cloud` origin. That this is a *maintainer* upload pipeline shrinks the population of attackers, but the mitigation is one line of middleware and would close the polyglot-file class entirely. Recommendation: wrap the `/static/` handler in a middleware that always sets `X-Content-Type-Options: nosniff`, and consider `Content-Security-Policy: default-src 'none'; img-src 'self'` scoped to `/static/img/*`. *Out of scope for this PR — file as a follow-up.*

### F-2 — file extension whitelist is convention-only (low)

The article template hardcodes a `.jpg` extension in the `<img src>`, but `http.FileServerFS` will serve *anything* under `static/img/articles/` regardless of extension. Today the directory contains only the seven JPEGs the developer dropped in. There is no build-time check that, say, a `.svg`, `.html`, or `.js` accidentally placed under `static/img/articles/` would be refused service. SVG in particular is XML and can carry `<script>` that *does* execute when an SVG is referenced via `<iframe>`, `<object>`, or inlined into HTML — though a browser will *not* execute scripts inside an SVG referenced via `<img src=*.svg>`. The current template uses the safer `<img>` path, but the directory itself is permissive. Recommendation: either a CI lint that whitelists extensions under `static/img/`, or — better — a small Go init() in `app.go` that walks the embedded FS at startup and rejects unknown extensions before `ListenAndServe`. *Forward-looking; no live exposure today.*

### F-3 — EXIF metadata is intact on all seven seed images (low / info)

The committed JPEGs were not stripped of EXIF before commit. A segment-by-segment scan shows:

- `captain-avatar.jpg` — APP1/Exif (98 B): orientation, X/Y-resolution, YCbCrPositioning. No GPS.
- `derek-wildstar.jpg` — no APP1.
- `iq-9.jpg` — APP1/Exif (42 B): a single tag, `Software = "Google"` (the file originated from a Google Image Search download).
- `mark-venture.jpg`, `nova.jpg` — no APP1.
- `sandor.jpg` — APP1/Exif (4094 B): orientation, resolution, ExifVersion 0220, FlashpixVersion 0100, ColorSpace, PixelXY, GainControl. **No GPS, no Make/Model, no DateTime, no embedded thumbnail of size.** The 4 KB length is dominated by padding and standard color/sRGB tags.
- `space-battleship-yamato.jpg` — APP1/Exif (176 B): orientation, resolution, ExifVersion 0210 — the residue from `sips`'s JPEG encoder.

No GPS coordinates, camera serial numbers, or human-readable PII are present in any file. The `Software = "Google"` tag on `iq-9.jpg` is a minor sourcing tell but not a security issue. **No finding worth a fix; documenting that the EXIF was reviewed.** A future maintainer-checklist item might be "strip EXIF on commit" (`exiftool -all=` or a pre-commit hook), but the cost/benefit at current volume does not justify it.

### F-4 — `.DS_Store` files are embedded into the binary (low)

`//go:embed static` is recursive and follows the directory tree literally. The repo currently contains `static/.DS_Store`, `static/img/.DS_Store`, and `static/img/crew/.DS_Store` (all macOS Finder droppings). These are baked into the running binary and served on `GET /static/.DS_Store` as `application/octet-stream`. `.DS_Store` files are known to leak directory listings — they are why every static-site how-to tells you to add them to `.gitignore`. Today they expose the names "img", "crew", "articles", "README.md", and the seven JPGs — which a curious user could already discover by guessing slugs. So the disclosure delta is small, but the right answer is a repo-wide `.gitignore` entry and a `go:embed` pattern that excludes them. *Tracked as a small follow-up.*

### F-5 — slug-keyed paths leak the article list pre-IAP (info)

Of the 15 article slugs the developer covered in `article_image_map`, **7** have a real JPG and **8** fall back to the figure-removed state. The `/static/img/articles/` namespace is **outside IAP**, so anyone on the open internet can `GET /static/img/articles/captain-avatar.jpg` and confirm "captain-avatar" is an article. The article *body* stays behind IAP — only the slug is leaked, and only the seven slugs that have art. The slug list is also already public via the seeded `schema.sql` in the repo, so this is not a new disclosure. **Posture: by-design, no fix.**

### F-6 — no license-risk seed art shipped (info / clean)

The developer's `article_image_map` claims `copied-from-crew` for six entries and `copied-from-hero` for `space-battleship-yamato.jpg`. Hash-verified:

| article slug | source file | SHA-1 |
| --- | --- | --- |
| `captain-avatar` | `static/img/crew/captain-avatar.jpg` | `96b76c0…2a42d392` (matches) |
| `derek-wildstar` | `static/img/crew/derek-wildstar.jpg` | `0576d71…ca165` (matches) |
| `iq-9` | `static/img/crew/iq-9.jpg` | `8081af7…baffc` (matches) |
| `mark-venture` | `static/img/crew/mark-venture.jpg` | `6a8dbb5…42a94c` (matches) |
| `nova` | `static/img/crew/nova.jpg` | `4595a8c…707a37` (matches) |
| `sandor` | `static/img/crew/sandor.jpg` | `bfcca7f…b349780` (matches) |

All six "copy" claims are byte-identical to their source — no silent re-encode, no EXIF mangling, no tool tampering. The ship image is a `sips`-transcoded derivative of the already-shipped `yamato.png` hero and is therefore covered by whatever licensing chain that file is under (per `app/yamato/static/img/README.md`, "owned/licensed/original-derivative only"). The remaining 8 slugs ship no image — `wave-motion-engine`, `wave-motion-gun`, `cosmo-dna`, `the-mission`, `iscandar`, `queen-starsha`, `leader-desslok`, `gamilon-empire` — and the `onerror` removes their figure, which is the right call: no franchise stills were introduced. **Clean.**

### F-7 — embedded payload growth is well within Cloud Run budget (info)

The seven new files total **656 KB** (`72,643 + 73,020 + 44,137 + 36,304 + 43,513 + 56,199 + 346,016` bytes). The post-build `app/yamato/yamato` binary is ~31 MB. The largest single file is `space-battleship-yamato.jpg` at 346 KB / 1920×960 — large for a portrait that renders at 168 px, but a one-time cold-start cost only, not a per-request one. No file exceeds 1 MB. There is no realistic DoS or cold-start risk from this change. *Not a finding.* A future cleanup could resize the ship image down to the portrait dimensions it actually renders at.

### F-8 — no SVG anywhere, no inline `<svg>` blocks in templates (info / clean)

A grep for `.svg` and inline `<svg>` across `app/yamato/templates/` and `static/img/` returns nothing for the new code. The crew avatars and article portraits are all JPG. The only inline SVG previously in the templates is the decorative `.ship` fallback on the landing page, which has no `<script>` or external references. **Clean — SVG is not part of this app's attack surface today.**

## Posture and residual risk

What's clean:
- No SVG, no polyglot opportunity in the formats actually used.
- `http.FileServerFS` over a `go:embed` `fs.FS` is path-traversal-safe by construction — there is nothing outside the embed root for `../` to escape to.
- The slug rendered into the `img src` is the DB primary key (validated upstream), and `html/template` attribute-escapes it.
- EXIF on the seed images is shallow — no GPS, no PII, no embedded thumbnails of size.
- All "copied-from-crew" / "copied-from-hero" claims are byte-identical to source.
- No franchise art was introduced — the developer let the 8 license-blocked slugs render image-less rather than guess.

What's a nit:
- F-1 (`nosniff`) and F-2 (no extension whitelist) are both single-line fixes worth doing the next time someone is in `app.go`.
- F-4 (`.DS_Store` files embedded) is a `.gitignore` change.
- F-3 (EXIF kept) is fine at current volume; would become a checklist item if the seed grew.

What's deferred:
- A real maintainer pre-commit hook that strips EXIF, whitelists extensions, and `file(1)`-verifies the magic bytes match the claimed extension. Worth ~20 minutes the next time `cloudbuild.yaml` or pre-commit config is touched.

## Future state — if user uploads ever happen

This app does not have an upload endpoint and there is no plan in the seed to add one. *If* a future feature ever lets a signed-in operator upload an image (say, a "set article hero" button on `/wiki/<slug>`), the threat model changes entirely and every item on the following checklist becomes a hard requirement:

- **Authenticate the writer.** IAP identity from `X-Goog-Authenticated-User-Email` is necessary but not sufficient — verify the IAP JWT (`X-Goog-IAP-JWT-Assertion`) signature, not just the header, so a stripped-IAP cluster cannot accept anonymous writes.
- **Constrain on the wire.** `http.MaxBytesReader` per-request, multipart-form size cap, single-file-per-request, explicit per-user rate limit.
- **Server-side format whitelist by magic bytes**, not by `Content-Type` header and not by extension. `net/http.DetectContentType` is OK as a starting filter but should be paired with a real decoder (`image/jpeg.Decode`, `image/png.Decode`) to *prove* the file is what it claims.
- **Re-encode through a known-safe library.** Decode → re-encode produces a fresh JPG/PNG byte stream with no leftover metadata, no embedded scripts, no polyglot prefix. This is the single highest-leverage defense.
- **Strip EXIF / IPTC / XMP** as part of the re-encode (it falls out naturally if you decode pixels and re-encode).
- **Resize/clip to declared bounds.** Reject inputs whose decoded dimensions exceed a sensible cap (e.g. 4096×4096) — image-decompression-bomb defense.
- **Store outside the served filesystem.** Write to a GCS bucket with `uniformBucketLevelAccess` and `publicAccessPrevention`, then serve through a signed URL or a same-origin handler that sets `Content-Type` and `Content-Disposition` itself. Do *not* `go:embed` user content.
- **Set `X-Content-Type-Options: nosniff` and `Content-Security-Policy: default-src 'none'; img-src 'self'`** on the response path that serves the user content, ideally also `Content-Disposition: inline; filename="..."` with a server-controlled filename.
- **Quarantine.** A virus-scan step (e.g. ClamAV via Cloud Run Jobs) before promoting the upload from quarantine to serve. Belt-and-suspenders on top of re-encode.
- **Audit.** Every upload writes a Cloud Logging entry with the IAP identity, the SHA-256 of the bytes accepted, and the resulting object path, so a malicious commit can be reconstructed.

None of this applies today. Documenting it here so that the first PR that proposes user uploads has a checklist to review against, rather than rediscovering each item under fire.

## See also

- `app/yamato/app.go` — `staticFS` embed and the `GET /static/` mount.
- `app/yamato/templates/article.html` — the `<figure class="article-portrait">` block.
- `app/yamato/static/img/README.md` — the maintainer-facing rules for what art can be dropped in.
- `docs/infrastructurestate.md` — the Service / Application Layer boundary that explains why this is an app-layer change with no Terraform touched.
- `docs/security/zero-trust-iap.md` — what *is* gated by IAP, and what (like `/static/*`) is intentionally not.
