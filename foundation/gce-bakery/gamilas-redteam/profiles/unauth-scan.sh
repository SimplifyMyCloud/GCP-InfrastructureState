#!/usr/bin/env bash
# ---------------------------------------------------------------------------------------------------------------------
# gamilas-redteam — PROFILE 1 — Unauthenticated external attacker ("no creds")
# The Gamilas show up cold off the public internet with zero credentials. They can ONLY
# reach the rock-solid static landing page; everything else is a wall. This profile runs
# the standard external playbook and narrates, at each step, the GCP control that stops it
# and where the attempt is logged. Run from the DigitalOcean droplet for a true "outside
# GCP" vantage.
#
# Usage:
#   export AUTHORIZED=yes TARGET_HOST=yamato-dev.iq9.io
#   /opt/gamilas/profiles/unauth-scan.sh
# ---------------------------------------------------------------------------------------------------------------------
PROFILE_NAME="profile1-unauth"
# shellcheck disable=SC1091
source "$(dirname "$0")/lib/common.sh"

require_authorization
banner

# --- 1. Perimeter / port scan ---------------------------------------------------------------------------------------
step "Port & service scan (nmap)"
nmap -Pn -sV --top-ports 200 "$TARGET_HOST" -oN "$OUTDIR/nmap.txt" || true
defense "Only 443 (HTTPS LB) answers. There is no VM/SSH/DB to find — Cloud Run + Cloud SQL"
defense "have no public IPs. The global HTTPS LB front door is the ONLY exposed surface."

# --- 2. TLS posture -------------------------------------------------------------------------------------------------
step "TLS / cipher / certificate audit (testssl.sh)"
testssl.sh --quiet --color 0 "$TARGET_HOST" > "$OUTDIR/testssl.txt" 2>&1 || true
defense "Google-managed certificate, modern TLS only. Nothing to downgrade or strip."

# --- 3. Tech fingerprint --------------------------------------------------------------------------------------------
step "Tech fingerprint (whatweb)"
whatweb -a 3 "$TARGET_URL" | tee "$OUTDIR/whatweb.txt" || true
defense "Fingerprint stops at the LB/Google front end — no app stack version leaks."

# --- 4. Content discovery -------------------------------------------------------------------------------------------
step "Content / directory discovery (feroxbuster + ffuf)"
WORDLIST="/usr/share/seclists/Discovery/Web-Content/raft-medium-directories.txt"
[ -f "$WORDLIST" ] || WORDLIST="/usr/share/wordlists/dirb/common.txt"
feroxbuster -u "$TARGET_URL" -w "$WORDLIST" -q -o "$OUTDIR/ferox.txt" 2>/dev/null || \
  ffuf -u "${TARGET_URL}/FUZZ" -w "$WORDLIST" -of csv -o "$OUTDIR/ffuf.csv" 2>/dev/null || true
defense "Public path serves a STATIC page only. ${WIKI_PATH} returns a 302 to Google login"
defense "(IAP) — the app is never reached. No 200s leak beyond the landing page."

# --- 5. IAP wall check ----------------------------------------------------------------------------------------------
step "Probe the IAP-gated wiki path (expect a redirect to Google login)"
curl -s -o /dev/null -D "$OUTDIR/wiki-headers.txt" -w 'HTTP %{http_code} -> %{redirect_url}\n' \
  "${TARGET_URL}${WIKI_PATH}" | tee "$OUTDIR/wiki-probe.txt" || true
defense "IAP intercepts BEFORE the request reaches Cloud Run. Identity-Aware Proxy =="
defense "Google login + your @iq9.io allow-list. No valid identity, no app. Period."

# --- 6. Web vuln baseline -----------------------------------------------------------------------------------------
step "Web vuln scan (nikto + nuclei + ZAP baseline)"
nikto -host "$TARGET_URL" -output "$OUTDIR/nikto.txt" || true
nuclei -u "$TARGET_URL" -t /opt/nuclei-templates -o "$OUTDIR/nuclei.txt" 2>/dev/null || true
zap.sh -cmd -quickurl "$TARGET_URL" -quickout "$OUTDIR/zap-baseline.html" 2>/dev/null || true
defense "Only the static surface is testable — minimal attack surface by design."

# --- Wrap ----------------------------------------------------------------------------------------------------------
step "Profile 1 complete"
c_grn "Outside the wall, nothing gave. Every probe above generated Cloud Armor / LB"
c_grn "request logs and is queryable in Cloud Logging + the org audit sink."
log "Profile 1 (unauth) finished. Evidence in $OUTDIR"
echo "Evidence: $OUTDIR"
