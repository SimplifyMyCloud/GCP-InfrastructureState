# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-ops / smc-ops — service accounts
# ---------------------------------------------------------------------------------------------------------------------
#
#   smc-tf-foundation-sa   The dedicated Terraform identity for /foundation, created
#                          2026-11-01. After the first full import/apply it is made
#                          read-only (plan-only); see foundation/readme.md.
#
#   smc-ops-tf-org-admin   PRE-EXISTING. Holds roles/resourcemanager.organizationAdmin
#                          (iam_smc_ops_project.tf) and has 2 user-managed keys.
#                          Imported as-is; listed as a security finding in readme.md.

resource "google_service_account" "smc_tf_foundation_sa" {
  project      = "smc-ops"
  account_id   = "smc-tf-foundation-sa"
  display_name = "SMC Terraform Foundation SA"
  description  = "Dedicated Terraform identity for /foundation. Becomes read-only after the initial import/deploy."
}

import {
  to = google_service_account.smc_tf_foundation_sa
  id = "projects/smc-ops/serviceAccounts/smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com"
}

resource "google_service_account" "smc_ops_tf_org_admin" {
  project      = "smc-ops"
  account_id   = "smc-ops-tf-org-admin"
  display_name = "smc-ops-tf-org-admin"
  description  = "GCP Org Admin SA for Terraform"
}

import {
  to = google_service_account.smc_ops_tf_org_admin
  id = "projects/smc-ops/serviceAccounts/smc-ops-tf-org-admin@smc-ops.iam.gserviceaccount.com"
}

# --- who may act as these SAs ---------------------------------------------------------------------------------------

# NEW: lets chris@ run Terraform AS smc-tf-foundation-sa (impersonation via
# GOOGLE_IMPERSONATE_SERVICE_ACCOUNT / GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT).
resource "google_service_account_iam_member" "smc_tf_foundation_sa_token_creator_chris" {
  service_account_id = google_service_account.smc_tf_foundation_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:chris@simplifymy.cloud"
}

# Pre-existing grants on smc-ops-tf-org-admin, imported as-is.
resource "google_service_account_iam_member" "smc_ops_tf_org_admin_sa_admin_chris" {
  service_account_id = google_service_account.smc_ops_tf_org_admin.name
  role               = "roles/iam.serviceAccountAdmin"
  member             = "user:chris@simplifymy.cloud"
}

import {
  to = google_service_account_iam_member.smc_ops_tf_org_admin_sa_admin_chris
  id = "projects/smc-ops/serviceAccounts/smc-ops-tf-org-admin@smc-ops.iam.gserviceaccount.com roles/iam.serviceAccountAdmin user:chris@simplifymy.cloud"
}

resource "google_service_account_iam_member" "smc_ops_tf_org_admin_sa_user_chris" {
  service_account_id = google_service_account.smc_ops_tf_org_admin.name
  role               = "roles/iam.serviceAccountUser"
  member             = "user:chris@simplifymy.cloud"
}

import {
  to = google_service_account_iam_member.smc_ops_tf_org_admin_sa_user_chris
  id = "projects/smc-ops/serviceAccounts/smc-ops-tf-org-admin@smc-ops.iam.gserviceaccount.com roles/iam.serviceAccountUser user:chris@simplifymy.cloud"
}
