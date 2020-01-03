# SMC Infrastructure State

SimplifyMy.Cloud infrastructure state with a focus on simplicity and empathy.

---

## Infrastructure Layers

Breaking apart the cloud into three layers delivers a simple infrastructure state to manage and push changes to.  The goal of a well defined and engineered infrastructure is a DevOps culture which promotes healthy colaboration between all customers of that infrastructure, development, operations, security, end users and management.  Infrastructure empathy is the foundation which this is engineered.  Empathy for developers so they will never worry about making accidental changes to Production, emapthy of operations by incorporating self-healing and self-sizing along with self-service for other teams, emapthy for the security folks by siloing environments and access into auditable and verifiable worlds.



## Foundation Layer

Definition: The Foundation Layer is responsible for networking, security, users.



## Service Layer

Definition: The Service Layer is responsible for cloud native services (*-as-a-service), Baked VMs, storage, and observability.



## App Layer

Definition: The App Layer is the orchestartion of applications, services, data and monitoring that resides into the Services Layer.


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
