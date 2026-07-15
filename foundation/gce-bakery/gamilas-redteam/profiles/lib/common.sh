#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# gamilas-redteam — profiles/lib/common.sh
# Shared scaffolding for the two scan profiles: the AUTHORIZATION GATE, target config,
# an evidence/output directory, and small logging helpers. Sourced by every profile.
#
# This is an AUTHORIZED testing tool for OUR OWN infrastructure. The gate below is a
# deliberate seatbelt so the box can't be casually pointed at something it shouldn't be:
# a profile refuses to run unless you (a) name a TARGET and (b) export AUTHORIZED=yes,
# affirming you have written permission to scan it. Keep it that way.
# ---------------------------------------------------------------------------------------------------------------------
set -uo pipefail

# --- Target configuration (override via env or targets.env) ---------------------------------------------------------
# Defaults point at the yamato dev front door. Change for test/stage; never point this at
# infrastructure you do not own and are not authorized to test.
TARGET_HOST="${TARGET_HOST:-yamato-dev.iq9.io}"
TARGET_URL="${TARGET_URL:-https://${TARGET_HOST}}"
WIKI_PATH="${WIKI_PATH:-/wiki}"            # IAP-gated path
PUBLIC_PATH="${PUBLIC_PATH:-/}"            # rock-solid static landing

# Optional: load a local targets.env next to the profiles if present.
_here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -f "${_here}/targets.env" ] && . "${_here}/targets.env"

# --- Authorization gate ---------------------------------------------------------------------------------------------
require_authorization() {
  if [ "${AUTHORIZED:-no}" != "yes" ]; then
    cat >&2 <<EOF
[REFUSED] This is an authorized-testing tool. To run:
  export AUTHORIZED=yes        # you affirm written permission to scan the target
  export TARGET_HOST=<host>    # the system you own / are engaged to test
Current TARGET_HOST=${TARGET_HOST}
EOF
    exit 2
  fi
}

# --- Evidence directory + logging -----------------------------------------------------------------------------------
RUN_TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTDIR="${OUTDIR:-/var/log/gamilas/${PROFILE_NAME:-scan}-${RUN_TS}}"
mkdir -p "$OUTDIR"

c_red()  { printf '\033[31m%s\033[0m\n' "$*"; }
c_grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
c_yel()  { printf '\033[33m%s\033[0m\n' "$*"; }
c_cya()  { printf '\033[36m%s\033[0m\n' "$*"; }

log()    { echo "[$(date -u +%H:%M:%SZ)] $*" | tee -a "$OUTDIR/run.log"; }
step()   { echo; c_cya "==== $* ===="; echo "[$(date -u +%H:%M:%SZ)] STEP: $*" >> "$OUTDIR/run.log"; }

# Narrate the EXPECTED GCP defense for the step we just ran — this is what turns a scan
# log into a presentation. Printed in green; also captured to the evidence log.
defense() { c_grn "  [GCP DEFENSE] $*"; echo "  [GCP DEFENSE] $*" >> "$OUTDIR/run.log"; }

banner() {
  c_red "================================================================="
  c_red "  GAMILAS EMPIRE — assault on the Yamato   (${PROFILE_NAME:-scan})"
  c_red "  Target: ${TARGET_URL}"
  c_red "  Evidence: ${OUTDIR}"
  c_red "================================================================="
}
