<!--
Deck: Life of a Packet — the six layers between a hostile network and your server
Status: Pass 3 — full rebuild around 10-concept pairs (technical + Fort Knox parallel per concept)
Audience: Consulting prospects (CTOs / CISOs); also readable as a self-serve portfolio piece
Slide format: `---` between slides (works for Marp, reveal.js, and plain markdown viewing on GitHub)
Speaker notes: <!-- Speaker notes: … --> HTML comments (Marp renders these to presenter view; hidden from slide)
Image placeholders: [HERO IMAGE / DIAGRAM / SCREENSHOT: <description>] — Chris drops in the 90%
Long-form companion: docs/presentations/longform/ has one chapter per concept
-->

# Life of a Packet

### How GCP protects a private VM from a network that watches everything.

Six layers, one packet, a NORAD infirmary, and a MacBook.

*Shall we play a game?*

[HERO IMAGE: title-slide art — a stylized single packet in flight against a backdrop that hints at Google's global backbone. Muted, cinematic. WarGames-era CRT green glow optional. Bonus: a subtle silhouette of Fort Knox in the deep background suggesting the metaphor to come.]

<!-- Speaker notes: Welcome. This is a talk about the specific mechanisms GCP uses to keep a private server safe when the user connecting to it is on a network that cannot be trusted. We follow one packet, hop by hop, from an untrusted MacBook to a server with no exposure to the public internet — and back. Along the way we see the six layers of defense that protect the server. Then we prove the same six layers work in production against real adversaries on the Yamato Wiki. Metaphor throughout: it's a Fort Knox heist. Six armed checkpoints, no negotiation, no shortcuts. -->

---

# It is 1983.

### David Lightman is trapped in NORAD's infirmary.

He hacked the door lock on the way in. Now he needs to hack a tunnel on the way out — **properly this time.**

No WOPR. No 300-baud modem. No wardialing. Just IAP.

Every wifi and wired network in the building is presumed watched, logged, and forwarded to somebody who wants a copy. **He is authorized. The network is hostile.**

[HERO IMAGE: NORAD infirmary from WarGames — David at a CRT terminal, keypad visible. If a real still is off-limits, stylized reproduction: 1983 CRT green-on-black, keypad, "Restricted Access" signage. Optional callback: an old 300-baud modem sitting unused on the desk.]

<!-- Speaker notes: The setup is deliberately anachronistic — GCE didn't exist in 1983 — and that's the joke. The point survives the anachronism: on ANY untrusted network, the security problem is identical. Coffee shop wifi. Hotel wifi. Foreign airport. A conference. A military facility with monitors on every cable. BeyondCorp's whole thesis is: assume the network is hostile, and design accordingly. Everything after this slide is us doing that. WarGames callback: David used to break IN with a modem; now he needs to get OUT without one. -->

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

<!-- Speaker notes: This one slide is the whole shift. In datacenter think, David would need a VPN concentrator with a public IP that somebody has to patch forever, plus a bastion host with a public IP that somebody has to patch forever. Both are attack surface. In cloud think, neither exists. The trust decision happens on David's identity before a packet reaches the network. -->

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

**Every layer holds independently.** Over the next 20 slides, we walk one packet through all six — as a mechanical trace on one slide, and as a Fort Knox parallel on the next. **Same architecture, two vocabularies.**

[DIAGRAM: replace ASCII with a proper nested-boxes visual — each layer color-coded, each labeled. Reference for the entire rest of the deck.]

<!-- Speaker notes: Every layer holds independently. If one fails catastrophically, the layer inside it still blocks the attack. The next section walks a single packet from Layer 0 (David's laptop) to Layer 5 (the VM) and back. Each hop is one Fort Knox layer being tested. Then the second half of the talk shows the same six layers defending a completely different workload — a public web app — against real adversaries. -->

---

# Concept 1 · The trust boundary is not the network.

**Operation Aurora, 2009.** Chinese state-sponsored attackers penetrated Google's perimeter and moved laterally through the "trusted" interior. The perimeter had worked as designed. The interior assumption — "if you're inside, you're trusted" — is what got exploited.

Google's conclusion was severe: **stop trusting the network entirely.**

That conclusion is called **BeyondCorp**. Identity-Aware Proxy (IAP) is BeyondCorp productized for cloud workloads. **Every request evaluated — per request — against identity + context. Location tells you nothing.**

> *WOPR eventually learned that some games can't be won. In 2010, Google learned the same thing about trusting its own network.*

[HERO IMAGE: newspaper-collage aesthetic of the January 2010 Aurora disclosure headlines. Google's blog post, WSJ, NYT. Underneath, a torn edge revealing "BeyondCorp" as the response.]

<!-- Speaker notes: For fifty years, security was built on one idea: draw a line around your network, trust anything inside it. That model broke publicly in late 2009. Chinese state-sponsored attackers ran a coordinated campaign against ~30 US tech companies. Google was the highest-profile target. The attackers spear-phished one Google employee, exploited an IE6 zero-day, dropped a backdoor. That laptop was inside Google's corporate network — so from that beachhead, they moved laterally, accessed Gmail accounts of Chinese human rights activists, accessed Google's source code repositories. The interior-is-trusted assumption was itself the vulnerability. Google published this January 12, 2010 — publicly named China, exited Chinese search market. Rebuilt around BeyondCorp: no implicit trust from network location, per-request evaluation on identity + device + context, least privilege continuously re-evaluated. IAP is Aurora's direct descendant. Every IAP check enforces the lesson Google learned when attackers moved laterally through their trusted interior. -->

---

# Fort Knox parallel · One wall isn't Fort Knox. Six walls are.

**Six independent layers. Each armed. Any one falls, five more hold.**

[HERO IMAGE: cross-section of Fort Knox showing all six concentric layers with an armed guard icon at each]

<!-- Speaker notes: Fort Knox hasn't been robbed in 90+ years — not because any single defense is unbeatable, but because you'd have to defeat six of them in sequence, each armed. That's BeyondCorp: not a better wall, six walls. -->

---

# Concept 2 · The packet is encrypted before it leaves your laptop.

The first thing David's laptop does — before the SSH connection reaches the VM, before IAP evaluates anything — is wrap the entire session in **TLS to Google's edge, over port 443.**

Anyone sniffing NORAD wifi sees an encrypted HTTPS connection to a Google address — indistinguishable from Gmail. **Because every HTTPS session looks the same, an attacker can't tell if this one is worth breaking** — and expensive attacks aren't worth mounting against an unknown payload.

Same reason **BitTorrent, Bitcoin, and Tor** all tunnel over 443 in restrictive networks. It's a battle-tested design pattern, not a novel trick.

[DIAGRAM: three-panel visual. Panel 1: David's MacBook with outbound arrow wrapped in TLS envelope. Panel 2: what the sniffer sees — encrypted hex, port 443, destination Google, indistinguishable from Gmail. Panel 3: strip along the bottom showing BitTorrent, Bitcoin, Tor logos with caption *"the same technique, for the same reason."*]

<!-- Speaker notes: David's laptop takes the entire SSH session and wraps it in TLS before anything reaches a Google server. That single step is where NORAD's wifi loses. Sniffers see: encrypted bytes going to a Google IP on port 443. They don't see SSH. They don't see credentials. They don't see the target VM hostname. Indistinguishable from Gmail. Every HTTPS session on the internet looks identical from the outside — so an attacker who wanted to break David's specific connection wouldn't know in advance whether it was worth their time. A serious attack against a single TLS session takes real resources; the payoff of any random HTTPS session is unknowable. Expected value collapses toward zero. Attackers walk away. Not a novel trick: BitTorrent moved to port 443 to bypass ISP throttling. Bitcoin nodes in restrictive networks configure port 443. Tor's pluggable transports make Tor traffic look like HTTPS to defeat national censorship. IAP applies a design pattern that already works to move BitTorrent through corporate firewalls and Bitcoin through the Great Firewall. If it works there, it works for David. Encryption is TLS 1.3 with perfect forward secrecy — an adversary recording tonight can't decrypt with next year's stolen keys. -->

---

# Fort Knox parallel · The armored truck. And it might be empty.

**Every truck looks identical. Attacking is expensive; the payoff is unknown; most attackers walk away.**

[HERO IMAGE: highway scene with three armored trucks driving in a row, visually identical from outside. Cargo x-ray above each: Truck 1 = gold bars. Truck 2 = cash. Truck 3 = empty. Observers on the roadside with binoculars, thought bubbles: *"which one?"* On the horizon, a lone hijacker walking away.]

<!-- Speaker notes: The packet is the armored truck. TLS is the seal. Every HTTPS session looks identical from outside — same shape, unknown contents. Attackers can't tell if breaking THIS one is worth their time, so most don't try. -->

---

# Concept 3 · The packet lands at Google's edge. TLS terminates. DDoS dies.

David's packet, anycast-routed to the nearest **Google Front End (GFE)**, lands at the outermost active defense of Google's cloud. GFE terminates TLS, applies **DDoS scrubbing at Google-network scale.**

**Volumetric attacks die here.** In 2020: **2.5 Tbps** flood absorbed. In 2023: **398 million HTTP requests per second** (Rapid Reset attack). All dropped at the edge.

**This is the last hop on the public internet** — beyond GFE, every packet rides Google's own fiber.

[DIAGRAM: Google PoP as fortified gate. Approaching it: swarm of thousands of tiny "attack packet" icons labeled *SYN flood, HTTP/2 rapid reset, amplification, slowloris*. At the gate, all bounce off. One legitimate packet (David's) passes through cleanly. Stat callouts: *"2.5 Tbps mitigated · 2020"* and *"398M rps mitigated · 2023."*]

<!-- Speaker notes: After David's packet leaves his laptop wrapped in TLS, its first stop on Google's infrastructure is the Google Front End. Every internet-facing Google service — Search, Gmail, YouTube, Cloud Run, IAP itself — sits behind a GFE. Nothing on Google Cloud is directly exposed to the public internet. Anycast routing finds the closest of 150+ PoPs automatically. When packet arrives, three things happen: TLS terminated on Google-designed hardware, DDoS scrubbing runs at Google-network scale, packet routed inward onto Google's private fiber. In 2020 Google mitigated a 2.5 Tbps DDoS — largest ever recorded at the time. In 2023 the HTTP/2 Rapid Reset attack hit 398 million rps against Google services — all absorbed at the edge. For context: "large" DDoS against typical enterprise is tens of Gbps. Google routinely absorbs several times the peak volume of the Mirai botnet. The math is asymmetric permanently: defender is Google's entire edge capacity, tens of Tbps provisioned for YouTube-at-Super-Bowl-Sunday scale. No attacker can bring more traffic than that. Even if there were a nation-state DDoS at the exact moment David's packet arrived, his packet still passes. This is the last time it's on the public internet. -->

---

# Fort Knox parallel · The outer gate. Backed by a tank division.

**One tank defeats a thousand cars. Not by being stronger — by being entirely different equipment.**

[HERO IMAGE: Fort Knox outer perimeter gate. Armed soldier at checkpoint. Behind: visible tanks parked in formation — M1 Abrams, Bradley Fighting Vehicles. In front of the gate: chaotic swarm of vehicles trying to push through, all stopped cold. Caption: *"a thousand cars against one tank division: the math is wrong."*]

<!-- Speaker notes: The outer gate holds against volumetric attacks not because it's individually unbreakable, but because behind it sits a US Army armor installation with a tank division. Adding more cars doesn't help. That's GFE + Google's global network capacity. -->

---

# Concept 4 · The packet leaves the public internet. From here it's Google's own fiber.

After GFE clears David's packet, **the packet leaves the public internet.** From this hop until the response returns, every switch, every router, every mile of fiber is Google's own — **one million miles of fiber, 15+ subsea cables** (Curie, Dunant, Grace Hopper, Firmina), run by **B4** (Google's SDN with centralized traffic engineering).

Every RPC across the network is encrypted with **ALTS** (or its hardware-offloaded successor, PSP). Because Google learned in 2013 — via the NSA's **MUSCULAR program** tapping Google's own internal fiber — that **owning the fiber is not the same as trusting the fiber.**

[DIAGRAM: World map with Google's global fiber network highlighted in Google-blue — subsea cables named. Overlay of a single packet's path from Denver → us-east1. Small "ALTS encrypted" lock icons at each internal hop. Optional inset: "NSA MUSCULAR tap" icon on a submarine cable crossed out with red X, annotated *"2013 wake-up call → encrypted everywhere since."*]

<!-- Speaker notes: After GFE clears David's packet, the packet leaves the public internet entirely. Everything from here to us-east1 is Google's own fiber. One million miles + 15 subsea cables. Backbone run by B4, Google's SDN — centralized traffic engineering with global visibility instead of distributed BGP. Now the important bit. Google owns the fiber, huge advantage. But owning the fiber is NOT the same as trusting the fiber. In October 2013, Snowden disclosures revealed an NSA program called MUSCULAR that had been tapping unencrypted links between Google's own data centers, exfiltrating hundreds of millions of internal records per day. Google's response — leaked engineer comment "these guys have to go" — was to encrypt every internal link everywhere. That produced ALTS: mutual authentication + encryption on every RPC, even inside Google. Newer traffic uses hardware-offloaded PSP. MUSCULAR is to Google's network what Aurora was to Google's corporate identity model — both permanent architectural shifts toward never trusting the perimeter. When David's packet rides Google's fiber, it's ALTS-encrypted at every RPC hop, invisible to public adversaries AND to any Google operator with a wire tap. The interior is more encrypted than the perimeter, not less. -->

---

# Fort Knox parallel · The base interior. Private roads. Roving patrols. Random ID checks.

**The interior is monitored more heavily than the perimeter, not less.**

[HERO IMAGE: aerial view of Fort Knox interior showing internal road network with multiple checkpoints between the outer gate and the depository. Armed patrol vehicles in transit. A visitor's badged vehicle being stopped by a roving patrol at a random interior checkpoint. Cameras at every intersection.]

<!-- Speaker notes: Past the outer gate is not "the trusted interior." It's the vast, monitored, patrolled interior of an armor installation. Passing GFE gets your packet on Google's backbone — it doesn't give you free run of Google's interior. Every RPC still authenticates (ALTS). The perimeter filters; the interior verifies. -->

---

# Concept 5 · IAP checks identity. Per request. Every request.

David's packet, now on Google's private backbone, arrives at **Identity-Aware Proxy**. IAP asks two questions on every request: **who is this identity, and are they authorized right now?**

Identity: cryptographic — IAP validates David's JWT signed by **Google Auth**, verified against Google's public keys.

Authorization: **Cloud IAM** tells IAP whether David holds `roles/iap.tunnelResourceAccessor` on this VM.

**These are two separate services.** Google Auth (identity plane, not part of GCP) issues the token; Cloud IAM (GCP authorization plane) consumes it. **GCP is a customer of Google Auth via the same OAuth/OIDC standards any "Sign in with Google" integration uses.**

Both checks happen **every request.** Not once at login. Every request. **If David's admin revokes his access at 3:00pm, his active SSH tunnel dies at 3:01pm on the next TCP segment.**

[DIAGRAM: IAP as a checkpoint. Above IAP, two labeled boxes connected by an "OAuth/OIDC" arrow: *"Google Auth (identity plane — not GCP)"* and *"Cloud IAM (GCP authorization plane)."* Below IAP, two sequential doors: JWT signature check → Google Auth; role check → Cloud IAM. Both green → passes through. Timeline at bottom: *3:00:00 → OK · 3:00:30 → OK · 3:01:00 → admin revoked → DENIED.*]

<!-- Speaker notes: This is the zero-trust moment of the packet trace — BeyondCorp made concrete for the user identity layer. IAP asks two questions on every request: identity and authorization. Identity check is cryptographic: David authenticated to gcloud earlier via gcloud auth login, got an OAuth refresh token. gcloud uses it to get a short-lived access token — a JWT signed by Google. IAP verifies the signature against Google's public keys. Authorization check: IAP asks Google's central IAM system whether David has roles/iap.tunnelResourceAccessor on this specific VM. If yes, tunnel opens. If no, 403. Architectural detail worth naming: these are two separate systems. Google Auth is the identity service, not a Google Cloud product — same team, same infrastructure that authenticates Gmail, YouTube, Android, and every Google Workspace user in the world. Google Cloud is a customer of Google Auth via standard OAuth 2.0 and OIDC — the same protocol any third-party "Sign in with Google" integration uses. Cloud IAM's job starts when Google Auth's job ends. Two systems, one clean interface, independent failure domains. Genuinely different from AWS (own identity system) or Azure (Entra ID). Critical operational point: both checks happen fresh on every request. Not once at login. If David's admin revokes his tunnel-access role at 3:00pm, David's active SSH session dies at 3:01pm on the next TCP segment. Session does not outlive the underlying grant. Employee leaves mid-day: admin disables account, all active sessions terminate within minutes. The authorization system IS the session controller. Works with Workforce Identity Federation for non-Google IdPs (Okta, Azure AD, Auth0) — same per-request property. -->

---

# Fort Knox parallel · The Depository's biometric gate. Every visit, every time.

**Yesterday's badge is not today's badge. Every entry is a fresh authorization event.**

[HERO IMAGE: ultra-modern Depository building entrance. Biometric scanners (fingerprint, retina). Guard station with a live-updating access-roster display. Depository employee being prompted for fingerprint scan even though clearly a long-time employee. Small red-X animation showing scanner querying live database and getting "access revoked." Guards flanking, hand near holsters.]

<!-- Speaker notes: Not a locked door with a key — biometric gate with a real-time database check. Even long-tenured employees prompted every visit. If HR disabled your access at 3:00pm, the scanner refuses you at 3:01pm. That's IAP's per-request identity model in physical form. -->

---

# Concept 6 · Even with the right identity: is the request also in the right context?

Identity is not enough. IAP's second-layer check — **Context-Aware Access** — evaluates the *circumstances* of the request.

Is this from a **corporate-managed device with a valid device certificate?** Is disk encryption enabled? Is the OS above the minimum patch level? Is the source IP in the corporate egress range, or an allowed country?

**Even if David's OAuth token is valid, if any context signal fails the policy, IAP denies the request.**

This is the practical answer to *"what if a nation-state phishes David's refresh token?"* — the attacker doesn't have David's laptop, can't fake the device certificate, can't fake the corporate egress IP. **Stolen credentials alone are worthless.**

[DIAGRAM: IAP checkpoint as a THIRD door in sequence (Doors 1 and 2 were identity + IAM). Door 3 = "Context signals." Below Door 3: stack of icons — laptop with green checkmark *(device cert valid)*, padlock *(disk encrypted)*, globe with checkmark *(IP in allowlist)*, version tag *(OS ≥ 14)*. Any one turns red → the door slams. Inset: attacker with stolen token running on wrong laptop, stopped at Door 3, caption *"valid token, wrong device."*]

<!-- Speaker notes: Getting past the biometric gate is not the whole IAP story. Even after IAP validates David's OAuth token and confirms his IAM role, there's a second-layer check: Context-Aware Access. This is where IAP crosses from "authenticator" into genuine BeyondCorp zero-trust. CAA evaluates the circumstances: corporate-managed device with a valid device certificate? Disk encryption enabled? OS above minimum patch level? Source IP in corporate egress range? Any signal fails, request denied — even with valid OAuth token, even with right IAM role. The specific scenario this defends against is the most common breach pattern: credential theft. Attacker phishes David, exfiltrates malware from his laptop, or buys credentials on a breach forum. With identity-only IAP, that's game over. With CAA, the attacker's token is valid but circumstances aren't. They don't have David's laptop. Can't fake the corporate device certificate. Can't fake corporate egress IP. 403 forbidden. BeyondCorp thesis was always three things: identity, device, context. Chapter 5 was identity. This is device + context. Together they replace the perimeter model with something categorically stronger — attacker needs to compromise credentials AND specific hardware AND network location AND compliant OS version. Each orders of magnitude harder. Operationally: laptop stolen → MDM revokes device cert → next request denied instantly. Employee travels to restricted country → CAA geo-policy denies. OS falls below patch level → denied until updated. -->

---

# Fort Knox parallel · The escort in the hallway. Right person, right context, or turned around.

**Identity gets you past the gate. Context is what keeps you moving forward.**

[HERO IMAGE: interior of the Depository hallway. Escort officer walking alongside visitor toward the vault. Escort has tablet showing live checklist: *"arrival gate authorized ✓ · background check current ✓ · escort clearance valid ✓ · authorized items only ✓ · hours within business window ✓."* One box turned red: *"unauthorized device in pocket ✗"*. Escort turning toward visitor, hand near holster.]

<!-- Speaker notes: The biometric gate confirmed identity. The escort now checks a different set of things: what you're carrying, where you came from, whether your background check is current. Right person, wrong context, turned around. That's Context-Aware Access — the answer to "what if a nation-state phishes your credentials." -->

---

# Concept 7 · The VPC firewall. Only IAP gets through. No exceptions.

Even after IAP validates identity and context, one more layer sits between the packet and the VM: the **VPC firewall.**

The rule is deliberately narrow — only traffic from IAP's fixed source range **`35.235.240.0/20`** (about 4,096 IPs) is allowed on port 22. Everything else — public internet scanners, another VM in the same project, a misconfigured route — is dropped silently.

**Even if IAP itself had a bug and let an unauthorized request through, the VPC firewall would still refuse it**, because the traffic wouldn't come from IAP's known source range. **Two independent gates, both must open.**

The rule is Terraform-managed in ~5 lines of HCL. **The VM's entire ingress surface is 4,096 IPs on one port — and Google owns them all.**

[DIAGRAM: VPC boundary as a fortified wall. Along the wall, one single narrow doorway labeled `35.235.240.0/20 : tcp/22 (IAP only)`. All other sides of the wall labeled `DENY`. Traffic from IAP passes through; traffic from other sources bounces off. Inside: the VM. Inset: 5-line Terraform snippet.]

<!-- Speaker notes: Belt-and-suspenders at the network layer. The rule is deliberately narrow: only source range 35.235.240.0/20 on port 22. That's IAP's fixed, published range — 4,096 addresses that Google owns and reserves for IAP tunneling. Everything else denied. Why do we need this if IAP already checks identity and context? Because layers must be independent. If IAP had a bug tomorrow — zero-day, misconfiguration, whatever — the firewall still holds because it doesn't care about IAP's authentication logic. It cares about the source IP. Anything not from 35.235.240.0/20 is dropped no matter how legitimate at the application layer. Two independent gates, two independent enforcement mechanisms, both required. A vulnerability in one doesn't compromise the other. Real scenarios: IAP accidentally removed from LB config (VPC firewall still holds), zero-day in IAP (firewall catches direct network attempts), insider trying to reach VM from another VM in the project (denied), route misconfiguration (firewall enforces the source-IP restriction regardless). Terraform-managed, five lines of HCL. Cloud Run analog: ingress = INTERNAL_LOAD_BALANCER. Same architectural pattern for serverless. -->

---

# Fort Knox parallel · The vault hallway. Escort service only. No exceptions.

**The vault hallway has its own roster. Even valid Depository badges get turned back if they're not on it.**

[HERO IMAGE: vault hallway. Two armed guards at the entrance holding a printed roster. Escort officer and visitor from Chapter 6 arriving; guards check roster — both names present — step aside. On the far wall: the vault door visible in the distance. Another figure approaching from a different corridor — clearly badged employee — being politely but firmly turned back by a second guard, caption *"not on the vault list."*]

<!-- Speaker notes: Even inside the building, the vault hallway is its own perimeter with its own credentialed personnel. Passing the biometric gate doesn't put you here. That's the VPC firewall — two independent authorizations, both required, so if IAP fails or misconfigures, the firewall still holds. -->

---

# Concept 8 · OS Login validates the SSH key. Second independent check at the VM.

The packet has arrived at the VM. But **IAP only tunneled raw TCP — it did not authenticate the SSH connection itself.**

**OS Login** validates David's SSH public key (pushed to the VM based on his Google identity + IAM role) against `sshd`. **A completely independent check from IAP.** IAP asked *"can this identity open a tunnel?"* OS Login asks *"does this identity have a valid SSH key?"* **Two questions, two answers, both required.**

Even if IAP had somehow been bypassed, OS Login still refuses because the attacker doesn't have David's private key. And **revoke the key in Google's admin console → it stops working on every VM in the fleet within seconds.** No config-management push. No stale `authorized_keys` on forgotten VMs.

[DIAGRAM: the VM as a small fortified vault. Two doors in sequence on the VM itself. Door 1: IAP tunnel arrival, labeled *"identity-authorized to reach port 22"*. Door 2: sshd + OS Login, labeled *"SSH key validated against Google identity"*. Both green → shell spawns. Either red → connection refused. Side diagram showing key upload flow. Optional far right: "revocation" scene — admin clicks revoke, red X propagates across fleet.]

<!-- Speaker notes: David's packet has cleared every layer between his laptop and the VM. Seven layers of defense. But one more check before he gets a shell. IAP only tunneled raw TCP — it made the connection reachable but did not authenticate the SSH protocol itself. That's OS Login's job, at the VM. OS Login is Google's replacement for traditional SSH key management. Instead of per-VM authorized_keys files that admins have to distribute, OS Login federates SSH access to Google's identity system. David uploaded his SSH public key to his Google identity via gcloud compute os-login ssh-keys add. When David's SSH client connects, sshd runs the OS Login PAM module, queries Google's metadata server for David's authorized keys, compares presented key against returned list. If key matches and David holds roles/compute.osLogin, shell spawns. Two independent authorization systems at the same request. IAP asks "can this identity open a tunnel to this VM's port 22?" OS Login asks "does this identity have a valid SSH key for this OS user?" Different IAM roles gate them. Different authentication artifacts prove them. Both must succeed. Belt-and-suspenders at the innermost layer. Operational value mirrors IAP: revoke the key in Google's admin console, stops working on every VM within seconds. No config-management push. No SSH-to-every-host cleanup. No stale authorized_keys on forgotten VMs. Identity plane is the source of truth; VMs pull from it. Employee terminated: their SSH access to every VM in every project dies within minutes. Compromised key: remove from Google identity, key stops working everywhere. Fleet-wide access grant for new team member: grant roles/compute.osLogin at project level, immediate on all VMs. Time-boxed contractor: CAA-conditional grant, silently ends after N days. -->

---

# Fort Knox parallel · The vault cage. YOUR key to YOUR cage. Sentry says no.

**Right roster entry + right physical key. Either wrong = cage stays shut.**

[HERO IMAGE: interior of the vault, wall of ornate golden cages. David at his specific cage, inserting his key. Behind him, armed vault sentry (weapon at shoulder) watching. Cage door opening — key worked, roster entry current. In the background, another visitor at a different cage: their key doesn't fit; cage stays locked; second sentry has hand near holster. Caption: *"identity + key + current roster = access. Any wrong = cage stays shut."*]

<!-- Speaker notes: You've made it to the cage. But the cage has its own lock — unique to your specific cage, requiring your personal key registered in the central roster. Wrong key, cage stays shut. That's OS Login — a second independent authorization at the innermost layer, distinct from IAP's tunnel-authorization check. -->

---

# Concept 9 · Return path. Same six hops. And where the trap closes.

The return trip is the six hops reversed — same tunnel, same encryption, same layered infrastructure.

For an authorized user like David, the exit is uneventful — output flows back, nobody notices. **But the same reverse path becomes the killing floor for anyone who was NOT supposed to be in.**

Every layer that authorized traffic passes through smoothly becomes a *slowdown* for unauthorized traffic. Every exit attempt is logged. Every anomaly scores against the adversary. **Alarms fire while the intruder is still trying to leave. The gold, being heavy, moves slower than the alarm.**

**The next slide is what that actually looks like.**

[DIAGRAM: same six-layer diagram with arrows in both directions, split into two rows. Top row (labeled *"authorized user path"*) shows David's output flowing back smoothly, no alarm indicators. Bottom row (labeled *"attacker exfiltration path"*) shows the same six hops with alarm indicators lighting up at every checkpoint. Large red arrow pointing to bottom row: *"next slide."*]

<!-- Speaker notes: Return trip is the six hops reversed. Same tunnel, same encryption, same infrastructure. For David the exit is uneventful — output flows back, nobody notices. But the same reverse path becomes a killing floor for anyone who wasn't supposed to be in. Every layer that authorized traffic passes through smoothly becomes a slowdown for unauthorized traffic. Every exit attempt is logged. Every anomaly scores against the adversary. Alarms fire while the intruder is still trying to leave. The gold, being heavy, moves slower than the alarm. The next slide — the APT counterfactual — is where the whole story pays off. -->

---

# Fort Knox parallel · Legitimate courier walks out unnoticed. The intruder does not.

**Same infrastructure. Radically different experience. The alarm decides which.**

[HERO IMAGE: split panel. Left: David walking out through the six gates, guards nodding, no drama, calm and procedural. Right: shadowy intruder trying to walk out through the same six gates, alarm lights blaring red at each checkpoint, guards converging with weapons drawn, intruder visibly slowing under the weight of gold bars.]

<!-- Speaker notes: The authorized courier walks the six gates and is recognized at each — no drama. The intruder walking the same six gates has a very different experience: every checkpoint transforms into a slowdown. The distinction is whether an alarm has fired somewhere behind you. -->

---

# Concept 10 · The APT gets in. And meets the reverse-flow defenses.

Assume the impossible: a nation-state APT has defeated the six-layer inbound defense. **They have a shell on the VM. They've grabbed data. Now they need to exfiltrate.**

Every action generates unforgeable **Cloud Logging** entries shipped off-host in real time. **Cloud Armor's adaptive protection** scores the anomaly and tightens enforcement automatically. **VPC egress + VPC Service Controls** force outbound traffic through inspected corridors — even a bucket the attacker controls in their own project is blocked by the data perimeter. **The runtime service account holds almost no IAM** — nowhere useful to send the stolen data. **The distroless container has no shell, no `curl`, no `wget`** — no tools to cut with. **Cloud Monitoring alerts** page the on-call within seconds.

**The attacker's window between "grabbed data" and "gets caught" is measured in seconds, not hours. The gold, being heavy, moves slower than the alarm.**

**"Nobody gets in" is a fantasy. "Even if they get in, they can't get out" is the real guarantee.**

[DIAGRAM: VM with "COMPROMISED" indicator flashing. Inside: shadowy attacker with data blocks in hand. Around them: alarm indicators lighting up in sequence — Cloud Logging (stream off-host), adaptive protection (score climbing), egress restrictions (razor wire), minimal SA (near-empty IAM), distroless (empty toolbox), alerts (paging icon). Arrows showing attacker trying to move outward, bouncing off each layer. Timeline strip: *T+0 first exfil syscall · T+3s Cloud Logging entry off-host · T+15s adaptive protection tightens · T+30s alert paged · T+45s SecOps engaged · T+60s session terminated.* Caption: *"the window is measured in seconds."*]

<!-- Speaker notes: This is the dramatic finale of the packet trace. Grant the impossible: a nation-state APT has defeated the six-layer inbound defense. Fake identity that passed IAP, zero-day that bypassed OS Login, whatever it took. They're on the VM, they have a shell, they've grabbed some data. Now they need to leave with it. This is where the architecture pays its second, larger dividend. Every action generates evidence — Cloud Logging captures every syscall, every outbound connection, every DNS lookup, shipped off-host in real time to a bucket the attacker doesn't have access to. There is no way to erase the trail from inside the compromised VM. Cloud Armor's adaptive protection scores the anomaly in real time and tightens enforcement automatically. VPC egress restrictions and VPC Service Controls force outbound traffic through inspected corridors — even if the attacker has valid credentials for a bucket in their own project, VPC SC blocks the exfil because it crosses the data perimeter. Runtime SA has almost no IAM — no storage.admin, no pubsub.publisher, no Cloud Functions invoke. Nowhere useful to send the stolen data. Distroless container: no shell, no curl, no wget, no bash. No tools to cut with. Cloud Monitoring alerts page the on-call within seconds. Physics: data movement is bandwidth-bounded, alert propagation is essentially instantaneous. Attacker's ability to move data is bounded by these constraints; defender's response is bounded only by human reaction time. Window measured in seconds, not hours. The gold, being heavy, moves slower than the alarm. This is the security guarantee that actually matters. Not "nobody ever gets in." But: even if somebody does get in, they cannot get out with what they came for. Not because we're perfect. Because we architected the physics to be against them. -->

---

# Fort Knox parallel · Gold in hand. Alarms already firing. Guards converging. Razor wire on every fence.

**The gold cannot leave the vault faster than the alarm reaches the guards.**

[HERO IMAGE: interior of the vault mid-heist. Intruder crouched, arms full of gold bars (visible weight, visible strain). All around: alarm strobes flashing red, guards visible converging from multiple corridors with weapons drawn. Cross-section overlay showing every previous checkpoint on the way out now sealed and reinforced. Razor wire on the fences. Getaway vehicle in the far distance, unreachable. Counter in corner: *"Time since alarm: 00:17 · Guards converging: 12 · Exits sealed: 6 of 6."*]

<!-- Speaker notes: The intruder in the vault, arms full of gold, needs to walk back out through the same six gates. But those gates are no longer the same. Alarms firing, guards converging, exits sealed. 27-pound gold bars slow the intruder; alarms travel at the speed of light. Physics is against them. That's the security guarantee that actually matters — not "nobody gets in," but "even if they do, they can't get out." -->

---

# Now — the same six layers, in production, against real adversaries.

### Meet the Yamato Wiki.

A Star Blazers fan wiki, running on GCP, publicly discoverable at `yamato-dev.iq9.io`. Built as a working demo of GCP's security stack. **Same six layers you just watched protect David's private VM — deployed differently, for a different workload, in the same architecture.**

[HERO IMAGE: screenshot of the Yamato Wiki landing page — crew cards, Star Blazers hero art, "Enter the Archive →" CTA.]

<!-- Speaker notes: The hero sequence walked mechanism. The next section walks proof. Everything you're about to see is real production data from the last 24 hours, on infrastructure we built in a few days using the same principles. Not a demo. This is what happens when you leave the site on the internet with alerts on. -->

---

# Layer 1 in production — 345 real attacks. All blocked.

**Last night, twenty unique adversaries hit `yamato-dev.iq9.io`.**

- 274 hits from a single AWS Paris IP hunting for `/.env` files (transactional-email credential theft)
- 71 hits from a long tail of Azure / OVH / residential scanners
- **Every single one blocked at Cloud Armor before the app was touched**

Zero operator intervention. Zero customer impact. One threshold alert to say "the wall is holding."

[SCREENSHOT: /wiki/noc "Top source IPs · 24h" tile showing `13.36.195.225` at top with 274 hits, and the long tail below.]

<!-- Speaker notes: Same Layer 1 that would have blocked a hostile bot trying to hit David's VM. Here it's blocking bots trying to hit our public wiki. Full evidence trail in docs/security/in-the-wild-2026-06-03.md. This is the moment prospects realize the deck isn't theoretical. -->

---

# Layer 2 in production — IAP gating /wiki.

- **`/`** — public landing page. No IAP. Anyone can see the Star Blazers crew cards.
- **`/wiki/*`** — IAP-gated. `@iq9.io` Google identity required. Every request. Not just the first.

[SCREENSHOT: Google IAP sign-in redirect page — branded "Sign in with Google" dialog with domain restriction visible.]

<!-- Speaker notes: Same IAP that let David's SSH tunnel through when he had the right identity. On the wiki, IAP enforces a Google Workspace domain restriction. Same mechanism, different rule. Same "biometric gate with armed guards" from the Fort Knox metaphor. -->

---

# Layers 3–5 in production.

- **Layer 3 — GFE** in front of the LB, doing exactly what it did for David's SSH.
- **Layer 4 — IAP** at the LB, plus the runtime service account with two IAM roles total (`cloudsql.client` + one secret accessor).
- **Layer 5 — the workload:** Cloud Run ingress = `INTERNAL_LOAD_BALANCER` (the `*.run.app` URL rejects public traffic); Cloud SQL on **private IP only**; distroless container image, nonroot, no shell.

**Same architecture as David's VM. Nothing publicly attackable at the innermost layers.**

[DIAGRAM: the six-layer nested-boxes diagram from earlier in the deck, but with each layer annotated with its Yamato-specific implementation. Side-by-side with the "David's VM" version.]

<!-- Speaker notes: Direct mapping. Layer 4 identity: IAP + IAM. Layer 5 workload perimeter: Cloud Run ingress lockdown, Cloud SQL private IP, minimal service account. Same shape as David's 35.235.240.0/20-only firewall + OS Login SSH-key check. Different technology; same architectural pattern. Distroless container is the "no cutting tools in the vault" from the APT slide. -->

---

# The NOC — live evidence, refreshed every 30 seconds.

The tiles a prospect sees when they walk in:

- Cloud Armor blocks — last 1h and last 24h
- Top 5 source IPs — with provider attribution
- Top 5 probed URLs — the attacker menu, live
- Top WAF rule priorities — which layer of the WAF is firing
- 9 alert policies — green/yellow/red state board

**They don't have to trust the story. They watch it hold.**

[SCREENSHOT: /wiki/noc dashboard, fully populated, with AWS Paris IP visibly at top of source-IPs tile and `.env` probe paths on URLs tile.]

<!-- Speaker notes: NOC is IAP-gated — signed-in @iq9.io identities only. Reads from Cloud Logging + Cloud Monitoring APIs on a 25-second cache, refreshes every 30 seconds. In a demo, open this tab, log in, let the prospect watch numbers change while you talk. The tile with the Paris attacker is the moment a serious buyer leans forward. -->

---

# Layer 0 — the honeypot lure.

We do not just block. **We identify.**

In 1983, David wardialed NORAD — trying every phone number until one answered. Today's bots wardial the *internet* — trying every URL until one leaks credentials. **Our honeypots are the numbers we leave for them to find, that go nowhere.**

Six deliberately enticing endpoints on the public service — `/admin`, `/backup.sql`, `/api/v1/users`, `/server-status`, `/phpmyadmin`, `/console` — outside Cloud Armor's block list. Every hit is logged with source IP, user-agent, method, and first 1KB of the request body.

[SCREENSHOT: /wiki/noc "Tripwire hits · 24h" tile — total count on the left, top three lured paths on the right.]

<!-- Speaker notes: Layer 0 lure — outside the perimeter gate. Bots that Cloud Armor doesn't already have a rule for come here, spring the wire, and we log everything about them. Cloud Armor gives us blocks; honeypots give us intelligence. "We don't just block attackers, we identify, fingerprint, and track them." Wardialing callback: David's whole thing in the movie was calling every number in Sunnyvale until Joshua answered. Modern scanner bots do the same thing to URLs — the honeypot is the modern equivalent of a fake phone number that answers to keep the wardialer busy. -->

---

# What this cost to build.

- **Days**, not months
- **Multi-agent playbook** — Developer → Tester → Technical Writer, in sequence, with each role's context sealed off from the others so the Tester can't rationalize past the Developer's blind spots
- **Everything as code** — Terraform for infra, Cloud Build for app deploys, structured JSON handoffs between roles
- **Every commit reviewed by an independent agent** before landing
- **Full history reproducible from git** — you can walk any commit and see what was known when

**The consulting angle: the value is the playbook, not the days.**

[DIAGRAM: multi-agent playbook flow — Developer node → structured JSON → Tester node → structured JSON → Writer node → three commits on `dev-refresh`. Arrows for fix-and-verify loop-back the other direction.]

<!-- Speaker notes: SimplifyMy.Cloud differentiator. Any competent team can build this in the same days if they have the playbook. The playbook is the product. The wiki is the receipt. We can show them both. -->

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

<!-- Speaker notes: For the appendix reader. Three resources total. Firewall accepts only IAP's range. VM has no external IP. One IAM binding grants David tunnel access. That is the whole architecture in ~30 lines of terraform. -->

---

# Further reading — the long form.

Each concept from this deck has a full-chapter written version in `docs/presentations/longform/`:

1. [The Trust Boundary Is Not the Network](../presentations/longform/01-beyondcorp-premise.md) — Aurora, BeyondCorp
2. [TLS Wrap on the Client](../presentations/longform/02-tls-wrap-on-the-client.md) — port 443, uncertainty tax, BitTorrent/Bitcoin/Tor precedent
3. [GFE + DDoS Scrubbing](../presentations/longform/03-gfe-ddos-scrubbing.md) — 2.5 Tbps, 398M rps, tank division
4. [Google's Private Backbone](../presentations/longform/04-google-private-backbone.md) — B4, ALTS, MUSCULAR
5. [IAP Identity Check](../presentations/longform/05-iap-identity-check.md) — OAuth/JWT, per-request, Google Auth separation
6. [IAP Context Check](../presentations/longform/06-iap-context-check.md) — device posture, credential-theft defense
7. [VPC Firewall (`35.235.240.0/20`)](../presentations/longform/07-vpc-firewall.md) — belt-and-suspenders independence
8. [OS Login SSH Key Check](../presentations/longform/08-os-login-ssh-key-check.md) — central identity as SSH truth
9. [Return Path](../presentations/longform/09-return-path.md) — bridge to the finale
10. [The APT Counterfactual](../presentations/longform/10-apt-counterfactual.md) — the reverse-flow defenses and the honest guarantee

Also in `docs/security/`: [in-the-wild-2026-06-03.md](../security/in-the-wild-2026-06-03.md), [noc.md](../noc.md), [honeypot.md](../honeypot.md), [multi-agent-playbook.md](../multi-agent-playbook.md).

<!-- Speaker notes: These are the docs a prospect gets if they want to walk the receipts themselves. Each stands alone. Prospects who read them all know the system as well as we do. -->

---

# Thank you.

**Chris Ashenbrenner · SimplifyMy.Cloud**

The Yamato Wiki is live at **`yamato-dev.iq9.io`**. The repo is real. The multi-agent playbook is at [`docs/multi-agent-playbook.md`](../multi-agent-playbook.md). The receipts are in [`docs/security/`](../security/).

**We build like this for a living.**

*Shall we play a game?* — this time, we already have.

[HERO IMAGE: closing art — Yamato ship silhouetted against a nebula, with the Fort Knox layers superimposed as a translucent shield. Optional: 1983-CRT overlay reading *"THE ONLY WINNING MOVE IS TO ARCHITECT PROPERLY."*]

<!-- Speaker notes: Land the pitch. The wiki is a proof-of-work artifact — a prospect can visit it right now, watch the NOC, see the honeypots catching bots, read the /docs shelf. This is not a slide deck about what we could build. It is a slide deck built on top of what we did. The final WarGames callback lands as the invitation — the prospect's turn to engage. -->

---
