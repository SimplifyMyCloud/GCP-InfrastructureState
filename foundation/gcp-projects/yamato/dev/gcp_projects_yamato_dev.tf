# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects — yamato / dev
# ---------------------------------------------------------------------------------------------------------------------
#
# Creates the empty GCP project that hosts the dev environment of the
# `yamato` application (the Star Blazers ships/characters/planets codex).
#
# This file owns one resource: the project shell. Per the foundation-layer
# discipline, NO cloud services and NO API enablement live here. APIs are
# enabled by the state that needs them — `compute` + `servicenetworking` in
# foundation/gcp-networks/yamato/dev/, and per-service APIs (`sqladmin`,
# `run`, `vpcaccess`, ...) in the Service Layer states.
#
# Hardcoded values
# ----------------
#   folder_id        696735621171                       (the `dev` folder)
#   billing_account  000000-000002-6D3BF8               (the iq9 billing account)
#   project_id       iq9-gcp-dev-yamato                 (per docs/naming-convention.md)
#
# auto_create_network = false because the default VPC is a sprawl of
# auto-mode subnets across every region. Foundation/gcp-networks/yamato/dev/
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
