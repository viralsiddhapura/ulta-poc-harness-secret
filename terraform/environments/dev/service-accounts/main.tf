# =============================================================================
# Pipeline 1: Service Accounts Deployment
# Creates Confluent and GCP service accounts with API keys
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  # Backend configuration - use GCS for state management
  # Uncomment and configure for production use
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "harness-poc/service-accounts/dev"
  # }

  # For PoC, use local backend
  backend "local" {
    path = "terraform.tfstate"
  }

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Providers - Credentials injected by Harness
# -----------------------------------------------------------------------------

provider "confluent" {
  # Credentials injected via environment variables:
  # CONFLUENT_CLOUD_API_KEY and CONFLUENT_CLOUD_API_SECRET
  # OR via TF_VAR_confluent_cloud_api_key and TF_VAR_confluent_cloud_api_secret
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

provider "google" {
  # Credentials injected via GOOGLE_APPLICATION_CREDENTIALS env var
  project = var.gcp_project_id
  # Note: Using GOOGLE_APPLICATION_CREDENTIALS env var for credentials
  # to avoid Terraform crash with sensitive values in conditionals
}

# -----------------------------------------------------------------------------
# Confluent Service Account Module
# -----------------------------------------------------------------------------

module "confluent_service_account" {
  source = "../../../modules/confluent-service-account"

  environment_id       = var.confluent_environment_id
  kafka_cluster_id     = var.confluent_kafka_cluster_id
  service_account_name = var.confluent_service_account_name
  connector_name       = var.connector_name
  target_topic         = var.kafka_topic
}

# -----------------------------------------------------------------------------
# GCP Service Account Module
# -----------------------------------------------------------------------------

module "gcp_service_account" {
  source = "../../../modules/gcp-service-account"

  gcp_project_id               = var.gcp_project_id
  service_account_id           = var.gcp_service_account_id
  service_account_display_name = var.gcp_service_account_display_name
  pubsub_subscription_id       = var.pubsub_subscription_id
  grant_project_viewer         = var.gcp_grant_project_viewer
}

# -----------------------------------------------------------------------------
# Local file for outputs (used by Harness to capture secrets)
# -----------------------------------------------------------------------------

resource "local_file" "outputs_json" {
  filename = "${path.module}/outputs.json"
  content = jsonencode({
    confluent = {
      service_account_id = module.confluent_service_account.service_account_id
      kafka_api_key      = module.confluent_service_account.kafka_api_key
      kafka_api_secret   = module.confluent_service_account.kafka_api_secret
    }
    gcp = {
      service_account_email = module.gcp_service_account.service_account_email
      gcp_sa_key_base64     = module.gcp_service_account.gcp_sa_key_base64
    }
  })

  # Ensure this file is not committed
  lifecycle {
    ignore_changes = [content]
  }
}
