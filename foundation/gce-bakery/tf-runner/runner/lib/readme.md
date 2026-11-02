# gce-bakery / tf-runner / runner / lib

| File | What it does |
| --- | --- |
| `common.sh` | Shared code for `tf-run.sh`: picks the RO or RW target SA for the phase, mints a **short-lived impersonated token** from the VM's low-privilege attached SA (no keys anywhere), enforces the write-window gate, finds the repo checkout, and writes the run log. |
