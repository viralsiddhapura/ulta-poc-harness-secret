#!/bin/bash
# =============================================================================
# Store Terraform Outputs to Harness Secret Manager
# Uses Harness API to create/update secrets from Terraform outputs
# =============================================================================

set -e

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
HARNESS_API_KEY="${HARNESS_API_KEY:?ERROR: HARNESS_API_KEY is required}"
HARNESS_ACCOUNT_ID="${HARNESS_ACCOUNT_ID:?ERROR: HARNESS_ACCOUNT_ID is required}"
HARNESS_ORG_ID="${HARNESS_ORG_ID:?ERROR: HARNESS_ORG_ID is required}"
HARNESS_PROJECT_ID="${HARNESS_PROJECT_ID:?ERROR: HARNESS_PROJECT_ID is required}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

HARNESS_API_URL="https://app.harness.io/ng/api/v2/secrets"

# -----------------------------------------------------------------------------
# Function: Create or Update Secret
# -----------------------------------------------------------------------------
create_or_update_secret() {
    local secret_name="$1"
    local secret_value="$2"
    local secret_type="${3:-SecretText}"  # SecretText or SecretFile

    echo "Creating/updating secret: $secret_name"

    # Try to create the secret
    response=$(curl -s -w "\n%{http_code}" -X POST "$HARNESS_API_URL" \
        -H "x-api-key: $HARNESS_API_KEY" \
        -H "Content-Type: application/json" \
        -H "Harness-Account: $HARNESS_ACCOUNT_ID" \
        -d "{
            \"secret\": {
                \"type\": \"$secret_type\",
                \"name\": \"$secret_name\",
                \"identifier\": \"$secret_name\",
                \"orgIdentifier\": \"$HARNESS_ORG_ID\",
                \"projectIdentifier\": \"$HARNESS_PROJECT_ID\",
                \"spec\": {
                    \"secretManagerIdentifier\": \"harnessSecretManager\",
                    \"valueType\": \"Inline\",
                    \"value\": \"$secret_value\"
                }
            }
        }")

    http_code=$(echo "$response" | tail -1)
    body=$(echo "$response" | head -n -1)

    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        echo "✓ Secret created: $secret_name"
    elif [ "$http_code" = "400" ] || [ "$http_code" = "409" ]; then
        # Secret may already exist, try to update
        echo "Secret exists, attempting update..."

        response=$(curl -s -w "\n%{http_code}" -X PUT "$HARNESS_API_URL/$secret_name" \
            -H "x-api-key: $HARNESS_API_KEY" \
            -H "Content-Type: application/json" \
            -H "Harness-Account: $HARNESS_ACCOUNT_ID" \
            -d "{
                \"secret\": {
                    \"type\": \"$secret_type\",
                    \"name\": \"$secret_name\",
                    \"identifier\": \"$secret_name\",
                    \"orgIdentifier\": \"$HARNESS_ORG_ID\",
                    \"projectIdentifier\": \"$HARNESS_PROJECT_ID\",
                    \"spec\": {
                        \"secretManagerIdentifier\": \"harnessSecretManager\",
                        \"valueType\": \"Inline\",
                        \"value\": \"$secret_value\"
                    }
                }
            }")

        http_code=$(echo "$response" | tail -1)
        if [ "$http_code" = "200" ]; then
            echo "✓ Secret updated: $secret_name"
        else
            echo "✗ Failed to update secret: $secret_name (HTTP $http_code)"
            echo "$body"
        fi
    else
        echo "✗ Failed to create secret: $secret_name (HTTP $http_code)"
        echo "$body"
    fi
}

# -----------------------------------------------------------------------------
# Main: Read Terraform outputs and store as secrets
# -----------------------------------------------------------------------------

echo "=== Storing Terraform outputs as Harness secrets ==="
echo "Environment: $ENVIRONMENT"

# Check if terraform outputs file exists
TF_OUTPUTS_FILE="${TF_OUTPUTS_FILE:-terraform.tfstate}"
TF_DIR="${TF_DIR:-.}"

cd "$TF_DIR"

# Read outputs from Terraform
if command -v terraform &> /dev/null; then
    echo "Reading Terraform outputs..."

    # Confluent Kafka API Key
    KAFKA_API_KEY=$(terraform output -raw confluent_kafka_api_key 2>/dev/null || echo "")
    if [ -n "$KAFKA_API_KEY" ]; then
        create_or_update_secret "connector_kafka_api_key_${ENVIRONMENT}" "$KAFKA_API_KEY"
    fi

    # Confluent Kafka API Secret
    KAFKA_API_SECRET=$(terraform output -raw confluent_kafka_api_secret 2>/dev/null || echo "")
    if [ -n "$KAFKA_API_SECRET" ]; then
        create_or_update_secret "connector_kafka_api_secret_${ENVIRONMENT}" "$KAFKA_API_SECRET"
    fi

    # GCP Service Account Key (Base64)
    GCP_SA_KEY=$(terraform output -raw gcp_service_account_key_base64 2>/dev/null || echo "")
    if [ -n "$GCP_SA_KEY" ]; then
        create_or_update_secret "connector_gcp_sa_key_${ENVIRONMENT}" "$GCP_SA_KEY"
    fi
else
    echo "ERROR: terraform command not found"
    exit 1
fi

echo ""
echo "=== Secret storage complete ==="
