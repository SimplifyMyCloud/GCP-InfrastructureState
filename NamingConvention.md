# GCP Naming Convention

## Org Domain

_iq9.io_

## Base

3 Letters representing the company name

_iq9_

## Top Level Folder

`{base}-{environments}`

`iq9-sandbox` - `iq9-dev` - `iq9-production` - `iq9-logging` - `iq9-ops`

## GCP Projects

[GCP docs link](https://cloud.google.com/resource-manager/docs/creating-managing-projects)

_Globally unique across all of GCP and GCP customers_

_The ending number 00-10 is a best practice for the scenario where a new GCP Project must be created and migrated (A/B) to accommodate a not fixable error with a GCP Project._

Project ID requirements:

 * Must be 6 to 30 characters in length.
 * Can only contain lowercase letters, numbers, and hyphens.
 * Must start with a letter.
 * Cannot end with a hyphen.
 * Cannot be in use or previously used; this includes deleted projects.
 * Cannot contain restricted strings, such as google and ssl.

Standard:

`{base}-gcp-{environment}-{app}`

Actual:

`iq9-ops-01` - iq9 Operations Environment
`iq9-gcp-prod-bmwapp` - Project Name for the application

## GCP Networks

[GCP docs link](https://cloud.google.com/architecture/best-practices-vpc-design#naming)

Standard:
 * Company name: iq9.io: iq9
 * Region code: europe-west3: eu-we3
 * Environment codes: sndbx, dev, test, stage, prod

VPC network
 * syntax: `{company}-vpc-{environment-label}-{region}`
 * example: `iq9-vpc-prod-eu-west3`

Subnet
 * syntax: `{company}-subnet-{environment-label}-{app}`
 * example: `iq9-subnet-prod-bmwapp`

 Firewall rule
 * syntax: `{company}-fw-{environment}-{description-label}{source-label}-{dest-label}-{protocol}-{port}-{action}`
 * example: `iq9-fw-dev-bmwapp-internet-internal-tcp-80-allow`

 IP route
 * syntax: `{company}-route-{origin}-{destination}`
 * example: `iq9-route-bmwapp-internet`
