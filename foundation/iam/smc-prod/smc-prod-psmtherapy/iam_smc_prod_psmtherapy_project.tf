# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-prod / smc-prod-psmtherapy — project IAM bindings
# ---------------------------------------------------------------------------------------------------------------------
#
# Every project-level IAM grant on smc-prod-psmtherapy at the 2026-11-01 import
# (10 grants). One google_project_iam_member per role + member (additive):
# Terraform owns exactly these grants and nothing else on the policy.
# Google-managed service agents (service-<number>@gcp-sa-*) are included so git
# shows the complete live policy.

locals {
  project_iam = {
    "roles/cloudfunctions.serviceAgent serviceAccount:service-628436475039@gcf-admin-robot.iam.gserviceaccount.com"                = { role = "roles/cloudfunctions.serviceAgent", member = "serviceAccount:service-628436475039@gcf-admin-robot.iam.gserviceaccount.com" }
    "roles/cloudsecuritycompliance.serviceAgent serviceAccount:service-628436475039@gcp-sa-csc-hpsa.iam.gserviceaccount.com"       = { role = "roles/cloudsecuritycompliance.serviceAgent", member = "serviceAccount:service-628436475039@gcp-sa-csc-hpsa.iam.gserviceaccount.com" }
    "roles/editor serviceAccount:628436475039@cloudservices.gserviceaccount.com"                                                   = { role = "roles/editor", member = "serviceAccount:628436475039@cloudservices.gserviceaccount.com" }
    "roles/editor serviceAccount:smc-prod-psmtherapy@appspot.gserviceaccount.com"                                                  = { role = "roles/editor", member = "serviceAccount:smc-prod-psmtherapy@appspot.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com" = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:service-628436475039@gcp-sa-firebase.iam.gserviceaccount.com"            = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:service-628436475039@gcp-sa-firebase.iam.gserviceaccount.com" }
    "roles/firebase.sdkAdminServiceAgent serviceAccount:firebase-adminsdk-zdldb@smc-prod-psmtherapy.iam.gserviceaccount.com"       = { role = "roles/firebase.sdkAdminServiceAgent", member = "serviceAccount:firebase-adminsdk-zdldb@smc-prod-psmtherapy.iam.gserviceaccount.com" }
    "roles/firebaserules.system serviceAccount:service-628436475039@firebase-rules.iam.gserviceaccount.com"                        = { role = "roles/firebaserules.system", member = "serviceAccount:service-628436475039@firebase-rules.iam.gserviceaccount.com" }
    "roles/iam.serviceAccountTokenCreator serviceAccount:firebase-adminsdk-zdldb@smc-prod-psmtherapy.iam.gserviceaccount.com"      = { role = "roles/iam.serviceAccountTokenCreator", member = "serviceAccount:firebase-adminsdk-zdldb@smc-prod-psmtherapy.iam.gserviceaccount.com" }
    "roles/owner user:chris@simplifymy.cloud"                                                                                      = { role = "roles/owner", member = "user:chris@simplifymy.cloud" }
  }
}

resource "google_project_iam_member" "this" {
  for_each = local.project_iam

  project = "smc-prod-psmtherapy"
  role    = each.value.role
  member  = each.value.member
}

import {
  for_each = local.project_iam
  to       = google_project_iam_member.this[each.key]
  id       = "smc-prod-psmtherapy ${each.value.role} ${each.value.member}"
}
