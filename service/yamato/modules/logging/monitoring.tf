# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: logging — monitoring side
# ---------------------------------------------------------------------------------------------------------------------
#
# Performance + security alerting and a dashboard, built on a mix of Cloud Run /
# Cloud SQL built-in metrics and the log-based metrics from logging.tf. All alert
# policies fan out to one email notification channel.
#
# Thresholds are variables with sensible defaults — tune after the first real
# traffic / `terraform plan`.
# ---------------------------------------------------------------------------------------------------------------------

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "yamato dev alerts (${var.notification_email})"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}

# --- Performance: Cloud Run p95 latency ----------------------------------------------------------------------------
resource "google_monitoring_alert_policy" "high_latency" {
  project      = var.project_id
  display_name = "yamato — Cloud Run p95 latency > ${var.latency_threshold_ms}ms"
  combiner     = "OR"

  conditions {
    display_name = "p95 request latency"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.label.service_name=\"${var.run_service_name}\" AND metric.type=\"run.googleapis.com/request_latencies\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.latency_threshold_ms
      duration        = "300s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_PERCENTILE_95"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "Cloud Run p95 latency for ${var.run_service_name} exceeded ${var.latency_threshold_ms}ms over 5 minutes."
    mime_type = "text/markdown"
  }
}

# --- Performance: Cloud Run 5xx rate -------------------------------------------------------------------------------
resource "google_monitoring_alert_policy" "high_5xx" {
  project      = var.project_id
  display_name = "yamato — Cloud Run 5xx rate > ${var.error_5xx_threshold}/s"
  combiner     = "OR"

  conditions {
    display_name = "5xx response rate"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND resource.label.service_name=\"${var.run_service_name}\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.label.response_code_class=\"5xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.error_5xx_threshold
      duration        = "300s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

# --- Performance: Cloud SQL CPU --------------------------------------------------------------------------------------
resource "google_monitoring_alert_policy" "sql_cpu" {
  project      = var.project_id
  display_name = "yamato — Cloud SQL CPU > ${var.sql_cpu_threshold}"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL CPU utilization"
    condition_threshold {
      filter          = "resource.type=\"cloudsql_database\" AND resource.label.database_id=\"${var.project_id}:${var.sql_instance_name}\" AND metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.sql_cpu_threshold
      duration        = "300s"
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

# --- Reliability: app ERROR log volume (log-based metric) ----------------------------------------------------------
resource "google_monitoring_alert_policy" "app_errors" {
  project      = var.project_id
  display_name = "yamato — app errors > ${var.app_error_threshold}/5min"
  combiner     = "OR"

  conditions {
    display_name = "app ERROR log events"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.app_errors.name}\" AND resource.type=\"cloud_run_revision\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.app_error_threshold
      duration        = "0s"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]
}

# --- Security: Secret Manager access spike (log-based metric) -------------------------------------------------------
resource "google_monitoring_alert_policy" "secret_access_spike" {
  project      = var.project_id
  display_name = "yamato — Secret Manager access spike > ${var.secret_access_threshold}/5min"
  combiner     = "OR"

  conditions {
    display_name = "AccessSecretVersion calls"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.secret_access.name}\" AND resource.type=\"audited_resource\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.secret_access_threshold
      duration        = "0s"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "Unusually high Secret Manager AccessSecretVersion volume on ${var.project_id}. Normal is a small number at Cloud Run cold start; a spike may indicate exfiltration or a misbehaving deploy."
    mime_type = "text/markdown"
  }
}

# --- Security: Cloud Armor blocks (log-based metric) --------------------------------------------------------------
# Gated: the cloud_armor_blocked metric must have logged >=1 DENY before Monitoring will
# accept an alert built on it (see var.enable_cloud_armor_alert). The metric + dashboard
# tile exist unconditionally; only this alert waits for the first real block.
resource "google_monitoring_alert_policy" "cloud_armor_blocks" {
  count        = var.enable_cloud_armor_alert ? 1 : 0
  project      = var.project_id
  display_name = "yamato — Cloud Armor blocks > ${var.cloud_armor_block_threshold}/5min"
  combiner     = "OR"

  conditions {
    display_name = "Cloud Armor blocked requests"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.cloud_armor_blocked.name}\" AND resource.type=\"http_load_balancer\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.cloud_armor_block_threshold
      duration        = "0s"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "Cloud Armor is actively blocking requests at the yamato front door — a scan or injection attempt is in progress. The matched WAF rule IDs are in the LB logs under jsonPayload.enforcedSecurityPolicy (log_level=VERBOSE)."
    mime_type = "text/markdown"
  }
}

# --- Security: denied API calls — the IAM wall (log-based metric) -------------------------------------------------
resource "google_monitoring_alert_policy" "denied_api_calls" {
  project      = var.project_id
  display_name = "yamato — denied API calls > ${var.denied_api_threshold}/5min"
  combiner     = "OR"

  conditions {
    display_name = "PERMISSION_DENIED API calls"
    condition_threshold {
      # Cloud Audit Log-based metrics surface under the `audited_resource` monitored
      # resource (Monitoring requires a resource.type pin); REDUCE_SUM aggregates across services.
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.denied_api_calls.name}\" AND resource.type=\"audited_resource\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.denied_api_threshold
      duration        = "0s"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "A spike in PERMISSION_DENIED calls means an identity is repeatedly being refused by IAM — the classic signature of stolen credentials probing for privilege escalation. Least privilege is holding."
    mime_type = "text/markdown"
  }
}

# --- Security: SA token mints / impersonation (log-based metric) --------------------------------------------------
resource "google_monitoring_alert_policy" "sa_token_mints" {
  project      = var.project_id
  display_name = "yamato — SA token mints > ${var.sa_token_mint_threshold}/5min"
  combiner     = "OR"

  conditions {
    display_name = "GenerateAccessToken calls"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.sa_token_mints.name}\" AND resource.type=\"audited_resource\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.sa_token_mint_threshold
      duration        = "0s"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "Unusual volume of service-account access-token minting (GenerateAccessToken) — a possible service-account-takeover / impersonation attempt (gamilas Profile 2)."
    mime_type = "text/markdown"
  }
}

