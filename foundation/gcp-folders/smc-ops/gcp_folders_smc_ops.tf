# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Folders — smc-ops (714502724732)
# ---------------------------------------------------------------------------------------------------------------------
#
# The smc-ops environment folder, directly under the simplifymy.cloud Org
# (933250405420). Projects inside it are in foundation/gcp-projects/smc-ops/.
#
# Imported from the live Org on 2026-11-01. deletion_protection stops a stray
# `terraform destroy` from deleting the folder (and orphaning its projects).

resource "google_folder" "smc_ops" {
  display_name        = "smc-ops"
  parent              = "organizations/933250405420"
  deletion_protection = true
}

import {
  to = google_folder.smc_ops
  id = "folders/714502724732"
}
