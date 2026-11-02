# Chapter 7 — VPC Firewall (`35.235.240.0/20`)

*The belt-and-suspenders layer. Even if IAP misconfigures or breaks, this layer holds — because it doesn't trust anything upstream.*

## Where we are

David's packet has now cleared IAP. Identity was verified against a Google-Auth-signed OAuth token. IAM confirmed his `roles/iap.tunnelResourceAccessor` grant on the specific VM. Context-Aware Access checked his device posture, network location, and OS patch level, and they all matched policy. IAP has opened the tunnel and is about to forward the packet inward.

But between IAP and the VM, one more layer sits: the **VPC firewall.**

At first glance this may seem redundant. If IAP already checked identity, IAM, and context — why do we need a network-layer firewall as well? The answer is the entire philosophy of defense in depth, and it is worth understanding thoroughly.

## What VPC firewalls are

Google Cloud's VPC firewall is a stateful, distributed, packet-filter enforcement layer applied per-VPC-network. It has these operational properties:

- **Stateful.** Once a connection is established, return traffic is automatically permitted — you do not need to open ephemeral port ranges for responses.
- **Distributed.** The firewall runs at every hypervisor hosting a VM in the network; there is no central chokepoint. Every packet is evaluated at the point of ingress to (or egress from) its target VM.
- **Rule-ordered by priority.** Lower priority number = evaluated first. Rules are additive; the first match determines the action.
- **Default deny for ingress, default allow for egress.** In a new VPC, nothing is allowed in until you write a rule saying so. Everything is allowed out until you write a rule denying it.
- **Targets by tag or service account.** Rules apply to specific instances via network tags (like `allow-iap-ssh`) or by the runtime service account of the VM.

The primitive is standard across cloud providers — AWS calls the equivalent Security Groups, Azure calls it Network Security Groups. But the *specific pattern* we use for IAP tunneling is a Google idiom that emerges directly from the IAP architecture.

## The specific rule for IAP tunneling

To allow IAP-tunneled SSH to reach a VM, the VPC firewall needs exactly one rule:

```hcl
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-ssh-from-iap"
  network = google_compute_network.vpc.name

  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]     # IAP's fixed range
  target_tags   = ["allow-iap-ssh"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
```

The rule says: on this VPC, for VMs tagged `allow-iap-ssh`, allow incoming TCP connections on port 22 from source addresses in the `35.235.240.0/20` block. That is the entire configuration.

Everything else is implicit-deny:
- Public internet trying to reach the VM on port 22 → denied.
- Another VM in the same project trying to reach in directly → denied (unless there is a separate rule for internal VPC traffic).
- Any other port → denied.
- Any other protocol → denied.

Five lines of HCL. **That is the VM's entire inbound network surface.**

## Why the source range is `35.235.240.0/20`

The address block `35.235.240.0/20` is **Google's published, stable source range for IAP TCP forwarding.** Roughly 4,096 addresses, reserved by Google exclusively for IAP tunneling infrastructure. When IAP forwards a tunneled request to a VM, the request always originates from an IP inside this range.

Two properties of the range are worth naming:

1. **It is fixed and stable.** Customers can hardcode this range in firewall rules and rely on it not changing without notice. Google publishes the range in its documentation and any change would be announced well in advance.
2. **Google owns the entire block.** No other tenant, no other Google service, no external party controls IPs inside this range. Traffic sourced from `35.235.240.0/20` provably came from IAP.

The consequence: if a packet arrives at your VM claiming to be from `35.235.240.0/20`, it came from IAP. Full stop. There is no impersonation vector — the source IP is enforced at multiple layers of Google's network before it ever reaches your VPC.

## Why this is belt-and-suspenders — the defense in depth argument

The question that opens this chapter — *"if IAP already checks identity and context, why do we need a firewall too?"* — has a specific and important answer: **because the layers must be independent.**

Imagine, hypothetically, that IAP had a bug tomorrow. A zero-day. Something that let unauthorized requests through the identity check. Or imagine an admin accidentally misconfigured IAP on a load balancer, and a backend became reachable without IAP in front of it. Or imagine a routing change that unintentionally created a network path around IAP.

In every one of those scenarios, the VPC firewall still holds. **Because the firewall does not care about IAP's authentication logic.** It cares about the source IP. Anything that does not come from `35.235.240.0/20` is dropped, no matter how legitimate the request looks at the application layer. No matter how valid the OAuth token. No matter how good the identity story.

This is what defense in depth means when it is real: **two independent enforcement mechanisms, evaluating two independent properties, both required to pass.** A vulnerability in one does not compromise the other, because they are checking different things at different layers.

Contrast this with the failure mode of collapsed-layer architectures. When identity and authorization and network are all enforced at one point — say, an application-layer auth check in the application itself — then a bug in that one point compromises the whole system. The Aurora attackers exploited exactly this pattern: once past the perimeter, everything trusted the network. There was no second gate.

VPC firewalls exist so there is always a second gate at the network layer, regardless of what the layers above are doing.

## Independent enforcement — the philosophical point

The important design principle here is not "add more layers." It is **make each layer independent.**

If two layers check the same thing in the same way, they add nothing. If a bug in one layer exists, the same bug in the other layer (or a shared dependency they both rely on) means the "second" layer doesn't actually catch anything.

VPC firewalls are useful precisely because they check something IAP does not: the source IP of the incoming packet, evaluated at the hypervisor level, using data from Google's SDN control plane. The firewall does not consult IAM. It does not verify OAuth tokens. It does not care about Context-Aware Access policies. It knows one thing — "does this packet's source IP match an allowlisted range" — and it enforces that one thing rigorously.

