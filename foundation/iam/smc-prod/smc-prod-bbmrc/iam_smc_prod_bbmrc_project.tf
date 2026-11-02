# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-prod / smc-prod-bbmrc — project IAM bindings
# ---------------------------------------------------------------------------------------------------------------------
#
# Every project-level IAM grant on smc-prod-bbmrc at the 2026-11-01 import
# (2 grants). One google_project_iam_member per role + member (additive):
# Terraform owns exactly these grants and nothing else on the policy.
# Google-managed service agents (service-<number>@gcp-sa-*) are included so git
# shows the complete live policy.

locals {
  project_iam = {
    "roles/cloudsecuritycompliance.serviceAgent serviceAccount:service-570081741393@gcp-sa-csc-hpsa.iam.gserviceaccount.com" = { role = "roles/cloudsecuritycompliance.serviceAgent", member = "serviceAccount:service-570081741393@gcp-sa-csc-hpsa.iam.gserviceaccount.com" }
    "roles/owner user:chris@simplifymy.cloud"                                                                                = { role = "roles/owner", member = "user:chris@simplifymy.cloud" }
  }
}

resource "google_project_iam_member" "this" {
  for_each = local.project_iam

  project = "smc-prod-bbmrc"
  role    = each.value.role
  member  = each.value.member
}

import {
  for_each = local.project_iam
  to       = google_project_iam_member.this[each.key]
  id       = "smc-prod-bbmrc ${each.value.role} ${each.value.member}"
}
