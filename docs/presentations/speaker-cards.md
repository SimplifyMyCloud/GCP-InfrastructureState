<!--
Speaker cards — Life of a Packet
Print this file with one card per page.

Render options:
  1. Pandoc → PDF:   pandoc speaker-cards.md -o speaker-cards.pdf --toc
  2. VS Code Markdown PDF: right-click → "Markdown PDF: Export (pdf)"
  3. Marp: marp speaker-cards.md --pdf  (add --allow-local-files if images are referenced)

Each card = one slide. Bulleted riffs, not prose. Glance and go.
-->

# Speaker Cards — Life of a Packet

*One card per slide. Bullets so you can glance and riff — no "reading a book" tone.*

<div style="page-break-after: always;"></div>

## Slide 1 · Title — "Life of a Packet"

**The moment:** Set the tone. WarGames callback + Fort Knox promise.

### Beats
- One packet. Six layers. NORAD to VM and back.
- *"Shall we play a game?"* — the WarGames thread runs the whole deck.
- Metaphor promise: it's a Fort Knox heist. Six armed checkpoints. No shortcuts.

### Land
- "Let's follow the packet."

<div style="page-break-after: always;"></div>

## Slide 2 · Cold open — "It is 1983"

**The moment:** Anchor the entire talk in ONE relatable adversary scenario.

### Beats
- David Lightman, NORAD infirmary, hostile network on every wire.
- He's authorized. The network is not.
- The anachronism (GCE in 1983) IS the joke — the security problem is timeless.
- Any hostile network works: coffee shop wifi, hotel, foreign airport, conference, a facility with monitors on every cable.
- BeyondCorp's whole thesis: **assume the network is hostile, design accordingly.**
- WarGames callback: David used to break IN with a modem — now he needs to get OUT without one.

### Land
- "Everything after this slide is us doing exactly that."

<div style="page-break-after: always;"></div>

## Slide 3 · Two mindsets, only one survives

**The moment:** The paradigm shift in one table. Show the delta.

### Beats
- Datacenter think: trust the network. Cloud think: trust the identity.
- Castle-and-moat vs. no wall, every request checked.
- In datacenter think, David needs a VPN concentrator with a public IP AND a bastion with a public IP.
- Both are attack surface. Both need patching forever. Both are just waiting for a bad day.
- In cloud think, neither exists. Nothing on the public internet.
- The trust decision happens on identity, *before* a packet reaches the network.

### Land
- "This one slide is the whole shift. The rest of the deck is how it works."

<div style="page-break-after: always;"></div>

## Slide 4 · The six layers protecting GCP

**The moment:** Show the roadmap. This is our map for the next 20 slides.

### Beats
- Six concentric layers, outermost to innermost: Physical → Network → GFE → Identity → Workload → Data.
- **Every layer holds independently.** If one fails catastrophically, the layer inside it still blocks.
- Two vocabularies coming up: mechanical trace (tech slide) + Fort Knox parallel (metaphor slide).
- Same architecture, two languages — pick the one that lands for your brain.
- Then the second half: same six layers defending a completely different workload — Yamato Wiki — against real adversaries.

### Land
- "Let's start with the outermost."

<div style="page-break-after: always;"></div>

## Slide 5 · Concept 1 · BeyondCorp premise

**The moment:** Anchor the whole zero-trust story in a specific historical event.

### Beats
- For 50 years, security was built on one idea: draw a line around your network, trust anything inside it.
- **That model broke publicly in late 2009.** Operation Aurora.
- Chinese state-sponsored campaign against ~30 US tech companies. Google was the highest-profile target.
- Attackers spear-phished ONE Google employee, exploited an IE6 zero-day, dropped a backdoor.
- That laptop was inside Google's corporate network → from that beachhead they moved laterally.
- Accessed Gmail of Chinese human-rights activists. Accessed Google source-code repos.
- **The "interior is trusted" assumption WAS the vulnerability.**
- Google published Jan 12, 2010. Publicly named China. Exited Chinese search market.
- Rebuilt around BeyondCorp: no implicit trust from network location. Per-request evaluation on identity + device + context. Least privilege, continuously re-evaluated.
- **IAP is Aurora's direct descendant.** Every IAP check enforces the lesson Google learned when attackers moved through their trusted interior.

