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
| [`artifact-registry/`](./artifact-registry/) | A Docker repo to hold the app image. |
| [`cloudsql/`](./cloudsql/) | Postgres 16 (private IP, smallest zonal tier), the `yamato` DB + `yamato_app` user, password in Secret Manager. |
| [`cloudrun/`](./cloudrun/) | Two Cloud Run services (public + IAP-gated wiki), shared runtime SA, Direct VPC egress to Cloud SQL. Ingress locked to the LB. |
| [`frontdoor/`](./frontdoor/) | External HTTPS LB + IAP: public landing at `/`, IAP-gated wiki at `/wiki` for `@iq9.io`. Two NEGs → the two services. |
| [`logging/`](./logging/) | Per-app performance + security logging: log-based metrics, alert policies, and a dashboard. |

## Apply order

```
artifact-registry  →  cloudsql  →  cloudrun  →  frontdoor
```

`logging/` is independent and can be applied any time after `cloudrun/`.

After `frontdoor`: create the `yamato-dev.iq9.io` A-record pointing at the LB IP
output, and wait for the managed certificate to go `ACTIVE`. Once the App Layer
image is built and pushed, deploy it with `gcloud run services update` on **both**
Cloud Run services — the cloudrun state ignores the running image, so app versions
ship via gcloud/CI, not Terraform.

## Foundation this depends on

- Project `iq9-gcp-dev-yamato` — [`foundation/gcp-projects/yamato/dev/`](../../../foundation/gcp-projects/yamato/dev/)
- VPC + app subnet + PSA range — [`foundation/networks/yamato/dev/`](../../../foundation/networks/yamato/dev/)
  (Cloud Run uses Direct VPC egress onto the app subnet; no VPC connector.)

Each `<service>/` directory has its own readme with the full detail.
