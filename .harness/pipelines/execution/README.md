# Execution Pipelines

This folder contains execution pipelines designed for scenarios where the **Platform Team has already provisioned all service accounts and secrets**.

## When to Use These Pipelines

Use execution pipelines when:
- Confluent Cloud API credentials are pre-provisioned
- Connector Kafka API keys are pre-provisioned
- GCP Pub/Sub service account JSON is pre-provisioned
- All secrets are already stored in Harness

## Available Pipelines

### `connector-execution-pipeline.yaml`

Deploys a GCP Pub/Sub Source Connector to Confluent Cloud.

**Prerequisites:**
- All secrets must exist in Harness before running

**Required Harness Secrets:**

| Secret Identifier | Description |
|-------------------|-------------|
| `confluent_cloud_api_key` | Confluent Cloud API Key |
| `confluent_cloud_api_secret` | Confluent Cloud API Secret |
| `connector_kafka_api_key` | Kafka API Key for connector |
| `connector_kafka_api_secret` | Kafka API Secret for connector |
| `gcp_pubsub_credentials_base64` | GCP SA JSON (base64 encoded) |

## How Secrets Are Pulled at Runtime

Secrets are fetched dynamically using Harness expressions:

```yaml
envVariables:
  # Secrets pulled at runtime
  TF_VAR_confluent_cloud_api_key: <+secrets.getValue("<+pipeline.variables.secret_confluent_api_key>")>
```

The pipeline variables (`secret_confluent_api_key`, etc.) define which Harness secrets to use. This allows:
- Different secret names per environment
- Flexibility in secret organization
- Clear visibility of which secrets are used

## Pipeline Stages

1. **Pre-flight Validation** - Verifies all secrets are accessible
2. **Terraform Plan** - Shows resources to be created
3. **Approval** - Manual review before apply
4. **Terraform Apply** - Deploys the connector
5. **Verify Connector** - Confirms connector is running

## Input Sets

See `inputsets/` folder for pre-configured input sets:
- `dev-execution-inputset.yaml` - Development environment

## Usage

```bash
# Run via Harness CLI
harness pipeline run \
  --pipeline gcp_pubsub_connector_execution \
  --inputset dev-execution-inputset

# Or run via Harness UI
# Pipelines → execution → GCP PubSub Connector Execution → Run
```
