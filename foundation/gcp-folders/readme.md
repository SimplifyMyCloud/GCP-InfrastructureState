<!-- hand-written -->
# foundation/gcp-folders

The three environment folders directly under the Org, one directory (one state) per folder. Each owns just the `google_folder`, with `deletion_protection = true`.

State for any directory below: `gs://smc-ops-tf-state/terraform/state/foundation/gcp-folders/<same path>/default.tfstate`.

| Directory | Terraform for |
| --- | --- |
| [`smc-prod/`](smc-prod/) | the `smc-prod` folder itself |
| [`smc-ops/`](smc-ops/) | the `smc-ops` folder itself |
| [`smc-dev/`](smc-dev/) | the `smc-dev` folder itself |

Back to the [Foundation guide](../readme.md).
