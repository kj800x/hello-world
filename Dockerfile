# Builder stage
FROM rust:1.91-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /usr/src/hello-world

# Copy manifest files first for better caching
COPY Cargo.toml Cargo.lock ./

# Create a dummy main.rs to build dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build dependencies only (this layer will be cached if Cargo.toml doesn't change)
RUN cargo build --release

# Remove the dummy main.rs and copy the real source code
RUN rm src/main.rs
COPY src/ ./src/

# Build the actual application
RUN cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user for security
RUN groupadd -r hello-world && useradd -r -g hello-world hello-world

# Set working directory
WORKDIR /app

# Copy the binary from builder stage
COPY --from=builder /usr/src/hello-world/target/release/hello-world /usr/bin/hello-world

# Change ownership to the non-root user
RUN chown hello-world:hello-world /usr/bin/hello-world

# Switch to non-root user
USER hello-world

# Expose port
EXPOSE 8080

# Run the binary
CMD ["/usr/bin/hello-world"]
