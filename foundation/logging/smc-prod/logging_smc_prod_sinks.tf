# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# Logging — log sinks on smc-prod folder (386439801809)
# ---------------------------------------------------------------------------------------------------------------------
#
# Only Google's built-in _Default / _Required folder sinks.
#
# Imported from the live Org on 2026-11-01. Built-in sinks carry prevent_destroy.

resource "google_logging_folder_sink" "default" {
  destination        = "logging.googleapis.com/folders/386439801809/locations/global/buckets/_Default"
  disabled           = false
  filter             = "NOT LOG_ID(\"cloudaudit.googleapis.com/activity\") AND NOT LOG_ID(\"externalaudit.googleapis.com/activity\") AND NOT LOG_ID(\"cloudaudit.googleapis.com/system_event\") AND NOT LOG_ID(\"externalaudit.googleapis.com/system_event\") AND NOT LOG_ID(\"cloudaudit.googleapis.com/access_transparency\") AND NOT LOG_ID(\"externalaudit.googleapis.com/access_transparency\")"
  folder             = "386439801809"
  include_children   = false
  intercept_children = false
  name               = "_Default"

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_logging_folder_sink.default
  id = "folders/386439801809/sinks/_Default"
}

resource "google_logging_folder_sink" "required" {
  destination        = "logging.googleapis.com/folders/386439801809/locations/global/buckets/_Required"
  disabled           = false
  filter             = "LOG_ID(\"cloudaudit.googleapis.com/activity\") OR LOG_ID(\"externalaudit.googleapis.com/activity\") OR LOG_ID(\"cloudaudit.googleapis.com/system_event\") OR LOG_ID(\"externalaudit.googleapis.com/system_event\") OR LOG_ID(\"cloudaudit.googleapis.com/access_transparency\") OR LOG_ID(\"externalaudit.googleapis.com/access_transparency\")"
  folder             = "386439801809"
  include_children   = false
  intercept_children = false
  name               = "_Required"

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_logging_folder_sink.required
  id = "folders/386439801809/sinks/_Required"
}
