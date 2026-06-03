package main

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"sort"
	"strings"
	"sync"
	"time"

	monitoring "cloud.google.com/go/monitoring/apiv3/v2"
	"cloud.google.com/go/monitoring/apiv3/v2/monitoringpb"
	"google.golang.org/api/iterator"

	"cloud.google.com/go/logging/logadmin"
)

// NOC dashboard at /wiki/noc — a live view of Cloud Armor + IAP defense
// activity, pulled at request time from the Cloud Logging API and the
// Cloud Monitoring API. The page is IAP-gated by the LB's /wiki/* path rule.
//
// Design notes
// ------------
//   - Every external call is in its own short-deadline context and runs in a
//     goroutine. If one API stalls or fails, the corresponding tile renders a
//     "logs unavailable" / "alert state unavailable" fallback and the page
//     continues to render. The whole page never 500s on a logging outage.
//   - Aggregation (top-N IPs / URLs / WAF priorities) is done client-side in
//     this handler because Cloud Logging has no GROUP BY. We cap the scan with
//     PageSize entries per query (see nocEntryCap below). On a quiet day the
//     results are exact; on a very busy day "top N" is exact within the
//     sampled window.
//   - Authentication is via Application Default Credentials. On Cloud Run, ADC
//     resolves to the runtime service account `iq9-yamato-dev-run`. The SA
//     needs roles/logging.viewer (for Cloud Logging) and roles/monitoring.viewer
//     (for alert policy state). See docs and the iam_changes_required note from
//     the build that introduced this handler — terraform change required.

// nocEntryCap bounds the number of log entries each Cloud Logging query
// will pull back before client-side aggregation. ~3000 is comfortably under
// the Cloud Run request budget (we run two scans in parallel, each with a
// 6s deadline) and large enough to make "top N" exact on all but the
// loudest attack days.
const nocEntryCap = 3000

// nocAPITimeout is the per-call deadline applied to every Cloud Logging and
// Cloud Monitoring call this handler makes. Cloud Run's request budget is
// ~15s for healthy pages, and the handler fans out three calls in parallel,
// so each gets a comfortable share before the meta-refresh tries again.
const nocAPITimeout = 6 * time.Second

// nocProjectID returns the project ID the handler queries against. It checks
// the GCP_PROJECT env (set on Cloud Run) first, then falls back to the dev
// project hard-default so a local `go run` still renders the page shape.
func nocProjectID() string {
	return getenv("GCP_PROJECT", "iq9-gcp-dev-yamato")
}

// nocCountTile holds the "blocks in the last 1h / 24h" tile data.
type nocCountTile struct {
	Last1h    int64
	Last24h   int64
	Available bool   // false → render the fallback ("logs unavailable")
	Error     string // operator-visible explanation when Available is false
}

// nocTopRow is one row in a top-N tile (IPs, URLs, WAF priorities).
type nocTopRow struct {
	Key   string
	Count int64
}

// nocTopTile is a generic top-N tile (top IPs / top URLs / top priorities).
type nocTopTile struct {
	Rows      []nocTopRow
	Available bool
	Error     string
	Empty     bool // true when the API call succeeded but returned zero rows
}

// nocAlertRow is one alert policy's live state.
type nocAlertRow struct {
	DisplayName string
	Enabled     bool
	Severity    string // "RED", "AMBER", "GREEN" — derived; see colorClass()
	LastChange  string // human-readable timestamp of last policy mutation
}

// ColorClass maps the internal severity to the CSS class hook.
func (r nocAlertRow) ColorClass() string {
	switch r.Severity {
	case "RED":
		return "noc-alert-red"
	case "AMBER":
		return "noc-alert-amber"
	default:
		return "noc-alert-green"
	}
}

// nocAlertTile holds the 9-policy state board.
type nocAlertTile struct {
	Rows      []nocAlertRow
	Available bool
	Error     string
	Empty     bool
}

// nocPageData is the typed bag the noc_dashboard.html template renders.
type nocPageData struct {
	Title       string
	User        string
	Project     string
	AsOf        string // "YYYY-MM-DD HH:MM:SS UTC" — printed in the header so
	// the prospect sees the dashboard is live, not cached.
	RefreshSecs int
	Counts      nocCountTile
	TopIPs      nocTopTile
	TopURLs     nocTopTile
	TopPriors   nocTopTile
	Alerts      nocAlertTile
}

