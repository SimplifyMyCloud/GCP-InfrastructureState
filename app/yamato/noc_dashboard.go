package main

import (
	"context"
	"errors"
	"fmt"
	"log"
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
//
// Per-side availability is tracked independently (Last1hAvailable /
// Last24hAvailable) so that when one scan errors and the other succeeds —
// a common transient on slow API days — the template renders "—" for the
// failed half rather than a misleading "0". Available remains true when
// either side has data, so the tile shell stays visible even on a partial
// outage; only when BOTH sides fail does the whole tile fall back to the
// "logs unavailable" empty state.
type nocCountTile struct {
	Last1h           int64
	Last24h          int64
	Last1hAvailable  bool
	Last24hAvailable bool
	Available        bool   // true when EITHER side has data (closes F-001)
	Error            string // operator-visible explanation; non-empty when at least one side failed
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

// nocTripwireTile holds the "Tripwire hits — 24h" tile data: a total
// count of honeypot hits in the last 24h plus the top 3 paths hit.
// Fed by a Cloud Logging scan of `jsonPayload.tripwire=true` entries
// on the public Cloud Run service (see nocTripwireFilter).
type nocTripwireTile struct {
	Total     int64
	Rows      []nocTopRow // top 3 paths by hit count
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
	Tripwire    nocTripwireTile
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

// nocTripwireServiceName returns the public Cloud Run service whose
// stderr stream carries honeypot tripwire entries. Env override exists
// so a future test/stage environment can point the tile at a different
// service without an image rebuild.
func nocTripwireServiceName() string {
	return getenv("HONEYPOT_SERVICE_NAME", "iq9-run-dev-yamato")
}

// nocTripwireFilter is the Cloud Logging filter the tripwire tile uses.
// Tripwire entries arrive on the public Cloud Run service's stderr as
// structured JSON (see honeypot.go logTripwire). resource.type and
// resource.labels.service_name pin the search to the right stream;
// jsonPayload.tripwire=true matches every honeypot hit and nothing else.
func nocTripwireFilter(since time.Time, serviceName string) string {
	return fmt.Sprintf(
		`resource.type="cloud_run_revision" `+
			`AND resource.labels.service_name="%s" `+
			`AND jsonPayload.tripwire=true `+
			`AND timestamp>="%s"`,
		serviceName,
		since.UTC().Format(time.RFC3339),
	)
}

// nocCacheTTL bounds how long an assembled page snapshot stays warm in
// memory before the next request re-runs the fan-out. 25s is deliberately
// shorter than the 30s meta-refresh interval so each refresh always
// re-validates against fresh data, but long enough that two visitors
// refreshing in the same window share one set of API calls. The TTL is
// also what smooths over occasional transient API timeouts: a single
// slow gRPC dial on one tile no longer flips the visible page between
// "data" and "unavailable" every refresh, because the prior good snapshot
// stays renderable while the next fetch runs.
const nocCacheTTL = 25 * time.Second

// nocState owns the NOC dashboard's per-process state: long-lived Cloud
// Logging and Cloud Monitoring clients (reused across requests instead of
// reconstructed every refresh — closes F-003) and a short-TTL cache of
// the assembled page (closes the auto-refresh flip-flop and brings cold-
// path LCP from ~6s to ~50ms on warm cache).
//
// Both clients are safe for concurrent use by multiple goroutines per
// the google-cloud-go SDK contract. Lazy init under clientMu lets a
// transient failure on the first request be retried on the second
// instead of poisoning the process for its lifetime (sync.Once would
// have done the latter).
type nocState struct {
	clientMu  sync.Mutex
	logClient *logadmin.Client
	monClient *monitoring.AlertPolicyClient

	cacheMu  sync.Mutex
	cached   *nocPageData
	cachedAt time.Time
}

// nocLogClient returns the process-shared Cloud Logging client, lazily
// constructing it on the first call (or after a prior init failure).
// Caller MUST NOT Close it; lifecycle is owned by app.Close().
func (a *app) nocLogClient(ctx context.Context) (*logadmin.Client, error) {
	a.noc.clientMu.Lock()
	defer a.noc.clientMu.Unlock()
	if a.noc.logClient != nil {
		return a.noc.logClient, nil
	}
	c, err := logadmin.NewClient(ctx, nocProjectID())
	if err != nil {
		return nil, err
	}
	a.noc.logClient = c
	return c, nil
}

// nocMonClient returns the process-shared Cloud Monitoring client. Same
// lifecycle contract as nocLogClient — caller MUST NOT Close.
func (a *app) nocMonClient(ctx context.Context) (*monitoring.AlertPolicyClient, error) {
	a.noc.clientMu.Lock()
	defer a.noc.clientMu.Unlock()
	if a.noc.monClient != nil {
		return a.noc.monClient, nil
	}
	c, err := monitoring.NewAlertPolicyClient(ctx)
	if err != nil {
		return nil, err
	}
	a.noc.monClient = c
	return c, nil
}

// getCachedNOC returns the most recently assembled page snapshot if it
// is still fresh, plus a bool indicating cache hit. The returned value
// is a shallow copy so the caller can overlay per-request fields (User)
// without mutating the cache.
func (a *app) getCachedNOC() (nocPageData, bool) {
	a.noc.cacheMu.Lock()
	defer a.noc.cacheMu.Unlock()
	if a.noc.cached == nil {
		return nocPageData{}, false
	}
	if time.Since(a.noc.cachedAt) > nocCacheTTL {
		return nocPageData{}, false
	}
	return *a.noc.cached, true
}

// setCachedNOC stores a freshly assembled page snapshot with the current
// wall clock. Subsequent requests within nocCacheTTL skip the fan-out.
func (a *app) setCachedNOC(data nocPageData) {
	a.noc.cacheMu.Lock()
	defer a.noc.cacheMu.Unlock()
	cp := data
	a.noc.cached = &cp
	a.noc.cachedAt = time.Now()
}

// close releases the long-lived API clients. Called from app.Close at
// process shutdown; errors are logged but not surfaced because nothing
// downstream can act on them.
func (s *nocState) close() {
	if s == nil {
		return
	}
	s.clientMu.Lock()
	defer s.clientMu.Unlock()
	if s.logClient != nil {
		if err := s.logClient.Close(); err != nil {
			log.Printf("noc: logadmin close: %v", err)
		}
		s.logClient = nil
	}
	if s.monClient != nil {
		if err := s.monClient.Close(); err != nil {
			log.Printf("noc: monitoring close: %v", err)
		}
		s.monClient = nil
	}
}

// handleNOCDashboard renders the live NOC dashboard at /wiki/noc.
//
// The handler fans out four independent API calls in parallel:
//
//   - one Cloud Logging scan of the last 24h Cloud Armor DENY events,
//     which feeds the counts tile, top-IPs tile, top-URLs tile, and
//     top-priorities tile (one scan, four aggregations);
//   - one Cloud Logging scan of the last 1h DENY events for the 1h counter;
//   - one Cloud Monitoring call for the 9 alert policy states;
//   - one Cloud Logging scan of the last 24h honeypot tripwire hits
//     (jsonPayload.tripwire=true on the public Cloud Run service).
//
// Each call has an independent failure mode and an independent fallback;
// the page always renders even when every external call fails.
func (a *app) handleNOCDashboard(w http.ResponseWriter, r *http.Request) {
	// Cache check is the first move: if a recent snapshot is still warm,
	// we skip the fan-out entirely and only overlay the per-request fields.
	// This is what closes the auto-refresh flip-flop bug — a single slow
	// API call no longer makes the next refresh render "unavailable" tiles,
	// because the prior good snapshot stays renderable until the TTL expires.
	data, hit := a.getCachedNOC()
	if !hit {
		data = a.fetchNOCData(r.Context())
		a.setCachedNOC(data)
	}

	// Per-request overlay. User is IAP-asserted and cannot be cached;
	// Title and RefreshSecs are static but live in fetchNOCData for
	// snapshot completeness, so they survive the cache hit unchanged.
	data.User = iapUser(r)

	a.render(w, "noc_dashboard.html", data)
}

// fetchNOCData runs the four-call fan-out, assembles a nocPageData
// snapshot, and returns it. The snapshot is cacheable in its entirety
// because every field (including AsOf — which records when the FETCH
// happened, not when the request rendered) is fetch-time, not request-time.
//
// Each goroutine acquires the shared client at goroutine start and treats
// a client-acquisition failure identically to a query failure: the per-tile
// fallback state renders and the page never 500s. Errors that reach the
// fallback path are also surfaced to stderr via log.Printf so operators
// can read Cloud Run logs to diagnose a persistent "unavailable" state
// instead of guessing (closes F-004).
func (a *app) fetchNOCData(ctx context.Context) nocPageData {
	proj := nocProjectID()
	now := time.Now().UTC()

	data := nocPageData{
		Title:       "Defense Command · Live",
		Project:     proj,
		AsOf:        now.Format("2006-01-02 15:04:05 UTC"),
		RefreshSecs: 30,
	}

	// Four goroutines fan out in parallel. Each writes only to its own
	// pre-declared local variables; the snapshot is assembled after
	// wg.Wait() to keep concurrent access to data fields out of the
	// picture. Each fanout call wraps the parent context in a
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

		// Tripwire (honeypot) tile output.
		tripErr     error
		tripTotal   int64
		tripPathMap map[string]int64
	)
	wg.Add(4)

	go func() {
		defer wg.Done()
		// The 24h scan feeds three tiles at once (top IPs, top URLs, top
		// priorities) and also the 24h half of the counts tile.
		callCtx, cancel := context.WithTimeout(ctx, nocAPITimeout)
		defer cancel()
		client, err := a.nocLogClient(callCtx)
		if err != nil {
			scan24Err = fmt.Errorf("logadmin client: %w", err)
			return
		}
		count24h, ipsMap, urlsMap, priorsMap, scan24Err = scan24h(callCtx, client, now)
	}()

	go func() {
		defer wg.Done()
		callCtx, cancel := context.WithTimeout(ctx, nocAPITimeout)
		defer cancel()
		client, err := a.nocLogClient(callCtx)
		if err != nil {
			scan1hErr = fmt.Errorf("logadmin client: %w", err)
			return
		}
		count1h, scan1hErr = scan1hCount(callCtx, client, now)
	}()

	go func() {
		defer wg.Done()
		callCtx, cancel := context.WithTimeout(ctx, nocAPITimeout)
		defer cancel()
		client, err := a.nocMonClient(callCtx)
		if err != nil {
			alertErr = fmt.Errorf("alert policy client: %w", err)
			return
		}
		alertTile, alertErr = fetchAlertTile(callCtx, client, proj)
	}()

	go func() {
		defer wg.Done()
		callCtx, cancel := context.WithTimeout(ctx, nocAPITimeout)
		defer cancel()
		client, err := a.nocLogClient(callCtx)
		if err != nil {
			tripErr = fmt.Errorf("logadmin client: %w", err)
			return
		}
		tripTotal, tripPathMap, tripErr = scanTripwire(callCtx, client, now, nocTripwireServiceName())
	}()

	wg.Wait()

	// 24h tiles (counts/24h half, top IPs, top URLs, top priorities).
	if scan24Err != nil {
		log.Printf("noc dashboard: 24h scan: %v", scan24Err)
		msg := "Cloud Logging unavailable — retry on next refresh"
		data.Counts.Error = msg
		data.TopIPs = nocTopTile{Available: false, Error: msg}
		data.TopURLs = nocTopTile{Available: false, Error: msg}
		data.TopPriors = nocTopTile{Available: false, Error: msg}
	} else {
		data.Counts.Last24h = count24h
		data.Counts.Last24hAvailable = true
		data.Counts.Available = true
		data.TopIPs = topTile(ipsMap, 5)
		data.TopURLs = topTile(urlsMap, 5)
		data.TopPriors = topTile(priorsMap, 5)
	}

	// 1h half of the counts tile is independent: it can succeed when the
	// 24h scan failed (or vice versa). Per-side Available flags let the
	// template render "—" for the failed half rather than a misleading
	// "0" (closes F-001). The tile-level Available stays true whenever
	// either side has data, so the tile shell remains visible during a
	// partial outage.
	if scan1hErr != nil {
		log.Printf("noc dashboard: 1h scan: %v", scan1hErr)
		if data.Counts.Error == "" {
			data.Counts.Error = "1h window unavailable"
		}
	} else {
		data.Counts.Last1h = count1h
		data.Counts.Last1hAvailable = true
		data.Counts.Available = true
	}

	// Alert tile.
	if alertErr != nil {
		log.Printf("noc dashboard: alert policies: %v", alertErr)
		data.Alerts = nocAlertTile{Available: false, Error: "Monitoring API unavailable — alert state cannot be read"}
	} else {
		data.Alerts = alertTile
	}

	// Tripwire tile. Reuses topTile() for the rows so the rendering shape
	// matches the other top-N tiles; Total is preserved separately because
	// the headline number is "X attackers tripped a wire" — the rows are
	// the supporting breakdown.
	if tripErr != nil {
		log.Printf("noc dashboard: tripwire scan: %v", tripErr)
		data.Tripwire = nocTripwireTile{Available: false, Error: "Cloud Logging unavailable — retry on next refresh"}
	} else {
		top := topTile(tripPathMap, 3)
		data.Tripwire = nocTripwireTile{
			Total:     tripTotal,
			Rows:      top.Rows,
			Available: true,
			Empty:     tripTotal == 0,
		}
	}

	return data
}

// scanTripwire pulls every honeypot hit in the last 24h and returns the
// total count plus a frequency map keyed by path. The shape mirrors
// scan24h: same nocEntryCap cap, same NewestFirst ordering, same
// best-effort error semantics (the tile renders an "unavailable" state
// on failure; the page does not 500).
//
// The Cloud Logging payload for a tripwire entry is the slog JSON output
// (see honeypot.go logTripwire). logadmin unwraps that into a
// map[string]any in entry.Payload — we read the `path` field defensively
// and skip any malformed entry.
func scanTripwire(ctx context.Context, client *logadmin.Client, now time.Time, serviceName string) (int64, map[string]int64, error) {
	since := now.Add(-24 * time.Hour)
	// client is process-shared (see nocState.logClient) — DO NOT Close here.

	it := client.Entries(ctx,
		logadmin.Filter(nocTripwireFilter(since, serviceName)),
		logadmin.PageSize(nocEntryCap),
		logadmin.NewestFirst(),
	)

	paths := map[string]int64{}
	var n int64
	for n < nocEntryCap {
		e, err := it.Next()
		if errors.Is(err, iterator.Done) {
			break
		}
		if err != nil {
			return 0, nil, fmt.Errorf("entries.Next: %w", err)
		}
		n++
		if p := extractTripwirePath(e.Payload); p != "" {
			paths[p]++
		}
	}
	return n, paths, nil
}

// extractTripwirePath pulls the `path` field from a tripwire log entry
// payload. logadmin unmarshalls jsonPayload into map[string]any; we walk
// the top-level key defensively and return "" on any miss so a single
// malformed entry cannot poison the aggregation.
func extractTripwirePath(payload any) string {
	m, ok := payload.(map[string]any)
	if !ok {
		return ""
	}
	if s, ok := m["path"].(string); ok {
		return s
	}
	return ""
}

// scan24h pulls every Cloud Armor DENY event in the last 24h and returns
// the total count plus three frequency maps the caller turns into top-N
// tiles. PageSize is capped at nocEntryCap; if the actual 24h volume is
// higher than the cap (very loud day), the aggregations are accurate
// within the sampled window.
func scan24h(ctx context.Context, client *logadmin.Client, now time.Time) (int64, map[string]int64, map[string]int64, map[string]int64, error) {
	since := now.Add(-24 * time.Hour)
	// client is process-shared (see nocState.logClient) — DO NOT Close here.

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
func scan1hCount(ctx context.Context, client *logadmin.Client, now time.Time) (int64, error) {
	since := now.Add(-1 * time.Hour)
	// client is process-shared (see nocState.logClient) — DO NOT Close here.

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
func fetchAlertTile(ctx context.Context, client *monitoring.AlertPolicyClient, projectID string) (nocAlertTile, error) {
	// client is process-shared (see nocState.monClient) — DO NOT Close here.
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
