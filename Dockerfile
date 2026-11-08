
# Stage 1: Build the Go application
FROM golang:1.25.1-alpine AS builder

WORKDIR /app

# Copy Go dependency files
COPY app/go.mod app/go.sum ./

# Download dependencies
RUN go mod download

# Copy application source code
COPY app/ .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o /app/muchtodo ./cmd/api

# Stage 2: Create a lightweight runtime image
FROM alpine:3.22

WORKDIR /app

# Install certificates for secure connections
RUN apk add --no-cache ca-certificates

# Copy the compiled application
COPY --from=builder /app/muchtodo .

RUN adduser -D -H appuser
USER appuser

# Application port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:8080/health || exit 1

# Start the application
CMD ["./muchtodo"]