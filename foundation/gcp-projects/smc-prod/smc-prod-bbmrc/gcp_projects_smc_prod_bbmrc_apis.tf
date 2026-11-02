# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects — smc-prod / smc-prod-bbmrc — enabled APIs
# ---------------------------------------------------------------------------------------------------------------------
#
# Every API enabled on smc-prod-bbmrc at the 2026-11-01 import (23 APIs). Hardcoded
# on purpose: reading the list tells you exactly which Google services this
# project can use. disable_on_destroy = false so removing Terraform code never
# switches off a live API.

locals {
  apis = toset([
    "analyticshub.googleapis.com",
    "bigquery.googleapis.com",
    "bigqueryconnection.googleapis.com",
    "bigquerydatapolicy.googleapis.com",
    "bigquerymigration.googleapis.com",
    "bigqueryreservation.googleapis.com",
    "bigquerystorage.googleapis.com",
    "cloudapis.googleapis.com",
    "cloudtrace.googleapis.com",
    "containeranalysis.googleapis.com",
    "dataform.googleapis.com",
    "dataplex.googleapis.com",
    "datastore.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "pubsub.googleapis.com",
    "servicemanagement.googleapis.com",
    "serviceusage.googleapis.com",
    "sql-component.googleapis.com",
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
    "storage.googleapis.com",
    "telemetry.googleapis.com",
  ])
}

resource "google_project_service" "apis" {
  for_each = local.apis

  project            = "smc-prod-bbmrc"
  service            = each.value
  disable_on_destroy = false
}

import {
  for_each = local.apis
  to       = google_project_service.apis[each.value]
  id       = "smc-prod-bbmrc/${each.value}"
}
