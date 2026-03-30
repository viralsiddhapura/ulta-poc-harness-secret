# =============================================================================
# GCP Pub/Sub Source Connector Module
# Deploys a Confluent Cloud connector that reads from GCP Pub/Sub
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 2.0"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources - Lookup existing resources
# -----------------------------------------------------------------------------

data "confluent_environment" "this" {
  id = var.environment_id
}

data "confluent_kafka_cluster" "this" {
  id = var.kafka_cluster_id

  environment {
    id = data.confluent_environment.this.id
  }
}

# -----------------------------------------------------------------------------
# GCP Pub/Sub Source Connector
# -----------------------------------------------------------------------------

resource "confluent_connector" "gcp_pubsub_source" {
  environment {
    id = data.confluent_environment.this.id
  }

  kafka_cluster {
    id = data.confluent_kafka_cluster.this.id
  }

  # Sensitive configuration - credentials injected from Harness secrets
  config_sensitive = {
    "gcp.pubsub.credentials.json" = base64decode(var.gcp_credentials_base64)
    "kafka.api.key"               = var.kafka_api_key
    "kafka.api.secret"            = var.kafka_api_secret
  }

  # Non-sensitive configuration
  config_nonsensitive = {
    "name"                       = var.connector_name
    "connector.class"            = "PubSubSource"
    "kafka.auth.mode"            = "KAFKA_API_KEY"
    "kafka.topic"                = var.kafka_topic
    "gcp.pubsub.project.id"      = var.gcp_project_id
    "gcp.pubsub.topic.id"        = var.pubsub_topic_id
    "gcp.pubsub.subscription.id" = var.pubsub_subscription_id
    "tasks.max"                  = tostring(var.tasks_max)
    "output.data.format"         = var.output_data_format
  }

  lifecycle {
    # Set to true for production to prevent accidental deletion
    prevent_destroy = false
  }

  depends_on = [
    data.confluent_kafka_cluster.this
  ]
}
