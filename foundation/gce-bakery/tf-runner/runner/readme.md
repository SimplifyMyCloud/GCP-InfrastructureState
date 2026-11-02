# gce-bakery / tf-runner / runner

The **`tf-run` wrapper** that gets baked into the runner image. Instead of calling `terraform` directly, operators run `tf-run <plan|apply|destroy> <foundation path>`. The wrapper chooses the identity for each run: a read-only SA for `plan`, a read-write SA for `apply`/`destroy`, and the latter only inside the release write-window. It also logs every run.

| Path | What it is |
| --- | --- |
| `tf-run.sh` | the entry point, installed on the image as `tf-run` |
| [`lib/`](lib/) | shared helpers sourced by `tf-run.sh` |

Not in use yet. See the status note in [`../readme.md`](../readme.md).
