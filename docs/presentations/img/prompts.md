# Image Prompt Sheet — Life of a Packet deck

*Paste any of these into Midjourney, ImageFX, DALL·E 3, or your generator of choice. Prompts are grouped by slide, in deck order.*

**Recommended style anchors** (append to any prompt to unify the deck):
- **Cinematic set:** `cinematic lighting, moody, muted palette, 35mm film grain, wide aspect 16:9`
- **Painterly set:** `matte painting, editorial illustration, limited palette (deep navy, gold, brick red), high detail`
- **Diagram set:** `clean vector illustration, isometric, Google Material palette, flat but with subtle depth shadows, minimal text`

**Aspect ratio:** `--ar 16:9` for slide heroes; `--ar 4:3` for diagrams that need to breathe.

**Suggested negatives (Midjourney):** `--no text, logos, watermarks, hands with wrong finger count, blurry`

---

## Slide 1 — Title

**Type:** HERO
**Prompt:**
> A single glowing packet of data in flight, cinematic wide shot, backdrop of Google's global fiber backbone as faint blue arcs across a dark stylized world map. Muted cinematic color palette, deep navy and gold. Subtle 1983 CRT green glow bleeding at the edges. In the deep background, the silhouette of Fort Knox faintly visible on the horizon. Wide 16:9, no text.

---

## Slide 2 — Cold open: NORAD

**Type:** HERO · WarGames callback
**Prompt:**
> 1983-era NORAD infirmary interior, teenage boy at a CRT terminal glowing green-on-black, keypad visible on the desk, "Restricted Access" military signage on the wall. An old 300-baud modem sits unused beside him. Cinematic low-key lighting, 35mm film grain, muted palette, wide 16:9.

