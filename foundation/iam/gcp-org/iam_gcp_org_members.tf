# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — gcp-org — organization IAM bindings (simplifymy.cloud, 933250405420)
# ---------------------------------------------------------------------------------------------------------------------
#
# Every org-level IAM grant, one google_organization_iam_member per
# role + member (additive). Grouped by WHO holds the grant so the whiteboard
# question "who can do what at the top of the Org" is answered by reading the
# group headers.
#
# Imported from the live Org on 2026-11-01. No grant here has an IAM condition.

locals {
  # Human users (direct grants).
  org_iam_humans = {
    "roles/cloudbuild.builds.builder user:chris@simplifymy.cloud"           = { role = "roles/cloudbuild.builds.builder", member = "user:chris@simplifymy.cloud" }
    "roles/cloudkms.admin user:chris@simplifymy.cloud"                      = { role = "roles/cloudkms.admin", member = "user:chris@simplifymy.cloud" }
    "roles/cloudsql.admin user:chris@simplifymy.cloud"                      = { role = "roles/cloudsql.admin", member = "user:chris@simplifymy.cloud" }
    "roles/compute.admin user:chris@simplifymy.cloud"                       = { role = "roles/compute.admin", member = "user:chris@simplifymy.cloud" }
    "roles/container.admin user:chris@simplifymy.cloud"                     = { role = "roles/container.admin", member = "user:chris@simplifymy.cloud" }
    "roles/container.clusterAdmin user:chris@simplifymy.cloud"              = { role = "roles/container.clusterAdmin", member = "user:chris@simplifymy.cloud" }
    "roles/containeranalysis.admin user:chris@simplifymy.cloud"             = { role = "roles/containeranalysis.admin", member = "user:chris@simplifymy.cloud" }
    "roles/dataflow.admin user:chris@simplifymy.cloud"                      = { role = "roles/dataflow.admin", member = "user:chris@simplifymy.cloud" }
    "roles/dns.admin user:chris@simplifymy.cloud"                           = { role = "roles/dns.admin", member = "user:chris@simplifymy.cloud" }
    "roles/iam.organizationRoleAdmin user:chris@simplifymy.cloud"           = { role = "roles/iam.organizationRoleAdmin", member = "user:chris@simplifymy.cloud" }
    "roles/iap.admin user:chris@simplifymy.cloud"                           = { role = "roles/iap.admin", member = "user:chris@simplifymy.cloud" }
    "roles/iap.tunnelResourceAccessor user:chris@simplifymy.cloud"          = { role = "roles/iap.tunnelResourceAccessor", member = "user:chris@simplifymy.cloud" }
    "roles/logging.admin user:chris@simplifymy.cloud"                       = { role = "roles/logging.admin", member = "user:chris@simplifymy.cloud" }
    "roles/monitoring.admin user:chris@simplifymy.cloud"                    = { role = "roles/monitoring.admin", member = "user:chris@simplifymy.cloud" }
    "roles/orgpolicy.policyAdmin user:chris@simplifymy.cloud"               = { role = "roles/orgpolicy.policyAdmin", member = "user:chris@simplifymy.cloud" }
    "roles/owner user:chris@simplifymy.cloud"                               = { role = "roles/owner", member = "user:chris@simplifymy.cloud" }
    "roles/pubsub.admin user:chris@simplifymy.cloud"                        = { role = "roles/pubsub.admin", member = "user:chris@simplifymy.cloud" }
    "roles/resourcemanager.folderAdmin user:chris@simplifymy.cloud"         = { role = "roles/resourcemanager.folderAdmin", member = "user:chris@simplifymy.cloud" }
    "roles/resourcemanager.folderIamAdmin user:chris@simplifymy.cloud"      = { role = "roles/resourcemanager.folderIamAdmin", member = "user:chris@simplifymy.cloud" }
    "roles/resourcemanager.organizationAdmin user:chris@simplifymy.cloud"   = { role = "roles/resourcemanager.organizationAdmin", member = "user:chris@simplifymy.cloud" }
    "roles/resourcemanager.organizationViewer user:chris@simplifymy.cloud"  = { role = "roles/resourcemanager.organizationViewer", member = "user:chris@simplifymy.cloud" }
    "roles/resourcemanager.projectIamAdmin user:chris@simplifymy.cloud"     = { role = "roles/resourcemanager.projectIamAdmin", member = "user:chris@simplifymy.cloud" }
    "roles/servicemanagement.quotaAdmin user:chris@simplifymy.cloud"        = { role = "roles/servicemanagement.quotaAdmin", member = "user:chris@simplifymy.cloud" }
    "roles/servicemanagement.quotaViewer user:chris@simplifymy.cloud"       = { role = "roles/servicemanagement.quotaViewer", member = "user:chris@simplifymy.cloud" }
    "roles/servicemanagement.serviceController user:chris@simplifymy.cloud" = { role = "roles/servicemanagement.serviceController", member = "user:chris@simplifymy.cloud" }
  }

  # Everyone in the simplifymy.cloud Cloud Identity domain.
  org_iam_domain = {
    "roles/billing.creator domain:simplifymy.cloud"                = { role = "roles/billing.creator", member = "domain:simplifymy.cloud" }
    "roles/resourcemanager.projectCreator domain:simplifymy.cloud" = { role = "roles/resourcemanager.projectCreator", member = "domain:simplifymy.cloud" }
  }

  # cis-ig1-auditor: read-only CIS IG1 auditor SA (lives in simplifymycloud-dev).
  org_iam_auditor = {
    "organizations/933250405420/roles/cisIg1Audit2IapReader serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"     = { role = "organizations/933250405420/roles/cisIg1Audit2IapReader", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "organizations/933250405420/roles/cisIg1Audit2KeyReader serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"     = { role = "organizations/933250405420/roles/cisIg1Audit2KeyReader", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "organizations/933250405420/roles/cisIg1Audit2StorageReader serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" = { role = "organizations/933250405420/roles/cisIg1Audit2StorageReader", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/accesscontextmanager.policyReader serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                    = { role = "roles/accesscontextmanager.policyReader", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/artifactregistry.reader serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                              = { role = "roles/artifactregistry.reader", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/bigquery.metadataViewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                              = { role = "roles/bigquery.metadataViewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/binaryauthorization.policyViewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                     = { role = "roles/binaryauthorization.policyViewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/browser serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                              = { role = "roles/browser", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/cloudasset.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                    = { role = "roles/cloudasset.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/cloudfunctions.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                = { role = "roles/cloudfunctions.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/cloudkms.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                      = { role = "roles/cloudkms.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/cloudsecurityscanner.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                          = { role = "roles/cloudsecurityscanner.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/cloudsql.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                      = { role = "roles/cloudsql.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/compute.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                       = { role = "roles/compute.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/container.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                     = { role = "roles/container.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/datastore.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                     = { role = "roles/datastore.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/dns.reader serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                           = { role = "roles/dns.reader", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/essentialcontacts.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                             = { role = "roles/essentialcontacts.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/gkebackup.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                     = { role = "roles/gkebackup.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/iam.securityReviewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                 = { role = "roles/iam.securityReviewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/iam.serviceAccountViewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                             = { role = "roles/iam.serviceAccountViewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/logging.privateLogViewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                             = { role = "roles/logging.privateLogViewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/logging.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                       = { role = "roles/logging.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/monitoring.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                    = { role = "roles/monitoring.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/orgpolicy.policyViewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                               = { role = "roles/orgpolicy.policyViewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/osconfig.inventoryViewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                             = { role = "roles/osconfig.inventoryViewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/policyanalyzer.activityAnalysisViewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                = { role = "roles/policyanalyzer.activityAnalysisViewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/privilegedaccessmanager.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                       = { role = "roles/privilegedaccessmanager.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/recommender.iamViewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                = { role = "roles/recommender.iamViewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/run.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                           = { role = "roles/run.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/secretmanager.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                 = { role = "roles/secretmanager.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/serviceusage.serviceUsageViewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                      = { role = "roles/serviceusage.serviceUsageViewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
    "roles/spanner.viewer serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com"                                       = { role = "roles/spanner.viewer", member = "serviceAccount:cis-ig1-auditor@simplifymycloud-dev.iam.gserviceaccount.com" }
  }

  # Google-managed org service agents (Security Command Center, Audit Manager).
  org_iam_agents = {
    "roles/auditmanager.serviceAgent serviceAccount:service-org-933250405420@gcp-sa-audit-manager.iam.gserviceaccount.com"     = { role = "roles/auditmanager.serviceAgent", member = "serviceAccount:service-org-933250405420@gcp-sa-audit-manager.iam.gserviceaccount.com" }
    "roles/cloudfunctions.serviceAgent serviceAccount:service-org-933250405420@security-center-api.iam.gserviceaccount.com"    = { role = "roles/cloudfunctions.serviceAgent", member = "serviceAccount:service-org-933250405420@security-center-api.iam.gserviceaccount.com" }
    "roles/securitycenter.serviceAgent serviceAccount:service-org-933250405420@security-center-api.iam.gserviceaccount.com"    = { role = "roles/securitycenter.serviceAgent", member = "serviceAccount:service-org-933250405420@security-center-api.iam.gserviceaccount.com" }
    "roles/serviceusage.serviceUsageAdmin serviceAccount:service-org-933250405420@security-center-api.iam.gserviceaccount.com" = { role = "roles/serviceusage.serviceUsageAdmin", member = "serviceAccount:service-org-933250405420@security-center-api.iam.gserviceaccount.com" }
  }

  org_iam = merge(
    local.org_iam_humans,
    local.org_iam_domain,
    local.org_iam_auditor,
    local.org_iam_agents,
  )
}
resource "google_organization_iam_member" "this" {
  for_each = local.org_iam

  org_id = "933250405420"
  role   = each.value.role
  member = each.value.member
}

import {
  for_each = local.org_iam
  to       = google_organization_iam_member.this[each.key]
  id       = "933250405420 ${each.value.role} ${each.value.member}"
}
