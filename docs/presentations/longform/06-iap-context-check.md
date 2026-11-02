# Chapter 6 — IAP Context Check (Context-Aware Access)

*Identity is not enough. Stolen credentials are worthless if the circumstances don't match. This is where IAP becomes genuinely zero-trust.*

## Where we are

Chapter 5 covered the first half of what IAP does: **identity.** IAP verifies who the requester is, cryptographically (via a Google-Auth-signed OAuth JWT), and checks whether that identity has the right IAM role for the resource. Both checks happen fresh per request. Neither trusts the network.

But identity alone is not the full BeyondCorp story. The original BeyondCorp papers described three factors: **identity, device, and context.** IAP handles identity via the checks in Chapter 5. It handles device and context via a feature called **Context-Aware Access**, sometimes still called IAM Conditions or Access Levels depending on the surface. This is Chapter 6.

## Identity alone is not enough — the argument

Here is the scenario that Context-Aware Access exists to defeat, and it is the single most common breach pattern in modern enterprise security: **credential theft.**

The pattern:

1. Attacker phishes David — a convincing email, a look-alike login page, David enters his Google password.
2. Or: attacker deploys malware on David's laptop that exfiltrates his OAuth refresh token from the ADC store.
3. Or: attacker buys David's credentials on a breach forum after some third-party service he uses is compromised.
4. Or: attacker is an insider who observed David's credentials.

The attacker now has a valid identity artifact — a password, an OAuth token, whatever the primary authentication factor was. With identity-only enforcement, that is game over. The attacker walks in as David, and the system has no way to know the difference.

Second factor authentication (2FA, MFA) helps here — but not as much as advertised. Sophisticated attackers phish the second factor along with the first ("adversary-in-the-middle" phishing). SIM swapping defeats SMS 2FA. Malware on the endpoint captures TOTP codes as they are entered.

**The real defense against credential theft is to require something the attacker cannot easily copy: the physical device David uses, and the network context David is in.** That is what Context-Aware Access enforces.

## What Context-Aware Access is

Context-Aware Access is Google's productized version of the BeyondCorp device-and-context enforcement layer. It extends Cloud IAM with **conditional access** — the ability to say not just "does this identity have this role," but "does this identity have this role *under these specific circumstances*."

Concretely, an admin defines one or more **Access Levels** in a service called Access Context Manager. Each Access Level is a Boolean expression over context signals. Then the admin binds an Access Level as a **condition** on an IAM role grant. When IAP evaluates whether to allow a request, it now performs three checks in sequence:

1. Is the OAuth token valid? (identity)
2. Does the identity hold the required role on the resource? (authorization)
3. Does the current request context satisfy the Access Level condition on that role binding? (context)

If any of the three fails, the request is denied. The tunnel does not open.

## The signals Context-Aware Access can evaluate

The context signals available for Access Level policies cover a wide surface. The most operationally important ones:

- **Source IP address / range.** "Only allow when the request comes from the corporate egress IP range" or "block requests from any IP outside these country codes."
- **Device management state.** Is the device enrolled in the company's endpoint management (Google Endpoint Management, or a third-party MDM via integration)? Is it compliant with policy?
- **Device certificate.** Does the device present a valid X.509 client certificate proving it is corporate-owned? Certificates get provisioned when the device is onboarded, and can be revoked instantly when the device is retired, stolen, or compromised.
- **Device encryption.** Is the device's disk encrypted at rest?
- **Screen lock.** Does the device have auto-lock enabled with a reasonable timeout?
- **OS version.** Is the operating system at or above a minimum patch level?
- **Browser identity.** Is the browser one of the enterprise-approved browsers (relevant for web application access; less so for gcloud CLI)?
- **User attribute conditions.** Does the user belong to a specific group in Cloud Identity or Google Workspace? (Useful for finer-grained role gating.)

Any of these signals can be combined into an Access Level. A common enterprise policy for high-sensitivity access looks something like: *"Allow this role only when the request comes from an IP in our corporate range OR from a device with a valid corporate certificate AND disk encryption enabled AND OS version at or above the minimum patch level AND screen lock enabled with 15-minute timeout."*

## How the device signals get to Google — Endpoint Verification

For device-posture signals to be usable in Context-Aware Access, Google needs to know the state of the device on every request. This is handled by **Endpoint Verification** — a small Google-provided agent that runs on the user's device.

Endpoint Verification is delivered as a Chrome extension for browsers, plus native agents for macOS, Windows, and Linux. It gathers device posture data:

- OS version and patch level
- Disk encryption status
- Screen lock configuration
- Device serial number and hostname
- Presence and validity of device certificates
- Endpoint management enrollment status

The agent reports these signals to Google Cloud on a regular cadence (and on-demand when a request is being evaluated). The signals feed into Context-Aware Access policy evaluation.

For David's SSH tunnel scenario: David's laptop, if it is subject to corporate CAA policies, has Endpoint Verification running. When David runs the gcloud tunnel command, the current device posture is available to the IAP request evaluation. If the laptop's disk encryption was disabled last Tuesday, and the CAA policy requires disk encryption, the tunnel does not open — even though David's OAuth token is perfectly valid.

## The "stolen credentials" scenario, defeated

Return to the pattern that opened this chapter: an attacker has David's OAuth refresh token. What happens when they try to use it?