That narrow independence is the whole security value. IAP failing does not affect the firewall's decision-making. A firewall bug does not affect IAP's decision-making. They are two systems with two data planes and two failure modes.

## Real scenarios where this layer saves you

A few concrete cases where "we also have the VPC firewall" is what actually holds:

**IAP accidentally removed from a load balancer.** An admin editing the LB configuration accidentally removes the IAP-enforcement setting from a backend service. The backend is now reachable via the LB without IAP in front. **Without the VPC firewall, the workload is now public.** With the VPC firewall allowing only `35.235.240.0/20`, the workload remains protected — the LB can route traffic to it, but the VPC firewall drops any traffic whose source isn't an IAP IP.

**Zero-day in IAP.** A hypothetical vulnerability lets attackers bypass IAP authentication. Attackers craft requests that IAP incorrectly accepts. **Requests still originate from IAP-owned IPs, so the firewall doesn't catch this specific attack** — but if the attack instead bypasses IAP entirely (e.g., a direct network path is found), the firewall catches it because the source IP is not IAP's range.

**Insider with project access.** An engineer who legitimately has access to another VM in the same project tries to reach the target VM directly, bypassing IAP. Without a rule permitting internal VPC traffic on port 22, the firewall denies it. Even inside the project, the VM is only reachable through IAP.

**Route misconfiguration.** Someone adds a custom route that shouldn't be there, giving the VM a new network path from an unexpected source. The firewall still enforces "traffic must come from IAP's range" and drops anything else regardless of routing.

**Provider-level infrastructure change.** Google's own infrastructure evolves; new services get added, existing services change behavior. The firewall's rule is stable regardless — as long as `35.235.240.0/20` stays the IAP source range, the VM's ingress surface does not change.

In each of these scenarios, the VPC firewall is the layer that holds when something else has moved.

## Stateful firewall behavior

One important operational note: the firewall is **stateful.** Once a TCP connection is established from an allowed source, the return traffic from the VM back to that source is automatically permitted. There is no need for a matching egress rule, no need to open ephemeral port ranges, no need to think about which port the response will come from.

This matters because the naive alternative — separate ingress and egress rules for the two directions of a TCP connection — is a common source of misconfiguration in stateless firewall systems. GCP's stateful behavior removes that class of mistake.

For David's SSH connection: IAP opens a TCP connection to the VM's port 22 from an IP in `35.235.240.0/20`. The firewall permits the connection because the source and destination match the rule. All subsequent packets in that TCP conversation — SSH banner exchange, key exchange, encrypted shell traffic, response bytes going back — flow automatically without additional rule matches.

## The Cloud Run analog

The same architectural pattern applies to serverless workloads. In the Yamato Wiki story earlier in this session, both Cloud Run services are configured with:

```hcl
ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
```

This means the Cloud Run services refuse traffic on their `*.run.app` URLs from the public internet. Only traffic from the external HTTPS load balancer (Google's internal path from the LB to Cloud Run) can invoke them. It is the same architectural idea as the VPC firewall's IAP-only rule — narrow the accepted source of traffic to a specific, trusted upstream, and refuse everything else at the network layer.

Between the two — VPC firewall on private VMs, ingress restriction on Cloud Run services — the pattern generalizes: **for any workload that should not be publicly reachable, restrict its network ingress to specifically-known trusted sources, enforced independently of application-layer auth.**

## Contrast with "no firewall" architectures

Some cloud architectures skip network-layer firewalls entirely, relying on load balancers, API gateways, or application-layer authentication to control access. This is fine until it isn't:

- If the application-layer auth has a bug, there is no second gate.
- If the LB is misconfigured to allow public routing, no second gate.
- If someone accidentally exposes the workload (say, by changing an ingress setting), no second gate.
- If the app-layer auth's dependency (say, an identity provider) has an outage, the workload either becomes unreachable or, worse, becomes wide open depending on how the failure mode is coded.

VPC firewall — or Cloud Run ingress restriction, or any other network-layer restriction — is the *"and one more thing"* that says: even if the layer above me fails, this layer holds. It costs almost nothing to configure. It costs almost nothing to operate. And it is the difference between a bug being a bad afternoon and a bug being a breach.

## The Fort Knox parallel

Even inside the Depository building — past the biometric gate, past the escort walking the interior corridor — the vault itself sits at the end of a hallway that has **its own credentialed personnel.**

The vault-escort service is a specific team, pre-cleared for this specific corridor. Not every Depository employee walks this hallway. Not every visitor with a valid interior escort gets this far. When you arrive at the vault-hallway entrance, two armed guards are checking their roster: is your escort officer on the vault-escort roster today? Is your visitor name on the pre-cleared list for this hallway? If both boxes check, you pass through. If either does not, the guards turn you back — politely, but with hand near holster, and with visible armed backup a few steps behind.

The vault-hallway guards do not care about the biometric gate. They do not care about your interior escort's own authorization. They care about their roster. If the roster says you belong here, you belong here. If the roster says no, no. **Even if the biometric gate had let someone in by mistake, the vault-hallway guards would still refuse them at this door — because they aren't on the roster for this specific hallway.**

Two independent authorizations, both required. Two independent enforcement mechanisms, both operating on different data. If one fails, the other holds. That is the operational property of the VPC firewall in the packet-trace story, told in the physical language of the vault.

For David's packet: it came from IAP, so its source IP is inside `35.235.240.0/20`. The firewall waves it through. If David had somehow tried to reach the VM's internal IP directly from anywhere else — from another VM in the same project, from a compromised endpoint elsewhere in Google's network, from anywhere — the firewall would have refused, silently, no matter how valid his OAuth token or how compliant his device.

---

*Next up: [Chapter 8 — OS Login SSH Key Check](./08-os-login-ssh-key-check.md)*