### Land
- *"WOPR eventually learned that some games can't be won. In 2010, Google learned the same about trusting its own network."*

<div style="page-break-after: always;"></div>

## Slide 6 · Fort Knox parallel · Six walls

**The moment:** The metaphor promise, delivered visually.

### Riff
- Fort Knox hasn't been robbed in 90+ years.
- Not because any single defense is unbeatable.
- Because you'd have to defeat six of them, in sequence, each armed.
- That's BeyondCorp: not a better wall. **Six walls.**

<div style="page-break-after: always;"></div>

## Slide 7 · Concept 2 · TLS wrap on the client

**The moment:** The packet is opaque BEFORE it leaves the laptop.

### Beats
- David's laptop wraps the entire SSH session in TLS before anything reaches a Google server.
- That single step is where NORAD's wifi loses.
- Sniffers see: encrypted bytes to a Google IP on port 443. **Don't see SSH. Don't see credentials. Don't see the target VM hostname.**
- Indistinguishable from Gmail.
- Every HTTPS session looks identical from outside → the attacker who wants to break David's specific connection doesn't know in advance whether it's worth their time.
- Serious attack against a single TLS session takes real resources; payoff of any random HTTPS session is unknowable.
- **Expected value collapses toward zero. Attackers walk away.**
- Not a novel trick: BitTorrent moved to 443 to bypass ISP throttling. Bitcoin nodes in restrictive networks. Tor's pluggable transports defeat national censorship.
- If it works to move BitTorrent through corporate firewalls and Bitcoin through the Great Firewall, it works for David.
- TLS 1.3 with perfect forward secrecy — an adversary recording tonight can't decrypt with next year's stolen keys.

### Land
- "The packet was already opaque before Google saw it."

<div style="page-break-after: always;"></div>

## Slide 8 · Fort Knox parallel · The armored truck

**The moment:** The uncertainty tax, made physical.

### Riff
- The packet is the armored truck. TLS is the seal.
- Every HTTPS session looks identical from outside — same shape, unknown contents.
- Attackers can't tell if breaking THIS one is worth their time.
- So most don't try. **The truck might be empty.**

<div style="page-break-after: always;"></div>

## Slide 9 · Concept 3 · GFE + DDoS scrubbing

**The moment:** The volumetric wall. Where public-internet attacks die.

### Beats
- After David's TLS-wrapped packet leaves his laptop, first stop on Google infrastructure is the Google Front End.
- **Every internet-facing Google service — Search, Gmail, YouTube, Cloud Run, IAP itself — sits behind a GFE.**
- Nothing on Google Cloud is directly exposed to the public internet.
- Anycast routing finds the closest of 150+ PoPs automatically.
- Three things happen when the packet lands: TLS terminated on Google-designed hardware, DDoS scrubbing at Google-network scale, packet routed inward onto private fiber.
- 2020: 2.5 Tbps flood absorbed — largest ever recorded at the time.
- 2023: HTTP/2 Rapid Reset — 398 million rps against Google services — all absorbed at the edge.
- For context: "large" DDoS against typical enterprise is tens of Gbps. Google routinely absorbs several times the peak Mirai botnet.
- Defender is Google's entire edge capacity — tens of Tbps provisioned for YouTube-at-Super-Bowl-Sunday scale.
- **No attacker can bring more traffic than that.** Even mid-nation-state-DDoS, David's packet still passes.
- This is the last time it's on the public internet.

### Land
- "Everything after this is Google's own fiber."

<div style="page-break-after: always;"></div>

## Slide 10 · Fort Knox parallel · Outer gate + tanks

**The moment:** Asymmetric defense, made physical.

### Riff
- The outer gate isn't unbreakable on its own.
- Behind it: a US Army armor installation with a tank division.
- One tank defeats a thousand cars. Not by being stronger — by being entirely different equipment.
- That's GFE + Google's global network. **Adding more attacker cars doesn't help.**

