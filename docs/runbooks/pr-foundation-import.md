# PR: Foundation, import the entire live simplifymy.cloud GCP Org into Terraform

_Paste as the PR body for `dev-refresh` → `main`. You can delete this file after the PR is open._

## What

`/foundation` now describes the **simplifymy.cloud GCP Org exactly as it is**, and so does the Terraform state:

> **GCP = git = Terraform state.** Every Org / folder / project node has one git directory, and that directory's state lives at the same path in `gs://smc-ops-tf-state/terraform/state/`.

- **56 Terraform directories** in 7 slices: `gcp-org`, `gcp-folders`, `gcp-projects`, `iam`, `logging`, `networks`, `firewalls`
- **~1,000 resources imported** from the live Org; **every directory plans to `No changes`** (full sweep run after the last apply)
- Hardcoded values only; one shared `gcp_provider.tf` symlinked everywhere; one hardcoded backend per directory
- Terraform runs as **`smc-tf-foundation-sa`** via impersonation env vars, with no identity or key in code
- A `readme.md` in **every** directory. **`foundation/readme.md`** is the one-hour new-SRE guide (Org + networking whiteboards, who runs Terraform, findings)

## Changes made in GCP during the import

| Change | Where |
| --- | --- |
| created `smc-tf-foundation-sa` + `gs://smc-ops-tf-state` | `iam/smc-ops/smc-ops`, `gcp-projects/smc-ops/smc-ops` |
| SA granted org owner / orgAdmin / orgpolicy.policyAdmin / billing.user / iam.organizationRoleAdmin for the import, **then switched to plan-only** (see below) | `iam/gcp-org` |
| chris@ granted tokenCreator on the SA | `iam/smc-ops/smc-ops` |
| 33 management APIs enabled on smc-ops (quota project for the SA) | `gcp-projects/smc-ops/smc-ops` |
| **removed** 10 leftover `iq9-bootstrap-sa` org grants | `iam/gcp-org` |

Everything else was an import with no change.

## SA switched to plan-only (2026-11-02)

After the import, `smc-tf-foundation-sa` lost its 5 broad org roles and now holds read roles only (`viewer`, `iam.securityReviewer`, `orgpolicy.policyViewer`, `iam.organizationRoleViewer`, `browser`, `firebaserules.viewer`, `storage.bucketViewer`), plus `storage.objectAdmin` on the state bucket for locks. All 56 directories plan `No changes` as the read-only SA. Applies now happen in a **change window** that chris@ opens and closes in `iam/gcp-org` (process in `foundation/readme.md` section 4).

## Firewalls: no SSH/RDP from the internet (2026-11-02)

First change window (`2224bbf` open → `13168ec` apply → `b102609` close): deleted `default-allow-ssh` / `default-allow-rdp` (0.0.0.0/0) in the 5 prod VPCs and `smc-fw-public-22` in dev, 11 rules in all. No VMs exist in those projects. Dev SSH stays IAP-only (`smc-fw-iap-22`). `default-allow-icmp` kept on purpose.

## Retiring `smc-ops-tf-org-admin`, stage 1 (2026-11-02)

Second change window (`e71f4a8` open → `50c1028` apply → `fb46173` close): removed its `organizationAdmin` binding on smc-ops and **disabled** the SA. Its one user-managed key (2020) was disabled with gcloud; its other key is Google-managed. **Stage 2 on or after 2026-12-02** (30-day quiet period): delete the key, the SA and its two chris@ grants.

## Org-wide log archive + dev retention (2026-11-02)

Third change window (`a6d3397` open → `dc34817` apply → `96401f6` close): new org sink `smc-org-log-archive` (no filter, every folder and project, non-intercepting) → `gs://smc-ops-log-archive` (Archive class, us-west1, deleted after 365 days, not locked), with `objectCreator` for the sink's writer identity. `smc-dev-env-logging` retention raised from 3 to 30 days.

## Removed from the repo

- iq9-era Terraform that no longer matches GCP: old `foundation/*` dirs and `service/yamato/` (still at tag `iq9-final`)
- iq9-era docs/demo material is **kept** with a "Historical (iq9 era)" banner

## Follow-ups (not in this PR)

1. Stage 2 of retiring `smc-ops-tf-org-admin`, on or after 2026-12-02
2. Delete `gen-lang-client-0690825234`; `state rm` the CIS custom roles from the CIS audit module

🤖 Generated with [Claude Code](https://claude.com/claude-code)
