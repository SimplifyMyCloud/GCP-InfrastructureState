# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Networking state
# ---------------------------------------------------------------------------------------------------------------------

# ensure data gathered from default project

# GCP project & region output
output "GCP region" {
  value = "Terraform is targeting the ${var.gcp_region} region"
}

data "google_project" "default_project" {}

output "GCP default project" {
  value = "a GCP project named ${data.google_project.default_project.name} has the id ${data.google_project.default_project.number}"
}

# GCP VPC default network output
data "google_compute_network" "default" {
  name = "default"
}

output "GCP default VPC network" {
  value = "a GCP default VPC network named ${data.google_compute_network.default.name}"
}

# GCP VPC default subnet output
data "google_compute_subnetwork" "default" {
  name = "default"
}

output "GCP default VPC subnetwork" {
  value = "a GCP default VPC subnetwork list with the name ${data.google_compute_subnetwork.default.name} has a CIDR range of ${data.google_compute_subnetwork.default.ip_cidr_range}"
}

# ensure a not-default VPC network 

# regional VPC network
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "0.6.0"

  project_id   = "${var.gcp_project}"
  network_name = "${var.vpc_network_name}"
  routing_mode = "${var.vpc_network_routing_mode}"

  subnets = [
    {
      subnet_name           = "${var.vpc_network_subnet_one}"
      subnet_ip             = "${var.vpc_network_subnet_one_cidr}"
      subnet_region         = "${var.gcp_region}"
      subnet_private_access = "${var.vpc_network_subnet_one_gcp_private_access}"
      subnet_flow_logs      = "${var.vpc_network_subnet_one_vpc_flow_logs}"
    },
    {
      subnet_name           = "${var.vpc_network_subnet_two}"
      subnet_ip             = "${var.vpc_network_subnet_two_cidr}"
      subnet_region         = "${var.gcp_region}"
      subnet_private_access = "${var.vpc_network_subnet_two_gcp_private_access}"
      subnet_flow_logs      = "${var.vpc_network_subnet_two_vpc_flow_logs}"
    },
  ]

  secondary_ranges = {
    "${var.vpc_network_subnet_one}" = []
    "${var.vpc_network_subnet_two}" = []
  }

  routes = [
    {
      name              = "egress-internet"
      description       = "route through the IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    },
    {
      name              = "subnet-one-route"
      description       = "Default local route to the subnetwork one"
      destination_range = "${var.vpc_network_subnet_one_cidr}"
      tags              = "subnet-one"
    },
    {
      name              = "subnet-two-route"
      description       = "Default local route to the subnetwork two"
      destination_range = "${var.vpc_network_subnet_two_cidr}"
      tags              = "subnet-two"
    },
  ]
}