**Without Context-Aware Access:** the attacker's request hits IAP with David's valid token. Identity check passes. IAM check passes (David's role is still active). Tunnel opens. Attacker SSHes to the VM as David. Game over.

**With Context-Aware Access:** the attacker's request hits IAP with David's valid token. Identity check passes. IAM check passes. Then the context check runs. The attacker's laptop:

- Does not have David's corporate device certificate. → policy fails.
- Is not on the corporate egress IP range. → policy fails.
- Is not running Endpoint Verification. → policy fails.
- Has different OS fingerprint, different serial number, different hostname than David's registered device. → policy fails.

**Any one of these failures ends the request at IAP.** The attacker's valid OAuth token is worthless because they cannot reproduce the physical and network context of David's actual laptop.

To defeat this attacker, they would need to: exfiltrate the credentials AND compromise David's specific laptop AND arrange to route requests through the corporate egress IP AND avoid alerting the endpoint management system that the device state has changed. Each of those is orders of magnitude harder than "phish a password." Most attackers stop trying.

**This is the operational meaning of "zero trust."** Trust is not conferred by a credential alone. Trust is conferred by the combination of *this identity, on this device, in this context, right now.*

## The BeyondCorp trilogy — identity, device, context

The BeyondCorp architecture papers described the security model as three factors that must all check out:

1. **Identity** — who is the user, cryptographically verified per request. (Chapter 5.)
2. **Device** — what device is the user on, is it enrolled, is it compliant, is it trusted. (This chapter.)
3. **Context** — where is the request coming from, when, under what conditions. (This chapter.)

All three must be evaluated on every request. Identity alone lets stolen credentials in. Device alone doesn't identify the user. Context alone can be forged with a VPN. Only the **combination** provides genuine trust — because compromising the combination requires compromising three different, physically-distinct things at once.

IAP with Context-Aware Access enforces all three. Without CAA, IAP is still valuable (identity-per-request beats identity-once-at-login), but it is not the full BeyondCorp model. With CAA, IAP is the productized enforcement point that closes the credential-theft attack path.

## Operational scenarios — what this actually looks like

A few concrete examples of Context-Aware Access defending in practice:

**Laptop stolen at an airport.** The corporate MDM system detects the device has not checked in for 24 hours and marks it non-compliant. The device certificate is revoked. Next IAP request from that laptop, using David's still-valid OAuth token: denied. Instantly. No manual VM session termination required.

**Employee travels to a restricted country.** David goes to a country the company's CAA policy flags as high-risk. His IAP requests originate from an IP that geolocates to that country. The CAA geo-restriction denies. Instantly.

**OS patch fell behind.** David's laptop OS has fallen below the minimum patch level (say, a critical CVE was announced last week and the fix hasn't landed on his machine yet). His IAP requests are denied by the OS-version condition until he updates.

**Compromised device with fresh malware.** David clicks a bad link, malware installs, endpoint management flags the device as compromised, device certificate revoked. Next request denied.

**Off-hours access attempt.** CAA policy limits certain roles to business hours. A 3am request against those roles is denied even from a compliant device.

**Contractor with time-boxed access.** An external contractor is granted a role with a CAA condition of "expires in 14 days." After 14 days, the role effectively vanishes; no admin action required.

Each of these is a category of breach the traditional perimeter model cannot defend against, because the perimeter is not evaluating any of these signals per request. CAA does.

## Contrast with the VPN model

The traditional enterprise security model for remote work was: **VPN in from wherever, get network-level access, trust follows from being "inside" the VPN.** This model fails against every scenario above:

- Stolen VPN credentials? VPN grants access.
- Compromised laptop? VPN doesn't care.
- Travel to a restricted country? VPN doesn't care.
- OS out of date? VPN doesn't care.

BeyondCorp (and its productization in IAP + CAA) replaces the VPN model entirely. **There is no VPN.** There is a per-request enforcement point (IAP) evaluating identity + device + context on every request. The user does not "get in" and then have free run of the interior; every request is a fresh evaluation.

For David at NORAD: he is not on a VPN. He does not need to be on a VPN. His identity, his device posture, and his context are being evaluated on every packet through the tunnel. If any of them go wrong mid-session — device stops checking in, source IP changes to somewhere unexpected, device certificate is revoked — the tunnel dies on the next request. The VM never has to know. The security posture is enforced by the checkpoint, not by any assumption about the network.

## The Fort Knox parallel

The Depository's biometric gate — from Chapter 5 — confirmed the visitor's identity is correct. Fingerprint matches, retinal scan matches, roster says they're currently authorized. They pass the gate.

Now, in the interior hallway heading toward the vault, an **escort officer** is walking with them. And the escort is checking a completely different set of things:

- Where did the visitor enter the building from? (The escort tablet shows the arrival-gate log; if the entry doesn't match the visitor's planned route, the escort flags it.)
- What is the visitor carrying? (Metal detectors, x-ray, visual inspection at intervals along the hallway.)
- Is the visitor's background check current? (The tablet checks in real-time against the personnel database.)
- Are they here during authorized hours? (The tablet cross-references the visitor's approved access window.)
- Is the escort officer's own clearance current for this section of the building? (The escort has to be authorized to walk this specific route.)
- Are there any items on the visitor that shouldn't be there — a phone, a camera, a USB device — that would be red flags in this context?

**The escort is not doing an identity check.** The biometric gate handled that. The escort is doing a *context check.* Same person, different circumstances, different answer.

If any signal is wrong — the visitor is carrying an unauthorized device, or their background check expired yesterday, or they came through the wrong entrance, or the hour is off — the escort walks them right back out. Not because they are not who they say they are. Because **this isn't the right context for them to be here.**

This is the exact operational property of Context-Aware Access. Identity gets you past IAP's first door. Context is what keeps you moving forward through the second. Right person, wrong device — denied. Right person, right device, wrong network — denied. Right person, everything right, but the OS patch level fell behind yesterday — denied until fixed.

The escort verifies the right person is in the right situation. Not just the right person.

---

*Next up: [Chapter 7 — VPC Firewall](./07-vpc-firewall.md)*
