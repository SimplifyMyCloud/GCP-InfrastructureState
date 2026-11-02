# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects — smc-ops / smc-ops — the project
# ---------------------------------------------------------------------------------------------------------------------
#
# smc-ops is the SRE / operations project. It holds the Terraform state bucket
# (gs://smc-ops-tf-state), the Terraform service accounts, and the log bucket
# that receives the smc-dev folder's logs.
#
# Imported from the live Org on 2026-11-01. Every value below is the value GCP
# reported; nothing here was invented.
#
#   folder_id        714502724732            smc-ops folder
#   billing_account  000000-000002-6D3BF8    simplifymycloud-billing-main
#
# auto_create_network only matters when a project is CREATED. smc-ops has the
# Compute API disabled, so there is no default VPC.

resource "google_project" "smc_ops" {
  name                = "smc-ops"
  project_id          = "smc-ops"
  folder_id           = "714502724732"
  billing_account     = "000000-000002-6D3BF8"
  auto_create_network = true
  deletion_policy     = "PREVENT"
  labels              = {}
}

import {
  to = google_project.smc_ops
  id = "smc-ops"
}
