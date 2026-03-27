# =============================================================================
# Variables for Confluent Service Account Module
# =============================================================================

variable "environment_id" {
  description = "The Confluent Cloud environment ID (e.g., env-xxxxx)"
  type        = string

  validation {
    condition     = can(regex("^env-[a-z0-9]+$", var.environment_id))
    error_message = "Environment ID must be in format 'env-xxxxx'"
  }
}

variable "kafka_cluster_id" {
  description = "The Confluent Cloud Kafka cluster ID (e.g., lkc-xxxxx)"
  type        = string

  validation {
    condition     = can(regex("^lkc-[a-z0-9]+$", var.kafka_cluster_id))
    error_message = "Kafka cluster ID must be in format 'lkc-xxxxx'"
  }
}

variable "service_account_name" {
  description = "Display name for the service account"
  type        = string
  default     = "connector-sa"

  validation {
    condition     = length(var.service_account_name) >= 3 && length(var.service_account_name) <= 64
    error_message = "Service account name must be between 3 and 64 characters"
  }
}

variable "connector_name" {
  description = "Name of the connector (used in descriptions)"
  type        = string
}

variable "target_topic" {
  description = "The Kafka topic the connector will write to"
  type        = string

  validation {
    condition     = length(var.target_topic) >= 1 && length(var.target_topic) <= 255
    error_message = "Topic name must be between 1 and 255 characters"
  }
}
