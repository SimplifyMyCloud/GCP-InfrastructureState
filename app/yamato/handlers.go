package main

import (
	"errors"
	"log"
	"net/http"
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
