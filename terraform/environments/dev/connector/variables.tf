# =============================================================================
# Variables for Connector Deployment (Pipeline 2)
# Most values injected by Harness - includes secrets from Pipeline 1
# =============================================================================

# -----------------------------------------------------------------------------
# Confluent Cloud Credentials (from Harness Secrets)
# -----------------------------------------------------------------------------

variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (injected by Harness)"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret (injected by Harness)"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Confluent Resource IDs
# -----------------------------------------------------------------------------

variable "confluent_environment_id" {
  description = "Confluent Cloud Environment ID"
  type        = string
}

variable "confluent_kafka_cluster_id" {
  description = "Confluent Cloud Kafka Cluster ID"
  type        = string
}

# -----------------------------------------------------------------------------
# Connector Configuration
# -----------------------------------------------------------------------------

variable "connector_name" {
  description = "Name for the connector"
  type        = string
}

variable "kafka_topic" {
  description = "Target Kafka topic"
  type        = string
}

variable "tasks_max" {
  description = "Maximum number of connector tasks"
  type        = number
  default     = 1
}

variable "output_data_format" {
  description = "Output data format"
  type        = string
  default     = "JSON"
}

# -----------------------------------------------------------------------------
# GCP Configuration
# -----------------------------------------------------------------------------

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "pubsub_subscription_id" {
  description = "Pub/Sub subscription ID"
  type        = string
}

# -----------------------------------------------------------------------------
# Credentials from Pipeline 1 (Injected by Harness)
# -----------------------------------------------------------------------------

variable "gcp_credentials_base64" {
  description = "Base64-encoded GCP service account key (from Pipeline 1)"
  type        = string
  sensitive   = true
}

variable "kafka_api_key" {
  description = "Kafka API key (from Pipeline 1)"
  type        = string
  sensitive   = true
}

variable "kafka_api_secret" {
  description = "Kafka API secret (from Pipeline 1)"
  type        = string
  sensitive   = true
}
