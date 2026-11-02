# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# Logging — log sinks on smc-dev folder (922883963214)
# ---------------------------------------------------------------------------------------------------------------------
#
# smc-dev-env-log-sink copies EVERY log from every project in smc-dev
# (include_children = true) into the smc-dev-env-logging bucket in smc-ops
# (3-day retention, see logging/smc-ops/smc-ops/). Its writer identity
# service-folder-922883963214@gcp-sa-logging is granted bucketWriter in
# iam/smc-ops/smc-ops/. Plus the built-in _Default / _Required folder sinks.
#
# Imported from the live Org on 2026-11-01. Built-in sinks carry prevent_destroy.

resource "google_logging_folder_sink" "required" {
  destination        = "logging.googleapis.com/folders/922883963214/locations/global/buckets/_Required"
  disabled           = false
  filter             = "LOG_ID(\"cloudaudit.googleapis.com/activity\") OR LOG_ID(\"externalaudit.googleapis.com/activity\") OR LOG_ID(\"cloudaudit.googleapis.com/system_event\") OR LOG_ID(\"externalaudit.googleapis.com/system_event\") OR LOG_ID(\"cloudaudit.googleapis.com/access_transparency\") OR LOG_ID(\"externalaudit.googleapis.com/access_transparency\")"
  folder             = "922883963214"
  include_children   = false
  intercept_children = false
  name               = "_Required"

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_logging_folder_sink.required
  id = "folders/922883963214/sinks/_Required"
}

resource "google_logging_folder_sink" "default" {
  destination        = "logging.googleapis.com/folders/922883963214/locations/global/buckets/_Default"
  disabled           = false
  filter             = "NOT LOG_ID(\"cloudaudit.googleapis.com/activity\") AND NOT LOG_ID(\"externalaudit.googleapis.com/activity\") AND NOT LOG_ID(\"cloudaudit.googleapis.com/system_event\") AND NOT LOG_ID(\"externalaudit.googleapis.com/system_event\") AND NOT LOG_ID(\"cloudaudit.googleapis.com/access_transparency\") AND NOT LOG_ID(\"externalaudit.googleapis.com/access_transparency\")"
  folder             = "922883963214"
  include_children   = false
  intercept_children = false
  name               = "_Default"

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_logging_folder_sink.default
  id = "folders/922883963214/sinks/_Default"
}

resource "google_logging_folder_sink" "smc_dev_env_log_sink" {
  description        = "DevEnv Logging Sink"
  destination        = "logging.googleapis.com/projects/smc-ops/locations/us-west1/buckets/smc-dev-env-logging"
  disabled           = false
  folder             = "922883963214"
  include_children   = true
  intercept_children = false
  name               = "smc-dev-env-log-sink"
}

import {
  to = google_logging_folder_sink.smc_dev_env_log_sink
  id = "folders/922883963214/sinks/smc-dev-env-log-sink"
}
