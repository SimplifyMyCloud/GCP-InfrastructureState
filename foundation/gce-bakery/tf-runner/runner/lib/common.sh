#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# tf-runner — runner/lib/common.sh
# Shared scaffolding for the tf-run wrapper: identity selection (the RO/RW swap), the
# write-window gate, repo location, and logging. Sourced by tf-run.sh.
#
# IDENTITY MODEL — keyless, never pinned in code (matches repo-root gcp_provider.tf):
#
#   * The runner VM boots with an ATTACHED service account (its base identity, resolved
#     by ADC off the metadata server). That base SA is deliberately low-privilege.
#   * For each run, the wrapper selects the phase-appropriate target SA and mints a
#     SHORT-LIVED impersonated access token for it, exported as GOOGLE_OAUTH_ACCESS_TOKEN
#     — which both the google provider and the GCS backend consume. No keys, no tf edits.
#       - plan            -> impersonate the READ-ONLY  SA  (TFRUN_RO_SA)
#       - apply / destroy -> impersonate the READ-WRITE SA  (TFRUN_RW_SA)
#   * The "swap on the release schedule" is enforced by IAM, not by this script: the base
#     SA only holds roles/iam.serviceAccountTokenCreator on the RW SA DURING an approved
#     deployment window (a Foundation IAM change). Outside the window, minting an RW token
#     simply fails — least privilege by time.
#
# FALLBACK — if a target SA env var is unset, the wrapper runs as the attached SA directly
# (the "attached-SA swap" model, where you instead stop the VM and change its attached SA
# RO<->RW). Both models are valid; see ../readme.md. This script supports either.
# ---------------------------------------------------------------------------------------------------------------------
set -uo pipefail

# Where the IaC repo is checked out on the runner. Pull it fresh per run (CI/automation),
# rather than baking it into the image where it would go stale.
REPO_DIR="${TFRUN_REPO_DIR:-/opt/iac/GCP-InfrastructureState}"

log()  { echo "[$(date -u +%H:%M:%SZ)] $*"; }
die()  { echo "[tf-run][FATAL] $*" >&2; exit 1; }

# select_identity <ro|rw> — set GOOGLE_OAUTH_ACCESS_TOKEN by impersonating the target SA,
# or fall through to the attached-SA ADC if no target is configured.
select_identity() {
  local phase="$1" target=""
  case "$phase" in
    ro) target="${TFRUN_RO_SA:-}" ;;
    rw) target="${TFRUN_RW_SA:-}" ;;
    *)  die "select_identity: unknown phase '$phase'" ;;
  esac

  if [ -n "$target" ]; then
    log "Identity: impersonating ${phase^^} SA -> ${target}"
    local token
    token="$(gcloud auth print-access-token --impersonate-service-account="$target" 2>/dev/null)" \
      || die "could not mint a token for ${target} — is tokenCreator granted for THIS phase/window?"
    export GOOGLE_OAUTH_ACCESS_TOKEN="$token"
  else
    log "Identity: no ${phase^^} target SA set — using the VM's attached SA via ADC (attached-SA-swap model)."
    unset GOOGLE_OAUTH_ACCESS_TOKEN 2>/dev/null || true
  fi
}

# require_write_window — RW actions (apply/destroy) are double-gated: the operator/automation
# must explicitly assert an approved deployment window. Belt-and-suspenders on top of the
# IAM time-boxing above, so a stray `apply` outside a window can't slip through.
require_write_window() {
  [ "${TFRUN_ALLOW_WRITE:-no}" = "yes" ] \
    || die "RW action blocked: export TFRUN_ALLOW_WRITE=yes only inside an approved deployment window."
}
