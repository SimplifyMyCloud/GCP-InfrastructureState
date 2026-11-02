# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — gcp-org — smc-tf-foundation-sa deployment grants
# ---------------------------------------------------------------------------------------------------------------------
#
# NEW grants, not imports. They give the dedicated Terraform SA enough power to
# import and manage every resource type in the Org during the initial deploy
# (decided 2026-11-01: broad set).
#
# ⚠️ TEMPORARY. Once every directory under foundation/ has a zero-diff plan, this
# set is replaced with a read-only one (plan-only) and the SA can no longer
# change the Org. See foundation/readme.md, "Making the SA read-only".

locals {
  tf_foundation_sa_deploy_roles = toset([
    "roles/owner",
    "roles/resourcemanager.organizationAdmin",
    "roles/orgpolicy.policyAdmin",
    "roles/billing.user",
    "roles/iam.organizationRoleAdmin",
  ])
}

resource "google_organization_iam_member" "tf_foundation_sa" {
  for_each = local.tf_foundation_sa_deploy_roles

  org_id = "933250405420"
  role   = each.value
  member = "serviceAccount:smc-tf-foundation-sa@smc-ops.iam.gserviceaccount.com"
}
