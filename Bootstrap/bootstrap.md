# Bootstrap Steps

## GCP Cloud Shell

The bootstrap steps can and should be run from GCP Cloud Shell for simplicity and security.  GCP Cloud Shell can be used with a GCP Org that has no GCP Projects, a simple way to run these commands.  GCP Cloud Shell is secure becuase it does not require any GCP Service Account private keys to be generated and offloaded from GCP to a local workstation.  GCP Cloud Shell will authenticate with the genesis user account and ask for privledged access during startup.  That allows GCP Cloud Shell to assume the identity and privledges of the genesis account, to create the `Operations` GCP Project, the ultimate permanent home of Terraform OSS or Terraform Enterprise.

## Clean up the GCP Org

The first step of the bootstrap involves deleting the `My First Project` GCP Project.  We do not want to use this GCP Project in anyway, so removing it is the simpliest way to start.

```bash
gcloud projects delete [PROJECT_ID_OR_NUMBER]
```

## Retrieve the organization number along with the billing account

```bash
gcloud organizations list
gcloud beta billing accounts list
```

## Export environment variables in order to simplify the manual steps
  
```bash
export TF_VAR_ORG_ID=123456789000
export TF_VAR_BILLING_ACCOUNT=012345-ABCDEF-012345
export TF_VAR_GENESIS_ORG_ADMIN=bob@example.com
export TF_OPS_PROJECT=iq9-ops-env
export TF_OPS_FOLDER=ops
export TF_FOUNDATION_SA=tf-foundation-sa
export TF_CREDS_JSON=~/.config/gcloud/${TF_FOUNDATION_SA}.json
export TF_FOUNDATION_SA_URL=${TF_FOUNDATION_SA}@${TF_OPS_PROJECT}.iam.gserviceaccount.com
```

## Add authorizations to create the Ops environment

```bash
gcloud organizations add-iam-policy-binding ${TF_VAR_ORG_ID} \
  --member user:${TF_VAR_GENESIS_ORG_ADMIN} \
  --role roles/resourcemanager.projectCreator
```

```bash
gcloud organizations add-iam-policy-binding ${TF_VAR_ORG_ID} \
  --member user:${TF_VAR_GENESIS_ORG_ADMIN} \
  --role roles/resourcemanager.folderCreator
```

```bash
gcloud organizations add-iam-policy-binding ${TF_VAR_ORG_ID} \
  --member user:${TF_VAR_GENESIS_ORG_ADMIN} \
  --role roles/billing.user
```


## Create the Ops environment GCP Folder

```bash
gcloud resource-manager folders create \
  --organization ${TF_VAR_ORG_ID} \
  --display-name ${TF_OPS_FOLDER}
```

## Create the Ops environment GCP Project

```bash
gcloud projects create ${TF_OPS_PROJECT} \
  --organization ${TF_VAR_ORG_ID} \
  --set-as-default
```

```bash
gcloud beta billing projects link ${TF_OPS_PROJECT} \
  --billing-account ${TF_VAR_BILLING_ACCOUNT}
```

## Create the Terraform foundation service account

Create the foundation service account in the Terraform admin project and download the JSON credentials:

```bash
gcloud iam service-accounts create ${TF_FOUNDATION_SA} \
  --display-name "Terraform Foundation Layer GCP Service Account"
```

```bash
gcloud iam service-accounts keys create \
  --iam-account ${TF_FOUNDATION_SA_URL} ${TF_FOUNDATION_SA}.json
```

This will place a private key in the directory where you are running the command.  This private key is highly privledged and should be safely stored with extreme care.  Once Terraform is configured on GCP with either Cloud Build or on a GCE VM, this private key will be removed and no longer used.

## Grant the service account permission to view the Ops environment GCP Project and manage GCP Cloud Storage:

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

## Any actions that Terraform performs require that the API be enabled to do so. For the Bootstrap, Terraform requires the following:

```bash
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable cloudbilling.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable serviceusage.googleapis.com
```

## Add organization/folder-level permissions

Grant the service account permission to create projects and assign billing accounts:

```bash
gcloud organizations add-iam-policy-binding ${TF_VAR_ORG_ID} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/resourcemanager.projectCreator
```

```bash
gcloud organizations add-iam-policy-binding ${TF_VAR_ORG_ID} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/resourcemanager.folderCreator
```

```bash
gcloud organizations add-iam-policy-binding ${TF_VAR_ORG_ID} \
  --member serviceAccount:${TF_FOUNDATION_SA_URL} \
  --role roles/billing.user
```

## Set up remote state in Cloud Storage

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

## Enable versioning for the Terraform state GCS bucket:

```bash
gsutil versioning set on gs://${TF_OPS_PROJECT}
```

## From here

After running these manual steps you have created an Ops environment to host Terraform.  At this point you can refer back to the GCP Infrastructure Culture `../` Terraform to ensure the state of the dev, test, stage, and production environments.
