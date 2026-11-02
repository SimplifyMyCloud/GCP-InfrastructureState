# Chapter 9 — Return Path

*The bridge to the finale. On the way out is where the trap closes on anyone who was not supposed to be in.*

## The mirror image

The return path is the six hops reversed. The VM produces output; it flows back through OS Login (already authenticated for this session), through the VPC firewall (stateful — return traffic is automatically permitted), through the IAP tunnel (still open, still authorized), through Google's private backbone (still ALTS-encrypted), out the GFE (re-wrapped in the same TLS session), and back to David's laptop.

For David, the authorized user, this is unremarkable. He types, he sees output, the round-trip feels normal. The layers that let him in also let him out, and every checkpoint recognizes him on the way. **The architecture, having done all its work, disappears from his awareness.**

That is the payoff for the legitimate user. It is not the interesting part of the story.

## The interesting part

The interesting part is what happens when the person walking out through the same six hops is *not* the legitimate user.

Every layer on the reverse path becomes something different for an unauthorized exit attempt. Not a pass-through — a **slowdown.** Every exit attempt is logged. Every anomaly is scored in real time. Alarms fire while the intruder is still trying to leave. Egress paths are narrowed, throttled, or blocked entirely.

**And here is the physics of the situation: the gold, being heavy, moves slower than the alarm.** The attacker's ability to exfiltrate anything of value is bounded by their ability to move data outward through channels that are being watched, throttled, and closed in real time as they try. The alarm reaches the guards faster than the intruder can reach the exit.

## The Fort Knox parallel — a preview

The authorized courier walks out the same six gates he came in through, recognized at each. That is what David just did. No alarm. No pursuit. No drama.

The intruder walking out through the same six gates has an entirely different experience: alarms firing at every checkpoint, guards converging from every direction, razor wire on every fence, and gold bars — being heavy — moving slower than any of it. **Same infrastructure, same physical checkpoints, radically different experience.**

The distinction is whether an alarm has fired somewhere behind you. For David, no alarm. For the intruder, every layer is an alarm point.

Chapter 10 is that story in full.

---

*Next up: [Chapter 10 — The APT Counterfactual](./10-apt-counterfactual.md)*
