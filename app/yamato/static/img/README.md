# Landing images — drop your own licensed art here

The app embeds the whole `static/` directory (`//go:embed static`), so any file you
add here is served at `/static/img/...` on the next image build + deploy. **Use art
you have the rights to** (licensed or owned); the built-in placeholders are original.

The landing page (`/`) references these and **falls back gracefully** if a file is
absent — so the page always looks complete:

- **`yamato.png`** — hero image, top-center of `/`.
  Falls back to the original SVG battleship if missing.
  Suggested: wide, ~1200px, transparent or dark background.

- **`crew/<slug>.jpg`** — square avatar in each crew card.
  Falls back to the character's initials badge if missing.
  Slugs: `captain-avatar`, `derek-wildstar`, `nova`, `mark-venture`, `sandor`, `iq-9`
  Suggested: square (e.g. 256×256), face-centered.

After adding files: rebuild the image (`gcloud builds submit app/yamato …`) and roll
both Cloud Run services onto it — the new images appear automatically.
