# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-prod folder (386439801809) — folder IAM bindings
# ---------------------------------------------------------------------------------------------------------------------
#
# Grants made on the smc-prod FOLDER are inherited by every project inside it.
# Imported from the live Org on 2026-11-01.

locals {
  folder_iam = {
    "roles/resourcemanager.folderAdmin chris@simplifymy.cloud"  = { role = "roles/resourcemanager.folderAdmin", member = "user:chris@simplifymy.cloud" }
    "roles/resourcemanager.folderEditor chris@simplifymy.cloud" = { role = "roles/resourcemanager.folderEditor", member = "user:chris@simplifymy.cloud" }
  }
}

resource "google_folder_iam_member" "this" {
  for_each = local.folder_iam

  folder = "folders/386439801809"
  role   = each.value.role
  member = each.value.member
}

import {
  for_each = local.folder_iam
  to       = google_folder_iam_member.this[each.key]
  id       = "folders/386439801809 ${each.value.role} ${each.value.member}"
}
