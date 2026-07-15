# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects — yamato / dev
# ---------------------------------------------------------------------------------------------------------------------
#
# Creates the empty GCP project that hosts the dev environment of the
# `yamato` application (the Star Blazers ships/characters/planets codex).
#
# This state owns the project shell (this file) AND the project's API enablement
# (gcp_projects_yamato_dev_apis.tf). API enablement is a foundation-layer
# responsibility — in a hardened split-identity model the Service-layer TF SA
# cannot enable APIs — so the Service Layer assumes the APIs it needs are already
# on and never enables them itself.
#
# Hardcoded values
# ----------------
#   folder_id        696735621171                       (the `dev` folder)
#   billing_account  000000-000002-6D3BF8               (the iq9 billing account)
#   project_id       iq9-gcp-dev-yamato                 (per docs/naming-convention.md)
#
# auto_create_network = false because the default VPC is a sprawl of
# auto-mode subnets across every region. Foundation/networks/yamato/dev/
# creates a single custom-mode VPC inside this project.
#
# deletion_policy = "PREVENT" so a `terraform destroy` cannot accidentally
# wipe the project (and everything inside it). To actually destroy the
# project the policy must first be flipped to DELETE in a separate apply.

resource "google_project" "yamato_dev" {
  name       = "iq9-gcp-dev-yamato"
  project_id = "iq9-gcp-dev-yamato"

  folder_id       = "696735621171"
  billing_account = "000000-000002-6D3BF8"

  auto_create_network = false
  deletion_policy     = "PREVENT"

  labels = {
    env = "dev"
    app = "yamato"
  }
}
