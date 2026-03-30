# Harness + Terraform: GCP Pub/Sub to Confluent Kafka Connector

A production-ready solution for deploying GCP Pub/Sub Source Connectors to Confluent Cloud using Harness pipelines and Terraform.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration Reference](#configuration-reference)
- [Harness Setup Guide](#harness-setup-guide)
- [Terraform Module](#terraform-module)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

---

## Overview

This repository provides Infrastructure as Code (IaC) to deploy GCP Pub/Sub Source Connectors on Confluent Cloud. The solution integrates:

- **Harness** - CI/CD platform for pipeline orchestration
- **Terraform** - Infrastructure provisioning
- **Confluent Cloud** - Managed Kafka platform
- **GCP Pub/Sub** - Source messaging system

**Data Flow:**
```
GCP Pub/Sub Topic → GCP Pub/Sub Subscription → Confluent Connector → Kafka Topic
```

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              HARNESS PLATFORM                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────┐     │
│  │                    EXECUTION PIPELINE                              │     │
│  │  ┌──────────────┐   ┌──────────────┐   ┌──────────────────────┐    │     │
│  │  │ Terraform    │ → │   Approval   │ → │  Terraform Apply     │    │     │
│  │  │ Plan         │   │   Gate       │   │  (Deploy Connector)  │    │     │
│  │  └──────────────┘   └──────────────┘   └──────────────────────┘    │     │
│  └────────────────────────────────────────────────────────────────────┘     │
│                                                                             │
│  Secrets (Pre-provisioned):                                                 │
│  • Confluent Cloud API Key/Secret                                           │
│  • Connector Kafka API Key/Secret                                           │
│  • GCP Service Account Credentials (JSON)                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CONFLUENT CLOUD                                │
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐  │
│  │  Environment    │    │  Kafka Cluster  │    │  GCP Pub/Sub Connector  │  │
│  │  (env-xxxxx)    │───▶│  (lkc-xxxxx)    │◀───│  (Source Connector)     │  │
│  └─────────────────┘    └─────────────────┘    └─────────────────────────┘  │
│                                                           │                 │
└───────────────────────────────────────────────────────────│─────────────────┘
                                                            │
                                                            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GOOGLE CLOUD PLATFORM                          │
│                                                                             │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────────────┐  │
│  │  GCP Project    │    │  Pub/Sub Topic  │    │  Pub/Sub Subscription   │  │
│  │                 │───▶│                 │───▶│  (Connector reads here) │  │
│  └─────────────────┘    └─────────────────┘    └─────────────────────────┘  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
harness-terraform-poc/
│
├── .harness/
│   └── pipelines/
│       └── execution/
│           ├── connector-execution-pipeline.yaml   # Main pipeline
│           ├── inputsets/
│           │   └── dev-execution-inputset.yaml     # Dev environment inputs
│           └── README.md                           # Pipeline documentation
│
├── terraform/
│   ├── modules/
│   │   └── gcp-pubsub-connector/                   # GCP Pub/Sub Source Connector
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/
│       └── dev/
│           └── connector/                          # Environment configuration
│               ├── main.tf
│               ├── variables.tf
│               └── outputs.tf
│
├── docs/
│   └── HARNESS_UI_SETUP_GUIDE.md                   # Detailed UI setup guide
│
├── Dockerfile                                      # Custom delegate image
├── .gitignore
└── README.md                                       # This file
```

---

## Prerequisites

### Accounts Required

| Service | Requirements |
|---------|-------------|
| **Harness** | Account with pipeline execution permissions |
| **GitHub** | Repository access for pipeline source |
| **Confluent Cloud** | Environment and Kafka cluster pre-created |
| **Google Cloud** | Project with Pub/Sub API enabled |

### Confluent Cloud Setup

Before running the pipeline, ensure you have:

1. **Confluent Cloud Organization** with API access
2. **Environment** created (note the `env-xxxxx` ID)
3. **Kafka Cluster** created (note the `lkc-xxxxx` ID)
4. **Cloud API Key** with OrganizationAdmin or EnvironmentAdmin permissions
5. **Kafka API Key** for the connector to authenticate with the cluster

### GCP Setup

1. **GCP Project** with Pub/Sub API enabled
2. **Pub/Sub Topic** created
3. **Pub/Sub Subscription** created for the topic
4. **Service Account** with `roles/pubsub.subscriber` permission
5. **Service Account Key** (JSON format, base64 encoded for Harness)

### Harness Setup

1. **Harness Delegate** installed and running (named: `terraform-delegate`)
2. **GitHub Connector** for repository access
3. **Secrets** configured (see [Required Secrets](#required-secrets))

---

## Quick Start

### Step 1: Clone Repository

```bash
git clone https://github.com/<YOUR_ORG>/<YOUR_REPO>.git
cd harness-terraform-poc
```

### Step 2: Update Placeholders

Update the following in `.harness/pipelines/execution/connector-execution-pipeline.yaml`:

```yaml
# Update these identifiers
projectIdentifier: <YOUR_PROJECT_IDENTIFIER>
orgIdentifier: <YOUR_ORG_IDENTIFIER>

# Update the git clone URL in the script sections
git clone https://x-access-token:${GITHUB_TOKEN}@github.com/<YOUR_ORG>/<YOUR_REPO>.git repo
```

### Step 3: Configure Harness Secrets

Add these secrets in Harness (Project → Secrets):

| Secret Identifier | Description | Format |
|-------------------|-------------|--------|
| `confluent_cloud_api_key` | Confluent Cloud API Key | Plain text |
| `confluent_cloud_api_secret` | Confluent Cloud API Secret | Plain text |
| `connector_kafka_api_key` | Kafka API Key for connector | Plain text |
| `connector_kafka_api_secret` | Kafka API Secret for connector | Plain text |
| `gcp_bootstrap_credentials_json` | GCP Service Account JSON | Base64 encoded |
| `github-token` | GitHub Personal Access Token | Plain text |

**To base64 encode GCP credentials:**
```bash
base64 -i service-account.json | tr -d '\n'
```

### Step 4: Create Pipeline in Harness

1. Go to Harness → Pipelines → **+ Create Pipeline**
2. Select **Import from Git**
3. Path: `.harness/pipelines/execution/connector-execution-pipeline.yaml`
4. Save

### Step 5: Run Pipeline

1. Click **Run**
2. Fill in the required variables:
   - `confluent_environment_id` (e.g., `env-xxxxx`)
   - `confluent_kafka_cluster_id` (e.g., `lkc-xxxxx`)
   - `connector_name` (e.g., `gcp-pubsub-source`)
   - `kafka_topic` (e.g., `my.events.topic`)
   - `gcp_project_id` (e.g., `my-gcp-project`)
   - `pubsub_topic_id` (e.g., `my-pubsub-topic`)
   - `pubsub_subscription_id` (e.g., `my-subscription`)
3. Click **Run Pipeline**
4. Review the Terraform plan
5. **Approve** to deploy the connector

---

## Configuration Reference

### Pipeline Variables

| Variable | Description | Required | Example |
|----------|-------------|----------|---------|
| `confluent_environment_id` | Confluent Environment ID | Yes | `env-abc123` |
| `confluent_kafka_cluster_id` | Kafka Cluster ID | Yes | `lkc-xyz789` |
| `connector_name` | Name for the connector | Yes | `gcp-pubsub-source` |
| `kafka_topic` | Target Kafka topic | Yes | `my.events.topic` |
| `tasks_max` | Max connector tasks (1-10) | No | `1` |
| `output_data_format` | Output format | No | `JSON` |
| `gcp_project_id` | GCP Project ID | Yes | `my-project-123` |
| `pubsub_topic_id` | Pub/Sub Topic ID | Yes | `my-topic` |
| `pubsub_subscription_id` | Pub/Sub Subscription ID | Yes | `my-subscription` |

### Required Secrets

| Secret Identifier | Description | How to Obtain |
|-------------------|-------------|---------------|
| `confluent_cloud_api_key` | Cloud API Key | Confluent Cloud → API Keys → Create Key |
| `confluent_cloud_api_secret` | Cloud API Secret | Created with API Key |
| `connector_kafka_api_key` | Kafka API Key | Confluent Cloud → Cluster → API Keys |
| `connector_kafka_api_secret` | Kafka API Secret | Created with Kafka API Key |
| `gcp_bootstrap_credentials_json` | GCP SA JSON (base64) | `base64 -i service-account.json` |
| `github-token` | GitHub PAT | GitHub → Settings → Developer Settings → PAT |

---

## Harness Setup Guide

### 1. Create Harness Project

1. Log in to Harness → Select your Organization
2. Click **Projects** → **+ Project**
3. Name: `your-project-name`
4. Save

### 2. Install Harness Delegate

1. Go to **Project Settings** → **Delegates**
2. Click **+ New Delegate**
3. Select **Docker** or **Kubernetes**
4. Name: `terraform-delegate`
5. Follow installation instructions
6. Verify delegate is connected

**Option: Use Custom Delegate Image**

Build the provided Dockerfile for a delegate with Terraform pre-installed:
```bash
docker build -t harness-terraform-delegate:latest .
```

### 3. Create GitHub Connector

1. Go to **Project Settings** → **Connectors**
2. Click **+ New Connector** → **Code Repositories** → **GitHub**
3. Name: `github-connector`
4. Connection Type: **HTTP**
5. URL: `https://github.com/<YOUR_ORG>`
6. Authentication: **Username and Token**
7. Token: Select secret `github-token`
8. Test and Save

### 4. Add Secrets

1. Go to **Project Settings** → **Secrets**
2. Click **+ New Secret** → **Text**
3. Add each secret from the [Required Secrets](#required-secrets) table

### 5. Create and Run Pipeline

1. Go to **Pipelines** → **+ Create Pipeline**
2. Select **Import from Git**
3. Path: `.harness/pipelines/execution/connector-execution-pipeline.yaml`
4. Save and **Run**

---

## Terraform Module

### gcp-pubsub-connector

Deploys a GCP Pub/Sub Source Connector to Confluent Cloud.

**Inputs:**

| Variable | Type | Description |
|----------|------|-------------|
| `environment_id` | string | Confluent Environment ID |
| `kafka_cluster_id` | string | Kafka Cluster ID |
| `connector_name` | string | Connector name |
| `kafka_topic` | string | Target Kafka topic |
| `tasks_max` | number | Max tasks (default: 1) |
| `output_data_format` | string | Output format (default: JSON) |
| `gcp_project_id` | string | GCP Project ID |
| `pubsub_topic_id` | string | Pub/Sub Topic ID |
| `pubsub_subscription_id` | string | Pub/Sub Subscription ID |
| `gcp_credentials_base64` | string | Base64-encoded GCP SA JSON |
| `kafka_api_key` | string | Kafka API Key |
| `kafka_api_secret` | string | Kafka API Secret |

**Outputs:**

| Output | Description |
|--------|-------------|
| `connector_id` | Created connector ID |
| `connector_name` | Connector name |
| `connector_status` | Connector status |

---

## Troubleshooting

### Common Errors

#### "Error: Secret not found"
- Verify all secrets exist in Harness with exact identifiers
- Check secret scope (Project vs Organization)

#### "Error: Delegate not found"
- Verify delegate name matches `delegateSelectors` in pipeline (`terraform-delegate`)
- Check delegate is healthy in Harness UI

#### "Error: Invalid GCP Credentials"
- Ensure GCP credentials are base64 encoded
- Verify service account has `roles/pubsub.subscriber` role
- Test decoding: `echo "<base64_string>" | base64 -d`

#### "Error: Confluent provider kafka credentials"
- This is handled by renamed variables (`connector_kafka_key`)
- Ensure using the latest pipeline version from this repository

#### "Error: gcp.pubsub.topic.id is required"
- Ensure `pubsub_topic_id` variable is provided when running the pipeline

#### "Error: Connector still creating after 10 minutes"
- This is normal for first-time connector creation
- Check Confluent Cloud UI for connector status
- Connector provisioning can take 2-5 minutes

### Debug Mode

Add to pipeline environment variables for verbose logging:
```yaml
environmentVariables:
  - name: TF_LOG
    type: String
    value: DEBUG
```

### Verify Connector Status

After deployment, verify in Confluent Cloud:
1. Go to **Connectors** in your cluster
2. Find your connector by name
3. Check status is **RUNNING**
4. View **Tasks** tab for task status

---

## Security Best Practices

1. **Secret Management**
   - All credentials stored in Harness Secret Manager
   - Never commit secrets to repository
   - Use secret references in pipelines

2. **Least Privilege**
   - GCP SA: Only `roles/pubsub.subscriber` role
   - Kafka API Key: Scoped to specific cluster
   - Confluent API: Environment-level access only

3. **Network Security**
   - Connector runs in Confluent Cloud (fully managed)
   - No direct network access required from Harness delegate

4. **Audit & Compliance**
   - Harness provides complete audit logs
   - Terraform state tracks all infrastructure changes
   - Approval gates prevent unauthorized deployments

---

## Custom Delegate (Dockerfile)

A `Dockerfile` is provided to build a custom Harness delegate with required tools:

```bash
# Build the delegate image
docker build -t harness-terraform-delegate:latest .

# Push to your container registry
docker tag harness-terraform-delegate:latest <YOUR_REGISTRY>/harness-terraform-delegate:latest
docker push <YOUR_REGISTRY>/harness-terraform-delegate:latest
```

**Included Tools:**
- Terraform 1.6.0
- Google Cloud CLI
- Git
- Python 3.11

---

## Support

- **Harness Documentation:** https://developer.harness.io
- **Confluent Terraform Provider:** https://registry.terraform.io/providers/confluentinc/confluent
- **GCP Pub/Sub Connector:** https://docs.confluent.io/cloud/current/connectors/cc-gcp-pubsub-source.html

---

## License

This project is provided as-is for demonstration purposes.
