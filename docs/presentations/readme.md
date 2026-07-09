# Presentations

Slide decks and supporting material for talks / consulting pitches. Written as
markdown so the words iterate cleanly in git; the render target (Marp, reveal.js,
Google Slides) is chosen per deck when it's time to present.

## Files

- **[`deck.md`](./deck.md)** — *Life of a Packet: How GCP protects a private VM
  from a network that watches everything.* 25 slides. The consulting deck.
  Walks a single SSH packet from David Lightman's MacBook at the NORAD infirmary
  through six layers of GCP defense to a private GCE VM in `us-east1` and back,
  then proves the same six layers in production against real-world attackers on
  the Yamato Wiki (`yamato-dev.iq9.io`).

## Conventions (all decks in this directory)

- **`---` on its own line** separates slides. Compatible with Marp, reveal.js,
  and plain-markdown viewing on GitHub.
- **`# Slide title`** at the top of each slide.
- **Speaker notes** live in a blockquote prefixed `> **Speaker notes:**` — reads
  fine as prose on GitHub, converts to Marp/reveal speaker-note syntax when a
  render target is picked.
- **Image placeholders** are bracketed hints:
  `[HERO IMAGE: <description>]`, `[DIAGRAM: <description>]`,
  `[SCREENSHOT: <description>]`. Replace one line each with
  `![alt](img/foo.png)` when the pictures land.
- **Diagrams** use fenced ASCII boxes for the mockup phase and Mermaid fenced
  blocks for anything that needs to render as a real diagram. GitHub renders
  Mermaid inline.

## Rendering the decks (when the words are ready)

Any of these works — pick per audience:

```bash
# Marp CLI → HTML or PDF (local presenter, git-friendly)
brew install marp-cli
marp docs/presentations/deck.md -o deck.pdf

# Marp + GitHub Actions + Pages → hosted slides at a URL (share with prospects)
# See marp-team/marp-cli-action for the workflow file.

# Google Slides → paste per-slide from deck.md (team-editable, no tooling)
```

## Next-up decks (candidates, not committed to)

- A **short-form** cut of `deck.md` (~10 slides) for lightning talks and gate
  conversations
- **Multi-agent playbook** as its own deck (the pattern from
  [`../multi-agent-playbook.md`](../multi-agent-playbook.md), told as a deck)
- **In-the-wild evidence** slides (deep-dive companion to
  [`../security/in-the-wild-2026-06-03.md`](../security/in-the-wild-2026-06-03.md))