<div style="page-break-after: always;"></div>

## Slide 11 · Concept 4 · Google's private backbone

**The moment:** The packet has left the public internet. What comes next.

### Beats
- Everything from here to us-east1 is Google's own fiber.
- One million miles of fiber. 15+ subsea cables (Curie, Dunant, Grace Hopper, Firmina).
- Backbone run by B4 — Google's SDN — centralized traffic engineering with global visibility instead of distributed BGP.
- **Now the important bit: owning the fiber is NOT the same as trusting the fiber.**
- October 2013: Snowden disclosures revealed an NSA program called MUSCULAR tapping unencrypted links between Google's own data centers.
- Exfiltrating hundreds of millions of internal records per day.
- Google's response — leaked engineer comment *"these guys have to go"* — encrypt every internal link, everywhere.
- Produced ALTS: mutual auth + encryption on every RPC, even inside Google. Newer traffic uses hardware-offloaded PSP.
- **MUSCULAR is to Google's network what Aurora was to Google's identity model — both permanent architectural shifts toward never trusting the perimeter.**
- David's packet on the backbone is ALTS-encrypted at every RPC hop.
- Invisible to public adversaries AND to any Google operator with a wire tap.
- **The interior is more encrypted than the perimeter, not less.**

### Land
- "Owning the fiber isn't the same as trusting it. Google learned that in 2013."

<div style="page-break-after: always;"></div>

## Slide 12 · Fort Knox parallel · Base interior roads

**The moment:** Interior is monitored more than perimeter, not less.

### Riff
- Past the outer gate is not "the trusted interior."
- It's the vast, monitored, patrolled interior of an armor installation.
- Cameras at every intersection. Roving patrols. Random ID checks.
- The perimeter filters. **The interior verifies.**

<div style="page-break-after: always;"></div>

## Slide 13 · Concept 5 · IAP identity check

**The moment:** The zero-trust moment. BeyondCorp made concrete for user identity.

### Beats
- IAP asks two questions on EVERY request: who is this identity, and are they authorized right now?
- Identity is cryptographic: David authenticated to gcloud earlier via `gcloud auth login`, got an OAuth refresh token.
- gcloud uses it to get a short-lived access token — a JWT signed by Google. IAP verifies the signature against Google's public keys.
- Authorization: IAP asks Cloud IAM whether David holds `roles/iap.tunnelResourceAccessor` on THIS specific VM. Yes → tunnel opens. No → 403.
- **These are two separate systems.** Google Auth is the identity service; Cloud IAM is the authorization plane.
- Google Auth is NOT a Google Cloud product. Same team + infrastructure that authenticates Gmail, YouTube, Android, and every Google Workspace user in the world.
- **Google Cloud is a customer of Google Auth** via standard OAuth 2.0 / OIDC — the same protocol any third-party "Sign in with Google" integration uses.
- Cloud IAM's job starts when Google Auth's job ends. Two systems, one clean interface, independent failure domains.
- Genuinely different from AWS (own identity system) or Azure (Entra ID).
- **Both checks happen fresh on every request. Not once at login.**
- 3:00pm admin revokes → 3:01pm active SSH session dies on the next TCP segment.
- Session does not outlive the underlying grant. **The authorization system IS the session controller.**
- Works with Workforce Identity Federation for Okta, Azure AD, Auth0 — same per-request property.

### Land
- "Revocation is immediate, not eventual."

<div style="page-break-after: always;"></div>

## Slide 14 · Fort Knox parallel · Biometric gate

**The moment:** Per-request identity, made physical.

### Riff
- Not a locked door with a key. A biometric gate with a real-time database check.
- Even the longest-tenured employee gets prompted every visit.
- If HR disabled your access at 3:00pm, the scanner refuses you at 3:01pm.
- **Yesterday's badge is not today's badge.**

<div style="page-break-after: always;"></div>

## Slide 15 · Concept 6 · IAP context check

**The moment:** Where credential theft gets defeated.

