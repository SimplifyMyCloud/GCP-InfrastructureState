# Chapter 8 — OS Login SSH Key Check

*The innermost check. IAP tunneled the raw TCP; SSH itself still has to prove its identity. Two independent authorization systems, both required, at the same request.*

## Where we are

David's packet has now cleared every layer between his laptop and the VM. TLS wrapping made the packet opaque on the wire. GFE terminated the TLS envelope and scrubbed DDoS. The private backbone carried the packet on Google's own fiber, ALTS-encrypted. IAP verified David's identity, checked his IAM role, and evaluated his device and context. The VPC firewall verified the packet's source IP was inside IAP's known range.

Seven layers of defense, seven checks, each independently enforced. The packet has finally arrived at the VM's internal IP address on port 22.

But there is still one more check before David gets a shell.

## IAP tunneled raw TCP — it did not authenticate SSH

Here is the architectural fact that is easy to overlook and important to name: **IAP only tunneled the TCP connection.** It made the VM's port 22 reachable to a specific identity from a specific device in a specific context. It did not authenticate the SSH protocol itself. It did not verify David's SSH key. It did not spawn a shell.

Those are the VM's job. Specifically, they are `sshd`'s job — the OpenSSH server running on the VM. And on a properly-configured GCE VM, sshd delegates the key-management side of its work to **OS Login**.

## What OS Login is

OS Login is Google's replacement for traditional SSH key management on Compute Engine VMs. Traditionally, SSH access to a Linux server was gated by `~/.ssh/authorized_keys` — a per-user file on each server listing the public keys allowed to authenticate as that user. Managing these files across a fleet of machines was a well-known operational headache: distributing new keys required a configuration-management push; removing an employee's access required a sweep across every server they might have touched; forgotten keys accumulated silently over years.

OS Login replaces that model. When OS Login is enabled on a project or VM (via the metadata flag `enable-oslogin=TRUE`), traditional `authorized_keys` files are bypassed. Instead, SSH keys are managed centrally in **Google's identity service** — the same identity service that authenticates IAP requests. Keys are keyed to a Google identity (a user account), and the VM queries Google in real-time to determine which keys are currently authorized for which identity.

The consequence: **SSH access is managed as an IAM binding**, not as a file on a machine. Granting or revoking access is a policy change in Cloud IAM, not a config-management run.

## How the SSH key check actually works

The mechanics, step by step, for David's SSH connection:

