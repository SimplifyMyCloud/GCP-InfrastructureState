package main

import (
	"context"
	"embed"
	"html/template"
	"io/fs"
	"net/http"
)

//go:embed templates/*.html
var templateFS embed.FS

//go:embed static
var staticFS embed.FS

//go:embed schema.sql
var schemaSQL string

// app holds the process-wide dependencies: the database pool and parsed
// templates. One instance is built at startup and shared across requests.
type app struct {
	db   *store
	tmpl *template.Template
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

	return &app{db: db, tmpl: tmpl}, nil
}

func (a *app) Close() {
	if a.db != nil {
		a.db.Close()
	}
}

func (a *app) routes() http.Handler {
	mux := http.NewServeMux()

	// --- Public surface (outside /wiki — NOT covered by IAP) ---
	mux.HandleFunc("GET /{$}", a.handleLanding)
	mux.HandleFunc("GET /healthz", a.handleHealth)

	staticRoot, _ := fs.Sub(staticFS, "static")
	mux.Handle("GET /static/", http.StripPrefix("/static/", http.FileServerFS(staticRoot)))

	// --- Protected surface (the LB routes /wiki and /wiki/* to the IAP backend) ---
	// Both "/wiki" and "/wiki/" land on the index; "/wiki/{slug}" is an article.
	mux.HandleFunc("GET /wiki", a.handleWikiIndex)
	mux.HandleFunc("GET /wiki/{$}", a.handleWikiIndex)
	mux.HandleFunc("GET /wiki/search", a.handleSearch)
	mux.HandleFunc("GET /wiki/{slug}", a.handleArticle)

	// Internal NOC ("Yamato Defense Command"). The LB routes /noc and /noc/* to the SAME
	// IAP backend as /wiki, so it is private to signed-in identities.
	mux.HandleFunc("GET /noc", a.handleNOC)
	mux.HandleFunc("GET /noc/{$}", a.handleNOC)

	return mux
}