### Beats
- Getting past the biometric gate is not the whole IAP story.
- Even after IAP validates David's OAuth token and confirms his IAM role, second-layer check: Context-Aware Access.
- This is where IAP crosses from "authenticator" into genuine BeyondCorp zero-trust.
- CAA evaluates the *circumstances*: corporate-managed device with a valid device certificate? Disk encryption enabled? OS above minimum patch level? Source IP in corporate egress range? Country allowed?
- **Any single signal fails → 403.** Even with a valid token, even with the right IAM role.
- The specific scenario this defends against is the most common breach pattern: credential theft.
- Attacker phishes David, exfiltrates malware from his laptop, or buys credentials on a breach forum.
- With identity-only IAP, that's game over.
- With CAA: attacker's token is valid but circumstances aren't. **No David's laptop. No corporate device cert. No corporate egress IP.** 403 forbidden.
- BeyondCorp thesis was always three things: identity, device, context. Chapter 5 was identity. This is device + context.
- Together they replace the perimeter with something categorically stronger — attacker needs credentials AND specific hardware AND network location AND compliant OS version. Each orders of magnitude harder.
- Real ops: laptop stolen → MDM revokes device cert → next request denied instantly.
- Employee travels to restricted country → CAA geo-policy denies.
- OS falls below patch level → denied until updated.

### Land
- "Stolen credentials alone are worthless."

<div style="page-break-after: always;"></div>

## Slide 16 · Fort Knox parallel · The escort

**The moment:** Context check, made physical.

### Riff
- Biometric gate confirmed identity. The escort checks a different set of things.
- What are you carrying? Where did you come from? Is your background check current?
- Right person, wrong context → turned around.
- **Identity gets you past the gate. Context is what keeps you moving forward.**

<div style="page-break-after: always;"></div>

## Slide 17 · Concept 7 · VPC firewall

**The moment:** Belt-and-suspenders at the network layer. Independence matters.

### Beats
- Belt-and-suspenders at the network layer.
- Rule is deliberately narrow: only source range `35.235.240.0/20` on port 22.
- That's IAP's fixed, published range — 4,096 addresses Google owns and reserves for IAP tunneling.
- Everything else denied.
- Why do we need this if IAP already checks identity and context? **Because layers must be independent.**
- If IAP had a bug tomorrow — zero-day, misconfiguration, whatever — the firewall still holds. It doesn't care about IAP's auth logic. It cares about source IP.
- Anything not from `35.235.240.0/20` is dropped no matter how legitimate at the application layer.
- Two independent gates, two independent enforcement mechanisms, both required.
- **A vulnerability in one doesn't compromise the other.**
- Real scenarios: IAP accidentally removed from LB config (firewall still holds), zero-day in IAP (firewall catches direct network attempts), insider trying to reach VM from another VM in project (denied), route misconfiguration (firewall enforces regardless).
- Terraform-managed, ~5 lines of HCL.
- Cloud Run analog: `ingress = INTERNAL_LOAD_BALANCER`. Same architectural pattern for serverless.

### Land
- **"The VM's entire ingress surface is 4,096 IPs on one port — and Google owns them all."**

<div style="page-break-after: always;"></div>

## Slide 18 · Fort Knox parallel · Vault hallway roster

**The moment:** Independent authorization, made physical.

### Riff
- Even inside the building, the vault hallway is its own perimeter.
- With its own credentialed personnel and its own roster.
- Passing the biometric gate doesn't put you here.
- **Two independent authorizations. Both required.**

<div style="page-break-after: always;"></div>

## Slide 19 · Concept 8 · OS Login

**The moment:** The innermost check. Second independent auth system at the VM.

