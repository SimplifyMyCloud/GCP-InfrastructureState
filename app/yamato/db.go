package main

import (
	"context"
	"fmt"
	"net"
	"os"
	"strings"
	"time"

	"cloud.google.com/go/cloudsqlconn"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// store wraps the Cloud SQL connection pool and the article queries.
type store struct {
	pool   *pgxpool.Pool
	dialer *cloudsqlconn.Dialer
}

// newStore opens the pool, applies the embedded schema + seed, and returns a
// ready store. The Cloud SQL instance is private-IP only, so connections are
// dialed through the Cloud SQL Go connector with the private-IP option rather
// than over a public address. The runtime service account's roles/cloudsql.client
// grant is what authorizes the dialer.
func newStore(ctx context.Context, schema string) (*store, error) {
	instance := os.Getenv("INSTANCE_CONNECTION_NAME")
	dbName := os.Getenv("DB_NAME")
	dbUser := os.Getenv("DB_USER")
	dbPass := os.Getenv("DB_PASS")
	if instance == "" || dbName == "" || dbUser == "" {
		return nil, fmt.Errorf("missing required DB env (INSTANCE_CONNECTION_NAME, DB_NAME, DB_USER)")
	}

	dialer, err := cloudsqlconn.NewDialer(ctx, cloudsqlconn.WithDefaultDialOptions(cloudsqlconn.WithPrivateIP()))
	if err != nil {
		return nil, fmt.Errorf("cloud sql dialer: %w", err)
	}

	// The connector terminates TLS to the instance itself, so pgx-level TLS is
	// disabled; host/port in the DSN are placeholders the DialFunc ignores.
	dsn := fmt.Sprintf("user=%s password=%s dbname=%s sslmode=disable", dbUser, dbPass, dbName)
	cfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		dialer.Close()
		return nil, fmt.Errorf("parse pool config: %w", err)
	}
	cfg.ConnConfig.DialFunc = func(ctx context.Context, _, _ string) (net.Conn, error) {
		return dialer.Dial(ctx, instance)
	}

	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	if err != nil {
		dialer.Close()
		return nil, fmt.Errorf("create pool: %w", err)
	}

	pingCtx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		dialer.Close()
		return nil, fmt.Errorf("ping db: %w", err)
	}

	if _, err := pool.Exec(ctx, schema); err != nil {
		pool.Close()
		dialer.Close()
		return nil, fmt.Errorf("apply schema: %w", err)
	}

	return &store{pool: pool, dialer: dialer}, nil
}

func (s *store) Close() {
	if s.pool != nil {
		s.pool.Close()
	}
	if s.dialer != nil {
		_ = s.dialer.Close()
	}
}

func (s *store) ping(ctx context.Context) error {
	return s.pool.Ping(ctx)
}

// article is one wiki entry. Body is the raw stored text; Paragraphs is the body
// split for templated rendering (each element auto-escaped by html/template).
type article struct {
	Slug      string
	Title     string
	Category  string
	Body      string
	UpdatedAt time.Time
}

func (a article) Updated() string { return a.UpdatedAt.Format("2006-01-02") }

func (a article) Paragraphs() []string {
	parts := strings.Split(strings.TrimSpace(a.Body), "\n\n")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		if p = strings.TrimSpace(p); p != "" {
			out = append(out, p)
		}
	}
	return out
}

// categoryGroup is a category and the articles filed under it, for the index.
type categoryGroup struct {
	Category string
	Articles []article
}

// listGrouped returns all articles grouped by category, both the groups and the
// articles within them ordered alphabetically.
func (s *store) listGrouped(ctx context.Context) ([]categoryGroup, error) {
	rows, err := s.pool.Query(ctx,
		`SELECT slug, title, category, updated_at FROM articles ORDER BY category, title`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var groups []categoryGroup
	for rows.Next() {
		var a article
		if err := rows.Scan(&a.Slug, &a.Title, &a.Category, &a.UpdatedAt); err != nil {
			return nil, err
		}
		if n := len(groups); n > 0 && groups[n-1].Category == a.Category {
			groups[n-1].Articles = append(groups[n-1].Articles, a)
		} else {
			groups = append(groups, categoryGroup{Category: a.Category, Articles: []article{a}})
		}
	}
	return groups, rows.Err()
}

// get returns one article by slug, or pgx.ErrNoRows if it doesn't exist.
func (s *store) get(ctx context.Context, slug string) (article, error) {
	var a article
	err := s.pool.QueryRow(ctx,
		`SELECT slug, title, category, body, updated_at FROM articles WHERE slug = $1`, slug).
		Scan(&a.Slug, &a.Title, &a.Category, &a.Body, &a.UpdatedAt)
	return a, err
}

// errNoRows is re-exported so handlers don't import pgx directly.
var errNoRows = pgx.ErrNoRows
