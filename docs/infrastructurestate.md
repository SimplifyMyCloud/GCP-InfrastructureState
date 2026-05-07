# Infrastructure State

The shape, granularity, and change-control posture of the Terraform state files in this repo. This document is the *why* behind the foundation layer; the per-directory readmes are the *what*.

## The Foundation Layer

The Foundation Layer is the bottom of the infrastructure tree — the resources every other layer assumes already exist. GCP folders, GCP projects, organization-level IAM bindings, the org's networking spine, and the org-scoped log sink all live here. Once a foundation resource exists, it lives forever; foundation deletions are essentially never approved.

Above the foundation sit the **Service Layer** (shared platform services — observability, image bakery, CI/CD, secrets) and the **Application Layer** (the customer-facing products). Both layers depend on the foundation; the foundation depends on nothing inside the repo.

Foundation state is the most rarely-touched, most heavily-reviewed Terraform in the repo. A foundation change is, by definition, a change to the org-shape — a new environment, a renamed project, a re-parented folder. The reviewer's default disposition is to push back hard and ask whether the new shape is really necessary, or whether the work could fit inside something that already exists.

## Hardcoded values, no variables

Every value in foundation `*.tf` files is hardcoded. No `variables.tf`, no `*.tfvars`, no module indirection. Reading the file tells you exactly which resources exist and where they live, with nothing to chase down.

The cost is that values like the parent folder ID `147640766174` appear in every foundation file that needs them; the benefit is that the file is self-documenting and a newly-onboarded engineer can read the entire foundation layer in an afternoon and understand what's deployed. Variables and modules are appropriate one layer up — at the Service Layer and Application Layer — where the same shape is repeated across environments. At the foundation, where each resource is unique and permanent, hardcoding wins.

## State granularity strategy

State granularity *increases* as you climb the infrastructure tree.

At the very bottom — `foundation/gcp-folders/` — five folder resources live in a single state file. They're siblings, with no cross-references, no nested ordering, and no realistic blast-radius concern: if a `terraform apply` here goes wrong, the worst case is recreating folders that have nothing inside them yet. One state for five resources is the right choice.

One layer up — `foundation/gcp-projects/` — state breaks down per environment subdirectory. Projects in `dev/` are independent of projects in `prod/`, and the audit trails should be too: a developer should not be touching prod state, and a prod-impacting plan should not have to be reviewed alongside unrelated dev churn.

At the Service Layer, granularity goes finer still — typically one state per service per environment. The Application Layer goes finest of all, with state granularity matching the deployment unit (one state per app per environment, sometimes one state per microservice).

The general rule: **state boundaries follow blast-radius boundaries.** Resources that share a failure domain share a state file; resources that don't, don't.

## Change-control posture

Every layer has its own review bar, and the bar gets higher as you descend.

Foundation Layer changes require a minimum of **3 PR approvals from the foundation reviewers group**. Every foundation change is, by definition, a change to the org-shape. The reviewers' job is to push back: is this new shape really necessary? Could this fit inside an existing environment, project, or folder? Foundation *additions* are rare exceptions to the steady-state expectation. Foundation *deletions* are essentially never approved — once a folder, project, or org-level IAM binding exists, it almost always stays.

Service Layer changes require 2 reviewer approvals from the platform team. Application Layer changes follow per-app CODEOWNERS rules with 1 reviewer typically sufficient.

If a `terraform plan` on any foundation state ever shows drift, the audit log is the next stop — drift on rarely-changed state usually means somebody has touched the org by hand, and that's a finding worth tracing.

## Bootstrap-created resources

A small number of foundation resources predate the Terraform that manages them. The `iq9` top-level folder, the `ops` and `logs` environment folders, the `iq9-bootstrap` project, the `iq9-ops-iac` project, and the `iq9-iac-ops-tf-state-bucket` GCS bucket were all created by hand during bootstrap, before any Terraform state existed to capture them.

These resources are brought under management with `terraform import` the first time their owning state runs. Once imported, they're indistinguishable from net-new resources — the state file owns them, drift is detected normally, and any subsequent change goes through the standard review process. The fact that they were born by hand is a historical detail, not an ongoing exception.

The full bootstrap procedure lives in `Bootstrap/bootstrap-playbook.md`.
