# SMC Infrastructure State Bootstrapping

GCP must be prepared for the infrastructure state to be ensure by Terraform.  This bootstrapping process will use manually run commands to create a dedicated GCP Project that will host the Terraform server.  This Terraform GCP Project is a long lived home for Terraform.  Because of this long lived status we can can wire up dedicated GCP Service Accounts.

With a newly created Google Cloud, a beachhead must be established to enable the Foundation Layer to be ensured by Terraform.  To accomplish this we will follow this excellent documentation from Google, [Managing GCP Projects with Terraform](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform) with a small change, naming the project "Operations".

---

## The goal

Create an "Operations" GCP Project that will host the automation to build Google Cloud along with any internal tooling needed by the infrastructure.  This will be the "Ops environment" hosting all infrastructure needed to manage and maintain the entire GCP Org.  The Ops environment would be on the same level as the dev, test, stage, production environments.

Steps:

### Retrieve the organization number along with the billing account

```bash
gcloud organizations list
gcloud beta billing accounts list
```

### Export environment variables in order to simplify the manual steps
  
```bash
export TF_VAR_org_id=447686549950
export TF_VAR_billing_account=01AE65-A7583F-D9EB1A
export TF_OPS_PROJECT=iq9-ops-env
export TF_OPS_FOLDER=ops
export TF_FOUNDATION_SA=tf-foundation-sa
export TF_CREDS_JSON=~/.config/gcloud/${TF_FOUNDATION_SA}.json
export TF_FOUNDATION_SA_URL=${TF_FOUNDATION_SA}@${TF_OPS_PROJECT}.iam.gserviceaccount.com
```

### Create the Ops environment GCP Folder

```bash
gcloud resource-manager folders create \
  --organization ${TF_VAR_org_id} \
  --display-name ${TF_OPS_FOLDER}
```


### Create the Ops environment GCP Project

```bash
gcloud projects create ${TF_OPS_PROJECT} \
  --organization ${TF_VAR_org_id} \
  --folder ${TF_OPS_FOLDER} \
  --set-as-default
```

```bash
gcloud beta billing projects link ${TF_ADMIN} \
  --billing-account ${TF_VAR_billing_account}
```

### Create the Terraform foundation service account

Create the foundation service account in the Terraform admin project and download the JSON credentials:

```bash
gcloud iam service-accounts create ${TF_FOUNDATION_SA} \
  --display-name "Terraform Foundation Layer GCP Service Account"
```

```bash
gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account ${TF_FOUNDATION_SA_URL}
```

### Grant the service account permission to view the Ops environment GCP Project and manage GCP Cloud Storage:

```bash
gcloud projects add-iam-policy-binding ${TF_OPS_PROJECT} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/viewer
```

```bash
gcloud projects add-iam-policy-binding ${TF_OPS_PROJECT} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/storage.admin
```

### Any actions that Terraform performs require that the API be enabled to do so. For the Bootstrap, Terraform requires the following:

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

Create the remote backend bucket in Cloud Storage and the `backend.tf` Terraform file for storage of the `terraform.tfstate` file:

```bash
gsutil mb \
-p ${TF_OPS_PROJECT} \
-l us-west1 \
gs://${TF_OPS_PROJECT}
```

```bash
cat > foundation_backend.tf << EOF
terraform {
 backend "gcs" {
   bucket  = "${TF_OPS_PROJECT}"
   prefix  = "terraform/state"
 }
}
EOF
```

### Enable versioning for the Terraform state GCS bucket:

```bash
gsutil versioning set on gs://${TF_OPS_PROJECT}
```
