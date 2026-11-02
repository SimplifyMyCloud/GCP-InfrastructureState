# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects — smc-ops / smc-ops — enabled APIs
# ---------------------------------------------------------------------------------------------------------------------
#
# Hardcoded on purpose: reading these lists tells you exactly which Google
# services smc-ops can use. To enable an API, add it to the added list. To
# disable one, remove it AND flip disable_on_destroy for that apply (disabling
# is deliberately manual).
#
# Two lists:
#   smc_ops_apis_imported   the 25 APIs already on at the 2026-11-01 import
#   smc_ops_apis_added      enabled by Terraform since then
#
# Why smc-ops needs "management" APIs: calls made AS smc-tf-foundation-sa bill
# their quota to the SA's home project (smc-ops). So every Google API Terraform
# talks to, anywhere in the Org, must be enabled HERE.

locals {
  smc_ops_apis_imported = toset([
    "apphub.googleapis.com",
    "appoptimize.googleapis.com",
    "apptopology.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudaicompanion.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudasset.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "containeranalysis.googleapis.com",
    "datastore.googleapis.com",
    "designcenter.googleapis.com",
    "geminicloudassist.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "recommender.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "telemetry.googleapis.com",
  ])

  smc_ops_apis_added = toset([
    # Needed by smc-tf-foundation-sa (quota project = smc-ops): one entry per
    # Google API that Terraform manages somewhere in the Org.
    "accesscontextmanager.googleapis.com",
    "aiplatform.googleapis.com",
    "apikeys.googleapis.com",
    "appengine.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudsecuritycompliance.googleapis.com",
    "compute.googleapis.com",
    "dataplex.googleapis.com",
    "discoveryengine.googleapis.com",
    "dns.googleapis.com",
    "firebase.googleapis.com",
    "firebasehosting.googleapis.com",
    "firebaserules.googleapis.com",
    "firestore.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "identitytoolkit.googleapis.com",
    "networkmanagement.googleapis.com",
    "orgpolicy.googleapis.com",
    "osconfig.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "securitycenter.googleapis.com",
    "securitycentermanagement.googleapis.com",
    "servicedirectory.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "vpcaccess.googleapis.com",
    "websecurityscanner.googleapis.com",
  ])
}

resource "google_project_service" "apis" {
  for_each = setunion(local.smc_ops_apis_imported, local.smc_ops_apis_added)

  project            = "smc-ops"
  service            = each.value
  disable_on_destroy = false
}

import {
  for_each = local.smc_ops_apis_imported
  to       = google_project_service.apis[each.value]
  id       = "smc-ops/${each.value}"
}
