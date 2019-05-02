# ---------------------------------------------------------------------------------------------------------------------
# vars to ensure the state of the development environment
# ---------------------------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------------------------------------------------------
# provider variables to configure terraform and gcp
# ---------------------------------------------------------------------------------------------------------------------
# development environment project wide variables
gcp_project = "simplifymycloud-dev"
gcp_region  = "us-west1"
gcp_environment = "dev"

# networking variables
vpc_network_name  = "smc-dev-vpc-01"
vpc_network_description = "SMC development environment VPC"
vpc_network_subnet_one  = "smc-dev-vpc-sub01"
vpc_network_subnet_one_cidr = "10.10.10.0/24"
vpc_network_subnet_two  = "smc-dev-vpc-sub02"
vpc_network_subnet_two_cidr = "10.10.20.0/24"

# security variables
vpc_network_firewall_icmp_disabled  = ""
vpc_network_firewall_internal_disabled  = ""
vpc_network_firewall_ssh_disabled = ""
