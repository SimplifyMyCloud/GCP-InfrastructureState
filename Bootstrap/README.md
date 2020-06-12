# SMC Infrastructure State Bootstrapping

SimplifyMy.Cloud GCP genesis build.  GCP must be configured to prepare it for the infrastructure state to be ensure by Terraform.  This bootstrapping process will use manually run commands to create a dedicated GCP Project that will host the Terraform server.  This Terraform GCP Project is a long lived home for Terraform.  Because of this long lived status we can can wire up dedicated GCP Service Accounts.

---

## Backstory:

With a newly created Google Cloud, a beachhead must be established to enable the Foundation Layer to be ensured by Terraform.  To accomplish this we will follow this excellent documentation from Google, [Managing GCP Projects with Terraform](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform) with a small change, naming the project "Operations".

---

## The goal:

Create an "Operations" project that will host the automation to build Google Cloud along with any internal tooling needed by the infrastructure.  

Steps:

- Retrieve the organization number along with the billing account

```bash
gcloud organizations list
gcloud beta billing accounts list
```

```bash
export TF_VAR_org_id=447686549950
export TF_VAR_billing_account=01AE65-A7583F-D9EB1A
export TF_BOOTSTRAP_PROJECT=iq9-tf-bootstrap
export TF_FOUNDATION_SA=tf-foundation-sa
export TF_CREDS_JSON=~/.config/gcloud/${TF_FOUNDATION_SA}.json
export TF_FOUNDATION_SA_URL=${TF_FOUNDATION_SA}@${TF_BOOTSTRAP_PROJECT}.iam.gserviceaccount.com
```

### create tf admin GCP Project

```bash
gcloud projects create ${TF_BOOTSTRAP_PROJECT} \
  --organization ${TF_VAR_org_id} \
  --set-as-default
```

```bash
gcloud beta billing projects link ${TF_ADMIN} \
  --billing-account ${TF_VAR_billing_account}
```

### Create the Terraform service account

Create the service account in the Terraform admin project and download the JSON credentials:

```bash
gcloud iam service-accounts create ${TF_FOUNDATION_SA} \
  --display-name "Terraform Foundation Layer GCP Service Account"
```

```bash
gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account ${TF_FOUNDATION_SA_URL}
```

### Grant the service account permission to view the Admin Project and manage Cloud Storage:

```bash
gcloud projects add-iam-policy-binding ${TF_BOOTSTRAP_PROJECT} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/viewer
```

```bash
gcloud projects add-iam-policy-binding ${TF_BOOTSTRAP_PROJECT} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/storage.admin
```

### Any actions that Terraform performs require that the API be enabled to do so. In this guide, Terraform requires the following:

```bash
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable serviceusage.googleapis.com
```

### Add organization/folder-level permissions

Grant the service account permission to create projects and assign billing accounts:

```bash
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/resourcemanager.projectCreator
```

```bash
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/resourcemanager.folderCreator
```

```bash
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/billing.user
```

### Set up remote state in Cloud Storage

Create the remote backend bucket in Cloud Storage and the backend.tf file for storage of the terraform.tfstate file:

```bash
gsutil mb \
-p ${TF_BOOTSTRAP_PROJECT} \
-l us-west1 \
gs://${TF_BOOTSTRAP_PROJECT}
```

```bash
cat > foundation_backend.tf << EOF
terraform {
 backend "gcs" {
   bucket  = "${TF_BOOTSTRAP_PROJECT}"
   prefix  = "terraform/state"
 }
}
EOF
```

### Enable versioning for said remote bucket:

```bash
gsutil versioning set on gs://${TF_BOOTSTRAP_PROJECT}
```