### Beats
- David's packet has cleared every layer between his laptop and the VM. Seven layers. But one more check before he gets a shell.
- **IAP only tunneled raw TCP.** It made the connection reachable — it did NOT authenticate the SSH protocol itself.
- That's OS Login's job, at the VM.
- OS Login is Google's replacement for traditional SSH key management.
- Instead of per-VM `authorized_keys` files admins have to distribute, OS Login federates SSH access to Google's identity system.
- David uploaded his SSH public key to his Google identity via `gcloud compute os-login ssh-keys add`.
- When David's SSH client connects, sshd runs the OS Login PAM module → queries Google's metadata server → compares the presented key against the returned list.
- If the key matches AND David holds `roles/compute.osLogin`, shell spawns.
- **Two independent authorization systems at the same request.** IAP asks "can this identity open a tunnel to port 22?" OS Login asks "does this identity have a valid SSH key?"
- Different IAM roles gate them. Different authentication artifacts prove them. **Both must succeed.**
- Operational value mirrors IAP: revoke the key in Google's admin console → stops working on every VM within seconds.
- No config-management push. No SSH-to-every-host cleanup. No stale `authorized_keys` on forgotten VMs.
- Identity plane is the source of truth; VMs pull from it.
- Employee terminated → SSH access to every VM in every project dies within minutes.
- Compromised key → remove from Google identity → key stops working everywhere.
- Fleet-wide grant for new team member → `roles/compute.osLogin` at project level → immediate access to all VMs.
- Time-boxed contractor → CAA-conditional grant → silently ends after N days.

### Land
- "Belt-and-suspenders at the innermost layer."

<div style="page-break-after: always;"></div>

## Slide 20 · Fort Knox parallel · The vault cage

**The moment:** Second independent check, made physical.

### Riff
- You've made it to the cage. But the cage has its own lock.
- Unique to your specific cage. Requires your personal key. Registered in the central roster.
- Wrong key → cage stays shut.
- **Right roster entry + right physical key. Either wrong = cage stays shut.**

<div style="page-break-after: always;"></div>

## Slide 21 · Concept 9 · Return path

**The moment:** Bridge to the finale. Same six hops reversed — different experience.

### Beats
- Return trip is the six hops in reverse. Same tunnel, same encryption, same infrastructure.
- For David: exit is uneventful. Output flows back. Nobody notices.
- For an intruder: **same reverse path becomes the killing floor.**
- Every layer that authorized traffic passes through smoothly = a slowdown for unauthorized traffic.
- Every exit attempt is logged. Every anomaly scores against the adversary.
- Alarms fire while the intruder is still trying to leave.
- **The gold, being heavy, moves slower than the alarm.**

### Land
- "The next slide is where the whole story pays off."

<div style="page-break-after: always;"></div>

## Slide 22 · Fort Knox parallel · Courier vs. intruder

**The moment:** Return-path duality, made physical.

### Riff
- Same six gates. Radically different experience.
- Authorized courier: guards nod. Calm and procedural. No drama.
- Intruder: alarms at every checkpoint. Guards converging. Gold weighing them down.
- **The alarm decides which experience you get.**

<div style="page-break-after: always;"></div>

## Slide 23 · Concept 10 · APT counterfactual

**The moment:** The finale. Grant the impossible; watch the reverse-flow defenses close the trap.

### Beats
- The dramatic finale of the packet trace.
- Grant the impossible: nation-state APT has defeated the six-layer inbound defense. Fake identity that passed IAP. Zero-day that bypassed OS Login. Whatever it took.
- They're on the VM. They have a shell. They grabbed some data. **Now they need to leave with it.**
- This is where the architecture pays its second, larger dividend.
- **Cloud Logging** — captures every syscall, outbound connection, DNS lookup. Shipped off-host in real time to a bucket the attacker doesn't have access to. **There is no way to erase the trail from inside the compromised VM.**
- **Cloud Armor adaptive protection** — scores the anomaly in real time and tightens enforcement automatically.
- **VPC egress + VPC Service Controls** — outbound traffic forced through inspected corridors. Even if the attacker has valid credentials for a bucket in their own project, VPC SC blocks the exfil because it crosses the data perimeter.
- **Runtime service account** — no `storage.admin`, no `pubsub.publisher`, no Cloud Functions invoke. **Nowhere useful to send the stolen data.**
- **Distroless container** — no shell, no `curl`, no `wget`, no `bash`. **No tools to cut with.**
- **Cloud Monitoring alerts** — page the on-call within seconds.