// nocBlockedFilter is the Cloud Logging filter that selects Cloud Armor
// DENY events at the external HTTPS load balancer over the freshness window.
// The shape mirrors `docs/security/in-the-wild-2026-06-03.md` Methodology
// section — the `enforcedSecurityPolicy.outcome="DENY"` predicate is the
// canonical signal that Layer 1 stopped a request at the edge. The OR-arm
// with `statusDetails="denied_by_security_policy"` catches the legacy field
// some entries surface instead of the nested outcome.
//
// `since` is rendered as an RFC3339 timestamp on the `timestamp>="..."` clause
// rather than `--freshness=Nh`, because the logadmin Go client does not have
// a freshness flag the way `gcloud logging read` does.
func nocBlockedFilter(since time.Time) string {
	return fmt.Sprintf(
		`resource.type="http_load_balancer" `+
			`AND (jsonPayload.enforcedSecurityPolicy.outcome="DENY" `+
			`OR jsonPayload.statusDetails="denied_by_security_policy") `+
			`AND timestamp>="%s"`,
		since.UTC().Format(time.RFC3339),
	)
}

// handleNOCDashboard renders the live NOC dashboard at /wiki/noc.
//
// The handler fans out three independent API calls in parallel:
//
//   - one Cloud Logging scan of the last 24h Cloud Armor DENY events,
//     which feeds the counts tile, top-IPs tile, top-URLs tile, and
//     top-priorities tile (one scan, four aggregations);
//   - one Cloud Logging scan of the last 1h DENY events for the 1h counter;
//   - one Cloud Monitoring call for the 9 alert policy states.
//
// Each call has an independent failure mode and an independent fallback;
// the page always renders even when every external call fails.
func (a *app) handleNOCDashboard(w http.ResponseWriter, r *http.Request) {
	proj := nocProjectID()
	now := time.Now().UTC()

	data := nocPageData{
		Title:       "Defense Command · Live",
		User:        iapUser(r),
		Project:     proj,
		AsOf:        now.Format("2006-01-02 15:04:05 UTC"),
		RefreshSecs: 30,
	}

	// Three goroutines fan out in parallel. Each writes only to its own
	// pre-declared local variables; the handler assembles the data struct
	// after wg.Wait() to keep concurrent access to data fields out of the
	// picture entirely. Each fanout call wraps the request context in a
	// nocAPITimeout deadline so a hung API does not pin the page.
	var (
		wg sync.WaitGroup

		// 24h scan outputs.
		scan24Err error
		count24h  int64
		ipsMap    map[string]int64
		urlsMap   map[string]int64
		priorsMap map[string]int64

		// 1h scan output.
		scan1hErr error
		count1h   int64

		// Alert tile output.
		alertErr  error
		alertTile nocAlertTile
	)
	wg.Add(3)

	go func() {
		defer wg.Done()
		// The 24h scan feeds three tiles at once (top IPs, top URLs, top
		// priorities) and also the 24h half of the counts tile.
		ctx, cancel := context.WithTimeout(r.Context(), nocAPITimeout)
		defer cancel()
		count24h, ipsMap, urlsMap, priorsMap, scan24Err = scan24h(ctx, proj, now)
	}()

	go func() {
		defer wg.Done()
		ctx, cancel := context.WithTimeout(r.Context(), nocAPITimeout)
		defer cancel()
		count1h, scan1hErr = scan1hCount(ctx, proj, now)
	}()

	go func() {
		defer wg.Done()
		ctx, cancel := context.WithTimeout(r.Context(), nocAPITimeout)
		defer cancel()
		alertTile, alertErr = fetchAlertTile(ctx, proj)
	}()

	wg.Wait()

	// 24h tiles (counts/24h half, top IPs, top URLs, top priorities).
	if scan24Err != nil {
		msg := "Cloud Logging unavailable — retry on next refresh"
		data.Counts.Error = msg
		data.TopIPs = nocTopTile{Available: false, Error: msg}
		data.TopURLs = nocTopTile{Available: false, Error: msg}
		data.TopPriors = nocTopTile{Available: false, Error: msg}
	} else {
		data.Counts.Last24h = count24h
		data.Counts.Available = true
		data.TopIPs = topTile(ipsMap, 5)
		data.TopURLs = topTile(urlsMap, 5)
		data.TopPriors = topTile(priorsMap, 5)
	}

	// 1h half of the counts tile is independent: it can succeed when the
	// 24h scan failed (or vice versa). Available stays true if either side
	// has data; the template renders "—" for the side that errored.
	if scan1hErr != nil {
		if data.Counts.Error == "" {
			data.Counts.Error = "1h window unavailable"
		}
	} else {
		data.Counts.Last1h = count1h
		data.Counts.Available = true
	}

	// Alert tile.
	if alertErr != nil {
		data.Alerts = nocAlertTile{Available: false, Error: "Monitoring API unavailable — alert state cannot be read"}
	} else {
		data.Alerts = alertTile
	}

	a.render(w, "noc_dashboard.html", data)
}

