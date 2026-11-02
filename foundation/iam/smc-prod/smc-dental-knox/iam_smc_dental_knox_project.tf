# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-prod / smc-dental-knox — project IAM bindings
# ---------------------------------------------------------------------------------------------------------------------
#
# Every project-level IAM grant on smc-dental-knox at the 2026-11-01 import
# (16 grants). One google_project_iam_member per role + member (additive):
# Terraform owns exactly these grants and nothing else on the policy.
# Google-managed service agents (service-<number>@gcp-sa-*) are included so git
# shows the complete live policy.

locals {
  project_iam = {
    "roles/cloudfunctions.developer serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com"                = { role = "roles/cloudfunctions.developer", member = "serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com" }
    "roles/cloudfunctions.serviceAgent serviceAccount:service-96744263649@gcf-admin-robot.iam.gserviceaccount.com"                 = { role = "roles/cloudfunctions.serviceAgent", member = "serviceAccount:service-96744263649@gcf-admin-robot.iam.gserviceaccount.com" }
    "roles/cloudsecuritycompliance.serviceAgent serviceAccount:service-96744263649@gcp-sa-csc-hpsa.iam.gserviceaccount.com"        = { role = "roles/cloudsecuritycompliance.serviceAgent", member = "serviceAccount:service-96744263649@gcp-sa-csc-hpsa.iam.gserviceaccount.com" }
    "roles/editor serviceAccount:96744263649@cloudservices.gserviceaccount.com"                                                    = { role = "roles/editor", member = "serviceAccount:96744263649@cloudservices.gserviceaccount.com" }
    "roles/editor serviceAccount:smc-dental-knox@appspot.gserviceaccount.com"                                                      = { role = "roles/editor", member = "serviceAccount:smc-dental-knox@appspot.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com" = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:service-96744263649@gcp-sa-firebase.iam.gserviceaccount.com"             = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:service-96744263649@gcp-sa-firebase.iam.gserviceaccount.com" }
    "roles/firebase.sdkAdminServiceAgent serviceAccount:firebase-adminsdk-kcrbg@smc-dental-knox.iam.gserviceaccount.com"           = { role = "roles/firebase.sdkAdminServiceAgent", member = "serviceAccount:firebase-adminsdk-kcrbg@smc-dental-knox.iam.gserviceaccount.com" }
    "roles/firebaseauth.admin serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com"                      = { role = "roles/firebaseauth.admin", member = "serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com" }
    "roles/firebasehosting.admin serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com"                   = { role = "roles/firebasehosting.admin", member = "serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com" }
    "roles/firebaserules.system serviceAccount:service-96744263649@firebase-rules.iam.gserviceaccount.com"                         = { role = "roles/firebaserules.system", member = "serviceAccount:service-96744263649@firebase-rules.iam.gserviceaccount.com" }
    "roles/iam.serviceAccountTokenCreator serviceAccount:firebase-adminsdk-kcrbg@smc-dental-knox.iam.gserviceaccount.com"          = { role = "roles/iam.serviceAccountTokenCreator", member = "serviceAccount:firebase-adminsdk-kcrbg@smc-dental-knox.iam.gserviceaccount.com" }
    "roles/owner user:chris@simplifymy.cloud"                                                                                      = { role = "roles/owner", member = "user:chris@simplifymy.cloud" }
    "roles/run.viewer serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com"                              = { role = "roles/run.viewer", member = "serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com" }
    "roles/serviceusage.apiKeysViewer serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com"              = { role = "roles/serviceusage.apiKeysViewer", member = "serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com" }
    "roles/serviceusage.serviceUsageConsumer serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com"       = { role = "roles/serviceusage.serviceUsageConsumer", member = "serviceAccount:github-action-710542866@smc-dental-knox.iam.gserviceaccount.com" }
  }
}

resource "google_project_iam_member" "this" {
  for_each = local.project_iam

  project = "smc-dental-knox"
  role    = each.value.role
  member  = each.value.member
}

import {
  for_each = local.project_iam
  to       = google_project_iam_member.this[each.key]
  id       = "smc-dental-knox ${each.value.role} ${each.value.member}"
}
