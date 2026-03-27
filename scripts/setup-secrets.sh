#!/bin/bash
# =============================================================================
# Setup Secrets Script
# Creates temporary directory and writes secrets for Terraform consumption
# =============================================================================

set -e

SECRETS_DIR="${SECRETS_DIR:-/tmp/harness-secrets}"

echo "=== Setting up secrets directory: $SECRETS_DIR ==="
mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

# -----------------------------------------------------------------------------
# Write GCP credentials if provided
# -----------------------------------------------------------------------------
if [ -n "$GCP_CREDENTIALS_JSON" ]; then
    echo "Writing GCP credentials..."
    echo "$GCP_CREDENTIALS_JSON" > "$SECRETS_DIR/gcp-sa-key.json"
    chmod 600 "$SECRETS_DIR/gcp-sa-key.json"

    # Validate JSON format
    if python3 -c "import json; json.load(open('$SECRETS_DIR/gcp-sa-key.json'))" 2>/dev/null; then
        echo "✓ GCP credentials JSON is valid"
    else
        echo "✗ WARNING: GCP credentials may not be valid JSON"
    fi

    # Set environment variable for Terraform
    export GOOGLE_APPLICATION_CREDENTIALS="$SECRETS_DIR/gcp-sa-key.json"
    echo "export GOOGLE_APPLICATION_CREDENTIALS=$SECRETS_DIR/gcp-sa-key.json"
fi

# -----------------------------------------------------------------------------
# Write GCP credentials (Base64 encoded version)
# -----------------------------------------------------------------------------
if [ -n "$GCP_CREDENTIALS_BASE64" ]; then
    echo "Writing GCP credentials from base64..."
    echo "$GCP_CREDENTIALS_BASE64" | base64 -d > "$SECRETS_DIR/gcp-sa-key.json"
    chmod 600 "$SECRETS_DIR/gcp-sa-key.json"

    export GOOGLE_APPLICATION_CREDENTIALS="$SECRETS_DIR/gcp-sa-key.json"
    echo "export GOOGLE_APPLICATION_CREDENTIALS=$SECRETS_DIR/gcp-sa-key.json"
fi

# -----------------------------------------------------------------------------
# List files created (for debugging)
# -----------------------------------------------------------------------------
echo ""
echo "=== Secrets directory contents ==="
ls -la "$SECRETS_DIR"

echo ""
echo "=== Setup complete ==="
