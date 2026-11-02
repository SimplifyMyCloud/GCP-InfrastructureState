# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Org — organization policies (simplifymy.cloud, 933250405420)
# ---------------------------------------------------------------------------------------------------------------------
#
# The five boolean org policies enforced at the TOP of the Org, so they are
# inherited by every folder and project (no folder or project overrides them).
#
#   iam.disableServiceAccountKeyCreation   no NEW service-account keys anywhere
#   compute.requireOsLogin                 VMs use OS Login (IAM-controlled SSH)
#   compute.managed.requireOsLogin         same, managed-constraint version
#   compute.skipDefaultNetworkCreation     new projects get NO default VPC
#   compute.restrictXpnProjectLienRemoval  Shared-VPC host liens can't be removed casually
#
# Imported from the live Org on 2026-11-01.

locals {
  org_boolean_policies = toset([
    "iam.disableServiceAccountKeyCreation",
    "compute.requireOsLogin",
    "compute.managed.requireOsLogin",
    "compute.skipDefaultNetworkCreation",
    "compute.restrictXpnProjectLienRemoval",
  ])
}

resource "google_org_policy_policy" "boolean" {
  for_each = local.org_boolean_policies

  name   = "organizations/933250405420/policies/${each.value}"
  parent = "organizations/933250405420"

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

import {
  for_each = local.org_boolean_policies
  to       = google_org_policy_policy.boolean[each.value]
  id       = "organizations/933250405420/policies/${each.value}"
}