# --- Security: SA key-creation attempts — should be flat zero (log-based metric) ----------------------------------
resource "google_monitoring_alert_policy" "sa_key_create_attempts" {
  project      = var.project_id
  display_name = "yamato — SA key-creation attempts > ${var.sa_key_create_threshold}/5min"
  combiner     = "OR"

  conditions {
    display_name = "CreateServiceAccountKey calls"
    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.sa_key_create_attempts.name}\" AND resource.type=\"audited_resource\""
      comparison      = "COMPARISON_GT"
      threshold_value = var.sa_key_create_threshold
      duration        = "0s"
      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "Someone tried to create a service-account KEY. Org policy iam.disableServiceAccountKeyCreation blocks this, so any attempt is suspicious — the attacker is rattling a locked door."
    mime_type = "text/markdown"
  }
}

# --- Attack-view dashboard -----------------------------------------------------------------------------------------
#
# The single screen to project during the gamilas demo: six tiles that stay flat in normal
# operation and visibly spike the moment the attack starts — edge blocks, front-door
# denials, IAM refusals, impersonation attempts, secret access, key-creation attempts.
resource "google_monitoring_dashboard" "yamato_security" {
  project = var.project_id

  dashboard_json = jsonencode({
    displayName = "yamato — dev (SECURITY / attack view)"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          xPos = 0, yPos = 0, width = 6, height = 4
          widget = {
            title = "Cloud Armor — blocked requests (edge WAF/rate-limit)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.cloud_armor_blocked.name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_DELTA"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos = 6, yPos = 0, width = 6, height = 4
          widget = {
            title = "Front-door denials — 403 (IAP / authz)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.iap_denied.name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_DELTA"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos = 0, yPos = 4, width = 6, height = 4
          widget = {
            title = "Denied API calls — PERMISSION_DENIED (IAM wall)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.denied_api_calls.name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_DELTA"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos = 6, yPos = 4, width = 6, height = 4
          widget = {
            title = "SA access-token mints (impersonation / takeover)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.sa_token_mints.name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_DELTA"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos = 0, yPos = 8, width = 6, height = 4
          widget = {
            title = "Secret Manager access"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.secret_access.name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_DELTA"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos = 6, yPos = 8, width = 6, height = 4
          widget = {
            title = "SA key-creation attempts (blocked by org policy)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.sa_key_create_attempts.name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_DELTA"
                      crossSeriesReducer = "REDUCE_SUM"
                    }
                  }
                }
              }]
            }
          }
        }
      ]
    }
  })
}

# --- Dashboard -----------------------------------------------------------------------------------------------------
resource "google_monitoring_dashboard" "yamato" {
  project = var.project_id

  dashboard_json = jsonencode({
    displayName = "yamato — dev (performance & security)"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          xPos = 0, yPos = 0, width = 6, height = 4
          widget = {
            title = "Cloud Run — request rate by response class"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"run.googleapis.com/request_count\" resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.run_service_name}\""
                    aggregation = {
                      alignmentPeriod    = "60s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["metric.label.response_code_class"]
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos = 6, yPos = 0, width = 6, height = 4
          widget = {
            title = "Cloud Run — p95 request latency (ms)"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"run.googleapis.com/request_latencies\" resource.type=\"cloud_run_revision\" resource.label.service_name=\"${var.run_service_name}\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_PERCENTILE_95"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos = 0, yPos = 4, width = 6, height = 4
          widget = {
            title = "Cloud SQL — CPU utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"cloudsql.googleapis.com/database/cpu/utilization\" resource.type=\"cloudsql_database\" resource.label.database_id=\"${var.project_id}:${var.sql_instance_name}\""
                    aggregation = {
                      alignmentPeriod  = "60s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
              }]
            }
          }
        },
        {
          xPos = 6, yPos = 4, width = 6, height = 4
          widget = {
            title = "Security — secret access & front-door denials"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.secret_access.name}\""
                      aggregation = {
                        alignmentPeriod    = "300s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.iap_denied.name}\""
                      aggregation = {
                        alignmentPeriod    = "300s"
                        perSeriesAligner   = "ALIGN_DELTA"
                        crossSeriesReducer = "REDUCE_SUM"
                      }
                    }
                  }
                }
              ]
            }
          }
        }
      ]
    }
  })
}
