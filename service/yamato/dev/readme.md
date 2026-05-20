# Service Layer — yamato / dev

The **dev environment** of the yamato wiki — its own dedicated directory and its
own set of Terraform states. Each subdirectory here is one independent state
(its own GCS backend) that instantiates a shared module from
[`../modules/`](../modules/) with dev values.

When `test`, `stage`, and `prod` activate, they become sibling directories under
[`../`](../) (`service/yamato/test/`, …) — never folded into dev via workspaces.

## States in this environment

| State | Focus / desired state |
| --- | --- |
| [`artifact-registry/`](./artifact-registry/) | A Docker repo to hold the app image; Artifact Registry + Cloud Build APIs enabled. |
| [`cloudsql/`](./cloudsql/) | Postgres 16 (private IP, smallest zonal tier), the `yamato` DB + `yamato_app` user, password in Secret Manager. |
| [`cloudrun/`](./cloudrun/) | The Cloud Run service, its runtime SA, and the Serverless VPC connector to reach Cloud SQL. Ingress locked to the LB. |
| [`frontdoor/`](./frontdoor/) | External HTTPS LB + IAP: public landing at `/`, IAP-gated wiki at `/wiki` for `@iq9.io`. |

## Apply order

```
artifact-registry  →  cloudsql  →  cloudrun  →  frontdoor
```

After `frontdoor`: create the `yamato-dev.iq9.io` A-record pointing at the LB IP
output, and wait for the managed certificate to go `ACTIVE`. Once the App Layer
image is built and pushed, flip the cloudrun `container_image` variable off the
`cloudrun/hello` placeholder.

## Foundation this depends on

- Project `iq9-gcp-dev-yamato` — [`foundation/gcp-projects/yamato/dev/`](../../../foundation/gcp-projects/yamato/dev/)
- VPC + PSA + the reserved connector range — [`foundation/gcp-networks/yamato/dev/`](../../../foundation/gcp-networks/yamato/dev/)

Each `<service>/` directory has its own readme with the full detail.
