# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Folders
# ensures GCP Folders per Infrastructure Environment for the Foundation Layer
# ---------------------------------------------------------------------------------------------------------------------
module "folders" {
  source  = "terraform-google-modules/folders/google"
  version = "~> 2.0"

  parent  = "organizations/447686549950"

  names = [
    "dev",
    "test",
    "staging",
    "production",
    "ops",
  ]

  set_roles = true

  per_folder_admins = [
    "group:gcp-developers@iq9.io",
    "group:gcp-test@iq9.io",
    "group:gcp-stage@iq9.io",
    "group:gcp-ops@iq9.io"
  ]

  all_folder_admins = [
    "group:gcp-ops@iq9.io",
  ]
}