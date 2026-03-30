# =============================================================================
# Pipeline 2: Connector Deployment
# Deploys the GCP Pub/Sub Source Connector using secrets from Pipeline 1
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  # Backend configuration - use GCS for state management
  # Uncomment and configure for production use
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "harness-poc/connector/dev"
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
  }
}

# -----------------------------------------------------------------------------
# Provider - Credentials injected by Harness
# -----------------------------------------------------------------------------

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

# -----------------------------------------------------------------------------
# GCP Pub/Sub Source Connector Module
# -----------------------------------------------------------------------------

module "gcp_pubsub_connector" {
  source = "../../../modules/gcp-pubsub-connector"

  # Confluent environment
  environment_id   = var.confluent_environment_id
  kafka_cluster_id = var.confluent_kafka_cluster_id

  # Connector configuration
  connector_name     = var.connector_name
  kafka_topic        = var.kafka_topic
  tasks_max          = var.tasks_max
  output_data_format = var.output_data_format

  # GCP configuration
  gcp_project_id         = var.gcp_project_id
  pubsub_subscription_id = var.pubsub_subscription_id

  # Credentials - ALL injected from Harness Secrets (created by Pipeline 1)
  gcp_credentials_base64 = var.gcp_credentials_base64
  kafka_api_key          = var.connector_kafka_key
  kafka_api_secret       = var.connector_kafka_secret
}
