# Landing & article images — drop your own licensed art here

The app embeds the whole `static/` directory (`//go:embed static`), so any file you
add here is served at `/static/img/...` on the next image build + deploy. **Use art
you have the rights to** (licensed or owned); the built-in placeholders are original.

Every image slot **falls back gracefully** when its file is absent — so the page
always looks complete:

- **`yamato.png`** — hero image, top-center of `/`.
  Falls back to the original SVG battleship if missing.
  Suggested: wide, ~1200px, transparent or dark background.

- **`crew/<slug>.jpg`** — square avatar in each crew card on `/`.
  Falls back to the character's initials badge if missing.
  Slugs: `captain-avatar`, `derek-wildstar`, `nova`, `mark-venture`, `sandor`, `iq-9`
  Suggested: square (e.g. 256×256), face-centered.

- **`articles/<slug>.jpg`** — per-article profile image on `/wiki/<slug>`.
  The article template requests `/static/img/articles/{{.Article.Slug}}.jpg`
  for the article being rendered, and the `<figure>` is removed via `onerror`
  if the file is missing — so the article body leads on its own for slugs
  without art. Currently populated for the slugs whose crew portraits already
  exist (copied from `crew/`) plus the ship hero (`space-battleship-yamato.jpg`,
  converted from `yamato.png`). All other slugs in the seed render image-less
  until licensed art is dropped in:
  - Technology: `wave-motion-engine`, `wave-motion-gun`, `cosmo-dna`
  - Voyage: `the-mission`
  - Worlds: `iscandar`
  - Characters: `queen-starsha`, `leader-desslok`
  - Factions: `gamilon-empire`
  Suggested: square or near-square (e.g. 512×512), subject centered — it is
  cropped into a 168px circular portrait at the top of the article.

## Adding new images

1. Drop a `.jpg` named exactly `<slug>.jpg` into `articles/` (slug matches the
   `articles.slug` column in `schema.sql`).
2. Confirm you have the rights to the image — **no franchise stills, production
   art, or toy/box art**. Owned, licensed, or original-derivative only.
3. Rebuild the container image (`gcloud builds submit app/yamato …`) and roll
   the Cloud Run services onto it — the new image appears automatically.

No code, schema, or DB change is required: the slug → file lookup is the entire
mechanism.
