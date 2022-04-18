# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects
# ensures GCP Projects per Infrastructure Environment
# for the Foundation Layer development environment, ensure a random prefix is included to avoid naming collisions
# and naming reservations.  GCP Projects are long lived naming reservations.
# ---------------------------------------------------------------------------------------------------------------------
# log warehouse environment
# ensure the GCP Project
resource "google_project" "gcp_project_iq9_log_warehouse" {
  name                = "iq9_log_warehouse_00"
  project_id          = "iq9_log_warehouse_00"
  folder_id           = "1074889022289"
  billing_account     = "01AE65-A7583F-D9EB1A"
  skip_delete         = false
  auto_create_network = false
}

resource "google_project_service" "cloudbilling_api" {
  project = "iq9_log_warehouse_00"
  service = "cloudbilling.googleapis.com"
}

resource "google_project_service" "oslogin_api" {
  project = "iq9_log_warehouse_00"
  service = "oslogin.googleapis.com"
}

resource "google_project_service" "iam_api" {
  project = "iq9_log_warehouse_00"
  service = "iam.googleapis.com"
}

resource "google_project_service" "serviceusage_api" {
  project = "iq9_log_warehouse_00"
  service = "serviceusage.googleapis.com"
}

resource "google_project_service" "cloudresourcemanager_api" {
  project = "iq9_log_warehouse_00"
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "storage-component_api" {
  project = "iq9_log_warehouse_00"
  service = "storage-component.googleapis.com"
}

resource "google_project_service" "logging_api" {
  project = "iq9_log_warehouse_00"
  service = "logging.googleapis.com"
}

resource "google_project_service" "clouderrorreporting_api" {
  project = "iq9_log_warehouse_00"
  service = "clouderrorreporting.googleapis.com"
}

resource "google_project_service" "monitoring_api" {
  project = "iq9_log_warehouse_00"
  service = "monitoring.googleapis.com"
}
