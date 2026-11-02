# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-ops / smc-ops — project IAM bindings
# ---------------------------------------------------------------------------------------------------------------------
#
# One google_project_iam_member per role+member (additive). Terraform owns the
# bindings listed here and nothing else on the project's policy.
#
# Google-managed service agents (service-<number>@gcp-sa-*) are included so
# git shows the complete live policy. Google re-creates them when an API is
# enabled, so don't remove them by hand.

locals {
  smc_ops_project_iam = {
    "roles/cloudaicompanion.serviceAgent service-328135394383@gcp-sa-cloudaicompanion" = { role = "roles/cloudaicompanion.serviceAgent", member = "serviceAccount:service-328135394383@gcp-sa-cloudaicompanion.iam.gserviceaccount.com" }
    "roles/cloudsecuritycompliance.serviceAgent service-328135394383@gcp-sa-csc-hpsa"  = { role = "roles/cloudsecuritycompliance.serviceAgent", member = "serviceAccount:service-328135394383@gcp-sa-csc-hpsa.iam.gserviceaccount.com" }
    "roles/owner chris@simplifymy.cloud"                                               = { role = "roles/owner", member = "user:chris@simplifymy.cloud" }
    # ⚠️ Finding: org admin granted at PROJECT scope to a keyed SA.
    "roles/resourcemanager.organizationAdmin smc-ops-tf-org-admin" = { role = "roles/resourcemanager.organizationAdmin", member = "serviceAccount:smc-ops-tf-org-admin@smc-ops.iam.gserviceaccount.com" }
  }
}

resource "google_project_iam_member" "this" {
  for_each = local.smc_ops_project_iam

  project = "smc-ops"
  role    = each.value.role
  member  = each.value.member
}

import {
  for_each = local.smc_ops_project_iam
  to       = google_project_iam_member.this[each.key]
  id       = "smc-ops ${each.value.role} ${each.value.member}"
}

# The smc-dev folder sink's writer identity may write ONLY into the
# smc-dev-env-logging bucket (IAM condition). Created by the Console when the
# sink was set up, hence the condition title is the member string.

resource "google_project_iam_member" "smc_dev_sink_bucket_writer" {
  project = "smc-ops"
  role    = "roles/logging.bucketWriter"
  member  = "serviceAccount:service-folder-922883963214@gcp-sa-logging.iam.gserviceaccount.com"

  condition {
    title      = "serviceAccount:service-folder-922883963214@gcp-sa-logging.iam.gserviceaccount.com"
    expression = "resource.name.endsWith('locations/us-west1/buckets/smc-dev-env-logging')"
  }
}

import {
  to = google_project_iam_member.smc_dev_sink_bucket_writer
  id = "smc-ops roles/logging.bucketWriter serviceAccount:service-folder-922883963214@gcp-sa-logging.iam.gserviceaccount.com serviceAccount:service-folder-922883963214@gcp-sa-logging.iam.gserviceaccount.com"
}
