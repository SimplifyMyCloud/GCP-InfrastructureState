# Code Comment Headers

## As the Terraform code itself is a form of human readable documentation, adding descriptive comment headers to all Terraform files ensure an extra level of information for the reader.

## The goal is a newly onboarded engineer is able to read the entire Infrastructure-as-code Git repo in two hours or less, and be able to whiteboard the basic layout of the infrastructure.

---

### Terraform Backend State - `{file_name}_gcs_backend.tf`

```bash
# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer - GCP Logging Project
# GCS Backend for Terraform State
# ---------------------------------------------------------------------------------------------------------------------
```

### GCP Projects Terraform files - `gcp_projects_logging_log_warehouse.tf`

```bash
# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects
# ensures GCP Projects per Infrastructure Environment
# for the Foundation Layer development environment, ensure a random prefix is included to avoid naming collisions
# and naming reservations.  GCP Projects are long lived naming reservations.
# ---------------------------------------------------------------------------------------------------------------------
# log warehouse environment
# ensure the GCP Project - `gcp_project_name`
```

### GCP Projects Terraform files - `gcp_projects_logging_log_warehouse.tf`

```bash
# ---------------------------------------------------------------------------------------------------------------------
# Foundation Layer
# GCP Projects
# ensures GCP Projects per Infrastructure Environment
# for the Foundation Layer development environment, ensure a random prefix is included to avoid naming collisions
# and naming reservations.  GCP Projects are long lived naming reservations.
# ---------------------------------------------------------------------------------------------------------------------
# log warehouse environment
# ensure the GCP Project - `gcp_project_name`
```