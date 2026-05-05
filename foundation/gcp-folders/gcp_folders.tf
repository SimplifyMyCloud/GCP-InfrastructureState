# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Folders — environment hierarchy under the iq9 top-level folder
# ---------------------------------------------------------------------------------------------------------------------
#
# Five environment folders hang directly off the iq9 folder, one per
# environment. The iq9 folder itself is bootstrap-created and lives outside
# Terraform management; this state owns only its children.
#
#   ops      — SRE domain. Hosts iac (this terraform), observability, image
#              bakery, and the short-lived bootstrap project.
#   logs     — log warehouse. Cold archive, multi-year retention, deliberately
#              separate from observability.
#   sandbox  — per-engineer playgrounds. No company code or data.
#   dev      — application development. Contains a `test` sub-environment
#              project (CI-only IAM).
#   prod     — production. Contains a `stage` sub-environment project for
#              blue/green flip-flops.
#
# `ops` and `logs` are created manually by the bootstrap and brought under
# Terraform management via `terraform import` (commands in readme.md). The
# other three are created fresh by `terraform apply`.
#
# Parent folder ID 147640766174 is the bootstrap-created `iq9` folder, child
# of organization 933250405420 (simplifymy.cloud). It is treated as a
# constant by every foundation TF state in this repo.

resource "google_folder" "ops" {
  display_name = "ops"
  parent       = "folders/147640766174"
}

resource "google_folder" "logs" {
  display_name = "logs"
  parent       = "folders/147640766174"
}

resource "google_folder" "sandbox" {
  display_name = "sandbox"
  parent       = "folders/147640766174"
}

resource "google_folder" "dev" {
  display_name = "dev"
  parent       = "folders/147640766174"
}

resource "google_folder" "prod" {
  display_name = "prod"
  parent       = "folders/147640766174"
}
