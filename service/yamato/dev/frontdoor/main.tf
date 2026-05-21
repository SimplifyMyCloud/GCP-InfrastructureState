# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — yamato / dev / frontdoor
# Thin environment root: instantiates the shared frontdoor module with dev values.
# The reusable shape lives in ../../modules/frontdoor.
# ---------------------------------------------------------------------------------------------------------------------

module "frontdoor" {
  source = "../../modules/frontdoor"

  project_id             = var.project_id
  region                 = var.region
  name_prefix            = var.name_prefix
  domain                 = var.domain
  cloud_run_service_name = var.cloud_run_service_name
  iap_members            = var.iap_members
  iap_enabled            = var.iap_enabled
}

output "load_balancer_ip" {
  description = "Point yamato-dev.iq9.io at this IP (A record) to finish cert provisioning."
  value       = module.frontdoor.load_balancer_ip
}

output "managed_certificate_name" {
  description = "Managed cert to watch until ACTIVE."
  value       = module.frontdoor.managed_certificate_name
}
