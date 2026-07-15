# tf-runner — the dedicated Terraform runner image

Bakes the box that runs **every** `terraform` command off humans' laptops and inside GCP —
the `iq9-tf-runner` VM referenced in the repo-root [`gcp_provider.tf`](../../../gcp_provider.tf)
auth model. One reproducible, auditable execution environment for the whole IaC pipeline,
with a **swappable RO/RW identity** gated by the release schedule.

Built in the same dedicated bakery network as every recipe
([`foundation/networks/bakery/`](../../networks/bakery/)): no public IP, SSH over IAP,
egress via Cloud NAT.

## What's baked

| Tool | Why |
| --- | --- |
| `terraform` (pinned, `var.terraform_version`) | The runner agrees with the repo's `required_version` |
| `tflint`, `terraform-docs` | plan-time lint + doc generation in the pipeline |
| `google-cloud-cli` (gcloud + gsutil) | ADC auth, **impersonated-token minting**, state-bucket access |
| `git`, `jq`, `make` | pull the IaC repo, parse plan/state JSON |
| `/usr/local/bin/tf-run` | the RO/RW swap wrapper (see below) |

No SA keys are ever baked — the org forbids them, and identity is resolved at runtime.

## The RO/RW swap (the whole point)

The **image is identity-agnostic.** Which SA a run uses is decided at runtime by `tf-run`:

```bash
tf-run plan    foundation/networks/bakery     # READ-ONLY  identity
tf-run apply   foundation/networks/bakery     # READ-WRITE identity (deployment window only)
```

There are two valid mechanisms; the wrapper supports both:

### A) Impersonation (recommended — no restart, time-boxed by IAM)

- The VM's **attached** SA is a low-privilege base identity (`iq9-tf-runner-sa`).
- Per run, `tf-run` mints a **short-lived impersonated access token** for the phase's
  target SA and exports `GOOGLE_OAUTH_ACCESS_TOKEN` (consumed by both the provider and the
  GCS backend). Set the targets via env (typically from instance metadata):
  ```bash
  export TFRUN_RO_SA=iq9-tf-ro-sa@<proj>.iam.gserviceaccount.com
  export TFRUN_RW_SA=iq9-tf-rw-sa@<proj>.iam.gserviceaccount.com
  ```
- **The swap is enforced by IAM, not the script:** the base SA only holds
  `roles/iam.serviceAccountTokenCreator` on the **RW** SA *during an approved deployment
  window* (a Foundation IAM change on the release schedule). Outside the window, minting an
  RW token simply fails — least privilege *by time*. The RO SA's tokenCreator can stand
  permanently so `plan` always works.

### B) Attached-SA swap (simplest — uses ADC directly)

- Leave `TFRUN_RO_SA`/`TFRUN_RW_SA` unset; `tf-run` runs as the **attached** SA via ADC.
- To go RO→RW you swap the instance's attached SA: stop the VM,
  `gcloud compute instances set-service-account … --service-account=<RO|RW>`, start it.
  Clunkier (requires a restart) but dead simple and matches the current `gcp_provider.tf`
  model exactly (ADC = attached SA, nothing impersonated).

Either way, `apply`/`destroy` are **double-gated**: `tf-run` refuses them unless
`TFRUN_ALLOW_WRITE=yes` is exported — a deliberate "are we really in a deployment window?"
seatbelt on top of the IAM time-boxing.

> The RO/RW SAs, their role grants, and the tokenCreator time-boxing are **Foundation IAM
> Terraform** (e.g. under `foundation/iam/`), *not* part of this image — the image stays
> generic. This recipe bakes the tools + wrapper only.

## Build

```bash
cd foundation/gce-bakery/tf-runner
packer init .
packer validate -var "gcp_project_id=iq9-gcp-dev-yamato" .
packer build    -var "gcp_project_id=iq9-gcp-dev-yamato" .
```

Produces a private image `iq9-img-tf-runner-<ts>` (family `iq9-tf-runner`). Same OS-Login /
IAP / NAT build path as the other recipes — see [`../gamilas-redteam/`](../gamilas-redteam/)
if the build stalls at SSH (IAP role) or NAT warm-up.

## Deploy (separate Terraform, not in this recipe)

Stand up the runner from the `iq9-tf-runner` family with: the low-priv base SA attached,
**no external IP** (it reaches GCP APIs via Private Google Access / the bakery NAT), on the
bakery subnet (or its own ops subnet), and the RO/RW target SAs passed via instance
metadata so `tf-run` picks them up. Then per run:

```bash
git -C /opt/iac/GCP-InfrastructureState pull        # fresh desired-state
tf-run plan  foundation/networks/bakery             # RO
TFRUN_ALLOW_WRITE=yes tf-run apply foundation/networks/bakery   # RW, in-window
```

## Files

| File | Purpose |
| --- | --- |
| `tf-runner.pkr.hcl` | googlecompute source + build (bakery network, IAP, no public IP) |
| `variables.pkr.hcl` | build inputs incl. `terraform_version` |
| `scripts/00-base.sh … 99-cleanup.sh` | base, terraform+linters, gcloud, cleanup |
| `runner/tf-run.sh` + `runner/lib/common.sh` | the RO/RW swap wrapper (→ `/opt/tf-runner`, `tf-run` on PATH) |
| `readme.md` | this file |
