# ---------------------------------------------------------------------------------------------------------------------
# Service Layer — module: cloudrun
# The Cloud Run service that runs the yamato app and its dedicated runtime service
# account. The service reaches Cloud SQL over private IP via Direct VPC egress
# (attached straight to the app subnet) — NOT a Serverless VPC Access connector,
# which is incompatible with the enforced compute.requireOsLogin org policy (its
# managed VMs can't provision, so the connector lands in ERROR). Ingress is locked
# to the external HTTPS load balancer; the front door (LB + IAP) is provisioned by
# the frontdoor state.
# ---------------------------------------------------------------------------------------------------------------------

# APIs (run, vpcaccess) are enabled by the foundation project state,
# foundation/gcp-projects/yamato/dev/ — not here. The Service Layer assumes they
# are already on.

# ---------------------------------------------------------------------------------------------------------------------
# Runtime service account — the identity the container runs as.
# ---------------------------------------------------------------------------------------------------------------------
#
# Dedicated, least-privilege: it gets only roles/cloudsql.client (to use the
# Cloud SQL connector) and accessor on the DB password secret. Nothing else.
resource "google_service_account" "runtime" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "yamato Cloud Run runtime SA (${var.service_name})"
}

resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

# This state grants its own SA access to the secret the cloudsql state created —
# each state owns its IAM. Referenced by secret ID (string), so no cross-state
# resource dependency.
resource "google_secret_manager_secret_iam_member" "accessor" {
  project   = var.project_id
  secret_id = var.password_secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.runtime.email}"
}

# ---------------------------------------------------------------------------------------------------------------------
# The Cloud Run service.
# ---------------------------------------------------------------------------------------------------------------------
#
# - ingress = internal-and-cloud-load-balancing: the public cannot hit the
#   *.run.app URL; only the external HTTPS LB (front door) can route here.
# - vpc_access: Direct VPC egress onto the app subnet; egress PRIVATE_RANGES_ONLY
#   so only RFC1918 traffic (Cloud SQL private IP) routes through the VPC, while
#   public egress goes direct.
# - DB_PASS is injected from Secret Manager as a secret env var; the other DB
#   parameters are plain env vars. The app uses the Cloud SQL connector with
#   INSTANCE_CONNECTION_NAME over the private path.
# - container_image defaults to the GCP hello image so this stands up before the
#   App Layer exists; flip the variable to the real image after the first build.
resource "google_cloud_run_v2_service" "this" {
  project  = var.project_id
  name     = var.service_name
  location = var.region
  ingress  = var.ingress
  labels   = var.labels

  deletion_protection = var.deletion_protection

  template {
    service_account = google_service_account.runtime.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    vpc_access {
      egress = var.vpc_egress
      network_interfaces {
        network    = var.network_name
        subnetwork = var.subnet_name
      }
    }

    containers {
      image = var.container_image

      ports {
        container_port = var.container_port
      }

      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
      }

      env {
        name  = "INSTANCE_CONNECTION_NAME"
        value = var.db_connection_name
      }
      env {
        name  = "DB_NAME"
        value = var.db_name
      }
      env {
        name  = "DB_USER"
        value = var.db_user
      }
      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = var.password_secret_id
            version = "latest"
          }
        }
      }
    }
  }

  depends_on = [google_secret_manager_secret_iam_member.accessor]
}

# ---------------------------------------------------------------------------------------------------------------------
# Invoker binding.
# ---------------------------------------------------------------------------------------------------------------------
#
# With ingress locked to the LB, only the front door can reach the service, so
# granting run.invoker to allUsers does NOT expose the service publicly — IAP at
# the LB still enforces identity. If org policy forbids allUsers bindings, set
# invoker_members to a narrower principal.
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  for_each = toset(var.invoker_members)

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = each.value
}