// scan24h pulls every Cloud Armor DENY event in the last 24h and returns
// the total count plus three frequency maps the caller turns into top-N
// tiles. PageSize is capped at nocEntryCap; if the actual 24h volume is
// higher than the cap (very loud day), the aggregations are accurate
// within the sampled window.
func scan24h(ctx context.Context, projectID string, now time.Time) (int64, map[string]int64, map[string]int64, map[string]int64, error) {
	since := now.Add(-24 * time.Hour)
	client, err := logadmin.NewClient(ctx, projectID)
	if err != nil {
		return 0, nil, nil, nil, fmt.Errorf("logadmin client: %w", err)
	}
	defer client.Close()

	it := client.Entries(ctx,
		logadmin.Filter(nocBlockedFilter(since)),
		logadmin.PageSize(nocEntryCap),
		logadmin.NewestFirst(),
	)

	ips := map[string]int64{}
	urls := map[string]int64{}
	priors := map[string]int64{}
	var n int64

	for n < nocEntryCap {
		e, err := it.Next()
		if errors.Is(err, iterator.Done) {
			break
		}
		if err != nil {
			return 0, nil, nil, nil, fmt.Errorf("entries.Next: %w", err)
		}
		n++

		if e.HTTPRequest != nil {
			if ip := strings.TrimSpace(e.HTTPRequest.RemoteIP); ip != "" {
				ips[ip]++
			}
			if e.HTTPRequest.Request != nil && e.HTTPRequest.Request.URL != nil {
				if p := canonicalPath(e.HTTPRequest.Request.URL); p != "" {
					urls[p]++
				}
			}
		}

		// Cloud Armor policy match: jsonPayload.enforcedSecurityPolicy.priority
		// arrives in the Payload map (logadmin unwraps JSON payloads into
		// map[string]any). The shape is robust to missing fields — we just
		// skip the prior bucket if anything is absent.
		if p := extractPriority(e.Payload); p != "" {
			priors[p]++
		}
	}

	return n, ips, urls, priors, nil
}

// scan1hCount counts (only) the Cloud Armor DENY events in the last hour.
// Separated from the 24h scan so a failure of either window leaves the
// other intact, and so the 1h number is not a stale aggregate when the
// 24h scan hits the entry cap.
func scan1hCount(ctx context.Context, projectID string, now time.Time) (int64, error) {
	since := now.Add(-1 * time.Hour)
	client, err := logadmin.NewClient(ctx, projectID)
	if err != nil {
		return 0, fmt.Errorf("logadmin client: %w", err)
	}
	defer client.Close()

	it := client.Entries(ctx,
		logadmin.Filter(nocBlockedFilter(since)),
		logadmin.PageSize(nocEntryCap),
		logadmin.NewestFirst(),
	)
	var n int64
	for n < nocEntryCap {
		_, err := it.Next()
		if errors.Is(err, iterator.Done) {
			break
		}
		if err != nil {
			return 0, fmt.Errorf("entries.Next: %w", err)
		}
		n++
	}
	return n, nil
}

// canonicalPath strips host/scheme and trims a URL down to its path so the
// top-N URLs tile groups `/wp-config.php` from any source IP into one row.
// Cloud Armor's request URLs are typically already paths, but the
// httpRequest.requestUrl field can carry the full URL on some routes — we
// take only what `url.Parse` returned as Path. Empty paths are returned as
// "/" so the tile renders a meaningful label.
func canonicalPath(u *url.URL) string {
	if u == nil {
		return ""
	}
	p := u.Path
	if p == "" {
		p = u.RequestURI() // covers `?...` only
	}
	if p == "" {
		return "/"
	}
	// Defensive cap: very long URLs (e.g. command-injection payloads) would
	// blow out the tile layout. The aggregation key is truncated, not the
	// stored URL.
	const maxLen = 120
	if len(p) > maxLen {
		return p[:maxLen] + "…"
	}
	return p
}

