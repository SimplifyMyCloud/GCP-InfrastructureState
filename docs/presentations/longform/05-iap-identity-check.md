# Chapter 5 — IAP Identity Check

*The zero-trust moment of the packet trace. Where BeyondCorp is made real for the user identity, per request, every request.*

## Where we are

David's packet has been TLS-wrapped by his laptop, landed at a GFE, cleared DDoS scrubbing, and is now riding Google's ALTS-encrypted private backbone toward the destination region in us-east1. Everything so far has been about **making the packet reachable-but-opaque and physically unreachable-by-outsiders.** None of it has asked the fundamental question:

> **Should this packet even be delivered?**

That question — the identity-and-authorization question — is where Identity-Aware Proxy enters the story. This is the moment BeyondCorp becomes concrete for the user identity layer, exactly as the previous chapter described BeyondProd becoming concrete for the service-to-service layer.

## What IAP is

Identity-Aware Proxy is Google's productized answer to the Aurora incident. Where Aurora demonstrated that "if you're inside the network, you're trusted" is a catastrophic security model, BeyondCorp described the philosophical alternative, and IAP implemented that alternative as a shipping service anyone can consume.

IAP is architecturally a **reverse proxy sitting in front of a resource** — an app, a Compute Engine VM, a Cloud Run service, a GKE cluster — that intercepts every incoming request and evaluates whether it should be allowed to reach the resource. It integrates with Google's identity system (or a federated identity provider, more on which below) and with Google's central IAM system to make that evaluation.

For David's SSH tunnel to a private VM, IAP is the gatekeeper between his packet and the VPC. Every packet passes through IAP first. Every packet is evaluated.

## The two questions IAP asks

On every incoming request, IAP asks two questions in sequence:

1. **Who is this identity?** — an authentication question.
2. **Is that identity authorized for this specific resource right now?** — an authorization question.

Both must pass for the request to reach the resource. Either failure ends the request at IAP; no packet reaches the workload, no operator log entry appears on the VM, no invocation is billed to the Cloud Run service. From the workload's perspective, the request never happened.

## The identity check — OAuth, JWT, cryptographic verification

IAP authenticates the request identity via **OAuth 2.0 with OpenID Connect** (OIDC) — the industry-standard identity protocols, not a Google-proprietary alternative.

The concrete mechanics for David's SSH tunnel:

