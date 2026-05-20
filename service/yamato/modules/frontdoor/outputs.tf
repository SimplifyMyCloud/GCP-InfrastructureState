# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: frontdoor — outputs
# ---------------------------------------------------------------------------------------------------------------------

output "load_balancer_ip" {
  description = "Global external IP. Create an A record  <domain> -> this IP  to finish cert provisioning and go live."
  value       = google_compute_global_address.this.address
}

output "managed_certificate_name" {
  description = "Managed SSL certificate name (watch its status until ACTIVE after DNS resolves)."
  value       = google_compute_managed_ssl_certificate.this.name
}
