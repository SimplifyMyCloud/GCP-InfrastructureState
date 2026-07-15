package main

import (
	"context"
	"embed"
	"html/template"
	"io/fs"
	"net/http"
	"path"
	"strings"
)

//go:embed templates/*.html
var templateFS embed.FS

//go:embed static
var staticFS embed.FS

//go:embed schema.sql
var schemaSQL string

// app holds the process-wide dependencies: the database pool, parsed
// templates, and the NOC dashboard's shared API clients + tile cache.
// One instance is built at startup and shared across requests.
type app struct {
	db   *store
	tmpl *template.Template
	noc  *nocState // see noc_dashboard.go — shared logadmin/monitoring clients + tile cache
}

func newApp(ctx context.Context) (*app, error) {
	db, err := newStore(ctx, schemaSQL)
	if err != nil {
		return nil, err
	}

	tmpl, err := template.ParseFS(templateFS, "templates/*.html")
	if err != nil {
		db.Close()
		return nil, err
	}

	return &app{db: db, tmpl: tmpl, noc: &nocState{}}, nil
}

func (a *app) Close() {
	if a.db != nil {
		a.db.Close()
	}
	if a.noc != nil {
		a.noc.close()
	}
}

func (a *app) routes() http.Handler {
	mux := http.NewServeMux()

	// --- Public surface (outside /wiki — NOT covered by IAP) ---
	mux.HandleFunc("GET /{$}", a.handleLanding)
	mux.HandleFunc("GET /healthz", a.handleHealth)

	staticRoot, _ := fs.Sub(staticFS, "static")
	mux.Handle("GET /static/", staticHandler(staticRoot))

	// --- Honeypot tripwires (PUBLIC service ONLY — must stay outside /wiki) ---
	// Each path returns a small, believable fake 200 and emits one structured
	// log entry (jsonPayload.tripwire=true). The NOC tile at /wiki/noc reads
	// those entries back. Registered without a method prefix so we capture
	// GET, POST, HEAD, and the unusual verbs bots use to fingerprint software.
	// See honeypot.go for the contract; honeypotPaths() is the source of truth.
	for _, p := range honeypotPaths() {
		mux.HandleFunc(p, a.handleHoneypot)
	}

	// --- Protected surface (the LB routes /wiki and /wiki/* to the IAP backend) ---
	// Both "/wiki" and "/wiki/" land on the index; "/wiki/{slug}" is an article.
	// /wiki/noc is the live defense-command dashboard — pulled from Cloud Logging
	// + Cloud Monitoring at request time and IAP-gated by the LB's /wiki/* path
	// rule (no separate auth wiring; it lives under /wiki for exactly this reason).
	mux.HandleFunc("GET /wiki", a.handleWikiIndex)
	mux.HandleFunc("GET /wiki/{$}", a.handleWikiIndex)
	mux.HandleFunc("GET /wiki/search", a.handleSearch)
	mux.HandleFunc("GET /wiki/noc", a.handleNOCDashboard)
	mux.HandleFunc("GET /wiki/{slug}", a.handleArticle)

	// Internal NOC ("Yamato Defense Command"). The LB routes /noc and /noc/* to the SAME
	// IAP backend as /wiki, so it is private to signed-in identities.
	mux.HandleFunc("GET /noc", a.handleNOC)
	mux.HandleFunc("GET /noc/{$}", a.handleNOC)

	return mux
}

// allowedImageExts is the whitelist of file extensions served under /static/img/.
// The article template hardcodes `.jpg` and the maintainer rules in
// static/img/README.md call for raster portraits only, so the directory should
// never serve HTML, JS, or SVG (SVG can carry <script> that runs when referenced
// outside an <img> tag — see docs/image-security.md F-2). Anything outside this
// list under /static/img/ is rejected with 404 before the FileServer sees it.
// Adjust here if a new portrait format is ever introduced.
var allowedImageExts = map[string]bool{
	".jpg":  true,
	".jpeg": true,
	".png":  true,
	".webp": true,
	".gif":  true,
}

// staticHandler wraps http.FileServerFS with two security headers and one path
// check, applied to every /static/* response:
//
//   - X-Content-Type-Options: nosniff — defeats MIME-sniffing on polyglot files
//     (closes F-1 in docs/image-security.md). The static FS infers Content-Type
//     from the extension; nosniff makes that the only signal a browser uses.
//   - Cache-Control: public, max-age=300 — every container rebuild invalidates
//     the embedded asset set, so a five-minute window is safe and cheap.
//   - Under /static/img/, only the extensions in allowedImageExts are served;
//     anything else 404s (closes F-2). Subdirectory listings (paths ending in
//     "/") are passed through unchanged so FileServer can return its own 404.
func staticHandler(root fs.FS) http.Handler {
	fileServer := http.StripPrefix("/static/", http.FileServerFS(root))
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("Cache-Control", "public, max-age=300")

		// Extension whitelist for the image namespace only. Other prefixes
		// (e.g. /static/style.css) keep their existing behaviour.
		if strings.HasPrefix(r.URL.Path, "/static/img/") && !strings.HasSuffix(r.URL.Path, "/") {
			ext := strings.ToLower(path.Ext(r.URL.Path))
			if ext == "" || !allowedImageExts[ext] {
				http.NotFound(w, r)
				return
			}
		}

		fileServer.ServeHTTP(w, r)
	})
}
