# Bootstrap Playbook

A pilot's pre-flight: copy-paste each block into GCP Cloud Shell in order, top-to-bottom, ticking each step off in `bootstrap-checklist.md` as you go.

> **Run this once, manually, from GCP Cloud Shell as the genesis Org Admin.**

The playbook is split into eight phases. Phase 0 captures identifiers; phases 1–6 build the foundation; phases 7–8 hand off to Terraform and clean up the short-lived bootstrap.

| Phase | What it does | State at end |
| --- | --- | --- |
| 0 | Pre-flight — capture identifiers, set env vars | Variables exported in shell |
| 1 | Baseline GCP Org policies | Policies enforce on every future resource |
| 2 | Temporary genesis admin elevations | Genesis admin can create folders/projects |
| 3 | Create `iq9`, `ops`, `iq9-bootstrap`, `iq9-bootstrap-sa` | Bootstrap SA exists with org-level perms |
| 4 | Create `iq9-ops-iac`, `iq9-tf-foundation-sa`, `gs://iq9-iac-ops-tf-state-bucket`, `iq9-tf-runner` | Long-lived TF infra exists |
| 5 | Create `logs`, `iq9-logging-warehouse`, archive bucket, `iq9` folder-level log sink | Every action inside `iq9/` from here on is captured in the archive |
| 6 | De-privilege the genesis admin | Genesis admin returns to baseline perms |
| 7 | Hand off to the Foundation Layer | Runner VM applies `foundation/` |
| 8 | Archive `iq9-bootstrap` | Short-lived bootstrap project + SA gone |

> **Clean-room mode notes:** if the GCP Org already has resources outside `iq9/`, no special steps are needed for phases 1–6 — the `iq9/` hierarchy is a brand new sibling, and Phase 5's folder-scoped log sink only captures what lives inside `iq9/`, leaving the rest of the org untouched. Existing projects/folders can be imported into Terraform later as time allows.

> **Retention lock deferred until end-to-end is verified.** Phase 5 sets a 180-day retention policy on the warehouse bucket, but the `--lock-retention-period` command is left commented out. Lock the policy only after you've watched logs land and verified everything works. The lock is one-way; once fired, the bucket is immutable for 180 days.

---

## Phase 0 — Pre-flight

Open Cloud Shell at <https://console.cloud.google.com/>. Capture the org and billing IDs:

```bash
gcloud organizations list
gcloud billing accounts list
```

Export the identifiers and the genesis admin's email. Everything downstream uses these vars.

```bash
export TF_VAR_ORG_ID=123456789000
export TF_VAR_BILLING_ACCOUNT=012345-ABCDEF-012345
export TF_VAR_GENESIS_ADMIN=$(gcloud config get-value account)
export TF_VAR_REGION=us-west1
export TF_VAR_ZONE=us-west1-a
```

---

## Phase 1 — Baseline GCP Org policies

Set these **before** any projects exist so they apply to every project the bootstrap and foundation layer will create. Some org policies are not retroactive; getting them in first means the desired-state is universal from genesis.

```bash
# Require OS Login on every GCE VM. SSH access goes through GCP IAM,
# never local Linux user accounts. One of the highest-value policies you can set.
gcloud resource-manager org-policies enable-enforce \
  compute.requireOsLogin \
  --organization=${TF_VAR_ORG_ID}

# Forbid creation of long-lived service account keys. Force impersonation
# / workload identity instead.
gcloud resource-manager org-policies enable-enforce \
  iam.disableServiceAccountKeyCreation \
  --organization=${TF_VAR_ORG_ID}

# Skip the auto-created `default` VPC on every new project. The Foundation
# Layer creates host VPCs explicitly.
gcloud resource-manager org-policies enable-enforce \
  compute.skipDefaultNetworkCreation \
  --organization=${TF_VAR_ORG_ID}
```

---

## Phase 2 — Temporary genesis admin elevations

The genesis Org Admin needs a few extra roles to run Phase 3. These come off again in Phase 6.

```bash
for role in roles/resourcemanager.folderCreator \
            roles/resourcemanager.projectCreator \
            roles/billing.user \
            roles/iam.serviceAccountAdmin \
            roles/serviceusage.serviceUsageAdmin; do
  gcloud organizations add-iam-policy-binding ${TF_VAR_ORG_ID} \
    --member=user:${TF_VAR_GENESIS_ADMIN} \
    --role=${role}
done
```

---

