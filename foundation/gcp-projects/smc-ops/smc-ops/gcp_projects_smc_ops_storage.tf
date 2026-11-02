# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects — smc-ops / smc-ops — GCS buckets
# ---------------------------------------------------------------------------------------------------------------------
#
# gs://smc-ops-tf-state — the ONE bucket that holds every Terraform state file
# in this repo. Its folder tree mirrors the git tree:
#   gs://smc-ops-tf-state/terraform/state/<git path>/default.tfstate
#
# Created by hand with gcloud on 2026-11-01 (it has to exist before any
# `terraform init`), then imported here. Versioned so a bad apply can be rolled
# back to an earlier state file; UBLA + public access prevention so it can never
# be made public.
#
# ⚠️ Do NOT add `project = "smc-ops"` to this resource. The import records the
# project as null, and setting it makes Terraform plan to DESTROY and recreate
# the state bucket. The bucket's project is fixed by where it was created.

resource "google_storage_bucket" "smc_ops_tf_state" {
  name          = "smc-ops-tf-state"
  location      = "US-WEST1"
  storage_class = "STANDARD"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  default_event_based_hold    = false
  enable_object_retention     = false
  requester_pays              = false
  force_destroy               = false
  labels                      = {}

  versioning {
    enabled = true
  }

  soft_delete_policy {
    retention_duration_seconds = 604800 # 7 days
  }

  hierarchical_namespace {
    enabled = false
  }

  # Losing this bucket loses every Terraform state file in the Org.
  lifecycle {
    prevent_destroy = true
  }
}

import {
  to = google_storage_bucket.smc_ops_tf_state
  id = "smc-ops-tf-state"
}

# gs://smc-ops-log-archive — the Org's cold log archive (NEW 2026-11-02).
# Written by the org-wide sink `smc-org-log-archive` (logging/gcp-org/), which sends
# EVERY log from every folder and project here. Archive storage class: the
# cheapest to keep, slow and costly to read; it's evidence, not a search tool.
# For searching, use each project's Logs Explorer (_Default, 30 days) or the
# smc-dev-env-logging bucket. Objects are deleted after 365 days, which also
# matches Archive's 365-day minimum storage duration, so there's no early-delete fee.
# Not locked: retention can still be changed. Writer IAM:
# iam/smc-ops/smc-ops/iam_smc_ops_log_archive_bucket.tf.

resource "google_storage_bucket" "smc_ops_log_archive" {
  name          = "smc-ops-log-archive"
  project       = "smc-ops"
  location      = "US-WEST1"
  storage_class = "ARCHIVE"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false
  labels                      = {}

  versioning {
    enabled = false
  }

  # Logs are write-once; soft delete would only add storage cost.
  soft_delete_policy {
    retention_duration_seconds = 0
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}
