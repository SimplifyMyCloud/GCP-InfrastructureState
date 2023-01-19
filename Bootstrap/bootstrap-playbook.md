# Bootstrap the GCP Org for Terraform

---

## Helpful Links to GCP Docs

- [Predefined IAM Roles](https://cloud.google.com/iam/docs/understanding-roles#predefined)
- [GCP Org Policy Constraints](https://cloud.google.com/resource-manager/docs/organization-policy/org-policy-constraints)
- [gcloud sdk APIs](https://cloud.google.com/sdk/gcloud/reference/services)

---

## Scaffolding

In order to prepare the GCP environment to host and run Terraform, we must build up a scaffolding that will be short lived and eventually torn down.  The highest priority of all actions taken during the bootstrap is every action being atomically recorded.

---

## Clean up the GCP Org

The first step of the bootstrap involves deleting the `My First Project` GCP Project.  We do not want to use this GCP Project in anyway, so removing it is the simplest way to start.

```bash
gcloud projects delete 640514074828
```

Move all existing GCP Projects to a "tech debt" GCP Folder

### Retrieve the organization number along with the billing account

```bash
gcloud organizations list
gcloud beta billing accounts list
```

---

## Export environment variables in order to simplify the manual steps

Definitions:

Scaffolding: is a short lived environment to be torn down once the environment is running Terraform CiCd from the permanent GCP Org Operations environment

GCP Org Operations: is a long lived environment that hosts the infrastructure required in order to ensure the state of the GCP Org itself

GCP Environment Operations: are long lived environments that host the infrastructure required in order to ensure the state of it environment, from within the security boundary of that environment

### Environment Variables
  
```bash
export GCP_ORG_ID={NEEDS_VALUE}
export GCP_ORG_BILLING_ACCOUNT_ID={NEEDS_VALUE}
export GCP_REGION={NEEDS_VALUE}
export GCP_ZONE={NEEDS_VALUE}
export SCAFFOLDING_ORG_ADMIN={NEEDS_VALUE}
export SCAFFOLDING_GCP_PROJECT={NEEDS_VALUE}
export SCAFFOLDING_VPC={NEEDS_VALUE}
export SCAFFOLDING_SUBNET={NEEDS_VALUE}
export SCAFFOLDING_GCE_VM={NEEDS_VALUE}
export SCAFFOLDING_ORG_SA={NEEDS_VALUE}
export SCAFFOLDING_ORG_SA_URL=${SCAFFOLDING_ORG_SA}@${SCAFFOLDING_GCP_PROJECT}.iam.gserviceaccount.com
export GCP_ORG_OPS_FOLDER=operations
export GCP_ORG_OPS_PROJECT={NEEDS_VALUE}
export GCP_ORG_OPS_VPC={NEEDS_VALUE}
export GCP_ORG_OPS_SUBNET={NEEDS_VALUE}
export GCP_ORG_OPS_GCE_VM={NEEDS_VALUE}
export GCP_ORG_OPS_SA={NEEDS_VALUE}
export GCP_ORG_OPS_SA_URL=${GCP_ORG_OPS_SA}@${GCP_ORG_OPS_PROJECT}.iam.gserviceaccount.com
export GCP_ORG_OPS_GCS_ARTIFACTS={NEEDS_VALUE}
export GCP_ORG_OPS_GCE_IMAGE={NEEDS_VALUE}
```

---

## Set inherited GCP Organization Policy

Some GCP Org policies are not retroactively applied and must be set _before_ the GCP Projects are created, ensuring the newly created GCP Projects are under the desired state of the GCP Org policy being enforced.  If these policies are decided upon now, and implemented now, before the bootstrapping, all GCP Projects will be under the desired state of the GCP Org policies.

Review GCP Org policy constraints [here](https://cloud.google.com/resource-manager/docs/organization-policy/org-policy-constraints) and then add them to your bootstrap playbook here, to ensure they are enforced GCP Org wide.

### GCP Org Policy

The GCP Org Policy can be ensured via the GCP Web Console _or_ via `gcloud` _or_ via Terraform.  Regardless of how these policies are ensured now, they will eventually be imported into the Terraform state, once it is deployed.

- [ ] Enforce desired state for GCP Org Policies (that are non-retroactive)
- [ ] Enforced: Require OS Login 
      `constraints/compute.requireOsLogin`
- [ ] Enforced: Define allowed external IPs for VM instances 
      `constraints/compute.vmExternalIpAccess`
    ** Exempt Legacy folder in prod, but all folders created by Scaffold/Foundation use this policy.
- [ ] Enforced: Skip default network creation
      `constraints/compute.skipDefaultNetworkCreation`
- [ ] Enforced: Google Cloud Platform - Resource Location Restriction
      `constraints/gcp.resourceLocations` 
        Allow List:
        us-west1-c
        us-west1-b
        us-central1-locations
        us-central2-d
        us-east1-a
        us-central1-b
        us-central1
        us-central2
        us-east1
        us-central1-c
        us-west1-a
        us-east1-b
        us-central1-f
        us-central2-a
        us-east1-locations
        us-west1-locations
        us-central2-c
        us-central1-a
        us-east1-c
        us-west1
        us-central2-locations
        us-central2-b
        us-east1-d
- [ ] Enforced: Disable Public Marketplace
      `constraints/commerceorggovernance.disablePublicMarketplace`

---

## GCP Org Desired State

_Scaffolding_:

- GCP Project - `${SCAFFOLDING_GCP_PROJECT}`
- GCP Org Level Service Account = `${SCAFFOLDING_ORG_ADMIN}`
- GCP VPC - `${SCAFFOLDING_VPC}`
- GCP VPC Subnet - `${SCAFFOLDING_SUBNET}`
- GCE VM - `${SCAFFOLDING_GCE_VM}`

_GCP Org Ops_:

- GCP Folder - `${GCP_ORG_OPS_FOLDER}`
- GCP Project - `${GCP_ORG_OPS_PROJECT}`
- GCP Org level SA - `${GCP_ORG_OPS_SA}`
- GCP VPC - `${GCP_ORG_OPS_VPC}`
- GCP VPC Subnet - `${GCP_ORG_OPS_SUBNET}`
- GCE VM - `${GCP_ORG_OPS_GCE_VM}`

---

## Scaffolding Ops

### Verify privilege escalations and authorizations to create the Scaffolding Ops environment

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member user:${SCAFFOLDING_ORG_ADMIN} \
  --role roles/resourcemanager.projectCreator
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member user:${SCAFFOLDING_ORG_ADMIN} \
  --role roles/resourcemanager.folderCreator
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member user:${SCAFFOLDING_ORG_ADMIN} \
  --role roles/billing.user
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member user:${SCAFFOLDING_ORG_ADMIN} \
  --role roles/billing.projectManager
```


### Create the Scaffolding Ops environment GCP Project

```bash
gcloud projects create ${SCAFFOLDING_GCP_PROJECT} \
  --organization ${GCP_ORG_ID} \
  --set-as-default
```

```bash
gcloud beta billing projects link ${SCAFFOLDING_GCP_PROJECT} \
  --billing-account ${GCP_ORG_BILLING_ACOUNT_ID}
```

### Enable APIs in the Scaffolding GCP Project

```bash
gcloud services enable cloudbilling.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable serviceusage.googleapis.com
gcloud services enable compute.googleapis.com
```

### Deploy a VPC for hosting the Scaffolding Ops Subnet

```bash
gcloud compute networks create ${SCAFFOLDING_VPC} \
--project ${SCAFFOLDING_GCP_PROJECT} \
--description "VPC to host the Scaffolding gcloud sdk" \
--subnet-mode=custom \
--mtu=1460 \
--bgp-routing-mode=regional
```

### Deploy a Subnet for hosting the Scaffolding Ops gcloud sdk

```bash
gcloud compute networks subnets create ${SCAFFOLDING_SUBNET} \
--project ${SCAFFOLDING_GCP_PROJECT} \
--description "Subnet to host the Scaffolding gcloud sdk" \
 --range=10.0.0.0/29 \
 --stack-type=IPV4_ONLY \
 --network=${SCAFFOLDING_VPC} \
 --region=${GCP_REGION} \
 --enable-private-ip-google-access
```

### Create Service Account privilege escalations and authorizations to GCP Scaffolding project  

```bash
gcloud iam service-accounts create ${SCAFFOLDING_ORG_SA} \
--project ${SCAFFOLDING_GCP_PROJECT} \
--display-name ${SCAFFOLDING_ORG_SA}
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member serviceAccount:${SCAFFOLDING_ORG_SA_URL} \
  --role roles/resourcemanager.projectCreator
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member serviceAccount:${SCAFFOLDING_ORG_SA_URL} \
  --role roles/resourcemanager.folderCreator
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member serviceAccount:${SCAFFOLDING_ORG_SA_URL} \
  --role roles/billing.user
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member serviceAccount:${SCAFFOLDING_ORG_SA_URL} \
  --role roles/iam.serviceAccountCreator
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member serviceAccount:${SCAFFOLDING_ORG_SA_URL} \
  --role roles/iam.securityAdmin
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member serviceAccount:${SCAFFOLDING_ORG_SA_URL} \
  --role roles/serviceusage.serviceUsageAdmin
```

### Deploy GCE VM for hosting Scaffolding Ops gcloud sdk

```bash
gcloud compute instances create ${SCAFFOLDING_GCE_VM} \
--project=${SCAFFOLDING_GCP_PROJECT} \
--machine-type=e2-medium \
--network-interface=subnet=${SCAFFOLDING_SUBNET},no-address \
--metadata=enable-oslogin=true \
--maintenance-policy=MIGRATE \
--provisioning-model=STANDARD \
--service-account=${SCAFFOLDING_ORG_SA_URL} \
--scopes=https://www.googleapis.com/auth/cloud-platform \
--create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=projects/rocky-linux-cloud/global/images/rocky-linux-8-optimized-gcp-v20221102,mode=rw,size=20,type=projects/${SCAFFOLDING_GCP_PROJECT}/zones/${GCP_ZONE}/diskTypes/pd-balanced \
--zone=${GCP_ZONE} \
--shielded-secure-boot \
--shielded-vtpm \
--shielded-integrity-monitoring \
--labels=role=terraform-server,environment=operations,owner=sre-ops,impact-level=none,region=${GCP_ZONE},gcp-project=${SCAFFOLDING_OPS_PROJECT} \
--reservation-affinity=any
```

### Add firewall rule to enable IAP connection to the Scaffold VM

```bash
gcloud compute firewall-rules create allow-iap-traffic \
--project=${SCAFFOLDING_GCP_PROJECT} \
--description="Allow IAP connection to GCE" \
--direction=INGRESS \
--priority=1000 \
--network=${SCAFFOLDING_VPC} \
--action=ALLOW \
--rules=tcp:80 \
--source-ranges=130.211.0.0/22,35.191.0.0/16 \
--enable-logging
```

```bash
gcloud compute firewall-rules create allow-ssh-ingress-from-iap \
  --project=${SCAFFOLDING_GCP_PROJECT} \
  --description="Allow IAP connection to GCE" \
  --direction=INGRESS \
  --priority=1000 \
  --network=${SCAFFOLDING_VPC} \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  --enable-logging
```

---

## GCP Org Ops

_*all commands from here are run from the Scaffolding VM*_

### Create the GCP Org Ops GCP Folder

```bash
gcloud resource-manager folders create \
--display-name ${GCP_ORG_OPS_FOLDER} \
--organization ${GCP_ORG_ID}
```

### Create the GCP Org Ops environment GCP Project

```bash
gcloud projects create ${GCP_ORG_OPS_PROJECT} \
  --folder [NEEDS_VALUE] \
  --set-as-default
```

```bash
gcloud beta billing projects link ${GCP_ORG_OPS_PROJECT} \
  --billing-account ${GCP_ORG_BILLING_ACOUNT_ID}
```

### Enable APIs in the GCP Org Ops GCP Project

```bash
gcloud services enable cloudbilling.googleapis.com \
--project ${GCP_ORG_OPS_PROJECT}
```

```bash
gcloud services enable cloudresourcemanager.googleapis.com \
--project ${GCP_ORG_OPS_PROJECT}
```

```bash
gcloud services enable serviceusage.googleapis.com \
--project ${GCP_ORG_OPS_PROJECT}
```

```bash
gcloud services enable iam.googleapis.com \
--project ${GCP_ORG_OPS_PROJECT}
```

```bash
gcloud services enable compute.googleapis.com \
--project ${GCP_ORG_OPS_PROJECT}
```

### Create Service Account privilege escalations and authorizations to GCP Org Ops  

```bash
gcloud iam service-accounts create ${GCP_ORG_OPS_SA} \
--project ${GCP_ORG_OPS_PROJECT} \
--display-name ${GCP_ORG_OPS_SA}
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member serviceAccount:${GCP_ORG_OPS_SA_URL} \
  --role roles/resourcemanager.projectCreator
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member serviceAccount:${GCP_ORG_OPS_SA_URL} \
  --role roles/resourcemanager.folderCreator
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member serviceAccount:${GCP_ORG_OPS_SA_URL} \
  --role roles/billing.user
```

```bash
gcloud organizations add-iam-policy-binding ${GCP_ORG_ID} \
  --member serviceAccount:${GCP_ORG_OPS_SA_URL} \
  --role roles/storage.admin
```

### Deploy a VPC for hosting the GCP Org Ops Subnet

```bash
gcloud compute networks create ${GCP_ORG_OPS_VPC} \
--project ${GCP_ORG_OPS_PROJECT} \
--description "VPC to host the GCP Org Ops Subnet" \
--subnet-mode=custom \
--mtu=1460 \
--bgp-routing-mode=regional
```

### Deploy a Subnet for hosting a GCE VM

```bash
gcloud compute networks subnets create ${GCP_ORG_OPS_SUBNET} \
--project ${GCP_ORG_OPS_PROJECT} \
--description "Subnet to host the GCP Org Ops Terraform Server" \
 --range=10.0.0.0/29 \
 --stack-type=IPV4_ONLY \
 --network=${GCP_ORG_OPS_VPC} \
 --region=${GCP_REGION} \
 --enable-private-ip-google-access
```

### Create Firewall Rules for org-ops terraform network for IAP access to VM

```bash
gcloud compute firewall-rules create allow-iap-traffic \
--project=${GCP_ORG_OPS_PROJECT} \
--description="Allow IAP connection to GCE" \
--direction=INGRESS \
--priority=1000 \
--network=${GCP_ORG_OPS_VPC} \
--action=ALLOW \
--rules=tcp:80 \
--source-ranges=130.211.0.0/22,35.191.0.0/16 \
--enable-logging
```

```bash
gcloud compute firewall-rules create allow-ssh-ingress-from-iap \
  --project=${GCP_ORG_OPS_PROJECT} \
  --direction=INGRESS \
  --priority=1000 \
  --network=${GCP_ORG_OPS_VPC} \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  --enable-logging
  ```

### Create a GCS Bucket to host Org Ops artifacts in the Scaffolding GCP Project

```bash
gsutil mb gs://${GCP_ORG_OPS_GCS_ARTIFACTS} \
-p ${SCAFFOLDING_GCP_PROJECT}
```

### Upload artifacts to the Org Ops artifacts GCS Bucket

```bash
gsutil cp terraform gs://${GCP_ORG_OPS_GCS_ARTIFACTS}/terraform/
```

```bash
gsutil cp terraform-provider-google_v4.46.0_x5 gs://${GCP_ORG_OPS_GCS_ARTIFACTS}/gcp-provider/
```

### Bake the offline Terraform server

```bash
sudo yum install -y yum-utils
```

```bash
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
```

```bash
sudo yum -y install packer
```

### Upload the recipe to the scaffolding GCE VM

`packer/terraform-offline.pkr.hcl`
`packer/config.pkr.hcl`

### Bake the recipe with Packer from the scaffolding GCE VM

```bash
packer validate .
```

```bash
packer build .
```

Capture GCE Image name:

`export GCP_ORG_OPS_GCE_IMAGE={NEEDS_VALUE}`

### Deploy GCE VM for hosting GCP Org Ops Terraform Server VM

```bash
gcloud compute instances create ${GCP_ORG_OPS_GCE_VM} \
--project=${GCP_ORG_OPS_PROJECT} \
--zone=${GCP_ZONE} \
--machine-type=e2-medium \
--network-interface=subnet=${GCP_ORG_OPS_SUBNET},no-address \
--metadata=enable-oslogin=true \
--maintenance-policy=MIGRATE \
--provisioning-model=STANDARD \
--service-account=${GCP_ORG_OPS_SA_URL} \
--scopes=https://www.googleapis.com/auth/cloud-platform \
--create-disk=auto-delete=yes,boot=yes,device-name=instance-1,image=${GCP_ORG_OPS_GCE_IMAGE},mode=rw,size=20,type=projects/${GCP_ORG_OPS_PROJECT}/zones/${GCP_ZONE}/diskTypes/pd-balanced \
--shielded-secure-boot \
--shielded-vtpm \
--shielded-integrity-monitoring \
--labels=role=terraform-server,environment=operations,owner=sre-ops,impact-level=none,region=${GCP_ZONE},gcp-project=${GCP_ORG_OPS_PROJECT} \
--reservation-affinity=any
```

### Set up remote state in Cloud Storage

Create the remote backend bucket in Cloud Storage and the `backend.tf` Terraform file for storage of the `terraform.tfstate` file:

```bash
gsutil mb \
-p ${GCP_ORG_OPS_PROJECT} \
-l ${GCP_REGION} \
gs://${GCP_ORG_OPS_PROJECT}-tf-state
```

### Enable versioning for the Terraform state GCS bucket:

```bash
gsutil versioning set on gs://${GCP_ORG_OPS_PROJECT}-tf-state
```

---

## Current State

_Scaffolding_:

- [ ] GCP Project - `${SCAFFOLDING_GCP_PROJECT}`
- [ ] GCP Org Level Service Account = `${SCAFFOLDING_ORG_ADMIN}`
- [ ] GCP VPC - `${SCAFFOLDING_VPC}`
- [ ] GCP VPC Subnet - `${SCAFFOLDING_SUBNET}`
- [ ] GCE VM - `${SCAFFOLDING_GCE_VM}`

_GCP Org Ops_:

- [ ] GCP Folder - `${GCP_ORG_OPS_FOLDER}`
- [ ] GCP Project - `${GCP_ORG_OPS_PROJECT}`
- [ ] GCP Org level SA - `${GCP_ORG_OPS_SA}`
- [ ] GCP VPC - `${GCP_ORG_OPS_VPC}`
- [ ] GCP VPC Subnet - `${GCP_ORG_OPS_SUBNET}`
- [ ] GCE VM - `${GCP_ORG_OPS_GCE_VM}`
- [ ] GCS Artifact Bucket - `${}`

---

## GCP Bootstrap Complete

__Run Terraform from GCP Org Ops Offline Terraform Server__

__Move all ensured state from this point forward to Git Pull Requests__

