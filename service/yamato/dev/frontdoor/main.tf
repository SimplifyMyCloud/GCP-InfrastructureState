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
  wiki_service_name      = var.wiki_service_name
  iap_members            = var.iap_members
  iap_enabled            = var.iap_enabled

  enable_cloud_armor         = var.enable_cloud_armor
  cloud_armor_preview        = var.cloud_armor_preview
  enable_adaptive_protection = var.enable_adaptive_protection
}

output "load_balancer_ip" {
  description = "Point yamato-dev.iq9.io at this IP (A record) to finish cert provisioning."
  value       = module.frontdoor.load_balancer_ip
}

output "managed_certificate_name" {
  description = "Managed cert to watch until ACTIVE."
  value       = module.frontdoor.managed_certificate_name
}

output "cloud_armor_policy_name" {
  description = "Cloud Armor policy guarding the front door (null if disabled)."
  value       = module.frontdoor.cloud_armor_policy_name
}
