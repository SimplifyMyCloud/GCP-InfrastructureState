# Code Comment Headers

As the Terraform code itself is a form of human readable documentation, adding descriptive comment headers to all Terraform files ensure an extra level of information for the reader.

The goal is a newly on-boarded engineer is able to read the entire Infrastructure-as-code Git repo in two hours or less, and be able to whiteboard the basic layout of the infrastructure.  Rich comments along with the Terraform itself will tell this story.

---

First line of each file will contain a comment describing the role of the file in the Terraform workspace.  The comment is broken into cascading descriptions.

`# First Directory - Second Directory - Third Directory - Fourth Directory`

`# foundation - gcp projects - logging - log warehouse`

Example is a Terraform workspace contained in

`/foundation/gcp-projects/`

## Terraform Backend State - `log-warehouse-backend.tf`

```bash
# Foundation Layer - GCP Projects - GCS Backend for Terraform State
```

## GCP Projects Terraform files - `log-warehouse.tf`

```bash
# Foundation Layer - GCP Projects - Log Warehouse
```
