# Chapter 3 — GFE + DDoS Scrubbing

*The outermost active defense. Where volumetric attacks die, and the public internet ends.*

## The arrival

After David's TLS-wrapped packet leaves his laptop and flies out onto the NORAD wifi, its first landing on Google's infrastructure is at a **Google Front End** — a GFE. This is a globally-distributed reverse-proxy layer that sits in front of every internet-facing Google service. Not "most" services. Every one. Search, Gmail, YouTube, Maps, Workspace, and every single Google Cloud service — Cloud Run, Compute Engine, BigQuery, IAP itself — all of them sit behind a GFE. **Nothing on Google's cloud is directly exposed to the public internet.** Everything is behind this layer.

The GFE is the outermost active defense of the Google network. For David's packet, it does three things at once: it terminates TLS, it applies DDoS scrubbing, and it hands the request onto Google's private backbone. These three operations determine whether the packet even survives long enough for IAP to see it.

## Anycast — how the packet finds a GFE

Google runs more than **150 GFE points of presence** worldwide — physical facilities in cities across every populated continent. All of them announce the same IP address for a given service. This is the technique called **anycast**: many locations, one IP address, BGP routing steering each packet to whichever location is topologically closest.

From David at NORAD, that "closest" is probably a GFE in Denver, Salt Lake City, or somewhere else in the mountain west — but he never configured it, and he doesn't need to know. The routing is automatic. Every packet finds the nearest PoP without any user or application involvement. This is why Google's services feel snappy from anywhere on earth: the round-trip time to the edge is a few tens of milliseconds even from remote locations.

The consequence for security is subtle but important: **there is no single "Google" to attack.** An adversary trying to focus a DDoS attempt on a particular Google endpoint discovers that "the endpoint" is actually 150+ different geographic locations. Coordinating a distributed attack against a distributed, anycast-routed target that steers traffic away from congested paths is hard by construction.

## What GFE does when the packet arrives

Three operations, essentially simultaneous.

**1. TLS termination.** The GFE decrypts the incoming TLS envelope using Google's private keys. This is where the encrypted bytes David's laptop generated become plaintext HTTP requests again — but now inside Google's own hardware, on Google's own network. From here inward, TLS is replaced with Google's internal encryption (ALTS, which we'll cover in Chapter 4). The private keys never leave hardware.

**2. DDoS scrubbing.** Simultaneously, the GFE evaluates the incoming traffic for signs of denial-of-service abuse. Volumetric floods, protocol-abuse floods, HTTP request floods, slow-connection attacks, amplification attacks — the whole zoo. Anything that looks like attack traffic is dropped at the edge before consuming any backend resources. Legitimate traffic passes through with negligible added latency.

**3. Routing onto the private backbone.** Once the packet is decrypted and cleared as legitimate, GFE hands it off to Google's internal RPC infrastructure, which carries it over Google's own fiber to the eventual backend. **This is the last hop on the public internet.** From here inward, David's packet is on Google's own network.

## DDoS scrubbing at scale — the records worth knowing

The scale of what GFE handles is worth stating concretely, because the numbers do the argument by themselves.

- **In 2020**, Google mitigated a **2.5 Tbps DDoS attack** targeting a Google service. This was the largest recorded DDoS attack up to that point in internet history. The attack was absorbed and dropped at the edge; the targeted service saw no user-visible impact. Google disclosed the incident publicly, in part to demonstrate that infrastructure-scale defense was possible against nation-state-scale attackers.

- **In 2023**, attackers exploited a novel HTTP/2 protocol feature (later designated **CVE-2023-44487**, the "HTTP/2 Rapid Reset" attack) to generate massive request floods with minimal attacker bandwidth. Google mitigated a peak of **398 million HTTP requests per second** — an order of magnitude larger than the previous record. Every one of those requests was absorbed at the GFE layer and dropped before touching a backend.

For context on how big these numbers are: a "large" DDoS attack against a typical enterprise target is measured in tens of gigabits per second. The Mirai botnet, at its 2016 peak, generated around 1 Tbps. **What Google is routinely absorbing at the edge is several times larger than the peak volume of the most notorious DDoS tool in the history of the internet** — and Google absorbs it without customer-visible impact.

## Why the defender's math always wins

Here is the structural reason DDoS scrubbing at Google-network scale works, and why it's not something a typical enterprise can replicate on their own.

An attacker mounting a volumetric DDoS attack has some finite amount of attack bandwidth — from a botnet, from booter-service resellers, from misconfigured amplifiers. The attacker's ceiling is bounded by the resources they can muster or rent. Even for a well-funded state actor, aggregating enough compromised endpoints and amplification vectors to hit multi-terabit-per-second aggregate throughput is expensive, slow, and detectable.

The defender — in this case, GFE — has as much bandwidth as Google's global network. Google's network capacity is measured in **tens of terabits per second globally**, provisioned for Google's own services (Search, YouTube, Gmail) which routinely serve billions of users. When an attacker sends 2.5 Tbps at Google, GFE evaluates each packet, drops the attack traffic, and Google's remaining capacity handles legitimate traffic without noticing.

