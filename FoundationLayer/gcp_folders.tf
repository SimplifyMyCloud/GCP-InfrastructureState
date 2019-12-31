# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Folders
# ensures GCP Folders per Infrastructure Environment
# for the Foundation Layer development environment, ensure a random prefix is included to avoid naming collisions
# and naming reservations.  GCP Folders and GCP Projects are long lived naming reservations
# ---------------------------------------------------------------------------------------------------------------------
# development environment
resource "google_folder" "gcp_folder_dev_env" {
  display_name = "development"
  parent       = "organizations/${var.gcp_org_id}"
}

# test environment
resource "google_folder" "gcp_folder_test_env" {
  display_name = "test"
  parent       = "organizations/${var.gcp_org_id}"
}

# stage environment
resource "google_folder" "gcp_folder_stage_env" {
  display_name = "stage"
  parent       = "organizations/${var.gcp_org_id}"
}

# production environment
resource "google_folder" "gcp_folder_production_env" {
  display_name = "production"
  parent       = "organizations/${var.gcp_org_id}"
}



