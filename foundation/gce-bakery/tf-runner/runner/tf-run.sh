#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# tf-runner — runner/tf-run.sh   (installed on the image as /usr/local/bin/tf-run)
# Run terraform against one IaC state directory as the phase-appropriate service account.
#
#   tf-run plan    foundation/networks/bakery          # RO identity
#   tf-run apply   foundation/networks/bakery          # RW identity (needs deployment window)
#   tf-run destroy service/yamato/dev/cloudrun         # RW identity (needs deployment window)
#
# Identity selection and the RO/RW swap live in lib/common.sh. The state dir is given
# relative to the repo root (TFRUN_REPO_DIR). plan writes a tfplan; apply consumes it.
# ---------------------------------------------------------------------------------------------------------------------
set -euo pipefail
# shellcheck disable=SC1091
source "$(dirname "$0")/lib/common.sh"

ACTION="${1:-}"
STATE_DIR="${2:-}"
[ -n "$ACTION" ] && [ -n "$STATE_DIR" ] \
  || die "usage: tf-run <plan|apply|destroy> <state-dir-relative-to-repo-root>"

case "$ACTION" in
  plan)          PHASE=ro ;;
  apply|destroy) PHASE=rw ;;
  *) die "unknown action '$ACTION' (expected plan|apply|destroy)" ;;
esac

TARGET="${REPO_DIR}/${STATE_DIR}"
[ -d "$TARGET" ] || die "state dir not found: $TARGET (is the repo checked out at $REPO_DIR?)"

select_identity "$PHASE"
cd "$TARGET"
log "terraform init in ${STATE_DIR}"
terraform init -input=false

case "$ACTION" in
  plan)
    log "terraform plan (RO) -> tfplan"
    terraform plan -input=false -out=tfplan
    ;;
  apply)
    require_write_window
    if [ -f tfplan ]; then
      log "terraform apply (RW) of saved tfplan"
      terraform apply -input=false tfplan
    else
      log "no saved tfplan — applying with -auto-approve (RW)"
      terraform apply -input=false -auto-approve
    fi
    ;;
  destroy)
    require_write_window
    log "terraform destroy (RW)"
    terraform destroy -input=false -auto-approve
    ;;
esac

log "done: ${ACTION} ${STATE_DIR}"