### The physics
- Data movement is bandwidth-bounded. Alert propagation is essentially instantaneous.
- Attacker's ability to move data is bounded by these constraints; defender's response is bounded only by human reaction time.
- Window between "grabbed data" and "gets caught" is measured in **seconds, not hours.**
- **The gold, being heavy, moves slower than the alarm.**

### Land — the honest guarantee
- **"Nobody gets in" is a fantasy. "Even if they get in, they can't get out" is the real guarantee.**
- Not because we're perfect. **Because we architected the physics to be against them.**

<div style="page-break-after: always;"></div>

## Slide 24 · Fort Knox parallel · Gold in hand, alarms firing

**The moment:** The physics of the guarantee, made physical.

### Riff
- Intruder in the vault, arms full of gold. Needs to walk back out through the same six gates.
- But those gates are no longer the same. Alarms firing. Guards converging. Exits sealed.
- 27-pound gold bars slow the intruder. Alarms travel at the speed of light.
- **The gold cannot leave the vault faster than the alarm reaches the guards.**

<div style="page-break-after: always;"></div>

## Slide 25 · Meet the Yamato Wiki

**The moment:** Pivot from theory to proof.

### Beats
- The hero sequence walked mechanism. **This section walks proof.**
- Star Blazers fan wiki. Publicly discoverable at `yamato-dev.iq9.io`. Running on GCP.
- Built as a working demo of GCP's security stack.
- **Same six layers you just watched protect David's VM — deployed differently, for a different workload, in the same architecture.**
- Everything you're about to see is real production data from the last 24 hours.
- On infrastructure we built in a few days using the same principles.
- **Not a demo.** This is what happens when you leave the site on the internet with alerts on.

<div style="page-break-after: always;"></div>

## Slide 26 · Layer 1 in production — 345 real attacks

**The moment:** The moment prospects realize the deck isn't theoretical.

### Beats
- Last night: **20 unique adversaries** hit `yamato-dev.iq9.io`.
- 274 hits from a single AWS Paris IP hunting for `/.env` files (transactional-email credential theft).
- 71 hits from a long tail of Azure / OVH / residential scanners.
- **Every single one blocked at Cloud Armor before the app was touched.**
- Zero operator intervention. Zero customer impact. One threshold alert to say "the wall is holding."
- Same Layer 1 that would have blocked a hostile bot going after David's VM.
- Full evidence trail lives in `docs/security/in-the-wild-2026-06-03.md` — walk the receipts.

### Land
- "This is the moment the deck stops being theoretical."

<div style="page-break-after: always;"></div>

## Slide 27 · Layer 2 in production — IAP gating /wiki

**The moment:** Show the same IAP mechanism, different rule.

### Beats
- `/` — public landing page. No IAP. Anyone can see the crew cards.
- `/wiki/*` — IAP-gated. `@iq9.io` Google identity required. **Every request. Not just the first.**
- Same IAP that let David's SSH tunnel through when he had the right identity.
- Here, IAP enforces a Google Workspace domain restriction.
- Same mechanism, different rule.
- Same "biometric gate with armed guards" from the Fort Knox metaphor.

<div style="page-break-after: always;"></div>

## Slide 28 · Layers 3–5 in production

**The moment:** Complete the mapping — this wiki has the same architecture as David's VM.

### Beats
- Direct mapping across the stack.
- **Layer 3 — GFE** in front of the LB. Same GFE that scrubbed David's DDoS.
- **Layer 4 — IAP + IAM.** Runtime service account has just two roles total: `cloudsql.client` + one secret accessor.
- **Layer 5 — the workload:**
  - Cloud Run ingress = `INTERNAL_LOAD_BALANCER` — the `*.run.app` URL rejects public traffic.
  - Cloud SQL on **private IP only**.
  - Distroless container image, nonroot, no shell.
- Same shape as David's `35.235.240.0/20`-only firewall + OS Login SSH-key check.
- **Different technology; same architectural pattern.**
- Distroless container is the "no cutting tools in the vault" from the APT slide.

