# =============================================================================
# Confluent Service Account Module
# Creates a service account and API key for connector authentication
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
# Service Account - For connector authentication
# -----------------------------------------------------------------------------

resource "confluent_service_account" "connector" {
  display_name = var.service_account_name
  description  = "Service account for ${var.connector_name} connector - managed by Harness Terraform"
}

# -----------------------------------------------------------------------------
# API Key - For Kafka cluster access
# -----------------------------------------------------------------------------

resource "confluent_api_key" "connector_kafka" {
  display_name = "${var.service_account_name}-kafka-api-key"
  description  = "Kafka API key for ${var.connector_name} connector"

  owner {
    id          = confluent_service_account.connector.id
    api_version = confluent_service_account.connector.api_version
    kind        = confluent_service_account.connector.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.this.id
    api_version = data.confluent_kafka_cluster.this.api_version
    kind        = data.confluent_kafka_cluster.this.kind

    environment {
      id = data.confluent_environment.this.id
    }
  }

  lifecycle {
    prevent_destroy = false  # Allow destruction for PoC - change to true for production
  }
}

# -----------------------------------------------------------------------------
# Role Bindings - Grant necessary permissions
# -----------------------------------------------------------------------------

# DeveloperWrite on the target topic
resource "confluent_role_binding" "connector_topic_write" {
  principal   = "User:${confluent_service_account.connector.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_kafka_cluster.this.rbac_crn}/kafka=${data.confluent_kafka_cluster.this.id}/topic=${var.target_topic}"
}

# DeveloperRead on the target topic (for connector status checks)
resource "confluent_role_binding" "connector_topic_read" {
  principal   = "User:${confluent_service_account.connector.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_kafka_cluster.this.rbac_crn}/kafka=${data.confluent_kafka_cluster.this.id}/topic=${var.target_topic}"
}

# DeveloperManage for connector consumer groups
resource "confluent_role_binding" "connector_group" {
  principal   = "User:${confluent_service_account.connector.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_kafka_cluster.this.rbac_crn}/kafka=${data.confluent_kafka_cluster.this.id}/group=connect-*"
}
