# GCP Naming Convention

Updated 2026-11-02 to match the live **simplifymy.cloud** Org. Where existing names don't follow the standard, they're listed as exceptions: project IDs can never be renamed, so the exceptions stay.

## Org domain

_simplifymy.cloud_ (Org `933250405420`)

## Base

3 letters representing the company name:

_smc_

## Folders

`{base}-{environment}`, directly under the Org:

`smc-ops` · `smc-dev` · `smc-prod`

## GCP Projects

[GCP docs link](https://cloud.google.com/resource-manager/docs/creating-managing-projects)

_Globally unique across all of GCP and all GCP customers._

Project ID requirements:

 * Must be 6 to 30 characters in length.
 * Can only contain lowercase letters, numbers, and hyphens.
 * Must start with a letter.
 * Cannot end with a hyphen.
 * Cannot be in use or previously used; this includes deleted projects.
 * Cannot contain restricted strings, such as google and ssl.

Standard:

`{base}-{environment}-{app}`

Actual:

| Project | Note |
| --- | --- |
| `smc-prod-bbmrc`, `smc-prod-bigbarkozspeedshop`, `smc-prod-caballerosflyingclub`, `smc-prod-madeinwestgermany`, `smc-prod-olympic-flying-club`, `smc-prod-psmtherapy`, `smc-prod-simplifymycloud`, `smc-prod-trilliumhiring` | follow the standard |
| `smc-ops` | exception: the ops project predates the standard (would be `smc-ops-platform`) |
| `smc-dental-knox` | exception: missing the `prod` segment |
| `simplifymycloud-dev` | exception: predates the `smc` base |

## Service accounts

`{base}-{purpose}-sa`, e.g. `smc-tf-foundation-sa` (the Terraform identity). `smc-ops-tf-org-admin` predates this and is due to be retired.

## GCS buckets

`{project}-{purpose}`, e.g. `smc-ops-tf-state`. Google-created buckets (`<project>.appspot.com`, `staging.<project>.appspot.com`) keep their names.

## GCP IAM Custom Roles

[GCP docs link](https://cloud.google.com/iam/docs/understanding-custom-roles)

Standard:
  * syntax: `{base}-iam-{environment}-{rolename}-{rw | ro}`
  * example: `smc-iam-dev-gce-rw`

Exception: the 3 org roles `cisIg1Audit2{IapReader,KeyReader,StorageReader}` (camelCase, created by the CIS IG1 audit module).

## GCP Networks

[GCP docs link](https://cloud.google.com/architecture/best-practices-vpc-design#naming)

Today every VPC in the Org is a Google-created auto-mode `default` network. These rules apply to any **new** VPC.

Standard:
 * Base name: simplifymy.cloud → `smc`
 * Region code: us-west1 → `us-we1`
 * Environment codes: `ops`, `dev`, `test`, `stage`, `prod`

VPC network
 * syntax: `{base}-vpc-{environment}-{app}-{region}`
 * example: `smc-vpc-prod-bbmrc-us-we1`

Subnet
 * syntax: `{base}-subnet-{environment}-{app}`
 * example: `smc-subnet-prod-bbmrc`
 * exception: `gitlab-lb-test-01-sub` in `simplifymycloud-dev`

Firewall rule
 * syntax: `{base}-fw-{environment}-{description-label}-{source-label}-{dest-label}-{protocol}-{port}-{action}`
 * example: `smc-fw-dev-gitlab-internet-internal-tcp-443-allow`
 * existing: `smc-fw-iap-22`, `smc-fw-public-22` (short form); Google's `default-allow-*` rules

IP route
 * syntax: `{base}-route-{origin}-{destination}`
 * example: `smc-route-bbmrc-internet`
