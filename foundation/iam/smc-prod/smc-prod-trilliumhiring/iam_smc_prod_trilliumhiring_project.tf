# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-prod / smc-prod-trilliumhiring — project IAM bindings
# ---------------------------------------------------------------------------------------------------------------------
#
# Every project-level IAM grant on smc-prod-trilliumhiring at the 2026-11-01 import
# (12 grants). One google_project_iam_member per role + member (additive):
# Terraform owns exactly these grants and nothing else on the policy.
# Google-managed service agents (service-<number>@gcp-sa-*) are included so git
# shows the complete live policy.

locals {
  project_iam = {
    "roles/cloudfunctions.serviceAgent serviceAccount:service-583903799463@gcf-admin-robot.iam.gserviceaccount.com"                = { role = "roles/cloudfunctions.serviceAgent", member = "serviceAccount:service-583903799463@gcf-admin-robot.iam.gserviceaccount.com" }
    "roles/cloudsecuritycompliance.serviceAgent serviceAccount:service-583903799463@gcp-sa-csc-hpsa.iam.gserviceaccount.com"       = { role = "roles/cloudsecuritycompliance.serviceAgent", member = "serviceAccount:service-583903799463@gcp-sa-csc-hpsa.iam.gserviceaccount.com" }
    "roles/compute.serviceAgent serviceAccount:service-583903799463@compute-system.iam.gserviceaccount.com"                        = { role = "roles/compute.serviceAgent", member = "serviceAccount:service-583903799463@compute-system.iam.gserviceaccount.com" }
    "roles/editor serviceAccount:583903799463-compute@developer.gserviceaccount.com"                                               = { role = "roles/editor", member = "serviceAccount:583903799463-compute@developer.gserviceaccount.com" }
    "roles/editor serviceAccount:583903799463@cloudservices.gserviceaccount.com"                                                   = { role = "roles/editor", member = "serviceAccount:583903799463@cloudservices.gserviceaccount.com" }
    "roles/editor serviceAccount:smc-prod-trilliumhiring@appspot.gserviceaccount.com"                                              = { role = "roles/editor", member = "serviceAccount:smc-prod-trilliumhiring@appspot.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com" = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:service-583903799463@gcp-sa-firebase.iam.gserviceaccount.com"            = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:service-583903799463@gcp-sa-firebase.iam.gserviceaccount.com" }
    "roles/firebase.sdkAdminServiceAgent serviceAccount:firebase-adminsdk-k820k@smc-prod-trilliumhiring.iam.gserviceaccount.com"   = { role = "roles/firebase.sdkAdminServiceAgent", member = "serviceAccount:firebase-adminsdk-k820k@smc-prod-trilliumhiring.iam.gserviceaccount.com" }
    "roles/firebaserules.system serviceAccount:service-583903799463@firebase-rules.iam.gserviceaccount.com"                        = { role = "roles/firebaserules.system", member = "serviceAccount:service-583903799463@firebase-rules.iam.gserviceaccount.com" }
    "roles/iam.serviceAccountTokenCreator serviceAccount:firebase-adminsdk-k820k@smc-prod-trilliumhiring.iam.gserviceaccount.com"  = { role = "roles/iam.serviceAccountTokenCreator", member = "serviceAccount:firebase-adminsdk-k820k@smc-prod-trilliumhiring.iam.gserviceaccount.com" }
    "roles/owner user:chris@simplifymy.cloud"                                                                                      = { role = "roles/owner", member = "user:chris@simplifymy.cloud" }
  }
}

resource "google_project_iam_member" "this" {
  for_each = local.project_iam

  project = "smc-prod-trilliumhiring"
  role    = each.value.role
  member  = each.value.member
}

import {
  for_each = local.project_iam
  to       = google_project_iam_member.this[each.key]
  id       = "smc-prod-trilliumhiring ${each.value.role} ${each.value.member}"
}
