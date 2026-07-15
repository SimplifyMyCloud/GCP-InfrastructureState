# Foundation Layer — GCE Bakery

> _"A GCE VM **must be baked** in the GCP Bakery to be available on the GCP API."_ — repo README

The **bakery** is where machine images are built. We do not boot a VM and `apt install`
into production; we **bake** a frozen, auditable image with [Packer](https://www.packer.io/),
publish it, and then Service-Layer Terraform (or `doctl` on DigitalOcean) deploys VMs
**from** that image. Baking gives us: reproducible builds, a fixed/auditable software set,
fast boots, and a clean separation between "what's on the box" (bakery) and "where the box
runs" (Service Layer).

Each subdirectory here is one **recipe** — a self-contained Packer build for one image.

## Recipes

| Recipe | Image | Purpose |
| --- | --- | --- |
| [`gitlab-offline/`](./gitlab-offline/) | _(stub)_ | Offline GitLab appliance image. |
| [`gamilas-redteam/`](./gamilas-redteam/) | Ubuntu 22.04 + red-team toolkit | **Authorized** security-scanning box (GCP image **and** DigitalOcean snapshot) used to attack our own yamato wiki and prove the GCP defense-in-depth holds, logs, and alerts. |
| [`tf-runner/`](./tf-runner/) | Ubuntu 22.04 + Terraform toolchain | The dedicated Terraform runner (`iq9-tf-runner`): pinned terraform + gcloud + a RO/RW service-account-swap wrapper, so all IaC runs happen on one auditable, keyless box gated by the release schedule. |

## Conventions

- **HCL2 Packer** (`*.pkr.hcl`), `packer init` to fetch plugins, `packer fmt` + `packer
  validate` before build.
- Image name standard: `iq9-img-{recipe}-{YYYYMMDD-hhmmss}`, image family `iq9-{role}`.
- **Secrets are variables, never hardcoded** (API tokens, project IDs). Tool/content
  *selection* is hardcoded in provisioner scripts — the Foundation security perimeter is
  fixed in code, not parameterised.
- Every image is labelled `layer=foundation` + `purpose=…` so it is identifiable in an audit.
