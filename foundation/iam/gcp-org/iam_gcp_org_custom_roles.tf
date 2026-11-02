# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# IAM — gcp-org — org-level custom roles
# ---------------------------------------------------------------------------------------------------------------------
#
# Three narrow read-only roles for the cis-ig1-auditor SA. They fill gaps that
# predefined viewer roles leave open (IAP settings, SA key listing, bucket IAM).
#
# Originally created by a separate "CIS IG1 audit module" Terraform. Ownership
# moved to this repo on 2026-11-01. ⚠️ Run `terraform state rm` for these in that
# module's state so the two never fight (see readme.md).

resource "google_organization_iam_custom_role" "cis_ig1_audit_iap_reader" {
  org_id      = "933250405420"
  role_id     = "cisIg1Audit2IapReader"
  title       = "CIS IG1 Audit — IAP Settings Reader"
  description = "Read-only. Created by the CIS IG1 audit module; removed on terraform destroy."
  stage       = "GA"
  permissions = ["iap.web.getSettings"]
}

import {
  to = google_organization_iam_custom_role.cis_ig1_audit_iap_reader
  id = "organizations/933250405420/roles/cisIg1Audit2IapReader"
}

resource "google_organization_iam_custom_role" "cis_ig1_audit_key_reader" {
  org_id      = "933250405420"
  role_id     = "cisIg1Audit2KeyReader"
  title       = "CIS IG1 Audit — Service Account Key Reader"
  description = "Read-only. Created by the CIS IG1 audit module; removed on terraform destroy."
  stage       = "GA"
  permissions = ["iam.serviceAccountKeys.list"]
}

import {
  to = google_organization_iam_custom_role.cis_ig1_audit_key_reader
  id = "organizations/933250405420/roles/cisIg1Audit2KeyReader"
}

resource "google_organization_iam_custom_role" "cis_ig1_audit_storage_reader" {
  org_id      = "933250405420"
  role_id     = "cisIg1Audit2StorageReader"
  title       = "CIS IG1 Audit — Storage Reader"
  description = "Read-only. Created by the CIS IG1 audit module; removed on terraform destroy."
  stage       = "GA"
  permissions = ["storage.buckets.get", "storage.buckets.getIamPolicy", "storage.buckets.list"]
}

import {
  to = google_organization_iam_custom_role.cis_ig1_audit_storage_reader
  id = "organizations/933250405420/roles/cisIg1Audit2StorageReader"
}