// extractPriority pulls the Cloud Armor rule priority out of a JSON log
// entry payload. The Cloud Logging entry's jsonPayload is unmarshalled by
// the logadmin client into map[string]any with nested maps; we walk the
// `enforcedSecurityPolicy.priority` chain defensively and return "" if
// anything along the path is missing or the wrong type. Priorities come
// back as integers from the API; we render them as the bare integer string
// so they sort and group correctly.
func extractPriority(payload any) string {
	m, ok := payload.(map[string]any)
	if !ok {
		return ""
	}
	esp, ok := m["enforcedSecurityPolicy"].(map[string]any)
	if !ok {
		return ""
	}
	switch p := esp["priority"].(type) {
	case float64:
		return fmt.Sprintf("%d", int64(p))
	case int64:
		return fmt.Sprintf("%d", p)
	case int:
		return fmt.Sprintf("%d", p)
	case string:
		return p
	}
	return ""
}

// topTile turns a frequency map into a top-N tile (sorted descending by
// count, then ascending by key for stable ordering). An empty map returns
// a tile flagged Empty so the template can render the "no activity"
// message instead of an empty list.
func topTile(counts map[string]int64, n int) nocTopTile {
	if len(counts) == 0 {
		return nocTopTile{Available: true, Empty: true}
	}
	rows := make([]nocTopRow, 0, len(counts))
	for k, v := range counts {
		rows = append(rows, nocTopRow{Key: k, Count: v})
	}
	sort.Slice(rows, func(i, j int) bool {
		if rows[i].Count != rows[j].Count {
			return rows[i].Count > rows[j].Count
		}
		return rows[i].Key < rows[j].Key
	})
	if len(rows) > n {
		rows = rows[:n]
	}
	return nocTopTile{Rows: rows, Available: true}
}

// fetchAlertTile lists every alert policy in the project and returns a
// best-effort live state. The Monitoring v3 SDK does not expose firing
// incidents directly, so the live signal we surface here is:
//
//   - Enabled / disabled (from the policy itself)
//   - Severity (RED if disabled or invalid, AMBER if recently mutated, GREEN
//     if enabled and stable)
//   - Last mutation timestamp (operator-visible "last changed" hint)
//
// If/when the Go SDK grows an Incidents.List, this can be enriched without
// changing the tile contract. The template renders one row per policy and
// only the colorClass+timestamp move.
func fetchAlertTile(ctx context.Context, projectID string) (nocAlertTile, error) {
	client, err := monitoring.NewAlertPolicyClient(ctx)
	if err != nil {
		return nocAlertTile{}, fmt.Errorf("alert policy client: %w", err)
	}
	defer client.Close()

	it := client.ListAlertPolicies(ctx, &monitoringpb.ListAlertPoliciesRequest{
		Name: "projects/" + projectID,
	})

	rows := []nocAlertRow{}
	for {
		p, err := it.Next()
		if errors.Is(err, iterator.Done) {
			break
		}
		if err != nil {
			return nocAlertTile{}, fmt.Errorf("alert policies.Next: %w", err)
		}

		enabled := false
		if p.GetEnabled() != nil {
			enabled = p.GetEnabled().GetValue()
		}

		// Severity heuristic — see fetchAlertTile docstring for the contract.
		// Disabled or invalid policies are RED; everything else is GREEN. We
		// do not currently surface AMBER (no recent-mutation signal that
		// reads cleanly without an incidents API), but the template knows
		// how to render it for the day a firing-incident lookup is added.
		sev := "GREEN"
		if !enabled || p.GetValidity().GetCode() != 0 {
			sev = "RED"
		}

		lastChange := ""
		if mr := p.GetMutationRecord(); mr != nil && mr.GetMutateTime() != nil {
			lastChange = mr.GetMutateTime().AsTime().UTC().Format("2006-01-02 15:04 UTC")
		}

		name := p.GetDisplayName()
		if name == "" {
			// Fall back to the policy resource name's trailing ID rather than
			// the empty string so a misconfigured policy is still legible.
			name = p.GetName()
		}

		rows = append(rows, nocAlertRow{
			DisplayName: name,
			Enabled:     enabled,
			Severity:    sev,
			LastChange:  lastChange,
		})
	}

	sort.Slice(rows, func(i, j int) bool {
		// Disabled / RED policies float to the top so the prospect's eye
		// catches problems first; the remaining rows stay alphabetical.
		if (rows[i].Severity == "RED") != (rows[j].Severity == "RED") {
			return rows[i].Severity == "RED"
		}
		return rows[i].DisplayName < rows[j].DisplayName
	})

	return nocAlertTile{Rows: rows, Available: true, Empty: len(rows) == 0}, nil
}
