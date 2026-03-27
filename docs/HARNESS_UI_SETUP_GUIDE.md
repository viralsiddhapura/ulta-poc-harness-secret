# Harness UI Setup Guide - Complete Step-by-Step

This guide walks you through setting up Harness from scratch to run the Terraform pipelines for GCP Pub/Sub connector deployment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Create Harness Account](#step-1-create-harness-account)
3. [Step 2: Create Organization and Project](#step-2-create-organization-and-project)
4. [Step 3: Connect GitHub Repository](#step-3-connect-github-repository)
5. [Step 4: Set Up Delegate](#step-4-set-up-delegate)
6. [Step 5: Configure Secrets](#step-5-configure-secrets)
7. [Step 6: Create Pipeline 1 (Service Accounts)](#step-6-create-pipeline-1-service-accounts)
8. [Step 7: Create Pipeline 2 (Connector Deployment)](#step-7-create-pipeline-2-connector-deployment)
9. [Step 8: Run the Pipelines](#step-8-run-the-pipelines)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

- [ ] Email address for Harness account
- [ ] GitHub account with a repository containing this PoC code
- [ ] Confluent Cloud account with:
  - Cloud API Key and Secret (Organization or Environment Admin)
  - Environment ID (e.g., `env-xxxxx`)
  - Kafka Cluster ID (e.g., `lkc-xxxxx`)
- [ ] Google Cloud account with:
  - Project with Pub/Sub API enabled
  - Service Account with Pub/Sub Admin role (for bootstrapping)
  - Existing Pub/Sub subscription

---

## Step 1: Create Harness Account

### 1.1 Sign Up for Harness

1. Go to [https://app.harness.io/auth/#/signup](https://app.harness.io/auth/#/signup)

2. Choose one of these options:
   - **Sign up with Google** (fastest)
   - **Sign up with GitHub**
   - **Sign up with Email**

3. Fill in your details:
   - First Name
   - Last Name
   - Company Name (can be your name for personal use)
   - Accept Terms of Service

4. Click **Sign Up**

### 1.2 Complete Email Verification

1. Check your email for verification link
2. Click the link to verify your account
3. You'll be redirected to Harness dashboard

### 1.3 Initial Setup Wizard

After signing in, Harness may show a setup wizard:

1. **Select your use case**: Choose "Continuous Delivery" or "Infrastructure"
2. **Select modules**: Enable "Continuous Delivery" and optionally "Infrastructure as Code"
3. Click **Continue**

---

## Step 2: Create Organization and Project

### 2.1 Create an Organization

Organizations are the top-level containers in Harness.

1. In the left sidebar, click on your account name at the top
2. Click **Organizations**
3. Click **+ New Organization**
4. Fill in:
   - **Name**: `kafka-infrastructure` (or your preferred name)
   - **Description**: "Kafka infrastructure management with Terraform"
   - **Identifier**: Auto-generated (or customize)
5. Click **Save**

### 2.2 Create a Project

Projects contain your pipelines and resources.

1. After creating the organization, you'll be in it
2. Click **+ New Project**
3. Fill in:
   - **Name**: `gcp-pubsub-connector`
   - **Description**: "GCP Pub/Sub Connector deployment"
   - **Identifier**: Auto-generated
   - **Color**: Choose any color
4. Click **Save**

**Screenshot reference points:**
```
┌─────────────────────────────────────────────────────┐
│  Harness                    [Account Name ▼]        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Organizations                                      │
│  ┌───────────────────────────────────────────────┐  │
│  │ + New Organization                            │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
│  Your Organizations:                                │
│  ┌───────────────────────────────────────────────┐  │
│  │ kafka-infrastructure                          │  │
│  │ └── gcp-pubsub-connector (Project)            │  │
│  └───────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Step 3: Connect GitHub Repository

### 3.1 Push Code to GitHub

First, push the PoC code to your GitHub:

```bash
# Navigate to the PoC directory
cd harness-terraform-poc

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial Harness + Terraform PoC setup"

# Create repository on GitHub first, then:
git remote add origin https://github.com/YOUR_USERNAME/harness-terraform-poc.git
git branch -M main
git push -u origin main
```

### 3.2 Create GitHub Connector in Harness

1. In your project, go to **Project Settings** (gear icon in left sidebar)
2. Under "Project-level resources", click **Connectors**
3. Click **+ New Connector**
4. Select **Code Repositories** → **GitHub**

### 3.3 Configure GitHub Connector

**Step 1: Overview**
- **Name**: `github-connector`
- **Description**: "Connection to GitHub repository"
- **Identifier**: Auto-generated
- Click **Continue**

**Step 2: Details**
- **URL Type**: Select **Repository**
- **Connection Type**: Select **HTTP**
- **GitHub Repository URL**: `https://github.com/YOUR_USERNAME/harness-terraform-poc`
- Click **Continue**

**Step 3: Credentials**
- **Authentication**: Select **Username and Token**
- **Username**: Your GitHub username
- **Personal Access Token**: Click **Create or Select a Secret**

### 3.4 Create GitHub Token Secret

1. In the secret dialog, click **+ New Secret Text**
2. **Name**: `github-token`
3. **Value**: Paste your GitHub Personal Access Token

   To create a GitHub PAT:
   - Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Select scopes: `repo` (full control of private repositories)
   - Copy the generated token

4. Click **Save**
5. Select the newly created secret
6. Click **Continue**

**Step 4: Select Connectivity Mode**
- Select **Connect through Harness Platform**
- Click **Save and Continue**

**Step 5: Test Connection**
- Click **Test Connection**
- Should show "Connection Successful"
- Click **Finish**

---

## Step 4: Set Up Delegate

The Harness Delegate is an agent that runs your pipelines. For this PoC, we'll use a Docker delegate.

### 4.1 Navigate to Delegates

1. Go to **Project Settings** → **Delegates**
2. Click **+ New Delegate**

### 4.2 Choose Delegate Type

Select **Docker** for easiest setup.

### 4.3 Configure Docker Delegate

**Delegate Name**: `terraform-delegate`

**Download the delegate command:**

```bash
docker run -d --name harness-delegate \
  -e DELEGATE_NAME=terraform-delegate \
  -e NEXT_GEN=true \
  -e DELEGATE_TYPE=DOCKER \
  -e ACCOUNT_ID=YOUR_ACCOUNT_ID \
  -e DELEGATE_TOKEN=YOUR_DELEGATE_TOKEN \
  -e MANAGER_HOST_AND_PORT=https://app.harness.io \
  -e LOG_STREAMING_SERVICE_URL=https://app.harness.io/log-service/ \
  harness/delegate:latest
```

**Important**: Replace `YOUR_ACCOUNT_ID` and `YOUR_DELEGATE_TOKEN` with the values shown in the Harness UI.

### 4.4 Install Required Tools on Delegate

The delegate needs Terraform installed. Create a custom delegate:

1. Create a `Dockerfile`:

```dockerfile
FROM harness/delegate:latest

USER root

# Install Terraform
RUN apt-get update && apt-get install -y wget unzip && \
    wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip && \
    unzip terraform_1.6.0_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_1.6.0_linux_amd64.zip && \
    terraform --version

# Install Google Cloud SDK (optional but recommended)
RUN apt-get install -y apt-transport-https ca-certificates gnupg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt-get update && apt-get install -y google-cloud-sdk

USER harness
```

2. Build and run:

```bash
docker build -t harness-delegate-terraform .
docker run -d --name harness-delegate \
  -e DELEGATE_NAME=terraform-delegate \
  -e NEXT_GEN=true \
  -e DELEGATE_TYPE=DOCKER \
  -e ACCOUNT_ID=YOUR_ACCOUNT_ID \
  -e DELEGATE_TOKEN=YOUR_DELEGATE_TOKEN \
  -e MANAGER_HOST_AND_PORT=https://app.harness.io \
  harness-delegate-terraform
```

### 4.5 Verify Delegate Connection

1. In Harness UI, go to **Project Settings** → **Delegates**
2. Wait for your delegate to appear (may take 2-3 minutes)
3. Status should show **Connected** with a green indicator

---

## Step 5: Configure Secrets

### 5.1 Navigate to Secrets

1. Go to **Project Settings** → **Secrets**
2. You'll see any existing secrets

### 5.2 Create Confluent Cloud Secrets

**Secret 1: Confluent Cloud API Key**

1. Click **+ New Secret** → **Secret Text**
2. Fill in:
   - **Name**: `confluent_cloud_api_key`
   - **Description**: "Confluent Cloud API Key for Terraform"
   - **Secret Value**: Paste your Confluent Cloud API Key
3. Click **Save**

**Secret 2: Confluent Cloud API Secret**

1. Click **+ New Secret** → **Secret Text**
2. Fill in:
   - **Name**: `confluent_cloud_api_secret`
   - **Description**: "Confluent Cloud API Secret for Terraform"
   - **Secret Value**: Paste your Confluent Cloud API Secret
3. Click **Save**

### 5.3 Create GCP Bootstrap Credentials Secret

This is the GCP service account JSON key used to CREATE the new service account.

1. Click **+ New Secret** → **Secret File** (or **Secret Text** for JSON string)
2. Fill in:
   - **Name**: `gcp_bootstrap_credentials_json`
   - **Description**: "GCP SA credentials for creating Pub/Sub reader SA"
   - **Upload**: Upload your GCP service account JSON key file
     OR
   - **Secret Value**: Paste the entire JSON content
3. Click **Save**

### 5.4 Create Harness API Key (for storing outputs)

1. Go to your **Profile** (top right) → **My API Keys**
2. Click **+ API Key**
3. Fill in:
   - **Name**: `terraform-automation`
   - **Description**: "API key for Terraform pipeline automation"
4. Click **Save**
5. **Copy the API key** - you won't see it again!
6. Go back to **Project Settings** → **Secrets**
7. Create a new secret:
   - **Name**: `harness_api_key`
   - **Value**: Paste the API key
8. Click **Save**

### 5.5 Summary of Required Secrets

After this step, you should have these secrets:

| Secret Name | Type | Description |
|-------------|------|-------------|
| `confluent_cloud_api_key` | Text | Confluent Cloud API Key |
| `confluent_cloud_api_secret` | Text | Confluent Cloud API Secret |
| `gcp_bootstrap_credentials_json` | Text/File | GCP SA JSON for bootstrapping |
| `harness_api_key` | Text | Harness API key for automation |
| `github-token` | Text | GitHub PAT (created in Step 3) |

---

## Step 6: Create Pipeline 1 (Service Accounts)

### 6.1 Navigate to Pipelines

1. In left sidebar, click **Pipelines**
2. Click **+ Create Pipeline**

### 6.2 Pipeline Basics

1. **Name**: `Pipeline 1 - Service Accounts Setup`
2. **Description**: "Creates Confluent and GCP service accounts"
3. Click **Start**

### 6.3 Option A: Import from YAML (Recommended)

1. In the pipeline editor, click the **YAML** toggle (top right)
2. Click **Edit YAML**
3. Replace the content with the YAML from `.harness/pipelines/pipeline-1-service-accounts.yaml`
4. Update the placeholders:
   - `<+input>` values for `orgIdentifier` and `projectIdentifier`
   - GitHub connector reference
5. Click **Save**

### 6.4 Option B: Build in Visual Editor

If you prefer the visual editor, follow these steps:

**Add Stage 1: Terraform Plan**

1. Click **Add Stage** → **Custom Stage**
2. **Name**: `Terraform Plan`
3. Click **Set Up Stage**

**Add Steps to Stage 1:**

1. Click **Add Step** → **Shell Script**
2. Configure:
   - **Name**: `Setup Secrets`
   - **Script**: (copy from pipeline YAML)
   - Click **Apply Changes**

3. Click **Add Step** → **Shell Script**
4. Configure:
   - **Name**: `Terraform Init`
   - **Script**: (copy from pipeline YAML)
   - Add Environment Variables for secrets
   - Click **Apply Changes**

5. Click **Add Step** → **Shell Script**
6. Configure:
   - **Name**: `Terraform Plan`
   - **Script**: (copy from pipeline YAML)
   - Click **Apply Changes**

**Add Stage 2: Approval**

1. Click **Add Stage** → **Approval**
2. **Name**: `Approval`
3. Configure:
   - **Approval Type**: Harness Approval
   - **Approvers**: Select your user or create a user group
   - Click **Apply Changes**

**Add Stage 3: Terraform Apply**

1. Click **Add Stage** → **Custom Stage**
2. **Name**: `Terraform Apply`
3. Add steps similar to Stage 1, plus secret storage step

### 6.5 Configure Pipeline Variables

1. Click on the pipeline name at the top
2. Go to **Variables** tab
3. Add these variables:

| Variable Name | Type | Required | Default Value |
|---------------|------|----------|---------------|
| `environment` | String | Yes | `dev` |
| `confluent_environment_id` | String | Yes | - |
| `confluent_kafka_cluster_id` | String | Yes | - |
| `confluent_service_account_name` | String | Yes | `pubsub-connector-sa` |
| `connector_name` | String | Yes | `gcp-pubsub-source` |
| `kafka_topic` | String | Yes | - |
| `gcp_project_id` | String | Yes | - |
| `gcp_service_account_id` | String | Yes | `confluent-pubsub-reader` |
| `pubsub_subscription_id` | String | Yes | - |

### 6.6 Save Pipeline

Click **Save** in the top right corner.

---

## Step 7: Create Pipeline 2 (Connector Deployment)

### 7.1 Create New Pipeline

1. Click **Pipelines** → **+ Create Pipeline**
2. **Name**: `Pipeline 2 - Connector Deployment`
3. **Description**: "Deploys GCP Pub/Sub connector using secrets from Pipeline 1"
4. Click **Start**

### 7.2 Import YAML

1. Click **YAML** toggle
2. Paste content from `.harness/pipelines/pipeline-2-connector.yaml`
3. Update placeholders
4. Click **Save**

### 7.3 Key Differences from Pipeline 1

Pipeline 2 uses secrets created by Pipeline 1:
- `connector_kafka_api_key_dev` - Created by Pipeline 1
- `connector_kafka_api_secret_dev` - Created by Pipeline 1
- `connector_gcp_sa_key_dev` - Created by Pipeline 1

These secrets won't exist until Pipeline 1 runs successfully!

---

## Step 8: Run the Pipelines

### 8.1 Run Pipeline 1 First

1. Go to **Pipelines**
2. Click on `Pipeline 1 - Service Accounts Setup`
3. Click **Run**

### 8.2 Fill in Runtime Inputs

A form will appear for pipeline variables:

```
┌─────────────────────────────────────────────────────────────┐
│  Run Pipeline                                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Pipeline Variables:                                         │
│                                                              │
│  environment:           [dev                            ]    │
│  confluent_environment_id: [env-56ov5g                  ]    │
│  confluent_kafka_cluster_id: [lkc-kyv0kv               ]    │
│  confluent_service_account_name: [pubsub-connector-sa  ]    │
│  connector_name:        [gcp-pubsub-source-dev         ]    │
│  kafka_topic:           [pubsub.gcp_input_dev          ]    │
│  gcp_project_id:        [your-gcp-project-id           ]    │
│  gcp_service_account_id: [confluent-pubsub-reader-dev  ]    │
│  pubsub_subscription_id: [your-subscription-id         ]    │
│                                                              │
│                              [Cancel]  [Run Pipeline]        │
└─────────────────────────────────────────────────────────────┘
```

### 8.3 Monitor Pipeline Execution

1. After clicking **Run Pipeline**, you'll see the execution view
2. Watch each stage progress:
   - **Terraform Plan**: Should show Terraform output
   - **Approval**: Click to approve when ready
   - **Terraform Apply**: Creates the resources

### 8.4 Approve the Terraform Plan

1. When the pipeline reaches the Approval stage, you'll see a notification
2. Click on the **Approval** stage
3. Review the plan output from the previous stage
4. Click **Approve**

### 8.5 Verify Pipeline 1 Success

After Pipeline 1 completes:

1. Go to **Project Settings** → **Secrets**
2. Verify these new secrets exist:
   - `connector_kafka_api_key_dev`
   - `connector_kafka_api_secret_dev`
   - `connector_gcp_sa_key_dev`

### 8.6 Run Pipeline 2

1. Go to **Pipelines**
2. Click on `Pipeline 2 - Connector Deployment`
3. Click **Run**
4. Fill in the same values as Pipeline 1 (for matching environment)
5. Approve when prompted
6. Wait for completion

### 8.7 Verify Connector Deployment

1. Log into Confluent Cloud Console
2. Navigate to your cluster
3. Click **Connectors**
4. Find your connector (e.g., `gcp-pubsub-source-dev`)
5. Verify status is **Running**

---

## Troubleshooting

### Common Issues

#### Issue 1: "Secret not found"

**Symptoms**: Pipeline fails with "Secret 'connector_kafka_api_key_dev' not found"

**Solution**:
- Ensure Pipeline 1 completed successfully
- Check Project Settings → Secrets for the secret
- Verify the environment variable matches (e.g., `dev`)

#### Issue 2: "Delegate not available"

**Symptoms**: Pipeline stuck waiting for delegate

**Solution**:
- Check Project Settings → Delegates
- Verify delegate status is "Connected"
- If delegate is missing, restart the Docker container

#### Issue 3: "Terraform init failed"

**Symptoms**: Terraform fails to initialize

**Solution**:
- Verify delegate has Terraform installed
- Check network connectivity from delegate
- Verify GitHub connector is working

#### Issue 4: "Confluent authentication failed"

**Symptoms**: Terraform fails with 401 Unauthorized

**Solution**:
- Verify `confluent_cloud_api_key` and `confluent_cloud_api_secret` are correct
- Ensure API key has sufficient permissions (Environment Admin or higher)
- Check if API key is expired

#### Issue 5: "GCP authentication failed"

**Symptoms**: Terraform fails to authenticate to GCP

**Solution**:
- Verify `gcp_bootstrap_credentials_json` is valid JSON
- Ensure the service account has required permissions
- Check if the service account key is expired

### Debug Tips

1. **Enable Terraform Debug Logging**:
   Add this environment variable to your pipeline steps:
   ```
   TF_LOG=DEBUG
   ```

2. **Check Pipeline Logs**:
   - Click on any step in the pipeline execution
   - Click **View Logs** to see detailed output

3. **Test Secrets**:
   Add a debug step to verify secrets:
   ```bash
   # Check if secret is accessible (don't print the actual value!)
   if [ -n "<+secrets.getValue('confluent_cloud_api_key')>" ]; then
     echo "Secret is accessible"
   else
     echo "Secret NOT accessible"
   fi
   ```

### Getting Help

- **Harness Documentation**: [developer.harness.io](https://developer.harness.io)
- **Harness Community**: [community.harness.io](https://community.harness.io)
- **Terraform Confluent Provider**: [registry.terraform.io/providers/confluentinc/confluent](https://registry.terraform.io/providers/confluentinc/confluent)

---

## Next Steps

After completing the PoC:

1. **Add more environments**: Create staging and production configurations
2. **Implement GitOps**: Trigger pipelines on git push
3. **Add approval gates**: Require multiple approvers for production
4. **Set up notifications**: Configure Slack or email notifications
5. **Implement rollback**: Add Terraform destroy steps for rollback scenarios

---

## Quick Reference

### Harness Navigation

```
Left Sidebar:
├── Pipelines          → Create and manage pipelines
├── Executions         → View pipeline run history
├── Templates          → Reusable pipeline templates
├── Triggers           → Automated pipeline triggers
├── Project Settings   → Connectors, Secrets, Delegates
└── Account Settings   → Organization-wide settings
```

### Important URLs

| Resource | URL |
|----------|-----|
| Harness Platform | https://app.harness.io |
| Harness Docs | https://developer.harness.io |
| Confluent Cloud | https://confluent.cloud |
| GCP Console | https://console.cloud.google.com |

### Key Harness Expressions

| Expression | Description |
|------------|-------------|
| `<+secrets.getValue('name')>` | Get secret value |
| `<+pipeline.variables.var>` | Get pipeline variable |
| `<+project.identifier>` | Project identifier |
| `<+org.identifier>` | Organization identifier |
| `<+account.identifier>` | Account identifier |
