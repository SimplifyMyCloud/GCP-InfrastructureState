# Chapter 4 — Google's Private Backbone

*After GFE, the packet leaves the internet entirely. From here to the vault, it's Google's fiber all the way — and even that fiber is treated as adversarial.*

## The moment

David's packet has arrived at a GFE — probably somewhere in the mountain west, based on where NORAD sits geographically. The GFE has terminated the TLS envelope, applied DDoS scrubbing, and cleared the packet as legitimate. What happens next is one of the more understated architectural facts of the modern internet: **the packet leaves the public internet.**

It does not go back onto the public internet again until the response returns to David seconds later. Everything between the GFE PoP and the destination VM in us-east1 — every switch, every router, every mile of fiber — is Google's own.

## What Google's backbone physically is

Google operates one of the largest private networks in existence. It includes:

- **Over a million miles of fiber** — a mix of Google-owned and Google-leased routes across every populated continent
- **15+ subsea cables** in which Google has significant ownership or investment — **Curie** (Los Angeles ↔ Chile), **Dunant** (US ↔ France), **Grace Hopper** (US ↔ UK ↔ Spain), **Firmina** (US ↔ Argentina), **Blue-Raman** (Israel ↔ India), **Nuvem** (US ↔ Portugal ↔ Bermuda), and more
- **A private high-speed backbone** connecting Google's data centers, edge PoPs, and internet peering points

The scale is worth pausing on. Google's private network moves more traffic than most national ISPs. It was engineered for internal Google services — Search, Gmail, YouTube — but every Cloud customer's traffic inherits it. When David's packet leaves the Denver GFE bound for us-east1, it rides Google's own fiber across the continental US, likely never touching a public ISP router along the way.

## B4 — Google's SDN backbone

The technical story of how this network is run is itself a landmark. In 2013, Google published a SIGCOMM paper describing **B4** — Google's software-defined WAN. B4 was one of the first at-scale production SDN deployments in existence. Instead of traditional distributed routing protocols making per-router decisions, B4 uses centralized traffic engineering to make globally-optimal decisions about which fiber path each flow should take.

The upshot: **Google's private backbone is not a collection of independently-routed pipes.** It is a globally-orchestrated system. Traffic engineering, capacity planning, congestion avoidance, and failure recovery are all done at the fleet level, not at individual routers.

For David's packet, this means the path from Denver to us-east1 was chosen for latency, capacity, and reliability by a system with full visibility across the entire backbone. Not "whichever routes BGP happened to converge on today."

## ALTS — internal encryption

Physical ownership of the fiber, however, is not enough on its own. Fiber can be tapped. Splicing hardware into a fiber run — even a Google-owned fiber run — is expensive but not impossible for a sufficiently motivated adversary with physical access. And once the packet leaves the fiber and enters a Google switch or data-center router, it is briefly in the clear on internal cables that any operator with the right badge could theoretically reach.

To defend against this, Google encrypts **every internal RPC** with a protocol called **ALTS** — Application Layer Transport Security. Every service-to-service call across the Google backbone is:

- **Authenticated** — each service proves its identity to the other via mutual certificate exchange
- **Encrypted** — the RPC payload is encrypted with a session key derived at handshake time
- **Integrity-checked** — any tampering with the encrypted bytes is detected and the call rejected

ALTS is applied at the layer just below the application, transparent to service code. Every RPC frame in Google's internal fabric is authenticated and encrypted, even when it's traveling on Google-owned fiber, inside Google-owned data centers.

**Why this level of paranoia?** The next section explains.

## MUSCULAR — the wake-up call

In October 2013, *Washington Post* reporters — working from documents Edward Snowden had disclosed earlier that year — revealed the existence of an NSA operation code-named **MUSCULAR**. MUSCULAR was a joint US–UK signals-intelligence program that had tapped unencrypted fiber links between the private data centers of Google and Yahoo, exfiltrating hundreds of millions of internal records per day.

The operational method was straightforward: NSA and GCHQ physically accessed fiber runs outside the direct control of the tech companies — likely at overseas landing stations or peering points — and mirrored the traffic. Because Google's data-center-to-data-center traffic at the time was **not encrypted end-to-end** (the assumption being that Google owned the fiber, so it was "safe"), the collectors could read it in the clear.

