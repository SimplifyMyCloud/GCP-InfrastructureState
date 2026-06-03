package main

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"os"
	"strings"
	"sync"
)

// Honeypot tripwires — Layer 0 lure on the PUBLIC Cloud Run service.
//
// Cloud Armor (Layer 1) blocks the ~345 probes/day matching OWASP WAF
// signatures, but its DENY logs only carry the matched rule ID — no
// per-attacker UA strings, no request bodies, no full payloads. These
// routes fill the telemetry gap by accepting a small menu of well-known
// attacker paths (the ones bots probe by default), returning a small
// believable fake 200, and emitting ONE structured Cloud Logging entry
// per hit with the rich attacker context the NOC tripwire tile renders.
//
// IMPORTANT contract:
//   - These routes MUST live on the public Cloud Run service mux ONLY
//     (the LB routes /wiki/* to the IAP-gated service, so registering
//     these here keeps them OUTSIDE the IAP perimeter — exactly what we
//     want, since IAP would 302 the attacker before they ever hit a
//     tripwire). See app.go routes() for the mux registration.
//   - The fake response content MUST NOT contain any real value: no real
//     project ID, SA email, IP, hostname, key, or path. Placeholders use
//     obvious sentinels ("FAKE", "HONEY", "host.example", "iq9-fake-honey")
//     so a future operator pasting any value into a real GCP console gets
//     a clean miss.
//   - The log line carries the REQUEST (path, method, IP, UA, first 1KB
//     of body). It MUST NOT carry the RESPONSE (we are tracking what the
//     attacker tried, not what we lied about).

// honeypotBodyCap caps how much of the request body we capture. 1 KiB is
// large enough to fingerprint the payload family (sqlmap POST, log4j JNDI
// string, command-injection one-liner) without bloating Cloud Logging
// entry size.
const honeypotBodyCap = 1024

// tripwireLogger is a slog.JSONHandler wired to stderr. Cloud Run picks
// up structured JSON on stderr and surfaces every top-level field under
// jsonPayload in Cloud Logging — which is exactly what the NOC tile
// filters on (jsonPayload.tripwire=true).
//
// The handler is built once and reused for every honeypot hit; slog
// handlers are safe for concurrent use.
var tripwireLogger = func() *slog.Logger {
	h := slog.NewJSONHandler(os.Stderr, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	})
	return slog.New(h)
}()

// clientIP returns the attacker's IP. On Cloud Run behind a Google
// HTTP(S) load balancer, r.RemoteAddr is the LB's edge proxy — the real
// client lives in the first comma-separated entry of X-Forwarded-For,
// which the LB rewrites to put the verified client first (so the value
// is trustworthy in production even though XFF is attacker-controllable
// upstream of the LB). Falls back to r.RemoteAddr for local runs.
func clientIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		if i := strings.IndexByte(xff, ','); i >= 0 {
			return strings.TrimSpace(xff[:i])
		}
		return strings.TrimSpace(xff)
	}
	return r.RemoteAddr
}

// logTripwire emits the single structured log entry for one honeypot
// hit. The shape is the contract the NOC tile depends on:
//
//	{ "severity":"NOTICE", "tripwire":true, "path":"/admin",
//	  "method":"GET", "remote_ip":"...", "user_agent":"...",
//	  "body_truncated":"..." }
//
// Cloud Logging surfaces every top-level JSON field on stderr under
// jsonPayload, so `jsonPayload.tripwire=true` matches every entry this
// function emits and nothing else.
func logTripwire(r *http.Request) {
	body := ""
	if r.Body != nil {
		// LimitReader caps the read at honeypotBodyCap+1 so we can tell
		// whether the body was actually truncated, but we never keep more
		// than honeypotBodyCap bytes in memory.
		b, _ := io.ReadAll(io.LimitReader(r.Body, honeypotBodyCap))
		body = string(b)
		_ = r.Body.Close()
	}

	// slog.JSONHandler emits its own `time`, `level`, and `msg` keys; we
	// add `severity` explicitly so Cloud Logging's structured-payload
	// mapping picks it up as the entry severity (it ignores slog's
	// LevelInfo→INFO mapping when an explicit severity field is present).
	tripwireLogger.LogAttrs(r.Context(), slog.LevelInfo, "honeypot tripwire",
		slog.String("severity", "NOTICE"),
		slog.Bool("tripwire", true),
		slog.String("path", r.URL.Path),
		slog.String("method", r.Method),
		slog.String("remote_ip", clientIP(r)),
		slog.String("user_agent", r.UserAgent()),
		slog.String("body_truncated", body),
	)
}

