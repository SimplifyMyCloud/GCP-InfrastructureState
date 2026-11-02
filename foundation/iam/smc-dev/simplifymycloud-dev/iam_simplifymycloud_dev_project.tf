# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-dev / simplifymycloud-dev — project IAM bindings
# ---------------------------------------------------------------------------------------------------------------------
#
# Every project-level IAM grant on simplifymycloud-dev at the 2026-11-01 import
# (74 grants). One google_project_iam_member per role + member (additive):
# Terraform owns exactly these grants and nothing else on the policy.
# Google-managed service agents (service-<number>@gcp-sa-*) are included so git
# shows the complete live policy.

locals {
  project_iam = {
    "roles/accesscontextmanager.policyEditor serviceAccount:288261943767-compute@developer.gserviceaccount.com"                    = { role = "roles/accesscontextmanager.policyEditor", member = "serviceAccount:288261943767-compute@developer.gserviceaccount.com" }
    "roles/aiplatform.customCodeServiceAgent serviceAccount:service-288261943767@gcp-sa-aiplatform-cc.iam.gserviceaccount.com"     = { role = "roles/aiplatform.customCodeServiceAgent", member = "serviceAccount:service-288261943767@gcp-sa-aiplatform-cc.iam.gserviceaccount.com" }
    "roles/aiplatform.serviceAgent serviceAccount:service-288261943767@gcp-sa-aiplatform.iam.gserviceaccount.com"                  = { role = "roles/aiplatform.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-aiplatform.iam.gserviceaccount.com" }
    "roles/appengine.serviceAgent serviceAccount:service-288261943767@gcp-gae-service.iam.gserviceaccount.com"                     = { role = "roles/appengine.serviceAgent", member = "serviceAccount:service-288261943767@gcp-gae-service.iam.gserviceaccount.com" }
    "roles/appengineflex.serviceAgent serviceAccount:service-288261943767@gae-api-prod.google.com.iam.gserviceaccount.com"         = { role = "roles/appengineflex.serviceAgent", member = "serviceAccount:service-288261943767@gae-api-prod.google.com.iam.gserviceaccount.com" }
    "roles/artifactregistry.serviceAgent serviceAccount:service-288261943767@gcp-sa-artifactregistry.iam.gserviceaccount.com"      = { role = "roles/artifactregistry.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-artifactregistry.iam.gserviceaccount.com" }
    "roles/auditmanager.serviceAgent serviceAccount:service-288261943767@gcp-sa-audit-manager.iam.gserviceaccount.com"             = { role = "roles/auditmanager.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-audit-manager.iam.gserviceaccount.com" }
    "roles/bigquery.jobUser serviceAccount:phishing-dashboard-app@simplifymycloud-dev.iam.gserviceaccount.com"                     = { role = "roles/bigquery.jobUser", member = "serviceAccount:phishing-dashboard-app@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/cloudaicompanion.serviceAgent serviceAccount:service-288261943767@gcp-sa-cloudaicompanion.iam.gserviceaccount.com"      = { role = "roles/cloudaicompanion.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-cloudaicompanion.iam.gserviceaccount.com" }
    "roles/cloudaicompanion.user user:chris@simplifymy.cloud"                                                                      = { role = "roles/cloudaicompanion.user", member = "user:chris@simplifymy.cloud" }
    "roles/cloudbuild.builds.builder serviceAccount:288261943767@cloudbuild.gserviceaccount.com"                                   = { role = "roles/cloudbuild.builds.builder", member = "serviceAccount:288261943767@cloudbuild.gserviceaccount.com" }
    "roles/cloudbuild.serviceAgent serviceAccount:service-288261943767@gcp-sa-cloudbuild.iam.gserviceaccount.com"                  = { role = "roles/cloudbuild.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-cloudbuild.iam.gserviceaccount.com" }
    "roles/cloudconfig.serviceAgent serviceAccount:service-288261943767@gcp-sa-config.iam.gserviceaccount.com"                     = { role = "roles/cloudconfig.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-config.iam.gserviceaccount.com" }
    "roles/cloudfunctions.serviceAgent serviceAccount:service-288261943767@gcf-admin-robot.iam.gserviceaccount.com"                = { role = "roles/cloudfunctions.serviceAgent", member = "serviceAccount:service-288261943767@gcf-admin-robot.iam.gserviceaccount.com" }
    "roles/cloudkms.serviceAgent serviceAccount:service-288261943767@gcp-sa-cloudkms.iam.gserviceaccount.com"                      = { role = "roles/cloudkms.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-cloudkms.iam.gserviceaccount.com" }
    "roles/cloudsecuritycompliance.serviceAgent serviceAccount:service-288261943767@gcp-sa-csc-hpsa.iam.gserviceaccount.com"       = { role = "roles/cloudsecuritycompliance.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-csc-hpsa.iam.gserviceaccount.com" }
    "roles/compute.admin serviceAccount:288261943767@cloudbuild.gserviceaccount.com"                                               = { role = "roles/compute.admin", member = "serviceAccount:288261943767@cloudbuild.gserviceaccount.com" }
    "roles/compute.admin serviceAccount:simplifymycloud-dev-sa@simplifymycloud-dev.iam.gserviceaccount.com"                        = { role = "roles/compute.admin", member = "serviceAccount:simplifymycloud-dev-sa@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/compute.instanceAdmin.v1 serviceAccount:simplifymycloud-dev-sa@simplifymycloud-dev.iam.gserviceaccount.com"             = { role = "roles/compute.instanceAdmin.v1", member = "serviceAccount:simplifymycloud-dev-sa@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/compute.instanceAdmin.v1 serviceAccount:smc-packer-sa@simplifymycloud-dev.iam.gserviceaccount.com"                      = { role = "roles/compute.instanceAdmin.v1", member = "serviceAccount:smc-packer-sa@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/compute.networkUser serviceAccount:org-svcops-svc-admin-sa-rw@simplifymycloud-dev.iam.gserviceaccount.com"              = { role = "roles/compute.networkUser", member = "serviceAccount:org-svcops-svc-admin-sa-rw@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/compute.serviceAgent serviceAccount:service-288261943767@compute-system.iam.gserviceaccount.com"                        = { role = "roles/compute.serviceAgent", member = "serviceAccount:service-288261943767@compute-system.iam.gserviceaccount.com" }
    "roles/compute.storageAdmin serviceAccount:288261943767-compute@developer.gserviceaccount.com"                                 = { role = "roles/compute.storageAdmin", member = "serviceAccount:288261943767-compute@developer.gserviceaccount.com" }
    "roles/container.admin serviceAccount:288261943767@cloudbuild.gserviceaccount.com"                                             = { role = "roles/container.admin", member = "serviceAccount:288261943767@cloudbuild.gserviceaccount.com" }
    "roles/container.defaultNodeServiceAgent serviceAccount:service-288261943767@gcp-sa-gkenode.iam.gserviceaccount.com"           = { role = "roles/container.defaultNodeServiceAgent", member = "serviceAccount:service-288261943767@gcp-sa-gkenode.iam.gserviceaccount.com" }
    "roles/container.serviceAgent serviceAccount:service-288261943767@container-engine-robot.iam.gserviceaccount.com"              = { role = "roles/container.serviceAgent", member = "serviceAccount:service-288261943767@container-engine-robot.iam.gserviceaccount.com" }
    "roles/containeranalysis.ServiceAgent serviceAccount:service-288261943767@container-analysis.iam.gserviceaccount.com"          = { role = "roles/containeranalysis.ServiceAgent", member = "serviceAccount:service-288261943767@container-analysis.iam.gserviceaccount.com" }
    "roles/containerregistry.ServiceAgent serviceAccount:288261943767-compute@developer.gserviceaccount.com"                       = { role = "roles/containerregistry.ServiceAgent", member = "serviceAccount:288261943767-compute@developer.gserviceaccount.com" }
    "roles/containerscanning.ServiceAgent serviceAccount:service-288261943767@gcp-sa-containerscanning.iam.gserviceaccount.com"    = { role = "roles/containerscanning.ServiceAgent", member = "serviceAccount:service-288261943767@gcp-sa-containerscanning.iam.gserviceaccount.com" }
    "roles/dataflow.serviceAgent serviceAccount:service-288261943767@dataflow-service-producer-prod.iam.gserviceaccount.com"       = { role = "roles/dataflow.serviceAgent", member = "serviceAccount:service-288261943767@dataflow-service-producer-prod.iam.gserviceaccount.com" }
    "roles/dataproc.serviceAgent serviceAccount:service-288261943767@dataproc-accounts.iam.gserviceaccount.com"                    = { role = "roles/dataproc.serviceAgent", member = "serviceAccount:service-288261943767@dataproc-accounts.iam.gserviceaccount.com" }
    "roles/discoveryengine.serviceAgent serviceAccount:service-288261943767@gcp-sa-discoveryengine.iam.gserviceaccount.com"        = { role = "roles/discoveryengine.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-discoveryengine.iam.gserviceaccount.com" }
    "roles/editor serviceAccount:288261943767-compute@developer.gserviceaccount.com"                                               = { role = "roles/editor", member = "serviceAccount:288261943767-compute@developer.gserviceaccount.com" }
    "roles/editor serviceAccount:288261943767@cloudbuild.gserviceaccount.com"                                                      = { role = "roles/editor", member = "serviceAccount:288261943767@cloudbuild.gserviceaccount.com" }
    "roles/editor serviceAccount:288261943767@cloudservices.gserviceaccount.com"                                                   = { role = "roles/editor", member = "serviceAccount:288261943767@cloudservices.gserviceaccount.com" }
    "roles/editor serviceAccount:gcp-project-owner-test-sa@simplifymycloud-dev.iam.gserviceaccount.com"                            = { role = "roles/editor", member = "serviceAccount:gcp-project-owner-test-sa@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/editor serviceAccount:service-288261943767@containerregistry.iam.gserviceaccount.com"                                   = { role = "roles/editor", member = "serviceAccount:service-288261943767@containerregistry.iam.gserviceaccount.com" }
    "roles/editor serviceAccount:simplifymycloud-dev-sa@simplifymycloud-dev.iam.gserviceaccount.com"                               = { role = "roles/editor", member = "serviceAccount:simplifymycloud-dev-sa@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/editor serviceAccount:simplifymycloud-dev@appspot.gserviceaccount.com"                                                  = { role = "roles/editor", member = "serviceAccount:simplifymycloud-dev@appspot.gserviceaccount.com" }
    "roles/file.serviceAgent serviceAccount:service-288261943767@cloud-filer.iam.gserviceaccount.com"                              = { role = "roles/file.serviceAgent", member = "serviceAccount:service-288261943767@cloud-filer.iam.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com" = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:firebase-service-account@firebase-sa-management.iam.gserviceaccount.com" }
    "roles/firebase.managementServiceAgent serviceAccount:service-288261943767@gcp-sa-firebase.iam.gserviceaccount.com"            = { role = "roles/firebase.managementServiceAgent", member = "serviceAccount:service-288261943767@gcp-sa-firebase.iam.gserviceaccount.com" }
    "roles/firebaserules.system serviceAccount:service-288261943767@firebase-rules.iam.gserviceaccount.com"                        = { role = "roles/firebaserules.system", member = "serviceAccount:service-288261943767@firebase-rules.iam.gserviceaccount.com" }
    "roles/firestore.serviceAgent serviceAccount:service-288261943767@gcp-sa-firestore.iam.gserviceaccount.com"                    = { role = "roles/firestore.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-firestore.iam.gserviceaccount.com" }
    "roles/iam.serviceAccountUser serviceAccount:288261943767@cloudbuild.gserviceaccount.com"                                      = { role = "roles/iam.serviceAccountUser", member = "serviceAccount:288261943767@cloudbuild.gserviceaccount.com" }
    "roles/iam.serviceAccountUser serviceAccount:288261943767@cloudservices.gserviceaccount.com"                                   = { role = "roles/iam.serviceAccountUser", member = "serviceAccount:288261943767@cloudservices.gserviceaccount.com" }
    "roles/iam.serviceAccountUser serviceAccount:simplifymycloud-dev-sa@simplifymycloud-dev.iam.gserviceaccount.com"               = { role = "roles/iam.serviceAccountUser", member = "serviceAccount:simplifymycloud-dev-sa@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/iam.serviceAccountUser serviceAccount:smc-packer-sa@simplifymycloud-dev.iam.gserviceaccount.com"                        = { role = "roles/iam.serviceAccountUser", member = "serviceAccount:smc-packer-sa@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/iap.admin user:chris@simplifymy.cloud"                                                                                  = { role = "roles/iap.admin", member = "user:chris@simplifymy.cloud" }
    "roles/iap.tunnelResourceAccessor serviceAccount:smc-packer-sa@simplifymycloud-dev.iam.gserviceaccount.com"                    = { role = "roles/iap.tunnelResourceAccessor", member = "serviceAccount:smc-packer-sa@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/iap.tunnelResourceAccessor user:chris@simplifymy.cloud"                                                                 = { role = "roles/iap.tunnelResourceAccessor", member = "user:chris@simplifymy.cloud" }
    "roles/logging.privateLogViewer user:chris@simplifymy.cloud"                                                                   = { role = "roles/logging.privateLogViewer", member = "user:chris@simplifymy.cloud" }
    "roles/logging.serviceAgent serviceAccount:service-288261943767@gcp-sa-logging.iam.gserviceaccount.com"                        = { role = "roles/logging.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-logging.iam.gserviceaccount.com" }
    "roles/logging.viewer user:chris@simplifymy.cloud"                                                                             = { role = "roles/logging.viewer", member = "user:chris@simplifymy.cloud" }
    "roles/managedidentities.serviceAgent serviceAccount:service-288261943767@gcp-sa-mi.iam.gserviceaccount.com"                   = { role = "roles/managedidentities.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-mi.iam.gserviceaccount.com" }
    "roles/networkmanagement.serviceAgent serviceAccount:service-288261943767@gcp-sa-networkmanagement.iam.gserviceaccount.com"    = { role = "roles/networkmanagement.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-networkmanagement.iam.gserviceaccount.com" }
    "roles/notebooks.serviceAgent serviceAccount:service-288261943767@gcp-sa-notebooks.iam.gserviceaccount.com"                    = { role = "roles/notebooks.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-notebooks.iam.gserviceaccount.com" }
    "roles/osconfig.serviceAgent serviceAccount:service-288261943767@gcp-sa-osconfig.iam.gserviceaccount.com"                      = { role = "roles/osconfig.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-osconfig.iam.gserviceaccount.com" }
    "roles/owner user:chris@simplifymy.cloud"                                                                                      = { role = "roles/owner", member = "user:chris@simplifymy.cloud" }
    "roles/redis.serviceAgent serviceAccount:service-288261943767@cloud-redis.iam.gserviceaccount.com"                             = { role = "roles/redis.serviceAgent", member = "serviceAccount:service-288261943767@cloud-redis.iam.gserviceaccount.com" }
    "roles/run.admin serviceAccount:288261943767@cloudbuild.gserviceaccount.com"                                                   = { role = "roles/run.admin", member = "serviceAccount:288261943767@cloudbuild.gserviceaccount.com" }
    "roles/run.serviceAgent serviceAccount:service-288261943767@serverless-robot-prod.iam.gserviceaccount.com"                     = { role = "roles/run.serviceAgent", member = "serviceAccount:service-288261943767@serverless-robot-prod.iam.gserviceaccount.com" }
    "roles/run.viewer serviceAccount:288261943767-compute@developer.gserviceaccount.com"                                           = { role = "roles/run.viewer", member = "serviceAccount:288261943767-compute@developer.gserviceaccount.com" }
    "roles/servicenetworking.serviceAgent serviceAccount:service-288261943767@service-networking.iam.gserviceaccount.com"          = { role = "roles/servicenetworking.serviceAgent", member = "serviceAccount:service-288261943767@service-networking.iam.gserviceaccount.com" }
    "roles/serviceusage.serviceUsageConsumer user:chris@simplifymy.cloud"                                                          = { role = "roles/serviceusage.serviceUsageConsumer", member = "user:chris@simplifymy.cloud" }
    "roles/serviceusage.serviceUsageViewer user:chris@simplifymy.cloud"                                                            = { role = "roles/serviceusage.serviceUsageViewer", member = "user:chris@simplifymy.cloud" }
    "roles/sourcerepo.serviceAgent serviceAccount:service-288261943767@sourcerepo-service-accounts.iam.gserviceaccount.com"        = { role = "roles/sourcerepo.serviceAgent", member = "serviceAccount:service-288261943767@sourcerepo-service-accounts.iam.gserviceaccount.com" }
    "roles/storage.admin serviceAccount:288261943767-compute@developer.gserviceaccount.com"                                        = { role = "roles/storage.admin", member = "serviceAccount:288261943767-compute@developer.gserviceaccount.com" }
    "roles/storage.admin serviceAccount:288261943767@cloudservices.gserviceaccount.com"                                            = { role = "roles/storage.admin", member = "serviceAccount:288261943767@cloudservices.gserviceaccount.com" }
    "roles/storage.objectViewer serviceAccount:simplifymycloud-dev-sa@simplifymycloud-dev.iam.gserviceaccount.com"                 = { role = "roles/storage.objectViewer", member = "serviceAccount:simplifymycloud-dev-sa@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/viewer serviceAccount:smc-packer-sa@simplifymycloud-dev.iam.gserviceaccount.com"                                        = { role = "roles/viewer", member = "serviceAccount:smc-packer-sa@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/vmwareengine.serviceAgent serviceAccount:service-288261943767@gcp-sa-vmwareengine.iam.gserviceaccount.com"              = { role = "roles/vmwareengine.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-vmwareengine.iam.gserviceaccount.com" }
    "roles/websecurityscanner.serviceAgent serviceAccount:service-288261943767@gcp-sa-websecurityscanner.iam.gserviceaccount.com"  = { role = "roles/websecurityscanner.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-websecurityscanner.iam.gserviceaccount.com" }
    "roles/workstations.serviceAgent serviceAccount:service-288261943767@gcp-sa-workstations.iam.gserviceaccount.com"              = { role = "roles/workstations.serviceAgent", member = "serviceAccount:service-288261943767@gcp-sa-workstations.iam.gserviceaccount.com" }
  }
}

resource "google_project_iam_member" "this" {
  for_each = local.project_iam

  project = "simplifymycloud-dev"
  role    = each.value.role
  member  = each.value.member
}

import {
  for_each = local.project_iam
  to       = google_project_iam_member.this[each.key]
  id       = "simplifymycloud-dev ${each.value.role} ${each.value.member}"
}
