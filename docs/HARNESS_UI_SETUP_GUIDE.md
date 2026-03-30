# Harness UI Setup Guide - Complete Step-by-Step

This guide walks you through setting up Harness from scratch to run the Terraform pipeline for GCP Pub/Sub connector deployment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Create Harness Account](#step-1-create-harness-account)
3. [Step 2: Create Organization and Project](#step-2-create-organization-and-project)
4. [Step 3: Connect GitHub Repository](#step-3-connect-github-repository)
5. [Step 4: Set Up Delegate](#step-4-set-up-delegate)
6. [Step 5: Configure Secrets](#step-5-configure-secrets)
7. [Step 6: Create Execution Pipeline](#step-6-create-execution-pipeline)
8. [Step 7: Run the Pipeline](#step-7-run-the-pipeline)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

- [ ] Email address for Harness account
- [ ] GitHub account with a repository containing this code
- [ ] GitHub Personal Access Token (PAT) with repo access
- [ ] Confluent Cloud account with:
  - Cloud API Key and Secret (Organization or Environment Admin)
  - Kafka API Key and Secret (for connector authentication)
  - Environment ID (e.g., `env-xxxxx`)
  - Kafka Cluster ID (e.g., `lkc-xxxxx`)
- [ ] Google Cloud account with:
  - Project with Pub/Sub API enabled
  - Service Account with `roles/pubsub.subscriber` permission
  - Service Account JSON key (base64 encoded)
  - Existing Pub/Sub topic and subscription

---

## Step 1: Create Harness Account

### 1.1 Sign Up for Harness

1. Go to [https://app.harness.io/auth/#/signup](https://app.harness.io/auth/#/signup)

2. Choose one of these options:
   - **Sign up with Google** (fastest)
   - **Sign up with GitHub**
   - **Sign up with Email**

3. Fill in your details and verify your email

4. After verification, you'll be taken to the Harness dashboard

---

## Step 2: Create Organization and Project

### 2.1 Create Organization (if needed)

1. Click on **Account Settings** (gear icon in bottom left)
2. Click **Organizations** → **+ New Organization**
3. Enter organization name (e.g., `my-org`)
4. Click **Save**

### 2.2 Create Project

1. Go to **Home** → Click your organization
2. Click **Projects** → **+ Project**
3. Fill in:
   - **Name**: `gcp-pubsub-connector` (or your preferred name)
   - **Organization**: Select your organization
   - **Description**: GCP Pub/Sub to Kafka connector deployment
4. Click **Save**

---

## Step 3: Connect GitHub Repository

### 3.1 Create GitHub Personal Access Token

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Give it a name: `harness-access`
4. Select scopes:
   - `repo` (Full control of private repositories)
5. Click **Generate token**
6. **Copy the token** (you won't see it again!)

### 3.2 Store GitHub Token as Harness Secret

1. In Harness, go to your **Project** → **Project Settings** → **Secrets**
2. Click **+ New Secret** → **Text**
3. Fill in:
   - **Secret Name**: `github-token`
   - **Secret Identifier**: `github-token` (auto-generated)
   - **Secret Value**: Paste your GitHub PAT
4. Click **Save**

### 3.3 Create GitHub Connector

1. Go to **Project Settings** → **Connectors**
2. Click **+ New Connector**
3. Select **Code Repositories** → **GitHub**
4. Fill in:
   - **Name**: `github-connector`
   - **URL Type**: **Repository**
   - **Connection Type**: **HTTP**
   - **GitHub Repository URL**: `https://github.com/<YOUR_ORG>/<YOUR_REPO>`
5. Click **Continue**
6. For **Credentials**:
   - **Authentication**: Username and Token
   - **Username**: Your GitHub username
   - **Personal Access Token**: Click **Create or Select a Secret** → Select `github-token`
7. Click **Continue**
8. For **Connect to Provider**:
   - Select **Connect through Harness Platform**
9. Click **Save and Continue**
10. Test the connection and click **Finish**

---

## Step 4: Set Up Delegate

The delegate is a service that runs in your infrastructure and executes pipeline tasks.

### 4.1 Install Docker Delegate (Recommended for PoC)

1. Go to **Project Settings** → **Delegates**
2. Click **+ New Delegate**
3. Select **Docker**
4. Fill in:
   - **Delegate Name**: `terraform-delegate`
   - **Delegate Size**: Small
5. Copy the Docker run command shown
6. Run the command on your local machine or server:

```bash
docker run -d --name terraform-delegate \
  -e DELEGATE_NAME=terraform-delegate \
  -e NEXT_GEN=true \
  -e DELEGATE_TYPE=DOCKER \
  -e ACCOUNT_ID=<YOUR_ACCOUNT_ID> \
  -e DELEGATE_TOKEN=<YOUR_TOKEN> \
  -e MANAGER_HOST_AND_PORT=https://app.harness.io \
  harness/delegate:latest
```

7. Wait for the delegate to connect (check status in Harness UI)

### 4.2 Option: Build Custom Delegate with Terraform

Use the provided `Dockerfile` to build a delegate with Terraform pre-installed:

```bash
# Build the image
docker build -t harness-terraform-delegate:latest .

# Run the delegate
docker run -d --name terraform-delegate \
  -e DELEGATE_NAME=terraform-delegate \
  -e NEXT_GEN=true \
  -e DELEGATE_TYPE=DOCKER \
  -e ACCOUNT_ID=<YOUR_ACCOUNT_ID> \
  -e DELEGATE_TOKEN=<YOUR_TOKEN> \
  -e MANAGER_HOST_AND_PORT=https://app.harness.io \
  harness-terraform-delegate:latest
```

### 4.3 Verify Delegate Connection

1. Go to **Project Settings** → **Delegates**
2. Your delegate should show as **Connected** (green status)
3. If not connected after 5 minutes, check Docker logs:
   ```bash
   docker logs terraform-delegate
   ```

---

## Step 5: Configure Secrets

### 5.1 Required Secrets

Create the following secrets in Harness (**Project Settings** → **Secrets** → **+ New Secret** → **Text**):

| Secret Name | Identifier | Value |
|-------------|------------|-------|
| Confluent Cloud API Key | `confluent_cloud_api_key` | Your Confluent Cloud API Key |
| Confluent Cloud API Secret | `confluent_cloud_api_secret` | Your Confluent Cloud API Secret |
| Connector Kafka API Key | `connector_kafka_api_key` | Kafka API Key for connector |
| Connector Kafka API Secret | `connector_kafka_api_secret` | Kafka API Secret for connector |
| GCP Credentials JSON | `gcp_bootstrap_credentials_json` | Base64-encoded GCP SA JSON |

### 5.2 Base64 Encode GCP Credentials

Before adding the GCP credentials secret, base64 encode the JSON file:

```bash
# On macOS/Linux
base64 -i service-account.json | tr -d '\n'

# On Windows (PowerShell)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("service-account.json"))
```

Copy the output and use it as the secret value for `gcp_bootstrap_credentials_json`.

### 5.3 Create Each Secret

For each secret:
1. Click **+ New Secret** → **Text**
2. Enter the **Secret Name** and **Secret Value**
3. Click **Save**
4. Repeat for all 5 secrets (plus `github-token` from Step 3)

---

## Step 6: Create Execution Pipeline

### 6.1 Update Pipeline Placeholders

Before importing, update the pipeline file `.harness/pipelines/execution/connector-execution-pipeline.yaml`:

1. Update project and org identifiers:
   ```yaml
   projectIdentifier: <YOUR_PROJECT_IDENTIFIER>
   orgIdentifier: <YOUR_ORG_IDENTIFIER>
   ```

2. Update the GitHub repository URL in the script sections:
   ```bash
   git clone https://x-access-token:${GITHUB_TOKEN}@github.com/<YOUR_ORG>/<YOUR_REPO>.git repo
   ```

3. Commit and push the changes to your repository

### 6.2 Import Pipeline from Git

1. Go to **Pipelines** in your project
2. Click **+ Create Pipeline**
3. Enter:
   - **Name**: `GCP PubSub Connector Execution`
   - **How do you want to set up your pipeline?**: **Import from Git**
4. Click **Import from Git**
5. Fill in:
   - **Git Connector**: Select `github-connector`
   - **Repository**: Your repository name
   - **Branch**: `main`
   - **YAML Path**: `.harness/pipelines/execution/connector-execution-pipeline.yaml`
6. Click **Import**

### 6.3 Verify Pipeline

After import, verify the pipeline has:
- **Stage 1**: Terraform Plan
- **Stage 2**: Approval
- **Stage 3**: Terraform Apply

---

## Step 7: Run the Pipeline

### 7.1 Execute Pipeline

1. Go to **Pipelines** → Click your pipeline
2. Click **Run**
3. Fill in the **Input Variables**:

| Variable | Example Value |
|----------|--------------|
| `confluent_environment_id` | `env-abc123` |
| `confluent_kafka_cluster_id` | `lkc-xyz789` |
| `connector_name` | `gcp-pubsub-source` |
| `kafka_topic` | `my.events.topic` |
| `gcp_project_id` | `my-gcp-project` |
| `pubsub_topic_id` | `my-pubsub-topic` |
| `pubsub_subscription_id` | `my-subscription` |

4. Click **Run Pipeline**

### 7.2 Monitor Execution

1. **Terraform Plan Stage**:
   - Watch the logs for planned resources
   - Verify the connector configuration looks correct

2. **Approval Stage**:
   - Review the plan output
   - Click **Approve** to proceed (or **Reject** to cancel)

3. **Terraform Apply Stage**:
   - Watch the connector being created
   - Wait for completion (can take 2-5 minutes)

### 7.3 Verify Deployment

After successful pipeline completion:

1. Go to **Confluent Cloud** → Your cluster → **Connectors**
2. Find your connector by name
3. Verify status is **RUNNING**
4. Check the **Tasks** tab for healthy tasks

---

## Troubleshooting

### Pipeline Import Failed

**Error**: "Invalid YAML"
- Ensure placeholders are replaced with actual values
- Check YAML syntax is valid
- Verify file path is correct

### Delegate Not Connected

**Error**: "No delegates available"
- Check delegate is running: `docker ps`
- View delegate logs: `docker logs terraform-delegate`
- Verify account ID and token are correct
- Ensure delegate name matches `delegateSelectors` in pipeline

### Secret Not Found

**Error**: "Secret not found: xyz"
- Verify secret exists in Project → Secrets
- Check secret identifier matches exactly (case-sensitive)
- Ensure secret is at project scope (not organization)

### Git Clone Failed

**Error**: "Authentication failed"
- Verify `github-token` secret has correct PAT value
- Ensure PAT has `repo` scope
- Check repository URL is correct

### Terraform Init Failed

**Error**: "Provider not found"
- Ensure delegate has internet access
- Check Terraform is installed on delegate
- Use custom delegate image with Terraform pre-installed

### Invalid GCP Credentials

**Error**: "Invalid Credentials Json"
- Verify GCP credentials are base64 encoded
- Test decoding: `echo "<base64_string>" | base64 -d`
- Ensure service account has correct permissions

### Connector Creation Failed

**Error**: "Pub/Sub topic not found"
- Verify GCP project ID is correct
- Ensure Pub/Sub topic exists
- Check subscription exists and is attached to topic
- Verify service account has `roles/pubsub.subscriber`

---

## Next Steps

After successful deployment:

1. **Test the Connector**:
   - Publish a message to your Pub/Sub topic
   - Consume from the Kafka topic to verify data flow

2. **Monitor**:
   - Check connector status in Confluent Cloud
   - Review connector metrics and logs

3. **Production Considerations**:
   - Increase `tasks_max` for higher throughput
   - Set up alerting for connector failures
   - Configure Terraform state backend (GCS/S3)
