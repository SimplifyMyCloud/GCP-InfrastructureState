# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — gcp-org — smc-tf-foundation-sa org grants
# ---------------------------------------------------------------------------------------------------------------------
#
# smc-tf-foundation-sa is PLAN-ONLY by default (decided 2026-11-02). It can read
# everything in the Org, so `terraform plan` works in every foundation/ directory,
# but it cannot change GCP. Its only write access is to the state bucket's
# objects, for state locks (iam/smc-ops/smc-ops/iam_smc_ops_state_bucket.tf).
#
# Change window: to let the SA apply, chris@ (NOT the SA) opens a window here.
#   1. Set tf_foundation_sa_write_roles = local.tf_foundation_sa_change_window_roles
#   2. Apply THIS directory as chris@: unset GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
#      and GOOGLE_BACKEND_IMPERSONATE_SERVICE_ACCOUNT first. The SA can't grant
#      itself roles.
#   3. Plan and apply the change as the SA, as usual.
#   4. Close the window: set it back to toset([]) and apply this directory as chris@.
# See foundation/readme.md, "Change windows".

locals {
  # Always on: read the whole Org.
  tf_foundation_sa_read_roles = toset([
    "roles/viewer",                     # read nearly every resource's config
    "roles/iam.securityReviewer",       # read every IAM policy (org, folders, projects, buckets, SAs …)
    "roles/orgpolicy.policyViewer",     # read org policies
    "roles/iam.organizationRoleViewer", # read org custom roles
    "roles/browser",                    # read the Org / folder / project hierarchy
    "roles/firebaserules.viewer",       # read Firebase rulesets (not in roles/viewer)
    "roles/storage.bucketViewer",       # read bucket config where a bucket's own IAM hides it from viewer (no object access)
  ])

  # The broad set the SA used for the initial import (2026-11-01). It is granted
  # only during a change window.
  tf_foundation_sa_change_window_roles = toset([
    "roles/owner",
    "roles/resourcemanager.organizationAdmin",
    "roles/orgpolicy.policyAdmin",
    "roles/billing.user",
    "roles/iam.organizationRoleAdmin",
  ])

  # Closed (no write roles). Set to local.tf_foundation_sa_change_window_roles to open a window.
  tf_foundation_sa_write_roles = toset([])
}

resource "google_organization_iam_member" "tf_foundation_sa_read" {
  for_each = local.tf_foundation_sa_read_roles

  org_id = "933250405420"
  role   = each.value
  member = "serviceAccount:smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com"
}

resource "google_organization_iam_member" "tf_foundation_sa_write" {
  for_each = local.tf_foundation_sa_write_roles

  org_id = "933250405420"
  role   = each.value
  member = "serviceAccount:smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com"
}