1. **David uploads his SSH public key** to his Google identity via `gcloud compute os-login ssh-keys add --key-file=~/.ssh/id_ed25519.pub`. The key is stored centrally in Google's identity service, tied to his `user:david.lightman@example.com` identity.
2. **David runs the gcloud SSH command** with `--tunnel-through-iap`. gcloud opens the IAP tunnel (Chapters 5–7 in this book), presents David's SSH public key to `sshd` on the VM, and offers to prove possession of the corresponding private key.
3. **On the VM, `sshd` runs the OS Login PAM module** (Pluggable Authentication Modules — the Linux extension point for authentication). The PAM module queries Google's metadata server: *"what are the current authorized SSH keys for identity `david.lightman@example.com`?"*
4. **The metadata server returns the current key list** for David's identity, along with confirmation that David holds the required IAM role (`roles/compute.osLogin` for standard access, or `roles/compute.osAdminLogin` for sudo-capable access).
5. **`sshd` compares the presented public key against the returned list.** If the key matches, sshd proceeds with the standard SSH public-key authentication challenge — asking David's client to prove possession of the corresponding private key.
6. **David's SSH client signs a challenge with the private key.** sshd verifies the signature.
7. **If both the key-match and the signature-verification succeed**, sshd allows the connection and spawns a shell as the corresponding OS user (the OS user is derived from David's Google identity — the local username is a stable derivation of his email).

The whole exchange takes a few tens of milliseconds. From David's perspective, it looks like a normal SSH session opening.

## Two independent authorization systems, at the same request

The architectural point is worth stating precisely: **IAP and OS Login are two independent authorization systems, evaluating two different questions, both required to succeed for a shell to spawn.**

- **IAP asks:** "Does this identity have `roles/iap.tunnelResourceAccessor` on this specific VM? Are they connecting from an authorized device in an authorized context? Is their OAuth token valid right now?"
- **OS Login asks:** "Does this identity have `roles/compute.osLogin` on this project or VM? Have they registered an SSH public key? Does the key presented at the SSH handshake match a currently-registered key?"

Both use Google's identity system as the anchor — the *same* `david.lightman@example.com` is the subject of both checks. But the two checks are separate. Different IAM roles gate them (`iap.tunnelResourceAccessor` vs `compute.osLogin`). Different authentication artifacts prove them (OAuth JWT vs SSH public/private key pair). Different failure modes.

**Both must succeed.** If David's IAP role is revoked, the tunnel never opens and OS Login is never consulted. If David's OS Login role is revoked, the tunnel might open but sshd refuses the connection. If David's registered SSH public key is removed, sshd refuses the connection even if his OS Login role is intact.

This is the innermost expression of the belt-and-suspenders principle we saw at the VPC firewall. Even if IAP had somehow been bypassed — hypothetical zero-day, admin misconfiguration, whatever — OS Login is still there. And even if OS Login could somehow be fooled, IAP had already vouched for the identity through an independent authentication path.

## What OS Login replaced — and why the replacement matters

To feel the operational value of OS Login, it helps to remember what it replaced.

Before OS Login, SSH key management on a cloud fleet was an exercise in perpetual maintenance:

- **New employee joins.** Their public key gets added to `~/.ssh/authorized_keys` for every user account on every server they need to access. Typically via a config-management tool — Ansible, Chef, Puppet — but the operational discipline of running that tool consistently across the fleet was itself a challenge.
- **Employee leaves.** Their public key needs to be removed from `~/.ssh/authorized_keys` on every server. This required knowing which servers they had access to. In practice, forgotten keys were the norm — a departing engineer's key might sit in `authorized_keys` files on machines nobody remembered they'd touched, for years.
- **Key rotation.** An engineer wants to rotate their SSH key. They generate a new pair, and now the same config-management sweep has to distribute the new key and remove the old one, across every server the engineer accesses.
- **Compromised key.** An engineer's private key is exfiltrated by malware. Damage control requires purging that specific key from every `authorized_keys` file on every server. In the meantime, the attacker still has access.
- **Audit.** Answering "who currently has SSH access to this server?" required inspecting `authorized_keys` files across every user account on that server. Answering "who currently has SSH access anywhere in the fleet?" required doing that inspection across every server. Both are painful.

OS Login collapses all of these operations into IAM policy changes:

- **New employee joins.** Grant them `roles/compute.osLogin` on the project. They can now SSH into every VM in the project (once their SSH key is uploaded to their Google identity). Zero VM-level work.
- **Employee leaves.** Revoke their `roles/compute.osLogin`. Their SSH access to every VM in the project dies within seconds, on the next connection attempt. Their Google account is likely also disabled by that point, which independently removes their registered SSH keys.
- **Key rotation.** Upload the new key to Google identity. Delete the old key from Google identity. Both changes propagate to all VMs on the next connection.
- **Compromised key.** Delete the compromised key from Google identity. It stops working on every VM within seconds. No config-management run required.
- **Audit.** Query IAM: "who has `roles/compute.osLogin` on this project?" The answer is authoritative. Query Google identity: "what SSH keys does this identity have registered?" Also authoritative.

**Central identity is the source of truth. The VMs pull from it. The fleet's SSH access surface is managed as policy, not as files.**

## IAM roles for SSH access

OS Login gates SSH access via two IAM roles:

- **`roles/compute.osLogin`** — allows SSH access as a regular (non-privileged) user. The OS user's shell has whatever permissions a normal Linux user would have; no sudo.
- **`roles/compute.osAdminLogin`** — allows SSH access with sudo privileges. Grants passwordless sudo on the VM.

These roles can be bound at the project level (granting access to all VMs in the project), the folder level (granting access to all VMs in a folder), or the individual VM level (granting access to just one VM). The bindings can be conditional via Context-Aware Access, meaning admin-level sudo on production VMs could be gated by device posture and network location conditions on top of everything else.

## Two-factor authentication via OS Login

OS Login also supports **two-factor authentication for SSH.** This is separate from the key-check we've been describing — it adds a second factor that David would need to satisfy at connection time, beyond his SSH key. Supported factors include:

- **Hardware security keys** (FIDO U2F / WebAuthn)
- **Google Authenticator TOTP codes**
- **Google Prompt** on David's registered phone

For high-sensitivity resources — production databases, sudo access on core services — admins can require 2FA on top of SSH key possession. The tunneled SSH connection now requires: valid IAP identity + IAP context + VPC firewall + SSH key match + second factor. Five independent gates, all required.

## Real operational scenarios

A few concrete cases where OS Login's central-identity model demonstrably beats the traditional fleet-of-authorized_keys model:

**Employee terminated at 4:30pm Friday.** HR disables the Google account at 4:31pm. Their `roles/compute.osLogin` binding either gets removed as part of the offboarding IAM cleanup or becomes unusable because the underlying identity is gone. Their SSH access to every VM in every project dies within minutes. Nobody has to log into any VM. Nobody has to run a config-management job. No stale keys are left behind.

**Compromised laptop with exposed SSH private key.** David reports his laptop stolen. Admin (or David himself) removes the specific compromised SSH public key from David's Google identity. Within seconds, that key stops working on every VM. David uploads a new key from a replacement device; the new key immediately works everywhere.

**Fleet-wide SSH access grant for a new team member.** A new engineer joins a team that manages 500 VMs across a project. Grant them `roles/compute.osLogin` at the project level. They can immediately SSH to all 500 VMs (once they've uploaded their key). No fleet-wide config-management push. No manual per-VM setup.

**Time-boxed contractor access.** A contractor needs SSH access for three weeks. Grant `roles/compute.osLogin` with a Context-Aware Access condition of "expires in 21 days." After 21 days, access silently ends. No admin action required at expiration time.

**Audit of who has SSH access.** Query the IAM policy on the project for `roles/compute.osLogin` bindings. That is the authoritative list. No need to inspect files on individual VMs.

## The Fort Knox parallel

You have made it all the way to the vault cage.

The escort brought you here (Context-Aware Access). The vault-hallway guards let you through (VPC firewall). You are standing in front of the specific cage that holds the gold you are authorized to see.

**But the cage itself has its own lock.**

The lock on the cage is unique to your specific cage. It requires your personal key — a key that has been registered against your identity in the depository's central roster. The armed vault sentry watches the final check. You insert the key. Two things happen simultaneously: the physical mechanism of the lock verifies that the key's shape matches the cage's tumblers, and the depository's roster is checked in real-time to confirm your key registration is still current.

Both must be true. **Wrong-shaped key: the cage stays locked. Correct key but your registration has been revoked: the cage still stays locked.** The sentry, one hand near their holster, watches for either failure. If both pass, the cage door opens and you retrieve what you came for.

This is OS Login's operational model, told in the physical language of the vault.

Your key is not a physical key hanging on your belt in isolation. It is a key registered in the depository's central roster, matched against the cage in real time. If the depository revokes your key registration — say, you have left the depository's employ, or the depository's security team has flagged your access for review — the key you are holding stops opening the cage the same moment. **No sentry has to physically confiscate the key. The registration change is the enforcement.**

And two independent things are being checked at once: the physical key (your SSH private key) and the current roster entry (your Google identity + IAM role). Either wrong, the cage stays shut, even though you passed every prior gate on the way to this cage.

For David: he inserts his key. The cage's lock accepts the key's shape. The roster confirms his registration is current. Both true. **The cage opens.** The gold — a shell prompt — is his.

---

*Next up: [Chapter 9 — Return Path](./09-return-path.md)*