// honeypotResponse is the menu of believable fake 200s, keyed by path.
// Each entry is small (<2 KB) and uses OBVIOUSLY FAKE values so a future
// operator (or pen-tester) pasting anything into a real GCP console
// immediately sees the bait.
type honeypotResponse struct {
	ContentType string
	Body        string
}

// honeypotResponses is initialised at startup. Paths here MUST match the
// routes registered in app.go routes(); see also handleHoneypot below.
var honeypotResponses = map[string]honeypotResponse{
	"/admin": {
		ContentType: "text/html; charset=utf-8",
		Body: `<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Admin · Internal Tools</title></head>
<body style="font-family:sans-serif;max-width:380px;margin:6rem auto;">
<h1 style="font-size:1.2rem;">Admin Login</h1>
<form method="post" action="/admin/login">
  <label>Username <input name="u" autocomplete="off"></label><br><br>
  <label>Password <input name="p" type="password" autocomplete="off"></label><br><br>
  <button type="submit">Sign in</button>
</form>
<p style="color:#888;font-size:0.8rem;">build host.example · v0.0.0-FAKE-HONEY</p>
</body></html>`,
	},
	"/backup.sql": {
		ContentType: "text/plain; charset=utf-8",
		Body: `-- MySQL dump 10.13  Distrib FAKE, for Linux (x86_64)
-- Host: host.example    Database: iq9-fake-honey
-- ------------------------------------------------------
-- Server version       0.0.0-FAKE-HONEY

DROP TABLE IF EXISTS ` + "`users`" + `;
CREATE TABLE ` + "`users`" + ` (
  ` + "`id`" + ` int(11) NOT NULL AUTO_INCREMENT,
  ` + "`email`" + ` varchar(255) NOT NULL,
  ` + "`api_key`" + ` varchar(64) DEFAULT NULL,
  PRIMARY KEY (` + "`id`" + `)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO ` + "`users`" + ` VALUES
  (1,'fake-user-1@host.example','AKIA0000000FAKEHONEY1'),
  (2,'fake-user-2@host.example','AKIA0000000FAKEHONEY2');
-- Dump completed
`,
	},
	"/api/v1/users": {
		ContentType: "application/json; charset=utf-8",
		Body: `{"users":[` +
			`{"id":1,"username":"fake-user-1","email":"fake-user-1@host.example","role":"admin","api_key":"AKIA0000000FAKEHONEY1"},` +
			`{"id":2,"username":"fake-user-2","email":"fake-user-2@host.example","role":"viewer","api_key":"AKIA0000000FAKEHONEY2"}` +
			`],"count":2,"next":null}`,
	},
	"/server-status": {
		ContentType: "text/plain; charset=utf-8",
		Body: `Apache Server Status for host.example (via 0.0.0.0)
Server Version: Apache/0.0.0 (FAKE-HONEY)
Server MPM: event
Server Built: Jan  1 1970 00:00:00
-----------------------------------------------
Current Time: Thu, 01 Jan 1970 00:00:00 GMT
Restart Time: Thu, 01 Jan 1970 00:00:00 GMT
Parent Server Config. Generation: 1
Parent Server MPM Generation: 0
Server uptime: 0 minutes
Server load: 0.00 0.00 0.00
Total accesses: 0 - Total Traffic: 0 kB - Total Duration: 0
CPU Usage: u0 s0 cu0 cs0
0 requests/sec - 0 B/second
1 requests currently being processed, 0 idle workers

Scoreboard Key:
"_" Waiting for Connection, "S" Starting up, "R" Reading Request,
"W" Sending Reply, "K" Keepalive (read), "D" DNS Lookup,
"C" Closing connection, "L" Logging, "G" Gracefully finishing,
"I" Idle cleanup of worker, "." Open slot with no current process
`,
	},
	"/phpmyadmin": {
		ContentType: "text/html; charset=utf-8",
		Body: `<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>phpMyAdmin</title></head>
<body style="font-family:Verdana,sans-serif;max-width:420px;margin:5rem auto;background:#f5f5f5;padding:1.5rem;border:1px solid #ccc;">
<h1 style="font-size:1.1rem;color:#235a81;">Welcome to phpMyAdmin</h1>
<form method="post" action="index.php">
  <label>Username: <input name="pma_username" autocomplete="off"></label><br><br>
  <label>Password: <input name="pma_password" type="password" autocomplete="off"></label><br><br>
  <label>Server: <input name="pma_servername" value="host.example" readonly></label><br><br>
  <button type="submit">Go</button>
</form>
<p style="color:#888;font-size:0.75rem;">phpMyAdmin 0.0.0-FAKE-HONEY</p>
</body></html>`,
	},
	"/console": {
		ContentType: "text/html; charset=utf-8",
		Body: `<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Console</title></head>
<body style="font-family:monospace;background:#111;color:#0f0;max-width:560px;margin:4rem auto;padding:1.5rem;border:1px solid #0f0;">
<h1 style="font-size:1rem;">Management Console</h1>
<p>host.example · build FAKE-HONEY</p>
<form method="post" action="/console/auth">
  <label>User: <input name="user" style="background:#000;color:#0f0;border:1px solid #0f0;" autocomplete="off"></label><br><br>
  <label>Token: <input name="token" type="password" style="background:#000;color:#0f0;border:1px solid #0f0;" autocomplete="off"></label><br><br>
  <button type="submit" style="background:#0f0;color:#000;border:0;padding:0.3rem 0.8rem;">Authenticate</button>
</form>
</body></html>`,
	},
}

