package main

import (
	"errors"
	"log"
	"net/http"
	"net/url"
	"strings"
)

func (a *app) handleHealth(w http.ResponseWriter, r *http.Request) {
	if err := a.db.ping(r.Context()); err != nil {
		http.Error(w, "db unavailable", http.StatusServiceUnavailable)
		return
	}
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	_, _ = w.Write([]byte("ok"))
}

func (a *app) handleLanding(w http.ResponseWriter, r *http.Request) {
	a.render(w, "landing.html", map[string]any{
		"Title": "Star Blazers Archive",
	})
}

func (a *app) handleWikiIndex(w http.ResponseWriter, r *http.Request) {
	groups, err := a.db.listGrouped(r.Context())
	if err != nil {
		a.serverError(w, "list articles", err)
		return
	}
	a.render(w, "wiki_index.html", map[string]any{
		"Title":  "Yamato Wiki",
		"User":   iapUser(r),
		"Groups": groups,
	})
}

func (a *app) handleArticle(w http.ResponseWriter, r *http.Request) {
	art, err := a.db.get(r.Context(), r.PathValue("slug"))
	if errors.Is(err, errNoRows) {
		http.NotFound(w, r)
		return
	}
	if err != nil {
		a.serverError(w, "get article", err)
		return
	}
	a.render(w, "article.html", map[string]any{
		"Title":   art.Title,
		"User":    iapUser(r),
		"Article": art,
	})
}

// navCard is one tile on the NOC ("Yamato Defense Command") page.
type navCard struct {
	No, Title, Desc, Href, Kind string
}

// handleNOC renders the internal NOC page. It is reachable only via the /noc path
// rule, which the load balancer routes to the IAP-gated backend — so, like /wiki,
// only signed-in @iq9.io / @simplifymy.cloud identities ever reach it. The page is a
// launcher: each tile deep-links to a live, auto-refreshing GCP surface (dashboards,
// Cloud Armor, pre-filtered Logs Explorer, alerting). Project + dashboard IDs are env
// vars with dev defaults, so the App Layer image stays environment-agnostic.
func (a *app) handleNOC(w http.ResponseWriter, r *http.Request) {
	proj := getenv("GCP_PROJECT", "iq9-gcp-dev-yamato")
	const console = "https://console.cloud.google.com"

	dash := func(id string) string {
		return console + "/monitoring/dashboards/custom/" + id + "?project=" + proj
	}
	logs := func(q string) string {
		return console + "/logs/query;query=" + strings.ReplaceAll(url.QueryEscape(q), "+", "%20") + "?project=" + proj
	}

	cards := []navCard{
		{"01", "Attack View", "Live edge blocks, IAP denials, IAM refusals & SA-impersonation attempts — the board that lights up under attack.", dash(getenv("DASH_SECURITY", "6ad77d51-ba49-4446-bce9-8efdc119422c")), "armor"},
		{"02", "Performance & Security", "Request rate by class, p95 latency, Cloud SQL CPU, secret access & front-door denials.", dash(getenv("DASH_PERF", "0f8924dc-7962-4215-b7cb-c369f0554c8f")), "perf"},
		{"03", "Cloud Armor Policy", "8 OWASP WAF rules + per-IP rate-limit ban, ENFORCE. Inspect rules and hit counts.", console + "/net-security/securitypolicies/details/" + getenv("ARMOR_POLICY", "iq9-dev-yamato-armor") + "?project=" + proj, "armor"},
		{"04", "Logs · Cloud Armor blocks", "Every request denied at the edge, with the matched WAF rule (VERBOSE).", logs(`resource.type="http_load_balancer" AND jsonPayload.enforcedSecurityPolicy.outcome="DENY"`), "logs"},
		{"05", "Logs · Denied API calls", "PERMISSION_DENIED across the project — the IAM wall holding the line.", logs(`protoPayload.status.code=7`), "logs"},
		{"06", "Logs · Front-door 403s", "IAP / authorization denials at the load balancer.", logs(`resource.type="http_load_balancer" AND httpRequest.status=403`), "logs"},
		{"07", "Alerting / Incidents", "Active alert policies and firing incidents (→ email).", console + "/monitoring/alerting?project=" + proj, "alert"},
	}

	a.render(w, "noc.html", map[string]any{
		"Title":   "Yamato Defense Command",
		"User":    iapUser(r),
		"Project": proj,
		"Cards":   cards,
	})
}

func (a *app) render(w http.ResponseWriter, name string, data any) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	if err := a.tmpl.ExecuteTemplate(w, name, data); err != nil {
		log.Printf("render %s: %v", name, err)
	}
}

func (a *app) serverError(w http.ResponseWriter, ctx string, err error) {
	log.Printf("%s: %v", ctx, err)
	http.Error(w, "internal server error", http.StatusInternalServerError)
}

// iapUser extracts the signed-in identity IAP asserts on requests it forwards.
// The header value looks like "accounts.google.com:user@iq9.io"; we want the
// trailing email. Empty when absent (e.g. local runs without IAP in front).
func iapUser(r *http.Request) string {
	v := r.Header.Get("X-Goog-Authenticated-User-Email")
	if v == "" {
		return ""
	}
	if i := strings.LastIndex(v, ":"); i >= 0 {
		return v[i+1:]
	}
	return v
}
