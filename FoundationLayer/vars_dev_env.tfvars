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
vpc_network_name  = "smc-test-vpc-v01"
vpc_network_description = "SMC development environment VPC"

# security variables
vpc_network_firewall_icmp_disabled  = ""
vpc_network_firewall_internal_disabled  = ""
vpc_network_firewall_ssh_disabled = ""
