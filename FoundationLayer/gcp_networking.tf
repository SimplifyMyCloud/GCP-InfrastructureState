# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP networking state
# ---------------------------------------------------------------------------------------------------------------------

# ensure data gathered from default project

data  "google_project"  "project" {}

output  "GCP network project output"  {
  value = "a GCP project named ${data.google_project.project.name} has the id ${data.google_project.project.number}"
}