Google's public reaction was severe. A now-famous internal comment from a Google security engineer, leaked shortly after — "**Fuck these guys**," referring to the NSA — captured the mood inside the company. Google began an urgent multi-year project to **encrypt every single internal link**, everywhere, immediately. That project produced ALTS in its current form. It also produced Google's fierce insistence, going forward, that **owning the fiber is not the same as trusting the fiber.** The network — even Google's private network — is adversarial by default, and every packet is encrypted whether the wire is "trusted" or not.

**MUSCULAR is to Google's network what Aurora was to Google's corporate identity model.** Both incidents produced a permanent architectural shift: never trust the perimeter, never trust the network, encrypt everything, authenticate everything.

## PSP — hardware-offloaded next generation

ALTS has been the workhorse for a decade. It is being progressively replaced by a newer protocol called **PSP** (PSP Security Protocol), which Google published open-source in 2022.

The key difference: PSP is designed to be **hardware-offloaded**. Modern network interface cards (NICs) can implement PSP directly, encrypting and decrypting at line rate without consuming CPU cycles. This matters because as Google's internal traffic volumes climb into the tens of terabits per second, software-based encryption becomes a real bottleneck. PSP shifts the work off CPUs and into silicon.

The security properties of PSP are similar to ALTS — mutual authentication, per-flow encryption, replay protection — but the throughput is dramatically higher, and the CPU savings free those cycles for actual service work. Every RPC still gets encrypted; the cost of encrypting drops to essentially zero.

## BeyondProd — the mental model

Google's internal security philosophy for services is called **BeyondProd** — the production-service equivalent of BeyondCorp for user identity. The core BeyondProd principles:

- **No implicit trust from network location.** A service does not trust another service just because the caller came from an internal IP address.
- **Every RPC is authenticated with an identity.** ALTS mutual authentication is mandatory, not optional.
- **Every RPC is encrypted.** Even if the wire is "trusted." Even if the destination is another Google service in the same data center.
- **Least privilege for services.** A service can only call other services it has been explicitly authorized to call.

The same intellectual framework as BeyondCorp — never trust the network — applied at the service-to-service layer instead of the user-to-service layer.

For David's packet, this means the traffic riding Google's backbone from Denver to us-east1 is not just "on Google's private fiber." It's on Google's private fiber, **encrypted at the RPC layer with ALTS (or PSP)**, and every service handoff along the way is mutually authenticated. There is no point along the internal path where the packet is naked.

## The hierarchy — public, private, hyper-private

The packet's journey now has three distinct trust environments:

1. **Public internet** (David's laptop → GFE): the packet is opaque to observers by virtue of TLS wrapping, but it is on public infrastructure Google does not control.
2. **Google's private backbone** (GFE → destination region): the packet is on Google's own fiber, orchestrated by B4, encrypted at the RPC layer with ALTS/PSP.
3. **Destination data center** (regional backbone → the specific VM): the packet enters a specific data center, where it will be handed to IAP and eventually the VM. Still ALTS/PSP-encrypted at every service handoff.

**Each of these environments treats the layers outside it as adversarial.** The public internet is adversarial to Google's edge — hence TLS termination at GFE. Google's own backbone is adversarial to service-to-service RPCs — hence ALTS. And within the destination data center, individual services are adversarial to each other in the sense of default-deny access control — hence the IAP identity checks and per-service IAM we will cover in Chapters 5 through 8.

Adversarial by default, at every scale.

## The Fort Knox parallel

Past the outer gate of Fort Knox is not "the trusted interior of the base." It is **the vast, monitored, patrolled interior of a US Army armor installation.** Every road inside is a base-owned road. There are no public roads that reach into the interior. There are no free-roaming visitors — every vehicle inside the base is either authorized personnel or an authorized visitor with an escort, and both are **subject to being stopped at random by armed patrols who will demand credentials on the spot.**

**You do not have free run of the interior just because you passed the outer gate.** Roving patrols continuously verify that every person and every vehicle on base has legitimate business. Cameras cover every intersection. Movement is monitored. Suspicious behavior is challenged immediately.

This is the exact analog of what ALTS enforces. Passing GFE gets the packet onto Google's private backbone — but it does not give the packet free run of Google's interior. Every RPC still authenticates. Every service still verifies. The interior is monitored more heavily than the perimeter, not less.

**The interior of a well-designed base is more monitored than the perimeter, not less.** Because the perimeter's job is to be the first filter; the interior's job is to catch anything the perimeter missed.

---

*Next up: [Chapter 5 — IAP Identity Check](./05-iap-identity-check.md)*
