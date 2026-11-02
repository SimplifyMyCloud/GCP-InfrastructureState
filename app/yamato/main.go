// Command yamato is the Star Blazers wiki web app.
//
// It serves two surfaces from one process, matching the front-door contract
// enforced by the load balancer (service/yamato/dev/frontdoor):
//
//   - public content OUTSIDE /wiki (landing page, static theme assets) — the LB
//     routes these to the un-gated backend.
//   - protected content under /wiki — the LB routes these to the IAP backend, so
//     only @iq9.io identities reach the handlers.
//
// The app never enforces identity itself; IAP at the LB does. Under /wiki the
// app reads the IAP-asserted identity from the X-Goog-Authenticated-User-Email
// header purely to greet the signed-in user.
package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	log.SetFlags(log.LstdFlags | log.LUTC)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	app, err := newApp(ctx)
	if err != nil {
		log.Fatalf("startup: %v", err)
	}
	defer app.Close()

	port := getenv("PORT", "8080")
	srv := &http.Server{
		Addr:              ":" + port,
		Handler:           app.routes(),
		ReadHeaderTimeout: 10 * time.Second,
	}

	go func() {
		log.Printf("yamato listening on :%s", port)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatalf("serve: %v", err)
		}
	}()

	<-ctx.Done()
	log.Print("shutdown signal received")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Printf("graceful shutdown: %v", err)
	}
}

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
