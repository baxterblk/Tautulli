# Build stage
FROM python:3.9-slim as builder

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Final stage
FROM python:3.9-slim

# Add labels
LABEL maintainer="Tautulli"
LABEL description="A Python based monitoring and tracking tool for Plex Media Server"
LABEL version="1.0"

# Set working directory
WORKDIR /app

# Copy Python packages from builder
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

# Copy application code
COPY . .

# Create volume mount points
VOLUME ["/config", "/logs"]

# Expose default Tautulli port
EXPOSE 8181

# Set environment variables
ENV TAUTULLI_DOCKER="True" \
    TAUTULLI_CONFIG_DIR="/config" \
    TAUTULLI_LOG_DIR="/logs"

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8181/status || exit 1

# Set entry point
CMD ["python", "Tautulli.py", "--nolaunch", "--config", "/config/config.ini", "--datadir", "/config"]
