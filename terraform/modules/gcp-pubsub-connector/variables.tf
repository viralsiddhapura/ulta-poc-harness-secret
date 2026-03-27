# =============================================================================
# Variables for GCP Pub/Sub Source Connector Module
# =============================================================================

# -----------------------------------------------------------------------------
# Confluent Environment Variables
# -----------------------------------------------------------------------------

variable "environment_id" {
  description = "The Confluent Cloud environment ID"
  type        = string

  validation {
    condition     = can(regex("^env-[a-z0-9]+$", var.environment_id))
    error_message = "Environment ID must be in format 'env-xxxxx'"
  }
}

variable "kafka_cluster_id" {
  description = "The Confluent Cloud Kafka cluster ID"
  type        = string

  validation {
    condition     = can(regex("^lkc-[a-z0-9]+$", var.kafka_cluster_id))
    error_message = "Kafka cluster ID must be in format 'lkc-xxxxx'"
  }
}

# -----------------------------------------------------------------------------
# Connector Configuration
# -----------------------------------------------------------------------------

variable "connector_name" {
  description = "Name of the connector"
  type        = string

  validation {
    condition     = length(var.connector_name) >= 1 && length(var.connector_name) <= 256
    error_message = "Connector name must be between 1 and 256 characters"
  }
}

variable "kafka_topic" {
  description = "The Kafka topic to write messages to"
  type        = string

  validation {
    condition     = length(var.kafka_topic) >= 1 && length(var.kafka_topic) <= 255
    error_message = "Topic name must be between 1 and 255 characters"
  }
}

variable "tasks_max" {
  description = "Maximum number of tasks for the connector"
  type        = number
  default     = 1

  validation {
    condition     = var.tasks_max >= 1 && var.tasks_max <= 10
    error_message = "tasks_max must be between 1 and 10"
  }
}

variable "output_data_format" {
  description = "Output data format (AVRO, JSON_SR, PROTOBUF, JSON, BYTES)"
  type        = string
  default     = "JSON"

  validation {
    condition     = contains(["AVRO", "JSON_SR", "PROTOBUF", "JSON", "BYTES"], var.output_data_format)
    error_message = "output_data_format must be one of: AVRO, JSON_SR, PROTOBUF, JSON, BYTES"
  }
}

# -----------------------------------------------------------------------------
# GCP Configuration
# -----------------------------------------------------------------------------

variable "gcp_project_id" {
  description = "The GCP project ID containing the Pub/Sub subscription"
  type        = string
}

variable "pubsub_subscription_id" {
  description = "The GCP Pub/Sub subscription ID to read from"
  type        = string
}

# -----------------------------------------------------------------------------
# Credentials - Injected from Harness Secrets
# -----------------------------------------------------------------------------

variable "gcp_credentials_base64" {
  description = "Base64-encoded GCP service account JSON key"
  type        = string
  sensitive   = true
}

variable "kafka_api_key" {
  description = "Kafka API key for connector authentication"
  type        = string
  sensitive   = true
}

variable "kafka_api_secret" {
  description = "Kafka API secret for connector authentication"
  type        = string
  sensitive   = true
}
