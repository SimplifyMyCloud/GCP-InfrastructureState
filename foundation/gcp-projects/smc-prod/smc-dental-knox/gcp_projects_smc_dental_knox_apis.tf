# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects — smc-prod / smc-dental-knox — enabled APIs
# ---------------------------------------------------------------------------------------------------------------------
#
# Every API enabled on smc-dental-knox at the 2026-11-01 import (35 APIs). Hardcoded
# on purpose: reading the list tells you exactly which Google services this
# project can use. disable_on_destroy = false so removing Terraform code never
# switches off a live API.

locals {
  apis = toset([
    "appengine.googleapis.com",
    "bigquery.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudaicompanion.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtrace.googleapis.com",
    "containeranalysis.googleapis.com",
    "datastore.googleapis.com",
    "fcm.googleapis.com",
    "fcmregistrations.googleapis.com",
    "firebase.googleapis.com",
    "firebaseappdistribution.googleapis.com",
    "firebasedynamiclinks.googleapis.com",
    "firebasehosting.googleapis.com",
    "firebaseinstallations.googleapis.com",
    "firebaseremoteconfig.googleapis.com",
    "firebaserules.googleapis.com",
    "googlecloudmessaging.googleapis.com",
    "identitytoolkit.googleapis.com",
    "logging.googleapis.com",
    "mobilecrashreporting.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "runtimeconfig.googleapis.com",
    "securetoken.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "source.googleapis.com",
    "sql-component.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "telemetry.googleapis.com",
    "testing.googleapis.com",
  ])
}

resource "google_project_service" "apis" {
  for_each = local.apis

  project            = "smc-dental-knox"
  service            = each.value
  disable_on_destroy = false
}

import {
  for_each = local.apis
  to       = google_project_service.apis[each.value]
  id       = "smc-dental-knox/${each.value}"
}
