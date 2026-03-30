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

**Pipeline Stages:**
1. **Terraform Plan** - Shows resources to be created
2. **Approval** - Manual review before apply
3. **Terraform Apply** - Deploys the connector

## Prerequisites

### Required Harness Secrets

Before running, ensure these secrets exist in your Harness project:

| Secret Identifier | Description | Format |
|-------------------|-------------|--------|
| `confluent_cloud_api_key` | Confluent Cloud API Key | Plain text |
| `confluent_cloud_api_secret` | Confluent Cloud API Secret | Plain text |
| `connector_kafka_api_key` | Kafka API Key for connector | Plain text |
| `connector_kafka_api_secret` | Kafka API Secret for connector | Plain text |
| `gcp_bootstrap_credentials_json` | GCP SA JSON | Base64 encoded |
| `github-token` | GitHub Personal Access Token | Plain text |

### Required Updates Before Use

Update the following placeholders in `connector-execution-pipeline.yaml`:

1. **Project/Org Identifiers:**
   ```yaml
   projectIdentifier: <YOUR_PROJECT_IDENTIFIER>
   orgIdentifier: <YOUR_ORG_IDENTIFIER>
   ```

2. **GitHub Repository URL:**
   ```bash
   git clone https://x-access-token:${GITHUB_TOKEN}@github.com/<YOUR_ORG>/<YOUR_REPO>.git repo
   ```

3. **Pipeline Variables (at runtime):**
   - `confluent_environment_id` - Your Confluent Environment ID (e.g., `env-xxxxx`)
   - `confluent_kafka_cluster_id` - Your Kafka Cluster ID (e.g., `lkc-xxxxx`)
   - `connector_name` - Name for your connector
   - `kafka_topic` - Target Kafka topic name
   - `gcp_project_id` - Your GCP Project ID
   - `pubsub_topic_id` - GCP Pub/Sub Topic ID
   - `pubsub_subscription_id` - GCP Pub/Sub Subscription ID

## Delegate Requirements

The pipeline requires a delegate with:
- **Name:** `terraform-delegate`
- **Terraform:** Installed and available in PATH
- **Git:** Installed for repository cloning

See the `Dockerfile` in the repository root to build a custom delegate image with these tools pre-installed.

## Usage

### Via Harness UI

1. Navigate to **Pipelines** in your Harness project
2. Click **+ Create Pipeline**
3. Select **Import from Git**
4. Enter path: `.harness/pipelines/execution/connector-execution-pipeline.yaml`
5. Save and click **Run**
6. Fill in the required variable values
7. Click **Run Pipeline**

## Data Flow After Deployment

```
GCP Pub/Sub Topic
       ↓
GCP Pub/Sub Subscription
       ↓
Confluent Connector (gcp-pubsub-source)
       ↓
Kafka Topic
```

## Troubleshooting

### Common Issues

1. **Secret not found** - Verify secret identifiers match exactly
2. **Delegate not available** - Check delegate named `terraform-delegate` is running
3. **Git clone failed** - Verify GitHub token has repository access
4. **Invalid GCP credentials** - Ensure credentials are base64 encoded

### Debug Mode

Add `TF_LOG=DEBUG` to environment variables for verbose Terraform output.
