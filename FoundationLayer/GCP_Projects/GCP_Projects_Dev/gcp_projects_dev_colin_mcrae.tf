# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects
# ensures GCP Projects per Infrastructure Environment
# for the Foundation Layer development environment, ensure a random prefix is included to avoid naming collisions
# and naming reservations.  GCP Projects are long lived naming reservations.
# ---------------------------------------------------------------------------------------------------------------------
# development environment
resource "google_project" "gcp_project_dev_colin_mcrae" {
  name                = "colin_mcrae_dev_tf"
  project_id          = "colin_mcrae_dev_tf"
  folder_id           = "918772134080"
  billing_account     = "01AE65-A7583F-D9EB1A"
  skip_delete         = false
  auto_create_network = true
}

resource "google_project_service" "cloudbilling_api" {
  project = "colin_mcrae_dev_tf"
  service = "cloudbilling.googleapis.com"
}

resource "google_project_service" "compute_api" {
  project = "colin_mcrae_dev_tf"
  service = "compute.googleapis.com"
}

resource "google_project_service" "oslogin_api" {
  project = "colin_mcrae_dev_tf"
  service = "oslogin.googleapis.com"
}

resource "google_project_service" "container_api" {
  project = "colin_mcrae_dev_tf"
  service = "container.googleapis.com"
}

resource "google_project_service" "iam_api" {
  project = "colin_mcrae_dev_tf"
  service = "iam.googleapis.com"
}

resource "google_project_service" "serviceusage_api" {
  project = "colin_mcrae_dev_tf"
  service = "serviceusage.googleapis.com"
}

resource "google_project_service" "cloudresourcemanager_api" {
  project = "colin_mcrae_dev_tf"
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "run_api" {
  project = "colin_mcrae_dev_tf"
  service = "run.googleapis.com"
}

resource "google_project_service" "cloudbuild_api" {
  project = "colin_mcrae_dev_tf"
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "storage-component_api" {
  project = "colin_mcrae_dev_tf"
  service = "storage-component.googleapis.com"
}

resource "google_project_service" "logging_api" {
  project = "colin_mcrae_dev_tf"
  service = "logging.googleapis.com"
}

resource "google_project_service" "clouderrorreporting_api" {
  project = "colin_mcrae_dev_tf"
  service = "clouderrorreporting.googleapis.com"
}

resource "google_project_service" "monitoring_api" {
  project = "colin_mcrae_dev_tf"
  service = "monitoring.googleapis.com"
}
