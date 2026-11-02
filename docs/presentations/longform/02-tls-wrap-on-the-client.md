# Chapter 2 — TLS Wrap on the Client

*The packet is opaque the moment it leaves the laptop. Everything else is downstream of that fact.*

## The first thing that happens

David types the `gcloud` command and hits enter. The `--tunnel-through-iap` flag activates. Before any traffic reaches a Google server, before IAP evaluates anything, before the target VM even knows David exists, David's laptop does one thing: it takes the entire SSH session and **wraps it in TLS.** The bytes are encrypted, addressed to a Google endpoint on **port 443**, and pushed out onto the NORAD wifi.

That is the first mechanism of the six-layer defense, and it happens entirely on the client side. Google isn't involved yet. The network isn't involved yet. **The security here is a property of what David's laptop does before letting a single packet touch the wire.**

## What TLS is, briefly

TLS — Transport Layer Security — is the modern successor to SSL (Secure Sockets Layer). Its history is one of the older stories on the internet: SSL 1.0 in 1994 (never publicly released, too broken); SSL 2.0 later that year; SSL 3.0 in 1996; TLS 1.0 (rebranded) in 1999; TLS 1.1 in 2006; TLS 1.2 in 2008; and TLS 1.3 in 2018. Each version tightened the cryptography, closed newly-discovered attacks, and removed obsolete cipher suites. TLS 1.3 is the current default and the version relevant to everything that follows.

The protocol does three things simultaneously:

1. **Authentication.** The client verifies the server's identity via an X.509 certificate signed by a trusted Certificate Authority. In our case, David's laptop verifies that it is actually talking to Google's edge, not a network attacker pretending to be Google.
2. **Key agreement.** The client and server establish a shared secret using ephemeral Diffie–Hellman key exchange — meaning the keys used to encrypt this specific session exist only during this session and are destroyed afterward.
3. **Encryption.** Once the session key is established, all subsequent data is encrypted with an authenticated cipher (AES-GCM or ChaCha20-Poly1305 in TLS 1.3). Every byte in both directions is encrypted with keys the observer will never possess.

## What the observer at NORAD actually sees

Here is the concrete list of everything a network adversary — with root on the NORAD wifi, or a tap on the ISP's fiber, or a lawful-intercept order compelling the provider to hand over traffic — can see when David runs his gcloud command:

- **A destination IP address** — belonging to Google's edge (anycast, so the exact point of presence varies).
- **A destination port** — 443.
- **A TLS handshake** — the initial protocol negotiation. In TLS 1.3, this handshake is itself mostly encrypted after the first message; with ECH (Encrypted Client Hello) enabled, even the destination hostname (SNI) is hidden.
- **A stream of encrypted application-data bytes** — variable length, random-looking.

That is the entire capture. What the observer sees is indistinguishable from any other HTTPS connection to a Google service. It could be Gmail. It could be a search query. It could be a YouTube video buffering. It could be Google Drive syncing. Or it could be David SSHing to a private VM on the other side of the continent. **There is no signal, in the plaintext of the wire, that discriminates between these cases.**

## What the observer does NOT see

- The fact that this is SSH traffic
- The hostname of the target VM
- David's SSH credentials, keys, or command output
- The IAP tunneling handshake happening *inside* the TLS envelope
- Any subsequent shell commands or their responses

The observer does not see these things not because they weren't trying, but because **the packet was already opaque the moment it left David's laptop.** The security here is a property of the TLS wrapping itself, not of any downstream defense.

## The uncertainty tax — why attackers don't even try

The security here goes deeper than "the contents are hidden." **The contents are so uniformly hidden that even attempting to attack becomes economically irrational.**

Attackers have finite time, finite compute, finite attention. They allocate these resources against targets with knowable expected value. A conventional attack against a specific target — say, a company's login portal — has a calculable payoff: crack it, and you get customer data worth $X on the dark market. The attacker weighs $X against the cost of the attack (hours of specialized labor, expensive compute, risk of detection) and decides whether it's worth trying.

TLS wrapping breaks that calculation. David's SSH-over-TLS connection to Google's edge is one of a billion identical-looking HTTPS sessions being carried by the same infrastructure. From the outside, none of them advertise value. A patient adversary who allocated a week of expensive compute to breaking one such session would need to be certain, *in advance*, that it was the interesting session — the SSH tunnel, and not Gmail, and not a search query, and not a YouTube video buffering.

There is no way to make that determination from the plaintext of the wire. Which means the expected value of breaking any *specific* random-looking HTTPS session collapses toward zero. **The uncertainty itself becomes a form of security.** Not because attacking is impossible — because it's not worth attacking.

## Why port 443 specifically

The choice of port 443 is deliberate and does more work than it looks.

Port 443 is the standard port for HTTPS. In 2026, HTTPS accounts for the overwhelming majority of internet traffic — approaching 95% by some measurements. Every web browser, every mobile app, every API client, every software update mechanism, every ad tracker, every video call — all of it flows over port 443. A network firewall that blocks port 443 blocks the internet.

Which means: **port 443 is the one port any restrictive network almost has to allow.** Corporate firewalls that block everything else allow 443. Airport captive portals allow 443. Hotel wifi allows 443. Hostile countries that block VPNs and SSH still allow 443, because blocking it would mean blocking the web itself.

