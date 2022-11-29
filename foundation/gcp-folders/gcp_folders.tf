# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Folders
# ensures GCP Folders per Infrastructure Environment for the Foundation Layer
# ---------------------------------------------------------------------------------------------------------------------
#
# Top level GCP Folders are to split Cloud Foundation Toolkit & Vanilla Terraform

resource "google_folder" "tf_gcp_folder" {
  display_name = "tf"
  parent = "organizations/447686549950"
}

# Second level GCP Folders - to host vanilla Terraform environment
resource "google_folder" "logging_env_tf_gcp_folder" {
  display_name = "iq9_logging_tf"
  parent = "folders/97206097866"
}

resource "google_folder" "sandbox_env_tf_gcp_folder" {
  display_name = "iq9_sandbox_tf"
  parent  = "folders/97206097866"
}

resource "google_folder" "dev_env_tf_gcp_folder" {
  display_name = "iq9_dev_tf"
  parent  = "folders/97206097866"
}

resource "google_folder" "prod_env_tf_gcp_folder" {
  display_name = "iq9_prod_tf"
  parent  = "folders/97206097866"
}

# Third level GCP Folders - to host vanilla Terraform apps
resource "google_folder" "dev_env_ari_gcp_folder" {
  display_name = "iq9_ari_vatanen_dev_tf"
  parent  = "folders/882276245846"
}

resource "google_folder" "prod_env_ari_gcp_folder" {
  display_name = "iq9_ari_vatanen_prod_tf"
  parent  = "folders/771423495270"
}

resource "google_folder" "dev_env_colin_gcp_folder" {
  display_name = "iq9_colin_mcrae_dev_tf"
  parent  = "folders/882276245846"
}

resource "google_folder" "prod_env_colin_gcp_folder" {
  display_name = "iq9_colin_mcrae_prod_tf"
  parent  = "folders/771423495270"
}