*(If you'd rather use a real still from the film: search "WarGames 1983 NORAD David Lightman terminal" — but licensed AI reimagining is the safer path.)*

---

## Slide 3 — Foundation: the trust boundary

**Type:** DIAGRAM · split panel
**Prompt:**
> Editorial illustration, split panel. LEFT: medieval castle with a moat, attackers climbing scaling ladders over the outer wall, chaos beyond. RIGHT: no wall at all — instead, at every doorway an armed guard is checking papers of every visitor individually. Same castle interior visible in both panels. Muted painterly palette, high detail, no text.

---

## Slide 4 — The seven-layer stack

**Type:** DIAGRAM · nested boxes
**Prompt:**
> Clean isometric technical diagram, seven concentric nested rounded rectangles, each a distinct color-coded layer. Outer to inner: TLS wrap · Google Front End · Private Backbone · IAP Identity · IAP Context · VPC Firewall · OS Login. Google Material color palette, subtle depth shadows, minimal labels, on a soft off-white background. 16:9.

---

## Concept 1 pair — BeyondCorp Premise

### Slide 5 (technical) — Aurora headlines
**Type:** HERO · newspaper collage
**Prompt:**
> Newspaper collage aesthetic circa January 2010: overlapping newspaper clippings and blog screenshots reporting the Operation Aurora disclosure — WSJ, NYT, Google's official blog post visible. Torn edge across the middle reveals the word "BeyondCorp" underneath in modern clean type. Muted vintage newsprint tones with a single accent of Google-blue on the torn reveal. 16:9.

### Slide 6 (Fort Knox) — Six walls
**Type:** HERO · cross-section
**Prompt:**
> Detailed illustrated cross-section of Fort Knox from the outer perimeter inward to the central vault. Six concentric defensive layers clearly visible, each with a small armed guard icon standing sentry. Muted painterly palette (deep navy, gold, dusty green), editorial illustration style, dramatic side-lighting, wide 16:9, no text.

---

## Concept 2 pair — TLS Wrap

### Slide 7 (technical) — Three-panel packet journey
**Type:** DIAGRAM · triptych
**Prompt:**
> Three-panel technical illustration in horizontal strip. Panel 1: a MacBook with a stylized outbound arrow wrapped in a translucent TLS envelope. Panel 2: what an eavesdropper sees — a scrolling wall of encrypted hex, "port 443", "→ google.com", indistinguishable from Gmail traffic. Panel 3: bottom strip showing BitTorrent, Bitcoin, and Tor logos with the caption "same technique, same reason." Clean vector, minimal text, muted palette.

### Slide 8 (Fort Knox) — Armored truck
**Type:** HERO · highway scene
**Prompt:**
> Wide cinematic highway shot, three identical armored trucks driving in a row, viewed from a bridge overpass. Above each truck, a translucent x-ray overlay reveals cargo — Truck 1: gold bars. Truck 2: cash bundles. Truck 3: completely empty. On the roadside, observers with binoculars, small thought bubbles reading "which one?" On the distant horizon, a lone hijacker figure walking away dejectedly. Muted dusk palette, cinematic, 16:9.

---

## Concept 3 pair — GFE + DDoS

### Slide 9 (technical) — Attack swarm at the gate
**Type:** DIAGRAM
**Prompt:**
> Stylized technical illustration: a fortified Google Point-of-Presence gate at center. Approaching it from the left, a chaotic swarm of thousands of tiny attack-packet icons labeled "SYN flood", "HTTP/2 rapid reset", "amplification", "slowloris" — all bouncing off the gate. From the right, one single legitimate packet passes cleanly through. Two large stat callouts floating in the background: "2.5 Tbps mitigated · 2020" and "398M rps mitigated · 2023." Muted palette, minimal text.

### Slide 10 (Fort Knox) — Outer gate + tanks
**Type:** HERO
**Prompt:**
> Fort Knox outer perimeter gate, cinematic wide shot at dusk. Armed soldier at the checkpoint in modern combat gear. Behind the gate, visible in formation: M1 Abrams tanks and Bradley Fighting Vehicles parked in disciplined rows. In front of the gate, a chaotic swarm of civilian vehicles is trying to push through and being stopped cold. Muted olive-drab and dusty palette, 35mm film grain, wide 16:9.

---

## Concept 4 pair — Private Backbone

### Slide 11 (technical) — World map + fiber
**Type:** DIAGRAM · world map
**Prompt:**
> Stylized dark world map, Google's global fiber network highlighted in Google-blue glowing lines, with subsea cable names labeled discreetly. A single packet path traced from Denver to us-east1 with small ALTS-encrypted padlock icons at each internal hop. Inset in bottom-right corner: a small "NSA MUSCULAR tap" icon on a submarine cable, crossed out with a red X, annotated "2013 wake-up call → encrypted everywhere since." Editorial infographic style, muted palette. 16:9.

### Slide 12 (Fort Knox) — Base interior roads
**Type:** HERO · aerial
**Prompt:**
> High aerial view of Fort Knox military base interior. Network of internal roads with multiple checkpoints between the outer perimeter and the central depository building. Armed patrol vehicles in transit along the roads. In the foreground, a visitor's badged vehicle is being stopped by a roving patrol at a random interior checkpoint. Surveillance cameras mounted at every intersection. Muted daylight palette, editorial illustration, 16:9.

---

## Concept 5 pair — IAP Identity

### Slide 13 (technical) — IAP as checkpoint
**Type:** DIAGRAM
**Prompt:**
> Technical diagram: an IAP checkpoint at center. Above it, two labeled boxes connected by an "OAuth/OIDC" arrow — left box "Google Auth (identity plane — not GCP)", right box "Cloud IAM (GCP authorization plane)." Below the checkpoint, two sequential doors: Door 1 "JWT signature check → Google Auth", Door 2 "Role check → Cloud IAM." Both doors green, packet passes through. Timeline strip at bottom: "3:00:00 → OK · 3:00:30 → OK · 3:01:00 → admin revoked → DENIED." Clean vector, minimal.

### Slide 14 (Fort Knox) — Biometric gate
**Type:** HERO
**Prompt:**
> Ultra-modern high-security depository building entrance at night. Biometric scanners (fingerprint pad, retina scanner) mounted prominently. Guard station with a large live-updating access-roster display screen. A long-time depository employee is being prompted for a fingerprint scan — the scanner display showing a small red X, "access revoked" text glowing. Two armed guards flank the entrance, hands near holsters. Cinematic side-lighting, cold blue palette, 16:9.

---

## Concept 6 pair — IAP Context

### Slide 15 (technical) — Third door: context
**Type:** DIAGRAM
**Prompt:**
> Technical diagram: three doors in sequence. Doors 1 and 2 labeled "identity" and "IAM role" (both green, checkmarks). Door 3 labeled "Context signals" — beneath it a small stack of icons: laptop with green check ("device cert valid"), padlock ("disk encrypted"), globe with check ("IP in allowlist"), version tag ("OS ≥ 14"). Any one turning red slams Door 3. Small inset in corner: an attacker figure holding a stolen token on a wrong laptop, stopped at Door 3, caption "valid token, wrong device." Clean vector, minimal.

### Slide 16 (Fort Knox) — Escort officer
**Type:** HERO
**Prompt:**
> Interior of the depository hallway, marble floors, dim overhead lighting. An escort officer in tactical dress walks alongside a visitor toward the vault. The escort holds a tablet showing a live checklist visible to the viewer: "arrival gate authorized ✓ · background check current ✓ · escort clearance valid ✓ · authorized items only ✓ · hours within business window ✓" — with one line red: "unauthorized device in pocket ✗". Escort is turning toward the visitor, hand moving to holster. Cinematic tension, cold palette, 16:9.

---

## Concept 7 pair — VPC Firewall

### Slide 17 (technical) — Fortified wall
**Type:** DIAGRAM
**Prompt:**
> Technical illustration: a large fortified stone-and-steel VPC boundary wall spanning the width of the frame. One single narrow doorway in the wall, labeled "35.235.240.0/20 : tcp/22 (IAP only)". All other sections of the wall labeled "DENY" in bold red type. Traffic from IAP passes through the doorway; other traffic bounces off. Behind the wall, a single VM as a small fortified vault. Small inset in the corner: a 5-line Terraform code snippet. Clean editorial illustration.

### Slide 18 (Fort Knox) — Vault hallway roster
**Type:** HERO
**Prompt:**
> Interior of a marble vault hallway. Two armed guards at the entrance, one holding a clipboard with a printed roster. An escort officer and a visitor from the previous scene are arriving; guards are checking the roster — both names present — and stepping aside. In the distance, the vault door visible at the far end of the hallway. From a side corridor, another badged employee is approaching but being politely turned back by a second guard. Cinematic, cold blue-grey palette, 16:9.

---

## Concept 8 pair — OS Login

### Slide 19 (technical) — Two doors on the VM
**Type:** DIAGRAM
**Prompt:**
> Technical illustration: a small fortified VM shown as a vault. Two doors in sequence on the VM itself. Door 1 labeled "IAP tunnel arrival · identity-authorized to reach port 22" (green). Door 2 labeled "sshd + OS Login · SSH key validated against Google identity" (green). Both green: a small shell prompt icon spawns behind the second door. Side diagram showing the SSH key upload flow to Google identity. Far right inset: an admin clicks "revoke," a red X ripples outward across a small fleet of VM icons. Clean vector.

### Slide 20 (Fort Knox) — Vault cage
**Type:** HERO
**Prompt:**
> Interior of the central vault. A long wall of ornate golden cages stretches into the distance, each with its own individual lock. David — a tall man in a modest suit — stands at his specific cage, inserting a brass key. Behind him, an armed vault sentry (weapon at shoulder) watches intently. The cage door has just cracked open — key worked, roster current. In the mid-background, another visitor at a different cage: their key doesn't fit, cage stays locked, a second sentry has hand near holster. Warm cinematic lighting, gold accents, 16:9.

---

## Concept 9 pair — Return Path

### Slide 21 (technical) — Bidirectional stack
**Type:** DIAGRAM
**Prompt:**
> Technical diagram, six-layer nested-boxes architecture with arrows in both directions. Split into two horizontal rows. Top row labeled "authorized user path" — arrows flow back smoothly, no alarm indicators, calm green highlights. Bottom row labeled "attacker exfiltration path" — the same six hops in reverse but with alarm indicators lighting up red at every checkpoint. Large red arrow pointing to the bottom row with caption "next slide." Clean vector, muted palette.

### Slide 22 (Fort Knox) — Split panel: courier vs intruder
**Type:** HERO · split panel
**Prompt:**
> Cinematic split-panel illustration. LEFT PANEL: David the authorized courier walking out through six sequential gates, guards nodding as he passes, calm and procedural, warm daylight palette, no drama. RIGHT PANEL: a shadowy intruder trying to walk out through the same six gates — alarm strobe lights blaring red at each checkpoint, armed guards converging from every direction with weapons drawn, the intruder visibly slowing under the weight of gold bars in his arms. Muted cinematic style, dramatic contrast between the two panels, 16:9.

---

## Concept 10 pair — APT Counterfactual

### Slide 23 (technical) — VM compromised, defenses closing
**Type:** DIAGRAM
**Prompt:**
> Technical illustration: a VM with a bright flashing "COMPROMISED" indicator. Inside the VM, a shadowy attacker figure with data blocks in hand. Around the perimeter, alarm indicators lighting up in sequence — small icons for Cloud Logging (data streaming off-host), adaptive protection (score climbing meter), egress restrictions (razor wire), minimal SA (near-empty IAM badge), distroless (empty toolbox), alerts (paging pager icon). Arrows show the attacker trying to move outward and bouncing off each layer. Timeline strip along the bottom: "T+0 first exfil syscall · T+3s Cloud Logging entry off-host · T+15s adaptive protection tightens · T+30s alert paged · T+45s SecOps engaged · T+60s session terminated." Caption: "the window is measured in seconds." Clean editorial style.

### Slide 24 (Fort Knox) — Gold in hand, alarms firing
**Type:** HERO
**Prompt:**
> Interior of the central vault mid-heist. An intruder crouched low, arms full of heavy gold bars, visible strain and weight. All around him: alarm strobes flashing red, armed guards visibly converging from multiple corridors with weapons drawn. A translucent cross-section overlay along one edge shows every previous checkpoint on the exit path is now sealed and reinforced with razor wire. In the far background, an unreachable getaway vehicle. Small counter in the corner: "Time since alarm: 00:17 · Guards converging: 12 · Exits sealed: 6 of 6." Cinematic tension, dramatic red-and-shadow palette, 16:9.

---

## Yamato Wiki section

### Slide — Yamato landing page (screenshot)
Take a real screenshot of the deployed Yamato wiki landing page. No AI generation needed.

### Slide — Six-layer diagram, Yamato-annotated
**Type:** DIAGRAM
**Prompt:**
> Same six-layer nested-boxes architecture diagram from the earlier slides, but each layer annotated with its Yamato-specific implementation. Presented side-by-side with the generic "David's VM" version for comparison. Clean vector, Google Material palette, minimal text.

### Slide — Multi-agent playbook
**Type:** DIAGRAM
**Prompt:**
> Flow diagram of a multi-agent development pipeline. Three nodes left-to-right: Developer → structured JSON → Tester → structured JSON → Writer → three commit icons on a "dev-refresh" branch. Arrows for the fix-and-verify loop flowing back the other direction. Clean vector, Google Material palette, minimal.

---

## Closing slide

**Type:** HERO · finale art
**Prompt:**
> Cinematic closing artwork: the Yamato space battleship silhouetted against a deep purple-and-gold nebula. Superimposed as a translucent shield around the ship: the six concentric Fort Knox defensive layers, glowing faintly. A subtle 1983-CRT green scanline overlay across the whole image, with the text reading "THE ONLY WINNING MOVE IS TO ARCHITECT PROPERLY." Wide 16:9, cinematic, muted-yet-rich palette.

---

## Style consistency tips

1. **Pick one style bucket per pair** — technical slides use the diagram set, Fort Knox slides use the cinematic set. Don't mix within a pair.
2. **Run a seed test first.** Generate slides 6, 8, 10, 12 in one batch — those are the four "big Fort Knox exteriors." If they look coherent as a set, use the same style anchors for the rest.
3. **Faces are the hardest.** For David and the intruder, consider silhouettes or back-of-head shots — reduces the "AI face" uncanny valley.
4. **Reserve real photos** for anything with named people (David Lightman = WarGames film still if licensable, otherwise silhouette), the Yamato landing page (real screenshot), or actual Fort Knox exterior (Wikimedia has public-domain shots).
5. **After generation:** drop finals into `docs/presentations/img/` and swap the `[HERO IMAGE: ...]` / `[DIAGRAM: ...]` placeholders in `deck.md` for `![alt text](img/filename.png)`.