1. **Earlier, David authenticated to gcloud** by running `gcloud auth login`. That opened a browser, prompted him to sign in to his Google account, and (upon success) stored an **OAuth refresh token** in his laptop's Application Default Credentials store.
2. **When David runs the tunnel command** (`gcloud compute ssh vm-name --tunnel-through-iap`), gcloud uses the refresh token to obtain a short-lived **OAuth access token** — a **JSON Web Token (JWT)** signed by Google. The token contains claims: the identity (David's email address), the token's expiration time, the audience it's valid for, and other metadata.
3. **When gcloud opens the tunnel to IAP**, it presents this JWT in the request's authorization header.
4. **IAP verifies the JWT signature cryptographically** against Google's public keys, which are published at a well-known URL and rotated periodically. If the signature is invalid, the token is expired, or the token is not intended for IAP (wrong audience), the request is rejected at this step.

If the signature verifies and the token is fresh, IAP knows definitively **who** is making the request. That knowledge is anchored in cryptography — not "the traffic came from an IP we recognize" or "there's a session cookie we remember." Cryptographic proof of identity, per request.

## The authorization check — IAM

Identity alone is not sufficient. Knowing that David is David does not tell IAP whether David is allowed to reach this specific VM. That is the second question.

IAP performs the authorization check by asking Google's central **IAM system**: *"Does the identity `user:david.lightman@example.com` hold the role `roles/iap.tunnelResourceAccessor` on the resource `projects/<project>/zones/<zone>/instances/vm-name`?"*

IAM is Google's centralized authorization system, the same one used for every Cloud service. Roles are grants; grants are made explicitly (either directly on the resource or inherited from higher up the resource hierarchy). If the grant exists, IAM returns *yes* and IAP proceeds to open the tunnel. If the grant does not exist — or was revoked yesterday, or was granted for a different VM — IAM returns *no* and IAP returns HTTP 403 Forbidden.

The IAM lookup is heavily cached for performance, but the semantics are: fresh check per request. When a grant is revoked, the revocation propagates to the cache invalidation quickly (measured in seconds), and the next request evaluates against the new state.

## Two separate systems — identity is not authorization

There is an architectural fact about IAP that is easy to miss but worth naming out loud: **the identity check and the authorization check are done by two separate Google systems, and one of them is not even part of Google Cloud.**

**Google Auth** — the identity service that authenticates David's OAuth request, verifies his credentials, and issues the JWT — is not a Google Cloud service. It is the same identity service that authenticates every Gmail user, every YouTube viewer, every Android device owner, and every Google Workspace employee at every company that uses Workspace. It is run by Google's identity engineering organization. It has its own product roadmap, its own release cadence, its own SLA, and its own security model.

**Google Cloud is a customer of Google Auth.** Cloud IAM integrates with Google Auth via the standard OAuth 2.0 and OpenID Connect protocols — the same standards that let any third-party application on the internet accept "Sign in with Google" as an identity method. If you have ever used "Sign in with Google" to log into a random web app, you have used exactly the same authentication interface Google Cloud uses.

Contrast this with the industry norm. In many enterprise SaaS products, identity and authorization are the same system — users are created inside the product, permissions are set inside the product, everything lives in one database. On AWS, identity is handled by IAM users and roles specific to AWS; an AWS account is not the same as an Amazon.com shopping account, and AWS built its own identity system rather than federating to one. Microsoft Azure has its own enterprise identity service (now Entra ID, formerly Azure AD) that is deliberately separated from consumer Microsoft identity.

Google's approach is architecturally cleaner in a specific way: **the identity plane and the authorization plane are decoupled.** Google Auth's job ends the moment it issues a signed token saying "this is `david.lightman@example.com`." Cloud IAM's job begins there — it consumes the signed token and makes an authorization decision about what David can do on this particular GCP resource. Two systems, two responsibilities, one clean interface between them.

This decoupling has real consequences:

- **Independent evolution.** Improvements to Google's identity service (new factor types, tightened token cryptography, additional signals) ship without any change to Cloud IAM. Improvements to Cloud IAM (new resource types, finer-grained role definitions, new binding syntax) ship without any change to Google Auth.
- **Isolated failure domains.** A vulnerability in Cloud IAM does not automatically become a vulnerability in Gmail authentication. A breach of one system does not immediately compromise the other.
- **Federation for free.** Because the interface between them is standard OAuth/OIDC, replacing Google Auth with a third-party identity provider — Okta, Azure AD, Auth0 — is a matter of pointing Cloud IAM at a different token issuer. The authorization system does not care where the token came from, only that the signature is valid and the claims are legitimate. This is the technical basis for Workforce Identity Federation, which we cover below.
- **One identity, everywhere.** The Google account David uses to sign into gcloud is the same account he would use for personal Gmail. This unification across consumer and enterprise is unusual among cloud providers, and it is a deliberate consequence of the separation: because identity lives in a service outside GCP, GCP does not need its own concept of "user accounts."

For David's SSH tunnel: **his identity is validated by Google's identity service — the same service that validates Gmail users — before Cloud IAM ever sees the request.** IAP then hands the validated identity to Cloud IAM, which asks whether that specific identity holds the specific role on the specific VM. Two separate systems, one clean protocol between them, one enforcement point (IAP) sitting in front of both.

## The critical insight — per-request evaluation

Both of these checks — the OAuth token validation and the IAM role lookup — happen **on every request.** Not once at login. Every request.

This is the observable difference between an IAP-protected resource and the traditional SSH model.

**Traditional SSH:** David authenticates once at connection start with a password or a key. If the check passes, an SSH session opens. That session runs until David types `exit` or the connection times out. If David's account is disabled at 3pm, the SSH session that started at 2pm keeps running — the sshd process on the VM has no idea David's credentials are now dead. To terminate the session, an admin has to manually kill the process on the box, or wait for it to time out on its own.

**IAP-tunneled SSH:** Every TCP segment in the tunnel is authorized by IAP. If David's `roles/iap.tunnelResourceAccessor` role is revoked at 3:00pm, the next TCP segment through the tunnel (usually within milliseconds) gets 403 from IAP. The tunnel closes. David's SSH session dies within seconds of the revocation. **No admin has to kill anything. The authorization system IS the session controller.**

This is what BeyondCorp meant by "access granted per request." It is not a metaphor. It is the literal request-by-request behavior of the enforcement point.

## Operational consequences

This per-request model produces categorically different security operations. A few concrete scenarios:

- **Employee leaves the company mid-day.** HR disables their Google account at 2:47pm. Within seconds, every active IAP-protected session that employee held — SSH tunnels to VMs, browser sessions to internal admin panels, API tokens for automated workflows — terminates on next request. No operator needs to know which sessions were active. No one has to hunt for lingering processes. The revocation propagates by itself.

- **OAuth refresh token compromised.** An attacker exfiltrates a Google refresh token from a developer's laptop. Admin discovers this and revokes the token in the Google Workspace admin console. On the attacker's next attempt to refresh the access token, refresh fails; on the attacker's next request through IAP, the (now-invalid) access token is rejected. Session dies. Without admin action on any individual VM.

- **IAM policy change (privilege reduction).** A user's `roles/iap.tunnelResourceAccessor` role is downgraded to `roles/logging.viewer` on the same project. Their existing SSH tunnels to VMs terminate on next request; their existing log-viewer sessions continue. Zero coordination required; the new policy just takes effect on all subsequent requests.

The traditional model's answer to any of these scenarios is: audit currently-active sessions, identify affected ones, terminate them manually across possibly hundreds of resources, hope no attacker was faster than the auditor. The IAP model's answer is: revoke the grant, walk away. The system enforces the new state automatically.

## Workforce Identity Federation — beyond Google identities

A common misreading of IAP is that it requires everyone to have a Google Workspace account. That is not true.

IAP integrates with any OIDC-compliant or SAML-compliant identity provider via **Workforce Identity Federation**. Common integrations include Okta, Auth0, Microsoft Azure AD / Entra ID, Ping Identity, and custom SAML implementations. For a company that uses Okta as its primary identity provider, users sign in to Okta as normal, and Okta issues tokens that IAP accepts as proof of identity — mapped to IAM grants on Google Cloud resources.

The per-request-evaluation property holds either way. Whether the identity comes from Google Workspace or a federated IdP, IAP validates the token cryptographically, checks the IAM binding, and enforces the current state on every request.

## The Aurora / BeyondCorp connection, made concrete

Aurora's technical lesson was that the interior-is-trusted assumption is the vulnerability. BeyondCorp's response was: never trust the network, evaluate identity + context per request.

IAP is where that response becomes concrete for a cloud workload. The **identity** part of BeyondCorp is what this chapter has been describing. The **context** part — the "what device, what location, what patch level" additional factors — is Chapter 6.

Together, they replace the perimeter-trust model with something categorically stronger: **no request is trusted merely because of where it came from; every request must prove who it is and be currently authorized for the specific thing it's asking for.**

For David's packet: it has been decrypted, backbone-routed, ALTS-authenticated between Google services, and now has to prove — with cryptographic identity and current IAM authorization — that it is entitled to open a tunnel to this specific VM. That is happening right now, at IAP. If either check fails, the packet dies here and never reaches the VPC firewall.

## The Fort Knox parallel

The Depository building's entrance is not a locked door with a key. It is a **biometric gate with a real-time database check.** Fingerprint scanner, retinal scanner, live query against the current authorization roster.

Even the Depository's own long-tenured employees are prompted anew every single visit. There is no "I was here yesterday" bypass. There is no "I've been an employee for twenty years" bypass. **The scanner does not care about history; it cares about current authorization.** If HR disabled your access at 3:00pm because you left the company, the scanner refuses you at 3:01pm — regardless of whether you show up with your old badge, your old fingerprint, or your old face. The database says no, the scanner says no, the guards act on the scanner's answer.

This is the exact operational property of IAP. Every visit is a fresh authorization event. The badge in your pocket has no authority independent of the database. The database is the truth. The scanner is the enforcement point. **Yesterday's badge is not today's badge.**

---

*Next up: [Chapter 6 — IAP Context Check (Context-Aware Access)](./06-iap-context-check.md)*