<div style="page-break-after: always;"></div>

## Slide 29 · The NOC — live evidence

**The moment:** They don't have to trust the story. They watch it hold.

### Beats
- NOC tiles refreshed every 30 seconds:
  - Cloud Armor blocks — last 1h and last 24h
  - Top 5 source IPs with provider attribution
  - Top 5 probed URLs — the attacker menu, live
  - Top WAF rule priorities — which layer is firing
  - 9 alert policies — green/yellow/red state board
- NOC itself is IAP-gated (`@iq9.io` only).
- Reads from Cloud Logging + Monitoring APIs on a 25-second cache, refreshes every 30 seconds.
- **In a demo: open this tab, log in, let the prospect watch numbers change while you talk.**
- The tile with the Paris attacker is the moment a serious buyer leans forward.

<div style="page-break-after: always;"></div>

## Slide 30 · Layer 0 — the honeypot lure

**The moment:** We don't just block. We identify.

### Beats
- 1983: David wardialed NORAD — trying every phone number until one answered.
- Today's bots wardial the *internet* — trying every URL until one leaks credentials.
- **Our honeypots are the numbers we leave for them to find, that go nowhere.**
- Six deliberately enticing endpoints outside Cloud Armor's block list: `/admin`, `/backup.sql`, `/api/v1/users`, `/server-status`, `/phpmyadmin`, `/console`.
- Every hit logged: source IP, user-agent, method, first 1KB of body.
- Bots that Cloud Armor doesn't already have a rule for come here, spring the wire, we log everything.
- **Cloud Armor gives us blocks. Honeypots give us intelligence.**
- Wardialing callback: David's whole thing in the movie was calling every number in Sunnyvale until Joshua answered.
- The honeypot is the modern equivalent — a fake number that answers just to keep the wardialer busy.

### Land
- "We don't just block attackers — we identify, fingerprint, and track them."

<div style="page-break-after: always;"></div>

## Slide 31 · What this cost to build

**The moment:** The consulting angle. Playbook is the product; wiki is the receipt.

### Beats
- **Days, not months.**
- Multi-agent playbook: Developer → Tester → Technical Writer, sequential, each role's context sealed off.
- Tester can't rationalize past the Developer's blind spots — different agent, different framing.
- Everything as code: Terraform for infra, Cloud Build for app deploys, structured JSON handoffs between roles.
- Every commit reviewed by an independent agent before landing.
- Full history reproducible from git — walk any commit, see what was known when.

### Land
- **"The value is the playbook, not the days. Any competent team can build this if they have the playbook."**
- **"The playbook is the product. The wiki is the receipt. We can show them both."**

<div style="page-break-after: always;"></div>

## Slide 32 · Terraform appendix

**The moment:** For the appendix reader / technical follow-up.

### Beats
- Three resources total, ~30 lines of HCL.
- Firewall accepts only IAP's range (`35.235.240.0/20`).
- VM has no external IP (no `access_config` block).
- One IAM binding grants David tunnel access.
- **That's the whole ingress architecture.**

<div style="page-break-after: always;"></div>

## Slide 33 · Further reading — the long form

**The moment:** Give prospects the receipts.

### Beats
- Each concept from the deck has a full-chapter written version in `docs/presentations/longform/` (chapters 1–10).
- Each stands alone. Each cites its history.
- **Prospects who read all ten know the system as well as we do.**
- Additional receipts in `docs/security/`: in-the-wild logs, NOC docs, honeypot docs, multi-agent playbook.

<div style="page-break-after: always;"></div>

## Slide 34 · Thank you

**The moment:** Land the pitch. Invite engagement.

### Beats
- Wiki is live at `yamato-dev.iq9.io`. Repo is real. Playbook is documented.
- Prospect can visit right now, watch the NOC, see honeypots catching bots, read the `/docs` shelf.
- **We build like this for a living.**
- **Not a slide deck about what we could build. A slide deck built on top of what we did.**

### Land
- *"Shall we play a game? — this time, we already have."*
- **The prospect's turn to engage.**
