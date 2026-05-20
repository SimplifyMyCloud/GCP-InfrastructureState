# syntax=docker/dockerfile:1

# --- build stage ---------------------------------------------------------------
FROM golang:1.26 AS build
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
# Pure-Go build (pgx + cloudsqlconn need no cgo), static so it runs on distroless.
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /yamato .

# --- runtime stage -------------------------------------------------------------
# distroless/static ships ca-certificates (needed for the Cloud SQL connector's
# HTTPS calls) and a nonroot user; nothing else.
FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /yamato /yamato
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/yamato"]
