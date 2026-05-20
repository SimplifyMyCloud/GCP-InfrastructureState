# Service Layer — yamato / dev / artifact-registry

The Docker image repository for the yamato app's dev environment, plus the APIs
the image pipeline needs.

## What this state owns

- `artifactregistry.googleapis.com` and `cloudbuild.googleapis.com` enabled on
  `iq9-gcp-dev-yamato`.
- One Docker-format Artifact Registry repository, `yamato`, in `us-west1`.

Cloud Build *triggers* are deliberately not created here. Until the App Layer
exists, images are pushed manually (`gcloud builds submit` / `docker push`); a
source-connected trigger is a later addition.

## Variables (set in `terraform.tfvars`)

| Variable | Value | Notes |
| --- | --- | --- |
| `project_id` | `iq9-gcp-dev-yamato` | the dev project |
| `region` | `us-west1` | co-located with Cloud Run |
| `repository_id` | `yamato` | the Docker repo name |

`labels = { env = "dev", app = "yamato" }` is set in `main.tf` (the root is the
dev instantiation).

## Resulting image path

```
us-west1-docker.pkg.dev/iq9-gcp-dev-yamato/yamato/<image>:<tag>
```

This prefix is exported as the `repository_url` output, and is what the Cloud Run
`container_image` variable points at once the app image is built and pushed.

## First-time setup

```bash
cd service/yamato/dev/artifact-registry/
terraform init
terraform plan    # enables 2 APIs, creates 1 repository
terraform apply
```

Verify:

```bash
gcloud artifacts repositories describe yamato \
  --project=iq9-gcp-dev-yamato --location=us-west1 \
  --format='table(name, format)'
```

## What comes next

[`../cloudsql/`](../cloudsql/) and [`../cloudrun/`](../cloudrun/). The repository
created here is where the App Layer build pushes the yamato image that
`../cloudrun/` eventually runs.
