#!/bin/bash
# =============================================================================
# Cleanup Secrets Script
# Removes temporary secrets directory after Terraform execution
# =============================================================================

set -e

SECRETS_DIR="${SECRETS_DIR:-/tmp/harness-secrets}"

echo "=== Cleaning up secrets directory: $SECRETS_DIR ==="

if [ -d "$SECRETS_DIR" ]; then
    # Securely delete files (overwrite before delete)
    if [ -f "$SECRETS_DIR/gcp-sa-key.json" ]; then
        shred -u "$SECRETS_DIR/gcp-sa-key.json" 2>/dev/null || rm -f "$SECRETS_DIR/gcp-sa-key.json"
    fi

    # Remove any other files
    rm -rf "$SECRETS_DIR"
    echo "✓ Secrets directory removed"
else
    echo "Secrets directory does not exist, nothing to clean"
fi

# Clean up any temporary Terraform files
echo "=== Cleaning up Terraform temporary files ==="
rm -f /tmp/tf-outputs.json 2>/dev/null || true
rm -f /tmp/kafka_api_key.txt 2>/dev/null || true
rm -f /tmp/kafka_api_secret.txt 2>/dev/null || true
rm -f /tmp/gcp_sa_key_base64.txt 2>/dev/null || true

echo "=== Cleanup complete ==="