## Phase 3 — Create `iq9`, `ops`, `iq9-bootstrap`, `iq9-bootstrap-sa`

Build the top of the folder tree and the short-lived bootstrap project + SA.

```bash
# --- iq9 (top-level folder) ---
export IQ9_FOLDER=$(gcloud resource-manager folders create \
  --display-name=iq9 \
  --organization=${TF_VAR_ORG_ID} \
  --format='value(name)' | sed 's|folders/||')
echo "iq9 folder id: ${IQ9_FOLDER}"

# --- ops (folder) ---
export IQ9_OPS_FOLDER=$(gcloud resource-manager folders create \
  --display-name=ops \
  --folder=${IQ9_FOLDER} \
  --format='value(name)' | sed 's|folders/||')
echo "ops folder id: ${IQ9_OPS_FOLDER}"

# --- iq9-bootstrap (project, short-lived) ---
gcloud projects create iq9-bootstrap \
  --folder=${IQ9_OPS_FOLDER}

gcloud billing projects link iq9-bootstrap \
  --billing-account=${TF_VAR_BILLING_ACCOUNT}

# Enable the APIs the bootstrap SA will exercise (single call = much faster than a loop)
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  cloudbilling.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  serviceusage.googleapis.com \
  storage.googleapis.com \
  compute.googleapis.com \
  logging.googleapis.com \
  --project=iq9-bootstrap

# --- iq9-bootstrap-sa (the short-lived bootstrap SA) ---
gcloud iam service-accounts create iq9-bootstrap-sa \
  --project=iq9-bootstrap \
  --display-name="iq9 Bootstrap SA — short-lived, deleted after foundation deploys"

export BOOTSTRAP_SA=iq9-bootstrap-sa@iq9-bootstrap.iam.gserviceaccount.com

# Grant the bootstrap SA the org-level perms it needs to create folders/projects
for role in roles/resourcemanager.folderAdmin \
            roles/resourcemanager.projectCreator \
            roles/billing.user \
            roles/iam.serviceAccountAdmin \
            roles/iam.serviceAccountTokenCreator \
            roles/serviceusage.serviceUsageAdmin \
            roles/storage.admin \
            roles/compute.admin \
            roles/logging.configWriter \
            roles/logging.admin; do
  gcloud organizations add-iam-policy-binding ${TF_VAR_ORG_ID} \
    --member=serviceAccount:${BOOTSTRAP_SA} \
    --role=${role}
done

# Allow the genesis admin to impersonate the bootstrap SA.
# (--project is required: gcloud's resource parser doesn't reliably extract
# the project from the SA email here. Quote --member to be safe.)
gcloud iam service-accounts add-iam-policy-binding ${BOOTSTRAP_SA} \
  --project=iq9-bootstrap \
  --member="user:${TF_VAR_GENESIS_ADMIN}" \
  --role=roles/iam.serviceAccountTokenCreator

# From this point on, every command impersonates the bootstrap SA so that
# the audit log attributes every action to it, not to the genesis human.
export IMPERSONATE="--impersonate-service-account=${BOOTSTRAP_SA}"
```

---

## Phase 4 — Create the long-lived ops IaC

`iq9-ops-iac` project, foundation SA, tfstate bucket, and TF runner VM.

