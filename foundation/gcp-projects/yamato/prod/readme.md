# Foundation Layer — yamato / prod

**Status:** placeholder, not yet provisioned.

This directory will own a single `google_project` resource — `iq9-gcp-prod-yamato`, parented to the `prod` folder — when the prod environment is provisioned. Until then, no `*.tf` files exist in this directory and no Terraform state is created.

The activation steps will mirror [`../dev/`](../dev/) almost exactly:

1. Drop in `gcp_projects_yamato_prod.tf` with `folder_id` set to the prod folder ID, `project_id = "iq9-gcp-prod-yamato"`, deletion-protected, labels `env=prod` / `app=yamato`.
2. Drop in `gcp_projects_yamato_prod_gcs_backend.tf` with `prefix = "terraform/state/foundation/gcp-projects/yamato/prod"`.
3. Symlink `gcp_provider.tf` to the repo-root provider file.
4. `terraform init && terraform apply`.

The prod environment also needs a `stage` sub-environment project (`iq9-gcp-prod-yamato-stage`, also parented to the `prod` folder) for blue/green flip-flops. That project lives in its own state at `foundation/gcp-projects/yamato/stage/`, created when the stage workflow is wired up.
