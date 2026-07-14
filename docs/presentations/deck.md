<!--
Deck: Life of a Packet — the six layers between a hostile network and your server
Status: Pass 2 — speaker notes moved to HTML comments; Fort Knox mapping woven in; WarGames sprinkles
Audience: Consulting prospects (CTOs / CISOs); also readable as a self-serve portfolio piece
Slide format: `---` between slides (works for Marp, reveal.js, and plain markdown viewing on GitHub)
Speaker notes: <!-- Speaker notes: … --> HTML comments (Marp renders these to presenter view; hidden from slide)
Fort Knox annotations: blockquote `> **Fort Knox parallel:** …` — visible on each hop slide as a callout
Image placeholders: [HERO IMAGE / DIAGRAM / SCREENSHOT: <description>] — Chris drops in the 90%
Mermaid: fenced code blocks render natively on GitHub; polish/replace later
-->

# Life of a Packet

### How GCP protects a private VM from a network that watches everything.

Six layers, one packet, a NORAD infirmary, and a MacBook.

*Shall we play a game?*

[HERO IMAGE: title-slide art — a stylized single packet in flight against a backdrop that hints at Google's global backbone. Muted, cinematic. WarGames-era CRT green glow optional. Bonus: a very subtle silhouette of Fort Knox in the deep background suggesting the metaphor to come.]

<!-- Speaker notes: Welcome. This is a talk about the specific mechanisms GCP uses to keep a private server safe when the user connecting to it is on a network that cannot be trusted. We're going to follow one packet, hop by hop, from an untrusted MacBook to a server that has no exposure to the public internet — and back. Along the way we'll see the six layers of defense that protect the server. And then we'll prove the same six layers work in production, against real adversaries, on a live system we built. The metaphor throughout: it's a Fort Knox heist. Six armed checkpoints, no negotiation, no shortcuts. -->

---

# It is 1983.

### David Lightman is trapped in NORAD's infirmary.

He hacked the door lock on the way in. Now he needs to hack a tunnel on the way out — **properly this time.**

No WOPR. No 300-baud modem. No wardialing. Just IAP.

Every wifi and wired network in the building is presumed watched, logged, and forwarded to somebody who wants a copy. He is authorized. The network is hostile.

[HERO IMAGE: still or illustration of the NORAD infirmary from WarGames — David at a CRT terminal, ideally with the door-lock keypad visible in the corner. If a real still is off-limits, a stylized reproduction: 1983 CRT green-on-black, keypad, "Restricted Access" signage. Optional callback: an old 300-baud modem sitting unused on the desk.]

<!-- Speaker notes: The setup is deliberately anachronistic — GCE didn't exist in 1983 — and that is the joke. The point survives the anachronism: on ANY untrusted network, the security problem is identical. Coffee shop wifi. Hotel wifi. Foreign airport. A conference. A military facility with monitors on every cable. BeyondCorp's whole thesis is: assume the network is hostile, and design accordingly. Everything after this slide is us doing that. WarGames callback: David used to break IN with a modem; now he needs to get OUT without one. -->

---

# Two mindsets. Only one survives.

|                          | Datacenter think                                     | Cloud think                                            |
|--------------------------|------------------------------------------------------|--------------------------------------------------------|
| **Trust boundary**       | The network — "inside" = trusted                     | The identity — every request proven on its own         |
| **Perimeter model**      | Castle-and-moat: hard shell, soft interior           | No shell — every network is hostile                    |
| **Lateral movement**     | Often unchecked once inside                          | Blocked by default; least privilege everywhere         |
| **Access control**       | VPN, jump boxes, network ACLs                        | Identity-Aware Proxy, IAM, Context-Aware Access        |
| **Attackable surface**   | VPN concentrator + bastion + patchable-forever       | Nothing on the public internet at all                  |

[DIAGRAM: side-by-side visual — left panel a medieval castle-with-moat with attackers scaling the wall; right panel a "no wall" diagram where every request meets an armed guard checking papers. Same underlying architecture; radically different failure modes.]

<!-- Speaker notes: This one slide is the whole shift. In datacenter think, David would need a VPN concentrator with a public IP that somebody has to patch forever, plus a bastion host with a public IP that somebody has to patch forever. Both are attack surface. In cloud think, neither exists. The trust decision happens on David's *identity* before a packet reaches the network he's connecting to. -->

---

# It came from a real breach.

### Operation Aurora — 2009.

Attackers moved laterally inside Google's *own* corporate network once past the perimeter. The perimeter had worked as designed. The interior assumption — "if you're inside, you're trusted" — is what got exploited.

Google's conclusion was severe: **stop trusting the network entirely.**

That conclusion is called **BeyondCorp**. Identity-Aware Proxy is BeyondCorp productized for cloud workloads.

> *WOPR eventually learned that some games can't be won. In 2010, Google learned the same thing about trusting its own network.*

[HERO IMAGE: newspaper-collage aesthetic of the January 2010 Aurora disclosure headlines. Google's blog post, WSJ, NYT. Underneath, a torn edge revealing "BeyondCorp" as the response.]

<!-- Speaker notes: Aurora is worth naming out loud because it makes zero trust concrete. This is not an academic paper. This is: Google was breached, decided the network model was the problem, and rebuilt around identity. Every principle of BeyondCorp — no implicit trust from network location, access granted per-request based on who + device + context, least privilege continuously re-evaluated — traces back to that response. IAP is that response, as a service you consume. WarGames callback: WOPR played every scenario of Global Thermonuclear War until it concluded there was no winning move. Google's Aurora conclusion was structurally identical — no perimeter-trust configuration wins. -->

---

# The six layers protecting GCP.

Defense in depth, outermost to innermost.

```
┌──────────────────────────────────────────────────────────────────────┐
│  1. Physical / hardware — badges, Titan chips, hardware root of trust│
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │  2. Global network — Google's private backbone                 │  │
│  │  ┌──────────────────────────────────────────────────────────┐  │  │
│  │  │  3. Google Front End — TLS termination, DDoS scrubbing   │  │  │
│  │  │  ┌────────────────────────────────────────────────────┐  │  │  │
│  │  │  │  4. Identity & access — IAM, Context-Aware, IAP    │  │  │  │
│  │  │  │  ┌──────────────────────────────────────────────┐  │  │  │  │
│  │  │  │  │  5. Service & workload — VPC firewall, ALTS  │  │  │  │  │
│  │  │  │  │  ┌────────────────────────────────────────┐  │  │  │  │  │
│  │  │  │  │  │  6. Data — encrypted at rest, per-key  │  │  │  │  │  │
│  │  │  │  │  └────────────────────────────────────────┘  │  │  │  │  │
│  │  │  │  └──────────────────────────────────────────────┘  │  │  │  │
│  │  │  └────────────────────────────────────────────────────┘  │  │  │
│  │  └──────────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

[DIAGRAM: replace the ASCII with a proper nested-boxes visual — each layer color-coded, each labeled with one line of what it does. This slide is the visual reference for the entire rest of the deck.]

<!-- Speaker notes: Every layer holds independently. If any one layer failed catastrophically, the layer inside it would still block the attack — that's the definition of defense in depth. The next section of the talk walks a single packet from Layer 0 (David's laptop, off the diagram) to Layer 5 (the VM) and back, and you'll see each layer do exactly its one job. Then the second half of the talk shows the same six layers defending a completely different workload — a public web app — against real adversaries. -->

---

# How to read the next seven slides.

### It's a Fort Knox heist. Every hop is an armed checkpoint.

Fort Knox holds the US gold reserve. Its defense is not one wall — it's **six concentric layers, each staffed by armed guards, none of them negotiable.** Outer perimeter road, base gate, patrolled interior, depository building gate, vault hallway, vault cage. Every layer independently refuses. Every layer has a gun.

**GCP's defense of a private VM works the same way.** Each of the next six slides is one layer of that heist, from the attacker's approach to the vault cage itself. On each slide, a **Fort Knox parallel** shows what that layer looks like as a physical checkpoint with armed guards.

The catch: for our packet, we ARE the authorized courier. The layers open. **For anyone else — no negotiation.**

[DIAGRAM: Fort Knox on the left as six nested concentric rings, each with a small armed-guard icon at the gate. GCP six-layer diagram on the right, same shape, each layer labeled with its enforcement mechanism (Cloud Armor, IAP, VPC firewall, etc.). Side-by-side. Same architecture, different domain.]

<!-- Speaker notes: This slide sets up the metaphor. The reason Fort Knox has never been successfully robbed in 90+ years is not that any single defense is unbeatable — it's that you'd have to defeat all six in sequence, each of them armed, each of them independent. Same principle for GCP's defense of a private workload. In the six slides that follow, each hop is one Fort Knox layer being tested. Emphasize "armed" — this isn't just credential checks, it's automated enforcement that executes at machine speed. Cloud Armor doesn't ask a human whether to block a SQLi payload; it just does. That's the "gun". -->

---

# David's setup.

- **David:** MacBook, NORAD infirmary wifi. Every packet is presumed observed.
- **Target:** GCE VM `vm-name`, zone `us-east1-b`. **No external IP.** Internal `10.x.x.x` only.
- **Problem:** SSH into the VM. No VPN. No bastion host. No exposed public IP anywhere in the architecture.

[DIAGRAM: David + MacBook on the left, a stormy "hostile network" cloud in the middle with observer icons, and on the right a VPC boundary containing a VM with the label "no external IP" — nothing outside the VPC to attack.]

<!-- Speaker notes: The negative space is the interesting part. There is nothing on the public internet an nmap could find. No open port on the VM. No VPN endpoint. No bastion host. The VM is not addressable from the internet at all. And yet David is going to reach it, over a hostile network, from the wrong hemisphere. -->

---

# One line.

```bash
gcloud compute ssh vm-name \
  --zone us-east1-b \
  --tunnel-through-iap
```

That flag — `--tunnel-through-iap` — is the whole trick.

[HERO IMAGE: 1983 CRT-styled screenshot of the command, monospace green-on-black. Bonus points if the cursor is blinking on the last line.]

<!-- Speaker notes: Everything that happens for the next eight slides happens because of that flag. What LOOKS like SSH is actually SSH-wrapped-in-HTTPS-over-443, and the tunneling handshake happens with IAP before a single SSH byte is transmitted. To an observer on David's network, this is indistinguishable from any other HTTPS connection to a Google endpoint. -->

---

# Hop 1 — MacBook → Google Front End.

The packet leaves David's laptop **wrapped in TLS**, destined for HTTPS/443.

On the NORAD wifi, anyone sniffing sees encrypted noise. Not SSH. Not credentials. Not the target hostname. **HTTPS.**

[DIAGRAM: David's laptop → hostile-cloud with sniffer/observer icons scattered through it → nearest GFE point-of-presence (anycast). The observer icons should have "???" or padlocks over them — they see nothing decodable.]

> **Fort Knox parallel:** The courier approaches Fort Knox in an unmarked armored truck. Anyone watching the road sees a truck. Nobody sees the manifest inside. The truck itself is not the security — the sealed container inside it is.

<!-- Speaker notes: The GFE is announced via anycast, so the packet lands at whichever point-of-presence is topologically closest to David. TLS 1.3, modern ciphers, a Google-managed cert. Nothing in the plaintext of the wire indicates SSH is in progress. This is Layer 3 of the six-layer diagram doing its job on the way in — the GFE is the *only* thing on the public internet that this connection ever touches. -->

---

# Hop 2 — GFE terminates TLS. Last hop on public internet.

The GFE decrypts the TLS envelope, applies DDoS scrubbing, and passes the request onto Google's private backbone.

**This is the last time the packet is anywhere a public adversary could observe it.**

[DIAGRAM: GFE as a box, three labels — "TLS termination", "DDoS scrubbing", "edge routing". Arrow leaving the box labeled "→ private backbone" with a stylized "public internet ends here" boundary line.]

> **Fort Knox parallel:** The perimeter gate of the Army base. **Armed soldier stops every vehicle.** No badge, no entry. Volumetric attackers — the truck rammers, the mob of a thousand cars — die at this gate before they ever see the base. Beyond this point: only Google's own roads.

<!-- Speaker notes: Two things happen here that don't happen on any other cloud provider's edge at this scale. First, TLS terminates on hardware Google designed. Second, volumetric DDoS attacks die at this layer — they never reach the workload, never bill you for the traffic, never wake up an oncall. Past this point we are on Google's own fiber. -->

---

# Hop 3 — Google's private backbone.

From the GFE inward, the packet rides Google's own fiber — re-encrypted at the RPC layer (ALTS, increasingly PSP-hardware-offloaded).

**NORAD's infirmary to `us-east1` without ever routing back onto the public internet.**

[DIAGRAM: US map, NORAD (Cheyenne Mountain / Colorado Springs) on the left, us-east1 (South Carolina) on the right, connected by a fat glowing line labeled "Google private backbone (ALTS-encrypted)". Optional smaller line showing where the equivalent public internet path would have gone — full of switches, ISPs, adversary nodes.]

> **Fort Knox parallel:** The interior of the Army base. Vast. Private. **Roving patrols, weapons drawn, prompting for credentials at random.** Public roads do not reach in here. Even inside the base, you are watched.

<!-- Speaker notes: Google's fiber network is one of the largest private networks in existence. Once traffic is on it, an adversary who had somehow tapped a fiber run between GFE and datacenter would still see only ALTS-encrypted RPC frames — the RPC layer is independently encrypted from TLS. The layer inside the layer inside the layer. This is Layer 2 of the six-layer diagram. -->

---

# Hop 4 — IAP. The zero-trust moment.

*Shall we play a game?* Sure — but only if you're on the guest list.

The packet arrives at Identity-Aware Proxy. IAP now decides, per-request:

- **Who** is David? (OAuth / OIDC identity verified)
- **What** is he allowed to do? (IAM role `roles/iap.tunnelResourceAccessor`)
- **What device** is he on? (Context-Aware Access, optional)
- **Where** is he? (IP + location risk signals, optional)

Any check fails? **Tunnel never opens. Packet dies here. Nowhere near the VM.**

[DIAGRAM: IAP as a multi-gate structure — four sequential checkpoints, each labeled with one check (identity / IAM / device / context), each flanked by a stylized armed-guard icon. Packet enters left; a green ✓ path exits right toward "VPC firewall"; a red ✗ path exits down toward a trash can labeled "denied".]

> **Fort Knox parallel:** The Depository building's biometric gate. **Armed guards flanking the door.** Fake credentials fail the scanner. Even a real employee is prompted anew every visit — no "I was here yesterday" pass. Every request, every time.

<!-- Speaker notes: This is the layer that would have prevented Aurora. This is BeyondCorp made real. Every one of these checks happens on every request, not just at login. If David's IAM role is revoked in the middle of his SSH session, the next TCP segment fails. If his device drops out of compliance, the next segment fails. This is Layer 4 of the six-layer diagram. The zero-trust checkpoint. WarGames callback: the "shall we play a game?" line lands here because IAP is the gate that decides whether the game happens at all. -->

---

# Hop 5 — VPC firewall. Only IAP gets through.

IAP's TCP forwarding **always originates from the fixed range `35.235.240.0/20`.**

The VPC firewall accepts ingress ONLY from that range, ONLY on port 22.

Nothing else on the internet can even reach the VM.

```hcl
resource "google_compute_firewall" "allow_iap_ssh" {
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]     # IAP's fixed range
  target_tags   = ["allow-iap-ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
```

[DIAGRAM: VPC boundary drawn as a solid wall. One tiny door labeled "35.235.240.0/20 : tcp/22", flanked by armed-guard icons. Every other side of the wall labeled "DENY". Inside the wall: the VM.]

> **Fort Knox parallel:** The vault hallway. **Armed escort service, no exceptions.** Only their pre-cleared personnel walk this corridor. Everyone else — even employees with valid Depository badges — is turned back at the door. At gunpoint.

<!-- Speaker notes: Belt and suspenders. Even if IAP itself had a defect, this firewall would still refuse traffic from any source other than IAP's known range. Even from another Google service. Even from another VM in the same project. Only IAP. This is Layer 5 of the six-layer diagram — the workload's own perimeter. -->

---

# Hop 6 — VM. OS Login validates SSH.

The packet arrives at the VM's internal address.

IAP only tunneled raw TCP — **it did not authenticate SSH.** That's still to come.

**OS Login** validates David's SSH public key (pushed to instance metadata based on his IAM identity) against `sshd`.

**Two independent checks:** IAP said "can this identity open a tunnel?"; OS Login says "does this identity have a valid key for this OS user?"

[DIAGRAM: The VM with two gates in series. First gate: "IAP tunnel — is this identity allowed here?". Second gate: "sshd + OS Login — does this identity have a valid key?". Armed sentry icon at each gate. Both gates must open for a shell to spawn.]

> **Fort Knox parallel:** The vault cage itself. **Armed vault sentry at the cage door.** Even inside the hallway, even with the escort, without YOUR personal key to YOUR specific cage — the sentry says no. Wrong key, no gold. Right key, verified against the manifest, then the cage opens.

<!-- Speaker notes: This is where the "defense in depth" phrase stops being marketing and becomes literal. Two independent authentication systems, both keyed to the same identity, either of which can independently deny. If OS Login is misconfigured, IAP still blocked unauthorized tunnels. If IAP was somehow bypassed, OS Login still refuses the SSH handshake. The layers hold independently. -->

---

# Return trip — six hops in reverse.

VM → firewall → IAP → backbone → GFE → public internet → David.

**Same tunnel, bidirectional. Same TLS envelope on the way back.**

[DIAGRAM: mirror image of the hero-sequence flow, arrows reversed. Same six boxes; same "encrypted throughout" annotations; same "observer sees only HTTPS" callout at the David-side end.]

> **Fort Knox parallel:** The authorized courier walks out the same six gates. Guards recognize the escort. The manifest is verified. Nothing tripped, nothing alarmed. **This is what the return trip looks like for a legitimate user.** The next slide is what it looks like when someone tries the same path without authorization.

<!-- Speaker notes: Nothing exotic on the return. The tunnel is bidirectional; a single TLS connection carries traffic both ways. The observer at NORAD watches encrypted HTTPS in both directions and can decode neither. What sits on David's terminal is a fully interactive shell prompt. This slide is deliberately short — the drama is on the next slide. -->

---

# But what if an APT actually made it in?

An Advanced Persistent Threat — nation-state grade, patient, well-funded — beats several layers on the way in. Fake identity that passed IAP. Some subset of the six defenses defeated. **They reach the vault. They grab a few gold bars.**

Now they need to run out.

**Every gate they passed is now a hostile checkpoint. Alarms firing across the base. Armed guards on high alert. Razor wire on every fence.** The moment they attempt to leave, every layer becomes a slowdown — **and the slowdown IS the security.**

## In GCP terms

| Fort Knox slowdown | GCP mechanism |
|---|---|
| Alarm bells throughout the compound | **Cloud Logging** captures every syscall, every outbound connection, every DNS lookup — unforgeable, shipped off-host in real time |
| Armed reinforcements arriving on scene | **Cloud Armor adaptive protection** scores the anomaly, tightens enforcement, blocks the source range |
| Razor wire on every fence — must be cut one strand at a time | **VPC egress restrictions** force outbound traffic through inspection points; RFC1918-only routing pins the attacker to a narrow escape corridor |
| No getaway vehicle in the vault | **The runtime service account** holds two IAM roles. It cannot write to buckets, cannot publish to PubSub, cannot invoke Cloud Functions. **Nowhere useful to send the gold.** |
| No cutting tools in the vault | **Distroless container.** No shell, no `curl`, no `wget`, no `bash`, no package manager. Nothing to pick up and use. |
| The on-call guards arrive | **Cloud Monitoring alerts** page the responder before the second exfil syscall completes |

**The gold cannot leave the vault faster than the alarm reaches the guards with guns.**

[DIAGRAM: APT figure in the vault holding a couple of gold bars. Escape route in the foreground: multiple layers of razor wire, armed guards closing in from every angle, alarm indicators lit red across the entire compound. Time-lapse hint: the APT is slowly, carefully cutting one strand of wire while multiple guards are within visible shooting range. On the right side, the GCP equivalents (Cloud Logging, adaptive protection, alerts) labeled onto each guard/wire/alarm.]

> **Fort Knox parallel:** Getting in requires stealth. Getting out requires speed. **The APT does not have speed** — because heavy gold bars move slowly, alarms do not, and armed guards do not miss. Exfil is where the mathematically-asymmetric physics of the situation catches up with them.

<!-- Speaker notes: This slide addresses the "yes but what if" question every serious buyer will ask. The answer: even in the counterfactual where an APT breaches multiple layers, the reverse-direction defenses are designed around slowdown. Every attempt to exfiltrate takes time — time for logging to capture, for alerts to fire, for adaptive protection to tighten, for the on-call to respond. The mathematical asymmetry between "cutting one strand of razor wire" and "shooting an armed intruder" is the point. This is straight out of the reverse-path section of docs/security/in-the-wild-2026-06-03.md. The prospect walks away thinking: even the worst-case-plausible scenario has the defender at the advantage. -->

---

# What did NOT happen.

- **No** public IP on the VM
- **No** VPN concentrator to patch forever
- **No** bastion host to patch forever
- **No** port 22 exposed to the public internet
- **No** credentials on the wire, ever
- **No** attack surface for `nmap` to find
- **No** DNS record pointing to anything attackable
- **No** SSH banner leaking software versions to scanners

**The observer at NORAD watched HTTPS. That's it.**

[HERO IMAGE: a big red X over a stereotypical "old-way" diagram — bastion host with public IP, VPN concentrator, patch-cycle calendar, security-audit paperwork. Underneath: a simple "→ IAP tunnel" replacement, one line.]

> **Fort Knox parallel:** The very best defense is a vault an attacker never finds. **No signs pointing to the depository. No visible cameras. No gate to case.** Same idea for David's VM: no public IP means nothing to point a scanner at. The APT scenario on the last slide is what happens when someone gets in *anyway*. This slide is what makes that scenario vanishingly rare in the first place.

<!-- Speaker notes: This is the punchline for the hero sequence. The datacenter-think architecture would have had at least three publicly-attackable surfaces — VPN endpoint, bastion, sometimes the VM itself. Cloud-think has ZERO. The attack surface is *nothing*. There is nothing for an attacker to scan. Combined with the previous slide (even if they got in, they can't get out), the argument is watertight. -->

---

# Now — the same six layers, in production, against real adversaries.

### Meet the Yamato Wiki.

A Star Blazers fan wiki, running on GCP, publicly discoverable at `yamato-dev.iq9.io`. Built as a working demo of GCP's security stack. Same six layers you just watched protect David's private VM — deployed differently, for a different workload, in the same architecture.

[HERO IMAGE: screenshot of the Yamato Wiki landing page — the crew cards, the Star Blazers hero art, the "Enter the Archive →" CTA button.]

<!-- Speaker notes: The point of the hero sequence was to walk mechanism. The point of the next section is to walk proof. Everything you're about to see is real production data from the last twenty-four hours, on infrastructure we built in a few days using the same principles. This is not a demo. This is what happens when you leave the site on the internet with alerts on. -->

---

# Layer 1 in production — 345 real attacks. All blocked.

**Last night, twenty unique adversaries hit `yamato-dev.iq9.io`.**

- 274 hits from a single AWS Paris IP hunting for `/.env` files (transactional-email credential theft)
- 71 hits from a long tail of Azure / OVH / residential scanners
- **Every single one blocked at Cloud Armor before the app was touched**

Zero operator intervention. Zero customer impact. One threshold alert to say "the wall is holding."

[SCREENSHOT: the /wiki/noc "Top source IPs · 24h" tile showing `13.36.195.225` at the top with 274 hits, and the long tail below. Ideally captured in a moment where the tile is populated with real numbers.]

<!-- Speaker notes: Same Layer 1 that would have blocked a hostile bot trying to hit David's VM. Here it's blocking bots trying to hit our public wiki. Full evidence trail — every source IP, every URL probed, every WAF rule that fired — is in docs/security/in-the-wild-2026-06-03.md. This slide is the moment prospects realize the deck isn't theoretical. This is the same "armed perimeter gate" from Hop 2, doing the same job on a different workload. -->

---

# Layer 2 in production — IAP gating /wiki.

- **`/`** — public landing page. No IAP. Anyone can see the Star Blazers crew cards.
- **`/wiki/*`** — IAP-gated. `@iq9.io` Google identity required. Every request. Not just the first.

[SCREENSHOT: the Google IAP sign-in redirect page — the branded "Sign in with Google" dialog with the domain restriction visible.]

<!-- Speaker notes: Same IAP that let David's SSH tunnel through when he had the right identity. On the wiki, IAP is enforcing a Google Workspace domain restriction. Same mechanism, different rule. Different workload, same layer. Same "biometric gate with armed guards" from the Fort Knox metaphor. -->

---

# Layers 3–5 in production.

- **Layer 3 — GFE** in front of the LB doing exactly what it did for David's SSH.
- **Layer 4 — IAP** at the LB, plus the runtime service account with two IAM roles total (`cloudsql.client` + one secret accessor).
- **Layer 5 — the workload:** Cloud Run ingress = `INTERNAL_LOAD_BALANCER` (the `*.run.app` URL rejects public traffic); Cloud SQL on **private IP only** (no `5432` reachable from the internet); distroless container image, nonroot, no shell.

**Same architecture as David's VM. Nothing publicly attackable at the innermost layers.**

[DIAGRAM: the same six-layer nested-boxes diagram from earlier in the deck, but with each layer annotated with its Yamato-specific implementation. Side-by-side with the "David's VM" version if space permits.]

<!-- Speaker notes: The mapping is direct. Layer 4 identity: IAP + IAM. Layer 5 workload perimeter: Cloud Run ingress lockdown, Cloud SQL private IP, minimal service account. Same shape as David's `35.235.240.0/20`-only firewall + OS Login SSH key check. Different technology; same architectural pattern. The distroless-container line is the same "no cutting tools in the vault" from the APT slide. -->

---

# The NOC — live evidence, refreshed every 30 seconds.

The tiles a prospect sees when they walk in:

- Cloud Armor blocks — last 1h and last 24h
- Top 5 source IPs — with provider attribution
- Top 5 probed URLs — the attacker menu, live
- Top WAF rule priorities — which layer of the WAF is firing
- 9 alert policies — green/yellow/red state board

**They don't have to trust the story. They watch it hold.**

[SCREENSHOT: the /wiki/noc dashboard, fully populated, with the AWS Paris IP visibly at the top of the source-IPs tile and the `.env` probe paths on the URLs tile.]

<!-- Speaker notes: The NOC is IAP-gated — signed-in @iq9.io identities only. It reads from Cloud Logging + Cloud Monitoring APIs on a 25-second cache, refreshes every 30 seconds. In a demo, you open this tab, log in, and let the prospect watch numbers change while you talk. The tile with the Paris attacker is the moment a serious buyer leans forward. -->

---

# Layer 0 — the honeypot lure.

We do not just block. **We identify.**

In 1983, David wardialed NORAD — trying every phone number until one answered. Today's bots wardial the *internet* — trying every URL until one leaks credentials. **Our honeypots are the numbers we leave for them to find, that go nowhere.**

Six deliberately enticing endpoints on the public service — `/admin`, `/backup.sql`, `/api/v1/users`, `/server-status`, `/phpmyadmin`, `/console` — outside Cloud Armor's block list. Every hit is logged with:

- Source IP
- User-agent (the tool fingerprint)
- Method
- First 1KB of the request body

The NOC tile shows the count climbing in real time.

[SCREENSHOT: the /wiki/noc "Tripwire hits · 24h" tile — total count on the left, top three lured paths on the right. Bonus if the top path is `/admin` because that's the most common bot target.]

<!-- Speaker notes: This is the Layer 0 lure — outside the perimeter gate. Bots that Cloud Armor doesn't already have a rule for come here, spring the wire, and we log everything about them. Cloud Armor gives us blocks; honeypots give us intelligence. "We don't just block attackers, we identify, fingerprint, and track them" is the exact sentence to use with a prospect. Wardialing callback: David's whole thing in the movie was calling every number in Sunnyvale until Joshua answered. Modern scanner bots do the same thing to URLs — the honeypot is the modern equivalent of a fake phone number that answers to keep the wardialer busy. -->

---

# What this cost to build.

- **Days**, not months
- **Multi-agent playbook** — Developer → Tester → Technical Writer, in sequence, with each role's context sealed off from the others so the Tester can't rationalize past the Developer's blind spots
- **Everything as code** — Terraform for infra, Cloud Build for app deploys, structured JSON handoffs between roles
- **Every commit reviewed by an independent agent** before landing
- **Full history reproducible from git** — you can walk any commit and see what was known when

The consulting angle: **the value is the playbook, not the days.**

[DIAGRAM: multi-agent playbook flow — Developer node → structured JSON → Tester node → structured JSON → Writer node → three commits on `dev-refresh`. Arrows for the fix-and-verify loop-back going the other direction, labeled "when the tester finds something worth fixing".]

<!-- Speaker notes: This is the SimplifyMy.Cloud differentiator. Any competent team can build this in the same days *if* they have the playbook. The playbook is the product. The wiki is the receipt. We can show them both. -->

---

# Appendix — Terraform for the ingress path.

```hcl
resource "google_compute_firewall" "allow_iap_ssh" {
  name          = "allow-ssh-from-iap"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]    # IAP's fixed range — the only allowed ingress
  target_tags   = ["allow-iap-ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_instance" "private_vm" {
  name         = "vm-name"
  machine_type = "e2-medium"
  zone         = "us-east1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnet.name
    # NB: no `access_config` block → no external IP.
  }

  tags = ["allow-iap-ssh"]
}

resource "google_iap_tunnel_instance_iam_member" "david_tunnel_access" {
  project  = var.project_id
  zone     = "us-east1-b"
  instance = google_compute_instance.private_vm.name
  role     = "roles/iap.tunnelResourceAccessor"
  member   = "user:david.lightman@example.com"
}
```

<!-- Speaker notes: For the appendix reader. Three resources total. Firewall accepts only IAP's range. VM has no external IP. One IAM binding grants David tunnel access. That is the whole architecture in ~30 lines of terraform. Nothing else needed. -->

---

# Further reading.

- **[`docs/security/in-the-wild-2026-06-03.md`](../security/in-the-wild-2026-06-03.md)** — the full 345-blocks-in-24h evidence trail, with methodology and reproducible gcloud queries
- **[`docs/noc.md`](../noc.md)** — how the /wiki/noc dashboard works end-to-end
- **[`docs/honeypot.md`](../honeypot.md)** — the Layer 0 lure, six paths, the log structure
- **[`docs/infrastructurestate.md`](../infrastructurestate.md)** — the layered architecture (Foundation / Service / App) and change-control posture
- **[`docs/multi-agent-playbook.md`](../multi-agent-playbook.md)** — the Developer → Tester → Writer pattern with brief-writing guidance
- **[`docs/security/fort-knox.md`](../security/fort-knox.md)** — the one un-hecklable claim, in prose

<!-- Speaker notes: These are the docs a prospect gets if they want to walk the receipts themselves. Each one stands alone. Prospects who read them all know the system as well as we do. -->

---

# Thank you.

**Chris Ashenbrenner · SimplifyMy.Cloud**

The Yamato Wiki is live at **`yamato-dev.iq9.io`**. The repo is real. The multi-agent playbook is at [`docs/multi-agent-playbook.md`](../multi-agent-playbook.md). The receipts are in [`docs/security/`](../security/).

We build like this for a living.

*Shall we play a game?* — this time, we already have.

[HERO IMAGE: closing art — the Yamato ship silhouetted against a nebula, with the Fort Knox layers superimposed as a translucent shield. Optional: a 1983-CRT overlay reading "THE ONLY WINNING MOVE IS TO ARCHITECT PROPERLY." — or the classic "SHALL WE PLAY A GAME?" answered by "yes — but properly this time."]

<!-- Speaker notes: Land the pitch. The wiki is a proof-of-work artifact — a prospect can visit it right now, watch the NOC, see the honeypots catching bots, read the /docs shelf. This is not a slide deck about what we could build. It is a slide deck built on top of what we did. The final WarGames callback ("shall we play a game?") lands as the invitation — the prospect's turn to engage. -->

---
