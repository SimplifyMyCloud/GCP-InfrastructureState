# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP variables
# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer variables
variable "gcp_project" {
  type        = "string"
  description = "declares the GCP Project to be targeted for the desired infrastructure state."
  default     = ""
}

variable "gcp_region" {
  type        = "string"
  description = "declares the GCP Region to be target for the desired infrastructure state."
  default     = ""
}

variable "gcp_environment" {
  type        = "string"
  description = "declares the infrastructure environment (dev,test,stage,ops,prodcution) to be targeted for the desired infrastructure state."
  default     = ""
}

# Networking variables
variable "vpc_network_name" {
  type        = "string"
  description = "declares the name of the VPC network to be used in the project"
  default     = ""
}

variable "vpc_network_description" {
  type        = "string"
  description = "document the VPC network for the project"
  default     = ""
}

variable "vpc_network_autocreate_subnetworks" {
  type        = "string"
  description = "declares if GCP should autocreate the subnetworks across the VPC network, true creates a subnet in every region, false does not create subnets"
  default     = "true"
}

variable "vpc_network_routing_mode" {
  type        = "string"
  description = "declares the routing mode for the VPC network.  If set to REGIONAL, this network's cloud routers will only advertise routes with subnetworks of this network in the same region as the router. If set to GLOBAL, this network's cloud routers will advertise routes with all subnetworks of this network, across regions."
  default     = "REGIONAL"
}

#variable "vpc_network_delete_default_routes" {
#  type        = "string"
#  description = "declares if the default routes created for the VPC network will be deleted after the VPC network is deployed"
#  default     = "false"
#}
