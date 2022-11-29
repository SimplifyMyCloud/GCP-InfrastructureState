---
name: Foundation Layer ToDo GCP Project
about: ToDo for the GCP Foundation Layers GCP Projects
title: "[WIP] Ensure a GCP Project named {GCP PROJECT NAME} exists in the {ENV} environment"
labels: ["ToDo", "WIP", "gcp-project"]
assignees:
  - first
  - second

---

## Desired GCP Infrastructure State

- [ ] Ensure a GCP Project exists and is named {GCP RESOURCE NAME}

- [ ] Ensure the GCP Project is created under the environment GCP Folder { `Sandbox` `Dev` `Production` `Ops` `Logging` }

---

The Terraform workspace will be contained in a Git directory here:

`foundation/gcp-projects/{ENV}/{GCP_PROJECT_NAME}`

- [ ] The Terraform workspace state file will be contained in a GCS directory here:

`foundation/gcp-projects/{ENV}/{GCP_PROJECT_NAME}`

---

## Current GCP Infrastructure State

This GCP Project does not exist on the GCP API
