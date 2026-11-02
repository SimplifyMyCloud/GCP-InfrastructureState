# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# Logging — log sinks on smc-ops folder (714502724732)
# ---------------------------------------------------------------------------------------------------------------------
#
# Only Google's built-in _Default / _Required folder sinks. They route folder-level
# logs into the folder's own built-in buckets.
#
# Imported from the live Org on 2026-11-01. Built-in sinks carry prevent_destroy.

resource "google_logging_folder_sink" "default" {
  destination        = "logging.googleapis.com/folders/714502724732/locations/global/buckets/_Default"
  disabled           = false
  filter             = "NOT LOG_ID(\"cloudaudit.googleapis.com/activity\") AND NOT LOG_ID(\"externalaudit.googleapis.com/activity\") AND NOT LOG_ID(\"cloudaudit.googleapis.com/system_event\") AND NOT LOG_ID(\"externalaudit.googleapis.com/system_event\") AND NOT LOG_ID(\"cloudaudit.googleapis.com/access_transparency\") AND NOT LOG_ID(\"externalaudit.googleapis.com/access_transparency\")"
  folder             = "714502724732"
  include_children   = false
  intercept_children = false
  name               = "_Default"

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_logging_folder_sink.default
  id = "folders/714502724732/sinks/_Default"
}

resource "google_logging_folder_sink" "required" {
  destination        = "logging.googleapis.com/folders/714502724732/locations/global/buckets/_Required"
  disabled           = false
  filter             = "LOG_ID(\"cloudaudit.googleapis.com/activity\") OR LOG_ID(\"externalaudit.googleapis.com/activity\") OR LOG_ID(\"cloudaudit.googleapis.com/system_event\") OR LOG_ID(\"externalaudit.googleapis.com/system_event\") OR LOG_ID(\"cloudaudit.googleapis.com/access_transparency\") OR LOG_ID(\"externalaudit.googleapis.com/access_transparency\")"
  folder             = "714502724732"
  include_children   = false
  intercept_children = false
  name               = "_Required"

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_logging_folder_sink.required
  id = "folders/714502724732/sinks/_Required"
}