// honeypotResponseCache is a parallel map of paths to JSON-pre-serialised
// fake responses. It's only used when handleHoneypot wants to confirm
// the content map matches the registered routes; the once.Do prevents
// silent drift between honeypotResponses and the route table in app.go.
var honeypotPathSet = func() map[string]struct{} {
	s := make(map[string]struct{}, len(honeypotResponses))
	for k := range honeypotResponses {
		s[k] = struct{}{}
	}
	return s
}()

var honeypotInitOnce sync.Once

// handleHoneypot is the single shared handler for all 6 tripwire routes.
// The path the attacker hit is read from r.URL.Path (the mux registered
// each path as a literal, so r.URL.Path matches the registration key
// exactly). One log line per hit, one canned fake 200 in return.
//
// All HTTP methods are accepted — bots try unusual verbs to fingerprint
// deployed software (HEAD, PROPFIND, etc.), and we want the data on all
// of them. The mux registers without a method prefix to enable this.
func (a *app) handleHoneypot(w http.ResponseWriter, r *http.Request) {
	// Guard rail: the honeypotResponses map is the single source of truth
	// for "is this a real honeypot path or did somebody misregister a
	// route". If the path is unknown, fall through to 404 — never serve
	// a generic fake for an unmapped path.
	resp, ok := honeypotResponses[r.URL.Path]
	if !ok {
		http.NotFound(w, r)
		return
	}

	// Log BEFORE responding so a slow client disconnect (or a panic on
	// the response side, which we don't expect with a string write) does
	// not silently drop the tripwire entry.
	logTripwire(r)

	w.Header().Set("Content-Type", resp.ContentType)
	w.Header().Set("Cache-Control", "no-store")
	// Server-side fingerprint that looks plausible but matches no real
	// running software — completes the illusion without leaking any real
	// runtime detail (no Go version, no Cloud Run revision).
	w.Header().Set("Server", "fake-honey/0.0")
	w.WriteHeader(http.StatusOK)
	_, _ = io.WriteString(w, resp.Body)
}

// honeypotPaths returns the registered tripwire paths in a stable order.
// Used by app.go routes() to register the mux handlers and (in tests, if
// any are added later) to enumerate the surface. Kept here so the route
// list and the response map cannot drift apart.
func honeypotPaths() []string {
	// Ordering chosen to group conceptually (admin UIs first, data dumps,
	// API surface, server-status, then alt admin UIs). Mux registration
	// order does not affect routing for literal paths under Go 1.22+
	// ServeMux, but a stable order makes startup logs easier to grep.
	return []string{
		"/admin",
		"/backup.sql",
		"/api/v1/users",
		"/server-status",
		"/phpmyadmin",
		"/console",
	}
}

// init asserts that honeypotPaths() and honeypotResponses are in sync at
// startup, so a future maintainer adding a path to one and not the other
// gets an immediate hard failure instead of a 404 in production.
func init() {
	honeypotInitOnce.Do(func() {
		for _, p := range honeypotPaths() {
			if _, ok := honeypotResponses[p]; !ok {
				panic("honeypot route " + p + " has no canned response")
			}
		}
		// Sanity-check the response size budget (<2 KB per the brief).
		for p, r := range honeypotResponses {
			if len(r.Body) > 2048 {
				panic("honeypot response for " + p + " exceeds 2 KB budget")
			}
		}
		// Confirm the response map round-trips through JSON for any
		// path whose response is itself JSON. A typo in a JSON literal
		// would otherwise only surface when an attacker hit the route.
		for p, r := range honeypotResponses {
			if strings.HasPrefix(r.ContentType, "application/json") {
				var v any
				if err := json.Unmarshal([]byte(r.Body), &v); err != nil {
					panic("honeypot JSON response invalid for " + p + ": " + err.Error())
				}
			}
		}
	})
}
