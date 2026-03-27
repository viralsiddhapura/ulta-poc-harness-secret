# Harness + Terraform PoC for GCP Pub/Sub Connector

This is a complete, isolated Proof of Concept for integrating Harness with Terraform to deploy GCP Pub/Sub Source Connectors on Confluent Cloud.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              HARNESS PLATFORM                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────────────┐         ┌──────────────────────────┐          │
│  │   PIPELINE 1             │         │   PIPELINE 2             │          │
│  │   Service Accounts &     │ ──────► │   Connector Deployment   │          │
│  │   Secrets Setup          │         │                          │          │ 
│  └──────────────────────────┘         └──────────────────────────┘          │
│           │                                      │                          │
│           ▼                                      ▼                          │
│  ┌──────────────────────────┐         ┌──────────────────────────┐          │
│  │   Creates:               │         │   Deploys:               │          │
│  │   • Confluent SA         │         │   • GCP Pub/Sub          │          │
│  │   • Confluent API Keys   │         │     Source Connector     │          │
│  │   • GCP SA               │         │   • Uses secrets from    │          │
│  │   • GCP SA Key           │         │     Pipeline 1           │          │
│  │   • Stores in Harness    │         │                          │          │
│  │     Secret Manager       │         │                          │          │
│  └──────────────────────────┘         └──────────────────────────┘          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CONFLUENT CLOUD                                │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────────────────────┐    │
│  │ Service Account│  │   API Keys     │  │  GCP Pub/Sub Connector      │    │
│  │ (connector-sa) │  │ (kafka access) │  │  (reads from GCP Pub/Sub)   │    │
│  └────────────────┘  └────────────────┘  └─────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GOOGLE CLOUD                                   │
│  ┌────────────────┐  ┌────────────────┐  ┌─────────────────────────────┐    │
│  │ Service Account│  │   SA Key       │  │     Pub/Sub Subscription    │    │
│  │ (pubsub-reader)│  │   (JSON)       │  │     (source data)           │    │
│  └────────────────┘  └────────────────┘  └─────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
harness-terraform-poc/
├── .harness/
│   ├── pipelines/
│   │   ├── pipeline-1-service-accounts.yaml    # Pipeline 1: Create SAs & Secrets
│   │   └── pipeline-2-connector.yaml           # Pipeline 2: Deploy Connector
│   ├── templates/
│   │   └── terraform-execution-template.yaml   # Reusable Terraform template
│   └── inputsets/
│       ├── dev-inputset.yaml                   # Dev environment inputs
│       └── prod-inputset.yaml                  # Prod environment inputs
├── terraform/
│   ├── modules/
│   │   ├── confluent-service-account/          # Creates Confluent SA + API Keys
│   │   ├── gcp-service-account/                # Creates GCP SA + Key
│   │   └── gcp-pubsub-connector/               # Deploys the connector
│   └── environments/
│       └── dev/
│           ├── service-accounts/               # Pipeline 1 deployment
│           └── connector/                      # Pipeline 2 deployment
├── scripts/
│   ├── setup-secrets.sh                        # Pre-terraform secret setup
│   ├── cleanup-secrets.sh                      # Post-terraform cleanup
│   └── store-output-to-harness.sh              # Store TF outputs as secrets
├── docs/
│   └── HARNESS_UI_SETUP_GUIDE.md              # Step-by-step UI guide
└── README.md                                   # This file
```

## Prerequisites

Before you begin, ensure you have:

1. **Harness Account** (Free tier works for PoC)
2. **GitHub Account** (to host this repository)
3. **Confluent Cloud Account** with:
   - Organization Admin or Environment Admin access
   - An existing environment
   - An existing Kafka cluster
4. **Google Cloud Account** with:
   - Project with Pub/Sub API enabled
   - Existing Pub/Sub subscription
   - IAM permissions to create service accounts

## Quick Start

### Step 1: Fork/Clone to Your GitHub

```bash
# Create a new repository on GitHub, then:
cd harness-terraform-poc
git init
git add .
git commit -m "Initial Harness + Terraform PoC setup"
git remote add origin https://github.com/YOUR_USERNAME/harness-terraform-poc.git
git push -u origin main
```

### Step 2: Set Up Harness (Follow the UI Guide)

See [docs/HARNESS_UI_SETUP_GUIDE.md](docs/HARNESS_UI_SETUP_GUIDE.md) for detailed instructions.

### Step 3: Configure Secrets in Harness

Add these secrets in Harness Secret Manager:
- `confluent_cloud_api_key` - Your Confluent Cloud API Key
- `confluent_cloud_api_secret` - Your Confluent Cloud API Secret
- `gcp_project_id` - Your GCP Project ID
- `gcp_credentials_json` - Your GCP Service Account JSON (for initial bootstrap)

### Step 4: Run Pipeline 1

This creates all service accounts and stores credentials as secrets.

### Step 5: Run Pipeline 2

This deploys the GCP Pub/Sub connector using the secrets from Pipeline 1.

## Security Best Practices

1. **Never commit secrets** - All sensitive data stored in Harness Secret Manager
2. **Use short-lived credentials** - API keys can be rotated via Pipeline 1
3. **Least privilege** - Service accounts have minimal required permissions
4. **Audit trail** - Harness provides complete audit logs

## Pipeline Details

### Pipeline 1: Service Accounts & Secrets Setup

Creates:
- Confluent Cloud Service Account for the connector
- Confluent API Key/Secret for Kafka access
- GCP Service Account for Pub/Sub access
- GCP Service Account Key (JSON)
- Stores all outputs in Harness Secret Manager

### Pipeline 2: Connector Deployment

Deploys:
- GCP Pub/Sub Source Connector
- Automatically injects secrets from Harness
- Configures connector to read from specified subscription

## Troubleshooting

### Common Issues

1. **"Secret not found"** - Ensure Pipeline 1 ran successfully first
2. **"Insufficient permissions"** - Check Confluent/GCP IAM roles
3. **"Connector failed to start"** - Verify Pub/Sub subscription exists

### Debug Mode

Set `TF_LOG=DEBUG` in pipeline environment variables for verbose logging.

## Next Steps

After PoC validation:
1. Add staging/production environments
2. Implement approval gates between environments
3. Add Terraform state locking
4. Configure notifications and alerts

## Support

For issues with this PoC:
- Check [docs/HARNESS_UI_SETUP_GUIDE.md](docs/HARNESS_UI_SETUP_GUIDE.md)
- Review Harness documentation: https://developer.harness.io
- Terraform Confluent Provider: https://registry.terraform.io/providers/confluentinc/confluent
