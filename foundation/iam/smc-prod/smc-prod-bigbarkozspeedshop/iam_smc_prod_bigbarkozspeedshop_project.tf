# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-prod / smc-prod-bigbarkozspeedshop — project IAM bindings
# ---------------------------------------------------------------------------------------------------------------------
#
# Every project-level IAM grant on smc-prod-bigbarkozspeedshop at the 2026-11-01 import
# (18 grants). One google_project_iam_member per role + member (additive):
# Terraform owns exactly these grants and nothing else on the policy.
# Google-managed service agents (service-<number>@gcp-sa-*) are included so git
# shows the complete live policy.

locals {
  project_iam = {
    "roles/appengine.serviceAgent serviceAccount:service-1059488236225@gcp-gae-service.iam.gserviceaccount.com"                       = { role = "roles/appengine.serviceAgent", member = "serviceAccount:service-1059488236225@gcp-gae-service.iam.gserviceaccount.com" }
    "roles/cloudbuild.builds.builder serviceAccount:1059488236225@cloudbuild.gserviceaccount.com"                                     = { role = "roles/cloudbuild.builds.builder", member = "serviceAccount:1059488236225@cloudbuild.gserviceaccount.com" }
    "roles/cloudbuild.serviceAgent serviceAccount:service-1059488236225@gcp-sa-cloudbuild.iam.gserviceaccount.com"                    = { role = "roles/cloudbuild.serviceAgent", member = "serviceAccount:service-1059488236225@gcp-sa-cloudbuild.iam.gserviceaccount.com" }
    "roles/cloudfunctions.serviceAgent serviceAccount:service-1059488236225@gcf-admin-robot.iam.gserviceaccount.com"                  = { role = "roles/cloudfunctions.serviceAgent", member = "serviceAccount:service-1059488236225@gcf-admin-robot.iam.gserviceaccount.com" }
    "roles/cloudsecuritycompliance.serviceAgent serviceAccount:service-1059488236225@gcp-sa-csc-hpsa.iam.gserviceaccount.com"         = { role = "roles/cloudsecuritycompliance.serviceAgent", member = "serviceAccount:service-1059488236225@gcp-sa-csc-hpsa.iam.gserviceaccount.com" }
    "roles/compute.serviceAgent serviceAccount:service-1059488236225@compute-system.iam.gserviceaccount.com"                          = { role = "roles/compute.serviceAgent", member = "serviceAccount:service-1059488236225@compute-system.iam.gserviceaccount.com" }
    "roles/editor serviceAccount:1059488236225-compute@developer.gserviceaccount.com"                                                 = { role = "roles/editor", member = "serviceAccount:1059488236225-compute@developer.gserviceaccount.com" }
    "roles/editor serviceAccount:1059488236225@cloudservices.gserviceaccount.com"                                                     = { role = "roles/editor", member = "serviceAccount:1059488236225@cloudservices.gserviceaccount.com" }
    "roles/editor serviceAccount:service-1059488236225@containerregistry.iam.gserviceaccount.com"                                     = { role = "roles/editor", member = "serviceAccount:service-1059488236225@containerregistry.iam.gserviceaccount.com" }
    "roles/editor serviceAccount:smc-prod-bigbarkozspeedshop@appspot.gserviceaccount.com"                                             = { role = "roles/editor", member = "serviceAccount:smc-prod-bigbarkozspeedshop@appspot.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com"    = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:service-1059488236225@gcp-sa-firebase.iam.gserviceaccount.com"              = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:service-1059488236225@gcp-sa-firebase.iam.gserviceaccount.com" }
    "roles/firebase.sdkAdminServiceAgent serviceAccount:firebase-adminsdk-qz5kp@smc-prod-bigbarkozspeedshop.iam.gserviceaccount.com"  = { role = "roles/firebase.sdkAdminServiceAgent", member = "serviceAccount:firebase-adminsdk-qz5kp@smc-prod-bigbarkozspeedshop.iam.gserviceaccount.com" }
    "roles/firebaserules.system serviceAccount:service-1059488236225@firebase-rules.iam.gserviceaccount.com"                          = { role = "roles/firebaserules.system", member = "serviceAccount:service-1059488236225@firebase-rules.iam.gserviceaccount.com" }
    "roles/firestore.serviceAgent serviceAccount:service-1059488236225@gcp-sa-firestore.iam.gserviceaccount.com"                      = { role = "roles/firestore.serviceAgent", member = "serviceAccount:service-1059488236225@gcp-sa-firestore.iam.gserviceaccount.com" }
    "roles/iam.serviceAccountTokenCreator serviceAccount:firebase-adminsdk-qz5kp@smc-prod-bigbarkozspeedshop.iam.gserviceaccount.com" = { role = "roles/iam.serviceAccountTokenCreator", member = "serviceAccount:firebase-adminsdk-qz5kp@smc-prod-bigbarkozspeedshop.iam.gserviceaccount.com" }
    "roles/iam.serviceAccountUser serviceAccount:1059488236225@cloudbuild.gserviceaccount.com"                                        = { role = "roles/iam.serviceAccountUser", member = "serviceAccount:1059488236225@cloudbuild.gserviceaccount.com" }
    "roles/owner user:chris@simplifymy.cloud"                                                                                         = { role = "roles/owner", member = "user:chris@simplifymy.cloud" }
  }
}

resource "google_project_iam_member" "this" {
  for_each = local.project_iam

  project = "smc-prod-bigbarkozspeedshop"
  role    = each.value.role
  member  = each.value.member
}

import {
  for_each = local.project_iam
  to       = google_project_iam_member.this[each.key]
  id       = "smc-prod-bigbarkozspeedshop ${each.value.role} ${each.value.member}"
}