```bash
# --- iq9-ops-iac (project, long-lived) ---
gcloud projects create iq9-ops-iac \
  --folder=${IQ9_OPS_FOLDER} \
  ${IMPERSONATE}

gcloud billing projects link iq9-ops-iac \
  --billing-account=${TF_VAR_BILLING_ACCOUNT} \
  ${IMPERSONATE}

gcloud services enable \
  cloudresourcemanager.googleapis.com \
  cloudbilling.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  serviceusage.googleapis.com \
  storage.googleapis.com \
  compute.googleapis.com \
  oslogin.googleapis.com \
  logging.googleapis.com \
  --project=iq9-ops-iac \
  ${IMPERSONATE}

# --- iq9-tf-foundation-sa (long-lived) ---
gcloud iam service-accounts create iq9-tf-foundation-sa \
  --project=iq9-ops-iac \
  --display-name="iq9 Terraform Foundation SA — long-lived, scoped to iq9 folder" \
  ${IMPERSONATE}

export FOUNDATION_SA=iq9-tf-foundation-sa@iq9-ops-iac.iam.gserviceaccount.com

# Scope the foundation SA's perms to the iq9 folder, NOT the org. Blast radius reduction.
for role in roles/resourcemanager.folderAdmin \
            roles/resourcemanager.projectCreator \
            roles/resourcemanager.projectDeleter \
            roles/billing.user \
            roles/compute.networkAdmin \
            roles/compute.securityAdmin \
            roles/iam.serviceAccountAdmin \
            roles/iam.serviceAccountUser \
            roles/serviceusage.serviceUsageAdmin \
            roles/storage.admin \
            roles/logging.configWriter \
            roles/logging.admin; do
  gcloud resource-manager folders add-iam-policy-binding ${IQ9_FOLDER} \
    --member=serviceAccount:${FOUNDATION_SA} \
    --role=${role} \
    ${IMPERSONATE}
done

# `roles/iam.roleAdmin` is project-scoped only (not folder-supported), so it gets
# granted separately at the iq9-ops-iac project. Lets terraform manage custom IAM
# roles in iq9-ops-iac going forward (e.g. iq9_iam_ops_tfstate_rw on the tfstate
# bucket). Roles for OTHER projects (dev, prod, sandbox, log-warehouse) will be
# granted by foundation/iam/ Terraform once those projects exist — the foundation
# SA becomes project-owner on creation and can grant roleAdmin to itself.
gcloud projects add-iam-policy-binding iq9-ops-iac \
  --member="serviceAccount:${FOUNDATION_SA}" \
  --role=roles/iam.roleAdmin \
  ${IMPERSONATE}

# Grant the bootstrap SA permission to *act as* the foundation SA. Without
# this binding, attaching the foundation SA to the iq9-tf-runner VM later
# in this phase fails with "user does not have access to service account".
# The grant is at the SA-resource scope (not project-wide), so the bootstrap
# SA can ONLY impersonate this one SA — minimum-privilege.
gcloud iam service-accounts add-iam-policy-binding ${FOUNDATION_SA} \
  --project=iq9-ops-iac \
  --member="serviceAccount:${BOOTSTRAP_SA}" \
  --role=roles/iam.serviceAccountUser \
  ${IMPERSONATE}

# --- gs://iq9-iac-ops-tf-state-bucket (single tfstate bucket for the whole repo) ---
gcloud storage buckets create gs://iq9-iac-ops-tf-state-bucket \
  --project=iq9-ops-iac \
  --location=${TF_VAR_REGION} \
  --uniform-bucket-level-access \
  --public-access-prevention \
  ${IMPERSONATE}

gcloud storage buckets update gs://iq9-iac-ops-tf-state-bucket \
  --versioning \
  ${IMPERSONATE}

gcloud storage buckets add-iam-policy-binding gs://iq9-iac-ops-tf-state-bucket \
  --member=serviceAccount:${FOUNDATION_SA} \
  --role=roles/storage.objectAdmin \
  ${IMPERSONATE}

# --- Bootstrap-temporary VPC for the runner VM ---
# Phase 1's `compute.skipDefaultNetworkCreation` org policy means no `default`
# VPC was auto-created. Build a minimal VPC + subnet just for the runner.
# This VPC will be replaced by the proper ops host VPC once foundation/ creates it.
gcloud compute networks create iq9-ops-iac-vpc \
  --project=iq9-ops-iac \
  --subnet-mode=custom \
  ${IMPERSONATE}

# Private Google Access ON so the VM (with --no-address) can reach googleapis.com.
gcloud compute networks subnets create iq9-ops-iac-subnet \
  --project=iq9-ops-iac \
  --network=iq9-ops-iac-vpc \
  --region=${TF_VAR_REGION} \
  --range=10.0.0.0/29 \
  --enable-private-ip-google-access \
  ${IMPERSONATE}

# Firewall: allow IAP-tunnel SSH (Google's managed IAP CIDR → tcp:22).
# Without this the VM has no inbound and `gcloud compute ssh --tunnel-through-iap` fails.
gcloud compute firewall-rules create iq9-ops-iac-allow-iap-ssh \
  --project=iq9-ops-iac \
  --network=iq9-ops-iac-vpc \
  --direction=INGRESS \
  --action=ALLOW \
  --rules=tcp:22 \
  --source-ranges=35.235.240.0/20 \
  ${IMPERSONATE}

# Cloud NAT — egress to the public internet for VMs without a public IP.
# Without this, --no-address VMs can reach googleapis.com (via Private Google
# Access) but NOT debian repos or hashicorp.com etc. ~$45/mo running cost.
gcloud compute routers create iq9-ops-iac-router \
  --project=iq9-ops-iac \
  --network=iq9-ops-iac-vpc \
  --region=${TF_VAR_REGION} \
  ${IMPERSONATE}

gcloud compute routers nats create iq9-ops-iac-nat \
  --project=iq9-ops-iac \
  --router=iq9-ops-iac-router \
  --region=${TF_VAR_REGION} \
  --auto-allocate-nat-external-ips \
  --nat-all-subnet-ip-ranges \
  ${IMPERSONATE}

# --- iq9-tf-runner (the GCE VM Terraform runs on) ---
# Vanilla Debian 12 for the bootstrap. Once foundation/gce-bakery/ exists,
# this VM is replaced by an instance from a Packer-baked image.
gcloud compute instances create iq9-tf-runner \
  --project=iq9-ops-iac \
  --zone=${TF_VAR_ZONE} \
  --machine-type=e2-small \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --service-account=${FOUNDATION_SA} \
  --scopes=cloud-platform \
  --subnet=iq9-ops-iac-subnet \
  --metadata=enable-oslogin=TRUE \
  --no-address \
  ${IMPERSONATE}

# SSH in via Identity-Aware Proxy (no public IP on the VM)
gcloud compute ssh iq9-tf-runner \
  --zone=${TF_VAR_ZONE} --tunnel-through-iap --project=iq9-ops-iac

# On the VM, install Terraform:
sudo apt-get update && sudo apt-get install -y unzip
TF_VERSION=1.10.5
wget https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip
unzip terraform_${TF_VERSION}_linux_amd64.zip && sudo mv terraform /usr/local/bin/
terraform -version
```

