# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP variables
# ---------------------------------------------------------------------------------------------------------------------
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
