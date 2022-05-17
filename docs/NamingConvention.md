# GCP Naming Convention

## Org Domain

_iq9.io_

## Base

Standard:

3 Letters representing the company name

_iq9_

Optional:

3 letters representing the business unit 

## Top Level Folder

Standard:

`{base}-{environments}`

`iq9-sandbox` - `iq9-dev` - `iq9-stage` - `iq9-production` - `iq9-logging` - `iq9-shared` - `iq9-ops`

Optional:

`{business unit}`

&darr;

`{business unit}-{environments}`

Example:

`fintech`

&darr;

`fintech-sandbox` - `fintech-dev` - `fintech-stage` - `fintech-production` - `fintech-logging` - `fintech-shared` - `fintech-ops`

---

`customer service`

&darr;

`cusrv-sandbox` - `cusrv-dev` - `cusrv-stage` - `cusrv-production` - `cusrv-logging` - `cusrv-shared` - `cusrv-ops`

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

`base-environment-description-number`

Example:

`iq9-dev-bmw-app-01`

## GCP Networks

[GCP docs link](https://cloud.google.com/architecture/best-practices-vpc-design#naming)

Standard:
 * Company name: IQ9.io: iq9
 * Region code: northamerica-northeast1: na-ne1, europe-west1: eu-we1
 * Environment codes: sndbx, dev, stage, prod

VPC network
 * syntax: `{company name}-{description-label}-{environment-label}-{seq#}`
 * example: `iq9-hostnet-dev-vpc-1`

Subnet
 * syntax: `{company-name}-{environment}-{description-label}-{region/zone-label}`
 * example: `iq9-dev-bmw-app-na-ne1-dev-subnet`

 Firewall rule
 * syntax: `{company-name}-{environment}-{description-label}{source-label}-{dest-label}-{protocol}-{port}-{action}`
 * example: `iq9-dev-bmw-app-internet-internal-tcp-80-allow-rule`

 IP route
 * syntax: `{priority}-{VPC-label}-{tag}-{next hop}`
 * example: `1000-iq9-dev-vpc-1-int-gw`
