# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Folders — smc-prod (386439801809)
# ---------------------------------------------------------------------------------------------------------------------
#
# The smc-prod environment folder, directly under the simplifymy.cloud Org
# (933250405420). Projects inside it are in foundation/gcp-projects/smc-prod/.
#
# Imported from the live Org on 2026-11-01. deletion_protection stops a stray
# `terraform destroy` from deleting the folder (and orphaning its projects).

resource "google_folder" "smc_prod" {
  display_name        = "smc-prod"
  parent              = "organizations/933250405420"
  deletion_protection = true
}

import {
  to = google_folder.smc_prod
  id = "folders/386439801809"
}