**The math is asymmetric by orders of magnitude, permanently.** An attacker cannot bring more traffic to Google's edge than Google's edge is provisioned to handle — because Google's edge is provisioned for YouTube-at-Super-Bowl-Sunday levels of legitimate load, and an attack exceeding that level would exceed the entire capacity of the internet backbone infrastructure it would have to traverse to get there.

For David: even if the exact moment his packet arrived at GFE coincided with a nation-state DDoS attempt against Google, **his packet still passes through.** The attack traffic dies; the legitimate traffic doesn't notice.

## GFE existed before Cloud — Cloud inherited it

The pedagogical thing worth naming: **GFE was built for Google's own services**, years before Google Cloud existed as a public product. When Cloud launched in 2008 (initially with App Engine), it was built on top of the same infrastructure Google was already using for Search and Gmail. That included GFE.

This means every Cloud customer, from day one, has been getting Google-scale DDoS protection at the edge — for free, invisibly, with no configuration. It's not a separate product you enable or pay for. It's the way the network is built.

Compare this to the equivalent story on other public clouds. On AWS, edge DDoS protection at anything close to this scale requires **AWS Shield Advanced**, which starts at $3,000 per month plus additional data-processing charges. Cloudflare Enterprise, Akamai Prolexic, and other DDoS-scrubbing services offer similar protection as add-on products elsewhere. On GCP, **the equivalent capability is the default posture** — it's what your Cloud Run service already has, whether you configured it or not.

## The public/private boundary

There is one more property of GFE that matters for the packet trace: **it is the demarcation between public internet and Google's private network.**

Before GFE: David's packet is on the public internet. It rode NORAD wifi to an ISP to whatever backbone provider routes to Google's edge. Every hop along that path is public infrastructure that Google does not control.

After GFE: David's packet is on Google's private network. Google-owned fiber. Google-managed switches. Google-designed hardware. Every hop is Google. **No public adversary can observe traffic beyond this point.**

Everything else in this book — the private backbone, IAP, VPC firewall, OS Login, the VM itself — all of it happens inside the Google-private space that starts on the other side of GFE. GFE is the boundary crossing.

## The Fort Knox parallel

The outermost active defense of Fort Knox is not the vault. Not the depository. Not even the interior guards. It's the **outer gate of the Army base itself** — a checkpoint staffed by an armed soldier, backed by the full weight of the base behind them.

This is where the volumetric attackers die.

A single suspicious car? Handled. A convoy of a dozen? Handled. A mob of a thousand cars, coordinated, all trying to ram the gate at once? **Also handled** — because the gate is designed for exactly that scale, and the base behind it has more soldiers, more vehicles, and more institutional resources than any coordinated crowd can bring. **The gate's job is not to be individually unbreakable; it is to guarantee that no attacker with mere numerical advantage gets past.**

### But here is the deeper point — the base is a tank installation

Fort Knox is not just any Army post. It is the historic home of the **US Army Armor School** and for decades the primary training and stationing site for American armored cavalry units — including the 1st Armored Division. **The gold depository was placed inside Fort Knox specifically because the surrounding installation is a military armor post** with tanks, artillery, and a full complement of the equipment and personnel needed to defeat any conventional ground threat.

This adds a category of protection the outer gate itself does not provide: **asymmetric military power.** A mob of a thousand civilians attempting to overwhelm the gate is one problem. That same mob attempting to fight past the gate against a tank division is a fundamentally different problem. **One M1 Abrams can defeat a thousand unarmored cars — not by being stronger, but by being entirely different equipment.** The technology gap is so wide that adding more cars doesn't help. The physics of the situation is against them.

Same principle at GFE. It is not just a filter appliance sitting in a rack. It is backed by:

- **Google's full global network capacity** — tens of terabits per second, engineered for legitimate load
- **Custom-designed silicon** at the edge — Titan security chips, hardware-accelerated crypto
- **Real-time adaptive mitigation systems** that observe and react across the entire fleet in seconds
- **A team of engineers** whose day job is defeating novel attack patterns as they emerge

An attacker mounting a volumetric DDoS is not going up against a rate limiter. **They are going up against the technology that makes YouTube work at Super Bowl Sunday scale.** The gap is not "we have more"; the gap is *"we have entirely different equipment."* Adding more attack traffic doesn't help — the math is wrong at the level of the physics.

Everything downstream — the depository, the vault, the cages — is designed under the assumption that the outer gate is holding. If the outer gate ever failed, the downstream layers would become the story. But the outer gate has been holding for a long, long time, and it holds because the base's resources dwarf any conceivable attacker's coordination.

GFE is the outer gate. Volumetric attackers die at GFE. What passes into the interior is only what the gate has already cleared.

---

*Next up: [Chapter 4 — Google's Private Backbone](./04-google-private-backbone.md)*
