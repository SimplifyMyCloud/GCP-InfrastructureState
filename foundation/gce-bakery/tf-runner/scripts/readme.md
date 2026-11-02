# gce-bakery / tf-runner / scripts

Packer **provisioner scripts** for the tf-runner image. Packer runs them in numeric order on the throwaway build VM.

| Script | Step |
| --- | --- |
| `00-base.sh` | update Ubuntu 22.04 and install base utilities |
| `10-terraform.sh` | install a **pinned** Terraform version (from the recipe) plus linters |
| `20-gcloud.sh` | install the Google Cloud SDK (auth is ADC off the attached SA, never keys) |
| `99-cleanup.sh` | runs last: strip caches, logs, machine identity and SSH host keys so the image is clean to publish |
