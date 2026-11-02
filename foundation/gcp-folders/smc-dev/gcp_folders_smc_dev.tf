# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Folders — smc-dev (922883963214)
# ---------------------------------------------------------------------------------------------------------------------
#
# The smc-dev environment folder, directly under the simplifymy.cloud Org
# (933250405420). Projects inside it are in foundation/gcp-projects/smc-dev/.
#
# Imported from the live Org on 2026-11-01. deletion_protection stops a stray
# `terraform destroy` from deleting the folder (and orphaning its projects).

resource "google_folder" "smc_dev" {
  display_name        = "smc-dev"
  parent              = "organizations/933250405420"
  deletion_protection = true
}

import {
  to = google_folder.smc_dev
  id = "folders/922883963214"
}