---

## Phase 5 — Logging environment + `iq9` folder-level log sink

This is the audit anchor for the `iq9/` hierarchy. The sink is scoped to the `iq9` folder (not the org) with `--include-children`, so every log line from every folder, project, and resource **inside `iq9/`** — including everything that comes after this point in the bootstrap itself — lands in the archive. Anything outside `iq9/` (existing SMC Dev, `smc-ops`, etc.) is left untouched.

> **Retention lock deferred.** `--lock-retention-period` is **commented out** below. Lock the policy only after you've watched logs land and verified end-to-end. The lock is one-way; once fired, the bucket is immutable for 180 days regardless of who owns the project.

```bash
# --- logs (folder) ---
export IQ9_LOG_FOLDER=$(gcloud resource-manager folders create \
  --display-name=logs \
  --folder=${IQ9_FOLDER} \
  --format='value(name)' \
  ${IMPERSONATE} | sed 's|folders/||')
echo "logs folder id: ${IQ9_LOG_FOLDER}"

# --- iq9-logging-warehouse (project) ---
gcloud projects create iq9-logging-warehouse \
  --folder=${IQ9_LOG_FOLDER} \
  ${IMPERSONATE}

gcloud billing projects link iq9-logging-warehouse \
  --billing-account=${TF_VAR_BILLING_ACCOUNT} \
  ${IMPERSONATE}

gcloud services enable \
  storage.googleapis.com \
  logging.googleapis.com \
  --project=iq9-logging-warehouse \
  ${IMPERSONATE}

# --- gs://iq9-logging-warehouse (the archive bucket) ---
# ARCHIVE storage class = cheapest cold storage; minimum 365-day storage cost,
# 12-hour minimum first-byte latency.
gcloud storage buckets create gs://iq9-logging-warehouse \
  --project=iq9-logging-warehouse \
  --location=${TF_VAR_REGION} \
  --default-storage-class=ARCHIVE \
  --uniform-bucket-level-access \
  --public-access-prevention \
  ${IMPERSONATE}

# Set the retention policy: 180 days (showcase value).
# A production deployment would use the org's compliance window (5–7 years).
gcloud storage buckets update gs://iq9-logging-warehouse \
  --retention-period=180d \
  ${IMPERSONATE}

# !! HOLD on the lock until end-to-end is verified !!
# When you're ready to make the bucket immutable, run:
# gcloud storage buckets update gs://iq9-logging-warehouse \
#   --lock-retention-period \
#   ${IMPERSONATE}

# Lifecycle rule — delete objects older than 180 days.
# (Aligns the deletion window with the retention policy.)
cat > /tmp/iq9-logging-warehouse-lifecycle.json << 'EOF'
{
  "lifecycle": {
    "rule": [
      {
        "action": { "type": "Delete" },
        "condition": { "age": 180 }
      }
    ]
  }
}
EOF

gcloud storage buckets update gs://iq9-logging-warehouse \
  --lifecycle-file=/tmp/iq9-logging-warehouse-lifecycle.json \
  ${IMPERSONATE}

# --- iq9-log-sink (folder-level log sink, scoped to the `iq9` folder tree) ---
# Folder-level rather than org-level: captures every log line from every
# folder, project, and resource INSIDE `iq9/`, but leaves anything outside
# `iq9/` untouched (e.g. existing SMC Dev, smc-ops). This keeps the iq9
# audit chain sealed without entangling the rest of the org.
# `--include-children` walks the entire iq9 subtree.
# No `--log-filter` flag = capture everything within scope.
gcloud logging sinks create iq9-log-sink \
  storage.googleapis.com/iq9-logging-warehouse \
  --folder=${IQ9_FOLDER} \
  --include-children \
  --description="iq9 folder-level log archive sink — captures every log inside the iq9/ tree into the immutable warehouse" \
  ${IMPERSONATE}

# The sink gets an auto-generated writer-identity SA. Grant it the
# permission to write objects into the warehouse bucket.
export SINK_WRITER_SA=$(gcloud logging sinks describe iq9-log-sink \
  --folder=${IQ9_FOLDER} \
  --format='value(writerIdentity)' \
  ${IMPERSONATE})
echo "sink writer identity: ${SINK_WRITER_SA}"

gcloud storage buckets add-iam-policy-binding gs://iq9-logging-warehouse \
  --member=${SINK_WRITER_SA} \
  --role=roles/storage.objectCreator \
  ${IMPERSONATE}
```

