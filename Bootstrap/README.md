# SMC Infrastructure State Genesis

SimplifyMy.Cloud infrastructure state with a focus on simplicity and empathy.

---

Backstory:

With a newly created Google Cloud, a beachhead must be established to enable the Foundation Layer to be ensured by Terraform.  To accomplish this we will follow this excellent documentation from Google, [Managing GCP Projects with Terraform](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform) with a small change, naming the project "Operations".

---

The goal:

Create an "Operations" project that will host the automation to build Google Cloud along with any internal tooling needed by the infrastructure.  

Steps:

- Retrieve the organization number along with the billing account

```
gcloud organizations list
gcloud beta billing accounts list
```

- Create environment variables

```
export TF_VAR_org_id=YOUR_ORG_ID
export TF_VAR_billing_account=YOUR_BILLING_ACCOUNT_ID
export TF_ADMIN=${USER}-terraform-admin
export TF_CREDS=~/.config/gcloud/terraform-admin.json
```

- Create the Operations project

```
gcloud projects create operations \
  --organization ${TF_VAR_org_id} \
  --set-as-default
```

- Link the billing account to the operations project

```
gcloud beta billing projects link operations \
  --billing-account ${TF_VAR_billing_account}
```

- Create the Terraform IAM service account

```
gcloud iam service-accounts create terraform \
  --display-name "Terraform admin account"
```

- Create the Terraform SA keys

```
gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account terraform@operations.iam.gserviceaccount.com
```

- Grant Terraform SA permissions to view the operations project

```
gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@operations.iam.gserviceaccount.com \
  --role roles/viewer
```

- Grant Terraform SA permissions to manage GCS in the operations project

```
gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@operations.iam.gserviceaccount.com \
  --role roles/storage.admin
```

- Enable a base set of GCP APIs for Terraform to use

```
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com
```
- Grant the Terraform SA permissions to create folders and assign IAM permissions to those folders at the organization level

```
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@operations.iam.gserviceaccount.com \
  --role roles/resourcemanager.folderAdmin
```

```
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@operations.iam.gserviceaccount.com \
  --role roles/resourcemanager.folderIamAdmin
```

- Grant the Terraform SA permissions to create projects at the organization level

```
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@operations.iam.gserviceaccount.com \
  --role roles/resourcemanager.projectCreator
```

- Grant the Terraform SA permissions to assign billing accounts to newly created projects and folders

```
gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:terraform@operations.iam.gserviceaccount.com \
  --role roles/billing.user
```

- Create a GCS bucket to host the Terraform state files

_GCS bucket names must be worldwide unique_

```
gsutil mb -p operations gs://smc-terraform-state-files

cat > backend.tf <<EOF
terraform {
 backend "gcs" {
   bucket  = "smc-terraform-state-files"
   path    = "/terraform.tfstate"
   project = "operations"
 }
}
EOF
```

- Enable versioning on the Terraform state bucket

```
gsutil versioning set on gs://smc-terraform-state-files
```

- Add the Terraform credentials to your environment path

```
export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS}
export GOOGLE_PROJECT=operations
```

- Initialize Terrafrom to create the state files

```
terraform init
```


_Capturing the bootstrap genesis steps_

# prep GCP

gcloud organizations list
gcloud beta billing accounts list

export TF_VAR_org_id=447686549950
export TF_VAR_billing_account=01AE65-A7583F-D9EB1A
export TF_BOOTSTRAP_PROJECT=iq9-tf-bootstrap
export TF_FOUNDATION_SA=tf-foundation-sa
export TF_CREDS_JSON=~/.config/gcloud/${TF_FOUNDATION_SA}.json
export TF_FOUNDATION_SA_URL=${TF_FOUNDATION_SA}@${TF_BOOTSTRAP_PROJECT}.iam.gserviceaccount.com


# create tf admin GCP Project

gcloud projects create ${TF_BOOTSTRAP_PROJECT} \
  --organization ${TF_VAR_org_id} \
  --set-as-default

gcloud beta billing projects link ${TF_ADMIN} \
  --billing-account ${TF_VAR_billing_account}


# Create the Terraform service account

Create the service account in the Terraform admin project and download the JSON credentials:

gcloud iam service-accounts create ${TF_FOUNDATION_SA} \
  --display-name "Terraform Foundation Layer GCP Service Account"

gcloud iam service-accounts keys create ${TF_CREDS} \
  --iam-account ${TF_FOUNDATION_SA_URL}

# Grant the service account permission to view the Admin Project and manage Cloud Storage:

gcloud projects add-iam-policy-binding ${TF_BOOTSTRAP_PROJECT} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/viewer

gcloud projects add-iam-policy-binding ${TF_BOOTSTRAP_PROJECT} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/storage.admin

# Any actions that Terraform performs require that the API be enabled to do so. In this guide, Terraform requires the following:

gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable serviceusage.googleapis.com


# Add organization/folder-level permissions

Grant the service account permission to create projects and assign billing accounts:

gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/resourcemanager.projectCreator

gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/resourcemanager.folderCreator

gcloud organizations add-iam-policy-binding ${TF_VAR_org_id} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/billing.user



# Set up remote state in Cloud Storage

Create the remote backend bucket in Cloud Storage and the backend.tf file for storage of the terraform.tfstate file:

gsutil mb \
-p ${TF_BOOTSTRAP_PROJECT} \
-l us-west1 \
gs://${TF_BOOTSTRAP_PROJECT}

cat > foundation_backend.tf << EOF
terraform {
 backend "gcs" {
   bucket  = "${TF_BOOTSTRAP_PROJECT}"
   prefix  = "terraform/state"
 }
}
EOF


# Enable versioning for said remote bucket:

gsutil versioning set on gs://${TF_BOOTSTRAP_PROJECT}

# Configure your environment for the Google Cloud Terraform provider:

export GOOGLE_APPLICATION_CREDENTIALS=${TF_CREDS_JSON}
export GOOGLE_PROJECT=${TF_BOOTSTRAP_PROJECT}
