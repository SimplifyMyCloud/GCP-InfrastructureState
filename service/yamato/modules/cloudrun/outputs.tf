# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: cloudrun — outputs
# ---------------------------------------------------------------------------------------------------------------------

output "service_name" {
  description = "The Cloud Run service name (frontdoor's serverless NEG targets it)."
  value       = google_cloud_run_v2_service.this.name
}

output "service_uri" {
  description = "The service's *.run.app URI (not publicly reachable — ingress is LB-only)."
  value       = google_cloud_run_v2_service.this.uri
}

output "runtime_service_account_email" {
  description = "Email of the Cloud Run runtime service account."
  value       = google_service_account.runtime.email
}

output "connector_id" {
  description = "The Serverless VPC Access connector resource ID."
  value       = google_vpc_access_connector.this.id
}
