# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# Logging — log sinks on the Org (933250405420)
# ---------------------------------------------------------------------------------------------------------------------
#
# Only Google's built-in _Default / _Required ORG sinks. There is no
# org-wide aggregated sink today: org-level logs stay in the org's own
# built-in buckets (see readme.md findings).
#
# Imported from the live Org on 2026-11-01. Built-in sinks carry prevent_destroy.

resource "google_logging_organization_sink" "required" {
  destination        = "logging.googleapis.com/organizations/933250405420/locations/global/buckets/_Required"
  disabled           = false
  filter             = "LOG_ID(\"cloudaudit.googleapis.com/activity\") OR LOG_ID(\"externalaudit.googleapis.com/activity\") OR LOG_ID(\"cloudaudit.googleapis.com/system_event\") OR LOG_ID(\"externalaudit.googleapis.com/system_event\") OR LOG_ID(\"cloudaudit.googleapis.com/access_transparency\") OR LOG_ID(\"externalaudit.googleapis.com/access_transparency\")"
  include_children   = false
  intercept_children = false
  name               = "_Required"
  org_id             = "933250405420"

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_logging_organization_sink.required
  id = "organizations/933250405420/sinks/_Required"
}

resource "google_logging_organization_sink" "default" {
  destination        = "logging.googleapis.com/organizations/933250405420/locations/global/buckets/_Default"
  disabled           = false
  filter             = "NOT LOG_ID(\"cloudaudit.googleapis.com/activity\") AND NOT LOG_ID(\"externalaudit.googleapis.com/activity\") AND NOT LOG_ID(\"cloudaudit.googleapis.com/system_event\") AND NOT LOG_ID(\"externalaudit.googleapis.com/system_event\") AND NOT LOG_ID(\"cloudaudit.googleapis.com/access_transparency\") AND NOT LOG_ID(\"externalaudit.googleapis.com/access_transparency\")"
  include_children   = false
  intercept_children = false
  name               = "_Default"
  org_id             = "933250405420"

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_logging_organization_sink.default
  id = "organizations/933250405420/sinks/_Default"
}
