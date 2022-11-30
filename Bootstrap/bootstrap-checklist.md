# Bootstrap Checklist

### A checklist of items in order that complete a GCP Bootstrap

---

## Domain Registration

- [ ] Register domain

---

## GCP Org Policy

- [ ] Document desired enforced policies
- [ ] Add policys to Terraform

---

## GCP Org level Scaffolding Ops

- [ ] Create GCP Project - Ops Scaffolding
- [ ] Create Org level Service Account for Terraform
- [ ] Create a GCE VM associated to org level SA
- [ ] Login to GCE VM to run `gcloud` cli

---

## Operations Environment

- [ ] Create GCP Folder - operations
- [ ] Create GCP Project - `terraform org ops`
- [ ] Create GCE VM associated to org level SA
- [ ] Terraform: GCS Buckets for Terraform state

---

_all steps from here are ensured via Terraform_

---

## Logging Environment

- [ ] Log Warehouse
- [ ] Audit Log Warehouse
- [ ] Org level log sinks

---

## Top Level GCP Folders

---

