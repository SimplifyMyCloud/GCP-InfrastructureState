# Module — artifact-registry

**Focus:** a single Docker-format Artifact Registry repository to hold an app's
container images, plus the APIs the image pipeline needs.

**Desired state**
- `artifactregistry.googleapis.com` and `cloudbuild.googleapis.com` enabled on the project (`disable_on_destroy = false`).
- One `google_artifact_registry_repository` (format `DOCKER`) in the given region.

Cloud Build *triggers* are intentionally out of scope — images are pushed with
`gcloud builds submit` / `docker push` until a source-connected trigger is added.

## Inputs

| Variable | Required | Purpose |
| --- | --- | --- |
| `project_id` | yes | Project that owns the repository |
| `region` | yes | Repository location (co-locate with Cloud Run) |
| `repository_id` | yes | Repository name (e.g. `yamato`) |
| `description` | no | Repository description |
| `labels` | no | Resource labels (e.g. `env`, `app`) |

## Outputs

`repository_id`, `repository_name` (full resource name), `repository_url`
(the `<region>-docker.pkg.dev/<project>/<repo>` tag prefix).

Consumed by [`../../dev/artifact-registry/`](../../dev/artifact-registry/).
