# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects — smc-ops / smc-ops — security monitoring
# ---------------------------------------------------------------------------------------------------------------------
#
# Three log-based metrics count security-relevant changes. Two alert policies
# email chris@simplifymy.cloud when those counts go above zero.
#
#   metric                  alert                  watches
#   audit-config-changes    audit-config-changes   audit-logging config changed (SetIamPolicy w/ auditConfigDeltas)
#   storage-iam-change      storage-iam-change     IAM changed on any GCS bucket
#   custom-role-change      (none)                 custom IAM role created/updated/deleted
#
# These metrics only see logs that land in smc-ops itself, so they are not
# org-wide today. That's listed as a finding in this directory's readme.md.

# --- notification channel -------------------------------------------------------------------------------------------

resource "google_monitoring_notification_channel" "c5287669036998057566" {
  project      = "smc-ops"
  display_name = "Log Alert Email"
  type         = "email"
  enabled      = true
  force_delete = false
  labels = {
    email_address = "chris@simplifymy.cloud"
  }
  user_labels = {}
}

import {
  to = google_monitoring_notification_channel.c5287669036998057566
  id = "projects/smc-ops/notificationChannels/5287669036998057566"
}

# --- log-based metrics ----------------------------------------------------------------------------------------------

resource "google_logging_metric" "audit_config_changes" {
  project          = "smc-ops"
  name             = "audit-config-changes"
  disabled         = false
  filter           = "    protoPayload.methodName=\"SetIamPolicy\"\n    AND protoPayload.serviceData.policyDelta.auditConfigDeltas:*\n"
  label_extractors = {}
  metric_descriptor {
    metric_kind = "DELTA"
    unit        = "1"
    value_type  = "INT64"
  }
}

import {
  to = google_logging_metric.audit_config_changes
  id = "smc-ops audit-config-changes"
}

resource "google_logging_metric" "custom_role_change" {
  project          = "smc-ops"
  name             = "custom-role-change"
  disabled         = false
  filter           = "    resource.type=\"iam_role\"\n    AND (protoPayload.methodName=\"google.iam.admin.v1.CreateRole\"\n    OR protoPayload.methodName=\"google.iam.admin.v1.DeleteRole\"\n    OR protoPayload.methodName=\"google.iam.admin.v1.UpdateRole\")\n"
  label_extractors = {}
  metric_descriptor {
    metric_kind = "DELTA"
    unit        = "1"
    value_type  = "INT64"
  }
}

import {
  to = google_logging_metric.custom_role_change
  id = "smc-ops custom-role-change"
}

resource "google_logging_metric" "storage_iam_change" {
  project          = "smc-ops"
  name             = "storage-iam-change"
  disabled         = false
  filter           = "    resource.type=\"gcs_bucket\"\n    AND protoPayload.methodName=\"storage.setIamPermissions\"\n"
  label_extractors = {}
  metric_descriptor {
    metric_kind = "DELTA"
    unit        = "1"
    value_type  = "INT64"
  }
}

import {
  to = google_logging_metric.storage_iam_change
  id = "smc-ops storage-iam-change"
}

# --- alert policies -------------------------------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "storage_iam_change" {
  project      = "smc-ops"
  display_name = "storage-iam-change"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "storage-iam-change condition"
    condition_threshold {
      filter     = "metric.type=\"logging.googleapis.com/user/storage-iam-change\" AND resource.type=\"gcs_bucket\""
      comparison = "COMPARISON_GT"
      duration   = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.c5287669036998057566.id]
}

import {
  to = google_monitoring_alert_policy.storage_iam_change
  id = "smc-ops projects/smc-ops/alertPolicies/2846761872485402864"
}

resource "google_monitoring_alert_policy" "audit_config_changes" {
  project      = "smc-ops"
  display_name = "audit-config-changes"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "audit-config-changes condition"
    condition_threshold {
      filter     = "metric.type=\"logging.googleapis.com/user/audit-config-changes\" AND resource.type=\"global\""
      comparison = "COMPARISON_GT"
      duration   = "60s"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.c5287669036998057566.id]
}

import {
  to = google_monitoring_alert_policy.audit_config_changes
  id = "smc-ops projects/smc-ops/alertPolicies/3728661420003220009"
}
