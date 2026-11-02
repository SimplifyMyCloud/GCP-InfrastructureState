# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — smc-ops / smc-ops — service accounts
# ---------------------------------------------------------------------------------------------------------------------
#
#   smc-tf-foundation-sa   The dedicated Terraform identity for /foundation, created
#                          2026-11-01. After the first full import/apply it is made
#                          read-only (plan-only); see foundation/readme.md.
#
#   smc-ops-tf-org-admin   PRE-EXISTING, BEING RETIRED (decided 2026-11-02; nothing uses it).
#                          Stage 1 (2026-11-02): org-admin binding removed, SA DISABLED,
#                          its one user-managed key (2603638549a0…, from 2020) disabled
#                          with gcloud. A disabled SA can't authenticate, with or
#                          without keys. Reversible: set disabled = false.
#                          (Its other key is Google-managed and auto-rotating; it can't
#                          be disabled or downloaded and goes away with the SA.)
#                          Stage 2 (on/after 2026-12-02, after a 30-day quiet period):
#                          delete the user-managed key (gcloud), then remove this SA and
#                          its two chris@ grants below from code and apply in a change
#                          window.

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
  disabled     = true # retiring: stage 1 of 2, see header
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