From this point forward, every log line in the org is captured. The audit chain is closed (the retention lock will close it permanently once you run the lock command).

---

## Phase 6 — De-privilege the genesis admin

Return the genesis Org Admin to baseline perms. The bootstrap SA now does the rest of the work via impersonation; the Foundation Layer SA does it after that.

```bash
for role in roles/resourcemanager.folderCreator \
            roles/resourcemanager.projectCreator \
            roles/billing.user \
            roles/iam.serviceAccountAdmin \
            roles/serviceusage.serviceUsageAdmin; do
  gcloud organizations remove-iam-policy-binding ${TF_VAR_ORG_ID} \
    --member=user:${TF_VAR_GENESIS_ADMIN} \
    --role=${role}
done
```

> **GCP Super Admins should now be offline** — passwords on paper, in a vault, two-person-rule for retrieval.

---

## Phase 7 — Hand off to the Foundation Layer

SSH into `iq9-tf-runner` (via IAP), clone this repo, and `terraform apply` the foundation directories in dependency order.

```bash
gcloud compute ssh iq9-tf-runner \
  --zone=${TF_VAR_ZONE} \
  --tunnel-through-iap \
  --project=iq9-ops-iac
```

On the VM:

```bash
git clone https://github.com/SimplifyMyCloud/GCP-InfrastructureState.git
cd GCP-InfrastructureState/foundation/gcp-folders
terraform init
terraform plan
terraform apply
# ...repeat for each foundation directory in the order in foundation/README.md
```

The Foundation Layer creates `iq9-ops-observability`, `iq9-ops-bakery`, `sandbox`, `dev`, `prod`, plus all networks, firewalls, IAM bindings, and additional logging configuration.

---

## Phase 8 — Archive the bootstrap

Once the Foundation Layer has finished, the short-lived bootstrap artifacts come down. This is itself a Terraform step, recorded in state, audit-trailed in the warehouse.

```bash
# Delete the bootstrap SA (no longer needed)
gcloud iam service-accounts delete ${BOOTSTRAP_SA} \
  --project=iq9-bootstrap

# Remove its org-level role bindings
for role in roles/resourcemanager.folderAdmin \
            roles/resourcemanager.projectCreator \
            roles/billing.user \
            roles/iam.serviceAccountAdmin \
            roles/iam.serviceAccountTokenCreator \
            roles/serviceusage.serviceUsageAdmin \
            roles/storage.admin \
            roles/compute.admin \
            roles/logging.configWriter \
            roles/logging.admin; do
  gcloud organizations remove-iam-policy-binding ${TF_VAR_ORG_ID} \
    --member=serviceAccount:${BOOTSTRAP_SA} \
    --role=${role}
done

# Delete the iq9-bootstrap project
gcloud projects delete iq9-bootstrap
```

The bootstrap is complete. From here on, **every change to the GCP Org is a Terraform PR**.
