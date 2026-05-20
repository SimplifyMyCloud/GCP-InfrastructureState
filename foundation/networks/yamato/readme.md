# Foundation Layer — yamato Networks

The per-environment VPCs that host the `yamato` application. One VPC per project, no Shared VPC, no host/service split. Each environment gets its own state with its own backend prefix, so a change to `dev` never touches `prod` planning.

For the broader design philosophy — hardcoded values, state granularity, and change-control posture — see [`docs/infrastructurestate.md`](../../../docs/infrastructurestate.md).

## Layout

```
foundation/gcp-networks/yamato/
├── readme.md          (this file)
├── dev/               (state #1 — iq9-vpc-dev-yamato in us-west1)
├── test/              (pending — iq9-vpc-dev-yamato-test, when CI/CD wiring lands)
├── stage/             (pending — iq9-vpc-prod-yamato-stage)
└── prod/              (pending — iq9-vpc-prod-yamato; will likely revisit Shared VPC at this point)
```

## Environment status

| Subdir | VPC | Project | Status |
| --- | --- | --- | --- |
| [`dev/`](./dev/) | `iq9-vpc-dev-yamato` | `iq9-gcp-dev-yamato` | provisioned |
| `test/` | `iq9-vpc-dev-yamato-test` | `iq9-gcp-dev-yamato-test` | pending |
| `stage/` | `iq9-vpc-prod-yamato-stage` | `iq9-gcp-prod-yamato-stage` | pending |
| `prod/` | `iq9-vpc-prod-yamato` | `iq9-gcp-prod-yamato` | pending |

## Dev vs prod networking model

For `dev`, the simplicity argument wins: one project, one VPC, one subnet, one PSA range, no NAT, no FW rules. The dev environment exists to empower developers to ship code; cross-project IAM, host-project quotas, and two-state-per-change deploys would slow the inner loop down for no security or scalability benefit at this scale.

For `prod`, the calculus is different. Shared VPC, dedicated host project, centralized firewall rules, Cloud NAT for predictable egress IPs, VPC Flow Logs with sampling, and possibly a service perimeter become reasonable investments — they protect customer traffic and provide auditable network paths. The `prod/` directory will revisit those decisions when it lands.

`test` and `stage` follow their parent environments: `test/` mirrors `dev/`, `stage/` mirrors `prod/`.

## Activation pattern

Every environment subdir follows the same shape as [`dev/`](./dev/):

```
yamato/{env}/
├── gcp_networks_yamato_{env}.tf            (APIs + VPC + subnet + PSA + peering)
├── gcp_networks_yamato_{env}_gcs_backend.tf (state prefix: foundation/gcp-networks/yamato/{env}/)
├── gcp_provider.tf                          (symlink to repo-root)
└── readme.md
```

CIDR ranges across environments are chosen so dev/test/stage/prod don't overlap, in case a future need for VPC peering between them ever arises (e.g. a stage runbook fetching schema from a dev backup):

```
dev    10.10.0.0/20 subnet  +  10.20.0.0/20 PSA
test   10.30.0.0/20 subnet  +  10.40.0.0/20 PSA
stage  10.50.0.0/20 subnet  +  10.60.0.0/20 PSA
prod   10.70.0.0/20 subnet  +  10.80.0.0/20 PSA
```
