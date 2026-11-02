# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# Logging — smc-ops / smc-ops — log buckets and project sinks
# ---------------------------------------------------------------------------------------------------------------------
#
# Where log entries land inside smc-ops:
#
#   smc-dev folder sink (logging/smc-dev/) ──► smc-dev-env-logging   us-west1, 3-day retention, Log Analytics on
#   smc-ops project logs ──► _Required sink ──► _Required bucket      400 days, locked by Google (not managed here)
#                        └─► _Default sink  ──► _Default bucket       30 days
#
# _Default and _Required are Google's built-in sinks/buckets. They're imported
# so git shows how logs flow, and prevent_destroy stops a stray
# `terraform destroy` from breaking project logging.

# --- log buckets ----------------------------------------------------------------------------------------------------

resource "google_logging_project_bucket_config" "smc_dev_env_logging" {
  project          = "projects/smc-ops"
  location         = "us-west1"
  bucket_id        = "smc-dev-env-logging"
  description      = "Logging for the DevEnv of SMC"
  retention_days   = 30 # was 3 until 2026-11-02; 30 is the retention included in Logging pricing
  enable_analytics = true
  locked           = false
}

import {
  to = google_logging_project_bucket_config.smc_dev_env_logging
  id = "projects/smc-ops/locations/us-west1/buckets/smc-dev-env-logging"
}

resource "google_logging_project_bucket_config" "default" {
  project          = "projects/smc-ops"
  location         = "global"
  bucket_id        = "_Default"
  description      = "Default bucket"
  retention_days   = 30
  enable_analytics = false
  locked           = false

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_logging_project_bucket_config.default
  id = "projects/smc-ops/locations/global/buckets/_Default"
}

# --- built-in project sinks -----------------------------------------------------------------------------------------

resource "google_logging_project_sink" "required" {
  project                = "smc-ops"
  name                   = "_Required"
  destination            = "logging.googleapis.com/projects/smc-ops/locations/global/buckets/_Required"
  filter                 = "LOG_ID(\"cloudaudit.googleapis.com/activity\") OR LOG_ID(\"externalaudit.googleapis.com/activity\") OR LOG_ID(\"cloudaudit.googleapis.com/system_event\") OR LOG_ID(\"externalaudit.googleapis.com/system_event\") OR LOG_ID(\"cloudaudit.googleapis.com/access_transparency\") OR LOG_ID(\"externalaudit.googleapis.com/access_transparency\")"
  disabled               = false
  unique_writer_identity = true

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_logging_project_sink.required
  id = "projects/smc-ops/sinks/_Required"
}

resource "google_logging_project_sink" "default" {
  project                = "smc-ops"
  name                   = "_Default"
  destination            = "logging.googleapis.com/projects/smc-ops/locations/global/buckets/_Default"
  filter                 = "NOT LOG_ID(\"cloudaudit.googleapis.com/activity\") AND NOT LOG_ID(\"externalaudit.googleapis.com/activity\") AND NOT LOG_ID(\"cloudaudit.googleapis.com/system_event\") AND NOT LOG_ID(\"externalaudit.googleapis.com/system_event\") AND NOT LOG_ID(\"cloudaudit.googleapis.com/access_transparency\") AND NOT LOG_ID(\"externalaudit.googleapis.com/access_transparency\")"
  disabled               = false
  unique_writer_identity = true

  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_logging_project_sink.default
  id = "projects/smc-ops/sinks/_Default"
}