IAP's design choice to tunnel SSH over HTTPS on port 443 turns a limitation of the SSH protocol (blockable on unusual ports, distinguishable in the clear) into a non-issue. **Wherever web browsing works, IAP tunneling works.** Which is essentially everywhere.

### The technique has a long track record

This design pattern — wrap the payload in TLS, ship it out on port 443, hide it inside the boring majority of internet traffic — is not novel. It has been used in genuinely adversarial environments for years:

- **BitTorrent.** The BitTorrent protocol traditionally used ports 6881–6889 for peer connections. ISPs and university networks routinely throttled or blocked those ports to discourage piracy. Modern BitTorrent clients increasingly tunnel their traffic over port 443 with TLS-shaped encryption, making a BitTorrent swarm's traffic indistinguishable from a browser tab loading a website. If a network allows HTTPS at all, it allows this.

- **Bitcoin.** The Bitcoin P2P protocol defaults to port 8333 for node-to-node communication. In restrictive networks — corporate, university, or state-firewalled — Bitcoin nodes are commonly configured to listen on port 443 with TLS wrapping instead. The traffic then looks like HTTPS to any observer, and passes through firewalls that would otherwise block it.

- **Tor.** The Tor anonymity network has entire *pluggable transports* — obfs4, meek — designed to make Tor traffic look like HTTPS/443 to defeat state-level censorship. Users behind China's Great Firewall rely on these transports to reach the outside internet at all.

The pattern is well-known and battle-tested. When IAP tunnels SSH over HTTPS on port 443, it is not inventing a novel technique. It is applying a **design pattern that already demonstrably works** to move traffic through corporate firewalls, university throttlers, and national censorship apparatus worldwide. If it works for BitTorrent swarms and Bitcoin nodes and Tor users behind the Great Firewall, it works for David's SSH tunnel from NORAD.

## Perfect forward secrecy

TLS 1.3 mandates **perfect forward secrecy** (PFS), and it matters here.

Without PFS, the same long-lived private key on the server would be used to encrypt many sessions. An adversary who patiently recorded encrypted traffic for years and then, later, stole that server's private key could retroactively decrypt every session they had captured. This is the "harvest now, decrypt later" attack pattern that state actors have been running against internet traffic for decades.

With PFS, each session uses ephemeral keys derived at handshake time. The long-lived server key is used only to *authenticate* — to prove the server is who it says it is — not to encrypt the session data. When the session ends, the ephemeral keys are destroyed. There is no retroactive decryption path.

Concretely for David: an adversary who records his encrypted SSH-over-TLS traffic tonight, and who somehow compromises Google's edge key material next year, still cannot decrypt what they recorded. **The keys never existed anywhere after the session ended.**

## The historical context — Snowden and "encrypt everything"

Modern TLS's ubiquity is not accidental. In 2013, **Edward Snowden's disclosures** showed that the US National Security Agency (and, by extension, adversarial intelligence services worldwide) had been collecting unencrypted internet traffic at massive scale — tapping fiber, subpoenaing providers, exfiltrating from data-center interconnects. Most web traffic at the time was not encrypted. That meant most email, most searches, most everyday web browsing was being harvested in bulk by state actors.

The industry response was swift. In 2016, **Let's Encrypt** launched, making TLS certificates free and automatically-renewable — removing the last practical excuse for any website to be HTTP-only. Browsers began aggressively marking HTTP pages as "Not Secure." By 2020, HTTPS was the default for essentially all web traffic. The mass-collection dragnet's payload — which had assumed HTTP was normal — collapsed to encrypted noise the intercept infrastructure couldn't decode.

David's IAP tunnel rides on that infrastructure inheritance. When we say his packets are "just HTTPS on port 443," we mean: **they blend into the encrypted majority of internet traffic that the post-2016 world made the default.** The observer at NORAD is not looking at a suspicious outlier; they are looking at one more HTTPS session in a sea of billions.

## The Fort Knox parallel

Fort Knox's gold does not walk out of the vault. It leaves in **an armored truck driving on public roads.**

Anyone standing beside the road can see the truck. The road is a road; it is public. The truck's route is public. The truck itself is a heavy metal box — nothing exotic. There is no attempt to hide the fact that a truck is on the road.

**What can't be seen is what's inside.** The truck's walls are opaque. The seal on the doors is tamper-evident. The observer with binoculars, or with a drone, or with a checkpoint downstream, can see the truck perfectly clearly — and can tell you nothing about the cargo. Rip the seal, alert the guards.

### And here is the deeper trick

**From the outside, all armored trucks look identical.** This one might carry gold from the depository. The next one carries cash for a bank branch. The one after that is empty, deadheading back to the depot after a delivery. A hijacker committing to steal from a random armored truck doesn't know, in advance, whether they'll get a fortune or an empty box.

The economics of the attack collapse. Hijacking an armored truck is expensive — coordinated, risky, potentially fatal. If the expected value of a random hit is uncertain, and might well be zero, most attackers walk away. Not because the trucks are unbreakable. **Because the payoff isn't knowable in advance, so the expected return doesn't justify the cost.**

The packet is the armored truck. TLS is the seal. Every truck on the road looks the same. Every packet on the wire looks the same. Attacking is expensive; the payoff is unknown; most attackers walk away without trying.

---

*Next up: [Chapter 3 — GFE + DDoS Scrubbing](./03-gfe-ddos-scrubbing.md)*
