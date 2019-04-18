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
vpc_network_name  = "smc-test-vpc"
vpc_network_description = "SMC development environment VPC"
