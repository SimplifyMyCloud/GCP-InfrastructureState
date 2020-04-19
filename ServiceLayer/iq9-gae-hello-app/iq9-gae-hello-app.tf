# Service Layer
# smc-hello-app

resource "google_cloud_run_service" "smc-hello" {
  name     = "smc-hello-tf"
  location = "us-west1"
  project  = "iq9-dev-bfc2"

  template {
    spec {
      containers {
        image = "gcr.io/iq9-dev-bfc2/helloworld:latest"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.smc-hello.location
  project  = google_cloud_run_service.smc-hello.project
  service  = google_cloud_run_service.smc-hello.name

  policy_data = data.google_iam_policy.noauth.policy_data
}
