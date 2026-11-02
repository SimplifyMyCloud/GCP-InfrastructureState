# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-prod / smc-prod-olympic-flying-club — project IAM bindings
# ---------------------------------------------------------------------------------------------------------------------
#
# Every project-level IAM grant on smc-prod-olympic-flying-club at the 2026-11-01 import
# (8 grants). One google_project_iam_member per role + member (additive):
# Terraform owns exactly these grants and nothing else on the policy.
# Google-managed service agents (service-<number>@gcp-sa-*) are included so git
# shows the complete live policy.

locals {
  project_iam = {
    "roles/cloudsecuritycompliance.serviceAgent serviceAccount:service-368048532063@gcp-sa-csc-hpsa.iam.gserviceaccount.com"           = { role = "roles/cloudsecuritycompliance.serviceAgent", member = "serviceAccount:service-368048532063@gcp-sa-csc-hpsa.iam.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com"     = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:service-368048532063@gcp-sa-firebase.iam.gserviceaccount.com"                = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:service-368048532063@gcp-sa-firebase.iam.gserviceaccount.com" }
    "roles/firebase.sdkAdminServiceAgent serviceAccount:firebase-adminsdk-ntgml@smc-prod-olympic-flying-club.iam.gserviceaccount.com"  = { role = "roles/firebase.sdkAdminServiceAgent", member = "serviceAccount:firebase-adminsdk-ntgml@smc-prod-olympic-flying-club.iam.gserviceaccount.com" }
    "roles/firebaserules.system serviceAccount:service-368048532063@firebase-rules.iam.gserviceaccount.com"                            = { role = "roles/firebaserules.system", member = "serviceAccount:service-368048532063@firebase-rules.iam.gserviceaccount.com" }
    "roles/iam.serviceAccountTokenCreator serviceAccount:firebase-adminsdk-ntgml@smc-prod-olympic-flying-club.iam.gserviceaccount.com" = { role = "roles/iam.serviceAccountTokenCreator", member = "serviceAccount:firebase-adminsdk-ntgml@smc-prod-olympic-flying-club.iam.gserviceaccount.com" }
    "roles/owner user:chris@simplifymy.cloud"                                                                                          = { role = "roles/owner", member = "user:chris@simplifymy.cloud" }
    "roles/pubsub.serviceAgent serviceAccount:service-368048532063@gcp-sa-pubsub.iam.gserviceaccount.com"                              = { role = "roles/pubsub.serviceAgent", member = "serviceAccount:service-368048532063@gcp-sa-pubsub.iam.gserviceaccount.com" }
  }
}

resource "google_project_iam_member" "this" {
  for_each = local.project_iam

  project = "smc-prod-olympic-flying-club"
  role    = each.value.role
  member  = each.value.member
}

import {
  for_each = local.project_iam
  to       = google_project_iam_member.this[each.key]
  id       = "smc-prod-olympic-flying-club ${each.value.role} ${each.value.member}"
}
